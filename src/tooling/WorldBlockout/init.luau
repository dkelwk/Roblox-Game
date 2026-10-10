--!strict
--[[
	WorldBlockout — procedurally builds the Phase 1 world blockout from WorldLayout.

	Run by `lune run scripts/build`, which saves the result as assets/generated/World.rbxm and
	mounts it at Workspace.World. It can also be run from the Studio command bar:
		require(game.ServerStorage.Tooling.WorldBlockout).build().Parent = workspace

	The blockout is a polished layout pass, not final art. Approved pieces get replaced by
	Blender assets in Phase 5 (see docs/ASSET_MANIFEST.md).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local WorldLayout = require(ReplicatedStorage.Shared.Config.WorldLayout)
local DesertRegion = require(script.DesertRegion)
local Kit = require(script.Kit)
local LabDistrict = require(script.LabDistrict)

local BOUNDARY_HEIGHT = 400
local BOUNDARY_THICKNESS = 4

local WorldBlockout = {}

local function buildBaseGround(world: Model)
	-- One sand plate under everything, extending past the play area to the horizon.
	Kit.part(world, {
		name = "BaseSand",
		size = Vector3.new(1600, 4, 1760),
		cframe = CFrame.new(0, -2, -460),
		color = Palette.Core.Sand,
		material = Enum.Material.Sand,
		castShadow = false,
	})
end

-- Invisible walls around the union of the district and the desert. Players collide with
-- them, but cameras and raycasts pass through (CanQuery off).
local function buildBoundaries(world: Model)
	local folder = Kit.folder(world, "Boundaries")
	local district, desert = WorldLayout.District.Bounds, WorldLayout.Desert.Bounds
	local pad = BOUNDARY_THICKNESS / 2
	local function wall(name: string, a: Vector2, b: Vector2)
		local isAlongX = a.Y == b.Y
		local length = if isAlongX then math.abs(b.X - a.X) else math.abs(b.Y - a.Y)
		local wallPart = Kit.part(folder, {
			name = name,
			size = if isAlongX
				then Vector3.new(length + BOUNDARY_THICKNESS, BOUNDARY_HEIGHT, BOUNDARY_THICKNESS)
				else Vector3.new(BOUNDARY_THICKNESS, BOUNDARY_HEIGHT, length + BOUNDARY_THICKNESS),
			cframe = CFrame.new((a.X + b.X) / 2, BOUNDARY_HEIGHT / 2, (a.Y + b.Y) / 2),
			color = Palette.Core.Cream,
			transparency = 1,
			castShadow = false,
		})
		wallPart.CanQuery = false
		wallPart.CanTouch = false
		wallPart:AddTag(GameConfig.Tags.Boundary)
	end
	-- District (south part)
	wall(
		"DistrictWest",
		Vector2.new(district.MinX - pad, district.MinZ),
		Vector2.new(district.MinX - pad, district.MaxZ + pad)
	)
	wall(
		"DistrictEast",
		Vector2.new(district.MaxX + pad, district.MinZ),
		Vector2.new(district.MaxX + pad, district.MaxZ + pad)
	)
	wall(
		"DistrictSouth",
		Vector2.new(district.MinX - pad, district.MaxZ + pad),
		Vector2.new(district.MaxX + pad, district.MaxZ + pad)
	)
	-- Desert (north part); its south edge only exists where it is wider than the district.
	wall(
		"DesertSouthWest",
		Vector2.new(desert.MinX - pad, desert.MaxZ + pad),
		Vector2.new(district.MinX - pad, desert.MaxZ + pad)
	)
	wall(
		"DesertSouthEast",
		Vector2.new(district.MaxX + pad, desert.MaxZ + pad),
		Vector2.new(desert.MaxX + pad, desert.MaxZ + pad)
	)
	wall(
		"DesertWest",
		Vector2.new(desert.MinX - pad, desert.MinZ - pad),
		Vector2.new(desert.MinX - pad, desert.MaxZ + pad)
	)
	wall(
		"DesertEast",
		Vector2.new(desert.MaxX + pad, desert.MinZ - pad),
		Vector2.new(desert.MaxX + pad, desert.MaxZ + pad)
	)
	wall(
		"DesertNorth",
		Vector2.new(desert.MinX - pad, desert.MinZ - pad),
		Vector2.new(desert.MaxX + pad, desert.MinZ - pad)
	)
end

function WorldBlockout.build(): Model
	local world = Instance.new("Model")
	world.Name = "World"
	world:SetAttribute("BlockoutVersion", GameConfig.Version)
	buildBaseGround(world)
	buildBoundaries(world)
	LabDistrict.build(world)
	DesertRegion.build(world)
	return world
end

return WorldBlockout
