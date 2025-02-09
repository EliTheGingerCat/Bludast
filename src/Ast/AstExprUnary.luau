local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstNodeTypes = require("./AstNodeTypes")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstExpr = AstExpr.AstExpr
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

--[=[
	@class AstExprUnary

	Class from [`/Ast/src/Ast.cpp`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/src/Ast.cpp#L250-L261) and [`/Ast/include/Luau/Ast.h`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Ast.h#L472-L490).
]=]
export type AstExprUnary = AstNodeTypes.AstExprUnary

local AstExprUnary = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstExprUnary,

	Op = {
		Not = 0,
		Minus = 1,
		Len = 2
	}
}
local prototype = setmetatable({}, AstExpr.metatable)
local metatable = {__index = prototype}

function AstExprUnary.new(location: Location, op: number, expr: AstExpr): AstExprUnary
	local self = AstExpr.interface.new(AstExprUnary.ClassIndex, location) :: AstExprUnary
	self.op = op
	self.expr = expr
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstExprUnary, visitor: AstVisitor): ()
	if visitor:visitAstExprUnary(self) then
		self.expr:visit(visitor)
	end
end

return AstExprUnary