--> Runs tests to ensure the code works as it should. Can run a specific test with `[path to file] [test name]`.

local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local requestedFile: string? = process.args[1]
local requestedTest: string? = process.args[2]

local EXTENSION_TEST = ".test.luau"

type testData = {
	[string]: () -> ()
}

local Ws = 0
local Ls = 0

local function reportError(message: string): ()
	stdio.ewrite(stdio.color("red") .. "Error: " .. message .. stdio.color("reset") .. "\n")
end

local function reportFatalError(message: string): ()
	stdio.ewrite(stdio.color("red") .. "Fatal error: " .. message .. stdio.color("reset") .. "\n")
end

local function getRequirePath(pathFs: string): string
	return "../" .. pathFs
end

local function getTestData(path: string): testData?
	local pathRequire = getRequirePath(path)
	local data = require(pathRequire) :: testData

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

local testAny

local function testDirectory(pathDirectory: string): ()
	for _, name in fs.readDir(pathDirectory) do
		local pathMember = pathDirectory .. "/" .. name
		testAny(pathMember)
	end
end

testAny = function(path: string): ()
	if fs.isDir(path) then
		testDirectory(path)
	elseif path:sub(-#EXTENSION_TEST) == EXTENSION_TEST then
		testFile(path)
	end
end

if not fs.isDir("./tests") then
	reportFatalError('"tests" directory was not found.')
	return
end

local pathStart = "./tests"

if requestedFile then
	if not requestedTest then
		reportFatalError(`If file is specified ("{requestedFile}") then test name must also be specified.`)
		return
	end

	pathStart ..= "/" .. requestedFile

	local metadata = fs.metadata(pathStart)
	if not metadata.exists then
		reportFatalError(`Could not find file "{pathStart}".`)
		return
	end
	if metadata.kind ~= "file" then
		reportFatalError(`"{pathStart}" is not a file.`)
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

testAny(pathStart)

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