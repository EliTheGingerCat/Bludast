local Vector = require("@Polyfill/Vector")

type Vector<T> = Vector.Vector<T>

--[=[
	@class TempVector
]=]
local TempVector = {}
local prototype = {}
local metatable = {__index = prototype}

export type TempVector<T> = typeof(setmetatable({} :: {
	storage: Vector<T>,
	offset: number,
	size_: number
}, metatable))

--[=[
	@within TempVector
	@function new
	@param storage Vector<T>
	@return TempVector<T>

	<T>
]=]
function TempVector.new<T>(storage: Vector<T>): TempVector<T>
	return setmetatable({
		storage = storage,
		offset = storage:size() + 1,
		size_ = 0
	}, metatable)
end

--[=[
	@within TempVector
	@method destroy

	Ideally this would be hooked up to the `__gc` metamethod, but that is not supported in Luau, so instead it has to be manually called before returning from a function.
]=]
function prototype.destroy(self: TempVector<any>): ()
	assert(self.storage:size() == self.offset + self.size_ - 1)
	if self.size_ ~= 0 then
		self.storage:erase(self.offset, self.offset + self.size_ - 1)
	end
end

function prototype.get<T>(self: TempVector<T>, index: number): T
	assert(index < self.size_ + 1)
	return self.storage:get(self.offset + index - 1)
end

function prototype.front<T>(self: TempVector<T>): T
	assert(self.size_ > 0)
	return self.storage:get(self.offset)
end

function prototype.back<T>(self: TempVector<T>): T
	assert(self.size_ > 0)
	return self.storage:back()
end

function prototype.empty(self: TempVector<any>): boolean
	return self.size_ == 0
end

function prototype.size(self: TempVector<any>): number
	return self.size_
end

function prototype.push_back<T>(self: TempVector<T>, item: T): ()
	assert(self.storage:size() == self.offset + self.size_ - 1)
	self.storage:push_back(item)
	self.size_ += 1
end

function prototype.copy_data<T>(self: TempVector<T>): {T}
	return self.storage:copy_range(1, self.offset + self.size_ - 1)
end

type iteratorState<T> = {
	vector: TempVector<T>,
	index: number,
	size: number
}
local function iterator<T>(state: iteratorState<T>): (number, T)
	state.index += 1
	if state.index > state.size then
		return nil :: any, nil :: any
	else
		return state.index, state.vector:get(state.index)
	end
end
function metatable.__iter<T>(self: TempVector<T>)
	return iterator, {
		vector = self,
		index = self.offset,
		size = self.storage:size()
	} :: iteratorState<T>
end

return TempVector