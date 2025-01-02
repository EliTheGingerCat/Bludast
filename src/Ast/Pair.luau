--[=[
	@class Pair
	@tag C++

	Class template from C++ std.

	<T1, T2>

	Holds two values. They can be of different types. 

	https://en.cppreference.com/w/cpp/utility/pair
]=]
local Pair = {}

export type Pair<T1, T2> = {
	--[=[
		@within Pair
		@prop first T1
		@readonly
		@since v0.1.0
	]=]
	first: T1,

	--[=[
		@within Pair
		@prop second T2
		@readonly
		@since v0.1.0
	]=]
	second: T2
}

--[=[
	@within Pair
	@function new
	@param o1 T1
	@param o2 T2
	@return Pair<T1, T2>
	<T1, T2>
]=]
function Pair.new<T1, T2>(o1: T1, o2: T2): Pair<T1, T2>
	return {
		first = o1,
		second = o2
	}
end

return Pair