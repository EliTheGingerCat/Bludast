local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstNodeTypes = require("./AstNodeTypes")
local AstStat = require("./AstStat")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

export type AstStatError = AstNodeTypes.AstStatError

local AstStatError = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatError
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

--[=[
	@class AstStatError
]=]
function AstStatError.new(location: Location.Location, expressions: {AstExpr.AstExpr}, statements: {AstStat.AstStat}, messageIndex: number): AstStatError
	local self = AstStat.interface.new(AstStatError.ClassIndex, location) :: AstStatError
	self.expressions = expressions
	self.statements = statements
	self.messageIndex = messageIndex
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstStatError, visitor: AstVisitor.AstVisitor): ()
	if visitor:visitAstStatError(self) then
		-- Eli NEW_SOLVER
		for _, expression in self.expressions do
			expression:visit(visitor)
		end

		for _, statement in self.statements do
			statement:visit(visitor)
		end
	end
end

return AstStatError