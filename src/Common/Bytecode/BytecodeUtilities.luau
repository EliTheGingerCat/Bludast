local LuauOpcode = require("./LuauOpcode")

--[=[
	@class BytecodeUtilities
]=]
local BytecodeUtilities = {}

--[=[
	@within BytecodeUtilities
	@since v0.1.0
]=]
function BytecodeUtilities.getOpLength(op: number): number
	if
		op == LuauOpcode.LOP_GETGLOBAL
		or op == LuauOpcode.LOP_SETGLOBAL
		or op == LuauOpcode.LOP_GETIMPORT
		or op == LuauOpcode.LOP_GETTABLEKS
		or op == LuauOpcode.LOP_SETTABLEKS
		or op == LuauOpcode.LOP_NAMECALL
		or op == LuauOpcode.LOP_JUMPIFEQ
		or op == LuauOpcode.LOP_JUMPIFLE
		or op == LuauOpcode.LOP_JUMPIFLT
		or op == LuauOpcode.LOP_JUMPIFNOTEQ
		or op == LuauOpcode.LOP_JUMPIFNOTLE
		or op == LuauOpcode.LOP_JUMPIFNOTLT
		or op == LuauOpcode.LOP_NEWTABLE
		or op == LuauOpcode.LOP_SETLIST
		or op == LuauOpcode.LOP_FORGLOOP
		or op == LuauOpcode.LOP_LOADKX
		or op == LuauOpcode.LOP_FASTCALL2
		or op == LuauOpcode.LOP_FASTCALL2K
		or op == LuauOpcode.LOP_JUMPXEQKNIL
		or op == LuauOpcode.LOP_JUMPXEQKB
		or op == LuauOpcode.LOP_JUMPXEQKN
		or op == LuauOpcode.LOP_JUMPXEQKS
	then
		return 2
	else
		return 1
	end
end

--[=[
	@within BytecodeUtilities
	@since v0.1.0

	Bytecode instruction header: it's always a 32-bit integer, with low byte (first byte in little endian) containing the opcode. Some instruction types require more data and have more 32-bit integers following the header.
]=]
function BytecodeUtilities.LUAU_INSN_OP(insn: number): number
	return bit32.band(insn, 0xff)
end


-- ABC encoding: three 8-bit values, containing registers or small numbers
function BytecodeUtilities.LUAU_INSN_A(insn: number): number
	return bit32.band(bit32.rshift(insn,  8), 0xff)
end
function BytecodeUtilities.LUAU_INSN_B(insn: number): number
	return bit32.band(bit32.rshift(insn, 16), 0xff)
end
function BytecodeUtilities.LUAU_INSN_C(insn: number): number
	return bit32.band(bit32.rshift(insn, 24), 0xff)
end

local function int16(n: number): number
    if n > 2^15 - 1 then
        return n - 2^16
    else
        return n
    end
end

-- AD encoding: one 8-bit value, one signed 16-bit value
function BytecodeUtilities.LUAU_INSN_D(insn: number): number
	return int16(bit32.rshift(insn, 16))
end

-- E encoding: one signed 24-bit value
function BytecodeUtilities.LUAU_INSN_E(insn: number): number
	return int16(bit32.rshift(insn, 8))
end

return BytecodeUtilities