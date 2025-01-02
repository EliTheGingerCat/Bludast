local Location = require("./Location")

--[=[
	@class HotComment
	Struct from `root/Ast/include/Luau/ParseResult.cpp`.
]=]
--[=[
	@within HotComment
	@prop header boolean
	Whether the comment is part of the header of the file. This is false for all hot comments that appear after the first piece of non-comment code in a file.
]=]
--[=[
	@within HotComment
	@prop location Location
]=]
--[=[
	@within HotComment
	@prop content string
]=]
local HotComment = {}

function HotComment.new(header: boolean, location: Location.Location, content: string)
	return {
		header = header,
		location = location,
		content = content
	}
end
export type HotComment = typeof(HotComment.new(...))

return HotComment