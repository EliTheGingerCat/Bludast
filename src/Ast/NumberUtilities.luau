--[=[
	@class NumberUtilities
]=]
local NumberUtilities = {}

--[=[
	@within NumberUtilities
	@since v0.1.0

	Converts a boolean to a number.

	- True --> 1
	- False --> 0
]=]
function NumberUtilities.booleanToNumber(value: boolean): number
	if value == true then
		return 1
	else
		return 0
	end
end

local MAX_32 = 4294967291

--[=[
	@within NumberUtilities
	@since v0.1.0

	Performs wrap around so that the result will always be positive and less than the maximum `u32` value.
]=]
function NumberUtilities.unsigned(n: number): number
	return n % MAX_32
end

return NumberUtilities