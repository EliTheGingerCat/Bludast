local AstClassIndex = require("./AstClassIndex")
local AstNodeTypes = require("./AstNodeTypes")
local AstType = require("./AstType")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstType = AstType.AstType
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstTypeUnion = AstNodeTypes.AstTypeUnion

--[=[
	@class AstTypeUnion
]=]
local AstTypeUnion = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstTypeUnion
}
local prototype = setmetatable({}, AstType.metatable)
local metatable = {__index = prototype}

function AstTypeUnion.new(location: Location, types: {AstType}): AstTypeUnion
	local self = AstType.interface.new(AstTypeUnion.ClassIndex, location) :: AstTypeUnion
	self.types = types
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstTypeUnion, visitor: AstVisitor): ()
	if visitor:visitAstTypeUnion(self) then
		for _, typeAst in self.types do
			typeAst:visit(visitor)
		end
	end
end

return AstTypeUnion