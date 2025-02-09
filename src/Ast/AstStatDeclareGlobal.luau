local AstClassIndex = require("./AstClassIndex")
local AstName = require("./AstName")
local AstNodeTypes = require("./AstNodeTypes")
local AstStat = require("./AstStat")
local AstType = require("./AstType")
local AstVisitor = require("./AstVisitor")
local Location = require("@Shared/Location")

type AstName = AstName.AstName
type AstStat = AstStat.AstStat
type AstType = AstType.AstType
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstStatDeclareGlobal = AstNodeTypes.AstStatDeclareGlobal

--[=[
	@class AstStatDeclareGlobal
]=]
local AstStatDeclareGlobal = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatDeclareGlobal
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

function AstStatDeclareGlobal.new(location: Location, name: AstName, type: AstType): AstStatDeclareGlobal
	local self = AstStat.interface.new(AstStatDeclareGlobal.ClassIndex, location) :: AstStatDeclareGlobal
	self.name = name
	self.type = type
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstStatDeclareGlobal, visitor: AstVisitor): ()
	if visitor:visitAstStatDeclareGlobal(self) then
		self.type:visit(visitor)
	end
end

return AstStatDeclareGlobal