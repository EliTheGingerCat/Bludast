--[=[
	@class AstTableAccess
	@tag enum class

	For some reason binary numbers are used.
]=]
return {
	--[=[
		@within AstTableAccess
		@prop Read 0b01
	]=]
	Read = 0b01,

	--[=[
		@within AstTableAccess
		@prop Write 0b10
	]=]
	Write = 0b10,

	--[=[
		@within AstTableAccess
		@prop ReadWrite 0b11
	]=]
	ReadWrite = 0b11
}