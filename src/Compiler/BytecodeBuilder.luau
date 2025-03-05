--!nolint LocalShadow

local Buffer = require("./Buffer")
local BytecodeEncoder = require("./BytecodeEncoder")
local BytecodeUtilities = require("@Common/Bytecode/BytecodeUtilities")
local DebugFlags = require("@Shared/DebugFlags")
local FastVariables = require("@Shared/FastVariables")
local LUAU_ASSERT = require("@Shared/LUAU_ASSERT")
local LuauBytecodeTag = require("@Common/Bytecode/LuauBytecodeTag")
local LuauBytecodeType = require("@Common/Bytecode/LuauBytecodeType")
local LuauCaptureType = require("@Common/Bytecode/LuauCaptureType")
local LuauOpcode = require("@Common/Bytecode/LuauOpcode")
local NumberConversions = require("@Polyfill/NumberConversions")
local Pair = require("@Polyfill/Pair")
local Vector = require("@Polyfill/Vector")

local btn = NumberConversions.booleanToNumber
type Buffer = Buffer.Buffer
type BytecodeEncoder = BytecodeEncoder.BytecodeEncoder
local getOpLength = BytecodeUtilities.getOpLength
local int = NumberConversions.int
local int16_t = NumberConversions.int16_t
local LUAU_INSN_A = BytecodeUtilities.LUAU_INSN_A
local LUAU_INSN_B = BytecodeUtilities.LUAU_INSN_B
local LUAU_INSN_C = BytecodeUtilities.LUAU_INSN_C
local LUAU_INSN_D = BytecodeUtilities.LUAU_INSN_D
local LUAU_INSN_E = BytecodeUtilities.LUAU_INSN_E
local LUAU_INSN_OP = BytecodeUtilities.LUAU_INSN_OP
type Pair<T1, T2> = Pair.Pair<T1, T2>
local uint8_t = NumberConversions.uint8_t
local uint16_t = NumberConversions.uint16_t
local uint32_t = NumberConversions.uint32_t
local unsigned = NumberConversions.unsigned
type Vector<T> = Vector.Vector<T>

local function dictionarySize(tab: {}): number
	local count = 0
	for _ in tab do
		count += 1
	end
	return count
end

--[=[
	@type stringWrap {s: string}
	@within BytecodeBuilder
	
	Used for passing strings by reference.
]=]
type stringWrap = {
	s: string
}

local kMaxConstantCount = bit32.lshift(1, 23)
local kMaxClosureCount = bit32.lshift(1, 15)

local kMaxJumpDistance = bit32.lshift(1, 23)

local StringRef = {}

export type StringRef = {
	data: string,
	length: number
}

function StringRef.new(data: string, length: number): StringRef
	return {
		data = data,
		length = length
	}
end

local function hashStringRef(v: StringRef): number
	local data = v.data
	local size = v.length

	-- FNV-1a
	local hash = 2166136261

	for i = 1, size do
		hash = bit32.bxor(hash, uint8_t(string.byte(data, i)))
		hash *= 16777619
	end

	return hash
end

--[=[
	@class BytecodeBuilder_TableShape
]=]
local TableShape = {
	kMaxLength = 32
}

type TableShape = {
	keys: {number},
	length: number
}

function TableShape.new(): TableShape
	return {
		keys = table.create(TableShape.kMaxLength),
		length = 0
	}
end

local function hashTableShape(v: TableShape): number
	-- FNV-1a inspired hash (note that we feed integers instead of bytes)
	local hash = 2166136261

	for i = 1, v.length do
		hash = bit32.bxor(hash, v.keys[i])
		hash *= 16777619
	end

	return hash
end

--[=[
	@class DumpFlags
]=]
local DumpFlags = {
	Dump_Code = bit32.lshift(1, 0),
	Dump_Lines = bit32.lshift(1, 1),
	Dump_Source = bit32.lshift(1, 2),
	Dump_Locals = bit32.lshift(1, 3),
	Dump_Remarks = bit32.lshift(1, 4),
	Dump_Types = bit32.lshift(1, 5)
}

--[=[
	@class Constant
]=]
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

	-- union, if one is filled then the rest are nil
	valueBoolean: boolean,
	valueNumber: number,
	valueVector: {number},
	valueString: number, -- index into string table
	valueImport: number, -- 10-10-10-2 encoded import id
	valueTable: number,  -- index into tableShapes[]
	valueClosure: number -- index of function in global list
}

function Constant.new(type: number): Constant
	return {
		type = type
	} :: any
end

--[=[
	@class ConstantKey
]=]
local ConstantKey = {}

type ConstantKey = {
	type: number,
	-- Note: this stores value* from Constant;
	value1: number,
	value2: number,
	value3: number,
	value4: number
}

function ConstantKey.new(type: number, value: number?): ConstantKey
	return {
		type = type,
		value1 = value or 0,
		value2 = 0,
		value3 = 0,
		value4 = 0,
		extra = 0
	}
end

local function hashKey(key: ConstantKey)
	if key.type == Constant.Type.Type_Vector then
		local i = table.create(4)
		i[1], i[2], i[3], i[4] = key.value1, key.value2, key.value3, key.value4

		-- scramble bits to make sure that integer coordinates have entropy in lower bits
		i[1] = bit32.bxor(i[1], bit32.rshift(i[1], 17))
		i[2] = bit32.bxor(i[2], bit32.rshift(i[2], 17))
		i[3] = bit32.bxor(i[3], bit32.rshift(i[3], 17))
		i[4] = bit32.bxor(i[1], bit32.rshift(i[4], 17))

		-- Optimized Spatial Hashing for Collision Detection of Deformable Objects
		local h = bit32.bxor(
			i[1] * 73856093,
			i[2] * 19349663,
			i[3] * 83492791,
			i[4] * 39916801
		)

		return h
	else
		-- finalizer from MurmurHash64B
		local m = 0x5bd1e995

		local h1 = uint32_t(key.value1)
		local h2 = bit32.bxor(uint32_t(bit32.rshift(key.value1, 32)), key.type * m)

		h1 = bit32.bxor(h1, bit32.rshift(h2, 18))
		h1 *= m
		h2 = bit32.bxor(h2, bit32.rshift(h1, 22))
		h2 *= m
		h1 = bit32.bxor(h1, bit32.rshift(h2, 17))
		h1 *= m
		h2 = bit32.bxor(h2, bit32.rshift(h1, 19))
		h2 *= m

		-- ... truncated to 32-bit output (normally hash is equal to (uint64_t(h1) << 32) | h2, but we only really need the lower 32-bit half)
		return h2
	end
end

--[=[
	@class Bytecode_Function
]=]
local Bytecode_Function = {}

