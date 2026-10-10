--!strict
--[[
	DesertRegion — Zone B, "Groom Lake Dunes", the starter extraction region.

	Readable structure for new players: one trail from the Extraction Gate to a signposted
	junction (with an overturned research truck whose spilled cargo holds the starter
	capsules), then three branches to three distinct landmarks:
	  • Crash Crater (west)    — crashed saucer, glowing crystals
	  • Research Outpost (north) — damaged buildings, climbable comms tower
	  • Nest Ridge (east)      — tall mesa with alien nests, reachable by ramp or jetpack
	Beyond the north fence, the distant Area 51 skyline frames the horizon.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local WorldLayout = require(ReplicatedStorage.Shared.Config.WorldLayout)
local Kit = require(script.Parent.Kit)
local Props = require(script.Parent.Props)

local World = Palette.World
local Desert = WorldLayout.Desert
local Sites = Desert.Sites
local Sand = Enum.Material.Sand
local Sandstone = Enum.Material.Sandstone
local Glass = Enum.Material.Glass
local Neon = Enum.Material.Neon

local REGION_ID = "desert"
local SEED = 51
local UP_FROM_X = CFrame.Angles(0, 0, math.rad(90))

local GATE_EXIT = Vector3.new(0, 0, WorldLayout.District.RoadNorthZ)
-- Nest Ridge's mesa ramp climbs the west face; the trail ends at its foot.
local RAMP_LENGTH = 60
local RAMP_Z = -18
local RAMP_FOOT = Sites.NestRidge + Vector3.new(-20 - RAMP_LENGTH, 0, RAMP_Z)
local TRAILS = {
	{ GATE_EXIT, Desert.Junction },
	{ Desert.Junction, Sites.CrashCrater },
	{ Desert.Junction, Sites.Outpost },
	{ Desert.Junction, RAMP_FOOT },
}
-- Scatter keeps this far from each site's center.
local SITE_CLEARANCES = {
	{ center = Sites.CrashCrater, radius = 70 },
	{ center = Sites.Outpost, radius = 80 },
	{ center = Sites.NestRidge, radius = 95 },
}

local DesertRegion = {}

-- Trail segments (start, finish), exposed for world specs.
DesertRegion.Trails = TRAILS

local function trailDistance(position: Vector3): number
	local best = math.huge
	for _, segment in TRAILS do
		best = math.min(best, Kit.distanceToSegment(position, segment[1], segment[2]))
	end
	return best
end

local function siteClearance(position: Vector3, margin: number): boolean
	for _, site in SITE_CLEARANCES do
		local dx, dz = position.X - site.center.X, position.Z - site.center.Z
		if math.sqrt(dx * dx + dz * dz) < site.radius + margin then
			return false
		end
	end
	local junction = Desert.Junction
	local jx, jz = position.X - junction.X, position.Z - junction.Z
	return math.sqrt(jx * jx + jz * jz) >= 45 + margin
end

local function randomPointInBounds(rng: Kit.Rng, inset: number): Vector3
	local b = Desert.Bounds
	return Vector3.new(rng:range(b.MinX + inset, b.MaxX - inset), 0, rng:range(b.MinZ + inset, b.MaxZ - inset))
end

-- Repeatedly samples points until `accept` passes or attempts run out.
local function scatter(rng: Kit.Rng, count: number, inset: number, accept: (Vector3) -> boolean, place: (Vector3) -> ())
	local placed, attempts = 0, 0
	while placed < count and attempts < count * 60 do
		attempts += 1
		local point = randomPointInBounds(rng, inset)
		if accept(point) then
			place(point)
			placed += 1
		end
	end
end

local function addSpawn(folder: Folder, siteId: string, tier: string, position: Vector3)
	local index = 1
	while folder:FindFirstChild(`{siteId}{index}`) do
		index += 1
	end
	local marker = Kit.marker(folder, `{siteId}{index}`, CFrame.new(position + Vector3.new(0, 1.5, 0)))
	marker:AddTag(GameConfig.Tags.SpecimenSpawn)
	marker:SetAttribute(GameConfig.Attributes.RegionId, REGION_ID)
	marker:SetAttribute(GameConfig.Attributes.SiteId, siteId)
	marker:SetAttribute(GameConfig.Attributes.SpawnTier, tier)
end

local function buildTrails(model: Model)
	local trails = Kit.model(model, "Trails")
	local width = 16
	for _, segment in TRAILS do
		local a, b = segment[1], segment[2]
		local length = (b - a).Magnitude + width
		local middle = (a + b) / 2
		Kit.block(trails, "Trail", Vector3.new(width, 0.3, length), CFrame.lookAt(middle, b), World.SandLight, Sand)
		-- Markers alternate sides every 40 studs.
		local direction = (b - a).Unit
		local right = direction:Cross(Vector3.yAxis)
		local steps = math.floor((b - a).Magnitude / 40)
		for step = 1, steps do
			local side = if step % 2 == 0 then 1 else -1
			local point = a + direction * (step * 40) + right * side * (width / 2 + 2)
			Props.trailMarker(trails, CFrame.new(point))
		end
	end
	Kit.column(
		trails,
		"JunctionPad",
		44,
		0.32,
		CFrame.new(Desert.Junction - Vector3.new(0, 0.01, 0)),
		World.SandLight,
		Sand
	)
end

local function buildSignpost(model: Model)
	local signpost = Kit.model(model, "JunctionSignpost")
	local base = CFrame.new(Desert.Junction)
	Kit.column(signpost, "Pole", 1.4, 13, base, World.Steel)
	Kit.column(signpost, "Cap", 2, 0.8, base * CFrame.new(0, 13, 0), World.EnergyCyan)
	local destinations = {
		{ text = "CRASH CRATER", target = Sites.CrashCrater, height = 11.5 },
		{ text = "RESEARCH OUTPOST", target = Sites.Outpost, height = 9.5 },
		{ text = "NEST RIDGE", target = RAMP_FOOT, height = 7.5 },
		{ text = "LAB DISTRICT", target = GATE_EXIT, height = 5.5 },
	}
	for _, destination in destinations do
		local text, target, height = destination.text, destination.target, destination.height
		local direction = Vector3.new(target.X - Desert.Junction.X, 0, target.Z - Desert.Junction.Z).Unit
		local center = Desert.Junction + direction * 7 + Vector3.new(0, height, 0)
		-- Board's long axis points toward the destination.
		local frame = CFrame.lookAt(center, center + direction) * Kit.yaw(90)
		local board = Kit.block(signpost, "Board", Vector3.new(12, 2, 0.5), frame, World.HazardNavy)
		Kit.label(board, text, Enum.NormalId.Front, World.FacilityCream)
		Kit.label(board, text, Enum.NormalId.Back, World.FacilityCream)
		local tipFrame = CFrame.lookAt(center, center + direction) * CFrame.new(0, 0, -6.6)
		Kit.block(
			signpost,
			"Pointer",
			Vector3.new(0.5, 1.6, 1.6),
			tipFrame * CFrame.Angles(math.rad(45), 0, 0),
			World.EnergyCyan
		)
	end
end

local function buildTruckWreck(model: Model, rng: Kit.Rng, spawns: Folder)
	local wreck = Kit.model(model, "TruckWreck")
	-- Lying on its side, cargo spilled toward the trail.
	local frame = Kit.ground(30, -298, 20) * CFrame.new(0, 4.5, 0) * CFrame.Angles(0, 0, math.rad(88))
	Kit.block(wreck, "Cargo", Vector3.new(9, 9, 18), frame * CFrame.new(0, 0, 3), World.FacilityCream)
	Kit.block(wreck, "CargoStripe", Vector3.new(9.2, 1.4, 18.2), frame * CFrame.new(0, 0, 3), World.AlertOrange)
	Kit.block(wreck, "Cab", Vector3.new(8, 7, 7), frame * CFrame.new(0, -1, -10), World.Floor)
	Kit.part(wreck, {
		name = "Windshield",
		size = Vector3.new(6.4, 3, 0.3),
		cframe = frame * CFrame.new(0, 0.6, -13.6),
		color = World.Glass,
		material = Glass,
		transparency = 0.3,
	})
	for _, z in { -10, 6 } do
		for _, side in { -1, 1 } do
			Kit.part(wreck, {
				name = "Wheel",
				shape = "Cylinder",
				size = Vector3.new(1.6, 4.2, 4.2),
				cframe = frame * CFrame.new(side * 4.6, -4.4, z),
				color = World.HazardNavy,
			})
		end
	end
	for _, offset in { Vector3.new(14, 0, 6), Vector3.new(6, 0, 16), Vector3.new(20, 0, -8), Vector3.new(-6, 0, 12) } do
		Props.crateStack(wreck, Kit.ground(30 + offset.X, -298 + offset.Z, rng:range(0, 90)), rng)
	end

	for _, position in
		{
			Vector3.new(-12, 0, -212),
			Vector3.new(14, 0, -238),
			Vector3.new(-20, 0, -268),
			Vector3.new(46, 0, -278),
			Vector3.new(-26, 0, -340),
			Vector3.new(24, 0, -356),
		}
	do
		addSpawn(spawns, "Starter", "Starter", position)
	end
end

local function buildCrashCrater(model: Model, rng: Kit.Rng, spawns: Folder)
	local site = Kit.model(model, "CrashCrater")
	local center = Sites.CrashCrater
	Kit.column(site, "CraterFloor", 104, 0.34, CFrame.new(center - Vector3.new(0, 0.02, 0)), World.SandShadow, Sand)

	-- Rim mounds, with an opening facing the trail.
	local toJunction = math.deg(math.atan2(Desert.Junction.X - center.X, Desert.Junction.Z - center.Z))
	for index = 0, 13 do
		local angle = index * (360 / 14)
		local delta = (angle - toJunction + 540) % 360 - 180
		if math.abs(delta) > 24 then
			local frame = CFrame.new(center) * Kit.yaw(angle) * CFrame.new(0, -4, 56)
			Kit.part(site, {
				name = "RimMound",
				shape = "Cylinder",
				size = Vector3.new(30, 16, 16),
				cframe = frame,
				color = if index % 2 == 0 then World.SandShadow else Palette.Core.Sand,
				material = Sand,
			})
		end
	end

	-- The crashed saucer, nose-down in the sand.
	local saucer = Kit.model(site, "Saucer")
	saucer.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local tilt = CFrame.new(center + Vector3.new(8, 3.5, -6))
		* Kit.yaw(30)
		* CFrame.Angles(math.rad(20), 0, math.rad(-6))
	Kit.part(saucer, {
		name = "Hull",
		shape = "Cylinder",
		size = Vector3.new(4.5, 42, 42),
		cframe = tilt * UP_FROM_X,
		color = World.Steel,
	})
	Kit.part(saucer, {
		name = "RimBand",
		shape = "Cylinder",
		size = Vector3.new(1.4, 44.5, 44.5),
		cframe = tilt * UP_FROM_X,
		color = World.AlertOrange,
	})
	Kit.part(saucer, {
		name = "Belly",
		shape = "Cylinder",
		size = Vector3.new(2.6, 28, 28),
		cframe = tilt * CFrame.new(0, -2.8, 0) * UP_FROM_X,
		color = World.SteelDark,
	})
	Kit.part(saucer, {
		name = "Dome",
		shape = "Ball",
		size = Vector3.one * 16,
		cframe = tilt * CFrame.new(0, 2.6, 0),
		color = World.Glass,
		material = Glass,
		transparency = 0.35,
	})
	for index = 0, 7 do
		local light = Kit.part(saucer, {
			name = "RimLight",
			shape = "Ball",
			size = Vector3.one * 1.4,
			cframe = tilt * Kit.yaw(index * 45) * CFrame.new(0, 0, -22.6),
			color = if index % 3 == 0 then World.AlertOrange else World.EnergyCyan,
			material = Neon,
			collide = false,
			castShadow = false,
		})
		light.Name = "RimLight"
	end
	for _ = 1, 6 do
		local angle = rng:range(0, 360)
		local distance = rng:range(26, 44)
		local debris = CFrame.new(center) * Kit.yaw(angle) * CFrame.new(0, 0.8, -distance)
		Kit.block(
			site,
			"Debris",
			Vector3.new(rng:range(2, 5), rng:range(0.6, 1.4), rng:range(2, 6)),
			debris
				* CFrame.Angles(math.rad(rng:range(-20, 20)), math.rad(rng:range(0, 180)), math.rad(rng:range(-20, 20))),
			if rng:next() < 0.5 then World.Steel else World.FacilityTrim
		)
	end
	for index, offset in
		{ Vector3.new(-40, 0, 14), Vector3.new(26, 0, 34), Vector3.new(-18, 0, -42), Vector3.new(42, 0, -16) }
	do
		local color = if index % 2 == 0 then World.EnergyCyan else World.AlienMint
		Props.crystalCluster(
			site,
			CFrame.new(center + offset) * Kit.yaw(rng:range(0, 360)),
			1.3,
			color,
			index <= 2,
			rng
		)
	end

	for _, offset in
		{
			Vector3.new(-30, 0, -10),
			Vector3.new(-20, 0, 25),
			Vector3.new(10, 0, 32),
			Vector3.new(34, 0, 18),
			Vector3.new(30, 0, -30),
			Vector3.new(-12, 0, -36),
		}
	do
		addSpawn(spawns, "CrashCrater", "Standard", center + offset)
	end
	addSpawn(spawns, "CrashCrater", "Secret", (tilt * CFrame.new(0, 10.5, 0)).Position)
end

local function buildOutpost(model: Model, rng: Kit.Rng, spawns: Folder)
	local site = Kit.model(model, "ResearchOutpost")
	local center = Sites.Outpost
	local function at(x: number, z: number, yaw: number?): CFrame
		return Kit.ground(center.X + x, center.Z + z, yaw)
	end

	Kit.block(site, "Slab", Vector3.new(124, 0.6, 96), at(0, 0) * CFrame.new(0, 0.2, 0), World.Paving)

	-- Damaged lab: two walls standing, one crumbling, roof collapsed onto the ground.
	local lab = Kit.model(site, "DamagedLab")
	local labOrigin = at(-28, -10)
	Kit.block(lab, "BackWall", Vector3.new(30, 12, 2), labOrigin * CFrame.new(0, 6, -10), World.FacilityCream)
	Kit.block(lab, "SideWall", Vector3.new(2, 12, 22), labOrigin * CFrame.new(-14, 6, 0), World.FacilityCream)
	for index, height in { 10, 6, 3 } do
		Kit.block(
			lab,
			"BrokenWall",
			Vector3.new(2, height, 6.5),
			labOrigin * CFrame.new(14, height / 2, -11 + index * 6.8),
			World.FacilityTrim
		)
	end
	Kit.block(lab, "FrontStub", Vector3.new(9, 7, 2), labOrigin * CFrame.new(-9.5, 3.5, 10), World.FacilityCream)
	-- The back half of the roof still stands; the front half snapped and fell inward.
	Kit.block(lab, "RoofIntact", Vector3.new(31, 1.4, 12), labOrigin * CFrame.new(0, 12.7, -5), World.FacilityTrim)
	Kit.block(
		lab,
		"RoofFallen",
		Vector3.new(29, 1.4, 16.2),
		labOrigin * CFrame.new(1, 6.25, 6.5) * CFrame.Angles(math.rad(46), 0, math.rad(5)),
		World.FacilityTrim
	)
	Props.console(lab, labOrigin * CFrame.new(-8, 0.5, -6))
	Props.console(lab, labOrigin * CFrame.new(6, 0.5, -6))

	-- Storage depot: intact, closed.
	local depot = Kit.model(site, "StorageDepot")
	local depotOrigin = at(32, 14)
	Kit.block(depot, "Body", Vector3.new(26, 10, 20), depotOrigin * CFrame.new(0, 5, 0), World.FacilityCream)
	Kit.part(depot, {
		name = "Roof",
		shape = "Cylinder",
		size = Vector3.new(27.2, 20, 20),
		cframe = depotOrigin * CFrame.new(0, 10, 0),
		color = World.FacilityTrim,
	})
	Kit.block(depot, "Door", Vector3.new(12, 8, 0.6), depotOrigin * CFrame.new(0, 4, 10.2), World.Floor)
	Kit.block(depot, "DoorStripe", Vector3.new(12.2, 1, 0.7), depotOrigin * CFrame.new(0, 0.9, 10.2), World.AlertOrange)

	-- Climbable comms tower; its platform hides a secret capsule.
	local tower = Kit.model(site, "CommsTower")
	tower.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local towerBase = at(-6, -36)
	local truss = Instance.new("TrussPart")
	truss.Name = "Truss"
	truss.Anchored = true
	truss.Size = Vector3.new(2, 40, 2)
	truss.CFrame = towerBase * CFrame.new(0, 20, 0)
	truss.Color = World.Steel
	truss.Material = Enum.Material.SmoothPlastic
	truss.Parent = tower
	Kit.block(tower, "Platform", Vector3.new(9, 1, 9), towerBase * CFrame.new(0, 40.5, 0), World.FacilityCream)
	Kit.block(tower, "PlatformRail", Vector3.new(9.4, 0.4, 9.4), towerBase * CFrame.new(0, 41.2, 0), World.AlertOrange)
	Kit.column(tower, "Mast", 0.6, 10, towerBase * CFrame.new(3.4, 41, 3.4), World.Steel)
	local beacon =
		Kit.ball(tower, "Beacon", 1.4, (towerBase * CFrame.new(3.4, 51.4, 3.4)).Position, World.AlertOrange, Neon)
	beacon.CastShadow = false

	-- Fallen radar dish
	Kit.part(site, {
		name = "FallenDish",
		shape = "Cylinder",
		size = Vector3.new(1.6, 24, 24),
		cframe = at(-40, 30) * CFrame.new(0, 7, 0) * CFrame.Angles(0, math.rad(35), math.rad(62)),
		color = World.FacilityTrim,
	})
	Kit.column(site, "DishStub", 2.4, 3, at(-30, 24), World.SteelDark)

	-- Broken checkpoint across the entrance (south side, facing the junction trail).
	for _, x in { -26, -16, 16, 26 } do
		Props.barrier(site, at(x, 46))
	end
	-- One barrier knocked flat onto its back.
	Props.barrier(
		site,
		at(-8, 52, 70) * CFrame.new(0, 1.1, 0) * CFrame.Angles(math.rad(84), 0, 0) * CFrame.new(0, -1.3, 0)
	)
	Props.fence(site, (at(-62, 46)).Position, (at(-32, 46)).Position)
	Props.fence(site, (at(32, 46)).Position, (at(62, 46)).Position)
	Props.fence(site, (at(-62, 46)).Position, (at(-62, -46)).Position)
	Props.fence(site, (at(62, -46)).Position, (at(62, 8)).Position)

	for _, offset in
		{
			Vector3.new(-48, 0, 8),
			Vector3.new(10, 0, 30),
			Vector3.new(48, 0, -14),
			Vector3.new(16, 0, -40),
			Vector3.new(-44, 0, -36),
		}
	do
		Props.crateStack(site, at(offset.X, offset.Z, rng:range(0, 90)), rng)
	end
	Props.crystalCluster(site, at(8, -12, 20), 1.1, World.AlienMint, true, rng)
	Props.nest(site, at(48, -34), 0.8, rng)
	Props.lightPost(site, at(-14, 40))
	Props.lightPost(site, at(14, 40))

	for _, offset in
		{
			Vector3.new(-4, 0, 12),
			Vector3.new(20, 0, -22),
			Vector3.new(-24, 0, -36),
			Vector3.new(34, 0, -26),
			Vector3.new(50, 0, 32),
			Vector3.new(-18, 0, 24),
		}
	do
		addSpawn(spawns, "Outpost", "Standard", center + offset + Vector3.new(0, 0.5, 0))
	end
	addSpawn(spawns, "Outpost", "Secret", (towerBase * CFrame.new(0, 41, 0)).Position)
end

local function buildNestRidge(model: Model, rng: Kit.Rng, spawns: Folder)
	local site = Kit.model(model, "NestRidge")
	local center = Sites.NestRidge
	local top = Desert.MesaHeight
	local function at(x: number, z: number, y: number?): CFrame
		return CFrame.new(center.X + x, y or 0, center.Z + z)
	end

	-- Mesa: x ∈ [-20, 52], z ∈ [-32, 32] relative to the site center.
	local mesa = Kit.model(site, "Mesa")
	mesa.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	-- Three stepped strata under an overhanging cap give a layered, stylized silhouette.
	local tiers = {
		{ size = Vector3.new(78, 10, 70), bottom = -0.6, color = World.Rock },
		{ size = Vector3.new(74, 8.6, 66), bottom = 9.2, color = World.RockDark },
		{ size = Vector3.new(70, 7.2, 62), bottom = 17.6, color = World.Rock },
	}
	for index, tier in tiers do
		local yaw = if index == 2 then 1.5 else 0
		Kit.block(
			mesa,
			`Tier{index}`,
			tier.size,
			at(16, 0, tier.bottom + tier.size.Y / 2) * Kit.yaw(yaw),
			tier.color,
			Sandstone
		)
	end
	Kit.block(mesa, "Cap", Vector3.new(71.4, 1.2, 63.4), at(16, 0, top - 0.6), World.RockLight, Sandstone)
	Kit.block(mesa, "Ledge", Vector3.new(44, top * 0.62, 56), at(58, 6, top * 0.31 - 0.6), World.RockDark, Sandstone)
	-- Talus slopes against the north face.
	for _, x in { 0, 30 } do
		Kit.part(mesa, {
			name = "Talus",
			shape = "Wedge",
			size = Vector3.new(18, 9, 12),
			cframe = at(x, -40, 3.9),
			color = World.RockLight,
			material = Sandstone,
		})
	end

	-- Ramp up the west face (WedgePart rises toward its local +Z, turned to face east).
	Kit.part(mesa, {
		name = "Ramp",
		shape = "Wedge",
		size = Vector3.new(14, top, RAMP_LENGTH),
		cframe = at(-20 - RAMP_LENGTH / 2, RAMP_Z, top / 2 - 0.6) * Kit.yaw(90),
		color = World.RockLight,
		material = Sandstone,
	})

	-- A lone spire beside the mesa with a secret capsule on top.
	local spireBase = at(66, -46)
	local spireHeight = 0
	for index, size in { Vector3.new(16, 18, 14), Vector3.new(12, 16, 11), Vector3.new(9, 12, 8) } do
		Kit.block(
			site,
			"Spire",
			size,
			spireBase * CFrame.new(0, spireHeight + size.Y / 2, 0) * Kit.yaw(index * 17),
			if index == 2 then World.RockLight else World.Rock,
			Sandstone
		)
		spireHeight += size.Y
	end

	for _, offset in { Vector2.new(6, 14), Vector2.new(28, -14), Vector2.new(40, 16), Vector2.new(18, 22) } do
		Props.nest(site, at(offset.X, offset.Y, top), 1, rng)
	end
	Props.crystalCluster(site, at(-6, -24, top) * Kit.yaw(30), 1.2, World.AlienMint, true, rng)
	Props.crystalCluster(site, at(44, -4, top) * Kit.yaw(80), 1.0, World.EnergyCyan, false, rng)
	Props.nest(site, at(-30, 30), 0.9, rng)
	Props.nest(site, at(10, 45), 0.9, rng)

	for _, offset in { Vector2.new(-34, 14), Vector2.new(-6, 44), Vector2.new(30, 46) } do
		addSpawn(spawns, "NestRidge", "Standard", at(offset.X, offset.Y).Position)
	end
	for _, offset in { Vector2.new(0, -6), Vector2.new(20, 4), Vector2.new(44, -24), Vector2.new(-8, 20) } do
		addSpawn(spawns, "NestRidge", "Elevated", at(offset.X, offset.Y, top).Position)
	end
	addSpawn(spawns, "NestRidge", "Secret", (spireBase * CFrame.new(0, spireHeight, 0)).Position)
end

local function buildScatter(model: Model, rng: Kit.Rng, spawns: Folder)
	local scatterModel = Kit.model(model, "Scatter")
	local spawnPoints = {}
	for _, marker in spawns:GetChildren() do
		table.insert(spawnPoints, (marker :: BasePart).CFrame.Position)
	end
	local function clearOfSpawns(point: Vector3, radius: number): boolean
		for _, spawnPoint in spawnPoints do
			if Vector3.new(spawnPoint.X - point.X, 0, spawnPoint.Z - point.Z).Magnitude < radius then
				return false
			end
		end
		return true
	end

	-- Rolling dunes: long cylinders half-sunk into the sand, kept clear of trails and sites.
	local dunes = Kit.model(scatterModel, "Dunes")
	local placedDunes: { { position: Vector3, length: number } } = {}
	local attempts = 0
	while #placedDunes < 18 and attempts < 2000 do
		attempts += 1
		local point = randomPointInBounds(rng, 20)
		local length = rng:range(90, 200)
		-- Keep the whole dune north of the district wall.
		local clear = point.Z + length / 2 < Desert.Bounds.MaxZ - 10
			and trailDistance(point) >= length / 2 + 18
			and siteClearance(point, length / 2)
			and clearOfSpawns(point, length / 2 + 12)
		for _, other in placedDunes do
			if clear and (other.position - point).Magnitude < (other.length + length) * 0.35 then
				clear = false
			end
		end
		if clear then
			table.insert(placedDunes, { position = point, length = length })
			-- Wide, shallow arcs read as rolling sand rather than logs.
			local diameter = rng:range(90, 150)
			local height = rng:range(3.5, 7)
			Kit.part(dunes, {
				name = "Dune",
				shape = "Cylinder",
				size = Vector3.new(length, diameter, diameter),
				cframe = CFrame.new(point.X, height - diameter / 2, point.Z) * Kit.yaw(rng:range(0, 180)),
				color = if rng:next() < 0.5 then World.SandLight else World.SandShadow,
				material = Sand,
			})
		end
	end

	local rocks = Kit.model(scatterModel, "Rocks")
	scatter(rng, 16, 30, function(point)
		return trailDistance(point) > 16 and siteClearance(point, 10) and clearOfSpawns(point, 18)
	end, function(point)
		Props.rockCluster(rocks, CFrame.new(point), rng:range(0.8, 1.6), rng)
	end)

	local plants = Kit.model(scatterModel, "Plants")
	scatter(rng, 26, 20, function(point)
		return trailDistance(point) > 10 and siteClearance(point, 0) and clearOfSpawns(point, 8)
	end, function(point)
		Props.plant(plants, CFrame.new(point) * Kit.yaw(rng:range(0, 360)), rng:range(0.9, 1.4), rng)
	end)

	local crystals = Kit.model(scatterModel, "Crystals")
	scatter(rng, 5, 40, function(point)
		local distance = trailDistance(point)
		return distance > 14 and distance < 60 and siteClearance(point, 10) and clearOfSpawns(point, 10)
	end, function(point)
		Props.crystalCluster(
			crystals,
			CFrame.new(point) * Kit.yaw(rng:range(0, 360)),
			0.9,
			World.EnergyCyan,
			false,
			rng
		)
	end)

	local nests = Kit.model(scatterModel, "Nests")
	scatter(rng, 2, 40, function(point)
		local distance = trailDistance(point)
		return distance > 16 and distance < 45 and siteClearance(point, 20) and clearOfSpawns(point, 12)
	end, function(point)
		Props.nest(nests, CFrame.new(point), 0.7, rng)
	end)

	-- Boundary ridges along the east and west edges.
	local ridges = Kit.model(scatterModel, "BoundaryRidges")
	local b = Desert.Bounds
	for z = b.MaxZ - 20, b.MinZ + 20, -62 do
		for _, x in { b.MinX - 12, b.MaxX + 12 } do
			Props.rockCluster(ridges, CFrame.new(x, 0, z + rng:range(-12, 12)), rng:range(2.6, 3.6), rng)
		end
	end
end

local function buildSkyline(model: Model, rng: Kit.Rng)
	local skyline = Kit.model(model, "DistantFacility")
	skyline.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local b = Desert.Bounds
	-- North security fence marks the edge of the playable area.
	local fenceZ = b.MinZ
	for _, run in { { b.MinX, -140 }, { -140, 0 }, { 0, 140 }, { 140, b.MaxX } } do
		Props.fence(skyline, Vector3.new(run[1], 0, fenceZ), Vector3.new(run[2], 0, fenceZ), 20)
	end
	for _, x in { -70, 70 } do
		Props.sign(
			skyline,
			CFrame.lookAt(Vector3.new(x, 0, fenceZ + 3), Vector3.new(x, 0, fenceZ + 10)),
			"RESTRICTED AIRSPACE",
			16
		)
	end

	local origin = Desert.DistantFacility
	for _, x in { -170, 0, 170 } do
		local base = CFrame.new(origin.X + x, 0, origin.Z + rng:range(-20, 20))
		Kit.block(skyline, "Hangar", Vector3.new(110, 30, 64), base * CFrame.new(0, 15, 0), World.FacilityCream)
		Kit.part(skyline, {
			name = "HangarRoof",
			shape = "Cylinder",
			size = Vector3.new(111.2, 64, 64),
			cframe = base * CFrame.new(0, 30, 0),
			color = World.FacilityTrim,
		})
		Kit.block(skyline, "HangarDoor", Vector3.new(50, 24, 1), base * CFrame.new(0, 12, -32.4), World.Floor)
	end
	local tower = CFrame.new(origin.X + 280, 0, origin.Z + 30)
	Kit.column(skyline, "Tower", 14, 96, tower, World.FacilityCream)
	Kit.column(skyline, "TowerPod", 26, 10, tower * CFrame.new(0, 96, 0), World.Floor)
	local beacon = Kit.column(skyline, "TowerBeacon", 27, 1, tower * CFrame.new(0, 106, 0), World.AlertOrange, Neon)
	beacon.CastShadow = false
end

local function buildAtmosphere(model: Model)
	local atmosphere = Kit.model(model, "AmbientParticles")
	for _, position in { Desert.Junction, Sites.CrashCrater, Sites.Outpost, Sites.NestRidge } do
		local volume = Kit.part(atmosphere, {
			name = "DustVolume",
			size = Vector3.new(160, 30, 160),
			cframe = CFrame.new(position + Vector3.new(0, 15, 0)),
			color = World.SandLight,
			transparency = 1,
			collide = false,
			castShadow = false,
		})
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "DustMotes"
		emitter.Shape = Enum.ParticleEmitterShape.Box
		emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		emitter.Rate = 4
		emitter.Lifetime = NumberRange.new(6, 10)
		emitter.Speed = NumberRange.new(0.5, 2)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Acceleration = Vector3.new(1.5, 0.2, 0)
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.5, 0.8),
			NumberSequenceKeypoint.new(1, 0.3),
		})
		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		})
		emitter.Color = ColorSequence.new(World.SandLight)
		emitter.LightEmission = 0.3
		emitter.Parent = volume
	end
end

function DesertRegion.build(parent: Instance): Model
	local model = Kit.model(parent, "DesertRegion")
	model:SetAttribute(GameConfig.Attributes.RegionId, REGION_ID)
	local rng = Kit.rng(SEED)
	local spawns = Kit.folder(model, "SpecimenSpawns")

	buildTrails(model)
	buildSignpost(model)
	buildTruckWreck(model, rng, spawns)
	buildCrashCrater(model, rng, spawns)
	buildOutpost(model, rng, spawns)
	buildNestRidge(model, rng, spawns)
	buildScatter(model, rng, spawns)
	buildSkyline(model, rng)
	buildAtmosphere(model)
	return model
end

return DesertRegion
