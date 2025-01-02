local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstExpr = AstExpr.AstExpr
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstExprInterpString = AstExpr & {
	strings: {string},
	expressions: {AstExpr}
}

--[=[
	@class AstExprInterpString

	An interpolated string such as `foo{bar}baz` is represented as an array of strings for "foo" and "bar", and an array of expressions for "baz". [`strings`](AstExprInterpString#strings) will always have one more element than `expressions`.
]=]
local AstExprInterpString = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstExprInterpString
}
local prototype = setmetatable({}, AstExpr.metatable)
local metatable = {__index = prototype}

--[=[
	@within AstExprInterpString
	@function new
	@param location Location
	@param strings {string}
	@param expressions {AstExpr}
	@return AstExprInterpString
]=]
function AstExprInterpString.new(location: Location, strings: {string}, expressions: {AstExpr}): AstExprInterpString
	local self = AstExpr.interface.new(AstExprInterpString.ClassIndex, location) :: AstExprInterpString
	self.strings = string
	self.expressions = expressions
	setmetatable(self, metatable)
	return self
end

--[=[
	@within AstExprVarargs
	@method visit
	@param visitor AstVisitor
]=]
function prototype.visit(self: AstExprInterpString, visitor: AstVisitor): ()
	if visitor:visit(self) then
		for _, expr in self.expressions do
			expr:visit(visitor)
		end
	end
end

return AstExprInterpString