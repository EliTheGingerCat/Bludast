local AstClassIndex = require("./AstClassIndex")
local AstNodeTypes = require("./AstNodeTypes")
local AstStat = require("./AstStat")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstStat = AstStat.AstStat
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstStatContinue = AstNodeTypes.AstStatContinue

--[=[
	@class AstStatContinue
]=]
local interface = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatContinue
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

function interface.new(location: Location): AstStatContinue
	return setmetatable(AstStat.interface.new(interface.ClassIndex, location), metatable)
end

function prototype.visit(self: AstStatContinue, visitor: AstVisitor): ()
	visitor:visitAstStatContinue(self)
end

return interface