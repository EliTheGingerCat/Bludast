local AstNode = require("./AstNode")
local AstNodeTypes = require("./AstNodeTypes")
local Location = require("@Shared/Location")

export type AstType = AstNodeTypes.AstType
type Location = Location.Location

local AstType = {}
local prototype = setmetatable({}, AstNode.metatable)
local metatable = {__index = prototype}

--[=[
	@class AstType
]=]
function AstType.new(classIndex: number, location: Location): AstType
	local self = AstNode.interface.new(classIndex, location)
	setmetatable(self, metatable)
	return self :: any
end

function prototype.asType(self: AstType): AstType
	return self
end

return {
	interface = AstType,
	metatable = metatable
}