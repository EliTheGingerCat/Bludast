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
	--[[
		Eli:
		
		The maximum value of a byte is 127, so if both bytes are at the maximum, we get a sum of 254, which still fits in one byte. Therefore, this adds each matching byte together in place: the first byte of r1 is the first byte of x plus the first byte of y, and so on. If the byte is greater than 127, then it is over the maximum and will be dealt with by being set to 127. A possible result of this addition operation is:

		10100101 01010110 01010101 10101010 10000000 00011010 11111101 00000000
	]]
	-- Eli: r1 = result 1. We need result 1 and 2 since Luau only has a bit32 library, so we can only handle the u64 in chunks of u32. This applies to all the variables in this function as well as parallelMulStat.
	local r1 = x.first + y.first

	--[[
		Eli:
	
		This bitwise and operation has a 1 in the leftmost bit of each byte if the corresponding bit in r1 also has a 1 in that position, and bytes in r1 would only have a 1 in that position if they overflowed beyond the maximum. s1 could look like:

		10000000 00000000 00000000 10000000 10000000 00000000 10000000 00000000
	]]
	-- Eli: s1 = saturation 1
	local s1 = bit32.band(r1, 0x08080808) -- saturation mask

	--[[
		Eli:

		Shifting s1 right by 7 bits means that all the 1s it has move from the leftmost bit of the byte to the rightmost. This means the byte now has a value of 1. For example:

		00000001 00000000 00000000 00000001 00000001 00000000 00000001 00000000

		Subtracting that from s1 means that for all the bytes that had a 1, they will now have a value of 127, since 128 - 1 = 127. For example:

		01111111 00000000 00000000 01111111 01111111 00000000 01111111 00000000

		The exclusive or bitwise operation will ensure that any byte that surpassed the maximum will have the leftmost bit removed since both r1 and s1 would have 1 in that location, which is converted to 0 in exclusive or. Keeping that bit at 0 ensures that the byte can not surpass 127. That byte will now be saturated with 127 due to the bitwise or operation, which will grab the 0b01111111 from the second argument of the bitwise or. For values that did not overflow, the exclusive or will not take anything away from them and they will have no corresponding saturated byte, so they pass through to the final result unchanged.
	]]
	-- Eli: This variable is called t1 just because the others are r and s, and what comes after S? T!
	local t1 = bit32.bor(
		bit32.bxor(r1, s1),
		s1 - bit32.rshift(s1, 7)
	)

	-- Eli: Repeat for the second u32.
	local r2 = x.second + y.second
	local s2 = bit32.band(r2, 0x08080808) -- saturation mask

	local t2 = bit32.bor(
		bit32.bxor(r2, s2),
		s2 - bit32.rshift(s2, 7)
	)

	return Pair.new(t1, t2)
end

--[=[
	@within CostModel
	@private
	@since v0.1.0
	@tag local

	Efficiently multiplies a model by a scalar by individually multiplying each byte and clamping the sum to a maximum of 127.
]=]
local function parallelMulSat(a: u64, b: number): u64
	-- Eli: It is recommended to read the comments on parallelMulAdd first.
	-- Eli: Not sure why b can not be greater than 127. The maximum value of a byte before entering this function is 127. If we let b be 128, then we would get a product of 16256. Adding 32768-128 yields 48896, which takes up 16 bits: 0b1011111100000000. There is no overflow, so it is totally fine for b to be 128. A fellow Rossian, lemonization, suggests that "it helps keep some invariant there that makes the code simpler" (https://discord.com/channels/385151591524597761/906369439262461992/1339383042162163774). Ultimately, it is not a big deal, so you must not lose sleep over it.
	local b_saturated = if b < 127 then b else 127

	-- Eli: 127 is the maximum byte value, and 127 is the maximum b value, which yields a product of 16129, which takes up 14 bits: 0b11111100000001. This means that if we multiply each byte by the scalar, b, there is a very real possibility that the product will take up two bytes of space. Thus, we can not just multiply each half like we did in parallelAddSat. Rather, we need to multiply 4 bytes at a time, keeping track of the lower (1, 3, 5, 7) and higher (2, 4, 6, 8) bytes. And since we can only use 32 bits at a time due to Luau, we now need 4 variables. Sigh.
	local a1_lower  = b_saturated * bit32.band(bit32.rshift(a.first, 0), 0x007f007f)
	local a1_higher = b_saturated * bit32.band(bit32.rshift(a.first, 8), 0x007f007f)

	-- Eli: In order to check for surpassing the maximum value, an easy way is to increase each byte by a number that guarantees that any value over 128 will have a 1 on the leftmost bit. 32768 takes up 16 bits, but we only want to reach 16 bits if the byte is currently at 128+, so adding 32768-128 to each pair of bytes should do the trick, which equals 32640.
	local a1_lower_saturation  = a1_lower  + 0x7f807f80
	local a1_higher_saturation = a1_higher + 0x7f807f80

	local a1_saturation = bit32.bor(
		             bit32.band(a1_higher_saturation, 0x80008000),
		bit32.rshift(bit32.band(a1_lower_saturation,  0x80008000), 8)
	)

	local a1_result = bit32.bor(
		bit32.lshift(bit32.band(a1_higher, 0x007f007f), 8),
		             bit32.band(a1_lower,  0x007f007f)
	)

	local a1_final = bit32.bor(
		a1_result,
		a1_saturation - bit32.rshift(a1_saturation, 7)
	)

	-- Eli: Repeat for the second u32.
	local a2_lower  = b_saturated * bit32.band(bit32.rshift(a.second, 0), 0x007f007f)
	local a2_higher = b_saturated * bit32.band(bit32.rshift(a.second, 8), 0x007f007f)

	local a2_lower_saturation  = a2_lower  + 0x7f807f80
	local a2_higher_saturation = a2_higher + 0x7f807f80

	local a2_saturation = bit32.bor(
		             bit32.band(a2_higher_saturation, 0x80008000),
		bit32.rshift(bit32.band(a2_lower_saturation,  0x80008000), 8)
	)

	local a2_result = bit32.bor(
		bit32.lshift(bit32.band(a2_higher, 0x007f007f), 8),
		             bit32.band(a2_lower,  0x007f007f)
	)

	local a2_final = bit32.bor(
		a2_result,
		a2_saturation - bit32.rshift(a2_saturation, 7)
	)

	return Pair.new(a1_final, a2_final)
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

--[=[
	@within CostModel
	@method __mul
	@param self Cost
	@param other number
	@return Cost
	@since v0.1.0
	@tag metamethod
]=]
function metatable.__mul(self: Cost, other: number): Cost
	local result = Cost.new()
	result.model = parallelMulSat(self.model, other)
	return result
end

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

return Cost