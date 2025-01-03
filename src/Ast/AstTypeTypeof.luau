local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstType = require("./AstType")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstExpr = AstExpr.AstExpr
type AstType = AstType.AstType
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstTypeTypeof = AstType & {
	expr: AstExpr
}

--[=[
	@class AstTypeTypeof
]=]
local AstTypeTypeof = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstTypeTypeof
}
local prototype = setmetatable({}, AstType.metatable)
local metatable = {__index = prototype}

function AstTypeTypeof.new(location: Location, expr: AstExpr): AstTypeTypeof
	local self = AstType.interface.new(AstTypeTypeof.ClassIndex, location) :: AstTypeTypeof
	self.expr = expr
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstTypeTypeof, visitor: AstVisitor): ()
	if visitor:visit(self) then
		self.expr:visit(visitor)
	end
end

return AstTypeTypeof