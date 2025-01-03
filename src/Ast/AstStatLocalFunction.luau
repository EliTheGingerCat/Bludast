local AstClassIndex = require("./AstClassIndex")
local AstExprFunction = require("./AstExprFunction")
local AstLocal = require("./AstLocal")
local AstStat = require("./AstStat")
local AstVisitor = require("./AstVisitor")
local Location = require("./Location")

type AstExprFunction = AstExprFunction.AstExprFunction
type AstLocal = AstLocal.AstLocal
type AstStat = AstStat.AstStat
type AstVisitor = AstVisitor.AstVisitor
type Location = Location.Location

export type AstStatLocalFunction = AstStat & {
	name: AstLocal,
	func: AstExprFunction
}

--[=[
	@class AstStatLocalFunction

	Class from [`/Ast/src/Ast.cpp`](https://github.com/luau-lang/luau/blob/7d4033071abebe09971b410d362c00ffb3084afb/Ast/src/Ast.cpp#L663-L674) and [`/Ast/include/Luau/Ast.h`](https://github.com/luau-lang/luau/blob/7d4033071abebe09971b410d362c00ffb3084afb/Ast/include/Luau/Ast.h#L793-L804).

	```lua
	local function name()
		-- body
	end
	```
]=]
local AstStatLocalFunction = {
	ClassIndex = AstClassIndex(),
	ClassType = (nil :: any) :: AstStatLocalFunction
}
local prototype = setmetatable({}, AstStat.metatable)
local metatable = {__index = prototype}

function AstStatLocalFunction.new(location: Location, name: AstLocal, func: AstExprFunction): AstStatLocalFunction
	local self = AstStat.interface.new(AstStatLocalFunction.ClassIndex, location) :: AstStatLocalFunction
	self.name = name
	self.func = func
	setmetatable(self, metatable)
	return self
end

function prototype.visit(self: AstStatLocalFunction, visitor: AstVisitor): ()
	if visitor:visit(self) then
		self.func:visit(visitor)
	end
end

return AstStatLocalFunction