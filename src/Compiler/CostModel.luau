local AstExprCall = require("@Ast/AstExprCall")
local AstLocal = require("@Ast/AstLocal")
local AstNode = require("@Ast/AstNode")
local CostVisitor = require("@Compiler/CostVisitor")
local NumberConversions = require("@Polyfill/NumberConversions")
local Pair = require("@Polyfill/Pair")

type AstExprCall = AstExprCall.AstExprCall
type AstLocal = AstLocal.AstLocal
type AstNode = AstNode.AstNode
local btn = NumberConversions.booleanToNumber
type u64 = NumberConversions.u64

--[=[
	@class CostModel

	Set of functions from [`/Compiler/src/CostModel.cpp`](https://github.com/luau-lang/luau/blob/7d4033071abebe09971b410d362c00ffb3084afb/Compiler/src/CostModel.cpp#L374-L413) and [`/Compiler/src/CostModel.h`](https://github.com/luau-lang/luau/blob/7d4033071abebe09971b410d362c00ffb3084afb/Compiler/src/CostModel.h#L12-L19).
]=]
local CostModel = {}

local function get_u8_from_u64(u: u64, byte: number): number
	if byte < 5 then
		return bit32.band(bit32.rshift(u.first, (byte - 1) * 8), 0xff)
	else
		return bit32.band(bit32.rshift(u.second, (byte - 5) * 8), 0xff)
	end
end

--[=[
	@within CostModel
	@since v0.1.0

	Cost model: 8 bytes, where first byte is the baseline cost, and the next 7 bytes are discounts for when variable #i is constant.
]=]
function CostModel.modelCost(root: AstNode, vars: {AstLocal}, varCount: number, builtins: {[AstExprCall]: number}): u64
	local visitor = CostVisitor.new(builtins)
	for i = 1, math.min(varCount, 7) do
		local value
		if i < 5 then
			value = Pair.new(bit32.lshift(0xff, i * 8), 0)
		else
			value = Pair.new(0, bit32.lshift(0xff, (i - 4) * 8))
		end
		visitor.vars[vars[i]] = value
	end

	root:visit(visitor)

	return visitor.result.model
end

--[=[
	@within CostModel
	@since v0.1.0

	Cost is computed as `B - sum(Di * Ci)`, where `B` is baseline cost, `Di` is the discount for each variable and `Ci` is 1 when variable #i is constant.
]=]
function CostModel.computeCost(model: u64, varsConst: {boolean}?, varCount: number): number
	local cost = bit32.band(model.first, 0x7f)

	-- don't apply discounts to what is likely a saturated sum
	if cost == 0x7f then
		return cost
	end

	for i = 1, math.min(varCount, 7) do
		cost -= bit32.band(get_u8_from_u64(model, i + 1), 0x7f) * btn(assert(varsConst)[i])
	end

	return cost
end

--[=[
	@within CostModel
	@function getTripCount
	@param from number
	@param to number
	@param step number
	@return number
	@since v0.1.0

	Get loop trip count or -1 if we can't compute it precisely.
]=]
CostModel.getTripCount = CostVisitor.getTripCount

return CostModel