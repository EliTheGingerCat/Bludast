local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstExpr = AstExpr.AstExpr
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstExprIndexExpr = AstExpr & {
	expr: AstExpr,
	index: AstExpr
}

--[=[
	@class AstExprIndexExpr
	@tag class
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
	if visitor:visit(self) then
		self.expr:visit(visitor)
		self.index:visit(visitor)
	end
end

return AstExprIndexExpr