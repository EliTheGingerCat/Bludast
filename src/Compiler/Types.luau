local AstExpr = require("@Ast/AstExpr")
local AstExprFunction = require("@Ast/AstExprFunction")
local AstExprGlobal = require("@Ast/AstExprGlobal")
local AstGenericType = require("@Ast/AstGenericType")
local AstName = require("@Ast/AstName")
local AstStatTypeAlias = require("@Ast/AstStatTypeAlias")
local AstType = require("@Ast/AstType")
local AstTypeFunction = require("@Ast/AstTypeFunction")
local AstTypeIntersection = require("@Ast/AstTypeIntersection")
local AstTypeReference = require("@Ast/AstTypeReference")
local AstTypeTable = require("@Ast/AstTypeTable")
local AstTypeUnion = require("@Ast/AstTypeUnion")
local BytecodeBuilder = require("./BytecodeBuilder")
local FastVariables = require("@Shared/FastVariables")
local Location = require("@Shared/Location")
local LuauBytecodeType = require("@Common/Bytecode/LuauBytecodeType")
local ValueTracking = require("./ValueTracking")

type AstExpr = AstExpr.AstExpr
type AstExprFunction = AstExprFunction.AstExprFunction
type AstExprGlobal = AstExprGlobal.AstExprGlobal
type AstGenericType = AstGenericType.AstGenericType
type AstName = AstName.AstName
type AstStatTypeAlias = AstStatTypeAlias.AstStatTypeAlias
type AstType = AstType.AstType
type AstTypeFunction = AstTypeFunction.AstTypeFunction
type AstTypeIntersection = AstTypeIntersection.AstTypeIntersection
type AstTypeReference = AstTypeReference.AstTypeReference
type AstTypeTable = AstTypeTable.AstTypeTable
type AstTypeUnion = AstTypeUnion.AstTypeUnion
type BytecodeBuilder = BytecodeBuilder.BytecodeBuilder
local getGlobalState = ValueTracking.getGlobalState
local Global = ValueTracking.Global

--[=[
	@class Types
]=]
local Types = {}

local BuiltinTypes = {}

export type BuiltinTypes = {
	-- AstName use here will not match the AstNameTable, but the was we use them here always force a full string compare
	booleanType: AstTypeReference,
	numberType: AstTypeReference,
	stringType: AstTypeReference,
	vectorType: AstTypeReference
}

function BuiltinTypes.new(vectorType: string): BuiltinTypes
	return {
		booleanType = AstTypeReference.new(Location.new(), nil, AstName.new("boolean"), nil, Location.new()),
		numberType = AstTypeReference.new(Location.new(), nil, AstName.new("number"), nil, Location.new()),
		stringType = AstTypeReference.new(Location.new(), nil, AstName.new("number"), nil, Location.new()),
		vectorType = AstTypeReference.new(Location.new(), nil, AstName.new(vectorType), nil, Location.new())
	}
end

local function isGeneric(name: AstName, generics: {AstGenericType}): boolean
	for _, gt in generics do
		if gt.name == name then
			return true
		end
	end

	return false
end

local function getPrimitiveType(name: AstName): number
	if name.value == "nil" then
		return LuauBytecodeType.LBC_TYPE_NIL
	elseif name.value == "boolean" then
		return LuauBytecodeType.LBC_TYPE_BOOLEAN
	elseif name.value == "number" then
		return LuauBytecodeType.LBC_TYPE_NUMBER
	elseif name.value == "string" then
		return LuauBytecodeType.LBC_TYPE_STRING
	elseif name.value == "thread" then
		return LuauBytecodeType.LBC_TYPE_THREAD
	elseif name.value == "buffer" then
		return LuauBytecodeType.LBC_TYPE_BUFFER
	elseif name.value == "any" or name.value == "unknown" then
		return LuauBytecodeType.LBC_TYPE_ANY
	else
		return LuauBytecodeType.LBC_TYPE_INVALID
	end
end

