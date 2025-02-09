local AstNode = require("./AstNode")
local AstNodeTypes = require("./AstNodeTypes")
local Location = require("@Shared/Location")

type AstNode = AstNode.AstNode
export type AstStat = AstNodeTypes.AstStat
type Location = Location.Location

--[=[
	@class AstStat
]=]
local AstStat = {}
local prototype = setmetatable({}, AstNode.metatable)
local metatable = {__index = prototype}

function AstStat.new(classIndex: number, location: Location): AstStat
	local self = AstNode.interface.new(classIndex, location) :: AstStat
	self.hasSemicolon = false
	setmetatable(self, metatable)
	return self
end

function prototype.asStat(self: AstStat): AstStat
	return self
end

return {
	interface = AstStat,
	metatable = metatable
}