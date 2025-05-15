--!nolint LocalShadow

local DebugFlags = require("@Shared/DebugFlags")
DebugFlags.AssertEnabled = true
local BytecodeBuilder = require("@Compiler/BytecodeBuilder")
local CompileError = require("@Compiler/CompileError")
local CompileOptions = require("@Compiler/CompileOptions")
local Compiler = require("@Compiler/Compiler")
local FastVariables = require("@Shared/FastVariables")
local LuauBuiltinFunction = require("@Common/Bytecode/LuauBuiltinFunction")
local LuauBytecodeTag = require("@Common/Bytecode/LuauBytecodeTag")
local LuauBytecodeType = require("@Common/Bytecode/LuauBytecodeType")
local LuauCaptureType = require("@Common/Bytecode/LuauCaptureType")
local LuauOpcode = require("@Common/Bytecode/LuauOpcode")
local ParseError = require("@Ast/ParseError")
local ParseOptions = require("@Ast/ParseOptions")
local ScopedVariable = require("@Shared/ScopedVariable")

local DumpFlags = BytecodeBuilder.DumpFlags

type CompileError = CompileError.CompileError
type FV = typeof(FastVariables)
type ParseError = ParseError.ParseError

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
		assert(compileFunction0("repeat local r = math.random() if r > 0.5 then continue end r = r + 0.3 until r < 0.5") == [[
L0: GETIMPORT R0 2 [math.random]
CALL R0 0 1
LOADK R1 K3 [0.5]
JUMPIFLT R1 R0 L1
ADDK R0 R0 K4 [0.29999999999999999]
L1: LOADK R1 K3 [0.5]
JUMPIFLT R0 R1 L2
JUMPBACK L0
L2: RETURN R0 0
]])

		-- it's however invalid to use locals if they are defined after continue
		local success, e: CompileError = pcall(function()
			local bcb = BytecodeBuilder.new()
			Compiler.compileOrThrow(bcb, [[

repeat
    local r = math.random()
    if r > 0.5 then
        continue
    end
    local rr = r + 0.3
until rr < 0.5
]])
		end)

		if success then
			error("Expected CompileError")
		else
			assert(e:getLocation().begin.line + 1 == 8)
			assert(e:what() == "Local rr used in the repeat..until condition is undefined because continue statement on line 5 jumps over it")
		end

		-- but it's okay if continue is inside a non-repeat..until loop, or inside a loop that doesn't use the local (here `continue` just terminates
		-- inner loop)
		assert(
			compileFunction0(
				"repeat local r = math.random() repeat if r > 0.5 then continue end r = r - 0.1 until true r = r + 0.3 until r < 0.5"
			) == [[
L0: GETIMPORT R0 2 [math.random]
CALL R0 0 1
LOADK R1 K3 [0.5]
JUMPIFLT R1 R0 L1
SUBK R0 R0 K4 [0.10000000000000001]
L1: ADDK R0 R0 K5 [0.29999999999999999]
LOADK R1 K3 [0.5]
JUMPIFLT R0 R1 L2
JUMPBACK L0
L2: RETURN R0 0
]]
		)

		-- and it's also okay to use a local defined in the until expression as long as it's inside a function!
		assert(
			compileFunction(
				"repeat local r = math.random() if r > 0.5 then continue end r = r + 0.3 until (function() local a = r return a < 0.5 end)()",
				1
			) == [[
L0: GETIMPORT R0 2 [math.random]
CALL R0 0 1
LOADK R1 K3 [0.5]
JUMPIFLT R1 R0 L1
ADDK R0 R0 K4 [0.29999999999999999]
L1: NEWCLOSURE R1 P0
CAPTURE REF R0
CALL R1 0 1
JUMPIF R1 L2
CLOSEUPVALS R0
JUMPBACK L0
L2: CLOSEUPVALS R0
RETURN R0 0
]]
		)

		-- but not if the function just refers to an upvalue
		local success, e: CompileError = pcall(function()
			local bcb = BytecodeBuilder.new()
			Compiler.compileOrThrow(bcb, [[

repeat
    local r = math.random()
    if r > 0.5 then
        continue
    end
    local rr = r + 0.3
until (function() return rr end)() < 0.5
]])
		end)

		if success then
			error("Expected CompileError")
		else
			assert(e:getLocation().begin.line + 1 == 8)
			assert(e:what() == "Local rr used in the repeat..until condition is undefined because continue statement on line 5 jumps over it")
		end

		-- unless that upvalue is from an outer scope
		assert(
			compileFunction0(
				"local stop = false stop = true function test() repeat local r = math.random() if r > 0.5 then \
				continue end r = r + 0.3 until stop or r < 0.5 end"
			) == [[
L0: GETIMPORT R0 2 [math.random]
CALL R0 0 1
LOADK R1 K3 [0.5]
JUMPIFLT R1 R0 L1
ADDK R0 R0 K4 [0.29999999999999999]
L1: GETUPVAL R1 0
JUMPIF R1 L2
LOADK R1 K3 [0.5]
JUMPIFLT R0 R1 L2
JUMPBACK L0
L2: RETURN R0 0
]]
		)

		-- including upvalue references from a function expression
		assert(
			compileFunction(
				"local stop = false stop = true function test() repeat local r = math.random() if r > 0.5 then continue \
				end r = r + 0.3 until (function() return stop or r < 0.5 end)() end",
				1
			) == [[
L0: GETIMPORT R0 2 [math.random]
CALL R0 0 1
LOADK R1 K3 [0.5]
JUMPIFLT R1 R0 L1
ADDK R0 R0 K4 [0.29999999999999999]
L1: NEWCLOSURE R1 P0
CAPTURE UPVAL U0
CAPTURE REF R0
CALL R1 0 1
JUMPIF R1 L2
CLOSEUPVALS R0
JUMPBACK L0
L2: CLOSEUPVALS R0
RETURN R0 0
]]
		)
	end,

	LoopContinueIgnoresImplicitConstant = function()
		-- this used to crash the compiler :(
		assert(compileFunction0([[
local _
repeat
continue
until not _
]]) == [[
RETURN R0 0
RETURN R0 0
]])
	end,

	LoopContinueIgnoresExplicitConstant = function()
		-- Constants do not allocate locals and 'continue' validation should skip them if their lifetime already started
		assert(compileFunction0([[
local c = true
repeat
    continue
until c
]]) == [[
RETURN R0 0
RETURN R0 0
]])
	end,

	LoopContinueRespectsExplicitConstant = function()
		-- If local lifetime hasn't started, even if it's a constant that will not receive an allocation, it cannot be jumped over
		local success, e: CompileError = pcall(function()
			local bcb = BytecodeBuilder.new()
			Compiler.compileOrThrow(bcb, [[

repeat
    do continue end

    local c = true
until c
]])
		end)

		if success then
			error("Expected CompileError")
		else
			assert(e:getLocation().begin.line + 1 == 6)
			assert(e:what() == "Local c used in the repeat..until condition is undefined because continue statement on line 3 jumps over it")
		end
	end,

	LoopContinueIgnoresImplicitConstantAfterInline = function()
		-- Inlining might also replace some locals with constants instead of allocating them
		assert(compileFunction([[
local function inline(f)
    repeat
        continue
    until f
end

local function test(...)
    inline(true)
end

test()
]], 1, 2) == [[
RETURN R0 0
RETURN R0 0
]])
	end,

	LoopContinueCorrectlyHandlesImplicitConstantAfterUnroll = function()
		ScopedVariable({LuauCompileLoopUnrollThreshold = 200} :: FV, function()
			-- access to implicit constant that depends on the unrolled loop constant is still invalid even though we can constant-propagate it
			local success, e: CompileError = pcall(function()
				compileFunction([[

for i = 1, 2 do
    s()
    repeat
        if i == 2 then
            continue
        end
        local x = i == 1 or a
    until f(x)
end
]], 0, 2)
			end)
	
			if success then
				error("Expected CompileError")
			else
				assert(e:getLocation().begin.line + 1 == 9)
				assert(e:what() == "Local x used in the repeat..until condition is undefined because continue statement on line 6 jumps over it")
			end
		end)
	end,

	LoopContinueUntilCapture = function()
		-- validate continue upvalue closing behavior: continue must close locals defined in the nested scopes
		-- but can't close locals defined in the loop scope - these are visible to the condition and will be closed
		-- when evaluating the condition instead.
		assert(compileFunction([[
local a a = 0
repeat
    local b b = 0
    if a then
        local c
        print(function() c = 0 end)
        if a then
            continue -- must close c but not a/b
        end
        -- must close c
    end
    -- must close b but not a
until function() a = 0 b = 0 end
-- must close b on loop exit
-- must close a
]], 2) == [[
LOADNIL R0
LOADN R0 0
L0: LOADNIL R1
LOADN R1 0
JUMPIFNOT R0 L2
LOADNIL R2
GETIMPORT R3 1 [print]
NEWCLOSURE R4 P0
CAPTURE REF R2
CALL R3 1 0
JUMPIFNOT R0 L1
CLOSEUPVALS R2
JUMP L2
L1: CLOSEUPVALS R2
L2: NEWCLOSURE R2 P1
CAPTURE REF R0
CAPTURE REF R1
JUMPIF R2 L3
CLOSEUPVALS R1
JUMPBACK L0
L3: CLOSEUPVALS R1
CLOSEUPVALS R0
RETURN R0 0
]])

		-- a simpler version of the above test doesn't need to close anything when evaluating continue
		assert(compileFunction([[
local a a = 0
repeat
    local b b = 0
    if a then
        continue -- must not close a/b
    end
    -- must close b but not a
until function() a = 0 b = 0 end
-- must close b on loop exit
-- must close a
]], 1) == [[
LOADNIL R0
LOADN R0 0
L0: LOADNIL R1
LOADN R1 0
JUMPIF R0 L1
L1: NEWCLOSURE R2 P0
CAPTURE REF R0
CAPTURE REF R1
JUMPIF R2 L2
CLOSEUPVALS R1
JUMPBACK L0
L2: CLOSEUPVALS R1
CLOSEUPVALS R0
RETURN R0 0
]])
	end,

	LoopContinueEarlyCleanup = function()
		-- locals after a potential 'continue' are not accessible inside the condition and can be closed at the end of a block
		assert(compileFunction([[
local y
repeat
    local a, b
    do continue end
    local c, d
    local function x()
        return a + b + c + d
    end

    c = 2
    a = 4

    y = x
until a
]], 1) == [[
LOADNIL R0
L0: LOADNIL R1
LOADNIL R2
JUMP L1
LOADNIL R3
LOADNIL R4
NEWCLOSURE R5 P0
CAPTURE REF R1
CAPTURE REF R3
LOADN R3 2
LOADN R1 4
MOVE R0 R5
CLOSEUPVALS R3
L1: JUMPIF R1 L2
CLOSEUPVALS R1
JUMPBACK L0
L2: CLOSEUPVALS R1
RETURN R0 0
]])
	end,

	AndOrOptimizations = function()
		-- the OR/ORK optimization triggers for cutoff since lhs is simple
		assert(compileFunction([[
local function advancedRidgedFilter(value, cutoff)
    local cutoff = cutoff or .5
    value = value - cutoff
    return 1 - (value < 0 and -value or value) * 1 / (1 - cutoff)
end
]], 0) == [[
ORK R2 R1 K0 [0.5]
SUB R0 R0 R2
LOADN R7 0
JUMPIFNOTLT R0 R7 L0
MINUS R6 R0
JUMPIF R6 L1
L0: MOVE R6 R0
L1: MULK R5 R6 K1 [1]
SUBRK R6 K1 [1] R2
DIV R4 R5 R6
SUBRK R3 K1 [1] R4
RETURN R3 1
]])

		-- sometimes we need to compute a boolean; this uses LOADB with an offset
		assert(compileFunction([[
function thinSurface(surfaceGradient, surfaceThickness)
    return surfaceGradient > .5 - surfaceThickness*.4 and surfaceGradient < .5 + surfaceThickness*.4
end
]], 0) == [[
LOADB R2 0
MULK R4 R1 K1 [0.40000000000000002]
SUBRK R3 K0 [0.5] R4
JUMPIFNOTLT R3 R0 L1
LOADK R4 K0 [0.5]
MULK R5 R1 K1 [0.40000000000000002]
ADD R3 R4 R5
JUMPIFLT R0 R3 L0
LOADB R2 0 +1
L0: LOADB R2 1
L1: RETURN R2 1
]])

		-- sometimes we need to compute a boolean; this uses LOADB with an offset for the last op, note that first op is compiled better
		assert(compileFunction([[
function thickSurface(surfaceGradient, surfaceThickness)
    return surfaceGradient < .5 - surfaceThickness*.4 or surfaceGradient > .5 + surfaceThickness*.4
end
]], 0) == [[
LOADB R2 1
MULK R4 R1 K1 [0.40000000000000002]
SUBRK R3 K0 [0.5] R4
JUMPIFLT R0 R3 L1
LOADK R4 K0 [0.5]
MULK R5 R1 K1 [0.40000000000000002]
ADD R3 R4 R5
JUMPIFLT R3 R0 L0
LOADB R2 0 +1
L0: LOADB R2 1
L1: RETURN R2 1
]])

		-- trivial ternary if with constants
		assert(compileFunction([[
function testSurface(surface)
    return surface and 1 or 0
end
]], 0) == [[
JUMPIFNOT R0 L0
LOADN R1 1
RETURN R1 1
L0: LOADN R1 0
RETURN R1 1
]])

		-- canonical saturate
		assert(compileFunction([[
function saturate(x)
    return x < 0 and 0 or x > 1 and 1 or x
end
]], 0) == [[
LOADN R2 0
JUMPIFNOTLT R0 R2 L0
LOADN R1 0
RETURN R1 1
L0: LOADN R2 1
JUMPIFNOTLT R2 R0 L1
LOADN R1 1
RETURN R1 1
L1: MOVE R1 R0
RETURN R1 1
]])
	end,

	JumpFold = function()
		-- jump-to-return folding to return
		assert(compileFunction0("return a and 1 or 0") == [[
GETIMPORT R1 1 [a]
JUMPIFNOT R1 L0
LOADN R0 1
RETURN R0 1
L0: LOADN R0 0
RETURN R0 1
]])

		-- conditional jump in the inner if() folding to jump out of the expression (JUMPIFNOT+5 skips over all jumps, JUMP+1 skips over JUMP+0)
		assert(compileFunction0("if a then if b then b() else end else end d()") == [[
GETIMPORT R0 1 [a]
JUMPIFNOT R0 L0
GETIMPORT R0 3 [b]
JUMPIFNOT R0 L0
GETIMPORT R0 3 [b]
CALL R0 0 0
JUMP L0
JUMP L0
L0: GETIMPORT R0 5 [d]
CALL R0 0 0
RETURN R0 0
]])

		-- same as example before but the unconditional jumps are folded with RETURN
		assert(compileFunction0("if a then if b then b() else end else end") == [[
GETIMPORT R0 1 [a]
JUMPIFNOT R0 L0
GETIMPORT R0 3 [b]
JUMPIFNOT R0 L0
GETIMPORT R0 3 [b]
CALL R0 0 0
RETURN R0 0
RETURN R0 0
L0: RETURN R0 0
]])

		-- in this example, we do *not* have a JUMP after RETURN in the if branch
		-- this is important since, even though this jump is never reached, jump folding needs to be able to analyze it
		assert(compileFunction([[
local function getPerlin(x, y, z, seed, scale, raw)
local seed = seed or 0
local scale = scale or 1
if not raw then
return math.noise(x / scale + (seed * 17) + masterSeed, y / scale - masterSeed, z / scale - seed*seed)*.5 + .5 --accounts for bleeding from interpolated line
else
return math.noise(x / scale + (seed * 17) + masterSeed, y / scale - masterSeed, z / scale - seed*seed)
end
end
]], 0) == [[
ORK R6 R3 K0 [0]
ORK R7 R4 K1 [1]
JUMPIF R5 L0
GETIMPORT R10 5 [math.noise]
DIV R13 R0 R7
MULK R14 R6 K6 [17]
ADD R12 R13 R14
GETIMPORT R13 8 [masterSeed]
ADD R11 R12 R13
DIV R13 R1 R7
GETIMPORT R14 8 [masterSeed]
SUB R12 R13 R14
DIV R14 R2 R7
MUL R15 R6 R6
SUB R13 R14 R15
CALL R10 3 1
MULK R9 R10 K2 [0.5]
ADDK R8 R9 K2 [0.5]
RETURN R8 1
L0: GETIMPORT R8 5 [math.noise]
DIV R11 R0 R7
MULK R12 R6 K6 [17]
ADD R10 R11 R12
GETIMPORT R11 8 [masterSeed]
ADD R9 R10 R11
DIV R11 R1 R7
GETIMPORT R12 8 [masterSeed]
SUB R10 R11 R12
DIV R12 R2 R7
MUL R13 R6 R6
SUB R11 R12 R13
CALL R8 3 -1
RETURN R8 -1
]])
	end,

	RecursionParse = function()
		-- The test forcibly pushes the stack limit during compilation; in NoOpt, the stack consumption is much larger so we need to reduce the limit to
		-- not overflow the C stack. When ASAN is enabled, stack consumption increases even more.
		
		local bcb = BytecodeBuilder.new()

		local success, e: ParseError = pcall(function()
			Compiler.compileOrThrow(bcb, "a=" .. string.rep("{", 1500) .. string.rep("}", 1500))
		end)

		if success then
			error("Expected exception")
		else
			assert(e:what() == "Exceeded allowed recursion depth; simplify your expression to make the code compile")
		end

		local success, e: ParseError = pcall(function()
			Compiler.compileOrThrow(bcb, "function a" .. string.rep(".a", 1500) .. "() end")
		end)

		if success then
			error("Expected exception")
		else
			assert(e:what() == "Exceeded allowed recursion depth; simplify your function name to make the code compile")
		end

		local success, e: ParseError = pcall(function()
			Compiler.compileOrThrow(bcb, "a=1" .. string.rep("+1", 1500))
		end)

		if success then
			error("Expected exception")
		else
			assert(e:what() == "Exceeded allowed recursion depth; simplify your expression to make the code compile")
		end

		local success, e: ParseError = pcall(function()
			Compiler.compileOrThrow(bcb, "a=" .. string.rep("(", 1500) .. "1" .. string.rep(")", 1500))
		end)

		if success then
			error("Expected exception")
		else
			assert(e:what() == "Exceeded allowed recursion depth; simplify your expression to make the code compile")
		end

		local success, e: ParseError = pcall(function()
			Compiler.compileOrThrow(bcb, string.rep("do ", 1500) .. "print()" .. string.rep(" end", 1500))
		end)

		if success then
			error("Expected exception")
		else
			assert(e:what() == "Exceeded allowed recursion depth; simplify your block to make the code compile")
		end

		local success, e: ParseError = pcall(function()
			Compiler.compileOrThrow(bcb, string.rep("a(", 1500) .. "42" .. string.rep(")", 1500))
		end)

		if success then
			error("Expected exception")
		else
			assert(e:what() == "Exceeded allowed recursion depth; simplify your expression to make the code compile")
		end

		local success, e: ParseError = pcall(function()
			Compiler.compileOrThrow(bcb, "return {" .. string.rep("{", 1500) .. string.rep("}", 1500))
		end)

		if success then
			error("Expected exception")
		else
			assert(e:what() == "Exceeded allowed recursion depth; simplify your expression to make the code compile")
		end

		local success, e: ParseError = pcall(function()
			Compiler.compileOrThrow(bcb, string.rep("while true do ", 1500) .. "print()" .. string.rep(" end", 1500))
		end)

		if success then
			error("Expected exception")
		else
			assert(e:what() == "Exceeded allowed recursion depth; simplify your expression to make the code compile")
		end

		local success, e: ParseError = pcall(function()
			Compiler.compileOrThrow(bcb, string.rep("for i=1,1 do ", 1500) .. "print()" .. string.rep(" end", 1500))
		end)

		if success then
			error("Expected exception")
		else
			assert(e:what() == "Exceeded allowed recursion depth; simplify your expression to make the code compile")
		end

		local success, e: ParseError = pcall(function()
			Compiler.compileOrThrow(bcb, string.rep("function a() ", 1500) .. "print()" .. string.rep(" end", 1500))
		end)

		if success then
			error("Expected exception")
		else
			assert(e:what() == "Exceeded allowed recursion depth; simplify your block to make the code compile")
		end

		local success, e: ParseError = pcall(function()
			Compiler.compileOrThrow(bcb, "return " .. string.rep("function() return ", 1500) .. "42" .. string.rep(" end", 1500))
		end)

		if success then
			error("Expected exception")
		else
			assert(e:what() == "Exceeded allowed recursion depth; simplify your block to make the code compile")
		end

		local success, e: ParseError = pcall(function()
			Compiler.compileOrThrow(bcb, "local f: " .. string.rep("(", 1500) .. "nil" .. string.rep(")", 1500))
		end)

		if success then
			error("Expected exception")
		else
			assert(e:what() == "Exceeded allowed recursion depth; simplify your type annotation to make the code compile")
		end

		local success, e: ParseError = pcall(function()
			Compiler.compileOrThrow(bcb, "local f: () " .. string.rep("-> ()", 1500))
		end)

		if success then
			error("Expected exception")
		else
			assert(e:what() == "Exceeded allowed recursion depth; simplify your type annotation to make the code compile")
		end

		local success, e: ParseError = pcall(function()
			Compiler.compileOrThrow(bcb, "local f: " .. string.rep("{x:", 1500) .. "nil" .. string.rep("}", 1500))
		end)

		if success then
			error("Expected exception")
		else
			assert(e:what() == "Exceeded allowed recursion depth; simplify your type annotation to make the code compile")
		end

		local success, e: ParseError = pcall(function()
			Compiler.compileOrThrow(bcb, "local f: " .. string.rep("(nil & ", 1500) .. "nil" .. string.rep(")", 1500))
		end)

		if success then
			error("Expected exception")
		else
			assert(e:what() == "Exceeded allowed recursion depth; simplify your type annotation to make the code compile")
		end
	end,

	ArrayIndexLiteral = function()
		assert(compileFunction0("local arr = {} return arr[0], arr[1], arr[256], arr[257]") == [[
NEWTABLE R0 0 0
LOADN R2 0
GETTABLE R1 R0 R2
GETTABLEN R2 R0 1
GETTABLEN R3 R0 256
LOADN R5 257
GETTABLE R4 R0 R5
RETURN R1 4
]])

		assert(compileFunction0("local arr = {} local b = ... arr[0] = b arr[1] = b arr[256] = b arr[257] = b") == [[
NEWTABLE R0 0 1
GETVARARGS R1 1
LOADN R2 0
SETTABLE R1 R0 R2
SETTABLEN R1 R0 1
SETTABLEN R1 R0 256
LOADN R2 257
SETTABLE R1 R0 R2
RETURN R0 0
]])
	end,

	NestedFunctionCalls = function()
		assert(compileFunction0("function clamp(t,a,b) return math.min(math.max(t,a),b) end") == [[
FASTCALL2 18 R0 R1 L0
MOVE R5 R0
MOVE R6 R1
GETIMPORT R4 2 [math.max]
CALL R4 2 1
L0: FASTCALL2 19 R4 R2 L1
MOVE R5 R2
GETIMPORT R3 4 [math.min]
CALL R3 2 -1
L1: RETURN R3 -1
]])
	end,

	UpvaluesLoopsBytecode = function()
		assert(compileFunction([[
function test()
    for i=1,10 do
        i = i
        foo(function() return i end)
        if bar then
            break
        end
    end
    return 0
end
]], 1) == [[
LOADN R2 1
LOADN R0 10
LOADN R1 1
FORNPREP R0 L2
L0: MOVE R3 R2
GETIMPORT R4 1 [foo]
NEWCLOSURE R5 P0
CAPTURE REF R3
CALL R4 1 0
GETIMPORT R4 3 [bar]
JUMPIFNOT R4 L1
CLOSEUPVALS R3
JUMP L2
L1: CLOSEUPVALS R3
FORNLOOP R0 L0
L2: LOADN R0 0
RETURN R0 1
]])

		assert(compileFunction([[
function test()
    for i in ipairs(data) do
        i = i
        foo(function() return i end)
        if bar then
            break
        end
    end
    return 0
end
]], 1) == [[
GETIMPORT R0 1 [ipairs]
GETIMPORT R1 3 [data]
CALL R0 1 3
FORGPREP_INEXT R0 L2
L0: GETIMPORT R5 5 [foo]
NEWCLOSURE R6 P0
CAPTURE REF R3
CALL R5 1 0
GETIMPORT R5 7 [bar]
JUMPIFNOT R5 L1
CLOSEUPVALS R3
JUMP L3
L1: CLOSEUPVALS R3
L2: FORGLOOP R0 L0 1 [inext]
L3: LOADN R0 0
RETURN R0 1
]])

		assert(compileFunction([[
function test()
    local i = 0
    while i < 5 do
        local j
        j = i
        foo(function() return j end)
        i = i + 1
        if bar then
            break
        end
    end
    return 0
end
]], 1) == [[
LOADN R0 0
L0: LOADN R1 5
JUMPIFNOTLT R0 R1 L2
LOADNIL R1
MOVE R1 R0
GETIMPORT R2 1 [foo]
NEWCLOSURE R3 P0
CAPTURE REF R1
CALL R2 1 0
ADDK R0 R0 K2 [1]
GETIMPORT R2 4 [bar]
JUMPIFNOT R2 L1
CLOSEUPVALS R1
JUMP L2
L1: CLOSEUPVALS R1
JUMPBACK L0
L2: LOADN R1 0
RETURN R1 1
]])

		assert(compileFunction([[
function test()
    local i = 0
    repeat
        local j
        j = i
        foo(function() return j end)
        i = i + 1
        if bar then
            break
        end
    until i < 5
    return 0
end
]], 1) == [[
LOADN R0 0
L0: LOADNIL R1
MOVE R1 R0
GETIMPORT R2 1 [foo]
NEWCLOSURE R3 P0
CAPTURE REF R1
CALL R2 1 0
ADDK R0 R0 K2 [1]
GETIMPORT R2 4 [bar]
JUMPIFNOT R2 L1
CLOSEUPVALS R1
JUMP L3
L1: LOADN R2 5
JUMPIFLT R0 R2 L2
CLOSEUPVALS R1
JUMPBACK L0
L2: CLOSEUPVALS R1
L3: LOADN R1 0
RETURN R1 1
]])
	end,

	TypeAliasing = function()
		local bcb = BytecodeBuilder.new()
		local options = CompileOptions.new()
		local parseOptions = ParseOptions.new()
		assert(pcall(function()
			Compiler.compileOrThrow(bcb, "type A = number local a: A = 1", options, parseOptions)
		end) == true)
	end,

	DebugLineInfo = function()
		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(bit32.bor(DumpFlags.Dump_Code, DumpFlags.Dump_Lines))
		Compiler.compileOrThrow(bcb, [[

local kSelectedBiomes = {
    ['Mountains'] = true,
    ['Canyons'] = true,
    ['Dunes'] = true,
    ['Arctic'] = true,
    ['Lavaflow'] = true,
    ['Hills'] = true,
    ['Plains'] = true,
    ['Marsh'] = true,
    ['Water'] = true,
}
local result = ""
for k in pairs(kSelectedBiomes) do
    result = result .. k
end
return result
]])

		assert(bcb:dumpFunction(0) == [[
2: NEWTABLE R0 16 0
3: LOADB R1 1
3: SETTABLEKS R1 R0 K0 ['Mountains']
4: LOADB R1 1
4: SETTABLEKS R1 R0 K1 ['Canyons']
5: LOADB R1 1
5: SETTABLEKS R1 R0 K2 ['Dunes']
6: LOADB R1 1
6: SETTABLEKS R1 R0 K3 ['Arctic']
7: LOADB R1 1
7: SETTABLEKS R1 R0 K4 ['Lavaflow']
8: LOADB R1 1
8: SETTABLEKS R1 R0 K5 ['Hills']
9: LOADB R1 1
9: SETTABLEKS R1 R0 K6 ['Plains']
10: LOADB R1 1
10: SETTABLEKS R1 R0 K7 ['Marsh']
11: LOADB R1 1
11: SETTABLEKS R1 R0 K8 ['Water']
13: LOADK R1 K9 ['']
14: GETIMPORT R2 11 [pairs]
14: MOVE R3 R0
14: CALL R2 1 3
14: FORGPREP_NEXT R2 L1
15: L0: MOVE R7 R1
15: MOVE R8 R5
15: CONCAT R1 R7 R8
14: L1: FORGLOOP R2 L0 1
17: RETURN R1 1
]])
	end,

	DebugLineInfoFor = function()
		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(bit32.bor(DumpFlags.Dump_Code, DumpFlags.Dump_Lines))
		Compiler.compileOrThrow(bcb, [[

for
i
in
1
,
2
,
3
do
print(i)
end
]])

		assert(bcb:dumpFunction(0) == [[
5: LOADN R0 1
7: LOADN R1 2
9: LOADN R2 3
9: FORGPREP R0 L1
11: L0: GETIMPORT R5 1 [print]
11: MOVE R6 R3
11: CALL R5 1 0
2: L1: FORGLOOP R0 L0 1
13: RETURN R0 0
]])
	end,

	DebugLineInfoWhile = function()
		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(bit32.bor(DumpFlags.Dump_Code, DumpFlags.Dump_Lines))
		Compiler.compileOrThrow(bcb, [[

local count = 0
while true do
    count += 1
    if count > 1 then
        print("done!")
        break
    end
end
]])

		assert(bcb:dumpFunction(0) == [[
2: LOADN R0 0
4: L0: ADDK R0 R0 K0 [1]
5: LOADN R1 1
5: JUMPIFNOTLT R1 R0 L1
6: GETIMPORT R1 2 [print]
6: LOADK R2 K3 ['done!']
6: CALL R1 1 0
7: RETURN R0 0
3: L1: JUMPBACK L0
10: RETURN R0 0
]])
	end,

	DebugLineInfoRepeatUntil = function()
		assert(compileFunction0Coverage([[

local f = 0
repeat
    f += 1
    if f == 1 then
        print(f)
    else
        f = 0
    end
until f == 0
]], 0) == [[
2: LOADN R0 0
4: L0: ADDK R0 R0 K0 [1]
5: JUMPXEQKN R0 K0 L1 NOT [1]
6: GETIMPORT R1 2 [print]
6: MOVE R2 R0
6: CALL R1 1 0
6: JUMP L2
8: L1: LOADN R0 0
10: L2: JUMPXEQKN R0 K3 L3 [0]
10: JUMPBACK L0
11: L3: RETURN R0 0
]])
	end,

	DebugLineInfoSubTable = function()
		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(bit32.bor(DumpFlags.Dump_Code, DumpFlags.Dump_Lines))
		Compiler.compileOrThrow(bcb, [[

local Value1, Value2, Value3 = ...
local Table = {}

Table.SubTable["Key"] = {
    Key1 = Value1,
    Key2 = Value2,
    Key3 = Value3,
    Key4 = true,
}
]])

		assert(bcb:dumpFunction(0) == [[
2: GETVARARGS R0 3
3: NEWTABLE R3 0 0
5: GETTABLEKS R4 R3 K0 ['SubTable']
5: DUPTABLE R5 5
6: SETTABLEKS R0 R5 K1 ['Key1']
7: SETTABLEKS R1 R5 K2 ['Key2']
8: SETTABLEKS R2 R5 K3 ['Key3']
9: LOADB R6 1
9: SETTABLEKS R6 R5 K4 ['Key4']
5: SETTABLEKS R5 R4 K6 ['Key']
11: RETURN R0 0
]])
	end,

	DebugLineInfoCall = function()
		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(bit32.bor(DumpFlags.Dump_Code, DumpFlags.Dump_Lines))
		Compiler.compileOrThrow(bcb, [[

local Foo = ...

Foo:Bar(
    1,
    2,
    3)
]])

		assert(bcb:dumpFunction(0) == [[
2: GETVARARGS R0 1
5: LOADN R3 1
6: LOADN R4 2
7: LOADN R5 3
4: NAMECALL R1 R0 K0 ['Bar']
4: CALL R1 4 0
8: RETURN R0 0
]])
	end,

	DebugLineInfoCallChain = function()
		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(bit32.bor(DumpFlags.Dump_Code, DumpFlags.Dump_Lines))
		Compiler.compileOrThrow(bcb, [[

local Foo = ...

Foo
:Bar(1)
:Baz(2)
.Qux(3)
]])

		assert(bcb:dumpFunction(0) == [[
2: GETVARARGS R0 1
5: LOADN R4 1
5: NAMECALL R2 R0 K0 ['Bar']
5: CALL R2 2 1
6: LOADN R4 2
6: NAMECALL R2 R2 K1 ['Baz']
6: CALL R2 2 1
7: GETTABLEKS R1 R2 K2 ['Qux']
7: LOADN R2 3
7: CALL R1 1 0
8: RETURN R0 0
]])
	end,

	DebugLineInfoFastCall = function()
		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(bit32.bor(DumpFlags.Dump_Code, DumpFlags.Dump_Lines))
		Compiler.compileOrThrow(bcb, [[

local Foo, Bar = ...

return
    math.max(
        Foo,
        Bar)
]])

		assert(bcb:dumpFunction(0) == [[
2: GETVARARGS R0 2
5: FASTCALL2 18 R0 R1 L0
5: MOVE R3 R0
5: MOVE R4 R1
5: GETIMPORT R2 2 [math.max]
5: CALL R2 2 -1
5: L0: RETURN R2 -1
]])
	end,

	DebugLineInfoAssignment = function()
		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(bit32.bor(DumpFlags.Dump_Code, DumpFlags.Dump_Lines))
		Compiler.compileOrThrow(bcb, [[

   local a = { b = { c = { d = 3 } } }

a
["b"]
["c"]
["d"] = 4
]])

		assert(bcb:dumpFunction(0) == [[
2: DUPTABLE R0 1
2: DUPTABLE R1 3
2: DUPTABLE R2 5
2: LOADN R3 3
2: SETTABLEKS R3 R2 K4 ['d']
2: SETTABLEKS R2 R1 K2 ['c']
2: SETTABLEKS R1 R0 K0 ['b']
5: GETTABLEKS R2 R0 K0 ['b']
6: GETTABLEKS R1 R2 K2 ['c']
7: LOADN R2 4
7: SETTABLEKS R2 R1 K4 ['d']
8: RETURN R0 0
]])
	end,

	DebugSource = function()
		local source = [[

local kSelectedBiomes = {
    ['Mountains'] = true,
    ['Canyons'] = true,
    ['Dunes'] = true,
    ['Arctic'] = true,
    ['Lavaflow'] = true,
    ['Hills'] = true,
    ['Plains'] = true,
    ['Marsh'] = true,
    ['Water'] = true,
}
local result = ""
for k in pairs(kSelectedBiomes) do
    result = result .. k
end
return result
]]

		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(bit32.bor(DumpFlags.Dump_Code, DumpFlags.Dump_Source))
		bcb:setDumpSource(source)

		Compiler.compileOrThrow(bcb, source)

		assert(bcb:dumpFunction(0) == [[
    2: local kSelectedBiomes = {
NEWTABLE R0 16 0
    3:     ['Mountains'] = true,
LOADB R1 1
SETTABLEKS R1 R0 K0 ['Mountains']
    4:     ['Canyons'] = true,
LOADB R1 1
SETTABLEKS R1 R0 K1 ['Canyons']
    5:     ['Dunes'] = true,
LOADB R1 1
SETTABLEKS R1 R0 K2 ['Dunes']
    6:     ['Arctic'] = true,
LOADB R1 1
SETTABLEKS R1 R0 K3 ['Arctic']
    7:     ['Lavaflow'] = true,
LOADB R1 1
SETTABLEKS R1 R0 K4 ['Lavaflow']
    8:     ['Hills'] = true,
LOADB R1 1
SETTABLEKS R1 R0 K5 ['Hills']
    9:     ['Plains'] = true,
LOADB R1 1
SETTABLEKS R1 R0 K6 ['Plains']
   10:     ['Marsh'] = true,
LOADB R1 1
SETTABLEKS R1 R0 K7 ['Marsh']
   11:     ['Water'] = true,
LOADB R1 1
SETTABLEKS R1 R0 K8 ['Water']
   13: local result = ""
LOADK R1 K9 ['']
   14: for k in pairs(kSelectedBiomes) do
GETIMPORT R2 11 [pairs]
MOVE R3 R0
CALL R2 1 3
FORGPREP_NEXT R2 L1
   15:     result = result .. k
L0: MOVE R7 R1
MOVE R8 R5
CONCAT R1 R7 R8
   14: for k in pairs(kSelectedBiomes) do
L1: FORGLOOP R2 L0 1
   17: return result
RETURN R1 1
]])
	end,

	DebugLocals = function()
		local source = [[

function foo(e, f)
    local a = 1
    for i=1,3 do
        print(i)
    end
    for k,v in pairs() do
        print(k, v)
    end
    do
        local b = 2
        print(b)
    end
    do
        local c = 2
        print(b)
    end
    local function inner()
        return inner, a
    end
    return a
end
]]

		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(bit32.bor(DumpFlags.Dump_Code, DumpFlags.Dump_Lines, DumpFlags.Dump_Locals))
		bcb:setDumpSource(source)

		local options = CompileOptions.new()
		options.debugLevel = 2

		Compiler.compileOrThrow(bcb, source, options)

		assert(bcb:dumpFunction(1) == [[
local 0: reg 5, start pc 5 line 5, end pc 8 line 5
local 1: reg 6, start pc 14 line 8, end pc 18 line 8
local 2: reg 7, start pc 14 line 8, end pc 18 line 8
local 3: reg 3, start pc 22 line 12, end pc 25 line 12
local 4: reg 3, start pc 27 line 16, end pc 31 line 16
local 5: reg 0, start pc 0 line 3, end pc 35 line 21
local 6: reg 1, start pc 0 line 3, end pc 35 line 21
local 7: reg 2, start pc 1 line 4, end pc 35 line 21
local 8: reg 3, start pc 35 line 21, end pc 35 line 21
3: LOADN R2 1
4: LOADN R5 1
4: LOADN R3 3
4: LOADN R4 1
4: FORNPREP R3 L1
5: L0: GETIMPORT R6 1 [print]
5: MOVE R7 R5
5: CALL R6 1 0
4: FORNLOOP R3 L0
7: L1: GETIMPORT R3 3 [pairs]
7: CALL R3 0 3
7: FORGPREP_NEXT R3 L3
8: L2: GETIMPORT R8 1 [print]
8: MOVE R9 R6
8: MOVE R10 R7
8: CALL R8 2 0
7: L3: FORGLOOP R3 L2 2
11: LOADN R3 2
12: GETIMPORT R4 1 [print]
12: LOADN R5 2
12: CALL R4 1 0
15: LOADN R3 2
16: GETIMPORT R4 1 [print]
16: GETIMPORT R5 5 [b]
16: CALL R4 1 0
18: NEWCLOSURE R3 P0
18: CAPTURE VAL R3
18: CAPTURE VAL R2
21: RETURN R2 1
]])
	end,

	DebugLocals2 = function()
		local source = [[

function foo(x)
    repeat
        local a, b
    until true
end
]]
		
		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(bit32.bor(DumpFlags.Dump_Code, DumpFlags.Dump_Lines, DumpFlags.Dump_Locals))
		bcb:setDumpSource(source)

		local options = CompileOptions.new()
		options.debugLevel = 2

		Compiler.compileOrThrow(bcb, source, options)

		assert(bcb:dumpFunction(0) == [[
local 0: reg 1, start pc 2 line 6, no live range
local 1: reg 2, start pc 2 line 6, no live range
local 2: reg 0, start pc 0 line 4, end pc 2 line 6
4: LOADNIL R1
4: LOADNIL R2
6: RETURN R0 0
]])
	end,

	DebugLocals3 = function()
		local source = [[

function foo(x)
    repeat
        local a, b
        do continue end
        local c, d = 2
    until true
end
]]
		
		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(bit32.bor(DumpFlags.Dump_Code, DumpFlags.Dump_Lines, DumpFlags.Dump_Locals))
		bcb:setDumpSource(source)

		local options = CompileOptions.new()
		options.debugLevel = 2

		Compiler.compileOrThrow(bcb, source, options)
				
		assert(bcb:dumpFunction(0) == [[
local 0: reg 3, start pc 5 line 8, no live range
local 1: reg 4, start pc 5 line 8, no live range
local 2: reg 1, start pc 2 line 5, end pc 4 line 6
local 3: reg 2, start pc 2 line 5, end pc 4 line 6
local 4: reg 0, start pc 0 line 4, end pc 5 line 8
4: LOADNIL R1
4: LOADNIL R2
5: RETURN R0 0
6: LOADN R3 2
6: LOADNIL R4
8: RETURN R0 0
]])
	end,

	DebugRemarks = function()
		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(bit32.bor(DumpFlags.Dump_Code, DumpFlags.Dump_Remarks))

		local fid = bcb:beginFunction(0)

		bcb:addDebugRemark(("test remark #%d"):format(1))
		bcb:emitABC(LuauOpcode.LOP_LOADNIL, 0, 0, 0)
		bcb:addDebugRemark(("test remark #%d"):format(2))
		bcb:addDebugRemark(("test remark #%d"):format(3))
		bcb:emitABC(LuauOpcode.LOP_RETURN, 0, 1, 0)

		bcb:endFunction(1, 0)

		bcb:setMainFunction(fid)
		bcb:finalize()

		assert(bcb:dumpFunction(0) == [[
REMARK test remark #1
LOADNIL R0
REMARK test remark #2
REMARK test remark #3
RETURN R0 0
]])
	end,

	DebugTypes = function()
		ScopedVariable({
			LuauCompileTypeInfo = true,
			LuauCompileTempTypeInfo = true,
			LuauCompileUserdataInfo = true
		} :: FV, function()
			local source = [[
local up: number = 2

function foo(e: vector, f: mat3, g: sequence)
    local h = e * e

    for i=1,3 do
        print(i)
    end

    print(e * f)
    print(g)
    print(h)

    up += a
    return a
end
]]

			local bcb = BytecodeBuilder.new()
			bcb:setDumpFlags(bit32.bor(DumpFlags.Dump_Code, DumpFlags.Dump_Types))
			bcb:setDumpSource(source)

			local options = CompileOptions.new()
			options.vectorCtor = "vector"
			options.vectorType = "vector"

			options.typeInfoLevel = 1
			
			local kUserdataCompileTypes = {"vec2", "color", "mat3"}
			options.userdataTypes = kUserdataCompileTypes

			Compiler.compileOrThrow(bcb, source, options)

			assert(bcb:dumpFunction(0) == [[
R0: vector [argument]
R1: mat3 [argument]
R2: userdata [argument]
U0: number
R6: any from 1 to 9
R3: vector from 0 to 30
MUL R3 R0 R0
LOADN R6 1
LOADN R4 3
LOADN R5 1
FORNPREP R4 L1
L0: GETIMPORT R7 1 [print]
MOVE R8 R6
CALL R7 1 0
FORNLOOP R4 L0
L1: GETIMPORT R4 1 [print]
MUL R5 R0 R1
CALL R4 1 0
GETIMPORT R4 1 [print]
MOVE R5 R2
CALL R4 1 0
GETIMPORT R4 1 [print]
MOVE R5 R3
CALL R4 1 0
GETUPVAL R4 0
GETIMPORT R5 3 [a]
ADD R4 R4 R5
SETUPVAL R4 0
GETIMPORT R4 3 [a]
RETURN R4 1
]])
		end)
	end,

	SourceRemarks = function()
		local source = [[
local a, b = ...

local function foo(x)
    return(math.abs(x))
end

return foo(a) + foo(assert(b))
]]

		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(bit32.bor(DumpFlags.Dump_Source, DumpFlags.Dump_Remarks))
		bcb:setDumpSource(source)

		local options = CompileOptions.new()
		options.optimizationLevel = 2

		Compiler.compileOrThrow(bcb, source, options)

		local remarks = bcb:dumpSourceRemarks()

		assert(remarks == [[
local a, b = ...

local function foo(x)
    -- remark: builtin math.abs/1
    return(math.abs(x))
end

-- remark: builtin assert/1
-- remark: inlining succeeded (cost 2, profit 2.50x, depth 0)
return foo(a) + foo(assert(b))
]])
	end,

	AssignmentConflict = function()
		-- assignments are left to right
		assert(compileFunction0("local a, b a, b = 1, 2") == [[
LOADNIL R0
LOADNIL R1
LOADN R0 1
LOADN R1 2
RETURN R0 0
]])

		-- if assignment of a local invalidates a direct register reference in later assignments, the value is assigned to a temp register first
		assert(compileFunction0("local a a, a[1] = 1, 2") == [[
LOADNIL R0
LOADN R1 1
LOADN R2 2
SETTABLEN R2 R0 1
MOVE R0 R1
RETURN R0 0
]])

		-- note that this doesn't happen if the local assignment happens last naturally
		assert(compileFunction0("local a a[1], a = 1, 2") == [[
LOADNIL R0
LOADN R2 1
LOADN R1 2
SETTABLEN R2 R0 1
MOVE R0 R1
RETURN R0 0
]])

		-- this will happen if assigned register is used in any table expression, including as an object...
		assert(compileFunction0("local a a, a.foo = 1, 2") == [[
LOADNIL R0
LOADN R1 1
LOADN R2 2
SETTABLEKS R2 R0 K0 ['foo']
MOVE R0 R1
RETURN R0 0
]])

		-- ... or a table index ...
		assert(compileFunction0("local a a, foo[a] = 1, 2") == [[
LOADNIL R0
GETIMPORT R1 1 [foo]
LOADN R2 1
LOADN R3 2
SETTABLE R3 R1 R0
MOVE R0 R2
RETURN R0 0
]])

		-- ... or both ...
		assert(compileFunction0("local a a, a[a] = 1, 2") == [[
LOADNIL R0
LOADN R1 1
LOADN R2 2
SETTABLE R2 R0 R0
MOVE R0 R1
RETURN R0 0
]])

		-- ... or both with two different locals ...
		assert(compileFunction0("local a, b a, b, a[b] = 1, 2, 3") == [[
LOADNIL R0
LOADNIL R1
LOADN R2 1
LOADN R3 2
LOADN R4 3
SETTABLE R4 R0 R1
MOVE R0 R2
MOVE R1 R3
RETURN R0 0
]])

		-- however note that if it participates in an expression on the left hand side, there's no point reassigning it since we'd compute the expr value
		-- into a temp register
		assert(compileFunction0("local a a, foo[a + 1] = 1, 2") == [[
LOADNIL R0
GETIMPORT R1 1 [foo]
ADDK R2 R0 K2 [1]
LOADN R0 1
LOADN R3 2
SETTABLE R3 R1 R2
RETURN R0 0
]])
	end,

	FastcallBytecode = function()
		-- direct global call
		assert(compileFunction0("return math.abs(-5)") == [[
LOADN R1 -5
FASTCALL1 2 R1 L0
GETIMPORT R0 2 [math.abs]
CALL R0 1 -1
L0: RETURN R0 -1
]])

		-- call through a local variable
		assert(compileFunction0("local abs = math.abs return abs(-5)") == [[
GETIMPORT R0 2 [math.abs]
LOADN R2 -5
FASTCALL1 2 R2 L0
MOVE R1 R0
CALL R1 1 -1
L0: RETURN R1 -1
]])

		-- call through an upvalue
		assert(compileFunction0("local abs = math.abs function foo() return abs(-5) end return foo()") == [[
LOADN R1 -5
FASTCALL1 2 R1 L0
GETUPVAL R0 0
CALL R0 1 -1
L0: RETURN R0 -1
]])

		-- mutating the global in the script breaks the optimization
		assert(compileFunction0("math = {} return math.abs(-5)") == [[
NEWTABLE R0 0 0
SETGLOBAL R0 K0 ['math']
GETGLOBAL R1 K0 ['math']
GETTABLEKS R0 R1 K1 ['abs']
LOADN R1 -5
CALL R0 1 -1
RETURN R0 -1
]])

		-- mutating the local in the script breaks the optimization
		assert(compileFunction0("local abs = math.abs abs = nil return abs(-5)") == [[
GETIMPORT R0 2 [math.abs]
LOADNIL R0
MOVE R1 R0
LOADN R2 -5
CALL R1 1 -1
RETURN R1 -1
]])

		-- mutating the global in the script breaks the optimization, even if you do this after computing the local (for simplicity)
		assert(compileFunction0("local abs = math.abs math = {} return abs(-5)") == [[
GETGLOBAL R1 K0 ['math']
GETTABLEKS R0 R1 K1 ['abs']
NEWTABLE R1 0 0
SETGLOBAL R1 K0 ['math']
MOVE R1 R0
LOADN R2 -5
CALL R1 1 -1
RETURN R1 -1
]])
	end,

	FastcallSelect = function()
		-- select(_, ...) compiles to a builtin call
		assert(compileFunction0("return (select('#', ...))") == [[
LOADK R1 K0 ['#']
FASTCALL1 57 R1 L0
GETIMPORT R0 2 [select]
GETVARARGS R2 -1
CALL R0 -1 1
L0: RETURN R0 1
]])

		-- more complex example: select inside a for loop bound + select from a iterator
		assert(compileFunction0([[
local sum = 0
for i=1, select('#', ...) do
    sum += select(i, ...)
end
return sum
]]) == [[
LOADN R0 0
LOADN R3 1
LOADK R5 K0 ['#']
FASTCALL1 57 R5 L0
GETIMPORT R4 2 [select]
GETVARARGS R6 -1
CALL R4 -1 1
L0: MOVE R1 R4
LOADN R2 1
FORNPREP R1 L3
L1: FASTCALL1 57 R3 L2
GETIMPORT R4 2 [select]
MOVE R5 R3
GETVARARGS R6 -1
CALL R4 -1 1
L2: ADD R0 R0 R4
FORNLOOP R1 L1
L3: RETURN R0 1
]])

		-- currently we assume a single value return to avoid dealing with stack resizing
		assert(compileFunction0("return select('#', ...)") == [[
GETIMPORT R0 1 [select]
LOADK R1 K2 ['#']
GETVARARGS R2 -1
CALL R0 -1 -1
RETURN R0 -1
]])

		-- note that select with a non-variadic second argument doesn't get optimized
		assert(compileFunction0("return select('#')") == [[
GETIMPORT R0 1 [select]
LOADK R1 K2 ['#']
CALL R0 1 -1
RETURN R0 -1
]])

		-- note that select with a non-variadic second argument doesn't get optimized
		assert(compileFunction0("return select('#', foo())") == [[
GETIMPORT R0 1 [select]
LOADK R1 K2 ['#']
GETIMPORT R2 4 [foo]
CALL R2 0 -1
CALL R0 -1 -1
RETURN R0 -1
]])
	end,

	LotsOfParameters = function()
		local source = [[
select("#",1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1)
]]

		local success, e: CompileError = pcall(function()
			local bcb = BytecodeBuilder.new()
			Compiler.compileOrThrow(bcb, source)
		end)

		if success then
			error("Expected exception")
		else
			assert(e:what() == "Out of registers when trying to allocate 265 registers: exceeded limit 255")
		end
	end,

	LotsOfIndexers = function()
		local source = [[
function u(t)for t in s(t.l.l.l.l.l.l.l.l.l.l.l.l.l.l.n.l.l.l.l.l.l.l.l.l.l.l.l.n.l.l.l.l.l.l.n.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.n.l.l.l.g.l.l.l.l.l.l.l.l.l.l.l.l.l.n.l.l.l.l.l.t.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.r.l.l.l.l.l.l.n.l.l.l.l.l.l.l.l.l.l.l.l.n.l.l.l.l.l.l.n.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.g.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.n.l.l.l.l.l.l.l.l.n.l.l.l.l.l.l.l.l.l.l.l.l.n.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.r.n.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.n.l.l.l.n.l.l.l.l.l.l.l.n.l.l.l.l.l.l.l.l.l.l..l,l)do end
end
]]

		local success, e: CompileError = pcall(function()
			local bcb = BytecodeBuilder.new()
			Compiler.compileOrThrow(bcb, source)
		end)

		if success then
			error("Expected exception")
		else
			assert(e:what() == "Out of registers when trying to allocate 1 registers: exceeded limit 255")
		end
	end,

	AsConstant = function()
		local source = [[
--!strict
return (1 + 2) :: number
]]

		local options = CompileOptions.new()
		local parseOptions = ParseOptions.new()

		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(DumpFlags.Dump_Code)
		Compiler.compileOrThrow(bcb, source, options, parseOptions)

		assert(bcb:dumpFunction(0) == [[
LOADN R0 3
RETURN R0 1
]])
	end,

	PreserveNegZero = function()
		assert(compileFunction0("return 0") == [[
LOADN R0 0
RETURN R0 1
]])

		assert(compileFunction0("return -0") == [[
LOADK R0 K0 [-0]
RETURN R0 1
]])
	end,

	CaptureImmutable = function()
		-- capture argument: note capture by value
		assert(compileFunction("function foo(a, b) return function() return a end end", 1) == [[
NEWCLOSURE R2 P0
CAPTURE VAL R0
RETURN R2 1
]])

		-- capture mutable argument: note capture by reference + close
		assert(compileFunction("function foo(a, b) a = 1 return function() return a end end", 1) == [[
LOADN R0 1
NEWCLOSURE R2 P0
CAPTURE REF R0
CLOSEUPVALS R0
RETURN R2 1
]])

		-- capture two arguments, one mutable, one immutable
		assert(compileFunction("function foo(a, b) a = 1 return function() return a + b end end", 1) == [[
LOADN R0 1
NEWCLOSURE R2 P0
CAPTURE REF R0
CAPTURE VAL R1
CLOSEUPVALS R0
RETURN R2 1
]])

		-- capture self
		assert(compileFunction("function bar:foo(a, b) return function() return self end end", 1) == [[
NEWCLOSURE R3 P0
CAPTURE VAL R0
RETURN R3 1
]])

		-- capture mutable self (who mutates self?!?)
		assert(compileFunction("function bar:foo(a, b) self = 42 return function() return self end end", 1) == [[
LOADN R0 42
NEWCLOSURE R3 P0
CAPTURE REF R0
CLOSEUPVALS R0
RETURN R3 1
]])

		-- capture upvalue: one mutable, one immutable
		assert(compileFunction("local a, b = math.rand() a = 42 function foo() return function() return a + b end end", 1) == [[
NEWCLOSURE R0 P0
CAPTURE UPVAL U0
CAPTURE UPVAL U1
RETURN R0 1
]])

		-- recursive capture
		assert(compileFunction("local function foo() return foo() end", 1) == [[
DUPCLOSURE R0 K0 ['foo']
CAPTURE VAL R0
RETURN R0 0
]])

		-- multi-level recursive capture
		assert(compileFunction("local function foo() return function() return foo() end end", 1) == [[
DUPCLOSURE R0 K0 []
CAPTURE UPVAL U0
RETURN R0 1
]])

		-- multi-level recursive capture where function isn't top-level
		-- note: this should probably be optimized to DUPCLOSURE but doing that requires a different upval tracking flow in the compiler
		assert(compileFunction([[
local function foo()
    local function bar()
        return function() return bar() end
    end
end
]], 1) == [[
NEWCLOSURE R0 P0
CAPTURE UPVAL U0
RETURN R0 1
]])
	end,

	OutOfLocals = function()
		local sourcePieces = table.create(201)

		for i = 0, 199 do
			table.insert(sourcePieces, string.format("local foo%d\n", i))
		end

		table.insert(sourcePieces, "local bar\n")

		local source = table.concat(sourcePieces)

		local options = CompileOptions.new()
		options.debugLevel = 2 -- make sure locals aren't elided by requesting their debug info

		local success, e: CompileError = pcall(function()
			local bcb = BytecodeBuilder.new()
			Compiler.compileOrThrow(bcb, source, options)
		end)

		if success then
			error("Expected CompileError")
		else
			assert(e:getLocation().begin.line + 1 == 201)
			assert(e:what() == "Out of local registers when trying to allocate bar: exceeded limit 200")
		end
	end,

	OutOfUpvalues = function()
		local sourcePieces = table.create(753)

		for i = 0, 149 do
			table.insert(sourcePieces, string.format("local foo%d\n", i))
			table.insert(sourcePieces, string.format("foo%d = 42\n", i))
		end

		table.insert(sourcePieces, "function foo()\n")

		for i = 0, 149 do
			table.insert(sourcePieces, string.format("local bar%d\n", i))
			table.insert(sourcePieces, string.format("bar%d = 42\n", i))
		end

		table.insert(sourcePieces, "function bar()\n")

		for i = 0, 149 do
			table.insert(sourcePieces, string.format("print(foo%d, bar%d)\n", i, i))
		end

		table.insert(sourcePieces, "end\nend\n")

		local source = table.concat(sourcePieces)

		local success, e: CompileError = pcall(function()
			local bcb = BytecodeBuilder.new()
			Compiler.compileOrThrow(bcb, source)
		end)

		if success then
			error("Expected CompileError")
		else
			assert(e:getLocation().begin.line + 1 == 201)
			assert(e:what() == "Out of upvalue registers when trying to allocate foo100: exceeded limit 200")
		end
	end,

	OutOfRegisters = function()
		local sourcePieces = table.create(303)

		table.insert(sourcePieces, "print(\n")

		for i = 0, 149 do
			table.insert(sourcePieces, string.format("%d,\n", i))
		end

		table.insert(sourcePieces, "table.pack(\n")

		for i = 0, 149 do
			table.insert(sourcePieces, string.format("%d,\n", i))
		end

		table.insert(sourcePieces, "42))\n")

		local source = table.concat(sourcePieces)

		local success, e: CompileError = pcall(function()
			local bcb = BytecodeBuilder.new()
			Compiler.compileOrThrow(bcb, source)
		end)

		if success then
			error("Expected CompileError")
		else
			assert(e:getLocation().begin.line + 1 == 152)
			assert(e:what() == "Out of registers when trying to allocate 152 registers: exceeded limit 255")
		end
	end,

	FastCallImportFallback = function()
		local sourcePieces = table.create(1026)

		table.insert(sourcePieces, "local t = {}\n")

		-- we need to exhaust the 10-bit constant space to block GETIMPORT from being emitted
		for i = 1, 1024 do
			table.insert(sourcePieces, string.format("t[%d] = \"%d\"\n", i, i))
		end

		table.insert(sourcePieces, "return math.abs(-1)\n")

		local source = table.concat(sourcePieces)

		local code = compileFunction0(source)

		local insns = string.split(code, "\n")
		
		local fragmentPieces = table.create(16)

		for i = 9, 2, -1 do
			table.insert(fragmentPieces, insns[#insns - i])
			table.insert(fragmentPieces, "\n")
		end

		local fragment = table.concat(fragmentPieces)

		-- note: it's important that GETGLOBAL below doesn't overwrite R2
		assert(fragment == [[
LOADN R1 1024
LOADK R2 K1023 ['1024']
SETTABLE R2 R0 R1
LOADN R2 -1
FASTCALL1 2 R2 L0
GETGLOBAL R3 K1024 ['math']
GETTABLEKS R1 R3 K1025 ['abs']
CALL R1 1 -1
]])
	end,

	CompoundAssignment = function()
		-- globals vs constants
		assert(compileFunction0("a += 1") == [[
GETGLOBAL R0 K0 ['a']
ADDK R0 R0 K1 [1]
SETGLOBAL R0 K0 ['a']
RETURN R0 0
]])

		-- globals vs expressions
		assert(compileFunction0("a -= a") == [[
GETGLOBAL R0 K0 ['a']
GETGLOBAL R1 K0 ['a']
SUB R0 R0 R1
SETGLOBAL R0 K0 ['a']
RETURN R0 0
]])

		-- locals vs locals
		assert(compileFunction0("local a = 1 a /= a") == [[
LOADN R0 1
DIV R0 R0 R0
RETURN R0 0
]])

		-- locals vs expressions
		assert(compileFunction0("local a = 1 a /= a + 1") == [[
LOADN R0 1
ADDK R1 R0 K0 [1]
DIV R0 R0 R1
RETURN R0 0
]])

		-- upvalues
		assert(compileFunction0("local a = 1 function foo() a += 4 end") == [[
GETUPVAL R0 0
ADDK R0 R0 K0 [4]
SETUPVAL R0 0
RETURN R0 0
]])

		-- table variants (indexed by string, number, variable)
		assert(compileFunction0("local a = {} a.foo += 5") == [[
NEWTABLE R0 0 0
GETTABLEKS R1 R0 K0 ['foo']
ADDK R1 R1 K1 [5]
SETTABLEKS R1 R0 K0 ['foo']
RETURN R0 0
]])

		assert(compileFunction0("local a = {} a[1] += 5") == [[
NEWTABLE R0 0 0
GETTABLEN R1 R0 1
ADDK R1 R1 K0 [5]
SETTABLEN R1 R0 1
RETURN R0 0
]])

		assert(compileFunction0("local a = {} a[a] += 5") == [[
NEWTABLE R0 0 0
GETTABLE R1 R0 R0
ADDK R1 R1 K0 [5]
SETTABLE R1 R0 R0
RETURN R0 0
]])

		-- left hand side is evaluated once
		assert(compileFunction0("foo()[bar()] += 5") == [[
GETIMPORT R0 1 [foo]
CALL R0 0 1
GETIMPORT R1 3 [bar]
CALL R1 0 1
GETTABLE R2 R0 R1
ADDK R2 R2 K4 [5]
SETTABLE R2 R0 R1
RETURN R0 0
]])
	end,

	CompoundAssignmentConcat = function()
		-- basic concat
		assert(compileFunction0("local a = '' a ..= 'a'") == [[
LOADK R0 K0 ['']
MOVE R1 R0
LOADK R2 K1 ['a']
CONCAT R0 R1 R2
RETURN R0 0
]])

		-- concat chains
		assert(compileFunction0("local a = '' a ..= 'a' .. 'b'") == [[
LOADK R0 K0 ['']
MOVE R1 R0
LOADK R2 K1 ['a']
LOADK R3 K2 ['b']
CONCAT R0 R1 R3
RETURN R0 0
]])

		assert(compileFunction0("local a = '' a ..= 'a' .. 'b' .. 'c'") == [[
LOADK R0 K0 ['']
MOVE R1 R0
LOADK R2 K1 ['a']
LOADK R3 K2 ['b']
LOADK R4 K3 ['c']
CONCAT R0 R1 R4
RETURN R0 0
]])

		-- concat on non-local
		assert(compileFunction0("_VERSION ..= 'a' .. 'b'") == [[
GETGLOBAL R1 K0 ['_VERSION']
LOADK R2 K1 ['a']
LOADK R3 K2 ['b']
CONCAT R0 R1 R3
SETGLOBAL R0 K0 ['_VERSION']
RETURN R0 0
]])
	end,

	JumpTrampoline = function()
		local sourcePieces = table.create(20006)
		table.insert(sourcePieces, "local sum = 0\n")
		table.insert(sourcePieces, "for i=1,3 do\n")
		for i = 1, 10000 do
			table.insert(sourcePieces, "sum = sum + i\n")
			table.insert(sourcePieces, "if sum > 150000 then break end\n")
		end
		table.insert(sourcePieces, "end\n")
		table.insert(sourcePieces, "return sum\n")
		
		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(DumpFlags.Dump_Code)
		Compiler.compileOrThrow(bcb, table.concat(sourcePieces))

		local bcs = bcb:dumpFunction(0)

		local insns = string.split(bcs, "\n")
		table.remove(insns, #insns)

		-- FORNPREP and early JUMPs (break) need to go through a trampoline
		local headPieces = table.create(15)
		for i = 1, 16 do
			table.insert(headPieces, insns[i] .. "\n")
		end
		local head = table.concat(headPieces)

		assert(head == [[
LOADN R0 0
LOADN R3 1
LOADN R1 3
LOADN R2 1
JUMP L1
L0: JUMPX L14543
L1: FORNPREP R1 L0
L2: ADD R0 R0 R3
LOADK R4 K0 [150000]
JUMP L4
L3: JUMPX L14543
L4: JUMPIFLT R4 R0 L3
ADD R0 R0 R3
LOADK R4 K0 [150000]
JUMP L6
L5: JUMPX L14543
]])

		-- FORNLOOP has to go through a trampoline since the jump is back to the beginning of the function
		-- however, late JUMPs (break) don't need a trampoline since the loop end is really close by
		local tailPieces = {}
		for i = 44540, #insns do
			table.insert(tailPieces, insns[i] .. "\n")
		end
		local tail = table.concat(tailPieces)

		assert(tail == [[
ADD R0 R0 R3
LOADK R4 K0 [150000]
JUMPIFLT R4 R0 L14543
ADD R0 R0 R3
LOADK R4 K0 [150000]
JUMPIFLT R4 R0 L14543
JUMP L14542
L14541: JUMPX L2
L14542: FORNLOOP R1 L14541
L14543: RETURN R0 1
]])
	end,

	CompileBytecode = function()
		-- This is a coverage test, it just exercises bytecode dumping for correct and malformed code
		Compiler.compile("return 5")
		Compiler.compile("this is not valid lua, right?")
	end,

	NestedNamecall = function()
		assert(compileFunction0([[
local obj = ...
return obj:Method(1):Method(2):Method(3)
]]) == [[
GETVARARGS R0 1
LOADN R3 1
NAMECALL R1 R0 K0 ['Method']
CALL R1 2 1
LOADN R3 2
NAMECALL R1 R1 K0 ['Method']
CALL R1 2 1
LOADN R3 3
NAMECALL R1 R1 K0 ['Method']
CALL R1 2 -1
RETURN R1 -1
]])
	end,

	ElideLocals = function()
		-- simple local elision: all locals are constant
		assert(compileFunction0([[
local a, b = 1, 2
return a + b
]]) == [[
LOADN R0 3
RETURN R0 1
]])

		-- side effecting expressions block local elision
		assert(compileFunction0([[
local a = g()
return a
]]) == [[
GETIMPORT R0 1 [g]
CALL R0 0 1
RETURN R0 1
]])

		-- ... even if they are not used
		assert(compileFunction0([[
local a = 1, g()
return a
]]) == [[
LOADN R0 1
GETIMPORT R1 1 [g]
CALL R1 0 1
RETURN R0 1
]])
	end,

	ConstantJumpCompare = function()
		assert(compileFunction0([[
local obj = ...
local b = obj == 1
]]) == [[
GETVARARGS R0 1
JUMPXEQKN R0 K0 L0 [1]
LOADB R1 0 +1
L0: LOADB R1 1
L1: RETURN R0 0
]])

		assert(compileFunction0([[
local obj = ...
local b = 1 == obj
]]) == [[
GETVARARGS R0 1
JUMPXEQKN R0 K0 L0 [1]
LOADB R1 0 +1
L0: LOADB R1 1
L1: RETURN R0 0
]])

		assert(compileFunction0([[
local obj = ...
local b = "Hello, Sailor!" == obj
]]) == [[
GETVARARGS R0 1
JUMPXEQKS R0 K0 L0 ['Hello, Sailor!']
LOADB R1 0 +1
L0: LOADB R1 1
L1: RETURN R0 0
]])

		assert(compileFunction0([[
local obj = ...
local b = nil == obj
]]) == [[
GETVARARGS R0 1
JUMPXEQKNIL R0 L0
LOADB R1 0 +1
L0: LOADB R1 1
L1: RETURN R0 0
]])

		assert(compileFunction0([[
local obj = ...
local b = true == obj
]]) == [[
GETVARARGS R0 1
JUMPXEQKB R0 1 L0
LOADB R1 0 +1
L0: LOADB R1 1
L1: RETURN R0 0
]])

		assert(compileFunction0([[
local obj = ...
local b = nil ~= obj
]]) == [[
GETVARARGS R0 1
JUMPXEQKNIL R0 L0 NOT
LOADB R1 0 +1
L0: LOADB R1 1
L1: RETURN R0 0
]])

		-- table literals should not generate IFEQK variants
		assert(compileFunction0([[
local obj = ...
local b = obj == {}
]]) == [[
GETVARARGS R0 1
NEWTABLE R2 0 0
JUMPIFEQ R0 R2 L0
LOADB R1 0 +1
L0: LOADB R1 1
L1: RETURN R0 0
]])
	end,

	TableConstantStringIndex = function()
		assert(compileFunction0([[
local t = { a = 2 }
return t['a']
]]) == [[
DUPTABLE R0 1
LOADN R1 2
SETTABLEKS R1 R0 K0 ['a']
GETTABLEKS R1 R0 K0 ['a']
RETURN R1 1
]])

		assert(compileFunction0([[
local t = {}
t['a'] = 2
]]) == [[
NEWTABLE R0 0 0
LOADN R1 2
SETTABLEKS R1 R0 K0 ['a']
RETURN R0 0
]])
	end,

	Coverage = function()
		-- basic statement coverage
		assert(compileFunction0Coverage([[

print(1)
print(2)
]], 1) == [[
2: COVERAGE
2: GETIMPORT R0 1 [print]
2: LOADN R1 1
2: CALL R0 1 0
3: COVERAGE
3: GETIMPORT R0 1 [print]
3: LOADN R1 2
3: CALL R0 1 0
4: RETURN R0 0
]])

		-- branching
		assert(compileFunction0Coverage([[

if x then
    print(1)
else
    print(2)
end
]], 1) == [[
2: COVERAGE
2: GETIMPORT R0 1 [x]
2: JUMPIFNOT R0 L0
3: COVERAGE
3: GETIMPORT R0 3 [print]
3: LOADN R1 1
3: CALL R0 1 0
3: RETURN R0 0
5: L0: COVERAGE
5: GETIMPORT R0 3 [print]
5: LOADN R1 2
5: CALL R0 1 0
7: RETURN R0 0
]])

		-- branching with comments
		-- note that commented lines don't have COVERAGE insns!
		assert(compileFunction0Coverage([[

if x then
    -- first
    print(1)
else
    -- second
    print(2)
end
]], 1) == [[
2: COVERAGE
2: GETIMPORT R0 1 [x]
2: JUMPIFNOT R0 L0
4: COVERAGE
4: GETIMPORT R0 3 [print]
4: LOADN R1 1
4: CALL R0 1 0
4: RETURN R0 0
7: L0: COVERAGE
7: GETIMPORT R0 3 [print]
7: LOADN R1 2
7: CALL R0 1 0
9: RETURN R0 0
]])

		-- expression coverage for table literals
		-- note: duplicate COVERAGE instructions are there since we don't deduplicate expr/stat
		assert(compileFunction0Coverage([[

local c = ...
local t = {
    a = 1,
    b = 2,
    c = c
}
]], 2) == [[
2: COVERAGE
2: COVERAGE
2: GETVARARGS R0 1
3: COVERAGE
3: COVERAGE
3: DUPTABLE R1 3
4: COVERAGE
4: COVERAGE
4: LOADN R2 1
4: SETTABLEKS R2 R1 K0 ['a']
5: COVERAGE
5: COVERAGE
5: LOADN R2 2
5: SETTABLEKS R2 R1 K1 ['b']
6: COVERAGE
6: SETTABLEKS R0 R1 K2 ['c']
8: RETURN R0 0
]])
	end,

	ConstantClosure = function()
		-- closures without upvalues are created when bytecode is loaded
		assert(compileFunction([[
return function() end
]], 1) == [[
DUPCLOSURE R0 K0 []
RETURN R0 1
]])

		-- they can access globals just fine
		assert(compileFunction([[
return function() print("hi") end
]], 1) == [[
DUPCLOSURE R0 K0 []
RETURN R0 1
]])

		-- if they need upvalues, we can't create them before running the code (but see SharedClosure test)
		assert(compileFunction([[
function test()
    local print = print
    return function() print("hi") end
end
]], 1) == [[
GETIMPORT R0 1 [print]
NEWCLOSURE R1 P0
CAPTURE VAL R0
RETURN R1 1
]])

		-- if they don't need upvalues but we sense that environment may be modified, we disable this to avoid fenv-related identity confusion
		assert(compileFunction([[
setfenv(1, {})
return function() print("hi") end
]], 1) == [[
GETIMPORT R0 1 [setfenv]
LOADN R1 1
NEWTABLE R2 0 0
CALL R0 2 0
NEWCLOSURE R0 P0
RETURN R0 1
]])

		-- note that fenv analysis isn't flow-sensitive right now, which is sort of a feature
		assert(compileFunction([[
if false then setfenv(1, {}) end
return function() print("hi") end
]], 1) == [[
NEWCLOSURE R0 P0
RETURN R0 1
]])
	end,

	SharedClosure = function()
		-- closures can be shared even if functions refer to upvalues, as long as upvalues are top-level
		assert(compileFunction([[
local val = ...

local function foo()
    return function() return val end
end
]], 1) == [[
DUPCLOSURE R0 K0 []
CAPTURE UPVAL U0
RETURN R0 1
]])

		-- ... as long as the values aren't mutated.
		assert(compileFunction([[
local val = ...

local function foo()
    return function() return val end
end

val = 5
]], 1) == [[
NEWCLOSURE R0 P0
CAPTURE UPVAL U0
RETURN R0 1
]])

		-- making the upvalue non-toplevel disables the optimization since it's likely that it will change
		assert(compileFunction([[
local function foo(val)
    return function() return val end
end
]], 1) == [[
NEWCLOSURE R1 P0
CAPTURE VAL R0
RETURN R1 1
]])

		-- the upvalue analysis is transitive through local functions, which allows for code reuse to not defeat the optimization
		assert(compileFunction([[
local val = ...

local function foo()
    local function bar()
        return val
    end

    return function() return bar() end
end
]], 2) == [[
DUPCLOSURE R0 K0 ['bar']
CAPTURE UPVAL U0
DUPCLOSURE R1 K1 []
CAPTURE VAL R0
RETURN R1 1
]])

		-- as such, if the upvalue that we reach transitively isn't top-level we fall back to newclosure
		assert(compileFunction([[
local function foo(val)
    local function bar()
        return val
    end

    return function() return bar() end
end
]], 2) == [[
NEWCLOSURE R1 P0
CAPTURE VAL R0
NEWCLOSURE R2 P1
CAPTURE VAL R1
RETURN R2 1
]])

		-- we also allow recursive function captures to share the object, even when it's not top-level
		assert(compileFunction("function test() local function foo() return foo() end end", 1) == [[
DUPCLOSURE R0 K0 ['foo']
CAPTURE VAL R0
RETURN R0 0
]])

		-- multi-level recursive capture where function isn't top-level fails however.
		-- note: this should probably be optimized to DUPCLOSURE but doing that requires a different upval tracking flow in the compiler
		assert(compileFunction([[
local function foo()
    local function bar()
        return function() return bar() end
    end
end
]], 1) == [[
NEWCLOSURE R0 P0
CAPTURE UPVAL U0
RETURN R0 1
]])

		-- top level upvalues inside loops should not be shared -- note that the bytecode below only uses NEWCLOSURE
		assert(compileFunction([[
for i=1,10 do
    print(function() return i end)
end

for k,v in pairs(...) do
    print(function() return k end)
end

for i=1,10 do
    local j = i
    print(function() return j end)
end
]], 3) == [[
LOADN R2 1
LOADN R0 10
LOADN R1 1
FORNPREP R0 L1
L0: GETIMPORT R3 1 [print]
NEWCLOSURE R4 P0
CAPTURE VAL R2
CALL R3 1 0
FORNLOOP R0 L0
L1: GETIMPORT R0 3 [pairs]
GETVARARGS R1 -1
CALL R0 -1 3
FORGPREP_NEXT R0 L3
L2: GETIMPORT R5 1 [print]
NEWCLOSURE R6 P1
CAPTURE VAL R3
CALL R5 1 0
L3: FORGLOOP R0 L2 2
LOADN R2 1
LOADN R0 10
LOADN R1 1
FORNPREP R0 L5
L4: GETIMPORT R3 1 [print]
NEWCLOSURE R4 P2
CAPTURE VAL R2
CALL R3 1 0
FORNLOOP R0 L4
L5: RETURN R0 0
]])
	end,

	MutableGlobals = function()
		local source = [[
print()
Game.print()
Workspace.print()
_G.print()
game.print()
plugin.print()
script.print()
shared.print()
workspace.print()
]]

		-- Check Roblox globals are no longer here
		assert(compileFunction0(source) == [[
GETIMPORT R0 1 [print]
CALL R0 0 0
GETIMPORT R0 3 [Game.print]
CALL R0 0 0
GETIMPORT R0 5 [Workspace.print]
CALL R0 0 0
GETIMPORT R1 7 [_G]
GETTABLEKS R0 R1 K0 ['print']
CALL R0 0 0
GETIMPORT R0 9 [game.print]
CALL R0 0 0
GETIMPORT R0 11 [plugin.print]
CALL R0 0 0
GETIMPORT R0 13 [script.print]
CALL R0 0 0
GETIMPORT R0 15 [shared.print]
CALL R0 0 0
GETIMPORT R0 17 [workspace.print]
CALL R0 0 0
RETURN R0 0
]])

		-- Check we can add them back
		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(DumpFlags.Dump_Code)
		local options = CompileOptions.new()
		local mutableGlobals = {"Game", "Workspace", "game", "plugin", "script", "shared", "workspace"}
		options.mutableGlobals = mutableGlobals
		Compiler.compileOrThrow(bcb, source, options)

		assert(bcb:dumpFunction(0) == [[
GETIMPORT R0 1 [print]
CALL R0 0 0
GETIMPORT R1 3 [Game]
GETTABLEKS R0 R1 K0 ['print']
CALL R0 0 0
GETIMPORT R1 5 [Workspace]
GETTABLEKS R0 R1 K0 ['print']
CALL R0 0 0
GETIMPORT R1 7 [_G]
GETTABLEKS R0 R1 K0 ['print']
CALL R0 0 0
GETIMPORT R1 9 [game]
GETTABLEKS R0 R1 K0 ['print']
CALL R0 0 0
GETIMPORT R1 11 [plugin]
GETTABLEKS R0 R1 K0 ['print']
CALL R0 0 0
GETIMPORT R1 13 [script]
GETTABLEKS R0 R1 K0 ['print']
CALL R0 0 0
GETIMPORT R1 15 [shared]
GETTABLEKS R0 R1 K0 ['print']
CALL R0 0 0
GETIMPORT R1 17 [workspace]
GETTABLEKS R0 R1 K0 ['print']
CALL R0 0 0
RETURN R0 0
]])
	end,

	ConstantsNoFolding = function()
		local source = "return nil, true, 42, 'hello'"

		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(DumpFlags.Dump_Code)
		local options = CompileOptions.new()
		options.optimizationLevel = 0
		Compiler.compileOrThrow(bcb, source, options)

		assert(bcb:dumpFunction(0) == [[
LOADNIL R0
LOADB R1 1
LOADK R2 K0 [42]
LOADK R3 K1 ['hello']
RETURN R0 4
]])
	end,

	VectorFastCall = function()
		local source = "return Vector3.new(1, 2, 3)"

		local bcb = BytecodeBuilder.new()
		bcb:setDumpFlags(DumpFlags.Dump_Code)
		local options = CompileOptions.new()
		options.vectorLib = "Vector3"
		options.vectorCtor = "new"
		Compiler.compileOrThrow(bcb, source, options)

		assert(bcb:dumpFunction(0) == [[
LOADN R1 1
LOADN R2 2
LOADN R3 3
FASTCALL 54 L0
GETIMPORT R0 2 [Vector3.new]
CALL R0 3 -1
L0: RETURN R0 -1
]])
	end,

	VectorLiterals = function()
		assert(compileFunction("return Vector3.new(1, 2, 3)", 0, 2, true) == [[
LOADK R0 K0 [1, 2, 3]
RETURN R0 1
]])

		assert(compileFunction("print(Vector3.new(1, 2, 3))", 0, 2, true) == [[
GETIMPORT R0 1 [print]
LOADK R1 K2 [1, 2, 3]
CALL R0 1 0
RETURN R0 0
]])

		assert(compileFunction("print(Vector3.new(1, 2, 3, 4))", 0, 2, true) == [[
GETIMPORT R0 1 [print]
LOADK R1 K2 [1, 2, 3, 4]
CALL R0 1 0
RETURN R0 0
]])

		assert(compileFunction("return Vector3.new(0, 0, 0), Vector3.new(-0, 0, 0)", 0, 2, true) == [[
LOADK R0 K0 [0, 0, 0]
LOADK R1 K1 [-0, 0, 0]
RETURN R0 2
]])

		assert(compileFunction("return type(Vector3.new(0, 0, 0))", 0, 2, true) == [[
LOADK R0 K0 ['vector']
RETURN R0 1
]])
	end,

	TypeAssertion = function()
		-- validate that type assertions work with the compiler and that the code inside type assertion isn't evaluated
		assert(compileFunction0([[
print(foo() :: typeof(error("compile time")))
]]) == [[
GETIMPORT R0 1 [print]
GETIMPORT R1 3 [foo]
CALL R1 0 1
CALL R0 1 0
RETURN R0 0
]])

		-- note that above, foo() is treated as single-arg function; removing type assertion changes the bytecode
		assert(compileFunction0([[
print(foo())
]]) == [[
GETIMPORT R0 1 [print]
GETIMPORT R1 3 [foo]
CALL R1 0 -1
CALL R0 -1 0
RETURN R0 0
]])
	end,

	Arithmetics = function()
		-- basic arithmetics codegen with non-constants
		assert(compileFunction0([[
local a, b = ...
return a + b, a - b, a / b, a * b, a % b, a ^ b
]]) == [[
GETVARARGS R0 2
ADD R2 R0 R1
SUB R3 R0 R1
DIV R4 R0 R1
MUL R5 R0 R1
MOD R6 R0 R1
POW R7 R0 R1
RETURN R2 6
]])

		-- basic arithmetics codegen with constants on the right side
		-- note that we don't simplify these expressions as we don't know the type of a
		assert(compileFunction0([[
local a = ...
return a + 1, a - 1, a / 1, a * 1, a % 1, a ^ 1
]]) == [[
GETVARARGS R0 1
ADDK R1 R0 K0 [1]
SUBK R2 R0 K0 [1]
DIVK R3 R0 K0 [1]
MULK R4 R0 K0 [1]
MODK R5 R0 K0 [1]
POWK R6 R0 K0 [1]
RETURN R1 6
]])
	end,

	LoopUnrollBasic = function()
		-- forward loops
		assert(compileFunction([[
local t = {}
for i=1,2 do
    t[i] = i
end
return t
]], 0, 2) == [[
NEWTABLE R0 0 2
LOADN R1 1
SETTABLEN R1 R0 1
LOADN R1 2
SETTABLEN R1 R0 2
RETURN R0 1
]])

		-- backward loops
		assert(compileFunction([[
local t = {}
for i=2,1,-1 do
    t[i] = i
end
return t
]], 0, 2) == [[
NEWTABLE R0 0 0
LOADN R1 2
SETTABLEN R1 R0 2
LOADN R1 1
SETTABLEN R1 R0 1
RETURN R0 1
]])

		-- loops with step that doesn't divide to-from
		assert(compileFunction([[
local t = {}
for i=1,4,2 do
    t[i] = i
end
return t
]], 0, 2) == [[
NEWTABLE R0 0 0
LOADN R1 1
SETTABLEN R1 R0 1
LOADN R1 3
SETTABLEN R1 R0 3
RETURN R0 1
]])

		-- empty loops
		assert(compileFunction([[
for i=2,1 do
end
]], 0, 2) == [[
RETURN R0 0
]])
	end,

	LoopUnrollNested = function()
		-- we can unroll nested loops just fine
		assert(compileFunction([[
local t = {}
for i=0,1 do
    for j=0,1 do
        t[i*2+(j+1)] = 0
    end
end
]], 0, 2) == [[
NEWTABLE R0 0 0
LOADN R1 0
SETTABLEN R1 R0 1
LOADN R1 0
SETTABLEN R1 R0 2
LOADN R1 0
SETTABLEN R1 R0 3
LOADN R1 0
SETTABLEN R1 R0 4
RETURN R0 0
]])

		-- if the inner loop is too expensive, we won't unroll the outer loop though, but we'll still unroll the inner loop!
		assert(compileFunction([[
local t = {}
for i=0,3 do
    for j=0,3 do
        t[i*4+(j+1)] = 0
    end
end
]], 0, 2) == [[
NEWTABLE R0 0 0
LOADN R3 0
LOADN R1 3
LOADN R2 1
FORNPREP R1 L1
L0: MULK R5 R3 K1 [4]
ADDK R4 R5 K0 [1]
LOADN R5 0
SETTABLE R5 R0 R4
MULK R5 R3 K1 [4]
ADDK R4 R5 K2 [2]
LOADN R5 0
SETTABLE R5 R0 R4
MULK R5 R3 K1 [4]
ADDK R4 R5 K3 [3]
LOADN R5 0
SETTABLE R5 R0 R4
MULK R5 R3 K1 [4]
ADDK R4 R5 K1 [4]
LOADN R5 0
SETTABLE R5 R0 R4
FORNLOOP R1 L0
L1: RETURN R0 0
]])

		-- note, we sometimes can even unroll a loop with varying internal iterations
		assert(compileFunction([[
local t = {}
for i=0,1 do
    for j=0,i do
        t[i*2+(j+1)] = 0
    end
end
]], 0, 2) == [[
NEWTABLE R0 0 0
LOADN R1 0
SETTABLEN R1 R0 1
LOADN R1 0
SETTABLEN R1 R0 3
LOADN R1 0
SETTABLEN R1 R0 4
RETURN R0 0
]])
	end,

	LoopUnrollUnsupported = function()
		-- can't unroll loops with non-constant bounds
		assert(compileFunction([[
for i=x,y,z do
end
]], 0, 2) == [[
GETIMPORT R2 1 [x]
GETIMPORT R0 3 [y]
GETIMPORT R1 5 [z]
FORNPREP R0 L1
L0: FORNLOOP R0 L0
L1: RETURN R0 0
]])

		-- can't unroll loops with bounds where we can't compute trip count
		assert(compileFunction([[
for i=1,1,0 do
end
]], 0, 2) == [[
LOADN R2 1
LOADN R0 1
LOADN R1 0
FORNPREP R0 L1
L0: FORNLOOP R0 L0
L1: RETURN R0 0
]])

		-- can't unroll loops with bounds that might be imprecise (non-integer)
		assert(compileFunction([[
for i=1,2,0.1 do
end
]], 0, 2) == [[
LOADN R2 1
LOADN R0 2
LOADK R1 K0 [0.10000000000000001]
FORNPREP R0 L1
L0: FORNLOOP R0 L0
L1: RETURN R0 0
]])

		-- can't unroll loops if the bounds are too large, as it might overflow trip count math
		assert(compileFunction([[
for i=4294967295,4294967296 do
end
]], 0, 2) == [[
LOADK R2 K0 [4294967295]
LOADK R0 K1 [4294967296]
LOADN R1 1
FORNPREP R0 L1
L0: FORNLOOP R0 L0
L1: RETURN R0 0
]])
	end,

	LoopUnrollControlFlow = function()
		ScopedVariable({
			LuauCompileLoopUnrollThreshold = 50,
			LuauCompileLoopUnrollThresholdMaxBoost = 300
		} :: FV, function()
			-- break jumps to the end
			assert(compileFunction([[
for i=1,3 do
    if math.random() < 0.5 then
        break
    end
end
]], 0, 2) == [[
GETIMPORT R0 2 [math.random]
CALL R0 0 1
LOADK R1 K3 [0.5]
JUMPIFLT R0 R1 L0
GETIMPORT R0 2 [math.random]
CALL R0 0 1
LOADK R1 K3 [0.5]
JUMPIFLT R0 R1 L0
GETIMPORT R0 2 [math.random]
CALL R0 0 1
LOADK R1 K3 [0.5]
JUMPIFLT R0 R1 L0
L0: RETURN R0 0
]])

			-- continue jumps to the next iteration
			assert(compileFunction([[
for i=1,3 do
    if math.random() < 0.5 then
        continue
    end
    print(i)
end
]], 0, 2) == [[
GETIMPORT R0 2 [math.random]
CALL R0 0 1
LOADK R1 K3 [0.5]
JUMPIFLT R0 R1 L0
GETIMPORT R0 5 [print]
LOADN R1 1
CALL R0 1 0
L0: GETIMPORT R0 2 [math.random]
CALL R0 0 1
LOADK R1 K3 [0.5]
JUMPIFLT R0 R1 L1
GETIMPORT R0 5 [print]
LOADN R1 2
CALL R0 1 0
L1: GETIMPORT R0 2 [math.random]
CALL R0 0 1
LOADK R1 K3 [0.5]
JUMPIFLT R0 R1 L2
GETIMPORT R0 5 [print]
LOADN R1 3
CALL R0 1 0
L2: RETURN R0 0
]])

			-- continue needs to properly close upvalues
			assert(compileFunction([[
for i=1,1 do
    local j = global(i)
    print(function() return j end)
    if math.random() < 0.5 then
        continue
    end
    j += 1
end
]], 1, 2) == [[
GETIMPORT R0 1 [global]
LOADN R1 1
CALL R0 1 1
GETIMPORT R1 3 [print]
NEWCLOSURE R2 P0
CAPTURE REF R0
CALL R1 1 0
GETIMPORT R1 6 [math.random]
CALL R1 0 1
LOADK R2 K7 [0.5]
JUMPIFNOTLT R1 R2 L0
CLOSEUPVALS R0
RETURN R0 0
L0: ADDK R0 R0 K8 [1]
CLOSEUPVALS R0
RETURN R0 0
]])

			-- this weird contraption just disappears
			assert(compileFunction([[
for i=1,1 do
    for j=1,1 do
        if i == 1 then
            continue
        else
            break
        end
    end
end
]], 0, 2) == [[
RETURN R0 0
RETURN R0 0
]])
		end)
	end,

	LoopUnrollNestedClosure = function()
		-- if the body has functions that refer to loop variables, we unroll the loop and use MOVE+CAPTURE for upvalues
		assert(compileFunction([[
for i=1,2 do
    local x = function() return i end
end
]], 1, 2) == [[
LOADN R1 1
NEWCLOSURE R0 P0
CAPTURE VAL R1
LOADN R1 2
NEWCLOSURE R0 P0
CAPTURE VAL R1
RETURN R0 0
]])
	end,

	LoopUnrollCost = function()
		ScopedVariable({
			LuauCompileLoopUnrollThreshold = 25,
			LuauCompileLoopUnrollThresholdMaxBoost = 300
		} :: FV, function()
			-- loops with short body
			assert(compileFunction([[
local t = {}
for i=1,10 do
    t[i] = i
end
return t
]], 0, 2) == [[
NEWTABLE R0 0 10
LOADN R1 1
SETTABLEN R1 R0 1
LOADN R1 2
SETTABLEN R1 R0 2
LOADN R1 3
SETTABLEN R1 R0 3
LOADN R1 4
SETTABLEN R1 R0 4
LOADN R1 5
SETTABLEN R1 R0 5
LOADN R1 6
SETTABLEN R1 R0 6
LOADN R1 7
SETTABLEN R1 R0 7
LOADN R1 8
SETTABLEN R1 R0 8
LOADN R1 9
SETTABLEN R1 R0 9
LOADN R1 10
SETTABLEN R1 R0 10
RETURN R0 1
]])

			-- loops with body that's too long
			assert(compileFunction([[
local t = {}
for i=1,100 do
    t[i] = i
end
return t
]], 0, 2) == [[
NEWTABLE R0 0 0
LOADN R3 1
LOADN R1 100
LOADN R2 1
FORNPREP R1 L1
L0: SETTABLE R3 R0 R3
FORNLOOP R1 L0
L1: RETURN R0 1
]])

			-- loops with body that's long but has a high boost factor due to constant folding
			assert(compileFunction([[
local t = {}
for i=1,25 do
    t[i] = i * i * i
end
return t
]], 0, 2) == [[
NEWTABLE R0 0 0
LOADN R1 1
SETTABLEN R1 R0 1
LOADN R1 8
SETTABLEN R1 R0 2
LOADN R1 27
SETTABLEN R1 R0 3
LOADN R1 64
SETTABLEN R1 R0 4
LOADN R1 125
SETTABLEN R1 R0 5
LOADN R1 216
SETTABLEN R1 R0 6
LOADN R1 343
SETTABLEN R1 R0 7
LOADN R1 512
SETTABLEN R1 R0 8
LOADN R1 729
SETTABLEN R1 R0 9
LOADN R1 1000
SETTABLEN R1 R0 10
LOADN R1 1331
SETTABLEN R1 R0 11
LOADN R1 1728
SETTABLEN R1 R0 12
LOADN R1 2197
SETTABLEN R1 R0 13
LOADN R1 2744
SETTABLEN R1 R0 14
LOADN R1 3375
SETTABLEN R1 R0 15
LOADN R1 4096
SETTABLEN R1 R0 16
LOADN R1 4913
SETTABLEN R1 R0 17
LOADN R1 5832
SETTABLEN R1 R0 18
LOADN R1 6859
SETTABLEN R1 R0 19
LOADN R1 8000
SETTABLEN R1 R0 20
LOADN R1 9261
SETTABLEN R1 R0 21
LOADN R1 10648
SETTABLEN R1 R0 22
LOADN R1 12167
SETTABLEN R1 R0 23
LOADN R1 13824
SETTABLEN R1 R0 24
LOADN R1 15625
SETTABLEN R1 R0 25
RETURN R0 1
]])

			-- loops with body that's long and doesn't have a high boost factor
			assert(compileFunction([[

local t = {}
for i=1,10 do
    t[i] = math.abs(math.sin(i))
end
return t
]], 0, 2) == [[
NEWTABLE R0 0 10
LOADN R3 1
LOADN R1 10
LOADN R2 1
FORNPREP R1 L3
L0: FASTCALL1 24 R3 L1
MOVE R6 R3
GETIMPORT R5 2 [math.sin]
CALL R5 1 1
L1: FASTCALL1 2 R5 L2
GETIMPORT R4 4 [math.abs]
CALL R4 1 1
L2: SETTABLE R4 R0 R3
FORNLOOP R1 L0
L3: RETURN R0 1
]])
		end)
	end,

	LoopUnrollMutable = function()
		-- can't unroll loops that mutate iteration variable
		assert(compileFunction([[
for i=1,3 do
    i = 3
    print(i) -- should print 3 three times in a row
end
]], 0, 2) == [[
LOADN R2 1
LOADN R0 3
LOADN R1 1
FORNPREP R0 L1
L0: MOVE R3 R2
LOADN R3 3
GETIMPORT R4 1 [print]
MOVE R5 R3
CALL R4 1 0
FORNLOOP R0 L0
L1: RETURN R0 0
]])
	end,

	LoopUnrollCostBuiltins = function()
		ScopedVariable({
			LuauCompileLoopUnrollThreshold = 25,
			LuauCompileLoopUnrollThresholdMaxBoost = 300
		} :: FV, function()
			-- this loop uses builtins and is close to the cost budget so it's important that we model builtins as cheaper than regular calls
			assert(compileFunction([[
function cipher(block, nonce)
    for i = 0,3 do
        block[i + 1] = bit32.band(bit32.rshift(nonce, i * 8), 0xff)
    end
end
]], 0, 2) == [[
FASTCALL2K 39 R1 K0 L0 [0]
MOVE R4 R1
LOADK R5 K0 [0]
GETIMPORT R3 3 [bit32.rshift]
CALL R3 2 1
L0: FASTCALL2K 29 R3 K4 L1 [255]
LOADK R4 K4 [255]
GETIMPORT R2 6 [bit32.band]
CALL R2 2 1
L1: SETTABLEN R2 R0 1
FASTCALL2K 39 R1 K7 L2 [8]
MOVE R4 R1
LOADK R5 K7 [8]
GETIMPORT R3 3 [bit32.rshift]
CALL R3 2 1
L2: FASTCALL2K 29 R3 K4 L3 [255]
LOADK R4 K4 [255]
GETIMPORT R2 6 [bit32.band]
CALL R2 2 1
L3: SETTABLEN R2 R0 2
FASTCALL2K 39 R1 K8 L4 [16]
MOVE R4 R1
LOADK R5 K8 [16]
GETIMPORT R3 3 [bit32.rshift]
CALL R3 2 1
L4: FASTCALL2K 29 R3 K4 L5 [255]
LOADK R4 K4 [255]
GETIMPORT R2 6 [bit32.band]
CALL R2 2 1
L5: SETTABLEN R2 R0 3
FASTCALL2K 39 R1 K9 L6 [24]
MOVE R4 R1
LOADK R5 K9 [24]
GETIMPORT R3 3 [bit32.rshift]
CALL R3 2 1
L6: FASTCALL2K 29 R3 K4 L7 [255]
LOADK R4 K4 [255]
GETIMPORT R2 6 [bit32.band]
CALL R2 2 1
L7: SETTABLEN R2 R0 4
RETURN R0 0
]])

			-- note that if we break compiler's ability to reason about bit32 builtin the loop is no longer unrolled as it's too expensive
			assert(compileFunction([[
bit32 = {}

function cipher(block, nonce)
    for i = 0,3 do
        block[i + 1] = bit32.band(bit32.rshift(nonce, i * 8), 0xff)
    end
end
]], 0, 2) == [[
LOADN R4 0
LOADN R2 3
LOADN R3 1
FORNPREP R2 L1
L0: ADDK R5 R4 K0 [1]
GETGLOBAL R7 K1 ['bit32']
GETTABLEKS R6 R7 K2 ['band']
GETGLOBAL R8 K1 ['bit32']
GETTABLEKS R7 R8 K3 ['rshift']
MOVE R8 R1
MULK R9 R4 K4 [8]
CALL R7 2 1
LOADN R8 255
CALL R6 2 1
SETTABLE R6 R0 R5
FORNLOOP R2 L0
L1: RETURN R0 0
]])

			-- additionally, if we pass too many constants the builtin stops being cheap because of argument setup
			assert(compileFunction([[
function cipher(block, nonce)
    for i = 0,3 do
        block[i + 1] = bit32.band(bit32.rshift(nonce, i * 8), 0xff, 0xff, 0xff, 0xff, 0xff)
    end
end
]], 0, 2) == [[
LOADN R4 0
LOADN R2 3
LOADN R3 1
FORNPREP R2 L3
L0: ADDK R5 R4 K0 [1]
MULK R9 R4 K1 [8]
FASTCALL2 39 R1 R9 L1
MOVE R8 R1
GETIMPORT R7 4 [bit32.rshift]
CALL R7 2 1
L1: LOADN R8 255
LOADN R9 255
LOADN R10 255
LOADN R11 255
LOADN R12 255
FASTCALL 29 L2
GETIMPORT R6 6 [bit32.band]
CALL R6 6 1
L2: SETTABLE R6 R0 R5
FORNLOOP R2 L0
L3: RETURN R0 0
]])
		end)
	end,

	InlineBasic = function()
		-- inline function that returns a constant
		assert(compileFunction([[
local function foo()
    return 42
end

local x = foo()
return x
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
LOADN R1 42
RETURN R1 1
]])

		-- inline function that returns the argument
		assert(compileFunction([[
local function foo(a)
    return a
end

local x = foo(42)
return x
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
LOADN R1 42
RETURN R1 1
]])

		-- inline function that returns one of the two arguments
		assert(compileFunction([[
local function foo(a, b, c)
    if a then
        return b
    else
        return c
    end
end

local x = foo(true, math.random(), 5)
return x
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
GETIMPORT R2 3 [math.random]
CALL R2 0 1
MOVE R1 R2
RETURN R1 1
RETURN R1 1
]])

		-- inline function that returns one of the two arguments
		assert(compileFunction([[
local function foo(a, b, c)
    if a then
        return b
    else
        return c
    end
end

local x = foo(true, 5, math.random())
return x
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
GETIMPORT R2 3 [math.random]
CALL R2 0 1
LOADN R1 5
RETURN R1 1
RETURN R1 1
]])
	end,

	InlineProhibited = function()
		-- we can't inline variadic functions
		assert(compileFunction([[
local function foo(...)
    return 42
end

local x = foo()
return x
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
MOVE R1 R0
CALL R1 0 1
RETURN R1 1
]])

		-- we can't inline any functions in modules with getfenv/setfenv
		assert(compileFunction([[
local function foo()
    return 42
end

local x = foo()
getfenv()
return x
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
MOVE R1 R0
CALL R1 0 1
GETIMPORT R2 2 [getfenv]
CALL R2 0 0
RETURN R1 1
]])
	end,

	InlineProhibitedRecursion = function()
		-- we can't inline recursive invocations of functions in the functions
		-- this is actually profitable in certain cases, but it complicates the compiler as it means a local has multiple registers/values

		-- in this example, inlining is blocked because we're compiling fact() and we don't yet have the cost model / profitability data for fact()
		assert(compileFunction([[
local function fact(n)
    return if n <= 1 then 1 else fact(n-1)*n
end

return fact
]], 0, 2) == [[
LOADN R2 1
JUMPIFNOTLE R0 R2 L0
LOADN R1 1
RETURN R1 1
L0: GETUPVAL R2 0
SUBK R3 R0 K0 [1]
CALL R2 1 1
MUL R1 R2 R0
RETURN R1 1
]])

		-- in this example, inlining of fact() succeeds, but the nested call to fact() fails since fact is already on the inline stack
		assert(compileFunction([[
local function fact(n)
    return if n <= 1 then 1 else fact(n-1)*n
end

local function factsafe(n)
    assert(n >= 1)
    return fact(n)
end

return factsafe
]], 1, 2) == [[
LOADN R3 1
JUMPIFLE R3 R0 L0
LOADB R2 0 +1
L0: LOADB R2 1
L1: FASTCALL1 1 R2 L2
GETIMPORT R1 1 [assert]
CALL R1 1 0
L2: LOADN R2 1
JUMPIFNOTLE R0 R2 L3
LOADN R1 1
RETURN R1 1
L3: GETUPVAL R2 0
SUBK R3 R0 K2 [1]
CALL R2 1 1
MUL R1 R2 R0
RETURN R1 1
]])
	end,

	InlineNestedLoops = function()
		-- functions with basic loops get inlined
		assert(compileFunction([[
local function foo(t)
    for i=1,3 do
        t[i] = i
    end
    return t
end

local x = foo({})
return x
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
NEWTABLE R2 0 0
LOADN R3 1
SETTABLEN R3 R2 1
LOADN R3 2
SETTABLEN R3 R2 2
LOADN R3 3
SETTABLEN R3 R2 3
MOVE R1 R2
RETURN R1 1
]])

		-- we can even unroll the loops based on inline argument
		assert(compileFunction([[
local function foo(t, n)
    for i=1, n do
        t[i] = i
    end
    return t
end

local x = foo({}, 3)
return x
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
NEWTABLE R2 0 0
LOADN R3 1
SETTABLEN R3 R2 1
LOADN R3 2
SETTABLEN R3 R2 2
LOADN R3 3
SETTABLEN R3 R2 3
MOVE R1 R2
RETURN R1 1
]])
	end,

	InlineNestedClosures = function()
		-- we can inline functions that contain/return functions
		assert(compileFunction([[
local function foo(x)
    return function(y) return x + y end
end

local x = foo(1)(2)
return x
]], 2, 2) == [[
DUPCLOSURE R0 K0 ['foo']
LOADN R2 1
NEWCLOSURE R1 P1
CAPTURE VAL R2
LOADN R2 2
CALL R1 1 1
RETURN R1 1
]])
	end,

	InlineMutate = function()
		-- if the argument is mutated, it gets a register even if the value is constant
		assert(compileFunction([[
local function foo(a)
    a = a or 5
    return a
end

local x = foo(42)
return x
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
LOADN R2 42
ORK R2 R2 K1 [5]
MOVE R1 R2
RETURN R1 1
]])

		-- if the argument is a local, it can be used directly
		assert(compileFunction([[
local function foo(a)
    return a
end

local x = ...
local y = foo(x)
return y
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
GETVARARGS R1 1
MOVE R2 R1
RETURN R2 1
]])

		-- ... but if it's mutated, we move it in case it is mutated through a capture during the inlined function
		assert(compileFunction([[
local function foo(a)
    return a
end

local x = ...
x = nil
local y = foo(x)
return y
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
GETVARARGS R1 1
LOADNIL R1
MOVE R3 R1
MOVE R2 R3
RETURN R2 1
]])

		-- we also don't inline functions if they have been assigned to
		assert(compileFunction([[
local function foo(a)
    return a
end

foo = foo

local x = foo(42)
return x
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
MOVE R1 R0
LOADN R2 42
CALL R1 1 1
RETURN R1 1
]])
	end,

	InlineUpval = function()
		-- if the argument is an upvalue, we naturally need to copy it to a local
		assert(compileFunction([[
local function foo(a)
    return a
end

local b = ...

function bar()
    local x = foo(b)
    return x
end
]], 1, 2) == [[
GETUPVAL R1 0
MOVE R0 R1
RETURN R0 1
]])

		-- if the function uses an upvalue it's more complicated, because the lexical upvalue may become a local
		assert(compileFunction([[
local b = ...

local function foo(a)
    return a + b
end

local x = foo(42)
return x
]], 1, 2) == [[
GETVARARGS R0 1
DUPCLOSURE R1 K0 ['foo']
CAPTURE VAL R0
LOADN R3 42
ADD R2 R3 R0
RETURN R2 1
]])

		-- sometimes the lexical upvalue is deep enough that it's still an upvalue though
		assert(compileFunction([[
local b = ...

function bar()
    local function foo(a)
        return a + b
    end

    local x = foo(42)
    return x
end
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
CAPTURE UPVAL U0
LOADN R2 42
GETUPVAL R3 0
ADD R1 R2 R3
RETURN R1 1
]])
	end,

	InlineCapture = function()
		-- if the argument is captured by a nested closure, normally we can rely on capture by value
		assert(compileFunction([[
local function foo(a)
    return function() return a end
end

local x = ...
local y = foo(x)
return y
]], 2, 2) == [[
DUPCLOSURE R0 K0 ['foo']
GETVARARGS R1 1
NEWCLOSURE R2 P1
CAPTURE VAL R1
RETURN R2 1
]])

		-- if the argument is a constant, we move it to a register so that capture by value can happen
		assert(compileFunction([[
local function foo(a)
    return function() return a end
end

local y = foo(42)
return y
]], 2, 2) == [[
DUPCLOSURE R0 K0 ['foo']
LOADN R2 42
NEWCLOSURE R1 P1
CAPTURE VAL R2
RETURN R1 1
]])

		-- if the argument is an externally mutated variable, we copy it to an argument and capture it by value
		assert(compileFunction([[
local function foo(a)
    return function() return a end
end

local x x = 42
local y = foo(x)
return y
]], 2, 2) == [[
DUPCLOSURE R0 K0 ['foo']
LOADNIL R1
LOADN R1 42
MOVE R3 R1
NEWCLOSURE R2 P1
CAPTURE VAL R3
RETURN R2 1
]])

		-- finally, if the argument is mutated internally, we must capture it by reference and close the upvalue
		assert(compileFunction([[
local function foo(a)
    a = a or 42
    return function() return a end
end

local y = foo()
return y
]], 2, 2) == [[
DUPCLOSURE R0 K0 ['foo']
LOADNIL R2
ORK R2 R2 K1 [42]
NEWCLOSURE R1 P1
CAPTURE REF R2
CLOSEUPVALS R2
RETURN R1 1
]])

		-- note that capture might need to be performed during the fallthrough block
		assert(compileFunction([[
local function foo(a)
    a = a or 42
    print(function() return a end)
end

local x = ...
local y = foo(x)
return y
]], 2, 2) == [[
DUPCLOSURE R0 K0 ['foo']
GETVARARGS R1 1
MOVE R3 R1
ORK R3 R3 K1 [42]
GETIMPORT R4 3 [print]
NEWCLOSURE R5 P1
CAPTURE REF R3
CALL R4 1 0
LOADNIL R2
CLOSEUPVALS R3
RETURN R2 1
]])

		-- note that mutation and capture might be inside internal control flow
		-- TODO: this has an oddly redundant CLOSEUPVALS after JUMP; it's not due to inlining, and is an artifact of how StatBlock/StatReturn interact
		-- fixing this would reduce the number of redundant CLOSEUPVALS a bit but it only affects bytecode size as these instructions aren't executed
		assert(compileFunction([[
local function foo(a)
    if not a then
        local b b = 42
        return function() return b end
    end
end

local x = ...
local y = foo(x)
return y, x
]], 2, 2) == [[
DUPCLOSURE R0 K0 ['foo']
GETVARARGS R1 1
JUMPIF R1 L0
LOADNIL R3
LOADN R3 42
NEWCLOSURE R2 P1
CAPTURE REF R3
CLOSEUPVALS R3
JUMP L1
CLOSEUPVALS R3
L0: LOADNIL R2
L1: MOVE R3 R2
MOVE R4 R1
RETURN R3 2
]])
	end,

	InlineFallthrough = function()
		-- if the function doesn't return, we still fill the results with nil
		assert(compileFunction([[
local function foo()
end

local a, b = foo()
return a, b
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
LOADNIL R1
LOADNIL R2
RETURN R1 2
]])

		-- this happens even if the function returns conditionally
		assert(compileFunction([[
local function foo(a)
    if a then return 42 end
end

local a, b = foo(false)
return a, b
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
LOADNIL R1
LOADNIL R2
RETURN R1 2
]])

		-- note though that we can't inline a function like this in multret context
		-- this is because we don't have a SETTOP instruction
		assert(compileFunction([[
local function foo()
end

return foo()
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
MOVE R1 R0
CALL R1 0 -1
RETURN R1 -1
]])
	end,

	InlineArgMismatch = function()
		-- when inlining a function, we must respect all the usual rules

		-- caller might not have enough arguments
		assert(compileFunction([[
local function foo(a)
    return a
end

local x = foo()
return x
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
LOADNIL R1
RETURN R1 1
]])

		-- caller might be using multret for arguments
		assert(compileFunction([[
local function foo(a, b)
    return a + b
end

local x = foo(math.modf(1.5))
return x
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
LOADK R3 K1 [1.5]
FASTCALL1 20 R3 L0
GETIMPORT R2 4 [math.modf]
CALL R2 1 2
L0: ADD R1 R2 R3
RETURN R1 1
]])

		-- caller might be using varargs for arguments
		assert(compileFunction([[
local function foo(a, b)
    return a + b
end

local x = foo(...)
return x
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
GETVARARGS R2 2
ADD R1 R2 R3
RETURN R1 1
]])

		-- caller might have too many arguments, but we still need to compute them for side effects
		assert(compileFunction([[
local function foo(a)
    return a
end

local x = foo(42, print())
return x
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
GETIMPORT R2 2 [print]
CALL R2 0 1
LOADN R1 42
RETURN R1 1
]])

		-- caller might not have enough arguments, and the arg might be mutated so it needs a register
		assert(compileFunction([[
local function foo(a)
    a = 42
    return a
end

local x = foo()
return x
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
LOADNIL R2
LOADN R2 42
MOVE R1 R2
RETURN R1 1
]])
	end,

	InlineMultiple = function()
		-- we call this with a different set of variable/constant args
		assert(compileFunction([[
local function foo(a, b)
    return a + b
end

local x, y = ...
local a = foo(x, 1)
local b = foo(1, x)
local c = foo(1, 2)
local d = foo(x, y)
return a, b, c, d
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
GETVARARGS R1 2
ADDK R3 R1 K1 [1]
LOADN R5 1
ADD R4 R5 R1
LOADN R5 3
ADD R6 R1 R2
RETURN R3 4
]])
	end,

	InlineChain = function()
		-- inline a chain of functions
		assert(compileFunction([[
local function foo(a, b)
    return a + b
end

local function bar(x)
    return foo(x, 1) * foo(x, -1)
end

local function baz()
    return (bar(42))
end

return (baz())
]], 3, 2) == [[
DUPCLOSURE R0 K0 ['foo']
DUPCLOSURE R1 K1 ['bar']
DUPCLOSURE R2 K2 ['baz']
LOADN R4 43
LOADN R5 41
MUL R3 R4 R5
RETURN R3 1
]])
	end,

	InlineThresholds = function()
		ScopedVariable({
			LuauCompileInlineThreshold = 25,
			LuauCompileInlineThresholdMaxBoost = 300,
			LuauCompileInlineDepth = 2
		} :: FV, function()
			-- this function has enormous register pressure (50 regs) so we choose not to inline it
			assert(compileFunction([[
local function foo()
    return {{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
end

return (foo())
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
MOVE R1 R0
CALL R1 0 1
RETURN R1 1
]])

			-- this function has less register pressure but a large cost
			assert(compileFunction([[
local function foo()
    return {},{},{},{},{}
end

return (foo())
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
MOVE R1 R0
CALL R1 0 1
RETURN R1 1
]])

			-- this chain of function is of length 3 but our limit in this test is 2, so we call foo twice
			assert(compileFunction([[
local function foo(a, b)
    return a + b
end

local function bar(x)
    return foo(x, 1) * foo(x, -1)
end

local function baz()
    return (bar(42))
end

return (baz())
]], 3, 2) == [[
DUPCLOSURE R0 K0 ['foo']
DUPCLOSURE R1 K1 ['bar']
DUPCLOSURE R2 K2 ['baz']
MOVE R4 R0
LOADN R5 42
LOADN R6 1
CALL R4 2 1
MOVE R5 R0
LOADN R6 42
LOADN R7 -1
CALL R5 2 1
MUL R3 R4 R5
RETURN R3 1
]])
		end)
	end,

	InlineIIFE = function()
		-- IIFE with arguments
		assert(compileFunction([[
function choose(a, b, c)
    return ((function(a, b, c) if a then return b else return c end end)(a, b, c))
end
]], 1, 2) == [[
JUMPIFNOT R0 L0
MOVE R3 R1
RETURN R3 1
L0: MOVE R3 R2
RETURN R3 1
RETURN R3 1
]])

		-- IIFE with upvalues
		assert(compileFunction([[
function choose(a, b, c)
    return ((function() if a then return b else return c end end)())
end
]], 1, 2) == [[
JUMPIFNOT R0 L0
MOVE R3 R1
RETURN R3 1
L0: MOVE R3 R2
RETURN R3 1
RETURN R3 1
]])
	end,

	InlineRecurseArguments = function()
		-- the example looks silly but we preserve it verbatim as it was found by fuzzer for a previous version of the compiler
		assert(compileFunction([[
local function foo(a, b)
end
foo(foo(foo,foo(foo,foo))[foo])
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
LOADNIL R3
LOADNIL R2
GETTABLE R1 R2 R0
RETURN R0 0
]])

		-- verify that invocations of the inlined function in any position for computing the arguments to itself compile
		assert(compileFunction([[
local function foo(a, b)
    return a + b
end

local x, y, z = ...

return foo(foo(x, y), foo(z, 1))
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
GETVARARGS R1 3
ADD R5 R1 R2
ADDK R6 R3 K1 [1]
ADD R4 R5 R6
RETURN R4 1
]])

		-- verify that invocations of the inlined function in any position for computing the arguments to itself compile, including constants and locals
		-- note that foo(k1, k2) doesn't get constant folded, so there's still actual math emitted for some of the calls below
		assert(compileFunction([[
local function foo(a, b)
    return a + b
end

local x, y, z = ...

return
    foo(foo(1, 2), 3),
    foo(1, foo(2, 3)),
    foo(x, foo(2, 3)),
    foo(x, foo(y, 3)),
    foo(x, foo(y, z)),
    foo(x+0, foo(y, z)),
    foo(x+0, foo(y+0, z)),
    foo(x+0, foo(y, z+0)),
    foo(1, foo(x, y))
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
GETVARARGS R1 3
LOADN R5 3
ADDK R4 R5 K1 [3]
LOADN R6 5
LOADN R7 1
ADD R5 R7 R6
LOADN R7 5
ADD R6 R1 R7
ADDK R8 R2 K1 [3]
ADD R7 R1 R8
ADD R9 R2 R3
ADD R8 R1 R9
ADDK R10 R1 K2 [0]
ADD R11 R2 R3
ADD R9 R10 R11
ADDK R11 R1 K2 [0]
ADDK R13 R2 K2 [0]
ADD R12 R13 R3
ADD R10 R11 R12
ADDK R12 R1 K2 [0]
ADDK R14 R3 K2 [0]
ADD R13 R2 R14
ADD R11 R12 R13
ADD R13 R1 R2
LOADN R14 1
ADD R12 R14 R13
RETURN R4 9
]])
	end,

	InlineFastCallK = function()
		assert(compileFunction([[
local function set(l0)
    rawset({}, l0)
end

set(false)
set({})
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['set']
NEWTABLE R2 0 0
FASTCALL2K 49 R2 K1 L0 [false]
LOADK R3 K1 [false]
GETIMPORT R1 3 [rawset]
CALL R1 2 0
L0: NEWTABLE R1 0 0
NEWTABLE R3 0 0
FASTCALL2 49 R3 R1 L1
MOVE R4 R1
GETIMPORT R2 3 [rawset]
CALL R2 2 0
L1: RETURN R0 0
]])
	end,

	InlineExprIndexK = function()
		assert(compileFunction([[
local _ = function(l0)
local _ = nil
while _(_)[_] do
end
end
local _ = _(0)[""]
if _ then
do
for l0=0,8 do
end
end
elseif _ then
_ = nil
do
for l0=0,8 do
return true
end
end
end
]], 1, 2) == [[
DUPCLOSURE R0 K0 []
L0: LOADNIL R4
LOADNIL R5
CALL R4 1 1
LOADNIL R5
GETTABLE R3 R4 R5
JUMPIFNOT R3 L1
JUMPBACK L0
L1: LOADNIL R2
GETTABLEKS R1 R2 K1 ['']
JUMPIFNOT R1 L2
RETURN R0 0
L2: JUMPIFNOT R1 L3
LOADNIL R1
LOADB R2 1
RETURN R2 1
LOADB R2 1
RETURN R2 1
LOADB R2 1
RETURN R2 1
LOADB R2 1
RETURN R2 1
LOADB R2 1
RETURN R2 1
LOADB R2 1
RETURN R2 1
LOADB R2 1
RETURN R2 1
LOADB R2 1
RETURN R2 1
LOADB R2 1
RETURN R2 1
L3: RETURN R0 0
]])
	end,

	InlineHiddenMutation = function()
		-- when the argument is assigned inside the function, we can't reuse the local
		assert(compileFunction([[
local function foo(a)
    a = 42
    return a
end

local x = ...
local y = foo(x :: number)
return y
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
GETVARARGS R1 1
MOVE R3 R1
LOADN R3 42
MOVE R2 R3
RETURN R2 1
]])

		-- and neither can we do that when it's assigned outside the function
		assert(compileFunction([[
local function foo(a)
    mutator()
    return a
end

local x = ...
mutator = function() x = 42 end

local y = foo(x :: number)
return y
]], 2, 2) == [[
DUPCLOSURE R0 K0 ['foo']
GETVARARGS R1 1
NEWCLOSURE R2 P1
CAPTURE REF R1
SETGLOBAL R2 K1 ['mutator']
MOVE R3 R1
GETGLOBAL R4 K1 ['mutator']
CALL R4 0 0
MOVE R2 R3
CLOSEUPVALS R1
RETURN R2 1
]])
	end,

	InlineMultret = function()
		-- inlining a function in multret context is prohibited since we can't adjust L->top outside of CALL/GETVARARGS
		assert(compileFunction([[
local function foo(a)
    return a()
end

return foo(42)
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
MOVE R1 R0
LOADN R2 42
CALL R1 1 -1
RETURN R1 -1
]])

		-- however, if we can deduce statically that a function always returns a single value, the inlining will work
		assert(compileFunction([[
local function foo(a)
    return a
end

return foo(42)
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
LOADN R1 42
RETURN R1 1
]])

		-- this analysis will also propagate through other functions
		assert(compileFunction([[
local function foo(a)
    return a
end

local function bar(a)
    return foo(a)
end

return bar(42)
]], 2, 2) == [[
DUPCLOSURE R0 K0 ['foo']
DUPCLOSURE R1 K1 ['bar']
LOADN R2 42
RETURN R2 1
]])

		-- we currently don't do this analysis fully for recursive functions since they can't be inlined anyway
		assert(compileFunction([[
local function foo(a)
    return foo(a)
end

return foo(42)
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
CAPTURE VAL R0
MOVE R1 R0
LOADN R2 42
CALL R1 1 -1
RETURN R1 -1
]])

		-- we do this for builtins though as we assume getfenv is not used or is not changing arity
		assert(compileFunction([[
local function foo(a)
    return math.abs(a)
end

return foo(42)
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
LOADN R1 42
RETURN R1 1
]])
	end,

	ReturnConsecutive = function()
		-- we can return a single local directly
		assert(compileFunction0([[
local x = ...
return x
]]) == [[
GETVARARGS R0 1
RETURN R0 1
]])

		-- or multiple, when they are allocated in consecutive registers
		assert(compileFunction0([[
local x, y = ...
return x, y
]]) == [[
GETVARARGS R0 2
RETURN R0 2
]])

		-- but not if it's an expression
		assert(compileFunction0([[
local x, y = ...
return x, y + 1
]]) == [[
GETVARARGS R0 2
MOVE R2 R0
ADDK R3 R1 K0 [1]
RETURN R2 2
]])

		-- or a local with wrong register number
		assert(compileFunction0([[
local x, y = ...
return y, x
]]) == [[
GETVARARGS R0 2
MOVE R2 R1
MOVE R3 R0
RETURN R2 2
]])

		-- also double check the optimization doesn't trip on no-argument return (these are rare)
		assert(compileFunction0([[
return
]]) == [[
RETURN R0 0
]])

		-- this optimization also works in presence of group / type casts
		assert(compileFunction0([[
local x, y = ...
return (x), y :: number
]]) == [[
GETVARARGS R0 2
RETURN R0 2
]])
	end,

	OptimizationLevel = function()
		-- at optimization level 1, no inlining is performed
		assert(compileFunction([[
local function foo(a)
    return a
end

return foo(42)
]], 1, 1) == [[
DUPCLOSURE R0 K0 ['foo']
MOVE R1 R0
LOADN R2 42
CALL R1 1 -1
RETURN R1 -1
]])

		-- you can override the level from 1 to 2 to force it
		assert(compileFunction([[
--!optimize 2
local function foo(a)
    return a
end

return foo(42)
]], 1, 1) == [[
DUPCLOSURE R0 K0 ['foo']
LOADN R1 42
RETURN R1 1
]])

		-- you can override the level from 1 to 2 to force it
		assert(compileFunction([[
local function foo(a)
    return a
end

return foo(42)
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
LOADN R1 42
RETURN R1 1
]])

		-- ... after which you can downgrade it back via hot comment
		assert(compileFunction([[
--!optimize 1
local function foo(a)
    return a
end

return foo(42)
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['foo']
MOVE R1 R0
LOADN R2 42
CALL R1 1 -1
RETURN R1 -1
]])
	end,
	
	BuiltinFolding = function()
		assert(compileFunction([[
return
    math.abs(-42),
    math.acos(1),
    math.asin(0),
    math.atan2(0, 1),
    math.atan(0),
    math.ceil(1.5),
    math.cosh(0),
    math.cos(0),
    math.deg(3.14159265358979323846),
    math.exp(0),
    math.floor(-1.5),
    math.fmod(7, 3),
    math.ldexp(0.5, 3),
    math.log10(100),
    math.log(1),
    math.log(4, 2),
    math.log(64, 4),
    math.max(1, 2, 3),
    math.min(1, 2, 3),
    math.pow(3, 3),
    math.floor(math.rad(180)),
    math.sinh(0),
    math.sin(0),
    math.sqrt(9),
    math.tanh(0),
    math.tan(0),
    bit32.arshift(-10, 1),
    bit32.arshift(10, 1),
    bit32.band(1, 3),
    bit32.bnot(-2),
    bit32.bor(1, 2),
    bit32.bxor(3, 7),
    bit32.btest(1, 3),
    bit32.extract(100, 1, 3),
    bit32.lrotate(100, -1),
    bit32.lshift(100, 1),
    bit32.replace(100, 5, 1, 3),
    bit32.rrotate(100, -1),
    bit32.rshift(100, 1),
    type(100),
    string.byte("a"),
    string.byte("abc", 2),
    string.len("abc"),
    typeof(true),
    math.clamp(-1, 0, 1),
    math.sign(77),
    math.round(7.6),
    bit32.extract(-1, 31),
    bit32.replace(100, 1, 0),
    math.log(100, 10),
    typeof(nil),
    (type("fin"))
]], 0, 2) == [[
LOADN R0 42
LOADN R1 0
LOADN R2 0
LOADN R3 0
LOADN R4 0
LOADN R5 2
LOADN R6 1
LOADN R7 1
LOADN R8 180
LOADN R9 1
LOADN R10 -2
LOADN R11 1
LOADN R12 4
LOADN R13 2
LOADN R14 0
LOADN R15 2
LOADN R16 3
LOADN R17 3
LOADN R18 1
LOADN R19 27
LOADN R20 3
LOADN R21 0
LOADN R22 0
LOADN R23 3
LOADN R24 0
LOADN R25 0
LOADK R26 K0 [4294967291]
LOADN R27 5
LOADN R28 1
LOADN R29 1
LOADN R30 3
LOADN R31 4
LOADB R32 1
LOADN R33 2
LOADN R34 50
LOADN R35 200
LOADN R36 106
LOADN R37 200
LOADN R38 50
LOADK R39 K1 ['number']
LOADN R40 97
LOADN R41 98
LOADN R42 3
LOADK R43 K2 ['boolean']
LOADN R44 0
LOADN R45 1
LOADN R46 8
LOADN R47 1
LOADN R48 101
LOADN R49 2
LOADK R50 K3 ['nil']
LOADK R51 K4 ['string']
RETURN R0 52
]])
	end,

	BuiltinFoldingProhibited = function()
		assert(compileFunction([[
return
    math.abs(),
    math.max(1, true),
    string.byte("abc", 42),
    bit32.rshift(10, 42),
    bit32.extract(1, 2, "3"),
    bit32.bor(1, true),
    bit32.band(1, true),
    bit32.bxor(1, true),
    bit32.btest(1, true),
    math.min(1, true)
]], 0, 2) == [[
FASTCALL 2 L0
GETIMPORT R0 2 [math.abs]
CALL R0 0 1
L0: LOADN R2 1
FASTCALL2K 18 R2 K3 L1 [true]
LOADK R3 K3 [true]
GETIMPORT R1 5 [math.max]
CALL R1 2 1
L1: LOADK R3 K6 ['abc']
FASTCALL2K 41 R3 K7 L2 [42]
LOADK R4 K7 [42]
GETIMPORT R2 10 [string.byte]
CALL R2 2 1
L2: LOADN R4 10
FASTCALL2K 39 R4 K7 L3 [42]
LOADK R5 K7 [42]
GETIMPORT R3 13 [bit32.rshift]
CALL R3 2 1
L3: LOADN R5 1
LOADN R6 2
LOADK R7 K14 ['3']
FASTCALL 34 L4
GETIMPORT R4 16 [bit32.extract]
CALL R4 3 1
L4: LOADN R6 1
FASTCALL2K 31 R6 K3 L5 [true]
LOADK R7 K3 [true]
GETIMPORT R5 18 [bit32.bor]
CALL R5 2 1
L5: LOADN R7 1
FASTCALL2K 29 R7 K3 L6 [true]
LOADK R8 K3 [true]
GETIMPORT R6 20 [bit32.band]
CALL R6 2 1
L6: LOADN R8 1
FASTCALL2K 32 R8 K3 L7 [true]
LOADK R9 K3 [true]
GETIMPORT R7 22 [bit32.bxor]
CALL R7 2 1
L7: LOADN R9 1
FASTCALL2K 33 R9 K3 L8 [true]
LOADK R10 K3 [true]
GETIMPORT R8 24 [bit32.btest]
CALL R8 2 1
L8: LOADN R10 1
FASTCALL2K 19 R10 K3 L9 [true]
LOADK R11 K3 [true]
GETIMPORT R9 26 [math.min]
CALL R9 2 1
L9: RETURN R0 10
]])
	end,

	BuiltinFoldingProhibitedCoverage = function()
		local builtins = {
			"math.abs",
			"math.acos",
			"math.asin",
			"math.atan2",
			"math.atan",
			"math.ceil",
			"math.cosh",
			"math.cos",
			"math.deg",
			"math.exp",
			"math.floor",
			"math.fmod",
			"math.ldexp",
			"math.log10",
			"math.log",
			"math.max",
			"math.min",
			"math.pow",
			"math.rad",
			"math.sinh",
			"math.sin",
			"math.sqrt",
			"math.tanh",
			"math.tan",
			"bit32.arshift",
			"bit32.band",
			"bit32.bnot",
			"bit32.bor",
			"bit32.bxor",
			"bit32.btest",
			"bit32.extract",
			"bit32.lrotate",
			"bit32.lshift",
			"bit32.replace",
			"bit32.rrotate",
			"bit32.rshift",
			"type",
			"string.byte",
			"string.len",
			"typeof",
			"math.clamp",
			"math.sign",
			"math.round"
		}

		for _, func in builtins do
			local source = `return {func}()`

			local bc = compileFunction(source, 0, 2)
			
			assert(string.find(bc, "FASTCALL") ~= nil)
		end
	end,

	BuiltinFoldingMultret = function()
		assert(compileFunction([=[
local NoLanes: Lanes = --[[                             ]] 0b0000000000000000000000000000000
local OffscreenLane: Lane = --[[                        ]] 0b1000000000000000000000000000000

local function getLanesToRetrySynchronouslyOnError(root: FiberRoot): Lanes
    local everythingButOffscreen = bit32.band(root.pendingLanes, bit32.bnot(OffscreenLane))
    if everythingButOffscreen ~= NoLanes then
        return everythingButOffscreen
    end
    if bit32.band(everythingButOffscreen, OffscreenLane) ~= 0 then
        return OffscreenLane
    end
    return NoLanes
end
]=], 0, 2) == [[
GETTABLEKS R2 R0 K0 ['pendingLanes']
FASTCALL2K 29 R2 K1 L0 [3221225471]
LOADK R3 K1 [3221225471]
GETIMPORT R1 4 [bit32.band]
CALL R1 2 1
L0: JUMPXEQKN R1 K5 L1 [0]
RETURN R1 1
L1: FASTCALL2K 29 R1 K6 L2 [1073741824]
MOVE R3 R1
LOADK R4 K6 [1073741824]
GETIMPORT R2 4 [bit32.band]
CALL R2 2 1
L2: JUMPXEQKN R2 K5 L3 [0]
LOADK R2 K6 [1073741824]
RETURN R2 1
L3: LOADN R2 0
RETURN R2 1
]])

		-- Note: similarly, here we should have folded the return value but haven't because it's the last call in the sequence
		assert(compileFunction([[
return math.abs(-42)
]], 0, 2) == [[
LOADN R0 42
RETURN R0 1
]])
	end,

	LocalReassign = function()
		-- locals can be re-assigned and the register gets reused
		assert(compileFunction0([[
local function test(a, b)
    local c = a
    return c + b
end
]]) == [[
ADD R2 R0 R1
RETURN R2 1
]])

		-- this works if the expression is using type casts or grouping
		assert(compileFunction0([[
local function test(a, b)
    local c = (a :: number)
    return c + b
end
]]) == [[
ADD R2 R0 R1
RETURN R2 1
]])

		-- the optimization requires that neither local is mutated
		assert(compileFunction0([[
local function test(a, b)
    local c = a
    c += 0
    local d = b
    b += 0
    return c + d
end
]]) == [[
MOVE R2 R0
ADDK R2 R2 K0 [0]
MOVE R3 R1
ADDK R1 R1 K0 [0]
ADD R4 R2 R3
RETURN R4 1
]])

		-- sanity check for two values
		assert(compileFunction0([[
local function test(a, b)
    local c = a
    local d = b
    return c + d
end
]]) == [[
ADD R2 R0 R1
RETURN R2 1
]])

		-- note: we currently only support this for single assignments
		assert(compileFunction0([[
local function test(a, b)
    local c, d = a, b
    return c + d
end
]]) == [[
MOVE R2 R0
MOVE R3 R1
ADD R4 R2 R3
RETURN R4 1
]])

		-- of course, captures capture the original register as well (by value since it's immutable)
		assert(compileFunction([[
local function test(a, b)
    local c = a
    local d = b
    return function() return c + d end
end
]], 1) == [[
NEWCLOSURE R2 P0
CAPTURE VAL R0
CAPTURE VAL R1
RETURN R2 1
]])
	end,

	MultipleAssignments = function()
		-- order of assignments is left to right
		assert(compileFunction0([[
        local a, b
        a, b = f(1), f(2)
]]) == [[
LOADNIL R0
LOADNIL R1
GETIMPORT R2 1 [f]
LOADN R3 1
CALL R2 1 1
MOVE R0 R2
GETIMPORT R2 1 [f]
LOADN R3 2
CALL R2 1 1
MOVE R1 R2
RETURN R0 0
]])

		-- this includes table assignments
		assert(compileFunction0([[
        local t
        t[1], t[2] = 3, 4
]]) == [[
LOADNIL R0
LOADNIL R1
LOADN R2 3
LOADN R3 4
SETTABLEN R2 R0 1
SETTABLEN R3 R1 2
RETURN R0 0
]])

		-- semantically, we evaluate the right hand side first; this allows us to e.g swap elements in a table easily
		assert(compileFunction0([[
        local t = ...
        t[1], t[2] = t[2], t[1]
]]) == [[
GETVARARGS R0 1
GETTABLEN R1 R0 2
GETTABLEN R2 R0 1
SETTABLEN R1 R0 1
SETTABLEN R2 R0 2
RETURN R0 0
]])

		-- however, we need to optimize local assignments; to do this well, we need to handle assignment conflicts
		-- let's first go through a few cases where there are no conflicts:

		-- when multiple assignments have no conflicts (all local vars are read after being assigned), codegen is the same as a series of single
		-- assignments
		assert(compileFunction0([[
        local xm1, x, xp1, xi = ...

        xm1,x,xp1,xi = x,xp1,xp1+1,xi-1
]]) == [[
GETVARARGS R0 4
MOVE R0 R1
MOVE R1 R2
ADDK R2 R2 K0 [1]
SUBK R3 R3 K0 [1]
RETURN R0 0
]])

		-- similar example to above from a more complex case
		assert(compileFunction0([[
        local a, b, c, d, e, f, g, h, t1, t2 = ...

        h, g, f, e, d, c, b, a = g, f, e, d + t1, c, b, a, t1 + t2
]]) == [[
GETVARARGS R0 10
MOVE R7 R6
MOVE R6 R5
MOVE R5 R4
ADD R4 R3 R8
MOVE R3 R2
MOVE R2 R1
MOVE R1 R0
ADD R0 R8 R9
RETURN R0 0
]])

		-- when locals have a conflict, we assign temporaries instead of locals, and at the end copy the values back
		-- the basic example of this is a swap/rotate
		assert(compileFunction0([[
        local a, b = ...
        a, b = b, a
]]) == [[
GETVARARGS R0 2
MOVE R2 R1
MOVE R1 R0
MOVE R0 R2
RETURN R0 0
]])

		assert(compileFunction0([[
        local a, b, c = ...
        a, b, c = c, a, b
]]) == [[
GETVARARGS R0 3
MOVE R3 R2
MOVE R4 R0
MOVE R2 R1
MOVE R0 R3
MOVE R1 R4
RETURN R0 0
]])

		assert(compileFunction0([[
        local a, b, c = ...
        a, b, c = b, c, a
]]) == [[
GETVARARGS R0 3
MOVE R3 R1
MOVE R1 R2
MOVE R2 R0
MOVE R0 R3
RETURN R0 0
]])

		-- multiple assignments with multcall handling - foo() evalutes to temporary registers and they are copied out to target
		assert(compileFunction0([[
        local a, b, c, d = ...
        a, b, c, d = 1, foo()
]]) == [[
GETVARARGS R0 4
LOADN R0 1
GETIMPORT R4 1 [foo]
CALL R4 0 3
MOVE R1 R4
MOVE R2 R5
MOVE R3 R6
RETURN R0 0
]])

		-- note that during this we still need to handle local reassignment, eg when table assignments are performed
		assert(compileFunction0([[
        local a, b, c, d = ...
        a, b[a], c[d], d = 1, foo()
]]) == [[
GETVARARGS R0 4
LOADN R4 1
GETIMPORT R6 1 [foo]
CALL R6 0 3
SETTABLE R6 R1 R0
SETTABLE R7 R2 R3
MOVE R0 R4
MOVE R3 R8
RETURN R0 0
]])

		-- multiple assignments with multcall handling - foo evaluates to a single argument so all remaining locals are assigned to nil
		-- note that here we don't assign the locals directly, as this case is very rare so we use the similar code path as above
		assert(compileFunction0([[
        local a, b, c, d = ...
        a, b, c, d = 1, foo
]]) == [[
GETVARARGS R0 4
LOADN R0 1
GETIMPORT R4 1 [foo]
LOADNIL R5
LOADNIL R6
MOVE R1 R4
MOVE R2 R5
MOVE R3 R6
RETURN R0 0
]])

		-- note that we also try to use locals as a source of assignment directly when assigning fields; this works using old local value when possible
		assert(compileFunction0([[
        local a, b = ...
        a[1], a[2] = b, b + 1
]]) == [[
GETVARARGS R0 2
ADDK R2 R1 K0 [1]
SETTABLEN R1 R0 1
SETTABLEN R2 R0 2
RETURN R0 0
]])

		-- ... of course if the local is reassigned, we defer the assignment until later
		assert(compileFunction0([[
        local a, b = ...
        b, a[1] = 42, b
]]) == [[
GETVARARGS R0 2
LOADN R2 42
SETTABLEN R1 R0 1
MOVE R1 R2
RETURN R0 0
]])

		-- when there are more expressions when values, we evalute them for side effects, but they also participate in conflict handling
		assert(compileFunction0([[
        local a, b = ...
        a, b = 1, 2, a + b
]]) == [[
GETVARARGS R0 2
LOADN R2 1
LOADN R3 2
ADD R4 R0 R1
MOVE R0 R2
MOVE R1 R3
RETURN R0 0
]])

		-- because we perform assignments to complex l-values after assignments to locals, we make sure register conflicts are tracked accordingly
		assert(compileFunction0([[
        local a, b = ...
        a[1], b = b, b + 1
]]) == [[
GETVARARGS R0 2
ADDK R2 R1 K0 [1]
SETTABLEN R1 R0 1
MOVE R1 R2
RETURN R0 0
]])
	end,

	BuiltinExtractK = function()
		-- below, K0 refers to a packed f+w constant for bit32.extractk builtin
		-- K1 and K2 refer to 1 and 3 and are only used during fallback path
		assert(compileFunction0([[
local v = ...

return bit32.extract(v, 1, 3)
]]) == [[
GETVARARGS R0 1
FASTCALL2K 59 R0 K0 L0 [65]
MOVE R2 R0
LOADK R3 K1 [1]
LOADK R4 K2 [3]
GETIMPORT R1 5 [bit32.extract]
CALL R1 3 -1
L0: RETURN R1 -1
]])
	end,

	SkipSelfAssignment = function()
		assert(compileFunction0("local a a = a") == [[
LOADNIL R0
RETURN R0 0
]])

		assert(compileFunction0("local a a = a :: number") == [[
LOADNIL R0
RETURN R0 0
]])

		assert(compileFunction0("local a a = (((a)))") == [[
LOADNIL R0
RETURN R0 0
]])

		assert(compileFunction("local a a = a", 0, 0) == [[
LOADNIL R0
MOVE R0 R0
RETURN R0 0
]])
	end,

	ElideJumpAfterIf = function()
		-- break refers to outer loop => we can elide unconditional branches
		assert(compileFunction0([[
local foo, bar = ...
repeat
    if foo then break
    elseif bar then break
    end
    print(1234)
until foo == bar
]]) == [[
GETVARARGS R0 2
L0: JUMPIFNOT R0 L1
RETURN R0 0
L1: JUMPIF R1 L2
GETIMPORT R2 1 [print]
LOADN R3 1234
CALL R2 1 0
JUMPIFEQ R0 R1 L2
JUMPBACK L0
L2: RETURN R0 0
]])

		-- break refers to inner loop => branches remain
		assert(compileFunction0([[
local foo, bar = ...
repeat
    if foo then while true do break end
    elseif bar then while true do break end
    end
    print(1234)
until foo == bar
]]) == [[
GETVARARGS R0 2
L0: JUMPIFNOT R0 L1
JUMP L2
JUMPBACK L2
JUMP L2
L1: JUMPIFNOT R1 L2
JUMP L2
JUMPBACK L2
L2: GETIMPORT R2 1 [print]
LOADN R3 1234
CALL R2 1 0
JUMPIFEQ R0 R1 L3
JUMPBACK L0
L3: RETURN R0 0
]])
	end,

	BuiltinArity = function()
		-- by default we can't assume that we know parameter/result count for builtins as they can be overridden at runtime
		assert(compileFunction([[
return math.abs(unknown())
]], 0, 1) == [[
GETIMPORT R1 1 [unknown]
CALL R1 0 -1
FASTCALL 2 L0
GETIMPORT R0 4 [math.abs]
CALL R0 -1 -1
L0: RETURN R0 -1
]])

		-- however, when using optimization level 2, we assume compile time knowledge about builtin behavior even if we can't deoptimize that with fenv
		-- in the test case below, this allows us to synthesize a more efficient FASTCALL1 (and use a fixed-return call to unknown)
		assert(compileFunction([[
return math.abs(unknown())
]], 0, 2) == [[
GETIMPORT R1 1 [unknown]
CALL R1 0 1
FASTCALL1 2 R1 L0
GETIMPORT R0 4 [math.abs]
CALL R0 1 1
L0: RETURN R0 1
]])

		-- some builtins are variadic, and as such they can't use fixed-length fastcall variants
		assert(compileFunction([[
return math.max(0, unknown())
]], 0, 2) == [[
LOADN R1 0
GETIMPORT R2 1 [unknown]
CALL R2 0 -1
FASTCALL 18 L0
GETIMPORT R0 4 [math.max]
CALL R0 -1 1
L0: RETURN R0 1
]])

		-- some builtins are not variadic but don't have a fixed number of arguments; we currently don't optimize this although we might start to in the
		-- future
		assert(compileFunction([[
return bit32.extract(0, 1, unknown())
]], 0, 2) == [[
LOADN R1 0
LOADN R2 1
GETIMPORT R3 1 [unknown]
CALL R3 0 -1
FASTCALL 34 L0
GETIMPORT R0 4 [bit32.extract]
CALL R0 -1 1
L0: RETURN R0 1
]])

		-- some builtins are not variadic and have a fixed number of arguments but are not none-safe, meaning that we can't replace calls that may
		-- return none with calls that will return nil
		assert(compileFunction([[
return type(unknown())
]], 0, 2) == [[
GETIMPORT R1 1 [unknown]
CALL R1 0 -1
FASTCALL 40 L0
GETIMPORT R0 3 [type]
CALL R0 -1 1
L0: RETURN R0 1
]])

		-- importantly, this optimization also helps us get around the multret inlining restriction for builtin wrappers
		assert(compileFunction([[
local function new()
    return setmetatable({}, MT)
end

return new()
]], 1, 2) == [[
DUPCLOSURE R0 K0 ['new']
NEWTABLE R2 0 0
GETIMPORT R3 2 [MT]
FASTCALL2 61 R2 R3 L0
GETIMPORT R1 4 [setmetatable]
CALL R1 2 1
L0: RETURN R1 1
]])

		-- note that the results of this optimization are benign in fixed-arg contexts which dampens the effect of fenv substitutions on correctness in
		-- practice
		assert(compileFunction([[
local x = ...
local y, z = type(x)
return type(y, z)
]], 0, 2) == [[
GETVARARGS R0 1
FASTCALL1 40 R0 L0
MOVE R2 R0
GETIMPORT R1 1 [type]
CALL R1 1 2
L0: FASTCALL2 40 R1 R2 L1
MOVE R4 R1
MOVE R5 R2
GETIMPORT R3 1 [type]
CALL R3 2 1
L1: RETURN R3 1
]])
	end,

	EncodedTypeTable = function()
		assert(compileTypeTable([[
function myfunc(test: string, num: number)
    print(test)
end

function myfunc2(test: number?)
end

function myfunc3(test: string, n: number)
end

function myfunc4(test: string | number, n: number)
end

-- Promoted to function(any, any) since general unions are not supported.
-- Functions with all `any` parameters will have omitted type info.
function myfunc5(test: string | number, n: number | boolean)
end

function myfunc6(test: (number) -> string)
end

myfunc('test')
]]) == [[
0: function(string, number)
1: function(number?)
2: function(string, number)
3: function(any, number)
5: function(function)
]])

		assert(compileTypeTable([[
local Str = {
    a = 1
}

-- Implicit `self` parameter is automatically assumed to be table type.
function Str:test(n: number)
    print(self.a, n)
end

Str:test(234)
]]) == [[
0: function(table, number)
]])
	end,

	HostTypesAreUserdata = function()
		assert(compileTypeTable([[
function myfunc(test: string, num: number)
    print(test)
end

function myfunc2(test: Instance, num: number)
end

type Foo = string

function myfunc3(test: string, n: Foo)
end

function myfunc4<Bar>(test: Bar, n: Part)
end
]]) == [[
0: function(string, number)
1: function(userdata, number)
2: function(string, string)
3: function(any, userdata)
]])
	end,

	HostTypesVector = function()
		assert(compileTypeTable([[
function myfunc(test: Instance, pos: Vector3)
end

function myfunc2<Vector3>(test: Instance, pos: Vector3)
end

do
    type Vector3 = number

    function myfunc3(test: Instance, pos: Vector3)
    end
end
]]) == [[
0: function(userdata, vector)
1: function(userdata, any)
2: function(userdata, number)
]])
	end,

	TypeAliasScoping = function()
		assert(compileTypeTable([[
do
    type Part = number
end

function myfunc1(test: Part, num: number)
end

do
    type Part = number

    function myfunc2(test: Part, num: number)
    end
end

repeat
    type Part = number
until (function(test: Part, num: number) end)()

function myfunc4(test: Instance, num: number)
end

type Instance = string
]]) == [[
0: function(userdata, number)
1: function(number, number)
2: function(number, number)
3: function(string, number)
]])
	end,

	TypeAliasResolve = function()
		assert(compileTypeTable([[
type Foo1 = number
type Foo2 = { number }
type Foo3 = Part
type Foo4 = Foo1 -- we do not resolve aliases within aliases
type Foo5<X> = X

function myfunc(f1: Foo1, f2: Foo2, f3: Foo3, f4: Foo4, f5: Foo5<number>)
end

function myfuncerr(f1: Foo1<string>, f2: Foo5)
end

]]) == [[
0: function(number, table, userdata, any, any)
1: function(number, any)
]])
	end,

	TypeUnionIntersection = function()
		assert(compileTypeTable([[
function myfunc(test: string | nil, foo: nil)
end

function myfunc2(test: string & nil, foo: nil)
end

function myfunc3(test: string | number, foo: nil)
end

function myfunc4(test: string & number, foo: nil)
end
]]) == [[
0: function(string?, nil)
1: function(any, nil)
2: function(any, nil)
3: function(any, nil)
]])
	end,

	BuiltinFoldMathK = function()
		-- we can fold math.pi at optimization level 2
		assert(compileFunction([[
function test()
    return math.pi * 2
end
]], 0, 2) == [[
LOADK R0 K0 [6.2831853071795862]
RETURN R0 1
]])

		-- we don't do this at optimization level 1 because it may interfere with environment substitution
		assert(compileFunction([[
function test()
    return math.pi * 2
end
]], 0, 1) == [[
GETIMPORT R1 3 [math.pi]
MULK R0 R1 K0 [2]
RETURN R0 1
]])

		-- we also don't do it if math global is assigned to
		assert(compileFunction([[
function test()
    return math.pi * 2
end

math = { pi = 4 }
]], 0, 2) == [[
GETGLOBAL R2 K1 ['math']
GETTABLEKS R1 R2 K2 ['pi']
MULK R0 R1 K0 [2]
RETURN R0 1
]])
	end,

	NoBuiltinFoldFenv = function()
		-- builtin folding is disabled when getfenv/setfenv is used in the module
		assert(compileFunction([[
getfenv()

function test()
    return math.pi, math.sin(0)
end
]], 0, 2) == [[
GETIMPORT R0 2 [math.pi]
LOADN R2 0
FASTCALL1 24 R2 L0
GETIMPORT R1 4 [math.sin]
CALL R1 1 1
L0: RETURN R0 2
]])
	end,

	IfThenElseAndOr = function()
		-- if v then v else k can be optimized to ORK
		assert(compileFunction0([[
local x = ...
return if x then x else 0
]]) == [[
GETVARARGS R0 1
ORK R1 R0 K0 [0]
RETURN R1 1
]])

		-- if v then v else l can be optimized to OR
		assert(compileFunction0([[
local x, y = ...
return if x then x else y
]]) == [[
GETVARARGS R0 2
OR R2 R0 R1
RETURN R2 1
]])

		-- this also works in presence of type casts
		assert(compileFunction0([[
local x, y = ...
return if x then x :: number else 0
]]) == [[
GETVARARGS R0 2
ORK R2 R0 K0 [0]
RETURN R2 1
]])

		-- if v then k else v can be optimized to ANDK
		assert(compileFunction0([[
local x = ...
return if x then 0 else x
]]) == [[
GETVARARGS R0 1
ANDK R1 R0 K0 [0]
RETURN R1 1
]])

		-- if v then l else v can be optimized to AND
		assert(compileFunction0([[
local x, y = ...
return if x then y else x
]]) == [[
GETVARARGS R0 2
AND R2 R0 R1
RETURN R2 1
]])

		-- this also works in presence of type casts
		assert(compileFunction0([[
local x, y = ...
return if x then y else x :: number
]]) == [[
GETVARARGS R0 2
AND R2 R0 R1
RETURN R2 1
]])

		-- all of the above work when the target is a temporary register, which is safe because the value is only mutated once
		assert(compileFunction0([[
local x, y = ...
x = if x then x else y
x = if x then y else x
]]) == [[
GETVARARGS R0 2
OR R0 R0 R1
AND R0 R0 R1
RETURN R0 0
]])

		-- note that we can't do this transformation if the expression has possible side effects
		assert(compileFunction0([[
local x = ...
return if x.data then x.data else 0
]]) == [[
GETVARARGS R0 1
GETTABLEKS R2 R0 K0 ['data']
JUMPIFNOT R2 L0
GETTABLEKS R1 R0 K0 ['data']
RETURN R1 1
L0: LOADN R1 0
RETURN R1 1
]])
	end,

	SideEffects = function()
		-- we do not evaluate expressions in some cases when we know they can't carry side effects
		assert(compileFunction0([[
local x = 5, print
local y = 5, 42
local z = 5, table.find -- considered side effecting because of metamethods
]]) == [[
LOADN R0 5
LOADN R1 5
LOADN R2 5
GETIMPORT R3 2 [table.find]
RETURN R0 0
]])

		-- this also applies to returns in cases where a function gets inlined
		assert(compileFunction([[
local function test1()
    return 42
end

local function test2()
    return print
end

local function test3()
    return function() print(test3) end
end

local function test4()
    return table.find -- considered side effecting because of metamethods
end

test1()
test2()
test3()
test4()
]], 5, 2) == [[
DUPCLOSURE R0 K0 ['test1']
DUPCLOSURE R1 K1 ['test2']
DUPCLOSURE R2 K2 ['test3']
CAPTURE VAL R2
DUPCLOSURE R3 K3 ['test4']
GETIMPORT R4 6 [table.find]
RETURN R0 0
]])
	end,

	IfElimination = function()
		-- if the left hand side of a condition is constant, it constant folds and we don't emit the branch
		assert(compileFunction0("local a = false if a and b then b() end") == [[
RETURN R0 0
]])

		assert(compileFunction0("local a = true if a or b then b() end") == [[
GETIMPORT R0 1 [b]
CALL R0 0 0
RETURN R0 0
]])

		-- of course this keeps the other branch if present
		assert(compileFunction0("local a = false if a and b then b() else return 42 end") == [[
LOADN R0 42
RETURN R0 1
RETURN R0 0
]])

		assert(compileFunction0("local a = true if a or b then b() else return 42 end") == [[
GETIMPORT R0 1 [b]
CALL R0 0 0
RETURN R0 0
]])

		-- if the right hand side is constant, the condition doesn't constant fold but we still could eliminate one of the branches for 'a and K'
		assert(compileFunction0("local a = false if b and a then return 1 end") == [[
RETURN R0 0
]])

		assert(compileFunction0("local a = false if b and a then return 1 else return 2 end") == [[
LOADN R0 2
RETURN R0 1
]])

		-- of course if the right hand side of 'and' is 'true', we still need to actually evaluate the left hand side
		assert(compileFunction0("local a = true if b and a then return 1 end") == [[
GETIMPORT R0 1 [b]
JUMPIFNOT R0 L0
LOADN R0 1
RETURN R0 1
L0: RETURN R0 0
]])

		assert(compileFunction0("local a = true if b and a then return 1 else return 2 end") == [[
GETIMPORT R0 1 [b]
JUMPIFNOT R0 L0
LOADN R0 1
RETURN R0 1
L0: LOADN R0 2
RETURN R0 1
]])

		-- also even if we eliminate the branch, we still need to compute side effects
		assert(compileFunction0("local a = false if b.test and a then return 1 end") == [[
GETIMPORT R0 2 [b.test]
RETURN R0 0
]])

		assert(compileFunction0("local a = false if b.test and a then return 1 else return 2 end") == [[
GETIMPORT R0 2 [b.test]
LOADN R0 2
RETURN R0 1
]])
	end,

	ArithRevK = function()
		-- - and / have special optimized form for reverse constants; in the future, + and * will likely get compiled to ADDK/MULK
		-- other operators are not important enough to optimize reverse constant forms for
		assert(compileFunction0([[
local x: number = unknown
return 2 + x, 2 - x, 2 * x, 2 / x, 2 % x, 2 // x, 2 ^ x
]]) == [[
GETIMPORT R0 1 [unknown]
LOADN R2 2
ADD R1 R2 R0
SUBRK R2 K2 [2] R0
LOADN R4 2
MUL R3 R4 R0
DIVRK R4 K2 [2] R0
LOADN R6 2
MOD R5 R6 R0
LOADN R7 2
IDIV R6 R7 R0
LOADN R8 2
POW R7 R8 R0
RETURN R1 7
]])
	end
}