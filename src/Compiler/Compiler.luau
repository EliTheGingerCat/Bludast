--!nolint LocalShadow

local AstExpr = require("@Ast/AstExpr")
local AstExprBinary = require("@Ast/AstExprBinary")
local AstExprCall = require("@Ast/AstExprCall")
local AstExprConstantBool = require("@Ast/AstExprConstantBool")
local AstExprConstantNil = require("@Ast/AstExprConstantNil")
local AstExprConstantNumber = require("@Ast/AstExprConstantNumber")
local AstExprConstantString = require("@Ast/AstExprConstantString")
local AstExprFunction = require("@Ast/AstExprFunction")
local AstExprGlobal = require("@Ast/AstExprGlobal")
local AstExprGroup = require("@Ast/AstExprGroup")
local AstExprIfElse = require("@Ast/AstExprIfElse")
local AstExprIndexExpr = require("@Ast/AstExprIndexExpr")
local AstExprIndexName = require("@Ast/AstExprIndexName")
local AstExprInterpString = require("@Ast/AstExprInterpString")
local AstExprLocal = require("@Ast/AstExprLocal")
local AstExprTable = require("@Ast/AstExprTable")
local AstExprTypeAssertion = require("@Ast/AstExprTypeAssertion")
local AstExprUnary = require("@Ast/AstExprUnary")
local AstExprVarargs = require("@Ast/AstExprVarargs")
local AstLocal = require("@Ast/AstLocal")
local AstName = require("@Ast/AstName")
local AstNode = require("@Ast/AstNode")
local AstNameTable = require("@Ast/AstNameTable")
local AstStat = require("@Ast/AstStat")
local AstStatAssign = require("@Ast/AstStatAssign")
local AstStatBlock = require("@Ast/AstStatBlock")
local AstStatBreak = require("@Ast/AstStatBreak")
local AstStatCompoundAssign = require("@Ast/AstStatCompoundAssign")
local AstStatExpr = require("@Ast/AstStatExpr")
local AstStatFor = require("@Ast/AstStatFor")
local AstStatForIn = require("@Ast/AstStatForIn")
local AstStatFunction = require("@Ast/AstStatFunction")
local AstStatContinue = require("@Ast/AstStatContinue")
local AstStatIf = require("@Ast/AstStatIf")
local AstStatLocal = require("@Ast/AstStatLocal")
local AstStatLocalFunction = require("@Ast/AstStatLocalFunction")
local AstStatRepeat = require("@Ast/AstStatRepeat")
local AstStatReturn = require("@Ast/AstStatReturn")
local AstStatTypeAlias = require("@Ast/AstStatTypeAlias")
local AstStatWhile = require("@Ast/AstStatWhile")
local AstVisitor = require("@Ast/AstVisitor")
local Builtins = require("./Builtins")
local BytecodeBuilder = require("./BytecodeBuilder")
local BytecodeEncoder = require("./BytecodeEncoder")
local CompileError = require("./CompileError")
local CompileOptions = require("./CompileOptions")
local Constant = require("./CompilerConstant")
local ConstantFolding = require("./ConstantFolding")
local CostModel = require("./CostModel")
local FastVariables = require("@Shared/FastVariables")
local Location = require("@Shared/Location")
local LuauBuiltinFunction = require("@Common/Bytecode/LuauBuiltinFunction")
local LuauBytecodeType = require("@Common/Bytecode/LuauBytecodeType")
local LuauCaptureType = require("@Common/Bytecode/LuauCaptureType")
local LuauOpcode = require("@Common/Bytecode/LuauOpcode")
local LuauProtoFlag = require("@Common/Bytecode/LuauProtoFlag")
local NumberConversions = require("@Polyfill/NumberConversions")
local Parser = require("@Ast/Parser")
local ParseErrors = require("@Ast/ParseErrors")
local ParseResult = require("@Ast/ParseResult")
local ParseOptions = require("@Ast/ParseOptions")
local TableShape = require("./TableShape")
local TimeTrace = require("@Shared/TimeTrace")
local Types = require("./Types")
local ValueTracking = require("./ValueTracking")
local Vector = require("@Polyfill/Vector")

local analyzeBuiltins = Builtins.analyzeBuiltins
local assignMutable = ValueTracking.assignMutable
type AstExpr = AstExpr.AstExpr
type AstExprBinary = AstExprBinary.AstExprBinary
type AstExprCall = AstExprCall.AstExprCall
type AstExprConstantBool = AstExprConstantBool.AstExprConstantBool
type AstExprConstantNil = AstExprConstantNil.AstExprConstantNil
type AstExprConstantNumber = AstExprConstantNumber.AstExprConstantNumber
type AstExprConstantString = AstExprConstantString.AstExprConstantString
type AstExprFunction = AstExprFunction.AstExprFunction
type AstExprGlobal = AstExprGlobal.AstExprGlobal
type AstExprGroup = AstExprGroup.AstExprGroup
type AstExprIfElse = AstExprIfElse.AstExprIfElse
type AstExprIndexExpr = AstExprIndexExpr.AstExprIndexExpr
type AstExprIndexName = AstExprIndexName.AstExprIndexName
type AstExprInterpString = AstExprInterpString.AstExprInterpString
type AstExprLocal = AstExprLocal.AstExprLocal
type AstExprTable = AstExprTable.AstExprTable
type AstExprTypeAssertion = AstExprTypeAssertion.AstExprTypeAssertion
type AstExprUnary = AstExprUnary.AstExprUnary
type AstExprVarargs = AstExprVarargs.AstExprVarargs
type AstLocal = AstLocal.AstLocal
type AstName = AstName.AstName
type AstNode = AstNode.AstNode
type AstNameTable = AstNameTable.AstNameTable
type AstStat = AstStat.AstStat
type AstStatAssign = AstStatAssign.AstStatAssign
type AstStatBlock = AstStatBlock.AstStatBlock
type AstStatBreak = AstStatBreak.AstStatBreak
type AstStatCompoundAssign = AstStatCompoundAssign.AstStatCompoundAssign
type AstStatExpr = AstStatExpr.AstStatExpr
type AstStatFor = AstStatFor.AstStatFor
type AstStatForIn = AstStatForIn.AstStatForIn
type AstStatFunction = AstStatFunction.AstStatFunction
type AstStatContinue = AstStatContinue.AstStatContinue
type AstStatIf = AstStatIf.AstStatIf
type AstStatLocal = AstStatLocal.AstStatLocal
type AstStatLocalFunction = AstStatLocalFunction.AstStatLocalFunction
type AstStatRepeat = AstStatRepeat.AstStatRepeat
type AstStatReturn = AstStatReturn.AstStatReturn
type AstStatTypeAlias = AstStatTypeAlias.AstStatTypeAlias
type AstStatWhile = AstStatWhile.AstStatWhile
type AstVisitor = AstVisitor.AstVisitor
local btn = NumberConversions.booleanToNumber
local buildTypeMap = Types.buildTypeMap
local BuiltinTypes = Types.BuiltinTypes
type BuiltinTypes = Types.BuiltinTypes
type BytecodeBuilder = BytecodeBuilder.BytecodeBuilder
type BytecodeEncoder = BytecodeEncoder.BytecodeEncoder
type CompileError = CompileError.CompileError
type CompileOptions = CompileOptions.CompileOptions
local computeCost = CostModel.computeCost
type Constant = Constant.Constant
local foldConstants = ConstantFolding.foldConstants
local getBuiltin = Builtins.getBuiltin
local getBuiltinInfo = Builtins.getBuiltinInfo
local getGlobalState = ValueTracking.getGlobalState
local getTripCount = CostModel.getTripCount
local Global = ValueTracking.Global
local int16_t = NumberConversions.int16_t
type Location = Location.Location
local LUAU_TIMETRACE_ARGUMENT = TimeTrace.LUAU_TIMETRACE_ARGUMENT
local LUAU_TIMETRACE_SCOPE = TimeTrace.LUAU_TIMETRACE_SCOPE
local modelCost = CostModel.modelCost
type ParseResult = ParseResult.ParseResult
type ParseOptions = ParseOptions.ParseOptions
local predictTableShapes = TableShape.predictTableShapes
local StringRef = BytecodeBuilder.StringRef
type StringRef = BytecodeBuilder.StringRef
type TableShape = TableShape.TableShape
local trackValues = ValueTracking.trackValues
type u64 = NumberConversions.u64
local int = NumberConversions.int
local uint8_t = NumberConversions.uint8_t
local unsigned = NumberConversions.unsigned
type Variable = ValueTracking.Variable
type Vector<T> = Vector.Vector<T>

local kMaxRegisterCount = 255
local kMaxUpvalueCount = 200
local kMaxLocalCount = 200
local kMaxInstructionCount = 1_000_000_000

local kInvalidReg = 255

local kDefaultAllocPc = bit32.bnot(0)

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

local prototypeUndefinedLocalVisitor = setmetatable({}, AstVisitor.metatable)
local metatableUndefinedLocalVisitor = {__index = prototypeUndefinedLocalVisitor}
local UndefinedLocalVisitor = {}
type UndefinedLocalVisitor = AstVisitor & {
	compiler: Compiler,
	undef: AstLocal?,
	locals: {},

	check: (self: UndefinedLocalVisitor, astLocal: AstLocal) -> ()
}

function UndefinedLocalVisitor.new(compiler: Compiler): UndefinedLocalVisitor
	local self = AstVisitor.new() :: UndefinedLocalVisitor
	self.compiler = compiler
	self.locals = {}
	setmetatable(self, metatableUndefinedLocalVisitor)
	return self
end

function prototypeUndefinedLocalVisitor.check(self: UndefinedLocalVisitor, astLocal: AstLocal): ()
	if not self.undef and self.locals[astLocal] then
		self.undef = astLocal
	end
end

function prototypeUndefinedLocalVisitor.visitAstExprLocal(self: UndefinedLocalVisitor, node: AstExprLocal): boolean
	if not node.upvalue then
		self:check(node.localAst)
	end

	return false
end

function prototypeUndefinedLocalVisitor.visitAstExprFunction(self: UndefinedLocalVisitor, node: AstExprFunction): boolean
	local f = self.compiler.functions[node] :: any
	for _, uv: AstLocal in f.upvals:data() do
		assert(uv.functionDepth < node.functionDepth)

		if uv.functionDepth == node.functionDepth - 1 then
			self:check(uv)
		end
	end

	return false
end

local prototypeConstUpvalueVisitor = setmetatable({}, AstVisitor.metatable)
local metatableConstUpvalueVisitor = {__index = prototypeConstUpvalueVisitor}
local ConstUpvalueVisitor = {}
type ConstUpvalueVisitor = AstVisitor & {
	compiler: Compiler,
	upvals: Vector<AstLocal>
}

function ConstUpvalueVisitor.new(compiler: Compiler): ConstUpvalueVisitor
	local self = AstVisitor.new() :: ConstUpvalueVisitor
	self.compiler = compiler
	self.upvals = Vector.new()
	setmetatable(self, metatableConstUpvalueVisitor)
	return self
end

function prototypeConstUpvalueVisitor.visitAstExprLocal(self: ConstUpvalueVisitor, node: AstExprLocal): boolean
	if node.upvalue and self.compiler:isConstant(node) then
		self.upvals:push_back(node.localAst)
	end

	return false
end

function prototypeConstUpvalueVisitor.visitAstExprFunction(self: ConstUpvalueVisitor, node: AstExprFunction): boolean
	-- short-circuits the traversal to make it faster
	return false
end

local prototypeReturnVisitor = setmetatable({}, AstVisitor.metatable)
local metatableReturnVisitor = {__index = prototypeReturnVisitor}
local ReturnVisitor = {}
type ReturnVisitor = AstVisitor & {
	compiler: Compiler,
	returnsOne: boolean
}

function ReturnVisitor.new(compiler: Compiler): ReturnVisitor
	local self = AstVisitor.new() :: ReturnVisitor
	self.compiler = compiler
	self.returnsOne = true
	setmetatable(self, metatableReturnVisitor)
	return self
end

function prototypeReturnVisitor.visitAstExpr(self: ReturnVisitor, node: AstExpr): boolean
	return false
end

function prototypeReturnVisitor.visitAstStatReturn(self: ReturnVisitor, stat: AstStatReturn): boolean
	self.returnsOne = self.returnsOne and #stat.list == 1 and not self.compiler:isExprMultRet(stat.list[1])

	return false
end

local prototypeRegScope = {}
local metatableRegScope = {__index = prototypeRegScope}
local RegScope = {}

type RegScope = typeof(setmetatable({} :: {
	compiler: Compiler,
	oldTop: number
}, metatableRegScope))

function RegScope.new(compiler: Compiler, top: number?): RegScope
	local self = {}
	self.compiler = compiler
	self.oldTop = compiler.regTop
	if top then
		assert(top <= compiler.regTop)
		compiler.regTop = top
	end
	setmetatable(self, metatableRegScope)
	return self
end

function prototypeRegScope.destroy(self: RegScope): ()
	self.compiler.regTop = self.oldTop
end

local Function = {}

type Function = {
	id: number,
	upvals: Vector<AstLocal>,
	costModel: u64,
	stackSize: number,
	canInline: boolean,
	returnsOne: boolean
}

