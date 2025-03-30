--[=[
	@class FastVariables
	
	Luau settings that can be changed to quickly revert an update. In Bludast's case, one would need to set the flags before initialisation, so they are not really that fast. These variables are found all over C++ files. The C++ code distinguishes between flags and integers, but here we group everything together.
]=]

--[=[
	@within FastVariables
	@prop DebugLuauTimeTracing false
	@readonly
	@since v0.1.0

	Time tracing allows for seeing how long each operation takes.
]=]

--[=[
	@within FastVariables
	@prop LuauAttributeSyntax false
	@readonly
	@since v0.1.0

	Attributes modify functions.
	
	See: https://rfcs.luau.org/syntax-attributes-functions.html

	Example:

	```lua
	 @native
	local function quick(n: number): number
		for i = 1, 1_000 do
			n += i
		end
		return n
	end
	```
]=]

--[=[
	@within FastVariables
	@prop LuauAttributeSyntaxFunExpr false
	@readonly
	@since v0.1.0

	Whether function expressions can have attributes.

	```lua
	local name = (@native function()
		local raw = "Hello, my name is Michael."
		local name = raw:match("Hello, my name is (%u%l+)%.")
		if name then
			return name
		else
			return "Unknown"
		end
	end)
	```
]=]

--[=[
	@within FastVariables
	@prop LuauCompileInlineDepth 5
	@readonly
	@since v0.1.0
]=]

--[=[
	@within FastVariables
	@prop LuauCompileInlineThreshold 25
	@readonly
	@since v0.1.0
]=]

--[=[
	@within FastVariables
	@prop LuauCompileInlineThresholdMaxBoost 300
	@readonly
	@since v0.1.0
]=]

--[=[
	@within FastVariables
	@prop LuauCompileLoopUnrollThreshold 25
	@readonly
	@since v0.1.0
]=]

--[=[
	@within FastVariables
	@prop LuauCompileLoopUnrollThresholdMaxBoost 300
	@readonly
	@since v0.1.0
]=]

--[=[
	@within FastVariables
	@prop LuauCompileTempTypeInfo false
	@readonly
	@since v0.1.0
]=]

--[=[
	@within FastVariables
	@prop LuauCompileTypeInfo false
	@readonly
	@since v0.1.0

	Writes type information into the bytecode.
]=]

--[=[
	@within FastVariables
	@prop LuauCompileUserdataInfo false
	@readonly
	@since v0.1.0

	Writes userdata information into the bytecode.
]=]

--[=[
	@within FastVariables
	@prop LuauLeadingBarAndAmpersand2 false
	@readonly
	@since v0.1.0

	Allows for leading `|` and `&` when defining types.

	```lua
	type name =
		| "Fred"
		| "Jones"
	```
]=]

--[=[
	@within FastVariables
	@prop LuauLexerLookaheadRemembersBraceType false
	@readonly
	@since v0.1.0
]=]

--[=[
	@within FastVariables
	@prop LuauParseErrorLimit 100
	@readonly
	@since v0.1.0
]=]

--[=[
	@within FastVariables
	@prop LuauNativeAttribute false
	@readonly
	@since v0.1.0

	Native functions are compiled to machine code, resulting in higher performance.  
	See: https://create.roblox.com/docs/luau/native-code-gen

	This flag determines if the `@native` attribute is enabled.

	```lua
	 @native
	local function quick(n: number): number
		for i = 1, 1_000 do
			n += i
		end
		return n
	end
	```
]=]

--[=[
	@within FastVariables
	@prop LuauRecursionLimit 1000
	@readonly
	@since v0.1.0
	
	The maximum amount of times the parser may recurse. This is not like function recursion - expressions, type annotations, et cetera are the items in question.
]=]

--[=[
	@within FastVariables
	@prop LuauTypeLengthLimit 1000
	@readonly
	@since v0.1.0

	Determines how many individual types there may be to a composite type.

	```lua
	type data = string | number -- length = 2
	```
]=]

return {
	DebugLuauTimeTracing = false,
	LuauAttributeSyntax = false,
	LuauAttributeSyntaxFunExpr = false,
	LuauCompileInlineDepth = 5,
	LuauCompileInlineThreshold = 25,
	LuauCompileInlineThresholdMaxBoost = 300,
	LuauCompileLoopUnrollThreshold = 25,
	LuauCompileLoopUnrollThresholdMaxBoost = 300,
	LuauCompileTempTypeInfo = false,
	LuauCompileTypeInfo = false,
	LuauCompileUserdataInfo = false,
	LuauLeadingBarAndAmpersand2 = false,
	LuauLexerLookaheadRemembersBraceType = false,
	LuauParseErrorLimit = 100,
	LuauNativeAttribute = false,
	LuauRecursionLimit = 1000,
	LuauTypeLengthLimit = 1000
}