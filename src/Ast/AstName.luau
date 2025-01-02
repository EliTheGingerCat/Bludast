--[=[
	@class AstName
	Struct from `root/Ast/include/Luau/Ast.h`.
]=]
--[=[
	@within AstName
	@prop value string
	@since v0.1.0
]=]
local AstName = {}
local metatable = {}
export type AstName = typeof(setmetatable({} :: {
	value: string
}, metatable))

--[=[
	@within AstName
	@function new
	@param value string?
	@return AstName
]=]
function AstName.new(value: string?): AstName
	return setmetatable({
		value = value or ""
	}, metatable)
end

--[=[
	@within AstName
	@method __eq
	@param rhs AstName
	@return boolean
	@tag metamethod
]=]
function metatable.__eq(self: AstName, rhs: AstName): boolean
	return self.value == rhs.value
end

--[=[
	@within AstName
	@method __lt
	@param rhs AstName
	@return boolean
	@tag metamethod
]=]
function metatable.__lt(self: AstName, rhs: AstName): boolean
	return self.value < rhs.value
end

return AstName