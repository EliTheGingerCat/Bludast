local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstExpr = AstExpr.AstExpr
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstExprConstantNumber = AstExpr & {
	value: number,
	parseResult: number
}

--[=[
	@class AstExprConstantNumber
	@tag class
]=]
local AstExprConstantNumber = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstExprConstantNumber
}
local prototype = setmetatable({}, AstExpr.metatable)
local metatable = {__index = prototype}

--[=[
	@within AstExprConstantNumber
	@function new
	@param location Location
	@return AstExprConstantNumber
]=]
function AstExprConstantNumber.new(location: Location, value: number, parseResult: number): AstExprConstantNumber
	local self = AstExpr.interface.new(AstExprConstantNumber.ClassIndex, location) :: AstExprConstantNumber
	self.value = value
	self.parseResult = parseResult
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstExprConstantNumber, visitor: AstVisitor): ()
	visitor:visit(self)
end

return AstExprConstantNumber