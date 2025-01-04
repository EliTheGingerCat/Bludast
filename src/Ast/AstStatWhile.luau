local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstStat = require("./AstStat")
local AstStatBlock = require("./AstStatBlock")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstExpr = AstExpr.AstExpr
type AstStat = AstStat.AstStat
type AstStatBlock = AstStatBlock.AstStatBlock
type Location = Location.Location

export type AstStatWhile = AstStat & {
	condition: AstExpr,
	body: AstStatBlock,

	hasDo: boolean,
	doLocation: Location
}

--[=[
	@class AstStatWhile
]=]
local AstStatWhile = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatWhile
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

function AstStatWhile.new(location: Location, condition: AstExpr, body: AstStatBlock, hasDo: boolean, doLocation: Location): AstStatWhile
	local self = AstStat.interface.new(AstStatWhile.ClassIndex, location) :: AstStatWhile
	self.condition = condition
	self.body = body
	self.hasDo = hasDo
	self.doLocation = doLocation
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstStatWhile, visitor: AstVisitor.AstVisitor): ()
	if visitor:visit(self) then
		self.condition:visit(visitor)
		self.body:visit(visitor)
	end
end

return AstStatWhile