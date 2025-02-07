local AstNameTable = require("./AstNameTable")
local FastVariables = require("@Shared/FastVariables")
local Lexeme = require("./Lexeme")
local Location = require("./Location")
local Position = require("./Position")
local NumberConversions = require("@Polyfill/NumberConversions")

type AstNameTable = AstNameTable.AstNameTable
type Lexeme = Lexeme.Lexeme
type Location = Location.Location
type Position = Position.Position
local unsigned = NumberConversions.unsigned

local CHAR_ZERO = string.char(0)
local UCHAR_MAX = 255

local enumBraceType = {
	InterpolatedString = 0,
	Normal = 1
}

local function isAlpha(ch: string): boolean
	-- use or trick to convert to lower case and unsigned comparison to do range check
	return unsigned(bit32.bor(string.byte(ch), string.byte(" ")) - string.byte("a")) < 26
end

local function isDigit(ch: string): boolean
	return unsigned(string.byte(ch) - string.byte("0")) < 10
end

local function isHexDigit(ch: string): boolean
	-- use or trick to convert to lower case and unsigned comparison to do range check
	return unsigned(string.byte(ch) - string.byte("0")) < 10 or unsigned(bit32.bor(string.byte(ch), string.byte(" ")) - string.byte("a")) < 6
end

local function isNewline(ch: string): boolean
	return ch == "\n"
end

local function isSpace(ch: string): boolean
	return ch == " "
		or ch == "\t"
		or ch == "\r"
		or ch == "\n"
		or ch == "\v"
		or ch == "\f"
end

local function unescape(ch: string): (string)
	if ch == "a" then
		return "\a"
	elseif ch == "b" then
		return "\b"
	elseif ch == "f" then
		return "\f"
	elseif ch == "n" then
		return "\n"
	elseif ch == "r" then
		return "\r"
	elseif ch == "t" then
		return "\t"
	elseif ch == "v" then
		return "\v"
	else
		return ch
	end
end

--[=[
	@class Lexer
	
	Class from `root/Ast/src/Lexer.cpp`.  
	Scans Luau code and converts them to [Lexemes](Lexeme), splitting the code up into more meaningful chunks.
]=]
local Lexer = {}
local prototype = {}
local metatable = {__index = prototype}

export type Lexer = typeof(setmetatable({} :: {
	buffer: string,
	bufferSize: number,
	offset: number,
	line: number,
	lineOffset: number,
	lexeme: Lexeme,
	names: AstNameTable,
	skipComments: boolean,
	readNames: boolean,
	prevLocation: Location,
	braceStack: {number}
}, metatable))

--[=[
	@within Lexer
	@prop buffer string
	@readonly
	@private
	@since v0.1.0
]=]
--[=[
	@within Lexer
	@prop bufferSize number
	@readonly
	@private
	@since v0.1.0
]=]
--[=[
	@within Lexer
	@prop offset number
	@private
	@since v0.1.0
]=]
--[=[
	@within Lexer
	@prop line number
	@private
	@since v0.1.0
]=]
--[=[
	@within Lexer
	@prop lineOffset number
	@private
	@since v0.1.0
]=]
--[=[
	@within Lexer
	@prop lexeme Lexeme
	@private
	@since v0.1.0
]=]
--[=[
	@within Lexer
	@prop names AstNameTable
	@readonly
	@private
	@since v0.1.0
]=]
--[=[
	@within Lexer
	@prop skipComments boolean
	@private
	@since v0.1.0
]=]
--[=[
	@within Lexer
	@prop readNames boolean
	@private
	@since v0.1.0
]=]
--[=[
	@within Lexer
	@prop prevLocation Location
	@private
	@since v0.1.0
]=]
--[=[
	@within Lexer
	@prop braceStack {number}
	@readonly
	@private
	@since v0.1.0
]=]
local _

--[=[
	@within Lexer
	@function new
	@param buffer string
	@param bufferSize number
	@param names AstNameTable
	@return Lexer
]=]
function Lexer.new(buffer: string, bufferSize: number, names: AstNameTable): Lexer
	return setmetatable({
		buffer = buffer,
		bufferSize = bufferSize,
		offset = 1,
		line = 1,
		lineOffset = 1,
		lexeme = Lexeme.new(Location.new(Position.new(1, 1), 0), Lexeme.Type.Eof),
		names = names,
		skipComments = false,
		readNames = false,
		braceStack = {},
		prevLocation = Location.new()
	}, metatable)
