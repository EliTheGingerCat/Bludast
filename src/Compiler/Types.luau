local AstExpr = require("@Ast/AstExpr")
local AstExprBinary = require("@Ast/AstExprBinary")
local AstExprCall = require("@Ast/AstExprCall")
local AstExprConstantBool = require("@Ast/AstExprConstantBool")
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
local AstExprTypeAssertion = require("@Ast/AstExprTypeAssertion")
local AstExprUnary = require("@Ast/AstExprUnary")
local AstGenericType = require("@Ast/AstGenericType")
local AstLocal = require("@Ast/AstLocal")
local AstName = require("@Ast/AstName")
local AstNode = require("@Ast/AstNode")
local AstStat = require("@Ast/AstStat")
local AstStatBlock = require("@Ast/AstStatBlock")
local AstStatForIn = require("@Ast/AstStatForIn")
local AstStatLocal = require("@Ast/AstStatLocal")
local AstStatRepeat = require("@Ast/AstStatRepeat")
local AstStatTypeAlias = require("@Ast/AstStatTypeAlias")
local AstTableIndexer = require("@Ast/AstTableIndexer")
local AstType = require("@Ast/AstType")
local AstTypeFunction = require("@Ast/AstTypeFunction")
local AstTypeIntersection = require("@Ast/AstTypeIntersection")
local AstTypeReference = require("@Ast/AstTypeReference")
local AstTypeTable = require("@Ast/AstTypeTable")
local AstTypeUnion = require("@Ast/AstTypeUnion")
local AstVisitor = require("@Ast/AstVisitor")
local BytecodeBuilder = require("./BytecodeBuilder")
local FastVariables = require("@Shared/FastVariables")
local Location = require("@Shared/Location")
local LuauBuiltinFunction = require("@Common/Bytecode/LuauBuiltinFunction")
local LuauBytecodeType = require("@Common/Bytecode/LuauBytecodeType")
local Pair = require("@Polyfill/Pair")
local ValueTracking = require("./ValueTracking")
local Vector = require("@Polyfill/Vector")

type AstExpr = AstExpr.AstExpr
type AstExprBinary = AstExprBinary.AstExprBinary
type AstExprCall = AstExprCall.AstExprCall
type AstExprConstantBool = AstExprConstantBool.AstExprConstantBool
type AstExprConstantNumber = AstExprConstantNumber.AstExprConstantNumber
type AstExprConstantString = AstExprConstantString.AstExprConstantString
type AstExprFunction = AstExprFunction.AstExprFunction
type AstExprGlobal = AstExprGlobal.AstExprGlobal
type AstExprGroup = AstExprGroup.AstExprGroup
type AstExprIfElse = AstExprIfElse.AstExprIfElse
type AstExprIndexExpr = AstExprIndexExpr.AstExprIndexExpr
type AstExprIndexName = AstExprIndexName.AstExprIndexName
type AstExprInterpString = AstExprInterpString.AstExprInterpString
type AstExprLocal = AstExprLocal.AstExprLocal
type AstExprTypeAssertion = AstExprTypeAssertion.AstExprTypeAssertion
type AstExprUnary = AstExprUnary.AstExprUnary
type AstGenericType = AstGenericType.AstGenericType
type AstLocal = AstLocal.AstLocal
type AstName = AstName.AstName
type AstNode = AstNode.AstNode
type AstStat = AstStat.AstStat
type AstStatBlock = AstStatBlock.AstStatBlock
type AstStatForIn = AstStatForIn.AstStatForIn
type AstStatLocal = AstStatLocal.AstStatLocal
type AstStatRepeat = AstStatRepeat.AstStatRepeat
type AstStatTypeAlias = AstStatTypeAlias.AstStatTypeAlias
type AstTableIndexer = AstTableIndexer.AstTableIndexer
type AstType = AstType.AstType
type AstTypeFunction = AstTypeFunction.AstTypeFunction
type AstTypeIntersection = AstTypeIntersection.AstTypeIntersection
type AstTypeReference = AstTypeReference.AstTypeReference
type AstTypeTable = AstTypeTable.AstTypeTable
type AstTypeUnion = AstTypeUnion.AstTypeUnion
type AstVisitor = AstVisitor.AstVisitor
type BytecodeBuilder = BytecodeBuilder.BytecodeBuilder
local getGlobalState = ValueTracking.getGlobalState
local Global = ValueTracking.Global
type Pair<T1, T2> = Pair.Pair<T1, T2>
type Vector<T> = Vector.Vector<T>

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

