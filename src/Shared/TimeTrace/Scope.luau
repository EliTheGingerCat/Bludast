local FastVariables = require("../FastVariables")
local ThreadContext = require("./ThreadContext")

type ThreadContext = ThreadContext.ThreadContext

local Scope = {}
local prototype = {}
local metatable = {__index = prototype}

export type Scope = typeof(setmetatable({} :: {
	context: ThreadContext
}, metatable))

function Scope.new(token: number)
	local self = setmetatable({
		context = ThreadContext.new()
	}, metatable)

	if not FastVariables.DebugLuauTimeTracing then
		return
	end

	self.context:eventEnter(token)

	return self
end

-- Eli: TODO call destroy
function prototype.destroy(self: Scope): ()
	if not FastVariables.DebugLuauTimeTracing then
		return
	end

	self.context:eventLeave()
end

return Scope