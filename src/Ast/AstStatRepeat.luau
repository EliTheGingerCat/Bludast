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

export type AstStatRepeat = AstStat & {
	condition: AstExpr,
	body: AstStatBlock
}

local interface = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatRepeat
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

function interface.new(location: Location, condition: AstExpr, body: AstStatBlock): AstStatRepeat
	local self = AstStat.interface.new(interface.ClassIndex, location) :: AstStatRepeat
	self.condition = condition
	self.body = body
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstStatRepeat, visitor: AstVisitor.AstVisitor): ()
	if visitor:visit(self) then
		self.body:visit(visitor)
		self.condition:visit(visitor)
	end
end

return interface