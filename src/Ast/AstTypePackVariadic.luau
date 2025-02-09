local AstClassIndex = require("./AstClassIndex")
local AstNodeTypes = require("./AstNodeTypes")
local AstType = require("./AstType")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstType = AstType.AstType
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstTypePackVariadic = AstNodeTypes.AstTypePackVariadic

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
	if visitor:visitAstTypePackVariadic(self) then
		self.variadicType:visit(visitor)
	end
end

return AstTypePackVariadic