local AstNameTable = require("@Ast/AstNameTable")
local AstStatAssign = require("@Ast/AstStatAssign")
local AstStatBlock = require("@Ast/AstStatBlock")
local AstStatExpr = require("@Ast/AstStatExpr")
local AstStatFunction = require("@ASt/AstStatFunction")
local AstStatLocal = require("@Ast/AstStatLocal")
local AstStatTypeAlias = require("@Ast/AstStatTypeAlias")
local AstTypeFunction = require("@Ast/AstTypeFunction")
local AstTypeIntersection = require("@Ast/AstTypeIntersection")
local AstTypeReference = require("@Ast/AstTypeReference")
local Location = require("@Ast/Location")
local ParseErrors = require("@Ast/ParseErrors")
local ParseOptions = require("@Ast/ParseOptions")
local Parser = require("@Ast/Parser")
local Position = require("@Ast/Position")

type AstStatBlock = AstStatBlock.AstStatBlock

local names = AstNameTable.new()
local options = ParseOptions.new(false, true)

local function parse(source: string): AstStatBlock?
	local result = Parser.parse(source, #source, names, options)

	if not result.errors:empty() then
		error(ParseErrors.new(result.errors))
	end

	return result.root
end

return {
	basic_parse = function()
		local block = parse("print(\"Hello World!\")")
		assert(block)
	end,
	can_haz_annotations = function()
		local block = parse("local foo: string = \"Hello Types!\"")
		assert(block)
	end,
	local_with_annotation = function()
		local block = parse([[
			local foo: string = "Hello Types!"
		]])

		assert(block)
		assert(#block.body > 0)

		local statLocal = block.body[1]:as(AstStatLocal)
		assert(statLocal)

		assert(1 == #statLocal.vars)

		local l = statLocal.vars[1]
		assert(l.annotation)
		
		assert(1 == #statLocal.values)
	end,
	type_names_can_contain_dots = function()
		parse([[
			local foo: SomeModule.CoolType
		]])
	end,
	functions_can_have_return_annotations = function()
		local block = parse([[
			function foo(): number return 55 end
		]])

		assert(block)
		assert(#block.body > 0)

		local statFunction = block.body[1]:as(AstStatFunction)
		assert(statFunction)

		assert(statFunction.func.returnAnnotation)
		assert(#statFunction.func.returnAnnotation.types == 1)
		assert(statFunction.func.returnAnnotation.tailType == nil)
	end,
	functions_can_have_a_function_type_annotation = function()
		local block = parse([[
			function f(): (number) -> nil return nil end
		]])

		assert(block)
		assert(#block.body > 0)

		local statFunc = block.body[1]:as(AstStatFunction)
		assert(statFunc)

		assert(statFunc.func.returnAnnotation)
		assert(statFunc.func.returnAnnotation.tailType == nil)
		local retTypes = statFunc.func.returnAnnotation.types
		assert(#retTypes == 1)

		local funTy = retTypes[1]:as(AstTypeFunction)
		assert(funTy)
	end,
	function_return_type_should_disambiguate_from_function_type_and_multiple_returns = function()
		local block = parse([[
			function f(): (number, string) return 1, "foo" end
		]])

		assert(block)
		assert(#block.body > 0)

		local statFunc = block.body[1]:as(AstStatFunction)
		assert(statFunc)

		assert(statFunc.func.returnAnnotation)
		assert(statFunc.func.returnAnnotation.tailType == nil)
		local retTypes = statFunc.func.returnAnnotation.types
		assert(#retTypes == 2)

		local ty0 = retTypes[1]:as(AstTypeReference)
		assert(ty0)
		assert(ty0.name.value == "number")

		local ty1 = retTypes[2]:as(AstTypeReference)
		assert(ty1)
		assert(ty1.name.value == "string")
	end,
	function_return_type_should_parse_as_function_type_annotation_with_no_args = function()
		local block = parse([[
			function f(): () -> nil return nil end
		]])

		assert(block)
		assert(#block.body > 0)

		local statFunc = block.body[1]:as(AstStatFunction)
		assert(statFunc)

		assert(statFunc.func.returnAnnotation)
		assert(statFunc.func.returnAnnotation.tailType == nil)
		local retTypes = statFunc.func.returnAnnotation.types
		assert(#retTypes == 1)

		local funTy = retTypes[1]:as(AstTypeFunction)
		assert(funTy)
		assert(#funTy.argTypes.types == 0)
		assert(funTy.argTypes.tailType == nil)
		assert(funTy.returnTypes.tailType == nil)

		local ty = funTy.returnTypes.types[1]:as(AstTypeReference)
		assert(ty)
		assert(ty.name.value == "nil")
	end,
	annotations_can_be_tables = function()
		local stat = parse([[
			local zero: number
        	local one: {x: number, y: string}
		]])
		assert(stat)
	end,
	tables_should_have_an_indexer_and_keys = function()
		local stat = parse([[
			local t: {
				[string]: number,
				f: () -> nil
        	}
		]])
		assert(stat)
	end,
	tables_can_have_trailing_separator = function()
		local stat = parse([[
			local zero: number
        	local one: {x: number, y: string, }
		]])

		assert(stat)
	end,
	tables_can_use_semicolons = function()
		local stat = parse([[
			local zero: number
        	local one: {x: number; y: string; }
		]])

		assert(stat)
	end,
	other_places_where_type_annotations_are_allowed = function()
		local stat = parse([[
			for i: number = 0, 50 do end
        	for i: number, s: string in expr() do end
		]])

		assert(stat)
	end,
	nil_is_a_valid_type_name = function()
		local stat = parse([[
			local n: nil
		]])

		assert(stat)
	end,
	function_type_annotation = function()
		local stat = parse([[
			local f: (number, string) -> nil
		]])

		assert(stat)
	end,
	functions_can_return_multiple_values = function()
		local stat = parse([[
			local f: (number) -> (number, number)
		]])

		assert(stat)
	end,
	functions_can_have_0_arguments = function()
		local stat = parse([[
			local f: () -> number
		]])

		assert(stat)
	end,
	functions_can_return_0_values = function()
		local stat = parse([[
			local f: (number) -> ()
		]])

		assert(stat)
	end,
	intersection_of_two_function_types_if_no_returns = function()
		local block = parse([[
			local f: (string) -> () & (number) -> ()
		]])

		assert(block)

		local statLocal = assert(block.body[1]:as(AstStatLocal))
		local annotation = assert(statLocal.vars[1].annotation):as(AstTypeIntersection)
		assert(annotation)
		assert(annotation.types[1]:as(AstTypeFunction))
		assert(annotation.types[2]:as(AstTypeFunction))
	end,
	intersection_of_two_function_types_if_two_or_more_returns = function()
		local block = parse([[
			local f: (string) -> (string, number) & (number) -> (number, string)
		]])

		assert(block)

		local statLocal = assert(block.body[1]:as(AstStatLocal))
		local annotation = assert(statLocal.vars[1].annotation):as(AstTypeIntersection)
		assert(annotation)
		assert(annotation.types[1]:as(AstTypeFunction))
		assert(annotation.types[2]:as(AstTypeFunction))
	end,
	return_type_is_an_intersection_type_if_led_with_one_parenthesized_type = function()
		local block = parse([[
			local f: (string) -> (string) & (number) -> (number)
		]])

		assert(block)

		local statLocal = block.body[1]:as(AstStatLocal)
		local annotation = assert(assert(statLocal).vars[1].annotation):as(AstTypeFunction)
		assert(annotation)

		local returnAnnotation = annotation.returnTypes.types[1]:as(AstTypeIntersection)
		assert(returnAnnotation)
		assert(returnAnnotation.types[1]:as(AstTypeReference))
		assert(returnAnnotation.types[2]:as(AstTypeFunction))
	end,
	type_alias_to_a_typeof = function()
		local block = parse("       type A = typeof(1)")

		assert(block)
		assert(#block.body > 0)

		local typeAliasStat = block.body[1]:as(AstStatTypeAlias)
		assert(typeAliasStat)
		assert(typeAliasStat.location :: any == Location.new(Position.new(1, 8), Position.new(1, 26)))
	end,
	type_alias_should_point_to_string = function()
		local block = parse([[
			type A = string
		]])

		assert(block)
		assert(#block.body > 0)
		assert(block.body[1]:is(AstStatTypeAlias))
	end,
	type_alias_should_not_interfere_with_type_function_call_or_assignment = function()
		local block = parse([[
			type("a")
        	type = nil
		]])

		assert(block)
		assert(#block.body > 0)

		local stat = block.body[1]:as(AstStatExpr)
		assert(stat)
		assert(stat.expr)

		assert(assert(block.body[2]:is(AstStatAssign)))
	end,
	type_alias_should_work_when_name_is_also_local = function()
		local block = parse([[
			local A = nil
        	type A = string
		]])
		
		assert(block)
		assert(#block.body == 2)
		assert(block.body[1]:is(AstStatLocal))
		assert(block.body[2]:is(AstStatTypeAlias))
	end,
	type_alias_span_is_correct = function()
		local block = parse([[
       type Packed1<T...> = (T...) -> (T...)
       type Packed2<T...> = (Packed1<T...>, T...) -> (Packed1<T...>, T...)
		]])

		assert(block)
		assert(2 == #block.body)
		local t1 = block.body[1]:as(AstStatTypeAlias)
		assert(t1)
		assert(Location.new(Position.new(1, 8), Position.new(1, 45)) :: any == t1.location)
		
		local t2 = block.body[2]:as(AstStatTypeAlias)
		assert(t2)
		assert(Location.new(Position.new(2, 8), Position.new(2, 75)) :: any == t2.location)
	end
}