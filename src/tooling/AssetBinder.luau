--!strict
--[[
	AssetBinder — applies Roblox material and palette color to imported Blender meshes.

	Blender assets export one mesh per material + color, named
		<Part>__<RobloxMaterial>__<PaletteToken>     e.g. BaseCap__SmoothPlastic__Steel
	After importing an FBX with the 3D Importer, bind it from the command bar:
		require(game.ServerStorage.Tooling.AssetBinder).bind(workspace.SpecimenCapsule)

	Colors come from Palette.luau, so imported assets always match the design system.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage.Shared.Config.Palette)

local MATERIALS: { [string]: Enum.Material } = {
	SmoothPlastic = Enum.Material.SmoothPlastic,
	Glass = Enum.Material.Glass,
	Neon = Enum.Material.Neon,
	Metal = Enum.Material.Metal,
	Sand = Enum.Material.Sand,
	Sandstone = Enum.Material.Sandstone,
}

-- Glass meshes are see-through in Roblox only with some transparency.
local GLASS_TRANSPARENCY = 0.45

-- Palette groups searched for a token, most specific first.
local PALETTE_GROUPS: { { [string]: Color3 } } = { Palette.World :: any, Palette.Core :: any, Palette.UI :: any }

local AssetBinder = {}

function AssetBinder.color(token: string): Color3?
	for _, group in PALETTE_GROUPS do
		local color: Color3? = group[token]
		if color then
			return color
		end
	end
	return nil
end

-- Binds every matching BasePart under `root` (inclusive). Returns how many parts were bound;
-- errors listing every part whose material or palette token is unknown.
function AssetBinder.bind(root: Instance): number
	local candidates = root:GetDescendants()
	table.insert(candidates, root)
	local bound, problems = 0, {}
	for _, instance in candidates do
		if not instance:IsA("BasePart") then
			continue
		end
		local _, materialName, token = string.match(instance.Name, "^(.-)__(%w+)__(%w+)$")
		if materialName == nil or token == nil then
			continue
		end
		local material = MATERIALS[materialName]
		local color = AssetBinder.color(token)
		if material == nil or color == nil then
			table.insert(problems, `{instance:GetFullName()} (material '{materialName}', token '{token}')`)
			continue
		end
		local part = instance :: BasePart
		part.Material = material
		part.Color = color
		if material == Enum.Material.Glass then
			part.Transparency = GLASS_TRANSPARENCY
		end
		bound += 1
	end
	if #problems > 0 then
		error(`AssetBinder: unknown material or palette token:\n  {table.concat(problems, "\n  ")}`)
	end
	return bound
end

return AssetBinder
