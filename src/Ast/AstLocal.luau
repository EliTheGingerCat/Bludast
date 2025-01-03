local AstName = require("./AstName")
local AstType = require("./AstType")
local Location = require("./Location")

type AstName = AstName.AstName
type AstType = AstType.AstType
type Location = Location.Location

export type AstLocal = {
	name: AstName,
	location: Location,
	shadow: AstLocal?,
	functionDepth: number,
	loopDepth: number,

	annotation: AstType?
}

local AstLocal = {}

--[=[
	@class AstLocal
]=]
function AstLocal.new(name: AstName, location: Location, shadow: AstLocal?, functionDepth: number, loopDepth: number, annotation: AstType?): AstLocal
	return {
		name = name,
		location = location,
		shadow = shadow,
		functionDepth = functionDepth,
		loopDepth = loopDepth,
		annotation = annotation
	}
end

return AstLocal