local AstNode = require("./AstNode")

type AstNode = AstNode.AstNode

--[=[
	@class AstVisitor
]=]

--[=[
	@within AstVisitor
	@method visit
	@param node AstNode
	@return boolean -- Whether subnodes contained in `node` should be visited.
	@since v0.1.0
]=]
local _

export type AstVisitor = {
	visit: (
		self: AstVisitor,
		node: AstNode
	) -> boolean
}

return nil