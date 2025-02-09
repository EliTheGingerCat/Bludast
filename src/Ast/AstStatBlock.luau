local AstClassIndex = require("./AstClassIndex")
local AstNodeTypes = require("./AstNodeTypes")
local AstStat = require("./AstStat")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstStat = AstStat.AstStat

export type AstStatBlock = AstNodeTypes.AstStatBlock

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
	if visitor:visitAstStatBlock(self) then
		for _, stat in self.body do
			stat:visit(visitor)
		end
	end
end

return interface