function BuiltinTypes.new(vectorType: string?): BuiltinTypes
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

local function isMatchingGlobal(globals: {[string]: number}, node: AstExpr, name: string): boolean
	assert(FastVariables.LuauCompileTempTypeInfo)

	local expr = node:as(AstExprGlobal)
	if expr then
		return getGlobalState(globals, expr.name) == Global.Default and expr.name :: any == name
	end

	return false
end

local prototype = setmetatable({}, AstVisitor.metatable)
local metatable = {__index = prototype}
local TypeMapVisitor = {}
type TypeMapVisitor = AstVisitor & {
	functionTypes: {[AstExprFunction]: string},
	localTypes: {[AstLocal]: number},
	exprTypes: {[AstExpr]: number},
	vectorType: string?,
	userdataTypes: {[AstName]: number},
	builtinTypes: BuiltinTypes,
	builtinCalls: {[AstExprCall]: number},
	globals: {[string]: number},
	bytecode: BytecodeBuilder,

	typeAliases: {[AstName]: AstStatTypeAlias},
	typeAliasStack: Vector<Pair<AstName, AstStatTypeAlias>>,
	resolvedLocals: {[AstLocal]: AstType},
	resolvedExprs: {[AstExpr]: AstType},

	pushTypeAliases: (self: TypeMapVisitor, block: AstStatBlock) -> number,
	popTypeAliases: (self: TypeMapVisitor, aliasStackTop: number) -> (),
	resolveAliases: (self: TypeMapVisitor, ty: AstType) -> AstType,
	tryGetTableIndexer: (self: TypeMapVisitor, expr: AstExpr) -> AstTableIndexer?,
	recordResolvedType:
		  ((self: TypeMapVisitor, expr: AstExpr, ty: AstType) -> number)
		& ((self: TypeMapVisitor, astLocal: AstLocal, ty: AstType) -> number)
}

function TypeMapVisitor.new(
	functionTypes: {[AstExprFunction]: string},
	localTypes: {[AstLocal]: number},
	exprTypes: {[AstExpr]: number},
	vectorType: string?,
	userdataTypes: {[AstName]: number},
	builtinTypes: BuiltinTypes,
	builtinCalls: {[AstExprCall]: number},
	globals: {[string]: number},
	bytecode: BytecodeBuilder
): TypeMapVisitor
	local self = AstVisitor.new() :: TypeMapVisitor
	self.functionTypes = functionTypes
	self.localTypes = localTypes
	self.exprTypes = exprTypes
	self.vectorType = vectorType
	self.userdataTypes = userdataTypes
	self.builtinTypes = builtinTypes
	self.builtinCalls = builtinCalls
	self.globals = globals
	self.bytecode = bytecode
	self.typeAliases = {}
	self.typeAliasStack = Vector.new()
	self.resolvedLocals = {}
	self.resolvedExprs = {}
	setmetatable(self, metatable)
	return self
end

function prototype.pushTypeAliases(self: TypeMapVisitor, block: AstStatBlock): number
	local aliasStackTop = self.typeAliasStack:size()

	for _, stat in block.body do
		local alias = (stat :: AstStat):as(AstStatTypeAlias)
		if alias then
			local prevAlias = self.typeAliases[alias.name]

			self.typeAliasStack:push_back(Pair.new(alias.name, prevAlias))
			self.typeAliases[alias.name] = alias
		end
	end

	return aliasStackTop
end

