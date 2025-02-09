local AstNodeTypes = require("./AstNodeTypes")
local AstType = require("./AstType")
local AstTypePack = require("./AstTypePack")

type AstType = AstType.AstType
type AstTypePack = AstTypePack.AstTypePack

--[=[
	@class AstTypeList
	@tag struct

	Struct from [`/Ast/include/Luau/Ast.h`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Ast.h#L114-L119).
]=]
local AstTypeList = {}

export type AstTypeList = AstNodeTypes.AstTypeList

--[=[
	@within AstTypeList
	@function new
	@param types {AstType}
	@param tailType AstTypePack?
	@return AstTypeList
]=]
function AstTypeList.new(types: {AstType}, tailType: AstTypePack?): AstTypeList
	return {
		types = types,
		tailType = tailType
	}
end

return AstTypeList