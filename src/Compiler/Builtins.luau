local AstExpr = require("@Ast/AstExpr")
local AstExprCall = require("@Ast/AstExprCall")
local AstExprGlobal = require("@Ast/AstExprGlobal")
local AstExprIndexName = require("@Ast/AstExprIndexName")
local AstExprLocal = require("@Ast/AstExprLocal")
local AstLocal = require("@Ast/AstLocal")
local AstName = require("@Ast/AstName")
local AstNode = require("@Ast/AstNode")
local AstExprVarargs = require("@Ast/AstExprVarargs")
local AstVisitor = require("@Ast/AstVisitor")
local CompileOptions = require("./CompileOptions")
local LuauBuiltinFunction = require("@Common/Bytecode/LuauBuiltinFunction")
local ValueTracking = require("./ValueTracking")

type AstExpr = AstExpr.AstExpr
type AstExprCall = AstExprCall.AstExprCall
type AstExprGlobal = AstExprGlobal.AstExprGlobal
type AstExprIndexName = AstExprIndexName.AstExprIndexName
type AstExprLocal = AstExprLocal.AstExprLocal
type AstLocal = AstLocal.AstLocal
type AstName = AstName.AstName
type AstNode = AstNode.AstNode
type AstVisitor = AstVisitor.AstVisitor
type CompileOptions = CompileOptions.CompileOptions
local getGlobalState = ValueTracking.getGlobalState
local Global = ValueTracking.Global
type Variable = ValueTracking.Variable

--[=[
	@class Builtins
	@since 0.1.0
]=]
local Builtins = {}

local prototype = {}
local metatable = {__index = prototype}
local Builtin = {}

export type Builtin = typeof(setmetatable({} :: {
	object: AstName,
	method: AstName
}, metatable))

function Builtin.new(object: AstName?, method: AstName?): Builtin
	return setmetatable({
		object = object or AstName.new(),
		method = method or AstName.new()
	}, metatable)
end

function prototype.empty(self: Builtin): boolean
	return self.object :: any == AstName.new() and self.method :: any == AstName.new()
end

function prototype.isGlobal(self: Builtin, name: string): boolean
	return self.object :: any == AstName.new() and self.method.value == name
end

function prototype.isMethod(self: Builtin, table: string, name: string): boolean
	return self.object.value == table and self.method.value == name
end

function Builtins.getBuiltin(node: AstExpr, globals: {[string]: number}, variables: {[AstLocal]: Variable}): Builtin
	local exprLocal = node:as(AstExprLocal)
	local exprIndexName = node:as(AstExprIndexName)
	local exprGlobal = node:as(AstExprGlobal)

	if exprLocal then
		local v = variables[exprLocal.localAst]

		return
			if v and not v.written and v.init then Builtins.getBuiltin(v.init, globals, variables)
			else Builtin.new()
	elseif exprIndexName then
		local object = exprIndexName.expr:as(AstExprGlobal)
		if object then
			return
				if getGlobalState(globals, object.name) == Global.Default then Builtin.new(object.name, exprIndexName.index)
				else Builtin.new()
		else
			return Builtin.new()
		end
	elseif exprGlobal then
		return
			if getGlobalState(globals, exprGlobal.name) == Global.Default then Builtin.new(AstName.new(), exprGlobal.name)
			else Builtin.new()
	else
		return Builtin.new()
	end
end

