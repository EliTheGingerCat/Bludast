--[=[
	@class NumberUtilities

	Various functions to help deal with numbers in ways that are normal in C++ but weird in Luau.
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

return NumberUtilities