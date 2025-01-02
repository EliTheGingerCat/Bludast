local AstName = require("./AstName")
local AstType = require("./AstType")
local Location = require("./Location")

type AstName = AstName.AstName
type AstType = AstType.AstType
type Location = Location.Location

export type AstTableProp = {
	--[=[
		@within AstTableProp
		@prop name AstName
		@since v0.1.0
	]=]
	name: AstName,
	
	--[=[
		@within AstTableProp
		@prop location Location
		@since v0.1.0
	]=]
	location: Location,

	--[=[
		@within AstTableProp
		@prop type AstType
		@since v0.1.0
	]=]
	type: AstType,

	--[=[
		@within AstTableProp
		@prop access number
		@since v0.1.0
	]=]
	access: number,

	--[=[
		@within AstTableProp
		@prop accessLocation Location?
		@since v0.1.0
	]=]
	accessLocation: Location?
}

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