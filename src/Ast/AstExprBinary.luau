local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstNodeTypes = require("./AstNodeTypes")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstExpr = AstExpr.AstExpr
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

--[=[
	@class AstExprBinary
	@tag class

	Class from [`/Ast/src/Ast.cpp`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/src/Ast.cpp#L279-L294) and [`/Ast/include/Luau/Ast.h`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Ast.h#L494-L528).
]=]
export type AstExprBinary = AstNodeTypes.AstExprBinary

local AstExprBinary = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstExprBinary,

	Op = {
		Add = 1,
		Sub = 2,
		Mul = 3,
		Div = 4,
		FloorDiv = 5,
		Mod = 6,
		Pow = 7,
		Concat = 8,
		CompareNe = 9,
		CompareEq = 10,
		CompareLt = 11,
		CompareLe = 12,
		CompareGt = 13,
		CompareGe = 14,
		And = 15,
		Or = 16
	},
	Op__Count = 16
}
local prototype = setmetatable({}, AstExpr.metatable)
local metatable = {__index = prototype}

function AstExprBinary.new(location: Location, op: number, left: AstExpr, right: AstExpr): AstExprBinary
	local self = AstExpr.interface.new(AstExprBinary.ClassIndex, location) :: AstExprBinary
	self.op = op
	self.left = left
	self.right = right
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstExprBinary, visitor: AstVisitor): ()
	if visitor:visitAstExprBinary(self) then
		self.left:visit(visitor)
		self.right:visit(visitor)
	end
end

return AstExprBinary