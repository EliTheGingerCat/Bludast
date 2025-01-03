local AstClassIndex = require("./AstClassIndex")
local AstType = require("./AstType")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstType = AstType.AstType
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstTypePackVariadic = AstType & {
	variadicType: AstType
}

--[=[
	@class AstTypePackVariadic
]=]
local AstTypePackVariadic = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstTypePackVariadic
}
local prototype = setmetatable({}, AstType.metatable)
local metatable = {__index = prototype}

function AstTypePackVariadic.new(location: Location, variadicType: AstType): AstTypePackVariadic
	local self = AstType.interface.new(AstTypePackVariadic.ClassIndex, location) :: AstTypePackVariadic
	self.variadicType = variadicType
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstTypePackVariadic, visitor: AstVisitor): ()
	if visitor:visit(self) then
		self.variadicType:visit(visitor)
	end
end

return AstTypePackVariadic