function prototype.popTypeAliases(self: TypeMapVisitor, aliasStackTop: number): ()
	while self.typeAliasStack:size() > aliasStackTop do
		local top = self.typeAliasStack:back()

		self.typeAliases[top.first] = top.second
		self.typeAliasStack:pop_back()
	end
end

function prototype.resolveAliases(self: TypeMapVisitor, ty: AstType): AstType
	assert(FastVariables.LuauCompileTempTypeInfo)

	local ref = ty:as(AstTypeReference)
	if ref then
		if ref.prefix then
			return ty
		end

		local alias = self.typeAliases[ref.name]
		if alias then
			return alias.type
		end
	end

	return ty
end

function prototype.tryGetTableIndexer(self: TypeMapVisitor, expr: AstExpr): AstTableIndexer?
	assert(FastVariables.LuauCompileTempTypeInfo)

	local typePtr = self.resolvedExprs[expr]
	if typePtr then
		local tableTy = typePtr:as(AstTypeTable)
		if tableTy then
			return tableTy.indexer
		end
	end

	return nil
end

function prototype.recordResolvedType(self: TypeMapVisitor, a1: any, ty: AstType): number
	assert(FastVariables.LuauCompileTempTypeInfo)

	ty = self:resolveAliases(ty)

	if a1.name == nil then
		local expr: AstExpr = a1

		self.resolvedExprs[expr] = ty

		local bty = getType(ty, {}, self.typeAliases, true, self.vectorType, self.userdataTypes, self.bytecode)
		self.exprTypes[expr] = bty
		return bty
	else
		local astLocal: AstLocal = a1

		self.resolvedLocals[astLocal] = ty

		local bty = getType(ty, {}, self.typeAliases, true, self.vectorType, self.userdataTypes, self.bytecode)

		if bty ~= LuauBytecodeType.LBC_TYPE_ANY then
			self.localTypes[astLocal] = bty
		end

		return bty
	end
end

function prototype.visitAstStatBlock(self: TypeMapVisitor, node: AstStatBlock): boolean
	local aliasStackTop = self:pushTypeAliases(node)

	for _, stat in node.body do
		(stat :: AstStat):visit(self)
	end

	self:popTypeAliases(aliasStackTop)

	return false
end

-- repeat..until scoping rules are such that condition (along with any possible functions declared in it) has aliases from repeat body in scope
function prototype.visitAstStatRepeat(self: TypeMapVisitor, node: AstStatRepeat): boolean
	local aliasStackTop = self:pushTypeAliases(node.body)

	for _, stat in node.body.body do
		(stat :: AstStat):visit(self)
	end

	node.condition:visit(self)

	self:popTypeAliases(aliasStackTop)

	return false
end

-- for...in statement can contain type annotations on locals (we might even infer some for ipairs/pairs/generalized iteration)
function prototype.visitAstStatForIn(self: TypeMapVisitor, node: AstStatForIn): boolean
	if not FastVariables.LuauCompileTempTypeInfo then
		return true
	end

	for _, expr in node.values do
		(expr :: AstExpr):visit(self)
	end

	-- This is similar to how Compiler matches builtin iteration, but we also handle generalized iteration case
	if #node.vars == 2 and #node.values == 1 then
		local call = node.values[1]:as(AstExprCall)
		local valueIndexer = self:tryGetTableIndexer(node.values[1])
		if call and #call.args == 1 then
			local func = call.func
			local arg = call.args[1]

			if isMatchingGlobal(self.globals, func, "ipairs") then
				local indexer = self:tryGetTableIndexer(arg)
				if indexer then
					self:recordResolvedType(node.vars[1], self.builtinTypes.numberType)
					self:recordResolvedType(node.vars[2], indexer.resultType)
				end
			elseif isMatchingGlobal(self.globals, func, "pairs") then
				local indexer = self:tryGetTableIndexer(arg)
				if indexer then
					self:recordResolvedType(node.vars[1], indexer.indexType)
					self:recordResolvedType(node.vars[2], indexer.resultType)
				end
			end
		elseif valueIndexer then
			self:recordResolvedType(node.vars[1], valueIndexer.indexType)
			self:recordResolvedType(node.vars[2], valueIndexer.resultType)
		end
	end

	for _, var in node.vars do
		local annotation = var.annotation
		if annotation then
			self:recordResolvedType(var :: AstLocal, annotation :: AstType)
		end
	end

	node.body:visit(self)

	return false
