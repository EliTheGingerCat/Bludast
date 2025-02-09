local AstNode = require("./AstNode")
local AstNodeTypes = require("./AstNodeTypes")

type AstAttr = AstNodeTypes.AstAttr
type AstExpr = AstNodeTypes.AstExpr
type AstExprGroup = AstNodeTypes.AstExprGroup
type AstExprConstantNil = AstNodeTypes.AstExprConstantNil
type AstExprConstantBool = AstNodeTypes.AstExprConstantBool
type AstExprConstantNumber = AstNodeTypes.AstExprConstantNumber
type AstExprConstantString = AstNodeTypes.AstExprConstantString
type AstExprLocal = AstNodeTypes.AstExprLocal
type AstExprGlobal = AstNodeTypes.AstExprGlobal
type AstExprVarargs = AstNodeTypes.AstExprVarargs
type AstExprCall = AstNodeTypes.AstExprCall
type AstExprIndexName = AstNodeTypes.AstExprIndexName
type AstExprIndexExpr = AstNodeTypes.AstExprIndexExpr
type AstExprFunction = AstNodeTypes.AstExprFunction
type AstExprTable = AstNodeTypes.AstExprTable
type AstExprUnary = AstNodeTypes.AstExprUnary
type AstExprBinary = AstNodeTypes.AstExprBinary
type AstExprTypeAssertion = AstNodeTypes.AstExprTypeAssertion
type AstExprIfElse = AstNodeTypes.AstExprIfElse
type AstExprInterpString = AstNodeTypes.AstExprInterpString
type AstExprError  = AstNodeTypes.AstExprError
type AstNode = AstNode.AstNode
type AstStat = AstNodeTypes.AstStat
type AstStatBlock = AstNodeTypes.AstStatBlock
type AstStatIf = AstNodeTypes.AstStatIf
type AstStatWhile = AstNodeTypes.AstStatWhile
type AstStatRepeat = AstNodeTypes.AstStatRepeat
type AstStatBreak = AstNodeTypes.AstStatBreak
type AstStatContinue = AstNodeTypes.AstStatContinue
type AstStatReturn = AstNodeTypes.AstStatReturn
type AstStatExpr = AstNodeTypes.AstStatExpr
type AstStatLocal = AstNodeTypes.AstStatLocal
type AstStatFor = AstNodeTypes.AstStatFor
type AstStatForIn = AstNodeTypes.AstStatForIn
type AstStatAssign = AstNodeTypes.AstStatAssign
type AstStatCompoundAssign = AstNodeTypes.AstStatCompoundAssign
type AstStatFunction = AstNodeTypes.AstStatFunction
type AstStatLocalFunction = AstNodeTypes.AstStatLocalFunction
type AstStatTypeAlias = AstNodeTypes.AstStatTypeAlias
type AstStatDeclareFunction = AstNodeTypes.AstStatDeclareFunction
type AstStatDeclareGlobal = AstNodeTypes.AstStatDeclareGlobal
type AstStatDeclareClass = AstNodeTypes.AstStatDeclareClass
type AstStatError = AstNodeTypes.AstStatError
type AstType = AstNodeTypes.AstType
type AstTypeReference = AstNodeTypes.AstTypeReference
type AstTypeTable = AstNodeTypes.AstTypeTable
type AstTypeFunction = AstNodeTypes.AstTypeFunction
type AstTypeTypeof = AstNodeTypes.AstTypeTypeof
type AstTypeUnion = AstNodeTypes.AstTypeUnion
type AstTypeIntersection = AstNodeTypes.AstTypeIntersection
type AstTypeSingletonBool = AstNodeTypes.AstTypeSingletonBool
type AstTypeSingletonString = AstNodeTypes.AstTypeSingletonString
type AstTypeError = AstNodeTypes.AstTypeError
type AstTypePack = AstNodeTypes.AstTypePack
type AstTypePackExplicit = AstNodeTypes.AstTypePackExplicit
type AstTypePackVariadic = AstNodeTypes.AstTypePackVariadic
type AstTypePackGeneric = AstNodeTypes.AstTypePackGeneric

