local GlobalContext = require("./GlobalContext")
local Scope = require("./Scope")
local Utilities = require("./Utilities")

type GlobalContext = GlobalContext.GlobalContext

local TimeTrace = {}

local function createScopeData(name: string, category: string): number
	return Utilities.createToken(Utilities.getGlobalContext(), name, category)
end

function TimeTrace.LUAU_TIMETRACE_SCOPE(name: string, category: string): ()
	local lttScopeStatic = createScopeData(name, category)
	Scope.new(lttScopeStatic)
end

return TimeTrace