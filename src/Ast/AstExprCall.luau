local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstNodeTypes = require("./AstNodeTypes")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstExpr = AstExpr.AstExpr
type Location = Location.Location

export type AstExprCall = AstNodeTypes.AstExprCall

--[=[
	@class AstExprCall
]=]
local AstExprCall = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstExprCall
}
local prototype = setmetatable({}, AstExpr.metatable)
local metatable = {
	__index = prototype
}

function AstExprCall.new(location: Location, func: AstExpr, args: {AstExpr}, self_boolean: boolean, argLocation: Location): AstExprCall
	local self = AstExpr.interface.new(AstExprCall.ClassIndex, location) :: AstExprCall
	self.func = func
	self.args = args
	self.self = self_boolean
	self.argLocation = argLocation
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstExprCall, visitor: AstVisitor.AstVisitor): ()
	if visitor:visitAstExprCall(self) then
		self.func:visit(visitor)

		for _, arg in self.args do
			-- Eli NEW_SOLVER
			arg:visit(visitor)
		end
	end
end

return AstExprCall