local Token = require("./Token")
local Vector = require("../Vector")

type Token = Token.Token
type Vector<T> = Vector.Vector<T>

export type GlobalContext = {
	tokens: Vector<Token>,
	started: boolean
}

local GlobalContext = {}

function GlobalContext.new(): GlobalContext
	return {
		tokens = Vector.new(),
		started = false
	}
end

return GlobalContext