end

function prototype.visitAstExprFunction(self: TypeMapVisitor, node: AstExprFunction): boolean
	local fnType = getFunctionType(node, self.typeAliases, self.vectorType, self.userdataTypes, self.bytecode)

	if #fnType ~= 0 then
		self.functionTypes[node] = fnType
	end

	return true -- Let generic visitor step into all expressions
end

function prototype.visitAstExprLocal(self: TypeMapVisitor, node: AstExprLocal): boolean
	if FastVariables.LuauCompileTempTypeInfo then
		if FastVariables.LuauCompileTypeInfo then
			local astLocal = node.localAst
			
			local annotation = astLocal.annotation
			local typePtr = self.resolvedLocals[astLocal]
			if annotation then
				local ty = self:recordResolvedType(node, annotation)

				if ty ~= LuauBytecodeType.LBC_TYPE_ANY then
					self.localTypes[astLocal] = ty
				end
			elseif typePtr then
				self.localTypes[astLocal] = self:recordResolvedType(node, typePtr)
			end
		end

		return false
	else
		if FastVariables.LuauCompileTypeInfo then
			local astLocal = node.localAst

			local annotation = astLocal.annotation
			if annotation then
				local ty = getType(annotation, {}, self.typeAliases, true, self.vectorType, self.userdataTypes, self.bytecode)

				if ty ~= LuauBytecodeType.LBC_TYPE_ANY then
					self.localTypes[astLocal] = ty
				end
			end
		end

		return true
	end
end

function prototype.visitAstStatLocal(self: TypeMapVisitor, node: AstStatLocal): boolean
	if not FastVariables.LuauCompileTempTypeInfo then
		return true
	end

	for _, expr in node.values do
		(expr :: AstExpr):visit(self)
	end

	for index, var in node.vars do
		-- Propagate from the value that's being assigned
		-- This simple propagation doesn't handle type packs in tail position
		if var.annotation == nil then
			if index <= #node.values then
				local typePtr = self.resolvedExprs[node.values[index]]
				self.resolvedLocals[var :: AstLocal] = typePtr
			end
		end
	end

	return false
end

function prototype.visitAstExprIndexExpr(self: TypeMapVisitor, node: AstExprIndexExpr): boolean
	if not FastVariables.LuauCompileTempTypeInfo then
		return true
	end

	node.expr:visit(self)
	node.index:visit(self)

	local indexer = self:tryGetTableIndexer(node.expr)
	if indexer then
		self:recordResolvedType(node, indexer.resultType)
	end

	return false
end

function prototype.visitAstExprIndexName(self: TypeMapVisitor, node: AstExprIndexName): boolean
	if not FastVariables.LuauCompileTempTypeInfo then
		return true
	end

	node.expr:visit(self)

	local typePtr = self.resolvedExprs[node.expr]
	if typePtr then
		local tableTy = typePtr:as(AstTypeTable)
		if tableTy then
			for _, prop in tableTy.props do
				if prop.name == node.index then
					self:recordResolvedType(node, prop.type :: AstType)
					return false
				end
			end
		end
	end

	local typeBcPtr = self.exprTypes[node.expr]
	if typeBcPtr then
		if typeBcPtr == LuauBytecodeType.LBC_TYPE_VECTOR then
			if node.index.value == "X" or node.index.value == "Y" or node.index.value == "Z" then
				self:recordResolvedType(node, self.builtinTypes.numberType)
			end
		end
	end

	return false
end

