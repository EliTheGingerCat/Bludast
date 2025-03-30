local BytecodeBuilder = require("@Compiler/BytecodeBuilder")
local CompileOptions = require("@Compiler/CompileOptions")
local Compiler = require("@Compiler/Compiler")
local DebugFlags = require("@Shared/DebugFlags")
local LuauBuiltinFunction = require("@Common/Bytecode/LuauBuiltinFunction")
local LuauBytecodeTag = require("@Common/Bytecode/LuauBytecodeTag")
local LuauBytecodeType = require("@Common/Bytecode/LuauBytecodeType")
local LuauCaptureType = require("@Common/Bytecode/LuauCaptureType")
local LuauOpcode = require("@Common/Bytecode/LuauOpcode")

local DumpFlags = BytecodeBuilder.DumpFlags

DebugFlags.AssertEnabled = true

local function compileFunction(source: string, id: number, optimizationLevel: number?, enableVectors: boolean?): string
	local bcb = BytecodeBuilder.new()
	bcb:setDumpFlags(DumpFlags.Dump_Code)
	local options = CompileOptions.new()
	options.optimizationLevel = optimizationLevel or 1
	if enableVectors then
		options.vectorLib = "Vector3"
		options.vectorCtor = "new"
	end
	Compiler.compileOrThrow(bcb, source, options)

	return bcb:dumpFunction(id)
end

local function compileFunction0(source: string): string
	local bcb = BytecodeBuilder.new()
	bcb:setDumpFlags(DumpFlags.Dump_Code)
	Compiler.compileOrThrow(bcb, source)

	return bcb:dumpFunction(0)
end

local function compileFunction0Coverage(source: string, level: number): string
	local bcb = BytecodeBuilder.new()
	bcb:setDumpFlags(bit32.bor(DumpFlags.Dump_Code, DumpFlags.Dump_Lines))

	local opts = CompileOptions.new()
	opts.coverageLevel = level
	Compiler.compileOrThrow(bcb, source, opts)

	return bcb:dumpFunction(0)
end

local function compileTypeTable(source: string): string
	local bcb = BytecodeBuilder.new()
	bcb:setDumpFlags(DumpFlags.Dump_Code)

	local opts = CompileOptions.new()
	opts.vectorType = "Vector3"
	opts.typeInfoLevel = 1
	Compiler.compileOrThrow(bcb, source, opts)

	return bcb:dumpTypeInfo()
end

