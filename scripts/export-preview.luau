--[[
	Usage: lune run scripts/export-preview

	Writes the built place's visible world geometry to build/preview/world.json so
	tools/preview/render_world.py can rebuild it in Blender for preview renders. Run
	`lune run scripts/build` first.
]]

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local Build = require("./lib/Build")
local Runtime = require("./lib/Runtime")

local runtime = Runtime.loadPlace(Build.PLACE_PATH)
local world = runtime.game:GetService("Workspace"):FindFirstChild("World")
assert(world, "Workspace.World is missing; run `lune run scripts/build` first")

local function shapeOf(part: any): string
	if part:IsA("WedgePart") then
		return "Wedge"
	elseif part:IsA("CornerWedgePart") then
		return "CornerWedge"
	elseif part:IsA("Part") then
		return part.Shape.Name
	end
	return "Block"
end

local parts = {}
for _, descendant in world:GetDescendants() do
	if descendant:IsA("BasePart") and descendant.Transparency < 1 then
		local cframe = descendant.CFrame
		table.insert(parts, {
			name = descendant.Name,
			shape = shapeOf(descendant),
			size = { descendant.Size.X, descendant.Size.Y, descendant.Size.Z },
			cframe = { cframe:GetComponents() },
			color = descendant.Color:ToHex(),
			material = descendant.Material.Name,
			transparency = descendant.Transparency,
		})
	end
end

if not fs.isDir("build/preview") then
	fs.writeDir("build/preview")
end
fs.writeFile("build/preview/world.json", serde.encode("json", { parts = parts }))
print(`Exported {#parts} visible parts to build/preview/world.json`)