function prototype.visitAstExprUnary(self: TypeMapVisitor, node: AstExprUnary): boolean
	if not FastVariables.LuauCompileTempTypeInfo then
		return true
	end

	node.expr:visit(self)

	if node.op == AstExprUnary.Op.Not then
		self:recordResolvedType(node, self.builtinTypes.booleanType)
	elseif node.op == AstExprUnary.Op.Minus then
		local typePtr = self.resolvedExprs[node.expr]
		local bcTypePtr = self.exprTypes[node.expr]

		if not typePtr or not bcTypePtr then
			return false
		end

		if bcTypePtr == LuauBytecodeType.LBC_TYPE_VECTOR then
			self:recordResolvedType(node, typePtr)
		elseif bcTypePtr == LuauBytecodeType.LBC_TYPE_NUMBER then
			self:recordResolvedType(node, typePtr)
		end
	elseif node.op == AstExprUnary.Op.Len then
		self:recordResolvedType(node, self.builtinTypes.numberType)
	end

	return false
end

function prototype.visitAstExprBinary(self: TypeMapVisitor, node: AstExprBinary): boolean
	if not FastVariables.LuauCompileTempTypeInfo then
		return true
	end

	node.left:visit(self)
	node.right:visit(self)

	-- Comparisons result in a boolean
	if
		node.op == AstExprBinary.Op.CompareNe
		or node.op == AstExprBinary.Op.CompareEq
		or node.op == AstExprBinary.Op.CompareLt
		or node.op == AstExprBinary.Op.CompareLe
		or node.op == AstExprBinary.Op.CompareGt
		or node.op == AstExprBinary.Op.CompareGe
	then
		self:recordResolvedType(node, self.builtinTypes.booleanType)
		return false
	end

	if node.op == AstExprBinary.Op.Concat or node.op == AstExprBinary.Op.And or node.op == AstExprBinary.Op.Or then
		return false
	end

	local leftTypePtr = self.resolvedExprs[node.left]
	local leftBcTypePtr = self.exprTypes[node.left]

	if not leftTypePtr or not leftBcTypePtr then
		return false
	end

	local rightTypePtr = self.resolvedExprs[node.right]
	local rightBcTypePtr = self.exprTypes[node.left]

	if not rightTypePtr or not rightBcTypePtr then
		return false
	end

	if leftBcTypePtr == LuauBytecodeType.LBC_TYPE_VECTOR then
		self:recordResolvedType(node, leftTypePtr)
	elseif rightBcTypePtr == LuauBytecodeType.LBC_TYPE_VECTOR then
		self:recordResolvedType(node, rightTypePtr)
	elseif leftBcTypePtr == LuauBytecodeType.LBC_TYPE_NUMBER and rightBcTypePtr == LuauBytecodeType.LBC_TYPE_NUMBER then
		self:recordResolvedType(node, leftTypePtr)
	end
	
	return false
end

function prototype.visitAstExprGroup(self: TypeMapVisitor, node: AstExprGroup): boolean
	if not FastVariables.LuauCompileTempTypeInfo then
		return true
	end

	node.expr:visit(self)

	local typePtr = self.resolvedExprs[node.expr]
	if typePtr then
		self:recordResolvedType(node, typePtr)
	end

	return false
end

function prototype.visitAstExprTypeAssertion(self: TypeMapVisitor, node: AstExprTypeAssertion): boolean
	if not FastVariables.LuauCompileTempTypeInfo then
		return true
	end

	node.expr:visit(self)

	self:recordResolvedType(node, node.annotation)
	
	return false
end

function prototype.visitAstExprConstantBool(self: TypeMapVisitor, node: AstExprConstantBool): boolean
	if not FastVariables.LuauCompileTempTypeInfo then
		return true
	end

	self:recordResolvedType(node, self.builtinTypes.booleanType)

	return false
end

function prototype.visitAstExprConstantNumber(self: TypeMapVisitor, node: AstExprConstantNumber): boolean
	if not FastVariables.LuauCompileTempTypeInfo then
		return true
	end

	self:recordResolvedType(node, self.builtinTypes.numberType)

	return false
end

function prototype.visitAstExprConstantString(self: TypeMapVisitor, node: AstExprConstantString): boolean
	if not FastVariables.LuauCompileTempTypeInfo then
		return true
	end

	self:recordResolvedType(node, self.builtinTypes.stringType)

	return false