export type AstVisitor = {
	visit: (
		self: AstVisitor,
		node: AstNode
	) -> boolean,
	visitAstAttr: (
		self: AstVisitor,
		node: AstAttr
	) -> boolean,
	visitAstExpr: (
		self: AstVisitor,
		node: AstExpr
	) -> boolean,
	visitAstExprGroup: (
		self: AstVisitor,
		node: AstExprGroup
	) -> boolean,
	visitAstExprConstantNil: (
		self: AstVisitor,
		node: AstExprConstantNil
	) -> boolean,
	visitAstExprConstantBool: (
		self: AstVisitor,
		node: AstExprConstantBool
	) -> boolean,
	visitAstExprConstantNumber: (
		self: AstVisitor,
		node: AstExprConstantNumber
	) -> boolean,
	visitAstExprConstantString: (
		self: AstVisitor,
		node: AstExprConstantString
	) -> boolean,
	visitAstExprLocal: (
		self: AstVisitor,
		node: AstExprLocal
	) -> boolean,
	visitAstExprGlobal: (
		self: AstVisitor,
		node: AstExprGlobal
	) -> boolean,
	visitAstExprVarargs: (
		self: AstVisitor,
		node: AstExprVarargs
	) -> boolean,
	visitAstExprCall: (
		self: AstVisitor,
		node: AstExprCall
	) -> boolean,
	visitAstExprIndexName: (
		self: AstVisitor,
		node: AstExprIndexName
	) -> boolean,
	visitAstExprIndexExpr: (
		self: AstVisitor,
		node: AstExprIndexExpr
	) -> boolean,
	visitAstExprFunction: (
		self: AstVisitor,
		node: AstExprFunction
	) -> boolean,
	visitAstExprTable: (
		self: AstVisitor,
		node: AstExprTable
	) -> boolean,
	visitAstExprUnary: (
		self: AstVisitor,
		node: AstExprUnary
	) -> boolean,
	visitAstExprBinary: (
		self: AstVisitor,
		node: AstExprBinary
	) -> boolean,
	visitAstExprTypeAssertion: (
		self: AstVisitor,
		node: AstExprTypeAssertion
	) -> boolean,
	visitAstExprIfElse: (
		self: AstVisitor,
		node: AstExprIfElse
	) -> boolean,
	visitAstExprInterpString: (
		self: AstVisitor,
		node: AstExprInterpString
	) -> boolean,
	visitAstExprError: (
		self: AstVisitor,
		node: AstExprError
	) -> boolean,
	visitAstStat: (
		self: AstVisitor,
		node: AstStat
	) -> boolean,
	visitAstStatBlock: (
		self: AstVisitor,
		node: AstStatBlock
	) -> boolean,
	visitAstStatIf: (
		self: AstVisitor,
		node: AstStatIf
	) -> boolean,
	visitAstStatWhile: (
		self: AstVisitor,
		node: AstStatWhile
	) -> boolean,
	visitAstStatRepeat: (
		self: AstVisitor,
		node: AstStatRepeat
	) -> boolean,
	visitAstStatBreak: (
		self: AstVisitor,
		node: AstStatBreak
	) -> boolean,
	visitAstStatContinue: (
		self: AstVisitor,
		node: AstStatContinue
	) -> boolean,
	visitAstStatReturn: (
		self: AstVisitor,
		node: AstStatReturn
	) -> boolean,
	visitAstStatExpr: (
		self: AstVisitor,
		node: AstStatExpr
	) -> boolean,
	visitAstStatLocal: (
		self: AstVisitor,
		node: AstStatLocal
	) -> boolean,
	visitAstStatFor: (
		self: AstVisitor,
		node: AstStatFor
	) -> boolean,
	visitAstStatForIn: (
		self: AstVisitor,
		node: AstStatForIn
	) -> boolean,
	visitAstStatAssign: (
		self: AstVisitor,
		node: AstStatAssign
	) -> boolean,
	visitAstStatCompoundAssign: (
		self: AstVisitor,
		node: AstStatCompoundAssign
	) -> boolean,
	visitAstStatFunction: (
		self: AstVisitor,
		node: AstStatFunction
	) -> boolean,
	visitAstStatLocalFunction: (
		self: AstVisitor,
		node: AstStatLocalFunction
	) -> boolean,
	visitAstStatTypeAlias: (
		self: AstVisitor,
		node: AstStatTypeAlias
	) -> boolean,
	visitAstStatDeclareFunction: (
		self: AstVisitor,
		node: AstStatDeclareFunction
	) -> boolean,
	visitAstStatDeclareGlobal: (
		self: AstVisitor,
		node: AstStatDeclareGlobal
	) -> boolean,
	visitAstStatDeclareClass: (
		self: AstVisitor,
		node: AstStatDeclareClass
	) -> boolean,
	visitAstStatError: (
		self: AstVisitor,
		node: AstStatError
	) -> boolean,
	visitAstType: (
		self: AstVisitor,
		node: AstType
	) -> boolean,
	visitAstTypeReference: (
		self: AstVisitor,
		node: AstTypeReference
	) -> boolean,
	visitAstTypeTable: (
		self: AstVisitor,
		node: AstTypeTable
	) -> boolean,
	visitAstTypeFunction: (
		self: AstVisitor,
		node: AstTypeFunction
	) -> boolean,
	visitAstTypeTypeof: (
		self: AstVisitor,
		node: AstTypeTypeof
	) -> boolean,
	visitAstTypeUnion: (
		self: AstVisitor,
		node: AstTypeUnion
	) -> boolean,
	visitAstTypeIntersection: (
		self: AstVisitor,
		node: AstTypeIntersection
	) -> boolean,
	visitAstTypeSingletonBool: (
		self: AstVisitor,
		node: AstTypeSingletonBool
	) -> boolean,
	visitAstTypeSingletonString: (
		self: AstVisitor,
		node: AstTypeSingletonString
	) -> boolean,
	visitAstTypeError: (
		self: AstVisitor,
		node: AstTypeError
	) -> boolean,
	visitAstTypePack: (
		self: AstVisitor,
		node: AstTypePack
	) -> boolean,
	visitAstTypePackExplicit: (
		self: AstVisitor,
		node: AstTypePackExplicit
	) -> boolean,
	visitAstTypePackVariadic: (
		self: AstVisitor,
		node: AstTypePackVariadic
	) -> boolean,
	visitAstTypePackGeneric: (
		self: AstVisitor,
		node: AstTypePackGeneric
	) -> boolean
}

