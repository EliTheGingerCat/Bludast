local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstNodeTypes = require("./AstNodeTypes")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstExpr = AstExpr.AstExpr
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstExprGroup = AstNodeTypes.AstExprGroup

--[=[
	@class AstExprGroup
]=]
local AstExprGroup = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstExprGroup
}
local prototype = setmetatable({}, AstExpr.metatable)
local metatable = {__index = prototype}

--[=[
	@within AstExprGroup
	@function new
	@param location Location
	@param expr Expr
	@return AstExprGroup
]=]
function AstExprGroup.new(location: Location, expr: AstExpr): AstExprGroup
	local self = AstExpr.interface.new(AstExprGroup.ClassIndex, location) :: AstExprGroup
	self.expr = expr
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstExprGroup, visitor: AstVisitor): ()
	if visitor:visitAstExprGroup(self) then
		self.expr:visit(visitor)
	end
end

return AstExprGroup