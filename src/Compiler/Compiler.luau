local AstExpr = require("@Ast/AstExpr")
local AstExprCall = require("@Ast/AstExprCall")
local AstExprFunction = require("@Ast/AstExprFunction")
local AstExprGlobal = require("@Ast/AstExprGlobal")
local AstExprTable = require("@Ast/AstExprTable")
local AstLocal = require("@Ast/AstLocal")
local AstName = require("@Ast/AstName")
local AstNameTable = require("@Ast/AstNameTable")
local AstStat = require("@Ast/AstStat")
local AstStatBlock = require("@Ast/AstStatBlock")
local AstStatBreak = require("@Ast/AstStatBreak")
local AstStatContinue = require("@Ast/AstStatContinue")
local AstStatIf = require("@Ast/AstStatIf")
local AstStatReturn = require("@Ast/AstStatReturn")
local AstVisitor = require("@Ast/AstVisitor")
local Builtins = require("./Builtins")
local BytecodeBuilder = require("./BytecodeBuilder")
local CompileError = require("./CompileError")
local CompileOptions = require("./CompileOptions")
local Constant = require("./CompilerConstant")
local ConstantFolding = require("./ConstantFolding")
local FastVariables = require("@Shared/FastVariables")
local LuauBytecodeType = require("@Common/Bytecode/LuauBytecodeType")
local LuauProtoFlag = require("@Common/Bytecode/LuauProtoFlag")
local Parser = require("@Ast/Parser")
local ParseErrors = require("@Ast/ParseErrors")
local ParseResult = require("@Ast/ParseResult")
local ParseOptions = require("@Ast/ParseOptions")
local TableShape = require("./TableShape")
local TimeTrace = require("@Shared/TimeTrace")
local ValueTracking = require("./ValueTracking")
local Vector = require("@Polyfill/Vector")

local analyzeBuiltins = Builtins.analyzeBuiltins
local assignMutable = ValueTracking.assignMutable
type AstExpr = AstExpr.AstExpr
type AstExprCall = AstExprCall.AstExprCall
type AstExprFunction = AstExprFunction.AstExprFunction
type AstExprGlobal = AstExprGlobal.AstExprGlobal
type AstExprTable = AstExprTable.AstExprTable
type AstLocal = AstLocal.AstLocal
type AstName = AstName.AstName
type AstNameTable = AstNameTable.AstNameTable
type AstStat = AstStat.AstStat
type AstStatBlock = AstStatBlock.AstStatBlock
type AstStatBreak = AstStatBreak.AstStatBreak
type AstStatContinue = AstStatContinue.AstStatContinue
type AstStatIf = AstStatIf.AstStatIf
type AstStatReturn = AstStatReturn.AstStatReturn
type AstVisitor = AstVisitor.AstVisitor
type BytecodeBuilder = BytecodeBuilder.BytecodeBuilder
type CompileOptions = CompileOptions.CompileOptions
type Constant = Constant.Constant
local foldConstants = ConstantFolding.foldConstants
local getGlobalState = ValueTracking.getGlobalState
local Global = ValueTracking.Global
local LUAU_TIMETRACE_SCOPE = TimeTrace.LUAU_TIMETRACE_SCOPE
type ParseResult = ParseResult.ParseResult
type ParseOptions = ParseOptions.ParseOptions
local predictTableShapes = TableShape.predictTableShapes
local trackValues = ValueTracking.trackValues
type Variable = ValueTracking.Variable
type Vector<T> = Vector.Vector<T>

local kMaxUpvalueCount = 200

local prototypeFenvVisitor = setmetatable({}, AstVisitor.metatable)
local metatableFenvVisitor = {__index = prototypeFenvVisitor}
local FenvVisitor = {}
type FenvVisitor = AstVisitor & {
	compiler: Compiler
}

function FenvVisitor.new(compiler: Compiler): FenvVisitor
	local self = AstVisitor.new() :: FenvVisitor
	self.compiler = compiler
	setmetatable(self, metatableFenvVisitor)
	return self
end

function prototypeFenvVisitor.visitAstExprGlobal(self: FenvVisitor, node: AstExprGlobal): boolean
	if node.name.value == "getfenv" then
		self.compiler.getfenvUsed = true
	end
	if node.name.value == "setfenv" then
		self.compiler.setfenvUsed = true
	end

	return false