function Function.new(): Function
	return {
		id = 0,
		upvals = Vector.new(),
		costModel = NumberConversions.u64_zero,
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

function LoopJump.new(type: number, label: number): LoopJump
	return {
		type = type,
		label = label
	}
end

local Loop = {}

type Loop = {
	localOffset: number,
	localOffsetContinue: number,
	continueUsed: AstStatContinue?
}

function Loop.new(localOffset: number, localOffsetContinue: number, continueUsed: AstStatContinue?): Loop
	return {
		localOffset = localOffset,
		localOffsetContinue = localOffsetContinue,
		continueUsed = continueUsed
	}
end

local InlineArg = {}

type InlineArg = {
	astLocal: AstLocal,
	reg: number,
	value: Constant,
	allocpc: number
}

function InlineArg.new(astLocal: AstLocal, reg: number, value: Constant?, allocpc: number?): InlineArg
	return {
		astLocal = astLocal,
		reg = reg or 0,
		value = value or Constant.new(),
		allocpc = allocpc or 0
	}
end

local InlineFrame = {}

type InlineFrame = {
	func: AstExprFunction,

	localOffset: number,

	target: number,
	targetCount: number,

	returnJumps: Vector<number>
}

function InlineFrame.new(func: AstExprFunction, oldLocals: number, target: number, targetCount: number): InlineFrame
	return {
		func = func,
		localOffset = oldLocals,
		target = target,
		targetCount = targetCount,
		returnJumps = Vector.new()
	}
end

local Capture = {}

type Capture = {
	type: number,
	data: number
}

function Capture.new(type: number, data: number): Capture
	return {
		type = type,
		data = data
	}
end

local LValue = {
	Kind = {
		Kind_Local = 1,
		Kind_Upvalue = 2,
		Kind_Global = 3,
		Kind_IndexName = 4,
		Kind_IndexNumber = 5,
		Kind_IndexExpr = 6
	}
}

type LValue = {
	kind: number,
	reg: number, -- register for local (Local) or table (Index*)
	upval: number,
	index: number, -- register for index in IndexExpr
	number: number, -- index-1 (0-255) in IndexNumber
	name: StringRef,
	location: Location
}

function LValue.new(kind: number): LValue
	return {
		kind = kind,
		reg = 0,
		upval = 0,
		index = 0,
		number = 0,
		name = StringRef.new("", 0),
		location = Location.new()
	}
end

local Assignment = {}

type Assignment = {
	lvalue: LValue,

	conflictReg: number,
	valueReg: number
}

function Assignment.new(): Assignment
	return {
		lvalue = nil :: any,
		conflictReg = kInvalidReg,
		valueReg = kInvalidReg
	}
end

local sref = function(a1: any)
	if typeof(a1) == "table" then
		local name: AstName = a1
		assert(name.value)
		return StringRef.new(name.value, #name.value)
	else
		local data: string = a1
		return StringRef.new(data, #data)
	end
end :: 
	  ((name: AstName) -> StringRef)
	& ((data: string) -> StringRef)

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
	locstants: {[AstLocal]: Constant},
	tableShapes: {[AstExprTable]: TableShape},
	builtins: {[AstExprCall]: number},
	userdataTypes: {[AstName]: number},
	functionTypes: {[AstExprFunction]: string},
	localTypes: {[AstLocal]: number},
	exprTypes: {[AstExpr]: number},
	builtinTypes: BuiltinTypes,

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
	inlineFrames: Vector<InlineFrame>,
	captures: Vector<Capture>,
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
		builtinTypes = BuiltinTypes.new(options.vectorType),

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
		self.bytecode:emitAD(LuauOpcode.LOP_LOADK, target, cid)
	else
		self.bytecode:emitAD(LuauOpcode.LOP_LOADKX, target, 0)
		self.bytecode:emitAux(cid)
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.getFunctionExpr(self: Compiler, node: AstExpr): AstExprFunction?
	local exprLocal = node:as(AstExprLocal)
	local exprGroup = node:as(AstExprGroup)
	local exprAssertion = node:as(AstExprTypeAssertion)

	if exprLocal then
		local lv = self.variables[exprLocal.localAst]

		if not lv or lv.written or not lv.init then
			return nil
		end

		return self:getFunctionExpr(lv.init)
	elseif exprGroup then
		return self:getFunctionExpr(exprGroup.expr)
	elseif exprAssertion then
		return self:getFunctionExpr(exprAssertion.expr)
	else
		return node:as(AstExprFunction)
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileFunction(self: Compiler, func: AstExprFunction, protoflags: number): number
	local scope = LUAU_TIMETRACE_SCOPE("Compiler::compileFunction", "Compiler")

	if func.debugname.value then
		LUAU_TIMETRACE_ARGUMENT("name", func.debugname.value, scope)
	end

	assert(not self.functions[func])
	assert(self.regTop == 0 and self.stackSize == 0 and self.localStack:empty() and self.upvals:empty())

	local rs = RegScope.new(self)

	local funcSelf = if func.self then 1 else 0
	local fid = self.bytecode:beginFunction(uint8_t(funcSelf + #func.args), func.vararg)

	self:setDebugLine(func)

	if not FastVariables.LuauCompileTypeInfo then
		-- note: we move types out of typeMap which is safe because compileFunction is only called once per function
		local funcType = self.functionTypes[func]
		if funcType then
			self.bytecode:setFunctionTypeInfo(funcType)
		end
	end

	if func.vararg then
		self.bytecode:emitABC(LuauOpcode.LOP_PREPVARARGS, uint8_t(funcSelf + #func.args), 0, 0)
	end

	local args = self:allocReg(func, funcSelf + unsigned(#func.args))

	if func.self then
		self:pushLocal(func.self, args, kDefaultAllocPc)
	end

	for i, arg in func.args do
		self:pushLocal(arg :: AstLocal, uint8_t(args + funcSelf + i - 1), kDefaultAllocPc)
	end

	if FastVariables.LuauCompileTypeInfo then
		self.argCount = self.localStack:size()
	end

	local stat = func.body

	for i = 1, #stat.body do
		self:compileStat(stat.body[i])
	end
	
	-- valid function bytecode must always end with RETURN
	-- we elide this if we're guaranteed to hit a RETURN statement regardless of the control flow
	if not self:alwaysTerminates(stat) then
		self:setDebugLineEnd(stat)
		self:closeLocals(0)

		self.bytecode:emitABC(LuauOpcode.LOP_RETURN, 0, 1, 0)
	end

	-- constant folding may remove some upvalue refs from bytecode, so this puts them back
	if self.options.optimizationLevel >= 1 and self.options.debugLevel >= 2 then
		self:gatherConstUpvals(func)
	end

	self.bytecode:setDebugFunctionLineDefined(func.location.begin.line + 1)

	if self.options.debugLevel >= 1 and func.debugname.value then
		self.bytecode:setDebugFunctionName(sref(func.debugname))
	end
	
	if self.options.debugLevel >= 2 and not self.upvals:empty() then
		for _, l in self.upvals:data() do
			self.bytecode:pushDebugUpval(sref(l.name))
		end
	end

	if FastVariables.LuauCompileTypeInfo and self.options.typeInfoLevel >= 1 then
		for _, l in self.upvals:data() do
			local ty = LuauBytecodeType.LBC_TYPE_ANY

			local recordedTy = self.localTypes[l :: AstLocal]
			if recordedTy then
				ty = recordedTy
			end

			self.bytecode:pushUpvalTypeInfo(ty)
		end
	end

	if self.options.optimizationLevel >= 1 then
		self.bytecode:foldJumps()
	end

	self.bytecode:expandJumps()

	self:popLocals(0)

	if self.bytecode:getInstructionCount() > kMaxInstructionCount then
		CompileError.raise(func.location, "Exceeded function instruction limit; split the function into parts to compile")
	end

	if FastVariables.LuauCompileTypeInfo then
		-- note: we move types out of typeMap which is safe because compileFunction is only called once per function
		local funcType = self.functionTypes[func]
		if funcType then
			self.bytecode:setFunctionTypeInfo(funcType)
		end
	end

	-- top-level code only executes once so it can be marked as cold if it has no loops; code with loops might be profitable to compile natively
	if func.functionDepth == 0 and not self.hasLoops then
		protoflags = bit32.bor(protoflags, LuauProtoFlag.LPF_NATIVE_COLD)
	end

	if FastVariables.LuauNativeAttribute and func:hasNativeAttribute() then
		protoflags = bit32.bor(protoflags, LuauProtoFlag.LPF_NATIVE_FUNCTION)
	end

	self.bytecode:endFunction(uint8_t(self.stackSize), uint8_t(self.upvals:size()), protoflags)

	local f = self.functions[func]
	f.id = fid
	local upvals: Vector<AstLocal> = Vector.new()
	for _, upval in self.upvals:data() do
		upvals:push_back(upval :: AstLocal)
	end
	f.upvals = upvals

	-- record information for inlining
	if self.options.optimizationLevel >= 2 and not func.vararg and func.self == nil and not self.getfenvUsed and not self.setfenvUsed then
		f.canInline = true
		f.stackSize = self.stackSize
		f.costModel = modelCost(func.body, func.args, #func.args, self.builtins)

		-- track functions that only ever return a single value so that we can convert multret calls to fixedret calls
		if self:alwaysTerminates(func.body) then
			local returnVisitor = ReturnVisitor.new(self)
			stat:visit(returnVisitor)
			f.returnsOne = returnVisitor.returnsOne
		end
	end

	self.upvals:clear()
	self.stackSize = 0

	if FastVariables.LuauCompileTypeInfo then
		self.argCount = 0
	end

	self.hasLoops = false

	rs:destroy()

	return fid
end

--[=[
	@within Compiler
	@private
	@since v0.1.0

	returns true if node can return multiple values; may conservatively return true even if expr is known to return just a single value
]=]
function prototype.isExprMultRet(self: Compiler, node: AstExpr): boolean
	local expr = node:as(AstExprCall)
	if not expr then
		return node:is(AstExprVarargs)
	end

	-- conservative version, optimized for compilation throughput
	if self.options.optimizationLevel <= 1 then
		return true
	end

	-- handles builtin calls that can be constant-folded
	-- without this we may omit some optimizations eg compiling fast calls without use of FASTCALL2K
	if self:isConstant(expr) then
		return false
	end

	-- handles builtin calls that can't be constant-folded but are known to return one value
	-- note: optimizationLevel check is technically redundant but it's important that we never optimize based on builtins in O1
	if self.options.optimizationLevel >= 2 then
		local bfid = self.builtins[expr]
		if bfid then
			return getBuiltinInfo(bfid).results ~= 1
		end
	end

	-- handles local function calls where we know only one argument is returned
	local func = self:getFunctionExpr(expr.func)
	local fi = if func then self.functions[func] else nil

	if fi and fi.returnsOne then
		return false
	end

	-- unrecognized call, so we conservatively assume multret
	return true
end

--[=[
	@within Compiler
	@private
	@since v0.1.0

	note: this doesn't just clobber target (assuming it's temp), but also clobbers *all* allocated registers >= target!
	this is important to be able to support "multret" semantics due to Lua call frame structure
]=]
function prototype.compileExprTempMultRet(self: Compiler, node: AstExpr, target: number): boolean
	local exprCall = node:as(AstExprCall)
	local exprVarargs = node:as(AstExprVarargs)
	if exprCall then
		-- Optimization: convert multret calls that always return one value to fixedret calls; this facilitates inlining/constant folding
		if self.options.optimizationLevel >= 2 and not self:isExprMultRet(node) then
			self:compileExprTemp(node, target)
			return false
		end

		-- We temporarily swap out regTop to have targetTop work correctly...
		-- This is a crude hack but it's necessary for correctness :(
		local rs = RegScope.new(self, target)
		self:compileExprCall(exprCall, target, 0, true, true)
		rs:destroy()
		return true
	elseif exprVarargs then
		-- We temporarily swap out regTop to have targetTop work correctly...
		-- This is a crude hack but it's necessary for correctness :(
		local rs = RegScope.new(self, target)
		self:compileExprVarargs(exprVarargs, target, 0, true)
		rs:destroy()
		return true
	else
		self:compileExprTemp(node, target)
		return false
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0

	note: this doesn't just clobber target (assuming it's temp), but also clobbers *all* allocated registers >= target!
	this is important to be able to emit code that takes fewer registers and runs faster
]=]
function prototype.compileExprTempTop(self: Compiler, node: AstExpr, target: number): ()
	-- We temporarily swap out regTop to have targetTop work correctly...
	-- This is a crude hack but it's necessary for performance :(
	-- It makes sure that nested call expressions can use targetTop optimization and don't need to have too many registers
	local rs = RegScope.new(self, target + 1)
	self:compileExprTemp(node, target)
	rs:destroy()
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileExprVarargs(self: Compiler, expr: AstExprVarargs, target: number, targetCount: number, multRet: boolean?): ()
	local multRet = multRet or false

	assert(not multRet or unsigned(target + targetCount) == self.regTop)

	self:setDebugLine(expr) -- normally compileExpr sets up line info, but compileExprVarargs can be called directly

	self.bytecode:emitABC(LuauOpcode.LOP_GETVARARGS, target, if multRet then 0 else uint8_t(targetCount + 1), 0)
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileExprSelectVararg(
	self: Compiler,
	expr: AstExprCall,
	target: number,
	targetCount: number,
	targetTop: boolean,
	multRet: boolean,
	regs: number
): ()
	assert(targetCount == 1)
	assert(not expr.self)
	assert(#expr.args == 2 and expr.args[2]:is(AstExprVarargs))

	local arg = expr.args[1]

	local argreg: number

	local reg = self:getExprLocalReg(arg)
	if reg and reg >= 0 then
		argreg = uint8_t(reg)
	else
		argreg = uint8_t(regs + 1)
		self:compileExprTempTop(arg, argreg)
	end

	local fastcallLabel = self.bytecode:emitLabel()

	self.bytecode:emitABC(LuauOpcode.LOP_FASTCALL1, LuauBuiltinFunction.LBF_SELECT_VARARG, argreg, 0)

	-- note, these instructions are normally not executed and are used as a fallback for FASTCALL
	-- we can't use TempTop variant here because we need to make sure the arguments we already computed aren't overwritten
	self:compileExprTemp(expr.func, reg)

	if argreg ~= regs + 1 then
		self.bytecode:emitABC(LuauOpcode.LOP_MOVE, uint8_t(regs + 1), argreg, 0)
	end

	self.bytecode:emitABC(LuauOpcode.LOP_GETVARARGS, uint8_t(regs + 2), 0, 0)

	local callLabel = self.bytecode:emitLabel()
	if not self.bytecode:patchSkipC(fastcallLabel, callLabel) then
		CompileError.raise(expr.func.location, "Exceeded jump distance limit; simplify the code to compile")
	end

	-- note, this is always multCall (last argument is variadic)
	self.bytecode:emitABC(LuauOpcode.LOP_CALL, regs, 0, if multRet then 0 else uint8_t(targetCount + 1))

	-- if we didn't output results directly to target, we need to move them
	if not targetTop then
		for i = 0, targetCount - 1 do
			self.bytecode:emitABC(LuauOpcode.LOP_MOVE, uint8_t(target + i), uint8_t(regs + i), 0)
		end
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileExprFastcallN(
	self: Compiler,
	expr: AstExprCall,
	target: number,
	targetCount: number,
	targetTop: boolean,
	multRet: boolean,
	regs: number,
	bfid: number,
	bfK: number?
)
	local bfK = bfK or -1

	assert(not expr.self)
	assert(#expr.args >= 1)
	assert(#expr.args <= 2 or (bfid == LuauBuiltinFunction.LBF_BIT32_EXTRACTK and #expr.args == 3))
	assert(if bfid == LuauBuiltinFunction.LBF_BIT32_EXTRACTK then bfK >= 0 else bfK <= 0)

	local opc =
		if #expr.args == 1 then LuauOpcode.LOP_FASTCALL1
		else if (bfK >= 0 or self:isConstant(expr.args[2])) then LuauOpcode.LOP_FASTCALL2K else LuauOpcode.LOP_FASTCALL2

	local args = table.create(3, 0)

	for i = 1, #expr.args do
		local reg = self:getExprLocalReg(expr.args[i])
		if i > 1 and opc == LuauOpcode.LOP_FASTCALL2K then
			local cid = self:getConstantIndex(expr.args[i])
			if cid < 0 then
				CompileError.raise(expr.location, "Exceeded constant limit; simplify the code to compile")
			end
			args[i] = cid
		elseif reg >= 0 then
			args[i] = uint8_t(reg)
		else
			args[i] = uint8_t(regs + 1 + i - 1)
			self:compileExprTempTop(expr.args[i], uint8_t(args[i]))
		end
	end

	local fastcallLabel = self.bytecode:emitLabel()

	self.bytecode:emitABC(opc, uint8_t(bfK), uint8_t(args[1]), 0)
	if opc ~= LuauOpcode.LOP_FASTCALL1 then
		self.bytecode:emitAux(if bfK >= 0 then bfK else args[2])
	end

	-- Set up a traditional Lua stack for the subsequent LOP_CALL.
	-- Note, as with other instructions that immediately follow FASTCALL, these are normally not executed and are used as a fallback for
	-- these FASTCALL variants.
	for i = 1, #expr.args do
		if i > 1 and opc == LuauOpcode.LOP_FASTCALL2K then
			self:emitLoadK(uint8_t(regs + 1 + i - 1), args[i])
		elseif args[i] ~= regs + 1 + i - 1 then
			self.bytecode:emitABC(LuauOpcode.LOP_MOVE, uint8_t(regs + 1 + i - 1), uint8_t(args[i]), 0)
		end
	end

	-- note, these instructions are normally not executed and are used as a fallback for FASTCALL
	-- we can't use TempTop variant here because we need to make sure the arguments we already computed aren't overwritten
	self:compileExprTemp(expr.func, regs)

	local callLabel = self.bytecode:emitLabel()

	-- FASTCALL will skip over the instructions needed to compute function and jump over CALL which must immediately follow the instruction
	-- sequence after FASTCALL
	if not self.bytecode:patchSkipC(fastcallLabel, callLabel) then
		CompileError.raise(expr.func.location, "Exceeded jump distance limit; simplify the code to compile")
	end

	self.bytecode:emitABC(LuauOpcode.LOP_CALL, regs, uint8_t(#expr.args + 1), if multRet then 0 else uint8_t(targetCount + 1))

	-- if we didn't output results directly to target, we need to move them
	if not targetTop then
		for i = 0, targetCount - 1 do
			self.bytecode:emitABC(LuauOpcode.LOP_MOVE, uint8_t(target + i), uint8_t(regs + i), 0)
		end
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.tryCompileInlinedCall(
	self: Compiler,
	expr: AstExprCall,
	func: AstExprFunction,
	target: number,
	targetCount: number,
	multRet: boolean,
	thresholdBase: number,
	thresholdMaxBoost: number,
	depthLimit: number
): boolean
	local fi = self.functions[func]
	assert(fi)

	-- make sure we have enough register space
	if self.regTop > 128 or fi.stackSize > 32 then
		self.bytecode:addDebugRemark("inlining failed: high register pressure")
		return false
	end

	-- we should ideally aggregate the costs during recursive inlining, but for now simply limit the depth
	if self.inlineFrames:size() >= depthLimit then
		self.bytecode:addDebugRemark("inlining failed: too many inlined frames")
		return false
	end
	
	-- compiling recursive inlining is difficult because we share constant/variable state but need to bind variables to different registers
	for _, frame in self.inlineFrames:data() do
		if frame.func == func then
			self.bytecode:addDebugRemark("inlining failed: can't inline recursive calls")
			return false
		end
	end

	-- we can't inline multret functions because the caller expects L->top to be adjusted:
	-- - inlined return compiles to a JUMP, and we don't have an instruction that adjusts L->top arbitrarily
	-- - even if we did, right now all L->top adjustments are immediately consumed by the next instruction, and for now we want to preserve that
	-- - additionally, we can't easily compile multret expressions into designated target as computed call arguments will get clobbered
	if multRet then
		self.bytecode:addDebugRemark("inlining failed: can't convert fixed returns to multret")
		return false
	end

	-- compute constant bitvector for all arguments to feed the cost model
	local varc: {boolean} = table.create(8, false)
	for i = 1, math.min(#func.args, #expr.args, 8) do
		varc[i] = self:isConstant(expr.args[i])
	end

	-- if the last argument only returns a single value, all following arguments are nil
	if #expr.args ~= 0 and not self:isExprMultRet(expr.args[#expr.args]) then
		for i = #expr.args + 1, math.min(#func.args, 8) do
			varc[i] = true
		end
	end

	-- we use a dynamic cost threshold that's based on the fixed limit boosted by the cost advantage we gain due to inlining
	local inlinedCost = computeCost(fi.costModel, varc, math.min(#func.args, 8))
	local baselineCost = computeCost(fi.costModel, nil, 0) + 3
	local inlineProfit = if inlinedCost == 0 then thresholdMaxBoost else math.min(thresholdMaxBoost, 100 * baselineCost / inlinedCost)

	local threshold = thresholdBase * inlineProfit / 100

	if inlinedCost > threshold then
		self.bytecode:addDebugRemark(("inlining failed: too expensive (cost %d, profit %.2fx)"):format(inlinedCost, inlineProfit / 100))
		return false
	end

	self.bytecode:addDebugRemark(
		("inlining succeeded (cost %d, profit %.2fx, depth %d)"):format(inlinedCost, inlineProfit / 100, self.inlineFrames:size())
	)
	
	self:compileInlinedCall(expr, func, target, targetCount)
	return true
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileInlinedCall(self: Compiler, expr: AstExprCall, func: AstExprFunction, target: number, targetCount: number): ()
	local rs = RegScope.new(self)

	local oldLocals = self.localStack:size()

	local args: Vector<InlineArg> = Vector.new()
	args:reserve(#func.args)

	-- evaluate all arguments; note that we don't emit code for constant arguments (relying on constant folding)
	-- note that compiler state (variable registers/values) does not change here - we defer that to a separate loop below to handle nested calls
	for i = 1, #func.args do
		local var = func.args[i]
		local arg = if i <= #expr.args then expr.args[i] else nil :: AstExpr?
		
		local vv = self.variables[var]
		local cv = if arg == nil then nil else self.constants[arg]
		if i == #expr.args and #func.args > #expr.args and self:isExprMultRet(assert(arg)) then
			assert(arg)
			-- if the last argument can return multiple values, we need to compute all of them into the remaining arguments
			local tail = unsigned(#func.args - #expr.args) + 1
			local reg = self:allocReg(arg :: AstExpr, tail)
			local allocpc = if FastVariables.LuauCompileTypeInfo then self.bytecode:getDebugPC() else kDefaultAllocPc
			
			local exprCall = arg:as(AstExprCall)
			local exprVarargs = arg:as(AstExprVarargs)
			if exprCall then
				self:compileExprCall(expr, reg, tail, true)
			elseif exprVarargs then
				self:compileExprVarargs(expr, reg, tail)
			else
				error("Unexpected expression type")			
			end

			for j = i, #func.args do
				if FastVariables.LuauCompileTypeInfo then
					args:push_back(InlineArg.new(func.args[j], uint8_t(reg + (j - i)), Constant.new(Constant.Type.Type_Unknown), allocpc))
				else
					args:push_back(InlineArg.new(func.args[j], uint8_t(reg + (j - i))))
				end
			end

			-- all remaining function arguments have been allocated and assigned to
			break
		elseif vv and vv.written then
			assert(arg)
			-- if the argument is mutated, we need to allocate a fresh register even if it's a constant
			local reg = self:allocReg(arg, 1)
			local allocpc = if FastVariables.LuauCompileTypeInfo then self.bytecode:getDebugPC() else kDefaultAllocPc

			if arg then
				self:compileExprTemp(arg, reg)
			else
				self.bytecode:emitABC(LuauOpcode.LOP_LOADNIL, reg, 0, 0)
			end

			if FastVariables.LuauCompileTypeInfo then
				args:push_back(InlineArg.new(var, reg, Constant.new(Constant.Type.Type_Unknown), allocpc))
			else
				args:push_back(InlineArg.new(var, reg))
			end
		elseif arg == nil then
			-- since the argument is not mutated, we can simply fold the value into the expressions that need it
			args:push_back(InlineArg.new(var, kInvalidReg, Constant.new(Constant.Type.Type_Unknown)))
		elseif cv and cv.type ~= Constant.Type.Type_Unknown then
			-- since the argument is not mutated, we can simply fold the value into the expressions that need it
			args:push_back(InlineArg.new(var, kInvalidReg, cv))
		else
			local le = self:getExprLocal(arg)
			local lv = if le then self.variables[le.localAst] else nil

			-- if the argument is a local that isn't mutated, we will simply reuse the existing register
			local reg = if le then self:getExprLocalReg(le) else -1
			if reg >= 0 and (not lv or not lv.written) then
				args:push_back(InlineArg.new(var, uint8_t(reg), Constant.new(Constant.Type.Type_Unknown), kDefaultAllocPc))
			else
				local temp = self:allocReg(arg, 1)
				local allocpc = if FastVariables.LuauCompileTypeInfo then self.bytecode:getDebugPC() else kDefaultAllocPc

				self:compileExprTemp(arg, temp)

				if FastVariables.LuauCompileTypeInfo then
					args:push_back(InlineArg.new(var, temp, Constant.new(Constant.Type.Type_Unknown), allocpc))
				else
					args:push_back(InlineArg.new(var, temp))
				end
			end
		end
	end

	-- evaluate extra expressions for side effects
	for i = #func.args + 1, #expr.args do
		self:compileExprSide(expr.args[i])
	end

	-- apply all evaluated arguments to the compiler state
	-- note: locals use current startpc for debug info, although some of them have been computed earlier; this is similar to compileStatLocal
	for _, arg in args:data() do
		if arg.value.type == Constant.Type.Type_Unknown then
			if FastVariables.LuauCompileTypeInfo then
				self:pushLocal(arg.astLocal :: AstLocal, arg.reg, arg.allocpc)
			else
				self:pushLocal(arg.astLocal :: AstLocal, arg.reg, kDefaultAllocPc)
			end
		else
			self.locstants[arg.astLocal :: AstLocal] = arg.value
		end
	end

	-- the inline frame will be used to compile return statements as well as to reject recursive inlining attempts
	self.inlineFrames:push_back(InlineFrame.new(func, oldLocals, target, targetCount))

	-- fold constant values updated above into expressions in the function body
	foldConstants(self.constants, self.variables, self.locstants, self.builtinsFold, self.builtinsFoldMathK, func.body)

	local usedFallthrough = false

	for _, stat in func.body.body do
		local ret = (stat :: AstStat):as(AstStatReturn)
		if ret then
			-- Optimization: use fallthrough when compiling return at the end of the function to avoid an extra JUMP
			self:compileInlineReturn(ret, true)
			-- TODO: This doesn't work when return is part of control flow; ideally we would track the state somehow and generalize this
			usedFallthrough = true
			break
		else
			self:compileStat(stat :: AstStat)
		end
	end

	-- for the fallthrough path we need to ensure we clear out target registers
	if not usedFallthrough and not self:alwaysTerminates(func.body) then
		for i = 0, targetCount - 1 do
			self.bytecode:emitABC(LuauOpcode.LOP_LOADNIL, uint8_t(target + i), 0, 0)
		end

		self:closeLocals(oldLocals)
	end

	self:popLocals(oldLocals)

	local returnLabel = self.bytecode:emitLabel()
	self:patchJumps(expr, self.inlineFrames:back().returnJumps, returnLabel)

	self.inlineFrames:pop_back()

	-- clean up constant state for future inlining attempts
	for _, astLocal in func.args do
		local var = self.locstants[astLocal :: AstLocal]
		if var then
			var.type = Constant.Type.Type_Unknown
		end
	end

	foldConstants(self.constants, self.variables, self.locstants, self.builtinsFold, self.builtinsFoldMathK, func.body)

	rs:destroy()
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileExprCall(self: Compiler, expr: AstExprCall, target: number, targetCount: number, targetTop: boolean?, multRet: boolean?): ()
	local targetTop = targetTop or false
	local multRet = multRet or false

	assert(not targetTop or unsigned(target + targetCount) == self.regTop)

	self:setDebugLine(expr) -- normally compileExpr sets up line info, but compileExprCall can be called directly

	-- try inlining the function
	if self.options.optimizationLevel >= 2 and not expr.self then
		local func = self:getFunctionExpr(expr.func)
		local fi = if func then self.functions[func] else nil

		if
			fi
			and fi.canInline
			and self:tryCompileInlinedCall(
				expr,
				func :: AstExprFunction,
				target, targetCount,
				multRet,
				FastVariables.LuauCompileInlineThreshold,
				FastVariables.LuauCompileInlineThresholdMaxBoost,
				FastVariables.LuauCompileInlineDepth
			)
		then
			return
		end

		-- add a debug remark for cases when we didn't even call tryCompileInlinedCall
		if func ~= nil and not (fi ~= nil and fi.canInline) then
			if func.vararg then
				self.bytecode:addDebugRemark("inlining failed: function is variadic")
			elseif fi == nil then
				self.bytecode:addDebugRemark("inlining failed: can't inline recursive calls")
			elseif self.getfenvUsed or self.setfenvUsed then
				self.bytecode:addDebugRemark("inlining failed: module uses getfenv/setfenv")
			end
		end
	end

	local rs = RegScope.new(self)

	local regCount = math.max(unsigned(1 + btn(expr.self) + #expr.args), unsigned(targetCount))

	-- Optimization: if target points to the top of the stack, we can start the call at oldTop - 1 and won't need MOVE at the end
	local regs = if targetTop then self:allocReg(expr, regCount - targetCount) - targetCount else self:allocReg(expr, regCount)

	local selfreg = 0

	local bfid = -1

	if self.options.optimizationLevel >= 1 and not expr.self then
		local id = self.builtins[expr]
		if id then
			bfid = id
		end
	end
	
	if bfid >= 0 and self.bytecode:needsDebugRemarks() then
		local builtin = getBuiltin(expr.func, self.globals, self.variables)
		local lastMult = #expr.args > 0 and self:isExprMultRet(expr.args[#expr.args])

		if builtin.object.value then
			self.bytecode:addDebugRemark(
				("builtin %s.%s/%d%s"):format(
					builtin.object.value,
					builtin.method.value,
					int(#expr.args),
					if lastMult then "+" else ""
				)
			)
		elseif builtin.method.value then
			self.bytecode:addDebugRemark(
				("builtin %s/%d%s"):format(
					builtin.method.value,
					int(#expr.args),
					if lastMult then "+" else ""
				)
			)
		end
	end

	if bfid == LuauBuiltinFunction.LBF_SELECT_VARARG then
		-- Optimization: compile select(_, ...) as FASTCALL1; the builtin will read variadic arguments directly
		-- note: for now we restrict this to single-return expressions since our runtime code doesn't deal with general cases
		if multRet == false and targetCount == 1 then
			rs:destroy()
			return self:compileExprSelectVararg(expr, target, targetCount, targetTop, multRet, regs)
		else
			bfid = -1
		end
	end

	-- Optimization: for bit32.extract with constant in-range f/w we compile using FASTCALL2K and a special builtin
	if bfid == LuauBuiltinFunction.LBF_BIT32_EXTRACT and #expr.args == 3 and self:isConstant(expr.args[2]) and self:isConstant(expr.args[3]) then
		local fc = self:getConstant(expr.args[2])
		local wc = self:getConstant(expr.args[3])

		local fi = if fc.type == Constant.Type.Type_Number then int(fc.valueNumber) else -1
		local wi = if wc.type == Constant.Type.Type_Number then int(wc.valueNumber) else -1

		if fi >= 0 and wi >= 0 and fi + wi <= 32 then
			local fwp = bit32.bor(fi, bit32.lshift(wi - 1, 5))
			local cid = self.bytecode:addConstantNumber(fwp)
			if cid < 0 then
				CompileError.raise(expr.location, "Exceeded constant limit; simplify the code to compile")
			end

			rs:destroy()
			return self:compileExprFastcallN(expr, target, targetCount, targetTop, multRet, regs, LuauBuiltinFunction.LBF_BIT32_EXTRACTK, cid)
		end
	end

	-- Optimization: for 1/2 argument fast calls use specialized opcodes
	if bfid >= 0 and #expr.args >= 1 and #expr.args <= 2 then
		if not self:isExprMultRet(expr.args[#expr.args]) then
			rs:destroy()
			return self:compileExprFastcallN(expr, target, targetCount, targetTop, multRet, regs, bfid)
		elseif self.options.optimizationLevel >= 2 then
			-- when a builtin is none-safe with matching arity, even if the last expression returns 0 or >1 arguments,
			-- we can rely on the behavior of the function being the same (none-safe means nil and none are interchangeable)
			local info = getBuiltinInfo(bfid)
			if int(#expr.args) == info.params and bit32.band(info.flags, Builtins.BuiltinInfo.Flags.Flag_NoneSafe) ~= 0 then
				rs:destroy()
				return self:compileExprFastcallN(expr, target, targetCount, targetTop, multRet, regs, bfid)
			end
		end
	end

	if expr.self then
		local fi = expr.func:as(AstExprIndexName)
		assert(fi)

		-- Optimization: use local register directly in NAMECALL if possible
		local reg = self:getExprLocalReg(fi.expr)
		if reg >= 0 then
			selfreg = uint8_t(reg)
		else
			-- Note: to be able to compile very deeply nested self call chains (obj:method1():method2():...), we need to be able to do this in
			-- finite stack space NAMECALL will happily move object from regs to regs+1 but we need to compute it into regs so that
			-- compileExprTempTop doesn't increase stack usage for every recursive call
			selfreg = regs

			self:compileExprTempTop(fi.expr, selfreg)
		end
	elseif bfid < 0 then
		self:compileExprTempTop(expr.func, regs)
	end

	local multCall = false

	for i = 1, #expr.args do
		if i == #expr.args then
			multCall = self:compileExprTempMultRet(expr.args[i], uint8_t(regs + 1 + btn(expr.self) + i - 1))
		else
			self:compileExprTempTop(expr.args[i], uint8_t(regs + 1 + btn(expr.self) + i - 1))
		end
	end

	self:setDebugLineEnd(expr.func)

	if expr.self then
		local fi = expr.func:as(AstExprIndexName)
		assert(fi)

		self:setDebugLine(fi.indexLocation)

		local iname = sref(fi.index)
		local cid = self.bytecode:addConstantString(iname)
		if cid < 0 then
			CompileError.raise(fi.location, "Exceeded constant limit; simplify the code to compile")
		end

		self.bytecode:emitABC(LuauOpcode.LOP_NAMECALL, regs, selfreg, uint8_t(BytecodeBuilder.getStringHash(iname)))
		self.bytecode:emitAux(cid)

		if FastVariables.LuauCompileTempTypeInfo then
			self:hintTemporaryExprRegType(fi.expr, selfreg, LuauBytecodeType.LBC_TYPE_TABLE, 2)
		end
	elseif bfid >= 0 then
		local fastcallLabel = self.bytecode:emitLabel()
		self.bytecode:emitABC(LuauOpcode.LOP_FASTCALL, uint8_t(bfid), 0, 0)

		-- note, these instructions are normally not executed and are used as a fallback for FASTCALL
		-- we can't use TempTop variant here because we need to make sure the arguments we already computed aren't overwritten
		self:compileExprTemp(expr.func, regs)

		local callLabel = self.bytecode:emitLabel()

		-- FASTCALL will skip over the instructions needed to compute function and jump over CALL which must immediately follow the instruction
		-- sequence after FASTCALL
		if not self.bytecode:patchSkipC(fastcallLabel, callLabel) then
			CompileError.raise(expr.func.location, "Exceeded jump distance limit; simplify the code to compile")
		end
	end

	self.bytecode:emitABC(
		LuauOpcode.LOP_CALL,
		regs,
		if multCall then 0 else uint8_t(btn(expr.self) + #expr.args + 1),
		if multRet then 0 else uint8_t(targetCount + 1)
	)

	-- if we didn't output results directly to target, we need to move them
	if not targetTop then
		for i = 0, targetCount - 1 do
			self.bytecode:emitABC(LuauOpcode.LOP_MOVE, uint8_t(target + i), uint8_t(regs + i), 0)
		end
	end
	rs:destroy()
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.shouldShareClosure(self: Compiler, func: AstExprFunction): boolean
	local f = self.functions[func]
	if func == nil then
		return false
	end
	
	for _, uv in f.upvals:data() do
		local ul = self.variables[uv :: AstLocal]
		
		if ul == nil then
			return false
		end

		if ul.written then
			return false
		end

		-- it's technically safe to share closures whenever all upvalues are immutable
		-- this is because of a runtime equality check in DUPCLOSURE.
		-- however, this results in frequent deoptimization and increases the set of reachable objects, making some temporary objects permanent
		-- instead we apply a heuristic: we share closures if they refer to top-level upvalues, or closures that refer to top-level upvalues
		-- this will only deoptimize (outside of fenv changes) if top level code is executed twice with different results.
		if uv.functionDepth ~= 0 or uv.loopDepth ~= 0 then
			local uf = if ul.init then ul.init:as(AstExprFunction) else nil
			if not uf then
				return false
			end

			if uf ~= func and not self:shouldShareClosure(uf) then
				return false
			end
		end
	end

	return true
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileExprFunction(self: Compiler, expr: AstExprFunction, target: number): ()
	local rs = RegScope.new(self)

	local f = self.functions[expr]
	assert(f)

	-- when the closure has upvalues we'll use this to create the closure at runtime
	-- when the closure has no upvalues, we use constant closures that technically don't rely on the child function list
	-- however, it's still important to add the child function because debugger relies on the function hierarchy when setting breakpoints
	local pid = self.bytecode:addChildFunction(f.id)
	if pid < 0 then
		CompileError.raise(expr.location, "Exceeded closure limit; simplify the code to compile")
	end

	-- we use a scratch vector to reduce allocations; this is safe since compileExprFunction is not reentrant
	self.captures:clear()
	self.captures:reserve(f.upvals:size())

	for _, uv in f.upvals:data() do
		assert(uv.functionDepth > expr.functionDepth)

		local reg = self:getLocalReg(uv :: AstLocal)
		local uc = self.locstants[uv :: AstLocal]
		if reg >= 0 then
			-- note: we can't check if uv is an upvalue in the current frame because inlining can migrate from upvalues to locals
			local ul = self.variables[uv :: AstLocal]
			local immutable = ul == nil or not ul.written

			self.captures:push_back(Capture.new(if immutable then LuauCaptureType.LCT_VAL else LuauCaptureType.LCT_REF, uint8_t(reg)))
		elseif uc and uc.type ~= Constant.Type.Type_Unknown then
			-- inlining can result in an upvalue capture of a constant, in which case we can't capture without a temporary register
			local reg = self:allocReg(expr, 1)
			self:compileExprConstant(expr, uc, reg)

			self.captures:push_back(Capture.new(LuauCaptureType.LCT_VAL, reg))
		else
			assert(uv.functionDepth < expr.functionDepth - 1)

			-- get upvalue from parent frame
			-- note: this will add uv to the current upvalue list if necessary
			local uid = self:getUpval(uv :: AstLocal)

			self.captures:push_back(Capture.new(LuauCaptureType.LCT_UPVAL, uid))
		end
	end
	rs:destroy()
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.getUnaryOp(self: Compiler, op: number): number
	if op == AstExprUnary.Op.Not then
		return LuauOpcode.LOP_NOT
	elseif op == AstExprUnary.Op.Minus then
		return LuauOpcode.LOP_MINUS
	elseif op == AstExprUnary.Op.Len then
		return LuauOpcode.LOP_LENGTH
	else
		error("Unexpected unary operation")
	end
end

function prototype.getBinaryOpArith(self: Compiler, op: number, k: boolean?): number
	local k = k or false
	if op == AstExprBinary.Op.Add then
		return if k then LuauOpcode.LOP_ADDK else LuauOpcode.LOP_ADD
	elseif op == AstExprBinary.Op.Sub then
		return if k then LuauOpcode.LOP_SUBK else LuauOpcode.LOP_SUB
	elseif op == AstExprBinary.Op.Mul then
		return if k then LuauOpcode.LOP_MULK else LuauOpcode.LOP_MUL
	elseif op == AstExprBinary.Op.Div then
		return if k then LuauOpcode.LOP_DIVK else LuauOpcode.LOP_DIV
	elseif op == AstExprBinary.Op.FloorDiv then
		return if k then LuauOpcode.LOP_IDIVK else LuauOpcode.LOP_IDIV
	elseif op == AstExprBinary.Op.Mod then
		return if k then LuauOpcode.LOP_MODK else LuauOpcode.LOP_MOD
	elseif op == AstExprBinary.Op.Pow then
		return if k then LuauOpcode.LOP_POWK else LuauOpcode.LOP_POW
	else
		error("Unexpected binary operation")
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.getJumpOpCompare(self: Compiler, op: number, not_: boolean?): number
	if op == AstExprBinary.Op.CompareNe then
		return if not_ then LuauOpcode.LOP_JUMPIFEQ else LuauOpcode.LOP_JUMPIFNOTEQ
	elseif op == AstExprBinary.Op.CompareEq then
		return if not_ then LuauOpcode.LOP_JUMPIFNOTEQ else LuauOpcode.LOP_JUMPIFEQ
	elseif
		op == AstExprBinary.Op.CompareLt
		or op == AstExprBinary.Op.CompareGt
	then
		return if not_ then LuauOpcode.LOP_JUMPIFNOTLT else LuauOpcode.LOP_JUMPIFLT
	elseif
		op == AstExprBinary.Op.CompareLe
		or op == AstExprBinary.Op.CompareGe
	then
		return if not_ then LuauOpcode.LOP_JUMPIFNOTLE else LuauOpcode.LOP_JUMPIFLE
	else
		error("Unexpected binary operation")
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.isConstant(self: Compiler, node: AstExpr): boolean
	local cv: Constant? = self.constants[node]

	return cv ~= nil and cv.type ~= Constant.Type.Type_Unknown
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.isConstantTrue(self: Compiler, node: AstExpr): boolean
	local cv: Constant? = self.constants[node]

	return cv ~= nil and cv.type ~= Constant.Type.Type_Unknown and cv:isTruthful()
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.isConstantFalse(self: Compiler, node: AstExpr): boolean
	local cv: Constant? = self.constants[node]

	return cv ~= nil and cv.type ~= Constant.Type.Type_Unknown and not cv:isTruthful()
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.isConstantVector(self: Compiler, node: AstExpr): boolean
	local cv: Constant? = self.constants[node]

	return cv ~= nil and cv.type == Constant.Type.Type_Vector
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.getConstant(self: Compiler, node: AstExpr): Constant
	local cv: Constant? = self.constants[node]

	return cv or Constant.new(Constant.Type.Type_Unknown)
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileCompareJump(self: Compiler, expr: AstExprBinary, not_: boolean?): number
	local not_ = not_ or false

	local rs = RegScope.new(self)

	local isEq = (expr.op == AstExprBinary.Op.CompareEq or expr.op == AstExprBinary.Op.CompareNe)
	local left = expr.left
	local right = expr.right

	local operandIsConstant = self:isConstant(right)
	if isEq and not operandIsConstant then
		operandIsConstant = self:isConstant(left)
		if operandIsConstant then
			left, right = right, left
			expr.left, expr.right = expr.right, expr.left
		end
	end

	-- disable fast path for vectors because supporting it would require a new opcode
	if operandIsConstant and self:isConstantVector(right) then
		operandIsConstant = false
	end

	local rl = self:compileExprAuto(left, rs)

	if isEq and operandIsConstant then
		local cv = self.constants[right]
		assert(cv and cv.type ~= Constant.Type.Type_Unknown)

		local opc = LuauOpcode.LOP_NOP
		local cid = -1
		local flip = if (expr.op == AstExprBinary.Op.CompareEq) == not_ then 0x80000000 else 0

		if cv.type == Constant.Type.Type_Nil then
			opc = LuauOpcode.LOP_JUMPXEQKNIL
			cid = 0
		elseif cv.type == Constant.Type.Type_Boolean then
			opc = LuauOpcode.LOP_JUMPXEQKB
			cid = btn(cv.valueBoolean)
		elseif cv.type == Constant.Type.Type_Number then
			opc = LuauOpcode.LOP_JUMPXEQKN
			cid = self:getConstantIndex(right)
		elseif cv.type == Constant.Type.Type_String then
			opc = LuauOpcode.LOP_JUMPXEQKS
			cid = self:getConstantIndex(right)
		else
			error("Unexpected constant type")
		end

		if cid < 0 then
			CompileError.raise(expr.location, "Exceeded constant limit; simplify the code to compile")
		end

		local jumpLabel = self.bytecode:emitLabel()

		self.bytecode:emitAD(opc, rl, 0)
		self.bytecode:emitAux(bit32.bor(cid, flip))

		rs:destroy()
		return jumpLabel
	else
		local opc = self:getJumpOpCompare(expr.op, not_)

		local rr = self:compileExprAuto(right, rs)

		local jumpLabel = self.bytecode:emitLabel()


		if expr.op == AstExprBinary.Op.CompareGt or expr.op == AstExprBinary.Op.CompareGe then
			self.bytecode:emitAD(opc, rr, 0)
			self.bytecode:emitAux(rl)
		else
			self.bytecode:emitAD(opc, rl, 0)
			self.bytecode:emitAux(rr)
		end

		rs:destroy()
		return jumpLabel
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.getConstantNumber(self: Compiler, node: AstExpr): number
	local c = self.constants[node]

	if c and c.type == Constant.Type.Type_Number then
		local cid = self.bytecode:addConstantNumber(c.valueNumber)
		if cid < 0 then
			CompileError.raise(node.location, "Exceeded constant limit; simplify the code to compile")
		end

		return cid
	end

	return -1
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.getConstantIndex(self: Compiler, node: AstExpr): number
	local c = self.constants[node]

	if not c or c.type == Constant.Type.Type_Unknown then
		return -1
	end

	local cid = -1
	
	if c.type == Constant.Type.Type_Nil then
		cid = self.bytecode:addConstantNil()
	elseif c.type == Constant.Type.Type_Boolean then
		cid = self.bytecode:addConstantBoolean(c.valueBoolean)
	elseif c.type == Constant.Type.Type_Number then
		cid = self.bytecode:addConstantNumber(c.valueNumber)
	elseif c.type == Constant.Type.Type_Vector then
		cid = self.bytecode:addConstantVector(c.valueVector[1], c.valueVector[2], c.valueVector[3], c.valueVector[4])
	elseif c.type == Constant.Type.Type_String then
		cid = self.bytecode:addConstantString(sref(c:getString()))
	else
		error("Unexpected constant type")
	end

	if cid < 0 then
		CompileError.raise(node.location, "Exceeded constant limit; simplify the code to compile")
	end

	return cid
end

--[=[
	@within Compiler
	@private
	@since v0.1.0

	compile expr to target temp register
	if the expr (or not expr if onlyTruth is false) is truthy, jump via skipJump
	if the expr (or not expr if onlyTruth is false) is falsy, fall through (target isn't guaranteed to be updated in this case)
	if target is omitted, then the jump behavior is the same - skipJump or fallthrough depending on the truthiness of the expression
]=]
function prototype.compileConditionValue(self: Compiler, node: AstExpr, target: number?, skipJump: Vector<number>, onlyTruth: boolean): ()
	-- Optimization: we don't need to compute constant values
	local cv = self.constants[node]
	if cv and cv.type ~= Constant.Type.Type_Unknown then
		-- note that we only need to compute the value if it's truthy; otherwise we cal fall through
		if cv:isTruthful() == onlyTruth then
			if target and target ~= 0 then
				self:compileExprTemp(node, target)
			end
			
			skipJump:push_back(self.bytecode:emitLabel())
			self.bytecode:emitAD(LuauOpcode.LOP_JUMP, 0, 0)
		end
		return
	end

	local expr = node:as(AstExprBinary)
	if expr then
		if
			expr.op == AstExprBinary.Op.And
			or expr.op == AstExprBinary.Op.Or
		then
			-- disambiguation: there's 4 cases (we only need truthy or falsy results based on onlyTruth)
			-- onlyTruth = 1: a and b transforms to a ? b : dontcare
			-- onlyTruth = 1: a or b transforms to a ? a : b
			-- onlyTruth = 0: a and b transforms to !a ? a : b
			-- onlyTruth = 0: a or b transforms to !a ? b : dontcare
			if onlyTruth == (expr.op == AstExprBinary.Op.And) then
				-- we need to compile the left hand side, and skip to "dontcare" (aka fallthrough of the entire statement) if it's not the same as
				-- onlyTruth if it's the same then the result of the expression is the right hand side because of this, we *never* care about the
				-- result of the left hand side
				local elseJump: Vector<number> = Vector.new()
				self:compileConditionValue(expr.left, nil, elseJump, not onlyTruth)

				-- fallthrough indicates that we need to compute & return the right hand side
                -- we use compileConditionValue again to process any extra and/or statements directly
				self:compileConditionValue(expr.right, target, skipJump, onlyTruth)

				local elseLabel = self.bytecode:emitLabel()

				self:patchJumps(expr, elseJump, elseLabel)
			else
				-- we need to compute the left hand side first; note that we will jump to skipJump if we know the answer
				self:compileConditionValue(expr.left, target, skipJump, onlyTruth)

				-- we will fall through if computing the left hand didn't give us an "interesting" result
				-- we still use compileConditionValue to recursively optimize any and/or/compare statements
				self:compileConditionValue(expr.right, target, skipJump, onlyTruth)
			end
			return
		elseif
			expr.op == AstExprBinary.Op.CompareNe
			or expr.op == AstExprBinary.Op.CompareEq
			or expr.op == AstExprBinary.Op.CompareLt
			or expr.op == AstExprBinary.Op.CompareLe
			or expr.op == AstExprBinary.Op.CompareGt
			or expr.op == AstExprBinary.Op.CompareGe
		then
			if target and target ~= 0 then
				-- since target is a temp register, we'll initialize it to 1, and then jump if the comparison is true
				-- if the comparison is false, we'll fallthrough and target will still be 1 but target has unspecified value for falsy results
				-- when we only care about falsy values instead of truthy values, the process is the same but with flipped conditionals
				self.bytecode:emitABC(LuauOpcode.LOP_LOADB, target, if onlyTruth then 1 else 0, 0)

				local jumpLabel = self:compileCompareJump(expr, not onlyTruth)

				skipJump:push_back(jumpLabel)
			end
			return
		end
	end

	local expr = node:as(AstExprUnary)
	if expr then
		-- if we *do* need to compute the target, we'd have to inject "not" ops on every return path
		-- this is possible but cumbersome; so for now we only optimize not expression when we *don't* need the value
		if not (target and target ~= 0) and expr.op == AstExprUnary.Op.Not then
			self:compileConditionValue(expr.expr, target, skipJump, not onlyTruth)
			return
		end
	end

	local expr = node:as(AstExprGroup)
	if expr then
		self:compileConditionValue(expr.expr, target, skipJump, onlyTruth)
		return
	end

	local rs = RegScope.new(self)
	local reg: number

	if target then
		reg = target
		self:compileExprTemp(node, reg)
	else
		reg = self:compileExprAuto(node, rs)
	end

	skipJump:push_back(self.bytecode:emitLabel())
	self.bytecode:emitAD(if onlyTruth then LuauOpcode.LOP_JUMPIF else LuauOpcode.LOP_JUMPIFNOT, reg, 0)
end

--[=[
	@within Compiler
	@private
	@since v0.1.0

	checks if compiling the expression as a condition value generates code that's faster than using compileExpr
]=]
function prototype.isConditionFast(self: Compiler, node: AstExpr): boolean
	local cv = self.constants[node]

	if cv and cv.type ~= Constant.Type.Type_Unknown then
		return true
	end

	local expr = node:as(AstExprBinary)
	if expr then
		if
			expr.op == AstExprBinary.Op.And
			or expr.op == AstExprBinary.Op.Or
		then
			return true
		elseif
			expr.op == AstExprBinary.Op.CompareNe
			or expr.op == AstExprBinary.Op.CompareEq
			or expr.op == AstExprBinary.Op.CompareLt
			or expr.op == AstExprBinary.Op.CompareLe
			or expr.op == AstExprBinary.Op.CompareGt
			or expr.op == AstExprBinary.Op.CompareGe
		then
			return true
		else
			return false
		end
	end

	local expr = node:as(AstExprGroup)
	if expr then
		return self:isConditionFast(expr.expr)
	end

	return false
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileExprAndOr(self: Compiler, expr: AstExprBinary, target: number, targetTemp: boolean): ()
	local and_ = expr.op == AstExprBinary.Op.And

	local rs = RegScope.new(self)

	-- Optimization: when left hand side is a constant, we can emit left hand side or right hand side
	local cl = self.constants[expr.left]
	if cl and cl.type ~= Constant.Type.Type_Unknown then
		self:compileExpr(if and_ == cl:isTruthful() then expr.right else expr.left, target, targetTemp)
		rs:destroy()
		return
	end

	-- Note: two optimizations below can lead to inefficient codegen when the left hand side is a condition
	if not self:isConditionFast(expr.left) then
		-- Optimization: when right hand side is a local variable, we can use AND/OR
		local reg = self:getExprLocalReg(expr.right)
		if reg >= 0 then
			local lr = self:compileExprAuto(expr.left, rs)
			local rr = uint8_t(reg)

			self.bytecode:emitABC(if and_ then LuauOpcode.LOP_AND else LuauOpcode.LOP_OR, target, lr, rr)
			rs:destroy()
			return
		end

		-- Optimization: when right hand side is a constant, we can use ANDK/ORK
		local cid = self:getConstantIndex(expr.right)

		if cid >= 0 and cid <= 255 then
			local lr = self:compileExprAuto(expr.left, rs)

			self.bytecode:emitABC(if and_ then LuauOpcode.LOP_ANDK else LuauOpcode.LOP_ORK, target, lr, uint8_t(cid))
			rs:destroy()
			return
		end
	end

	-- Optimization: if target is a temp register, we can clobber it which allows us to compute the result directly into it
	-- If it's not a temp register, then something like `a = a > 1 or a + 2` may clobber `a` while evaluating left hand side, and `a+2` will break
	local reg = if targetTemp then target else self:allocReg(expr, 1)

	local skipJump: Vector<number> = Vector.new()
	self:compileConditionValue(expr.left, reg, skipJump, not and_)

	self:compileExprTemp(expr.right, reg)

	local moveLabel = self.bytecode:emitLabel()

	self:patchJumps(expr, skipJump, moveLabel)

	if target ~= reg then
		self.bytecode:emitABC(LuauOpcode.LOP_MOVE, target, reg, 0)
	end

	rs:destroy()
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileExprUnary(self: Compiler, expr: AstExprUnary, target: number): ()
	local rs = RegScope.new(self)

	local re = self:compileExprAuto(expr.expr, rs)

	self.bytecode:emitABC(self:getUnaryOp(expr.op), target, re, 0)

	rs:destroy()
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function Compiler.unrollConcats(args: Vector<AstExpr>): ()
	while true do
		local be = args:back():as(AstExprBinary)

		if not be or be.op ~= AstExprBinary.Op.Concat then
			break
		end

		args:pop_back()
		args:push_back(be.left)
		args:push_back(be.right)
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileExprBinary(self: Compiler, expr: AstExprBinary, target: number, targetTemp: boolean): ()
	local rs = RegScope.new(self)

	if
		expr.op == AstExprBinary.Op.Add
		or expr.op == AstExprBinary.Op.Sub
		or expr.op == AstExprBinary.Op.Mul
		or expr.op == AstExprBinary.Op.Div
		or expr.op == AstExprBinary.Op.FloorDiv
		or expr.op == AstExprBinary.Op.Mod
		or expr.op == AstExprBinary.Op.Pow
	then
		local rc = self:getConstantNumber(expr.right)

		if rc >= 0 and rc <= 255 then
			local rl = self:compileExprAuto(expr.left, rs)

			self.bytecode:emitABC(self:getBinaryOpArith(expr.op, true), target, rl, uint8_t(rc))

			if FastVariables.LuauCompileTempTypeInfo then
				self:hintTemporaryExprRegType(expr.left, rl, LuauBytecodeType.LBC_TYPE_NUMBER, 1)
			end
		else
			if expr.op == AstExprBinary.Op.Sub or expr.op == AstExprBinary.Op.Div then
				local lc = self:getConstantNumber(expr.left)

				if lc >= 0 and lc <= 255 then
					local rr = self:compileExprAuto(expr.right, rs)
					local op = if expr.op == AstExprBinary.Op.Sub then LuauOpcode.LOP_SUBRK else LuauOpcode.LOP_DIVRK

					self.bytecode:emitABC(op, target, uint8_t(lc), uint8_t(rc))

					if FastVariables.LuauCompileTempTypeInfo then
						self:hintTemporaryExprRegType(expr.right, rr, LuauBytecodeType.LBC_TYPE_NUMBER, 1)
					end
					rs:destroy()
					return
				end
			end

			local rl = self:compileExprAuto(expr.left, rs)
			local rr = self:compileExprAuto(expr.right, rs)

			self.bytecode:emitABC(self:getBinaryOpArith(expr.op), target, rl, rr)

			if FastVariables.LuauCompileTempTypeInfo then
				self:hintTemporaryExprRegType(expr.left, rl, LuauBytecodeType.LBC_TYPE_NUMBER, 1)
				self:hintTemporaryExprRegType(expr.right, rr, LuauBytecodeType.LBC_TYPE_NUMBER, 1)
			end
		end
	elseif expr.op == AstExprBinary.Op.Concat then
		local args: Vector<AstExpr> = Vector.new()
		args:push_back(expr.left)
		args:push_back(expr.right)

		-- unroll the tree of concats down the right hand side to be able to do multiple ops
		Compiler.unrollConcats(args)

		local regs = self:allocReg(expr, unsigned(args:size()))

		for i = 1, args:size() do
			self:compileExprTemp(args:get(i), uint8_t(regs + i - 1))
		end

		self.bytecode:emitABC(LuauOpcode.LOP_CONCAT, target, regs, uint8_t(regs + args:size() - 1))
	elseif
		expr.op == AstExprBinary.Op.CompareNe
		or expr.op == AstExprBinary.Op.CompareEq
		or expr.op == AstExprBinary.Op.CompareLt
		or expr.op == AstExprBinary.Op.CompareLe
		or expr.op == AstExprBinary.Op.CompareGt
		or expr.op == AstExprBinary.Op.CompareGe
	then
		local jumpLabel = self:compileCompareJump(expr)

		-- note: this skips over the next LOADB instruction because of "1" in the C slot
		self.bytecode:emitABC(LuauOpcode.LOP_LOADB, target, 0, 1)

		local thenLabel = self.bytecode:emitLabel()

		self.bytecode:emitABC(LuauOpcode.LOP_LOADB, target, 1, 0)

		self:patchJump(expr, jumpLabel, thenLabel)
	elseif
		expr.op == AstExprBinary.Op.And
		or expr.op == AstExprBinary.Op.Or
	then
		self:compileExprAndOr(expr, target, targetTemp)
	else
		error("Unexpected binary operation")
	end

	rs:destroy()
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileExprIfElseAndOr(self: Compiler, and_: boolean, creg: number, other: AstExpr, target: number): ()
	local cid = self:getConstantIndex(other)

	if cid >= 0 and cid <= 255 then
		self.bytecode:emitABC(if and_ then LuauOpcode.LOP_ANDK else LuauOpcode.LOP_ORK, target, creg, uint8_t(cid))
	else
		local rs = RegScope.new(self)
		local oreg = self:compileExprAuto(other, rs)

		self.bytecode:emitABC(if and_ then LuauOpcode.LOP_AND else LuauOpcode.LOP_OR, target, creg, oreg)

		rs:destroy()
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileExprIfElse(self: Compiler, expr: AstExprIfElse, target: number, targetTemp: boolean): ()
	if self:isConstant(expr.condition) then
		if self:isConstantTrue(expr.condition) then
			self:compileExpr(expr.trueExpr, target, targetTemp)
		else
			self:compileExpr(expr.falseExpr, target, targetTemp)
		end
	else
		-- Optimization: convert some if..then..else expressions into and/or when the other side has no side effects and is very cheap to compute
		-- if v then v else e => v or e
		-- if v then e else v => v and e
		local creg = self:getExprLocalReg(expr.condition)
		if creg and creg >= 0 then
			if
				creg == self:getExprLocalReg(expr.trueExpr)
				and (self:getExprLocalReg(expr.falseExpr) >= 0 or self:isConstant(expr.falseExpr))
			then
				return self:compileExprIfElseAndOr(false, uint8_t(creg), expr.falseExpr, target)
			elseif
				creg == self:getExprLocalReg(expr.falseExpr)
				and (self:getExprLocalReg(expr.trueExpr) >= 0 or self:isConditionFast(expr.trueExpr))
			then
				return self:compileExprIfElseAndOr(true, uint8_t(creg), expr.trueExpr, target)
			end
		end

		local elseJump: Vector<number> = Vector.new()
		self:compileConditionValue(expr.condition, nil, elseJump, false)
		self:compileExpr(expr.trueExpr, target, targetTemp)

		-- Jump over else expression evaluation
		local thenLabel = self.bytecode:emitLabel()
		self.bytecode:emitAD(LuauOpcode.LOP_JUMP, 0, 0)

		local elseLabel = self.bytecode:emitLabel()
		self:compileExpr(expr.falseExpr, target, targetTemp)
		local endLabel = self.bytecode:emitLabel()

		self:patchJumps(expr, elseJump, elseLabel)
		self:patchJump(expr, thenLabel, endLabel)
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileExprInterpString(self: Compiler, expr: AstExprInterpString, target: number, targetTemp: boolean): ()
	local formatCapacity = 0
	for _, str in expr.strings do
		local occurances = 0
		for _, character in str:split("") do
			if character == "%" then
				occurances += 1
			end
		end
		formatCapacity += #str + occurances
	end

	local formatString: {string} = table.create(formatCapacity)

	local stringsLeft = #expr.strings

	for _, str in expr.strings do
		for _, character in str:split("") do
			table.insert(formatString, character)

			if character == "%" then
				table.insert(formatString, "%")
			end
		end

		stringsLeft -= 1

		if stringsLeft > 0 then
			table.insert(formatString, "%*")
		end
	end

	-- DarkenedRing: Not sure why I bothered making these goofy variables, I am 99% sure the stuff the C++ code does
	-- does not apply to Luau whatsoever, but whatever. I guess Compiler will be 0% slower.

	-- We can't use formatStringRef.data() directly, because short strings don't have their data
	-- pinned in memory, so when interpFormatStrings grows, these pointers will move and become invalid.
	local formatStringPtr
	formatStringPtr = table.concat(formatString)

	local formatStringArray = formatStringPtr
	self.interpStrings:emplace_back(formatStringPtr) -- invalidates formatStringPtr, but keeps formatStringArray intact

	local formatStringIndex = self.bytecode:addConstantString(sref(formatStringArray))
	if formatStringIndex < 0 then
		CompileError.raise(expr.location, "Exceeded constant limit; simplify the code to compile")
	end

	local rs = RegScope.new(self)

	local baseReg = self:allocReg(expr, unsigned(2 + #expr.expressions))

	self:emitLoadK(baseReg, formatStringIndex)

	for index = 1, #expr.expressions do
		self:compileExprTempTop(expr.expressions[index], uint8_t(baseReg + 2 + index - 1))
	end

	local formatMethod = sref(AstName.new("format"))

	local formatMethodIndex = self.bytecode:addConstantString(formatMethod)
	if formatMethodIndex < 0 then
		CompileError.raise(expr.location, "Exceeded constant limit; simplify the code to compile")
	end

	self.bytecode:emitABC(LuauOpcode.LOP_NAMECALL, baseReg, baseReg, uint8_t(BytecodeBuilder.getStringHash(formatMethod)))
	self.bytecode:emitAux(formatMethodIndex)
	self.bytecode:emitABC(LuauOpcode.LOP_CALL, baseReg, uint8_t(#expr.expressions + 2), 2)
	self.bytecode:emitABC(LuauOpcode.LOP_MOVE, target, baseReg, 0)

	rs:destroy()
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function Compiler.encodeHashSize(hashSize: number): number
	local hashSizeLog2 = 0
	while bit32.lshift(1, hashSizeLog2) < hashSize do
		hashSizeLog2 += 1
	end

	return if hashSize == 0 then 0 else uint8_t(hashSizeLog2 + 1)
end

function prototype.compileExprTable(self: Compiler, expr: AstExprTable, target: number, targetTemp: boolean): ()
	-- Optimization: if the table is empty, we can compute it directly into the target
	if #expr.items == 0 then
		local shape = self.tableShapes[expr]

		self.bytecode:addDebugRemark(("allocation: table hash %d"):format(shape.hashSize))

		self.bytecode:emitABC(LuauOpcode.LOP_NEWTABLE, target, Compiler.encodeHashSize(shape.hashSize), 0)
		self.bytecode:emitAux(shape.arraySize)
		return
	end

	local arraySize = 0
	local hashSize = 0
	local recordSize = 0
	local indexSize = 0

	for _, item in expr.items do
		arraySize += btn(item.kind == AstExprTable.Item.Kind.List)
		hashSize += btn(item.kind ~= AstExprTable.Item.Kind.List)
		recordSize += btn(item.kind == AstExprTable.Item.Kind.Record)
	end

	-- Optimization: allocate sequential explicitly specified numeric indices ([1]) as arrays
	if arraySize == 0 and hashSize > 0 then
		for _, item in expr.items do
			assert(item.key) -- no list portion => all items have keys

			local ckey: Constant? = self.constants[item.key :: AstExpr]
			
			indexSize += btn(ckey ~= nil and ckey.type == Constant.Type.Type_Number and ckey.valueNumber == indexSize + 1)
		end

		-- we only perform the optimization if we don't have any other []-keys
		-- technically it's "safe" to do this even if we have other keys, but doing so changes iteration order and may break existing code
		if hashSize == recordSize + indexSize then
			hashSize = recordSize
		else
			indexSize = 0
		end
	end

	local encodedHashSize = Compiler.encodeHashSize(hashSize)

	local rs = RegScope.new(self)

	-- Optimization: if target is a temp register, we can clobber it which allows us to compute the result directly into it
	local reg = if targetTemp then target else self:allocReg(expr, 1)

	-- Optimization: when all items are record fields, use template tables to compile expression
	if arraySize == 0 and indexSize == 0 and hashSize == recordSize and recordSize >= 1 and recordSize < BytecodeBuilder.TableShape.kMaxLength then
		local shape = BytecodeBuilder.TableShape.new()

		for _, item in expr.items do
			assert(item.kind == AstExprTable.Item.Kind.Record)

			local ckey = (item.key :: AstExpr):as(AstExprConstantString)
			assert(ckey)

			local cid = self.bytecode:addConstantString(sref(ckey.value))
			if cid < 0 then
				CompileError.raise(ckey.location, "Exceeded constant limit; simplify the code to compile")
			end

			assert(shape.length < BytecodeBuilder.TableShape.kMaxLength)
			shape.keys[shape.length] = int16_t(cid)
			shape.length += 1
		end

		local tid = self.bytecode:addConstantTable(shape)
		if tid < 0 then
			CompileError.raise(expr.location, "Exceeded constant limit; simplify the code to compile")
		end

		self.bytecode:addDebugRemark(("allocation: table template %d"):format(hashSize))

		if tid < 32768 then
			self.bytecode:emitAD(LuauOpcode.LOP_DUPTABLE, reg, int16_t(tid))
		else
			self.bytecode:emitABC(LuauOpcode.LOP_NEWTABLE, reg, uint8_t(encodedHashSize), 0)
			self.bytecode:emitAux(0)
		end
	else
		-- Optimization: instead of allocating one extra element when the last element of the table literal is ..., let SETLIST allocate the
		-- correct amount of storage
		local last = if #expr.items > 0 then expr.items[#expr.items] else nil

		local trailingVarargs = last ~= nil and last.kind == AstExprTable.Item.Kind.List and last.value:is(AstExprVarargs)
		assert(not trailingVarargs or arraySize > 0)

		local arrayAllocation = arraySize - btn(trailingVarargs) + indexSize

		if hashSize == 0 then
			self.bytecode:addDebugRemark(("allocation: table array %d"):format(arrayAllocation))
		elseif arrayAllocation == 0 then
			self.bytecode:addDebugRemark(("allocation: table hash %d"):format(hashSize))
		else
			self.bytecode:addDebugRemark(("allocation: table hash %d array %d"):format(hashSize, arrayAllocation))
		end

		self.bytecode:emitABC(LuauOpcode.LOP_NEWTABLE, reg, uint8_t(encodedHashSize), 0)
		self.bytecode:emitAux(arrayAllocation)
	end

	local arrayChunkSize = math.min(16, arraySize)
	local arrayChunkReg = self:allocReg(expr, arrayChunkSize)
	local arrayChunkCurrent = 0

	local arrayIndex = 1
	local multRet = false

	for i, item in expr.items do
		local key = item.key
		local value = item.value

		-- some key/value pairs don't require us to compile the expressions, so we need to setup the line info here
		self:setDebugLine(value :: AstExpr)

		if self.options.coverageLevel >= 2 then
			self.bytecode:emitABC(LuauOpcode.LOP_COVERAGE, 0, 0, 0)
		end

		-- flush array chunk on overflow or before hash keys to maintain insertion order
		if arrayChunkCurrent > 0 and (key ~= nil or arrayChunkCurrent == arrayChunkSize) then
			self.bytecode:emitABC(LuauOpcode.LOP_SETLIST, reg, arrayChunkReg, uint8_t(arrayChunkCurrent + 1))
			self.bytecode:emitAux(arrayIndex)
			arrayIndex += arrayChunkCurrent
			arrayChunkCurrent = 0
		end

		-- items with a key are set one by one via SETTABLE/SETTABLEKS/SETTABLEN
		if key then
			local rsi = RegScope.new(self)

			local lv = self:compileLValueIndex(reg, key :: AstExpr, rs)
			local rv = self:compileExprAuto(value :: AstExpr, rsi)

			self:compileAssign(lv, rv)

			rsi:destroy()
		-- items without a key are set using SETLIST so that we can initialize large arrays quickly
		else
			local temp = uint8_t(arrayChunkReg + arrayChunkCurrent)

			if i == #expr.items then
				multRet = self:compileExprTempMultRet(value :: AstExpr, temp)
			else
				self:compileExprTempTop(value :: AstExpr, temp)
			end

			arrayChunkCurrent += 1
		end
	end

	-- flush last array chunk; note that this needs multret handling if the last expression was multret
	if arrayChunkCurrent then
		self.bytecode:emitABC(LuauOpcode.LOP_SETLIST, reg, arrayChunkReg, if multRet then 0 else uint8_t(arrayChunkCurrent + 1))
		self.bytecode:emitAux(arrayIndex)
	end

	if target ~= reg then
		self.bytecode:emitABC(LuauOpcode.LOP_MOVE, target, reg, 0)
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.canImport(self: Compiler, expr: AstExprGlobal): boolean
	return self.options.optimizationLevel >= 1 and getGlobalState(self.globals, expr.name) ~= Global.Written
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.canImportChain(self: Compiler, expr: AstExprGlobal): boolean
	return self.options.optimizationLevel >= 1 and getGlobalState(self.globals, expr.name) == Global.Default
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileExprIndexName(self: Compiler, expr: AstExprIndexName, target: number): ()
	self:setDebugLine(expr) -- normally compileExpr sets up line info, but compileExprIndexName can be called directly

	-- Optimization: index chains that start from global variables can be compiled into GETIMPORT statement
	local importRoot: AstExprGlobal?
	local import1: AstExprIndexName
	local import2: AstExprIndexName?

	local index = expr.expr:as(AstExprIndexName)

	if index then
		importRoot = index.expr:as(AstExprGlobal)
		import1 = index
		import2 = expr
	else
		importRoot = expr.expr:as(AstExprGlobal)
		import1 = expr
	end

	if importRoot and self:canImportChain(importRoot) then
		local id0 = self.bytecode:addConstantString(sref(importRoot.name))
		local id1 = self.bytecode:addConstantString(sref(import1.index))
		local id2 = if import2 ~= nil then self.bytecode:addConstantString(sref(import2.index)) else -1

		if id0 < 0 or id1 < 0 or (import2 ~= nil and id2 < 0) then
			CompileError.raise(expr.location, "Exceeded constant limit; simplify the code to compile")
		end

		-- Note: GETIMPORT encoding is limited to 10 bits per object id component
		if id0 < 1024 and id1 < 1024 and id2 < 1024 then
			local iid = if import2 ~= nil then BytecodeBuilder.getImportId(id0, id1, id2) else BytecodeBuilder.getImportId(id0, id1)
			local cid = self.bytecode:addImport(iid)

			if cid >= 0 and cid < 32768 then
				self.bytecode:emitAD(LuauOpcode.LOP_GETIMPORT, target, int16_t(cid))
				self.bytecode:emitAux(iid)
				return
			end
		end
	end

	local rs = RegScope.new(self)
	local reg = self:compileExprAuto(expr.expr, rs)

	self:setDebugLine(expr.indexLocation)

	local iname = sref(expr.index)
	local cid = self.bytecode:addConstantString(iname)
	if cid < 0 then
		CompileError.raise(expr.location, "Exceeded constant limit; simplify the code to compile")
	end

	self.bytecode:emitABC(LuauOpcode.LOP_GETTABLEKS, target, reg, uint8_t(BytecodeBuilder.getStringHash(iname)))
	self.bytecode:emitAux(cid)

	if FastVariables.LuauCompileTempTypeInfo then
		self:hintTemporaryExprRegType(expr.expr, reg, LuauBytecodeType.LBC_TYPE_TABLE, 2)
	end

	rs:destroy()
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileExprIndexExpr(self: Compiler, expr: AstExprIndexExpr, target: number): ()
	local rs = RegScope.new(self)

	local cv = self:getConstant(expr.index)

	if cv.type == Constant.Type.Type_Number and cv.valueNumber >= 1 and cv.valueNumber <= 256 and int(cv.valueNumber) == cv.valueNumber then
		local i = uint8_t(int(cv.valueNumber) - 1)

		local rt = self:compileExprAuto(expr.expr, rs)

		self:setDebugLine(expr.index)

		self.bytecode:emitABC(LuauOpcode.LOP_GETTABLEN, target, rt, i)
	elseif cv.type == Constant.Type.Type_String then
		local iname = sref(cv:getString())
		local cid = self.bytecode:addConstantString(iname)
		if cid < 0 then
			CompileError.raise(expr.location, "Exceeded constant limit; simplify the code to compile")
		end

		local rt = self:compileExprAuto(expr.expr, rs)

		self:setDebugLine(expr.index)

		self.bytecode:emitABC(LuauOpcode.LOP_GETTABLEKS, target, rt, uint8_t(BytecodeBuilder.getStringHash(iname)))
		self.bytecode:emitAux(cid)
	else
		local rt = self:compileExprAuto(expr.expr, rs)
		local ri = self:compileExprAuto(expr.index, rs)

		self.bytecode:emitABC(LuauOpcode.LOP_GETTABLE, target, rt, ri)
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileExprGlobal(self: Compiler, expr: AstExprGlobal, target: number): ()
	-- Optimization: builtin globals can be retrieved using GETIMPORT
	if self:canImport(expr) then
		local id0 = self.bytecode:addConstantString(sref(expr.name))
		if id0 < 0 then
			CompileError.raise(expr.location, "Exceeded constant limit; simplify the code to compile")
		end

		-- Note: GETIMPORT encoding is limited to 10 bits per object id component
		if id0 < 1024 then
			local iid = BytecodeBuilder.getImportId(id0)
			local cid = self.bytecode:addImport(iid)

			if cid >= 0 and cid < 32768 then
				self.bytecode:emitAD(LuauOpcode.LOP_GETIMPORT, target, int16_t(cid))
				self.bytecode:emitAux(iid)
				return
			end
		end
	end

	local gname = sref(expr.name)
	local cid = self.bytecode:addConstantString(gname)
	if cid < 0 then
		CompileError.raise(expr.location, "Exceeded constant limit; simplify the code to compile")
	end

	self.bytecode:emitABC(LuauOpcode.LOP_GETGLOBAL, target, 0, uint8_t(BytecodeBuilder.getStringHash(gname)))
	self.bytecode:emitAux(cid)
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileExprConstant(self: Compiler, node: AstExpr, cv: Constant, target: number): ()
	if cv.type == Constant.Type.Type_Nil then
		self.bytecode:emitABC(LuauOpcode.LOP_LOADNIL, target, 0, 0)
	elseif cv.type == Constant.Type.Type_Boolean then
		self.bytecode:emitABC(LuauOpcode.LOP_LOADB, target, btn(cv.valueBoolean), 0)
	elseif cv.type == Constant.Type.Type_Number then
		local d = cv.valueNumber

		if d >= -32768 and d <= 32767 and int16_t(d) == d and not (d == 0 and math.sign(d) == -1) then
			-- short number encoding: doesn't require a table entry lookup
			self.bytecode:emitAD(LuauOpcode.LOP_LOADN, target, int16_t(d))
		else
			-- long number encoding: use generic constant path
			local cid = self.bytecode:addConstantNumber(d)
			if cid < 0 then
				CompileError.raise(node.location, "Exceeded constant limit; simplify the code to compile")
			end

			self:emitLoadK(target, cid)
		end
	elseif cv.type == Constant.Type.Type_Vector then
		local cid = self.bytecode:addConstantVector(cv.valueVector[1], cv.valueVector[2], cv.valueVector[3], cv.valueVector[4])
		self:emitLoadK(target, cid)
	elseif cv.type == Constant.Type.Type_String then
		local cid = self.bytecode:addConstantString(sref(cv:getString()))
		if cid < 0 then
			CompileError.raise(node.location, "Exceeded constant limit; simplify the code to compile")
		end

		self:emitLoadK(target, cid)
	else
		error("Unexpected constant type")
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileExpr(self: Compiler, node: AstExpr, target: number, targetTemp: boolean?): ()
	local targetTemp = targetTemp or false

	self:setDebugLine(node)

	if self.options.coverageLevel >= 2 and self:needsCoverage(node) then
		self.bytecode:emitABC(LuauOpcode.LOP_COVERAGE, 0, 0, 0)
	end

	-- Optimization: if expression has a constant value, we can emit it directly
	local cv = self.constants[node]
	if cv and cv.type ~= Constant.Type.Type_Unknown then
		self:compileExprConstant(node, cv, target)
		return
	end

	local exprGroup = node:as(AstExprGroup)
	local exprConstantNil = node:as(AstExprConstantNil)
	local exprConstantBool = node:as(AstExprConstantBool)
	local exprConstantNumber = node:as(AstExprConstantNumber)
	local exprConstantString = node:as(AstExprConstantString)
	local exprLocal = node:as(AstExprLocal)
	local exprGlobal = node:as(AstExprGlobal)
	local exprVarargs = node:as(AstExprVarargs)
	local exprCall = node:as(AstExprCall)
	local exprIndexName = node:as(AstExprIndexName)
	local exprIndexExpr = node:as(AstExprIndexExpr)
	local exprFunction = node:as(AstExprFunction)
	local exprTable = node:as(AstExprTable)
	local exprUnary = node:as(AstExprUnary)
	local exprBinary = node:as(AstExprBinary)
	local exprTypeAssertion = node:as(AstExprTypeAssertion)
	local exprIfElse = node:as(AstExprIfElse)
	local exprInterpString = node:as(AstExprInterpString)

	if exprGroup then
		self:compileExpr(exprGroup.expr, target, targetTemp)
	elseif exprConstantNil then
		self.bytecode:emitABC(LuauOpcode.LOP_LOADNIL, target, 0, 0)
	elseif exprConstantBool then
		self.bytecode:emitABC(LuauOpcode.LOP_LOADB, target, btn(exprConstantBool.value), 0)
	elseif exprConstantNumber then
		local cid = self.bytecode:addConstantNumber(exprConstantNumber.value)
		if cid < 0 then
			CompileError.raise(exprConstantNumber.location, "Exceeded constant limit; simplify the code to compile")
		end

		self:emitLoadK(target, cid)
	elseif exprConstantString then
		local cid = self.bytecode:addConstantString(sref(exprConstantString.value))
		if cid < 0 then
			CompileError.raise(exprConstantString.location, "Exceeded constant limit; simplify the code to compile")
		end

		self:emitLoadK(target, cid)
	elseif exprLocal then
		-- note: this can't check expr->upvalue because upvalues may be upgraded to locals during inlining
		local reg = self:getExprLocalReg(exprLocal)
		if reg >= 0 then
			-- Optimization: we don't need to move if target happens to be in the same register
			if self.options.optimizationLevel == 0 or target ~= reg then
				self.bytecode:emitABC(LuauOpcode.LOP_MOVE, target, uint8_t(reg), 0)
			end
		else
			assert(exprLocal.upvalue)
			local uid = self:getUpval(exprLocal.localAst)

			self.bytecode:emitABC(LuauOpcode.LOP_GETUPVAL, target, uid, 0)
		end
	elseif exprGlobal then
		self:compileExprGlobal(exprGlobal, target)
	elseif exprVarargs then
		self:compileExprVarargs(exprVarargs, target, 1)
	elseif exprCall then
		-- Optimization: when targeting temporary registers, we can compile call in a special mode that doesn't require extra register moves
		if targetTemp and target == self.regTop - 1 then
			self:compileExprCall(exprCall, target, 1, true)
		else
			self:compileExprCall(exprCall, target, 1)
		end
	elseif exprIndexName then
		self:compileExprIndexName(exprIndexName, target)
	elseif exprIndexExpr then
		self:compileExprIndexExpr(exprIndexExpr, target)
	elseif exprFunction then
		self:compileExprFunction(exprFunction, target)
	elseif exprTable then
		self:compileExprTable(exprTable, target, targetTemp)
	elseif exprUnary then
		self:compileExprUnary(exprUnary, target)
	elseif exprBinary then
		self:compileExprBinary(exprBinary, target, targetTemp)
	elseif exprTypeAssertion then
		self:compileExpr(exprTypeAssertion.expr, target, targetTemp)
	elseif exprIfElse then
		self:compileExprIfElse(exprIfElse, target, targetTemp)
	elseif exprInterpString then
		self:compileExprInterpString(exprInterpString, target, targetTemp)
	else
		error("Unknown expression type")
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileExprTemp(self: Compiler, node: AstExpr, target: number): ()
	return self:compileExpr(node, target, true)
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileExprAuto(self: Compiler, node: AstExpr, _: RegScope): number
	-- Optimization: directly return locals instead of copying them to a temporary
	local reg = self:getExprLocalReg(node)
	if reg >= 0 then
		return uint8_t(reg)
	end

	-- note: the register is owned by the parent scope
	local reg = self:allocReg(node, 1)

	self:compileExprTemp(node, reg)

	return reg
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileExprSide(self: Compiler, node: AstExpr): ()
	-- Optimization: some expressions never carry side effects so we don't need to emit any code
	if node:is(AstExprLocal) or node:is(AstExprGlobal) or node:is(AstExprVarargs) or node:is(AstExprFunction) or self:isConstant(node) then
		return
	end

	-- note: the remark is omitted for calls as it's fairly noisy due to inlining
	if not node:is(AstExprCall) then
		self.bytecode:addDebugRemark("expression only compiled for side effects")
	end

	local rsi = RegScope.new(self)
	self:compileExprAuto(node, rsi)
	rsi:destroy()
end

--[=[
	@within Compiler
	@private
	@since v0.1.0

	initializes target..target+targetCount-1 range using expression
	if expression is a call/vararg, we assume it returns all values, otherwise we fill the rest with nil
	assumes target register range can be clobbered and is at the top of the register space if targetTop = true
]=]
function prototype.compileExprTempN(self: Compiler, node: AstExpr, target: number, targetCount: number, targetTop: boolean): ()
	-- we assume that target range is at the top of the register space and can be clobbered
	-- this is what allows us to compile the last call expression - if it's a call - using targetTop=true
	assert(not targetTop or unsigned(target + targetCount) == self.regTop)

	local exprCall = node:as(AstExprCall)
	local exprVarargs = node:as(AstExprVarargs)

	if exprCall then
		self:compileExprCall(exprCall, target, targetCount, targetTop)
	elseif exprVarargs then
		self:compileExprVarargs(exprVarargs, target, targetCount)
	else
		self:compileExprTemp(node, target)

		for i = 1, targetCount - 1 do
			self.bytecode:emitABC(LuauOpcode.LOP_LOADNIL, uint8_t(target + i), 0, 0)
		end
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0

	initializes target..target+targetCount-1 range using expressions from the list
	if list has fewer expressions, and last expression is multret, we assume it returns the rest of the values
	if list has fewer expressions, and last expression isn't multret, we fill the rest with nil
	assumes target register range can be clobbered and is at the top of the register space if targetTop = true
]=]
function prototype.compileExprListTemp(self: Compiler, list: {AstExpr}, target: number, targetCount: number, targetTop: boolean): ()
	-- we assume that target range is at the top of the register space and can be clobbered
    -- this is what allows us to compile the last call expression - if it's a call - using targetTop=true
	assert(not targetTop or unsigned(target + targetCount) == self.regTop)

	if #list == targetCount then
		for i = 1, #list do
			self:compileExprTemp(list[i], uint8_t(target + i - 1))
		end
	elseif #list > targetCount then
		for i = 1, targetCount do
			self:compileExprTemp(list[i], uint8_t(target + i - 1))
		end

		-- evaluate extra expressions for side effects
		for i = targetCount + 1, #list do
			self:compileExprSide(list[i])
		end
	elseif #list > 0 then
		for i = 1, #list - 1 do
			self:compileExprTemp(list[i], uint8_t(target + i))
		end

		self:compileExprTempN(list[#list], uint8_t(target + #list - 1), uint8_t(targetCount - (#list - 1)), targetTop)
	else
		for i = 0, targetCount - 1 do
			self.bytecode:emitABC(LuauOpcode.LOP_LOADNIL, uint8_t(target + i), 0, 0)
		end
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileLValueIndex(self: Compiler, reg: number, index: AstExpr, rs: RegScope): LValue
	local cv = self:getConstant(index)

	if cv.type == Constant.Type.Type_Number and cv.valueNumber >= 1 and cv.valueNumber <= 256 and int(cv.valueNumber) == cv.valueNumber then
		local result = LValue.new(LValue.Kind.Kind_IndexNumber)
		result.reg = reg
		result.number = uint8_t(int(cv.valueNumber) - 1)
		result.location = index.location

		return result
	elseif cv.type == Constant.Type.Type_String then
		local result = LValue.new(LValue.Kind.Kind_IndexName)
		result.reg = reg
		result.name = sref(cv:getString())
		result.location = index.location

		return result
	else
		local result = LValue.new(LValue.Kind.Kind_IndexExpr)
		result.reg = reg
		result.index = self:compileExprAuto(index, rs)
		result.location = index.location

		return result
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileLValue(self: Compiler, node: AstExpr, rs: RegScope): LValue
	self:setDebugLine(node)

	local exprLocal = node:as(AstExprLocal)
	local exprGlobal = node:as(AstExprGlobal)
	local exprIndexName = node:as(AstExprIndexName)
	local exprIndexExpr = node:as(AstExprIndexExpr)

	if exprLocal then
		-- note: this can't check expr->upvalue because upvalues may be upgraded to locals during inlining
		local reg = self:getExprLocalReg(exprLocal)
		if reg >= 0 then
			local result = LValue.new(LValue.Kind.Kind_Local)
			result.reg = uint8_t(reg)
			result.location = node.location

			return result
		else
			assert(exprLocal.upvalue)

			local result = LValue.new(LValue.Kind.Kind_Upvalue)
			result.upval = self:getUpval(exprLocal.localAst)
			result.location = node.location

			return result
		end
	elseif exprGlobal then
		local result = LValue.new(LValue.Kind.Kind_Global)
		result.name = sref(exprGlobal.name)
		result.location = node.location

		return result
	elseif exprIndexName then
		local result = LValue.new(LValue.Kind.Kind_IndexName)
		result.reg = self:compileExprAuto(exprIndexName.expr, rs)
		result.name = sref(exprIndexName.index)
		result.location = node.location

		return result
	elseif exprIndexExpr then
		local reg = self:compileExprAuto(exprIndexExpr.expr, rs)

		return self:compileLValueIndex(reg, exprIndexExpr.index, rs)
	else
		error("Unknown assignment expression")
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileLValueUse(self: Compiler, lv: LValue, reg: number, set: boolean): ()
	self:setDebugLine(lv.location)

	if lv.kind == LValue.Kind.Kind_Local then
		if set then
			self.bytecode:emitABC(LuauOpcode.LOP_MOVE, lv.reg, reg, 0)
		else
			self.bytecode:emitABC(LuauOpcode.LOP_MOVE, reg, lv.reg, 0)
		end
	elseif lv.kind == LValue.Kind.Kind_Upvalue then
		self.bytecode:emitABC(if set then LuauOpcode.LOP_SETUPVAL else LuauOpcode.LOP_GETUPVAL, reg, lv.upval, 0)
	elseif lv.kind == LValue.Kind.Kind_Global then
		local cid = self.bytecode:addConstantString(lv.name)
		if cid < 0 then
			CompileError.raise(lv.location, "Exceeded constant limit; simplify the code to compile")
		end

		self.bytecode:emitABC(if set then LuauOpcode.LOP_SETGLOBAL else LuauOpcode.LOP_GETGLOBAL, reg, 0, BytecodeBuilder.getStringHash(lv.name))
		self.bytecode:emitAux(cid)
	elseif lv.kind == LValue.Kind.Kind_IndexName then
		local cid = self.bytecode:addConstantString(lv.name)
		if cid < 0 then
			CompileError.raise(lv.location, "Exceeded constant limit; simplify the code to compile")
		end

		self.bytecode:emitABC(if set then LuauOpcode.LOP_SETTABLEKS else LuauOpcode.LOP_GETTABLEKS, reg, lv.reg, BytecodeBuilder.getStringHash(lv.name))
		self.bytecode:emitAux(cid)
	elseif lv.kind == LValue.Kind.Kind_IndexNumber then
		self.bytecode:emitABC(if set then LuauOpcode.LOP_SETTABLEN else LuauOpcode.LOP_GETTABLEN, reg, lv.reg, lv.number)
	elseif lv.kind == LValue.Kind.Kind_IndexExpr then
		self.bytecode:emitABC(if set then LuauOpcode.LOP_SETTABLE else LuauOpcode.LOP_GETTABLE, reg, lv.reg, lv.index)
	else
		error("Unknown lvalue kind")
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileAssign(self: Compiler, lv: LValue, source: number): ()
	self:compileLValueUse(lv, source, true)
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.getExprLocal(self: Compiler, node: AstExpr): AstExprLocal?
	local exprLocal = node:as(AstExprLocal)
	local exprGroup = node:as(AstExprGroup)
	local exprTypeAssertion = node:as(AstExprTypeAssertion)

	if exprLocal then
		return exprLocal
	elseif exprGroup then
		return self:getExprLocal(exprGroup.expr)
	elseif exprTypeAssertion then
		return self:getExprLocal(exprTypeAssertion.expr)
	else
		return nil
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.getExprLocalReg(self: Compiler, node: AstExpr): number
	local expr = self:getExprLocal(node)
	if expr then
		-- note: this can't check expr->upvalue because upvalues may be upgraded to locals during inlining
		local l = self.locals[expr.localAst]

		return if l and l.allocated then l.reg else -1
	else
		return -1
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.isStatBreak(self: Compiler, node: AstStat): boolean
	local stat = node:as(AstStatBlock)
	if stat then
		return #stat.body == 1 and stat.body[1]:is(AstStatBreak)
	end

	return node:is(AstStatBreak)
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.extractStatContinue(self: Compiler, block: AstStatBlock): AstStatContinue?
	if #block.body == 1 then
		return block.body[1]:as(AstStatContinue)
	else
		return nil
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileStatIf(self: Compiler, stat: AstStatIf): ()
	-- Optimization: condition is always false => we only need the else body
	if self:isConstantFalse(stat.condition) then
		if stat.elsebody then
			self:compileStat(stat.elsebody)
		end
		return
	end

	-- Optimization: condition is always false but isn't a constant => we only need the else body and condition's side effects
	local cand = stat.condition:as(AstExprBinary)
	if cand and cand.op == AstExprBinary.Op.And and self:isConstantFalse(cand.right) then
		self:compileExprSide(cand.left)
		if stat.elsebody then
			self:compileStat(stat.elsebody)
		end
		return
	end

	-- Optimization: body is a "break" statement with no "else" => we can directly break out of the loop in "then" case
	if stat.elsebody == nil and self:isStatBreak(stat.thenbody) and not self:areLocalsCaptured(self.loops:back().localOffset) then
		-- fallthrough = continue with the loop as usual
		local elseJump: Vector<number> = Vector.new()
		self:compileConditionValue(stat.condition, nil, elseJump, true)

		for _, jump in elseJump:data() do
			self.loopJumps:push_back(LoopJump.new(LoopJump.Type.Break, jump))
		end
		return
	end

	local continueStatement = self:extractStatContinue(stat.thenbody)

	-- Optimization: body is a "continue" statement with no "else" => we can directly continue in "then" case
	if stat.elsebody == nil and continueStatement ~= nil and not self:areLocalsCaptured(self.loops:back().localOffsetContinue) then
		-- track continue statement for repeat..until validation (validateContinueUntil)
		if self.loops:back().continueUsed == nil then
			self.loops:back().continueUsed = continueStatement
		end

		local elseJump: Vector<number> = Vector.new()
		self:compileConditionValue(stat.condition, nil, elseJump, true)

		for _, jump in elseJump:data() do
			self.loopJumps:push_back(LoopJump.new(LoopJump.Type.Continue, jump))
		end
		return
	end

	local elseJump: Vector<number> = Vector.new()
	self:compileConditionValue(stat.condition, nil, elseJump, false)

	self:compileStat(stat.thenbody)

	if stat.elsebody ~= nil and elseJump:size() > 0 then
		-- we don't need to skip past "else" body if "then" ends with return/break/continue
		-- this is important because, if "else" also ends with return, we may *not* have any statement to skip to!
		if self:alwaysTerminates(stat.thenbody) then
			local elseLabel = self.bytecode:emitLabel()

			self:compileStat(stat.elsebody)

			self:patchJumps(stat, elseJump, elseLabel)
		else
			local thenLabel = self.bytecode:emitLabel()

			self.bytecode:emitAD(LuauOpcode.LOP_JUMP, 0, 0)

			local elseLabel = self.bytecode:emitLabel()

			self:compileStat(stat.elsebody)

			local endLabel = self.bytecode:emitLabel()

			self:patchJumps(stat, elseJump, elseLabel)
			self:patchJump(stat, thenLabel, endLabel)
		end
	else
		local endLabel = self.bytecode:emitLabel()

		self:patchJumps(stat, elseJump, endLabel)
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileStatWhile(self: Compiler, stat: AstStatWhile): ()
	-- Optimization: condition is always false => there's no loop!
	if self:isConstantFalse(stat.condition) then
		return
	end

	local oldJumps = self.loopJumps:size()
	local oldLocals = self.localStack:size()

	self.loops:push_back(Loop.new(oldLocals, oldLocals, nil))
	self.hasLoops = true

	local loopLabel = self.bytecode:emitLabel()

	local elseJump: Vector<number> = Vector.new()
	self:compileConditionValue(stat.condition, nil, elseJump, false)

	self:compileStat(stat.body)

	local contLabel = self.bytecode:emitLabel()

	local backLabel = self.bytecode:emitLabel()

	self:setDebugLine(stat.condition)

	-- Note: this is using JUMPBACK, not JUMP, since JUMPBACK is interruptible and we want all loops to have at least one interruptible
	-- instruction
	self.bytecode:emitAD(LuauOpcode.LOP_JUMPBACK, 0, 0)

	local endLabel = self.bytecode:emitLabel()
	
	self:patchJump(stat, backLabel, loopLabel)
	self:patchJumps(stat, elseJump, endLabel)

	self:patchLoopJumps(stat, oldJumps, endLabel, contLabel)
	self.loopJumps:resize(oldJumps)

	self.loops:pop_back()
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileStatRepeat(self: Compiler, stat: AstStatRepeat): ()
	local oldJumps = self.loopJumps:size()
	local oldLocals = self.localStack:size()
	
	self.loops:push_back(Loop.new(oldLocals, oldLocals, nil))
	self.hasLoops = true

	local loopLabel = self.bytecode:emitLabel()

	-- note: we "inline" compileStatBlock here so that we can close/pop locals after evaluating condition
	-- this is necessary because condition can access locals declared inside the repeat..until body
	local body = stat.body

	local rs = RegScope.new(self)

	local continueValidated = false
	local conditionLocals = 0

	for i = 1, #body.body do
		self:compileStat(body.body[i])

		-- continue statement inside the repeat..until loop should not close upvalues defined directly in the loop body
		-- (but it must still close upvalues defined in more nested blocks)
		-- this is because the upvalues defined inside the loop body may be captured by a closure defined in the until
		-- expression that continue will jump to.
		self.loops:back().localOffsetContinue = self.localStack:size()

		-- if continue was called from this statement, any local defined after this in the loop body should not be accessed by until condition
		-- it is sufficient to check this condition once, as if this holds for the first continue, it must hold for all subsequent continues.
		if self.loops:back().continueUsed and not continueValidated then
			self:validateContinueUntil(assert(self.loops:back().continueUsed), stat.condition, body, i + 1)
			continueValidated = true
			conditionLocals = self.localStack:size()
		end
	end

	-- if continue was used, some locals might not have had their initialization completed
	-- the lifetime of these locals has to end before the condition is executed
	-- because referencing skipped locals is not possible from the condition, this earlier closure doesn't affect upvalues
	if continueValidated then
		-- if continueValidated is set, it means we have visited at least one body node and size > 0
		self:setDebugLineEnd(body.body[#body.body])

		self:closeLocals(conditionLocals)

		self:popLocals(conditionLocals)
	end

	local contLabel = self.bytecode:emitLabel()

	local endLabel: number

	self:setDebugLine(stat.condition)

	if self:isConstantTrue(stat.condition) then
		self:closeLocals(oldLocals)

		endLabel = self.bytecode:emitLabel()
	else
		local skipJump: Vector<number> = Vector.new()
		self:compileConditionValue(stat.condition, nil, skipJump, true)

		-- we close locals *after* we compute loop conditionals because during computation of condition it's (in theory) possible that user code
		-- mutates them
		self:closeLocals(oldLocals)
		
		local backLabel = self.bytecode:emitLabel()

		-- Note: this is using JUMPBACK, not JUMP, since JUMPBACK is interruptible and we want all loops to have at least one interruptible
		-- instruction
		self.bytecode:emitAD(LuauOpcode.LOP_JUMPBACK, 0, 0)

		local skipLabel = self.bytecode:emitLabel()

		-- we need to close locals *again* after the loop ends because the first closeLocals would be jumped over on the last iteration
		self:closeLocals(oldLocals)

		endLabel = self.bytecode:emitLabel()

		self:patchJump(stat, backLabel, loopLabel)
		self:patchJumps(stat, skipJump, skipLabel)
	end

	self:popLocals(oldLocals)

	self:patchLoopJumps(stat, oldJumps, endLabel, contLabel)
	self.loopJumps:resize(oldJumps)

	self.loops:pop_back()

	rs:destroy()
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileInlineReturn(self: Compiler, stat: AstStatReturn, fallthrough: boolean): ()
	self:setDebugLine(stat) -- normally compileStat sets up line info, but compileInlineReturn can be called directly

	local frame = self.inlineFrames:back()

	self:compileExprListTemp(stat.list, frame.target, frame.targetCount, false)

	self:closeLocals(frame.localOffset)

	if not fallthrough then
		local jumpLabel = self.bytecode:emitLabel()
		self.bytecode:emitAD(LuauOpcode.LOP_JUMP, 0, 0)

		self.inlineFrames:back().returnJumps:push_back(jumpLabel)
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileStatReturn(self: Compiler, stat: AstStatReturn): ()
	local rs = RegScope.new(self)

	local temp = 0
	local consecutive = false
	local multRet = false

	-- Optimization: return locals directly instead of copying them into a temporary
	-- this is very important for a single return value and occasionally effective for multiple values
	local reg = if #stat.list > 0 then self:getExprLocalReg(stat.list[1]) else -1
	if reg >= 0 then
		temp = uint8_t(reg)
		consecutive = true

		for i = 2, #stat.list do
			if self:getExprLocalReg(stat.list[i]) ~= int(temp + i - 1) then
				consecutive = false
				break
			end
		end
	end

	if not consecutive and #stat.list > 0 then
		temp = self:allocReg(stat, unsigned(#stat.list))

		-- Note: if the last element is a function call or a vararg specifier, then we need to somehow return all values that that call returned
		for i = 1, #stat.list do
			if i == #stat.list then
				multRet = self:compileExprTempMultRet(stat.list[i], uint8_t(temp + i - 1))
			else
				self:compileExprTempTop(stat.list[i], uint8_t(temp + i - 1))
			end
		end
	end

	self:closeLocals(0)

	self.bytecode:emitABC(LuauOpcode.LOP_RETURN, uint8_t(temp), if multRet then 0 else uint8_t(#stat.list + 1), 0)

	rs:destroy()
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.areLocalsRedundant(self: Compiler, stat: AstStatLocal): boolean
	-- Extra expressions may have side effects
	if #stat.values > #stat.vars then
		return false
	end

	for _, astLocal in stat.vars do
		local v = self.variables[astLocal :: AstLocal]

		if v == nil or not v.constant then
			return false
		end
	end

	return true
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileStatLocal(self: Compiler, stat: AstStatLocal): ()
	-- Optimization: we don't need to allocate and assign const locals, since their uses will be constant-folded
	if self.options.optimizationLevel >= 1 and self.options.debugLevel <= 1 and self:areLocalsRedundant(stat) then
		return
	end

	-- Optimization: for 1-1 local assignments, we can reuse the register *if* neither local is mutated
	if self.options.optimizationLevel >= 1 and #stat.vars == 1 and #stat.values == 1 then
		local re = self:getExprLocal(stat.values[1])
		if re then
			local lv = self.variables[stat.vars[1]]
			local rv = self.variables[re.localAst]

			local reg = self:getExprLocalReg(re)
			if reg >= 0 and (lv == nil or not lv.written) and (rv == nil or not rv.written) then
				self:pushLocal(stat.vars[1], uint8_t(reg), kDefaultAllocPc)
				return
			end
		end
	end

	-- note: allocReg in this case allocates into parent block register - note that we don't have RegScope here
	local vars = self:allocReg(stat, unsigned(#stat.vars))
	local allocpc = if FastVariables.LuauCompileTypeInfo then self.bytecode:getDebugPC() else kDefaultAllocPc

	self:compileExprListTemp(stat.values, vars, uint8_t(#stat.vars), true)

	for i = 1, #stat.vars do
		self:pushLocal(stat.vars[i], uint8_t(vars + i - 1), allocpc)
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.tryCompileUnrolledFor(self: Compiler, stat: AstStatFor, thresholdBase: number, thresholdMaxBoost: number): boolean
	local one = Constant.new(Constant.Type.Type_Number)
	one.valueNumber = 1

	local fromc = self:getConstant(stat.from)
	local toc = self:getConstant(stat.to)
	local stepc = if stat.step ~= nil then self:getConstant(stat.step) else one

	local tripCount =
		if fromc.type == Constant.Type.Type_Number and toc.type == Constant.Type.Type_Number and stepc.type == Constant.Type.Type_Number
		then getTripCount(fromc.valueNumber, toc.valueNumber, stepc.valueNumber)
		else -1
	
	if tripCount < 0 then
		self.bytecode:addDebugRemark("loop unroll failed: invalid iteration count")
		return false
	end

	if tripCount > thresholdBase then
		self.bytecode:addDebugRemark(("loop unroll failed: too many iterations (%d)"):format(tripCount))
		return false
	end

	local lv = self.variables[stat.var]
	if lv and lv.written then
		self.bytecode:addDebugRemark("loop unroll failed: mutable loop variable")
		return false
	end

	local var = stat.var
	local costModel = modelCost(stat.body, var, 1, self.builtins)

	-- we use a dynamic cost threshold that's based on the fixed limit boosted by the cost advantage we gain due to unrolling
	local varc = {true}
	local unrolledCost = computeCost(costModel, varc, 1) * tripCount
	local baselineCost = (computeCost(costModel, nil, 0) + 1) * tripCount
	local unrollProfit = if unrolledCost == 0 then thresholdMaxBoost else math.min(thresholdMaxBoost, 100 * baselineCost / unrolledCost)

	local threshold = thresholdBase * unrollProfit / 100

	if unrolledCost > threshold then
		self.bytecode:addDebugRemark(
			("loop unroll failed: too expensive (iterations %d, cost %d, profit %.2fx)"):format(
				tripCount,
				unrolledCost,
				unrollProfit / 100
			)
		)
		return false
	end

	self.bytecode:addDebugRemark(
		("loop unroll succeeded (iterations %d, cost %d, profit %.2fx)"):format(tripCount, unrolledCost, unrollProfit / 100)
	)

	self:compileUnrolledFor(stat, tripCount, fromc.valueNumber, stepc.valueNumber)
	return true
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileUnrolledFor(self: Compiler, stat: AstStatFor, tripCount: number, from: number, step: number): ()
	local var = stat.var

	local oldLocals = self.localStack:size()
	local oldJumps = self.loopJumps:size()

	self.loops:push_back(Loop.new(oldLocals, oldLocals, nil))

	for iv = 0, tripCount - 1 do
		-- we need to re-fold constants in the loop body with the new value; this reuses computed constant values elsewhere in the tree
		self.locstants[var].type = Constant.Type.Type_Number
		self.locstants[var].valueNumber = from + iv * step

		foldConstants(self.constants, self.variables, self.locstants, self.builtinsFold, self.builtinsFoldMathK, stat)

		local iterJumps = self.loopJumps:size()

		self:compileStat(stat.body)

		-- all continue jumps need to go to the next iteration
		local contLabel = self.bytecode:emitLabel()
		for i = iterJumps + 1, self.loopJumps:size() do
			if self.loopJumps:get(i).type == LoopJump.Type.Continue then
				self:patchJump(stat, self.loopJumps:get(i).label, contLabel)
			end
		end
	end

	-- all break jumps need to go past the loop
	local endLabel = self.bytecode:emitLabel()

	for i = oldJumps + 1, self.loopJumps:size() do
		if self.loopJumps:get(i).type == LoopJump.Type.Break then
			self:patchJump(stat, self.loopJumps:get(i).label, endLabel)
		end
	end

	self.loopJumps:resize(oldJumps)

	self.loops:pop_back()

	-- clean up fold state in case we need to recompile - normally we compile the loop body once, but due to inlining we may need to do it again
	self.locstants[var].type = Constant.Type.Type_Unknown

	foldConstants(self.constants, self.variables, self.locstants, self.builtinsFold, self.builtinsFoldMathK, stat)
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileStatFor(self: Compiler, stat: AstStatFor): ()
	local rs = RegScope.new(self)

	-- Optimization: small loops can be unrolled when it is profitable
	if
		self.options.optimizationLevel >= 2
		and self:isConstant(stat.to)
		and self:isConstant(stat.from)
		and (stat.step == nil or self:isConstant(stat.step))
	then
		if self:tryCompileUnrolledFor(stat, FastVariables.LuauCompileLoopUnrollThreshold, FastVariables.LuauCompileLoopUnrollThresholdMaxBoost) then
			rs:destroy()
			return
		end
	end

	local oldLocals = self.localStack:size()
	local oldJumps = self.loopJumps:size()

	self.loops:push_back(Loop.new(oldLocals, oldLocals, nil))
	self.hasLoops = true

	-- register layout: limit, step, index
	local regs = self:allocReg(stat, 3)

	-- if the iteration index is assigned from within the loop, we need to protect the internal index from the assignment
	-- to do that, we will copy the index into an actual local variable on each iteration
	-- this makes sure the code inside the loop can't interfere with the iteration process (other than modifying the table we're iterating
	-- through)
	local varreg = regs + 2
	local varregallocpc = if FastVariables.LuauCompileTypeInfo then self.bytecode:getDebugPC() else kDefaultAllocPc

	local il = self.variables[stat.var]
	if il and il.written then
		varreg = self:allocReg(stat, 1)
	end

	self:compileExprTemp(stat.from, uint8_t(regs + 2))
	self:compileExprTemp(stat.to, uint8_t(regs + 0))

	if stat.step ~= nil then
		self:compileExprTemp(stat.step, uint8_t(regs + 1))
	else
		self.bytecode:emitABC(LuauOpcode.LOP_LOADN, uint8_t(regs + 1), 1, 0)
	end

	local forLabel = self.bytecode:emitLabel()

	self.bytecode:emitAD(LuauOpcode.LOP_FORNPREP, regs, 0)

	local loopLabel = self.bytecode:emitLabel()

	if varreg ~= regs + 2 then
		self.bytecode:emitABC(LuauOpcode.LOP_MOVE, varreg, regs + 2, 0)
	end

	self:pushLocal(stat.var, varreg, varregallocpc)

	self:compileStat(stat.body)

	self:closeLocals(oldLocals)
	self:popLocals(oldLocals)

	self:setDebugLine(stat)

	local contLabel = self.bytecode:emitLabel()

	local backLabel = self.bytecode:emitLabel()

	self.bytecode:emitAD(LuauOpcode.LOP_FORNLOOP, regs, 0)

	local endLabel = self.bytecode:emitLabel()

	self:patchJump(stat, forLabel, endLabel)
	self:patchJump(stat, backLabel, loopLabel)

	self:patchLoopJumps(stat, oldJumps, endLabel, contLabel)
	self.loopJumps:resize(oldJumps)

	self.loops:pop_back()

	rs:destroy()
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileStatForIn(self: Compiler, stat: AstStatForIn): ()
	local rs = RegScope.new(self)

	local oldLocals = self.localStack:size()
	local oldJumps = self.loopJumps:size()

	self.loops:push_back(Loop.new(oldLocals, oldLocals, nil))
	self.hasLoops = true

	-- register layout: generator, state, index, variables...
	local regs = self:allocReg(stat, 3)

	-- this puts initial values of (generator, state, index) into the loop registers
	self:compileExprListTemp(stat.values, regs, 3, true)

	-- note that we reserve at least 2 variables; this allows our fast path to assume that we need 2 variables instead of 1 or 2
	local vars = self:allocReg(stat, math.max(unsigned(#stat.vars), 2))
	assert(vars == regs + 3)
	local varsallocpc = if FastVariables.LuauCompileTypeInfo then self.bytecode:getDebugPC() else kDefaultAllocPc

	local skipOp = LuauOpcode.LOP_FORGPREP

	-- Optimization: when we iterate via pairs/ipairs, we generate special bytecode that optimizes the traversal using internal iteration index
	-- These instructions dynamically check if generator is equal to next/inext and bail out
	-- They assume that the generator produces 2 variables, which is why we allocate at least 2 above (see vars assignment)
	if self.options.optimizationLevel >= 1 and #stat.vars <= 2 then
		if #stat.values == 1 and stat.values[1]:is(AstExprCall) then
			local builtin = getBuiltin(assert(stat.values[1]:as(AstExprCall)).func, self.globals, self.variables)

			if builtin:isGlobal("ipairs") then -- for .. in ipairs(t)
				skipOp = LuauOpcode.LOP_FORGPREP_INEXT
			elseif builtin:isGlobal("pairs") then -- for .. in pairs(t)
				skipOp = LuauOpcode.LOP_FORGPREP_NEXT
			end
		elseif #stat.values == 2 then
			local builtin = getBuiltin(stat.values[1], self.globals, self.variables)

			if builtin:isGlobal("next") then -- for .. in next,t
				skipOp = LuauOpcode.LOP_FORGPREP_NEXT
			end
		end
	end

	-- first iteration jumps into FORGLOOP instruction, but for ipairs/pairs it does extra preparation that makes the cost of an extra instruction
	-- worthwhile
	local skipLabel = self.bytecode:emitLabel()

	self.bytecode:emitAD(skipOp, regs, 0)

	local loopLabel = self.bytecode:emitLabel()

	for i = 1, #stat.vars do
		self:pushLocal(stat.vars[i], uint8_t(vars + i - 1), varsallocpc)
	end

	self:compileStat(stat.body)

	self:closeLocals(oldLocals)
	self:popLocals(oldLocals)

	self:setDebugLine(stat)

	local contLabel = self.bytecode:emitLabel()

	local backLabel = self.bytecode:emitLabel()

	-- FORGLOOP uses aux to encode variable count and fast path flag for ipairs traversal in the high bit
	self.bytecode:emitAD(LuauOpcode.LOP_FORGLOOP, regs, 0)
	self.bytecode:emitAux(
		bit32.bor(
			if skipOp == LuauOpcode.LOP_FORGPREP_NEXT then 0x80000000 else 0,
			#stat.vars
		)
	)

	local endLabel = self.bytecode:emitLabel()

	self:patchJump(stat, skipLabel, backLabel)
	self:patchJump(stat, backLabel, loopLabel)

	self:patchLoopJumps(stat, oldJumps, endLabel, contLabel)
	self.loopJumps:resize(oldJumps)

	self.loops:pop_back()

	rs:destroy()
end

local function setBit(bits: {number}, offset: number, value: boolean): ()
    local numberIndex = math.ceil((offset + 1) / 32)
    bits[numberIndex] = bit32.replace(bits[numberIndex], btn(value), offset % 32, 1)
end

local function getBit(bits: {number}, offset: number): boolean
	local numberIndex = math.ceil((offset + 1) / 32)
	local bit = bit32.extract(bits[numberIndex], offset % 32, 1)
	return if bit == 1 then true else false
end

--[=[
	@within Compiler
	@private
	@since v0.1.0

	This function analyzes assignments and marks assignment conflicts: cases when a variable is assigned on lhs
	but subsequently used on the rhs, assuming assignments are performed in order. Note that it's also possible
	for a variable to conflict on the lhs, if it's used in an lvalue expression after it's assigned.
	When conflicts are found, Assignment::conflictReg is allocated and that's where assignment is performed instead,
	until the final fixup in compileStatAssign. Assignment::valueReg is allocated by compileStatAssign as well.

	Per Lua manual, section 3.3.3 (Assignments), the proper assignment order is only guaranteed to hold for syntactic access:

		Note that this guarantee covers only accesses syntactically inside the assignment statement. If a function or a metamethod called
		during the assignment changes the value of a variable, Lua gives no guarantees about the order of that access.

	As such, we currently don't check if an assigned local is captured, which may mean it gets reassigned during a function call.
]=]
function prototype.resolveAssignConflicts(self: Compiler, stat: AstStat, vars: Vector<Assignment>, values: {AstExpr}): ()
	local prototypeVisitor = setmetatable({}, AstVisitor.metatable)
	local metatableVisitor = {__index = prototypeVisitor}
	local Visitor = {}

	function Visitor.new(compiler: Compiler): Visitor
		local self = AstVisitor.new() :: Visitor
		self.compiler = compiler
		self.conflict = table.create(8, 0)
		self.assigned = table.create(8, 0)
		setmetatable(self, metatableVisitor)
		return self
	end

	function prototypeVisitor.visitAstExprLocal(self: Visitor, node: AstExprLocal): boolean
		local reg = self.compiler:getLocalReg(node.localAst)

		if reg >= 0 and getBit(self.assigned, reg) then
			setBit(self.conflict, reg, true)
		end

		return true
	end

	local visitor = Visitor.new(self)

	-- mark any registers that are used *after* assignment as conflicting

	-- first we go through assignments to locals, since they are performed before assignments to other l-values
	for i = 1, vars:size() do
		local li = vars:get(i).lvalue

		if li.kind == LValue.Kind.Kind_Local then
			if i <= #values then
				values[i]:visit(visitor)
			end

			setBit(visitor.assigned, li.reg, true)
		end
	end

	-- and now we handle all other l-values
	for i = 1, vars:size() do
		local li = vars:get(i).lvalue

		if li.kind ~= LValue.Kind.Kind_Local and i <= #values then
			values[i]:visit(visitor)
		end
	end

	-- mark any registers used in trailing expressions as conflicting as well
	for i = vars:size() + 1, #values do
		values[i]:visit(visitor)
	end

	-- mark any registers used on left hand side that are also assigned anywhere as conflicting
	-- this is order-independent because we evaluate all right hand side arguments into registers before doing table assignments
	for _, var in vars:data() do
		local li = var.lvalue

		if
			(li.kind == LValue.Kind.Kind_IndexName or li.kind == LValue.Kind.Kind_IndexNumber or li.kind == LValue.Kind.Kind_IndexExpr)
			and getBit(visitor.assigned, li.reg)
		then
			setBit(visitor.conflict, li.reg, true)
		end

		if li.kind == LValue.Kind.Kind_IndexExpr and getBit(visitor.assigned, li.index) then
			setBit(visitor.conflict, li.index, true)
		end
	end

	-- for any conflicting var, we need to allocate a temporary register where the assignment is performed, so that we can move the value later
	for _, var in vars:data() do
		local li = var.lvalue

		if li.kind == LValue.Kind.Kind_Local and getBit(visitor.conflict, li.reg) then
			var.conflictReg = self:allocReg(stat, 1)
		end
	end
end
type Visitor = AstVisitor & {
	compiler: Compiler,

	conflict: {number},
	assigned: {number}
}

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileStatAssign(self: Compiler, stat: AstStatAssign): ()
	local rs = RegScope.new(self)

	-- Optimization: one to one assignments don't require complex conflict resolution machinery
	if #stat.vars == 1 and #stat.values == 1 then
		local var = self:compileLValue(stat.vars[1], rs)

		-- Optimization: assign to locals directly
		if var.kind == LValue.Kind.Kind_Local then
			self:compileExpr(stat.values[1], var.reg)
		else
			local reg = self:compileExprAuto(stat.values[1], rs)

			self:setDebugLine(stat.vars[1])
			self:compileAssign(var, reg)
		end
		rs:destroy()
		return
	end

	-- compute all l-values: note that this doesn't assign anything yet but it allocates registers and computes complex expressions on the
	-- left hand side - for example, in "a[expr] = foo" expr will get evaluated here
	local vars: Vector<Assignment> = Vector.new()
	for _ = 1, #stat.vars do
		vars:push_back(Assignment.new())
	end
	
	for i = 1, #stat.vars do
		vars:get(i).lvalue = self:compileLValue(stat.vars[i], rs)
	end

	-- perform conflict resolution: if any expression refers to a local that is assigned before evaluating it, we assign to a temporary
	-- register after this, vars[i].conflictReg is set for locals that need to be assigned in the second pass
	self:resolveAssignConflicts(stat, vars, stat.values)

	-- compute rhs into (mostly) fresh registers
	-- note that when the lhs assigment is a local, we evaluate directly into that register
	-- this is possible because resolveAssignConflicts renamed conflicting locals into temporaries
	-- after this, vars[i].valueReg is set to a register with the value for *all* vars, but some have already been assigned
	for i = 1, math.min(#stat.vars, #stat.values) do
		local value = stat.values[i]

		if i == #stat.values and #stat.vars > #stat.values then
			-- allocate a consecutive range of regs for all remaining vars and compute everything into temps
			-- note, this also handles trailing nils
			local rest = uint8_t(#stat.vars - #stat.values + 1)
			local temp = self:allocReg(stat, rest)

			self:compileExprTempN(value, temp, rest, true)

			for j = i, #stat.vars do
				vars:get(j).valueReg = uint8_t(temp + (j - i))
			end
		else
			local var = vars:get(i)


			-- if target is a local, use compileExpr directly to target
			if var.lvalue.kind == LValue.Kind.Kind_Local then
				var.valueReg = if var.conflictReg == kInvalidReg then var.lvalue.reg else var.conflictReg

				self:compileExpr(stat.values[i], var.valueReg)
			else
				var.valueReg = self:compileExprAuto(stat.values[i], rs)
			end
		end
	end
	
	-- compute expressions with side effects
	for i = #stat.vars + 1, #stat.values do
		self:compileExprSide(stat.values[i])
	end

	-- almost done... let's assign everything left to right, noting that locals were either written-to directly, or will be written-to in a
	-- separate pass to avoid conflicts
	for _, var in vars:data() do
		assert(var.valueReg ~= kInvalidReg)

		if var.lvalue.kind ~= LValue.Kind.Kind_Local then
			self:setDebugLine(var.lvalue.location)
			self:compileAssign(var.lvalue, var.valueReg)
		end
	end

	-- all regular local writes are done by the prior loops by computing result directly into target, so this just handles conflicts OR
	-- local copies from temporary registers in multret context, since in that case we have to allocate consecutive temporaries
	for _, var in vars:data() do
		if var.lvalue.kind == LValue.Kind.Kind_Local and var.valueReg ~= var.lvalue.reg then
			self.bytecode:emitABC(LuauOpcode.LOP_MOVE, var.lvalue.reg, var.valueReg, 0)
		end
	end

	rs:destroy()
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileStatCompoundAssign(self: Compiler, stat: AstStatCompoundAssign): ()
	local rs = RegScope.new(self)

	local var = self:compileLValue(stat.var, rs)

	-- Optimization: assign to locals directly
	local target = if var.kind == LValue.Kind.Kind_Local then var.reg else self:allocReg(stat, 1)

	if
		stat.op == AstExprBinary.Op.Add
		or stat.op == AstExprBinary.Op.Sub
		or stat.op == AstExprBinary.Op.Mul
		or stat.op == AstExprBinary.Op.Div
		or stat.op == AstExprBinary.Op.FloorDiv
		or stat.op == AstExprBinary.Op.Mod
		or stat.op == AstExprBinary.Op.Pow
	then
		if var.kind ~= LValue.Kind.Kind_Local then
			self:compileLValueUse(var, target, false)
		end

		local rc = self:getConstantNumber(stat.value)

		if rc >= 0 and rc <= 255 then
			self.bytecode:emitABC(self:getBinaryOpArith(stat.op, true), target, target, uint8_t(rc))
		else
			local rr = self:compileExprAuto(stat.value, rs)

			self.bytecode:emitABC(self:getBinaryOpArith(stat.op), target, target, rr)

			if FastVariables.LuauCompileTempTypeInfo then
				if var.kind ~= LValue.Kind.Kind_Local then
					self:hintTemporaryRegType(stat.var, target, LuauBytecodeType.LBC_TYPE_NUMBER, 1)
				end

				self:hintTemporaryExprRegType(stat.value, rr, LuauBytecodeType.LBC_TYPE_NUMBER, 1)
			end
		end
	elseif stat.op == AstExprBinary.Op.Concat then
		local args: Vector<AstExpr> = Vector.new()
		args:push_back(stat.value)

		-- unroll the tree of concats down the right hand side to be able to do multiple ops
		Compiler.unrollConcats(args)

		local regs = self:allocReg(stat, unsigned(1 + args:size()))

		self:compileLValueUse(var, regs, false)

		for i = 1, args:size() do
			self:compileExprTemp(args:get(i), uint8_t(regs + 1 + i - 1))
		end

		self.bytecode:emitABC(LuauOpcode.LOP_CONCAT, target, regs, uint8_t(regs + args:size()))
	else
		error("Unexpected compound assignment operation")
	end

	if var.kind ~= LValue.Kind.Kind_Local then
		self:compileAssign(var, target)
	end

	rs:destroy()
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileStatFunction(self: Compiler, stat: AstStatFunction): ()
	-- Optimization: compile value expresion directly into target local register
	local reg = self:getExprLocalReg(stat.name)
	if reg >= 0 then
		self:compileExpr(stat.func, uint8_t(reg))
		return
	end

	local rs = RegScope.new(self)
	local reg = self:allocReg(stat, 1)

	self:compileExprTemp(stat.func, reg)

	local var = self:compileLValue(stat.name, rs)
	self:compileAssign(var, reg)

	rs:destroy()
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.compileStat(self: Compiler, node: AstNode): ()
	self:setDebugLine(node)

	if self.options.coverageLevel >= 1 and self:needsCoverage(node) then
		self.bytecode:emitABC(LuauOpcode.LOP_COVERAGE, 0, 0, 0)
	end

	local statBlock = node:as(AstStatBlock)
	local statIf = node:as(AstStatIf)
	local statWhile = node:as(AstStatWhile)
	local statRepeat = node:as(AstStatRepeat)
	local statBreak = node:as(AstStatBreak)
	local statContinue = node:as(AstStatContinue)
	local statReturn = node:as(AstStatReturn)
	local statExpr = node:as(AstStatExpr)
	local statLocal = node:as(AstStatLocal)
	local statFor = node:as(AstStatFor)
	local statForIn = node:as(AstStatForIn)
	local statAssign = node:as(AstStatAssign)
	local statCompoundAssign = node:as(AstStatCompoundAssign)
	local statFunction = node:as(AstStatFunction)
	local statLocalFunction = node:as(AstStatLocalFunction)
	local statTypeAlias = node:as(AstStatTypeAlias)

	if statBlock then
		local rs = RegScope.new(self)

		local oldLocals = self.localStack:size()

		for _, stat in statBlock.body do
			self:compileStat(stat :: AstStat)
		end

		self:closeLocals(oldLocals)

		self:popLocals(oldLocals)
		
		rs:destroy()
	elseif statIf then
		self:compileStatIf(statIf)
	elseif statWhile then
		self:compileStatWhile(statWhile)
	elseif statRepeat then
		self:compileStatRepeat(statRepeat)
	elseif statBreak then
		assert(not self.loops:empty())

		-- before exiting out of the loop, we need to close all local variables that were captured in closures since loop start
		-- normally they are closed by the enclosing blocks, including the loop block, but we're skipping that here
		self:closeLocals(self.loops:back().localOffset)

		local label = self.bytecode:emitLabel()

		self.bytecode:emitAD(LuauOpcode.LOP_JUMP, 0, 0)

		self.loopJumps:push_back(LoopJump.new(LoopJump.Type.Break, label))
	elseif statContinue then
		assert(not self.loops:empty())

		-- before continuing, we need to close all local variables that were captured in closures since loop start
		-- normally they are closed by the enclosing blocks, including the loop block, but we're skipping that here
		self:closeLocals(self.loops:back().localOffsetContinue)

		local label = self.bytecode:emitLabel()

		self.bytecode:emitAD(LuauOpcode.LOP_JUMP, 0, 0)

		self.loopJumps:push_back(LoopJump.new(LoopJump.Type.Continue, label))
	elseif statReturn then
		if self.options.optimizationLevel >= 2 and not self.inlineFrames:empty() then
			self:compileInlineReturn(statReturn, false)
		else
			self:compileStatReturn(statReturn)
		end
	elseif statExpr then
		-- Optimization: since we don't need to read anything from the stack, we can compile the call to not return anything which saves register
		-- moves
		local expr = statExpr.expr:as(AstExprCall)
		if expr then
			local target = uint8_t(self.regTop)

			self:compileExprCall(expr, target, 0)
		else
			self:compileExprSide(statExpr.expr)
		end
	elseif statLocal then
		self:compileStatLocal(statLocal)
	elseif statFor then
		self:compileStatFor(statFor)
	elseif statForIn then
		self:compileStatForIn(statForIn)
	elseif statAssign then
		self:compileStatAssign(statAssign)
	elseif statCompoundAssign then
		self:compileStatCompoundAssign(statCompoundAssign)
	elseif statFunction then
		self:compileStatFunction(statFunction)
	elseif statLocalFunction then
		local var = self:allocReg(statLocalFunction, 1)

		self:pushLocal(statLocalFunction.name, var, kDefaultAllocPc)
		self:compileExprFunction(statLocalFunction.func, var)

		local l = self.locals[statLocalFunction.name]

		-- we *have* to pushLocal before we compile the function, since the function may refer to the local as an upvalue
		-- however, this means the debugpc for the local is at an instruction where the local value hasn't been computed yet
		-- to fix this we just move the debugpc after the local value is established
		l.debugpc = self.bytecode:getDebugPC()
	elseif statTypeAlias then
		-- do nothing
	else
		error("Unknown statement type")
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.validateContinueUntil(self: Compiler, cont: AstStat, condition: AstExpr, body: AstStatBlock, start: number): ()
	local visitor = UndefinedLocalVisitor.new(self)

	for i = start, #body.body do
		local statLocal = body.body[i]:as(AstStatLocal)
		local statLocalFunction = body.body[i]:as(AstStatLocalFunction)
		if statLocal then
			for _, astLocal in statLocal.vars do
				table.insert(visitor.locals, astLocal)
			end
		elseif statLocalFunction then
			table.insert(visitor.locals, statLocalFunction.name)
		end
	end

	condition:visit(visitor)

	if visitor.undef ~= nil then
		CompileError.raise(
			condition.location,
			"Local %s used in the repeat..until condition is undefined because continue statement on line %d jumps over it",
			visitor.undef.name.value,
			cont.location.begin.line + 1
		)
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.gatherConstUpvals(self: Compiler, func: AstExprFunction): ()
	local visitor = ConstUpvalueVisitor.new(self)
	func.body:visit(visitor)

	for _, astLocal in visitor.upvals:data() do
		self:getUpval(astLocal :: AstLocal)
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.pushLocal(self: Compiler, astLocal: AstLocal, reg: number, allocpc: number): ()
	if self.localStack:size() >= kMaxLocalCount then
		CompileError.raise(
			astLocal.location,
			"Out of local registers when trying to allocate %s: exceeded limit %d",
			astLocal.name.value,
			kMaxLocalCount
		)
	end

	self.localStack:push_back(astLocal)

	local l = self.locals[astLocal]

	assert(not l.allocated)

	l.reg = reg
	l.allocated = true
	l.debugpc = self.bytecode:getDebugPC()

	if FastVariables.LuauCompileTypeInfo then
		l.allocpc = if allocpc == kDefaultAllocPc then l.debugpc else allocpc
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.areLocalsCaptured(self: Compiler, start: number): boolean
	assert(start <= self.localStack:size())
	start += 1

	for i = start, self.localStack:size() do
		local l = self.locals[self.localStack:get(i)]
		assert(l)

		if l.captured then
			return true
		end
	end

	return false
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.closeLocals(self: Compiler, start: number): ()
	assert(start <= self.localStack:size())
	start += 1 -- account for indices starting at 1 here, so the caller can still exactly copy the C++ code

	local captured = false
	local captureReg = 255

	for i = start, self.localStack:size() do
		local l = self.locals[self.localStack:get(i)]
		assert(l)

		if l.captured then
			captured = true
			captureReg = math.min(captureReg, l.reg)
		end
	end

	if captured then
		self.bytecode:emitABC(LuauOpcode.LOP_CLOSEUPVALS, captureReg, 0, 0)
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.popLocals(self: Compiler, start: number): ()
	assert(start <= self.localStack:size())
	start += 1 -- see `closeLocals`

	for i = start, self.localStack:size() do
		local l = self.locals[self.localStack:get(i)]
		assert(l)
		assert(l.allocated)

		if self.options.debugLevel >= 2 then
			local debugpc = self.bytecode:getDebugPC()

			self.bytecode:pushDebugLocal(sref(self.localStack:get(i).name), l.reg, l.debugpc, debugpc)
		end

		if FastVariables.LuauCompileTempTypeInfo and self.options.typeInfoLevel >= 1 and i > self.argCount then
			local debugpc = self.bytecode:getDebugPC()
			local ty = LuauBytecodeType.LBC_TYPE_ANY

			local recordedTy = self.localTypes[self.localStack:get(i)]
			if recordedTy then
				ty = recordedTy
			end

			self.bytecode:pushLocalTypeInfo(ty, l.reg, l.allocpc, debugpc)
		end
	end

	self.localStack:resize(start - 1, nil :: any)
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.patchJump(self: Compiler, node: AstNode, label: number, target: number): ()
	if not self.bytecode:patchJumpD(label, target) then
		CompileError.raise(node.location, "Exceeded jump distance limit; simplify the code to compile")
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.patchJumps(self: Compiler, node: AstNode, labels: Vector<number>, target: number): ()
	for _, l in labels:data() do
		self:patchJump(node, l, target)
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.patchLoopJumps(self: Compiler, node: AstNode, oldJumps: number, endLabel: number, contLabel: number): ()
	assert(oldJumps <= self.loopJumps:size())

	for i = oldJumps + 1, self.loopJumps:size() do
		local lj = self.loopJumps:get(i)
		
		if lj.type == LoopJump.Type.Break then
			self:patchJump(node, lj.label, endLabel)
		elseif lj.type == LoopJump.Type.Continue then
			self:patchJump(node, lj.label, contLabel)
		else
			error("Unknown loop jump type")
		end
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.allocReg(self: Compiler, node: AstNode, count: number): number
	local top = self.regTop
	if top + count > kMaxRegisterCount then
		CompileError.raise(node.location, "Out of registers when trying to allocate %d registers: exceeded limit %d", count, kMaxRegisterCount)
	end

	self.regTop += count
	self.stackSize = math.max(self.stackSize, self.regTop)

	return uint8_t(top)
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.setDebugLine(self: Compiler, a1: AstNode | Location): ()
	if self.options.debugLevel >= 1 then
		if (a1 :: any).location then
			local node: AstNode = a1 :: AstNode

			self.bytecode:setDebugLine(node.location.begin.line + 1)
		else
			local location: Location = a1 :: Location

			self.bytecode:setDebugLine(location.begin.line + 1)
		end
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.setDebugLineEnd(self: Compiler, node: AstNode): ()
	if self.options.debugLevel >= 1 then
		self.bytecode:setDebugLine(node.location.finish.line + 1)
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.needsCoverage(self: Compiler, node: AstNode): boolean
	return not node:is(AstStatBlock) and not node:is(AstStatTypeAlias)
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.hintTemporaryRegType(self: Compiler, expr: AstExpr, reg: number, expectedType: number, instLength: number): ()
	assert(FastVariables.LuauCompileTempTypeInfo)

	-- If we know the type of a temporary and it's not the type that would be expected by codegen, provide a hint
	local ty = self.exprTypes[expr]
	if ty then
		if ty ~= expectedType then
			self.bytecode:pushLocalTypeInfo(ty, reg, self.bytecode:getDebugPC() - instLength, self.bytecode:getDebugPC())
		end
	end
end

--[=[
	@within Compiler
	@private
	@since v0.1.0
]=]
function prototype.hintTemporaryExprRegType(self: Compiler, expr: AstExpr, reg: number, expectedType: number, instLength: number): ()
	assert(FastVariables.LuauCompileTempTypeInfo)

	-- If we allocated a temporary register for the operation argument, try hinting its type
	if not self:getExprLocal(expr) then
		self:hintTemporaryRegType(expr, reg, expectedType, instLength)
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

	local scope = LUAU_TIMETRACE_SCOPE("compileOrThrow", "Compiler")

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
			buildTypeMap(
				compiler.functionTypes,
				compiler.localTypes,
				compiler.exprTypes,
				root,
				options.vectorType,
				compiler.userdataTypes,
				compiler.builtinTypes,
				compiler.builtins,
				compiler.globals,
				bytecode
			)
		end
	else
		if functionVisitor.hasTypes then
			buildTypeMap(
				compiler.functionTypes,
				compiler.localTypes,
				compiler.exprTypes,
				root,
				options.vectorType,
				compiler.userdataTypes,
				compiler.builtinTypes,
				compiler.builtins,
				compiler.globals,
				bytecode
			)
		end
	end

	
	for _, expr in functions:data() do
		local protoflags = 0
		-- TC says compileFunction does not exist when using method call syntax here. What the Rizz?
		prototype.compileFunction(compiler, expr :: AstExprFunction, protoflags)

		-- If a function has native attribute and the whole module is not native, we set  LPF_NATIVE_FUNCTION flag
		-- This ensures that LPF_NATIVE_MODULE and LPF_NATIVE_FUNCTION are exclusive.
		if
			FastVariables.LuauNativeAttribute
			and bit32.band(protoflags, LuauProtoFlag.LPF_NATIVE_FUNCTION) ~= 0
			and bit32.band(mainFlags, LuauProtoFlag.LPF_NATIVE_MODULE) == 0
		then
			mainFlags = bit32.bor(mainFlags, LuauProtoFlag.LPF_NATIVE_FUNCTION)
		end
	end

	local main = AstExprFunction.new(root.location, {}, {}, {}, nil, {}, true, Location.new(), root, 0, AstName.new())
	local mainid = compiler:compileFunction(main, mainFlags)

	local mainf = compiler.functions[main]
	assert(mainf and mainf.upvals:empty())

	bytecode:setMainFunction(mainid)
	bytecode:finalize()

	if scope then
		scope:destroy()
	end
end :: (
	  ((bytecode: BytecodeBuilder, parseResult: ParseResult, names: AstNameTable, inputOptions: CompileOptions) -> ())
	& ((bytecode: BytecodeBuilder, source: string, options: CompileOptions?, parseOptions: ParseOptions?) -> ())
)

--[=[
	@within Compiler
	@since 0.1.0
]=]
function Compiler.compile(source: string, options: CompileOptions, parseOptions: ParseOptions, encoder: BytecodeEncoder): string
	local scope = LUAU_TIMETRACE_SCOPE("compile", "Compiler")

	local names = AstNameTable.new()
	local result = Parser.parse(source, #source, names, parseOptions)

	if not result.errors:empty() then
		-- Users of this function expect only a single error message
		local parseError = result.errors:front()
		local error = string.format(":%d: %s", parseError:getLocation().begin.line + 1, parseError:what())
		
		if scope then
			scope:destroy()
		end
		return BytecodeBuilder.getError(error)
	end

	local bcb = BytecodeBuilder.new(encoder)
	local success, e: CompileError = pcall(function()
		return Compiler.compileOrThrow(bcb, result, names, options) :: any
	end)

	if success then
		if scope then
			scope:destroy()
		end
		return bcb:getBytecode()
	else
		local error = string.format(":%d: %s", e:getLocation().begin.line + 1, e:what())
		if scope then
			scope:destroy()
		end
		return BytecodeBuilder.getError(error)
	end
end

return Compiler