local AstClassIndex = require("./AstClassIndex")
local AstNodeTypes = require("./AstNodeTypes")
local AstType = require("./AstType")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstType = AstType.AstType
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstTypeError = AstNodeTypes.AstTypeError

--[=[
	@class AstTypeError
]=]
local AstTypeError = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstTypeError
}
local prototype = setmetatable({}, AstType.metatable)
local metatable = {__index = prototype}

function AstTypeError.new(location: Location, types: {AstType}, isMissing: boolean, messageIndex: number): AstTypeError
	local self = AstType.interface.new(AstTypeError.ClassIndex, location) :: AstTypeError
	self.types = types
	self.isMissing = isMissing
	self.messageIndex = messageIndex
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstTypeError, visitor: AstVisitor): ()
	for _, typeAst in self.types do
		typeAst:visit(visitor)
	end
end

return AstTypeError