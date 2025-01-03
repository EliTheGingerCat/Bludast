local AstClassIndex = require("./AstClassIndex")
local AstType = require("./AstType")
local AstTypeList = require("./AstTypeList")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstType = AstType.AstType
type AstTypeList = AstTypeList.AstTypeList
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstTypePackExplicit = AstType & {
	typeList: AstTypeList
}

--[=[
	@class AstTypePackExplicit
]=]
local AstTypePackExplicit = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstTypePackExplicit
}
local prototype = setmetatable({}, AstType.metatable)
local metatable = {__index = prototype}

function AstTypePackExplicit.new(location: Location, typeList: AstTypeList): AstTypePackExplicit
	local self = AstType.interface.new(AstTypePackExplicit.ClassIndex, location) :: AstTypePackExplicit
	self.typeList = typeList
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstTypePackExplicit, visitor: AstVisitor): ()
	if visitor:visit(self) then
		for _, typeAst in self.typeList.types do
			typeAst:visit(visitor)
		end

		if self.typeList.tailType then
			self.typeList.tailType:visit(visitor)
		end
	end
end

return AstTypePackExplicit