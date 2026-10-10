--[[
	Runtime — executes Roblox scripts from a Rojo-built place inside Lune.

	Each script gets its own `script` global and an instance-based `require`, mirroring how
	Roblox resolves `require(script.Parent.Foo)`. This covers pure-logic modules and build
	tooling. Anything engine-driven (physics, Players, RunService, rendering, replication)
	is out of scope here and must be verified in Roblox Studio.
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

-- Lune omits WaitForChild. Inside a built place every child already exists, so a missing
-- child is a real error rather than something to wait for.
roblox.implementMethod("Instance", "WaitForChild", function(self, name: string)
	local child = self:FindFirstChild(name)
	if child == nil then
		error(`WaitForChild: '{name}' not found under {self:GetFullName()}`, 2)
	end
	return child
end)

local ROBLOX_GLOBALS = {
	"Axes",
	"BrickColor",
	"CFrame",
	"Color3",
	"ColorSequence",
	"ColorSequenceKeypoint",
	"Enum",
	"Faces",
	"Font",
	"Instance",
	"NumberRange",
	"NumberSequence",
	"NumberSequenceKeypoint",
	"PhysicalProperties",
	"Ray",
	"Rect",
	"Region3",
	"UDim",
	"UDim2",
	"Vector2",
	"Vector3",
}

export type Runtime = {
	game: any,
	require: (self: Runtime, module: any) -> any,
	runScript: (self: Runtime, scriptInstance: any) -> (),
	environment: (self: Runtime, scriptInstance: any?) -> { [string]: any },
	find: (self: Runtime, path: string) -> any,
	use: (self: Runtime, path: string) -> any,
}

local Runtime = {}
Runtime.__index = Runtime

function Runtime.new(game: any)
	return setmetatable({ game = game, _cache = {}, _loading = {} }, Runtime)
end

function Runtime.loadPlace(path: string)
	return Runtime.new(roblox.deserializePlace(fs.readFile(path)))
end

-- Globals a script sees: the DataModel, Roblox datatypes, task, and instance-based require.
function Runtime.environment(self, scriptInstance: any?): { [string]: any }
	local env: { [string]: any } = {
		game = self.game,
		workspace = self.game:GetService("Workspace"),
		script = scriptInstance,
		task = task,
		require = function(target)
			return self:require(target)
		end,
	}
	for _, name in ROBLOX_GLOBALS do
		env[name] = (roblox :: any)[name]
	end
	return env
end

function Runtime.require(self, module: any): any
	if typeof(module) ~= "Instance" or not module:IsA("ModuleScript") then
		error(`require expects a ModuleScript, got {typeof(module)}`, 2)
	end
	local cached = self._cache[module]
	if cached then
		return cached.value
	end
	if self._loading[module] then
		error(`Circular require of {module:GetFullName()}`, 2)
	end
	self._loading[module] = true
	local chunk = luau.load(module.Source, {
		debugName = module:GetFullName(),
		environment = self:environment(module),
	})
	local results = table.pack(chunk())
	self._loading[module] = nil
	if results.n ~= 1 then
		error(`Module {module:GetFullName()} must return exactly one value`)
	end
	self._cache[module] = { value = results[1] }
	return results[1]
end

function Runtime.runScript(self, scriptInstance: any)
	local chunk = luau.load(scriptInstance.Source, {
		debugName = scriptInstance:GetFullName(),
		environment = self:environment(scriptInstance),
	})
	chunk()
end

-- Resolves a dotted path such as "ReplicatedStorage.Shared.Config.GameConfig".
function Runtime.find(self, path: string): any
	local segments = string.split(path, ".")
	local current = self.game:GetService(segments[1])
	for index = 2, #segments do
		local child = current:FindFirstChild(segments[index])
		if child == nil then
			error(`'{segments[index]}' not found under {current:GetFullName()}`, 2)
		end
		current = child
	end
	return current
end

function Runtime.use(self, path: string): any
	return self:require(self:find(path))
end

return Runtime
