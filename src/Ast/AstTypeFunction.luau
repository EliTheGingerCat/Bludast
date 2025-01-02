local AstArgumentName = require("./AstArgumentName")
local AstAttr = require("./AstAttr")
local AstClassIndex = require("./AstClassIndex")
local AstGenericType = require("./AstGenericType")
local AstGenericTypePack = require("./AstGenericTypePack")
local AstType = require("./AstType")
local AstTypeList = require("./AstTypeList")
local AstUtilities = require("./AstUtilities")
local AstVisitor = require("./AstVisitor")
local FastVariables = require("./FastVariables")
local Location = require("./Location")

type AstArgumentName = AstArgumentName.AstArgumentName
type AstAttr = AstAttr.AstAttr
type AstGenericType = AstGenericType.AstGenericType
type AstGenericTypePack = AstGenericTypePack.AstGenericTypePack
type AstType = AstType.AstType
type AstTypeList = AstTypeList.AstTypeList
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstTypeFunction = AstType & {
	attributes: {AstAttr},
	generics: {AstGenericType},
	genericPacks: {AstGenericTypePack},
	argTypes: AstTypeList,
	argNames: {AstArgumentName?},
	returnTypes: AstTypeList,

	--[=[
		@within AstTypeFunction
		@method isCheckedFunction
		@return boolean

		Whether the `@checked` attribute was applied to the function, which looks like:

		```lua
		@checked
		local function name()

		end
		```
	]=]
	isCheckedFunction: (self: AstTypeFunction) -> boolean
}

--[=[
	@class AstTypeFunction
	@tag class

	Class from [`/Ast/src/Ast.cpp`]((https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/src/Ast.cpp#L859-L906)) and [`/Ast/include/Luau/Ast.h`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Ast.h#L966-L988).
	```
]=]
local AstTypeFunction = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstTypeFunction
}
local prototype = setmetatable({}, AstType.metatable)
local metatable = {__index = prototype}

-- Eli: I do not get paid enough to deal with all these overloaded functions.
AstTypeFunction.new = function(location, a2: any, a3: any, a4: any, a5: any, a6: any, a7: any)
	local self = AstType.interface.new(AstTypeFunction.ClassIndex, location) :: AstTypeFunction
	local arguments
	if a7 then
		self.attributes = a2
		arguments = {a3, a4, a5, a6, a7}
	else
		self.attributes = {}
		arguments = {a2, a3, a4, a5, a6}
	end
	self.generics = arguments[1]
	self.genericPacks = arguments[2]
	self.argTypes = arguments[3]
	self.argNames = arguments[4]
	self.returnTypes = arguments[5]
	setmetatable(self, metatable)

	assert(#self.argNames == 0 or #self.argNames == #self.argTypes.types)

	return self
end :: (
	  ((location: Location, generics: {AstGenericType}, genericPacks: {AstGenericTypePack}, argTypes: AstTypeList, argNames: {AstArgumentName?}, returnTypes: AstTypeList) -> AstTypeFunction)
	& ((location: Location, attributes: {AstAttr}, generics: {AstGenericType}, genericPacks: {AstGenericTypePack}, argTypes: AstTypeList, argNames: {AstArgumentName?}, returnTypes: AstTypeList) -> AstTypeFunction)
)

function prototype.visit(self: AstTypeFunction, visitor: AstVisitor): ()
	if visitor:visit(self) then
		AstUtilities.visitTypeList(visitor, self.argTypes)
		AstUtilities.visitTypeList(visitor, self.returnTypes)
	end
end

function prototype.isCheckedFunction(self: AstTypeFunction): boolean
	assert(FastFlags.LuauAttributeSyntax)

	for _, attr in self.attributes do
		if attr.type == AstAttr.Type.Checked then
			return true
		end
	end

	return false
end

return AstTypeFunction