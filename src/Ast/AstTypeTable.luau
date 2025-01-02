local AstClassIndex = require("./AstClassIndex")
local AstTableIndexer = require("./AstTableIndexer")
local AstTableProp = require("./AstTableProp")
local AstType = require("./AstType")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstTableIndexer = AstTableIndexer.AstTableIndexer
type AstTableProp = AstTableProp.AstTableProp
type AstType = AstType.AstType
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstTypeTable = AstType & {
	props: {AstTableProp},
	indexer: AstTableIndexer
}

--[=[
	@class AstTypeTable
	@tag class
]=]
local AstTypeTable = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstTypeTable
}
local prototype = setmetatable({}, AstType.metatable)
local metatable = {__index = prototype}

function AstTypeTable.new(location: Location, props: {AstTableProp}, indexer: AstTableIndexer): AstTypeTable
	local self = AstType.interface.new(AstTypeTable.ClassIndex, location) :: AstTypeTable
	self.props = props
	self.indexer = indexer
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstTypeTable, visitor: AstVisitor): ()
	if visitor:visit(self) then
		for _, prop in self.props do
			-- Eli: NEW_SOLVER
			prop.type:visit(visitor)
		end

		if self.indexer then
			self.indexer.indexType:visit(visitor)
			self.indexer.resultType:visit(visitor)
		end
	end
end

return AstTypeTable