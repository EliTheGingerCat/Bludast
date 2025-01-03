local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstStat = require("./AstStat")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstExpr = AstExpr.AstExpr
type AstStat = AstStat.AstStat
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstStatContinue = AstStat & {
	list: {AstExpr}
}

--[=[
	@class AstStatReturn
]=]
local AstStatReturn = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatContinue
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

function AstStatReturn.new(location: Location, list: {AstExpr}): AstStatContinue
	local self = setmetatable(AstStat.interface.new(AstStatReturn.ClassIndex, location), metatable) :: AstStatContinue
	self.list = list
	return self
end

function prototype.visit(self: AstStatContinue, visitor: AstVisitor): ()
	if visitor:visit(self) then
		for _, expr in self.list do
			-- Eli NEW_SOLVER
			expr:visit(visitor)
		end
	end
end

return AstStatReturn