local Location = require("@Shared/Location")

type Location = Location.Location

--[=[
	@class ParseError
	Class from `root/Ast/src/Parser.cpp`.
]=]

local ParseError = {}
local prototype = {}
local metatable = {__index = prototype}

--[=[
	@within ParseError
	@prop location Location
	@readonly
	@private
	@since v0.1.0
]=]

--[=[
	@within ParseError
	@prop message string
	@readonly
	@private
	@since v0.1.0
]=]

export type ParseError = typeof(setmetatable({} :: {
	location: Location,
	message: string
}, metatable))

--[=[
	@within ParseError
	@function new
	@param location Location
	@param message string
]=]
function ParseError.new(location: Location, message: string)
	return setmetatable({
		location = location,
		message = message
	}, metatable)
end

--[=[
	@within ParseError
	@since v0.1.0
]=]
function ParseError.raise(location: Location, message: string): never
	error(ParseError.new(location, message))
end

--[=[
	@within ParseError
	@since v0.1.0
]=]
function prototype.getLocation(self: ParseError): Location
	return self.location
end

--[=[
	@within ParseError
	@since v0.1.0
]=]
function prototype.getMessage(self: ParseError): string
	return self.message
end

--[=[
	@within ParseError
	@function what
	@param self ParseError
	@return string
	@since v0.1.0

	Same as ParseError:getMessage() though in the C++ version it returns the message as a C string.
]=]
prototype.what = prototype.getMessage

return ParseError