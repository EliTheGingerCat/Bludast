local AstName = require("./AstName")
local AstNodeTypes = require("./AstNodeTypes")
local AstType = require("./AstType")
local Location = require("@Shared/Location")

type AstName = AstName.AstName
type AstType = AstType.AstType
type Location = Location.Location

export type AstTableProp = AstNodeTypes.AstTableProp

--[=[
	@class AstTableProp
]=]
local AstTableProp = {}

function AstTableProp.new(name: AstName, location: Location, typeAst: AstType, access: number, accessLocation: Location?): AstTableProp
	return {
		name = name,
		location = location,
		type = typeAst,
		access = access,
		accessLocation = accessLocation
	}
end

return AstTableProp