--[=[
	@class AstVisitor

	Each visit method should return a boolean indicating whether the subnodes should be visited.
]=]

local AstVisitor = {}

local prototype = {}
local metatable = {__index = prototype}
AstVisitor.metatable = metatable

--- @within AstVisitor
function AstVisitor.new(): AstVisitor
	return setmetatable({}, metatable) :: any
end

--- @within AstVisitor
function prototype.visit(self: AstVisitor, node: AstNode): boolean
	return true
end

--- @within AstVisitor
function prototype.visitAstAttr(self: AstVisitor, node: AstAttr): boolean
	return self:visit(node)
end

--- @within AstVisitor
function prototype.visitAstExpr(self: AstVisitor, node: AstExpr): boolean
	return self:visit(node)
end

--- @within AstVisitor
function prototype.visitAstExprGroup(self: AstVisitor, node: AstExprGroup): boolean
	return self:visitAstExpr(node)
end

--- @within AstVisitor
function prototype.visitAstExprConstantNil(self: AstVisitor, node: AstExprConstantNil): boolean
	return self:visitAstExpr(node)
end

--- @within AstVisitor
function prototype.visitAstExprConstantBool(self: AstVisitor, node: AstExprConstantBool): boolean
	return self:visitAstExpr(node)
end

--- @within AstVisitor
function prototype.visitAstExprConstantNumber(self: AstVisitor, node: AstExprConstantNumber): boolean
	return self:visitAstExpr(node)
end

--- @within AstVisitor
function prototype.visitAstExprConstantString(self: AstVisitor, node: AstExprConstantString): boolean
	return self:visitAstExpr(node)
end

