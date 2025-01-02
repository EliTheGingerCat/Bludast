local AstName = require("./AstName")
local AstType = require("./AstType")

type AstName = AstName.AstName
type AstType = AstType.AstType

--[=[
	@class AstDeclaredClassProp

	Struct from [`/Ast/include/Luau/Ast.h`](https://github.com/luau-lang/luau/tree/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Ast.h#L864-L869)
]=]
local AstDeclaredClassProp = {}

function AstDeclaredClassProp.new(name: AstName, ty: AstType, isMethod: boolean)
	return {
		name = name,
		ty = ty,
		isMethod = isMethod
	}
end
export type AstDeclaredClassProp = typeof(AstDeclaredClassProp.new(...))

return AstDeclaredClassProp