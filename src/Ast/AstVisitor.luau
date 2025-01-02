local AstNode = require("./AstNode")

type AstNode = AstNode.AstNode

export type AstVisitor = {
	visit: (
		self: AstVisitor,
		node: AstNode
	) -> boolean
}

return nil