--- @within AstVisitor
function prototype.visitAstExprLocal(self: AstVisitor, node: AstExprLocal): boolean
	return self:visitAstExpr(node)
end

--- @within AstVisitor
function prototype.visitAstExprGlobal(self: AstVisitor, node: AstExprGlobal): boolean
	return self:visitAstExpr(node)
end

--- @within AstVisitor
function prototype.visitAstExprVarargs(self: AstVisitor, node: AstExprVarargs): boolean
	return self:visitAstExpr(node)
end

--- @within AstVisitor
function prototype.visitAstExprCall(self: AstVisitor, node: AstExprCall): boolean
	return self:visitAstExpr(node)
end

--- @within AstVisitor
function prototype.visitAstExprIndexName(self: AstVisitor, node: AstExprIndexName): boolean
	return self:visitAstExpr(node)
end

--- @within AstVisitor
function prototype.visitAstExprIndexExpr(self: AstVisitor, node: AstExprIndexExpr): boolean
	return self:visitAstExpr(node)
end

--- @within AstVisitor
function prototype.visitAstExprFunction(self: AstVisitor, node: AstExprFunction): boolean
	return self:visitAstExpr(node)
end

--- @within AstVisitor
function prototype.visitAstExprTable(self: AstVisitor, node: AstExprTable): boolean
	return self:visitAstExpr(node)
end

--- @within AstVisitor
function prototype.visitAstExprUnary(self: AstVisitor, node: AstExprUnary): boolean
	return self:visitAstExpr(node)
end

--- @within AstVisitor
function prototype.visitAstExprBinary(self: AstVisitor, node: AstExprBinary): boolean
	return self:visitAstExpr(node)
end

--- @within AstVisitor
function prototype.visitAstExprTypeAssertion(self: AstVisitor, node: AstExprTypeAssertion): boolean
	return self:visitAstExpr(node)
end

--- @within AstVisitor
function prototype.visitAstExprIfElse(self: AstVisitor, node: AstExprIfElse): boolean
	return self:visitAstExpr(node)
end

--- @within AstVisitor
function prototype.visitAstExprInterpString(self: AstVisitor, node: AstExprInterpString): boolean
	return self:visitAstExpr(node)
end

--- @within AstVisitor
function prototype.visitAstExprError(self: AstVisitor, node: AstExprError): boolean
	return self:visitAstExpr(node)
end

--- @within AstVisitor
function prototype.visitAstStat(self: AstVisitor, node: AstStat): boolean
	return self:visit(node)
end

--- @within AstVisitor
function prototype.visitAstStatBlock(self: AstVisitor, node: AstStatBlock): boolean
	return self:visitAstStat(node)
end

--- @within AstVisitor
function prototype.visitAstStatIf(self: AstVisitor, node: AstStatIf): boolean
	return self:visitAstStat(node)
end

--- @within AstVisitor
function prototype.visitAstStatWhile(self: AstVisitor, node: AstStatWhile): boolean
	return self:visitAstStat(node)
end

--- @within AstVisitor
function prototype.visitAstStatRepeat(self: AstVisitor, node: AstStatRepeat): boolean
	return self:visitAstStat(node)
end

--- @within AstVisitor
function prototype.visitAstStatBreak(self: AstVisitor, node: AstStatBreak): boolean
	return self:visitAstStat(node)
end

--- @within AstVisitor
function prototype.visitAstStatContinue(self: AstVisitor, node: AstStatContinue): boolean
	return self:visitAstStat(node)
end

--- @within AstVisitor
function prototype.visitAstStatReturn(self: AstVisitor, node: AstStatReturn): boolean
	return self:visitAstStat(node)
end

--- @within AstVisitor
function prototype.visitAstStatExpr(self: AstVisitor, node: AstStatExpr): boolean
	return self:visitAstStat(node)
end

--- @within AstVisitor
function prototype.visitAstStatLocal(self: AstVisitor, node: AstStatLocal): boolean
	return self:visitAstStat(node)
end

--- @within AstVisitor
function prototype.visitAstStatFor(self: AstVisitor, node: AstStatFor): boolean
	return self:visitAstStat(node)
end

