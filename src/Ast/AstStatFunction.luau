local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstExprFunction = require("./AstExprFunction")
local AstNodeTypes = require("./AstNodeTypes")
local AstStat = require("./AstStat")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstExpr = AstExpr.AstExpr
type AstExprFunction = AstExprFunction.AstExprFunction
type AstStat = AstStat.AstStat
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstStatFunction = AstNodeTypes.AstStatFunction

--[=[
	@class AstStatFunction
]=]
local AstStatFunction = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatFunction
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

function AstStatFunction.new(location: Location, name: AstExpr, func: AstExprFunction): AstStatFunction
	local self = AstStat.interface.new(AstStatFunction.ClassIndex, location) :: AstStatFunction
	self.name = name
	self.func = func
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstStatFunction, visitor: AstVisitor): ()
	if visitor:visitAstStatFunction(self) then
		self.name:visit(visitor)
		self.func:visit(visitor)
	end
end

return AstStatFunction