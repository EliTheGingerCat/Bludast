local AstName = require("./AstName")
local AstType = require("./AstType")
local Location = require("./Location")

type AstName = AstName.AstName
type AstType = AstType.AstType
type Location = Location.Location

--[=[
	@class AstGenericType

	Struct from [`/Ast/include/Luau/Ast.h`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Ast.h#L123-L128).
]=]
local AstGenericType = {}

function AstGenericType.new(name: AstName, location: Location, defaultValue: AstType)
	return {
		name = name,
		location = location,
		defaultValue = defaultValue
	}
end
export type AstGenericType = typeof(AstGenericType.new(...))

return AstGenericType