type Bytecode_Function = {
	data: Buffer,

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

--[=[
	@within Bytecode_Function
	@since v0.1.0
]=]
function Bytecode_Function.new(): Bytecode_Function
	return {
		data = Buffer.new(),
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

--[=[
	@class DebugLocal
]=]
local DebugLocal = {}

type DebugLocal = {
	name: number,

	reg: number,
	startpc: number,
	endpc: number
}

--[=[
	@within DebugLocal
	@since v0.1.0
]=]
function DebugLocal.new(): DebugLocal
	return {
		name = 0,
		
		reg = 0,
		startpc = 0,
		endpc = 0
	}
end

--[=[
	@class DebugUpval
]=]
local DebugUpval = {}

--[=[
	@within DebugUpval
	@prop name number
	@since v0.1.0
]=]
type DebugUpval = {
	name: number
}

--[=[
	@within DebugUpval
	@since v0.1.0
]=]
function DebugUpval.new(): DebugUpval
	return {
		name = 0
	}
end

--[=[
	@class TypedLocal
]=]
local TypedLocal = {}

--[=[
	@within TypedLocal
	@prop type LuauBytecodeType
	@since v0.1.0
]=]
local _

type TypedLocal = {
	type: number,
	reg: number,
	startpc: number,
	endpc: number
}

--[=[
	@within TypedLocal
	@since v0.1.0
]=]
function TypedLocal.new(): TypedLocal
	return {
		type = 0,
		reg = 0,
		startpc = 0,
		endpc = 0
	}
end

--[=[
	@class TypedUpval
]=]
local TypedUpval = {}

--[=[
	@within TypedLocal
	@prop type LuauBytecodeType
	@since v0.1.0
]=]
local _

type TypedUpval = {
	type: number
}

--[=[
	@within TypedLocal
	@since v0.1.0
]=]
function TypedUpval.new(): TypedUpval
	return {
		type = 0
	}
end

local UserdataType = {}

type UserdataType = {
	name: string,
	nameRef: number,
	used: boolean
}

function UserdataType.new(): UserdataType
	return {
		name = "",
		nameRef = 0,
		used = false
	}
end

--[=[
	@class Jump
]=]
local Jump = {}

type Jump = {
	source: number,
	target: number
}

--[=[
	@within Jump
	@since v0.1.0
]=]
function Jump.new(source: number, target: number): Jump
	return {
		source = source,
		target = target
	}
end

type StringRefHash = (v: StringRef) -> number

type ConstantKeyHash = (key: ConstantKey) -> number

type TableShapeHash = (v: TableShape) -> number

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

export type BytecodeBuilder = typeof(setmetatable({} :: {
	needsDebugRemarks: (self: BytecodeBuilder) -> boolean,

	functions: Vector<Bytecode_Function>,
	currentFunction: number,
	mainFunction: number,

	totalInstructionCount: number,
	insns: Vector<number>,
	lines: Vector<number>,
	constants: Vector<Constant>,
	protos: Vector<number>,
	jumps: {Jump},

	tableShapes: Vector<TableShape>,

	hasLongJumps: boolean,

	constantMap: {[number]: number},
	tableShapeMap: {[number]: number},
	protoMap: {[number]: number},

	debugLine: number,
	
	debugLocals: Vector<DebugLocal>,
	debugUpvals: Vector<DebugUpval>,

	typedLocals: Vector<TypedLocal>,
	typedUpvals: Vector<TypedUpval>,

	userdataTypes: Vector<UserdataType>,

	stringTable: {[number]: {index: number, stringRef: StringRef}},
	debugStrings: Vector<StringRef>,

	debugRemarks: Vector<Pair<number, number>>,
	debugRemarkBuffer: string,

	encoder: BytecodeEncoder?,
	bytecode: Buffer,

	dumpFlags: number,
	dumpSource: Vector<string>,
	dumpRemarks: Vector<Pair<number, string>>,
	
	tempTypeInfo: Buffer,

	dumpFunctionPtr: (Vector<number>) -> string,
}, metatable))

local function log2(v: number): number
	LUAU_ASSERT(v)

	local r = 0
	
	while v >= bit32.lshift(2, r) do
		r += 1
	end

	return r
end

--[=[
	@within BytecodeBuilder
	@param op LuauOpcode
	@private
	@since v0.1.0
	@tag local
]=]
local function isJumpD(op: number): boolean
	if op == LuauOpcode.LOP_JUMP
	or op == LuauOpcode.LOP_JUMPIF
	or op == LuauOpcode.LOP_JUMPIFNOT
	or op == LuauOpcode.LOP_JUMPIFEQ
	or op == LuauOpcode.LOP_JUMPIFLE
	or op == LuauOpcode.LOP_JUMPIFLT
	or op == LuauOpcode.LOP_JUMPIFNOTEQ
	or op == LuauOpcode.LOP_JUMPIFNOTLE
	or op == LuauOpcode.LOP_JUMPIFNOTLT
	or op == LuauOpcode.LOP_FORNPREP
	or op == LuauOpcode.LOP_FORNLOOP
	or op == LuauOpcode.LOP_FORGPREP
	or op == LuauOpcode.LOP_FORGLOOP
	or op == LuauOpcode.LOP_FORGPREP_INEXT
	or op == LuauOpcode.LOP_FORGPREP_NEXT
	or op == LuauOpcode.LOP_JUMPBACK
	or op == LuauOpcode.LOP_JUMPXEQKNIL
	or op == LuauOpcode.LOP_JUMPXEQKB
	or op == LuauOpcode.LOP_JUMPXEQKN
	or op == LuauOpcode.LOP_JUMPXEQKS then
		return true
	else
		return false
	end
end

--[=[
	@within BytecodeBuilder
	@param op LuauOpcode
	@private
	@since v0.1.0
	@tag local
]=]
local function isSkipC(op: number): boolean
	if op == LuauOpcode.LOP_LOADB then
		return true
	else
		return false
	end
end

--[=[
	@within BytecodeBuilder
	@param op LuauOpcode
	@private
	@since v0.1.0
	@tag local
]=]
local function isFastCall(op: number): boolean
	if op == LuauOpcode.LOP_FASTCALL
	or op == LuauOpcode.LOP_FASTCALL1
	or op == LuauOpcode.LOP_FASTCALL2
	or op == LuauOpcode.LOP_FASTCALL2K then
		return true
	else
		return false
	end
end

--[=[
	@within BytecodeBuilder
	@private
	@since v0.1.0
	@tag local
]=]
local function getJumpTarget(insn: number, pc: number): number
	local op = LUAU_INSN_OP(insn)

	if isJumpD(op) then
		return int(pc + LUAU_INSN_D(insn) + 1)
	elseif isFastCall(op) then
		return int(pc + LUAU_INSN_C(insn) + 2)
	elseif isSkipC(op) and LUAU_INSN_C(insn) ~= 0 then
		return int(pc + LUAU_INSN_C(insn) + 1)
	elseif op == LuauOpcode.LOP_JUMPX then
		return int(pc + LUAU_INSN_E(insn) + 1)
	else
		return -1
	end
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function BytecodeBuilder.new(encoder: BytecodeEncoder?): BytecodeBuilder
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
		jumps = {},

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

		bytecode = buffer.create(100),

		dumpFlags = 0,
		dumpSource = Vector.new(),
		dumpRemarks = Vector.new(),

		tempTypeInfo = Buffer.new()
	}, metatable) :: any

	self.dumpFunctionPtr = function(...)
		return self:dumpCurrentFunction(...)
	end

	LUAU_ASSERT(self.stringTable[hashStringRef(StringRef.new("", 0))] == nil)

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
	LUAU_ASSERT(self.currentFunction == bit32.bnot(0))

	local id = self.functions:size()

	local func = Bytecode_Function.new()
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
	LUAU_ASSERT(self.currentFunction ~= bit32.bnot(0))

	local func = self.functions:get(self.currentFunction + 1)

	func.maxstacksize = maxstacksize
	func.numupvalues = numupvalues

	if DebugFlags.AssertEnabled then
		self:validate()
	end

	-- this call is indirect to make sure we only gain link time dependency on dumpCurrentFunction when needed
	if self.dumpFunctionPtr then
		func.dump = self.dumpFunctionPtr(func.dumpinstoffs)
	end

	-- very approximate: 4 bytes per instruction for code, 1 byte for debug line, and 1-2 bytes for aux data like constants plus overhead
	-- func.data:reserve(32 + self.insns:size() * 7)

	if self.encoder then
		self.encoder:encode(self.insns[1], self.insns:size())
	end

	self:writeFunction(func.data, self.currentFunction, flags)

	self.currentFunction = bit32.bnot(0)

	self.totalInstructionCount += self.insns:size()
	self.insns:clear()
	self.lines:clear()
	self.constants:clear()
	self.protos:clear()
	table.clear(self.jumps)
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
	LUAU_ASSERT(fid < self.functions:size())

	self.mainFunction = fid
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.addConstant(self: BytecodeBuilder, key: ConstantKey, value: Constant): number
	local cache = self.constantMap[hashKey(key)]
	if cache then
		return cache
	end

	local id = self.constants:size()

	if id >= kMaxConstantCount then
		return -1
	end

	self.constantMap[hashKey(key)] = id
	self.constants:push_back(value)

	return id
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.addStringTableEntry(self: BytecodeBuilder, value: StringRef): number
	local hashed = hashStringRef(value)
	local entry = self.stringTable[hashed]
	local index = if entry then entry.index else 0

	-- note: bytecode serialization format uses 1-based table indices, 0 is reserved to mean nil
	if index == 0 then
		self.stringTable[hashed] = {index = uint32_t(dictionarySize(self.stringTable) + 1), stringRef = value}
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
	LUAU_ASSERT(FastVariables.LuauCompileUserdataInfo)

	local index = unsigned(bit32.band(type, bit32.bnot(LuauBytecodeType.LBC_TYPE_OPTIONAL_BIT) - LuauBytecodeType.LBC_TYPE_TAGGED_USERDATA_BASE))

	if index < self.userdataTypes:size() then
		return self.userdataTypes:get(index + 1).name
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
	k.value1 = value

	return self:addConstant(k, c)
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.addConstantVector(self: BytecodeBuilder, x: number, y: number, z: number, w: number): number
	local c = Constant.new(Constant.Type.Type_Vector)
	c.valueVector[1] = x
	c.valueVector[2] = y
	c.valueVector[3] = z
	c.valueVector[4] = w

	local k = ConstantKey.new(Constant.Type.Type_Vector)
	k.value1 = x
	k.value2 = y
	k.value3 = z
	k.value4 = w

	return self:addConstant(k, c)
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.addConstantString(self: BytecodeBuilder, value: StringRef): number
	local index = self:addStringTableEntry(value)

	local c = Constant.new(Constant.Type.Type_String)
	c.valueString = index

	local k = ConstantKey.new(Constant.Type.Type_String, index)

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
	local cache = self.tableShapeMap[hashTableShape(shape)]
	if cache then
		return cache
	end

	local id = self.constants:size()

	if id >= kMaxConstantCount then
		return -1
	end

	local value = Constant.new(Constant.Type.Type_Table)
	value.valueTable = self.tableShapes:size()

	self.tableShapeMap[hashTableShape(shape)] = id
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
	local cache = self.protoMap[fid + 1]
	if cache then
		return cache
	end

	local id = self.protos:size()

	if id >= kMaxClosureCount then
		return -1
	end

	self.protoMap[fid + 1] = id
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
		uint32_t(op),
		bit32.lshift(a, 8),
		bit32.lshift(uint16_t(d), 16)
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
function prototype.emitLabel(self: BytecodeBuilder): number
	return self.insns:size()
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.patchJumpD(self: BytecodeBuilder, jumpLabel: number, targetLabel: number): boolean
	LUAU_ASSERT(jumpLabel < self.insns:size())

	local jumpInsn = self.insns:get(jumpLabel + 1)

	LUAU_ASSERT(isJumpD(LUAU_INSN_OP(jumpInsn)))
	LUAU_ASSERT(LUAU_INSN_D(jumpInsn) == 0)

	LUAU_ASSERT(targetLabel <= self.insns:size())

	local offset = int(targetLabel) - int(jumpLabel) - 1

	if int16_t(offset) == offset then
		self.insns:set(jumpLabel + 1, bit32.bor(self.insns:get(jumpLabel + 1), bit32.lshift(uint16_t(offset), 16)))
	elseif math.abs(offset) < kMaxJumpDistance then
		-- our jump doesn't fit into 16 bits; we will need to repatch the bytecode sequence with jump trampolines, see expandJumps
		self.hasLongJumps = true
	else
		return false
	end

	table.insert(self.jumps, Jump.new(uint32_t(jumpLabel), uint32_t(targetLabel)))
	return true
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.patchSkipC(self: BytecodeBuilder, jumpLabel: number, targetLabel: number): boolean
	LUAU_ASSERT(jumpLabel < self.insns:size())

	local jumpInsn = self.insns:get(jumpLabel + 1)

	LUAU_ASSERT(isSkipC(LUAU_INSN_OP(jumpInsn)) or isFastCall(LUAU_INSN_OP(jumpInsn)))
	LUAU_ASSERT(LUAU_INSN_C(jumpInsn) == 0)

	local offset = targetLabel - jumpLabel - 1

	if uint8_t(offset) ~= offset then
		return false
	end

	self.insns:set(jumpLabel + 1, bit32.bor(self.insns:get(jumpLabel + 1), bit32.lshift(offset, 24)))
	return true
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.setFunctionTypeInfo(self: BytecodeBuilder, value: string): ()
	self.functions:get(self.currentFunction + 1).typeinfo = value
end

--[=[
	@within BytecodeBuilder
	@param type LuauBytecodeType
	@since v0.1.0
]=]
function prototype.pushLocalTypeInfo(self: BytecodeBuilder, type: number, reg: number, startpc: number, endpc: number): ()
	LUAU_ASSERT(FastVariables.LuauCompileTypeInfo)

	local typedLocal = TypedLocal.new()
	typedLocal.type = type
	typedLocal.reg = reg
	typedLocal.startpc = startpc
	typedLocal.endpc = endpc

	self.typedLocals:push_back(typedLocal)
end

--[=[
	@within BytecodeBuilder
	@param type LuauBytecodeType
	@since v0.1.0
]=]
function prototype.pushUpvalTypeInfo(self: BytecodeBuilder, type: number): ()
	LUAU_ASSERT(FastVariables.LuauCompileTypeInfo)

	local upval = TypedUpval.new()
	upval.type = type

	self.typedUpvals:push_back(upval)
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.addUserdataType(self: BytecodeBuilder, name: string): number
	LUAU_ASSERT(FastVariables.LuauCompileUserdataInfo)

	local ty = UserdataType.new()

	ty.name = name

	self.userdataTypes:push_back(ty)
	return uint32_t(self.userdataTypes:size() - 1)
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.useUserdataType(self: BytecodeBuilder, index: number): ()
	LUAU_ASSERT(FastVariables.LuauCompileUserdataInfo)

	self.userdataTypes:get(index + 1).used = true
end

