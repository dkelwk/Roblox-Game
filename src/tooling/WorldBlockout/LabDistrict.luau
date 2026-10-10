--!strict
--[[
	LabDistrict — Zone A, the safe hub: paved district, main road with guide lights, central
	plaza with the upgrade station, the Area 51 main facility landmark, six lab plots, and
	the oversized Extraction Gate that leads north into the desert.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local WorldLayout = require(ReplicatedStorage.Shared.Config.WorldLayout)
local Kit = require(script.Parent.Kit)
local LabPlot = require(script.Parent.LabPlot)
local Props = require(script.Parent.Props)

local World = Palette.World
local District = WorldLayout.District
local Neon = Enum.Material.Neon
local Glass = Enum.Material.Glass

local PAVING_TOP = 0.2
local ROAD_TOP = 0.3
local SIDEWALK_TOP = 0.45

local LabDistrict = {}

local function buildGround(model: Model)
	local b = District.Bounds
	local width, depth = b.MaxX - b.MinX, b.MaxZ - b.MinZ
	local centerX, centerZ = (b.MinX + b.MaxX) / 2, (b.MinZ + b.MaxZ) / 2
	Kit.block(
		model,
		"Paving",
		Vector3.new(width, 1, depth),
		CFrame.new(centerX, PAVING_TOP - 0.5, centerZ),
		World.Paving
	)

	-- Main road, sidewalks and centerline
	local roadLength = District.RoadSouthZ - District.RoadNorthZ
	local roadCenterZ = (District.RoadSouthZ + District.RoadNorthZ) / 2
	local roadHalf = District.RoadWidth / 2
	Kit.block(
		model,
		"Road",
		Vector3.new(District.RoadWidth, 0.4, roadLength),
		CFrame.new(0, ROAD_TOP - 0.2, roadCenterZ),
		World.Road
	)
	for _, side in { -1, 1 } do
		Kit.block(
			model,
			"Sidewalk",
			Vector3.new(8, 0.5, roadLength),
			CFrame.new(side * (roadHalf + 4), SIDEWALK_TOP - 0.25, roadCenterZ),
			World.FacilityTrim
		)
	end
	local dashes = Kit.model(model, "RoadLines")
	for z = District.RoadNorthZ + 10, District.RoadSouthZ - 10, 20 do
		Kit.block(dashes, "Dash", Vector3.new(0.7, 0.1, 8), CFrame.new(0, ROAD_TOP + 0.03, z), World.RoadLine)
	end

	-- Guide lights along both curbs lead the eye toward the gate.
	local guides = Kit.model(model, "GuideLights")
	for z = District.RoadNorthZ + 12, District.RoadSouthZ - 6, 24 do
		for _, side in { -1, 1 } do
			local light = Kit.block(
				guides,
				"GuideLight",
				Vector3.new(0.8, 0.25, 3),
				CFrame.new(side * (roadHalf - 0.6), ROAD_TOP + 0.1, z),
				World.EnergyCyan,
				Neon
			)
			light.CastShadow = false
		end
	end
end

local function buildPlaza(model: Model)
	local plaza = Kit.model(model, "Plaza")
	local center = CFrame.new(District.Plaza.Center)
	local diameter = District.Plaza.Radius * 2
	Kit.column(plaza, "Disc", diameter, ROAD_TOP + 0.1, center, World.FacilityTrim)
	Kit.column(plaza, "Ring", diameter - 14, ROAD_TOP + 0.16, center, World.Floor)
	Kit.column(plaza, "Inner", diameter - 18, ROAD_TOP + 0.22, center, World.FacilityCream)

	local spawnCFrame = District.DefaultSpawn
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "DefaultSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(10, 0.4, 10)
	spawn.CFrame = spawnCFrame * CFrame.new(0, ROAD_TOP + 0.4, 0)
	spawn.Color = World.EnergyCyan
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Parent = plaza

	for _, side in { -1, 1 } do
		Props.lightPost(plaza, Kit.ground(side * 30, District.Plaza.Center.Z - 22))
	end
end

local function buildUpgradeStation(model: Model)
	local station = Kit.model(model, "UpgradeStation")
	station:AddTag(GameConfig.Tags.UpgradeStation)
	local base = District.UpgradeStation * CFrame.new(0, ROAD_TOP + 0.22, 0)
	Kit.column(station, "Base", 16, 1.2, base, World.HazardNavy)
	Kit.column(station, "BaseRing", 14.4, 1.3, base, World.AlertOrange)
	Kit.column(station, "BaseTop", 13.4, 1.36, base, World.Floor)
	Kit.column(station, "Pillar", 4, 9, base * CFrame.new(0, 1.2, 1.5), World.FacilityCream)
	Kit.column(station, "Canopy", 17, 1.2, base * CFrame.new(0, 10.2, 1.5), World.FacilityCream)
	Kit.column(station, "CanopyTrim", 17.4, 0.4, base * CFrame.new(0, 10.0, 1.5), World.AlertOrange)
	local screen = Kit.part(station, {
		name = "Hologram",
		size = Vector3.new(9, 5, 0.3),
		cframe = base * CFrame.new(0, 6.4, -1.4) * CFrame.Angles(math.rad(-12), 0, 0),
		color = World.EnergyCyan,
		material = Glass,
		transparency = 0.35,
	})
	Kit.label(screen, "UPGRADES", Enum.NormalId.Front, World.FacilityCream)
	Kit.marker(station, "InteractPoint", base * CFrame.new(0, 3, -8))
end

local function buildMainFacility(model: Model)
	local facility = Kit.model(model, "MainFacility")
	facility.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local origin = CFrame.new(District.MainFacility)

	-- Hangar body with an arched roof (a cylinder half-sunk into the body).
	Kit.block(facility, "Hangar", Vector3.new(84, 24, 44), origin * CFrame.new(0, 12, 0), World.FacilityCream)
	Kit.part(facility, {
		name = "HangarRoof",
		shape = "Cylinder",
		-- Slight overhang so the roof's end caps never share a plane with the walls.
		size = Vector3.new(85.2, 44, 44),
		cframe = origin * CFrame.new(0, 24, 0),
		color = World.FacilityTrim,
	})
	Kit.block(facility, "HangarBand", Vector3.new(84.4, 2, 44.4), origin * CFrame.new(0, 21, 0), World.Floor)
	Kit.block(facility, "HangarDoor", Vector3.new(34, 18, 1), origin * CFrame.new(0, 9, -22.3), World.Floor)
	Kit.block(facility, "DoorStripe", Vector3.new(34.2, 1.4, 1.1), origin * CFrame.new(0, 2, -22.3), World.AlertOrange)
	local sign = Kit.block(
		facility,
		"FacilitySign",
		Vector3.new(40, 5, 0.6),
		origin * CFrame.new(0, 33, -18.8),
		World.HazardNavy
	)
	Kit.label(sign, "AREA 51 · RESEARCH DIVISION", Enum.NormalId.Front, World.FacilityCream)

	-- Side annexes
	for _, side in { -1, 1 } do
		Kit.block(facility, "Annex", Vector3.new(26, 14, 34), origin * CFrame.new(side * 55, 7, 2), World.FacilityCream)
		Kit.block(
			facility,
			"AnnexRoof",
			Vector3.new(27, 1.4, 35),
			origin * CFrame.new(side * 55, 14.7, 2),
			World.FacilityTrim
		)
		Kit.part(facility, {
			name = "AnnexWindow",
			size = Vector3.new(20, 4, 0.4),
			cframe = origin * CFrame.new(side * 55, 9, -15.1),
			color = World.Glass,
			material = Glass,
			transparency = 0.4,
		})
	end

	-- Control tower with a cyan beacon ring: the "home" landmark visible from the desert.
	local tower = origin * CFrame.new(-56, 0, 22)
	Kit.column(facility, "Tower", 12, 70, tower, World.FacilityCream)
	Kit.column(facility, "TowerBand", 12.6, 2, tower * CFrame.new(0, 40, 0), World.Floor)
	Kit.column(facility, "Pod", 22, 8, tower * CFrame.new(0, 70, 0), World.Floor)
	Kit.part(facility, {
		name = "PodGlass",
		shape = "Cylinder",
		size = Vector3.new(4, 22.6, 22.6),
		cframe = tower * CFrame.new(0, 74, 0) * CFrame.Angles(0, 0, math.rad(90)),
		color = World.Glass,
		material = Glass,
		transparency = 0.35,
	})
	Kit.column(facility, "PodRoof", 24, 1.6, tower * CFrame.new(0, 78, 0), World.FacilityCream)
	local beacon = Kit.column(facility, "Beacon", 25, 0.9, tower * CFrame.new(0, 79.8, 0), World.EnergyCyan, Neon)
	beacon.CastShadow = false
	Kit.column(facility, "Antenna", 0.8, 16, tower * CFrame.new(0, 79.6, 0), World.Steel)

	-- Rooftop radar dish
	Kit.column(facility, "DishMount", 3, 8, origin * CFrame.new(26, 40, 4), World.SteelDark)
	Kit.part(facility, {
		name = "Dish",
		shape = "Cylinder",
		size = Vector3.new(1.4, 18, 18),
		cframe = origin * CFrame.new(26, 50, 4) * CFrame.Angles(0, math.rad(-90), math.rad(-30)),
		color = World.FacilityTrim,
	})
end

local function buildGate(model: Model)
	local gate = Kit.model(model, "ExtractionGate")
	gate.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	gate:AddTag(GameConfig.Tags.ExtractionGate)
	local origin = District.ExtractionGate
	for _, side in { -1, 1 } do
		local pillar = origin * CFrame.new(side * 24, 0, 0)
		Kit.block(gate, "Pillar", Vector3.new(10, 36, 10), pillar * CFrame.new(0, 18, 0), World.FacilityCream)
		Kit.block(gate, "PillarInset", Vector3.new(10.4, 26, 3), pillar * CFrame.new(0, 17, 0), World.Floor)
		Kit.column(gate, "PillarCap", 11, 3, pillar * CFrame.new(0, 36, 0), World.FacilityTrim)
		for stripe = 0, 3 do
			Kit.block(
				gate,
				"HazardStripe",
				Vector3.new(10.5, 1.2, 10.5),
				pillar * CFrame.new(0, 1 + stripe * 2.4, 0),
				if stripe % 2 == 0 then World.AlertOrange else World.HazardNavy
			)
		end
	end
	local beam = Kit.block(gate, "Beam", Vector3.new(58, 8, 10), origin * CFrame.new(0, 32, 0), World.HazardNavy)
	Kit.label(beam, "EXTRACTION ZONE", Enum.NormalId.Back, World.FacilityCream)
	Kit.label(beam, "LAB DISTRICT", Enum.NormalId.Front, World.FacilityCream)
	local strip =
		Kit.block(gate, "BeamGlow", Vector3.new(38, 0.6, 1.2), origin * CFrame.new(0, 27.7, 0), World.EnergyCyan, Neon)
	strip.CastShadow = false
	-- Walk-through energy curtain
	Kit.part(gate, {
		name = "EnergyCurtain",
		size = Vector3.new(38, 27, 0.2),
		cframe = origin * CFrame.new(0, 13.8, 0),
		color = World.EnergyCyan,
		material = Neon,
		transparency = 0.93,
		collide = false,
		castShadow = false,
	})
end

local function buildPerimeter(model: Model)
	local perimeter = Kit.model(model, "Perimeter")
	local b = District.Bounds
	local wallHeight, thickness = 10, 3
	local function wall(fromX: number, toX: number, z: number)
		local length = toX - fromX
		Kit.block(
			perimeter,
			"Wall",
			Vector3.new(length, wallHeight, thickness),
			CFrame.new((fromX + toX) / 2, wallHeight / 2, z),
			World.FacilityCream
		)
		Kit.block(
			perimeter,
			"WallTrim",
			Vector3.new(length, 0.8, thickness + 0.4),
			CFrame.new((fromX + toX) / 2, wallHeight, z),
			World.Floor
		)
	end
	local function sideWall(x: number)
		local length = b.MaxZ - b.MinZ
		Kit.block(
			perimeter,
			"Wall",
			Vector3.new(thickness, wallHeight, length),
			CFrame.new(x, wallHeight / 2, (b.MinZ + b.MaxZ) / 2),
			World.FacilityCream
		)
		Kit.block(
			perimeter,
			"WallTrim",
			Vector3.new(thickness + 0.4, 0.8, length),
			CFrame.new(x, wallHeight, (b.MinZ + b.MaxZ) / 2),
			World.Floor
		)
	end
	local gateZ = District.ExtractionGate.Position.Z
	-- North wall meets the gate pillars; south wall closes the district behind the facility.
	wall(b.MinX, -29, gateZ)
	wall(29, b.MaxX, gateZ)
	wall(b.MinX, b.MaxX, b.MaxZ)
	sideWall(b.MinX)
	sideWall(b.MaxX)

	-- Planter beds and props between plots soften the district.
	for _, z in { 40, -40 } do
		for _, side in { -1, 1 } do
			Props.lightPost(perimeter, Kit.ground(side * 18, z, 0, SIDEWALK_TOP))
		end
	end
end

function LabDistrict.build(parent: Instance): Model
	local model = Kit.model(parent, "LabDistrict")
	model:SetAttribute(GameConfig.Attributes.RegionId, "lab_district")
	buildGround(model)
	buildPlaza(model)
	buildUpgradeStation(model)
	buildMainFacility(model)
	buildGate(model)
	buildPerimeter(model)
	local plots = Kit.folder(model, "Plots")
	for index, origin in WorldLayout.Plots do
		LabPlot.build(plots, index, origin)
	end
	return model
end

return LabDistrict
