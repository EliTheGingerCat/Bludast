local AstClassIndex = require("./AstClassIndex")
local AstDeclaredClassProp = require("./AstDeclaredClassProp")
local AstName = require("./AstName")
local AstStat = require("./AstStat")
local AstTableIndexer = require("./AstTableIndexer")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstDeclaredClassProp = AstDeclaredClassProp.AstDeclaredClassProp
type AstName = AstName.AstName
type AstStat = AstStat.AstStat
type AstTableIndexer = AstTableIndexer.AstTableIndexer
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstStatDeclareClass = AstStat & {
	name: AstName,
	superName: AstName?,

	props: {AstDeclaredClassProp},
	indexer: AstTableIndexer
}

--[=[
	@class AstStatDeclareClass
	@tag class
]=]
local AstStatDeclareClass = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatDeclareClass
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

function AstStatDeclareClass.new(location: Location, name: AstName, superName: AstName?, props: {AstDeclaredClassProp}, indexer: AstTableIndexer): AstStatDeclareClass
	local self = AstStat.interface.new(AstStatDeclareClass.ClassIndex, location) :: AstStatDeclareClass
	self.name = name
	self.superName = superName
	self.props = props
	self.indexer = indexer
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstStatDeclareClass, visitor: AstVisitor): ()
	if visitor:visit(self) then
		for _, prop in self.props do
			prop.ty:visit(visitor)
		end
	end
end

return AstStatDeclareClass