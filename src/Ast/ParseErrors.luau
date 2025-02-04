local ParseError = require("./ParseError")
local Vector = require("@Polyfill/Vector")

type ParseError = ParseError.ParseError
type Vector<T> = Vector.Vector<T>

--[=[
	@class ParseErrors
]=]
local ParseErrors = {}
local prototype = {}
local metatable = {__index = prototype}

function ParseErrors.new(errors: Vector<ParseError>)
	local self = setmetatable({
		errors = errors
	}, metatable)

	assert(not self.errors:empty())

	if self.errors:size() == 1 then
		self.message = self.errors:front():what()
	else
		self.message = ("%d parse errors"):format(self.errors:size())
	end

	return self
end
export type ParseErrors = typeof(ParseErrors.new(...))

function metatable.__tostring(self: ParseError): string
	return self:what()
end

function prototype.what(self: ParseErrors): string
	return self.message
end

function prototype.getErrors(self: ParseErrors): Vector<ParseError>
	return self.errors
end

return ParseErrors