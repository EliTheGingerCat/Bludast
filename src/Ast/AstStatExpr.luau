local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstNodeTypes = require("./AstNodeTypes")
local AstStat = require("./AstStat")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

export type AstStatExpr = AstNodeTypes.AstStatExpr

local AstStatExpr = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatExpr
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

--[=[
	@class AstStatExpr
]=]
function AstStatExpr.new(location: Location.Location, expr: AstExpr.AstExpr): AstStatExpr
	local self = AstStat.interface.new(AstStatExpr.ClassIndex, location) :: AstStatExpr
	self.expr = expr
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstStatExpr, visitor: AstVisitor.AstVisitor): ()
	if visitor:visitAstStatExpr(self) then
		self.expr:visit(visitor)
	end
end

return AstStatExpr