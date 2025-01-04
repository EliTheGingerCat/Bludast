local AstClassIndex = require("./AstClassIndex")
local AstStat = require("./AstStat")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstStat = AstStat.AstStat
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstStatContinue = AstStat

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
	visitor:visit(self)
end

return interface