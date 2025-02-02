local AstArgumentName = require("./AstArgumentName")
local AstAttr = require("./AstAttr")
local AstDeclaredClassProp = require("./AstDeclaredClassProp")
local AstExpr = require("./AstExpr")
local AstExprBinary = require("./AstExprBinary")
local AstExprCall = require("./AstExprCall")
local AstExprConstantBool = require("./AstExprConstantBool")
local AstExprConstantNil = require("./AstExprConstantNil")
local AstExprConstantNumber = require("./AstExprConstantNumber")
local AstExprConstantString = require("./AstExprConstantString")
local AstExprError = require("./AstExprError")
local AstExprFunction = require("./AstExprFunction")
local AstExprGlobal = require("./AstExprGlobal")
local AstExprGroup = require("./AstExprGroup")
local AstExprIfElse = require("./AstExprIfElse")
local AstExprIndexExpr = require("./AstExprIndexExpr")
local AstExprIndexName = require("./AstExprIndexName")
local AstExprInterpString = require("./AstExprInterpString")
local AstExprLocal = require("./AstExprLocal")
local AstExprTable = require("./AstExprTable")
local AstExprTypeAssertion = require("./AstExprTypeAssertion")
local AstExprUnary = require("./AstExprUnary")
local AstExprVarargs = require("./AstExprVarargs")
local AstGenericType = require("./AstGenericType")
local AstGenericTypePack = require("./AstGenericTypePack")
local AstLocal = require("./AstLocal")
local AstName = require("./AstName")
local AstNameTable = require("./AstNameTable")
local AstStat = require("./AstStat")
local AstStatAssign = require("./AstStatAssign")
local AstStatBlock = require("./AstStatBlock")
local AstStatBreak = require("./AstStatBreak")
local AstStatCompoundAssign = require("./AstStatCompoundAssign")
local AstStatContinue = require("./AstStatContinue")
local AstStatDeclareClass = require("./AstStatDeclareClass")
local AstStatDeclareFunction = require("./AstStatDeclareFunction")
local AstStatDeclareGlobal = require("./AstStatDeclareGlobal")
local AstStatError = require("./AstStatError")
local AstStatExpr = require("./AstStatExpr")
local AstStatFor = require("./AstStatFor")
local AstStatForIn = require("./AstStatForIn")
local AstStatFunction = require("./AstStatFunction")
local AstStatIf = require("./AstStatIf")
local AstStatLocal = require("./AstStatLocal")
local AstStatLocalFunction = require("./AstStatLocalFunction")
local AstStatRepeat = require("./AstStatRepeat")
local AstStatReturn = require("./AstStatReturn")
local AstStatTypeAlias = require("./AstStatTypeAlias")
local AstStatWhile = require("./AstStatWhile")
local AstTableAccess = require("./AstTableAccess")
local AstTableIndexer = require("./AstTableIndexer")
local AstTableProp = require("./AstTableProp")
local AstType = require("./AstType")
local AstTypeError = require("./AstTypeError")
local AstTypeFunction = require("./AstTypeFunction")
local AstTypeIntersection = require("./AstTypeIntersection")
local AstTypeList = require("./AstTypeList")
local AstTypeOrPack = require("./AstTypeOrPack")
local AstTypePack = require("./AstTypePack")
local AstTypePackExplicit = require("./AstTypePackExplicit")
local AstTypePackGeneric = require("./AstTypePackGeneric")
local AstTypePackVariadic = require("./AstTypePackVariadic")
local AstTypeReference = require("./AstTypeReference")
local AstTypeSingletonBool = require("./AstTypeSingletonBool")
local AstTypeSingletonString = require("./AstTypeSingletonString")
local AstTypeTable = require("./AstTypeTable")
local AstTypeTypeof = require("./AstTypeTypeof")
local AstTypeUnion = require("./AstTypeUnion")
local AstUtilities = require("./AstUtilities")
local Comment = require("./Comment")
local ConstantNumberParseResult = require("./ConstantNumberParseResult")
local FastVariables = require("./FastVariables")
local HotComment = require("./HotComment")
local Lexeme = require("./Lexeme")
local Lexer = require("./Lexer")
local Location = require("./Location")
local NumberUtilities = require("./NumberUtilities")
local Pair = require("./Pair")
local ParseError = require("./ParseError")
local ParseOptions = require("./ParseOptions")
local ParseResult = require("./ParseResult")
local Position = require("./Position")
local TempVector = require("./TempVector")
local TimeTrace = require("./TimeTrace")
local Vector = require("./Vector")

type AstArgumentName = AstArgumentName.AstArgumentName
type AstAttr = AstAttr.AstAttr
type AstDeclaredClassProp = AstDeclaredClassProp.AstDeclaredClassProp
type AstExpr = AstExpr.AstExpr
type AstExprError = AstExprError.AstExprError
type AstExprFunction = AstExprFunction.AstExprFunction
type AstGenericType = AstGenericType.AstGenericType
type AstGenericTypePack = AstGenericTypePack.AstGenericTypePack
type AstName = AstName.AstName
type AstNameTable = AstNameTable.AstNameTable
type AstStat = AstStat.AstStat
type AstStatBlock = AstStatBlock.AstStatBlock
type AstStatError = AstStatError.AstStatError
type AstLocal = AstLocal.AstLocal
type AstTableIndexer = AstTableIndexer.AstTableIndexer
type AstTableProp = AstTableProp.AstTableProp
type AstType = AstType.AstType
type AstTypeError = AstTypeError.AstTypeError
type AstTypeList = AstTypeList.AstTypeList
type AstTypeOrPack = AstTypeOrPack.AstTypeOrPack
type AstTypePack = AstTypePack.AstTypePack
type Comment = Comment.Comment
type HotComment = HotComment.HotComment
type Lexeme = Lexeme.Lexeme
type Lexer = Lexer.Lexer
type Location = Location.Location
type Pair<T1, T2> = Pair.Pair<T1, T2>
type ParseError = ParseError.ParseError
type ParseOptions = ParseOptions.ParseOptions
type ParseResult = ParseResult.ParseResult
type Position = Position.Position
type TempVector<T> = TempVector.TempVector<T>
local unsigned = NumberUtilities.unsigned
type Vector<T> = Vector.Vector<T>

