--[=[
	@class AstTableAccess

	For some reason binary numbers are used.
]=]

--[=[
	@within AstTableAccess
	@prop Read 0b01
	@readonly
	@since v0.1.0
]=]

--[=[
	@within AstTableAccess
	@prop Write 0b10
	@readonly
	@since v0.1.0
]=]

--[=[
	@within AstTableAccess
	@prop ReadWrite 0b11
	@readonly
	@since v0.1.0
]=]


return {
	Read = 0b01,
	Write = 0b10,
	ReadWrite = 0b11
}