--!nolint LocalShadow

local AstAttr = require("@Ast/AstAttr")
local AstExprBinary = require("@Ast/AstExprBinary")
local AstExprCall = require("@Ast/AstExprCall")
local AstExprConstantNumber = require("@Ast/AstExprConstantNumber")
local AstExprConstantString = require("@Ast/AstExprConstantString")
local AstExprError = require("@Ast/AstExprError")
local AstExprFunction = require("@Ast/AstExprFunction")
local AstExprIfElse = require("@Ast/AstExprIfElse")
local AstExprIndexName = require("@Ast/AstExprIndexName")
local AstExprTable = require("@Ast/AstExprTable")
local AstExprTypeAssertion = require("@Ast/AstExprTypeAssertion")
local AstName = require("@Ast/AstName")
local AstNameTable = require("@Ast/AstNameTable")
local AstQueryDsl = require("./AstQueryDsl")
local AstStatAssign = require("@Ast/AstStatAssign")
local AstStatBlock = require("@Ast/AstStatBlock")
local AstStatCompoundAssign = require("@Ast/AstStatCompoundAssign")
local AstStatContinue = require("@Ast/AstStatContinue")
local AstStatDeclareClass = require("@Ast/AstStatDeclareClass")
local AstStatDeclareFunction = require("@Ast/AstStatDeclareFunction")
local AstStatDeclareGlobal = require("@Ast/AstStatDeclareGlobal")
local AstStatError = require("@Ast/AstStatError")
local AstStatExpr = require("@Ast/AstStatExpr")
local AstStatFunction = require("@ASt/AstStatFunction")
local AstStatLocal = require("@Ast/AstStatLocal")
local AstStatLocalFunction = require("@Ast/AstStatLocalFunction")
local AstStatReturn = require("@Ast/AstStatReturn")
local AstStatTypeAlias = require("@Ast/AstStatTypeAlias")
local AstStatWhile = require("@Ast/AstStatWhile")
local AstTypeFunction = require("@Ast/AstTypeFunction")
local AstTypeIntersection = require("@Ast/AstTypeIntersection")
local AstTypePackGeneric = require("@Ast/AstTypePackGeneric")
local AstTypeReference = require("@Ast/AstTypeReference")
local AstTypeTable = require("@Ast/AstTypeTable")
local AstVisitor = require("@Ast/AstVisitor")
local FastVariables = require("@Shared/FastVariables")
local HotComment = require("@Ast/HotComment")
local Lexeme = require("@Ast/Lexeme")
local Lexer = require("@Ast/Lexer")
local Location = require("@Shared/Location")
local ParseError = require("@Ast/ParseError")
local ParseErrors = require("@Ast/ParseErrors")
local ParseOptions = require("@Ast/ParseOptions")
local ParseResult = require("@Ast/ParseResult")
local Parser = require("@Ast/Parser")
local Position = require("@Shared/Position")
local ScopedVariable = require("@Shared/ScopedVariable")
local Try = require("@Polyfill/Try")
local Vector = require("@Polyfill/Vector")

type AstStatBlock = AstStatBlock.AstStatBlock
type AstVisitor = AstVisitor.AstVisitor
type FV = typeof(FastVariables)
type ParseErrors = ParseErrors.ParseErrors
local query = AstQueryDsl.query

local defaultOptions = ParseOptions.new(false, true)

