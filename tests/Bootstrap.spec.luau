-- Server entry point and the Init/Start lifecycle contract.

local function makeModule(parent: Instance, name: string, source: string): ModuleScript
	local module = Instance.new("ModuleScript")
	module.Name = name
	module.Source = source
	module.Parent = parent
	return module
end

describe("Server bootstrap", function()
	it("boots with the real configuration and services folder", function()
		local fresh = freshRuntime()
		fresh:runScript(fresh:find("ServerScriptService.Server.Main"))
	end)

	it("refuses to start when configuration is invalid", function()
		local fresh = freshRuntime()
		local gameConfig = fresh:find("ReplicatedStorage.Shared.Config.GameConfig")
		gameConfig.Source = gameConfig.Source:gsub("MaxPlayersPerServer = 6", "MaxPlayersPerServer = 12")
		expect(function()
			fresh:runScript(fresh:find("ServerScriptService.Server.Main"))
		end).toThrow("Invalid configuration")
	end)
end)

describe("ModuleLoader", function()
	it("runs Init on every module before any Start, in name order", function()
		local fresh = freshRuntime()
		local container = Instance.new("Folder")
		local log = makeModule(container, "Log", "return {}")
		local template = [[
			local log = require(script.Parent.Log)
			local module = {}
			function module:Init() table.insert(log, "%s.Init") end
			function module:Start() table.insert(log, "%s.Start") end
			return module
		]]
		makeModule(container, "Beta", template:format("Beta", "Beta"))
		makeModule(container, "Alpha", template:format("Alpha", "Alpha"))
		local ModuleLoader = fresh:use("ReplicatedStorage.Shared.Util.ModuleLoader")
		local modules = ModuleLoader.boot(container)
		expect(fresh:require(log)).toEqual({ "Alpha.Init", "Beta.Init", "Alpha.Start", "Beta.Start" })
		expect(modules.Alpha ~= nil and modules.Beta ~= nil and modules.Log ~= nil).toBe(true)
	end)

	it("ignores non-module children", function()
		local fresh = freshRuntime()
		local container = Instance.new("Folder")
		Instance.new("Folder").Parent = container
		local ModuleLoader = fresh:use("ReplicatedStorage.Shared.Util.ModuleLoader")
		expect(next(ModuleLoader.boot(container))).toBe(nil)
	end)
end)
