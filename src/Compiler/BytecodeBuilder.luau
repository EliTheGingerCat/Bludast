local Bytecode = require("@Common/Bytecode/LuauBytecodeType")
local BytecodeEncoder = require("./BytecodeEncoder")
local FastVariables = require("@Ast/FastVariables")
local NumberUtilities = require("@Ast/NumberUtilities")
local Pair = require("@Ast/Pair")
local Vector = require("@Ast/Vector")

local btn = NumberUtilities.booleanToNumber
type BytecodeEncoder = BytecodeEncoder.BytecodeEncoder
type Pair<T1, T2> = Pair.Pair<T1, T2>
local unsigned = NumberUtilities.unsigned
type Vector<T> = Vector.Vector<T>

local function dictionarySize(tab: {}): number
	local count = 0
	for _ in tab do
		count += 1
	end
	return count
end

local kMaxConstantCount = bit32.lshift(1, 23)
local kMaxClosureCount = bit32.lshift(1, 15)

type StringRef = {
	data: string,
	length: number
}

local StringRef = {}

function StringRef.new(data: string, length: number): StringRef
	return {
		data = data,
		length = length
	}
end

local kMaxLength = 32

type TableShape = {
	keys: {number},
	length: number
}

local DumpFlags = {
	Dump_Code = bit32.lshift(1, 0),
	Dump_Lines = bit32.lshift(1, 1),
	Dump_Source = bit32.lshift(1, 2),
	Dump_Locals = bit32.lshift(1, 3),
	Dump_Remarks = bit32.lshift(1, 4),
	Dump_Types = bit32.lshift(1, 5)
}

local Constant = {
	Type = {
		Type_Nil = 1,
		Type_Boolean = 2,
		Type_Number = 3,
		Type_Vector = 4,
		Type_String = 5,
		Type_Import = 6,
		Type_Table = 7,
		Type_Closure = 8
	}
}

type Constant = {
	type: number,

	valueBoolean: boolean?,
	valueNumber: number?,
	valueVector: {number}?,
	valueString: number?, -- index into string table
	valueImport: number?, -- 10-10-10-2 encoded import id
	valueTable: number?,  -- index into tableShapes[]
	valueClosure: number? -- index of function in global list
}

function Constant.new(type: number): Constant
	return {
		type = type
	}
end

local ConstantKey = {}

type ConstantKey = {
	type: number,
	-- Note: this stores value* from Constant;
	value: number
}

function ConstantKey.new(type: number, value: number?): ConstantKey
	return {
		type = type,
		value = value or 0
	}
end

type Function = {
	data: string,

	maxstacksize: number,
	numparams: number,
	numupvalues: number,
	isvararg: boolean,
	
	debugname: number,
	debuglinedefined: number,

	dump: string,
	dumpname: string,
	dumpinstoffs: Vector<number>,
	typeinfo: string
}

local Function = {}

function Function.new(): Function
	return {
		data = "",
		maxstacksize = 0,
		numparams = 0,
		numupvalues = 0,
		isvararg = false,
		debugname = 0,
		debuglinedefined = 0,
		dump = "",
		dumpname = "",
		dumpinstoffs = Vector.new(),
		typeinfo = ""
	}
end

type DebugLocal = {
	name: number,

	reg: number,
	startpc: number,
	endpc: number
}

type DebugUpval = {
	name: number
}

type TypedLocal = {
	type: number,
	reg: number,
	startpc: number,
	endpc: number
}

type TypedUpval = {
	type: number
}

type UserdataType = {
	name: string,
	nameRef: number,
	used: boolean
}

type Jump = {
	source: number,
	target: number
}

type StringRefHash = (v: StringRef) -> number

type ConstantKeyHash = (key: ConstantKey) -> number

type TableShapeHash = (v: TableShape) -> number

