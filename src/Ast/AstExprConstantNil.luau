local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstNodeTypes = require("./AstNodeTypes")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstExpr = AstExpr.AstExpr
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstExprConstantNil = AstNodeTypes.AstExprConstantNil

--[=[
	@class AstExprConstantNil
]=]
local AstExprConstantNil = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstExprConstantNil
}
local prototype = setmetatable({}, AstExpr.metatable)
local metatable = {__index = prototype}

--[=[
	@within AstExprConstantNil
	@function new
	@param location Location
	@return AstExprConstantNil
]=]
function AstExprConstantNil.new(location: Location): AstExprConstantNil
	local self = AstExpr.interface.new(AstExprConstantNil.ClassIndex, location) :: AstExprConstantNil
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstExprConstantNil, visitor: AstVisitor): ()
	visitor:visitAstExprConstantNil(self)
end

return AstExprConstantNil