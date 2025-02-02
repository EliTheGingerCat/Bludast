local AstExpr = require("@Ast/AstExpr")
local AstExprCall = require("@Ast/AstExprCall")
local AstExprFunction = require("@Ast/AstExprFunction")
local AstExprTable = require("@Ast/AstExprTable")
local AstLocal = require("@Ast/AstLocal")
local AstName = require("@Ast/AstName")
local AstNameTable = require("@Ast/AstNameTable")
local BytecodeBuilder = require("./BytecodeBuilder")
local CompileOptions = require("./CompileOptions")
local FastVariables = require("@Ast/FastVariables")
local LuauProtoFlag = require("@Common/Bytecode/LuauProtoFlag")
local Parser = require("@Ast/Parser")
local ParseErrors = require("@Ast/ParseErrors")
local ParseResult = require("@Ast/ParseResult")
local ParseOptions = require("@Ast/ParseOptions")
local TimeTrace = require("@Ast/TimeTrace")
local Vector = require("@Ast/Vector")

type AstExpr = AstExpr.AstExpr
type AstExprCall = AstExprCall.AstExprCall
type AstExprFunction = AstExprFunction.AstExprFunction
type AstExprTable = AstExprTable.AstExprTable
type AstLocal = AstLocal.AstLocal
type AstName = AstName.AstName
type AstNameTable = AstNameTable.AstNameTable
type BytecodeBuilder = BytecodeBuilder.BytecodeBuilder
type CompileOptions = CompileOptions.CompileOptions
local LUAU_TIMETRACE_SCOPE = TimeTrace.LUAU_TIMETRACE_SCOPE
type ParseResult = ParseResult.ParseResult
type ParseOptions = ParseOptions.ParseOptions
type Vector<T> = Vector.Vector<T>

type Local = {
	reg: number,
	allocated: boolean,
	captured: boolean,
	debugpc: number,
	allocpc: number
}

local prototype = {}

--[=[
	@class Compiler
	@prototype prototype
]=]
local Compiler = {
	prototype = prototype
}

local metatable = {
	__index = prototype
}

export type Compiler = typeof(setmetatable({} :: {
	bytecode: BytecodeBuilder,

	options: CompileOptions,

	functions: {[AstExprFunction]: any}, -- Eli: TODO
	locals: {[AstLocal]: Local},
	globals: {[AstName]: any}, -- Eli: TODO
	variables: {[AstName]: any}, -- Eli: TODO
	constants: {[AstExpr]: any}, -- Eli: TODO
	locstants: {[AstLocal]: any}, -- Eli: TODO
	tableShapes: {[AstExprTable]: any}, -- Eli: TODO
	builtins: {[AstExprCall]: number}, -- Eli: TODO
	userdataTypes: {[AstName]: number}, -- Eli: TODO
	functionTypes: {[AstExprFunction]: string}, -- Eli: TODO
	localTypes: {[AstLocal]: number}, -- Eli: TODO
	exprTypes: {[AstExpr]: number}, -- Eli: TODO

	builtinsFold: {[AstExprCall]: number}?,
	builtinsFoldMathK: boolean,

	-- compileFunction state, gets reset for every function
	regTop: number,
	stackSize: number,
	argCount: number,
	hasLoops: boolean,

	getfenvUsed: boolean,
	setfenvUsed: boolean,

	localStack: Vector<AstLocal>,
	upvals: Vector<AstLocal>,
	loopJumps: Vector<any>, -- Eli: TODO
	loops: Vector<any>, -- Eli: TODO
	inlineFrames: Vector<any>, -- Eli: TODO
	captures: Vector<any>, -- Eli: TODO
	interpStrings: Vector<string>
}, metatable))

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function Compiler.new(bytecode: BytecodeBuilder, options: CompileOptions): Compiler
	local self: Compiler = setmetatable({
		bytecode = bytecode,
		options = options,
		functions = {},
		locals = {},
		globals = {},
		variables = {},
		constants = {},
		locstants = {},
		tableShapes = {},
		builtins = {},
		userdataTypes = {},
		functionTypes = {},
		localTypes = {},
		exprTypes = {},
		builtinTypes = {},

		builtinsFoldMathK = false,
		regTop = 0,
		stackSize = 0,
		argCount = 0,
		hasLoops = false,
		getfenvUsed = false,
		setfenvUsed = false,
		localStack = Vector.new(),
		upvals = Vector.new(),
		loopJumps = Vector.new(),
		loops = Vector.new(),
		inlineFrames = Vector.new(),
		captures = Vector.new(),
		interpStrings = Vector.new()
	}, metatable)

	-- preallocate some buffers that are very likely to grow anyway; this works around std::vector's inefficient growth policy for small arrays
	self.localStack:reserve(16)
	self.upvals:reserve(16)
	
	return self
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.getLocalReg(self: Compiler, astLocal: AstLocal): number
	local l: Local? = self.locals[astLocal]

	return if l and l.allocated then l.reg else -1
