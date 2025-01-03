local AstArgumentName = require("./AstArgumentName")
local AstAttr = require("./AstAttr")
local AstClassIndex = require("./AstClassIndex")
local AstGenericType = require("./AstGenericType")
local AstGenericTypePack = require("./AstGenericTypePack")
local AstName = require("./AstName")
local AstStat = require("./AstStat")
local AstTypeList = require("./AstTypeList")
local AstUtilities = require("./AstUtilities")
local AstVisitor = require("./AstVisitor")
local FastVariables = require("./FastVariables")
local Location = require("./Location")

type AstArgumentName = AstArgumentName.AstArgumentName
type AstAttr = AstAttr.AstAttr
type AstGenericType = AstGenericType.AstGenericType
type AstGenericTypePack = AstGenericTypePack.AstGenericTypePack
type AstName = AstName.AstName
type AstStat = AstStat.AstStat
type AstTypeList = AstTypeList.AstTypeList
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstStatDeclareFunction = AstStat & {
	attributes: {AstAttr},
	name: AstName,
	generics: {AstGenericType},
	genericPacks: {AstGenericTypePack},
	params: AstTypeList,
	paramNames: {AstArgumentName?},
	returnTypes: AstTypeList,

	--[=[
		@within AstTypeFunction
		@method isCheckedFunction
		@return boolean

		Whether the `@checked` attribute was applied to the function, which looks like:

		```lua
		@checked declare function name() -> ()
		```
	]=]
	isCheckedFunction: (self: AstStatDeclareFunction) -> boolean
}

--[=[
	@class AstStatDeclareFunction

	Class from [`/Ast/src/Ast.cpp`]((https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/src/Ast.cpp#L721-L769)) and [`/Ast/include/Luau/Ast.h`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Ast.h#L837-L862).

	This is a nicer syntax for [global declarations](#AstStatDeclareGlobal) that are functions.

	Example:

	```lua
	declare function print(...: any): ()
	```
]=]
local AstStatDeclareFunction = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatDeclareFunction
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

-- Eli: I do not get paid enough to deal with all these overloaded functions.
AstStatDeclareFunction.new = function(location, a2: any, a3: any, a4: any, a5: any, a6: any, a7: any, a8: any)
	local self = AstStat.interface.new(AstStatDeclareFunction.ClassIndex, location) :: AstStatDeclareFunction
	local arguments
	if a8 then
		self.attributes = a2
		arguments = {a3, a4, a5, a6, a7, a8}
	else
		self.attributes = {}
		arguments = {a2, a3, a4, a5, a6, a7}
	end
	self.name = arguments[1]
	self.generics = arguments[2]
	self.genericPacks = arguments[3]
	self.params = arguments[4]
	self.paramNames = arguments[5]
	self.returnTypes = arguments[6]
	setmetatable(self, metatable)
	return self
end :: (
	  ((location: Location, name: AstName, generics: {AstGenericType}, genericPacks: {AstGenericTypePack}, params: AstTypeList, paramNames: {AstArgumentName}, retTypes: AstTypeList) -> AstStatDeclareFunction)
	& ((location: Location, attributes: {AstAttr}, name: AstName, generics: {AstGenericType}, genericPacks: {AstGenericTypePack}, params: AstTypeList, paramNames: {AstArgumentName}, retTypes: AstTypeList) -> AstStatDeclareFunction)
)

function prototype.visit(self: AstStatDeclareFunction, visitor: AstVisitor): ()
	if visitor:visit(self) then
		AstUtilities.visitTypeList(visitor, self.params)
		AstUtilities.visitTypeList(visitor, self.returnTypes)
	end
end

function prototype.isCheckedFunction(self: AstStatDeclareFunction): boolean
	assert(FastVariables.LuauAttributeSyntax)

	for _, attr in self.attributes do
		if attr.type == AstAttr.Type.Checked then
			return true
		end
	end

	return false
end

return AstStatDeclareFunction