function Builtins.getBuiltinFunctionId(builtin: Builtin, options: CompileOptions): number
	if builtin:isGlobal("assert") then
		return LuauBuiltinFunction.LBF_ASSERT
	end

	if builtin:isGlobal("type") then
		return LuauBuiltinFunction.LBF_TYPE
	end

	if builtin:isGlobal("typeof") then
		return LuauBuiltinFunction.LBF_TYPEOF
	end

	if builtin:isGlobal("rawset") then
		return LuauBuiltinFunction.LBF_RAWSET
	end
	if builtin:isGlobal("rawget") then
		return LuauBuiltinFunction.LBF_RAWGET
	end
	if builtin:isGlobal("rawequal") then
		return LuauBuiltinFunction.LBF_RAWEQUAL
	end
	if builtin:isGlobal("rawlen") then
		return LuauBuiltinFunction.LBF_RAWLEN
	end

	if builtin:isGlobal("unpack") then
		return LuauBuiltinFunction.LBF_TABLE_UNPACK
	end

	if builtin:isGlobal("select") then
		return LuauBuiltinFunction.LBF_SELECT_VARARG
	end

	if builtin:isGlobal("getmetatable") then
		return LuauBuiltinFunction.LBF_GETMETATABLE
	end
	if builtin:isGlobal("setmetatable") then
		return LuauBuiltinFunction.LBF_SETMETATABLE
	end

	if builtin:isGlobal("tonumber") then
		return LuauBuiltinFunction.LBF_TONUMBER
	end
	if builtin:isGlobal("tostring") then
		return LuauBuiltinFunction.LBF_TOSTRING
	end

	if builtin.object.value == "math" then
		if builtin.method.value == "abs" then
			return LuauBuiltinFunction.LBF_MATH_ABS
		end
		if builtin.method.value == "acos" then
			return LuauBuiltinFunction.LBF_MATH_ACOS
		end
		if builtin.method.value == "asin" then
			return LuauBuiltinFunction.LBF_MATH_ASIN
		end
		if builtin.method.value == "atan2" then
			return LuauBuiltinFunction.LBF_MATH_ATAN2
		end
		if builtin.method.value == "atan" then
			return LuauBuiltinFunction.LBF_MATH_ATAN
		end
		if builtin.method.value == "ceil" then
			return LuauBuiltinFunction.LBF_MATH_CEIL
		end
		if builtin.method.value == "cosh" then
			return LuauBuiltinFunction.LBF_MATH_COSH
		end
		if builtin.method.value == "cos" then
			return LuauBuiltinFunction.LBF_MATH_COS
		end
		if builtin.method.value == "deg" then
			return LuauBuiltinFunction.LBF_MATH_DEG
		end
		if builtin.method.value == "exp" then
			return LuauBuiltinFunction.LBF_MATH_EXP
		end
		if builtin.method.value == "floor" then
			return LuauBuiltinFunction.LBF_MATH_FLOOR
		end
		if builtin.method.value == "fmod" then
			return LuauBuiltinFunction.LBF_MATH_FMOD
		end
		if builtin.method.value == "frexp" then
			return LuauBuiltinFunction.LBF_MATH_FREXP
		end
		if builtin.method.value == "ldexp" then
			return LuauBuiltinFunction.LBF_MATH_LDEXP
		end
		if builtin.method.value == "log10" then
			return LuauBuiltinFunction.LBF_MATH_LOG10
		end
		if builtin.method.value == "log" then
			return LuauBuiltinFunction.LBF_MATH_LOG
		end
		if builtin.method.value == "max" then
			return LuauBuiltinFunction.LBF_MATH_MAX
		end
		if builtin.method.value == "min" then
			return LuauBuiltinFunction.LBF_MATH_MIN
		end
		if builtin.method.value == "modf" then
			return LuauBuiltinFunction.LBF_MATH_MODF
		end
		if builtin.method.value == "pow" then
			return LuauBuiltinFunction.LBF_MATH_POW
		end
		if builtin.method.value == "rad" then
			return LuauBuiltinFunction.LBF_MATH_RAD
		end
		if builtin.method.value == "sinh" then
			return LuauBuiltinFunction.LBF_MATH_SINH
		end
		if builtin.method.value == "sin" then
			return LuauBuiltinFunction.LBF_MATH_SIN
		end
		if builtin.method.value == "sqrt" then
			return LuauBuiltinFunction.LBF_MATH_SQRT
		end
		if builtin.method.value == "tanh" then
			return LuauBuiltinFunction.LBF_MATH_TANH
		end
		if builtin.method.value == "tan" then
			return LuauBuiltinFunction.LBF_MATH_TAN
		end
		if builtin.method.value == "clamp" then
			return LuauBuiltinFunction.LBF_MATH_CLAMP
		end
		if builtin.method.value == "sign" then
			return LuauBuiltinFunction.LBF_MATH_SIGN
		end
		if builtin.method.value == "round" then
			return LuauBuiltinFunction.LBF_MATH_ROUND
		end
	end

	if builtin.object.value == "bit32" then
		if builtin.method.value == "arshift" then
			return LuauBuiltinFunction.LBF_BIT32_ARSHIFT
		end
		if builtin.method.value == "band" then
			return LuauBuiltinFunction.LBF_BIT32_BAND
		end
		if builtin.method.value == "bnot" then
			return LuauBuiltinFunction.LBF_BIT32_BNOT
		end
		if builtin.method.value == "bor" then
			return LuauBuiltinFunction.LBF_BIT32_BOR
		end
		if builtin.method.value == "bxor" then
			return LuauBuiltinFunction.LBF_BIT32_BXOR
		end
		if builtin.method.value == "btest" then
			return LuauBuiltinFunction.LBF_BIT32_BTEST
		end
		if builtin.method.value == "extract" then
			return LuauBuiltinFunction.LBF_BIT32_EXTRACT
		end
		if builtin.method.value == "lrotate" then
			return LuauBuiltinFunction.LBF_BIT32_LROTATE
		end
		if builtin.method.value == "lshift" then
			return LuauBuiltinFunction.LBF_BIT32_LSHIFT
		end
		if builtin.method.value == "replace" then
			return LuauBuiltinFunction.LBF_BIT32_REPLACE
		end
		if builtin.method.value == "rrotate" then
			return LuauBuiltinFunction.LBF_BIT32_RROTATE
		end
		if builtin.method.value == "rshift" then
			return LuauBuiltinFunction.LBF_BIT32_RSHIFT
		end
		if builtin.method.value == "countlz" then
			return LuauBuiltinFunction.LBF_BIT32_COUNTLZ
		end
		if builtin.method.value == "countrz" then
			return LuauBuiltinFunction.LBF_BIT32_COUNTRZ
		end
		if builtin.method.value == "byteswap" then
			return LuauBuiltinFunction.LBF_BIT32_BYTESWAP
		end
	end

	if builtin.object.value == "string" then
		if builtin.method.value == "byte" then
			return LuauBuiltinFunction.LBF_STRING_BYTE
		end
		if builtin.method.value == "char" then
			return LuauBuiltinFunction.LBF_STRING_CHAR
		end
		if builtin.method.value == "len" then
			return LuauBuiltinFunction.LBF_STRING_LEN
		end
		if builtin.method.value == "sub" then
			return LuauBuiltinFunction.LBF_STRING_SUB
		end
	end

	if builtin.object.value == "table" then
		if builtin.method.value == "insert" then
			return LuauBuiltinFunction.LBF_TABLE_INSERT
		end
		if builtin.method.value == "unpack" then
			return LuauBuiltinFunction.LBF_TABLE_UNPACK
		end
	end

	if builtin.object.value == "buffer" then
		if builtin.method.value == "readi8" then
			return LuauBuiltinFunction.LBF_BUFFER_READI8
		end
		if builtin.method.value == "readu8" then
			return LuauBuiltinFunction.LBF_BUFFER_READU8
		end
		if builtin.method.value == "writei8" or builtin.method.value == "writeu8" then
			return LuauBuiltinFunction.LBF_BUFFER_WRITEU8
		end
		if builtin.method.value == "readi16" then
			return LuauBuiltinFunction.LBF_BUFFER_READI16
		end
		if builtin.method.value == "readu16" then
			return LuauBuiltinFunction.LBF_BUFFER_READU16
		end
		if builtin.method.value == "writei16" or builtin.method.value == "writeu16" then
			return LuauBuiltinFunction.LBF_BUFFER_WRITEU16
		end
		if builtin.method.value == "readi32" then
			return LuauBuiltinFunction.LBF_BUFFER_READI32
		end
		if builtin.method.value == "readu32" then
			return LuauBuiltinFunction.LBF_BUFFER_READU32
		end
		if builtin.method.value == "writei32" or builtin.method.value == "writeu32" then
			return LuauBuiltinFunction.LBF_BUFFER_WRITEU32
		end
		if builtin.method.value == "readf32" then
			return LuauBuiltinFunction.LBF_BUFFER_READF32
		end
		if builtin.method.value == "writef32" then
			return LuauBuiltinFunction.LBF_BUFFER_WRITEF32
		end
		if builtin.method.value == "readf64" then
			return LuauBuiltinFunction.LBF_BUFFER_READF64
		end
		if builtin.method.value == "writef64" then
			return LuauBuiltinFunction.LBF_BUFFER_WRITEF64
		end
	end

	if options.vectorCtor then
		if options.vectorLib then
			if builtin:isMethod(options.vectorLib, options.vectorCtor) then
				return LuauBuiltinFunction.LBF_VECTOR
			end
		else
			if builtin:isGlobal(options.vectorCtor) then
				return LuauBuiltinFunction.LBF_VECTOR
			end
		end
	end

	return -1
