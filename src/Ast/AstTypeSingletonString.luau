local AstClassIndex = require("./AstClassIndex")
local AstType = require("./AstType")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstType = AstType.AstType
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

--[=[
	@class AstTypeSingletonString

	A string is technically a vector of numbers, but we typically think of them as pieces of text.

	```lua
	local greeting = "Hello!"

	-- Characters and numbers are one and the same.
	assert("A" == string.char(65))
	```
]=]
export type AstTypeSingletonString = AstType & {
	value: string
}

local AstTypeSingletonString = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstTypeSingletonString
}
local prototype = setmetatable({}, AstType.metatable)
local metatable = {__index = prototype}

--[=[
	@within AstTypeSingletonString
	@function new
]=]
function AstTypeSingletonString.new(location: Location, value: string): AstTypeSingletonString
	local self = AstType.interface.new(AstTypeSingletonString.ClassIndex, location) :: AstTypeSingletonString
	self.value = value
	setmetatable(self, metatable)
	return self
end

function prototype.visitor(self: AstTypeSingletonString, visitor: AstVisitor): ()
	visitor:visit(self)
end

return AstTypeSingletonString