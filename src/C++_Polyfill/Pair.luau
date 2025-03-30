--[=[
	@class Pair

	Class template from [C++ std](https://en.cppreference.com/w/cpp/utility/pair).

	Holds two values. They can be of different types.
]=]
local Pair = {}

--[=[
	@within Pair
	@prop first T1
	@readonly
	@since v0.1.0
]=]

--[=[
	@within Pair
	@prop second T2
	@readonly
	@since v0.1.0
]=]

export type Pair<T1, T2> = {
	first: T1,
	second: T2
}

--[=[
	@within Pair
	@since v0.1.0
]=]
function Pair.new<T1, T2>(o1: T1, o2: T2): Pair<T1, T2>
	return {
		first = o1,
		second = o2
	}
end

return Pair