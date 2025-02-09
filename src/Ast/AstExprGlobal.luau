local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstName = require("./AstName")
local AstNodeTypes = require("./AstNodeTypes")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstExpr = AstExpr.AstExpr
type AstName = AstName.AstName
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

--[=[
	@class AstExprGlobal
]=]
export type AstExprGlobal = AstNodeTypes.AstExprGlobal

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
	visitor:visitAstExprGlobal(self)
end

return AstExprGlobal