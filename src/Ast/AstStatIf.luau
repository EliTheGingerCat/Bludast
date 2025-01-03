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

export type AstStatIf = AstStat & {
	condition: AstExpr,
	thenbody: AstStatBlock,
	elsebody: AstStat,

	thenLocation: Location?,

	-- Active for 'elseif' as well
	elseLocation: Location?
}

--[=[
	@class AstStatIf
]=]
local AstStatIf = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatIf
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

function AstStatIf.new(location: Location, condition: AstExpr, thenbody: AstStatBlock, elsebody: AstStat, thenLocation: Location?, elseLocation: Location?): AstStatIf
	local self = AstStat.interface.new(AstStatIf.ClassIndex, location) :: AstStatIf
	self.condition = condition
	self.thenbody = thenbody
	self.elsebody = elsebody
	self.thenLocation = thenLocation
	self.elseLocation = elseLocation
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstStatIf, visitor: AstVisitor.AstVisitor): ()
	if visitor:visit(self) then
		self.condition:visit(visitor)
		self.thenbody:visit(visitor)

		if self.elsebody then
			self.elsebody:visit(visitor)
		end
	end
end

return AstStatIf