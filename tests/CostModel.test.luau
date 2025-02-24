local AstNameTable = require("@Ast/AstNameTable")
local AstStatFunction = require("@Ast/AstStatFunction")
local CostModel = require("@Compiler/CostModel")
local NumberConversions = require("@Polyfill/NumberConversions")
local ParseOptions = require("@Ast/ParseOptions")
local Parser = require("@Ast/Parser")

local computeCost = CostModel.computeCost
local modelCost = CostModel.modelCost
type u64 = NumberConversions.u64

local function modelFunction(source: string): u64
	local names = AstNameTable.new()

	local result = Parser.parse(source, #source, names, ParseOptions.new())
	assert(result.root ~= nil)

	local func = result.root.body[1]:as(AstStatFunction)
	assert(func)

	return modelCost(func.func.body, func.func.args, #func.func.args, {})
end

return {
	Expression = function()
		local model = modelFunction([[
function test(a, b, c)
	return a + (b + 1) * (b + 1) - c
end
		]])

		local args1 = {false, false, false}
		local args2 = {false, true, false}

		assert(5 == computeCost(model, args1, 3))
		assert(2 == computeCost(model, args2, 3))
	end,

	PropagateVariable = function()
		local model = modelFunction([[
function test(a)
    local b = a * a * a
    return b * b
end
		]])

		local args1 = {false}
		local args2 = {true}

		assert(3 == computeCost(model, args1, 1))
		assert(0 == computeCost(model, args2, 1))
	end,

	LoopAssign = function()
		local model = modelFunction([[
function test(a)
    for i=1,3 do
        a[i] = i
    end
end
		]])

		local args1 = {false}
		local args2 = {true}

		-- loop baseline cost is 5
		assert(6 == computeCost(model, args1, 1))
		assert(6 == computeCost(model, args2, 1))
	end,

	MutableVariable = function()
		local model = modelFunction([[
function test(a, b)
    local x = a * a
    x += b
    return x * x
end
		]])

		local args1 = {false}
		local args2 = {true}

		assert(3 == computeCost(model, args1, 1))
		assert(2 == computeCost(model, args2, 1))
	end,

	ImportCall = function()
		local model = modelFunction([[
function test(a)
    return Instance.new(a)
end
		]])
		
		local args1 = {false}
		local args2 = {true}

		assert(6 == computeCost(model, args1, 1))
		assert(6 == computeCost(model, args2, 1))
	end,

	FastCall = function()
		local model = modelFunction([[
function test(a)
    return math.abs(a + 1)
end
		]])

		local args1 = {false}
		local args2 = {true}

		-- note: we currently don't treat fast calls differently from cost model perspective
		assert(6 == computeCost(model, args1, 1))
		assert(5 == computeCost(model, args2, 1))
	end,

	ControlFlow = function()
		local model = modelFunction([[
function test(a)
    while a < 0 do
        a += 1
    end
    for i=10,1,-1 do
        a += 1
    end
    for i in pairs({}) do
        a += 1
        if a % 2 == 0 then continue end
    end
    repeat
        a += 1
        if a % 2 == 0 then break end
    until a > 10
    return a
end
		]])

		local args1 = {false}
		local args2 = {true}

		assert(76 == computeCost(model, args1, 1))
		assert(73 == computeCost(model, args2, 1))
	end,

	Conditional = function()
		local model = modelFunction([[
function test(a)
    return if a < 0 then -a else a
end
		]])

		local args1 = {false}
		local args2 = {true}

		assert(4 == computeCost(model, args1, 1))
		assert(2 == computeCost(model, args2, 1))
	end,

	VarArgs = function()
		local model = modelFunction([[
function test(...)
    return select('#', ...) :: number
end
		]])

		assert(8 == computeCost(model, nil, 0))
	end,

	TablesFunctions = function()
		local model = modelFunction([[
function test()
    return { 42, op = function() end }
end
		]])

		assert(22 == computeCost(model, nil, 0))
	end,

	CostOverflow = function()
		local model = modelFunction([[
function test()
    return {{{{{{{{{{{{{{{}}}}}}}}}}}}}}}
end
		]])

		assert(127 == computeCost(model, nil, 0))
	end,

	TableAssign = function()
		local model = modelFunction([[
function test(a)
    for i=1,#a do
        a[i] = i
    end
end
		]])

		local args1 = {false}
		local args2 = {true}

		assert(7 == computeCost(model, args1, 1))
		assert(6 == computeCost(model, args2, 1))
	end,

	InterpString = function()
		local model = modelFunction([[
function test(a)
    return `hello, {a}!`
end
		]])

		local args1 = {false}
		local args2 = {true}

		assert(3 == computeCost(model, args1, 1))
		assert(3 == computeCost(model, args2, 1))
	end,

	MultipleAssignments = function()
		local model = modelFunction([[
function test(a)
    local x = 0
    x = a
    x = a + 1
    x, x, x = a
    x = a, a, a
end
		]])

		local args1 = {false}
		local args2 = {true}

		assert(8 == computeCost(model, args1, 1))
		assert(7 == computeCost(model, args2, 1))
	end
}