local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstNodeTypes = require("./AstNodeTypes")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstExpr = AstExpr.AstExpr
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstExprVarargs = AstNodeTypes.AstExprVarargs

--[=[
	@class AstExprVarargs
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
	visitor:visitAstExprVarargs(self)
end

return AstExprVarargs