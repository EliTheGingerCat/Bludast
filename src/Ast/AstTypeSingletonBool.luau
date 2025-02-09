local AstClassIndex = require("./AstClassIndex")
local AstNodeTypes = require("./AstNodeTypes")
local AstType = require("./AstType")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstType = AstType.AstType
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstTypeSingletonBool = AstNodeTypes.AstTypeSingletonBool

--[=[
	@class AstTypeSingletonBool

	Booleans can be used as singletons in types.

	```lua
	type results<T, F> = {
		success: true,
		value: T
	} | {
		success: false,
		value: F
	}

	local response: results<number, string>
	if response.success then
		-- response.value: number
	else
		-- response.value: string
	end
	```
]=]
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
	visitor:visitAstTypeSingletonBool(self)
end

return AstTypeSingletonBool