export type BytecodeBuilder = {
	beginFunction: (numparams: number, isvararg: boolean?) -> number,
	endFunction: (maxstacksize: number, numupvalues: number, flags: number?) -> (),

	setMainFunction: (fid: number) -> (),

	addConstantNil: () -> number,
	addConstantBoolean: (value: boolean) -> number,
	addConstantNumber: (value: number) -> number,
	addConstantVector: (x: number, y: number, z: number, w: number) -> number,
	addConstantString: (value: StringRef) -> number,
	addImport: (iid: number) -> number,
	addConstantTable: (shape: TableShape) -> number,
	addConstantClosure: (fid: number) -> number,

	addChildFunction: (fid: number) -> number,

	emitABC: (op: number, a: number, b: number, c: number) -> (),
	emitAD: (op: number, a: number, d: number) -> (),
	emitE: (op: number, e: number) -> (),
	emitAux: (aux: number) -> (),

	emitLabel: () -> number,

	patchJumpD: (jumpLabel: number, targetLabel: number) -> boolean,
	patchSkipC: (jumpLabel: number, targetLabel: number) -> boolean,

	foldJumps: () -> (),
	expandJumps: () -> (),

	setFunctionTypeInfo: (value: string) -> (),
	pushLocalTypeInfo: (type: number, reg: number, startpc: number, endpc: number) -> (),
	pushUpvalTypeInfo: (type: number) -> (),

	addUserdataType: (name: string) -> number,
	useUserdataType: (index: number) -> (),

	setDebugFunctionName: (name: StringRef) -> (),
	setDebugFunctionLineDefined: (line: number) -> (),
	setDebugLine: (line: number) -> (),
	pushDebugLocal: (name: StringRef, reg: number, startpc: number, endpc: number) -> (),
	pushDebugUpval: (name: StringRef) -> (),

	getInstructionCount: () -> number,
	getTotalInstructionCount: () -> number,
	getDebugPC: () -> number,

	addDebugRemark: (format: string, ...any) -> (),
	
	finalize: () -> (),

	setDumpFlags: (flags: number) -> (),

	setDumpSource: (source: string) -> (),

	needsDebugRemarks: () -> boolean,

	getBytecode: () -> string,

	dumpFunction: (id: number) -> string,
	dumpEverything: () -> string,
	dumpSourceRemarks: () -> string,
	dumpTypeInfo: () -> string,

	annotateInstruction: (result: string, fid: number, instpos: number) -> (),

	functions: Vector<Function>,
	currentFunction: number,
	mainFunction: number,

	totalInstructionCount: number,
	insns: Vector<number>,
	lines: Vector<number>,
	constants: Vector<Constant>,
	protos: Vector<number>,
	jumps: Vector<Jump>,

	tableShapes: Vector<TableShape>,

	hasLongJumps: boolean,

	constantMap: {[ConstantKey]: number},
	tableShapeMap: {[TableShape]: number},
	protoMap: {[number]: number},

	debugLine: number,
	
	debugLocals: Vector<DebugLocal>,
	debugUpvals: Vector<DebugUpval>,

	typedLocals: Vector<TypedLocal>,
	typedUpvals: Vector<TypedUpval>,

	userdataTypes: Vector<UserdataType>,

	stringTable: {[StringRef]: number},
	debugStrings: Vector<StringRef>,

	debugRemarks: Vector<Pair<number, number>>,
	debugRemarkBuffer: string,

	encoder: BytecodeEncoder,
	bytecode: string,

	dumpFlags: number,
	dumpSource: Vector<string>,
	dumpRemarks: Vector<Pair<number, string>>,
	
	typeTypeInfo: string,

	dumpFunctionPtr: (Vector<number>) -> string,

	validate: (self: BytecodeBuilder) -> (),
	validateInstructions: () -> (),
	validateVariadic: () -> (),

	dumpCurrentFunction: (dumpinstoffs: Vector<number>) -> string,
	dumpConstant: (result: string, k: number) -> (),
	dumpInstruction: (opcode: number, output: string, targetLabel: number) -> (),

	writeFunction: (self: BytecodeBuilder, ss: string, id: number, flags: number) -> (),
	writeLineInfo: (self: BytecodeBuilder, ss: string) -> (),
	writeStringTable: (self: BytecodeBuilder, ss: string) -> (),

	addConstant: (self: BytecodeBuilder, key: ConstantKey, value: Constant) -> number,
	addStringTableEntry: (self: BytecodeBuilder, value: StringRef) -> number,

	tryGetUserdataTypeName: (self: BytecodeBuilder, type: number) -> string?
}

local prototype = {}

