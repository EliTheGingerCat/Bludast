local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstNodeTypes = require("./AstNodeTypes")
local AstType = require("./AstType")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstExpr = AstExpr.AstExpr
type AstType = AstType.AstType
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstExprTypeAssertion = AstNodeTypes.AstExprTypeAssertion

--[=[
	@class AstExprTypeAssertion
]=]
local AstExprTypeAssertion = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstExprTypeAssertion
}
local prototype = setmetatable({}, AstExpr.metatable)
local metatable = {__index = prototype}

--[=[
	@within AstExprTypeAssertion
	@function new
	@param location Location
	@param expr AstExpr
	@param annotation AstType
	@return AstExprTypeAssertion
]=]
function AstExprTypeAssertion.new(location: Location, expr: AstExpr, annotation: AstType): AstExprTypeAssertion
	local self = AstExpr.interface.new(AstExprTypeAssertion.ClassIndex, location) :: AstExprTypeAssertion
	self.expr = expr
	self.annotation = annotation
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstExprTypeAssertion, visitor: AstVisitor): ()
	if visitor:visitAstExprTypeAssertion(self) then
		self.expr:visit(visitor)
		self.annotation:visit(visitor)
	end
end

return AstExprTypeAssertion