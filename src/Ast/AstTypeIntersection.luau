local AstClassIndex = require("./AstClassIndex")
local AstNodeTypes = require("./AstNodeTypes")
local AstType = require("./AstType")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstType = AstType.AstType
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstTypeIntersection = AstNodeTypes.AstTypeIntersection

--[=[
	@class AstTypeIntersection
]=]
local AstTypeIntersection = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstTypeIntersection
}
local prototype = setmetatable({}, AstType.metatable)
local metatable = {__index = prototype}

function AstTypeIntersection.new(location: Location, types: {AstType}): AstTypeIntersection
	local self = AstType.interface.new(AstTypeIntersection.ClassIndex, location) :: AstTypeIntersection
	self.types = types
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstTypeIntersection, visitor: AstVisitor): ()
	if visitor:visitAstTypeIntersection(self) then
		for _, typeAst in self.types do
			typeAst:visit(visitor)
		end
	end
end

return AstTypeIntersection