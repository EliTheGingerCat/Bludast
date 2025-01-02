--[=[
	@class Try
	Syntax sugar for pcall to match the C++ code more closely.
]=]
--[=[
	@within Try
	@prop _success bolean
	@readonly
	@private
	@since v0.1.0
	Whether the attempted function was called without errors.
]=]
--[=[
	@within Try
	@prop _result any
	@readonly
	@private
	@since v0.1.0
	Any result the attempt returned, only kept for the error handler to use.

	:::danger

	Only the first return is kept; all other values will be discarded.
	```lua
	try(function()
		error(1, 2, 3)
	end):catch(function(...)
		print(...) -- 1
	end)
	```

	:::
]=]
local Try = {}
Try.__index = Try
export type Try = typeof(setmetatable({} :: {
	_success: boolean,
	_result: any
}, Try))

--[=[
	@within Try
	@function new
	@param attempt () -> ()
	@return Try
	@since v0.1.0
	The Try class can also be called directly as a shorthand and it is recommended.
	```lua
	try(function()
		...
	end)
	```
]=]
function Try.new(attempt: () -> ()): Try
	local success, result: any = pcall(attempt)
	return setmetatable({
		_success = success,
		_result = result
	}, Try)
end

--[=[
	@within Try
	@method catch
	@param handler (issue: any) -> ()
	@since v0.1.0
]=]
function Try.catch(self: Try, handler: (issue: any) -> ()): ()
	if self._success == false then
		handler(self._result)
	end
end

setmetatable(Try, {
	__call = function(_, a)
		return Try.new(a)
	end
})

return Try