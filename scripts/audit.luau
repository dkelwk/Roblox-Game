--[[
	Usage: lune run scripts/audit

	Prints the StudioAudit instance-level report for the built place's Workspace.World — the
	same numbers `require(game.ServerStorage.Tooling.StudioAudit).run()` prints in Studio.
]]

local Build = require("./lib/Build")
local Runtime = require("./lib/Runtime")

local runtime = Runtime.loadPlace(Build.PLACE_PATH)
local StudioAudit = runtime:use("ServerStorage.Tooling.StudioAudit")
local world = runtime.game:GetService("Workspace"):FindFirstChild("World")
assert(world, "Workspace.World is missing; run `lune run scripts/build` first")
print(StudioAudit.format(StudioAudit.measure(world)))
