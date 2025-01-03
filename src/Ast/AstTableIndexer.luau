local AstType = require("./AstType")
local Location = require("./Location")

type AstType = AstType.AstType
type Location = Location.Location

export type AstTableIndexer = {
	indexType: AstType,
	resultType: AstType,
	location: Location,

	access: number,
	accessLocation: Location?
}

--[=[
	@class AstTableIndexer
]=]
local AstTableIndexer = {}

function AstTableIndexer.new(indexType: AstType, resultType: AstType, location: Location, access: number, accessLocation: Location?): AstTableIndexer
	return {
		indexType = indexType,
		resultType = resultType,
		location = location,

		access = access,
		accessLocation = accessLocation
	}
end

return AstTableIndexer