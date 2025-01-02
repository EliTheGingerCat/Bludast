local AstClassIndex = require("./AstClassIndex")
local AstStat = require("./AstStat")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstStat = AstStat.AstStat

export type AstStatBlock = AstStat & {
    body: {AstStat},
    --[[
     - Indicates whether or not this block has been terminated in a
     - syntactically valid way.
     -
     - This is usually but not always done with the 'end' keyword.  AstStatIf
     - and AstStatRepeat are the two main exceptions to this.
     -
     - The 'then' clause of an if statement can properly be closed by the
     - keywords 'else' or 'elseif'.  A 'repeat' loop's body is closed with the
     - 'until' keyword.
    ]]
    hasEnd: boolean
}

--[=[
	@class AstStatBlock
	Class from `root/Ast/src/Ast.cpp`.
]=]
local interface = {
    ClassIndex = AstClassIndex(),
    ClassType = (nil :: any) :: AstStatBlock
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

function interface.new(location: Location.Location, body: {AstStat}, hasEnd: boolean?): AstStatBlock
    local self = AstStat.interface.new(interface.ClassIndex, location) :: AstStatBlock
    self.body = body
    self.hasEnd = hasEnd or false
    setmetatable(self, metatable)
    return self
end

function prototype.visit(self: AstStatBlock, visitor: AstVisitor.AstVisitor): ()
    if visitor:visit(self) then
        for _, stat in self.body do
            -- Eli NEW_SOLVER
            stat:visit(visitor)
        end
    end
end

return interface