--[[
	Build — produces the playable place file.

	1. Rojo builds the place from source (the generated world is optional at this stage).
	2. The world blockout generator (ServerStorage.Tooling.WorldBlockout) runs inside Lune
	   and is saved as assets/generated/World.rbxm.
	3. Rojo builds again, now mounting the generated world into Workspace.World.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Runtime = require("./Runtime")

local Build = {}

Build.PROJECT_PATH = "default.project.json"
Build.PLACE_PATH = "build/RaidArea51.rbxl"
Build.WORLD_PATH = "assets/generated/World.rbxm"

local function ensureDirectory(path: string)
	if not fs.isDir(path) then
		fs.writeDir(path)
	end
end

function Build.rojo()
	ensureDirectory("build")
	local result = process.exec("rojo", { "build", Build.PROJECT_PATH, "--output", Build.PLACE_PATH })
	if not result.ok then
		error(`rojo build failed:\n{result.stdout}\n{result.stderr}`)
	end
end

function Build.generateWorld(runtime: any): any
	local WorldBlockout = runtime:use("ServerStorage.Tooling.WorldBlockout")
	local world = WorldBlockout.build()
	ensureDirectory("assets/generated")
	fs.writeFile(Build.WORLD_PATH, roblox.serializeModel({ world }))
	return world
end

function Build.run()
	Build.rojo()
	local world = Build.generateWorld(Runtime.loadPlace(Build.PLACE_PATH))
	Build.rojo()
	local partCount = 0
	for _, descendant in world:GetDescendants() do
		if descendant:IsA("BasePart") then
			partCount += 1
		end
	end
	print(`Built {Build.PLACE_PATH} (world: {partCount} parts)`)
end

return Build
