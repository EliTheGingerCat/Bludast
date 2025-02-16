local AstAttr = require("./AstAttr")
local AstClassIndex = require("./AstClassIndex")
local AstExpr = require("./AstExpr")
local AstGenericType = require("./AstGenericType")
local AstGenericTypePack = require("./AstGenericTypePack")
local AstLocal = require("./AstLocal")
local AstName = require("./AstName")
local AstNodeTypes = require("./AstNodeTypes")
local AstStatBlock = require("./AstStatBlock")
local AstTypeList = require("./AstTypeList")
local AstUtilities = require("./AstUtilities")
local AstVisitor = require("./AstVisitor")
local FastVariables = require("@Shared/FastVariables")
local Location = require("@Shared/Location")

type AstAttr = AstAttr.AstAttr
type AstExpr = AstExpr.AstExpr
type AstGenericType = AstGenericType.AstGenericType
type AstGenericTypePack = AstGenericTypePack.AstGenericTypePack
type AstLocal = AstLocal.AstLocal
type AstName = AstName.AstName
type AstStatBlock = AstStatBlock.AstStatBlock
type AstTypeList = AstTypeList.AstTypeList
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstExprFunction = AstNodeTypes.AstExprFunction

--[=[
	@class AstExprFunction
]=]
local AstExprFunction = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstExprFunction
}
local prototype = setmetatable({}, AstExpr.metatable)
local metatable = {__index = prototype}

function AstExprFunction.new(location: Location, attributes: {AstAttr}, generics: {AstGenericType}, genericPacks: {AstGenericTypePack}, selfLocal: AstLocal?, args: {AstLocal}, vararg: boolean, varargLocation: Location, body: AstStatBlock, functionDepth: number, debugname: AstName, returnAnnotation: AstTypeList?, varargAnnotation: AstTypePack?, argLocation: Location?): AstExprFunction
	local self = AstExpr.interface.new(AstExprFunction.ClassIndex, location) :: AstExprFunction
	self.attributes = attributes
	self.generics = generics
	self.genericPacks = genericPacks
	self.self = selfLocal
	self.args = args
	self.returnAnnotation = returnAnnotation
	self.vararg = vararg
	self.varargLocation = varargLocation
	self.varargAnnotation = varargAnnotation
	self.body = body
	self.functionDepth = functionDepth
	self.debugname = debugname
	self.argLocation = argLocation
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstExprFunction, visitor: AstVisitor): ()
	if visitor:visitAstExprFunction(self) then
		for _, arg in self.args do
			if arg.annotation then
				arg.annotation:visit(visitor)
			end
		end

		if self.varargAnnotation then
			self.varargAnnotation:visit(visitor)
		end

		if self.returnAnnotation then
			AstUtilities.visitTypeList(visitor, self.returnAnnotation)
		end

		self.body:visit(visitor)
	end
end

function prototype.hasNativeAttribute(self: AstExprFunction): boolean
	assert(FastVariables.LuauNativeAttribute)

	for _, attribute in self.attributes do
		if attribute.type == AstAttr.Type.Native then
			return true
		end
	end
	return false
end

return AstExprFunction