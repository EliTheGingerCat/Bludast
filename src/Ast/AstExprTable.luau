local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstNodeTypes = require("./AstNodeTypes")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstExpr = AstExpr.AstExpr
type AstVisitor = AstVisitor.AstVisitor
type Item = AstNodeTypes.TableItem
type Location = Location.Location

export type AstExprTable = AstNodeTypes.AstExprTable

--[=[
	@class AstExprTable_Item
]=]
local Item = {
	--[=[
		@class AstExprTable_Item::Kind
	]=]
	Kind = {
		--[=[
			@within AstExprTable_Item::Kind
			@prop List 0
			@readonly
			@since v0.1.0

			`foo`, in which case key is a nullptr
		]=]
		List = 0,

		--[=[
			@within AstExprTable_Item::Kind
			@prop Record 1
			@readonly
			@since v0.1.0

			`foo=bar`, in which case key is a AstExprConstantString
		]=]
		Record = 1,

		--[=[
			@within AstExprTable_Item::Kind
			@prop General 2
			@readonly
			@since v0.1.0

			`[foo]=bar`
		]=]
		General = 2
	}
}

--[=[
	@within AstExprTable_Item
	@function new
	@param kind number
	@param key AstExpr?
	@param value AstExpr
	@return AstExprTable_Item
	@since v0.1.0
]=]
function Item.new(kind: number, key: AstExpr?, value: AstExpr): Item
	return {
		kind = kind,
		key = key,
		value = value
	}
end

--[=[
	@class AstExprTable
]=]
local AstExprTable = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstExprTable,
	
	Item = Item
}
local prototype = setmetatable({}, AstExpr.metatable)
local metatable = {__index = prototype}

function AstExprTable.new(location: Location, items: {Item}): AstExprTable
	local self = AstExpr.interface.new(AstExprTable.ClassIndex, location) :: AstExprTable
	self.items = items
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstExprTable, visitor: AstVisitor): ()
	if visitor:visitAstExprTable(self) then
		for _, item in self.items do
			if item.key then
				item.key:visit(visitor)
			end
			
			item.value:visit(visitor)
		end
	end
end

return AstExprTable