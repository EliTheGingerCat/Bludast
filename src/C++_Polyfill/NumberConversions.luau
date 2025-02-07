--[=[
	@class NumberConversions

	See: https://en.cppreference.com/w/cpp/types/integer
]=]
local NumberConversions = {}

local MAX_8 = 2^8
local MAX_16 = 2^16
local MAX_32 = 2^32 -- Eli: TODO I also found the value 4294967291 somewhere, need to investigate.

--[=[
	@within NumberConversions
	@param length -- bytes
	@private
	@tag local
]=]
local function twosComplement(unsigned: number, length: number): number
	if unsigned > 2^(length * 8 - 1) - 1 then
		return unsigned - 2^(length * 8)
	else
		return unsigned
	end
end

--[=[
	@within NumberConversions
	@since v0.1.0
]=]
function NumberConversions.int16_t(n: number): number
	return twosComplement(NumberConversions.uint16_t(n), 2)
end

--[=[
	@within NumberConversions
	@since v0.1.0
]=]
function NumberConversions.uint8_t(n: number): number
	return n % MAX_8
end

--[=[
	@within NumberConversions
	@since v0.1.0
]=]
function NumberConversions.uint16_t(n: number): number
	return n % MAX_16
end

--[=[
	@within NumberConversions
	@since v0.1.0
]=]
function NumberConversions.uint32_t(n: number): number
	return n % MAX_32
end

--[=[
	@within NumberUtilities
	@since v0.1.0

	Performs wrap around so that the result will always be positive and less than the maximum `u32` value.
]=]
function NumberConversions.unsigned(n: number): number
	return n % MAX_32
end

return NumberConversions