local Location = require("@Shared/Location")

type Location = Location.Location

--[=[
	@class CompileError
	Class from `root/Compiler/src/Compiler.cpp`.
]=]

local CompileError = {}
local prototype = {}
local metatable = {__index = prototype}

export type CompileError = typeof(setmetatable({} :: {
	--[=[
		@within CompileError
		@prop location Location
		@readonly
		@private
		@since v0.1.0
	]=]
	location: Location,

	--[=[
		@within CompileError
		@prop message string
		@readonly
		@private
		@since v0.1.0
	]=]
	message: string
}, metatable))

--[=[
	@within CompileError
	@function new
	@param location Location
	@param message string
]=]
function CompileError.new(location: Location, message: string)
	return setmetatable({
		location = location,
		message = message
	}, metatable)
end

--[=[
	@within CompileError
	@function raise
	@param location Location
	@param format string
	@param ... any
	@since v0.1.0
]=]
function CompileError.raise(location: Location, format: string, ...: any): ()
	local message = format:format(...)

	error(CompileError.new(location, message))
end

--[=[
	@within CompileError
	@method getLocation
	@return Location
	@since v0.1.0
]=]
function prototype.getLocation(self: CompileError): Location
	return self.location
end

--[=[
	@within CompileError
	@method what
	@return string
	@since v0.1.0
]=]
function prototype.what(self: CompileError): string
	return self.message
end

return CompileError