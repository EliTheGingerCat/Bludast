local AstNode = require("./AstNode")
local AstNodeTypes = require("./AstNodeTypes")
local Location = require("@Shared/Location")

type AstNode = AstNode.AstNode
type Location = Location.Location

--[=[
	@class AstExpr

	An expression is any combination of variables, constants, and operators that evaluates to a single value.
]=]
local AstExpr = {}
local prototype = setmetatable({}, AstNode.metatable)
local metatable = {__index = prototype}

export type AstExpr = AstNodeTypes.AstExpr

function AstExpr.new(classIndex: number, location: Location): AstExpr
	local self = AstNode.interface.new(classIndex, location) :: AstExpr
	setmetatable(self, metatable)
	return self
end

function prototype.asExpr(self: AstExpr): AstExpr
	return self
end

return {
	interface = AstExpr,
	metatable = metatable
}