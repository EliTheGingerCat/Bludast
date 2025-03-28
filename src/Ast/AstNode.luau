local AstClassIndex = require("./AstClassIndex")
local AstNodeTypes = require("./AstNodeTypes")
local Location = require("@Shared/Location")

export type AstNode = AstNodeTypes.AstNode
type Location = Location.Location

--[=[
	@within AstNode
	@type class {ClassIndex: number, ClassType: T}

	Used in [is](AstNode#is) and [as](AstNode#as).
]=]
export type class<T> = {
	ClassIndex: number,
	ClassType: T
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