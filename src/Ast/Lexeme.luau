local Confusables = require("./Confusables")
local FastVariables = require("@Shared/FastVariables")
local Location = require("./Location")

type Location = Location.Location

--[=[
	@class Lexeme
	@tag struct

	Struct from `root/Ast/src/Lexer.cpp`.  

	A meaningful piece of code with an assigned type and location.
]=]
local Lexeme = {}
local prototype = {}
local metatable = {__index = prototype}

export type Lexeme = {
	--[=[
		@within Lexeme
		@prop type number
		@readonly
		@since v0.1.0

		Corresponds to the [Lexeme Type Enum](Lexeme#Type).
	]=]
	type: number,
	--[=[
		@within Lexeme
		@prop location Location
		@readonly
		@since v0.1.0
	]=]
	location: Location,

	--[=[
		@within Lexeme
		@prop length number
		@readonly
		@private
		@since v0.1.0
	]=]
	-- length is used to extract a slice from the input buffer.
	-- This field is only valid for certain lexeme types which don't duplicate portions of input
	-- but instead store a pointer to a location in the input buffer and the length of lexeme.
	length: number,

	--[=[
		@within Lexeme
		@prop data string?
		@readonly
		@since v0.1.0

		For types String, Number, or Comment.

		Every lexeme may have either [data](Lexeme#data), [name](Lexeme#name), or [codepoint](Lexeme#codepoint).
	]=]
	data: string?,
	--[=[
		@within Lexeme
		@prop name string?
		@readonly
		@since v0.1.0

		For type Name.
	]=]
	name: string?,
	--[=[
		@within Lexeme
		@prop codepoint number?
		@since v0.1.0

		For type BrokenUnicode.
	]=]
	codepoint: number?,

	--[=[
		@within Lexeme
		@method getLength
		@return number
		@since v0.1.0
	]=]
	getLength: (self: Lexeme) -> number,

	--[=[
		@within Lexeme
		@method toString
		@return string
		@since v0.1.0
	]=]
	toString: (self: Lexeme) -> string
}

--[=[
	@within Lexeme
	@interface TypeEnum
	@tag enum
	
	.Eof 1,
	
	-- 2..255 means actual character values
	.Char_END 256,
	
	.Equal 257,
	.LessEqual 258,
	.GreaterEqual 259,
	.NotEqual 260,
	.Dot2 261,
	.Dot3 262,
	.SkinnyArrow 263,
	.DoubleColon 264,
	.FloorDiv 265,
	
	.InterpStringBegin 266,
	.InterpStringMid 267,
	.InterpStringEnd 268,
	-- An interpolated string with no expressions (like `x`)
	.InterpStringSimple 269,
	.AddAssign 270,
	.SubAssign 271,
	.MulAssign 272,
	.DivAssign 273,
	.FloorDivAssign 274,
	.ModAssign 275,
	.PowAssign 276,
	.ConcatAssign 277,
	
	.RawString 278,
	.QuotedString 279,
	.Number 280,
	.Name 281,
	
	.Comment 282,
	.BlockComment 283,
	
	.Attribute 284,
	
	.BrokenString 285,
	.BrokenComment 286,
	.BrokenUnicode 287,
	.BrokenInterpDoubleBrace 288,
	.Error 289,
	
	.Reserved_BEGIN 290,
	.ReservedAnd 290,
	.ReservedBreak 291,
	.ReservedDo 292,
	.ReservedElse 293,
	.ReservedElseif 294,
	.ReservedEnd 295,
	.ReservedFalse 296,
	.ReservedFor 297,
	.ReservedFunction 298,
	.ReservedIf 299,
	.ReservedIn 300,
	.ReservedLocal 301,
	.ReservedNil 302,
	.ReservedNot 303,
	.ReservedOr 304,
	.ReservedRepeat 305,
	.ReservedReturn 306,
	.ReservedThen 307,
	.ReservedTrue 308,
	.ReservedUntil 309,
	.ReservedWhile 310,
	.Reserved_END 311
]=]
local _

--[=[
	@within Lexeme
	@prop Type TypeEnum
]=]
Lexeme.Type = {
	--[[
		`<eof>`

		Represents the **e**nd **o**f the **f**ile.
	]]
	Eof = 1,
	
	-- 2..255 means actual character values
	Char_END = 256,

	Equal = 257,
	LessEqual = 258,
	GreaterEqual = 259,
	NotEqual = 260,
	--[[
		`..`

		The concatenation operator.
	]]
	Dot2 = 261,
	--[[
		`...`

		Used for type packs.
	]]
	Dot3 = 262,

	--[[
		`-->`
	]]
	SkinnyArrow = 263,
	--[[
		`::`
	]]
	DoubleColon = 264,
	--[[
		`//`

		```lua
		a // b
		```
		
		is equivalent to
		
		```lua
		math.floor(a / b)
		```
	]]
	FloorDiv = 265,
	
	InterpStringBegin = 266,
	InterpStringMid = 267,
	InterpStringEnd = 268,
	-- An interpolated string with no expressions (like `x`)
	InterpStringSimple = 269,
	AddAssign = 270,
	SubAssign = 271,
	MulAssign = 272,
	DivAssign = 273,
	FloorDivAssign = 274,
	ModAssign = 275,
	PowAssign = 276,
	ConcatAssign = 277,
	
	RawString = 278,
	QuotedString = 279,
	Number = 280,
	Name = 281,
	
	Comment = 282,
	BlockComment = 283,
	
	Attribute = 284,
	
	BrokenString = 285,
	BrokenComment = 286,
	BrokenUnicode = 287,
	BrokenInterpDoubleBrace = 288,
	Error = 289,
	
	--[[
		The start of the reserved words section, used for loops.

		```lua
		for index = Lexeme.Type.Reserved_BEGIN + 1, Lexeme.Type.Reserved_END - 1 do

		end
		```
	]]
	Reserved_BEGIN = 290,
	ReservedAnd = 290,
	ReservedBreak = 291,
	ReservedDo = 292,
	ReservedElse = 293,
	ReservedElseif = 294,
	ReservedEnd = 295,
	ReservedFalse = 296,
	ReservedFor = 297,
	ReservedFunction = 298,
	ReservedIf = 299,
	ReservedIn = 300,
	ReservedLocal = 301,
	ReservedNil = 302,
	ReservedNot = 303,
	ReservedOr = 304,
	ReservedRepeat = 305,
	ReservedReturn = 306,
	ReservedThen = 307,
	ReservedTrue = 308,
	ReservedUntil = 309,

	--[[
		The `while` keyword.

		```lua
		while true do
			print("Hello!")
			break
		end
		```
	]]
	ReservedWhile = 310,

	--[[
		The end of the reserved words section, used for loops.

		```lua
		for index = Lexeme.Type.Reserved_BEGIN + 1, Lexeme.Type.Reserved_END - 1 do

		end
		```
	]]
	Reserved_END = 311
}

--[=[
	@within Lexeme
	@prop reserved {string}
	All reserved keywords of Lua. Luau soft keywords, like "continue" and "export", are not contained in this list.
]=]
Lexeme.reserved = {"and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while"}

--[=[
	@within Lexeme
	@function new
	@param location Location
	@param typeAny number | string
	@param extra string?
	@param size number?
	@return Lexeme
	@since v0.1.0
	Arguments can be:
	- Location, TypeEnum
	- Location, single character
	- Location, TypeEnum, string for data, size
	- Location, TypeEnum, string for name
]=]
function Lexeme.new(location: Location.Location, typeAny: number | string, extra: string?, size: number?): Lexeme
	local object: any
	if type(typeAny) == "number" and extra == nil and size == nil then
		object = {
			type = typeAny,
			location = location,
			length = 0
		}
	elseif type(typeAny) == "string" and extra == nil and size == nil then
		object = {
			type = string.byte(typeAny),
			location = location,
			length = 0
		}
	elseif type(typeAny) == "number" and extra ~= nil and size ~= nil then
		object = {
			type = typeAny,
			location = location,
			length = size,
			data = extra
		}
		assert(table.find({Lexeme.Type.RawString, Lexeme.Type.QuotedString, Lexeme.Type.InterpStringBegin, Lexeme.Type.InterpStringMid, Lexeme.Type.InterpStringEnd, Lexeme.Type.InterpStringSimple, Lexeme.Type.BrokenInterpDoubleBrace, Lexeme.Type.Number, Lexeme.Type.Comment, Lexeme.Type.BlockComment}, typeAny))
	elseif type(typeAny) == "number" and extra ~= nil and size == nil then
		object = {
			type = typeAny,
			location = location,
			length = 0,
			name = extra
		}
		assert(table.find({Lexeme.Type.Name, Lexeme.Type.Attribute}, typeAny) or typeAny >= Lexeme.Type.Reserved_BEGIN and typeAny < Lexeme.Type.Reserved_END)
	else
		error(`Invalid arguments to Lexeme constructor: {location}, {typeAny}, {extra}, {size}.`)
	end

	return setmetatable(object, metatable)
end

function prototype.getLength(self: Lexeme): number
	return self.length
end

function prototype.toString(self: Lexeme): string
	if self.type == Lexeme.Type.Eof then
		return "<eof>"

	elseif self.type == Lexeme.Type.Equal then
		return "'=='"

	elseif self.type == Lexeme.Type.LessEqual then
		return "'<='"

	elseif self.type == Lexeme.Type.GreaterEqual then
		return "'>='"

	elseif self.type == Lexeme.Type.NotEqual then
		return "'~='"

	elseif self.type == Lexeme.Type.Dot2 then
		return "'..'"

	elseif self.type == Lexeme.Type.Dot3 then
		return "'...'"

	elseif self.type == Lexeme.Type.SkinnyArrow then
		return "'->'"

	elseif self.type == Lexeme.Type.DoubleColon then
		return "'::'"

	elseif self.type == Lexeme.Type.FloorDiv then
		return "'//'"

	elseif self.type == Lexeme.Type.AddAssign then
		return "'+='"

	elseif self.type == Lexeme.Type.SubAssign then
		return "'-='"

	elseif self.type == Lexeme.Type.MulAssign then
		return "'*='"

	elseif self.type == Lexeme.Type.DivAssign then
		return "'/='"

	elseif self.type == Lexeme.Type.FloorDivAssign then
		return "'//='"

	elseif self.type == Lexeme.Type.ModAssign then
		return "'%='"

	elseif self.type == Lexeme.Type.PowAssign then
		return "'^='"

	elseif self.type == Lexeme.Type.ConcatAssign then
		return "'..='"

	elseif self.type == Lexeme.Type.RawString or self.type == Lexeme.Type.QuotedString then
		return if self.data then string.format("\"%s\"", self.data) else "string"

	elseif self.type == Lexeme.Type.InterpStringBegin then
		return if self.data then string.format("`%s{", self.data) else "the beginning of an interpolated string"

	elseif self.type == Lexeme.Type.InterpStringMid then
		return if self.data then string.format("}%s{", self.data) else "the middle of an interpolated string"

	elseif self.type == Lexeme.Type.InterpStringEnd then
		return if self.data then string.format("}%s`", self.data) else "the end of an interpolated string"

	elseif self.type == Lexeme.Type.InterpStringSimple then
		return if self.data then string.format("`%s`", self.data) else "interpolated string"

	elseif self.type == Lexeme.Type.Number then
		return if self.data then string.format("'%s'", self.data) else "number"

	elseif self.type == Lexeme.Type.Name then
		return if self.name then string.format("'%s'", self.name) else "identifier"

	elseif self.type == Lexeme.Type.Comment then
		return "comment"

	elseif self.type == Lexeme.Type.Attribute then
		assert(FastVariables.LuauAttributeSyntax)
		return if self.name then string.format("'%s'", self.name) else "attribute"

	elseif self.type == Lexeme.Type.BrokenString then
		return "malformed string"

	elseif self.type == Lexeme.Type.BrokenComment then
		return "unfinished comment"

	elseif self.type == Lexeme.Type.BrokenInterpDoubleBrace then
		return "'{{', which is invalid (did you mean '\\{'?)"

	elseif self.type == Lexeme.Type.BrokenUnicode then
		if self.codepoint then
			local confusable = Confusables.findConfusable(self.codepoint)
			if confusable then
				return string.format("Unicode character U+%x (did you mean '%s'?)", self.codepoint, confusable)
			end

			return string.format("Unicode character U+%x", self.codepoint)
		else
			return "invalid UTF-8 sequence"
		end

	else
		if (self.type < Lexeme.Type.Char_END) then
			return string.format("'%c'", self.type)
		elseif (self.type >= Lexeme.Type.Reserved_BEGIN and self.type < Lexeme.Type.Reserved_END) then
			return string.format("'%s'", Lexeme.reserved[self.type - Lexeme.Type.Reserved_BEGIN + 1])
		else
			return "<unknown>"
		end
	end
end

return Lexeme