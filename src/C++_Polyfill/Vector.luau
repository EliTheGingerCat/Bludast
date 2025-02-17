--[=[
	@class Vector
	
	Class template from [C++ std](https://cplusplus.com/reference/vector/vector/).
]=]
local Vector = {}
local prototype = {}
local metatable = {__index = prototype}

Vector.prototype = prototype

--[=[
	@within Vector
	@prop _data {T}
	@readonly
	@private
	@since v0.1.0

	The underlying table.
]=]
--[=[
	@within Vector
	@prop _size number
	@readonly
	@private
	@since v0.1.0
	
	The amount of elements in the table, not including [EMPTY](Vector#EMPTY) values.
]=]
local _

--[=[
	@within Vector
	@prop EMPTY {}
	@readonly
	@private
	@since v0.1.0
	@tag local

	A value that represents nothing, used to prevent the key from being deallocated to (hopefully) improve performance. Displays as "EMPTY" when printed.
]=]
local EMPTY = setmetatable({}, {
	__index = function()
		print(debug.traceback())
		error("treat this as nil")
	end,
	__newindex = function()
		print(debug.traceback())
		error("treat this as nil")
	end,
	__tostring = function()
		return "EMPTY"
	end
})

export type Vector<T> = typeof(setmetatable({} :: {
	_data: {T},
	_size: number
}, metatable))

--[=[
	@within Vector
	@since v0.1.0
]=]
function Vector.new<T>(count: number?, value: T?): Vector<T>
	local self = setmetatable({
		_data = {},
		_size = 0
	}, metatable)

	if count then
		self:reserve(count)
		if value then
			for _ = 1, count do
				self:push_back(value)
			end
		end
	end

	return self
end

--[=[
	@within Vector
	@since v0.1.0

	Ensure the vector capacity is *at least* this size.
]=]
function prototype.reserve(self: Vector<any>, n: number): ()
	if n > self._size then
		for i = self._size + 1, n do
			self._data[i] = EMPTY
		end
	end
end

--[=[
	@within Vector
	@since v0.1.0

	Sets the vector size and capacity to `count` exactly, filling empty spaces with `value` or [EMPTY](Vector#EMPTY).
]=]
function prototype.resize<T>(self: Vector<T>, count: number, value: T?): ()
	if value == nil then
		value = EMPTY :: any
	end

	local size = self._size
	if size > count then
		for i = count + 1, size do
			self._data[i] = nil
		end
	elseif size < count then
		for i = size + 1, count do
			self._data[i] = value :: any
		end
	end
	self._size = count
end

--[=[
	@within Vector
	@since v0.1.0

	Essentially [table.create](https://create.roblox.com/docs/reference/engine/libraries/table#create).
]=]
function prototype.assign(self: Vector<any>, n: number, val: any): ()
	self._data = table.create(n, val)
	self._size = n
end

--[=[
	@within Vector
	@since v0.1.0

	Gets the item at the end.
]=]
function prototype.back<T>(self: Vector<T>): T
	assert(self._size > 0)
	return self._data[self._size]
end

--[=[
	@within Vector
	@since v0.1.0
]=]
function prototype.clear(self: Vector<any>): ()
	table.clear(self._data)
	self._size = 0
end

--[=[
	@within Vector
	@since v0.1.0
]=]
function prototype.empty(self: Vector<any>): boolean
	return self._size == 0
end

--[=[
	@within Vector
	@method erase
	@param first number
	@param last number?
	@since v0.1.0

	Overloads:
	- first: number, last: number
	- position: number -- the same as passing `erase(position, position)` 

	Set an index or a range to empty.
]=]
prototype.erase = function(self: Vector<any>, first: number, last: number?): ()
	if last then
		assert(first <= last)
		table.move(self._data, last, self._size, first, self._data)
		for index = last, self._size do
			self._data[index] = EMPTY
		end
		local difference = last - first + 1
		self._size -= difference
	else
		table.remove(self._data, first)
		self._data[self._size] = EMPTY
		self._size -= 1
	end
end :: (
	  ((self: Vector<any>, position: number) -> ())
	& ((self: Vector<any>, first: number, last: number) -> ())
)

--[=[
	@within Vector
	@since v0.1.0
]=]
function prototype.front<T>(self: Vector<T>): T
	assert(self._size ~= 0)
	return self._data[1]
end

--[=[
	@within Vector
	@since v0.1.0

	Use this method to index the inner array. The `__index` metamethod could be employed instead, but this would ruin typechecking unless methods are typed statically.
]=]
function prototype.get<T>(self: Vector<T>, index: number): T
	assert(0 < index and index < self._size + 1)
	return self._data[index]
end

--[=[
	@within Vector
	@since v0.1.0
]=]
function prototype.size(self: Vector<any>): number
	return self._size
end

--[=[
	@within Vector
	@since v0.1.0

	Returns a copy of the inner data. Only used by [TempVector].
]=]
function prototype.copy_range<T>(self: Vector<T>, from: number, to: number): {T}
	assert(from > 0 and to < self._size + 1)
	return table.move(self._data, from, to, 1, {})
end

--[=[
	@within Vector
	@since v0.1.0

	Returns the internal array. This should only be used for iteration, which requires this method since the `__iter` metamethod does not produce the correct types.

	:::danger

	The return value must not be mutated.

	:::
]=]
function prototype.data<T>(self: Vector<T>): {T}
	return self._data
end

--[=[
	@within Vector
	@method pop_back
	
	Removes the value at the end.
]=]
function prototype.pop_back(self: Vector<any>): ()
	self._data[self._size] = EMPTY
	self._size -= 1
end

--[=[
	@within Vector
	@since v0.1.0

	Adds a new value at the end.
]=]
function prototype.push_back<T>(self: Vector<T>, val: T): ()
	self._size += 1
	self._data[self._size] = val
end

--[=[
	@within Vector
	@method emplace_back
	@param val T
	@since v0.1.0

	Alias for [push_back](Vector#push_back).
]=]
prototype.emplace_back = prototype.push_back

-- setters

--[=[
	@within Vector
	@since v0.1.0
]=]
function prototype.set<T>(self: Vector<T>, index: number, value: T): ()
	assert(0 < index and index < self._size + 1)
	self._data[index] = value
end

--[=[
	@within Vector
	@since v0.1.0
]=]
function prototype.set_increment(self: Vector<number>, index: number): ()
	self._data[index] += 1
end

--[=[
	@within Vector
	@since v0.1.0
]=]
function prototype.set_decrement(self: Vector<number>, index: number): ()
	self._data[index] -= 1
end

--[=[
	@within Vector
	@since v0.1.0
]=]
function prototype.swap<T>(self: Vector<T>, other: Vector<T>): ()
	self._data, other._data = other._data, self._data
	self._size, other._size = other._size, self._size
end

--[=[
	@within Vector
	@private
	@since v0.1.0

	Used for debugging.
]=]
function prototype.check(self: Vector<any>): ()
	if self._data[0] then
		print(debug.traceback())
		error("stop")
	end
end

return Vector