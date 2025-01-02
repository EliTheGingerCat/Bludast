local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstExpr = AstExpr.AstExpr
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstExprVarargs = AstExpr & {
	
}

--[=[
	@class AstExprVarargs
	@tag class
]=]
local AstExprVarargs = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstExprVarargs
}
local prototype = setmetatable({}, AstExpr.metatable)
local metatable = {__index = prototype}

--[=[
	@within AstExprVarargs
	@function new
	@param location Location
	@return AstExprVarargs
]=]
function AstExprVarargs.new(location: Location): AstExprVarargs
	local self = AstExpr.interface.new(AstExprVarargs.ClassIndex, location) :: AstExprVarargs
	setmetatable(self, metatable)
	return self
end

--[=[
	@within AstExprVarargs
	@method visit
	@param visitor AstVisitor
]=]
function prototype.visit(self: AstExprVarargs, visitor: AstVisitor): ()
	visitor:visit(self)
end

return AstExprVarargs