--[[
	Usage: lune run scripts/check

	Everything a change must pass before it is pushed:
	  1. format   — StyLua (check only)
	  2. lint     — Selene for game code, specs and Lune scripts
	  3. types    — luau-lsp strict analysis of src/ against Roblox type definitions
	  4. build+test — Rojo build, world generation, and every tests/*.spec.luau
]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local DEFINITIONS_PATH = "build/globalTypes.None.d.luau"
local DEFINITIONS_URL = "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.None.d.luau"

local failures = {}

local function step(name: string, program: string, args: { string })
	print(`\n▶ {name}: {program} {table.concat(args, " ")}`)
	local result = process.exec(program, args, { stdio = "inherit" })
	if not result.ok then
		table.insert(failures, name)
	end
end

step("format", "stylua", { "--check", "src", "scripts", "tests" })
step("lint (game)", "selene", { "src" })
step("lint (specs)", "selene", { "--config", "tools/selene/selene-spec.toml", "tests" })
step("lint (scripts)", "selene", { "--config", "tools/selene/selene-lune.toml", "scripts" })

if not fs.isDir("build") then
	fs.writeDir("build")
end
if not fs.isFile(DEFINITIONS_PATH) then
	step("fetch Roblox type definitions", "curl", { "-sSfL", "-o", DEFINITIONS_PATH, DEFINITIONS_URL })
end
step("sourcemap", "rojo", { "sourcemap", "default.project.json", "--output", "build/sourcemap.json" })
step("types", "luau-lsp", {
	"analyze",
	"--platform=roblox",
	"--sourcemap=build/sourcemap.json",
	`--definitions=@roblox={DEFINITIONS_PATH}`,
	"src",
})

step("build + test", "lune", { "run", "scripts/test" })

if #failures > 0 then
	print(`\n✗ Failed: {table.concat(failures, ", ")}`)
	process.exit(1)
end
print("\n✓ All checks passed")
