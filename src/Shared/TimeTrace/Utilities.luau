local fs
local Event = require("./Event")
local GlobalContext = require("./GlobalContext")
local Token = require("./Token")
local Vector = require("@Polyfill/Vector")

if _VERSION:sub(1, 4) == "Lune" then
	fs = (require)("@lune/fs")
end

type Event = Event.Event
type GlobalContext = GlobalContext.GlobalContext
type Vector<T> = Vector.Vector<T>

local Utilities = {}

local FILE_NAME = "./trace.json"
local GLOBAL_CONTEXT = GlobalContext.new()

function Utilities.createToken(context: GlobalContext, name: string, category: string): number
	assert(context.tokens:size() < 64 * 1024)

	context.tokens:push_back(Token.new(name, category))
	return context.tokens:size() - 1
end

function Utilities.flushEvents(context: GlobalContext, events: Vector<Event>, data: Vector<string>)
	if not context.started then
		context.started = true
		
		fs.writeFile(FILE_NAME, "[\n")
	end

	local temp = ""

	local unfinishedEnter = false
	local unfinishedArgs = false

	for _, ev in events:data() do
		local case = ev.type
		if case == Event.Type.Enter then
			if unfinishedArgs then
				temp ..= "}"
				unfinishedArgs = false
			end

			if unfinishedEnter then
				temp ..= "},\n"
				unfinishedEnter = false
			end

			local token = context.tokens:get(ev.token)

			temp ..= ('{"name": "%s", "cat": "%s", "ph": "B", "ts": %u, "pid": 0'):format(token.name, token.category, ev.data)
			unfinishedEnter = true
		elseif case == Event.Type.Leave then
			if unfinishedArgs then
				temp ..= "}"
				unfinishedArgs = false
			end
			if unfinishedEnter then
				temp ..= "},\n"
				unfinishedEnter = false
			end

			temp ..= ('{"ph": "E", "ts": %u, "pid": 0},'):format(ev.data)
		elseif case == Event.Type.ArgName then
			if not unfinishedArgs then
				temp ..= (', "args": { "%s": '):format(data:get(ev.data))
				unfinishedArgs = true
			else
				temp ..= (', "%s": '):format(data:get(ev.data))
			end
		elseif case == Event.Type.ArgValue then
			temp ..= ('"%s"'):format(data:get(ev.data))
		end
	end

	if unfinishedArgs then
		temp ..= "}"
		unfinishedArgs = false
	end
	if unfinishedEnter then
		temp ..= "},\n"
		unfinishedEnter = false
	end

	fs.writeFile(FILE_NAME, temp)
end

function Utilities.getGlobalContext(): GlobalContext
	return GLOBAL_CONTEXT
end

return Utilities