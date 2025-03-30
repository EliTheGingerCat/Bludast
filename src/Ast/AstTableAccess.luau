--[=[
	@class AstTableAccess

	For some reason binary numbers are used.
]=]

--[=[
	@within AstTableAccess
	@prop Read 0b01
	@readonly
]=]

--[=[
	@within AstTableAccess
	@prop Write 0b10
	@readonly
]=]

--[=[
	@within AstTableAccess
	@prop ReadWrite 0b11
	@readonly
]=]


return {
	Read = 0b01,
	Write = 0b10,
	ReadWrite = 0b11
}