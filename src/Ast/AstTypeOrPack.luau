local AstNodeTypes = require("./AstNodeTypes")
local AstType = require("./AstType")
local AstTypePack = require("./AstTypePack")

type AstType = AstType.AstType
type AstTypePack = AstTypePack.AstTypePack

--[=[
	@class AstTypeOrPack
	@tag struct

	Struct from [`/Ast/include/Luau/Ast.h`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Ast.h#L919-L924).

	Either [type](AstTypeOrPack#type) or [typePack](AstTypeOrPack#typePack) will be populated and the other will be `nil`.
]=]
local AstTypeOrPack = {}

export type AstTypeOrPack = AstNodeTypes.AstTypeOrPack

--[=[
	@within AstTypeOrPack
	@function new
	@param typeAst AstType
	@param typePack AstTypePack
	@return AstTypeOrPack
]=]
-- Don't have Luau::Variant available, it's a bit of an overhead, but a plain struct is nice to use
function AstTypeOrPack.new(typeAst: AstType?, typePack: AstTypePack?): AstTypeOrPack
	return {
		type = typeAst,
		typePack = typePack
	}
end

return AstTypeOrPack