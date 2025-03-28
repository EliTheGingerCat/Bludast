--!nolint LocalShadow

local AstNode = require("@Ast/AstNode")
local AstType = require("@Ast/AstType")
local AstTypePack = require("@Ast/AstTypePack")
local AstVisitor = require("@Ast/AstVisitor")
local LUAU_ASSERT = require("@Shared/LUAU_ASSERT")

type AstNode = AstNode.AstNode
type AstType = AstType.AstType
type AstTypePack = AstTypePack.AstTypePack
type AstVisitor = AstVisitor.AstVisitor
type class<T> = AstNode.class<T>

type Nth = {
	classIndex: number,
	nth: number
}

local prototype = setmetatable({}, AstVisitor.metatable)
local metatable = {__index = prototype}
local FindNthOccurenceOf = {}
type FindNthOccurenceOf = AstVisitor & {
	requestedNth: Nth,
	currentOccurance: number,
	theNode: AstNode?,

	checkIt: (self: FindNthOccurenceOf, n: AstNode) -> boolean
}

function FindNthOccurenceOf.new(nth: Nth): FindNthOccurenceOf
	local self = AstVisitor.new() :: FindNthOccurenceOf
	self.requestedNth = nth
	self.currentOccurance = 0
	setmetatable(self, metatable)
	return self
end

function prototype.checkIt(self: FindNthOccurenceOf, n: AstNode): boolean
	if self.theNode then
		return false
	end

	if n.classIndex == self.requestedNth.classIndex then
		-- Human factor: the requestedNth starts from 1 because of the term `nth`.
		if self.currentOccurance + 1 ~= self.requestedNth.nth then
			self.currentOccurance += 1
		else
			self.theNode = n
		end
	end

	return not self.theNode -- once found, returns false and stops traversal
end

function prototype.visit(self: FindNthOccurenceOf, n: AstNode): boolean
	return self:checkIt(n)
end

function prototype.visitAstType(self: FindNthOccurenceOf, t: AstType): boolean
	return self:checkIt(t)
end

function prototype.visitAstTypePack(self: FindNthOccurenceOf, t: AstTypePack): boolean
	return self:checkIt(t)
end

--[=[
	@class AstQueryDsl
]=]
local AstQueryDsl = {}

--[=[
	@within AstQueryDsl
	@since 0.1.0
]=]
function AstQueryDsl.nth(T: class<any>, nth: number?): Nth
	local nth = nth or 1
	LUAU_ASSERT(nth > 0) -- Did you mean to use `nth<T>(1)`?

	return {
		classIndex = T.ClassIndex,
		nth = nth
	}
end

--[=[
	@within AstQueryDsl
	@since 0.1.0

	DSL querying of the AST.
	
	Given an AST, one can query for a particular node directly without having to manually unwrap the tree, for example:

	```lua
	if a and b then
		print(a + b)
	end

	function f(x, y)
		return x + y
	end
	```

	There are numerous ways to access the second AstExprBinary.
	1. Luau::query<AstExprBinary>(block, {nth<AstStatFunction>(), nth<AstExprBinary>()})
	2. Luau::query<AstExprBinary>(Luau::query<AstStatFunction>(block))
	3. Luau::query<AstExprBinary>(block, {nth<AstExprBinary>(2)})
]=]
function AstQueryDsl.query<T>(T: class<T>, N: number?, node: AstNode, nths: {Nth}?): T?
	local N = N or 1
	local nths = nths or {AstQueryDsl.nth(T, N)} :: {Nth}
	local node = node :: AstNode?

	for _, nth in nths do
		if not node then
			return nil
		end

		local finder = FindNthOccurenceOf.new(nth)
		node:visit(finder)
		node = finder.theNode
	end

	return if node then node:as(T) else nil
end

return AstQueryDsl