--[=[
	@class Parser
	@__index prototype

	Class from [`/Ast/src/Parser.cpp`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/src/Parser.cpp#L155-L3337) and [`/Ast/include/Luau/Parser.h`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Parser.h#L54-L429).

	Converts lexemes to an abstract syntax tree.
]=]
local prototype = {}
local Parser = {prototype = prototype}
local metatable = {__index = prototype}

--[=[
	@class Parser_BinaryOpPriority
]=]
local BinaryOpPriority = {}

type BinaryOpPriority = {
	left: number,
	right: number
}

--[=[
	@within Parser_BinaryOpPriority
	@function new
	@param left number
	@param right number
	@return Parser_BinaryOpPriority
]=]
function BinaryOpPriority.new(left: number, right: number): BinaryOpPriority
	return {
		left = left,
		right = right
	}
end

--[=[
	@class Parser_MatchLexeme

	Struct from [`/Ast/include/Luau/Parser.h`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Parser.h#L281-L291).
]=]
local MatchLexeme = {}

type MatchLexeme = {
	--[=[
		@within Parser_MatchLexeme
		@prop type number -- (Lexeme type)[Lexeme#Type]
		@readonly
		@since v0.1.0
	]=]
	type: number,

	--[=[
		@within Parser_MatchLexeme
		@prop position Position
		@readonly
		@since v0.1.0
	]=]
	position: Position
}

--[=[
	@within Parser_MatchLexeme
	@function new
	@param l Lexeme
	@return Parser_MatchLexeme
]=]
function MatchLexeme.new(l: Lexeme): MatchLexeme
	return {
		type = l.type,
		position = l.location.begin
	}
end

--[=[
	@class Parser_Function
	Struct from `root/Ast/include/Luau/Parser.h`.
]=]
local Function = {}

type Function = {
	--[=[
		@within Parser_Function
		@prop vararg boolean
		@since v0.1.0
	]=]
	vararg: boolean,

	--[=[
		@within Parser_Function
		@prop loopDepth number
		@since v0.1.0
	]=]
	loopDepth: number
}

--[=[
	@within Parser_Function
	@function new
	@return Parser_Function
	Initialised to
	
	```lua
	{
		vararg = false,
		loopDepth = 0
	}
	```
]=]
function Function.new(): Function
	return {
		vararg = false,
		loopDepth = 0
	}
end

--[=[
	@class Parser_Name

	Struct from [`/Ast/include/Luau/Parser.h`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Parser.h#L358-L368).
]=]
local Name = {}

type Name = {
	--[=[
		@within Parser_Name
		@prop name AstName
		@readonly
		@since v0.1.0
	]=]
	name: AstName,

	--[=[
		@within Parser_Name
		@prop location Location
		@readonly
		@since v0.1.0
	]=]
	location: Location
}

--[=[
	@within Parser_Name
	@function new
	@param name AstName
	@param location Location
	@return Parser_Name
]=]
function Name.new(name: AstName, location: Location): Name
	return {
		name = name,
		location = location
	}
end

--[=[
	@class Parser_Binding

	Struct from [`/Ast/include/Luau/Parser.h`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Parser.h#L370-380).

	Represents variable declarations with type.
	
	For example:

	```lua
	local variable: type
	```
]=]
local Binding = {}

type Binding = {
	--[=[
		@within Parser_Binding
		@prop name Name
		@since v0.1.0
	]=]
	name: Name,

	--[=[
		@within Parser_Binding
		@prop annotation AstType
		@since v0.1.0
	]=]
	annotation: AstType?
}

--[=[
	@within Parser_Binding
	@since v0.1.0
]=]
function Binding.new(name: Name, annotation: AstType?): Binding
	return {
		name = name,
		annotation = annotation
	}
end

type AttributeEntry = {
	name: string,
	type: number
}
local kAttributeEntries: {AttributeEntry} = {
	{
		name = "@checked",
		type = AstAttr.Type.Checked
	},
	{
		name = "@native",
		type = AstAttr.Type.Native
	}
}

--[=[
	@within Parser
	@private
	@since v0.1.0
	@tag local

	Useful for when there are multiple return statements in the same function.
]=]
local function destroy(vectors: {TempVector<any>}): ()
	for _, vector in vectors do
		vector:destroy()
	end
end

--[=[
	@within Parser
	@private
	@since v0.1.0
	@tag local
]=]
local function shouldParseTypePack(lexer: Lexer): boolean
	if lexer:current().type == Lexeme.Type.Dot3 then
		return true
	elseif lexer:current().type == Lexeme.Type.Name and lexer:lookahead().type == Lexeme.Type.Dot3 then
		return true
	end

	return false
end

--[=[
	@within Parser
	@since v0.1.0
	
	The primary function of this module which creates a parser and returns its results in a nice table for you.
]=]
function Parser.parse(buffer: string, bufferSize: number, names: AstNameTable, options: ParseOptions): ParseResult
	TimeTrace.LUAU_TIMETRACE_SCOPE("Parser::parse", "Parser")

	local p = Parser.new(buffer, bufferSize, names, options)

	local _, result = xpcall(
		function()
			local root = p:parseChunk()
			local lines = p.lexer:current().location.finish.line + (if bufferSize > 0 and string.sub(buffer, bufferSize, bufferSize) ~= "\n" then 1 else 0)

			return ParseResult.new(root, lines, p.hotcomments, p.parseErrors, p.commentLocations)
		end,
		function(err: ParseResult | string)
			-- when catching a fatal error, append it to the list of non-fatal errors and return
			if type(err) == "string" then
				-- Eli: Runtime error.
				p.parseErrors:push_back(ParseError.new(Location.new(), err))
			else
				p.parseErrors:push_back(err)
			end
			
			return ParseResult.new(nil, 0, nil, p.parseErrors)
		end
	)
	return result
end

local kParseNameError = "%error-id%"

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function Parser.new(buffer: string, bufferSize: number, names: AstNameTable, options: ParseOptions)
	local self = setmetatable({
		options = options,

		lexer = Lexer.new(buffer, bufferSize, names),
		
		commentLocations = Vector.new() :: Vector<Comment>,
		hotcomments = Vector.new() :: Vector<HotComment>,

		hotcommentHeader = true,

		recursionCounter = 0,

		endMismatchSuspect = MatchLexeme.new(Lexeme.new(Location.new(), Lexeme.Type.Eof)),

		functionStack = Vector.new(),

		localMap = {} :: {
			[AstName]: AstLocal
		},
		localStack = Vector.new(),

		parseErrors = Vector.new(),

		matchRecoveryStopOnToken = Vector.new(),

		scratchAttr = Vector.new(),
		scratchStat = Vector.new(),
		scratchString = Vector.new(),
		scratchExpr = Vector.new(),
		scratchExprAux = Vector.new(),
		scratchName = Vector.new(),
		scratchPackName = Vector.new(),
		scratchBinding = Vector.new(),
		scratchLocal = Vector.new(),
		scratchTableTypeProps = Vector.new(),
		scratchType = Vector.new(),
		scratchTypeOrPack = Vector.new(),
		scratchDeclaredClassProps = Vector.new(),
		scratchItem = Vector.new(),
		scratchArgName = Vector.new(),
		scratchGenericTypes = Vector.new(),
		scratchGenericTypePacks = Vector.new(),
		scratchOptArgName = Vector.new(),
		scratchData = ""
	}, metatable)

	local top = Function.new()
	top.vararg = true

	self.functionStack:reserve(8)
	self.functionStack:push_back(top)

	self.nameSelf = names:addStatic("self", nil :: any)
	self.nameNumber = names:addStatic("number", nil :: any)
	self.nameError = names:addStatic(kParseNameError, nil :: any)
	self.nameNil = names:getOrAdd("nil") -- nil is a reserved keyword

	self.matchRecoveryStopOnToken:assign(Lexeme.Type.Reserved_END, 0)
	self.matchRecoveryStopOnToken:set(Lexeme.Type.Eof, 1)
	
	-- required for lookahead() to work across a comment boundary and for nextLexeme() to work when captureComments is false
	self.lexer:setSkipComments(true)
	
	-- read first lexeme (any hot comments get .header = true)
	assert(self.hotcommentHeader)
	;(self :: any):nextLexeme() -- Eli NEW_SOLVER
	
	-- all hot comments parsed after the first non-comment lexeme are special in that they don't affect type checking / linting mode
	self.hotcommentHeader = false
	
	-- preallocate some buffers that are very likely to grow anyway; this works around std::vector's inefficient growth policy for small arrays
	self.localStack:reserve(16)
	self.scratchStat:reserve(16)
	self.scratchExpr:reserve(16)
	self.scratchLocal:reserve(16)
	self.scratchBinding:reserve(16)
	
	return self
end
type Parser = typeof(Parser.new(...))

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.blockFollow(self: Parser, l: Lexeme.Lexeme): boolean
	return
		l.type == Lexeme.Type.Eof
		or l.type == Lexeme.Type.ReservedElse
		or l.type == Lexeme.Type.ReservedElseif
		or l.type == Lexeme.Type.ReservedEnd
		or l.type == Lexeme.Type.ReservedUntil
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseChunk(self: Parser): AstStatBlock
	local result = self:parseBlock()

	if self.lexer:current().type ~= Lexeme.Type.Eof then
		self:expectAndConsumeFail(Lexeme.Type.Eof, nil)
	end

	return result
end

-- chunk ::= {stat [`;']} [laststat [`;']]
-- block ::= chunk
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseBlock(self: Parser): AstStatBlock
	local localsBegin = self:saveLocals()

	local result = self:parseBlockNoScope()

	self:restoreLocals(localsBegin)

	return result
end

--[=[
	@within Parser
	@private
	@since v0.1.0
	@tag local
]=]
local function isStatLast(stat: AstStat): boolean
	return stat:is(AstStatBreak) or stat:is(AstStatContinue) or stat:is(AstStatReturn)
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseBlockNoScope(self: Parser): AstStatBlock
	local body = TempVector.new(self.scratchStat)

	local prevPosition = self.lexer:previousLocation().finish

	while not self:blockFollow(self.lexer:current()) do
		local oldRecursionCount = self.recursionCounter

		self:incrementRecursionCounter("block")

		local stat = self:parseStat()

		self.recursionCounter = oldRecursionCount

		if self.lexer:current().type == (";"):byte() then
			self:nextLexeme()
			stat.hasSemicolon = true
		end

		body:push_back(stat)

		if isStatLast(stat) then
			break
		end
	end

	local location = Location.new(prevPosition, self.lexer:current().location.begin)

	local result = AstStatBlock.new(location, self:copy(body))

	body:destroy()

	return result
end

-- stat ::=
-- varlist `=' explist |
-- functioncall |
-- do block end |
-- while exp do block end |
-- repeat block until exp |
-- if exp then block {elseif exp then block} [else block] end |
-- for binding `=' exp `,' exp [`,' exp] do block end |
-- for namelist in explist do block end |
-- function funcname funcbody |
-- attributes function funcname funcbody |
-- local function Name funcbody |
-- local attributes function Name funcbody |
-- local namelist [`=' explist]
-- laststat ::= return [explist] | break
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseStat(self: Parser): AstStat
	-- guess the type from the token type
	local case = self.lexer:current().type
	if case == Lexeme.Type.ReservedIf then
		return self:parseIf()
	elseif case == Lexeme.Type.ReservedWhile then
		return self:parseWhile()
	elseif case == Lexeme.Type.ReservedDo then
		return self:parseDo()
	elseif case == Lexeme.Type.ReservedFor then
		return self:parseFor()
	elseif case == Lexeme.Type.ReservedRepeat then
		return self:parseRepeat()
	elseif case == Lexeme.Type.ReservedFunction then
		return self:parseFunctionStat({AstAttr.new(nil, AstAttr.Type.Checked)})
	elseif case == Lexeme.Type.ReservedLocal then
		return self:parseLocal({AstAttr.new(nil, AstAttr.Type.Checked)})
	elseif case == Lexeme.Type.ReservedReturn then
		return self:parseReturn()
	elseif case == Lexeme.Type.ReservedBreak then
		return self:parseBreak()
	elseif case == Lexeme.Type.Attribute then
		if FastVariables.LuauAttributeSyntax then
			return self:parseAttributeStat()
		end
	end

	local start = self.lexer:current().location

	-- we need to disambiguate a few cases, primarily assignment (lvalue = ...) vs statements-that-are calls
	local expr = self:parsePrimaryExpr(--[[ asStatement= ]] true)

	if expr:is(AstExprCall) then
		return AstStatExpr.new(expr.location, expr)
	end

	-- if the next token is , or =, it's an assignment (, means it's an assignment with multiple variables)
	if self.lexer:current().type == (","):byte() or self.lexer:current().type == ("="):byte() then
		return self:parseAssignment(expr)
	end

	-- if the next token is a compound assignment operator, it's a compound assignment (these don't support multiple variables)
	local op = self:parseCompoundOp(self.lexer:current())
	if op then
		return self:parseCompoundAssignment(expr, op)
	end

	-- we know this isn't a call or an assignment; therefore it must be a context-sensitive keyword such as `type` or `continue`
	local ident = AstUtilities.getIdentifier(expr)

	if ident.value == "type" then
		return self:parseTypeAlias(expr.location, --[[ exported= ]] false)
	end

	if ident.value == "export" and self.lexer:current().type == Lexeme.Type.Name and self.lexer:current().name == "type" then
		self:nextLexeme()
		return self:parseTypeAlias(expr.location, --[[ exported= ]] true)
	end

	if ident.value == "continue" then
		return self:parseContinue(expr.location)
	end

	if self.options.allowDeclarationSyntax then
		if ident.value == "declare" then
			return self:parseDeclaration(expr.location, {AstAttr.new(nil, AstAttr.Type.Checked)})
		end
	end

	-- skip unexpected symbol if lexer couldn't advance at all (statements are parsed in a loop)
	if start == self.lexer:current().location then
		self:nextLexeme()
	end

	return self:reportStatError(expr.location, {expr}, {}, "Incomplete statement: expected assignment or a function call")
end

-- if exp then block {elseif exp then block} [else block] end
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseIf(self: Parser): AstStat
	local start = self.lexer:current().location

	self:nextLexeme() -- // if / elseif

	local cond = self:parseExpr()

	local matchThen = self.lexer:current()
	local thenLocation: Location?
	if self:expectAndConsume(Lexeme.Type.ReservedThen, "if statement") then
		thenLocation = matchThen.location
	end

	local thenbody = self:parseBlock()

	local elsebody: AstStat
	local endLocation = start
	local elseLocation: Location?

	if self.lexer:current().type == Lexeme.Type.ReservedElseif then
		thenbody.hasEnd = true
		local oldRecursionCount = self.recursionCounter
		self:incrementRecursionCounter("elseif")
		elseLocation = self.lexer:current().location
		elsebody = self:parseIf()
		endLocation = elsebody.location
		self.recursionCounter = oldRecursionCount
	else
		local matchThenElse = matchThen

		if self.lexer:current().type == Lexeme.Type.ReservedElse then
			thenbody.hasEnd = true
			elseLocation = self.lexer:current().location
			matchThenElse = self.lexer:current()
			self:nextLexeme()

			elsebody = self:parseBlock()
			elsebody.location.begin = matchThenElse.location.finish
		end

		endLocation = self.lexer:current().location
		
		local hasEnd = self:expectMatchEndAndConsume(Lexeme.Type.ReservedEnd, matchThenElse)

		if elsebody then
			local elseBlock = elsebody:as(AstStatBlock)
			if elseBlock then
				elseBlock.hasEnd = hasEnd
			end
		else
			thenbody.hasEnd = hasEnd
		end
	end

	return AstStatIf.new(Location.new(start, endLocation), cond, thenbody, elsebody, thenLocation, elseLocation)
end

-- while exp do block end
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseWhile(self: Parser): AstStat
	local start = self.lexer:current().location

	self:nextLexeme() -- while

	local cond = self:parseExpr()

	local matchDo = self.lexer:current()
	local hasDo = self:expectAndConsume(Lexeme.Type.ReservedDo, "while loop")
	
	self.functionStack:back().loopDepth += 1

	local body = self:parseBlock()

	self.functionStack:back().loopDepth -= 1

	local endLocation = self.lexer:current().location
	
	local hasEnd = self:expectMatchEndAndConsume(Lexeme.Type.ReservedEnd, matchDo)
	body.hasEnd = hasEnd

	return AstStatWhile.new(Location.new(start, endLocation), cond, body, hasDo, matchDo.location)
end

-- repeat block until exp
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseRepeat(self: Parser): AstStat
	local start = self.lexer:current().location

	local matchRepeat = self.lexer:current()
	self:nextLexeme() -- repeat

	local localsBegin = self:saveLocals()

	self.functionStack:back().loopDepth += 1

	local body = self:parseBlockNoScope()

	self.functionStack:back().loopDepth -= 1

	local hasUntil = self:expectMatchEndAndConsume(Lexeme.Type.ReservedUntil, matchRepeat)
	body.hasEnd = hasUntil

	local cond = self:parseExpr()

	self:restoreLocals(localsBegin)

	return AstStatRepeat.new(Location.new(start, cond.location), cond, body)
end

-- do block end
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseDo(self: Parser): AstStat
	local start = self.lexer:current().location

	local matchDo = self.lexer:current()
	self:nextLexeme() -- do

	local body = self:parseBlock()

	body.location.begin = start.begin

	body.hasEnd = self:expectMatchEndAndConsume(Lexeme.Type.ReservedEnd, matchDo)

	return body
end

-- break
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseBreak(self: Parser): AstStat
	local start = self.lexer:current().location

	self:nextLexeme() -- break

	if self.functionStack:back().loopDepth == 0 then
		return self:reportStatError(start, {}, AstStatBreak.new(start), "break statement must be inside a loop")
	end

	return AstStatBreak.new(start)
end

-- continue
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseContinue(self: Parser, start: Location): AstStat
	if self.functionStack:back().loopDepth == 0 then
		return self:reportStatError(start, {}, AstStatContinue.new(start), "continue statement must be inside a loop")
	end

	-- note: the token is already parsed for us!

	return AstStatContinue.new(start)
end

-- for binding `=' exp `,' exp [`,' exp] do block end |
-- for bindinglist in explist do block end |
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseFor(self: Parser): AstStat
	local start = self.lexer:current().location

	self:nextLexeme() -- for

	local varname = self:parseBinding()

	if self.lexer:current().type == ("="):byte() then
		self:nextLexeme()

		local from = self:parseExpr()

		self:expectAndConsume(",", "index range")

		local to = self:parseExpr()

		local step: AstExpr?

		if self.lexer:current().type == (","):byte() then
			self:nextLexeme()

			step = self:parseExpr()
		end

		local matchDo = self.lexer:current()
		local hasDo = self:expectAndConsume(Lexeme.Type.ReservedDo, "for loop")

		local localsBegin = self:saveLocals()

		self.functionStack:back().loopDepth += 1

		local var = self:pushLocal(varname)

		local body = self:parseBlock()

		self.functionStack:back().loopDepth -= 1

		self:restoreLocals(localsBegin)

		local endLocation = self.lexer:current().location

		local hasEnd = self:expectMatchEndAndConsume(Lexeme.Type.ReservedEnd, matchDo)
		body.hasEnd = hasEnd

		return AstStatFor.new(Location.new(start, endLocation), var, from, to, step, body, hasDo, matchDo.location)
	else
		local names = TempVector.new(self.scratchBinding)
		names:push_back(varname)

		if self.lexer:current().type == (","):byte() then
			self:nextLexeme()

			self:parseBindingList(names)
		end

		local inLocation = self.lexer:current().location
		local hasIn = self:expectAndConsume(Lexeme.Type.ReservedIn, "for loop")

		local values = TempVector.new(self.scratchExpr)
		self:parseExprList(values)

		local matchDo = self.lexer:current()
		local hasDo = self:expectAndConsume(Lexeme.Type.ReservedDo, "for loop")

		local localsBegin = self:saveLocals()
		
		self.functionStack:back().loopDepth += 1

		local vars = TempVector.new(self.scratchLocal)

		for i = 1, names:size() do
			vars:push_back(self:pushLocal(names:get(i)))
		end

		local body = self:parseBlock()

		self.functionStack:back().loopDepth -= 1

		self:restoreLocals(localsBegin)

		local endLocation = self.lexer:current().location

		local hasEnd = self:expectMatchEndAndConsume(Lexeme.Type.ReservedEnd, matchDo)
		body.hasEnd = hasEnd

		local result = AstStatForIn.new(Location.new(start, endLocation), self:copy(vars), self:copy(values), body, hasIn, inLocation, hasDo, matchDo.location)

		names:destroy()
		values:destroy()
		vars:destroy()

		return result
	end
end

-- funcname ::= Name {`.' Name} [`:' Name]
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseFunctionName(self: Parser, start: Location): {hasself: boolean, debugname: AstName, expr: AstExpr}
	local hasself = false
	local debugname: AstName

	if self.lexer:current().type == Lexeme.Type.Name then
		debugname = AstName.new(self.lexer:current().name)
	end

	-- parse funcname into a chain of indexing operators
	local expr = self:parseNameExpr("function name")
	
	local oldRecursionCount = self.recursionCounter

	while self.lexer:current().type == ("."):byte() do
		local opPosition = self.lexer:current().location.begin
		self:nextLexeme()

		local name = self:parseName("field name")

		-- while we could concatenate the name chain, for now let's just write the short name
		debugname = name.name

		expr = AstExprIndexName.new(Location.new(start, name.location), expr, name.name, name.location, opPosition, ".")

		-- note: while the parser isn't recursive here, we're generating recursive structures of unbounded depth
		self:incrementRecursionCounter("function name")
	end

	self.recursionCounter = oldRecursionCount

	-- finish with :
	if self.lexer:current().type == (":"):byte() then
		local opPosition = self.lexer:current().location.begin
		self:nextLexeme()

		local name = self:parseName("method name")

		-- while we could concatenate the name chain, for now let's just write the short name
		debugname = name.name

		expr = AstExprIndexName.new(Location.new(start, name.location), expr, name.name, name.location, opPosition, ":")

		hasself = true
	end
	
	return {
		expr = expr,
		hasself = hasself,
		debugname = debugname
	}
end

-- function funcname funcbody
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseFunctionStat(self: Parser, attributes: {AstAttr}): AstStat
	local start = self.lexer:current().location

	local matchFunction = self.lexer:current()
	self:nextLexeme()

	local results = self:parseFunctionName(start)
	local hasself = results.hasself
	local debugname = results.debugname
	local expr = results.expr

	self.matchRecoveryStopOnToken:set_increment(Lexeme.Type.ReservedEnd)

	local body = self:parseFunctionBody(hasself, matchFunction, debugname, nil, attributes).first

	self.matchRecoveryStopOnToken:set_decrement(Lexeme.Type.ReservedEnd)

	return AstStatFunction.new(Location.new(start, body.location), expr, body)
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.validateAttribute(self: Parser, attributeName: string, attributes: TempVector<AstAttr>): Pair<boolean, number>
	assert(FastVariables.LuauAttributeSyntax)

	local typeAttr: number

	-- check if the attribute name is valid

	local found = false

	for _, entry in kAttributeEntries do
		found = attributeName == entry.name
		if found then
			typeAttr = entry.type

			if not FastVariables.LuauNativeAttribute and typeAttr == AstAttr.Type.Native then
				found = false
			end

			break
		end
	end

	if not found then
		if #attributeName == 1 then
			self:report(self.lexer:current().location, "Attribute name is missing")
		else
			self:report(self.lexer:current().location, "Invalid attribute '%s'", attributeName)
		end
	else
		-- check that attribute is not duplicated
		for _, attr in attributes do
			if attr.type == typeAttr then
				self:report(self.lexer:current().location, "Cannot duplicate attribute '%s'", attributeName)
			end
		end
	end

	return Pair.new(found, typeAttr)
end

-- attribute ::= '@' NAME
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseAttribute(self: Parser, attributes: TempVector<AstAttr>): ()
	assert(FastVariables.LuauAttributeSyntax)

	assert(self.lexer:current().type == Lexeme.Type.Attribute)

	local loc = self.lexer:current().location

	local name = self.lexer:current().name
	assert(name)
	
	local results = self:validateAttribute(name, attributes)
	local found = results.first
	local typeAttr = results.second

	self:nextLexeme()

	if found then
		attributes:push_back(AstAttr.new(loc, typeAttr))
	end
end

-- attributes ::= {attribute}
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseAttributes(self: Parser): {AstAttr}
	assert(FastVariables.LuauAttributeSyntax)

	local typeLex = self.lexer:current().type

	assert(typeLex == Lexeme.Type.Attribute)

	local attributes = TempVector.new(self.scratchAttr)

	while self.lexer:current().type == Lexeme.Type.Attribute do
		self:parseAttribute(attributes)
	end

	local result = self:copy(attributes)

	attributes:destroy()

	return result
end

-- attributes local function Name funcbody
-- attributes function funcname funcbody
-- attributes `declare function' Name`(' [parlist] `)' [`:` Type]
-- declare Name '{' Name ':' attributes `(' [parlist] `)' [`:` Type] '}'
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseAttributeStat(self: Parser): AstStat
	assert(FastVariables.LuauAttributeSyntax)

	local attributes = self:parseAttributes()

	local typeLex = self.lexer:current().type

	if typeLex == Lexeme.Type.ReservedFunction then
		return self:parseFunctionStat(attributes)
	elseif typeLex == Lexeme.Type.ReservedLocal then
		return self:parseLocal(attributes)
	elseif typeLex == Lexeme.Type.Name then
		if self.options.allowDeclarationSyntax and self.lexer:current().data ~= "declare" then
			local expr = self:parsePrimaryExpr(--[[ asStatement= ]] true)
			return self:parseDeclaration(expr.location, attributes)
		end
	else
		return self:reportStatError(self.lexer:current().location, {}, {}, "Expected 'function', 'local function', 'declare function' or a function type declaration after attribute, but got %s intead", self.lexer:current():toString())
	end
end

-- local function Name funcbody |
-- local bindinglist [`=' explist]
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseLocal(self: Parser, attributes: {AstAttr}): AstStat
	local start = self.lexer:current().location

	self:nextLexeme() -- local

	if self.lexer:current().type == Lexeme.Type.ReservedFunction then
		local matchFunction = self.lexer:current()
		self:nextLexeme()

		-- matchFunction is only used for diagnostics; to make it suitable for detecting missed indentation between
		-- `local function` and `end`, we patch the token to begin at the column where `local` starts
		if matchFunction.location.begin.line == start.begin.line then
			matchFunction.location.begin.column = start.begin.column
		end

		local name = self:parseName("variable name")

		self.matchRecoveryStopOnToken:set_increment(Lexeme.Type.ReservedEnd)

		local results = self:parseFunctionBody(false, matchFunction, name.name, name, attributes)
		local body = results.first
		local var = results.second

		self.matchRecoveryStopOnToken:set_decrement(Lexeme.Type.ReservedEnd)

		local location = Location.new(start.begin, body.location.finish)

		return AstStatLocalFunction.new(location, var, body)
	else
		if FastVariables.LuauAttributeSyntax and #attributes ~= 0 then
			return self:reportStatError(self.lexer:current().location, {}, {}, "Expected 'function' after local declaration with attribute, but got %s intead", self.lexer:current():toString())
		end

		self.matchRecoveryStopOnToken:set_increment(("="):byte())

		local names = TempVector.new(self.scratchBinding)
		self:parseBindingList(names)

		self.matchRecoveryStopOnToken:set_decrement(("="):byte())

		local vars = TempVector.new(self.scratchLocal)

		local values = TempVector.new(self.scratchExpr)

		local equalsSignLocation: Location?

		if self.lexer:current().type == ("="):byte() then
			equalsSignLocation = self.lexer:current().location

			self:nextLexeme()

			self:parseExprList(values)
		end

		for i = 1, names:size() do
			vars:push_back(self:pushLocal(names:get(i)))
		end

		local endLocation = if values:empty() then self.lexer:previousLocation() else values:back().location

		local result = AstStatLocal.new(Location.new(start, endLocation), self:copy(vars), self:copy(values), equalsSignLocation)

		names:destroy()
		vars:destroy()
		values:destroy()

		return result
	end
end

-- return [explist]
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseReturn(self: Parser): AstStat
	local start = self.lexer:current().location

	self:nextLexeme()

	local list = TempVector.new(self.scratchExpr)

	if not self:blockFollow(self.lexer:current()) and self.lexer:current().type ~= (";"):byte() then
		self:parseExprList(list)
	end

	local endLocation = if list:empty() then start else list:back().location

	local result = AstStatReturn.new(Location.new(start, endLocation), self:copy(list))

	list:destroy()

	return result
end

-- type Name [`<' varlist `>'] `=' Type
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseTypeAlias(self: Parser, start: Location.Location, exported: boolean): AstStat
	-- note: `type` token is already parsed for us, so we just need to parse the rest

	local name = self:parseNameOpt("type name")

	-- Use error name if the name is missing
	if not name then
		name = Name.new(self.nameError, self.lexer:current().location)
	end

	local results = self:parseGenericTypeList(--[[ withDefaultValues= ]] true)
	local generics = results.first
	local genericPacks = results.second

	self:expectAndConsume("=", "type alias")

	local typeAst = self:parseType()

	return AstStatTypeAlias.new(Location.new(start, typeAst.location), name.name, name.location, generics, genericPacks, typeAst, exported)
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseDeclaredClassMethod(self: Parser): AstDeclaredClassProp
	self:nextLexeme()
	local start = self.lexer:current().location
	local fnName = self:parseName("function name")
	
	-- TODO: generic method declarations CLI-39909
	local generics = {}
	local genericPacks = {}

	local matchParen = self.lexer:current()
	self:expectAndConsume("(", "function parameter list start")

	local args = TempVector.new(self.scratchBinding)

	local vararg = false
	local _varargLocation -- Eli: Not sure what this is for.
	local varargAnnotation
	if self.lexer:current().type ~= (")"):byte() then
		local results = self:parseBindingList(args, --[[ allowDot3 ]] true)
		vararg = results.vararg
		_varargLocation = results.varargLocation
		varargAnnotation = results.varargAnnotation
	end

	self:expectMatchAndConsume(")", matchParen)

	local retTypes = self:parseOptionalReturnType() or AstTypeList.new({}, nil)
	local endLocation = self.lexer:current().location

	local vars = TempVector.new(self.scratchType)
	local varNames = TempVector.new(self.scratchOptArgName)

	if args:size() == 0 or args:get(1).name.name ~= "self" or args:get(1).annotation ~= nil then
		return AstDeclaredClassProp.new(fnName.name, self:reportTypeError(Location.new(start, endLocation), {}, "'self' must be present as the unannotated first parameter"), true)
	end

	-- Skip the first index.
	for i = 2, args:size() do
		varNames:push_back(AstArgumentName.new(args:get(i).name.name, args:get(i).name.location))

		if args:get(i).annotation then
			vars:push_back(args:get(i).annotation)
		else
			vars:push_back(self:reportTypeError(Location.new(start, endLocation), {}, "All declaration parameters aside from 'self' must be annotated"))
		end
	end

	if vararg and not varargAnnotation then
		self:report(start, "All declaration parameters aside from 'self' must be annotated")
	end

	local fnType = AstTypeFunction.new(Location.new(start, endLocation), generics, genericPacks, AstTypeList.new(self:copy(vars), varargAnnotation), self:copy(varNames), retTypes)

	local result = AstDeclaredClassProp.new(fnName.name, fnType, true)

	args:destroy()
	vars:destroy()
	varNames:destroy()

	return result
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseDeclaration(self: Parser, start: Location.Location, attributes: {AstAttr}): AstStat
	-- `declare` token is already parsed at this point

	if FastVariables.LuauAttributeSyntax and #attributes ~= 0 and self.lexer:current().type ~= Lexeme.Type.ReservedFunction then
		return self:reportStatError(self.lexer:current().location, {}, {}, "Expected a function type declaration after attribute, but got %s intead", self.lexer:current():toString())
	end

	if self.lexer:current().type == Lexeme.Type.ReservedFunction then
		self:nextLexeme()

		local globalName = self:parseName("global function name")
		
		local results = self:parseGenericTypeList(--[[ withDefaultValues= ]] false)
		local generics = results.first
		local genericPacks = results.second

		local matchParen = self.lexer:current()

		self:expectAndConsume("(", "global function declaration")

		local args = TempVector.new(self.scratchBinding)

		local vararg = false
		local _varargLocation -- Eli: Not sure what this is for. 
		local varargAnnotation

		if self.lexer:current().type ~= (")"):byte() then
			local results2 = self:parseBindingList(args, --[[ allowDot3= ]] true)
			vararg = results2.vararg
			_varargLocation = results2.varargLocation
			varargAnnotation = results2.varargAnnotation
		end

		self:expectMatchAndConsume(")", matchParen)

		local retTypes = self:parseOptionalReturnType() or AstTypeList.new({}, nil)
		local endLocation = self.lexer:current().location

		local vars = TempVector.new(self.scratchType)
		local varNames = TempVector.new(self.scratchArgName)

		local vectors = {args, vars, varNames}

		for i = 1, args:size() do
			if not args:get(i).annotation then
				destroy(vectors)
				return self:reportStatError(Location.new(start, endLocation), {}, {}, "All declaration parameters must be annotated")
			end

			vars:push_back(args:get(i).annotation)
			varNames:push_back(AstArgumentName.new(args:get(i).name.name, args:get(i).name.location))
		end

		if vararg and not varargAnnotation then
			destroy(vectors)
			return self:reportStatError(Location.new(start, endLocation), {}, {}, "All declaration parameters must be annotated")
		end

		local result = AstStatDeclareFunction.new(Location.new(start, endLocation), attributes, globalName.name, generics, genericPacks, AstTypeList.new(self:copy(vars), varargAnnotation), self:copy(varNames), retTypes)
		
		destroy(vectors)

		return result
	elseif self.lexer:current().name == "class" then
		self:nextLexeme()
		local classStart = self.lexer:current().location
		local className = self:parseName("class name")
		local superName: AstName

		if self.lexer:current().name == "extends" then
			self:nextLexeme()
			superName = self:parseName("superclass name").name
		end

		local props = TempVector.new(self.scratchDeclaredClassProps)
		local indexer: AstTableIndexer

		while self.lexer:current().type ~= Lexeme.Type.ReservedEnd do
			-- There are two possibilities: Either it's a property or a function.
			if self.lexer:current().type == Lexeme.Type.ReservedFunction then
				props:push_back(self:parseDeclaredClassMethod())
			elseif self.lexer:current().type == ("["):byte() and (
				self.lexer:lookahead().type == Lexeme.Type.RawString  or self.lexer:lookahead().type == Lexeme.Type.QuotedString
			) then
				local begin = self.lexer:current()
				self:nextLexeme() -- [

				local chars = self:parseCharArray()

				self:expectMatchAndConsume("]", begin)
				self:expectAndConsume(":", "property type annotation")
				local typeAst = self:parseType()

				-- since AstName contains a char*, it can't contain null
				local containsNull = chars and chars:find("\0")

				if chars and not containsNull then
					props:push_back(AstDeclaredClassProp.new(AstName.new(chars), typeAst, false))
				else
					self:report(begin.location, "String literal contains malformed escape sequence or \\0")
				end
			elseif self.lexer:current().type == ("["):byte() then
				if indexer then
					-- maybe we don't need to parse the entire badIndexer...
					-- however, we either have { or [ to lint, not the entire table type or the bad indexer.
					local badIndexer = self:parseTableIndexer(AstTableAccess.ReadWrite, nil)

					-- we lose all additional indexer expressions from the AST after error recovery here
					self:report(badIndexer.location, "Cannot have more than one class indexer")
				else
					indexer = self:parseTableIndexer(AstTableAccess.ReadWrite, nil)
				end
			else
				local propName = self:parseName("property name")
				self:expectAndConsume(":", "property type annotation")
				local propType = self:parseType()
				props:push_back(AstDeclaredClassProp.new(propName.name, propType, false))
			end
		end

		local classEnd = self.lexer:current().location
		self:nextLexeme() -- skip past `end`

		local result = AstStatDeclareClass.new(Location.new(classStart, classEnd), className.name, superName, self:copy(props), indexer)

		props:destroy()

		return result
	else local globalName = self:parseNameOpt("global variable name"); if globalName then
		self:expectAndConsume(":", "global variable declaration")

		local typeAst = self:parseType(--[[ in declaration context ]] true)
		return AstStatDeclareGlobal.new(Location.new(start, typeAst.location), globalName.name, typeAst)
	else
		return self:reportStatError(start, {}, {}, "declare must be followed by an identifier, 'function', or 'class'")
	end end
end

local function isExprLValue(expr: AstExpr): boolean
	return expr:is(AstExprLocal) or expr:is(AstExprGlobal) or expr:is(AstExprIndexExpr) or expr:is(AstExprIndexName)
end

-- varlist `=' explist
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseAssignment(self: Parser, initial: AstExpr): AstStat
	if not isExprLValue(initial) then
		initial = self:reportExprError(initial.location, {initial}, "Assigned expression must be a variable or a field")
	end

	local vars = TempVector.new(self.scratchExpr)
	vars:push_back(initial)

	while self.lexer:current().type == (","):byte() do
		self:nextLexeme()

		local expr = self:parsePrimaryExpr(--[[ asStatement= ]] true)

		if not isExprLValue(expr) then
			expr = self:reportExprError(expr.location, {expr}, "Assigned expression must be a variable or a field")
		end

		vars:push_back(expr)
	end

	self:expectAndConsume("=", "assignment")

	local values = TempVector.new(self.scratchExprAux)
	self:parseExprList(values)

	local result = AstStatAssign.new(Location.new(initial.location, values:back().location), self:copy(vars), self:copy(values))

	vars:destroy()
	values:destroy()
	
	return result
end

-- var [`+=' | `-=' | `*=' | `/=' | `%=' | `^=' | `..='] exp
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseCompoundAssignment(self: Parser, initial: AstExpr, op: number): AstStat
	if not isExprLValue(initial) then
		initial = self:reportExprError(initial.location, {initial}, "Assigned expression must be a variable or a field")
	end

	self:nextLexeme()

	local value = self:parseExpr()

	return AstStatCompoundAssign.new(Location.new(initial.location, value.location), op, initial, value)
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.prepareFunctionArguments(self: Parser, start: Location, hasself: boolean, args: TempVector<Binding>): Pair<AstLocal, {AstLocal}>
	local selfLocal: AstLocal

	if hasself then
		selfLocal = self:pushLocal(Binding.new(Name.new(self.nameSelf, start), nil))
	end

	local vars = TempVector.new(self.scratchLocal)

	for i = 1, args:size() do
		vars:push_back(self:pushLocal(args:get(i)))
	end

	local result = Pair.new(selfLocal, self:copy(vars))

	vars:destroy()

	return result
end

-- funcbody ::= `(' [parlist] `)' [`:' ReturnType] block end
-- parlist ::= bindinglist [`,' `...'] | `...'
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseFunctionBody(self: Parser, hasself: boolean, matchFunction: Lexeme.Lexeme, debugname: AstName, localName: Name?, attributes: {AstAttr}): Pair<AstExprFunction, AstLocal>
	local start = matchFunction.location

	local results = self:parseGenericTypeList(--[[ withDefaultValues= ]] false)
	local generics = results.first
	local genericPacks = results.second

	local matchParen = self.lexer:current()
	self:expectAndConsume("(", "function")

	local args = TempVector.new(self.scratchBinding)

	local vararg = false
	local varargLocation: Location
	local varargAnnotation: AstTypePack

	if self.lexer:current().type ~= (")"):byte() then
		local results2 = self:parseBindingList(args, --[[ allowDot3= ]] true)
		vararg = results2.vararg
		varargLocation = results2.varargLocation
		varargAnnotation = results2.varargAnnotation
	end

	local argLocation: Location?

	if matchParen.type == ("("):byte() and self.lexer:current().type == (")"):byte() then
		local matchMatchParen = MatchLexeme.new(matchParen)
		argLocation = Location.new(matchMatchParen.position, self.lexer:current().location.finish)
	end

	self:expectMatchAndConsume(")", matchParen, true)

	local typelist = self:parseOptionalReturnType()

	local funLocal: AstLocal?

	if localName then
		funLocal = self:pushLocal(Binding.new(localName, nil))
	end

	local localsBegin = self:saveLocals()

	local fun = Function.new()
	fun.vararg = vararg

	self.functionStack:emplace_back(fun)

	local results3 = self:prepareFunctionArguments(start, hasself, args)
	local selfAst = results3.first
	local vars = results3.second

	local body = self:parseBlock()

	self.functionStack:pop_back()

	self:restoreLocals(localsBegin)
	
	local endLocation = self.lexer:current().location

	local hasEnd = self:expectMatchEndAndConsume(Lexeme.Type.ReservedEnd, matchFunction)
	body.hasEnd = hasEnd

	local result = Pair.new(
		AstExprFunction.new(Location.new(start, endLocation), attributes, generics, genericPacks, selfAst, vars, vararg, varargLocation, body, self.functionStack:size(), debugname, typelist, varargAnnotation, argLocation),
		funLocal
	)

	args:destroy()

	return result
end

-- explist ::= {exp `,'} exp
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseExprList(self: Parser, result: TempVector<AstExpr>): ()
	result:push_back(self:parseExpr())

	while self.lexer:current().type == (","):byte() do
		self:nextLexeme()

		if self.lexer:current().type == (")"):byte() then
			self:report(self.lexer:current().location, "Expected expression after ',' but got ')' instead")
			break
		end

		result:push_back(self:parseExpr())
	end
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseBinding(self: Parser): Binding
	local name = self:parseNameOpt("variable name")

	-- Use placeholder if the name is missing
	if not name then
		name = Name.new(self.nameError, self.lexer:current().location)
	end

	local annotation = self:parseOptionalType()

	return Binding.new(name, annotation)
end

-- bindinglist ::= (binding | `...') [`,' bindinglist]
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseBindingList(self: Parser, result: TempVector<Binding>, allowDot3: boolean?): {
	vararg: boolean,
	varargLocation: Location,
	varargAnnotation: AstTypePack?
}
	while true do
		if self.lexer:current().type == Lexeme.Type.Dot3 and allowDot3 then
			local varargLocation = self.lexer:current().location
			self:nextLexeme()

			local tailAnnotation: AstTypePack
			if self.lexer:current().type == (":"):byte() then
				self:nextLexeme()
				tailAnnotation = self:parseVariadicArgumentTypePack()
			end

			return {
				vararg = true,
				varargLocation = varargLocation,
				varargAnnotation = tailAnnotation
			}
		end

		result:push_back(self:parseBinding())

		if self.lexer:current().type ~= (","):byte() then
			break
		end
		self:nextLexeme()
	end

	return {
		vararg = false,
		varargLocation = Location.new(),
		varargAnnotation = nil
	}
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseOptionalType(self: Parser): AstType?
	if self.lexer:current().type == (":"):byte() then
		self:nextLexeme()
		return self:parseType()
	else
		return nil
	end
end

-- TypeList ::= Type [`,' TypeList] | ...Type
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseTypeList(self: Parser, result: TempVector<AstType>, resultNames: TempVector<AstArgumentName?>): AstType?
	while true do
		if shouldParseTypePack(self.lexer) then
			return self:parseTypePack()
		end

		if self.lexer:current().type == Lexeme.Type.Name and self.lexer:lookahead().type == (":"):byte() then
			-- Fill in previous argument names with empty slots
			while resultNames:size() < result:size() do
				resultNames:push_back(nil)
			end

			resultNames:push_back(AstArgumentName.new(AstName.new(self.lexer:current().name), self.lexer:current().location))
			self:nextLexeme()

			self:expectAndConsume(":")
		elseif not resultNames:empty() then
			-- If we have a type with named arguments, provide elements for all types
			resultNames:push_back(nil)
		end

		result:push_back(self:parseType())
		if self.lexer:current().type ~= (","):byte() then
			break
		end

		self:nextLexeme()

		if self.lexer:current().type == (")"):byte() then
			self:report(self.lexer:current().location, "Expected type after ',' but got ')' instead")
			break
		end
	end

	return nil
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseOptionalReturnType(self: Parser): AstTypeList?
	if self.lexer:current().type == (":"):byte() or self.lexer:current().type == Lexeme.Type.SkinnyArrow then
		if self.lexer:current().type == Lexeme.Type.SkinnyArrow then
			self:report(self.lexer:current().location, "Function return type annotations are written after ':' instead of '->'")
		end

		self:nextLexeme()

		local oldRecursionCount = self.recursionCounter

		local results = self:parseReturnType()
		local _location = results.first
		local result = results.second

		-- At this point, if we find a , character, it indicates that there are multiple return types
		-- in this type annotation, but the list wasn't wrapped in parentheses.
		if self.lexer:current().type == (","):byte() then
			self:report(self.lexer:current().location, "Expected a statement, got ','; did you forget to wrap the list of return types in parentheses?")

			self:nextLexeme()
		end

		self.recursionCounter = oldRecursionCount

		return result
	end

	return nil
end

-- ReturnType ::= Type | `(' TypeList `)'
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseReturnType(self: Parser): Pair<Location, AstTypeList>
	self:incrementRecursionCounter("type annotation")

	local begin = self.lexer:current()

	if self.lexer:current().type ~= ("("):byte() then
		if shouldParseTypePack(self.lexer) then
			local typePack = self:parseTypePack()

			return Pair.new(typePack.location, AstTypeList.new({}, typePack))
		else
			local typeAst = self:parseType()

			return Pair.new(typeAst.location, AstTypeList.new({typeAst},  nil))
		end
	end

	self:nextLexeme()

	local innerBegin = self.lexer:current().location

	self.matchRecoveryStopOnToken:set_increment(Lexeme.Type.SkinnyArrow)

	local result = TempVector.new(self.scratchType)
	local resultNames = TempVector.new(self.scratchOptArgName)
	local varargAnnotation: AstTypePack

	-- possibly () -> ReturnType
	if self.lexer:current().type ~= (")"):byte() then
		varargAnnotation = self:parseTypeList(result, resultNames)
	end
	
	local location = Location.new(begin.location, self.lexer:current().location)

	self:expectMatchAndConsume(")", begin, true)

	self.matchRecoveryStopOnToken:set_decrement(Lexeme.Type.SkinnyArrow)

	local vectors = {result, resultNames}

	if self.lexer:current().type ~= Lexeme.Type.SkinnyArrow and resultNames:empty() then
		-- If it turns out that it's just '(A)', it's possible that there are unions/intersections to follow, so fold over it.
		if result:size() == 1 then
			local returnType = self:parseTypeSuffix(result:get(1), innerBegin)

			-- If parseType parses nothing, then returnType->location.end only points at the last non-type-pack
			-- type to successfully parse.  We need the span of the whole annotation.
			local endPos = if result:size() == 1 then location.finish else returnType.location.finish
			
			destroy(vectors)

			return Pair.new(
				Location.new(location.begin, endPos),
				AstTypeList.new({returnType}, varargAnnotation)
			)
		end

		local resultToReturn = Pair.new(
			location,
			AstTypeList.new(self:copy(result), varargAnnotation)
		)

		destroy(vectors)

		return resultToReturn
	end

	local tail = self:parseFunctionTypeTail(begin, Lexeme.new(nil :: any, 0), {}, {}, self:copy(result), self:copy(resultNames), varargAnnotation)

	local resultToReturn = Pair.new(
		Location.new(location, tail.location),
		AstTypeList.new({tail}, varargAnnotation)
	)

	destroy(vectors)

	return resultToReturn
end

-- TableIndexer ::= `[' Type `]' `:' Type
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseTableIndexer(self: Parser, access: number, accessLocation: Location?): AstTableIndexer
	local begin = self.lexer:current()
	self:nextLexeme() -- [

	local index = self:parseType()

	self:expectMatchAndConsume("]", begin)

	self:expectAndConsume(":", "table field")

	local result = self:parseType()

	return AstTableIndexer.new(index, result, Location.new(begin.location, result.location), access, accessLocation)
end

-- TableProp ::= Name `:' Type
-- TablePropOrIndexer ::= TableProp | TableIndexer
-- PropList ::= TablePropOrIndexer {fieldsep TablePropOrIndexer} [fieldsep]
-- TableType ::= `{' PropList `}'
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseTableType(self: Parser, inDeclarationContext: boolean?): AstType
	self:incrementRecursionCounter("type annotation")

	local props = TempVector.new(self.scratchTableTypeProps)
	local indexer: AstTableIndexer

	local start = self.lexer:current().location

	local matchBrace = self.lexer:current()
	self:expectAndConsume("{", "table type")

	while self.lexer:current().type ~= ("}"):byte() do
		local access = AstTableAccess.ReadWrite
		local accessLocation: Location?

		if self.lexer:current().type == Lexeme.Type.Name and self.lexer:lookahead().type ~= (":"):byte() then
			if self.lexer:current().name == "read" then
				accessLocation = self.lexer:current().location
				access = AstTableAccess.Read
				self.lexer:next()
			elseif self.lexer:current().name == "write" then
				accessLocation = self.lexer:current().location
				access = AstTableAccess.Write
				self.lexer:next()
			end
		end

		if self.lexer:current().type == ("["):byte() and (self.lexer:lookahead().type == Lexeme.Type.RawString or self.lexer:lookahead().type == Lexeme.Type.QuotedString) then
			local begin = self.lexer:current()
			self:nextLexeme() -- [
			local chars = self:parseCharArray()

			self:expectMatchAndConsume("]", begin)
			self:expectAndConsume(":", "table field")

			local typeAst = self:parseType()

			-- since AstName contains a char*, it can't contain null
			local containsNull = chars and chars:find("\0")

			if chars and not containsNull then
				props:push_back(AstTableProp.new(AstName.new(chars), begin.location, typeAst, access, accessLocation))
			else
				self:report(begin.location, "String literal contains malformed escape sequence or \\0")
			end
		elseif self.lexer:current().type == ("["):byte() then
			if indexer then
				-- maybe we don't need to parse the entire badIndexer...
				-- however, we either have { or [ to lint, not the entire table type or the bad indexer.
				local badIndexer = self:parseTableIndexer(access, accessLocation)

				-- we lose all additional indexer expressions from the AST after error recovery here
				self:report(badIndexer.location, "Cannot have more than one table indexer")
			else
				indexer = self:parseTableIndexer(access, accessLocation)
			end
		elseif props:empty() and not indexer and not (self.lexer:current().type == Lexeme.Type.Name and self.lexer:lookahead().type == (":"):byte()) then
			local typeAst = self:parseType()

			-- array-like table type: {T} desugars into {[number]: T}
			local index = AstTypeReference.new(typeAst.location, nil, self.nameNumber, nil, typeAst.location)
			indexer = AstTableIndexer.new(index, typeAst, typeAst.location, access, accessLocation)

			break
		else
			local name = self:parseNameOpt("table field")

			if not name then
				break
			end

			self:expectAndConsume(":", "table field")

			local typeAst = self:parseType(inDeclarationContext)

			props:push_back(AstTableProp.new(name.name, name.location, typeAst, access, accessLocation))
		end

		if self.lexer:current().type == (","):byte() or self.lexer:current().type == (";"):byte() then
			self:nextLexeme()
		else
			if self.lexer:current().type ~= ("}"):byte() then
				break
			end
		end
	end

	local endLocation = self.lexer:current().location

	if not self:expectMatchAndConsume("}", matchBrace) then
		endLocation = self.lexer:previousLocation()
	end

	local result = AstTypeTable.new(Location.new(start, endLocation), self:copy(props), indexer)

	props:destroy()

	return result
end

-- ReturnType ::= Type | `(' TypeList `)'
-- FunctionType ::= [`<' varlist `>'] `(' [TypeList] `)' `->` ReturnType
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseFunctionType(self: Parser, allowPack: boolean, attributes: {AstAttr}): AstTypeOrPack
	self:incrementRecursionCounter("type annotation")

	local forceFunctionType = self.lexer:current().type == ("<"):byte()

	local begin = self.lexer:current()

	local results = self:parseGenericTypeList(--[[ withDefaultValues= ]] false)
	local generics = results.first
	local genericPacks = results.second

	local parameterStart = self.lexer:current()

	self:expectAndConsume("(", "function parameters")

	self.matchRecoveryStopOnToken:set_increment(Lexeme.Type.SkinnyArrow)

	local params = TempVector.new(self.scratchType)
	local names = TempVector.new(self.scratchOptArgName)
	local varargAnnotation: AstTypePack

	if self.lexer:current().type ~= (")"):byte() then
		varargAnnotation = self:parseTypeList(params, names)
	end
	
	self:expectMatchAndConsume(")", parameterStart, true)

	self.matchRecoveryStopOnToken:set_decrement(Lexeme.Type.SkinnyArrow)

	local paramTypes = self:copy(params)

	if not names:empty() then
		forceFunctionType = true
	end

	local returnTypeIntroducer = self.lexer:current().type == Lexeme.Type.SkinnyArrow or self.lexer:current().type == (":"):byte()

	local vectors = {params, names}

	-- Not a function at all. Just a parenthesized type. Or maybe a type pack with a single element
	if params:size() == 1 and not varargAnnotation and not forceFunctionType and not returnTypeIntroducer then
		if allowPack then
			destroy(vectors)

			return AstTypeOrPack.new(nil, AstTypePackExplicit.new(begin.location, AstTypeList.new(paramTypes, nil)))
		else
			local result = AstTypeOrPack.new(params:get(1), nil)

			destroy(vectors)

			return result
		end
	end

	if not forceFunctionType and not returnTypeIntroducer and allowPack then
		destroy(vectors)

		return AstTypeOrPack.new(nil, AstTypePackExplicit.new(begin.location, AstTypeList.new(paramTypes, nil)))
	end

	local paramNames = self:copy(names)

	local result = AstTypeOrPack.new(self:parseFunctionTypeTail(begin, attributes, generics, genericPacks, paramTypes, paramNames, varargAnnotation))

	destroy(vectors)

	return result
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseFunctionTypeTail(self: Parser, begin: Lexeme, attributes: {AstAttr}, generics: {AstGenericType}, genericPacks: {AstGenericTypePack}, params: {AstType}, paramNames: {AstArgumentName?}, varargAnnotation: AstTypePack): AstType
	self:incrementRecursionCounter("type annotation")

	if self.lexer:current().type == (":"):byte() then
		self:report(self.lexer:current().location, "Return types in function type annotations are written after '->' instead of ':'")
		self.lexer:next()
	-- Users occasionally write '()' as the 'unit' type when they actually want to use 'nil', here we'll try to give a more specific error
	elseif self.lexer:current().type ~= Lexeme.Type.SkinnyArrow and #generics == 0 and #genericPacks == 0 and #params == 0 then
		self:report(Location.new(begin.location, self.lexer:previousLocation()), "Expected '->' after '()' when parsing function type; did you mean 'nil'?")
		
		return AstTypeReference.new(begin.location, nil, self.nameNil, nil, begin.location)
	else
		self:expectAndConsume(Lexeme.Type.SkinnyArrow, "function type")
	end

	local results = self:parseReturnType()
	local endLocation = results.first
	local returnTypeList = results.second

	local paramTypes = AstTypeList.new(params, varargAnnotation)
	return AstTypeFunction.new(Location.new(begin.location, endLocation), attributes, generics, genericPacks, paramTypes, paramNames, returnTypeList)
end

-- Type ::=
--      nil |
--      Name[`.' Name] [`<' namelist `>'] |
--      `{' [PropList] `}' |
--      `(' [TypeList] `)' `->` ReturnType
--      `typeof` Type
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseTypeSuffix(self: Parser, typeAst: AstType, begin: Location.Location): AstType
	local parts = TempVector.new(self.scratchType)

	if not FastVariables.LuauLeadingBarAndAmpersand2 or typeAst ~= nil then
		parts:push_back(typeAst)
	end

	self:incrementRecursionCounter("type annotation")

	local isUnion = false
	local isIntersection = false
	local hasOptional = false
	
	local location = begin

	while true do
		local c = self.lexer:current().type
		if c == ("|"):byte() then
			self:nextLexeme()

			local oldRecursionCount = self.recursionCounter
			parts:push_back(self:parseSimpleType(--[[ allowPack= ]] false).type)
			self.recursionCounter = oldRecursionCount

			isUnion = true
		elseif c == ("?"):byte() then
			assert(parts:size() >= 1)

			local loc = self.lexer:current().location
			self:nextLexeme()

			if not hasOptional then
				parts:push_back(AstTypeReference.new(loc, nil, self.nameNil, nil, loc))
			end

			isUnion = true
			hasOptional = true
		elseif c == ("&"):byte() then
			self:nextLexeme()

			local oldRecursionCount = self.recursionCounter
			parts:push_back(self:parseSimpleType(--[[ allowPack= ]] false).type)
			self.recursionCounter = oldRecursionCount

			isIntersection = true
		elseif c == Lexeme.Type.Dot3 then
			self:report(self.lexer:current().location, "Unexpected '...' after type annotation")
			self:nextLexeme()
		else
			break
		end

		local addend = if hasOptional then 1 else 0
		if parts:size() > FastVariables.LuauTypeLengthLimit + addend then
			ParseError.raise(parts:back().location, "Exceeded allowed type length; simplify your type annotation to make the code compile")
		end
	end

	if parts:size() == 1 then
		local result = if FastVariables.LuauLeadingBarAndAmpersand2 then parts:get(1) else typeAst
		
		parts:destroy()

		return result
	end

	local copy = self:copy(parts)
	local copyBack = copy[#copy]

	parts:destroy()

	if isUnion and isIntersection then
		return self:reportTypeError(Location.new(begin, copyBack.location), copy, "Mixing union and intersection types is not allowed; consider wrapping in parentheses.")
	end

	location.finish = copyBack.location.finish

	if isUnion then
		return AstTypeUnion.new(location, copy)
	end

	if isIntersection then
		return AstTypeIntersection.new(location, copy)
	end

	assert(false)
	ParseError.raise(begin, "Composite type was not an intersection or union.")
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseTypeOrPack(self: Parser): AstTypeOrPack
	local oldRecursionCount = self.recursionCounter
	-- recursion counter is incremented in parseSimpleType

	local begin = self.lexer:current().location

	local results = self:parseSimpleType(--[[ allowPack= ]] true)
	local typeAst = results.type
	local typePack = results.typePack

	if typePack then
		assert(typeAst == nil)
		return AstTypeOrPack.new(nil, typePack)
	end
	assert(typeAst)

	self.recursionCounter = oldRecursionCount

	return AstTypeOrPack.new(self:parseTypeSuffix(typeAst, begin), nil)
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseType(self: Parser, inDeclarationContext: boolean?): AstType
	local oldRecursionCount = self.recursionCounter
	-- recursion counter is incremented in parseSimpleType and/or parseTypeSuffix

	local begin = self.lexer:current().location

	if FastVariables.LuauLeadingBarAndAmpersand2 then
		local typeAst: AstType

		local c = self.lexer:current().type
		if c ~= ("|"):byte() and c ~= ("&"):byte() then
			typeAst = self:parseSimpleType(--[[ allowPack= ]] false, --[[ in declaration context]] inDeclarationContext).type
			self.recursionCounter = oldRecursionCount
		end

		local typeWithSuffix = self:parseTypeSuffix(typeAst, begin)
		self.recursionCounter = oldRecursionCount

		return typeWithSuffix
	else
		local typeAst = self:parseSimpleType(--[[ allowPack= ]] false, --[[ in declaration context ]] inDeclarationContext).type

		self.recursionCounter = oldRecursionCount

		return self:parseTypeSuffix(typeAst, begin)
	end
end

-- Type ::= nil | Name[`.' Name] [ `<' Type [`,' ...] `>' ] | `typeof' `(' expr `)' | `{' [PropList] `}'
--   | [`<' varlist `>'] `(' [TypeList] `)' `->` ReturnType
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseSimpleType(self: Parser, allowPack: boolean, inDeclarationContext: boolean?): AstTypeOrPack
	self:incrementRecursionCounter("type annotation")

	local start = self.lexer:current().location


	if self.lexer:current().type == Lexeme.Type.Attribute then
		if not inDeclarationContext or not FastVariables.LuauAttributeSyntax then
			return AstTypeOrPack.new(self:reportTypeError(start, {}, "attributes are not allowed in declaration context"), nil)
		else
			local attributes = self:parseAttributes() -- Eli: Not sure how to translate `attributes = Parser::parseAttributes();`.
			return self:parseFunctionType(allowPack, attributes)
		end
	elseif self.lexer:current().type == Lexeme.Type.ReservedNil then
		self:nextLexeme()
		return AstTypeOrPack.new(AstTypeReference.new(start, nil, self.nameNil, nil, start), nil)
	elseif self.lexer:current().type == Lexeme.Type.ReservedTrue then
		self:nextLexeme()
		return AstTypeOrPack.new(AstTypeSingletonBool.new(start, true))
	elseif self.lexer:current().type == Lexeme.Type.ReservedFalse then
		self:nextLexeme()
		return AstTypeOrPack.new(AstTypeSingletonBool.new(start, false))
	elseif self.lexer:current().type == Lexeme.Type.RawString or self.lexer:current().type == Lexeme.Type.QuotedString then
		local value = self:parseCharArray(); if value then
			local svalue = value
			return AstTypeOrPack.new(AstTypeSingletonString.new(start, svalue))
		else
			return AstTypeOrPack.new(self:reportTypeError(start, {}, "String literal contains malformed escape sequence"))
		end
	elseif self.lexer:current().type == Lexeme.Type.InterpStringBegin or self.lexer:current().type == Lexeme.Type.InterpStringSimple then
		self:parseInterpString()

		return AstTypeOrPack.new(self:reportTypeError(start, {}, "Interpolated string literals cannot be used as types"))
	elseif self.lexer:current().type == Lexeme.Type.BrokenString then
		self:nextLexeme()
		return AstTypeOrPack.new(self:reportTypeError(start, {}, "Malformed string; did you forget to finish it?"))
	elseif self.lexer:current().type == Lexeme.Type.Name then
		local prefix: AstName?
		local prefixLocation: Location?
		local name = self:parseName("type name")

		if self.lexer:current().type == ("."):byte() then
			local pointPosition = self.lexer:current().location.begin
			self:nextLexeme()
			
			prefix = name.name
			prefixLocation = name.location
			name = self:parseIndexName("field name", pointPosition)
		elseif self.lexer:current().type == Lexeme.Type.Dot3 then
			self:report(self.lexer:current().location, "Unexpected '...' after type name; type pack is not allowed in this context")
			self:nextLexeme()
		elseif name.name.value == "typeof" then
			local typeofBegin = self.lexer:current()
			self:expectAndConsume("(", "typeof type")
			
			local expr = self:parseExpr()

			local endLocation = self.lexer:current().location

			self:expectMatchAndConsume(")", typeofBegin)

			return AstTypeOrPack.new(AstTypeTypeof.new(Location.new(start, endLocation), expr))
		end

		local hasParameters = false
		local parameters: {AstTypeOrPack} = {}

		if self.lexer:current().type == ("<"):byte() then
			hasParameters = true
			parameters = self:parseTypeParams()
		end

		local endLocation = self.lexer:previousLocation()

		return AstTypeOrPack.new(AstTypeReference.new(Location.new(start, endLocation), prefix, name.name, prefixLocation, name.location, hasParameters, parameters), nil)
	elseif self.lexer:current().type == ("{"):byte() then
		return AstTypeOrPack.new(self:parseTableType(--[[ inDeclarationContext ]] inDeclarationContext), nil)
	elseif self.lexer:current().type == ("("):byte() or self.lexer:current().type == ("<"):byte() then
		return self:parseFunctionType(allowPack, {})
	elseif self.lexer:current().type == Lexeme.Type.ReservedFunction then
		self:nextLexeme()

		return AstTypeOrPack.new(self:reportTypeError(start, {}, "Using 'function' as a type annotation is not supported, consider replacing with a function type annotation e.g. '(...any) -> ...any'"), nil)
	else
		-- For a missing type annotation, capture 'space' between last token and the next one
		local astErrorlocation = Location.new(self.lexer:previousLocation().finish, start.begin)
		-- The parse error includes the next lexeme to make it easier to display where the error is (e.g. in an IDE or a CLI error message).
		-- Including the current lexeme also makes the parse error consistent with other parse errors returned by Luau.
		local parseErrorLocation = Location.new(self.lexer:previousLocation().finish, start.finish)
		return AstTypeOrPack.new(self:reportMissingTypeError(parseErrorLocation, astErrorlocation, "Expected type, got %s", self.lexer:current():toString()), nil)
	end
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseVariadicArgumentTypePack(self: Parser): AstTypePack
	-- Generic: a...
	if self.lexer:current().type == Lexeme.Type.Name and self.lexer:lookahead().type == Lexeme.Type.Dot3 then
		local name = self:parseName("generic name")
		local endLocation = self.lexer:current().location

		-- This will not fail because of the lookahead guard.
		self:expectAndConsume(Lexeme.Type.Dot3, "generic type pack annotation")
		return AstTypePackGeneric.new(Location.new(name.location, endLocation), name.name)
	-- Variadic: T
	else
		local variadicAnnotation = self:parseType()
		return AstTypePackVariadic.new(variadicAnnotation.location, variadicAnnotation)
	end
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseTypePack(self: Parser): AstTypePack
	-- Variadic: ...T
	if self.lexer:current().type == Lexeme.Type.Dot3 then
		local start = self.lexer:current().location
		self:nextLexeme()
		local varargTy = self:parseType()
		return AstTypePackVariadic.new(Location.new(start, varargTy.location), varargTy)
	-- Generic: a...
	elseif self.lexer:current().type == Lexeme.Type.Name and self.lexer:lookahead().type == Lexeme.Type.Dot3 then
		local name = self:parseName("generic name")
		local endLocation = self.lexer:current().location

		-- This will not fail because of the lookahead guard.
		self:expectAndConsume(Lexeme.Type.Dot3, "generic type pack annotation")
		return AstTypePackGeneric.new(Location.new(name.location, endLocation), name.name)
	end

	-- TODO: shouldParseTypePack can be removed and parseTypePack can be called unconditionally instead
	error("parseTypePack can't be called if shouldParseTypePack() returned false")
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseUnaryOp(self: Parser, l: Lexeme): number?
	if l.type == Lexeme.Type.ReservedNot then
		return AstExprUnary.Op.Not
	elseif l.type == ("-"):byte() then
		return AstExprUnary.Op.Minus
	elseif l.type == ("#"):byte() then
		return AstExprUnary.Op.Len
	else
		return nil
	end
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseBinaryOp(self: Parser, l: Lexeme): number?
	if l.type == ("+"):byte() then
		return AstExprBinary.Op.Add
	elseif l.type == ("-"):byte() then
		return AstExprBinary.Op.Sub
	elseif l.type == ("*"):byte() then
		return AstExprBinary.Op.Mul
	elseif l.type == ("/"):byte() then
		return AstExprBinary.Op.Div
	elseif l.type == Lexeme.Type.FloorDiv then
		return AstExprBinary.Op.FloorDiv
	elseif l.type == ("%"):byte() then
		return AstExprBinary.Op.Mod
	elseif l.type == ("^"):byte() then
		return AstExprBinary.Op.Pow
	elseif l.type == Lexeme.Type.Dot2 then
		return AstExprBinary.Op.Concat
	elseif l.type == Lexeme.Type.NotEqual then
		return AstExprBinary.Op.CompareNe
	elseif l.type == Lexeme.Type.Equal then
		return AstExprBinary.Op.CompareEq
	elseif l.type == ("<"):byte() then
		return AstExprBinary.Op.CompareLt
	elseif l.type == Lexeme.Type.LessEqual then
		return AstExprBinary.Op.CompareLe
	elseif l.type == (">"):byte() then
		return AstExprBinary.Op.CompareGt
	elseif l.type == Lexeme.Type.GreaterEqual then
		return AstExprBinary.Op.CompareGe
	elseif l.type == Lexeme.Type.ReservedAnd then
		return AstExprBinary.Op.And
	elseif l.type == Lexeme.Type.ReservedOr then
		return AstExprBinary.Op.Or
	else
		return nil
	end
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseCompoundOp(self: Parser, l: Lexeme): number?
	if l.type == Lexeme.Type.AddAssign then
		return AstExprBinary.Op.Add
	elseif l.type == Lexeme.Type.SubAssign then
		return AstExprBinary.Op.Sub
	elseif l.type == Lexeme.Type.MulAssign then
		return AstExprBinary.Op.Mul
	elseif l.type == Lexeme.Type.DivAssign then
		return AstExprBinary.Op.Div
	elseif l.type == Lexeme.Type.FloorDivAssign then
		return AstExprBinary.Op.FloorDiv
	elseif l.type == Lexeme.Type.ModAssign then
		return AstExprBinary.Op.Mod
	elseif l.type == Lexeme.Type.PowAssign then
		return AstExprBinary.Op.Pow
	elseif l.type == Lexeme.Type.ConcatAssign then
		return AstExprBinary.Op.Concat
	else
		return nil
	end
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.checkUnaryConfusables(self: Parser): number?
	local curr = self.lexer:current()

	-- early-out: need to check if this is a possible confusable quickly
	if curr.type ~= ("!"):byte() then
		return nil
	end

	-- slow path: possible confusable
	local start = curr.location

	if curr.type == ("!"):byte() then
		self:report(start, "Unexpected '!'; did you mean 'not'?")
		return AstExprUnary.Op.Not
	end

	return nil
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.checkBinaryConfusables(self: Parser, binaryPriority: {BinaryOpPriority}, limit: number): number?
	local curr = self.lexer:current()
	-- early-out: need to check if this is a possible confusable quickly
	if curr.type ~= ("&"):byte() and curr.type ~= ("|"):byte() and curr.type ~= ("!"):byte() then
		return nil
	end

	-- slow path: possible confusable
	local start = curr.location
	local nextLex = self.lexer:lookahead()

	if curr.type == ("&"):byte() and nextLex.type == ("&"):byte() and curr.location.finish == nextLex.location.begin and binaryPriority[AstExprBinary.Op.And].left > limit then
		self:nextLexeme()
		self:report(Location.new(start, nextLex.location), "Unexpected '&&'; did you mean 'and'?")
		return AstExprBinary.Op.And
	elseif curr.type == ("|"):byte() and nextLex.type == ("|"):byte() and curr.location.finish == nextLex.location.begin and binaryPriority[AstExprBinary.Op.Or].left > limit then
		self:nextLexeme()
		self:report(Location.new(start, nextLex.location), "Unexpected '||'; did you mean 'or'?")
		return AstExprBinary.Op.Or
	elseif curr.type == ("!"):byte() and nextLex.type == ("="):byte() and curr.location.finish == nextLex.location.begin and binaryPriority[AstExprBinary.Op.CompareNe].left > limit then
		self:nextLexeme()
		self:report(Location.new(start, nextLex.location), "Unexpected '!='; did you mean '~='?")
		return AstExprBinary.Op.CompareNe
	end

	return nil
end

local BINARY_PRIORITY = {
	{6, 6}, {6, 6}, {7, 7}, {7, 7}, {7, 7}, {7, 7}, -- `+' `-' `*' `/' `//' `%'
    {10, 9}, {5, 4},                                -- power and concat (right associative)
    {3, 3}, {3, 3},                                 -- equality and inequality
    {3, 3}, {3, 3}, {3, 3}, {3, 3},                 -- order
    {2, 2}, {1, 1}                                  -- logical (and/or)
}
local binaryPriority: {BinaryOpPriority} = {}

-- subexpr -> (asexp | unop subexpr) { binop subexpr }
-- where `binop' is any binary operator with a priority higher than `limit'
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseExpr(self: Parser, limit: number?): AstExpr
	if limit == nil then
		limit = 0
	end
	assert(limit)
	
	assert(#BINARY_PRIORITY == AstExprBinary.Op__Count, "binaryPriority needs an entry per op")

	local oldRecursionCount = self.recursionCounter

	-- this handles recursive calls to parseSubExpr/parseExpr
	self:incrementRecursionCounter("expression")

	local unaryPriority = 8

	local start = self.lexer:current().location
	
	local expr: AstExpr

	local uop = self:parseUnaryOp(self.lexer:current())

	if not uop then
		uop = self:checkUnaryConfusables()
	end

	if uop then
		self:nextLexeme()

		local subexpr = self:parseExpr(unaryPriority)

		expr = AstExprUnary.new(Location.new(start, subexpr.location), uop, subexpr)
	else
		expr = self:parseAssertionExpr()
	end

	-- expand while operators have priorities higher than `limit'
	local op = self:parseBinaryOp(self.lexer:current())

	if not op then
		op = self:checkBinaryConfusables(binaryPriority, limit)
	end
	
	while op and binaryPriority[op].left > limit do
		self:nextLexeme()

		-- read sub-expression with higher priority
		local nextExpr = self:parseExpr(binaryPriority[op].right)

		expr = AstExprBinary.new(Location.new(start, nextExpr.location), op, expr, nextExpr)
		op = self:parseBinaryOp(self.lexer:current())

		if not op then
			op = self:checkBinaryConfusables(binaryPriority, limit)
		end

		-- note: while the parser isn't recursive here, we're generating recursive structures of unbounded depth
		self:incrementRecursionCounter("expression")
	end

	self.recursionCounter = oldRecursionCount

	return expr
end

-- NAME
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseNameExpr(self: Parser, context: string): AstExpr
	local name = self:parseNameOpt(context)

	if not name then
		return AstExprError.new(self.lexer:current().location, {}, unsigned(self.parseErrors:size() - 1))
	end

	local value = self.localMap[name.name]

	if value then
		local localAst = value
		
		return AstExprLocal.new(name.location, localAst, localAst.functionDepth ~= self.functionStack:size() - 1)
	end

	return AstExprGlobal.new(name.location, name.name)
end

-- prefixexp -> NAME | '(' expr ')'
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parsePrefixExpr(self: Parser): AstExpr
	if self.lexer:current().type == ("("):byte() then
		local start = self.lexer:current().location.begin

		local matchParen = self.lexer:current()
		self:nextLexeme()

		local expr = self:parseExpr()

		local endPosition = self.lexer:current().location.finish

		if self.lexer:current().type ~= (")"):byte() then
			local suggestion = if self.lexer:current().type == ("="):byte() then "; did you mean to use '{' when defining a table?" else nil

			self:expectMatchAndConsumeFail((")"):byte(), MatchLexeme.new(matchParen), suggestion)

			endPosition = self.lexer:previousLocation().finish
		else
			self:nextLexeme()
		end

		return AstExprGroup.new(Location.new(start, endPosition), expr)
	else
		return self:parseNameExpr("expression")
	end
end

-- primaryexp -> prefixexp { `.' NAME | `[' exp `]' | `:' NAME funcargs | funcargs }
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parsePrimaryExpr(self: Parser, asStatement: boolean): AstExpr
	local start = self.lexer:current().location.begin

	local expr = self:parsePrefixExpr()

	local oldRecursionCount = self.recursionCounter

	while true do
		if self.lexer:current().type == ("."):byte() then
			local opPosition = self.lexer:current().location.begin
			self:nextLexeme()

			local index= self:parseIndexName(nil, opPosition)

			expr = AstExprIndexName.new(Location.new(start, index.location.finish), expr, index.name, index.location, opPosition, ".")
		elseif self.lexer:current().type == ("["):byte() then
			local matchBracket = self.lexer:current()
			self:nextLexeme()

			local index = self:parseExpr()

			local endPosition = self.lexer:current().location.finish

			self:expectMatchAndConsume("]", matchBracket)

			expr = AstExprIndexExpr.new(Location.new(start, endPosition), expr, index)
		elseif self.lexer:current().type == (":"):byte() then
			local opPosition = self.lexer:current().location.begin
			self:nextLexeme()

			local index = self:parseIndexName("method name", opPosition)
			local func = AstExprIndexName.new(Location.new(start, index.location.finish), expr, index.name, index.location, opPosition, ":")

			expr = self:parseFunctionArgs(func, true)
		elseif self.lexer:current().type == ("("):byte() then
			-- This error is handled inside 'parseFunctionArgs' as well, but for better error recovery we need to break out the current loop here
			if not asStatement and expr.location.finish.line ~= self.lexer:current().location.begin.line then
				self:reportAmbiguousCallError()
				break
			end

			expr = self:parseFunctionArgs(expr, false)
		elseif self.lexer:current().type == ("{"):byte() or self.lexer:current().type == Lexeme.Type.RawString or self.lexer:current().type == Lexeme.Type.QuotedString then
			expr = self:parseFunctionArgs(expr, false)
		else
			break
		end

		-- note: while the parser isn't recursive here, we're generating recursive structures of unbounded depth
		self:incrementRecursionCounter("expression")
	end

	self.recursionCounter = oldRecursionCount

	return expr
end

-- asexp -> simpleexp [`::' Type]
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseAssertionExpr(self: Parser): AstExpr
	local start = self.lexer:current().location
	local expr = self:parseSimpleExpr()

	if self.lexer:current().type == Lexeme.Type.DoubleColon then
		self:nextLexeme()
		local annotation = self:parseType()
		return AstExprTypeAssertion.new(Location.new(start, annotation.location), expr, annotation)
	else
		return expr
	end
end

--[=[
	@within Parser
	@private
	@since v0.1.0

	Due to Luau limitations, this function is less accurate. It *is* possible to make it fully accurate with some sort of `BigNumber`, but I doubt this is necessary.
]=]
local function parseInteger(data: string, base: number): {
	outcome: number,
	result: number?
}
	assert(base == 2 or base == 16)

	local value = tonumber(data, base)

	if not value then
		return {
			outcome = ConstantNumberParseResult.Malformed,
			result = nil
		}
	end

	local result = value

	return {
		outcome = ConstantNumberParseResult.Ok,
		result = result
	}
end

local function parseDouble(data: string): {
	outcome: number,
	result: number?
}
	-- binary literal
	local data1 = data:sub(1, 1)
	local data2 = data:sub(2, 2)
	local data3 = data:sub(3, 3)
	if data1 == "0" and (data2 == "b" or data2 == "B") and data3 ~= "" then
		return parseInteger(data:sub(3), 2)
	end

	-- hexadecimal literal
	if data1 == "0" and (data2 == "x" or data2 == "X") and data3 ~= "" then
		return parseInteger(data:sub(3), 16)
	end

	local value = tonumber(data)

	if not value then
		return {
			outcome = ConstantNumberParseResult.Malformed,
			result = nil
		}
	end

	local result = value

	return {
		outcome = ConstantNumberParseResult.Ok,
		result = result
	}
end

-- simpleexp -> NUMBER | STRING | NIL | true | false | ... | constructor | [attributes] FUNCTION body | primaryexp
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseSimpleExpr(self: Parser): AstExpr
	local start = self.lexer:current().location

	local attributes: {AstAttr} = {}

	if FastVariables.LuauAttributeSyntax and FastVariables.LuauAttributeSyntaxFunExpr and self.lexer:current().type == Lexeme.Type.Attribute then
		attributes = self:parseAttributes()

		if self.lexer:current().type ~= Lexeme.Type.ReservedFunction then
			return self:reportExprError(start, {}, "Expected 'function' declaration after attribute, but got %s intead", self.lexer:current():toString())
		end
	end

	if self.lexer:current().type == Lexeme.Type.ReservedNil then
		self:nextLexeme()

		return AstExprConstantNil.new(start)
	elseif self.lexer:current().type == Lexeme.Type.ReservedTrue then
		self:nextLexeme()

		return AstExprConstantBool.new(start, true)
	elseif self.lexer:current().type == Lexeme.Type.ReservedFalse then
		self:nextLexeme()

		return AstExprConstantBool.new(start, false)
	elseif self.lexer:current().type == Lexeme.Type.ReservedFunction then
		local matchFunction = self.lexer:current()
		self:nextLexeme()

		return self:parseFunctionBody(false, matchFunction, AstName.new(), nil, attributes).first
	elseif self.lexer:current().type == Lexeme.Type.Number then
		return self:parseNumber()
	elseif self.lexer:current().type == Lexeme.Type.RawString or self.lexer:current().type == Lexeme.Type.QuotedString or self.lexer:current().type == Lexeme.Type.InterpStringSimple then
		return self:parseString()
	elseif self.lexer:current().type == Lexeme.Type.InterpStringBegin then
		return self:parseInterpString()
	elseif self.lexer:current().type == Lexeme.Type.BrokenString then
		self:nextLexeme()
		return self:reportExprError(start, {}, "Malformed string; did you forget to finish it?")
	elseif self.lexer:current().type == Lexeme.Type.BrokenInterpDoubleBrace then
		self:nextLexeme()
		return self:reportExprError(start, {}, "Double braces are not permitted within interpolated strings; did you mean '\\{'?")
	elseif self.lexer:current().type == Lexeme.Type.Dot3 then
		if self.functionStack:back().vararg then
			self:nextLexeme()

			return AstExprVarargs.new(start)
		else
			self:nextLexeme()

			return self:reportExprError(start, {}, "Cannot use '...' outside of a vararg function")
		end
	elseif self.lexer:current().type == ("{"):byte() then
		return self:parseTableConstructor()
	elseif self.lexer:current().type == Lexeme.Type.ReservedIf then
		return self:parseIfElseExpr()
	else
		return self:parsePrimaryExpr(--[[ asStatement= ]] false)
	end
end

-- args ::=  `(' [explist] `)' | tableconstructor | String
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseFunctionArgs(self: Parser, func: AstExpr, isSelf: boolean): AstExpr
	if self.lexer:current().type == ("("):byte() then
		local argStart = self.lexer:current().location.finish
		if func.location.finish.line ~= self.lexer:current().location.begin.line then
			self:reportAmbiguousCallError()
		end

		local matchParen = self.lexer:current()
		self:nextLexeme()

		local args = TempVector.new(self.scratchExpr)

		if self.lexer:current().type ~= (")"):byte() then
			self:parseExprList(args)
		end

		local endLocation = self.lexer:current().location
		local argEnd = endLocation.finish

		self:expectMatchAndConsume(")", matchParen)

		local result = AstExprCall.new(Location.new(func.location, endLocation), func, self:copy(args), isSelf, Location.new(argStart, argEnd))

		args:destroy()

		return result
	elseif self.lexer:current().type == ("{"):byte() then
		local argStart = self.lexer:current().location.finish
		local expr = self:parseTableConstructor()
		local argEnd = self.lexer:previousLocation().finish

		return AstExprCall.new(Location.new(func.location, expr.location), func, expr, isSelf, Location.new(argStart, argEnd))
	elseif self.lexer:current().type == Lexeme.Type.RawString or self.lexer:current().type == Lexeme.Type.QuotedString then
		local argLocation = self.lexer:current().location
		local expr = self:parseString()

		return AstExprCall.new(Location.new(func.location, expr.location), func, expr, isSelf, argLocation)
	else
		return self:reportFunctionArgsError(func, isSelf)
	end
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.reportFunctionArgsError(self: Parser, func: AstExpr, isSelf: boolean): AstExpr
	if isSelf and self.lexer:current().location.begin.line ~= func.location.finish.line then
		return self:reportExprError(func.location, {func}, "Expected function call arguments after '('")
	else
		return self:reportExprError(Location.new(func.location.begin, self.lexer:current().location.begin), {func}, "Expected '(', '{' or <string> when parsing function call, got %s", self.lexer:current():toString())
	end
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.reportAmbiguousCallError(self: Parser): ()
	self:report(self.lexer:current().location, "Ambiguous syntax: this looks like an argument list for a function call, but could also be a start of new statement; use ';' to separate statements")
end

-- tableconstructor ::= `{' [fieldlist] `}'
-- fieldlist ::= field {fieldsep field} [fieldsep]
-- field ::= `[' exp `]' `=' exp | Name `=' exp | exp
-- fieldsep ::= `,' | `;'
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseTableConstructor(self: Parser): AstExpr
	local items = TempVector.new(self.scratchItem)

	local start = self.lexer:current().location

	local matchBrace = self.lexer:current()
	self:expectAndConsume("{", "table literal")
	local lastElementIndent = 0

	while self.lexer:current().type ~= ("}"):byte() do
		lastElementIndent = self.lexer:current().location.begin.column

		if self.lexer:current().type == ("["):byte() then
			local matchLocationBracket = self.lexer:current()
			self:nextLexeme()

			local key = self:parseExpr()

			self:expectMatchAndConsume("]", matchLocationBracket)

			self:expectAndConsume("=", "table field")

			local value = self:parseExpr()

			items:push_back(AstExprTable.Item.new(AstExprTable.Item.Kind.General, key, value))
		elseif self.lexer:current().type == Lexeme.Type.Name and self.lexer:lookahead().type == ("="):byte() then
			local name = self:parseName("table field")

			self:expectAndConsume("=", "table field")

			local nameString = name.name.value

			local key = AstExprConstantString.new(name.location, nameString, AstExprConstantString.QuotedStyle.Unquoted)
			local value = self:parseExpr()

			local func = value:as(AstExprFunction); if func then
				func.debugname = name.name
			end

			items:push_back(AstExprTable.Item.new(AstExprTable.Item.Kind.Record, key, value))
		else
			local expr = self:parseExpr()

			items:push_back(AstExprTable.Item.new(AstExprTable.Item.Kind.List, nil, expr))
		end

		if self.lexer:current().type == (","):byte() or self.lexer:current().type == (";"):byte() then
			self:nextLexeme()
		elseif (self.lexer:current().type == ("["):byte() or self.lexer:current().type == Lexeme.Type.Name) and self.lexer:current().location.begin.column == lastElementIndent then
			self:report(self.lexer:current().location, "Expected ',' after table constructor element")
		elseif self.lexer:current().type ~= ("}"):byte() then
			break
		end
	end

	local endLocation = self.lexer:current().location

	if not self:expectMatchAndConsume("}", matchBrace) then
		endLocation = self.lexer:previousLocation()
	end

	local result = AstExprTable.new(Location.new(start, endLocation), self:copy(items))

	items:destroy()

	return result
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseIfElseExpr(self: Parser): AstExpr
	local hasElse = false
	local start = self.lexer:current().location

	self:nextLexeme() -- skip if / elseif

	local condition = self:parseExpr()

	local hasThen = self:expectAndConsume(Lexeme.Type.ReservedThen, "if then else expression")

	local trueExpr = self:parseExpr()
	local falseExpr: AstExpr

	if self.lexer:current().type == Lexeme.Type.ReservedElseif then
		local oldRecursionCount = self.recursionCounter
		self:incrementRecursionCounter("expression")
		hasElse = true
		falseExpr = self:parseIfElseExpr()
		self.recursionCounter = oldRecursionCount
	else
		hasElse = self:expectAndConsume(Lexeme.Type.ReservedElse, "if then else expression")
		falseExpr = self:parseExpr()
	end

	local endLocation = falseExpr.location

	return AstExprIfElse.new(Location.new(start, endLocation), condition, hasThen, trueExpr, hasElse, falseExpr)
end

-- Name
--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseNameOpt(self: Parser, context: string?): Name?
	if self.lexer:current().type ~= Lexeme.Type.Name then
		self:reportNameError(context)

		return nil
	end

	local result = Name.new(AstName.new(self.lexer:current().name), self.lexer:current().location)

	self:nextLexeme()

	return result
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseName(self: Parser, context: string?): Name
	local name = self:parseNameOpt(context); if name then
		return name
	end

	local location = self.lexer:current().location
	location.finish = location.begin

	return Name.new(self.nameError, location)
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseIndexName(self: Parser, context: string?, previous: Position): Name
	local name = self:parseNameOpt(context); if name then
		return name
	end

	-- If we have a reserved keyword next at the same line, assume it's an incomplete name
	if self.lexer:current().type >= Lexeme.Type.Reserved_BEGIN and self.lexer:current().type < Lexeme.Type.Reserved_END and self.lexer:current().location.begin.line == previous.line then
		local result = Name.new(AstName.new(self.lexer:current().name), self.lexer:current().location)

		self:nextLexeme()

		return result
	end

	local location = self.lexer:current().location
	location.finish = location.begin

	return Name.new(self.nameError, location)
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseGenericTypeList(self: Parser, withDefaultValues: boolean): Pair<{AstGenericType}, {AstGenericTypePack}>
	local names = TempVector.new(self.scratchGenericTypes)
	local namePacks = TempVector.new(self.scratchGenericTypePacks)

	if self.lexer:current().type == ("<"):byte() then
		local begin = self.lexer:current()
		self:nextLexeme()

		local seenPack = false
		local seenDefault = false

		while true do
			local nameLocation = self.lexer:current().location
			local name = self:parseName().name
			if self.lexer:current().type == Lexeme.Type.Dot3 or seenPack then
				seenPack = true

				if self.lexer:current().type ~= Lexeme.Type.Dot3 then
					self:report(self.lexer:current().location, "Generic types come before generic type packs")
				else
					self:nextLexeme()
				end

				if withDefaultValues and self.lexer:current().type == ("="):byte() then
					seenDefault = true
					self:nextLexeme()

					if shouldParseTypePack(self.lexer) then
						local typePack = self:parseTypePack()

						namePacks:push_back(AstGenericTypePack.new(name, nameLocation, typePack))
					else
						local results = self:parseTypeOrPack()
						local typeAst = results.type
						local typePack = results.typePack

						if typeAst then
							self:report(typeAst.location, "Expected type pack after '=', got type")
						end
						
						namePacks:push_back(AstGenericTypePack.new(name, nameLocation, typePack))
					end
				else
					if seenDefault then
						self:report(self.lexer:current().location, "Expected default type pack after type pack name")
					end

					namePacks:push_back(AstGenericTypePack.new(name, nameLocation, nil))
				end
			else
				if withDefaultValues and self.lexer:current().type == ("="):byte() then
					seenDefault = true
					self:nextLexeme()

					local defaultType = self:parseType()

					names:push_back(AstGenericType.new(name, nameLocation, defaultType))
				else
					if seenDefault then
						self:report(self.lexer:current().location, "Expected default type after type name")
					end

					names:push_back(AstGenericType.new(name, nameLocation, nil))
				end
			end

			if self.lexer:current().type == (","):byte() then
				self:nextLexeme()

				if self.lexer:current().type == (">"):byte() then
					self:report(self.lexer:current().location, "Expected type after ',' but got '>' instead")
					break
				end
			else
				break
			end
		end

		self:expectMatchAndConsume(">", begin)
	end

	local generics = self:copy(names)
	local genericPacks = self:copy(namePacks)

	names:destroy()
	namePacks:destroy()

	return Pair.new(generics, genericPacks)
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseTypeParams(self: Parser): {AstTypeOrPack}
	local parameters = TempVector.new(self.scratchTypeOrPack)

	if self.lexer:current().type == ("<"):byte() then
		local begin = self.lexer:current()
		self:nextLexeme()

		while true do
			if shouldParseTypePack(self.lexer) then
				local typePack = self:parseTypePack()

				parameters:push_back(AstTypeOrPack.new(nil, typePack))
			elseif self.lexer:current().type == ("("):byte() then
				local results = self:parseTypeOrPack()
				local typeAst = results.first
				local typePack = results.typePack

				if typePack then
					parameters:push_back(AstTypeOrPack.new(nil, typePack))
				else
					parameters:push_back(AstTypeOrPack.new(typeAst, nil))
				end
			elseif self.lexer:current().type == (">"):byte() and parameters:empty() then
				break
			else
				parameters:push_back(AstTypeOrPack.new(self:parseType(), nil))
			end

			if self.lexer:current().type == (","):byte() then
				self:nextLexeme()
			else
				break
			end
		end

		self:expectMatchAndConsume(">", begin)
	end

	local result = self:copy(parameters)

	parameters:destroy()

	return result
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseCharArray(self: Parser): string?
	assert(self.lexer:current().type == Lexeme.Type.QuotedString or self.lexer:current().type == Lexeme.Type.RawString or self.lexer:current().type == Lexeme.Type.InterpStringSimple)

	self.scratchData = assert(self.lexer:current().data)

	if self.lexer:current().type == Lexeme.Type.QuotedString or self.lexer:current().type == Lexeme.Type.InterpStringSimple then
		local results = Lexer.fixupQuotedString(self.scratchData)
		if results.success then
			self.scratchData = assert(results.result)
		else
			self:nextLexeme()
			return nil
		end
	else
		Lexer.fixupMultilineString(self.scratchData)
	end

	local value = self.scratchData
	self:nextLexeme()
	return value
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseString(self: Parser): AstExpr
	local location = self.lexer:current().location
	local value = self:parseCharArray(); if value then
		return AstExprConstantString.new(location, value)
	else
		return self:reportExprError(location, {}, "String literal contains malformed escape sequence")
	end
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseInterpString(self: Parser): AstExpr
	local strings = TempVector.new(self.scratchString)
	local expressions = TempVector.new(self.scratchExpr)

	local vectors = {strings, expressions}

	local startLocation = self.lexer:current().location
	local endLocation: Location

	while true do
		local currentLexeme = self.lexer:current()
		assert(currentLexeme.type == Lexeme.Type.InterpStringBegin or currentLexeme.type == Lexeme.Type.InterpStringMid or currentLexeme.type == Lexeme.Type.InterpStringEnd or currentLexeme.type == Lexeme.Type.InterpStringSimple)

		endLocation = currentLexeme.location

		self.scratchData = assert(currentLexeme.data)

		local results = Lexer.fixupQuotedString(self.scratchData)
		if results.success then
			self.scratchData = assert(results.result)
		else
			self:nextLexeme()
			return self:reportExprError(Location.new(startLocation, endLocation), {}, "Interpolated string literal contains malformed escape sequence")
		end

		local chars = self.scratchData

		self:nextLexeme()

		strings:push_back(chars)

		if currentLexeme.type == Lexeme.Type.InterpStringEnd or currentLexeme.type == Lexeme.Type.InterpStringSimple then
			break
		end

		local errorWhileChecking = false

		local case = self.lexer:current().type
		if case == Lexeme.Type.InterpStringMid or case == Lexeme.Type.InterpStringEnd then
			errorWhileChecking = true
			self:nextLexeme()
			expressions:push_back(self:reportExprError(endLocation, {}, "Malformed interpolated string, expected expression inside '{}'"))
		elseif case == Lexeme.Type.BrokenString then
			errorWhileChecking = true
			self:nextLexeme()
			expressions:push_back(self:reportExprError(endLocation, {}, "Malformed interpolated string; did you forget to add a '`'?"))
		else
			expressions:push_back(self:parseExpr())
		end

		if errorWhileChecking then
			break
		end

		local case2 = self.lexer:current().type
		if case == Lexeme.Type.InterpStringBegin or case == Lexeme.Type.InterpStringMid or case == Lexeme.Type.InterpStringEnd then
			break
		elseif case == Lexeme.Type.BrokenInterpDoubleBrace then
			self:nextLexeme()
			destroy(vectors)
			return self:reportExprError(endLocation, {}, "Double braces are not permitted within interpolated strings; did you mean '\\{'?")
		elseif case == Lexeme.Type.BrokenString then
			self:nextLexeme()
			destroy(vectors)
			return self:reportExprError(endLocation, {}, "Malformed interpolated string; did you forget to add a '}'?")
		else
			return self:reportExprError(endLocation, {}, "Malformed interpolated string, got %s", self.lexer:current():toString())
		end
	end

	local stringsArray = self:copy(strings)
	local expressionsArray = self:copy(expressions)

	strings:destroy()
	expressions:destroy()

	return AstExprInterpString.new(Location.new(startLocation, endLocation), stringsArray, expressionsArray)
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.parseNumber(self: Parser): AstExpr
	local start = self.lexer:current().location

	self.scratchData = assert(self.lexer:current().data)

	-- Remove all internal _ - they don't hold any meaning and this allows parsing code to just pass the string pointer to strtod et al
	if self.scratchData:find("_") then
		self.scratchData:gsub("_", "")
	end

	local results = parseDouble(self.scratchData)
	local result = results.outcome
	local value = results.result
	self:nextLexeme()

	if result == ConstantNumberParseResult.Malformed then
		return self:reportExprError(start, {}, "Malformed number")
	end

	return AstExprConstantNumber.new(start, assert(value), result)
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.pushLocal(self: Parser, binding: Binding): AstLocal
	local name = binding.name
	local localAst = self.localMap[name.name]

	localAst = AstLocal.new(name.name, name.location, --[[ shadow= ]] localAst, self.functionStack:size() - 1, self.functionStack:back().loopDepth, binding.annotation)

	self.localStack:push_back(localAst)

	return localAst
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.saveLocals(self: Parser): number
	return self.localStack:size()
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.restoreLocals(self: Parser, offset: number): ()
	for i = self.localStack:size(), offset + 1, -1 do
		local l = self.localStack:get(i)

		self.localMap[l.name] = l.shadow
	end

	self.localStack:resize(offset)
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.expectAndConsume(self: Parser, value: string | number, context: string?): boolean
	local typeLex: number
	if type(value) == "string" then
		typeLex = value:byte()
	else
		typeLex = value
	end

	if self.lexer:current().type ~= typeLex then
		self:expectAndConsumeFail(typeLex, context)

		-- check if this is an extra token and the expected token is next
		if self.lexer:lookahead().type == typeLex then
			-- skip invalid and consume expected
			self:nextLexeme()
			self:nextLexeme()
		end

		return false
	else
		self:nextLexeme()
		return true
	end
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.expectAndConsumeFail(self: Parser, typeLex: number, context: string?): ()
	local typeString = Lexeme.new(Location.new(Position.new(0, 0), 0), typeLex):toString()
	local currLexemeString = self.lexer:current():toString()

	if context then
		self:report(self.lexer:current().location, "Expected %s when parsing %s, got %s", typeString, context, currLexemeString)
	else
		self:report(self.lexer:current().location, "Expected %s, got %s", typeString, currLexemeString)
	end
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.expectMatchAndConsume(self: Parser, value: string, begin: Lexeme, searchForMissing: boolean?): boolean
	local typeLex = value:byte()

	if self.lexer:current().type ~= typeLex then
		local beginMatch = MatchLexeme.new(begin)

		self:expectMatchAndConsumeFail(typeLex, beginMatch)

		return self:expectMatchAndConsumeRecover(value, beginMatch, searchForMissing)
	else
		self:nextLexeme()

		return true
	end
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.expectMatchAndConsumeRecover(self: Parser, value: string, begin: MatchLexeme, searchForMissing: boolean?): boolean
	local typeLex = value:byte()

	if searchForMissing then
		-- previous location is taken because 'current' lexeme is already the next token
		local currentLine = self.lexer:previousLocation().finish.line

		-- search to the end of the line for expected token
		-- we will also stop if we hit a token that can be handled by parsing function above the current one
		local lexemeType = self.lexer:current().type

		while currentLine == self.lexer:current().location.begin.line and lexemeType ~= typeLex and self.matchRecoveryStopOnToken:get(lexemeType) == 0 do
			self:nextLexeme()
			lexemeType = self.lexer:current().type
		end

		if lexemeType == typeLex then
			self:nextLexeme()
			
			return true
		end
	else
		-- check if this is an extra token and the expected token is next
		if self.lexer:lookahead().type == typeLex then
			-- skip invalid and consume expected
			self:nextLexeme()
			self:nextLexeme()

			return true
		end
	end

	return false
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.expectMatchAndConsumeFail(self: Parser, typeLex: number, begin: MatchLexeme, extra: string?): ()
	local typeString = Lexeme.new(Location.new(Position.new(0, 0), 0), typeLex):toString()
	local matchString = Lexeme.new(Location.new(Position.new(0, 0), 0), begin.type):toString()

	if self.lexer:current().location.begin.line == begin.position.line then
		self:report(self.lexer:current().location, "Expected %s (to close %s at column %d), got %s%s", typeString, matchString, begin.position.column + 1, self.lexer:current():toString(), extra or "")
	else
		self:report(self.lexer:current().location, "Expected %s (to close %s at line %d), got %s%s", typeString, matchString, begin.position.line + 1, self.lexer:current():toString(), extra or "")
	end
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.expectMatchEndAndConsume(self: Parser, typeLex: number, begin: Lexeme): boolean
	local beginMatch = MatchLexeme.new(begin)

	if self.lexer:current().type ~= typeLex then
		self:expectMatchEndAndConsumeFail(typeLex, beginMatch)

		-- check if this is an extra token and the expected token is next
		if self.lexer:lookahead().type == typeLex then
			-- skip invalid and consume expected
			self:nextLexeme()
			self:nextLexeme()

			return true
		end

		return false
	else
		-- If the token matches on a different line and a different column, it suggests misleading indentation
		-- This can be used to pinpoint the problem location for a possible future *actual* mismatch
		if self.lexer:current().location.begin.line ~= beginMatch.position.line and self.lexer:current().location.begin.column ~= beginMatch.position.column and self.endMismatchSuspect.position.line < beginMatch.position.line then -- Only replace the previous suspect with more recent suspects
		self.endMismatchSuspect = beginMatch
		end

		self:nextLexeme()

		return true
	end
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.expectMatchEndAndConsumeFail(self: Parser, typeLex: number, begin: MatchLexeme): ()
	if self.endMismatchSuspect.type ~= Lexeme.Type.Eof and self.endMismatchSuspect.position.line > begin.position.line then
		local matchString = Lexeme.new(Location.new(Position.new(0, 0), 0), self.endMismatchSuspect.type):toString()
		local suggestion = ("; did you forget to close %s at line %d?"):format(matchString, self.endMismatchSuspect.position.line + 1)

		self:expectMatchAndConsumeFail(typeLex, begin, suggestion)
	else
		self:expectMatchAndConsumeFail(typeLex, begin)
	end
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.copy<T>(self: Parser, data: TempVector<T>): {T}
	return data:copy_data()
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.incrementRecursionCounter(self: Parser, context: string): ()
	self.recursionCounter += 1

	if self.recursionCounter > FastVariables.LuauRecursionLimit then
		ParseError.raise(self.lexer:current().location, "Exceeded allowed recursion depth; simplify your %s to make the code compile", context)
	end
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.report(self: Parser, location: Location, format: string, ...: any): ()
	-- To reduce number of errors reported to user for incomplete statements, we skip multiple errors at the same location
	-- For example, consider 'local a = (((b + ' where multiple tokens haven't been written yet
	if not self.parseErrors:empty() and location == self.parseErrors:back():getLocation() then
		return
	end

	local message = format:format(...)

	-- when limited to a single error, behave as if the error recovery is disabled
	if FastVariables.LuauParseErrorLimit == 1 then
		error(ParseError.new(location, message))
	end

	self.parseErrors:emplace_back(ParseError.new(location, message))

	if self.parseErrors:size() >= FastVariables.LuauParseErrorLimit then
		ParseError.raise(location, "Reached error limit (%d)", FastVariables.LuauParseErrorLimit)
	end
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.reportNameError(self: Parser, context: string?): ()
	if context then
		self:report(self.lexer:current().location, "Expected identifier when parsing %s, got %s", context, self.lexer:current():toString())
	else
		self:report(self.lexer:current().location, "Expected identifier, got %s", self.lexer:current():toString())
	end
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.reportStatError(self: Parser, location: Location, expressions: {AstExpr}, statements: {AstStat}, format: string, ...: string): AstStatError
	self:report(location, format, ...)
	
	return AstStatError.new(location, expressions, statements, unsigned(self.parseErrors:size() - 1))
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.reportExprError(self: Parser, location: Location, expressions: {AstExpr}, format: string, ...: string): AstExprError
	self:report(location, format, ...)

	return AstExprError.new(location, expressions, unsigned(self.parseErrors:size() - 1))
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.reportTypeError(self: Parser, location: Location, types: {AstType}, format: string, ...: string): AstTypeError
	self:report(location, format, ...)

	return AstTypeError.new(location, types, false, unsigned(self.parseErrors:size() - 1))
end

--[=[
	@within Parser
	@private
	@since v0.1.0
]=]
function prototype.reportMissingTypeError(self: Parser, parseErrorLocation: Location, astErrorLocation: Location, format: string, ...: string): AstTypeError
	self:report(parseErrorLocation, format, ...)

	return AstTypeError.new(astErrorLocation, {}, true, unsigned(self.parseErrors:size() - 1))
end

--[=[
	@within Parser
	@private
	@since v0.1.0

	Computes the next lexeme. If specified, the parser will collect [comments](Comment) and [hot comments](HotComment).
]=]
function prototype.nextLexeme(self: Parser): ()
	local typeLex = self.lexer:next(--[[ skipComments= ]] false, true).type

	while typeLex == Lexeme.Type.BrokenComment or typeLex == Lexeme.Type.Comment or typeLex == Lexeme.Type.BlockComment do
		local lexeme = self.lexer:current()

		if self.options.captureComments then
			self.commentLocations:push_back(Comment.new(lexeme.type, lexeme.location))
			
			-- Subtlety: Broken comments are weird because we record them as comments AND pass them to the parser as a lexeme.
			-- The parser will turn this into a proper syntax error.
			if lexeme.type == Lexeme.Type.BrokenComment then
				return
			end

			-- Comments starting with ! are called "hot comments" and contain directives for type checking / linting / compiling
			if lexeme.type == Lexeme.Type.Comment and lexeme:getLength() > 0 and lexeme.data and lexeme.data:sub(1, 1) == "!" then
				local text = lexeme.data

				local firstSpace = text:find("%s") or #text + 1
				self.hotcomments:push_back(HotComment.new(self.hotcommentHeader, lexeme.location, text:sub(2, firstSpace - 1)))
			end

			typeLex = self.lexer:next(false, false).type
		end
	end
end

-- Eli: Goofy Ahh Old Luau Type Inference Engine says that the Parser does not have any methods defined below this loop, thus we must write the loop at the bottom of the script.
for index, pair in BINARY_PRIORITY do
	binaryPriority[index] = BinaryOpPriority.new(pair[1], pair[2])
end

return Parser