local AstClassIndex = require("./AstClassIndex")
local AstStat = require("./AstStat")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

export type AstStatBreak = AstStat.AstStat

local interface = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatBreak
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

function interface.new(location: Location.Location): AstStatBreak
	return setmetatable(AstStat.interface.new(interface.ClassIndex, location), metatable)
end

function prototype.visit(self: AstStatBreak, visitor: AstVisitor.AstVisitor): ()
	visitor:visit(self)
end

return interface