local function getType(
	ty: AstType,
	generics: {AstGenericType},
	typeAliases: {[AstName]: AstStatTypeAlias},
	resolveAliases: boolean,
	vectorType: string?,
	userdataTypes: {[AstName]: number},
	bytecode: BytecodeBuilder
): number
	local ref = ty:as(AstTypeReference)
	local typeTable = ty:as(AstTypeTable)
	local func = ty:as(AstTypeFunction)
	local un = ty:as(AstTypeUnion)
	local inter = ty:as(AstTypeIntersection)

	if ref then
		if ref.prefix then
			return LuauBytecodeType.LBC_TYPE_ANY
		end

		local alias = typeAliases[ref.name]
		if alias then
			-- note: we only resolve aliases to the depth of 1 to avoid dealing with recursive aliases
			if resolveAliases then
				return getType(alias.type, alias.generics, typeAliases, --[[ resolveAliases= ]] false, vectorType, userdataTypes, bytecode)
			else
				return LuauBytecodeType.LBC_TYPE_ANY
			end
		end

		if isGeneric(ref.name, generics) then
			return LuauBytecodeType.LBC_TYPE_ANY
		end

		if vectorType and ref.name.value == vectorType then
			return LuauBytecodeType.LBC_TYPE_VECTOR
		end

		local prim = getPrimitiveType(ref.name)
		if prim ~= LuauBytecodeType.LBC_TYPE_INVALID then
			return prim
		end

		if FastVariables.LuauCompileUserdataInfo then
			local userdataIndex = userdataTypes[ref.name]
			if userdataIndex then
				bytecode:useUserdataType(userdataIndex)
				return LuauBytecodeType.LBC_TYPE_TAGGED_USERDATA_BASE + userdataIndex
			end
		end

		-- not primitive or alias or generic => host-provided, we assume userdata for now
		return LuauBytecodeType.LBC_TYPE_USERDATA
	elseif typeTable then
		return LuauBytecodeType.LBC_TYPE_TABLE
	elseif func then
		return LuauBytecodeType.LBC_TYPE_FUNCTION
	elseif un then
		local optional = false
		local bytecodeType = LuauBytecodeType.LBC_TYPE_INVALID

		for _, ty in un.types do
			local et = getType(ty :: AstType, generics, typeAliases, resolveAliases, vectorType, userdataTypes, bytecode)

			if et == LuauBytecodeType.LBC_TYPE_NIL then
				optional = true
				continue
			end

			if bytecodeType == LuauBytecodeType.LBC_TYPE_INVALID then
				bytecodeType = et
				continue
			end

			if bytecodeType ~= et then
				return LuauBytecodeType.LBC_TYPE_ANY
			end
		end

		if bytecodeType == LuauBytecodeType.LBC_TYPE_INVALID then
			return LuauBytecodeType.LBC_TYPE_ANY
		end

		return bit32.bor(
			bytecodeType,
			(if optional and (bytecodeType ~= LuauBytecodeType.LBC_TYPE_ANY) then LuauBytecodeType.LBC_TYPE_OPTIONAL_BIT else 0)
		)
	elseif inter then
		return LuauBytecodeType.LBC_TYPE_ANY
	end

	return LuauBytecodeType.LBC_TYPE_ANY
end

local function getFunctionType(
	func: AstExprFunction,
	typeAliases: {[AstName]: AstStatTypeAlias},
	vectorType: string?,
	userdataTypes: {[AstName]: number},
	bytecode: BytecodeBuilder
): string
	local self = func.self ~= nil

	local typeInfo = ""

	typeInfo ..= string.char(LuauBytecodeType.LBC_TYPE_FUNCTION)
	typeInfo ..= string.char((if self then 1 else 0) + #func.args)

	if self then
		typeInfo ..= string.char(LuauBytecodeType.LBC_TYPE_TABLE)
	end

	local haveNonAnyParam = false
	for _, arg in func.args do
		local ty =
			if arg.annotation then getType(arg.annotation :: AstType, func.generics, typeAliases, true, vectorType, userdataTypes, bytecode)
			else LuauBytecodeType.LBC_TYPE_ANY

		if ty ~= LuauBytecodeType.LBC_TYPE_ANY then
			haveNonAnyParam = true
		end

		typeInfo ..= string.char(ty)
	end

	-- If all parameters simplify to any, we can just omit type info for this function
	if not haveNonAnyParam then
		return ""
	end

	return typeInfo
end

local function isMatchingGlobal(globals: {[AstName]: number}, node: AstExpr, name: string): boolean
	assert(FastVariables.LuauCompileTempTypeInfo)

	local expr = node:as(AstExprGlobal)
	if expr then
		return getGlobalState(globals, expr.name) == Global.Default and expr.name :: any == name
	end

	return false
end

return Types