local Pair = require("@Polyfill/Pair")

type Pair<T1, T2> = Pair.Pair<T1, T2>

--[=[
	@class NumberConversions

	Various functions to help deal with numbers in ways that are normal in C++ but weird in Luau.

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

local function truncateDecimal(n: number): number
	if n >= 0 then
		return math.floor(n)
	else
		return math.ceil(n)
	end
end

--[=[
	@within NumberConversions
	@since v0.1.0

	Converts a boolean to a number.

	- True --> 1
	- False --> 0
]=]
function NumberConversions.booleanToNumber(value: boolean): number
	if value == true then
		return 1
	else
		return 0
	end
end

function NumberConversions.int(n: number): number
	return twosComplement(NumberConversions.uint32_t(n), 4)
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
function NumberConversions.int32_t(n: number): number
	return twosComplement(NumberConversions.uint32_t(n), 4)
end

--[=[
	@within NumberConversions
	@since v0.1.0
]=]
function NumberConversions.uint8_t(n: number): number
	return truncateDecimal(n) % MAX_8
end

--[=[
	@within NumberConversions
	@since v0.1.0
	LOL
]=]
function NumberConversions.uint16_t(n: number): number
	return truncateDecimal(n) % MAX_16
end

--[=[
	@within NumberConversions
	@since v0.1.0
]=]
function NumberConversions.uint32_t(n: number): number
	return truncateDecimal(n) % MAX_32
end

--[=[
	@within NumberConversions
	@type u64 Pair<number, number>

	A Luau-safe way to deal with 64 bit integers.
]=]
export type u64 = Pair<number, number>

--[=[
	@within NumberConversions
	@prop u64_zero u64
	@since v0.1.0

	0 represented as an unsigned 64 bit number.
]=]
NumberConversions.u64_zero = Pair.new(0, 0)

--[=[
	@within NumberConversions
	@prop u64_max u64
	@since v0.1.0

	The maximum u64 value, equal to 18446744073709551615.
]=]
NumberConversions.u64_max = Pair.new(0xffffffff, 0xffffffff)

--[=[
	@within NumberConversions
	@since v0.1.0

	Check if two unsigned 64 bit numbers are equal.
]=]
function NumberConversions.u64_equal(a: u64, b: u64): boolean
	return a.first == b.first and a.second == b.second
end

--[=[
	@within NumberConversions
	@since v0.1.0

	Performs wrap around so that the result will always be positive and less than the maximum `u32` value.
]=]
function NumberConversions.unsigned(n: number): number
	return truncateDecimal(n) % MAX_32
end

return NumberConversions