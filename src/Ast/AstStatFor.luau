local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstLocal = require("./AstLocal")
local AstNodeTypes = require("./AstNodeTypes")
local AstStat = require("./AstStat")
local AstStatBlock = require("./AstStatBlock")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstExpr = AstExpr.AstExpr
type AstLocal = AstLocal.AstLocal
type AstStat = AstStat.AstStat
type AstStatBlock = AstStatBlock.AstStatBlock
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstStatFor = AstNodeTypes.AstStatFor

--[=[
	@class AstStatFor
]=]
local AstStatFor = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatFor
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

function AstStatFor.new(location: Location, var: AstLocal, from: AstExpr, to: AstExpr, step: AstExpr?, body: AstStatBlock, hasDo: boolean, doLocation: Location): AstStatFor
	local self = AstStat.interface.new(AstStatFor.ClassIndex, location) :: AstStatFor
	self.var = var
	self.from = from
	self.to = to
	self.step = step
	self.body = body
	self.hasDo = hasDo
	self.doLocation = doLocation
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstStatFor, visitor: AstVisitor): ()
	if visitor:visitAstStatFor(self) then
		if self.var.annotation then
			self.var.annotation:visit(visitor)
		end

		self.from:visit(visitor)
		self.to:visit(visitor)

		if self.step then
			self.step:visit(visitor)
		end

		self.body:visit(visitor)
	end
end

return AstStatFor