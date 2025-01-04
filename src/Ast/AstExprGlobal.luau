local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstName = require("./AstName")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstExpr = AstExpr.AstExpr
type AstName = AstName.AstName
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

--[=[
	@class AstExprGlobal
]=]
export type AstExprGlobal = AstExpr & {
	name: AstName.AstName
}

local AstExprGlobal = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstExprGlobal
}
local prototype = setmetatable({}, AstExpr.metatable)
local metatable = {__index = prototype}

function AstExprGlobal.new(location: Location, name: AstName): AstExprGlobal
	local self = AstExpr.interface.new(AstExprGlobal.ClassIndex, location) :: AstExprGlobal
	self.name = name
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstExprGlobal, visitor: AstVisitor): ()
	visitor:visit(self)
end

return AstExprGlobal