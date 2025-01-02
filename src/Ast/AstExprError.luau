local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstExpr = AstExpr.AstExpr
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstExprError = AstExpr & {
	expressions: {AstExpr},
	messageIndex: number
}

--[=[
	@class AstExprError
]=]
local AstExprError = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstExprError
}
local prototype = setmetatable({}, AstExpr.metatable)
local metatable = {__index = prototype}

function AstExprError.new(location: Location, expressions: {AstExpr}, messageIndex: number): AstExprError
	local self = AstExpr.interface.new(AstExprError.ClassIndex, location) :: AstExprError
	self.expressions = expressions
	self.messageIndex = messageIndex
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstExprError, visitor: AstVisitor): ()
	if visitor:visit(self) then
		for _, expression in self.expressions do
			expression:visit(visitor)
		end
	end
end

return AstExprError