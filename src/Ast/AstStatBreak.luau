local AstClassIndex = require("./AstClassIndex")
local AstStat = require("./AstStat")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstStat = AstStat.AstStat
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstStatBreak = AstStat

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
	visitor:visit(self)
end

return AstStatBreak