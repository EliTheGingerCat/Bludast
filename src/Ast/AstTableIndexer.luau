local AstNodeTypes = require("./AstNodeTypes")
local AstType = require("./AstType")
local Location = require("@Shared/Location")

type AstType = AstType.AstType
type Location = Location.Location

export type AstTableIndexer = AstNodeTypes.AstTableIndexer

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