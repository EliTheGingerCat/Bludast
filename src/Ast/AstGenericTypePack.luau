local AstName = require("./AstName")
local AstNodeTypes = require("./AstNodeTypes")
local AstTypePack = require("./AstTypePack")
local Location = require("@Shared/Location")

type AstName = AstName.AstName
type AstTypePack = AstTypePack.AstTypePack
type Location = Location.Location

--[=[
	@class AstGenericTypePack

	Struct from [`/Ast/include/Luau/Ast.h`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Ast.h#L130-L135).
]=]
local AstGenericTypePack = {}

function AstGenericTypePack.new(name: AstName, location: Location, defaultValue: AstTypePack?): AstGenericTypePack
	return {
		name = name,
		location = location,
		defaultValue = defaultValue
	}
end
export type AstGenericTypePack = AstNodeTypes.AstGenericTypePack

return AstGenericTypePack