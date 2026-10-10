--!strict
--[[
	ModuleLoader — the lifecycle contract for server services and client controllers.

	Every ModuleScript directly inside the container is required. Then `Init` runs on all of
	them (in name order, synchronously — no yielding, no cross-module calls), then `Start`
	runs on all of them in its own thread. By the time any Start runs, every module is
	initialized, so modules can safely use each other in Start.
]]

local ModuleLoader = {}

function ModuleLoader.boot(container: Instance): { [string]: any }
	local modules: { [string]: any } = {}
	local names: { string } = {}
	for _, child in container:GetChildren() do
		if child:IsA("ModuleScript") then
			modules[child.Name] = (require :: any)(child)
			table.insert(names, child.Name)
		end
	end
	table.sort(names)

	for _, name in names do
		local module = modules[name]
		if type(module) == "table" and type(module.Init) == "function" then
			module:Init()
		end
	end
	for _, name in names do
		local module = modules[name]
		if type(module) == "table" and type(module.Start) == "function" then
			task.spawn(module.Start, module)
		end
	end
	return modules
end

return ModuleLoader
