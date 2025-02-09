local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstNodeTypes = require("./AstNodeTypes")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstExpr = AstExpr.AstExpr
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstExprConstantString = AstNodeTypes.AstExprConstantString

--[=[
	@class AstExprConstantString

	A string is technically a vector of numbers, but we typically think of them as pieces of text.

	```lua
	local greeting = "Hello!"

	-- Characters and numbers are one and the same.
	assert("A" == string.char(65))
	```
]=]
local AstExprConstantString = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstExprConstantString,

	QuotedStyle = {
		Quoted = 0,
		Unquoted = 1
	}
}
local prototype = setmetatable({}, AstExpr.metatable)
local metatable = {__index = prototype}

--[=[
	@within AstExprConstantString
	@function new
	@param location Location
	@param value string
	@param quoteStyle number?
	@return AstExprConstantString
]=]
function AstExprConstantString.new(location: Location, value: string, quoteStyle: number?): AstExprConstantString
	local self = AstExpr.interface.new(AstExprConstantString.ClassIndex, location) :: AstExprConstantString
	self.value = value
	self.quoteStyle = quoteStyle or AstExprConstantString.QuotedStyle.Quoted
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstExprConstantString, visitor: AstVisitor): ()
	visitor:visitAstExprConstantString(self)
end

return AstExprConstantString