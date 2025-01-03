local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstExpr = AstExpr.AstExpr
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstExprConstantBool = AstExpr & {
	value: boolean
}

--[=[
	@class AstExprConstantBool

	A boolean is true or false. It is named after [George Boole](https://en.wikipedia.org/wiki/George_Boole).

	```lua
	if true then
		print("This will be printed.")
	end

	if false then
		print("This will not be printed.")
	end
	```
]=]
local AstExprConstantBool = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstExprConstantBool
}
local prototype = setmetatable({}, AstExpr.metatable)
local metatable = {__index = prototype}

--[=[
	@within AstExprConstantBool
	@function new
	@param location Location
	@param value boolean
	@return AstExprConstantBool
]=]
function AstExprConstantBool.new(location: Location, value: boolean): AstExprConstantBool
	local self = AstExpr.interface.new(AstExprConstantBool.ClassIndex, location) :: AstExprConstantBool
	self.value = value
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstExprConstantBool, visitor: AstVisitor): ()
	visitor:visit(self)
end

return AstExprConstantBool