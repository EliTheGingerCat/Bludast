local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstNodeTypes = require("./AstNodeTypes")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstExpr = AstExpr.AstExpr
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstExprIndexExpr = AstNodeTypes.AstExprIndexExpr

--[=[
	@class AstExprIndexExpr
]=]
local AstExprIndexExpr = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstExprIndexExpr
}
local prototype = setmetatable({}, AstExpr.metatable)
local metatable = {__index = prototype}

function AstExprIndexExpr.new(location: Location, expr: AstExpr, index: AstExpr): AstExprIndexExpr
	local self = AstExpr.interface.new(AstExprIndexExpr.ClassIndex, location) :: AstExprIndexExpr
	self.expr = expr
	self.index = index
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstExprIndexExpr, visitor: AstVisitor): ()
	if visitor:visitAstExprIndexExpr(self) then
		self.expr:visit(visitor)
		self.index:visit(visitor)
	end
end

return AstExprIndexExpr