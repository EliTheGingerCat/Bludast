local AstName = require("./AstName")
local AstClassIndex = require("./AstClassIndex")
local AstNodeTypes = require("./AstNodeTypes")
local AstType = require("./AstType")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstName = AstName.AstName
type AstType = AstType.AstType
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstTypePackGeneric = AstNodeTypes.AstTypePackGeneric

--[=[
	@class AstTypePackGeneric
]=]
local AstTypePackGeneric = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstTypePackGeneric
}
local prototype = setmetatable({}, AstType.metatable)
local metatable = {__index = prototype}

function AstTypePackGeneric.new(location: Location, name: AstName): AstTypePackGeneric
	local self = AstType.interface.new(AstTypePackGeneric.ClassIndex, location) :: AstTypePackGeneric
	self.genericName = name
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstTypePackGeneric, visitor: AstVisitor): ()
	visitor:visitAstTypePackGeneric(self)
end

return AstTypePackGeneric