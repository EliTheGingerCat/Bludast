local AstName = require("@Ast/AstName")
local Constant = require("./CompilerConstant")
local LuauBuiltinFunction = require("@Common/Bytecode/LuauBuiltinFunction")
local NumberConversions = require("@Polyfill/NumberConversions")

type AstName = AstName.AstName
type Constant = Constant.Constant
local int = NumberConversions.int
local uint32_t = NumberConversions.uint32_t
local unsigned = NumberConversions.unsigned

--[=[
	@class BuiltinFolding
]=]
local BuiltinFolding = {}

local function cvar(): Constant
	return Constant.new()
end

local function cbool(v: boolean): Constant
	local res = Constant.new(Constant.Type.Type_Boolean)
	res.valueBoolean = v
	return res
end

local function cnum(v: number): Constant
	local res = Constant.new(Constant.Type.Type_Number)
	res.valueNumber = v
	return res
end

local function cvector(x: number, y: number, z: number, w: number): Constant
	local res = Constant.new(Constant.Type.Type_Vector)
	res.valueVector = {x, y, z, w}
	return res
end

local function cstring(v: string): Constant
	local res = Constant.new(Constant.Type.Type_String)
	res.stringLength = #v
	res.valueString = v
	return res
end

local function ctype(c: Constant): Constant
	assert(c.type ~= Constant.Type.Type_Unknown)

	if c.type == Constant.Type.Type_Nil then
		return cstring("nil")
	elseif c.type == Constant.Type.Type_Boolean then
		return cstring("boolean")
	elseif c.type == Constant.Type.Type_Number then
		return cstring("number")
	elseif c.type == Constant.Type.Type_Vector then
		return cstring("vector")
	elseif c.type == Constant.Type.Type_String then
		return cstring("string")
	else
		error("Unsupported constant type")
	end
end

local function toBit32(v: number): number
	-- convert through signed 64-bit integer to match runtime behavior and gracefully truncate negative integers
	return uint32_t(v)
end