return {
	BytecodeIsStable = function()
		-- As noted in Bytecode.h, all enums used for bytecode storage and serialization are order-sensitive
		-- Adding entries in the middle will typically pass the tests but break compatibility
		-- This test codifies this by validating that in each enum, the last (or close-to-last) entry has a fixed encoding

		-- This test will need to get occasionally revised to "move" the checked enum entries forward as we ship newer versions
		-- When doing so, please add *new* checks for more recent bytecode versions and keep existing checks in place.

		-- Bytecode ops (serialized & in-memory)
		assert(LuauOpcode.LOP_FASTCALL2K == 75) -- bytecode v1
		assert(LuauOpcode.LOP_JUMPXEQKS == 80)  -- bytecode v3
		
		-- Bytecode fastcall ids (serialized & in-memory)
		-- Note: these aren't strictly bound to specific bytecode versions, but must monotonically increase to keep backwards compat
		assert(LuauBuiltinFunction.LBF_VECTOR == 54)
		assert(LuauBuiltinFunction.LBF_TOSTRING == 63)

		-- Bytecode capture type (serialized & in-memory)
		assert(LuauCaptureType.LCT_UPVAL == 2) -- bytecode v1

		-- Bytecode constants (serialized)
		assert(LuauBytecodeTag.LBC_CONSTANT_CLOSURE == 6) -- bytecode v1

		-- Bytecode type encoding (serialized & in-memory)
		-- Note: these *can* change retroactively *if* type version is bumped, but probably shouldn't
		assert(LuauBytecodeType.LBC_TYPE_BUFFER == 9) -- type version 1
	end,

	CompileToBytecode = function()
		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(DumpFlags.Dump_Code)
		Compiler.compileOrThrow(bcb, "return 5, 6.5")

		assert(bcb:dumpFunction(0) == [[
LOADN R0 5
LOADK R1 K0 [6.5]
RETURN R0 2
]])

		assert(bcb:dumpEverything() == [[
Function 0 (??):
LOADN R0 5
LOADK R1 K0 [6.5]
RETURN R0 2

]])
	end,

	CompileError = function()
		local source = "local " .. string.rep("a,", 300) .. "a = ..."

		-- fails to parse
		local bc1 = Compiler.compile(source .. " !#*$!#$^&!*#&$^*")

		-- parses, but fails to compile (too many locals)
		local bc2 = Compiler.compile(source)
		
		-- 0 acts as a special marker for error bytecode
		assert(string.sub(bc1, 1, 1) == "\0")
		assert(string.sub(bc2, 1, 1) == "\0")
	end,

	LocalsDirectReference = function()
		assert(compileFunction0("local a return a") == [[
LOADNIL R0
RETURN R0 1
]])
	end,

	BasicFunction = function()
		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(DumpFlags.Dump_Code)
		Compiler.compileOrThrow(bcb, "local function foo(a, b) return b end")

		assert(bcb:dumpFunction(1) == [[
DUPCLOSURE R0 K0 ['foo']
RETURN R0 0
]])

		assert(bcb:dumpFunction(0) == [[
RETURN R1 1
]])
	end,

	BasicFunctionCall = function()
		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(DumpFlags.Dump_Code)
		Compiler.compileOrThrow(bcb, "local function foo(a, b) return b end function test() return foo(2) end")

		assert(bcb:dumpFunction(1) == [[
GETUPVAL R0 0
LOADN R1 2
CALL R0 1 -1
RETURN R0 -1
]])
	end,

	FunctionCallOptimization = function()
		-- direct call into local
		assert(compileFunction0("local foo = math.foo()") == [[
GETIMPORT R0 2 [math.foo]
CALL R0 0 1
RETURN R0 0
]])

		-- direct call into temp
		assert(compileFunction0("local foo = math.foo(math.bar())") == [[
GETIMPORT R0 2 [math.foo]
GETIMPORT R1 4 [math.bar]
CALL R1 0 -1
CALL R0 -1 1
RETURN R0 0
]])

		-- can't directly call into local since foo might be used as arguments of caller
		assert(compileFunction0("local foo foo = math.foo(foo)") == [[
LOADNIL R0
GETIMPORT R1 2 [math.foo]
MOVE R2 R0
CALL R1 1 1
MOVE R0 R1
RETURN R0 0
]])
	end,

	ReflectionBytecode = function()
		assert(compileFunction0([[
local part = Instance.new('Part', workspace)
part.Size = Vector3.new(1, 2, 3)
return part.Size.Z * part:GetMass()
]]) == [[
GETIMPORT R0 2 [Instance.new]
LOADK R1 K3 ['Part']
GETIMPORT R2 5 [workspace]
CALL R0 2 1
GETIMPORT R1 7 [Vector3.new]
LOADN R2 1
LOADN R3 2
LOADN R4 3
CALL R1 3 1
SETTABLEKS R1 R0 K8 ['Size']
GETTABLEKS R3 R0 K8 ['Size']
GETTABLEKS R2 R3 K9 ['Z']
NAMECALL R3 R0 K10 ['GetMass']
CALL R3 1 1
MUL R1 R2 R3
RETURN R1 1
]])
	end,

	ImportCall = function()
		assert(compileFunction0("return math.max(1, 2)") == [[
LOADN R1 1
FASTCALL2K 18 R1 K0 L0 [2]
LOADK R2 K0 [2]
GETIMPORT R0 3 [math.max]
CALL R0 2 -1
L0: RETURN R0 -1
]])
	end,

	FakeImportCall = function()
		local source = "math = {} function math.max() return 0 end function test() return math.max(1, 2) end"

		assert(compileFunction(source, 1) == [[
GETGLOBAL R1 K0 ['math']
GETTABLEKS R0 R1 K1 ['max']
LOADN R1 1
LOADN R2 2
CALL R0 2 -1
RETURN R0 -1
]])
	end,

	AssignmentLocal = function()
		assert(compileFunction0("local a a = 2") == [[
LOADNIL R0
LOADN R0 2
RETURN R0 0
]])
	end,

	AssignmentGlobal = function()
		assert(compileFunction0("a = 2") == [[
LOADN R0 2
SETGLOBAL R0 K0 ['a']
RETURN R0 0
]])
	end,

	AssignmentTable = function()
		local source = "local c = ... local a = {} a.b = 2 a.b = c"

		assert(compileFunction0(source) == [[
GETVARARGS R0 1
NEWTABLE R1 1 0
LOADN R2 2
SETTABLEKS R2 R1 K0 ['b']
SETTABLEKS R0 R1 K0 ['b']
RETURN R0 0
]])
	end,

	ConcatChainOptimization = function()
		assert(compileFunction0("return '1' .. '2'") == [[
LOADK R1 K0 ['1']
LOADK R2 K1 ['2']
CONCAT R0 R1 R2
RETURN R0 1
]])

		assert(compileFunction0("return '1' .. '2' .. '3'") == [[
LOADK R1 K0 ['1']
LOADK R2 K1 ['2']
LOADK R3 K2 ['3']
CONCAT R0 R1 R3
RETURN R0 1
]])

		assert(compileFunction0("return ('1' .. '2') .. '3'") == [[
LOADK R3 K0 ['1']
LOADK R4 K1 ['2']
CONCAT R1 R3 R4
LOADK R2 K2 ['3']
CONCAT R0 R1 R2
RETURN R0 1
]])
	end,

	RepeatLocals = function()
		assert(compileFunction0("repeat local a a = 5 until a - 4 < 0 or a - 4 >= 0") == [[
L0: LOADNIL R0
LOADN R0 5
SUBK R1 R0 K0 [4]
LOADN R2 0
JUMPIFLT R1 R2 L1
SUBK R1 R0 K0 [4]
LOADN R2 0
JUMPIFLE R2 R1 L1
JUMPBACK L0
L1: RETURN R0 0
]])
	end,

	ForBytecode = function()
		-- basic for loop: variable directly refers to internal iteration index (R2)
		assert(compileFunction0("for i=1,5 do print(i) end") == [[
LOADN R2 1
LOADN R0 5
LOADN R1 1
FORNPREP R0 L1
L0: GETIMPORT R3 1 [print]
MOVE R4 R2
CALL R3 1 0
FORNLOOP R0 L0
L1: RETURN R0 0
]])

		-- when you assign the variable internally, we freak out and copy the variable so that you aren't changing the loop behavior
		assert(compileFunction0("for i=1,5 do i = 7 print(i) end") == [[
LOADN R2 1
LOADN R0 5
LOADN R1 1
FORNPREP R0 L1
L0: MOVE R3 R2
LOADN R3 7
GETIMPORT R4 1 [print]
MOVE R5 R3
CALL R4 1 0
FORNLOOP R0 L0
L1: RETURN R0 0
]])

		-- basic for-in loop, generic version
		assert(compileFunction0("for word in string.gmatch(\"Hello Lua user\", \"%a+\") do print(word) end") == [[
GETIMPORT R0 2 [string.gmatch]
LOADK R1 K3 ['Hello Lua user']
LOADK R2 K4 ['%a+']
CALL R0 2 3
FORGPREP R0 L1
L0: GETIMPORT R5 6 [print]
MOVE R6 R3
CALL R5 1 0
L1: FORGLOOP R0 L0 1
RETURN R0 0
]])

		-- basic for-in loop, using inext specialization
		assert(compileFunction0("for k,v in ipairs({}) do print(k,v) end") == [[
GETIMPORT R0 1 [ipairs]
NEWTABLE R1 0 0
CALL R0 1 3
FORGPREP_INEXT R0 L1
L0: GETIMPORT R5 3 [print]
MOVE R6 R3
MOVE R7 R4
CALL R5 2 0
L1: FORGLOOP R0 L0 2 [inext]
RETURN R0 0
]])

		-- basic for-in loop, using next specialization
		assert(compileFunction0("for k,v in pairs({}) do print(k,v) end") == [[
GETIMPORT R0 1 [pairs]
NEWTABLE R1 0 0
CALL R0 1 3
FORGPREP_NEXT R0 L1
L0: GETIMPORT R5 3 [print]
MOVE R6 R3
MOVE R7 R4
CALL R5 2 0
L1: FORGLOOP R0 L0 2
RETURN R0 0
]])

		assert(compileFunction0("for k,v in next,{} do print(k,v) end") == [[
GETIMPORT R0 1 [next]
NEWTABLE R1 0 0
LOADNIL R2
FORGPREP_NEXT R0 L1
L0: GETIMPORT R5 3 [print]
MOVE R6 R3
MOVE R7 R4
CALL R5 2 0
L1: FORGLOOP R0 L0 2
RETURN R0 0
]])
	end,

	ForBytecodeBuiltin = function()
		-- we generally recognize builtins like pairs/ipairs and emit special opcodes
		assert(compileFunction0("for k,v in ipairs({}) do end") == [[
GETIMPORT R0 1 [ipairs]
NEWTABLE R1 0 0
CALL R0 1 3
FORGPREP_INEXT R0 L0
L0: FORGLOOP R0 L0 2 [inext]
RETURN R0 0
]])

		-- ... even if they are using a local variable
		assert(compileFunction0("local ip = ipairs for k,v in ip({}) do end") == [[
GETIMPORT R0 1 [ipairs]
MOVE R1 R0
NEWTABLE R2 0 0
CALL R1 1 3
FORGPREP_INEXT R1 L0
L0: FORGLOOP R1 L0 2 [inext]
RETURN R0 0
]])

		-- ... even when it's an upvalue
		assert(compileFunction0("local ip = ipairs function foo() for k,v in ip({}) do end end") == [[
GETUPVAL R0 0
NEWTABLE R1 0 0
CALL R0 1 3
FORGPREP_INEXT R0 L0
L0: FORGLOOP R0 L0 2 [inext]
RETURN R0 0
]])

		-- but if it's reassigned then all bets are off
		assert(compileFunction0("local ip = ipairs ip = pairs for k,v in ip({}) do end") == [[
GETIMPORT R0 1 [ipairs]
GETIMPORT R0 3 [pairs]
MOVE R1 R0
NEWTABLE R2 0 0
CALL R1 1 3
FORGPREP R1 L0
L0: FORGLOOP R1 L0 2
RETURN R0 0
]])

		-- or if the global is hijacked
		assert(compileFunction0("ipairs = pairs for k,v in ipairs({}) do end") == [[
GETIMPORT R0 1 [pairs]
SETGLOBAL R0 K2 ['ipairs']
GETGLOBAL R0 K2 ['ipairs']
NEWTABLE R1 0 0
CALL R0 1 3
FORGPREP R0 L0
L0: FORGLOOP R0 L0 2
RETURN R0 0
]])

		-- or if we don't even know the global to begin with
		assert(compileFunction0("for k,v in unknown({}) do end") == [[
GETIMPORT R0 1 [unknown]
NEWTABLE R1 0 0
CALL R0 1 3
FORGPREP R0 L0
L0: FORGLOOP R0 L0 2
RETURN R0 0
]])
	end,
	
	TableLiterals = function()
		-- empty table, note it's computed directly to target
		assert(compileFunction0("return {}") == [[
NEWTABLE R0 0 0
RETURN R0 1
]])

		-- we can't compute directly to target since that'd overwrite the local
		assert(compileFunction0("local a a = {a} return a") == [[
LOADNIL R0
NEWTABLE R1 0 1
MOVE R2 R0
SETLIST R1 R2 1 [1]
MOVE R0 R1
RETURN R0 1
]])

		-- short list
		assert(compileFunction0("return {1,2,3}") == [[
NEWTABLE R0 0 3
LOADN R1 1
LOADN R2 2
LOADN R3 3
SETLIST R0 R1 3 [1]
RETURN R0 1
]])

		-- long list, split into two chunks
		assert(compileFunction0("return {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17}") == [[
NEWTABLE R0 0 17
LOADN R1 1
LOADN R2 2
LOADN R3 3
LOADN R4 4
LOADN R5 5
LOADN R6 6
LOADN R7 7
LOADN R8 8
LOADN R9 9
LOADN R10 10
LOADN R11 11
LOADN R12 12
LOADN R13 13
LOADN R14 14
LOADN R15 15
LOADN R16 16
SETLIST R0 R1 16 [1]
LOADN R1 17
SETLIST R0 R1 1 [17]
RETURN R0 1
]])

		-- varargs; -1 indicates multret treatment; note that we don't allocate space for the ...
		assert(compileFunction0("return {...}") == [[
NEWTABLE R0 0 0
GETVARARGS R1 -1
SETLIST R0 R1 -1 [1]
RETURN R0 1
]])

		-- varargs with other elements; -1 indicates multret treatment; note that we don't allocate space for the ...
		assert(compileFunction0("return {1,2,3,...}") == [[
NEWTABLE R0 0 3
LOADN R1 1
LOADN R2 2
LOADN R3 3
GETVARARGS R4 -1
SETLIST R0 R1 -1 [1]
RETURN R0 1
]])

		-- basic literals; note that we use DUPTABLE instead of NEWTABLE
		assert(compileFunction0("return {a=1,b=2,c=3}") == [[
DUPTABLE R0 3
LOADN R1 1
SETTABLEKS R1 R0 K0 ['a']
LOADN R1 2
SETTABLEKS R1 R0 K1 ['b']
LOADN R1 3
SETTABLEKS R1 R0 K2 ['c']
RETURN R0 1
]])

		-- literals+array
		assert(compileFunction0("return {a=1,b=2,3,4}") == [[
NEWTABLE R0 2 2
LOADN R3 1
SETTABLEKS R3 R0 K0 ['a']
LOADN R3 2
SETTABLEKS R3 R0 K1 ['b']
LOADN R1 3
LOADN R2 4
SETLIST R0 R1 2 [1]
RETURN R0 1
]])

		-- expression assignment
		assert(compileFunction0("a = 7 return {[a]=42}") == [[
LOADN R0 7
SETGLOBAL R0 K0 ['a']
NEWTABLE R0 1 0
GETGLOBAL R1 K0 ['a']
LOADN R2 42
SETTABLE R2 R0 R1
RETURN R0 1
]])

		-- table template caching; two DUPTABLES out of three use the same slot. Note that caching is order dependent
		assert(compileFunction0("return {a=1,b=2},{b=3,a=4},{a=5,b=6}") == [[
DUPTABLE R0 2
LOADN R1 1
SETTABLEKS R1 R0 K0 ['a']
LOADN R1 2
SETTABLEKS R1 R0 K1 ['b']
DUPTABLE R1 3
LOADN R2 3
SETTABLEKS R2 R1 K1 ['b']
LOADN R2 4
SETTABLEKS R2 R1 K0 ['a']
DUPTABLE R2 2
LOADN R3 5
SETTABLEKS R3 R2 K0 ['a']
LOADN R3 6
SETTABLEKS R3 R2 K1 ['b']
RETURN R0 3
]])
	end,

	TableLiteralsNumberIndex = function()
		-- tables with [x] compile to SETTABLEN if the index is short
		assert(compileFunction0("return {[2] = 2, [256] = 256, [0] = 0, [257] = 257}") == [[
NEWTABLE R0 4 0
LOADN R1 2
SETTABLEN R1 R0 2
LOADN R1 256
SETTABLEN R1 R0 256
LOADN R1 0
LOADN R2 0
SETTABLE R2 R0 R1
LOADN R1 257
LOADN R2 257
SETTABLE R2 R0 R1
RETURN R0 1
]])

		-- when index chain starts with 0, or isn't sequential, we disable the optimization
		assert(compileFunction0("return {[0] = 0, [1] = 1, [2] = 2, [42] = 42}") == [[
NEWTABLE R0 4 0
LOADN R1 0
LOADN R2 0
SETTABLE R2 R0 R1
LOADN R1 1
SETTABLEN R1 R0 1
LOADN R1 2
SETTABLEN R1 R0 2
LOADN R1 42
SETTABLEN R1 R0 42
RETURN R0 1
]])

		-- we disable this optimization when the table has list elements for simplicity
		assert(compileFunction0("return {[1] = 1, [2] = 2, 3}") == [[
NEWTABLE R0 2 1
LOADN R2 1
SETTABLEN R2 R0 1
LOADN R2 2
SETTABLEN R2 R0 2
LOADN R1 3
SETLIST R0 R1 1 [1]
RETURN R0 1
]])

		-- we can also correctly predict the array length for mixed tables
		assert(compileFunction0("return {key = 1, value = 2, [1] = 42}") == [[
NEWTABLE R0 2 1
LOADN R1 1
SETTABLEKS R1 R0 K0 ['key']
LOADN R1 2
SETTABLEKS R1 R0 K1 ['value']
LOADN R1 42
SETTABLEN R1 R0 1
RETURN R0 1
]])
	end,

	TableLiteralsIndexConstant = function()
		-- validate that we use SETTTABLEKS for constant variable keys
		assert(compileFunction0([[
        local a, b = "key", "value"
        return {[a] = 42, [b] = 0}
		]]) == [[
NEWTABLE R0 2 0
LOADN R1 42
SETTABLEKS R1 R0 K0 ['key']
LOADN R1 0
SETTABLEKS R1 R0 K1 ['value']
RETURN R0 1
]])

		-- validate that we use SETTABLEN for constant variable keys *and* that we predict array size
		assert(compileFunction0([[
        local a, b = 1, 2
        return {[a] = 42, [b] = 0}
		]]) == [[
NEWTABLE R0 0 2
LOADN R1 42
SETTABLEN R1 R0 1
LOADN R1 0
SETTABLEN R1 R0 2
RETURN R0 1
]])
	end,

	TableSizePredictionBasic = function()
		assert(compileFunction0([[
local t = {}
t.a = 1
t.b = 1
t.c = 1
t.d = 1
t.e = 1
t.f = 1
t.g = 1
t.h = 1
t.i = 1
]]) == [[
NEWTABLE R0 16 0
LOADN R1 1
SETTABLEKS R1 R0 K0 ['a']
LOADN R1 1
SETTABLEKS R1 R0 K1 ['b']
LOADN R1 1
SETTABLEKS R1 R0 K2 ['c']
LOADN R1 1
SETTABLEKS R1 R0 K3 ['d']
LOADN R1 1
SETTABLEKS R1 R0 K4 ['e']
LOADN R1 1
SETTABLEKS R1 R0 K5 ['f']
LOADN R1 1
SETTABLEKS R1 R0 K6 ['g']
LOADN R1 1
SETTABLEKS R1 R0 K7 ['h']
LOADN R1 1
SETTABLEKS R1 R0 K8 ['i']
RETURN R0 0
]])

		assert(compileFunction0([[
local t = {}
t.x = 1
t.x = 2
t.x = 3
t.x = 4
t.x = 5
t.x = 6
t.x = 7
t.x = 8
t.x = 9
]]) == [[
NEWTABLE R0 1 0
LOADN R1 1
SETTABLEKS R1 R0 K0 ['x']
LOADN R1 2
SETTABLEKS R1 R0 K0 ['x']
LOADN R1 3
SETTABLEKS R1 R0 K0 ['x']
LOADN R1 4
SETTABLEKS R1 R0 K0 ['x']
LOADN R1 5
SETTABLEKS R1 R0 K0 ['x']
LOADN R1 6
SETTABLEKS R1 R0 K0 ['x']
LOADN R1 7
SETTABLEKS R1 R0 K0 ['x']
LOADN R1 8
SETTABLEKS R1 R0 K0 ['x']
LOADN R1 9
SETTABLEKS R1 R0 K0 ['x']
RETURN R0 0
]])

		assert(compileFunction0([[
local t = {}
t[1] = 1
t[2] = 1
t[3] = 1
t[4] = 1
t[5] = 1
t[6] = 1
t[7] = 1
t[8] = 1
t[9] = 1
t[10] = 1
]]) == [[
NEWTABLE R0 0 10
LOADN R1 1
SETTABLEN R1 R0 1
LOADN R1 1
SETTABLEN R1 R0 2
LOADN R1 1
SETTABLEN R1 R0 3
LOADN R1 1
SETTABLEN R1 R0 4
LOADN R1 1
SETTABLEN R1 R0 5
LOADN R1 1
SETTABLEN R1 R0 6
LOADN R1 1
SETTABLEN R1 R0 7
LOADN R1 1
SETTABLEN R1 R0 8
LOADN R1 1
SETTABLEN R1 R0 9
LOADN R1 1
SETTABLEN R1 R0 10
RETURN R0 0
]])
	end,

	TableSizePredictionObject = function()
		assert(compileFunction([[
local t = {}
t.field = 1
function t:getfield()
    return self.field
end
return t
]], 1) == [[
NEWTABLE R0 2 0
LOADN R1 1
SETTABLEKS R1 R0 K0 ['field']
DUPCLOSURE R1 K1 ['getfield']
SETTABLEKS R1 R0 K2 ['getfield']
RETURN R0 1
]])
	end,

	TableSizePredictionSetMetatable = function()
		assert(compileFunction0([[
local t = setmetatable({}, nil)
t.field1 = 1
t.field2 = 2
return t
]]) == [[
NEWTABLE R1 2 0
FASTCALL2K 61 R1 K0 L0 [nil]
LOADK R2 K0 [nil]
GETIMPORT R0 2 [setmetatable]
CALL R0 2 1
L0: LOADN R1 1
SETTABLEKS R1 R0 K3 ['field1']
LOADN R1 2
SETTABLEKS R1 R0 K4 ['field2']
RETURN R0 1
]])
	end,

	TableSizePredictionLoop = function()
		assert(compileFunction0([[
local t = {}
for i=1,4 do
    t[i] = 0
end
return t
]]) == [[
NEWTABLE R0 0 4
LOADN R3 1
LOADN R1 4
LOADN R2 1
FORNPREP R1 L1
L0: LOADN R4 0
SETTABLE R4 R0 R3
FORNLOOP R1 L0
L1: RETURN R0 1
]])
	end,

	ReflectionEnums = function()
		assert(compileFunction0("return Enum.EasingStyle.Linear") == [[
GETIMPORT R0 3 [Enum.EasingStyle.Linear]
RETURN R0 1
]])
	end,

	CaptureSelf = function()
		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(DumpFlags.Dump_Code)
		Compiler.compileOrThrow(bcb, [[
local MaterialsListClass = {}

function MaterialsListClass:_MakeToolTip(guiElement, text)
    local function updateTooltipPosition()
        self._tweakingTooltipFrame = 5
    end

    updateTooltipPosition()
end

return MaterialsListClass
]])

		assert(bcb:dumpFunction(1) == [[
NEWCLOSURE R3 P0
CAPTURE VAL R0
MOVE R4 R3
CALL R4 0 0
RETURN R0 0
]])

		assert(bcb:dumpFunction(0) == [[
GETUPVAL R0 0
LOADN R1 5
SETTABLEKS R1 R0 K0 ['_tweakingTooltipFrame']
RETURN R0 0
]])
	end,

	ConditionalBasic = function()
		assert(compileFunction0("local a = ... if a then return 5 end") == [[
GETVARARGS R0 1
JUMPIFNOT R0 L0
LOADN R1 5
RETURN R1 1
L0: RETURN R0 0
]])

		assert(compileFunction0("local a = ... if not a then return 5 end") == [[
GETVARARGS R0 1
JUMPIF R0 L0
LOADN R1 5
RETURN R1 1
L0: RETURN R0 0
]])
	end,

	ConditionalCompare = function()
		assert(compileFunction0("local a, b = ... if a < b then return 5 end") == [[
GETVARARGS R0 2
JUMPIFNOTLT R0 R1 L0
LOADN R2 5
RETURN R2 1
L0: RETURN R0 0
]])

		assert(compileFunction0("local a, b = ... if a <= b then return 5 end") == [[
GETVARARGS R0 2
JUMPIFNOTLE R0 R1 L0
LOADN R2 5
RETURN R2 1
L0: RETURN R0 0
]])

		assert(compileFunction0("local a, b = ... if a > b then return 5 end") == [[
GETVARARGS R0 2
JUMPIFNOTLT R1 R0 L0
LOADN R2 5
RETURN R2 1
L0: RETURN R0 0
]])


		assert(compileFunction0("local a, b = ... if a >= b then return 5 end") == [[
GETVARARGS R0 2
JUMPIFNOTLE R1 R0 L0
LOADN R2 5
RETURN R2 1
L0: RETURN R0 0
]])

		assert(compileFunction0("local a, b = ... if a == b then return 5 end") == [[
GETVARARGS R0 2
JUMPIFNOTEQ R0 R1 L0
LOADN R2 5
RETURN R2 1
L0: RETURN R0 0
]])

		assert(compileFunction0("local a, b = ... if a ~= b then return 5 end") == [[
GETVARARGS R0 2
JUMPIFEQ R0 R1 L0
LOADN R2 5
RETURN R2 1
L0: RETURN R0 0
]])
	end,

	ConditionalNot = function()
		assert(compileFunction0("local a, b = ... if not (not (a < b)) then return 5 end") == [[
GETVARARGS R0 2
JUMPIFNOTLT R0 R1 L0
LOADN R2 5
RETURN R2 1
L0: RETURN R0 0
]])

		assert(compileFunction0("local a, b = ... if not (not (not (a < b))) then return 5 end") == [[
GETVARARGS R0 2
JUMPIFLT R0 R1 L0
LOADN R2 5
RETURN R2 1
L0: RETURN R0 0
]])
	end,

	ConditionalAndOr = function()
		assert(compileFunction0("local a, b, c = ... if a < b and b < c then return 5 end") == [[
GETVARARGS R0 3
JUMPIFNOTLT R0 R1 L0
JUMPIFNOTLT R1 R2 L0
LOADN R3 5
RETURN R3 1
L0: RETURN R0 0
]])

		assert(compileFunction0("local a, b, c = ... if a < b or b < c then return 5 end") == [[
GETVARARGS R0 3
JUMPIFLT R0 R1 L0
JUMPIFNOTLT R1 R2 L1
L0: LOADN R3 5
RETURN R3 1
L1: RETURN R0 0
]])

		assert(compileFunction0("local a,b,c,d = ... if (a or b) and not (c and d) then return 5 end") == [[
GETVARARGS R0 4
JUMPIF R0 L0
JUMPIFNOT R1 L2
L0: JUMPIFNOT R2 L1
JUMPIF R3 L2
L1: LOADN R4 5
RETURN R4 1
L2: RETURN R0 0
]])

		assert(compileFunction0("local a,b,c = ... if a or not b or c then return 5 end") == [[
GETVARARGS R0 3
JUMPIF R0 L0
JUMPIFNOT R1 L0
JUMPIFNOT R2 L1
L0: LOADN R3 5
RETURN R3 1
L1: RETURN R0 0
]])

		assert(compileFunction0("local a,b,c = ... if a and not b and c then return 5 end") == [[
GETVARARGS R0 3
JUMPIFNOT R0 L0
JUMPIF R1 L0
JUMPIFNOT R2 L0
LOADN R3 5
RETURN R3 1
L0: RETURN R0 0
]])
	end,

	AndOr = function()
		-- codegen for constant, local, global for and
		assert(compileFunction0("local a = 1 a = a and 2 return a") == [[
LOADN R0 1
ANDK R0 R0 K0 [2]
RETURN R0 1
]])

		assert(compileFunction0("local a = 1 local b = ... a = a and b return a") == [[
LOADN R0 1
GETVARARGS R1 1
AND R0 R0 R1
RETURN R0 1
]])

		assert(compileFunction0("local a = 1 b = 2 a = a and b return a") == [[
LOADN R0 1
LOADN R1 2
SETGLOBAL R1 K0 ['b']
MOVE R1 R0
JUMPIFNOT R1 L0
GETGLOBAL R1 K0 ['b']
L0: MOVE R0 R1
RETURN R0 1
]])

		-- codegen for constant, local, global for or
		assert(compileFunction0("local a = 1 a = a or 2 return a") == [[
LOADN R0 1
ORK R0 R0 K0 [2]
RETURN R0 1
]])

		assert(compileFunction0("local a = 1 local b = ... a = a or b return a") == [[
LOADN R0 1
GETVARARGS R1 1
OR R0 R0 R1
RETURN R0 1
]])

		assert(compileFunction0("local a = 1 b = 2 a = a or b return a") == [[
LOADN R0 1
LOADN R1 2
SETGLOBAL R1 K0 ['b']
MOVE R1 R0
JUMPIF R1 L0
GETGLOBAL R1 K0 ['b']
L0: MOVE R0 R1
RETURN R0 1
]])

		-- codegen without a temp variable for and/or when we know we can assign directly into the target register
		-- note: `a = a` assignment is to disable constant folding for testing purposes
		assert(compileFunction0("local a = 1 a = a b = 2 local c = a and b return c") == [[
LOADN R0 1
LOADN R1 2
SETGLOBAL R1 K0 ['b']
MOVE R1 R0
JUMPIFNOT R1 L0
GETGLOBAL R1 K0 ['b']
L0: RETURN R1 1
]])

		assert(compileFunction0("local a = 1 a = a b = 2 local c = a or b return c") == [[
LOADN R0 1
LOADN R1 2
SETGLOBAL R1 K0 ['b']
MOVE R1 R0
JUMPIF R1 L0
GETGLOBAL R1 K0 ['b']
L0: RETURN R1 1
]])
	end,

	AndOrFoldLeft = function()
		-- constant folding and/or expression is possible even if just the left hand is constant
		assert(compileFunction0("local a = false return a and b") == [[
LOADB R0 0
RETURN R0 1
]])

		assert(compileFunction0("local a = true return a or b") == [[
LOADB R0 1
RETURN R0 1
]])

		-- if right hand side is constant we can't constant fold the entire expression
		assert(compileFunction0("local a = false return b and a") == [[
GETIMPORT R1 2 [b]
ANDK R0 R1 K0 [false]
RETURN R0 1
]])

		assert(compileFunction0("local a = true return b or a") == [[
GETIMPORT R1 2 [b]
ORK R0 R1 K0 [true]
RETURN R0 1
]])
	end,

	AndOrChainCodegen = function()
		local source = [[
    return
        (1 - verticalGradientTurbulence < waterLevel + .015 and Enum.Material.Sand)
        or (sandbank>0 and sandbank<1 and Enum.Material.Sand)--this for canyonbase sandbanks
        or Enum.Material.Sandstone
    ]]

		assert(compileFunction0(source) == [[
GETIMPORT R2 2 [verticalGradientTurbulence]
SUBRK R1 K0 [1] R2
GETIMPORT R3 5 [waterLevel]
ADDK R2 R3 K3 [0.014999999999999999]
JUMPIFNOTLT R1 R2 L0
GETIMPORT R0 9 [Enum.Material.Sand]
JUMPIF R0 L2
L0: GETIMPORT R1 11 [sandbank]
LOADN R2 0
JUMPIFNOTLT R2 R1 L1
GETIMPORT R1 11 [sandbank]
LOADN R2 1
JUMPIFNOTLT R1 R2 L1
GETIMPORT R0 9 [Enum.Material.Sand]
JUMPIF R0 L2
L1: GETIMPORT R0 13 [Enum.Material.Sandstone]
L2: RETURN R0 1
]])
	end,

	IfElseExpression = function()
		-- codegen for a true constant condition
		assert(compileFunction0("return if true then 10 else 20") == [[
LOADN R0 10
RETURN R0 1
]])

		-- codegen for a false constant condition
		assert(compileFunction0("return if false then 10 else 20") == [[
LOADN R0 20
RETURN R0 1
]])

		-- codegen for a true constant condition with non-constant expressions
		assert(compileFunction0("return if true then {} else error()") == [[
NEWTABLE R0 0 0
RETURN R0 1
]])

		-- codegen for a false constant condition with non-constant expressions
		assert(compileFunction0("return if false then error() else {}") == [[
NEWTABLE R0 0 0
RETURN R0 1
]])

		--  codegen for a false (in this case 'nil') constant condition
		assert(compileFunction0("return if nil then 10 else 20") == [[
LOADN R0 20
RETURN R0 1
]])

		-- codegen constant if-else expression used with a binary operation involving another constant
		-- The test verifies that everything constant folds down to a single constant
		assert(compileFunction0("return 7 + if true then 10 else 20") == [[
LOADN R0 17
RETURN R0 1
]])

		-- codegen for a non-constant condition
		assert(compileFunction0("return if condition then 10 else 20") == [[
GETIMPORT R1 1 [condition]
JUMPIFNOT R1 L0
LOADN R0 10
RETURN R0 1
L0: LOADN R0 20
RETURN R0 1
]])

		-- codegen for a non-constant condition using an assignment
		assert(compileFunction0("result = if condition then 10 else 20") == [[
GETIMPORT R1 1 [condition]
JUMPIFNOT R1 L0
LOADN R0 10
JUMP L1
L0: LOADN R0 20
L1: SETGLOBAL R0 K2 ['result']
RETURN R0 0
]])

		-- codegen for a non-constant condition using an assignment to a local variable
		assert(compileFunction0("local result = if condition then 10 else 20") == [[
GETIMPORT R1 1 [condition]
JUMPIFNOT R1 L0
LOADN R0 10
RETURN R0 0
L0: LOADN R0 20
RETURN R0 0
]])

		-- codegen for an if-else expression with multiple elseif's
		assert(compileFunction0("result = if condition1 then 10 elseif condition2 then 20 elseif condition3 then 30 else 40") == [[
GETIMPORT R1 1 [condition1]
JUMPIFNOT R1 L0
LOADN R0 10
JUMP L3
L0: GETIMPORT R1 3 [condition2]
JUMPIFNOT R1 L1
LOADN R0 20
JUMP L3
L1: GETIMPORT R1 5 [condition3]
JUMPIFNOT R1 L2
LOADN R0 30
JUMP L3
L2: LOADN R0 40
L3: SETGLOBAL R0 K6 ['result']
RETURN R0 0
]])
	end,

	UnaryBasic = function()
		assert(compileFunction0("local a = ... return not a") == [[
GETVARARGS R0 1
NOT R1 R0
RETURN R1 1
]])

		assert(compileFunction0("local a = ... return -a") == [[
GETVARARGS R0 1
MINUS R1 R0
RETURN R1 1
]])

		assert(compileFunction0("local a = ... return #a") == [[
GETVARARGS R0 1
LENGTH R1 R0
RETURN R1 1
]])
	end,

	InterpStringWithNoExpressions = function()
		assert(compileFunction0([[return "hello"]]) == compileFunction0("return `hello`"))
	end,

	InterpStringZeroCost = function()
		assert(compileFunction0([[local _ = `hello, {"world"}!`]]) == [[
LOADK R1 K0 ['hello, %*!']
LOADK R3 K1 ['world']
NAMECALL R1 R1 K2 ['format']
CALL R1 2 1
MOVE R0 R1
RETURN R0 0
]])
	end,

	InterpStringRegisterCleanup = function()
		assert(compileFunction0([[
            local a, b, c = nil, "um", "uh oh"
            a = `foo{"bar"}`
            print(a)
        ]]) == [[
LOADNIL R0
LOADK R1 K0 ['um']
LOADK R2 K1 ['uh oh']
LOADK R3 K2 ['foo%*']
LOADK R5 K3 ['bar']
NAMECALL R3 R3 K4 ['format']
CALL R3 2 1
MOVE R0 R3
GETIMPORT R3 6 [print]
MOVE R4 R0
CALL R3 1 0
RETURN R0 0
]])
	end,

	InterpStringRegisterLimit = function()
		assert((pcall(compileFunction0, "local a = `" .. string.rep("{1}", 254) .. "`")) == false)
		assert((pcall(compileFunction0, "local a = `" .. string.rep("{1}", 253) .. "`")) == false)
	end,

	ConstantFoldArith = function()
		assert(compileFunction0("return 10 + 2") == [[
LOADN R0 12
RETURN R0 1
]])

		assert(compileFunction0("return 10 - 2") == [[
LOADN R0 8
RETURN R0 1
]])

		assert(compileFunction0("return 10 * 2") == [[
LOADN R0 20
RETURN R0 1
]])

		assert(compileFunction0("return 10 / 2") == [[
LOADN R0 5
RETURN R0 1
]])

		assert(compileFunction0("return 10 % 2") == [[
LOADN R0 0
RETURN R0 1
]])

		assert(compileFunction0("return 10 ^ 2") == [[
LOADN R0 100
RETURN R0 1
]])

		assert(compileFunction0("return -(2 - 5)") == [[
LOADN R0 3
RETURN R0 1
]])

		-- nested arith expression with groups
		assert(compileFunction0("return (2 + 2) * 2") == [[
LOADN R0 8
RETURN R0 1
]])
	end,

	ConstantFoldStringLen = function()
		assert(compileFunction0("return #'string', #'', #'a', #('b')") == [[
LOADN R0 6
LOADN R1 0
LOADN R2 1
LOADN R3 1
RETURN R0 4
]])
	end,

	ConstantFoldCompare = function()
		-- ordered comparisons
		assert(compileFunction0("return 1 < 1, 1 < 2") == [[
LOADB R0 0
LOADB R1 1
RETURN R0 2
]])
		assert(compileFunction0("return 1 <= 1, 1 <= 2") == [[
LOADB R0 1
LOADB R1 1
RETURN R0 2
]])

		assert(compileFunction0("return 1 > 1, 1 > 2") == [[
LOADB R0 0
LOADB R1 0
RETURN R0 2
]])

		assert(compileFunction0("return 1 >= 1, 1 >= 2") == [[
LOADB R0 1
LOADB R1 0
RETURN R0 2
]])

		-- equality comparisons
		assert(compileFunction0("return nil == 1, nil ~= 1, nil == nil, nil ~= nil") == [[
LOADB R0 0
LOADB R1 1
LOADB R2 1
LOADB R3 0
RETURN R0 4
]])

		assert(compileFunction0("return 2 == 1, 2 ~= 1, 1 == 1, 1 ~= 1") == [[
LOADB R0 0
LOADB R1 1
LOADB R2 1
LOADB R3 0
RETURN R0 4
]])

		assert(compileFunction0("return true == false, true ~= false, true == true, true ~= true") == [[
LOADB R0 0
LOADB R1 1
LOADB R2 1
LOADB R3 0
RETURN R0 4
]])

		assert(compileFunction0("return 'a' == 'b', 'a' ~= 'b', 'a' == 'a', 'a' ~= 'a'") == [[
LOADB R0 0
LOADB R1 1
LOADB R2 1
LOADB R3 0
RETURN R0 4
]])
	end,

	ConstantFoldLocal = function()
		-- local constant propagation, including upvalues, and no propagation for mutated locals
		assert(compileFunction0("local a = 1 return a + a") == [[
LOADN R0 2
RETURN R0 1
]])

		assert(compileFunction0("local a = 1 a = a + a return a") == [[
LOADN R0 1
ADD R0 R0 R0
RETURN R0 1
]])

		assert(compileFunction0("local a = 1 function foo() return a + a end") == [[
LOADN R0 2
RETURN R0 1
]])

		assert(compileFunction0("local a = 1 function foo() return a + a end function bar() a = 5 end") == [[
GETUPVAL R1 0
GETUPVAL R2 0
ADD R0 R1 R2
RETURN R0 1
]])

		-- local values for multiple assignments
		assert(compileFunction0("local a return a") == [[
LOADNIL R0
RETURN R0 1
]])

		assert(compileFunction0("local a, b = 1, 3 return a + 1, b") == [[
LOADN R0 2
LOADN R1 3
RETURN R0 2
]])

		assert(compileFunction0("local a, b = 1 return a + 1, b") == [[
LOADN R0 2
LOADNIL R1
RETURN R0 2
]])

		-- local values for multiple assignments w/multret
		assert(compileFunction0("local a, b = ... return a + 1, b") == [[
GETVARARGS R0 2
ADDK R2 R0 K0 [1]
MOVE R3 R1
RETURN R2 2
]])

		assert(compileFunction0("local a, b = 1, ... return a + 1, b") == [[
LOADN R0 1
GETVARARGS R1 1
LOADN R2 2
MOVE R3 R1
RETURN R2 2
]])
	end,

	ConstantFoldAndOr = function()
		-- and/or constant folding when both sides are constant
		assert(compileFunction0("return true and 2") == [[
LOADN R0 2
RETURN R0 1
]])

		assert(compileFunction0("return false and 2") == [[
LOADB R0 0
RETURN R0 1
]])

		assert(compileFunction0("return nil and 2") == [[
LOADNIL R0
RETURN R0 1
]])

		assert(compileFunction0("return true or 2") == [[
LOADB R0 1
RETURN R0 1
]])

		assert(compileFunction0("return false or 2") == [[
LOADN R0 2
RETURN R0 1
]])

		assert(compileFunction0("return nil or 2") == [[
LOADN R0 2
RETURN R0 1
]])

		-- and/or constant folding when left hand side is constant
		assert(compileFunction0("return true and a") == [[
GETIMPORT R0 1 [a]
RETURN R0 1
]])

		assert(compileFunction0("return false and a") == [[
LOADB R0 0
RETURN R0 1
]])

		assert(compileFunction0("return true or a") == [[
LOADB R0 1
RETURN R0 1
]])

		assert(compileFunction0("return false or a") == [[
GETIMPORT R0 1 [a]
RETURN R0 1
]])

		-- constant fold parts in chains of and/or statements
		assert(compileFunction0("return a and true and b") == [[
GETIMPORT R0 1 [a]
JUMPIFNOT R0 L0
GETIMPORT R0 3 [b]
L0: RETURN R0 1
]])

		assert(compileFunction0("return a or false or b") == [[
GETIMPORT R0 1 [a]
JUMPIF R0 L0
GETIMPORT R0 3 [b]
L0: RETURN R0 1
]])
	end,

	ConstantFoldConditionalAndOr = function()
		assert(compileFunction0("local a = ... if false or a then print(1) end") == [[
GETVARARGS R0 1
JUMPIFNOT R0 L0
GETIMPORT R1 1 [print]
LOADN R2 1
CALL R1 1 0
L0: RETURN R0 0
]])

		assert(compileFunction0("local a = ... if not (false or a) then print(1) end") == [[
GETVARARGS R0 1
JUMPIF R0 L0
GETIMPORT R1 1 [print]
LOADN R2 1
CALL R1 1 0
L0: RETURN R0 0
]])

		assert(compileFunction0("local a = ... if true and a then print(1) end") == [[
GETVARARGS R0 1
JUMPIFNOT R0 L0
GETIMPORT R1 1 [print]
LOADN R2 1
CALL R1 1 0
L0: RETURN R0 0
]])

		assert(compileFunction0("local a = ... if not (true and a) then print(1) end") == [[
GETVARARGS R0 1
JUMPIF R0 L0
GETIMPORT R1 1 [print]
LOADN R2 1
CALL R1 1 0
L0: RETURN R0 0
]])
	end,

	ConstantFoldFlowControl = function()
		-- if
		assert(compileFunction0("if true then print(1) end") == [[
GETIMPORT R0 1 [print]
LOADN R1 1
CALL R0 1 0
RETURN R0 0
]])

		assert(compileFunction0("if false then print(1) end") == [[
RETURN R0 0
]])

		assert(compileFunction0("if true then print(1) else print(2) end") == [[
GETIMPORT R0 1 [print]
LOADN R1 1
CALL R0 1 0
RETURN R0 0
]])

		assert(compileFunction0("if false then print(1) else print(2) end") == [[
GETIMPORT R0 1 [print]
LOADN R1 2
CALL R0 1 0
RETURN R0 0
]])

		-- while
		assert(compileFunction0("while true do print(1) end") == [[
L0: GETIMPORT R0 1 [print]
LOADN R1 1
CALL R0 1 0
JUMPBACK L0
RETURN R0 0
]])

		assert(compileFunction0("while false do print(1) end") == [[
RETURN R0 0
]])

		-- repeat
		assert(compileFunction0("repeat print(1) until true") == [[
GETIMPORT R0 1 [print]
LOADN R1 1
CALL R0 1 0
RETURN R0 0
]])

		assert(compileFunction0("repeat print(1) until false") == [[
L0: GETIMPORT R0 1 [print]
LOADN R1 1
CALL R0 1 0
JUMPBACK L0
RETURN R0 0
]])

		-- there's an odd case in repeat..until compilation where we evaluate the expression that is always false for side-effects of the left hand side
		assert(compileFunction0("repeat print(1) until five and false") == [[
L0: GETIMPORT R0 1 [print]
LOADN R1 1
CALL R0 1 0
GETIMPORT R0 3 [five]
JUMPIFNOT R0 L1
L1: JUMPBACK L0
RETURN R0 0
]])
	end,

	LoopBreak = function()
		-- default codegen: compile breaks as unconditional jumps
		assert(compileFunction0("while true do if math.random() < 0.5 then break else end end") == [[
L0: GETIMPORT R0 2 [math.random]
CALL R0 0 1
LOADK R1 K3 [0.5]
JUMPIFNOTLT R0 R1 L1
RETURN R0 0
L1: JUMPBACK L0
RETURN R0 0
]])

		-- optimization: if then body is a break statement, flip the branches
		assert(compileFunction0("while true do if math.random() < 0.5 then break end end") == [[
L0: GETIMPORT R0 2 [math.random]
CALL R0 0 1
LOADK R1 K3 [0.5]
JUMPIFLT R0 R1 L1
JUMPBACK L0
L1: RETURN R0 0
]])
	end,

	LoopContinue = function()
		-- default codegen: compile continue as unconditional jumps
		assert(compileFunction0("repeat if math.random() < 0.5 then continue else end break until false error()") == [[
L0: GETIMPORT R0 2 [math.random]
CALL R0 0 1
LOADK R1 K3 [0.5]
JUMPIFNOTLT R0 R1 L2
JUMP L1
JUMP L2
L1: JUMPBACK L0
L2: GETIMPORT R0 5 [error]
CALL R0 0 0
RETURN R0 0
]])

		-- optimization: if then body is a continue statement, flip the branches
		assert(compileFunction0("repeat if math.random() < 0.5 then continue end break until false error()") == [[
L0: GETIMPORT R0 2 [math.random]
CALL R0 0 1
LOADK R1 K3 [0.5]
JUMPIFLT R0 R1 L1
JUMP L2
L1: JUMPBACK L0
L2: GETIMPORT R0 5 [error]
CALL R0 0 0
RETURN R0 0
]])
	end,

	LoopContinueUntil = function()
		-- it's valid to use locals defined inside the loop in until expression if they're defined before continue
		print(compileFunction0("repeat local r = math.random() if r > 0.5 then continue end r = r + 0.3 until r < 0.5"))
-- 		assert(compileFunction0("repeat local r = math.random() if r > 0.5 then continue end r = r + 0.3 until r < 0.5") == [[
-- L0: GETIMPORT R0 2 [math.random]
-- CALL R0 0 1
-- LOADK R1 K3 [0.5]
-- JUMPIFLT R1 R0 L1
-- ADDK R0 R0 K4 [0.29999999999999999]
-- L1: LOADK R1 K3 [0.5]
-- JUMPIFLT R0 R1 L2
-- JUMPBACK L0
-- L2: RETURN R0 0
-- ]])
	end
}