end

function prototype.setSkipComments(self: Lexer, skip: boolean): ()
	self.skipComments = skip
end

function prototype.setReadNames(self: Lexer, read: boolean): ()
	self.readNames = read
end

function prototype.next(self: Lexer, skipComments: boolean?, updatePrevLocation: boolean?): Lexeme
	if skipComments == nil then
		skipComments = self.skipComments
	end

	if updatePrevLocation == nil then
		updatePrevLocation = true
	end

	-- in skipComments mode we reject valid comments
	repeat
		-- consume whitespace before the token
		while isSpace(self:peekch()) do
			self:consumeAny()
		end
		if updatePrevLocation then
			self.prevLocation = self.lexeme.location
		end
		self.lexeme = self:readNext()
		updatePrevLocation = false
	until not (skipComments and (self.lexeme.type == Lexeme.Type.Comment or self.lexeme.type == Lexeme.Type.BlockComment))

	return self.lexeme
end

function prototype.nextline(self: Lexer): ()
	while self:peekch() ~= CHAR_ZERO and self:peekch() ~= "\r" and not isNewline(self:peekch()) do
		self:consume()
	end
	self:next()
end

function prototype.lookahead(self: Lexer): Lexeme
	local currentOffset = self.offset
	local currentLine = self.line
	local currentLineOffset = self.lineOffset
	local currentLexeme = self.lexeme
	local currentPrevLocation = self.prevLocation
	local currentBraceStackSize = #self.braceStack
	local currentBraceType = if #self.braceStack == 0 then enumBraceType.Normal else self.braceStack[#self.braceStack]

	local result = self:next()

	self.offset = currentOffset
	self.line = currentLine
	self.lineOffset = currentLineOffset
	self.lexeme = currentLexeme
	self.prevLocation = currentPrevLocation
	if (FastVariables.LuauLexerLookaheadRemembersBraceType) then
		if #self.braceStack < currentBraceStackSize then
			table.insert(self.braceStack, currentBraceType)
		elseif #self.braceStack > currentBraceStackSize then
			table.remove(self.braceStack, #self.braceStack)
		end
	end

	return result
end

--[=[
	@within Lexer
	@method current
	@return Lexeme
]=]
function prototype.current(self: Lexer): Lexeme
	return self.lexeme
end

function prototype.isReserved(self: Lexer, word: string): boolean
	for i = Lexeme.Type.Reserved_BEGIN, Lexeme.Type.Reserved_END - 1 do
		if word == Lexeme.reserved[i - Lexeme.Type.Reserved_BEGIN + 1] then
			return true
		end
	end

	return false
end

function prototype.peekch(self: Lexer, lookahead: number?): string
	lookahead = lookahead or 0; assert(lookahead) -- Eli NEW_SOLVER
	local offset = self.offset + lookahead
	return if offset - 1 < self.bufferSize then string.sub(self.buffer, offset, offset) else CHAR_ZERO
end

function prototype.position(self: Lexer): Position
	return Position.new(self.line, self.offset - self.lineOffset + 1)
end

function prototype.consume(self: Lexer): ()
	-- consume() assumes current character is known to not be a newline; use consumeAny if this is not guaranteed
	assert(not isNewline(string.sub(self.buffer, self.offset, self.offset)))
	self.offset += 1
end

function prototype.consumeAny(self: Lexer): ()
	if isNewline(string.sub(self.buffer, self.offset, self.offset)) then
		self.line += 1
		self.lineOffset = self.offset + 1
	end
	self.offset += 1
end

function prototype.readCommentBody(self: Lexer): Lexeme
	local start = self:position()

	assert(self:peekch(0) == "-" and self:peekch(1) == "-")
	self:consume()
	self:consume()

	local startOffset = self.offset

	if self:peekch() == "[" then
		local sep = self:skipLongSeparator()

		if sep >= 0 then
			return self:readLongString(start, sep, Lexeme.Type.BlockComment, Lexeme.Type.BrokenComment)
		end
	end

	-- fall back to single-line comment
	while self:peekch() ~= CHAR_ZERO and self:peekch() ~= "\r" and not isNewline(self:peekch()) do
		self:consume()
	end

	return Lexeme.new(Location.new(start, self:position()), Lexeme.Type.Comment, string.sub(self.buffer, startOffset, self.offset - 1), self.offset - startOffset)
end

-- Given a sequence [===[ or ]===], returns:
-- 1. number of equal signs (or 0 if none present) between the brackets
-- 2. -1 if this is not a long comment/string separator
-- 3. -N if this is a malformed separator
-- Does *not* consume the closing brace.
function prototype.skipLongSeparator(self: Lexer): number
	local start = self:peekch()

	assert(start == "[" or start == "]")
	self:consume()

	local count = 0

	while self:peekch() == "=" do
		self:consume()
		count += 1
	end

	return if start == self:peekch() then count else -count - 1
end

function prototype.readLongString(self: Lexer, start: Position, sep: number, ok: number, broken: number): Lexeme
	-- skip (second) [
	assert(self:peekch() == "[")
	self:consume()

	local startOffset = self.offset

	while self:peekch() ~= CHAR_ZERO do
		if self:peekch() == "]" then
			if self:skipLongSeparator() == sep then
				assert(self:peekch() == "]")
				self:consume() -- skip (second) ]

				local endOffset = self.offset - sep - 2
				assert(endOffset >= startOffset)

				return Lexeme.new(Location.new(start, self:position()), ok, string.sub(self.buffer, startOffset, endOffset - 1), endOffset - startOffset)
			end
		else
			self:consumeAny()
		end
	end

	return Lexeme.new(Location.new(start, self:position()), broken)
end

function prototype.readBackslashInString(self: Lexer): ()
	assert(self:peekch() == "\\")
	self:consume()
	if self:peekch() == "\r" then
		self:consume()
		if self:peekch() == "\n" then
			self:consumeAny()
		end
	elseif self:peekch() == CHAR_ZERO then
	elseif self:peekch() == "z" then
		self:consume()
		while isSpace(self:peekch()) do
			self:consumeAny()
		end
	else
		self:consumeAny()
	end
end

function prototype.readQuotedString(self: Lexer): Lexeme
	local start = self:position()

	local delimiter = self:peekch()
	assert(delimiter == "'" or delimiter == '"')
	self:consume()

	local startOffset = self.offset

	while (self:peekch() ~= delimiter) do
		if self:peekch() == CHAR_ZERO or self:peekch() == "\r" or self:peekch() == "\n" then
			return Lexeme.new(Location.new(start, self:position()), Lexeme.Type.BrokenString)
		elseif self:peekch() == "\\" then
			self:readBackslashInString()
		else
			self:consume()
		end
	end

	self:consume()

	return Lexeme.new(Location.new(start, self:position()), Lexeme.Type.QuotedString, string.sub(self.buffer, startOffset, self.offset - 2), self.offset - startOffset - 1)
end

function prototype.readInterpolatedStringBegin(self: Lexer): Lexeme
	assert(self:peekch() == "`")

	local start = self:position()
	self:consume()

	return self:readInterpolatedStringSection(start, Lexeme.Type.InterpStringBegin, Lexeme.Type.InterpStringSimple)
end

function prototype.readInterpolatedStringSection(self: Lexer, start: Position, formatType: number, endType: number): Lexeme
	local startOffset = self.offset

	while self:peekch() ~= "`" do
		if self:peekch() == CHAR_ZERO or self:peekch() == "\r" or self:peekch() == "\n" then
			return Lexeme.new(Location.new(start, self:position()), Lexeme.Type.BrokenString)
		elseif self:peekch() == "\\" then
			-- Allow for \u{}, which would otherwise be consumed by looking for {
			if self:peekch(1) == "u" and self:peekch(2) == "{" then
				self:consume() -- backslash
				self:consume() -- u
				self:consume() -- {
			end

			self:readBackslashInString()
		elseif self:peekch() == "{" then
			table.insert(self.braceStack, enumBraceType.InterpolatedString)

			if self:peekch(1) == "{" then
				local brokenDoubleBrace =
					Lexeme.new(Location.new(start, self:position()), Lexeme.Type.BrokenInterpDoubleBrace, string.sub(self.buffer, startOffset, self.offset - 1), self.offset - startOffset)
				self:consume()
				self:consume()
				return brokenDoubleBrace
			end

			self:consume()
			return Lexeme.new(Location.new(start, self:position()), formatType, string.sub(self.buffer, startOffset, self.offset - 2), self.offset - startOffset - 1)
		else
			self:consume()
		end
	end

	self:consume()

	return Lexeme.new(Location.new(start, self:position()), endType, string.sub(self.buffer, startOffset, self.offset - 2), self.offset - startOffset - 1)
end

function prototype.readNumber(self: Lexer, start: Position, startOffset: number): Lexeme
	assert(isDigit(self:peekch()))

	-- This function does not do the number parsing - it only skips a number-like pattern.
	-- It uses the same logic as Lua stock lexer; the resulting string is later converted
	-- to a number with proper verification.
	repeat
		self:consume()
	until not (isDigit(self:peekch()) or self:peekch() == "." or self:peekch() == "_")

	if self:peekch() == "e" or self:peekch() == "E" then
		self:consume()

		if self:peekch() == "+" or self:peekch() == "-" then
			self:consume()
		end
	end

	while (isAlpha(self:peekch()) or isDigit(self:peekch()) or self:peekch() == "_") do
		self:consume()
	end

	return Lexeme.new(Location.new(start, self:position()), Lexeme.Type.Number, string.sub(self.buffer, startOffset, self.offset - 1), self.offset - startOffset)
end

-- Eli: deviation
function prototype.readName(self: Lexer): Lexeme
	assert(isAlpha(self:peekch()) or self:peekch() == "_" or self:peekch() == "@")

	local startPosition = self:position()
	local startOffset = self.offset

	repeat
		self:consume()
	until not (isAlpha(self:peekch()) or isDigit(self:peekch()) or self:peekch() == "_")

	local name = string.sub(self.buffer, startOffset, self.offset - 1)
	local finalLocation = Location.new(startPosition, self.offset - startOffset)
	if self:isReserved(name) then
		local enumKey = "Reserved" .. string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
		local enumValue = Lexeme.Type[enumKey] :: number
		return Lexeme.new(finalLocation, enumValue)
	end

	return Lexeme.new(finalLocation, Lexeme.Type.Name, name)
end

function prototype.readNext(self: Lexer): Lexeme
	local start = self:position()

	local case = self:peekch()
	if case == CHAR_ZERO then
		return Lexeme.new(Location.new(start, 0), Lexeme.Type.Eof)
	elseif case == "-" then
		if self:peekch(1) == ">" then
			self:consume()
			self:consume()
			return Lexeme.new(Location.new(start, 2), Lexeme.Type.SkinnyArrow)
		elseif self:peekch(1) == "=" then
			self:consume()
			self:consume()
			return Lexeme.new(Location.new(start, 2), Lexeme.Type.SubAssign)
		elseif self:peekch(1) == "-" then
			return self:readCommentBody()
		else
			self:consume()
			return Lexeme.new(Location.new(start, 1), "-")
		end
	elseif case == "[" then
		local sep = self:skipLongSeparator()
		
		if sep >= 0 then
			return self:readLongString(start, sep, Lexeme.Type.RawString, Lexeme.Type.BrokenString)
		elseif sep == -1 then
			return Lexeme.new(Location.new(start, 1), "[")
		else
			return Lexeme.new(Location.new(start, self:position()), Lexeme.Type.BrokenString)
		end
	elseif case == "{" then
		self:consume()

		if #self.braceStack > 0 then
			table.insert(self.braceStack, enumBraceType.Normal)
		end

		return Lexeme.new(Location.new(start, 1), "{")
	elseif case == "}" then
		self:consume()

		if #self.braceStack == 0 then
			return Lexeme.new(Location.new(start, 1), "}")
		end

		local braceStackTop = self.braceStack[#self.braceStack]
		table.remove(self.braceStack, #self.braceStack)

		if braceStackTop ~= enumBraceType.InterpolatedString then
			return Lexeme.new(Location.new(start, 1), "}")
		end

		return self:readInterpolatedStringSection(self:position(), Lexeme.Type.InterpStringMid, Lexeme.Type.InterpStringEnd)
	elseif case == "=" then
		self:consume()

		if self:peekch() == "=" then
			self:consume()
			return Lexeme.new(Location.new(start, 2), Lexeme.Type.Equal)
		else
			return Lexeme.new(Location.new(start, 1), "=")
		end
	elseif case == "<" then
		self:consume()

		if self:peekch() == "=" then
			self:consume()
			return Lexeme.new(Location.new(start, 2), Lexeme.Type.LessEqual)
		else
			return Lexeme.new(Location.new(start, 1), "<")
		end
	elseif case == ">" then
		self:consume()

		if self:peekch() == "=" then
			self:consume()
			return Lexeme.new(Location.new(start, 2), Lexeme.Type.GreaterEqual)
		else
			return Lexeme.new(Location.new(start, 1), ">")
		end
	elseif case == "~" then
		self:consume()

		if self:peekch() == "=" then
			self:consume()
			return Lexeme.new(Location.new(start, 2), Lexeme.Type.NotEqual)
		else
			return Lexeme.new(Location.new(start, 1), "~")
		end
	elseif case == '"' or case == "'" then
		return self:readQuotedString()
	elseif case == "`" then
		return self:readInterpolatedStringBegin()
	elseif case == "." then
		self:consume()

		if self:peekch() == "." then
			self:consume()

			if self:peekch() == "." then
				self:consume()
				
				return Lexeme.new(Location.new(start, 3), Lexeme.Type.Dot3)
			elseif self:peekch() == "=" then
				self:consume()

				return Lexeme.new(Location.new(start, 3), Lexeme.Type.ConcatAssign)
			else
				return Lexeme.new(Location.new(start, 2), Lexeme.Type.Dot2)
			end
		else
			if isDigit(self:peekch()) then
				return self:readNumber(start, self.offset - 1)
			else
				return Lexeme.new(Location.new(start, 1), ".")
			end
		end
	elseif case == "+" then
		self:consume()

		if self:peekch() == "=" then
			self:consume()
			return Lexeme.new(Location.new(start, 2), Lexeme.Type.AddAssign)
		else
			return Lexeme.new(Location.new(start, 1), "+")
		end
	elseif case == "/" then
		self:consume()

		local ch = self:peekch()

		if ch == "=" then
			self:consume()
			return Lexeme.new(Location.new(start, 2), Lexeme.Type.DivAssign)
		elseif ch == "/" then
			self:consume()

			if self:peekch() == "=" then
				self:consume()
				return Lexeme.new(Location.new(start, 3), Lexeme.Type.FloorDivAssign)
			else
				return Lexeme.new(Location.new(start, 2), Lexeme.Type.FloorDiv)
			end
		else
			return Lexeme.new(Location.new(start, 1), "/")
		end
	elseif case == "*" then
		self:consume()

		if self:peekch() == "=" then
			self:consume()
			return Lexeme.new(Location.new(start, 2), Lexeme.Type.MulAssign)
		else
			return Lexeme.new(Location.new(start, 1), "*")
		end
	elseif case == "%" then
		self:consume()

		if self:peekch() == "=" then
			self:consume()
			return Lexeme.new(Location.new(start, 2), Lexeme.Type.ModAssign)
		else
			return Lexeme.new(Location.new(start, 1), "%")
		end
	elseif case == "^" then
		self:consume()

		if self:peekch() == "=" then
			self:consume()
			return Lexeme.new(Location.new(start, 2), Lexeme.Type.PowAssign)
		else
			return Lexeme.new(Location.new(start, 1), "^")
		end
	elseif case == ":" then
		self:consume()
		if self:peekch() == ":" then
			self:consume()
			return Lexeme.new(Location.new(start, 2), Lexeme.Type.DoubleColon)
		else
			return Lexeme.new(Location.new(start, 1), ":")
		end
	elseif case == "("
		or case == ")"
		or case == "]"
		or case == ";"
		or case == ","
		or case == "#"
		or case == "?"
		or case == "&"
		or case == "|" then
		local ch = self:peekch()
		self:consume()

		return Lexeme.new(Location.new(start, 1), ch)
	elseif case == "@" and FastVariables.LuauAttributeSyntax then
		-- Eli: deviation
		return self:readName()
	else
		if isDigit(self:peekch()) then
			return self:readNumber(start, self.offset)
		elseif isAlpha(self:peekch()) or self:peekch() == "_" then
			-- Eli: deviation
			return self:readName()
		elseif bit32.btest(string.byte(self:peekch()), 0x80) then
			return self:readUtf8Error()
		else
			local ch = self:peekch()
			self:consume()

			return Lexeme.new(Location.new(start, 1), ch)
		end
	end
end

function prototype.readUtf8Error(self: Lexer): Lexeme
	local start = self:position()
	local codepoint = 0
	local size = 0

	local chByte = self:peekch():byte()
	if bit32.band(chByte, 0b10000000) == 0b00000000 then
		size = 1
		codepoint = bit32.band(chByte, 0x7F)
	elseif bit32.band(chByte, 0b11100000) == 0b11000000 then
		size = 2
		codepoint = bit32.band(chByte, 0b11111)
	elseif bit32.band(chByte, 0b11110000) == 0b11100000 then
		size = 3
		codepoint = bit32.band(chByte, 0b1111)
	elseif bit32.band(chByte, 0b11111000) == 0b11110000 then
		size = 4
		codepoint = bit32.band(chByte, 0b111)
	else
		self:consume()
		return Lexeme.new(Location.new(start, self:position()), Lexeme.Type.BrokenUnicode)
	end

	self:consume()

	local chByte2 = string.byte(self:peekch())
	for i = 1, size-1 do
		if bit32.band(chByte2, 0b11000000) ~= 0b10000000 then
			return Lexeme.new(Location.new(start, self:position()), Lexeme.Type.BrokenUnicode)
		end

		codepoint = bit32.lshift(codepoint, 6)
		codepoint = bit32.bor(codepoint, chByte2)
		self:consume()
	end

	local result = Lexeme.new(Location.new(start, self:position()), Lexeme.Type.BrokenUnicode)
	result.codepoint = codepoint
	return result
end

local function toUtf8(data: {string}, offset: number, code: number): number
	-- U+0000..U+007F
	if code < 0x80 then
		data[offset] = string.char(code)
		return 1
	elseif code < 0x800 then
		-- U+0080..U+07FF
		data[offset] = string.char(bit32.bor(0xC0, bit32.rshift(code, 6)))
		data[offset+1] = string.char(bit32.bor(0x80, bit32.band(code, 0x3F)))
		return 2
	elseif code < 0x10000 then
		-- U+0800..U+FFFF
		data[offset] = string.char(bit32.bor(0xE0, bit32.rshift(code, 12)))
		data[offset+1] = string.char(bit32.bor(0x80, bit32.band(bit32.rshift(code, 6), 0x3F)))
		data[offset+2] = string.char(bit32.bor(0x80, bit32.band(code, 0x3F)))
		return 3
	elseif code < 0x110000 then
		-- U+10000..U+10FFFF
		data[offset] = string.char(bit32.bor(0xF0, bit32.rshift(code, 18)))
		data[offset+1] = string.char(bit32.bor(0x80, bit32.band(bit32.rshift(code, 12), 0x3F)))
		data[offset+2] = string.char(bit32.bor(0x80, bit32.band(bit32.rshift(code, 6), 0x3F)))
		data[offset+3] = string.char(bit32.bor(0x80, bit32.band(code, 0x3F)))
		return 4
	else
		return 0
	end
end

function Lexer.fixupQuotedString(str: string): {
	success: boolean,
	result: string?
}
	local size = #str

	if size == 0 or str:find("\\") == nil then
		return {
			success = true,
			result = str
		}
	end
	
	local sizeP1 = size + 1
	local data = str:split("")
	local write = 0

	local i = 1
	while true do
		if i > size then
			break
		end

		if data[i] ~= "\\" then
			write += 1
			data[write] = data[i]
			i += 1
			continue
		end

		if i + 1 > sizeP1 then
			return {success = false}
		end

		local escape = data[i + 1]
		i += 2 -- skip \e

		if escape == "\n" then
			write += 1
			data[write] = "\n"
		elseif escape == "\r" then
			write += 1
			data[write] = "\n"
			if i < sizeP1 and data[i] == "\n" then
				i += 1
			end
		elseif escape == CHAR_ZERO then
			return {success = false}
		elseif escape == "x" then
			-- hex escape codes are exactly 2 hex digits long
			if i + 2 > sizeP1 then
				return {success = false}
			end

			local code = 0

			for j = 0, 1 do
				local ch = data[i + j]
				if not isHexDigit(ch) then
					return {success = false}
				end

				-- use or trick to convert to lower case
				local chByte = ch:byte()
				code = 16 * code + (if isDigit(ch) then chByte - ("0"):byte() else bit32.bor(chByte, (" "):byte()) - ("a"):byte() + 10)
			end

			write += 1
			data[write] = string.char(code)
			i += 2
		elseif escape == "z" then
			while i < sizeP1 and isSpace(data[i]) do
				i += 1
			end
		elseif escape == "u" then
			-- unicode escape codes are at least 3 characters including braces
			if i + 3 > sizeP1 then
				return {success = false}
			end
			
			if data[i] ~= "{" then
				return {success = false}
			end
			i += 1

			if data[i] == "}" then
				return {success = false}
			end

			local code = 0

			for j = 0, 15 do
				if i == sizeP1 then
					return {success = false}
				end
				
				local ch = data[i]

				if ch == "}" then
					break
				end

				if not isHexDigit(ch) then
					return {success = false}
				end

				-- use or trick to convert to lower case
				local chByte = ch:byte()
				code = 16 * code + (if isDigit(ch) then chByte - ("0"):byte() else bit32.bor(chByte, (" "):byte()) - ("a"):byte() + 10)
				i += 1
			end
			
			if i == sizeP1 or data[i] ~= "}" then
				return {success = false}
			end
			i += 1

			local utf8 = toUtf8(data, write, code)
			if utf8 == 0 then
				return {success = false}
			end

			write += utf8
		else
			if isDigit(escape) then
				local code = (escape):byte() - ("0"):byte()

				for j = 0, 1 do
					if i == sizeP1 or not isDigit(data[i]) then
						break
					end

					code = 10 * code + data[i]:byte() - ("0"):byte()
					i += 1
				end

				if code > UCHAR_MAX then
					return {success = false}
				end

				write += 1
				data[write] = string.char(code)
			else
				write += 1
				data[write] = unescape(escape)
			end
		end
	end

	assert(write <= size)

	return {
		success = true,
		result = table.concat(data)
	}
end

--[=[
	@within Lexer
	@function fixupMultilineString
	@param data string
	@return string

	Lua rules for multiline strings are as follows:
	- standalone \r, \r\n, \n\r and \n are all considered newlines
	- first newline in the multiline string is skipped
	- all other newlines are normalized to \n
	
	Since our lexer just treats \n as newlines, we apply a simplified set of rules that is sufficient to get normalized newlines for Windows/Unix:
	- \r\n and \n are considered newlines
	- first newline is skipped
	- newlines are normalized to \n
	
	This makes the string parsing behavior consistent with general lexing behavior - a standalone \r isn't considered a new line from the line tracking perspective.
]=]
function Lexer.fixupMultilineString(data: string): string
	if #data == 0 then
		return ""
	end

	

	local source = data:split("")
	local result = {}

	local function add(replaceWithNewline: boolean?): ()
		if replaceWithNewline then
			table.remove(source, 1)
			table.insert(result, "\n")
		else
			table.insert(result, assert(table.remove(source, 1)))
		end
	end

	-- skip leading newline
	if source[1] == "\r" and source[2] == "\n" then
		add()
		add()
	elseif source[1] == "\n" then
		add()
	end

	-- parse the rest of the string, converting newlines as we go
	while #source > 0 do
		if source[1] == "\r" and source[2] == "\n" then
			add(true)
		else
			-- note, this handles \n by just writing it without changes
			add()
		end
	end

	return table.concat(result)
end

function prototype.previousLocation(self: Lexer): Location
	return self.prevLocation
end

return Lexer