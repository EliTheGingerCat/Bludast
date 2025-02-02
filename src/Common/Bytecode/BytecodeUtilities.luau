--[=[
	@class BytecodeUtilities
]=]
local BytecodeUtilities = {}

--[=[
	@within BytecodeUtilities
	@since v0.1.0

	Bytecode instruction header: it's always a 32-bit integer, with low byte (first byte in little endian) containing the opcode. Some instruction types require more data and have more 32-bit integers following the header.
]=]
function BytecodeUtilities.LUAU_INSN_OP(insn: number): number
	return bit32.band(insn, 0xff)
end

return BytecodeUtilities