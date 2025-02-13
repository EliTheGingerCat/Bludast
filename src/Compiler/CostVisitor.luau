local AstExpr = require("@Ast/AstExpr")
local AstExprBinary = require("@Ast/AstExprBinary")
local AstExprCall = require("@Ast/AstExprCall")
local AstExprConstantBool = require("@Ast/AstExprConstantBool")
local AstExprConstantNil = require("@Ast/AstExprConstantNil")
local AstExprConstantNumber = require("@Ast/AstExprConstantNumber")
local AstExprConstantString = require("@Ast/AstExprConstantString")
local AstExprFunction = require("@Ast/AstExprFunction")
local AstExprGlobal = require("@Ast/AstExprGlobal")
local AstExprGroup = require("@Ast/AstExprGroup")
local AstExprIfElse = require("@Ast/AstExprIfElse")
local AstExprIndexExpr = require("@Ast/AstExprIndexExpr")
local AstExprIndexName = require("@Ast/AstExprIndexName")
local AstExprInterpString = require("@Ast/AstExprInterpString")
local AstExprLocal = require("@Ast/AstExprLocal")
local AstExprTable = require("@Ast/AstExprTable")
local AstExprTypeAssertion = require("@Ast/AstExprTypeAssertion")
local AstExprUnary = require("@Ast/AstExprUnary")
local AstExprVarargs = require("@Ast/AstExprVarargs")
local AstLocal = require("@Ast/AstLocal")
local AstStatAssign = require("@Ast/AstStatAssign")
local AstStatBlock = require("@Ast/AstStatBlock")
local AstStatBreak = require("@Ast/AstStatBreak")
local AstStatCompoundAssign = require("@Ast/AstStatCompoundAssign")
local AstStatContinue = require("@Ast/AstStatContinue")
local AstStatFor = require("@Ast/AstStatFor")
local AstStatForIn = require("@Ast/AstStatForIn")
local AstStatIf = require("@Ast/AstStatIf")
local AstStatLocal = require("@Ast/AstStatLocal")
local AstStatRepeat = require("@Ast/AstStatRepeat")
local AstStatWhile = require("@Ast/AstStatWhile")
local AstVisitor = require("@Ast/AstVisitor")
local Cost = require("@Compiler/Cost")
local NumberConversions = require("@Polyfill/NumberConversions")
local Pair = require("@Polyfill/Pair")

type AstExpr = AstExpr.AstExpr
type AstExprCall = AstExprCall.AstExprCall
type AstLocal = AstLocal.AstLocal
type AstStatAssign = AstStatAssign.AstStatAssign
type AstStatBlock = AstStatBlock.AstStatBlock
type AstStatBreak = AstStatBreak.AstStatBreak
type AstStatCompoundAssign = AstStatCompoundAssign.AstStatCompoundAssign
type AstStatContinue = AstStatContinue.AstStatContinue
type AstStatFor = AstStatFor.AstStatFor
type AstStatForIn = AstStatForIn.AstStatForIn
type AstStatIf = AstStatIf.AstStatIf
type AstStatLocal = AstStatLocal.AstStatLocal
type AstStatRepeat = AstStatRepeat.AstStatRepeat
type AstStatWhile = AstStatWhile.AstStatWhile
type AstVisitor = AstVisitor.AstVisitor
local btn = NumberConversions.booleanToNumber
type Cost = Cost.Cost
type Pair<T1, T2> = Pair.Pair<T1, T2>
type u64 = NumberConversions.u64
local u64_eq = NumberConversions.u64_equal
local u64_zero = NumberConversions.u64_zero

local prototype = setmetatable({}, AstVisitor.metatable)