end

local prototypeVisitor = setmetatable({}, AstVisitor.metatable)
local metatableVisitor = {__index = prototypeVisitor}
local BuiltinVisitor = {}
type BuiltinVisitor = AstVisitor & {
	result: {[AstExprCall]: number},

	globals: {[string]: number},
	variables: {[AstLocal]: Variable},

	options: CompileOptions
}

function BuiltinVisitor.new(
	result: {[AstExprCall]: number},
	globals: {[string]: number},
	variables: {[AstLocal]: Variable},
	options: CompileOptions
): BuiltinVisitor
	local self = AstVisitor.new() :: BuiltinVisitor
	self.result = result
	self.globals = globals
	self.variables = variables
	self.options = options
	setmetatable(self, metatableVisitor)
	return self
end

function prototypeVisitor.visitAstExprCall(self: BuiltinVisitor, node: AstExprCall): boolean
	local builtin =
		if node.self then Builtin.new()
		else Builtins.getBuiltin(node.func, self.globals, self.variables)
	if builtin:empty() then
		return true
	end

	local bfid = Builtins.getBuiltinFunctionId(builtin, self.options)

	-- getBuiltinFunctionId optimistically assumes all select() calls are builtin but actually the second argument must be a vararg
	if bfid == LuauBuiltinFunction.LBF_SELECT_VARARG and not (#node.args == 2 and node.args[2]:is(AstExprVarargs)) then
		bfid = -1
	end

	if bfid >= 0 then
		self.result[node] = bfid
	end

	return true -- propagate to nested calls
end

function Builtins.analyzeBuiltins(
	result: {[AstExprCall]: number},
	globals: {[string]: number},
	variables: {[AstLocal]: Variable},
	options: CompileOptions,
	root: AstNode
): ()
	local visitor = BuiltinVisitor.new(result, globals, variables, options)
	root:visit(visitor)
end

local BuiltinInfo = {
	Flags = {
		-- none-safe builtins are builtins that have the same behavior for arguments that are nil or none
		-- this allows the compiler to compile calls to builtins more efficiently in certain cases
		-- for example, math.abs(x()) may compile x() as if it returns one value; if it returns no values, abs() will get nil instead of none
		Flag_NoneSafe = bit32.lshift(1, 0)
	}
}

type BuiltinInfo = {
	params: number,
	results: number,
	flags: number
}

function BuiltinInfo.new(param: number, results: number, flags: number?): BuiltinInfo
	return {
		params = param,
		results = results,
		flags = flags or 0
	}
end

function Builtins.getBuiltinInfo(bfid: number): BuiltinInfo
	if bfid == LuauBuiltinFunction.LBF_NONE then
		return BuiltinInfo.new(-1, -1)
	end

	if bfid == LuauBuiltinFunction.LBF_ASSERT then
		return BuiltinInfo.new(-1, -1) -- assert() returns all values when first value is truthy
	end

	if
		bfid == LuauBuiltinFunction.LBF_MATH_ABS
		or bfid == LuauBuiltinFunction.LBF_MATH_ACOS
		or bfid == LuauBuiltinFunction.LBF_MATH_ASIN
	then
		return BuiltinInfo.new(1, 1, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if bfid == LuauBuiltinFunction.LBF_MATH_ATAN2 then
		return BuiltinInfo.new(2, 1, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if
		bfid == LuauBuiltinFunction.LBF_MATH_ATAN
		or bfid == LuauBuiltinFunction.LBF_MATH_CEIL
		or bfid == LuauBuiltinFunction.LBF_MATH_COSH
		or bfid == LuauBuiltinFunction.LBF_MATH_COS
		or bfid == LuauBuiltinFunction.LBF_MATH_DEG
		or bfid == LuauBuiltinFunction.LBF_MATH_EXP
		or bfid == LuauBuiltinFunction.LBF_MATH_FLOOR
	then
		return BuiltinInfo.new(1, 1, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if bfid == LuauBuiltinFunction.LBF_MATH_FMOD then
		return BuiltinInfo.new(2, 1, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if bfid == LuauBuiltinFunction.LBF_MATH_FREXP then
		return BuiltinInfo.new(1, 2, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if bfid == LuauBuiltinFunction.LBF_MATH_LDEXP then
		return BuiltinInfo.new(2, 1, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if bfid == LuauBuiltinFunction.LBF_MATH_LOG10 then
		return BuiltinInfo.new(1, 1, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if bfid == LuauBuiltinFunction.LBF_MATH_LOG then
		return BuiltinInfo.new(-1, 1) -- 1 or 2 parameters
	end

	if
		bfid == LuauBuiltinFunction.LBF_MATH_MAX
		or bfid == LuauBuiltinFunction.LBF_MATH_MIN
	then
		return BuiltinInfo.new(-1, 1) -- variadic
	end

	if bfid == LuauBuiltinFunction.LBF_MATH_MODF then
		return BuiltinInfo.new(1, 2, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if bfid == LuauBuiltinFunction.LBF_MATH_POW then
		return BuiltinInfo.new(2, 1, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if
		bfid == LuauBuiltinFunction.LBF_MATH_RAD
		or bfid == LuauBuiltinFunction.LBF_MATH_SINH
		or bfid == LuauBuiltinFunction.LBF_MATH_SIN
		or bfid == LuauBuiltinFunction.LBF_MATH_SQRT
		or bfid == LuauBuiltinFunction.LBF_MATH_TANH
		or bfid == LuauBuiltinFunction.LBF_MATH_TAN
	then
		return BuiltinInfo.new(1, 1, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if bfid == LuauBuiltinFunction.LBF_BIT32_ARSHIFT then
		return BuiltinInfo.new(2, 1, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if bfid == LuauBuiltinFunction.LBF_BIT32_BAND then
		return BuiltinInfo.new(-1, 1) -- variadic
	end

	if bfid == LuauBuiltinFunction.LBF_BIT32_BNOT then
		return BuiltinInfo.new(1, 1, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if
		bfid == LuauBuiltinFunction.LBF_BIT32_BOR
		or bfid == LuauBuiltinFunction.LBF_BIT32_BXOR
		or bfid == LuauBuiltinFunction.LBF_BIT32_BTEST
	then
		return BuiltinInfo.new(-1, 1) -- variadic
	end

	if bfid == LuauBuiltinFunction.LBF_BIT32_EXTRACT then
		return BuiltinInfo.new(-1, 1) -- 2 or 3 parameters
	end

	if
		bfid == LuauBuiltinFunction.LBF_BIT32_LROTATE
		or bfid == LuauBuiltinFunction.LBF_BIT32_LSHIFT
	then
		return BuiltinInfo.new(2, 1, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if bfid == LuauBuiltinFunction.LBF_BIT32_REPLACE then
		return BuiltinInfo.new(-1, 1) -- 3 or 4 parameters
	end

	if
		bfid == LuauBuiltinFunction.LBF_BIT32_RROTATE
		or bfid == LuauBuiltinFunction.LBF_BIT32_RSHIFT
	then
		return BuiltinInfo.new(2, 1, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if bfid == LuauBuiltinFunction.LBF_TYPE then
		return BuiltinInfo.new(1, 1)
	end

	if bfid == LuauBuiltinFunction.LBF_STRING_BYTE then
		return BuiltinInfo.new(-1, -1) -- 1, 2 or 3 parameters
	end

	if bfid == LuauBuiltinFunction.LBF_STRING_CHAR then
		return BuiltinInfo.new(-1, 1) -- variadic
	end

	if bfid == LuauBuiltinFunction.LBF_STRING_LEN then
		return BuiltinInfo.new(1, 1, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if bfid == LuauBuiltinFunction.LBF_TYPEOF then
		return BuiltinInfo.new(1, 1)
	end

	if bfid == LuauBuiltinFunction.LBF_STRING_SUB then
		return BuiltinInfo.new(-1, 1) -- 2 or 3 parameters
	end

	if bfid == LuauBuiltinFunction.LBF_MATH_CLAMP then
		return BuiltinInfo.new(3, 1, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if
		bfid == LuauBuiltinFunction.LBF_MATH_SIGN
		or bfid == LuauBuiltinFunction.LBF_MATH_ROUND
	then
		return BuiltinInfo.new(1, 1, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if bfid == LuauBuiltinFunction.LBF_RAWSET then
		return BuiltinInfo.new(3, 1)
	end

	if
		bfid == LuauBuiltinFunction.LBF_RAWGET
		or bfid == LuauBuiltinFunction.LBF_RAWEQUAL
	then
		return BuiltinInfo.new(2, 1)
	end

	if bfid == LuauBuiltinFunction.LBF_TABLE_INSERT then
		return BuiltinInfo.new(-1, 0) -- 2 or 3 parameters
	end

	if bfid == LuauBuiltinFunction.LBF_TABLE_UNPACK then
		return BuiltinInfo.new(-1, -1) -- 1, 2 or 3 parameters
	end

	if bfid == LuauBuiltinFunction.LBF_VECTOR then
		return BuiltinInfo.new(-1, 1) -- 3 or 4 parameters in some configurations
	end

	if
		bfid == LuauBuiltinFunction.LBF_BIT32_COUNTLZ
		or bfid == LuauBuiltinFunction.LBF_BIT32_COUNTRZ
	then
		return BuiltinInfo.new(1, 1, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if bfid == LuauBuiltinFunction.LBF_SELECT_VARARG then
		return BuiltinInfo.new(-1, -1) -- variadic
	end

	if bfid == LuauBuiltinFunction.LBF_RAWLEN then
		return BuiltinInfo.new(1, 1, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if bfid == LuauBuiltinFunction.LBF_BIT32_EXTRACTK then
		return BuiltinInfo.new(3, 1, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if bfid == LuauBuiltinFunction.LBF_GETMETATABLE then
		return BuiltinInfo.new(1, 1)
	end

	if bfid == LuauBuiltinFunction.LBF_SETMETATABLE then
		return BuiltinInfo.new(2, 1)
	end

	if bfid == LuauBuiltinFunction.LBF_TONUMBER then
		return BuiltinInfo.new(-1, 1) -- 1 or 2 parameters
	end

	if bfid == LuauBuiltinFunction.LBF_TOSTRING then
		return BuiltinInfo.new(1, 1)
	end

	if bfid == LuauBuiltinFunction.LBF_BIT32_BYTESWAP then
		return BuiltinInfo.new(1, 1, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if
		bfid == LuauBuiltinFunction.LBF_BUFFER_READI8
		or bfid == LuauBuiltinFunction.LBF_BUFFER_READU8
		or bfid == LuauBuiltinFunction.LBF_BUFFER_READI16
		or bfid == LuauBuiltinFunction.LBF_BUFFER_READU16
		or bfid == LuauBuiltinFunction.LBF_BUFFER_READI32
		or bfid == LuauBuiltinFunction.LBF_BUFFER_READU32
		or bfid == LuauBuiltinFunction.LBF_BUFFER_READF32
		or bfid == LuauBuiltinFunction.LBF_BUFFER_READF64
	then
		return BuiltinInfo.new(2, 1, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	if
		bfid == LuauBuiltinFunction.LBF_BUFFER_WRITEU8
		or bfid == LuauBuiltinFunction.LBF_BUFFER_WRITEU16
		or bfid == LuauBuiltinFunction.LBF_BUFFER_WRITEU32
		or bfid == LuauBuiltinFunction.LBF_BUFFER_WRITEF32
		or bfid == LuauBuiltinFunction.LBF_BUFFER_WRITEF64
	then
		return BuiltinInfo.new(3, 0, BuiltinInfo.Flags.Flag_NoneSafe)
	end

	error("Unreachable")
end

Builtins.Builtin = Builtin
Builtins.BuiltinInfo = BuiltinInfo

return Builtins