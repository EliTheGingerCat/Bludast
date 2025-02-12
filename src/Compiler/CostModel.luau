local AstExpr = require("@Ast/AstExpr")
local AstExprCall = require("@Ast/AstExprCall")
local AstExprConstantNumber = require("@Ast/AstExprConstantNumber")
local AstExprUnary = require("@Ast/AstExprUnary")
local AstLocal = require("@Ast/AstLocal")
local AstNode = require("@Ast/AstNode")
local Pair = require("@Polyfill/Pair")

type AstExpr = AstExpr.AstExpr
type AstExprCall = AstExprCall.AstExprCall
type AstLocal = AstLocal.AstLocal
type AstNode = AstNode.AstNode
type Pair<T1, T2> = Pair.Pair<T1, T2>

--[=[
	@class CostModel

	Class from [`/Compiler/src/CostModel.cpp`](https://github.com/luau-lang/luau/blob/7d4033071abebe09971b410d362c00ffb3084afb/Compiler/src/CostModel.cpp#L14-L413) and [`/Compiler/src/CostModel.h`](https://github.com/luau-lang/luau/blob/7d4033071abebe09971b410d362c00ffb3084afb/Compiler/src/CostModel.h#L12-L19).

	Instead of 64 bit numbers, [pairs](Pair) of 32 bit numbers are used.
]=]
local CostModel = {}

--[=[
	@within CostModel
	@private
	@since v0.1.0
	@tag local
]=]
local function getNumber(node: AstExpr): Pair<number, boolean>
	local ne = node:as(AstExprConstantNumber)
	if ne then
		return Pair.new(ne.value, true)
	end

	local ue = node:as(AstExprUnary)
	if ue and ue.op == AstExprUnary.Op.Minus then
		local ne = ue.expr:as(AstExprConstantNumber)
		if ne then
			return Pair.new(-ne.value, true)
		end
	end

	return Pair.new(0, false)
end

--[=[
	@within CostModel
	@since v0.1.0

	Cost model: 8 bytes, where first byte is the baseline cost, and the next 7 bytes are discounts for when variable #i is constant.
]=]
function CostModel.modelCost(root: AstNode, vars: AstLocal, varCount: number, builtins: {[AstExprCall]: number}): number

end

--[=[
	@within CostModel
	@since v0.1.0

	Cost is computed as B - sum(Di * Ci), where B is baseline cost, Di is the discount for each variable and Ci is 1 when variable #i is constant.
]=]
function CostModel.computeCost(model: number, varsConst: boolean, varCount: number): number

end

--[=[
	@within CostModel
	@since v0.1.0

	Get loop trip count or -1 if we can't compute it precisely.
]=]
function CostModel.getTripCount(from: number, to: number, step: number): number

end

return CostModel