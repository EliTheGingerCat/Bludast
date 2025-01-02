local AstNode = require("./AstNode")
local Location = require("./Location")

type AstNode = AstNode.AstNode
type Location = Location.Location

export type AstType = AstNode

local AstType = {}
local prototype = setmetatable({}, AstNode.metatable)
local metatable = {__index = prototype}

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