end

local prototypeFunctionVisitor = setmetatable({}, AstVisitor.metatable)
local metatableFunctionVisitor = {__index = prototypeFunctionVisitor}
local FunctionVisitor = {}
type FunctionVisitor = AstVisitor & {
	functions: Vector<AstExprFunction>,
	hasTypes: boolean,
	hasNativeFunction: boolean
}

function FunctionVisitor.new(functions: Vector<AstExprFunction>): FunctionVisitor
	local self = AstVisitor.new() :: FunctionVisitor
	self.functions = functions
	self.hasTypes = false
	self.hasNativeFunction = false
	-- preallocate the result; this works around std::vector's inefficient growth policy for small arrays
	self.functions:reserve(16)
	setmetatable(self, metatableFunctionVisitor)
	return self
end

function prototypeFunctionVisitor.visitAstExprFunction(self: FunctionVisitor, node: AstExprFunction): boolean
	node.body:visit(self)

	for _, arg in node.args do
		self.hasTypes = self.hasTypes or (arg.annotation ~= nil)
	end

	-- this makes sure all functions that are used when compiling this one have been already added to the vector
	self.functions:push_back(node)

	if FastVariables.LuauNativeAttribute and not self.hasNativeFunction and node:hasNativeAttribute() then
		self.hasNativeFunction = true
	end

	return false
end

local Function = {}

type Function = {
	id: number,
	upvals: Vector<AstLocal>,
	costModel: number,
	stackSize: number,
	canInline: boolean,
	returnsOne: boolean
}

function Function.new(): Function
	return {
		id = 0,
		upvals = Vector.new(),
		costModel = 0,
		stackSize = 0,
		canInline = false,
		returnsOne = false
	}
end

local Local = {}

type Local = {
	reg: number,
	allocated: boolean,
	captured: boolean,
	debugpc: number,
	allocpc: number
}

function Local.new(): Local
	return {
		reg = 0,
		allocated = false,
		captured = false,
		debugpc = 0,
		allocpc = 0
	}
end

local LoopJump = {
	Type = {
		Break = 1,
		Continue = 2
	}
}

type LoopJump = {
	type: number,
	label: number
}

function LoopJump.new(): LoopJump
	return {
		type = LoopJump.Type.Break,
		label = 0
	}
end

local Loop = {}

type Loop = {
	localOffset: number,
	localOffsetContinue: number,
	continueUsed: AstStatContinue?
}

function Loop.new(): Loop
	return {
		localOffset = 0,
		localOffsetContinue = 0
	}
end

local InlineArg = {}

type InlineArg = {
	astLocal: AstLocal?,
	reg: number,
	value: Constant?,
	allocpc: number
}

function InlineArg.new(): InlineArg
	return {
		reg = 0,
		allocpc = 0
	}
end

local prototype = {}

