-- This file is practically identical to `AstStatBreak.luau`.

local AstClassIndex = require("./AstClassIndex")
local AstStat = require("./AstStat")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

export type AstStatContinue = AstStat.AstStat

local interface = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatContinue
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

function interface.new(location: Location.Location): AstStatContinue
	return setmetatable(AstStat.interface.new(interface.ClassIndex, location), metatable)
end

function prototype.visit(self: AstStatContinue, visitor: AstVisitor.AstVisitor): ()
	visitor:visit(self)
end

return interface