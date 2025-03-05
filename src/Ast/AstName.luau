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
	value: string?
}, metatable))

--[=[
	@within AstName
	@function new
	@param value string?
	@return AstName
]=]
function AstName.new(value: string?): AstName
	return setmetatable({
		value = value
	}, metatable)
end

function AstName.is(object: AstName): boolean
	return getmetatable(object) == metatable
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
	if self.value and rhs.value then
		return self.value < rhs.value
	elseif self.value == nil and rhs.value == nil then
		return false
	else
		return self.value == nil
	end
end

return AstName