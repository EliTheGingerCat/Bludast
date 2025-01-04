local Location = require("./Location")


--[=[
	@within Comment
	@prop type number

	Comment, BlockComment, or BrokenComment
]=]
--[=[
	@within Comment
	@prop location Location
]=]
local _

--[=[
	@class Comment
	
	Class from `root/Ast/include/Luau/ParseResult.cpp`.
]=]
local Comment = {}

--- @within Comment
function Comment.new(typeLex: number, location: Location.Location)
	return {
		type = typeLex,
		location = location
	}
end
export type Comment = typeof(Comment.new(...))

return Comment