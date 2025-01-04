local AstExpr = require("./AstExpr")
local AstExprGlobal = require("./AstExprGlobal")
local AstExprLocal = require("./AstExprLocal")
local AstName = require("./AstName")
local AstTypeList = require("./AstTypeList")
local AstVisitor = require("./AstVisitor")

type AstExpr = AstExpr.AstExpr
type AstName = AstName.AstName
type AstTypeList = AstTypeList.AstTypeList
type AstVisitor = AstVisitor.AstVisitor

--[=[
	@class AstUtilities
	
	Various functions found in `/Ast/Ast.cpp`.
]=]
local AstUtilities = {}


--- @within AstUtilities
function AstUtilities.visitTypeList(visitor: AstVisitor, list: AstTypeList): ()
	for _, ty in list.types do
		ty:visit(visitor)
	end

	if list.tailType then
		list.tailType:visit(visitor)
	end
end

--- @within AstUtilities
function AstUtilities.getIdentifier(node: AstExpr): AstName
	local exprG = node:as(AstExprGlobal)
	if exprG then
		return exprG.name
	end

	local exprL = node:as(AstExprLocal)
	if exprL then
		return exprL.localAst.name
	end

	return AstName.new()
end

return AstUtilities