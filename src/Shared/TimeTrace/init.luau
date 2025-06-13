local FastVariables = require("@Shared/FastVariables")
local Scope = require("@self/Scope")
local Utilities = require("@self/Utilities")

type Scope = Scope.Scope

local TimeTrace = {}

local function createScopeData(name: string, category: string): number
	return Utilities.createToken(Utilities.getGlobalContext(), name, category)
end

function TimeTrace.LUAU_TIMETRACE_SCOPE(name: string, category: string): Scope?
	local lttScopeStatic = createScopeData(name, category)
	return Scope.new(lttScopeStatic)
end

function TimeTrace.LUAU_TIMETRACE_ARGUMENT(name: string, value: string, lttScope: Scope?): ()
	if FastVariables.DebugLuauTimeTracing then
		assert(lttScope).context:eventArgument(name, value)
	end
end

return TimeTrace