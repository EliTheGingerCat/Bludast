--!nolint LocalShadow

local AstExpr = require("@Ast/AstExpr")
local AstExprCall = require("@Ast/AstExprCall")
local AstExprConstantNumber = require("@Ast/AstExprConstantNumber")
local AstExprGlobal = require("@Ast/AstExprGlobal")
local AstExprIndexExpr = require("@Ast/AstExprIndexExpr")
local AstExprIndexName = require("@Ast/AstExprIndexName")
local AstExprLocal = require("@Ast/AstExprLocal")
local AstExprTable = require("@Ast/AstExprTable")
local AstLocal = require("@Ast/AstLocal")
local AstName = require("@Ast/AstName")
local AstNode = require("@Ast/AstNode")
local AstStatAssign = require("@Ast/AstStatAssign")
local AstStatFor = require("@Ast/AstStatFor")
local AstStatFunction = require("@Ast/AstStatFunction")
local AstStatLocal = require("@Ast/AstStatLocal")
local AstVisitor = require("@Ast/AstVisitor")
local NumberConversions = require("@Polyfill/NumberConversions")
local Pair = require("@Polyfill/Pair")

type AstExpr = AstExpr.AstExpr
type AstExprCall = AstExprCall.AstExprCall
type AstExprConstantNumber = AstExprConstantNumber.AstExprConstantNumber
type AstExprGlobal = AstExprGlobal.AstExprGlobal
type AstExprIndexExpr = AstExprIndexExpr.AstExprIndexExpr
type AstExprIndexName = AstExprIndexName.AstExprIndexName
type AstExprLocal = AstExprLocal.AstExprLocal
type AstExprTable = AstExprTable.AstExprTable
type AstLocal = AstLocal.AstLocal
type AstName = AstName.AstName
type AstNode = AstNode.AstNode
type AstStatLocal = AstStatLocal.AstStatLocal
type AstStatAssign = AstStatAssign.AstStatAssign
type AstStatFor = AstStatFor.AstStatFor
type AstStatFunction = AstStatFunction.AstStatFunction
type AstVisitor = AstVisitor.AstVisitor
type Pair<T1, T2> = Pair.Pair<T1, T2>
local unsigned = NumberConversions.unsigned

--[=[
	@class TableShape
]=]
local TableShape = {}

-- conservative limit for the loop bound that establishes table array size
local kMaxLoopBound = 16

local TableShapeStruct = {}

export type TableShape = {
	arraySize: number,
	hashSize: number
}

function TableShapeStruct.new(): TableShape
	return {
		arraySize = 0,
		hashSize = 0
	}
end

local function getTableHint(expr: AstExpr): AstExprTable?
	-- unadorned table literal
	local exprTable = expr:as(AstExprTable)
	if exprTable then
		return exprTable
	end

	-- setmetatable(table literal, ...)
	local call = expr:as(AstExprCall)
	if call and not call.self and #call.args == 2 then
		local func = call.func:as(AstExprGlobal)
		if func and func.name.value == "setmetatable" then
			local exprTable = call.args[1]:as(AstExprTable)
			if exprTable then
				return exprTable
			end
		end
	end

	return nil
end

local prototype = setmetatable({}, AstVisitor.metatable)
local metatable = {__index = prototype}
local ShapeVisitor = {}
type ShapeVisitor = AstVisitor & {
	shapes: {[AstExprTable]: TableShape},

	tables: {[AstLocal]: AstExprTable},
	fields: {[string]: boolean},

	loops: {[AstLocal]: number}, -- iterator => upper bound for 1..k

	assignField:
		  ((self: ShapeVisitor, expr: AstExpr, index: AstName) -> ())
		& ((self: ShapeVisitor, expr: AstExpr, index: AstExpr) -> ()),
	assign: (self: ShapeVisitor, var: AstExpr) -> ()
}

function ShapeVisitor.new(shapes: {[AstExprTable]: TableShape}): ShapeVisitor
	local self = AstVisitor.new() :: ShapeVisitor
	self.shapes = shapes
	self.tables = {}
	self.fields = {}
	self.loops = {}
	setmetatable(self, metatable)
	return self
end

local function hashField(field: Pair<AstExprTable, AstName>): string
	-- DarkenedRing: This is terrible, and there is 100% a better way. Sorry. TODO fix this
	return tostring(field.first) .. tostring(field.second)
end

function prototype.assignField(self: ShapeVisitor, expr: AstExpr, index: any): ()
	if AstName.is(index) then
		local index: AstName = index

		local lv = expr:as(AstExprLocal)
		if lv then
			local exprTable = self.tables[lv.localAst]
			if exprTable then
				local field = hashField(Pair.new(exprTable, index))

				if not self.fields[field] then
					self.fields[field] = true
					if not self.shapes[exprTable] then
						self.shapes[exprTable] = TableShapeStruct.new()
					end
					self.shapes[exprTable].hashSize += 1
				end
			end
		end
	else
		local index: AstExpr = index

		local lv = expr:as(AstExprLocal)
		if not lv then
			return
		end

		local exprTable = self.tables[lv.localAst]
		if not exprTable then
			return
		end

		local number = index:as(AstExprConstantNumber)
		local iter = index:as(AstExprLocal)

		if number then
			local shape = self.shapes[exprTable]

			if number.value == shape.arraySize + 1 then
				shape.arraySize += 1
			end
		elseif iter then
			local bound = self.loops[iter.localAst]
			if bound then
				local shape = self.shapes[exprTable]

				if shape.arraySize == 0 then
					shape.arraySize = bound
				end
			end
		end
	end
end

function prototype.assign(self: ShapeVisitor, var: AstExpr): ()
	local indexName = var:as(AstExprIndexName)
	local indexExpr = var:as(AstExprIndexExpr)

	if indexName then
		self:assignField(indexName.expr, indexName.index)
	elseif indexExpr then
		self:assignField(indexExpr.expr, indexExpr.index)
	end
end

function prototype.visitAstStatLocal(self: ShapeVisitor, node: AstStatLocal): boolean
	-- track local -> table association so that we can update table size prediction in assignField
	if #node.vars == 1 and #node.values == 1 then
		local exprTable = getTableHint(node.values[1])
		if exprTable and #exprTable.items == 0 then
			self.tables[node.vars[1]] = exprTable
		end
	end

	return true
end

function prototype.visitAstStatAssign(self: ShapeVisitor, node: AstStatAssign): boolean
	for _, var in node.vars do
		self:assign(node.vars[1])
	end

	for _, value in node.values do
		(value :: AstExpr):visit(self)
	end

	return false
end

function prototype.visitAstStatFunction(self: ShapeVisitor, node: AstStatFunction): boolean
	self:assign(node.name)
	node.func:visit(self)

	return false
end

function prototype.visitAstStatFor(self: ShapeVisitor, node: AstStatFor): boolean
	local from = node.from:as(AstExprConstantNumber)
	local to = node.to:as(AstExprConstantNumber)

	if from and to and from.value == 1 and to.value >= 1 and to.value <= kMaxLoopBound and not node.step then
		self.loops[node.var] = unsigned(to.value)
	end

	return true
end

--[=[
	@within TableShape
	@since 0.1.0
]=]
function TableShape.predictTableShapes(shapes: {[AstExprTable]: TableShape}, root: AstNode): ()
	local visitor = ShapeVisitor.new(shapes)
	root:visit(visitor)
end

TableShape.TableShapeStruct = TableShapeStruct

return TableShape