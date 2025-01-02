export type Token = {
	name: string,
	category: string
}

local Token = {}

function Token.new(name: string, category: string): Token
	return {
		name = name,
		category = category
	}
end

return Token