function prototype.setDebugFunctionName(self: BytecodeBuilder, name: StringRef): ()
	local index = self:addStringTableEntry(name)

	self.functions:get(self.currentFunction + 1).debugname = index

	if self.dumpFunctionPtr then
		self.functions:get(self.currentFunction + 1).dumpname = name.data
	end
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.setDebugFunctionLineDefined(self: BytecodeBuilder, line: number): ()
	self.functions:get(self.currentFunction + 1).debuglinedefined = line
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.setDebugLine(self: BytecodeBuilder, line: number): ()
	self.debugLine = line
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.pushDebugLocal(self: BytecodeBuilder, name: StringRef, reg: number, startpc: number, endpc: number): ()
	local index = self:addStringTableEntry(name)

	local debugLocal = DebugLocal.new()
	debugLocal.name = index
	debugLocal.reg = reg
	debugLocal.startpc = startpc
	debugLocal.endpc = endpc

	self.debugLocals:push_back(debugLocal)
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.pushDebugUpval(self: BytecodeBuilder, name: StringRef): ()
	local index = self:addStringTableEntry(name)

	local upval = DebugUpval.new()
	upval.name = index

	self.debugUpvals:push_back(upval)
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.getInstructionCount(self: BytecodeBuilder): number
	return self.insns:size()
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.getTotalInstructionCount(self: BytecodeBuilder): number
	return self.totalInstructionCount
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.getDebugPC(self: BytecodeBuilder): number
	return uint32_t(self.insns:size())
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.addDebugRemark(self: BytecodeBuilder, remark: string): ()
	if bit32.band(self.dumpFlags, DumpFlags.Dump_Remarks) == 0 then
		return
	end

	local offset = #self.debugRemarkBuffer + 1

	self.debugRemarkBuffer ..= remark

	-- we null-terminate all remarks to avoid storing remark length
	self.debugRemarkBuffer ..= "\0"

	self.debugRemarks:push_back(Pair.new(uint32_t(self.insns:size()), uint32_t(offset)))
	self.dumpRemarks:push_back(Pair.new(self.debugLine, self.debugRemarkBuffer:sub(offset)))
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.finalize(self: BytecodeBuilder): ()
	if FastVariables.LuauCompileUserdataInfo then
		for _, ty in self.userdataTypes:data() do
			if ty.used then
				ty.nameRef = self:addStringTableEntry(StringRef.new(ty.name, #ty.name))
			end
		end
	end

	-- preallocate space for bytecode blob
	local capacity = 16

	for _, p in self.stringTable do
		capacity += p.stringRef.length + 2
	end

	for _, func in self.functions:data() do
		capacity += func.data.pos
	end
	
	-- assemble final bytecode blob
	local version = BytecodeBuilder.getVersion()
	LUAU_ASSERT(version >= LuauBytecodeTag.LBC_VERSION_MIN and version <= LuauBytecodeTag.LBC_VERSION_MAX)

	self.bytecode = Buffer.new()
	self.bytecode:writeByte(version)

	local typesversion = BytecodeBuilder.getTypeEncodingVersion()
	LUAU_ASSERT(typesversion >= LuauBytecodeTag.LBC_TYPE_VERSION_MIN and typesversion <= LuauBytecodeTag.LBC_TYPE_VERSION_MAX)
	self.bytecode:writeByte(typesversion)

	self:writeStringTable(self.bytecode)

	if FastVariables.LuauCompileTypeInfo and FastVariables.LuauCompileUserdataInfo then
		-- Write the mapping between used type name indices and their name
		for i, value in self.userdataTypes:data() do
			self.bytecode:writeByte(i)
			self.bytecode:writeVarInt(value.nameRef)
		end

		-- 0 marks the end of the mapping
		self.bytecode:writeByte(0)
	end

	self.bytecode:writeVarInt(uint32_t(self.functions:size()))

	for _, func in self.functions:data() do
		self.bytecode:copyAtEnd(func.data)
	end

	LUAU_ASSERT(self.mainFunction < self.functions:size())
	self.bytecode:writeVarInt(self.mainFunction)
end

function prototype.setDumpFlags(self: BytecodeBuilder, flags: number): ()
	self.dumpFlags = flags
	self.dumpFunctionPtr = function(...)
		return self:dumpCurrentFunction(...)
	end
end

function prototype.needsDebugRemarks(self: BytecodeBuilder): boolean
	return bit32.band(self.dumpFlags, DumpFlags.Dump_Remarks) ~= 0
end

function prototype.getBytecode(self: BytecodeBuilder): string
	LUAU_ASSERT(self.bytecode.pos ~= 0) -- did you forget to call finalize?
	local newBuffer = buffer.create(self.bytecode.pos)
	buffer.copy(newBuffer, 0, self.bytecode.buf, 0, self.bytecode.pos)
	return buffer.tostring(newBuffer)
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.writeFunction(self: BytecodeBuilder, buf: Buffer, id: number, flags: number): ()
	LUAU_ASSERT(id < self.functions:size())
	local func = self.functions:get(id + 1)

	-- header
	buf:writeByte(func.maxstacksize)
	buf:writeByte(func.numparams)
	buf:writeByte(func.numupvalues)
	buf:writeBoolean(func.isvararg)

	buf:writeByte(flags)

	if FastVariables.LuauCompileTypeInfo then
		if func.typeinfo ~= "" or not self.typedUpvals:empty() or not self.typedLocals:empty() then
			-- collect type info into a temporary string to know the overall size of type data
			self.tempTypeInfo:clear()
			self.tempTypeInfo:writeVarInt(uint32_t(#func.typeinfo))
			self.tempTypeInfo:writeVarInt(uint32_t(self.typedUpvals:size()))
			self.tempTypeInfo:writeVarInt(uint32_t(self.typedLocals:size()))

			self.tempTypeInfo:writeString(func.typeinfo)

			for _, l in self.typedUpvals:data() do
				self.tempTypeInfo:writeByte(l.type)
			end

			for _, l in self.typedLocals:data() do
				self.tempTypeInfo:writeByte(l.type)
				self.tempTypeInfo:writeByte(l.reg)
				self.tempTypeInfo:writeVarInt(l.startpc)
				LUAU_ASSERT(l.endpc >= l.startpc)
				self.tempTypeInfo:writeVarInt(l.endpc - l.startpc)
			end

			buf:writeVarInt(uint32_t(self.tempTypeInfo.pos))
			buf:copyAtEnd(self.tempTypeInfo)
		else
			buf:writeVarInt(0)
		end
	else
		buf:writeVarInt(uint32_t(#func.typeinfo))
		buf:writeString(func.typeinfo)
	end

	-- instructions
	buf:writeVarInt(uint32_t(self.insns:size()))

	for _, insn in self.insns:data() do
		buf:writeInt(insn)
	end

	-- constants
	buf:writeVarInt(uint32_t(self.constants:size()))

	for _, c in self.constants:data() do
		local cType = c.type
		if cType == Constant.Type.Type_Nil then
			buf:writeByte(LuauBytecodeTag.LBC_CONSTANT_NIL)

		elseif cType == Constant.Type.Type_Boolean then
			buf:writeByte(LuauBytecodeTag.LBC_CONSTANT_BOOLEAN)
			buf:writeBoolean(c.valueBoolean)

		elseif cType == Constant.Type.Type_Number then
			buf:writeByte(LuauBytecodeTag.LBC_CONSTANT_NUMBER)
			buf:writeDouble(c.valueNumber)

		elseif cType == Constant.Type.Type_Vector then
			buf:writeByte(LuauBytecodeTag.LBC_CONSTANT_VECTOR)
			buf:writeFloat(c.valueVector[1])
			buf:writeFloat(c.valueVector[2])
			buf:writeFloat(c.valueVector[3])
			buf:writeFloat(c.valueVector[4])

		elseif cType == Constant.Type.Type_String then
			buf:writeByte(LuauBytecodeTag.LBC_CONSTANT_STRING)
			buf:writeVarInt(c.valueString)

		elseif cType == Constant.Type.Type_Import then
			buf:writeByte(LuauBytecodeTag.LBC_CONSTANT_IMPORT)
			buf:writeInt(c.valueImport)

		elseif cType == Constant.Type.Type_Table then
			local shape = self.tableShapes:get(c.valueTable + 1)
			buf:writeByte(LuauBytecodeTag.LBC_CONSTANT_TABLE)
			buf:writeVarInt(uint32_t(shape.length))
			for _, key in shape.keys do
				buf:writeVarInt(key)
			end

		elseif cType == Constant.Type.Type_Closure then
			buf:writeByte(LuauBytecodeTag.LBC_CONSTANT_CLOSURE)
			buf:writeVarInt(c.valueClosure)

		else
			error("Unsupported constant type")
		end
	end

	-- child protos
	buf:writeVarInt(uint32_t(self.protos:size()))

	for _, child in self.protos:data() do
		buf:writeVarInt(child)
	end

	-- debug info
	buf:writeVarInt(func.debuglinedefined)
	buf:writeVarInt(func.debugname)

	local hasLines = true

	for _, line in self.lines:data() do
		if line == 0 then
			hasLines = false
			break
		end
	end

	if hasLines then
		buf:writeByte(1)

		self:writeLineInfo(buf)
	else
		buf:writeByte(0)
	end

	local hasDebug = not self.debugLocals:empty() or not self.debugUpvals:empty()

	if hasDebug then
		buf:writeByte(1)
		
		buf:writeVarInt(uint32_t(self.debugLocals:size()))

		for _, l in self.debugLocals:data() do
			buf:writeVarInt(l.name)
			buf:writeVarInt(l.startpc)
			buf:writeVarInt(l.endpc)
			buf:writeByte(l.reg)
		end

		buf:writeVarInt(uint32_t(self.debugUpvals:size()))

		for _, l in self.debugUpvals:data() do
			buf:writeVarInt(l.name)
		end
	else
		buf:writeByte(0)
	end
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.writeLineInfo(self: BytecodeBuilder, buf: Buffer): ()
	LUAU_ASSERT(not self.lines:empty())

	-- this function encodes lines inside each span as a 8-bit delta to span baseline
	-- span is always a power of two; depending on the line info input, it may need to be as low as 1
	local span = bit32.lshift(1, 24)

	-- first pass: determine span length
	for offset = 0, self.lines:size() - 1, span do
		local next = offset

		local min = self.lines:get(offset + 1)
		local max = self.lines:get(offset + 1)

		while true do
			if not (next < self.lines:size() and next < offset + span) then
				break
			end

			min = math.min(min, self.lines:get(next + 1))
			max = math.max(max, self.lines:get(next + 1))

			if max - min > 255 then
				break
			end

			next += 1
		end

		if next < self.lines:size() and next - offset < span then
			-- since not all lines in the range fit in 8b delta, we need to shrink the span
            -- next iteration will need to reprocess some lines again since span changed
			span = bit32.lshift(1, log2(next - offset))
		end
	end

	-- second pass: compute span base
	local baselineScratch = Vector.new() :: Vector<number>
	local baselineSize = (self.lines:size() - 1) / span + 1

	if baselineSize > 1 then
		-- avoid heap allocation for single-element baseline which is most functions (<256 lines)
		baselineScratch:resize(baselineSize)
	end

	for offset = 0, self.lines:size() - 1, span do
		local next = offset

		local min = self.lines:get(offset + 1)

		while true do
			if not (next < self.lines:size() and next < offset + span) then
				break
			end

			min = math.min(min, self.lines:get(next + 1))

			next += 1
		end

		if baselineSize <= 1 then
			baselineScratch:resize(1)
			baselineScratch:set(1, min)
		else
			baselineScratch:set((offset / span) + 1, min)			
		end
	end

	-- third pass: write resulting data
	local logspan = log2(span)

	buf:writeByte(uint8_t(logspan))

	local lastOffset = 0

	for i = 1, self.lines:size() do
		local delta = self.lines:get(i) - baselineScratch:get(bit32.rshift(i - 1, logspan) + 1)
		LUAU_ASSERT(delta >= 0 and delta <= 255)

		buf:writeByte(uint8_t(delta) - lastOffset)
		lastOffset = uint8_t(delta)
	end

	local lastLine = 0

	for _, base in baselineScratch:data() do
		buf:writeInt(base - lastLine)
		lastLine = base
	end
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.writeStringTable(self: BytecodeBuilder, buf: Buffer): ()
	local strings = Vector.new() :: Vector<StringRef>
	strings:resize(dictionarySize(self.stringTable))

	for first, second in self.stringTable do
		LUAU_ASSERT(second.index > 0 and second.index <= strings:size())
		strings:set(second.index - 1 + 1, second.stringRef)
	end

	buf:writeVarInt(uint32_t(strings:size()))

	for _, s in strings:data() do
		buf:writeVarInt(uint32_t(s.length))
		buf:writeString(s.data)
	end
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function BytecodeBuilder.getImportId(id0: number, id1: number?, id2: number?): number
	if id1 == nil and id2 == nil then
		LUAU_ASSERT(unsigned(id0) < 1024)

		return bit32.bor(
			bit32.lshift(1, 30),
			bit32.lshift(id0, 20)
		)
	elseif id1 ~= nil and id2 == nil then
		LUAU_ASSERT(unsigned(bit32.bor(id0, id1)) < 1024)

		return bit32.bor(
			bit32.lshift(2, 30),
			bit32.lshift(id0, 20),
			bit32.lshift(id1, 10)
		)
	elseif id1 ~= nil and id2 ~= nil then
		LUAU_ASSERT(unsigned(bit32.bor(id0, id1, id2)) < 1024)

		return bit32.bor(
			bit32.lshift(3, 30),
			bit32.lshift(id0, 20),
			bit32.lshift(id1, 10),
			id2
		)
	else
		error("Invalid arguments.")
	end
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function BytecodeBuilder.decomposeImportId(ids: number, id0: number, id1: number, id2: number): {
	id0: number,
	id1: number,
	id2: number,
	count: number
}
	local count = bit32.rshift(ids, 30)
	id0 = if count > 0 then bit32.band(bit32.rshift(ids, 20), 1023) else -1
	id1 = if count > 1 then bit32.band(bit32.rshift(ids, 10), 1023) else -1
	id2 = if count > 2 then bit32.band(             ids,      1023) else -1
	return {
		id0 = id0,
		id1 = id1,
		id2 = id2,
		count = count
	}
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function BytecodeBuilder.getStringHash(key: StringRef): number
	-- This hashing algorithm should match luaS_hash defined in VM/lstring.cpp for short inputs; we can't use that code directly to keep compiler and
	-- VM independent in terms of compilation/linking. The resulting string hashes are embedded into bytecode binary and result in a better initial
	-- guess for the field hashes which improves performance during initial code execution. We omit the long string processing here for simplicity, as
	-- it doesn't really matter on long identifiers.
	local str = key.data
	local len = key.length

	local h = unsigned(len)

	-- original Lua 5.1 hash for compatibility (exact match when len<32)
	local i = len
	while i > 0 do
		h = bit32.bxor(h, bit32.lshift(h, 5) + bit32.rshift(h, 2) + string.byte(string.sub(str, i)))
		i -= 1
	end

	return h
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.foldJumps(self: BytecodeBuilder): ()
	-- if our function has long jumps, some processing below can make jump instructions not-jumps (e.g. JUMP->RETURN)
	-- it's safer to skip this processing
	if self.hasLongJumps then
		return
	end

	for _, jump in self.jumps do
		local jumpLabel = jump.source

		local jumpInsn = self.insns:get(jumpLabel + 1)

		-- follow jump target through forward unconditional jumps
		-- we only follow forward jumps to make sure the process terminates
		local targetLabel = jumpLabel + 1 + LUAU_INSN_D(jumpInsn)
		LUAU_ASSERT(targetLabel < self.insns:size())
		local targetInsn = self.insns:get(targetLabel + 1)

		while LUAU_INSN_OP(targetInsn) == LuauOpcode.LOP_JUMP and LUAU_INSN_D(targetInsn) >= 0 do
			targetLabel = targetLabel + 1 + LUAU_INSN_D(targetInsn)
			LUAU_ASSERT(targetLabel < self.insns:size())
			targetInsn = self.insns:get(targetLabel + 1)
		end

		local offset = int(targetLabel) - int(jumpLabel) - 1

		-- for unconditional jumps to RETURN, we can replace JUMP with RETURN
		if LUAU_INSN_OP(jumpInsn) == LuauOpcode.LOP_JUMP and LUAU_INSN_OP(targetInsn) == LuauOpcode.LOP_RETURN then
			self.insns:set(jumpLabel + 1, targetInsn)
		elseif int16_t(offset) == offset then
			self.insns:set(jumpLabel + 1, bit32.band(self.insns:get(jumpLabel + 1), 0xffff))
			self.insns:set(jumpLabel + 1, bit32.bor(self.insns:get(jumpLabel + 1), bit32.lshift(uint16_t(offset), 16)))
		end

		jump.target = targetLabel
	end
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.expandJumps(self: BytecodeBuilder): ()
	if not self.hasLongJumps then
		return
	end

	-- we have some jump instructions that couldn't be patched which means their offset didn't fit into 16 bits
	-- our strategy for replacing instructions is as follows: instead of
	--   OP jumpoffset
	-- we will synthesize a jump trampoline before our instruction (note that jump offsets are relative to next instruction):
	--   JUMP +1
	--   JUMPX jumpoffset
	--   OP -2
	-- the idea is that during forward execution, we will jump over JUMPX into OP; if OP decides to jump, it will jump to JUMPX
	-- JUMPX can carry a 24-bit jump offset

	-- jump trampolines expand the code size, which can increase existing jump distances.
	-- because of this, we may need to expand jumps that previously fit into 16-bit just fine.
	-- the worst-case expansion is 3x, so to be conservative we will repatch all jumps that have an offset >= 32767/3
	local kMaxJumpDistanceConservative = 32767 / 3

	--  we will need to process jumps in order
	table.sort(self.jumps, function(lhs, rhs)
		return lhs.source < rhs.source
	end)

	-- first, let's add jump thunks for every jump with a distance that's too big
	-- we will create new instruction buffers, with remap table keeping track of the moves: remap[oldpc] = newpc
	local remap: Vector<number> = Vector.new()
	remap:reserve(self.insns:size())

	local newinsns: Vector<number> = Vector.new()
	local newlines: Vector<number> = Vector.new()

	LUAU_ASSERT(self.insns:size() == self.lines:size())
	newinsns:reserve(self.insns:size())
	newlines:reserve(self.insns:size())

	local currentJump = 0
	local pendingTrampolines = 0

	local i = 1

	while i <= self.insns:size() do
		local op = LUAU_INSN_OP(self.insns:get(i))
		LUAU_ASSERT(op < LuauOpcode.LOP__COUNT)

		if currentJump < #self.jumps and self.jumps[currentJump + 1].source == i - 1 then
			local offset = int(self.jumps[currentJump + 1].target) - int(self.jumps[currentJump - 1].source) - 1

			if math.abs(offset) > kMaxJumpDistanceConservative then
				-- insert jump trampoline as described above; we keep JUMPX offset uninitialized in this pass
				newinsns:push_back(bit32.bor(LuauOpcode.LOP_JUMP, bit32.lshift(1, 16)))
				newinsns:push_back(LuauOpcode.LOP_JUMPX)

				newlines:push_back(self.lines:get(i))
				newlines:push_back(self.lines:get(i))

				pendingTrampolines += 1
			end
		end

		local oplen = getOpLength(op)

		-- copy instruction and line info to the new stream
		for _ = 1, oplen do
			remap:set(i, uint32_t(newinsns:size()))

			newinsns:push_back(self.insns:get(i))
			newlines:push_back(self.lines:get(i))

			i += 1
		end
	end

	LUAU_ASSERT(currentJump == #self.jumps)
	LUAU_ASSERT(pendingTrampolines > 0)

	-- now we need to recompute offsets for jump instructions - we could not do this in the first pass because the offsets are between *target*
	-- instructions
	for _, jump in self.jumps do
		local offset = int(jump.target) - int(jump.source) - 1
		local newoffset = int(remap:get(jump.target + 1)) - int(remap:get(jump.source + 1)) - 1

		if math.abs(offset) > kMaxJumpDistanceConservative then
			-- fix up jump trampoline
			local insnt = newinsns:get(remap:get(jump.source + 1) - 1)
			local insnj = newinsns:get(remap:get(jump.source + 1))

			LUAU_ASSERT(LUAU_INSN_OP(insnt) == LuauOpcode.LOP_JUMPX)

			-- patch JUMPX to JUMPX to target location; note that newoffset is the offset of the jump *relative to OP*, so we need to add 1 to make it
			-- relative to JUMPX
			insnt = bit32.band(insnt, 0xff)
			insnt = bit32.bor(insnt, bit32.lshift(uint32_t(newoffset + 1), 8))

			-- patch OP to OP -2
			insnj = bit32.band(insnj, 0xffff)
			insnj = bit32.bor(insnj, bit32.lshift(uint16_t(-2), 16))

			pendingTrampolines -= 1
		else
			local insn = newinsns:get(remap:get(jump.source + 1) + 1)

			-- make sure jump instruction had the correct offset before we started
			LUAU_ASSERT(LUAU_INSN_D(insn) == offset)

			-- patch instruction with the new offset
			LUAU_ASSERT(int16_t(newoffset) == offset)

			insn = bit32.band(insn, 0xffff)
			insn = bit32.bor(insn, bit32.lshift(uint16_t(newoffset), 16))
		end
	end

	LUAU_ASSERT(pendingTrampolines == 0)

	-- this was hard, but we're done.
	self.insns:swap(newinsns)
	self.lines:swap(newlines)
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function BytecodeBuilder.getError(message: string): string
	-- 0 acts as a special marker for error bytecode (it's equal to LBC_VERSION_TARGET for valid bytecode blobs)
	local result = ""
	result ..= string.char(0)
	result ..= message

	return result
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function BytecodeBuilder.getVersion(): number
	-- This function usually returns LBC_VERSION_TARGET but may sometimes return a higher number (within LBC_VERSION_MIN/MAX) under fast flags
	return LuauBytecodeTag.LBC_VERSION_TARGET
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function BytecodeBuilder.getTypeEncodingVersion(): number
	if FastVariables.LuauCompileTypeInfo and FastVariables.LuauCompileUserdataInfo then
		return LuauBytecodeTag.LBC_TYPE_VERSION_TARGET
	end

	return if FastVariables.LuauCompileTypeInfo then 2 else LuauBytecodeTag.LBC_TYPE_VERSION_DEPRECATED
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.validate(self: BytecodeBuilder): ()
	self:validateInstructions()
	self:validateVariadic()
end

local function VREG(v: number, func: Bytecode_Function): ()
	LUAU_ASSERT(unsigned(v) < func.maxstacksize)
end
local function VREGRANGE(v: number, count: number, func: Bytecode_Function): ()
	LUAU_ASSERT(unsigned(v + (if count < 0 then 0 else count)) <= func.maxstacksize)
end
local function VUPVAL(v: number, func: Bytecode_Function): ()
	LUAU_ASSERT(unsigned(v) < func.numupvalues)
end
local function VCONST(v: number, kind: number, constants: Vector<Constant>)
	LUAU_ASSERT(unsigned(v) < constants:size() and constants:get(v + 1).type == kind)
end
local function VCONSTANY(v: number, constants: Vector<Constant>)
	LUAU_ASSERT(unsigned(v) < constants:size())
end
local function VJUMP(v: number, i: number, insns: Vector<number>, insnvalid: Vector<number>): ()
	LUAU_ASSERT((i + 1 + v) <= insns:size() and insnvalid:get(i + 1 + v) == 1)
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.validateInstructions(self: BytecodeBuilder): ()
	LUAU_ASSERT(self.currentFunction ~= bit32.bnot(0))

	local func = self.functions:get(self.currentFunction + 1)

	-- tag instruction offsets so that we can validate jumps
	local insnvalid = Vector.new(self.insns:size(), 0)
	local i = 1
	while i <= self.insns:size() do
		local insn = self.insns:get(i)
		local op = LUAU_INSN_OP(insn)

		insnvalid:set(i, btn(true))

		i += getOpLength(op)
		LUAU_ASSERT(i <= self.insns:size() + 1)
	end

	local openCaptures: Vector<number> = Vector.new()

	-- validate individual instructions
	local i = 1
	while i <= self.insns:size() do
		local insn = self.insns:get(i)
		local op = LUAU_INSN_OP(insn)

		if op == LuauOpcode.LOP_LOADNIL then
			VREG(LUAU_INSN_A(insn), func)
		elseif op == LuauOpcode.LOP_LOADB then
			VREG(LUAU_INSN_A(insn), func)
			LUAU_ASSERT(LUAU_INSN_B(insn) == 0 or LUAU_INSN_B(insn) == 1)
			VJUMP(LUAU_INSN_C(insn), i, self.insns, insnvalid)
		elseif op == LuauOpcode.LOP_LOADN then
			VREG(LUAU_INSN_A(insn), func)
		elseif op == LuauOpcode.LOP_LOADK then
			VREG(LUAU_INSN_A(insn), func)
			VCONSTANY(LUAU_INSN_D(insn), self.constants)
		elseif op == LuauOpcode.LOP_MOVE then
			VREG(LUAU_INSN_A(insn), func)
			VREG(LUAU_INSN_B(insn), func)
		elseif op == LuauOpcode.LOP_GETGLOBAL or op == LuauOpcode.LOP_SETGLOBAL then
			VREG(LUAU_INSN_A(insn), func)
			VCONST(self.insns:get(i + 1), Constant.Type.Type_String, self.constants)
		elseif op == LuauOpcode.LOP_GETUPVAL or op == LuauOpcode.LOP_SETUPVAL then
			VREG(LUAU_INSN_A(insn), func)
			VUPVAL(LUAU_INSN_B(insn), func)
		elseif op == LuauOpcode.LOP_CLOSEUPVALS then
			VREG(LUAU_INSN_A(insn), func)
			while openCaptures:size() > 0 and openCaptures:back() >= LUAU_INSN_A(insn) do
				openCaptures:pop_back()
			end
		elseif op == LuauOpcode.LOP_GETIMPORT then
			VREG(LUAU_INSN_A(insn), func)
			VCONST(LUAU_INSN_D(insn), Constant.Type.Type_Import, self.constants)
			local id = self.insns:get(i + 1)
			LUAU_ASSERT(bit32.rshift(id, 30) ~= 0) -- import chain with length 1-3
			for j = 0, bit32.rshift(id, 30) - 1 do
				VCONST(bit32.band(bit32.rshift(id, 20 - 10 * j), 1023), Constant.Type.Type_String, self.constants)
			end
		elseif op == LuauOpcode.LOP_GETTABLE or op == LuauOpcode.LOP_SETTABLE then
			VREG(LUAU_INSN_A(insn), func)
			VREG(LUAU_INSN_B(insn), func)
			VREG(LUAU_INSN_C(insn), func)
		elseif op == LuauOpcode.LOP_GETTABLEKS or op == LuauOpcode.LOP_SETTABLEKS then
			VREG(LUAU_INSN_A(insn), func)
			VREG(LUAU_INSN_B(insn), func)
			VCONST(self.insns:get(i + 1), Constant.Type.Type_String, self.constants)
		elseif op == LuauOpcode.LOP_GETTABLEN or op == LuauOpcode.LOP_SETTABLEN then
			VREG(LUAU_INSN_A(insn), func)
			VREG(LUAU_INSN_B(insn), func)
		elseif op == LuauOpcode.LOP_NEWCLOSURE then
			VREG(LUAU_INSN_A(insn), func)
			LUAU_ASSERT(unsigned(LUAU_INSN_D(insn)) < self.protos:size())
			LUAU_ASSERT(self.protos:get(LUAU_INSN_D(insn) + 1) < self.functions:size())
			local numupvalues = self.functions:get(self.protos:get(LUAU_INSN_D(insn) + 1) + 1).numupvalues

			for j = 0, numupvalues - 1 do
				LUAU_ASSERT(i + 1 + j < self.insns:size())
				local cinsn = self.insns:get(i + 1 + j)
				LUAU_ASSERT(LUAU_INSN_OP(cinsn) == LuauOpcode.LOP_CAPTURE)
			end
		elseif op == LuauOpcode.LOP_NAMECALL then
			VREG(LUAU_INSN_A(insn), func)
			VREG(LUAU_INSN_B(insn), func)
			VCONST(self.insns:get(i + 1), Constant.Type.Type_String, self.constants)
			LUAU_ASSERT(LUAU_INSN_OP(self.insns:get(i + 2)) == LuauOpcode.LOP_CALL)
		elseif op == LuauOpcode.LOP_CALL then
			local nparams = LUAU_INSN_B(insn) - 1
			local nresults = LUAU_INSN_C(insn) - 1
			VREG(LUAU_INSN_A(insn), func)
			VREGRANGE(LUAU_INSN_A(insn) + 1, nparams, func) -- 1..nparams
			VREGRANGE(LUAU_INSN_A(insn), nresults, func)    -- 1..nresults
		elseif op == LuauOpcode.LOP_RETURN then
			local nresults = LUAU_INSN_B(insn) - 1
			VREGRANGE(LUAU_INSN_A(insn), nresults, func) -- 0..nresults-1
		elseif op == LuauOpcode.LOP_JUMP then
			VJUMP(LUAU_INSN_D(insn), i, self.insns, insnvalid)
		elseif op == LuauOpcode.LOP_JUMPIF or op == LuauOpcode.LOP_JUMPIFNOT then
			VREG(LUAU_INSN_A(insn), func)
			VJUMP(LUAU_INSN_D(insn), i, self.insns, insnvalid)
		elseif
			op == LuauOpcode.LOP_JUMPIFEQ
			or op == LuauOpcode.LOP_JUMPIFLE
			or op == LuauOpcode.LOP_JUMPIFLT
			or op == LuauOpcode.LOP_JUMPIFNOTEQ
			or op == LuauOpcode.LOP_JUMPIFNOTLE
			or op == LuauOpcode.LOP_JUMPIFNOTLT
		then
			VREG(LUAU_INSN_A(insn), func)
			VREG(self.insns:get(i + 1), func)
			VJUMP(LUAU_INSN_D(insn), i, self.insns, insnvalid)
		elseif op == LuauOpcode.LOP_JUMPXEQKNIL or op == LuauOpcode.LOP_JUMPXEQKB then
			VREG(LUAU_INSN_A(insn), func)
			VJUMP(LUAU_INSN_D(insn), i, self.insns, insnvalid)
		elseif op == LuauOpcode.LOP_JUMPXEQKN then
			VREG(LUAU_INSN_A(insn), func)
			VCONST(bit32.band(self.insns:get(i + 1), 0xffffff), Constant.Type.Type_Number, self.constants)
			VJUMP(LUAU_INSN_D(insn), i, self.insns, insnvalid)
		elseif op == LuauOpcode.LOP_JUMPXEQKS then
			VREG(LUAU_INSN_A(insn), func)
			VCONST(bit32.band(self.insns:get(i + 1), 0xffffff), Constant.Type.Type_Number, self.constants)
			VJUMP(LUAU_INSN_D(insn), i, self.insns, insnvalid)
		elseif
			op == LuauOpcode.LOP_ADD
			or op == LuauOpcode.LOP_SUB
			or op == LuauOpcode.LOP_MUL
			or op == LuauOpcode.LOP_DIV
			or op == LuauOpcode.LOP_IDIV
			or op == LuauOpcode.LOP_MOD
			or op == LuauOpcode.LOP_POW
		then
			VREG(LUAU_INSN_A(insn), func)
			VREG(LUAU_INSN_B(insn), func)
			VREG(LUAU_INSN_C(insn), func)
		elseif
			op == LuauOpcode.LOP_ADDK
			or op == LuauOpcode.LOP_SUBK
			or op == LuauOpcode.LOP_MUL
			or op == LuauOpcode.LOP_DIVK
			or op == LuauOpcode.LOP_IDIVK
			or op == LuauOpcode.LOP_MODK
			or op == LuauOpcode.LOP_POWK
		then
			VREG(LUAU_INSN_A(insn), func)
			VREG(LUAU_INSN_B(insn), func)
			VCONST(LUAU_INSN_C(insn), Constant.Type.Type_Number, self.constants)
		elseif op == LuauOpcode.LOP_SUBRK or op == LuauOpcode.LOP_DIVRK then
			VREG(LUAU_INSN_A(insn), func)
			VCONST(LUAU_INSN_B(insn), Constant.Type.Type_Number, self.constants)
			VREG(LUAU_INSN_C(insn), func)
		elseif op == LuauOpcode.LOP_AND or op == LuauOpcode.LOP_OR then
			VREG(LUAU_INSN_A(insn), func)
			VREG(LUAU_INSN_B(insn), func)
			VREG(LUAU_INSN_C(insn), func)
		elseif op == LuauOpcode.LOP_ANDK or op == LuauOpcode.LOP_ORK then
			VREG(LUAU_INSN_A(insn), func)
			VREG(LUAU_INSN_B(insn), func)
			VCONSTANY(LUAU_INSN_C(insn), self.constants)
		elseif op == LuauOpcode.LOP_CONCAT then
			VREG(LUAU_INSN_A(insn), func)
			VREG(LUAU_INSN_B(insn), func)
			VREG(LUAU_INSN_C(insn), func)
			LUAU_ASSERT(LUAU_INSN_B(insn) <= LUAU_INSN_C(insn))
		elseif
			op == LuauOpcode.LOP_NOT
			or op == LuauOpcode.LOP_MINUS
			or op == LuauOpcode.LOP_LENGTH
		then
			VREG(LUAU_INSN_A(insn), func)
			VREG(LUAU_INSN_B(insn), func)
		elseif op == LuauOpcode.LOP_NEWTABLE then
			VREG(LUAU_INSN_A(insn), func)
		elseif op == LuauOpcode.LOP_DUPTABLE then
			VREG(LUAU_INSN_A(insn), func)
			VCONST(LUAU_INSN_D(insn), Constant.Type.Type_Table, self.constants)
		elseif op == LuauOpcode.LOP_SETLIST then
			local count = LUAU_INSN_C(insn) - 1
			VREG(LUAU_INSN_A(insn), func)
			VREGRANGE(LUAU_INSN_B(insn), count, func)
		elseif op == LuauOpcode.LOP_FORNPREP or op == LuauOpcode.LOP_FORNLOOP then
			-- for loop protocol: A, A+1, A+2 are used for iteration
			VREG(LUAU_INSN_A(insn) + 2, func)
			VJUMP(LUAU_INSN_D(insn), i, self.insns, insnvalid)
		elseif op == LuauOpcode.LOP_FORGPREP then
			-- forg loop protocol: A, A+1, A+2 are used for iteration protocol; A+3, ... are loop variables
			VREG(LUAU_INSN_A(insn) + 2 + 1, func)
			VJUMP(LUAU_INSN_D(insn), i, self.insns, insnvalid)
		elseif op == LuauOpcode.LOP_FORGLOOP then
			-- forg loop protocol: A, A+1, A+2 are used for iteration protocol; A+3, ... are loop variables
			VREG(LUAU_INSN_A(insn) + 2 + uint16_t(self.insns:get(i + 1)), func)
			VJUMP(LUAU_INSN_D(insn), i, self.insns, insnvalid)
			LUAU_ASSERT(uint16_t(self.insns:get(i + 1)) >= 1)
		elseif op == LuauOpcode.LOP_FORGPREP_INEXT or op == LuauOpcode.LOP_FORGPREP_NEXT then
			VREG(LUAU_INSN_A(insn) + 4, func)
			VJUMP(LUAU_INSN_D(insn), i, self.insns, insnvalid)
		elseif op == LuauOpcode.LOP_GETVARARGS then
			local nresults = LUAU_INSN_A(insn) - 1
			VREGRANGE(LUAU_INSN_A(insn), nresults, func) -- 0..nresults-1
		elseif op == LuauOpcode.LOP_DUPCLOSURE then
			VREG(LUAU_INSN_A(insn), func)
			VCONST(LUAU_INSN_D(insn), Constant.Type.Type_Closure, self.constants)
			local proto = self.constants:get(LUAU_INSN_D(insn) + 1).valueClosure
			LUAU_ASSERT(proto < self.functions:size())
			local numupvalues = self.functions:get(proto + 1).numupvalues

			for j = 0, numupvalues - 1 do
				LUAU_ASSERT(i + 1 + j < self.insns:size())
				local cinsn = self.insns:get(i + 1 + j)
				LUAU_ASSERT(LUAU_INSN_OP(cinsn) == LuauOpcode.LOP_CAPTURE)
				LUAU_ASSERT(LUAU_INSN_A(cinsn) == LuauCaptureType.LCT_VAL or LUAU_INSN_A(cinsn) == LuauCaptureType.LCT_UPVAL)
			end
		elseif op == LuauOpcode.LOP_PREPVARARGS then
			LUAU_ASSERT(LUAU_INSN_A(insn) == func.numparams)
			LUAU_ASSERT(func.isvararg)
		elseif op == LuauOpcode.LOP_BREAK then

		elseif op == LuauOpcode.LOP_JUMPBACK then
			VJUMP(LUAU_INSN_D(insn), i, self.insns, insnvalid)
		elseif op == LuauOpcode.LOP_LOADKX then
			VJUMP(LUAU_INSN_E(insn), i, self.insns, insnvalid)
			VCONSTANY(self.insns:get(i + 1), self.constants)
		elseif op == LuauOpcode.LOP_JUMPX then
			VJUMP(LUAU_INSN_E(insn), i, self.insns, insnvalid)
		elseif op == LuauOpcode.LOP_FASTCALL then
			VJUMP(LUAU_INSN_C(insn), i, self.insns, insnvalid)
			LUAU_ASSERT(LUAU_INSN_OP(self.insns:get(i + 1 + LUAU_INSN_C(insn))) == LuauOpcode.LOP_CALL)
		elseif op == LuauOpcode.LOP_FASTCALL1 then
			VREG(LUAU_INSN_B(insn), func)
			VJUMP(LUAU_INSN_C(insn), i, self.insns, insnvalid)
			LUAU_ASSERT(LUAU_INSN_OP(self.insns:get(i + 1 + LUAU_INSN_C(insn))) == LuauOpcode.LOP_CALL)
		elseif op == LuauOpcode.LOP_FASTCALL2 then
			VREG(LUAU_INSN_B(insn), func)
			VJUMP(LUAU_INSN_C(insn), i, self.insns, insnvalid)
			LUAU_ASSERT(LUAU_INSN_OP(self.insns:get(i + 1 + LUAU_INSN_C(insn))) == LuauOpcode.LOP_CALL)
			VREG(self.insns:get(i + 1), func)
		elseif op == LuauOpcode.LOP_FASTCALL2K then
			VREG(LUAU_INSN_B(insn), func)
			VJUMP(LUAU_INSN_C(insn), i, self.insns, insnvalid)
			LUAU_ASSERT(LUAU_INSN_OP(self.insns:get(i + 1 + LUAU_INSN_C(insn))) == LuauOpcode.LOP_CALL)
			VCONSTANY(self.insns:get(i + 1), self.constants)
		elseif op == LuauOpcode.LOP_COVERAGE then

		elseif op == LuauOpcode.LOP_CAPTURE then
			if LUAU_INSN_A(insn) == LuauCaptureType.LCT_VAL then
				VREG(LUAU_INSN_B(insn), func)
			elseif LUAU_INSN_A(insn) == LuauCaptureType.LCT_REF then
				VREG(LUAU_INSN_B(insn), func)
				openCaptures:push_back(LUAU_INSN_B(insn))
			elseif LUAU_INSN_A(insn) == LuauCaptureType.LCT_UPVAL then
				VUPVAL(LUAU_INSN_B(insn), func)
			else
				error("Unsupported capture type")
			end
		else
			error("Unsupported opcode")
		end

		i += getOpLength(op)
		LUAU_ASSERT(i <= self.insns:size() + 1)
	end

	-- all CAPTURE REF instructions must have a CLOSEUPVALS instruction after them in the bytecode stream
	-- this doesn't guarantee safety as it doesn't perform basic block based analysis, but if this fails
	-- then the bytecode is definitely unsafe to run since the compiler won't generate backwards branches
	-- except for loop edges
	LUAU_ASSERT(openCaptures:empty())
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.validateVariadic(self: BytecodeBuilder): ()
	-- validate MULTRET sequences: instructions that produce a variadic sequence and consume one must come in pairs
	-- we classify instructions into four groups: producers, consumers, neutral and others
	-- any producer (an instruction that produces more than one value) must be followed by 0 or more neutral instructions
	-- and a consumer (that consumes more than one value); these form a variadic sequence.
	-- except for producer, no instruction in the variadic sequence may be a jump target.
	-- from the execution perspective, producer adjusts L->top to point to one past the last result, neutral instructions
	-- leave L->top unmodified, and consumer adjusts L->top back to the stack frame end.
	-- consumers invalidate all values after L->top after they execute (which we currently don't validate)
	local variadicSeq = false

	local insntargets = Vector.new(self.insns:size(), 0)

	local i = 1
	while i <= self.insns:size() do
		local insn = self.insns:get(i)
		local op = LUAU_INSN_OP(insn)

		local target = getJumpTarget(insn, uint32_t(i - 1))

		if target >= 0 and not isFastCall(op) then
			LUAU_ASSERT(unsigned(target) < self.insns:size())

			insntargets:set(target, btn(true))
		end

		i += getOpLength(op)
		LUAU_ASSERT(i <= self.insns:size() + 1)
	end

	local i = 1
	while i <= self.insns:size() do
		local insn = self.insns:get(i)
		local op = LUAU_INSN_OP(insn)

		if variadicSeq then
			-- no instruction inside the sequence, including the consumer, may be a jump target
			-- this guarantees uninterrupted L->top adjustment flow
			LUAU_ASSERT(insntargets:get(i - 1) == 0)
		end

		if op == LuauOpcode.LOP_CALL then
			-- note: calls may end one variadic sequence and start a new one

			if LUAU_INSN_B(insn) == 0 then
				-- consumer instruction ends a variadic sequence
				LUAU_ASSERT(variadicSeq)
				variadicSeq = false
			else
				-- CALL is not a neutral instruction so it can't be present in a variadic sequence unless it's a consumer
				LUAU_ASSERT(not variadicSeq)
			end

			if LUAU_INSN_C(insn) == 0 then
				-- producer instruction starts a variadic sequence
				LUAU_ASSERT(not variadicSeq)
				variadicSeq = true
			end
		elseif op == LuauOpcode.LOP_GETVARARGS and LUAU_INSN_B(insn) == 0 then
			-- producer instruction starts a variadic sequence
			LUAU_ASSERT(not variadicSeq)
			variadicSeq = true
		elseif (op == LuauOpcode.LOP_RETURN and LUAU_INSN_B(insn) == 0) or (op == LuauOpcode.LOP_SETLIST and LUAU_INSN_C(insn) == 0) then
			-- consumer instruction ends a variadic sequence
			LUAU_ASSERT(variadicSeq)
			variadicSeq = false
		elseif op == LuauOpcode.LOP_FASTCALL then
			local callTarget = int(i + LUAU_INSN_C(insn) + 1)
			LUAU_ASSERT(unsigned(callTarget) <= self.insns:size() and LUAU_INSN_OP(self.insns:get(callTarget)) == LuauOpcode.LOP_CALL)

			if LUAU_INSN_B(self.insns:get(callTarget)) == 0 then
				-- consumer instruction ends a variadic sequence; however, we can't terminate it yet because future analysis of CALL will do it
				-- during FASTCALL fallback, the instructions between this and CALL consumer are going to be executed before L->top so they must
				-- be neutral; as such, we will defer termination of variadic sequence until CALL analysis
				LUAU_ASSERT(variadicSeq)
			else
				LUAU_ASSERT(not variadicSeq)
			end

			-- note: if FASTCALL is linked to a CALL producer, the instructions between FASTCALL and CALL are technically not part of an executed
			-- variadic sequence since they are never executed if FASTCALL does anything, so it's okay to skip their validation until CALL
			-- (we can't simply start a variadic sequence here because that would trigger assertions during linked CALL validation)
		elseif
			op == LuauOpcode.LOP_CLOSEUPVALS
			or op == LuauOpcode.LOP_NAMECALL
			or op == LuauOpcode.LOP_GETIMPORT
			or op == LuauOpcode.LOP_MOVE
			or op == LuauOpcode.LOP_GETUPVAL
			or op == LuauOpcode.LOP_GETGLOBAL
			or op == LuauOpcode.LOP_GETTABLEKS
			or op == LuauOpcode.LOP_COVERAGE
		then
			-- instructions inside a variadic sequence must be neutral (can't change L->top)
			-- while there are many neutral instructions like this, here we check that the instruction is one of the few
			-- that we'd expect to exist in FASTCALL fallback sequences or between consecutive CALLs for encoding reasons
		else
			LUAU_ASSERT(not variadicSeq)
		end

		i += getOpLength(op)
		LUAU_ASSERT(i <= self.insns:size() + 1)
	end

	LUAU_ASSERT(not variadicSeq)
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function BytecodeBuilder.printableStringConstant(str: string, len: number): boolean
	for i = 1, len do
		if string.byte(str, i) < string.byte(" ") then
			return false
		end
	end
	
	return true
end

local function formatAppend(str: stringWrap, fmt: string, ...: any)
	str.s ..= fmt:format(...)
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.dumpConstant(self: BytecodeBuilder, result: stringWrap, k: number): ()
	local k = int(k)
	LUAU_ASSERT(unsigned(k) < self.constants:size())
	local data = self.constants:get(k + 1)

	if data.type == Constant.Type.Type_Nil then
		formatAppend(result, "nil")
	elseif data.type == Constant.Type.Type_Boolean then
		formatAppend(result, "%s", if data.valueBoolean then "true" else "false")
	elseif data.type == Constant.Type.Type_Number then
		formatAppend(result, "%.17g", data.valueNumber)
	elseif data.type == Constant.Type.Type_Vector then
		-- 3-vectors is the most common configuration, so truncate to three components if possible
		if data.valueVector[4] == 0 then
			formatAppend(result, "%.9g, %.9g, %.9g", data.valueVector[1], data.valueVector[2], data.valueVector[3])
		else
			formatAppend(result, "%.9g, %.9g, %.9g, %.9g", data.valueVector[1], data.valueVector[2], data.valueVector[3], data.valueVector[4])
		end
	elseif data.type == Constant.Type.Type_String then
		local str = self.debugStrings:get(data.valueString)

		if BytecodeBuilder.printableStringConstant(str.data, str.length) then
			if str.length < 32 then
				formatAppend(result, str.data)
			else
				formatAppend(result, "'%s'...", str.data:sub(1, 32))
			end
		end
	elseif data.type == Constant.Type.Type_Import then
		local id0, id1, id2 = -1, -1, -1
		local returns = BytecodeBuilder.decomposeImportId(data.valueImport, id0, id1, id2)
		local count = returns.count
		id0 = returns.id0
		id1 = returns.id1
		id2 = returns.id2

		if count ~= 0 then
			do
				local id = self.constants:get(id0 + 1)
				LUAU_ASSERT(id.type == Constant.Type.Type_String and id.valueString <= self.debugStrings:size())

				local str = self.debugStrings:get(id.valueString)
				formatAppend(result, "%s", str.data)
			end

			if count > 1 then
				local id = self.constants:get(id1 + 1)
				LUAU_ASSERT(id.type == Constant.Type.Type_String and id.valueString <= self.debugStrings:size())

				local str = self.debugStrings:get(id.valueString)
				formatAppend(result, "%s", str.data)
			end

			if count > 2 then
				local id = self.constants:get(id2 + 1)
				LUAU_ASSERT(id.type == Constant.Type.Type_String and id.valueString <= self.debugStrings:size())

				local str = self.debugStrings:get(id.valueString)
				formatAppend(result, "%s", str.data)
			end
		end
	elseif data.type == Constant.Type.Type_Table then
		formatAppend(result, "{...}")
	elseif data.type == Constant.Type.Type_Closure then
		local func = self.functions:get(data.valueClosure + 1)

		if func.dumpname ~= "" then
			formatAppend(result, "'%s'", func.dumpname)
		end
	end
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.dumpInstruction(self: BytecodeBuilder, codeIndex: number, result: stringWrap, targetLabel: number): ()
	local insn = self.insns:get(codeIndex)
	local code = codeIndex + 1
	local op = LUAU_INSN_OP(insn)
	if op == LuauOpcode.LOP_LOADNIL then
		formatAppend(result, "LOADNIL R%d\n", LUAU_INSN_A(insn))
	elseif op == LuauOpcode.LOP_LOADB then
		if LUAU_INSN_C(insn) ~= 0 then
			formatAppend(result, "LOADB R%d %d +%d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
		else
			formatAppend(result, "LOADB R%d %d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn))
		end
	elseif op == LuauOpcode.LOP_LOADN then
		formatAppend(result, "LOADN R%d %d\n", LUAU_INSN_A(insn), LUAU_INSN_D(insn))
	elseif op == LuauOpcode.LOP_LOADK then
		formatAppend(result, "LOADK R%d K%d [", LUAU_INSN_A(insn), LUAU_INSN_D(insn))
		self:dumpConstant(result, LUAU_INSN_D(insn))
		result.s ..= "]\n"
	elseif op == LuauOpcode.LOP_MOVE then
		formatAppend(result, "MOVE R%d R%d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn))
	elseif op == LuauOpcode.LOP_GETGLOBAL then
		formatAppend(result, "GETGLOBAL R%d K%d [", LUAU_INSN_A(insn), self.insns:get(code))
		self:dumpConstant(result, self.insns:get(code))
		result.s ..= "]\n"
	elseif op == LuauOpcode.LOP_SETGLOBAL then
		formatAppend(result, "SETGLOBAL R%d K%d [", LUAU_INSN_A(insn), self.insns:get(code))
		self:dumpConstant(result, self.insns:get(code))
		result.s ..= "]\n"
		code += 1
	elseif op == LuauOpcode.LOP_GETUPVAL then
		formatAppend(result, "GETUPVAL R%d %d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn))
	elseif op == LuauOpcode.LOP_SETUPVAL then
		formatAppend(result, "SETUPVAL R%d %d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn))
	elseif op == LuauOpcode.LOP_CLOSEUPVALS then
		formatAppend(result, "CLOSEUPVALS R%d\n", LUAU_INSN_A(insn))
	elseif op == LuauOpcode.LOP_GETIMPORT then
		formatAppend(result, "GETIMPORT R%d %d [", LUAU_INSN_A(insn), LUAU_INSN_D(insn))
		self:dumpConstant(result, LUAU_INSN_D(insn))
		result.s ..= "]\n"
		code += 1 -- AUX
	elseif op == LuauOpcode.LOP_GETTABLE then
		formatAppend(result, "GETTABLE R%d R%d R%d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
	elseif op == LuauOpcode.LOP_SETTABLE then
		formatAppend(result, "SETTABLE R%d R%d R%d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
	elseif op == LuauOpcode.LOP_GETTABLEKS then
		formatAppend(result, "GETTABLEKS R%d R%d K%d [", LUAU_INSN_A(insn), LUAU_INSN_B(insn), self.insns:get(code))
		self:dumpConstant(result, self.insns:get(code))
		result.s ..= "]\n"
		code += 1
	elseif op == LuauOpcode.LOP_SETTABLEKS then
		formatAppend(result, "SETTABLEKS R%d R%d K%d [", LUAU_INSN_A(insn), LUAU_INSN_B(insn), self.insns:get(code))
		self:dumpConstant(result, self.insns:get(code))
		result.s ..= "]\n"
	elseif op == LuauOpcode.LOP_GETTABLEN then
		formatAppend(result, "GETTABLEN R%d R%d %d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn) + 1)
	elseif op == LuauOpcode.LOP_SETTABLEN then
		formatAppend(result, "SETTABLEN R%d R%d %d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn) + 1)
	elseif op == LuauOpcode.LOP_NEWCLOSURE then
		formatAppend(result, "NEWCLOSURE R%d P%d\n", LUAU_INSN_A(insn), LUAU_INSN_D(insn))
	elseif op == LuauOpcode.LOP_NAMECALL then
		formatAppend(result, "NAMECALL R%d R%d K%d [", LUAU_INSN_A(insn), LUAU_INSN_B(insn), self.insns:get(code))
		self:dumpConstant(result, self.insns:get(code))
		result.s ..= "]\n"
		code += 1
	elseif op == LuauOpcode.LOP_CALL then
		formatAppend(result, "CALL R%d %d %d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn) - 1, LUAU_INSN_C(insn) - 1)
	elseif op == LuauOpcode.LOP_RETURN then
		formatAppend(result, "RETURN R%d %d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn) - 1)
	elseif op == LuauOpcode.LOP_JUMP then
		formatAppend(result, "JUMP L%d\n", targetLabel)
	elseif op == LuauOpcode.LOP_JUMPIF then
		formatAppend(result, "JUMPIF R%d L%d\n", LUAU_INSN_A(insn), targetLabel)
	elseif op == LuauOpcode.LOP_JUMPIFNOT then
		formatAppend(result, "JUMPIFNOT R%d L%d\n", LUAU_INSN_A(insn), targetLabel)
	elseif op == LuauOpcode.LOP_JUMPIFEQ then
		formatAppend(result, "JUMPIFEQ R%d R%d L%d\n", LUAU_INSN_A(insn), self.insns:get(code), targetLabel)
		code += 1
	elseif op == LuauOpcode.LOP_JUMPIFLE then
		formatAppend(result, "JUMPIFLE R%d R%d L%d\n", LUAU_INSN_A(insn), self.insns:get(code), targetLabel)
		code += 1
	elseif op == LuauOpcode.LOP_JUMPIFLT then
		formatAppend(result, "JUMPIFLT R%d R%d L%d\n", LUAU_INSN_A(insn), self.insns:get(code), targetLabel)
		code += 1
	elseif op == LuauOpcode.LOP_JUMPIFNOTEQ then
		formatAppend(result, "JUMPIFNOTEQ R%d R%d L%d\n", LUAU_INSN_A(insn), self.insns:get(code), targetLabel)
		code += 1
	elseif op == LuauOpcode.LOP_JUMPIFNOTLE then
		formatAppend(result, "JUMPIFNOTLE R%d R%d L%d\n", LUAU_INSN_A(insn), self.insns:get(code), targetLabel)
		code += 1
	elseif op == LuauOpcode.LOP_JUMPIFNOTLT then
		formatAppend(result, "JUMPIFNOTLT R%d R%d L%d\n", LUAU_INSN_A(insn), self.insns:get(code), targetLabel)
		code += 1
	elseif op == LuauOpcode.LOP_ADD then
		formatAppend(result, "ADD R%d R%d R%d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
	elseif op == LuauOpcode.LOP_SUB then
		formatAppend(result, "SUB R%d R%d R%d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
	elseif op == LuauOpcode.LOP_MUL then
		formatAppend(result, "MUL R%d R%d R%d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
	elseif op == LuauOpcode.LOP_DIV then
		formatAppend(result, "DIV R%d R%d R%d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
	elseif op == LuauOpcode.LOP_IDIV then
		formatAppend(result, "IDIV R%d R%d R%d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
	elseif op == LuauOpcode.LOP_MOD then
		formatAppend(result, "MOD R%d R%d R%d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
	elseif op == LuauOpcode.LOP_POW then
		formatAppend(result, "POW R%d R%d R%d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
	elseif op == LuauOpcode.LOP_ADDK then
		formatAppend(result, "ADDK R%d R%d K%d [", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
		self:dumpConstant(result, LUAU_INSN_C(insn))
		result.s ..= "]\n"
	elseif op == LuauOpcode.LOP_SUBK then
		formatAppend(result, "SUBK R%d R%d K%d [", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
		self:dumpConstant(result, LUAU_INSN_C(insn))
		result.s ..= "]\n"
	elseif op == LuauOpcode.LOP_MULK then
		formatAppend(result, "MULK R%d R%d K%d [", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
		self:dumpConstant(result, LUAU_INSN_C(insn))
		result.s ..= "]\n"
	elseif op == LuauOpcode.LOP_DIVK then
		formatAppend(result, "DIVK R%d R%d K%d [", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
		self:dumpConstant(result, LUAU_INSN_C(insn))
		result.s ..= "]\n"
	elseif op == LuauOpcode.LOP_IDIVK then
		formatAppend(result, "IDIVK R%d R%d K%d [", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
		self:dumpConstant(result, LUAU_INSN_C(insn))
		result.s ..= "]\n"
	elseif op == LuauOpcode.LOP_MODK then
		formatAppend(result, "MODK R%d R%d K%d [", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
		self:dumpConstant(result, LUAU_INSN_C(insn))
		result.s ..= "]\n"
	elseif op == LuauOpcode.LOP_POWK then
		formatAppend(result, "POWK R%d R%d K%d [", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
		self:dumpConstant(result, LUAU_INSN_C(insn))
		result.s ..= "]\n"
	elseif op == LuauOpcode.LOP_SUBRK then
		formatAppend(result, "SUBRK R%d K%d [", LUAU_INSN_A(insn), LUAU_INSN_B(insn))
		self:dumpConstant(result, LUAU_INSN_C(insn))
		formatAppend(result, "] R%d\n", LUAU_INSN_C(insn))
	elseif op == LuauOpcode.LOP_DIVRK then
		formatAppend(result, "DIVRK R%d K%d [", LUAU_INSN_A(insn), LUAU_INSN_B(insn))
		self:dumpConstant(result, LUAU_INSN_C(insn))
		formatAppend(result, "] R%d\n", LUAU_INSN_C(insn))
	elseif op == LuauOpcode.LOP_AND then
		formatAppend(result, "AND R%d R%d R%d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
	elseif op == LuauOpcode.LOP_OR then
		formatAppend(result, "OR R%d R%d R%d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
	elseif op == LuauOpcode.LOP_ANDK then
		formatAppend(result, "ANDK R%d R%d K%d [", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
		self:dumpConstant(result, LUAU_INSN_C(insn))
		result.s ..= "]\n"
	elseif op == LuauOpcode.LOP_ORK then
		formatAppend(result, "ORK R%d R%d K%d [", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
		self:dumpConstant(result, LUAU_INSN_C(insn))
		result.s ..= "]\n"
	elseif op == LuauOpcode.LOP_CONCAT then
		formatAppend(result, "CONCAT R%d R%d R%d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn))
	elseif op == LuauOpcode.LOP_NOT then
		formatAppend(result, "NOT R%d R%d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn))
	elseif op == LuauOpcode.LOP_MINUS then
		formatAppend(result, "MINUS R%d R%d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn))
	elseif op == LuauOpcode.LOP_LENGTH then
		formatAppend(result, "LENGTH R%d R%d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn))
	elseif op == LuauOpcode.LOP_NEWTABLE then
		formatAppend(result,
			"NEWTABLE R%d %d %d\n",
			LUAU_INSN_A(insn),
			if LUAU_INSN_B(insn) == 0 then 0 else bit32.lshift(1, LUAU_INSN_B(insn) - 1),
			self.insns:get(code)
		)
		code += 1
	elseif op == LuauOpcode.LOP_DUPTABLE then
		formatAppend(result, "DUPTABLE R%d %d\n", LUAU_INSN_A(insn), LUAU_INSN_D(insn))
	elseif op == LuauOpcode.LOP_SETLIST then
		formatAppend(result, "SETLIST R%d R%d %d [%d]\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn), LUAU_INSN_C(insn) - 1, self.insns:get(code))
		code += 1
	elseif op == LuauOpcode.LOP_FORNPREP then
		formatAppend(result, "FORNPREP R%d L%d\n", LUAU_INSN_A(insn), targetLabel)
	elseif op == LuauOpcode.LOP_FORNLOOP then
		formatAppend(result, "FORNLOOP R%d L%d\n", LUAU_INSN_A(insn), targetLabel)
	elseif op == LuauOpcode.LOP_FORGPREP then
		formatAppend(result, "FORGPREP R%d L%d\n", LUAU_INSN_A(insn), targetLabel)
	elseif op == LuauOpcode.LOP_FORGLOOP then
		formatAppend(
			result,
			"FORGLOOP R%d L%d %d%s\n",
			LUAU_INSN_A(insn),
			targetLabel,
			self.insns:get(code),
			if self.insns:get(code) < 0 then " [inext]" else ""
		)
		code += 1
	elseif op == LuauOpcode.LOP_FORGPREP_INEXT then
		formatAppend(result, "FORGPREP_INEXT R%d L%d\n", LUAU_INSN_A(insn), targetLabel)
	elseif op == LuauOpcode.LOP_FORGPREP_NEXT then
		formatAppend(result, "FORGPREP_NEXT R%d L%d\n", LUAU_INSN_A(insn), targetLabel)
	elseif op == LuauOpcode.LOP_GETVARARGS then
		formatAppend(result, "GETVARARGS R%d %d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn) - 1)
	elseif op == LuauOpcode.LOP_DUPCLOSURE then
		formatAppend(result, "DUPCLOSURE R%d K%d [", LUAU_INSN_A(insn), LUAU_INSN_D(insn))
		self:dumpConstant(result, LUAU_INSN_D(insn))
		result.s ..= "]\n"
	elseif op == LuauOpcode.LOP_BREAK then
		formatAppend(result, "BREAK\n")
	elseif op == LuauOpcode.LOP_JUMPBACK then
		formatAppend(result, "JUMPBACK L%d\n", targetLabel)
	elseif op == LuauOpcode.LOP_LOADKX then
		formatAppend(result, "LOADKX R%d K%d [", LUAU_INSN_A(insn), self.insns:get(code))
		self:dumpConstant(result, self.insns:get(code))
		result.s ..= "]\n"
		code += 1
	elseif op == LuauOpcode.LOP_JUMPX then
		formatAppend(result, "JUMPX L%d\n", targetLabel)
	elseif op == LuauOpcode.LOP_FASTCALL then
		formatAppend(result, "FASTCALL %d L%d\n", LUAU_INSN_A(insn), targetLabel)
	elseif op == LuauOpcode.LOP_FASTCALL1 then
		formatAppend(result, "FASTCALL1 %d R%d L%d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn), targetLabel)
	elseif op == LuauOpcode.LOP_FASTCALL2 then
		formatAppend(result, "FASTCALL2 %d R%d R%d L%d\n", LUAU_INSN_A(insn), LUAU_INSN_B(insn), code, targetLabel)
		code += 1
	elseif op == LuauOpcode.LOP_FASTCALL2K then
		formatAppend(result, "FASTCALL2K %d R%d K%d L%d [", LUAU_INSN_A(insn), LUAU_INSN_B(insn), self.insns:get(code), targetLabel)
		self:dumpConstant(result, self.insns:get(code))
		result.s ..= "]\n"
		code += 1
	elseif op == LuauOpcode.LOP_COVERAGE then
		formatAppend(result, "COVERAGE\n")
	elseif op == LuauOpcode.LOP_CAPTURE then
		formatAppend(
			result,
			"CAPTURE %s %c%d\n",
			if LUAU_INSN_A(insn) == LuauCaptureType.LCT_UPVAL then "UPVAL"
			elseif LUAU_INSN_A(insn) == LuauCaptureType.LCT_REF then "REF"
			elseif LUAU_INSN_A(insn) == LuauCaptureType.LCT_VAL then "VAL"
			else "",
			string.byte(if LUAU_INSN_A(insn) == LuauCaptureType.LCT_UPVAL then "U" else "R"),
			LUAU_INSN_B(insn)
		)
	elseif op == LuauOpcode.LOP_JUMPXEQKNIL then
		formatAppend(result, "JUMPXEQKNIL R%d L%d%s\n", LUAU_INSN_A(insn), targetLabel, if bit32.rshift(self.insns:get(code), 31) ~= 0 then " NOT" else "")
		code += 1
	elseif op == LuauOpcode.LOP_JUMPXEQKB then
		formatAppend(
			result,
			"JUMPXEQKB R%d %d L%d%s\n",
			LUAU_INSN_A(insn),
			bit32.band(self.insns:get(code), 1),
			targetLabel,
			if bit32.rshift(self.insns:get(code), 31) ~= 0 then " NOT" else ""
		)
	elseif op == LuauOpcode.LOP_JUMPXEQKN then
		formatAppend(
			result,
			"JUMPXEQKN R%d K%d L%d%s [",
			LUAU_INSN_A(insn),
			bit32.band(self.insns:get(code), 0xffffff),
			targetLabel,
			if bit32.rshift(self.insns:get(code), 31) ~= 0 then " NOT" else ""
		)
		self:dumpConstant(result, bit32.band(self.insns:get(code), 0xffffff))
		result.s ..= "]\n"
		code += 1
	elseif op == LuauOpcode.LOP_JUMPXEQKS then
		formatAppend(
			result,
			"JUMPXEQKS R%d K%d L%d%s [",
			LUAU_INSN_A(insn),
			bit32.band(self.insns:get(code), 0xffffff),
			targetLabel,
			if bit32.rshift(self.insns:get(code), 31) ~= 0 then " NOT" else ""
		)
		self:dumpConstant(result, bit32.band(self.insns:get(code), 0xffffff))
		result.s ..= "]\n"
		code += 1
	else
		error("Unsupported opcode")
	end
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function BytecodeBuilder.getBaseTypeString(type: number): string
	local tag = bit32.band(type, bit32.bnot(LuauBytecodeType.LBC_TYPE_OPTIONAL_BIT))
	if tag == LuauBytecodeType.LBC_TYPE_NIL then
		return "nil"
	elseif tag == LuauBytecodeType.LBC_TYPE_BOOLEAN then
		return "boolean"
	elseif tag == LuauBytecodeType.LBC_TYPE_NUMBER then
		return "number"
	elseif tag == LuauBytecodeType.LBC_TYPE_STRING then
		return "string"
	elseif tag == LuauBytecodeType.LBC_TYPE_TABLE then
		return "table"
	elseif tag == LuauBytecodeType.LBC_TYPE_FUNCTION then
		return "function"
	elseif tag == LuauBytecodeType.LBC_TYPE_THREAD then
		return "thread"
	elseif tag == LuauBytecodeType.LBC_TYPE_USERDATA then
		return "userdata"
	elseif tag == LuauBytecodeType.LBC_TYPE_VECTOR then
		return "vector"
	elseif tag == LuauBytecodeType.LBC_TYPE_BUFFER then
		return "buffer"
	elseif tag == LuauBytecodeType.LBC_TYPE_ANY then
		return "any"
	end

	error("Unhandled type in getBaseTypeString")
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.dumpCurrentFunction(self: BytecodeBuilder, dumpinstoffs: Vector<number>): string
	if bit32.band(self.dumpFlags, DumpFlags.Dump_Code) == 0 then
		return ""
	end

	local lastLine = -1
	local nextRemark = 0

	local result = {s = ""}

	if bit32.band(self.dumpFlags, DumpFlags.Dump_Locals) ~= 0 then
		for i = 1, self.debugLocals:size() do
			local l = self.debugLocals:get(i)

			if l.startpc == l.endpc then
				LUAU_ASSERT(l.startpc < self.lines:size())

				-- it would be nice to emit name as well but it requires reverse lookup through stringtable
				formatAppend(result, "local %d: reg %d, start pc %d line %d, no live range\n", i - 1, l.reg, l.startpc, self.lines:get(l.startpc))
			else
				LUAU_ASSERT(l.startpc < l.endpc)
				LUAU_ASSERT(l.startpc < self.lines:size())
				LUAU_ASSERT(l.endpc <= self.lines:size()) -- endpc is exclusive in the debug info, but it's more intuitive to print inclusive data

				-- it would be nice to emit name as well but it requires reverse lookup through stringtable
				formatAppend(
					result,
					"local %d: reg %d, start pc %d line %d, end pc %d line %d\n",
					i,
					l.reg,
					l.startpc,
					self.lines:get(l.startpc + 1),
					l.endpc - 1,
					self.lines:get(l.endpc - 1 + 1)
				)
			end
		end
	end

	if FastVariables.LuauCompileTypeInfo then
		if bit32.band(self.dumpFlags, DumpFlags.Dump_Types) ~= 0 then
			local typeinfo = self.functions:back().typeinfo

			if FastVariables.LuauCompileUserdataInfo then
				-- Arguments start from third byte in function typeinfo string
				for i = 2, #typeinfo - 1 do
					local et = string.byte(typeinfo, i + 1)

					local userdata = self:tryGetUserdataTypeName(et)
					local name = if userdata then userdata else BytecodeBuilder.getBaseTypeString(et)
					local optional = if bit32.band(et, LuauBytecodeType.LBC_TYPE_OPTIONAL_BIT) ~= 0 then "?" else ""

					formatAppend(result, "R%d: %s%s [argument]\n", i - 2, name, optional)
				end

				for i = 0, self.typedUpvals:size() - 1 do
					local l = self.typedUpvals:get(i + 1)

					local userdata = self:tryGetUserdataTypeName(l.type)
					local name = if userdata then userdata else BytecodeBuilder.getBaseTypeString(l.type)
					local optional = if bit32.band(l.type, LuauBytecodeType.LBC_TYPE_OPTIONAL_BIT) ~= 0 then "?" else ""

					formatAppend(result, "U%d: %s%s\n", i, name, optional)
				end
				
				for i = 0, self.typedLocals:size() - 1 do
					local l = self.typedLocals:get(i + 1)

					local userdata = self:tryGetUserdataTypeName(l.type)
					local name = if userdata then userdata else BytecodeBuilder.getBaseTypeString(l.type)
					local optional = if bit32.band(l.type, LuauBytecodeType.LBC_TYPE_OPTIONAL_BIT) ~= 0 then "?" else ""

					formatAppend(result, "R%d: %s%s from %d to %d\n", l.reg, name, optional, l.startpc, l.endpc)
				end
			else
				-- Arguments start from third byte in function typeinfo string
				for i = 2, #typeinfo - 1 do
					local et = string.byte(typeinfo, i + 1)

					local base = BytecodeBuilder.getBaseTypeString(et)
					local optional = if bit32.band(et, LuauBytecodeType.LBC_TYPE_OPTIONAL_BIT) ~= 0 then "?" else ""

					formatAppend(result, "R%d: %s%s [argument]\n", i - 2, base, optional)
				end

				for i = 0, self.typedUpvals:size() - 1 do
					local l = self.typedUpvals:get(i + 1)

					local base = BytecodeBuilder.getBaseTypeString(l.type)
					local optional = if bit32.band(l.type, LuauBytecodeType.LBC_TYPE_OPTIONAL_BIT) ~= 0 then "?" else ""

					formatAppend(result, "U%d: %s%s\n", i, base, optional)
				end
				
				for i = 0, self.typedLocals:size() - 1 do
					local l = self.typedLocals:get(i + 1)

					local base = BytecodeBuilder.getBaseTypeString(l.type)
					local optional = if bit32.band(l.type, LuauBytecodeType.LBC_TYPE_OPTIONAL_BIT) ~= 0 then "?" else ""

					formatAppend(result, "R%d: %s%s from %d to %d\n", l.reg, base, optional, l.startpc, l.endpc)
				end
			end
		end
	end

	local labels: Vector<number> = Vector.new(self.insns:size(), -1)

	-- annotate valid jump targets with 0
	local i = 1
	while i <= self.insns:size() do
		local target = getJumpTarget(self.insns:get(i), uint32_t(i - 1))

		if target >= 0 then
			LUAU_ASSERT(target < self.insns:size())
			labels:set(target + 1, 0)
		end

		i += getOpLength(LUAU_INSN_OP(self.insns:get(i)))
		LUAU_ASSERT(i <= self.insns:size() + 1)
	end

	local nextLabel = 0

	-- compute label ids (sequential integers for all jump targets)
	for i = 1, labels:size() do
		if labels:get(i) == 0 then
			labels:set(i, nextLabel)
			nextLabel += 1
		end
	end

	dumpinstoffs:resize(self.insns:size() + 1, -1)

	local i = 1
	while i <= self.insns:size() do
		local code = self.insns:get(i)
		local op = LUAU_INSN_OP(code)

		dumpinstoffs:set(i, int(#result.s))

		if op == LuauOpcode.LOP_PREPVARARGS then
			-- Don't emit function header in bytecode - it's used for call dispatching and doesn't contain "interesting" information
			i += 1
			continue
		end

		if bit32.band(self.dumpFlags, DumpFlags.Dump_Remarks) ~= 0 then
			while nextRemark < self.debugRemarks:size() and self.debugRemarks:get(nextRemark + 1).first == i - 1 do
				-- string.sub(self.debugRemarkBuffer, self.debugRemarks:get(nextRemark + 1).second))
				formatAppend(result, "REMARK %s\n", self.dumpRemarks:get(nextRemark + 1).second)
				nextRemark += 1
			end
		end

		if bit32.band(self.dumpFlags, DumpFlags.Dump_Source) ~= 0 then
			local line = self.lines:get(i)

			if line > 0 and line ~= lastLine then
				LUAU_ASSERT((line - 1) < self.dumpSource:size())
				formatAppend(result, "%5d:  %s\n", line, self.dumpSource:get(line - 1 + 1))
				lastLine = line
			end
		end

		if bit32.band(self.dumpFlags, DumpFlags.Dump_Lines) ~= 0 then
			formatAppend(result, "%d: ", self.lines:get(i))
		end

		if labels:get(i) ~= -1 then
			formatAppend(result, "L%d: ", labels:get(i))
		end

		local target = getJumpTarget(code, uint32_t(i - 1))

		self:dumpInstruction(i, result, if target >= 0 then labels:get(target + 1) else -1)

		i += getOpLength(op)
		LUAU_ASSERT(i <= self.insns:size() + 1)
	end

	dumpinstoffs:set(self.insns:size() + 1, int(#result.s))

	return result.s
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.setDumpSource(self: BytecodeBuilder, source: string): ()
	self.dumpSource:clear()

	local pos: number? = 0

	while pos ~= nil do
		local next = source:find("\n", pos)

		if next == nil then
			self.dumpSource:push_back(source:sub(pos))
			pos = next
		else
			self.dumpSource:push_back(source:sub(pos, pos + (next - pos)))
			pos = next + 1
		end

		if self.dumpSource:back() ~= "" and string.sub(self.dumpSource:back(), -1) == "\r" then
			self.dumpSource:set(self.dumpSource:size(), string.sub(self.dumpSource:back(), 1, -2))
		end
	end
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.dumpFunction(self: BytecodeBuilder, id: number): string
	LUAU_ASSERT(id < self.functions:size())

	return self.functions:get(id + 1).dump
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.dumpEverything(self: BytecodeBuilder): string
	local result = {s = ""}

	for i = 0, self.functions:size() - 1 do
		local debugname = if self.functions:get(i + 1).dumpname == "" then "??" else self.functions:get(i + 1).dumpname
		
		formatAppend(result, "Function %d (%s):\n", i, debugname)

		result.s ..= self.functions:get(i + 1).dump
		result.s ..= "\n"
	end

	return result.s
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.dumpSourceRemarks(self: BytecodeBuilder): string
	local result = {s = ""}

	local nextRemark = 0

	local remarks: {Pair<number, string>} = {}
	table.move(self.dumpRemarks:data(), 1, self.dumpRemarks:size(), 1, remarks)
	table.sort(remarks, function(a, b)
		if a.first == b.first then
			return a.second < b.second
		end
		return a.first < b.first
	end)

	for i = 0, self.dumpSource:size() - 1 do
		local line = self.dumpSource:get(i + 1)

		local indent = 0
		while indent < #line and (string.sub(line, indent + 1, indent + 1) == " " or string.sub(line, indent + 1, indent + 1) == "\t") do
			indent += 1
		end

		while nextRemark < #remarks and remarks[nextRemark + 1].first == int(i + 1) do
			formatAppend(result, "%s-- remark: %s\n", string.sub(line, indent), remarks[nextRemark + 1].second)
			nextRemark += 1

			-- skip duplicate remarks (due to inlining/unrolling)
			while nextRemark < #remarks and remarks[nextRemark + 1] == remarks[nextRemark - 1 + 1] do
				nextRemark += 1
			end
		end

		result.s ..= line

		if i + 1 < self.dumpSource:size() then
			result.s ..= "\n"
		end
	end

	return result.s
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.dumpTypeInfo(self: BytecodeBuilder): string
	local result = {s = ""}

	for i = 0, self.functions:size() - 1 do
		local typeinfo = self.functions:get(i + 1).typeinfo
		if typeinfo == "" then
			continue
		end

		local encodedType = string.byte(typeinfo, 1, 1)

		LUAU_ASSERT(encodedType == LuauBytecodeType.LBC_TYPE_FUNCTION)
		
		formatAppend(result, "%d: function(", i)
		
		LUAU_ASSERT(#typeinfo >= 2)

		local numparams = string.byte(typeinfo, 2, 2)

		LUAU_ASSERT((1 + numparams - 1) < #typeinfo)

		for i = 0, numparams - 1 do
			local et = string.byte(typeinfo, 2 + i + 1, 2 + i + 1)
			local optional = if bit32.band(et, LuauBytecodeType.LBC_TYPE_OPTIONAL_BIT) ~= 0 then "?" else ""
			formatAppend(result, "%s%s", BytecodeBuilder.getBaseTypeString(et), optional)

			if i + 1 ~= numparams then
				formatAppend(result, ", ")
			end
		end

		formatAppend(result, ")\n")
	end

	return result.s
end

--[=[
	@within BytecodeBuilder
	@since v0.1.0
]=]
function prototype.annotateInstruction(self: BytecodeBuilder, result: stringWrap, fid: number, instpos: number): ()
	if bit32.band(self.dumpFlags, DumpFlags.Dump_Code) == 0 then
		return
	end

	LUAU_ASSERT(fid < self.functions:size())

	local func = self.functions:get(fid + 1)
	local dump = func.dump
	local dumpinstoffs = func.dumpinstoffs

	local next = instpos + 1

	LUAU_ASSERT(next < dumpinstoffs:size())

	-- Skip locations of multi-dword instructions
	while next < dumpinstoffs:size() and dumpinstoffs:get(next + 1) == -1 do
		next += 1
	end

	formatAppend(result, "%s", string.sub(
		string.sub(dump, 1, dumpinstoffs:get(instpos + 1)),
		1,
		dumpinstoffs:get(next + 1) - dumpinstoffs:get(instpos + 1)
	))
end

BytecodeBuilder.DumpFlags = DumpFlags
BytecodeBuilder.StringRef = StringRef
BytecodeBuilder.TableShape = TableShape

return BytecodeBuilder