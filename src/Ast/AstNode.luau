local AstClassIndex = require("./AstClassIndex")
local Location = require("./Location")

type Location = Location.Location

--[=[
	@within AstNode
	@type class {ClassIndex: number, ClassType: T}

	Used in [is](AstNode#is) and [as](AstNode#as).
]=]
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
	visit: (self: AstNode, visitor: AstVisitor) -> (),
	asStat: (self: AstNode) -> AstStat,
	asType: (self: AstNode) -> AstType,
	asAttr: (self: AstNode) -> AstAttr,
	is: <T>(self: AstNode, class: class<T>) -> boolean,
	as: <T>(self: AstNode, class: class<T>) -> T?,

	classIndex: number,
	location: Location
}

-- Defined a second time here to avoid cyclic since I think it would be weird for AstVisitor type to be accessed from AstNode.
type AstVisitor = {
	visit: (
		self: AstVisitor,
		node: AstNode
	) -> boolean
}

-- Define some stuff again to avoid cyclic dependencies.
type AstAttr = AstNode & {
	type: number
}
type AstStat = AstNode & {
	hasSemicolon: boolean
}
type AstType = AstNode

-- Eli TODO fix the above.

--[=[
	@class AstNode
	
	Class from [`root/Ast/include/Luau/Ast.h`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Ast.h#L154-L200).
]=]
local AstNode = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstNode
}
local prototype = {}
local metatable = { __index = prototype}

--- @within AstNode
function AstNode.new(classIndex: number, location: Location.Location): AstNode
	return setmetatable({
		classIndex = classIndex,
		location = location
	}, metatable) :: any
end

--[=[
	@within AstNode
	@method is
	@param class class<any>
	@return boolean -- Whether the class of `self` is `class`.
]=]
function prototype.is(self: AstNode, class: class<any>): boolean
	return self.classIndex == class.ClassIndex
end

--[=[
	@within AstNode
	@method as
	@param class class<T>
	@return T? -- `self` if its class is `class`, nil otherwise
]=]
function prototype.as<T>(self: AstNode, class: class<T>): T?
	return if self.classIndex == class.ClassIndex then self :: any else nil
end

return {
	interface = AstNode,
	metatable = metatable
}