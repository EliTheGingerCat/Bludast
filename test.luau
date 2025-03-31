--> Runs tests to ensure the code works as it should. Can run a specific test with `[path to file] [test name]`.

local args: {string} = table.pack(...)

local requestedFile: string? = args[1]
local requestedTest: string? = args[2]

local TEST_FILES = {
	"Compiler",
	"CostModel",
	"Lexer",
	"Parser"
}

type testData = {
	[string]: () -> ()
}

local Ws = 0
local Ls = 0

local function reportError(message: string): ()
	print("\27[31mError: " .. message .. "\27[0m")
end

local function reportFatalError(message: string): ()
	print("\27[31mFatal error: " .. message .. "\27[0m")
end

local function getTestData(path: string): testData?
	print(path)
	local data = require(path .. ".test") :: testData

	if type(data) == "table" then
		return data
	else
		reportError("Test data must be a table.")
		return nil
	end
end

local function testCase(path: string, name: string, case: () -> ()): ()
	local success, message: string? = pcall(case)
	if success then
		Ws += 1
	else
		Ls += 1
		print(`{path}.{name} failed: {message}`)
	end
end

local function testFile(path: string): ()
	local data = getTestData(path)
	if not data then
		return
	end

	for name, case in data do
		testCase(path, name, case)
	end
end

local pathStart = "./tests"

if requestedFile then
	if not requestedTest then
		reportFatalError(`If file is specified ("{requestedFile}") then test name must also be specified.`)
		return
	end

	pathStart ..= "/" .. requestedFile

	if table.find(TEST_FILES, requestedFile) == nil then
		reportFatalError(`Could not find file "{requestedFile .. ".test.luau"}".`)
		return
	end

	local data = getTestData(pathStart)
	if not data then
		return
	end

	local case = data[requestedTest]
	if not case then
		reportFatalError(`Test "{requestedTest}" was not found in file {pathStart}.`)
		return
	end

	testCase(pathStart, requestedTest, case)

	return
end

for _, file in TEST_FILES do
	testFile(pathStart .. "/" .. file)
end

if Ws == 0 and Ls == 0 then
	print("Bro did not write any tests... 😾")
elseif Ws == 1 and Ls == 0 then
	print("Your single test passed! 😸")
elseif Ws == 0 and Ls == 1 then
	print("Your single test failed. 😿")
elseif Ws == 0 then
	print(`All {Ls} tests failed. 💀`)
elseif Ls == 0 then
	print(`All {Ws} tests passed! 😸`)
else
	print(`You took {Ws} Ws and {Ls} Ls. 😿`)
end