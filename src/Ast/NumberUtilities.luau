--[=[
	@class NumberUtilities
]=]
local NumberUtilities = {}

local MAX_32 = 4294967291

--[=[
	@within NumberUtilities
	@function unsigned
	@param n number
	@return number

	Performs wrap around so that the result will always be positive and less than the maximum `u32` value.
]=]
function NumberUtilities.unsigned(n: number): number
	return n % MAX_32
end

return NumberUtilities