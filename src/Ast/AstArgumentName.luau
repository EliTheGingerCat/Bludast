local AstName = require("./AstName")
local Location = require("@Shared/Location")
local Pair = require("@Polyfill/Pair")

type AstName = AstName.AstName
type Location = Location.Location
type Pair<T1, T2> = Pair.Pair<T1, T2>

--[=[
	@class AstArgumentName
	@tag type alias

	Type alias from [`/Ast/include/Luau/Ast.h`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Ast.h#L121).
]=]
local AstArgumentName = {}

-- TODO: remove and replace when we get a common struct for this pair instead of AstName
export type AstArgumentName = Pair<AstName, Location>

--[=[
	@within AstArgumentName
	@function new
	@param name AstName
	@param location Location
	@return AstArgumentName
]=]
function AstArgumentName.new(name: AstName, location: Location): AstArgumentName
	return Pair.new(name, location)
end

return AstArgumentName