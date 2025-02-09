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

export type AstStatForIn = AstStat & {
	vars: {AstLocal},
	values: {AstExpr},
	body: AstStatBlock,

	hasIn: boolean,
	inLocation: Location,

	hasDo: boolean,
	doLocation: Location
}

--[=[
	@class AstStatForIn
]=]
local AstStatForIn = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatForIn
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

function AstStatForIn.new(location: Location, vars: {AstLocal}, values: {AstExpr}, body: AstStatBlock, hasIn: boolean, inLocation: Location, hasDo: boolean, doLocation: Location): AstStatForIn
	local self = AstStat.interface.new(AstStatForIn.ClassIndex, location) :: AstStatForIn
	self.vars = vars
	self.values = values
	self.body = body
	self.hasIn = hasIn
	self.inLocation = inLocation
	self.hasDo = hasDo
	self.doLocation = doLocation
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstStatForIn, visitor: AstVisitor): ()
	if visitor:visitAstStatForIn(self) then
		for _, var in self.vars do
			if var.annotation then
				-- Eli NEW_SOLVER
				var.annotation:visit(visitor)
			end
		end

		for _, expr in self.values do
			-- Eli NEW_SOLVER
			expr:visit(visitor)
		end

		self.body:visit(visitor)
	end
end

return AstStatForIn