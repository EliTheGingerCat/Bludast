local AstName = require("./AstName")
local AstTypePack = require("./AstTypePack")
local Location = require("./Location")

type AstName = AstName.AstName
type AstTypePack = AstTypePack.AstTypePack
type Location = Location.Location

--[=[
	@class AstGenericTypePack

	Struct from [`/Ast/include/Luau/Ast.h`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Ast.h#L130-L135).
]=]
local AstGenericTypePack = {}

function AstGenericTypePack.new(name: AstName, location: Location, defaultValue: AstTypePack)
	return {
		name = name,
		location = location,
		defaultValue = defaultValue
	}
end
export type AstGenericTypePack = typeof(AstGenericTypePack.new(...))

return AstGenericTypePack