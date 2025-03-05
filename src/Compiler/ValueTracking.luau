--!nolint LocalShadow

local AstExpr = require("@Ast/AstExpr")
local AstExprGlobal = require("@Ast/AstExprGlobal")
local AstExprLocal = require("@Ast/AstExprLocal")
local AstLocal = require("@Ast/AstLocal")
local AstName = require("@Ast/AstName")
local AstNameTable = require("@Ast/AstNameTable")
local AstNode = require("@Ast/AstNode")
local AstStatAssign = require("@Ast/AstStatAssign")
local AstStatCompoundAssign = require("@Ast/AstStatCompoundAssign")
local AstStatFunction = require("@Ast/AstStatFunction")
local AstStatLocal = require("@Ast/AstStatLocal")
local AstStatLocalFunction = require("@Ast/AstStatLocalFunction")
local AstVisitor = require("@Ast/AstVisitor")

type AstExpr = AstExpr.AstExpr
type AstLocal = AstLocal.AstLocal
type AstName = AstName.AstName
type AstNameTable = AstNameTable.AstNameTable
type AstNode = AstNode.AstNode
type AstStatAssign = AstStatAssign.AstStatAssign
type AstStatCompoundAssign = AstStatCompoundAssign.AstStatCompoundAssign
type AstStatFunction = AstStatFunction.AstStatFunction
type AstStatLocal = AstStatLocal.AstStatLocal
type AstStatLocalFunction = AstStatLocalFunction.AstStatLocalFunction
type AstVisitor = AstVisitor.AstVisitor

--[=[
	@class ValueTracking
	@since 0.1.0
]=]
local ValueTracking = {}

ValueTracking.Global = {
	Default = 0,
	Mutable = 1, -- builtin that has contents unknown at compile time, blocks GETIMPORT for chains
	Written = 2, -- written in the code which means we can't reason about the value
}

ValueTracking.Variable = {}

export type Variable = {
	init: AstExpr?,   -- initial value of the variable; filled by trackValues
	written: boolean, -- is the variable ever assigned to? filled by trackValues
	constant: boolean -- is the variable's value a compile-time constant? filled by constantFold
}

function ValueTracking.Variable.new(): Variable
	return {
		written = false,
		constant = false
	}
end

function ValueTracking.getGlobalState(globals: {[string]: number}, name: AstName): number
	local it = globals[name.value or ""]

	return it or ValueTracking.Global.Default
end

local prototype = setmetatable({}, AstVisitor.metatable)
local metatable = {__index = prototype}
local ValueVisitor = {}
type ValueVisitor = AstVisitor & {
	globals: {[string]: number},
	variables: {[AstLocal]: Variable},

	assign: (self: ValueVisitor, var: AstExpr) -> ()
}

function ValueVisitor.new(globals: {[string]: number}, variables: {[AstLocal]: Variable}): ValueVisitor
	local self = AstVisitor.new() :: ValueVisitor
	self.globals = globals
	self.variables = variables
	setmetatable(self, metatable)
	return self
end

function prototype.assign(self: ValueVisitor, var: AstExpr): ()
	local lv = var:as(AstExprLocal)
	local gv = var:as(AstExprGlobal)
	
	if lv then
		self.variables[lv.localAst].written = true
	elseif gv then
		self.globals[gv.name.value or ""] = ValueTracking.Global.Written
	else
		-- we need to be able to track assignments in all expressions, including crazy ones like t[function() t = nil end] = 5
		var:visit(self)
	end
end

function prototype.visitAstStatLocal(self: ValueVisitor, node: AstStatLocal): boolean
	for i = 1, math.min(#node.vars, #node.values) do
		if not self.variables[node.vars[i]] then
			self.variables[node.vars[i]] = ValueTracking.Variable.new()
		end
		self.variables[node.vars[i]].init = node.values[i]
	end

	for i = #node.values + 1, #node.vars do
		if not self.variables[node.vars[i]] then
			self.variables[node.vars[i]] = ValueTracking.Variable.new()
		end
		self.variables[node.vars[i]].init = nil
	end

	return true
end

function prototype.visitAstStatAssign(self: ValueVisitor, node: AstStatAssign): boolean
	for _, var in node.vars do
		self:assign(var :: AstExpr)
	end

	for _, value in node.values do
		(value :: AstExpr):visit(self)
	end

	return false
end

function prototype.visitAstStatCompoundAssign(self: ValueVisitor, node: AstStatCompoundAssign): boolean
	self:assign(node.var)
	node.value:visit(self)

	return false
end

function prototype.visitAstStatLocalFunction(self: ValueVisitor, node: AstStatLocalFunction): boolean
	if not self.variables[node.name] then
		self.variables[node.name] = ValueTracking.Variable.new()
	end
	self.variables[node.name].init = node.func

	return true
end

function prototype.visitAstStatFunction(self: ValueVisitor, node: AstStatFunction): boolean
	self:assign(node.name)
	node.func:visit(self)

	return false
end

--[=[
	@within ValueTracking
	@since 0.1.0
]=]
function ValueTracking.assignMutable(globals: {[string]: number}, names: AstNameTable, mutableGlobals: {string}?): ()
	local name = names:get("_G")
	if name and name.value then
		globals[name.value or ""] = ValueTracking.Global.Mutable
	end

	if mutableGlobals then
		for _, global in mutableGlobals do
			local name = names:get(global)
			if name and name.value then
				globals[name.value or ""] = ValueTracking.Global.Mutable
			end
		end
	end
end

--[=[
	@within ValueTracking
	@since 0.1.0
]=]
function ValueTracking.trackValues(globals: {[string]: number}, variables: {[AstLocal]: Variable}, root: AstNode): ()
	local visitor = ValueVisitor.new(globals, variables)
	root:visit(visitor)
end

return ValueTracking