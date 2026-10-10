--[[
	Usage: lune run scripts/test [--no-build] [filter]

	Builds the place, loads it into a Lune-emulated DataModel and runs every tests/*.spec.luau
	file against the real built instance tree. Exits non-zero on any failure.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local Build = require("./lib/Build")
local Runtime = require("./lib/Runtime")
local TestKit = require("./lib/TestKit")

local skipBuild = false
local filter: string? = nil
for _, arg in process.args do
	if arg == "--no-build" then
		skipBuild = true
	else
		filter = arg
	end
end

if not skipBuild then
	Build.run()
end

local specFiles = {}
for _, name in fs.readDir("tests") do
	if name:match("%.spec%.luau$") and (filter == nil or name:find(filter, 1, true)) then
		table.insert(specFiles, name)
	end
end
table.sort(specFiles)

local results: TestKit.Results = { passed = 0, failed = 0, failures = {} }
for _, name in specFiles do
	-- Fresh runtime per file so module state never leaks between specs.
	local runtime = Runtime.loadPlace(Build.PLACE_PATH)
	local environment = runtime:environment(nil)
	environment.runtime = runtime
	environment.use = function(path: string)
		return runtime:use(path)
	end
	-- An isolated runtime for tests that mutate module sources or state.
	environment.freshRuntime = function()
		return Runtime.loadPlace(Build.PLACE_PATH)
	end
	local path = `tests/{name}`
	local ok, err = pcall(TestKit.runFile, path, fs.readFile(path), environment, results)
	if not ok then
		results.failed += 1
		table.insert(results.failures, `{path}: failed to load\n    {err}`)
		print(`  ✗ failed to load: {err}`)
	end
end

print(`\n{results.passed} passed, {results.failed} failed`)
if results.failed > 0 then
	print("\nFailures:")
	for _, failure in results.failures do
		print(`  {failure}`)
	end
	process.exit(1)
end
