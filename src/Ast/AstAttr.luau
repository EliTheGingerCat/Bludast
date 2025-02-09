local AstClassIndex = require("./AstClassIndex")
local AstNode = require("./AstNode")
local AstNodeTypes = require("./AstNodeTypes")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstAttr = AstNodeTypes.AstAttr

--[=[
	@class AstAttr
]=]
local interface = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstAttr,
	Type = {
		Checked = 0,
		Native = 1
	}
}
local prototype = setmetatable({}, AstNode.metatable)
local metatable = {__index = prototype}

function interface.new(location: Location?, type_enum: number): AstAttr
	-- Eli: Not sure why location can seemingly be nil.
	local location_same = location :: Location

	local self = AstNode.interface.new(interface.ClassIndex, location_same) :: AstAttr
	self.type = type_enum
	setmetatable(self, metatable)
	return self
end

function prototype.asAttr(self: AstAttr): AstAttr
	return self
end

function prototype.visit(self: AstAttr, visitor: AstVisitor): ()
	visitor:visitAstAttr(self)
end

return interface