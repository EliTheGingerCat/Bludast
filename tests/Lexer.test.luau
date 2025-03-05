-- Test suite from `/tests/Lexer.test.cpp`.

local AstNameTable = require("@Ast/AstNameTable")
local Lexeme = require("@Ast/Lexeme")
local Lexer = require("@Ast/Lexer")
local Location = require("@Shared/Location")
local Position = require("@Shared/Position")

return {
	broken_string_works = function()
		local testInput = "[["
		local table = AstNameTable.new()
		local lexer = Lexer.new(testInput, #testInput, table)
		local lexeme = lexer:next()
		assert(lexeme.type == Lexeme.Type.BrokenString)
		assert(lexeme.location == Location.new(Position.new(0, 0), Position.new(0, 2)))
	end,

	broken_comment = function()
		local testInput = "--[[  "
		local table = AstNameTable.new()
		local lexer = Lexer.new(testInput, #testInput, table)
		local lexeme = lexer:next()
		assert(lexeme.type == Lexeme.Type.BrokenComment)
		assert(lexeme.location == Location.new(Position.new(0, 0), Position.new(0, 6)))
	end,

	broken_comment_kept = function()
		local testInput = "--[[  "
		local table = AstNameTable.new()
		local lexer = Lexer.new(testInput, #testInput, table)
		lexer:setSkipComments(true)
		assert(lexer:next().type == Lexeme.Type.BrokenComment)
	end,

	comment_skipped = function()
		local testInput = "--  "
		local table = AstNameTable.new()
		local lexer = Lexer.new(testInput, #testInput, table)
		lexer:setSkipComments(true)
		assert(lexer:next().type == Lexeme.Type.Eof)
	end,

	multilineCommentWithLexemeInAndAfter = function()
		local testInput = "--[[ function \n]] end"
		local table = AstNameTable.new()
		local lexer = Lexer.new(testInput, #testInput, table)
		local comment = lexer:next()
		local endd = lexer:next()

		assert(comment.type == Lexeme.Type.BlockComment)
		assert(comment.location == Location.new(Position.new(0, 0), Position.new(1, 2)))
		assert(endd.type == Lexeme.Type.ReservedEnd)
		assert(endd.location == Location.new(Position.new(1, 3), Position.new(1, 6)))
	end,

	testBrokenEscapeTolerant = function()
		local testInput = "'\\3729472897292378'"
		local table = AstNameTable.new()
		local lexer = Lexer.new(testInput, #testInput)
		local item = lexer:next()

		assert(item.type == Lexeme.Type.QuotedString)
		assert(item.location == Location.new(Position.new(0, 0), Position.new(0, #testInput)))
	end,

	testBigDelimiters = function()
		local testInput = "--[===[\n\n\n\n]===]"
		local table = AstNameTable.new()
		local lexer = Lexer.new(testInput, #testInput, table)
		local item = lexer:next()

		assert(item.type == Lexeme.Type.BlockComment)
		assert(item.location == Location.new(Position.new(0, 0), Position.new(4, 5)))
	end,

	lookahead = function()
		local testInput = "foo --[[ comment ]] bar : nil end"

		local table = AstNameTable.new()
		local lexer = Lexer.new(testInput, #testInput, table)
		lexer:setSkipComments(true)
		lexer:next() -- must call next() before reading data from lexer at least once

		assert(lexer:current().type == Lexeme.Type.Name)
		assert(lexer:current().name == "foo")
		assert(lexer:lookahead().type == Lexeme.Type.Name)
		assert(lexer:lookahead().name == "bar")

		lexer:next()

		assert(lexer:current().type == Lexeme.Type.Name)
		assert(lexer:current().name == "bar")
		assert(lexer:lookahead().type == string.byte(":"))

		lexer:next()

		assert(lexer:current().type == string.byte(":"))
		assert(lexer:lookahead().type == Lexeme.Type.ReservedNil)

		lexer:next()

		assert(lexer:current().type == Lexeme.Type.ReservedNil)
		assert(lexer:lookahead().type == Lexeme.Type.ReservedEnd)

		lexer:next()

		assert(lexer:current().type == Lexeme.Type.ReservedEnd)
		assert(lexer:lookahead().type == Lexeme.Type.Eof)

		lexer:next()

		assert(lexer:current().type == Lexeme.Type.Eof)
		assert(lexer:lookahead().type == Lexeme.Type.Eof)
	end,

	string_interpolation_basic = function()
		local testInput = '`foo {"bar"}`'
		local table = AstNameTable.new()
		local lexer = Lexer.new(testInput, #testInput, table)

		local interpBegin = lexer:next()
		assert(interpBegin.type == Lexeme.Type.InterpStringBegin)

		local quote = lexer:next()
		assert(quote.type == Lexeme.Type.QuotedString)

		local interpEnd = lexer:next()
		assert(interpEnd.type == Lexeme.Type.InterpStringEnd)
	end,

	string_interpolation_full = function()
		local testInput = '`foo {"bar"} {"baz"} end`'
		local table = AstNameTable.new()
		local lexer = Lexer.new(testInput, #testInput, table)

		local interpBegin = lexer:next()
		assert(interpBegin.type == Lexeme.Type.InterpStringBegin)
		assert(interpBegin:toString() == "`foo {")

		local quote1 = lexer:next()
		assert(quote1.type == Lexeme.Type.QuotedString)
		assert(quote1:toString() == '"bar"')

		local interpMid = lexer:next()
		assert(interpMid.type == Lexeme.Type.InterpStringMid)
		assert(interpMid:toString() == "} {")

		local quote2 = lexer:next()
		assert(quote2.type == Lexeme.Type.QuotedString)
		assert(quote2:toString() == '"baz"')

		local interpEnd = lexer:next()
		assert(interpEnd.type == Lexeme.Type.InterpStringEnd)
		assert(interpEnd:toString() == "} end`")
	end,

	string_interpolation_double_brace = function()
		local testInput = "`foo{{bad}}bar`"
		local table = AstNameTable.new()
		local lexer = Lexer.new(testInput, #testInput, table)

		local brokenInterpBegin = lexer:next()
		assert(brokenInterpBegin.type == Lexeme.Type.BrokenInterpDoubleBrace)
		assert(brokenInterpBegin.data == "foo")

		assert(lexer:next().type == Lexeme.Type.Name)

		local interpEnd = lexer:next()
		assert(interpEnd.type == Lexeme.Type.InterpStringEnd)
		assert(interpEnd.data == "}bar")
	end,

	string_interpolation_double_but_unmatched_brace = function()
		local testInput = "`{{oops}`, 1"
		local table = AstNameTable.new()
		local lexer = Lexer.new(testInput, #testInput, table)

		assert(lexer:next().type == Lexeme.Type.BrokenInterpDoubleBrace)
		assert(lexer:next().type == Lexeme.Type.Name)
		assert(lexer:next().type == Lexeme.Type.InterpStringEnd)
		assert(lexer:next().type == string.byte(","))
		assert(lexer:next().type == Lexeme.Type.Number)
	end,

	string_interpolation_unmatched_brace = function()
		local testInput = '{\n`hello {"world"}\n} -- this might be incorrectly parsed as a string'
		local table = AstNameTable.new()
		local lexer = Lexer.new(testInput, #testInput, table)

		assert(lexer:next().type == string.byte("{"))
		assert(lexer:next().type == Lexeme.Type.InterpStringBegin)
		assert(lexer:next().type == Lexeme.Type.QuotedString)
		assert(lexer:next().type == Lexeme.Type.BrokenString)
		assert(lexer:next().type == string.byte("}"))
	end,

	string_interpolation_with_unicode_escape = function()
		local testInput = "`\u{1F41B}`"
		local table = AstNameTable.new()
		local lexer = Lexer.new(testInput, #testInput, table)

		assert(lexer:next().type == Lexeme.Type.InterpStringSimple)
		assert(lexer:next().type == Lexeme.Type.Eof)
	end
}