--[=[
	@class Compiler
	@__index prototype
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

	functions: {[AstExprFunction]: Function},
	locals: {[AstLocal]: Local},
	globals: {[AstName]: number},
	variables: {[AstLocal]: Variable},
	constants: {[AstExpr]: Constant},
	locstants: {[AstLocal]: any}, -- Eli: TODO
	tableShapes: {[AstExprTable]: any}, -- Eli: TODO
	builtins: {[AstExprCall]: number},
	userdataTypes: {[AstName]: number}, -- Eli: TODO
	functionTypes: {[AstExprFunction]: string},
	localTypes: {[AstLocal]: number}, -- Eli: TODO
	exprTypes: {[AstExpr]: number}, -- Eli: TODO

	builtinsFold: {[AstExprCall]: number},
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
	loopJumps: Vector<LoopJump>,
	loops: Vector<Loop>,
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

		builtinsFold = {},
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
	@since v0.1.0
]=]
function prototype.getUpval(self: Compiler, astLocal: AstLocal): number
	for uid = 1, self.upvals:size() do
		if self.upvals[uid] == astLocal then
			return uid
		end
	end

	if self.upvals:size() >= kMaxUpvalueCount then
		CompileError.raise(
			astLocal.location,
			"Out of upvalue registers when trying to allocate %s: exceeded limit %d",
			astLocal.name.value,
			kMaxUpvalueCount
		)
	end

	-- mark local as captured so that closeLocals emits LOP_CLOSEUPVALS accordingly
	local v = self.variables[astLocal]

	if v and v.written then
		self.locals[astLocal].captured = true
	end

	self.upvals:push_back(astLocal)

	return self.upvals:size() - 1
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.alwaysTerminates(self: Compiler, node: AstStat): boolean
	local statBlock = node:as(AstStatBlock)
	local statIf = node:as(AstStatIf)

	if statBlock then
		return #statBlock.body > 0 and self:alwaysTerminates(statBlock.body[#statBlock.body])
	elseif node:is(AstStatReturn) then
		return true
	elseif node:is(AstStatBreak) or node:is(AstStatContinue) then
		return true
	elseif statIf then
		return statIf.elsebody and self:alwaysTerminates(statIf.thenbody) and self:alwaysTerminates(statIf.elsebody)
	else
		return false
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.emitLoadK(self: Compiler, target: number, cid: number)
	assert(cid >= 0)

	if cid < 32768 then
		self.bytecode:emitAD()
	end
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
Compiler.compileOrThrow = function(bytecode: BytecodeBuilder, a2: any, a3: any, a4: any)
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
	local functions: Vector<AstExprFunction> = Vector.new()
	local functionVisitor = FunctionVisitor.new(functions)
	root:visit(functionVisitor)

	if functionVisitor.hasNativeFunction then
		setCompileOptionsForNativeCompilation(options)
	end

	local compiler = Compiler.new(bytecode, options)

	-- since access to some global objects may result in values that change over time, we block imports from non-readonly tables
	assignMutable(compiler.globals, names, options.mutableGlobals)

	-- this pass analyzes mutability of locals/globals and associates locals with their initial values
    trackValues(compiler.globals, compiler.variables, root)

	-- this visitor tracks calls to getfenv/setfenv and disables some optimizations when they are found
	if options.optimizationLevel >= 1 and (names:get("getfenv").value or names:get("setfenv").value) then
		local fenvVisitor = FenvVisitor.new(compiler)
		root:visit(fenvVisitor)
	end

	-- builtin folding is enabled on optimization level 2 since we can't deoptimize folding at runtime
	if options.optimizationLevel >= 2 and (not compiler.getfenvUsed and not compiler.setfenvUsed) then
		compiler.builtinsFold = compiler.builtins

		local nameMath = names:get("math")
		if nameMath.value and getGlobalState(compiler.globals, nameMath) == Global.Default then
			compiler.builtinsFoldMathK = true
		end
	end

	if options.optimizationLevel >= 1 then
		-- this pass tracks which calls are builtins and can be compiled more efficiently
		analyzeBuiltins(compiler.builtins, compiler.globals, compiler.variables, options, root)

		-- this pass analyzes constantness of expressions
		foldConstants(compiler.constants, compiler.variables, compiler.locstants, compiler.builtinsFold, compiler.builtinsFoldMathK, root)

		-- this pass analyzes table assignments to estimate table shapes for initially empty tables
		predictTableShapes(compiler.tableShapes, root)
	end

	if FastVariables.LuauCompileUserdataInfo then
		for _, userdataType in options.userdataTypes do
			-- Type will only resolve to an AstName if it is actually mentioned in the source
			local name = names:get(userdataType)
			if name.value then
				compiler.userdataTypes[name] = bytecode:addUserdataType(name.value)
			end
		end

		if #options.userdataTypes > (LuauBytecodeType.LBC_TYPE_TAGGED_USERDATA_END - LuauBytecodeType.LBC_TYPE_TAGGED_USERDATA_BASE) then
			CompileError.raise(root.location, "Exceeded userdata type limit in the compilation options")
		end
	end

	-- computes type information for all functions based on type annotations
	if FastVariables.LuauCompileTypeInfo then
		if options.typeInfoLevel >= 1 then
			
		end
	end
end :: (
	  ((bytecode: BytecodeBuilder, parseResult: ParseResult, names: AstNameTable, inputOptions: CompileOptions) -> ())
	& ((bytecode: BytecodeBuilder, source: string, options: CompileOptions?, parseOptions: ParseOptions?) -> ())
)

return Compiler