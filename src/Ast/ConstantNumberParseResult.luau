--[=[
	@class ConstantNumberParseResult

	Enum class from [`/Ast/include/Luau/Ast.h`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Ast.h#L290-L297).
]=]

--[=[
	@within ConstantNumberParseResult
	@prop Ok 0
	@readonly
	@since v0.1.0
]=]

--[=[
	@within ConstantNumberParseResult
	@prop Imprecise 1
	@readonly
	@since v0.1.0
]=]

--[=[
	@within ConstantNumberParseResult
	@prop Malformed 2
	@readonly
	@since v0.1.0
]=]

--[=[
	@within ConstantNumberParseResult
	@prop BinOverflow 3
	@readonly
	@since v0.1.0
]=]

--[=[
	@within ConstantNumberParseResult
	@prop HexOverflow 4
	@readonly
	@since v0.1.0
]=]

return {
	Ok = 0,
	Imprecise = 1,
	Malformed = 2,
	BinOverflow = 3,
	HexOverflow = 4
}