--[=[
	@class ParseOptions

	Struct from `root/Ast/include/Luau/ParseOptions.h`.
]=]
local ParseOptions = {}
export type ParseOptions = {
	allowDeclarationSyntax: boolean,
	captureComments: boolean
}

--[=[
	@within ParseOptions
	@interface ModeEnum

	.NoCheck 1    -- Do not perform any inference
	.Nonstrict 2  -- Unannotated symbols are any
	.Strict 3     -- Unannotated symbols are inferred
	.Definition 4 -- Type definition module, has special parsing rules
]=]
--[=[
	@within ParseOptions
	@prop Mode ModeEnum
	@readonly
	@since v0.1.0
]=]
ParseOptions.Mode = {
	NoCheck = 1,    -- Do not perform any inference
	Nonstrict = 2,  -- Unannotated symbols are any
	Strict = 3,     -- Unannotated symbols are inferred
	Definition = 4, -- Type definition module, has special parsing rules
}

--[=[
	@within ParseOptions
	@since v0.1.0
]=]
function ParseOptions.new(allowDeclarationSyntax: boolean?, captureComments: boolean?): ParseOptions
	return {
		allowDeclarationSyntax = allowDeclarationSyntax or false,
		captureComments = captureComments or false
	}
end

return ParseOptions