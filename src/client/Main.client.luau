--!strict
-- Client entry point: wait for the initial replication snapshot, then boot every controller.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local ModuleLoader = require(ReplicatedStorage:WaitForChild("Shared").Util.ModuleLoader)

ModuleLoader.boot(script.Parent:WaitForChild("Controllers"))
