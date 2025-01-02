local Constant = {
	Type = {
		Type_Nil = 1,
		Type_Boolean = 2,
		Type_Number = 3,
		Type_Vector = 4,
		Type_String = 5,
		Type_Import = 6,
		Type_Table = 7,
		Type_Closure = 8
	}
}

type Constant = {
	type: number,

	valueBoolean: boolean,
	valueNumber: number,
	valueVector: {number},
	valueString: number, -- index into string table
	valueImport: number, -- 10-10-10-2 encoded import id
	valueTable: number, -- index into tableShapes[]
	valueClosure: number, -- index of function in global list
}

--[=[
	@class BytecodeBuilder
]=]
local BytecodeBuilder = {}

export type BytecodeBuilder = {
	
}

local function log2(v: number): ()
	assert(v)

	local r = 0
	
	while v >= bit32.lshift(2, r) do
		r += 1
	end

	return r
end

return BytecodeBuilder