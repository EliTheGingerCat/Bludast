--[=[
	@class Position
	Struct from `root/Ast/src/Location.cpp`.
]=]
local Position = {}
local prototype = {}
local metatable = {__index = prototype}

--[=[
	@within Position
	@prop line number
	@since v0.1.0
]=]
--[=[
	@within Position
	@prop column number
	@since v0.1.0
]=]
local _

export type Position = typeof(setmetatable({} :: {
	line: number,
	column: number
}, metatable))

--[=[
	@within Position
	@function new
	@param line number
	@param column number
	@return Position
	@since v0.1.0
]=]
function Position.new(line: number, column: number): Position
	return setmetatable({
		line = line,
		column = column
	}, metatable)
end

--[=[
	@within Position
	@function is
	@param object any
	@return Position?
	@since v0.1.0
]=]
function Position.is(object: any): Position?
	if getmetatable(object) == metatable then
		return object
	else
		return nil
	end
end

--[=[
	@within Position
	@method __eq
	@param rhs Position
	@return boolean
	@since v0.1.0
	@tag metamethod
]=]
function metatable.__eq(self: Position, rhs: Position): boolean
	return self.line == rhs.line and self.column == rhs.column
end

--[=[
	@within Position
	@method __lt
	@param rhs Position
	@return boolean
	@since v0.1.0
	@tag metamethod
]=]
function metatable.__lt(self: Position, rhs: Position): boolean
	if self.line == rhs.line then
		return self.column < rhs.column
	else
		return self.line < rhs.line
	end
end

--[=[
	@within Position
	@method __le
	@param rhs Position
	@return boolean
	@since v0.1.0
	@tag metamethod
]=]
function metatable.__le(self: Position, rhs: Position): boolean
	return self == rhs or self < rhs
end

--[=[
	@within Position
	@method shift
	@param start Position
	@param oldEnd Position
	@param newEnd Position
	@since v0.1.0
]=]
function prototype.shift(self: Position, start: Position, oldEnd: Position, newEnd: Position): ()
	if self >= start then
		if self.line < oldEnd.line then
			self.line += newEnd.line - oldEnd.line
		else
			self.line = newEnd.line
			self.column += newEnd.column - oldEnd.column
		end
	end
end

return Position