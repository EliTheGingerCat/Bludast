--[=[
	@class ConstantnumberParseResult
	@tag enum class

	Enum class from [`/Ast/include/Luau/Ast.h`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Ast.h#L290-L297).
]=]
return {
	--[=[
		@within ConstantnumberParseResult
		@prop Ok 0
		@readonly
		@since v0.1.0
	]=]
	Ok = 0,

	--[=[
		@within ConstantnumberParseResult
		@prop Imprecise 1
		@readonly
		@since v0.1.0
	]=]
	Imprecise = 1,

	--[=[
		@within ConstantnumberParseResult
		@prop Malformed 2
		@readonly
		@since v0.1.0
	]=]
	Malformed = 2,

	--[=[
		@within ConstantnumberParseResult
		@prop BinOverflow 3
		@readonly
		@since v0.1.0
	]=]
	BinOverflow = 3,

	--[=[
		@within ConstantnumberParseResult
		@prop HexOverflow 4
		@readonly
		@since v0.1.0
	]=]
	HexOverflow = 4
}