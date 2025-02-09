local prototype = {}
local metatable = {__index = prototype}
local Constant = {
	Type = {
		Type_Unknown = 1,
		Type_Nil = 2,
		Type_Boolean = 3,
		Type_Number = 4,
		Type_Vector = 5,
		Type_String = 6
	},
}

export type Constant = typeof(setmetatable({} :: {
	type: number,
	stringLength: number,

	valueBoolean: boolean,
	valueNumber: number,
	valueVector: {number},
	valueString: string
}, metatable))

function Constant.new(type: number?): Constant
	return setmetatable({
		type = type or Constant.Type.Type_Unknown
	}, metatable) :: Constant
end

function prototype.isTruthful(self: Constant): boolean
	assert(self.type ~= Constant.Type.Type_Unknown)
	return self.type ~= Constant.Type.Type_Nil and not (self.type == Constant.Type.Type_Boolean and self.valueBoolean == false)
end

function prototype.getString(self: Constant): string
	assert(self.type == Constant.Type.Type_String)
	return self.valueString
end

return Constant