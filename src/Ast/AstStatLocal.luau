local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstLocal = require("./AstLocal")
local AstStat = require("./AstStat")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstExpr = AstExpr.AstExpr
type AstLocal = AstLocal.AstLocal
type AstStat = AstStat.AstStat
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstStatLocal = AstStat & {
	vars: {AstLocal},
	values: {AstExpr},

	equalsSignLocation: Location?
}

local AstStatLocal = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatLocal
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

function AstStatLocal.new(location: Location, vars: {AstLocal}, values: {AstExpr}, equalsSignLocation: Location?): AstStatLocal
	local self = AstStat.interface.new(AstStatLocal.ClassIndex, location) :: AstStatLocal
	self.vars = vars
	self.values = values
	self.equalsSignLocation = equalsSignLocation
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstStatLocal, visitor: AstVisitor): ()
	if visitor:visit(self) then
		for _, var in self.vars do
			if var.annotation then
				-- Eli NEW_SOLVER
				var.annotation:visit(visitor)
			end
		end

		for _, expr in self.values do
			expr:visit(visitor)
		end
	end
end

return AstStatLocal