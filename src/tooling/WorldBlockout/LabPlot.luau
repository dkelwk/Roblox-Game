--!strict
--[[
	LabPlot — one player's laboratory: a miniature secret research facility with an open
	oversized entrance, big windows and a skylight so other players can see the aliens
	inside, a scanner station, and eight containment chambers.

	Plot-local space: origin at the plot center on the ground, -Z faces the road.
	Gameplay code finds everything it needs through the Markers folder and chamber models,
	never by part names inside the building shell.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local WorldLayout = require(ReplicatedStorage.Shared.Config.WorldLayout)
local Kit = require(script.Parent.Kit)
local Props = require(script.Parent.Props)

local World = Palette.World
local Glass = Enum.Material.Glass
local Neon = Enum.Material.Neon

local PAD_TOP = 0.65
local FLOOR_TOP = 1.0
local WALL_HEIGHT = 16
local HALF_WIDTH = 23 -- building spans x ∈ [-23, 23]
local FRONT_Z = -12 -- building spans z ∈ [-12, 27]
local BACK_Z = 27
local DOOR_HALF = 8

-- Chamber slot positions (plot-local X, Z). Slots 1–3 are the starting capacity, so they
-- take the most visible spots along the back wall.
local CHAMBER_SLOTS = {
	Vector2.new(-5, 20.5),
	Vector2.new(5, 20.5),
	Vector2.new(-15, 20.5),
	Vector2.new(15, 20.5),
	Vector2.new(-17.5, 12),
	Vector2.new(17.5, 12),
	Vector2.new(-17.5, 3.5),
	Vector2.new(17.5, 3.5),
}
local SCANNER_POSITION = Vector2.new(0, 3)

local LabPlot = {}

LabPlot.ChamberSlots = CHAMBER_SLOTS

local function buildShell(model: Model, origin: CFrame, accent: Color3)
	local function at(x: number, y: number, z: number): CFrame
		return origin * CFrame.new(x, y, z)
	end
	local depth = BACK_Z - FRONT_Z
	local midZ = (BACK_Z + FRONT_Z) / 2

	Kit.block(model, "Floor", Vector3.new(HALF_WIDTH * 2, 0.4, depth), at(0, FLOOR_TOP - 0.2, midZ), World.Floor)

	-- Back wall
	Kit.block(
		model,
		"BackWall",
		Vector3.new(HALF_WIDTH * 2, WALL_HEIGHT, 2),
		at(0, FLOOR_TOP + WALL_HEIGHT / 2, BACK_Z - 1),
		World.FacilityCream
	)

	-- Side walls: solid base, tall window band, solid header
	for _, side in { -1, 1 } do
		local x = side * (HALF_WIDTH - 1)
		Kit.block(model, "SideWallLow", Vector3.new(2, 4, depth), at(x, FLOOR_TOP + 2, midZ), World.FacilityCream)
		Kit.part(model, {
			name = "SideWindow",
			size = Vector3.new(0.6, 8, depth),
			cframe = at(x, FLOOR_TOP + 8, midZ),
			color = World.Glass,
			material = Glass,
			transparency = 0.55,
		})
		Kit.block(model, "SideWallHigh", Vector3.new(2, 4, depth), at(x, FLOOR_TOP + 14, midZ), World.FacilityCream)
		Kit.block(model, "Mullion", Vector3.new(2.2, 8, 1.6), at(x, FLOOR_TOP + 8, midZ), World.FacilityTrim)
	end

	-- Front wall segments either side of the oversized entrance
	local segmentWidth = HALF_WIDTH - DOOR_HALF
	for _, side in { -1, 1 } do
		local x = side * (DOOR_HALF + segmentWidth / 2)
		Kit.block(
			model,
			"FrontWallLow",
			Vector3.new(segmentWidth, 4, 2),
			at(x, FLOOR_TOP + 2, FRONT_Z + 1),
			World.FacilityCream
		)
		Kit.part(model, {
			name = "FrontWindow",
			size = Vector3.new(segmentWidth, 8, 0.6),
			cframe = at(x, FLOOR_TOP + 8, FRONT_Z + 1),
			color = World.Glass,
			material = Glass,
			transparency = 0.55,
		})
		Kit.block(
			model,
			"FrontWallHigh",
			Vector3.new(segmentWidth, 4, 2),
			at(x, FLOOR_TOP + 14, FRONT_Z + 1),
			World.FacilityCream
		)
	end

	-- Rounded corners
	for _, corner in
		{ Vector2.new(-1, FRONT_Z), Vector2.new(1, FRONT_Z), Vector2.new(-1, BACK_Z), Vector2.new(1, BACK_Z) }
	do
		Kit.column(
			model,
			"CornerPillar",
			4.4,
			WALL_HEIGHT + 1.2,
			at(corner.X * HALF_WIDTH, FLOOR_TOP, corner.Y),
			World.FacilityTrim
		)
	end

	-- Oversized entrance frame, projecting toward the road
	for _, side in { -1, 1 } do
		Kit.block(
			model,
			"DoorFrame",
			Vector3.new(3, 15, 4),
			at(side * (DOOR_HALF + 1.5), FLOOR_TOP + 7.5, FRONT_Z - 0.5),
			World.Steel
		)
	end
	local header = Kit.block(
		model,
		"DoorHeader",
		Vector3.new(DOOR_HALF * 2 + 6, 3.5, 4.4),
		at(0, FLOOR_TOP + 16.4, FRONT_Z - 0.5),
		World.HazardNavy
	)
	Kit.block(
		model,
		"DoorGlow",
		Vector3.new(DOOR_HALF * 2, 0.4, 0.8),
		at(0, FLOOR_TOP + 14.45, FRONT_Z - 2.2),
		accent,
		Neon
	)
	return header
end

local function buildRoof(model: Model, origin: CFrame, accent: Color3)
	local function at(x: number, y: number, z: number): CFrame
		return origin * CFrame.new(x, y, z)
	end
	local roofY = FLOOR_TOP + WALL_HEIGHT + 0.8
	local width = HALF_WIDTH * 2 + 2
	-- Front and back slabs with a glass skylight between them.
	-- Accent fascia just under the roof edge.
	Kit.block(
		model,
		"RoofFascia",
		Vector3.new(width + 0.6, 1, BACK_Z - FRONT_Z + 2.6),
		at(0, roofY - 1, (FRONT_Z + BACK_Z) / 2),
		accent
	)
	Kit.block(model, "RoofFront", Vector3.new(width, 1.6, 12), at(0, roofY, FRONT_Z + 5), World.FacilityCream)
	Kit.part(model, {
		name = "Skylight",
		size = Vector3.new(width - 4, 0.5, 15),
		cframe = at(0, roofY, FRONT_Z + 18.5),
		color = World.Glass,
		material = Glass,
		transparency = 0.5,
	})
	Kit.block(model, "RoofBack", Vector3.new(width, 1.6, 14), at(0, roofY, BACK_Z - 6), World.FacilityCream)
	for _, side in { -1, 1 } do
		Kit.block(
			model,
			"SkylightRail",
			Vector3.new(2, 1.6, 15),
			at(side * (width / 2 - 1), roofY, FRONT_Z + 18.5),
			World.FacilityCream
		)
	end
	-- Roof equipment
	Kit.column(model, "Vent", 3, 2.4, at(-14, roofY + 0.8, BACK_Z - 5), World.Steel)
	Kit.column(model, "Vent", 3, 2.4, at(-9, roofY + 0.8, BACK_Z - 5), World.Steel)
	Kit.column(model, "DishMount", 1, 3, at(14, roofY + 0.8, BACK_Z - 5), World.SteelDark)
	Kit.part(model, {
		name = "Dish",
		shape = "Cylinder",
		size = Vector3.new(0.6, 6, 6),
		cframe = at(14, roofY + 4.6, BACK_Z - 5) * CFrame.Angles(0, math.rad(-90), math.rad(-35)),
		color = World.FacilityTrim,
	})
end

local function buildScanner(model: Model, origin: CFrame, markers: Folder)
	local scanner = Kit.model(model, "Scanner")
	local base = origin * CFrame.new(SCANNER_POSITION.X, FLOOR_TOP, SCANNER_POSITION.Y)
	Kit.column(scanner, "Plinth", 12, 1, base, World.HazardNavy)
	Kit.column(scanner, "PlinthRing", 10.6, 1.08, base, World.EnergyCyan)
	Kit.column(scanner, "PlinthTop", 9.6, 1.16, base, World.Floor)
	Kit.column(scanner, "Pedestal", 4, 3, base * CFrame.new(0, 1, 0), World.FacilityCream)
	local seat = Kit.column(scanner, "CapsuleSeat", 4.4, 0.3, base * CFrame.new(0, 4, 0), World.EnergyCyan, Neon)
	seat.CastShadow = false
	for _, side in { -1, 1 } do
		Kit.block(scanner, "ArchPost", Vector3.new(1.2, 10, 1.2), base * CFrame.new(side * 5, 6, 0), World.Steel)
	end
	Kit.column(scanner, "Halo", 11, 0.8, base * CFrame.new(0, 11, 0), World.FacilityCream)
	local emitter = Kit.column(scanner, "HaloEmitter", 8, 0.2, base * CFrame.new(0, 10.85, 0), World.EnergyCyan, Neon)
	emitter.CastShadow = false
	local light = Instance.new("PointLight")
	light.Name = "ScannerLight"
	light.Color = World.EnergyCyan
	light.Range = 14
	light.Brightness = 0.8
	light.Shadows = false
	light.Parent = emitter
	Props.console(scanner, base * CFrame.new(8, 0, -1) * Kit.yaw(180))
	Kit.marker(markers, "ScannerAnchor", base * CFrame.new(0, 5.4, 0))
end

local function buildChamber(parent: Instance, origin: CFrame, slotIndex: number, slot: Vector2)
	local chamber = Kit.model(parent, `Chamber{slotIndex}`)
	chamber:SetAttribute(GameConfig.Attributes.SlotIndex, slotIndex)
	-- Face the lab's center so the ID plate is readable from the scanner area.
	local position = (origin * CFrame.new(slot.X, FLOOR_TOP, slot.Y)).Position
	local center = (origin * CFrame.new(0, FLOOR_TOP, 6)).Position
	local base = CFrame.lookAt(position, Vector3.new(center.X, position.Y, center.Z))
	Kit.column(chamber, "Base", 6, 1.2, base, World.Floor)
	local ring = Kit.column(chamber, "GlowRing", 5.4, 1.3, base, World.EnergyCyan, Neon)
	ring.CastShadow = false
	Kit.part(chamber, {
		name = "Tube",
		shape = "Cylinder",
		size = Vector3.new(7, 5, 5),
		cframe = base * CFrame.new(0, 1.3 + 3.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
		color = World.Glass,
		material = Glass,
		transparency = 0.6,
	})
	Kit.column(chamber, "Cap", 6, 1, base * CFrame.new(0, 8.3, 0), World.FacilityCream)
	local plate =
		Kit.block(chamber, "IdPlate", Vector3.new(3, 0.9, 0.2), base * CFrame.new(0, 0.6, -3.05), World.HazardNavy)
	Kit.label(plate, "EMPTY", Enum.NormalId.Front, World.FacilityCream)
	Kit.marker(chamber, "AlienAnchor", base * CFrame.new(0, 4.8, 0))
	return chamber
end

local function buildFrontYard(model: Model, origin: CFrame, markers: Folder)
	local function at(x: number, y: number, z: number): CFrame
		return origin * CFrame.new(x, y, z)
	end
	local half = WorldLayout.Plot.Size / 2
	-- Walkway from the entrance across the sidewalk to the road
	Kit.block(model, "Walkway", Vector3.new(12, 0.3, 26), at(0, PAD_TOP - 0.05, FRONT_Z - 13), World.FacilityTrim)

	-- Owner sign faces the road; PlotService writes the owner's name into OwnerLabel.
	local sign, label = Props.sign(model, at(-15, PAD_TOP, -half + 3.5), "VACANT LAB", 10)
	sign.Name = "OwnerSign"
	label.Name = "OwnerLabel"

	for _, side in { -1, 1 } do
		Props.lightPost(model, at(side * 7.5, PAD_TOP, -half + 1.5))
		local planter = at(side * 18, PAD_TOP, FRONT_Z - 6)
		Kit.block(model, "Planter", Vector3.new(7, 1.8, 5), planter * CFrame.new(0, 0.9, 0), World.FacilityCream)
		Kit.ball(model, "PlanterShrub", 3.2, (planter * CFrame.new(-1.6, 2.2, 0)).Position, World.Sage)
		Kit.ball(model, "PlanterShrub", 2.6, (planter * CFrame.new(1.6, 2.0, 0.4)).Position, World.SageDark)
	end

	-- Where the owner's character appears, facing the road.
	Kit.marker(markers, "SpawnPoint", at(0, PAD_TOP + 3, FRONT_Z - 10))
end

function LabPlot.build(parent: Instance, plotIndex: number, origin: CFrame): Model
	local model = Kit.model(parent, `Plot{plotIndex}`)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:AddTag(GameConfig.Tags.Plot)
	model:SetAttribute(GameConfig.Attributes.PlotIndex, plotIndex)
	local markers = Kit.folder(model, "Markers")

	local size = WorldLayout.Plot.Size
	local accent = Palette.PlotAccents[(plotIndex - 1) % #Palette.PlotAccents + 1]
	local pad = Kit.block(model, "Pad", Vector3.new(size, 1.1, size), origin * CFrame.new(0, PAD_TOP - 0.6, 0), accent)
	Kit.block(
		model,
		"PadInner",
		Vector3.new(size - 3, 1.1, size - 3),
		origin * CFrame.new(0, PAD_TOP - 0.55, 0),
		World.FacilityCream
	)
	model.PrimaryPart = pad

	local header = buildShell(model, origin, accent)
	Kit.label(header, string.format("LAB %02d", plotIndex), Enum.NormalId.Front, World.FacilityCream)
	buildRoof(model, origin, accent)
	buildScanner(model, origin, markers)
	local chambers = Kit.folder(model, "Chambers")
	for slotIndex, slot in CHAMBER_SLOTS do
		buildChamber(chambers, origin, slotIndex, slot)
	end
	buildFrontYard(model, origin, markers)
	return model
end

return LabPlot
