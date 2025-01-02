local AstNode = require("./AstNode")
local Location = require("./Location")

type AstNode = AstNode.AstNode
type Location = Location.Location

--[=[
	@class AstExpr

	An expression is any combination of variables, constants, and operators that evaluates to a single value.
]=]
local AstExpr = {}
local prototype = setmetatable({}, AstNode.metatable)
local metatable = {__index = prototype}

export type AstExpr = AstNode & {
	asExpr: (self: AstExpr) -> AstExpr
}

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