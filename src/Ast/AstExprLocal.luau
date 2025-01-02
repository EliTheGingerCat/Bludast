local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstLocal = require("./AstLocal")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstExpr = AstExpr.AstExpr
type AstLocal = AstLocal.AstLocal
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstExprLocal = AstExpr & {
	localAst: AstLocal,
	upvalue: boolean
}

local AstExprLocal = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstExprLocal
}
local prototype = setmetatable({}, AstExpr.metatable)
local metatable = {__index = prototype}

function AstExprLocal.new(location: Location, localAst: AstLocal, upvalue: boolean): AstExprLocal
	local self = AstExpr.interface.new(AstExprLocal.ClassIndex, location) :: AstExprLocal
	self.localAst = localAst
	self.upvalue = upvalue
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstExprLocal, visitor: AstVisitor): ()
	visitor:visit(self)
end

return AstExprLocal