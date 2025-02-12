local AstVisitor = require("@Ast/AstVisitor")
local Pair = require("@Polyfill/Pair")

type Pair<T1, T2> = Pair.Pair<T1, T2>


local prototype = setmetatable({}, AstVisitor.metatable)

--[=[
	@class Cost
]=]
local Cost = {
	prototype = prototype
}

local metatable = {
	__index = prototype
}

--[=[
	@within Cost
	@type u64 Pair<number, number>

	A Luau-safe way to deal with 64 bit integers.
]=]
type u64 = Pair<number, number>

export type Cost = typeof(setmetatable({} :: {
	model: u64,
	constant: u64
}, metatable))

--[=[
	@within Cost
	@prop model u64
	@since v0.1.0

	Cost model: 8 bytes, where first byte is the baseline cost, and the next 7 bytes are discounts for when variable #i is constant.
]=]
--[=[
	@within Cost
	@prop constant u64
	@since v0.1.0

	Constant mask: 8-byte 0xff mask; equal to all ff's for literals, for variables only byte #i (1+) is set to align with model.
]=]
local _

--[=[
	@within CostModel
	@private
	@since v0.1.0
	@tag local

	Efficiently adds two models together by individually adding eaching byte and clamping the sum to a maximum of 127.
]=]
local function parallelAddSat(x: u64, y: u64): u64
	local r1 = x.first + y.first
	local s1 = bit32.band(r1, 0x08080808) -- saturation mask

	local t1 = bit32.bor(
		bit32.bxor(r1, s1),
		s1 - bit32.rshift(s1, 7)
	)

	local r2 = x.second + y.second
	local s2 = bit32.band(r2, 0x08080808) -- saturation mask

	local t2 = bit32.bor(
		bit32.bxor(r2, s2),
		s2 - bit32.rshift(s2, 7)
	)

	return Pair.new(t1, t2)
end

--[=[
	@within Cost
	@prop kLiteral u64
	@since v0.1.0

	The maximum u64 value.
]=]
Cost.kLiteral = Pair.new(0xffffffff, 0xffffffff)

--[=[
	@within CostModel
	@since v0.1.0
]=]
function Cost.new(cost: number?, constant: u64?): Cost
	local model: u64
	if cost == nil then
		model = Pair.new(0, 0)
	elseif cost < 0x7f then
		model = Pair.new(0, cost)
	else
		model = Pair.new(0, 0x7f)
	end

	return setmetatable({
		model = model,
		constant = constant or Pair.new(0, 0)
	}, metatable)
end

--[=[
	@within CostModel
	@method __add
	@param self Cost
	@param other Cost
	@return Cost
	@since v0.1.0
	@tag metamethod
]=]
function metatable.__add(self: Cost, other: Cost): Cost
	local result = Cost.new()
	result.model = parallelAddSat(self.model, other.model)
	return result
end

-- Eli: TODO __mul

function Cost.fold(x: Cost, y: Cost): Cost
	local newmodel = parallelAddSat(x.model, y.model)

	local c1 = bit32.band(
		x.constant.first,
		y.constant.first
	)
	local c2 = bit32.band(
		x.constant.second,
		y.constant.second
	)

	-- the extra cost for folding is 1; the discount is 1 for the variable that is shared by x&y (or whichever one is used in x/y if the other is
	-- literal)
	local isEqual = c1 == Cost.kLiteral.first and c2 == Cost.kLiteral.second
	local extra = if isEqual then Pair.new(0, 0) else Pair.new(
		bit32.bor(1, bit32.band(0x01010101, c1)),
		bit32.band(0x01010101, c2)
	)

	local result = Cost.new()
	result.model = parallelAddSat(newmodel, extra)
	result.constant = Pair.new(c1, c2)

	return result
end

--[[

]]

return Cost