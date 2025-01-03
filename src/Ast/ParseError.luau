local Location = require("./Location")
local StringUtils = require("./StringUtils")

type Location = Location.Location

--[=[
	@class ParseError
	Class from `root/Ast/src/Parser.cpp`.
]=]

local ParseError = {}
local prototype = {}
local metatable = {__index = prototype}

export type ParseError = typeof(setmetatable({} :: {
	--[=[
		@within ParseError
		@prop location Location
		@readonly
		@private
		@since v0.1.0
	]=]
	location: Location,

	--[=[
		@within ParseError
		@prop message string
		@readonly
		@private
		@since v0.1.0
	]=]
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
	@function raise
	@param location Location
	@param format string
	@param ... any
	@since v0.1.0
]=]
function ParseError.raise(location: Location, format: string, ...: any): ()
	local message = StringUtils.vformat(format, ...)

	error(ParseError.new(location, message))
end

--[=[
	@within ParseError
	@method getLocation
	@return Location
	@since v0.1.0
]=]
function prototype.getLocation(self: ParseError): Location
	return self.location
end

--[=[
	@within ParseError
	@method getMessage
	@return string
	@since v0.1.0
]=]
function prototype.getMessage(self: ParseError): string
	return self.message
end

--[=[
	@within ParseError
	@method what
	@return string
	@since v0.1.0

	Same as ParseError:getMessage() though in the C++ version it returns the message as a C string.
]=]
prototype.what = prototype.getMessage

return ParseError