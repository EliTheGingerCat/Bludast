local AstStatBlock = require("./AstStatBlock")
local Comment = require("./Comment")
local HotComment = require("./HotComment")
local ParseError = require("./ParseError")
local Vector = require("./Vector")

type AstStatBlock = AstStatBlock.AstStatBlock
type Comment = Comment.Comment
type HotComment = HotComment.HotComment
type ParseError = ParseError.ParseError
type Vector<T> = Vector.Vector<T>

export type ParseResult = {
	root: AstStatBlock?,
	lines: number,

	hotcomments: Vector<HotComment>,
	errors: Vector<ParseError>,
	
	commentLocations: Vector<Comment>
}

--[=[
	@class ParseResult
]=]
local ParseResult = {}

function ParseResult.new(root: AstStatBlock?, lines: number, hotcomments: Vector<HotComment>?, errors: Vector<ParseError>, commentLocations: Vector<Comment>?): ParseResult
	return {
		root = root,
		lines = lines,
		hotcomments = hotcomments or Vector.new(),
		errors = errors,
		commentLocations = commentLocations or Vector.new()
	}
end

return ParseResult