local function parse(source: string, options: ParseOptions.ParseOptions?): AstStatBlock?
	local result = Parser.parse(source, #source, AstNameTable.new(), options or defaultOptions)

	if not result.errors:empty() then
		error(ParseErrors.new(result.errors))
	end

	return result.root
end

-- TODO: delete this and replace all other use of this function with matchParseError
local function getParseError(code: string): string
	local success, result = pcall(parse, code)

	if success then
		error(`Expected a parse error in '{code}'`)
	end

	return ((result :: any) :: ParseErrors):getErrors():front():getMessage()
end

local function matchParseError(source: string, message: string, location: Location.Location?): ParseResult.ParseResult
	local options = ParseOptions.new(true, true)
	local result = Parser.parse(source, #source, AstNameTable.new(), options)

	assert(not result.errors:empty(), `Expected a parse error in '{source}'`)

	if not result.errors:empty() then
		assert(result.errors:front():getMessage() == message)

		if location then
			assert(result.errors:front():getLocation() == location)
		end
	end

	return result
end

local function matchParseErrorPrefix(source: string, prefix: string)
	local options = ParseOptions.new()
	options.allowDeclarationSyntax = true

	local result = Parser.parse(source, #source, AstNameTable.new(), options)

	assert(not result.errors:empty(), `Expected a parse error in '{source}'`)

	if not result.errors:empty() then
		local message = result.errors:front():getMessage()
		assert(#message >= #prefix)
		assert(prefix == message:sub(1, #prefix))
	end

	return result
end

local function tryParse(source: string, parseOptions: ParseOptions.ParseOptions?): ParseResult.ParseResult
	local options = parseOptions or ParseOptions.new()
	options.allowDeclarationSyntax = true

	local result = Parser.parse(source, #source, AstNameTable.new(), options)
	return result
end

local function parseEx(source: string, options: ParseOptions.ParseOptions?): ParseResult.ParseResult
	local result = tryParse(source, options)
	if not result.errors:empty() then
		error(ParseErrors.new(result.errors))
	end
	return result
end

local function parseMode(hotcomments: Vector.Vector<HotComment.HotComment>): number?
	for _, hc in hotcomments:data() do
		if not hc.header then
			continue
		end
		if hc.content == "nocheck" then
			return ParseOptions.Mode.NoCheck
		end
		if hc.content == "nonstrict" then
			return ParseOptions.Mode.Nonstrict
		end
		if hc.content == "strict" then
			return ParseOptions.Mode.Strict
		end
	end

	return nil
end

local function checkAttribute(attr: AstAttr.AstAttr, type: number, location: Location.Location)
	assert(attr.type == type)
	assert(attr.location == location)
end

local function checkFirstErrorForAttributes(errors: Vector.Vector<ParseError.ParseError>, minSize: number, location: Location.Location, message: string)
	assert(minSize >= 1)

	assert(errors:size() >= minSize)
	assert(errors:get(1):getLocation() == location)
	assert(errors:get(1):getMessage() == message)
end

local prototype = setmetatable({}, AstVisitor.metatable)
local metatable = {__index = prototype}
local CountAstNodes = {}
type CountAstNodes = AstVisitor & {
	count: number
}

function CountAstNodes.new(): CountAstNodes
	local self = AstVisitor.new() :: CountAstNodes
	self.count = 0
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: CountAstNodes): boolean
	self.count += 1

	return true
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
		local block = parse([[

        type A = typeof(1)
		]])

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
	end,
	parse_error_messages = function()
		assert(getParseError([[

			local a: (number, number) -> (string
		]]) == "Expected ')' (to close '(' at line 2), got <eof>")

		assert(getParseError([[

			local a: (number, number) -> (
				string
		]]) == "Expected ')' (to close '(' at line 2), got <eof>")

		assert(getParseError([[

			local a: (number, number)
		]]) == "Expected '->' when parsing function type, got <eof>")
	
		assert(getParseError([[

			local a: (number, number
		]]) == "Expected ')' (to close '(' at line 2), got <eof>")

		assert(getParseError([[

			local a: {foo: string,
		]]) == "Expected identifier when parsing table field, got <eof>")

		assert(getParseError([[

			local a: {foo: string
		]]) == "Expected '}' (to close '{' at line 2), got <eof>")

		assert(getParseError([[

			local a: { [string]: number, [number]: string }
		]]) == "Cannot have more than one table indexer")

		assert(getParseError([[

			type T = <a>foo
		]]) == "Expected '(' when parsing function parameters, got 'foo'")
	end,
	mixed_intersection_and_union_not_allowed = function()
		matchParseError("type A = number & string | boolean", "Mixing union and intersection types is not allowed; consider wrapping in parentheses.")
	end,
	mixed_intersection_and_union_allowed_when_parenthesized = function()
		local success, result = pcall(parse, "type A = (number & string) | boolean")
		if not success then
			error((result :: any):what())
		end
	end,
	cannot_write_multiple_values_in_type_groups = function()
		matchParseError("type F = ((string, number))", "Expected '->' when parsing function type, got ')'")
		matchParseError("type F = () -> ((string, number))", "Expected '->' when parsing function type, got ')'")
	end,
	type_alias_error_messages = function()
		assert(getParseError("type 5 = number") == "Expected identifier when parsing type name, got '5'")
		assert(getParseError("type A") == "Expected '=' when parsing type alias, got <eof>")
		assert(getParseError("type A<") == "Expected identifier, got <eof>")
		assert(getParseError("type A<B") == "Expected '>' (to close '<' at column 7), got <eof>")
	end,
	type_assertion_expression = function()
		parse([[

			local a = something() :: any
		]])
	end,
	-- The bug that motivated this test was an infinite loop.
	-- TODO: Set a timer and crash if the timeout is exceeded.
	last_line_does_not_have_to_be_blank = function()
		parse("-- print('hello')")
	end,
	type_assertion_expression_binds_tightly = function()
		local stat = parse([[

			local a = one :: any + two :: any
		]])

		assert(stat)

		local block = stat:as(AstStatBlock)
		assert(block)
		assert(1 == #block.body)

		local statLocal = block.body[1]:as(AstStatLocal)
		assert(statLocal)
		assert(1 == #statLocal.values)

		local bin = statLocal.values[1]:as(AstExprBinary)
		assert(bin)

		assert(bin.left:as(AstExprTypeAssertion))
		assert(bin.right:as(AstExprTypeAssertion))
	end,
	mode_is_unset_if_no_hot_comment = function()
		local result = parseEx("print('Hello World!')")
		assert(result.hotcomments:empty())
	end,
	sense_hot_comment_on_first_line = function()
		local options = ParseOptions.new()
		options.captureComments = true

		local result = parseEx("   --!strict ", options)
		local mode = parseMode(result.hotcomments)
		assert(mode)
		assert(mode == ParseOptions.Mode.Strict)
	end,
	non_header_hot_comments = function()
		local options = ParseOptions.new()
		options.captureComments = true

		local result = parseEx("do end --!strict", options)
		local mode = parseMode(result.hotcomments)
		assert(mode == nil)
	end,
	stop_if_line_ends_with_hyphen = function()
		local success = pcall(parse, "   -")
		assert(success == false)
	end,
	nonstrict_mode = function()
		local options = ParseOptions.new()
		options.captureComments = true

		local result = parseEx("--!nonstrict", options)
		assert(result.errors:empty())
		local mode = parseMode(result.hotcomments)
		assert(mode)
		assert(mode == ParseOptions.Mode.Nonstrict)
	end,
	nocheck_mode = function()
		local options = ParseOptions.new()
		options.captureComments = true

		local result = parseEx("--!nocheck", options)
		assert(result.errors:empty())
		local mode = parseMode(result.hotcomments)
		assert(mode)
		assert(mode == ParseOptions.Mode.NoCheck)
	end,
	vertical_space = function()
		local result = parseEx("a()\vb()")
		assert(result.errors:empty())
	end,
	parse_error_type_name = function()
		assert(getParseError([[

			local a: Foo.=
		]]) == "Expected identifier when parsing field name, got '='")
	end,
	parse_numbers_decimal = function()
		local stat = parse("return 1, .5, 1.5, 1e-5, 1.5e-5, 12_345.1_25")
		assert(stat)

		local str = assert(assert(stat:as(AstStatBlock)).body[1]:as(AstStatReturn))
		assert(#str.list == 6)
		assert(assert(str.list[1]:as(AstExprConstantNumber)).value == 1)
		assert(assert(str.list[2]:as(AstExprConstantNumber)).value == 0.5)
		assert(assert(str.list[3]:as(AstExprConstantNumber)).value == 1.5)
		assert(assert(str.list[4]:as(AstExprConstantNumber)).value == 1e-5)
		assert(assert(str.list[5]:as(AstExprConstantNumber)).value == 1.5e-5)
		assert(assert(str.list[6]:as(AstExprConstantNumber)).value == 12345.125)
	end,
	parse_numbers_hexadecimal = function()
		local stat = parse("return 0xab, 0XAB05, 0xff_ff, 0xffffffffffffffff")
		assert(stat)
		
		local str = assert(assert(stat:as(AstStatBlock)).body[1]:as(AstStatReturn))
		assert(#str.list == 4)
		assert(assert(str.list[1]:as(AstExprConstantNumber)).value == 0xab)
		assert(assert(str.list[2]:as(AstExprConstantNumber)).value == 0XAB05)
		assert(assert(str.list[3]:as(AstExprConstantNumber)).value == 0xff_ff)
		assert(assert(str.list[4]:as(AstExprConstantNumber)).value == 18446744073709551616)
	end,
	parse_numbers_binary = function()
		local stat = parse("return 0b1, 0b0, 0b101010, 0b1111111111111111111111111111111111111111111111111111111111111111")
		assert(stat)

		local str = assert(assert(stat:as(AstStatBlock)).body[1]:as(AstStatReturn))
		assert(#str.list == 4)
		assert(assert(str.list[1]:as(AstExprConstantNumber)).value == 1)
		assert(assert(str.list[2]:as(AstExprConstantNumber)).value == 0)
		assert(assert(str.list[3]:as(AstExprConstantNumber)).value == 42)
		assert(assert(str.list[4]:as(AstExprConstantNumber)).value == 18446744073709551616)
	end,
	parse_numbers_error = function()
		assert(getParseError("return 0b123") == "Malformed number")
		assert(getParseError("return 123x") == "Malformed number")
		assert(getParseError("return 0xg") == "Malformed number")
		assert(getParseError("return 0x0x123") == "Malformed number")
		assert(getParseError("return 0xffffffffffffffffffffllllllg") == "Malformed number")
		assert(getParseError("return 0x0xffffffffffffffffffffffffffff") == "Malformed number")
	end,
	break_return_not_last_error = function()
		assert(getParseError("return 0 print(5)") == "Expected <eof>, got 'print'")
		assert(getParseError("while true do break print(5) end") == "Expected 'end' (to close 'do' at column 12), got 'print'")
	end,
	error_on_unicode = function()
		assert(getParseError([[

			local ☃ = 10
		]]) == "Expected identifier when parsing variable name, got Unicode character U+2603")
	end,
	allow_unicode_in_string = function()
		local result = parseEx("local snowman = \"☃\"")
		assert(result.errors:empty())
	end,
	error_on_confusable = function()
		assert(getParseError([[

			local pi = 3․13
		]]) == "Expected identifier when parsing expression, got Unicode character U+2024 (did you mean '.'?)")
	end,
	error_on_non_utf8_sequence = function()
		local expected = "Expected identifier when parsing expression, got invalid UTF-8 sequence"

		assert(getParseError("local pi = \xFF!") == expected)
		assert(getParseError("local pi = \xE2!") == expected)
	end,
	lex_broken_unicode = function()
		local testInput = "\xFF\xFE☃․"

		local nameTable = AstNameTable.new()
		local lexer = Lexer.new(testInput, #testInput, nameTable)
		local lexeme = lexer:current()

		lexeme = lexer:next()
		assert(lexeme.type == Lexeme.Type.BrokenUnicode)
		assert(lexeme.codepoint == 0)
		assert(lexeme.location :: any == Location.new(Position.new(0, 0), Position.new(0, 1)))

		lexeme = lexer:next()
		assert(lexeme.type == Lexeme.Type.BrokenUnicode)
		assert(lexeme.codepoint == 0)
		assert(lexeme.location :: any == Location.new(Position.new(0, 1), Position.new(0, 2)))

		lexeme = lexer:next()
		assert(lexeme.type == Lexeme.Type.BrokenUnicode)
		assert(lexeme.codepoint == 0x2603)
		assert(lexeme.location :: any == Location.new(Position.new(0, 2), Position.new(0, 5)))

		lexeme = lexer:next()
		assert(lexeme.type == Lexeme.Type.BrokenUnicode)
		assert(lexeme.codepoint == 0x2024)
		assert(lexeme.location :: any == Location.new(Position.new(0, 5), Position.new(0, 8)))

		lexeme = lexer:next()
		assert(lexeme.type == Lexeme.Type.Eof)
	end,
	parse_continue = function()
		local stat = parse([[

			while true do
				continue()
				continue = 5
				continue, continue = continue
				continue
        	end
		]])

		assert(stat)

		local block = stat:as(AstStatBlock)
		assert(block)
		assert(1 == #block.body)

		local wb = block.body[1]:as(AstStatWhile)
		assert(wb)

		local wblock = wb.body:as(AstStatBlock)
		assert(wblock)
		assert(4 == #wblock.body)

		assert(wblock.body[1]:is(AstStatExpr))
		assert(wblock.body[2]:is(AstStatAssign))
		assert(wblock.body[3]:is(AstStatAssign))
		assert(wblock.body[4]:is(AstStatContinue))
	end,
	continue_not_last_error = function()
		assert(getParseError("while true do continue print(5) end") == "Expected 'end' (to close 'do' at column 12), got 'print'")
	end,
	parse_export_type = function()
		local stat = parse([[

			export()
			export = 5
			export, export = export
			export type A = number
			type A = number
		]])
		assert(stat)

		local block = stat:as(AstStatBlock)
		assert(block)
		assert(5 == #block.body)

		assert(block.body[1]:is(AstStatExpr))
		assert(block.body[2]:is(AstStatAssign))
		assert(block.body[3]:is(AstStatAssign))
		assert(block.body[4]:is(AstStatTypeAlias))
		assert(block.body[5]:is(AstStatTypeAlias))
	end,
	export_is_an_identifier_only_when_followed_by_type = function()
		Try(function()
			parse([[

				export function a() end
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert("Incomplete statement: expected assignment or a function call" == e:getErrors():front():getMessage())
		end)
	end,
	incomplete_statement_error = function()
		assert(getParseError("fiddlesticks") == "Incomplete statement: expected assignment or a function call")
	end,
	parse_compound_assignment = function()
		local block = parse([[

			a += 5
		]])

		assert(block)
		assert(#block.body == 1)
		assert(block.body[1]:is(AstStatCompoundAssign))
		assert(assert(block.body[1]:as(AstStatCompoundAssign)).op == AstExprBinary.Op.Add)
	end,
	parse_compound_assignment_error_call = function()
		Try(function()
			parse([[

				a() += 5
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert("Expected identifier when parsing expression, got '+='" == e:getErrors():front():getMessage())
		end)
	end,
	parse_compound_assignment_error_not_lvalue = function()
		Try(function()
			parse([[

				(a) += 5
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert("Assigned expression must be a variable or a field" == e:getErrors():front():getMessage())
		end)
	end,
	parse_compound_assignment_error_multiple = function()
		Try(function()
			parse([[

				a, b += 5
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert("Expected '=' when parsing assignment, got '+='" == e:getErrors():front():getMessage())
		end)
	end,
	parse_interpolated_string_double_brace_begin = function()
		local success, e = pcall(parse, [[

			_ = `{{oops}}`
		]])
		if success then
			error("Expected ParseErrors to be thrown")
		end
		assert("Double braces are not permitted within interpolated strings; did you mean '\\{'?" == (e :: any):getErrors():front():getMessage())
	end,
	parse_interpolated_string_double_brace_mid = function()
		local success, e = pcall(parse, [[

			_ = `{nice} {{oops}}`
		]])
		if success then
			error("Expected ParseErrors to be thrown")
		end
		assert("Double braces are not permitted within interpolated strings; did you mean '\\{'?" == (e :: any):getErrors():front():getMessage())
	end,
	parse_interpolated_string_without_end_brace = function()
		local function columnOfEndBraceError(code: string): number
			local column: number
			Try(function()
				parse(code)
				error("Expected ParseErrors to be thrown")
			end):catch(function(e: ParseErrors)
				assert(e:getErrors():size() == 1)

				local error = e:getErrors():front()
				assert("Malformed interpolated string; did you forget to add a '}'?" == error:getMessage())
				column = error:getLocation().begin.column
			end)
			return column
		end

		-- This makes sure that the error is coming from the brace itself
		assert(columnOfEndBraceError("_ = `{a`") == columnOfEndBraceError("_ = `{abcdefg`"))
		assert(columnOfEndBraceError("_ = `{a`") ~= columnOfEndBraceError("_ =       `{a`"))
	end,
	parse_interpolated_string_without_end_brace_in_table = function()
		Try(function()
			parse([[

				_ = { `{a` }
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert(e:getErrors():size() == 2)

			assert("Malformed interpolated string; did you forget to add a '}'?" == e:getErrors():front():getMessage())
			assert("Expected '}' (to close '{' at line 2), got <eof>" == e:getErrors():back():getMessage())
		end)
	end,
	parse_interpolated_string_mid_without_end_brace_in_table = function()
		Try(function()
			parse([[

				_ = { `x {"y"} {z` }
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert(e:getErrors():size() == 2)

			assert("Malformed interpolated string; did you forget to add a '}'?" == e:getErrors():front():getMessage())
			assert("Expected '}' (to close '{' at line 2), got <eof>" == e:getErrors():back():getMessage())
		end)
	end,
	parse_interpolated_string_as_type_fail = function()
		Try(function()
			parse([[

				local a: `what` = `???`
				local b: `what {"the"}` = `???`
				local c: `what {"the"} heck` = `???`
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(parseErrors: ParseErrors)
			assert(parseErrors:getErrors():size() == 3)

			for _, error in parseErrors:getErrors():data() do
				assert(error:getMessage() == "Interpolated string literals cannot be used as types")
			end
		end)
	end,
	parse_interpolated_string_call_without_parens = function()
		Try(function()
			parse([[

				_ = print `{42}`
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert("Expected identifier when parsing expression, got `{" == e:getErrors():front():getMessage())
		end)
	end,
	parse_interpolated_string_without_expression = function()
		Try(function()
			parse([[

				print(`{}`)
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert("Malformed interpolated string, expected expression inside '{}'" == e:getErrors():front():getMessage())
		end)

		Try(function()
			parse([[

				print(`{}{1}`)
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert("Malformed interpolated string, expected expression inside '{}'" == e:getErrors():front():getMessage())
		end)
	end,
	parse_interpolated_string_malformed_escape = function()
		Try(function()
			parse([[

				local a = `???\xQQ {1}`
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert("Interpolated string literal contains malformed escape sequence" == e:getErrors():front():getMessage())
		end)
	end,
	parse_interpolated_string_weird_token = function()
		Try(function()
			parse([[

				local a = `??? {42 !!}`
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert("Malformed interpolated string, got '!'" == e:getErrors():front():getMessage())
		end)
	end,
	parse_nesting_based_end_detection = function()
		Try(function()
			parse([[-- i am line 1
function BottomUpTree(item, depth)
	if depth > 0 then
		local i = item + item
		depth = depth - 1
		local left, right = BottomUpTree(i-1, depth), BottomUpTree(i, depth)
		return { item, left, right }
	else
		return { item }
end

function ItemCheck(tree)
	if tree[2] then
		return tree[1] + ItemCheck(tree[2]) - ItemCheck(tree[3])
	else
		return tree[1]
	end
end
		]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert("Expected 'end' (to close 'function' at line 2), got <eof>; did you forget to close 'else' at line 8?"
				== e:getErrors():front():getMessage())
		end)
	end,
	parse_nesting_based_end_detection_single_line = function()
		Try(function()
			parse([[-- i am line 1
function ItemCheck(tree)
	if tree[2] then return tree[1] + ItemCheck(tree[2]) - ItemCheck(tree[3]) else return tree[1]
end

function BottomUpTree(item, depth)
	if depth > 0 then
		local i = item + item
		depth = depth - 1
		local left, right = BottomUpTree(i-1, depth), BottomUpTree(i, depth)
		return { item, left, right }
	else
		return { item }
	end
end
		]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert("Expected 'end' (to close 'function' at line 2), got <eof>; did you forget to close 'else' at line 3?"
				== e:getErrors():front():getMessage())
		end)
	end,
	parse_nesting_based_end_detection_local_repeat = function()
		Try(function()
			parse([[-- i am line 1
repeat
	print(1)
	repeat
		print(2)
	print(3)
until false
		]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert("Expected 'until' (to close 'repeat' at line 2), got <eof>; did you forget to close 'repeat' at line 4?"
				== e:getErrors():front():getMessage())
		end)
	end,
	parse_nesting_based_end_detection_local_function = function()
		Try(function()
			parse([[-- i am line 1
local function BottomUpTree(item, depth)
	if depth > 0 then
		local i = item + item
		depth = depth - 1
		local left, right = BottomUpTree(i-1, depth), BottomUpTree(i, depth)
		return { item, left, right }
	else
		return { item }
end

local function ItemCheck(tree)
	if tree[2] then
		return tree[1] + ItemCheck(tree[2]) - ItemCheck(tree[3])
	else
		return tree[1]
	end
end
		]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert("Expected 'end' (to close 'function' at line 2), got <eof>; did you forget to close 'else' at line 8?"
				== e:getErrors():front():getMessage())
		end)
	end,
	parse_nesting_based_end_detection_failsafe_earlier = function()
		Try(function()
			parse([[-- i am line 1
local function ItemCheck(tree)
	if tree[2] then
		return tree[1] + ItemCheck(tree[2]) - ItemCheck(tree[3])
	else
		return tree[1]
	end
end

local function BottomUpTree(item, depth)
	if depth > 0 then
		local i = item + item
		depth = depth - 1
		local left, right = BottomUpTree(i-1, depth), BottomUpTree(i, depth)
		return { item, left, right }
	else
		return { item }
	end
		]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert("Expected 'end' (to close 'function' at line 10), got <eof>" == e:getErrors():front():getMessage())
		end)
	end,
	parse_nesting_based_end_detection_nested = function()
		Try(function()
			parse([[-- i am line 1
function stringifyTable(t)
	local entries = {}
	for k, v in pairs(t) do
		-- if we find a nested table, convert that recursively
		if type(v) == "table" then
			v = stringifyTable(v)
		else
			v = tostring(v)
		k = tostring(k)

		-- add another entry to our stringified table
		entries[#entries + 1] = ("s = s"):format(k, v)
    end

	-- the memory location of the table
	local id = tostring(t):sub(8)

	return ("{s}@s"):format(table.concat(entries, ", "), id)
end
		]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert("Expected 'end' (to close 'function' at line 2), got <eof>; did you forget to close 'else' at line 8?"
				== e:getErrors():front():getMessage())
		end)
	end,
	parse_error_table_literal = function()
		Try(function()
			parse([[

function stringifyTable(t)
    local foo = (name = t)
    return foo
end
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert(
				"Expected ')' (to close '(' at column 17), got '='; did you mean to use '{' when defining a table?" == e:getErrors():front():getMessage())
		end)
	end,
	parse_error_function_call = function()
		Try(function()
			parse([[

function stringifyTable(t)
    local foo = t:Parse 2
    return foo
end
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert(e:getErrors():front():getLocation().begin.line == 2)
			assert("Expected '(', '{' or <string> when parsing function call, got '2'" == e:getErrors():front():getMessage())
		end)
	end,
	parse_error_function_call_newline = function()
		Try(function()
			parse([[

function stringifyTable(t)
    local foo = t:Parse
    return foo
end
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert(e:getErrors():front():getLocation().begin.line == 2)
			assert("Expected function call arguments after '('" == e:getErrors():front():getMessage())
		end)
	end,
	parse_error_with_too_many_nested_type_group = function()
		ScopedVariable({LuauRecursionLimit = 10} :: FV, function()
			matchParseError(
				"function f(): ((((((((((Fail)))))))))) end", "Exceeded allowed recursion depth; simplify your type annotation to make the code compile")
	
			matchParseError("function f(): () -> () -> () -> () -> () -> () -> () -> () -> () -> () -> () end",
				"Exceeded allowed recursion depth; simplify your type annotation to make the code compile")
		
			matchParseError("local t: {a: {b: {c: {d: {e: {f: {g: {h: {i: {j: {}}}}}}}}}}}",
				"Exceeded allowed recursion depth; simplify your type annotation to make the code compile")
		
			matchParseError("local f: ((((((((((Fail))))))))))", "Exceeded allowed recursion depth; simplify your type annotation to make the code compile")
		
			matchParseError("local t: a & (b & (c & (d & (e & (f & (g & (h & (i & (j & nil)))))))))",
				"Exceeded allowed recursion depth; simplify your type annotation to make the code compile")
		end)
	end,
	can_parse_complex_unions_successfully = function()
		ScopedVariable({LuauRecursionLimit = 10, LuauTypeLengthLimit = 10} :: FV, function()
				parse([[

local f:
() -> ()
|
() -> ()
|
{a: number}
|
{b: number}
|
((number))
|
((number))
|
(a & (b & nil))
|
(a & (b & nil))
]])

		parse([[

local f: a? | b? | c? | d? | e? | f? | g? | h?
]])

		matchParseError("local t: a & b & c & d & e & f & g & h & i & j & nil",
			"Exceeded allowed type length; simplify your type annotation to make the code compile")
		end)
	end,
	parse_error_with_too_many_nested_if_statements = function()
		ScopedVariable({LuauRecursionLimit = 10} :: FV, function()
			matchParseErrorPrefix([[

				function f() if true then if true then if true then if true then if true then if true then if true then if true then if true
				then if true then if true then end end end end end end end end end end end end
			]], "Exceeded allowed recursion depth;")
		end)
	end,
	parse_error_with_too_many_changed_elseif_statements = function()
		ScopedVariable({LuauRecursionLimit = 10} :: FV, function()
			matchParseErrorPrefix([[

				function f() if false then elseif false then elseif false then elseif false then elseif false then elseif false then elseif
				false then elseif false then elseif false then elseif false then elseif false then end end
			]], "Exceeded allowed recursion depth;")
		end)
	end,
	parse_error_with_too_many_nested_ifelse_expressions1 = function()
		ScopedVariable({LuauRecursionLimit = 10} :: FV, function()
			matchParseError([[

				function f() return if true then 1 elseif true then 2 elseif true then 3 elseif true then 4 elseif true then 5 elseif true then
				6 elseif true then 7 elseif true then 8 elseif true then 9 elseif true then 10 else 11 end
			]], "Exceeded allowed recursion depth; simplify your expression to make the code compile")
		end)
	end,
	parse_error_with_too_many_nested_ifelse_expressions2 = function()
		ScopedVariable({LuauRecursionLimit = 10} :: FV, function()
			matchParseError([[

				function f() return if if if if if if if if if if true then false else true then false else true then false else true then false else true
				then false else true then false else true then false else true then false else true then false else true then 1 else 2 end
			]], "Exceeded allowed recursion depth; simplify your expression to make the code compile")
		end)
	end,
	unparenthesized_function_return_type_list = function()
		matchParseError(
			"function foo(): string, number end", "Expected a statement, got ','; did you forget to wrap the list of return types in parentheses?"
		)
		matchParseError(
			"function foo(): (number) -> string, string",
        	"Expected a statement, got ','; did you forget to wrap the list of return types in parentheses?"
		)

		-- Will throw if the parse fails
		parse([[

			type Vector3MT = {
            	__add: (Vector3MT, Vector3MT) -> Vector3MT,
            	__mul: (Vector3MT, Vector3MT|number) -> Vector3MT
        	}
		]])
	end,
	short_array_types = function()
		local stat = parse([[

			local n: {string}
		]])

		assert(stat)
		local statLocal = assert(stat.body[1]:as(AstStatLocal))
		local annotation = assert(statLocal.vars[1].annotation):as(AstTypeTable)
		assert(annotation)
		assert(#annotation.props == 0)
		assert(annotation.indexer)
		assert(annotation.indexer.indexType:is(AstTypeReference))
		assert(assert(annotation.indexer.indexType:as(AstTypeReference)).name.value == "number")
		assert(annotation.indexer.resultType:is(AstTypeReference))
		assert(assert(annotation.indexer.resultType:as(AstTypeReference)).name.value == "string")
	end,
	short_array_types_must_be_alone = function()
		matchParseError("local n: {string, number}", "Expected '}' (to close '{' at column 10), got ','")
    	matchParseError("local n: {[number]: string, number}", "Expected ':' when parsing table field, got '}'")
    	matchParseError("local n: {x: string, number}", "Expected ':' when parsing table field, got '}'")
    	matchParseError("local n: {x: string, nil}", "Expected identifier when parsing table field, got 'nil'")
	end,
	short_array_types_do_not_break_field_names = function()
		local stat = parse([[

			local n: {string: number}
		]])

		assert(stat)
		local statLocal = assert(stat.body[1]:as(AstStatLocal))
		local annotation = assert(statLocal.vars[1].annotation):as(AstTypeTable)
		assert(annotation)
		assert(#annotation.props == 1)
		assert(not annotation.indexer)
		assert(annotation.props[1].name.value == "string")
		assert(annotation.props[1].type:is(AstTypeReference))
		assert(assert(annotation.props[1].type:as(AstTypeReference)).name.value == "number")
	end,
	short_array_types_are_not_field_names_when_complex = function()
		matchParseError("local n: {string | number: number}", "Expected '}' (to close '{' at column 10), got ':'")
	end,
	nil_can_not_be_a_field_name = function()
		matchParseError("local n: {nil: number}", "Expected '}' (to close '{' at column 10), got ':'")
	end,
	string_literal_call = function()
		local stat = parse("do foo 'bar' end")
		assert(stat)
		local dob = assert(stat.body[1]:as(AstStatBlock))
		local stc = dob.body[1]:as(AstStatExpr)
		assert(stc)
		local ec = assert(stc.expr:as(AstExprCall))
		assert(#ec.args == 1)
		local arg = ec.args[1]:as(AstExprConstantString)
		assert(arg)
		assert(arg.value == "bar")
	end,
	multiline_strings_newlines = function()
		local stat = parse("return [=[\nfoo\r\nbar\n\nbaz\n]=]")
		assert(stat)

		local ret = stat.body[1]:as(AstStatReturn)
		assert(ret)

		local str = ret.list[1]:as(AstExprConstantString)
		assert(str)
		assert(str.value == "foo\nbar\n\nbaz\n")
	end,
	string_literals_escape = function()
		local stat = parse([[

return
"foo\n\r",
"foo\0324",
"foo\x204",
"foo\u{20}",
"foo\u{0451}"
]])

		assert(stat)

		local ret = stat.body[1]:as(AstStatReturn)
		assert(ret)
		assert(#ret.list == 5)

		local str = ret.list[1]:as(AstExprConstantString)
		assert(str)
		assert(str.value == "foo\n\r")

		local str = ret.list[2]:as(AstExprConstantString)
		assert(str)
		assert(str.value == "foo 4")

		local str = ret.list[3]:as(AstExprConstantString)
		assert(str)
		assert(str.value == "foo 4")

		local str = ret.list[4]:as(AstExprConstantString)
		assert(str)
		assert(str.value == "foo ")

		local str = ret.list[5]:as(AstExprConstantString)
		assert(str)
		assert(str.value == "foo\xd1\x91")
	end,
	string_literals_escape_newline = function()
		local stat = parse("return \"foo\\z\n   bar\", \"foo\\\n    bar\", \"foo\\\r\nbar\"")

		assert(stat)

		local ret = stat.body[1]:as(AstStatReturn)
		assert(ret)
		assert(#ret.list == 3)

		local str = ret.list[1]:as(AstExprConstantString)
		assert(str)
		assert(str.value == "foobar")

		local str = ret.list[2]:as(AstExprConstantString)
		assert(str)
		assert(str.value == "foo\n    bar")
		
		local str = ret.list[3]:as(AstExprConstantString)
		assert(str)
		assert(str.value == "foo\nbar")
	end,
	string_literals_escapes = function()
		local stat = parse([[

return
"\xAB",
"\u{2024}",
"\121",
"\1x",
"\t",
"\n"
]])

		assert(stat)

		local ret = stat.body[1]:as(AstStatReturn)
		assert(ret)
		assert(#ret.list == 6)

		local str = ret.list[1]:as(AstExprConstantString)
		assert(str)
		assert(str.value == "\xAB")

		local str = ret.list[2]:as(AstExprConstantString)
		assert(str)
		assert(str.value == "\xE2\x80\xA4")

		local str = ret.list[3]:as(AstExprConstantString)
		assert(str)
		assert(str.value == "\x79")

		local str = ret.list[4]:as(AstExprConstantString)
		assert(str)
		assert(str.value == "\x01x")

		local str = ret.list[5]:as(AstExprConstantString)
		assert(str)
		assert(str.value == "\t")

		local str = ret.list[6]:as(AstExprConstantString)
		assert(str)
		assert(str.value == "\n")
	end,
	parse_error_broken_comment = function()
		local expected = "Expected identifier when parsing expression, got unfinished comment"

		matchParseError("--[[unfinished work", expected)
		matchParseError("--!strict\n--[[unfinished work", expected)
		matchParseError("local x = 1 --[[unfinished work", expected)
	end,
	string_literals_escapes_broken = function()
		local expected = "String literal contains malformed escape sequence"

		matchParseError("return \"\\u{\"", expected)
		matchParseError("return \"\\u{FO}\"", expected)
		matchParseError("return \"\\u{123456789}\"", expected)
		matchParseError("return \"\\359\"", expected)
		matchParseError("return \"\\xFO\"", expected)
		matchParseError("return \"\\xF\"", expected)
		matchParseError("return \"\\x\"", expected)
	end,
	string_literals_broken = function()
		matchParseError("return \"", "Malformed string; did you forget to finish it?")
		matchParseError("return \"\\", "Malformed string; did you forget to finish it?")
		matchParseError("return \"\r\r", "Malformed string; did you forget to finish it?")
	end,
	number_literals = function()
		local stat = parse([[

return
1,
1.5,
.5,
12_34_56,
0x1234,
 0b010101
]])

		assert(stat)

		local ret = stat.body[1]:as(AstStatReturn)
		assert(ret)
		assert(#ret.list == 6)

		local num = ret.list[1]:as(AstExprConstantNumber)
		assert(num)
		assert(num.value == 1.0)

		local num = ret.list[2]:as(AstExprConstantNumber)
		assert(num)
		assert(num.value == 1.5)

		local num = ret.list[3]:as(AstExprConstantNumber)
		assert(num)
		assert(num.value == 0.5)

		local num = ret.list[4]:as(AstExprConstantNumber)
		assert(num)
		assert(num.value == 123456)

		local num = ret.list[5]:as(AstExprConstantNumber)
		assert(num)
		assert(num.value == 0x1234)

		local num = ret.list[6]:as(AstExprConstantNumber)
		assert(num)
		assert(num.value == 0x15)
	end,
	end_extent_of_functions_unions_and_intersections = function()
		local block = parse([[

        type F = (string) -> string
        type G = string | number | boolean
        type H = string & number & boolean
        print('hello')
		]])

		assert(block)
		assert(4 == #block.body)
		assert(Position.new(1, 35) :: any == block.body[1].location.finish)
		assert(Position.new(2, 42) :: any == block.body[2].location.finish)
		assert(Position.new(3, 42) :: any == block.body[3].location.finish)
	end,
	end_extent_doesnt_consume_comments = function()
		local block = parse([[

        type F = number
        --comment
        print('hello')
		]])

		assert(block)
		assert(2 == #block.body)
		assert(Position.new(1, 23) :: any == block.body[1].location.finish)
	end,
	end_extent_doesnt_consume_comments_even_with_capture = function()
		-- Same should hold when comments are captured
		local opts = ParseOptions.new()
		opts.captureComments = true

		local block = parse([[

        type F = number
        --comment
        print('hello')
		]], opts)

		assert(block)
		assert(2 == #block.body)
		assert(Position.new(1, 23) :: any == block.body[1].location.finish)
	end,
	parse_error_loop_control = function()
		matchParseError("break", "break statement must be inside a loop")
		matchParseError("repeat local function a() break end until false", "break statement must be inside a loop")
		matchParseError("continue", "continue statement must be inside a loop")
		matchParseError("repeat local function a() continue end until false", "continue statement must be inside a loop")
	end,
	parse_error_confusing_function_call = function()
		local result1 = matchParseError([[

			function add(x, y) return x + y end
			add
			(4, 7)
		]], "Ambiguous syntax: this looks like an argument list for a function call, but could also be a start of new statement; use ';' to separate \z
		statements")

		assert(result1.errors:size() == 1)

		local result2 = matchParseError([[

			function add(x, y) return x + y end
			local f = add
			(f :: any)['x'] = 2
		]], "Ambiguous syntax: this looks like an argument list for a function call, but could also be a start of new statement; use ';' to separate \z
		statements")

		assert(result2.errors:size() == 1)

		local result3 = matchParseError([[

			local x = {}
			function x:add(a, b) return a + b end
			x:add
			(1, 2)
		]], "Ambiguous syntax: this looks like an argument list for a function call, but could also be a start of new statement; use ';' to separate \z
		statements")

		assert(result3.errors:size() == 1)

		local result4 = matchParseError([[

			local t = {}
			function f() return t end
			t.x, (f)
			().y = 5, 6
		]], "Ambiguous syntax: this looks like an argument list for a function call, but could also be a start of new statement; use ';' to separate \z
		statements")

		assert(result4.errors:size() == 1)
	end,
	parse_error_varargs = function()
		matchParseError("function add(x, y) return ... end", "Cannot use '...' outside of a vararg function")
	end,
	parse_error_assignment_lvalue = function()
		matchParseError([[

			local a, b
			(2), b = b, a
		]], "Assigned expression must be a variable or a field")

		matchParseError([[

			local a, b
			a, (3) = b, a
		]], "Assigned expression must be a variable or a field")
	end,
	parse_error_type_annotation = function()
		matchParseError("local a : 2 = 2", "Expected type, got '2'")
	end,
	parse_error_missing_type_annotation = function()
		local result = tryParse("local x:")
		assert(result.errors:size() == 1)
		local begin = result.errors:get(1):getLocation().begin
		local finish = result.errors:get(1):getLocation().finish
		assert(begin.line == finish.line)
		local width = finish.column - begin.column
		assert(width == 0)
		assert(result.errors:get(1):getMessage() == "Expected type, got <eof>")

		local result = tryParse("local x:=42")
		assert(result.errors:size() == 1)
		local begin = result.errors:get(1):getLocation().begin
		local finish = result.errors:get(1):getLocation().finish
		assert(begin.line == finish.line)
		local width = finish.column - begin.column
		assert(width == 1) -- Length of `=`
		assert(result.errors:get(1):getMessage() == "Expected type, got '='")

		local result = tryParse("function func():end")
		assert(result.errors:size() == 1)
		local begin = result.errors:get(1):getLocation().begin
		local finish = result.errors:get(1):getLocation().finish
		assert(begin.line == finish.line)
		local width = finish.column - begin.column
		assert(width == 3) -- Length of `end`
		assert(result.errors:get(1):getMessage() == "Expected type, got 'end'")
	end,
	parse_declarations = function()
		local stat = parseEx([[

			declare foo: number
			declare function bar(x: number): string
			declare function var(...: any)
		]]).root

		assert(stat)
		assert(#stat.body == 3)

		local global = stat.body[1]:as(AstStatDeclareGlobal)
		assert(global)
		assert(global.name.value == "foo")
		assert(global.type)

		local func = stat.body[2]:as(AstStatDeclareFunction)
		assert(func)
		assert(func.name.value == "bar")
		assert(#func.params.types == 1)
		assert(#func.returnTypes.types == 1)

		local varFunc = stat.body[3]:as(AstStatDeclareFunction)
		assert(varFunc)
		assert(varFunc.name.value == "var")
		assert(varFunc.params.tailType)

		matchParseError("declare function foo(x)", "All declaration parameters must be annotated")
		matchParseError("declare foo", "Expected ':' when parsing global variable declaration, got <eof>")
	end,
	parse_class_declarations = function()
		local stat = parseEx([[

			declare class Foo
				prop: number
				function method(self, foo: number): string
			end

			declare class Bar extends Foo
				prop2: string
			end
		]]).root

		assert(stat)
		assert(#stat.body == 2)

		local declaredClass = stat.body[1]:as(AstStatDeclareClass)
		assert(declaredClass)
		assert(declaredClass.name.value == "Foo")
		assert(not declaredClass.superName)

		assert(#declaredClass.props == 2)

		local prop = declaredClass.props[1]
		assert(prop.name.value == "prop")
		assert(prop.ty:is(AstTypeReference))

		local method = declaredClass.props[2]
		assert(method.name.value == "method")
		assert(method.ty:is(AstTypeFunction))

		local subclass = stat.body[2]:as(AstStatDeclareClass)
		assert(subclass)
		assert(subclass.superName)
		assert(subclass.name.value == "Bar")
		assert(subclass.superName.value == "Foo")

		assert(#subclass.props == 1)
		local prop2 = subclass.props[1]
		assert(prop2.name.value == "prop2")
		assert(prop2.ty:is(AstTypeReference))
	end,
	class_method_properties = function()
		local p1 = matchParseError([[

			declare class Foo
				-- method's first parameter must be 'self'
				function method(foo: number)
				function method2(self)
			end
		]], "'self' must be present as the unannotated first parameter")

		assert(1 == #assert(p1.root).body)

		local klass = p1.root.body[1]:as(AstStatDeclareClass)
		assert(klass)

		assert(2 == #klass.props)

		local p2 = matchParseError([[

			declare class Foo
				function method(self, foo)
				function method2()
			end
		]], "All declaration parameters aside from 'self' must be annotated")

		assert(1 == #assert(p2.root).body)

		local klass2 = p2.root.body[1]:as(AstStatDeclareClass)
		assert(klass2)
		
		assert(2 == #klass2.props)
	end,
	class_indexer = function()
		local stat = parseEx([[

			declare class Foo
				prop: boolean
				[string]: number
			end
		]]).root

		assert(stat)
		assert(#stat.body == 1)

		local declaredClass = stat.body[1]:as(AstStatDeclareClass)
		assert(declaredClass)
		assert(declaredClass.indexer)
		assert(declaredClass.indexer.indexType:is(AstTypeReference))
		assert(assert(declaredClass.indexer.indexType:as(AstTypeReference)).name.value == "string")
		assert(declaredClass.indexer.resultType:is(AstTypeReference))
		assert(assert(declaredClass.indexer.resultType:as(AstTypeReference)).name.value == "number")

		local p1 = matchParseError([[

			declare class Foo
				[string]: number
				-- can only have one indexer
				[number]: number
			end
		]], "Cannot have more than one class indexer")

		assert(1 == #assert(p1.root).body)

		local klass = p1.root.body[1]:as(AstStatDeclareClass)
		assert(klass)
		assert(klass.indexer)
	end,
	parse_variadics = function()
		--clang-format off
		local stat = parseEx([[

			function foo(bar, ...: number): ...string
			end

			type Foo = (string, number, ...number) -> ...boolean
			type Bar = () -> (number, ...boolean)
		]]).root
		--clang-format on

		assert(stat)
		assert(#stat.body == 3)

		local fn = stat.body[1]:as(AstStatFunction)
		assert(fn)
		assert(fn.func.vararg)
		assert(fn.func.varargAnnotation)
		
		local foo = stat.body[2]:as(AstStatTypeAlias)
		assert(foo)
		local fnFoo = foo.type:as(AstTypeFunction)
		assert(fnFoo)
		assert(#fnFoo.argTypes.types == 2)
		assert(fnFoo.argTypes.tailType)
		assert(#fnFoo.returnTypes.types == 0)
		assert(fnFoo.returnTypes.tailType)

		local bar = stat.body[3]:as(AstStatTypeAlias)
		assert(bar)
		local fnBar = bar.type:as(AstTypeFunction)
		assert(fnBar)
		assert(#fnBar.argTypes.types == 0)
		assert(not fnBar.argTypes.tailType)
		assert(#fnBar.returnTypes.types == 1)
		assert(fnBar.returnTypes.tailType)
	end,
	variadics_must_be_last = function()
		matchParseError("function foo(): (...number, string) end", "Expected ')' (to close '(' at column 17), got ','")
		matchParseError("type Foo = (...number, string) -> (...string, number)", "Expected ')' (to close '(' at column 12), got ','")
	end,
	variadic_definition_parsing = function()
		local stat = parseEx([[

			declare function foo(...: string): ...string
			declare class Foo
				function a(self, ...: string): ...string
			end
		]]).root

		assert(stat)

		matchParseError("declare function foo(...)", "All declaration parameters must be annotated")
		matchParseError("declare class Foo function a(self, ...) end", "All declaration parameters aside from 'self' must be annotated")
	end,
	generic_pack_parsing = function()
		local result = parseEx([[

			function f<a...>(...: a...)
			end

			type A = (a...) -> b...
		]])

		local stat = result.root
		assert(stat)

		local fn = stat.body[1]:as(AstStatFunction)
		assert(fn)
		assert(fn.func.varargAnnotation)

		local annot = fn.func.varargAnnotation:as(AstTypePackGeneric)
		assert(annot)
		assert(annot.genericName.value == "a")

		local alias = stat.body[2]:as(AstStatTypeAlias)
		assert(alias)
		local fnTy = alias.type:as(AstTypeFunction)
		assert(fnTy)

		local argAnnot = assert(fnTy.argTypes.tailType):as(AstTypePackGeneric)
		assert(argAnnot)
		assert(argAnnot.genericName.value == "a")

		local retAnnot = assert(fnTy.returnTypes.tailType):as(AstTypePackGeneric)
		assert(retAnnot)
		assert(retAnnot.genericName.value == "b")
	end,
	generic_function_declaration_parsing = function()
		local result = parseEx([[

			declare function f<a, b, c...>()
		]])

		local stat = result.root
		assert(stat)

		local decl = stat.body[1]:as(AstStatDeclareFunction)
		assert(decl)
		assert(#decl.generics == 2)
		assert(#decl.genericPacks == 1)
	end,
	function_type_named_arguments = function()
		local result = parseEx("type MyFunc = (a: number, b: string, c: number) -> string")

		local stat = result.root
		assert(stat)

		local decl = stat.body[1]:as(AstStatTypeAlias)
		assert(decl)
		local func = decl.type:as(AstTypeFunction)
		assert(func)
		assert(#func.argTypes.types == 3)
		assert(#func.argNames == 3)
		assert(func.argNames[3])
		assert(assert(func.argNames[3]).first.value == "c")

		local result = parseEx("type MyFunc = (a: number, string, c: number) -> string")

		local stat = result.root
		assert(stat)

		local decl = stat.body[1]:as(AstStatTypeAlias)
		assert(decl)
		local func = decl.type:as(AstTypeFunction)
		assert(func)
		assert(#func.argTypes.types == 3)
		assert(#func.argNames == 3)
		assert(not func.argNames[2])
		assert(func.argNames[3])
		assert(assert(func.argNames[3]).first.value == "c")

		local result = parseEx("type MyFunc = (a: number, string, number) -> string")

		local stat = result.root
		assert(stat)

		local decl = stat.body[1]:as(AstStatTypeAlias)
		assert(decl)
		local func = decl.type:as(AstTypeFunction)
		assert(func)
		assert(#func.argTypes.types == 3)
		assert(#func.argNames == 3)
		assert(not func.argNames[2])
		assert(not func.argNames[3])

		local result = parseEx("type MyFunc = (a: number, b: string, c: number) -> (d: number, e: string, f: number) -> string")

		local stat = result.root
		assert(stat)

		local decl = stat.body[1]:as(AstStatTypeAlias)
		assert(decl)
		local func = decl.type:as(AstTypeFunction)
		assert(func)
		assert(#func.argTypes.types == 3)
		assert(#func.argNames == 3)
		assert(func.argNames[3])
		assert(assert(func.argNames[3]).first.value == "c")
		local funcRet = func.returnTypes.types[1]:as(AstTypeFunction)
		assert(funcRet)
		assert(#funcRet.argTypes.types == 3)
		assert(#funcRet.argNames == 3)
		assert(func.argNames[3])
		assert(assert(funcRet.argNames[3]).first.value == "f")

		matchParseError(
			"type MyFunc = (a: number, b: string, c: number) -> (d: number, e: string, f: number)",
			"Expected '->' when parsing function type, got <eof>"
		)

		matchParseError("type MyFunc = (number) -> (d: number) <a, b, c> -> number", "Expected '->' when parsing function type, got '<'")
	end,
	function_type_matching_parenthesis = function()
		matchParseError("local a: <T>(number -> string", "Expected ')' (to close '(' at column 13), got '->'")
	end,
	parse_type_alias_default_type = function()
		local stat = parse([[

type A<T = string> = {}
type B<T... = ...number> = {}
type C<T..., U... = T...> = {}
type D<T..., U... = ()> = {}
type E<T... = (), U... = ()> = {}
type F<T... = (string), U... = ()> = (T...) -> U...
type G<T... = ...number, U... = (string, number, boolean)> = (U...) -> T...
		]])

		assert(stat)
	end,
	parse_type_alias_default_type_errors = function()
		matchParseError("type Y<T = number, U> = {}", "Expected default type after type name", Location.new(Position.new(0, 20), Position.new(0, 21)))
		matchParseError(
			"type Y<T... = ...number, U...> = {}",
			"Expected default type pack after type pack name",
			Location.new(Position.new(0, 29), Position.new(0, 30))
		)
		matchParseError(
			"type Y<T... = (string) -> number> = {}",
			"Expected type pack after '=', got type",
			Location.new(Position.new(0, 14), Position.new(0, 32))
		)
	end,
	parse_type_pack_errors = function()
		matchParseError(
			"type Y<T...> = {a: T..., b: number}",
			"Unexpected '...' after type name; type pack is not allowed in this context",
			Location.new(Position.new(0, 20), Position.new(0, 23))
		)
		matchParseError(
			"type Y<T...> = {a: (number | string)...",
			"Unexpected '...' after type annotation",
			Location.new(Position.new(0, 36), Position.new(0, 39))
		)
	end,
	parse_if_else_expression = function()
		local stat = parse("return if true then 1 else 2")
		
		assert(stat)
		local str = assert(stat:as(AstStatBlock)).body[1]:as(AstStatReturn)
		assert(str)
		assert(#str.list == 1)
		local ifElseExpr = str.list[1]:as(AstExprIfElse)
		assert(ifElseExpr)

		local stat = parse("return if true then 1 elseif true then 2 else 3")
		
		assert(stat)
		local str = assert(stat:as(AstStatBlock)).body[1]:as(AstStatReturn)
		assert(str)
		assert(#str.list == 1)
		local ifElseExpr1 = str.list[1]:as(AstExprIfElse)
		assert(ifElseExpr1)
		local ifElseExpr2 = ifElseExpr1.falseExpr:as(AstExprIfElse)
		assert(ifElseExpr2)

		-- Use "else if" as opposed to elseif
		local stat = parse("return if true then 1 else if true then 2 else 3")
		
		assert(stat)
		local str = assert(stat:as(AstStatBlock)).body[1]:as(AstStatReturn)
		assert(str)
		assert(#str.list == 1)
		local ifElseExpr1 = str.list[1]:as(AstExprIfElse)
		assert(ifElseExpr1)
		local ifElseExpr2 = ifElseExpr1.falseExpr:as(AstExprIfElse)
		assert(ifElseExpr2)

		-- Use an if-else expression as the conditional expression of an if-else expression
		local stat = parse("return if if true then false else true then 1 else 2")
		
		assert(stat)
		local str = assert(stat:as(AstStatBlock)).body[1]:as(AstStatReturn)
		assert(str)
		assert(#str.list == 1)
		local ifElseExpr = str.list[1]:as(AstExprIfElse)
		assert(ifElseExpr)
		local nestedIfElseExpr = ifElseExpr.condition:as(AstExprIfElse)
		assert(nestedIfElseExpr)
	end,
	parse_type_pack_type_parameters = function()
		local stat = parse([[

type Packed<T...> = () -> T...

type A<X...> = Packed<X...>
type B<X...> = Packed<...number>
type C<X...> = Packed<(number, X...)>
		]])

		assert(stat)
	end,
	invalid_type_forms = function()
		matchParseError("type A = (b: number)", "Expected '->' when parsing function type, got <eof>")
		matchParseError("type P<T...> = () -> T... type B = P<(x: number, y: string)>", "Expected '->' when parsing function type, got '>'")
		matchParseError("type F<T... = (a: string)> = (T...) -> ()", "Expected '->' when parsing function type, got '>'")
	end,

	-- test suite ParseErrorRecovery

	multiple_parse_errors = function()
		Try(function()
			parse([[

local a = 3 * (
return a +
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert(2 == e:getErrors():size())
		end)
	end,
	-- check that we are not skipping tokens that weren't processed at all
	statement_error_recovery_expected = function()
		Try(function()
			parse([[

function a(a, b) return a + b end
some
a(2, 5)
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert(1 == e:getErrors():size())
		end)
	end,
	statement_error_recovery_unexpected = function()
		Try(function()
			parse("+")
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert(1 == e:getErrors():size())
		end)
	end,
	extra_token_in_consume = function()
		Try(function()
			parse([[

function test + (a, f) return a + f end
return test(2, 3)
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert(1 == e:getErrors():size())
			assert("Expected '(' when parsing function, got '+'" == e:getErrors():front():getMessage())
		end)
	end,
	extra_token_in_consume_match = function()
		Try(function()
			parse([[

function test(a, f+) return a + f end
return test(2, 3)
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert(1 == e:getErrors():size())
			assert("Expected ')' (to close '(' at column 14), got '+'" == e:getErrors():front():getMessage())
		end)
	end,
	extra_token_in_consume_match_end = function()
		Try(function()
			parse([[

if true then
    return 12
then
end
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert(1 == e:getErrors():size())
			assert("Expected 'end' (to close 'then' at line 2), got 'then'" == e:getErrors():front():getMessage())
		end)
	end,
	extra_table_indexer_recovery = function()
		Try(function()
			parse([[

local a : { [string] : number, [number] : string, count: number }
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert(1 == e:getErrors():size())
		end)
	end,
	recovery_error_limit_1 = function()
		ScopedVariable({LuauParseErrorLimit = 1} :: FV, function()
			Try(function()
				parse("local a = ")
				error("Expected ParseErrors to be thrown")
			end):catch(function(e: ParseErrors)
				assert(1 == e:getErrors():size())
				assert(e:getErrors():front():getMessage() == e:what())
			end)
		end)
	end,
	recovery_error_limit_2 = function()
		ScopedVariable({LuauParseErrorLimit = 2} :: FV, function()
			Try(function()
				parse("escape escape escape")
				error("Expected ParseErrors to be thrown")
			end):catch(function(e: ParseErrors)
				assert(3 == e:getErrors():size())
				assert("3 parse errors" == e:what())
				assert("Reached error limit (2)" == e:getErrors():back():getMessage())
			end)
		end)
	end,
	recovery_of_parenthesized_expressions = function()
		local function checkAstEquivalence(codeWithErrors: string, code: string)
			local result1 = tryParse(codeWithErrors, defaultOptions)
			assert(result1.root)

			local counterWithErrors = CountAstNodes.new()
			result1.root:visit(counterWithErrors)

			local result2 = parse(code, defaultOptions)
			assert(result2)

			local counter = CountAstNodes.new()
			result2:visit(counter)

			assert(counterWithErrors.count == counter.count)
		end

		local function checkRecovery(codeWithErrors: string, code: string, expectedErrorCount: number)
			local success, e: ParseErrors = pcall(parse :: any, codeWithErrors)
			if success then
				error("Expected ParseErrors to be thrown")
			else
				assert(expectedErrorCount == e:getErrors():size())
				checkAstEquivalence(codeWithErrors, code)
			end
		end

		checkRecovery("function foo(a, b. c) return a + b end", "function foo(a, b) return a + b end", 1)
		checkRecovery(
			"function foo(a, b: { a: number, b: number. c:number }) return a + b end",
			"function foo(a, b: { a: number, b: number }) return a + b end",
			1
		)

		checkRecovery("function foo(a, b): (number -> number return a + b end", "function foo(a, b): (number) -> number return a + b end", 1)
		checkRecovery("function foo(a, b): (number, number -> number return a + b end", "function foo(a, b): (number) -> number return a + b end", 1)
		checkRecovery("function foo(a, b): (number; number) -> number return a + b end", "function foo(a, b): (number) -> number return a + b end", 1)

		checkRecovery("function foo(a, b): (number, number return a + b end", "function foo(a, b): (number, number) end", 1)
		checkRecovery("local function foo(a, b): (number, number return a + b end", "local function foo(a, b): (number, number) end", 1)

		-- These tests correctly recovered before the changes and we test that new recovery didn't make them worse
		-- (by skipping more tokens necessary)
		checkRecovery("type F = (number, number -> number", "type F = (number, number) -> number", 1)
		checkRecovery("function foo(a, b: { a: number, b: number) return a + b end", "function foo(a, b: { a: number, b: number }) return a + b end", 1)
		checkRecovery("function foo(a, b: { [number: number}) return a + b end", "function foo(a, b: { [number]: number}) return a + b end", 1)
		checkRecovery("local n: (string | number = 2", "local n: (string | number) = 2", 1)

		-- Check that we correctly stop at the end of a line
		checkRecovery([[

function foo(a, b
    return a + b
end
]], "function foo(a, b) return a + b end", 1)
	end,
	incomplete_method_call = function()
		local source = [[

        function howdy()
            return game:
        end
    ]]
		
		local result = Parser.parse(source, #source, AstNameTable.new(), ParseOptions.new())

		assert(1 == #assert(result.root).body)

		local howdyFunction = result.root.body[1]:as(AstStatFunction)
		assert(howdyFunction)

		local body = howdyFunction.func.body
		assert(1 == #body.body)

		local ret = body.body[1]:as(AstStatReturn)
		assert(ret)

		assert(howdyFunction.location.finish > body.location.finish)
	end,
	incomplete_method_call_2 = function()
		local source = [[

			local game = { GetService=function(s) return 'hello' end }

			function a()
				game:a
			end
		]]

		local result = Parser.parse(source, #source, AstNameTable.new(), ParseOptions.new())

		assert(2 == #assert(result.root).body)

		local howdyFunction = result.root.body[2]:as(AstStatFunction)
		assert(howdyFunction)

		local body = howdyFunction.func.body
		assert(1 == #body.body)

		local ret = body.body[1]:as(AstStatError)
		assert(ret)

		assert(howdyFunction.location.finish > body.location.finish)
	end,
	incomplete_method_call_still_yields_an_AstExprIndexName = function()
		local result = tryParse([[

			game:
		]])

		assert(1 == #assert(result.root).body)

		local stat = result.root.body[1]:as(AstStatError)
		assert(stat)

		local expr = stat.expressions[1]:as(AstExprError)
		assert(expr)

		local indexName = expr.expressions[1]:as(AstExprIndexName)
		assert(indexName)
	end,
	recover_confusables = function()
		-- Binary
		matchParseError("local a = 4 != 10", "Unexpected '!='; did you mean '~='?")
		matchParseError("local a = true && false", "Unexpected '&&'; did you mean 'and'?")
		matchParseError("local a = false || true", "Unexpected '||'; did you mean 'or'?")

		-- Unary
		matchParseError("local a = !false", "Unexpected '!'; did you mean 'not'?")

		-- Check that separate tokens are not considered as a single one
		matchParseError("local a = 4 ! = 10", "Expected identifier when parsing expression, got '!'")
		matchParseError("local a = true & & false", "Expected identifier when parsing expression, got '&'")
		matchParseError("local a = false | | true", "Expected identifier when parsing expression, got '|'")
	end,
	capture_comments = function()
		local options = ParseOptions.new()
		options.captureComments = true

		local result = parseEx([=[

        --!strict

        local a = 5 -- comment one
        local b = 8 -- comment two
        --[[
            Multi line comment
        ]]
        local c = 'see'
    ]=], options)

		assert(result.errors:empty())

		assert(4 == result.commentLocations:size())
		assert(Location.new(Position.new(1, 8), Position.new(1, 17)) :: any == result.commentLocations:get(1).location)
		assert(Location.new(Position.new(3, 20), Position.new(3, 34)) :: any == result.commentLocations:get(2).location)
		assert(Location.new(Position.new(4, 20), Position.new(4, 34)) :: any == result.commentLocations:get(3).location)
		assert(Location.new(Position.new(5, 8), Position.new(7, 10)) :: any == result.commentLocations:get(4).location)
	end,
	capture_broken_comment_at_the_start_of_the_file = function()
		local options = ParseOptions.new()
		options.captureComments = true

		local result = tryParse([[

        --[[
    ]], options)

		assert(1 == result.commentLocations:size())
		assert(Location.new(Position.new(1, 8), Position.new(2, 4)) :: any == result.commentLocations:get(1).location)
	end,
	capture_broken_comment = function()
		local options = ParseOptions.new()
		options.captureComments = true

		local result = tryParse([[

        local a = "test"

        --[[broken!
    ]], options)

		assert(1 == result.commentLocations:size())
		assert(Location.new(Position.new(3, 8), Position.new(4, 4)) :: any == result.commentLocations:get(1).location)
	end,
	empty_function_type_error_recovery = function()
		Try(function()
			parse([[

type Fn = (
    any,
    string | number | ()
) -> any
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert("Expected '->' after '()' when parsing function type; did you mean 'nil'?" == e:getErrors():front():getMessage())
		end)

		-- If we have arguments or generics, don't use special case
		Try(function()
			parse("type Fn = (any, string | number | (number, number)) -> any")
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert("Expected '->' when parsing function type, got ')'" == e:getErrors():front():getMessage())
		end)

		Try(function()
			parse("type Fn = (any, string | number | <a>()) -> any")
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert("Expected '->' when parsing function type, got ')'" == e:getErrors():front():getMessage())
		end)

		Try(function()
			parse("type Fn = (any, string | number | <a...>()) -> any")
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert("Expected '->' when parsing function type, got ')'" == e:getErrors():front():getMessage())
		end)
	end,
	AstName_comparison = function()
		assert(not (AstName.new() < AstName.new()))

		local one = AstName.new("one")
		local two = AstName.new("two")

		assert((one < two) ~= (two < one))
	end,
	generic_type_list_recovery = function()
		Try(function()
			parse([[

local function foo<T..., U>(a: U, ...: T...): (U, ...T) return a, ... end
return foo(1, 2 -- to check for a second error after recovery
			]])
			error("Expected ParseErrors to be thrown")
		end):catch(function(e: ParseErrors)
			assert(2 == e:getErrors():size())
			assert("Generic types come before generic type packs" == e:getErrors():front():getMessage())
		end)
	end,
	recover_index_name_keyword = function()
		local result = tryParse([[

local b
local a = b.do
		]])
		assert(1 == result.errors:size())

		result = tryParse([[

local b
local a = b.
do end
		]])

		assert(1 == result.errors:size())
	end,
	recover_self_call_keyword = function()
		local result = tryParse([[

local b
local a = b:do
		]])
		assert(2 == result.errors:size())

		result = tryParse([[

local b
local a = b:do
		]])
		assert(2 == result.errors:size())
	end,
	recover_type_index_name_keyword = function()
		local result = tryParse([[

local A
local b : A.do
		]])
		assert(1 == result.errors:size())

		result = tryParse([[

local A
local b : A.do
do end
		]])
		assert(1 == result.errors:size())
	end,
	recover_expected_type_pack = function()
		local result = tryParse([[

type Y<T..., U = T...> = (T...) -> U...
		]])
		assert(1 == result.errors:size())
	end,
	recover_unexpected_type_pack = function()
		local result = tryParse([[

type X<T...> = { a: T..., b: number }
type Y<T> = { a: T..., b: number }
type Z<T> = { a: string | T..., b: number }
		]])

		assert(3 == result.errors:size())
	end,
	recover_function_return_type_annotations = function()
		local result = tryParse([[

type Custom<A, B, C> = { x: A, y: B, z: C }
type Packed<A...> = { x: (A...) -> () }
type F = (number): Custom<boolean, number, string>
type G = Packed<(number): (string, number, boolean)>
local function f(x: number) -> Custom<string, boolean, number>
end
		]])
		assert(3 == result.errors:size())
		assert(result.errors:get(1):getMessage() == "Return types in function type annotations are written after '->' instead of ':'")
		assert(result.errors:get(2):getMessage() == "Return types in function type annotations are written after '->' instead of ':'")
		assert(result.errors:get(3):getMessage() == "Function return type annotations are written after ':' instead of '->'")
	end,
	error_message_for_using_function_as_type_annotation = function()
		local result = tryParse([[

			type Foo = function
		]])
		assert(1 == result.errors:size())
		assert(
			"Using 'function' as a type annotation is not supported, consider replacing with a function type annotation e.g. '(...any) -> ...any'"
				== result.errors:get(1):getMessage()
		)
	end,
	get_a_nice_error_when_there_is_an_extra_comma_at_the_end_of_a_function_argument_list = function()
		local result = tryParse([[

        foo(a, b, c,)
		]])

		assert(1 == result.errors:size())

		assert(Location.new(Position.new(1, 20), Position.new(1, 21)) :: any == result.errors:get(1):getLocation())
		assert("Expected expression after ',' but got ')' instead" == result.errors:get(1):getMessage())
	end,
	get_a_nice_error_when_there_is_an_extra_comma_at_the_end_of_a_function_parameter_list = function()
		local result = tryParse([[

        export type VisitFn = (
            any,
            Array<TAnyNode | Array<TAnyNode>>, -- extra comma here
        ) -> any
		]], ParseOptions.new(true, true))

		assert(1 == result.errors:size())

		assert(Location.new(Position.new(4, 8), Position.new(4, 9)) :: any == result.errors:get(1):getLocation())
		assert("Expected type after ',' but got ')' instead" == result.errors:get(1):getMessage())
	end,
	get_a_nice_error_when_there_is_an_extra_comma_at_the_end_of_a_generic_parameter_list = function()
		local result = tryParse([[

        export type VisitFn = <A, B,>(a: A, b: B) -> ()
    ]])

		assert(1 == result.errors:size())

		assert(Location.new(Position.new(1, 36), Position.new(1, 37)) :: any == result.errors:get(1):getLocation())
		assert("Expected type after ',' but got '>' instead" == result.errors:get(1):getMessage())

		assert(1 == #assert(result.root).body)

		local t = result.root.body[1]:as(AstStatTypeAlias)
		assert(t)

		local f = t.type:as(AstTypeFunction)
		assert(f)

		assert(2 == #f.generics)
	end,
	get_a_nice_error_when_there_is_no_comma_between_table_members = function()
		local result = tryParse([[

        local t = {
            first = 1
            second = 2,
            third = 3,
            fouth = 4,
        }
		]])

		assert(1 == result.errors:size())

		assert(Location.new(Position.new(3, 12), Position.new(3, 18)) :: any == result.errors:get(1):getLocation())
		assert("Expected ',' after table constructor element" == result.errors:get(1):getMessage())

		assert(1 == #assert(result.root).body)

		local exprTable = query(AstExprTable, nil, result.root)
		assert(exprTable)
		assert(#exprTable.items == 4)
	end,
	get_a_nice_error_when_there_is_no_comma_after_last_table_member = function()
		local result = tryParse([[

        local t = {
            first = 1

        local ok = true
        local good = ok == true
		]])

		assert(1 == result.errors:size())

		assert(Location.new(Position.new(4, 8), Position.new(4, 13)) :: any == result.errors:get(1):getLocation())
		assert("Expected '}' (to close '{' at line 2), got 'local'" == result.errors:get(1):getMessage())

		assert(3 == #assert(result.root).body)


		local exprTable = query(AstExprTable, nil, result.root)
		assert(exprTable)
		assert(#exprTable.items == 1)
	end,
	missing_default_type_pack_argument_after_variadic_type_parameter = function()
		local result = tryParse([[

        type Foo<T... = > = nil
		]])

		assert(2 == result.errors:size())

		assert(Location.new(Position.new(1, 23), Position.new(1, 25)) :: any == result.errors:get(1):getLocation())
		assert("Expected type, got '>'" == result.errors:get(1):getMessage())

		assert(Location.new(Position.new(1, 23), Position.new(1, 24)) :: any == result.errors:get(2):getLocation())
		assert("Expected type pack after '=', got type" == result.errors:get(2):getMessage())
	end,
	table_type_keys_cant_contain_nul = function()
		local result = tryParse([[

        type Foo = { ["\0"]: number }
		]])

		assert(1 == result.errors:size())

		assert(Location.new(Position.new(1, 21), Position.new(1, 22)) :: any == result.errors:get(1):getLocation())
		assert("String literal contains malformed escape sequence or \\0" == result.errors:get(1):getMessage())
	end,
	invalid_escape_literals_get_reported_but_parsing_continues = function()
		local result = tryParse([[

        local foo = "\xQQ"
        print(foo)
		]])

		assert(1 == result.errors:size())

		assert(Location.new(Position.new(1, 20), Position.new(1, 26)) :: any == result.errors:get(1):getLocation())
		assert("String literal contains malformed escape sequence" == result.errors:get(1):getMessage())

		assert(result.root)
		assert(#result.root.body == 2)
	end,
	unfinished_string_literals_get_reported_but_parsing_continues = function()
		local result = tryParse([[

        local foo = "hi
        print(foo)
		]])

		assert(1 == result.errors:size())

		assert(Location.new(Position.new(1, 20), Position.new(1, 23)) :: any == result.errors:get(1):getLocation())
		assert("Malformed string; did you forget to finish it?" == result.errors:get(1):getMessage())

		assert(result.root)
		assert(#result.root.body == 2)
	end,
	unfinished_string_literal_types_get_reported_but_parsing_continues = function()
		local result = tryParse([[

        type Foo = "hi
        print(foo)
		]])

		assert(1 == result.errors:size())

		assert(Location.new(Position.new(1, 19), Position.new(1, 22)) :: any == result.errors:get(1):getLocation())
		assert("Malformed string; did you forget to finish it?" == result.errors:get(1):getMessage())

		assert(result.root)
		assert(#result.root.body == 2)
	end,
	do_block_with_no_end = function()
		local result = tryParse([[

			do
		]])

		assert(1 == result.errors:size())

		local stat0 = assert(result.root).body[1]:as(AstStatBlock)
		assert(stat0)

		assert(not stat0.hasEnd)
	end,
	parse_interpolated_string_with_lookahead_involved = function()
		ScopedVariable({LuauLexerLookaheadRemembersBraceType = true} :: FV, function()
			local result = tryParse([[

				local x = `{ {y} }`
			]])

			if not result.errors:empty() then
				error(result.errors:get(1):getMessage())
			end
		end)
	end,
	parse_interpolated_string_with_lookahead_involved2 = function()
		ScopedVariable({LuauLexerLookaheadRemembersBraceType = true} :: FV, function()
			local result = tryParse([[

				local x = `{ { y{} } }`
			]])
	
			if not result.errors:empty() then
				error(result.errors:get(1):getMessage())
			end
		end)
	end,
	parse_top_level_checked_fn = function()
		local opts = ParseOptions.new()
		opts.allowDeclarationSyntax = true

		ScopedVariable({LuauAttributeSyntax = true} :: FV, function()
			local src = [[

				@checked declare function abs(n: number): number
			]]
			
			local pr = tryParse(src, opts)
			assert(pr.errors:size() == 0)
	
			assert(#assert(pr.root).body == 1)
			local root = pr.root.body[1]
			local func = root:as(AstStatDeclareFunction)
			assert(func)
			assert(func:isCheckedFunction())
		end)
	end,
	parse_declared_table_checked_member = function()
		local opts = ParseOptions.new()
		opts.allowDeclarationSyntax = true

		ScopedVariable({LuauAttributeSyntax = true} :: FV, function()
			local src = [[

    declare math : {
        abs : @checked (number) -> number
}
]]

			local pr = tryParse(src, opts)
			assert(pr.errors:size() == 0)

			assert(#assert(pr.root).body == 1)
			local root = pr.root.body[1]
			local glob = root:as(AstStatDeclareGlobal)
			assert(glob)
			local tbl = glob.type:as(AstTypeTable)
			assert(tbl)
			assert(#tbl.props == 1)
			local prop = tbl.props[1]
			local func = prop.type:as(AstTypeFunction)
			assert(func)
			assert(func:isCheckedFunction())
		end)
	end,
	parse_checked_outside_decl_fails = function()
		local opts = ParseOptions.new()
		opts.allowDeclarationSyntax = true

		ScopedVariable({LuauAttributeSyntax = true} :: FV, function()
			local pr = tryParse([[

				local @checked = 3
			]], opts)
			assert(pr.errors:size() > 0)
		end)
	end,
	parse_checked_in_and_out_of_decl_fails = function()
		local opts = ParseOptions.new()
		opts.allowDeclarationSyntax = true

		ScopedVariable({LuauAttributeSyntax = true} :: FV, function()
			local pr = tryParse([[

    local @checked = 3
    @checked declare function abs(n: number): number
			]], opts)
			assert(pr.errors:size() == 2)
			assert(pr.errors:get(1):getLocation().begin.line == 1)
			assert(pr.errors:get(2):getLocation().begin.line == 1)
		end)
	end,
	parse_checked_as_function_name_fails = function()
		local opts = ParseOptions.new()
		opts.allowDeclarationSyntax = true

		ScopedVariable({LuauAttributeSyntax = true} :: FV, function()
			local pr = tryParse([[

				@checked function(x: number) : number
				end
			]], opts)
			assert(pr.errors:size() > 0)
		end)
	end,
	["cannot_use_@_as_variable_name"] = function()
		local opts = ParseOptions.new()
		opts.allowDeclarationSyntax = true

		ScopedVariable({LuauAttributeSyntax = true} :: FV, function()
			local pr = tryParse([[

				local @blah = 3
			]])
	
			assert(pr.errors:size() > 0)
		end)
	end,
	read_write_table_properties = function()
		local pr = tryParse([[

			type A = {read x: number}
			type B = {write x: number}
			type C = {read x: number, write x: number}
			type D = {read: () -> string}
			type E = {write: (string) -> ()}
			type F = {read read: () -> string}
			type G = {read write: (string) -> ()}

			type H = {read ["A"]: number}
			type I = {write ["A"]: string}

			type J = {read [number]: number}
			type K = {write [number]: string}
		]])

		assert(pr.errors:size() == 0)
	end,
	parse_attribute_on_function_stat = function()
		ScopedVariable({LuauAttributeSyntax = true} :: FV, function()
			local stat = parse([[

@checked
function hello(x, y)
    return x + y
end]])
		
			assert(stat)
	
			local statFun = stat.body[1]:as(AstStatFunction)
			assert(statFun)
	
			local attributes = statFun.func.attributes
	
			assert(#attributes == 1)
	
			checkAttribute(attributes[1], AstAttr.Type.Checked, Location.new(Position.new(1, 0), Position.new(1, 8)))
		end)
	end,
	parse_attribute_for_function_expression = function()
		ScopedVariable({LuauAttributeSyntax = true, LuauAttributeSyntaxFunExpr = true} :: FV, function()
			local stat1 = parse([[

local function invoker(f)
    return f(1)
end

invoker(@checked function(x) return (x + 2) end)
			]])
	
			assert(stat1)
	
			local func1 = assert(assert(stat1.body[2]:as(AstStatExpr)).expr:as(AstExprCall)).args[1]:as(AstExprFunction)
			assert(func1)
	
			local attributes1 = func1.attributes
	
			assert(#attributes1 == 1)
	
			checkAttribute(attributes1[1], AstAttr.Type.Checked, Location.new(Position.new(5, 8), Position.new(5, 16)))
	
			local stat2 = parse([[

local f = @checked function(x) return (x + 2) end
			]])
	
			assert(stat2)
	
			local func2 = assert(stat2.body[1]:as(AstStatLocal)).values[1]:as(AstExprFunction)
			assert(func2)
	
			local attributes2 = func2.attributes
	
			assert(#attributes2 == 1)
	
			checkAttribute(attributes2[1], AstAttr.Type.Checked, Location.new(Position.new(1, 10), Position.new(1, 18)))
		end)
	end,
	parse_attribute_on_local_function_stat = function()
		ScopedVariable({LuauAttributeSyntax = true} :: FV, function()
			local stat = parse([[

    @checked
local function hello(x, y)
    return x + y
end]])
			
			assert(stat)
	
			local statFun = stat.body[1]:as(AstStatLocalFunction)
			assert(statFun)
	
			local attributes = statFun.func.attributes
	
			assert(#attributes == 1)
	
			checkAttribute(attributes[1], AstAttr.Type.Checked, Location.new(Position.new(1, 4), Position.new(1, 12)))
		end)
	end,
	empty_attribute_name_is_not_allowed = function()
		ScopedVariable({LuauAttributeSyntax = true} :: FV, function()
			local result = tryParse([[

@
function hello(x, y)
    return x + y
end]])

			checkFirstErrorForAttributes(result.errors, 1, Location.new(Position.new(1, 0), Position.new(1, 1)), "Attribute name is missing")
		end)
	end,
	dont_parse_attributes_on_non_function_stat = function()
		ScopedVariable({LuauAttributeSyntax = true} :: FV, function()
			local pr1 = tryParse([[

@checked
if a<0 then a = 0 end]])
			checkFirstErrorForAttributes(
				pr1.errors,
				1,
				Location.new(Position.new(2, 0), Position.new(2, 2)),
				"Expected 'function', 'local function', 'declare function' or a function type declaration after attribute, but got 'if' intead"
			)

			local pr2 = tryParse([[

local i = 1
@checked
while a[i] do
    print(a[i])
    i = i + 1
end]])
			checkFirstErrorForAttributes(
				pr2.errors,
				1,
				Location.new(Position.new(3, 0), Position.new(3, 5)),
				"Expected 'function', 'local function', 'declare function' or a function type declaration after attribute, but got 'while' intead"
			)

			local pr3 = tryParse([[

@checked
do
    local a2 = 2*a
    local d = sqrt(b^2 - 4*a*c)
    x1 = (-b + d)/a2
    x2 = (-b - d)/a2
end]])
			checkFirstErrorForAttributes(
				pr3.errors,
				1,
				Location.new(Position.new(2, 0), Position.new(2, 2)),
				"Expected 'function', 'local function', 'declare function' or a function type declaration after attribute, but got 'do' intead"
			)

			local pr4 = tryParse([[

@checked
for i=1,10 do print(i) end
		]])
			checkFirstErrorForAttributes(
				pr4.errors,
				1,
				Location.new(Position.new(2, 0), Position.new(2, 3)),
				"Expected 'function', 'local function', 'declare function' or a function type declaration after attribute, but got 'for' intead"
			)

			local pr5 = tryParse([[

@checked
repeat
    line = io.read()
until line ~= ""
		]])
			checkFirstErrorForAttributes(
				pr5.errors,
				1,
				Location.new(Position.new(2, 0), Position.new(2, 6)),
				"Expected 'function', 'local function', 'declare function' or a function type declaration after attribute, but got 'repeat' intead"
			)

			local pr6 = tryParse([[

@checked
local x = 10
		]])
			checkFirstErrorForAttributes(
				pr6.errors,
				1,
				Location.new(Position.new(2, 6), Position.new(2, 7)),
				"Expected 'function' after local declaration with attribute, but got 'x' intead"
			)

			local pr7 = tryParse([[

local i = 1
while a[i] do
    if a[i] == v then @checked break end
    i = i + 1
end
		]])
			checkFirstErrorForAttributes(
				pr7.errors,
				1,
				Location.new(Position.new(3, 31), Position.new(3, 36)),
				"Expected 'function', 'local function', 'declare function' or a function type declaration after attribute, but got 'break' intead"
			)

			local pr8 = tryParse([[

function foo1 () @checked return 'a' end
		]])
			checkFirstErrorForAttributes(
				pr8.errors,
				1,
				Location.new(Position.new(1, 26), Position.new(1, 32)),
				"Expected 'function', 'local function', 'declare function' or a function type declaration after attribute, but got 'return' intead"
			)
		end)
	end,
	dont_parse_attribute_on_argument_non_function = function()
		ScopedVariable({LuauAttributeSyntax = true, LuauAttributeSyntaxFunExpr = true} :: FV, function()
			local pr = tryParse([[

local function invoker(f, y)
    return f(y)
end

invoker(function(x) return (x + 2) end, @checked 1)
			]])
	
			checkFirstErrorForAttributes(
				pr.errors,
				1,
				Location.new(Position.new(5, 40), Position.new(5, 48)),
				"Expected 'function' declaration after attribute, but got '1' intead"
			)
		end)
	end,
	parse_attribute_on_function_type_declaration = function()
		ScopedVariable({LuauAttributeSyntax = true} :: FV, function()
			local opts = ParseOptions.new()
			opts.allowDeclarationSyntax = true
	
			local src = [[

@checked declare function abs(n: number): number
			]]
	
			local pr = tryParse(src, opts)
			assert(pr.errors:size() == 0)
	
			assert(#assert(pr.root).body == 1)
	
			local root = pr.root.body[1]
	
			local func = root:as(AstStatDeclareFunction)
			assert(func)
	
			assert(func:isCheckedFunction())
	
			local attributes = func.attributes
	
			checkAttribute(attributes[1], AstAttr.Type.Checked, Location.new(Position.new(1, 0), Position.new(1, 8)))
		end)
	end,
	parse_attributes_on_function_type_declaration_in_table = function()
		ScopedVariable({LuauAttributeSyntax = true} :: FV, function()
			local opts = ParseOptions.new()
			opts.allowDeclarationSyntax = true
	
			local src = [[

declare bit32: {
    band: @checked (...number) -> number
}]]
	
			local pr = tryParse(src, opts)
			assert(pr.errors:size() == 0)
	
			assert(#assert(pr.root).body == 1)
	
			local root = pr.root.body[1]
	
			local glob = root:as(AstStatDeclareGlobal)
			assert(glob)
	
			local tbl = glob.type:as(AstTypeTable)
			assert(tbl)
	
			assert(#tbl.props == 1)
			local prop = tbl.props[1]
	
			local func = prop.type:as(AstTypeFunction)
			assert(func)
	
			local attributes = func.attributes
	
			assert(#attributes == 1)
			checkAttribute(attributes[1], AstAttr.Type.Checked, Location.new(Position.new(2, 10), Position.new(2, 18)))
		end)
	end,
	dont_parse_attributes_on_non_function_type_declarations = function()
		ScopedVariable({LuauAttributeSyntax = true} :: FV, function()
			local opts = ParseOptions.new()
			opts.allowDeclarationSyntax = true
	
			local pr1 = tryParse([[

@checked declare foo: number
			]], opts)
	
			checkFirstErrorForAttributes(
				pr1.errors,
				1,
				Location.new(Position.new(1, 17), Position.new(1, 20)),
				"Expected a function type declaration after attribute, but got 'foo' intead"
			)
	
			local pr2 = tryParse([[

@checked declare class Foo
    prop: number
    function method(self, foo: number): string
end]], opts)
	
			checkFirstErrorForAttributes(
				pr2.errors,
				1,
				Location.new(Position.new(1, 17), Position.new(1, 22)),
				"Expected a function type declaration after attribute, but got 'class' intead"
			)
	
			local pr3 = tryParse([[

declare bit32: {
    band: @checked number
}]], opts)

			checkFirstErrorForAttributes(
				pr3.errors,
				1,
				Location.new(Position.new(2, 19), Position.new(2, 25)),
				"Expected '(' when parsing function parameters, got 'number'"
			)
		end)
	end,
	attributes_cannot_be_duplicated = function()
		ScopedVariable({LuauAttributeSyntax = true} :: FV, function()
			local result = tryParse([[

@checked
    @checked
function hello(x, y)
    return x + y
end]])
				
			checkFirstErrorForAttributes(
				result.errors,
				1,
				Location.new(Position.new(2, 4), Position.new(2, 12)),
				"Cannot duplicate attribute '@checked'"
			)
		end)
	end,
	unsupported_attributes_are_not_allowed = function()
		ScopedVariable({LuauAttributeSyntax = true} :: FV, function()
			local result = tryParse([[

@checked
    @cool_attribute
function hello(x, y)
    return x + y
end]])
			checkFirstErrorForAttributes(
				result.errors,
				1,
				Location.new(Position.new(2, 4), Position.new(2, 19)),
				"Invalid attribute '@cool_attribute'"
			)
		end)
	end,
	can_parse_leading_bar_unions_successfully = function()
		ScopedVariable({LuauLeadingBarAndAmpersand2 = true} :: FV, function()
			parse(`type A = | "Hello" | "World"`)
		end)
	end,
	can_parse_leading_ampersand_intersections_successfully = function()
		ScopedVariable({LuauLeadingBarAndAmpersand2 = true} :: FV, function()
			parse("type A = & { string } & { number }")
		end)
	end,
	mixed_leading_intersection_and_union_not_allowed = function()
		ScopedVariable({LuauLeadingBarAndAmpersand2 = true} :: FV, function()
			matchParseError("type A = & number | string | boolean", "Mixing union and intersection types is not allowed; consider wrapping in parentheses.")
			matchParseError("type A = | number & string & boolean", "Mixing union and intersection types is not allowed; consider wrapping in parentheses.")
		end)
	end
}