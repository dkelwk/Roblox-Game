--[[
	TestKit — a minimal describe/it/expect runner for spec files executed by Lune.
]]

local luau = require("@lune/luau")

local TestKit = {}

local function format(value: any): string
	if type(value) == "string" then
		return `"{value}"`
	end
	return tostring(value)
end

local function deepEqual(a: any, b: any): boolean
	if a == b then
		return true
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	for key, value in a do
		if not deepEqual(value, b[key]) then
			return false
		end
	end
	for key in b do
		if a[key] == nil then
			return false
		end
	end
	return true
end

local function expect(actual: any)
	local assertions = {}

	function assertions.toBe(expected: any)
		if actual ~= expected then
			error(`expected {format(expected)}, got {format(actual)}`, 2)
		end
	end

	function assertions.toEqual(expected: any)
		if not deepEqual(actual, expected) then
			error(`expected deep equality with {format(expected)}, got {format(actual)}`, 2)
		end
	end

	function assertions.toBeTruthy()
		if not actual then
			error(`expected a truthy value, got {format(actual)}`, 2)
		end
	end

	function assertions.toBeNear(expected: number, epsilon: number?)
		if math.abs(actual - expected) > (epsilon or 1e-4) then
			error(`expected {actual} to be within {epsilon or 1e-4} of {expected}`, 2)
		end
	end

	function assertions.toBeAtMost(limit: number)
		if not (actual <= limit) then
			error(`expected {format(actual)} <= {limit}`, 2)
		end
	end

	function assertions.toBeAtLeast(limit: number)
		if not (actual >= limit) then
			error(`expected {format(actual)} >= {limit}`, 2)
		end
	end

	-- For lists of problems: passes when empty, otherwise prints every entry.
	function assertions.toBeEmpty()
		if next(actual) ~= nil then
			local lines = {}
			for _, entry in actual do
				table.insert(lines, `    - {entry}`)
			end
			error(`expected no entries, got {#lines}:\n{table.concat(lines, "\n")}`, 2)
		end
	end

	function assertions.toContainMatch(pattern: string)
		for _, entry in actual do
			if type(entry) == "string" and entry:find(pattern) then
				return
			end
		end
		error(`expected an entry matching '{pattern}' in:\n    {table.concat(actual, "\n    ")}`, 2)
	end

	function assertions.toThrow(pattern: string?)
		local ok, message = pcall(actual)
		if ok then
			error("expected function to throw", 2)
		end
		if pattern and not tostring(message):find(pattern) then
			error(`expected error matching '{pattern}', got: {message}`, 2)
		end
	end

	return assertions
end

export type Results = { passed: number, failed: number, failures: { string } }

-- Runs one spec file. `environment` supplies extra globals (e.g. the Roblox runtime).
function TestKit.runFile(path: string, source: string, environment: { [string]: any }, results: Results)
	local prefix: { string } = {}

	local env = table.clone(environment)
	env.expect = expect
	env.describe = function(name: string, body: () -> ())
		table.insert(prefix, name)
		body()
		table.remove(prefix)
	end
	env.it = function(name: string, body: () -> ())
		local fullName = table.concat(prefix, " › ") .. " › " .. name
		local ok, message = xpcall(body, function(err)
			return tostring(err)
		end)
		if ok then
			results.passed += 1
			print(`  ✓ {fullName}`)
		else
			results.failed += 1
			table.insert(results.failures, `{path}: {fullName}\n    {message}`)
			print(`  ✗ {fullName}\n    {message}`)
		end
	end

	print(path)
	local chunk = luau.load(source, { debugName = path, environment = env })
	chunk()
end

return TestKit
