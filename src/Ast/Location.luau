local Position = require("./Position")

type Position = Position.Position

--[=[
	@within Location
	@prop begin Position
	@readonly
	@since v0.1.0
]=]
--[=[
	@within Location
	@prop finish Position
	@readonly
	@since v0.1.0
]=]
local _

--[=[
	@class Location
	Struct from `root/Ast/src/Location.cpp`.
]=]
local Location = {}
local prototype = {}
local metatable = {__index = prototype}
export type Location = typeof(setmetatable({} :: {
	begin: Position.Position,
	finish: Position.Position
}, metatable))

--[=[
	@within Location
	@function new
	@param nil | Position | Location
	@param finish nil | Position | number | Location
	@return Location
	@since v0.1.0
	Arguments can be:
	- nil, nil
	- Position, number
	- Position, Position
	- Location, Location
]=]
function Location.new(begin: nil | Position.Position | Location, finish: nil | Position.Position | number | Location): Location
	local beginPosition = Position.is(begin)
	local finishPosition = Position.is(finish)
	local beginLocation = Location.is(begin)
	local finishLocation = Location.is(finish)
	
	local object
	if begin == nil and finish == nil then
		-- nil, nil
		object = {
			begin = Position.new(1, 1),
			finish = Position.new(1, 1)
		}
	elseif beginPosition and type(finish) == "number" then
		-- Position, number
		object = {
			begin = beginPosition,
			finish = Position.new(beginPosition.line, beginPosition.column + finish)
		}
	elseif beginPosition and finishPosition then
		-- Position, Position
		object = {
			begin = beginPosition,
			finish = finishPosition
		}
	elseif beginLocation and finishLocation then
		-- Location, Location
		object = {
			begin = beginLocation.begin,
			finish = finishLocation.finish
		}
	else
		error("Invalid arguments to Location constructor.")
	end
	return setmetatable(object, metatable)
end

--[=[
	@within Location
	@function is
	@param object any
	@return Location?
	@since v0.1.0
	Returns the object if it is a Location object.
]=]
function Location.is(object: any): Location?
	if getmetatable(object) == Location then
		return object
	else
		return nil
	end
end

--[=[
	@within Location
	@method __eq
	@param rhs Location
	@return boolean
	@since v0.1.0
	@tag metamethod
	Locations can be compared with just the equals sign.

	```lua
	local one = Location.new()
	local two = Location.new()
	assert(one == two)
	```
]=]
function metatable.__eq(self: Location, rhs: Location): boolean
	return self.begin == rhs.begin and self.finish == rhs.finish
end

--[=[
	@within Location
	@method encloses
	@param l Location
	@return boolean
	@since v0.1.0
	Whether the given Location is fully within self, inclusive.
]=]
function prototype.encloses(self: Location, l: Location): boolean
	return self.begin <= l.begin and self.finish >= l.finish
end

--[=[
	@within Location
	@method overlaps
	@param l Location
	@return boolean
	@since v0.1.0
	Whether the given Location intersects with self at all, inclusive.
]=]
function prototype.overlaps(self: Location, l: Location): boolean
	return self.begin <= l.begin and self.finish >= l.begin or self.begin <= l.finish and self.finish >= l.finish or self.begin >= l.begin and self.finish <= l.finish
end

--[=[
	@within Location
	@method contains
	@param p Position
	@return boolean
	@since v0.1.0
	Whether the given Position is within the bounds of self, except that it can not be at `self.finish`.
]=]
function prototype.contains(self: Location, p: Position.Position): boolean
	return self.begin <= p and p < self.finish
end

--[=[
	@within Location
	@method containsClosed
	@param p Position
	@return boolean
	@since v0.1.0
	Whether the given Position is within the bounds of self, inclusive.
]=]
function prototype.containsClosed(self: Location, p: Position.Position): boolean
	return self.begin <= p and p <= self.finish
end

--[=[
	@within Location
	@method extend
	@param other Location
	@since v0.1.0
	Ensures that both bounds are further than or at `other`'s bounds, respectively.
]=]
function prototype.extend(self: Location, other: Location): ()
	if other.begin < self.begin then
		self.begin = other.begin
	end
	if other.finish > self.finish then
		self.finish = other.finish
	end
end

--[=[
	@within Location
	@method shift
	@param start Position
	@param oldEnd Position
	@param newEnd Position
	@since v0.1.0
	Shifts both of self's Positions by `oldEnd` and `newEnd`.
]=]
function prototype.shift(self: Location, start: Position.Position, oldEnd: Position.Position, newEnd: Position.Position): ()
	self.begin:shift(start, oldEnd, newEnd)
	self.finish:shift(start, oldEnd, newEnd)
end

return Location