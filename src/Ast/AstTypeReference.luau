local AstClassIndex = require("./AstClassIndex")
local AstName = require("./AstName")
local AstType = require("./AstType")
local AstTypeOrPack = require("./AstTypeOrPack")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstName = AstName.AstName
type AstType = AstType.AstType
type AstTypeOrPack = AstTypeOrPack.AstTypeOrPack
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstTypeReference = AstType & {
	hasParameterList: boolean,
	prefix: AstName?,
	prefixLocation: Location?,
	name: AstName,
	nameLocation: Location,
	parameters: {AstTypeOrPack}
}

local AstTypeReference = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstTypeReference
}
local prototype = setmetatable({}, AstType.metatable)
local metatable = {__index = prototype}

function AstTypeReference.new(location: Location, prefix: AstName?, name: AstName, prefixLocation: Location?, nameLocation: Location, hasParameterList: boolean?, parameters: {AstTypeOrPack}?): AstTypeReference
	local self = AstType.interface.new(AstTypeReference.ClassIndex, location) :: AstTypeReference
	self.hasParameterList = hasParameterList or false
	self.prefix = prefix
	self.prefixLocation = prefixLocation
	self.name = name
	self.nameLocation = nameLocation
	self.parameters = parameters or {}
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstTypeReference, visitor: AstVisitor): ()
	if visitor:visit(self) then
		for _, param in self.parameters do
			if param.type then
				-- Eli: NEW_SOLVER
				param.type:visit(visitor)
			else
				param.typePack:visit(visitor)
			end
		end
	end
end

return AstTypeReference