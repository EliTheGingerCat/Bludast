local fs = require("@lune/fs")

local AstNameTable = require("./src/Ast/AstNameTable")
local ParseOptions = require("./src/Ast/ParseOptions")
local Parser = require("./src/Ast/Parser")

local source = fs.readFile("./src/Ast/Parser.luau")

local result = Parser.parse(source, #source, AstNameTable.new(), ParseOptions.new(false, true))

print(result)

return nil