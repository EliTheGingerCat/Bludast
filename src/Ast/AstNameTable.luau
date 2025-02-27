local AstName = require("@Ast/AstName")
local Lexeme = require("@Ast/Lexeme")
local Pair = require("@Polyfill/Pair")

type AstName = AstName.AstName
type Pair<T1, T2> = Pair.Pair<T1, T2>

--[=[
	@class AstNameTable_Entry
	Struct from `/Ast/src/Lexer.cpp > AstNameTable`.
]=]
local Entry = {}

export type Entry = {
	--[=[
		@within AstNameTable_Entry
		@prop value AstName
		@readonly
		@since v0.1.0
	]=]
	value: AstName,

	--[=[
		@within AstNameTable_Entry
		@prop length number
		@readonly
		@since v0.1.0
	]=]
	length: number,

	--[=[
		@within AstNameTable_Entry
		@prop type number
		@readonly
		@since v0.1.0

		Corresponds to [lexeme type](Lexeme#Type).
	]=]
	type: number
}

--[=[
	@within AstNameTable_Entry
	@function new
	@param value AstName
	@param length number
	@param typeLex number
	@return Entry
]=]
function Entry.new(value: AstName, length: number, typeLex: number): Entry
	return {
		value = value,
		length = length,
		type = typeLex
	}
end

--[=[
	@within AstNameTable_Entry
	@method __eq
	@param other Entry
	@return boolean
	@tag metamethod
]=]
function Entry.__eq(self: Entry, other: Entry): boolean
	return self.value.value == other.value.value
end

local prototype = {}

--[=[
	@class AstNameTable
	@__index prototype

	Class from `/Ast/src/Lexer.cpp`.
]=]
local AstNameTable = {
	prototype = prototype
}

local metatable = {
	__index = prototype
}

export type AstNameTable = typeof(setmetatable({} :: {
	data: {
		[string]: Entry
	}
}, metatable))

function AstNameTable.new(): AstNameTable
	return setmetatable({
		data = {}
	}, metatable)
end

--[=[
	@within AstNameTable
	@since v0.1.0
]=]
function prototype.addStatic(self: AstNameTable, name: string, typeLexeme: number): AstName
	local entry = Entry.new(AstName.new(name), #name, typeLexeme)

	-- No need for EntryHash, Luau tables already use hashing. Perhaps it is still more efficient to use FNV1a though?
	self.data[name] = entry

	return entry.value
end

--[=[
	@within AstNameTable
	@since v0.1.0
]=]
function prototype.getOrAddWithType(self: AstNameTable, name: string, length: number): Pair<AstName, number>
	local entry = Entry.new(AstName.new(name), length, Lexeme.Type.Eof)
	
	-- entry already was inserted
	if self.data[name] then
		return Pair.new(entry.value, entry.type)
	end

	entry.type = if name:sub(1, 1) == "@" then Lexeme.Type.Attribute else Lexeme.Type.Name

	return Pair.new(entry.value, entry.type)
end

--[=[
	@within AstNameTable
	@since v0.1.0
]=]
function prototype.getWithType(self: AstNameTable, name: string, length: number): Pair<AstName, number>
	local entry = self.data[name]; if entry then
		return Pair.new(entry.value, entry.type)
	end
	return Pair.new(AstName.new(), Lexeme.Type.Name)
end

--[=[
	@within AstNameTable
	@since v0.1.0
]=]
function prototype.getOrAdd(self: AstNameTable, name: string): AstName
	return self:getOrAddWithType(name, #name).first
end

--[=[
	@within AstNameTable
	@method get
	@param name string
	@return AstName
	@since v0.1.0
]=]
function prototype.get(self: AstNameTable, name: string): AstName
	return self:getWithType(name, #name).first
end

return AstNameTable