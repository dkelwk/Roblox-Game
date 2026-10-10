--!strict
-- Server entry point: refuse to run on invalid configuration, then boot every service.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local ConfigValidator = require(Shared.ConfigValidator)
local GameConfig = require(Shared.Config.GameConfig)
local ModuleLoader = require(Shared.Util.ModuleLoader)

local errors = ConfigValidator.validate()
if #errors > 0 then
	error(`[RA51] Invalid configuration, server not started:\n  {table.concat(errors, "\n  ")}`)
end

local services = ModuleLoader.boot(script.Parent.Services)

local count = 0
for _ in services do
	count += 1
end
print(`[RA51] Server v{GameConfig.Version} running {count} services`)
