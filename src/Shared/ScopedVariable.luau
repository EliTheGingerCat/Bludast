local FastVariables = require("./FastVariables")

return function(variables: typeof(FastVariables), fn: () -> ()): ()
	local original = {}

	for name, value in variables do
		original[name] = FastVariables[name]
		FastVariables[name] = value
	end

	local success, result: string? = pcall(fn)

	for name, value in original do
		FastVariables[name] = value
	end
	
	if success == false then
		error(result, 2)
	end
end
