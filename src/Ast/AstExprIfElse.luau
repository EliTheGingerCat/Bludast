local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstExpr = AstExpr.AstExpr
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstExprIfElse = AstExpr & {
	condition: AstExpr,
	hasThen: boolean,
	trueExpr: AstExpr,
	hasElse: boolean,
	falseExpr: AstExpr
}

--[=[
	@class AstExprIfElse
]=]
local AstExprIfElse = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstExprIfElse
}
local prototype = setmetatable({}, AstExpr.metatable)
local metatable = {__index = prototype}

--[=[
	@within AstExprIfElse
	@function new
	@param location Location
	@param condition AstExpr
	@param hasThen boolean
	@param trueExpr AstExpr
	@param hasElse boolean
	@param falseExpr AstExpr
	@return AstExprIfElse
]=]
function AstExprIfElse.new(location: Location, condition: AstExpr, hasThen: boolean, trueExpr: AstExpr, hasElse: boolean, falseExpr: AstExpr): AstExprIfElse
	local self = AstExpr.interface.new(AstExprIfElse.ClassIndex, location) :: AstExprIfElse
	self.condition = condition
	self.hasThen = hasThen
	self.trueExpr = trueExpr
	self.hasElse = hasElse
	self.falseExpr = falseExpr
	setmetatable(self, metatable)
	return self
end

--[=[
	@within AstExprVarargs
	@method visit
	@param visitor AstVisitor
]=]
function prototype.visit(self: AstExprIfElse, visitor: AstVisitor): ()
	if visitor:visit(self) then
		self.condition:visit(visitor)
		self.trueExpr:visit(visitor)
		self.falseExpr:visit(visitor)
	end
end

return AstExprIfElse