--[=[
	@class BytecodeBuilder
	@__index prototype

	Class from [`/Compiler/src/BytecodeBuilder.h`](https://github.com/luau-lang/luau/blob/7d4033071abebe09971b410d362c00ffb3084afb/Compiler/src/BytecodeBuilder.cpp#L209-L2651) and [`/Compiler/include/Luau/BytecodeBuilder.h`](https://github.com/luau-lang/luau/blob/7d4033071abebe09971b410d362c00ffb3084afb/Compiler/include/Luau/BytecodeBuilder.h#L21-L325).
]=]
local BytecodeBuilder = {
	prototype = prototype
}

local metatable = {
	__index = prototype
}

local function log2(v: number): ()
	assert(v)

	local r = 0
	
	while v >= bit32.lshift(2, r) do
		r += 1
	end

	return r
end

function BytecodeBuilder.new(encoder: BytecodeEncoder): BytecodeBuilder
	local self: BytecodeBuilder = setmetatable({
		constantMap = {},
		tableShapeMap = {},
		protoMap = {},
		stringTable = {},
		encoder = encoder,

		functions = Vector.new(),
		currentFunction = bit32.bnot(0),
		mainFunction = bit32.bnot(0),

		totalInstructionCount = 0,
		insns = Vector.new(),
		lines = Vector.new(),
		constants = Vector.new(),
		protos = Vector.new(),
		jumps = Vector.new(),

		tableShapes = Vector.new(),

		hasLongJumps = false,

		debugLine = 0,

		debugLocals = Vector.new(),
		debugUpvals = Vector.new(),

		typedLocals = Vector.new(),
		typedUpvals = Vector.new(),

		userdataTypes = Vector.new(),

		debugStrings = Vector.new(),

		debugRemarks = Vector.new(),
		debugRemarkBuffer = "",

		bytecode = "",

		dumpFlags = 0,
		dumpSource = Vector.new(),
		dumpRemarks = Vector.new(),

		typeTypeInfo = ""
	} :: BytecodeBuilder, metatable) :: any

	assert(self.stringTable[StringRef.new("", 0)] == nil)

	-- preallocate some buffers that are very likely to grow anyway; this works around std::vector's inefficient growth policy for small arrays
	self.insns:reserve(32)
	self.lines:reserve(32)
	self.constants:reserve(16)
	self.protos:reserve(16)
	self.functions:reserve(8)

	return self
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.beginFunction(self: BytecodeBuilder, numparams: number, isvararg: boolean): number
	assert(self.currentFunction == bit32.bor(0))

	local id = self.functions:size()

	local func = Function.new()
	func.numparams = numparams
	func.isvararg = isvararg

	self.functions:push_back(func)

	self.currentFunction = id

	self.hasLongJumps = false
	self.debugLine = 0

	return id
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.endFunction(self: BytecodeBuilder, maxstacksize: number, numupvalues: number, flags: number): ()
	assert(self.currentFunction ~= bit32.bnot(0))

	local func = self.functions[self.currentFunction]

	func.maxstacksize = maxstacksize
	func.numupvalues = numupvalues

	self:validate()

	-- this call is indirect to make sure we only gain link time dependency on dumpCurrentFunction when needed
	if self.dumpFunctionPtr then
		func.dump = (self.dumpFunctionPtr)(func.dumpinstoffs)
	end

	-- very approximate: 4 bytes per instruction for code, 1 byte for debug line, and 1-2 bytes for aux data like constants plus overhead
	func.data:reserve(32 + self.insns:size() * 7)

	if self.encoder then
		self.encoder:encode(self.insns[1], self.insns:size())
	end

	self:writeFunction(func.data, self.currentFunction, flags)

	self.currentFunction = bit32.bor(0)

	self.totalInstructionCount += self.insns:size()
	self.insns:clear()
	self.lines:clear()
	self.constants:clear()
	self.protos:clear()
	self.jumps:clear()
	self.tableShapes:clear()

	self.debugLocals:clear()
	self.debugUpvals:clear()

	if FastVariables.LuauCompileTypeInfo then
		self.typedLocals:clear()
		self.typedUpvals:clear()
	end

	table.clear(self.constantMap)
	table.clear(self.tableShapeMap)
	table.clear(self.protoMap)

	self.debugRemarks:clear()
	self.debugRemarkBuffer = ""
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.setMainFunction(self: BytecodeBuilder, fid: number): ()
	assert(fid < self.functions:size())

	self.mainFunction = fid
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.addConstant(self: BytecodeBuilder, key: ConstantKey, value: Constant): number
	local cache = self.constantMap[key]
	if cache then
		return cache
	end

	local id = self.constants:size()

	if id >= kMaxConstantCount then
		return -1
	end

	self.constantMap[key] = id
	self.constants:push_back(value)

	return id
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.addStringTableEntry(self: BytecodeBuilder, value: StringRef): number
	local index = self.stringTable[value]

	-- note: bytecode serialization format uses 1-based table indices, 0 is reserved to mean nil
	if index == 0 then
		index = dictionarySize(self.stringTable)

		if bit32.band(self.dumpFlags, DumpFlags.Dump_Code) ~= 0 then
			self.debugStrings:push_back(value)
		end
	end
	
	return index
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.tryGetUserdataTypeName(self: BytecodeBuilder, type: number): string?
	assert(FastVariables.LuauCompileUserdataInfo)

	local index = unsigned(bit32.band(type, bit32.bnot(Bytecode.LBC_TYPE_OPTIONAL_BIT) - Bytecode.LBC_TYPE_TAGGED_USERDATA_BASE))

	if index < self.userdataTypes:size() then
		return self.userdataTypes[index].name
	end

	return nil
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.addConstantNil(self: BytecodeBuilder): number
	local c = Constant.new(Constant.Type.Type_Nil)

	local k = ConstantKey.new(Constant.Type.Type_Nil)
	return self:addConstant(k, c)
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.addConstantBoolean(self: BytecodeBuilder, value: boolean): number
	local c = Constant.new(Constant.Type.Type_Boolean)

	local k = ConstantKey.new(Constant.Type.Type_Boolean, btn(value))
	return self:addConstant(k, c)
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.addConstantNumber(self: BytecodeBuilder, value: number): number
	local c = Constant.new(Constant.Type.Type_Number)
	c.valueNumber = value

	local k = ConstantKey.new(Constant.Type.Type_Number)
	k.value = value

	return self:addConstant(k, c)
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.addImport(self: BytecodeBuilder, iid: number): number
	local c = Constant.new(Constant.Type.Type_Import)
	c.valueImport = iid

	local k = ConstantKey.new(Constant.Type.Type_Import, iid)

	return self:addConstant(k, c)
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.addConstantTable(self: BytecodeBuilder, shape: TableShape): number
	local cache = self.tableShapeMap[shape]
	if cache then
		return cache
	end

	local id = self.constants:size()

	if id >= kMaxConstantCount then
		return -1
	end

	local value = Constant.new(Constant.Type.Type_Table)
	value.valueTable = self.tableShapes:size()

	self.tableShapeMap[shape] = id
	self.tableShapes:push_back(shape)
	self.constants:push_back(value)

	return id
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.addConstantClosure(self: BytecodeBuilder, fid: number): number
	local c = Constant.new(Constant.Type.Type_Closure)
	c.valueClosure = fid

	local k = ConstantKey.new(Constant.Type.Type_Closure, fid)

	return self:addConstant(k, c)
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.addChildFunction(self: BytecodeBuilder, fid: number): number
	local cache = self.protoMap[fid]
	if cache then
		return cache
	end

	local id = self.protos:size()

	if id >= kMaxClosureCount then
		return -1
	end

	self.protoMap[fid] = id
	self.protos:push_back(fid)

	return id
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.emitABC(self: BytecodeBuilder, op: number, a: number, b: number, c: number): ()
	local insn = bit32.bor(
		op,
		bit32.lshift(a, 8),
		bit32.lshift(b, 16),
		bit32.lshift(c, 24)
	)

	self.insns:push_back(insn)
	self.lines:push_back(self.debugLine)
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.emitAD(self: BytecodeBuilder, op: number, a: number, d: number): ()
	local insn = bit32.bor(
		op,
		bit32.lshift(a, 8),
		bit32.lshift(d, 16)
	)

	self.insns:push_back(insn)
	self.lines:push_back(self.debugLine)
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.emitE(self: BytecodeBuilder, op: number, e: number): ()
	local insn = bit32.bor(
		op,
		bit32.lshift(e, 8)
	)

	self.insns:push_back(insn)
	self.lines:push_back(self.debugLine)
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.emitAux(self: BytecodeBuilder, aux: number): ()
	self.insns:push_back(aux)
	self.lines:push_back(self.debugLine)
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.emitLabel(self: BytecodeBuilder): ()
	return self.insns:size()
end

function prototype.patchJumpD(self: BytecodeBuilder, jumpLabel: number, targetLable: number): boolean
	assert(jumpLabel < self.insns:size())

	local jumpInsn = self.insns[jumpLabel]

	-- Eli: TODO
end

return BytecodeBuilder