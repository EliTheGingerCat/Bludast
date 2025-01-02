local AstClassIndex = require("./AstClassIndex")
local AstType = require("./AstType")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstType = AstType.AstType
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

--[=[
	@class AstTypeSingletonBool

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
export type AstTypeSingletonBool = AstType & {
	value: boolean
}

local AstTypeSingletonBool = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstTypeSingletonBool
}
local prototype = setmetatable({}, AstType.metatable)
local metatable = {__index = prototype}

--[=[
	@within AstTypeSingletonBool
	@function new
]=]
function AstTypeSingletonBool.new(location: Location, value: boolean): AstTypeSingletonBool
	local self = AstType.interface.new(AstTypeSingletonBool.ClassIndex, location) :: AstTypeSingletonBool
	self.value = value
	setmetatable(self, metatable)
	return self
end

function prototype.visitor(self: AstTypeSingletonBool, visitor: AstVisitor): ()
	visitor:visit(self)
end

return AstTypeSingletonBool