--[=[
	@within BuiltinFolding
	@since 0.1.0
]=]
function BuiltinFolding.foldBuiltin(bfid: number, args: {Constant}, count: number)
	if bfid == LuauBuiltinFunction.LBF_MATH_ABS then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			return cnum(math.abs(args[1].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_ACOS then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			return cnum(math.acos(args[1].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_ASIN then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			return cnum(math.asin(args[1].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_ATAN2 then
		if count == 2 and args[1].type == Constant.Type.Type_Number and args[2].type == Constant.Type.Type_Number then
			return cnum(math.atan2(args[1].valueNumber, args[2].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_ATAN then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			return cnum(math.atan(args[1].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_CEIL then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			return cnum(math.ceil(args[1].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_COSH then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			return cnum(math.cosh(args[1].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_COS then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			return cnum(math.cos(args[1].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_DEG then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			return cnum(math.deg(args[1].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_EXP then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			return cnum(math.exp(args[1].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_FLOOR then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			return cnum(math.floor(args[1].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_FMOD then
		if count == 2 and args[1].type == Constant.Type.Type_Number and args[2].type == Constant.Type.Type_Number then
			return cnum(math.fmod(args[1].valueNumber, args[2].valueNumber))
		end

		-- Note: FREXP isn't folded since it returns multiple values

	elseif bfid == LuauBuiltinFunction.LBF_MATH_LDEXP then
		if count == 2 and args[1].type == Constant.Type.Type_Number and args[2].type == Constant.Type.Type_Number then
			return cnum(math.ldexp(args[1].valueNumber, args[2].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_LOG10 then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			return cnum(math.log10(args[1].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_LOG then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			return cnum(math.log(args[1].valueNumber))
		elseif count == 2 and args[1].type == Constant.Type.Type_Number and args[2].type == Constant.Type.Type_Number then
			return cnum(math.log(args[1].valueNumber, args[2].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_MAX then
		if count >= 1 and args[1].type == Constant.Type.Type_Number then
			local r = args[1].valueNumber

			for _, arg in args do
				if arg.type ~= Constant.Type.Type_Number then
					return cvar()
				end

				local a = arg.valueNumber

				r = if a > r then a else r
			end

			return cnum(r)
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_MIN then
		if count >= 1 and args[1].type == Constant.Type.Type_Number then
			local r = args[1].valueNumber

			for _, arg in args do
				if arg.type ~= Constant.Type.Type_Number then
					return cvar()
				end

				local a = arg.valueNumber

				r = if a < r then a else r
			end

			return cnum(r)
		end

		-- Note: MODF isn't folded since it returns multiple values

	elseif bfid == LuauBuiltinFunction.LBF_MATH_POW then
		if count == 2 and args[1].type == Constant.Type.Type_Number and args[2].type == Constant.Type.Type_Number then
			return cnum(math.pow(args[1].valueNumber, args[2].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_RAD then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			return cnum(math.rad(args[1].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_SINH then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			return cnum(math.sinh(args[1].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_SIN then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			return cnum(math.sin(args[1].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_SQRT then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			return cnum(math.sqrt(args[1].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_TANH then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			return cnum(math.tanh(args[1].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_TAN then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			return cnum(math.tan(args[1].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_BIT32_ARSHIFT then
		if count == 2 and args[1].type == Constant.Type.Type_Number and args[2].type == Constant.Type.Type_Number then
			local u = toBit32(args[1].valueNumber)
			local s = int(args[2].valueNumber)

			if unsigned(s) < 32 then
				return cnum(bit32.arshift(u, s))
			end
		end
	elseif bfid == LuauBuiltinFunction.LBF_BIT32_BAND then
		if count >= 1 and args[1].type == Constant.Type.Type_Number then
			local r = toBit32(args[1].valueNumber)

			for _, arg in args do
				if arg.type ~= Constant.Type.Type_Number then
					return cvar()
				end

				r = bit32.band(r, toBit32(arg.valueNumber))
			end

			return cnum(r)
		end
	elseif bfid == LuauBuiltinFunction.LBF_BIT32_BNOT then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			return cnum(uint32_t(bit32.bnot(toBit32(args[1].valueNumber))))
		end
	elseif bfid == LuauBuiltinFunction.LBF_BIT32_BOR then
		if count >= 1 and args[1].type == Constant.Type.Type_Number then
			local r = toBit32(args[1].valueNumber)

			for _, arg in args do
				if arg.type ~= Constant.Type.Type_Number then
					return cvar()
				end

				r = bit32.bor(r, toBit32(arg.valueNumber))
			end

			return cnum(r)
		end
	elseif bfid == LuauBuiltinFunction.LBF_BIT32_BXOR then
		if count >= 1 and args[1].type == Constant.Type.Type_Number then
			local r = toBit32(args[1].valueNumber)

			for index, arg in args do
				if index == 1 then
					continue
				end

				if arg.type ~= Constant.Type.Type_Number then
					return cvar()
				end

				r = bit32.bxor(r, toBit32(arg.valueNumber))
			end

			return cnum(r)
		end
	elseif bfid == LuauBuiltinFunction.LBF_BIT32_BTEST then
		if count >= 1 and args[1].type == Constant.Type.Type_Number then
			local r = toBit32(args[1].valueNumber)

			for _, arg in args do
				if arg.type ~= Constant.Type.Type_Number then
					return cvar()
				end

				r = bit32.band(r, toBit32(arg.valueNumber))
			end

			return cbool(r ~= 0)
		end
	elseif bfid == LuauBuiltinFunction.LBF_BIT32_EXTRACT then
		if
			count >= 2
			and args[1].type == Constant.Type.Type_Number
			and args[2].type == Constant.Type.Type_Number
			and (count == 2 or args[3].type == Constant.Type.Type_Number)
		then
			local u = toBit32(args[1].valueNumber)
			local f = int(args[2].valueNumber)
			local w = if count == 2 then 1 else int(args[3].valueNumber)

			if f >= 0 and w > 0 and f + w <= 32 then
				local m = bit32.bnot(bit32.lshift(0xfffffffe, w - 1))

				return cnum(bit32.band(bit32.rshift(u, f), m))
			end
		end
	elseif bfid == LuauBuiltinFunction.LBF_BIT32_LROTATE then
		if count == 2 and args[1].type == Constant.Type.Type_Number and args[2].type == Constant.Type.Type_Number then
			local u = toBit32(args[1].valueNumber)
			local s = int(args[2].valueNumber)

			return cnum(bit32.lrotate(u, s))
		end
	elseif bfid == LuauBuiltinFunction.LBF_BIT32_LSHIFT then
		if count == 2 and args[1].type == Constant.Type.Type_Number and args[2].type == Constant.Type.Type_Number then
			local u = toBit32(args[1].valueNumber)
			local s = int(args[2].valueNumber)

			if unsigned(s) < 32 then
				return cnum(bit32.lshift(u, s))
			end
		end
	elseif bfid == LuauBuiltinFunction.LBF_BIT32_REPLACE then
		if
			count >= 3
			and args[1].type == Constant.Type.Type_Number
			and args[2].type == Constant.Type.Type_Number
			and args[3].type == Constant.Type.Type_Number
			and (count == 3 or args[4].type == Constant.Type.Type_Number)
		then
			local n = toBit32(args[1].valueNumber)
			local v = toBit32(args[2].valueNumber)
			local f = int(args[3].valueNumber)
			local w = if count == 3 then 1 else int(args[4].valueNumber)

			if f >= 0 and w > 0 and f + w <= 32 then
				return cnum(bit32.replace(n, v, f, w))
			end
		end
	elseif bfid == LuauBuiltinFunction.LBF_BIT32_RROTATE then
		if count == 2 and args[1].type == Constant.Type.Type_Number and args[2].type == Constant.Type.Type_Number then
			local u = toBit32(args[1].valueNumber)
			local s = int(args[2].valueNumber)

			return cnum(bit32.rrotate(u, s))
		end
	elseif bfid == LuauBuiltinFunction.LBF_BIT32_RSHIFT then
		if count == 2 and args[1].type == Constant.Type.Type_Number and args[2].type == Constant.Type.Type_Number then
			local u = toBit32(args[1].valueNumber)
			local s = int(args[2].valueNumber)

			if unsigned(s) < 32 then
				return cnum(bit32.rshift(u, s))
			end
		end
	elseif bfid == LuauBuiltinFunction.LBF_TYPE then
		if count == 1 and args[1].type ~= Constant.Type.Type_Unknown then
			return ctype(args[1])
		end
	elseif bfid == LuauBuiltinFunction.LBF_STRING_BYTE then
		if count == 1 and args[1].type == Constant.Type.Type_String then
			if args[1].stringLength > 0 then
				return cnum(string.byte(args[1].valueString))
			end
		elseif count == 2 and args[1].type == Constant.Type.Type_String and args[2].type == Constant.Type.Type_Number then
			local i = int(args[2].valueNumber)

			if i > 0 and unsigned(i) <= args[1].stringLength then
				return cnum(string.byte(args[1].valueString, i))
			end
		end
	elseif bfid == LuauBuiltinFunction.LBF_STRING_LEN then
		if count == 1 and args[1].type == Constant.Type.Type_String then
			return cnum(args[1].stringLength)
		end
	elseif bfid == LuauBuiltinFunction.LBF_TYPEOF then
		if count == 1 and args[1].type ~= Constant.Type.Type_Unknown then
			return ctype(args[1])
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_CLAMP then
		if
			count == 3
			and args[1].type == Constant.Type.Type_Number
			and args[2].type == Constant.Type.Type_Number
			and args[3].type == Constant.Type.Type_Number
		then
			local min = args[2].valueNumber
			local max = args[3].valueNumber
			if min <= max then
				return cnum(math.clamp(args[1].valueNumber, min, max))
			end
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_SIGN then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			local v = args[1].valueNumber
			return cnum(math.sign(v))
		end
	elseif bfid == LuauBuiltinFunction.LBF_MATH_ROUND then
		if count == 1 and args[1].type == Constant.Type.Type_Number then
			return cnum(math.round(args[1].valueNumber))
		end
	elseif bfid == LuauBuiltinFunction.LBF_VECTOR then
		if
			count >= 3
			and args[1].type == Constant.Type.Type_Number
			and args[2].type == Constant.Type.Type_Number
			and args[3].type == Constant.Type.Type_Number
		then
			if count == 3 then
				return cvector(args[1].valueNumber, args[2].valueNumber, args[3].valueNumber, 0)
			elseif count == 4 and args[4].type == Constant.Type.Type_Number then
				return cvector(args[1].valueNumber, args[2].valueNumber, args[3].valueNumber, args[4].valueNumber)
			end
		end
	end

	return cvar()
end

--[=[
	@within BuiltinFolding
	@since 0.1.0
]=]
function BuiltinFolding.foldBuiltinMath(index: AstName): Constant
	if index.value == "pi" then
		return cnum(math.pi)
	end

	if index.value == "huge" then
		return cnum(math.huge)
	end

	return cvar()
end

return BuiltinFolding