export type Event = {
	type: number,
	token: number,
	data: number
}

local Event = {
	Type = {
		Enter = 0,
		Leave = 1,
		ArgName = 2,
		ArgValue = 3
	}
}

function Event.new(typeEvent: number, token: number, data: number): Event
	return {
		type = typeEvent,
		token = token,
		data = data
	}
end

return Event