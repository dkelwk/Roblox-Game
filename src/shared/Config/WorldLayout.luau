--!strict
--[[
	WorldLayout — the single source of truth for world-space positions and sizes.

	The world blockout generator builds geometry from these numbers, and server services use
	the same numbers for authoritative checks (region membership, plot ownership areas).
	Moving something here moves it everywhere.

	Conventions: 1 unit = 1 stud. Ground top surface is Y = 0. "North" is -Z: players leave
	their labs heading north through the Extraction Gate into the desert.
]]

export type Bounds = {
	MinX: number,
	MaxX: number,
	MinZ: number,
	MaxZ: number,
}

local WorldLayout = {}

WorldLayout.GroundY = 0

local NORTH = Vector3.new(0, 0, -1)

local function facing(position: Vector3, direction: Vector3): CFrame
	return CFrame.lookAt(position, position + direction)
end

-- Zone A: Player Laboratory District
WorldLayout.District = {
	Bounds = { MinX = -150, MaxX = 150, MinZ = -170, MaxZ = 260 } :: Bounds,
	RoadWidth = 28,
	-- The main road runs from the Extraction Gate (north) to the central plaza (south).
	RoadNorthZ = -170,
	RoadSouthZ = 104,
	Plaza = { Center = Vector3.new(0, 0, 140), Radius = 38 },
	MainFacility = Vector3.new(0, 0, 214),
	UpgradeStation = facing(Vector3.new(0, 0, 150), NORTH),
	-- Fallback spawn used before a plot is assigned.
	DefaultSpawn = facing(Vector3.new(0, 0, 118), NORTH),
	ExtractionGate = facing(Vector3.new(0, 0, -150), NORTH),
}

WorldLayout.Plot = {
	-- Square footprint, in studs.
	Size = 60,
	-- Physical chamber slots built into every lab. Must cover the max Containment Wing level.
	ChamberSlotCount = 8,
}

--[[
	Plot origins. Each plot's CFrame looks toward the road, so in plot-local space the
	front edge (entrance, sign, spawn point) is at -Z.
	Plots 1–3 line the west side of the road from south to north; 4–6 line the east side.
]]
WorldLayout.Plots = {} :: { CFrame }
do
	local rowZ = { 80, 0, -80 }
	local sideX = { -52, 52 }
	for _, x in sideX do
		for _, z in rowZ do
			local center = Vector3.new(x, 0, z)
			local towardRoad = Vector3.new(-math.sign(x), 0, 0)
			table.insert(WorldLayout.Plots, facing(center, towardRoad))
		end
	end
end

-- Zone B: Desert Extraction Region (Groom Lake Dunes)
WorldLayout.Desert = {
	-- Playable area. Anything outside is backdrop.
	Bounds = { MinX = -420, MaxX = 420, MinZ = -1000, MaxZ = -170 } :: Bounds,
	-- Where the trail from the gate splits toward the three sites.
	Junction = Vector3.new(0, 0, -320),
	Sites = {
		CrashCrater = Vector3.new(-230, 0, -540),
		Outpost = Vector3.new(0, 0, -770),
		NestRidge = Vector3.new(250, 0, -520),
	},
	-- Height of the Nest Ridge mesa top; reachable by ramp or jetpack.
	MesaHeight = 26,
	-- Out-of-bounds skyline landmark beyond the north fence.
	DistantFacility = Vector3.new(0, 0, -1140),
}

function WorldLayout.isInside(bounds: Bounds, position: Vector3): boolean
	return position.X >= bounds.MinX
		and position.X <= bounds.MaxX
		and position.Z >= bounds.MinZ
		and position.Z <= bounds.MaxZ
end

return WorldLayout
