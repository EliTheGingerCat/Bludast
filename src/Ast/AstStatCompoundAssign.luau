local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstNodeTypes = require("./AstNodeTypes")
local AstStat = require("./AstStat")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstExpr = AstExpr.AstExpr
type AstStat = AstStat.AstStat
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstStatCompoundAssign = AstNodeTypes.AstStatCompoundAssign

--[=[
	@class AstStatCompoundAssign
]=]
local AstStatCompoundAssign = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatCompoundAssign
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

function AstStatCompoundAssign.new(location: Location, op: number, var: AstExpr, value: AstExpr): AstStatCompoundAssign
	local self = AstStat.interface.new(AstStatCompoundAssign.ClassIndex, location) :: AstStatCompoundAssign
	self.op = op
	self.var = var
	self.value = value
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstStatCompoundAssign, visitor: AstVisitor): ()
	if visitor:visitAstStatCompoundAssign(self) then
		self.var:visit(visitor)
		self.value:visit(visitor)
	end
end

return AstStatCompoundAssign