local AstClassIndex = require("./AstClassIndex")
local AstNodeTypes = require("./AstNodeTypes")
local AstStat = require("./AstStat")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstStat = AstStat.AstStat
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstStatBreak = AstNodeTypes.AstStatBreak

--[=[
	@class AstStatBreak
]=]
local AstStatBreak = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatBreak
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

function AstStatBreak.new(location: Location): AstStatBreak
	return setmetatable(AstStat.interface.new(AstStatBreak.ClassIndex, location), metatable)
end

function prototype.visit(self: AstStatBreak, visitor: AstVisitor): ()
	visitor:visitAstStatBreak(self)
end

return AstStatBreak