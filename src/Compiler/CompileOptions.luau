export type CompileOptions = {
	optimizationLevel: number,

	debugLevel: number,

	typeInfoLevel: number,

	coverageLevel: number,

	vectorLib: string?,
	vectorCtor: string?,

	vectorType: string?,

	mutableGlobals: {string}?,
	
	userdataTypes: {string}
}

--[=[
	@class CompileOptions
]=]
local CompileOptions = {}

--[=[
	@within CompileOptions
	@prop optimizationLevel number
	@readonly
	@since v0.1.0

	- 0 - no optimization
	- 1 - baseline optimization level that doesn't prevent debuggability
	- 2 - includes optimizations that harm debuggability such as inlining
]=]
--[=[
	@within CompileOptions
	@prop debugLevel number
	@readonly
	@since v0.1.0

	- 0 - no debugging support
	- 1 - line info & function names only; sufficient for backtraces
	- 2 - full debug info with local & upvalue names; necessary for debugger
]=]
--[=[
	@within CompileOptions
	@prop typeInfoLevel number
	@readonly
	@since v0.1.0

	type information is used to guide native code generation decisions

	information includes testable types for function arguments, locals, upvalues and some temporaries


	- 0 - generate for native modules
	- 1 - generate for all modules
]=]
--[=[
	@within CompileOptions
	@prop coverageLevel number
	@readonly
	@since v0.1.0

	- 0 - no code coverage support
	- 1 - statement coverage
	- 2 - statement and expression coverage (verbose)
]=]
--[=[
	@within CompileOptions
	@prop vectorLib string?
	@readonly
	@since v0.1.0

	global builtin to construct vectors; disabled by default
]=]
--[=[
	@within CompileOptions
	@prop vectorCtor string?
	@readonly
	@since v0.1.0

	See [vectorLib](CompileOptions#vectorLib).
]=]
--[=[
	@within CompileOptions
	@prop vectorType string?
	@readonly
	@since v0.1.0

	vector type name for type tables; disabled by default
]=]
--[=[
	@within CompileOptions
	@prop mutableGlobals string?
	@readonly
	@since v0.1.0

	null-terminated array of globals that are mutable; disables the import optimization for fields accessed through these
]=]
--[=[
	@within CompileOptions
	@prop userdataTypes string?
	@readonly
	@since v0.1.0

	null-terminated array of userdata types that will be included in the type information
]=]
local _

function CompileOptions.new(optimizationLevel: number?, debugLevel: number?, typeInfoLevel: number?, coverageLevel: number?, vectorLib: string?, vectorCtor: string?, vectorType: string?, mutableGlobals: {string}?, userdataTypes: {string}?): CompileOptions
	return {
		optimizationLevel = optimizationLevel or 1,
		debugLevel = debugLevel or 1,
		typeInfoLevel = typeInfoLevel or 0,
		coverageLevel = coverageLevel or 0,
		vectorLib = vectorLib,
		vectorCtor = vectorCtor,
		vectorType = vectorType,
		mutableGlobals = mutableGlobals,
		userdataTypes = userdataTypes or {}
	}
end

return CompileOptions