--- @within AstVisitor
function prototype.visitAstStatForIn(self: AstVisitor, node: AstStatForIn): boolean
	return self:visitAstStat(node)
end

--- @within AstVisitor
function prototype.visitAstStatAssign(self: AstVisitor, node: AstStatAssign): boolean
	return self:visitAstStat(node)
end

--- @within AstVisitor
function prototype.visitAstStatCompoundAssign(self: AstVisitor, node: AstStatCompoundAssign): boolean
	return self:visitAstStat(node)
end

--- @within AstVisitor
function prototype.visitAstStatFunction(self: AstVisitor, node: AstStatFunction): boolean
	return self:visitAstStat(node)
end

--- @within AstVisitor
function prototype.visitAstStatLocalFunction(self: AstVisitor, node: AstStatLocalFunction): boolean
	return self:visitAstStat(node)
end

--- @within AstVisitor
function prototype.visitAstStatTypeAlias(self: AstVisitor, node: AstStatTypeAlias): boolean
	return self:visitAstStat(node)
end

--- @within AstVisitor
function prototype.visitAstStatDeclareFunction(self: AstVisitor, node: AstStatDeclareFunction): boolean
	return self:visitAstStat(node)
end

--- @within AstVisitor
function prototype.visitAstStatDeclareGlobal(self: AstVisitor, node: AstStatDeclareGlobal): boolean
	return self:visitAstStat(node)
end

--- @within AstVisitor
function prototype.visitAstStatDeclareClass(self: AstVisitor, node: AstStatDeclareClass): boolean
	return self:visitAstStat(node)
end

--- @within AstVisitor
function prototype.visitAstStatError(self: AstVisitor, node: AstStatError): boolean
	return self:visitAstStat(node)
end

--- @within AstVisitor
--- By default visiting type annotations is disabled; override this in your visitor if you need to!
function prototype.visitAstType(self: AstVisitor, node: AstType): boolean
	return false
end

--- @within AstVisitor
function prototype.visitAstTypeReference(self: AstVisitor, node: AstTypeReference): boolean
	return self:visitAstType(node)
end

--- @within AstVisitor
function prototype.visitAstTypeTable(self: AstVisitor, node: AstTypeTable): boolean
	return self:visitAstType(node)
end

--- @within AstVisitor
function prototype.visitAstTypeFunction(self: AstVisitor, node: AstTypeFunction): boolean
	return self:visitAstType(node)
end

--- @within AstVisitor
function prototype.visitAstTypeTypeof(self: AstVisitor, node: AstTypeTypeof): boolean
	return self:visitAstType(node)
end

--- @within AstVisitor
function prototype.visitAstTypeUnion(self: AstVisitor, node: AstTypeUnion): boolean
	return self:visitAstType(node)
end

--- @within AstVisitor
function prototype.visitAstTypeIntersection(self: AstVisitor, node: AstTypeIntersection): boolean
	return self:visitAstType(node)
end

--- @within AstVisitor
function prototype.visitAstTypeSingletonBool(self: AstVisitor, node: AstTypeSingletonBool): boolean
	return self:visitAstType(node)
end

--- @within AstVisitor
function prototype.visitAstTypeSingletonString(self: AstVisitor, node: AstTypeSingletonString): boolean
	return self:visitAstType(node)
end

--- @within AstVisitor
function prototype.visitAstTypeError(self: AstVisitor, node: AstTypeError): boolean
	return self:visitAstType(node)
end

--- @within AstVisitor
function prototype.visitAstTypePack(self: AstVisitor, node: AstTypePack): boolean
	return self:visitAstType(node)
end

--- @within AstVisitor
function prototype.visitAstTypePackExplicit(self: AstVisitor, node: AstTypePackExplicit): boolean
	return self:visitAstType(node)
end

--- @within AstVisitor
function prototype.visitAstTypePackVariadic(self: AstVisitor, node: AstTypePackVariadic): boolean
	return self:visitAstType(node)
end

--- @within AstVisitor
function prototype.visitAstTypePackGeneric(self: AstVisitor, node: AstTypePackGeneric): boolean
	return self:visitAstType(node)
end

return AstVisitor