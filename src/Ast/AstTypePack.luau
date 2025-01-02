local AstNode = require("./AstNode")
local Location = require("./Location")

type AstNode = AstNode.AstNode
type Location = Location.Location

export type AstTypePack = AstNode

--[=[
	@class AstTypePack

	Class from [`/Ast/include/Luau/Ast.h`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Ast.h#1091-1098).

	This is literally just a wrapper for AstNode.
]=]
local AstTypePack = {}

function AstTypePack.new(classIndex: number, location): AstTypePack
	return AstNode.interface.new(classIndex, location)
end

return AstTypePack