end

--[=[
	@within Compiler
	@private
	@tag local
]=]
local function setCompileOptionsForNativeCompilation(options: CompileOptions): ()
	options.optimizationLevel = 2 -- note: this might be removed in the future in favor of --!optimize

	if FastVariables.LuauCompileTypeInfo then
		options.typeInfoLevel = 1
	end
end

--[=[
	@within Compiler
	@function compileOrThrow
	@param bytecode BytecodeBuilder
	@param a2 overloaded
	@param a3 overloaded
	@param a4 overloaded
	@since v0.1.0

	Overloads:

	- 1
	  - bytecode: [BytecodeBuilder]
	  - parseResult: [ParseResult]
	  - names: [AstNameTable]
	  - inputOptions: [CompileOptions]
	- 2
	  - bytecode: [BytecodeBuilder]
	  - source: string
	  - options: [CompileOptions]?
	  - parseOptions: [ParseOptions]?
]=]
Compiler.compileOrThrow = function(bytecode, a2: any, a3: any, a4: any)
	local parseResult: ParseResult
	local names: AstNameTable
	local options: CompileOptions

	if type(a2) == "string" then
		local source = a2
		options = a3 or CompileOptions.new()
		local parseOptions: ParseOptions = a4 or ParseOptions.new()

		names = AstNameTable.new()
		local result = Parser.parse(source, #source, names, parseOptions)

		if not result.errors:empty() then
			error(ParseErrors.new(result.errors))
		end

		parseResult = result
	else
		parseResult = a2
		names = a3
		options = a4
	end

	LUAU_TIMETRACE_SCOPE("compileOrThrow", "Compiler")

	assert(parseResult.root)
	assert(parseResult.errors:empty())

	local mainFlags = 0

	for _, hc in parseResult.hotcomments:data() do
		if hc.header and hc.content:sub(0, 9) == "optimize " then
			options.optimizationLevel = math.max(0, math.min(2, assert(tonumber(hc.content:sub(10)))))
		end

		if hc.header and hc.content == "native" then
			mainFlags = bit32.bor(mainFlags, LuauProtoFlag.LPF_NATIVE_MODULE)
			setCompileOptionsForNativeCompilation(options)
		end
	end

	local root = parseResult.root
	
	-- gathers all functions with the invariant that all function references are to functions earlier in the list
	-- for example, function foo() return function() end end will result in two vector entries, [0] = anonymous and [1] = foo
	local functions = Vector.new()
	-- Eli: TODO
end :: (
	  ((bytecode: BytecodeBuilder, parseResult: ParseResult, names: AstNameTable, inputOptions: CompileOptions) -> ())
	& ((bytecode: BytecodeBuilder, source: string, options: CompileOptions?, parseOptions: ParseOptions?) -> ())
)

return Compiler