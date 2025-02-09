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

export type AstStatReturn = AstNodeTypes.AstStatReturn

--[=[
	@class AstStatReturn
]=]
local AstStatReturn = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatReturn
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

function AstStatReturn.new(location: Location, list: {AstExpr}): AstStatReturn
	local self = setmetatable(AstStat.interface.new(AstStatReturn.ClassIndex, location), metatable) :: AstStatReturn
	self.list = list
	return self
end

function prototype.visit(self: AstStatReturn, visitor: AstVisitor): ()
	if visitor:visitAstStatReturn(self) then
		for _, expr in self.list do
			-- Eli NEW_SOLVER
			expr:visit(visitor)
		end
	end
end

return AstStatReturn