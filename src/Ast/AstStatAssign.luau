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

export type AstStatAssign = AstNodeTypes.AstStatAssign

--[=[
	@class AstStatAssign
]=]
local AstStatAssign = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatAssign
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

function AstStatAssign.new(location: Location, vars: {AstExpr}, values: {AstExpr}): AstStatAssign
	local self = AstStat.interface.new(AstStatAssign.ClassIndex, location) :: AstStatAssign
	self.vars = vars
	self.values = values
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstStatAssign, visitor: AstVisitor): ()
	if visitor:visitAstStatAssign(self) then
		for _, lvalue in self.vars do
			lvalue:visit(visitor)
		end

		for _, expr in self.values do
			expr:visit(visitor)
		end
	end
end

return AstStatAssign