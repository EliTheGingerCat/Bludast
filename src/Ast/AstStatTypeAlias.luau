local AstClassIndex = require("./AstClassIndex")
local AstGenericType = require("./AstGenericType")
local AstGenericTypePack = require("./AstGenericTypePack")
local AstName = require("./AstName")
local AstStat = require("./AstStat")
local AstType = require("./AstType")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstGenericType = AstGenericType.AstGenericType
type AstGenericTypePack = AstGenericTypePack.AstGenericTypePack
type AstName = AstName.AstName
type AstStat = AstStat.AstStat
type AstType = AstType.AstType
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstStatTypeAlias = AstStat & {
	name: AstName,
	nameLocation: Location,
	generics: {AstGenericType},
	genericPacks: {AstGenericTypePack},
	type: AstType,
	exported: boolean
}

--[=[
	@class AstStatTypeAlias
]=]
local AstStatTypeAlias = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatTypeAlias
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

function AstStatTypeAlias.new(location: Location, name: AstName, nameLocation: Location, generics: {AstGenericType}, genericPacks: {AstGenericTypePack}, typeAst: AstType, exported: boolean): AstStatTypeAlias
	local self = AstStat.interface.new(AstStatTypeAlias.ClassIndex, location) :: AstStatTypeAlias
	self.name = name
	self.nameLocation = nameLocation
	self.generics = generics
	self.genericPacks = genericPacks
	self.type = typeAst
	self.exported = exported
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstStatTypeAlias, visitor: AstVisitor): ()
	if visitor:visit(self) then
		for _, el in self.generics do
			if el.defaultValue then
				el.defaultValue:visit(visitor)
			end
		end

		for _, el in self.genericPacks do
			if el.defaultValue then
				el.defaultValue:visit(visitor)
			end
		end

		self.type:visit(visitor)
	end
end

return AstStatTypeAlias