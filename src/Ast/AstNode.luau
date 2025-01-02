local AstClassIndex = require("./AstClassIndex")
local Location = require("./Location")

type class<T> = {
    ClassIndex: number,
    ClassType: T
}
export type AstNode = {
    visit: (self: AstNode, visitor: AstVisitor) -> (),
    asStat: (self: AstNode) -> AstStat,
    asType: (self: AstNode) -> AstType,
    asAttr: (self: AstNode) -> AstAttr,
    is: <T>(self: AstNode, class: class<T>) -> boolean,
    as: <T>(self: AstNode, class: class<T>) -> T?,

    classIndex: number,
    location: Location.Location
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
	Class from `root/Ast/include/Luau/Ast.h`.
]=]
local interface = {
    ClassIndex = AstClassIndex(),
    ClassType = (nil :: any) :: AstNode
}
local prototype = {}
local metatable = { __index = prototype}

function interface.new(classIndex: number, location: Location.Location): AstNode
    return setmetatable({
        classIndex = classIndex,
        location = location
    }, metatable) :: any
end

function prototype.is(self: AstNode, class: class<any>): boolean
    return self.classIndex == class.ClassIndex
end

function prototype.as<T>(self: AstNode, class: class<T>): T?
    return if self.classIndex == class.ClassIndex then self :: any else nil
end

return {
    interface = interface,
    metatable = metatable
}