--[=[
	@class CostVisitor
	@__index prototype

	Struct from [`/Compiler/src/CostModel.cpp`](https://github.com/luau-lang/luau/blob/7d4033071abebe09971b410d362c00ffb3084afb/Compiler/src/CostModel.cpp#L114-L372).
]=]
local CostVisitor = {
	prototype = prototype
}

local metatable = {
	__index = prototype
}

export type CostVisitor = AstVisitor & typeof(setmetatable({} :: {
	builtins: {[AstExprCall]: number},

	vars: {[AstLocal]: u64?},
	result: Cost
}, metatable))

--[=[
	@within CostVisitor
	@prop builtins {[AstExprCall]: number}
	@since v0.1.0
]=]
--[=[
	@within CostVisitor
	@prop vars {[AstLocal]: u64?}
	@since v0.1.0
]=]
--[=[
	@within CostVisitor
	@prop result Cost
	@since v0.1.0
]=]
local _

--[=[
	@within CostVisitor
	@private
	@since v0.1.0
	@tag local
]=]
local function getNumber(node: AstExpr): {success: boolean, number: number}
	local ne = node:as(AstExprConstantNumber)
	if ne then
		return {
			success = true,
			number = ne.value
		}
	end

	local ue = node:as(AstExprUnary)
	if ue and ue.op == AstExprUnary.Op.Minus then
		ne = ue.expr:as(AstExprConstantNumber)
		if ne then
			return {
				success = true,
				number = -ne.value
			}
		end
	end

	return {
		success = false,
		number = 0
	}
end

--[=[
	@within CostVisitor
	@since v0.1.0
]=]
function CostVisitor.new(builtins: {[AstExprCall]: number}): CostVisitor
	return setmetatable({
		builtins = builtins,
		vars = {},
		result = Cost.new()
	}, metatable) :: any
end

--[=[
	@within CostVisitor
	@since v0.1.0

	This function is technically defined here since `CostVisitor:visitStatFor` depends on it, but all other code should access it through [CostModel.getTripCount].
]=]
function CostVisitor.getTripCount(from: number, to: number, step: number): number
	-- we compute trip count in integers because that way we know that the loop math (repeated addition) is precise
	local fromi = if from >= -32767 and from <= 32767 then from else nil
	local toi = if to >= -32767 and to <= 32767 then to else nil
	local stepi = if step >= -32767 and step <= 32767 then step else nil

	if fromi == nil or toi == nil or stepi == nil or stepi == 0 then
		return -1
	end

	if stepi < 0 and toi > fromi or stepi > 0 and toi < fromi then
		return 0
	end

	return (toi - fromi) / stepi + 1
end

--[=[
	@within CostVisitor
	@since v0.1.0
]=]
function prototype.model(self: CostVisitor, node: AstExpr): Cost
	local exprGroup = node:as(AstExprGroup)
	if exprGroup then
		return self:model(exprGroup.expr)
	end

	if node:is(AstExprConstantNil) or node:is(AstExprConstantBool) or node:is(AstExprConstantNumber) or node:is(AstExprConstantString) then
		return Cost.new(0, Cost.kLiteral)
	end

	local exprLocal = node:as(AstExprLocal)
	if exprLocal then
		local i = self.vars[exprLocal.localAst]

		return Cost.new(0, i)
	end

	local exprGlobal = node:as(AstExprGlobal)
	if exprGlobal then
		return Cost.new(1)
	end

	local exprVarargs = node:as(AstExprVarargs)
	if exprVarargs then
		return Cost.new(3)
	end

	local exprCall = node:as(AstExprCall)
	if exprCall then
		-- builtin cost modeling is different from regular calls because we use FASTCALL to compile these
		-- thus we use a cheaper baseline, don't account for function, and assume constant/local copy is free
		local builtin = self.builtins[exprCall] ~= nil
		local builtinShort = builtin and #exprCall.args <= 2 -- FASTCALL1/2

		local cost = Cost.new(if builtin then 2 else 3)

		if not builtin then
			cost += self:model(exprCall.func)
		end

		for _, arg in exprCall.args do
			local ac = self:model(arg :: AstExpr)
			-- for constants/locals we still need to copy them to the argument list
			cost += if u64_eq(ac.model, u64_zero) and not builtinShort then Cost.new(1) else ac
		end

		return cost
	end

	local exprIndexName = node:as(AstExprIndexName)
	if exprIndexName then
		return self:model(exprIndexName.expr) + Cost.new(1)
	end

	local exprIndexExpr = node:as(AstExprIndexExpr)
	if exprIndexExpr then
		return self:model(exprIndexExpr.expr) + self:model(exprIndexExpr.index) + Cost.new(1)
	end

	local exprFunction = node:as(AstExprFunction)
	if exprFunction then
		return Cost.new(10) -- high baseline cost due to allocation
	end

	local exprTable = node:as(AstExprTable)
	if exprTable then
		local cost = Cost.new(10) -- high baseline cost due to allocation

		for _, item in exprTable.items do
			if item.key then
				cost += self:model(item.key :: AstExpr)
			end

			cost += self:model(item.value :: AstExpr)
			cost += Cost.new(1)
		end

		return cost
	end

	local exprUnary = node:as(AstExprUnary)
	if exprUnary then
		return Cost.fold(self:model(exprUnary.expr), Cost.new(0, Cost.kLiteral))
	end

	local exprBinary = node:as(AstExprBinary)
	if exprBinary then
		return Cost.fold(self:model(exprBinary.left), self:model(exprBinary.right))
	end

	local exprAssertion = node:as(AstExprTypeAssertion)
	if exprAssertion then
		return self:model(exprAssertion.expr)
	end

	local exprIf = node:as(AstExprIfElse)
	if exprIf then
		return self:model(exprIf.condition) + self:model(exprIf.trueExpr) + self:model(exprIf.falseExpr) + Cost.new(2)
	end

	local exprInterp = node:as(AstExprInterpString)
	if exprInterp then
		-- Baseline cost of string.format
		local cost = Cost.new(3)

		for _, innerExpression in exprInterp.expressions do
			cost += self:model(innerExpression :: AstExpr)
		end

		return cost
	end

	error("Unknown expression type")
	return Cost.new()
end

--[=[
	@within CostVisitor
	@since v0.1.0
]=]
function prototype.assign(self: CostVisitor, expr: AstExpr): ()
	-- variable assignments reset variable mask, so that further uses of this variable aren't discounted
	-- this doesn't work perfectly with backwards control flow like loops, but is good enough for a single pass
	local lv = expr:as(AstExprLocal)
	if lv then
		local i = self.vars[lv.localAst]
		if i then
			self.vars[lv.localAst] = u64_zero
		end
	end
end

--[=[
	@within CostVisitor
	@since v0.1.0
]=]
function prototype.loop(self: CostVisitor, body: AstStatBlock, iterCost: Cost, factor: number?)
	factor = factor or 3; assert(factor)

	local before = self.result

	self.result = Cost.new()
	body:visit(self)

	self.result = before + (self.result + iterCost) * factor
end

function prototype.visitAstExpr(self: CostVisitor, node: AstExpr): boolean
	-- note: we short-circuit the visitor traversal through any expression trees by returning false
	-- recursive traversal is happening inside model() which makes it easier to get the resulting value of the subexpression
	self.result += self:model(node)

	return false
end

function prototype.visitAstStatFor(self: CostVisitor, node: AstStatFor): boolean
	self.result += self:model(node.from)
	self.result += self:model(node.to)

	if node.step then
		self.result += self:model(node.step)
	end

	local tripCount = -1
	
	-- Eli: Best code?
	local resultFrom = getNumber(node.from)
	local resultTo = getNumber(node.to)
	local resultStep

	if node.step then
		resultStep = getNumber(node.step)
	end

	if resultFrom.success and resultTo.success and not node.step or resultStep.success then
		tripCount = CostVisitor.getTripCount(
			resultFrom.number,
			resultTo.number,
			if resultStep then resultStep.number else 1
		)
	end

	self:loop(node.body, Cost.new(1), if tripCount < 0 then 3 else tripCount)
	return false
end

function prototype.visitAstStatForIn(self: CostVisitor, node: AstStatForIn): boolean
	for _, value in node.values do
		self.result += self:model(value :: AstExpr)
	end

	self:loop(node.body, Cost.new(1))
	return false
end

function prototype.visitAstStatWhile(self: CostVisitor, node: AstStatWhile): boolean
	local condition = self:model(node.condition)

	self:loop(node.body, condition)
	return false
end

function prototype.visitAstStatRepeat(self: CostVisitor, node: AstStatRepeat): boolean
	local condition = self:model(node.condition)

	self:loop(node.body, condition)
	return false
end

function prototype.visitAstStatIf(self: CostVisitor, node: AstStatIf): boolean
	-- unconditional 'else' may require a jump after the 'if' body
	-- note: this ignores cases when 'then' always terminates and also assumes comparison requires an extra instruction which may be false
	self.result += Cost.new(1 + btn(node.elsebody and not node.elsebody:is(AstStatIf)))

	return true
end

function prototype.visitAstStatLocal(self: CostVisitor, node: AstStatLocal): boolean
	for i = 0, #node.values - 1 do
		local arg = self:model(node.values[i + 1])

		-- propagate constant mask from expression through variables
		if not u64_eq(arg.constant, u64_zero) and i < #node.vars then
			self.vars[node.vars[i + 1]] = arg.constant
		end

		self.result += arg
	end
	
	return false
end

function prototype.visitAstStatAssign(self: CostVisitor, node: AstStatAssign): boolean
	for _, var in node.vars do
		self:assign(var :: AstExpr)
	end

	for i = 1, math.max(#node.vars, #node.values) do
		local ac = Cost.new()
		if i <= #node.vars then
			ac += self:model(node.vars[i])
		end
		if i <= #node.values then
			ac += self:model(node.values[i])
		end
		-- local->local or constant->local assignment is not free
		self.result += if u64_eq(ac.model, u64_zero) then Cost.new(1) else ac
	end

	return false
end

function prototype.visitAstStatCompoundAssign(self: CostVisitor, node: AstStatCompoundAssign): boolean
	self:assign(node.var)

	-- if lhs is not a local, setting it requires an extra table operation
	self.result += Cost.new(if node.var:is(AstExprLocal) then 1 else 2)

	return true
end

function prototype.visitAstStatBreak(self: CostVisitor, node: AstStatBreak): boolean
	self.result += Cost.new(1)

	return false
end

function prototype.visitAstStatContinue(self: CostVisitor, node: AstStatContinue): boolean
	self.result += Cost.new(1)

	return false
end

return CostVisitor