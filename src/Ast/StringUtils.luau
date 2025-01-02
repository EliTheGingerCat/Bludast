--[=[
	@class StringUtils
	Library from `/Ast/src/StringUtils.cpp`.
]=]

local StringUtils = {}

function StringUtils.format(fmt: string, ...: any): string
	return fmt:format(...)
end

function StringUtils.vformat(fmt: string, ...: any): string
	return fmt:format(...)
end

return StringUtils