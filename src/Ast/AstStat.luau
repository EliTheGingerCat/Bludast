local AstNode = require("./AstNode")
local Location = require("./Location")

type AstNode = AstNode.AstNode
type Location = Location.Location

export type AstStat = AstNode & {
	hasSemicolon: boolean
}

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