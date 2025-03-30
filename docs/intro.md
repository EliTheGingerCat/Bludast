Bludast currently does not have an easy-to-use API. Here is a code snippet to get bytecode from source, using Bludast alises:

```lua
local AstNameTable = require("@Ast/AstNameTable")
local BytecodeBuilder = require("@Compiler/BytecodeBuilder")
local Compiler = require("@Compiler/Compiler")
local CompileOptions = require("@Compiler/CompileOptions")
local Parser = require("@Ast/Parser")
local ParseOptions = require("@Ast/ParseOptions")

local PARSE_OPTIONS = ParseOptions.new(false, true)
local COMPILE_OPTIONS = CompileOptions.new(2, 1, 0)

local function compile(source: string): string
	local names = AstNameTable.new()
	local root = Parser.parse(source, #source, names, PARSE_OPTIONS)
	local builder = BytecodeBuilder.new()
	Compiler.compileOrThrow(builder, root, names, COMPILE_OPTIONS)
	return builder:getBytecode()
end

local source = [[
print("Hello, world!")
]]

local bytecode = compile(source)

print(bytecode)
```