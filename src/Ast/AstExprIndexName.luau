local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstName = require("./AstName")
local AstNodeTypes = require("./AstNodeTypes")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")
local Position = require("@Shared/Position")

type AstExpr = AstExpr.AstExpr
type AstName = AstName.AstName
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location
type Position = Position.Position

export type AstExprIndexName = AstNodeTypes.AstExprIndexName

--[=[
	@class AstExprIndexName
]=]
local AstExprIndexName = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstExprIndexName
}
local prototype = setmetatable({}, AstExpr.metatable)
local metatable = {__index = prototype}

function AstExprIndexName.new(location: Location, expr: AstExpr, index: AstName, indexLocation: Location, opPosition: Position, op: string): AstExprIndexName
	local self = AstExpr.interface.new(AstExprIndexName.ClassIndex, location) :: AstExprIndexName
	self.expr = expr
	self.index = index
	self.indexLocation = indexLocation
	self.opPosition = opPosition
	self.op = op
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstExprIndexName, visitor: AstVisitor): ()
	if visitor:visitAstExprIndexName(self) then
		self.expr:visit(visitor)
	end
end

return AstExprIndexName