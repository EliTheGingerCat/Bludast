local Event = require("./Event")
local GlobalContext = require("./GlobalContext")
local Utilities = require("./Utilities")
local Vector = require("@Polyfill/Vector")

type Event = Event.Event
type GlobalContext = GlobalContext.GlobalContext
type Vector<T> = Vector.Vector<T>

local ThreadContext = {}
local prototype = {}
local metatable = {__index = prototype}

local kEventFlushLimit = 8192

export type ThreadContext = typeof(setmetatable({} :: {
	globalContext: GlobalContext,
	events: Vector<Event>,
	data: Vector<string>
}, metatable))

function ThreadContext.new(): ThreadContext
	return setmetatable({
		globalContext = Utilities.getGlobalContext(),
		events = Vector.new(),
		data = Vector.new()
	}, metatable) :: any
end

-- Eli: TODO call destroy
function prototype.destroy(self: ThreadContext): ()
	if not self.events:empty() then
		self:flushEvents()
	end
end

function prototype.flushEvents(self: ThreadContext): ()
	local flushToken = Utilities.createToken(self.globalContext, "flushEvents", "TimeTrace")

	self.events:push_back(Event.new(Event.Type.Enter, flushToken, os.clock()))
	
	Utilities.flushEvents(self.globalContext, self.events, self.data)

	self.events:clear()
	self.data:clear()

	self.events:push_back(Event.new(Event.Type.Leave, 0, os.clock()))
end

function prototype.eventEnter(self: ThreadContext, token: number, microsec: number?): ()
	local microSeconds = microsec or os.clock()
	self.events:push_back(Event.new(Event.Type.Enter, token, microSeconds))
end

function prototype.eventLeave(self: ThreadContext, microsec: number?): ()
	local microSeconds = microsec or os.clock()
	self.events:push_back(Event.new(Event.Type.Leave, 0, microSeconds))

	if self.events:size() > kEventFlushLimit then
		self:flushEvents()
	end
end

function prototype.eventArgument(self: ThreadContext, name: string, value: string): ()
	local pos = self.data:size()
	-- insert
	self.events:push_back(Event.new(Event.Type.ArgName, 0, pos))
	
	pos = self.data:size()
	-- insert
	self.events:push_back(Event.new(Event.Type.ArgValue, 0, pos))
end

return ThreadContext