local AstArgumentName = require("./AstArgumentName")
local AstName = require("./AstName")
local Location = require("@Shared/Location")
local Position = require("@Shared/Position")

type AstArgumentName = AstArgumentName.AstArgumentName
type AstName = AstName.AstName
type Location = Location.Location
type Position = Position.Position

type AstVisitor = {
	visit: (
		self: AstVisitor,
		node: AstNode
	) -> boolean
}

type class<T> = {
	ClassIndex: number,
	ClassType: T
}

--[=[
	@within AstNode
	@method visit
	@param visitor AstVisitor
	@since v0.1.0
]=]

--[=[
	@within AstNode
	@method asStat
	@return AstStat
	@since v0.1.0

	Returns self. This is essentially a type assertion.
]=]

--[=[
	@within AstNode
	@method asType
	@return AstType
	@since v0.1.0

	Same as [asStat](AstNode#asStat).
]=]

--[=[
	@within AstNode
	@method asAttr
	@return AstAttr
	@since v0.1.0

	Same as [asStat](AstNode#asStat).
]=]

--[=[
	@within AstNode
	@prop classIndex number
	@readonly
	@since v0.1.0

	Used in [is](AstNode#is) and [as](AstNode#as).
]=]

--[=[
	@within AstNode
	@prop location Location
	@readonly
	@since v0.1.0
]=]
local _

export type AstNode = {
	visit: (self: AstNode, visitor: any) -> (),
	asStat: (self: AstNode) -> AstStat,
	asType: (self: AstNode) -> AstType,
	asAttr: (self: AstNode) -> AstAttr,
	is: <T>(self: AstNode, class: class<T>) -> boolean,
	as: <T>(self: AstNode, class: class<T>) -> T?,

	classIndex: number,
	location: Location
}

export type AstStat = AstNode & {
	hasSemicolon: boolean
}

export type AstType = AstNode

export type AstAttr = AstNode & {
	type: number
}

export type AstDeclaredClassProp = {
	name: AstName,
	ty: AstType,
	isMethod: boolean
}

export type AstExpr = AstNode & {
	asExpr: (self: AstExpr) -> AstExpr
}

export type AstExprBinary = AstExpr & {
	op: number,
	left: AstExpr,
	right: AstExpr
}

export type AstExprCall = AstExpr & {
	func: AstExpr,
	args: {AstExpr},
	self: boolean,
	argLocation: Location
}

export type AstExprConstantBool = AstExpr & {
	value: boolean
}

export type AstExprConstantNil = AstExpr

export type AstExprConstantNumber = AstExpr & {
	value: number,
	parseResult: number
}

export type AstExprConstantString = AstExpr & {
	value: string,
	quoteStyle: number
}

export type AstExprError = AstExpr & {
	expressions: {AstExpr},
	messageIndex: number
}

export type AstExprFunction = AstExpr & {
	attributes: {AstAttr},
	generics: {AstGenericType},
	genericPacks: {AstGenericTypePack},
	self: AstLocal?,
	args: {AstLocal},
	returnAnnotation: AstTypeList?,
	vararg: boolean,
	varargLocation: Location,
	varargAnnotation: AstTypePack?,

	body: AstStatBlock,

	functionDepth: number,

	debugname: AstName,

	argLocation: Location?,

	hasNativeAttribute: (self: AstExprFunction) -> boolean
}

export type AstExprGlobal = AstExpr & {
	name: AstName
}

export type AstExprGroup = AstExpr & {
	expr: AstExpr
}

export type AstExprIfElse = AstExpr & {
	condition: AstExpr,
	hasThen: boolean,
	trueExpr: AstExpr,
	hasElse: boolean,
	falseExpr: AstExpr
}

export type AstExprIndexExpr = AstExpr & {
	expr: AstExpr,
	index: AstExpr
}

export type AstExprIndexName = AstExpr & {
	expr: AstExpr,
	index: AstName,
	indexLocation: Location,
	opPosition: Position,
	op: string
}

export type AstExprInterpString = AstExpr & {
	strings: {string},
	expressions: {AstExpr}
}

export type AstExprLocal = AstExpr & {
	localAst: AstLocal,
	upvalue: boolean
}

export type TableItem = {
	--[=[
		@within AstExprTable_Item
		@prop kind number

		Corresponds to (kind enum)[AstExprTable_Item::Kind].
	]=]
	kind: number,

	--[=[
		@within AstExprTable_Item
		@prop key AstExpr?
	]=]
	key: AstExpr?,

	--[=[
		@within AstExprTable_Item
		@prop value AstExpr?
	]=]
	value: AstExpr
}

export type AstExprTable = AstExpr & {
	items: {TableItem}
}

export type AstExprTypeAssertion = AstExpr & {
	expr: AstExpr,
	annotation: AstType
}

export type AstExprUnary = AstExpr & {
	op: number,
	expr: AstExpr
}

export type AstExprVarargs = AstExpr & {
	
}

export type AstGenericType = {
	name: AstName,
	location: Location,
	defaultValue: AstType?
}

export type AstGenericTypePack = {
	name: AstName,
	location: Location,
	defaultValue: AstType?
}

export type AstLocal = {
	name: AstName,
	location: Location,
	shadow: AstLocal?,
	functionDepth: number,
	loopDepth: number,

	annotation: AstType?
}

export type AstStatAssign = AstStat & {
	vars: {AstExpr},
	values: {AstExpr}
}

export type AstStatBlock = AstStat & {
	body: {AstStat},

	--[=[
	@within AstStatBlock
	@prop hasEnd boolean
	@since v0.1.0

	Indicates whether or not this block has been terminated in a syntactically valid way.
	
	This is usually but not always done with the 'end' keyword.  AstStatIf and AstStatRepeat are the two main exceptions to this.
	
	The 'then' clause of an if statement can properly be closed by the keywords 'else' or 'elseif'.  A 'repeat' loop's body is closed with the 'until' keyword.
	]=]
	hasEnd: boolean
}

export type AstStatBreak = AstStat

export type AstStatCompoundAssign = AstStat & {
	op: number,
	var: AstExpr,
	value: AstExpr
}

export type AstStatContinue = AstStat

export type AstStatDeclareClass = AstStat & {
	name: AstName,
	superName: AstName?,

	props: {AstDeclaredClassProp},
	indexer: AstTableIndexer
}

export type AstStatDeclareFunction = AstStat & {
	attributes: {AstAttr},
	name: AstName,
	generics: {AstGenericType},
	genericPacks: {AstGenericTypePack},
	params: AstTypeList,
	paramNames: {AstArgumentName?},
	returnTypes: AstTypeList,

	--[=[
		@within AstTypeFunction
		@method isCheckedFunction
		@return boolean

		Whether the `@checked` attribute was applied to the function, which looks like:

		```lua
		@checked declare function name() -> ()
		```
	]=]
	isCheckedFunction: (self: AstStatDeclareFunction) -> boolean
}

export type AstStatDeclareGlobal = AstStat & {
	--[=[
		@within AstStatDeclareGlobal
		@prop name AstName
		@since v0.1.0
	]=]
	name: AstName,

	--[=[
		@within AstStatDeclareGlobal
		@prop type AstType
		@since v0.1.0
	]=]
	type: AstType
}

export type AstStatError = AstStat & {
	expressions: {AstExpr},
	statements: {AstStat},
	messageIndex: number
}

export type AstStatExpr = AstStat & {
	expr: AstExpr
}

export type AstStatFor = AstStat & {
	var: AstLocal,
	from: AstExpr,
	to: AstExpr,
	step: AstExpr?,
	body: AstStatBlock,

	hasDo: boolean,
	doLocation: Location
}

export type AstStatForIn = AstStat & {
	vars: {AstLocal},
	values: {AstExpr},
	body: AstStatBlock,

	hasIn: boolean,
	inLocation: Location,

	hasDo: boolean,
	doLocation: Location
}

export type AstStatFunction = AstStat & {
	name: AstExpr,
	func: AstExprFunction
}

export type AstStatIf = AstStat & {
	condition: AstExpr,
	thenbody: AstStatBlock,
	elsebody: AstStat,

	thenLocation: Location?,

	-- Active for 'elseif' as well
	elseLocation: Location?
}

export type AstStatLocal = AstStat & {
	vars: {AstLocal},
	values: {AstExpr},

	equalsSignLocation: Location?
}

export type AstStatLocalFunction = AstStat & {
	name: AstLocal,
	func: AstExprFunction
}

export type AstStatRepeat = AstStat & {
	condition: AstExpr,
	body: AstStatBlock
}

export type AstStatReturn = AstStat & {
	list: {AstExpr}
}

export type AstStatTypeAlias = AstStat & {
	name: AstName,
	nameLocation: Location,
	generics: {AstGenericType},
	genericPacks: {AstGenericTypePack},
	type: AstType,
	exported: boolean
}

export type AstStatWhile = AstStat & {
	condition: AstExpr,
	body: AstStatBlock,

	hasDo: boolean,
	doLocation: Location
}

export type AstTableIndexer = {
	indexType: AstType,
	resultType: AstType,
	location: Location,

	access: number,
	accessLocation: Location?
}

export type AstTableProp = {
	--[=[
		@within AstTableProp
		@prop name AstName
		@since v0.1.0
	]=]
	name: AstName,
	
	--[=[
		@within AstTableProp
		@prop location Location
		@since v0.1.0
	]=]
	location: Location,

	--[=[
		@within AstTableProp
		@prop type AstType
		@since v0.1.0
	]=]
	type: AstType,

	--[=[
		@within AstTableProp
		@prop access number
		@since v0.1.0
	]=]
	access: number,

	--[=[
		@within AstTableProp
		@prop accessLocation Location?
		@since v0.1.0
	]=]
	accessLocation: Location?
}

export type AstTypeError = AstType & {
	types: {AstType},
	isMissing: boolean,
	messageIndex: number
}

export type AstTypeFunction = AstType & {
	attributes: {AstAttr},
	generics: {AstGenericType},
	genericPacks: {AstGenericTypePack},
	argTypes: AstTypeList,
	argNames: {AstArgumentName?},
	returnTypes: AstTypeList,

	--[=[
		@within AstTypeFunction
		@method isCheckedFunction
		@return boolean

		Whether the `@checked` attribute was applied to the function, which looks like:

		```lua
		@checked
		local function name()

		end
		```
	]=]
	isCheckedFunction: (self: AstTypeFunction) -> boolean
}

export type AstTypeIntersection = AstType & {
	types: {AstType}
}

export type AstTypeList = {
	--[=[
		@within AstTypeList
		@prop types {AstType}
	]=]
	types: {AstType},

	--[=[
		@within AstTypeList
		@prop tailType AstTypePack?

		Nil indicates no tail, not an untyped tail.
	]=]
	tailType: AstTypePack?
}

export type AstTypeOrPack = {
	--[=[
		@within AstTypeOrPack
		@prop type AstType
	]=]
	type: AstType?,

	--[=[
		@within AstTypeOrPack
		@prop typePack AstTypePack
	]=]
	typePack: AstTypePack?
}

export type AstTypePack = AstNode

export type AstTypePackExplicit = AstType & {
	typeList: AstTypeList
}

export type AstTypePackGeneric = AstType & {
	genericName: AstName
}

export type AstTypePackVariadic = AstType & {
	variadicType: AstType
}

export type AstTypeReference = AstType & {
	hasParameterList: boolean,
	prefix: AstName?,
	prefixLocation: Location?,
	name: AstName,
	nameLocation: Location,
	parameters: {AstTypeOrPack}
}

export type AstTypeSingletonBool = AstType & {
	value: boolean
}

export type AstTypeSingletonString = AstType & {
	value: string
}

export type AstTypeTable = AstType & {
	props: {AstTableProp},
	indexer: AstTableIndexer
}

export type AstTypeTypeof = AstType & {
	expr: AstExpr
}

export type AstTypeUnion = AstType & {
	types: {AstType}
}

return nil