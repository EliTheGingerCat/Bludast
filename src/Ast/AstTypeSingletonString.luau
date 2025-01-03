local AstClassIndex = require("./AstClassIndex")
local AstType = require("./AstType")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstType = AstType.AstType
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstTypeSingletonString = AstType & {
	value: string
}

--[=[
	@class AstTypeSingletonString

	```lua
	type action = "walk" | "run"
	local response: action
	
	if response == "walk" then
		print("Walking.")
	elseif response == "rjn" then -- Type error: response is either "walk" or "run"
		print("Running.")
	end
]=]
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