end

function prototype.visitAstExprInterpString(self: TypeMapVisitor, node: AstExprInterpString): boolean
	if not FastVariables.LuauCompileTempTypeInfo then
		return true
	end

	self:recordResolvedType(node, self.builtinTypes.stringType)

	return false
end

function prototype.visitAstExprIfElse(self: TypeMapVisitor, node: AstExprIfElse): boolean
	if not FastVariables.LuauCompileTempTypeInfo then
		return true
	end

	node.condition:visit(self)
	node.trueExpr:visit(self)
	node.falseExpr:visit(self)

	local trueTypePtr = self.resolvedExprs[node.trueExpr]
	local trueBcTypePtr = self.exprTypes[node.trueExpr]
	local falseBcTypePtr = self.exprTypes[node.falseExpr]

	-- Optimistic check that both expressions are of the same kind, as AstType* cannot be compared
	if trueTypePtr and trueBcTypePtr and falseBcTypePtr and trueBcTypePtr == falseBcTypePtr then
		self:recordResolvedType(node, trueTypePtr)
	end

	return false
end

function prototype.visitAstExprCall(self: TypeMapVisitor, node: AstExprCall): boolean
	if not FastVariables.LuauCompileTempTypeInfo then
		return true
	end

	local bfid = self.builtinCalls[node]
	if bfid then
		if
			bfid == LuauBuiltinFunction.LBF_MATH_ABS
			or bfid == LuauBuiltinFunction.LBF_MATH_ACOS
			or bfid == LuauBuiltinFunction.LBF_MATH_ASIN
			or bfid == LuauBuiltinFunction.LBF_MATH_ATAN2
			or bfid == LuauBuiltinFunction.LBF_MATH_ATAN
			or bfid == LuauBuiltinFunction.LBF_MATH_CEIL
			or bfid == LuauBuiltinFunction.LBF_MATH_COSH
			or bfid == LuauBuiltinFunction.LBF_MATH_COS
			or bfid == LuauBuiltinFunction.LBF_MATH_DEG
			or bfid == LuauBuiltinFunction.LBF_MATH_EXP
			or bfid == LuauBuiltinFunction.LBF_MATH_FLOOR
			or bfid == LuauBuiltinFunction.LBF_MATH_FMOD
			or bfid == LuauBuiltinFunction.LBF_MATH_FREXP
			or bfid == LuauBuiltinFunction.LBF_MATH_LDEXP
			or bfid == LuauBuiltinFunction.LBF_MATH_LOG10
			or bfid == LuauBuiltinFunction.LBF_MATH_LOG
			or bfid == LuauBuiltinFunction.LBF_MATH_MAX
			or bfid == LuauBuiltinFunction.LBF_MATH_MIN
			or bfid == LuauBuiltinFunction.LBF_MATH_MODF
			or bfid == LuauBuiltinFunction.LBF_MATH_POW
			or bfid == LuauBuiltinFunction.LBF_MATH_RAD
			or bfid == LuauBuiltinFunction.LBF_MATH_SINH
			or bfid == LuauBuiltinFunction.LBF_MATH_SIN
			or bfid == LuauBuiltinFunction.LBF_MATH_SQRT
			or bfid == LuauBuiltinFunction.LBF_MATH_TANH
			or bfid == LuauBuiltinFunction.LBF_MATH_TAN
			or bfid == LuauBuiltinFunction.LBF_BIT32_ARSHIFT
			or bfid == LuauBuiltinFunction.LBF_BIT32_BAND
			or bfid == LuauBuiltinFunction.LBF_BIT32_BNOT
			or bfid == LuauBuiltinFunction.LBF_BIT32_BOR
			or bfid == LuauBuiltinFunction.LBF_BIT32_BXOR
			or bfid == LuauBuiltinFunction.LBF_BIT32_BTEST
			or bfid == LuauBuiltinFunction.LBF_BIT32_EXTRACT
			or bfid == LuauBuiltinFunction.LBF_BIT32_LROTATE
			or bfid == LuauBuiltinFunction.LBF_BIT32_LSHIFT
			or bfid == LuauBuiltinFunction.LBF_BIT32_REPLACE
			or bfid == LuauBuiltinFunction.LBF_BIT32_RROTATE
			or bfid == LuauBuiltinFunction.LBF_BIT32_RSHIFT
			or bfid == LuauBuiltinFunction.LBF_STRING_BYTE
			or bfid == LuauBuiltinFunction.LBF_STRING_LEN
			or bfid == LuauBuiltinFunction.LBF_MATH_CLAMP
			or bfid == LuauBuiltinFunction.LBF_MATH_SIGN
			or bfid == LuauBuiltinFunction.LBF_MATH_ROUND
			or bfid == LuauBuiltinFunction.LBF_BIT32_COUNTLZ
			or bfid == LuauBuiltinFunction.LBF_BIT32_COUNTRZ
			or bfid == LuauBuiltinFunction.LBF_RAWLEN
			or bfid == LuauBuiltinFunction.LBF_BIT32_EXTRACTK
			or bfid == LuauBuiltinFunction.LBF_TONUMBER
			or bfid == LuauBuiltinFunction.LBF_BIT32_BYTESWAP
			or bfid == LuauBuiltinFunction.LBF_BUFFER_READI8
			or bfid == LuauBuiltinFunction.LBF_BUFFER_READU8
			or bfid == LuauBuiltinFunction.LBF_BUFFER_READI16
			or bfid == LuauBuiltinFunction.LBF_BUFFER_READU16
			or bfid == LuauBuiltinFunction.LBF_BUFFER_READI32
			or bfid == LuauBuiltinFunction.LBF_BUFFER_READU32
			or bfid == LuauBuiltinFunction.LBF_BUFFER_READF32
			or bfid == LuauBuiltinFunction.LBF_BUFFER_READF64
		then
			self:recordResolvedType(node, self.builtinTypes.numberType)

		elseif
			bfid == LuauBuiltinFunction.LBF_TYPE
			or bfid == LuauBuiltinFunction.LBF_STRING_CHAR
			or bfid == LuauBuiltinFunction.LBF_TYPEOF
			or bfid == LuauBuiltinFunction.LBF_STRING_SUB
			or bfid == LuauBuiltinFunction.LBF_TOSTRING
		then
			self:recordResolvedType(node, self.builtinTypes.stringType)

		elseif
			bfid == LuauBuiltinFunction.LBF_RAWEQUAL
		then
			self:recordResolvedType(node, self.builtinTypes.booleanType)

		elseif
			bfid == LuauBuiltinFunction.LBF_VECTOR
		then
			self:recordResolvedType(node, self.builtinTypes.vectorType)
		end
	end

	return true -- Let generic visitor step into all expressions
end

-- AstExpr classes that are not covered:
-- * AstExprConstantNil is not resolved to 'nil' because that doesn't help codegen operations and often used as an initializer before real value
-- * AstExprGlobal is not supported as we don't have info on globals
-- * AstExprVarargs cannot be resolved to a testable type
-- * AstExprTable cannot be reconstructed into a specific AstTypeTable and table annotations don't really help codegen
-- * AstExprCall is very complex (especially if builtins and registered globals are included), will be extended in the future

--[=[
	@within Types
	@since 0.1.0
]=]
function Types.buildTypeMap(
	functionTypes: {[AstExprFunction]: string},
	localTypes: {[AstLocal]: number},
	exprTypes: {[AstExpr]: number},
	root: AstNode,
	vectorType: string?,
	userdataTypes: {[AstName]: number},
	builtinTypes: BuiltinTypes,
	builtinCalls: {[AstExprCall]: number},
	globals: {[string]: number},
	bytecode: BytecodeBuilder
): ()
	local visitor = TypeMapVisitor.new(functionTypes, localTypes, exprTypes, vectorType, userdataTypes, builtinTypes, builtinCalls, globals, bytecode)
	root:visit(visitor)
end

Types.BuiltinTypes = BuiltinTypes

return Types