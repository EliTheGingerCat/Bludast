local ParseError = require("./ParseError")
local Vector = require("./Vector")

local ParseErrors = {}
local prototype = {}
local metatable = {__index = prototype}

function ParseErrors.new(errors: Vector.Vector<ParseError.ParseError>)
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
type ParseErrors = typeof(ParseErrors.new(...))

function prototype.what(self: ParseErrors): string
	return self.message
end

function prototype.getErrors(self: ParseErrors): Vector.Vector<ParseError.ParseError>
	return self.errors
end

return ParseErrors