-- The generated world blockout as it ships in the built place (Workspace.World).

local GameConfig = use("ReplicatedStorage.Shared.Config.GameConfig")
local Palette = use("ReplicatedStorage.Shared.Config.Palette")
local WorldLayout = use("ReplicatedStorage.Shared.Config.WorldLayout")

local world = game:GetService("Workspace"):FindFirstChild("World")
assert(world, "Workspace.World is missing — run `lune run scripts/build` first")

local function descendantsOfClass(root: Instance, className: string): { Instance }
	local found = {}
	for _, descendant in root:GetDescendants() do
		if descendant:IsA(className) then
			table.insert(found, descendant)
		end
	end
	return found
end

local function tagged(tag: string): { Instance }
	local found = {}
	for _, descendant in world:GetDescendants() do
		if descendant:HasTag(tag) then
			table.insert(found, descendant)
		end
	end
	return found
end

local allParts = descendantsOfClass(world, "BasePart") :: { BasePart }

-- Solid geometry a character or capsule could collide with (boundaries excluded).
local solidParts = Geometry.solidParts(world, GameConfig.Tags.Boundary)

local function blockers(point: Vector3, margin: number): { string }
	return Geometry.blockers(solidParts, point, margin)
end

-- Samples a straight walking route at torso height and reports anything in the way.
local function routeBlockers(from: Vector3, to: Vector3, height: number): { string }
	local problems = {}
	local steps = math.ceil((to - from).Magnitude / 2)
	for step = 0, steps do
		local point = from:Lerp(to, step / steps) + Vector3.new(0, height, 0)
		for _, name in blockers(point, 0) do
			table.insert(problems, `{name} at {point}`)
		end
	end
	return problems
end

local function fingerprint(root: Instance): string
	local entries = {}
	for _, part in descendantsOfClass(root, "BasePart") do
		local p = (part :: BasePart).CFrame.Position
		table.insert(entries, string.format("%s %.2f %.2f %.2f", part.Name, p.X, p.Y, p.Z))
	end
	table.sort(entries)
	return table.concat(entries, "\n")
end

describe("World blockout › lab district", function()
	local plots = tagged(GameConfig.Tags.Plot)

	it("has one tagged plot per WorldLayout entry, indexed 1..N", function()
		expect(#plots).toBe(#WorldLayout.Plots)
		local seen = {}
		for _, plot in plots do
			local index = plot:GetAttribute(GameConfig.Attributes.PlotIndex)
			expect(seen[index]).toBe(nil)
			seen[index] = true
			expect(WorldLayout.Plots[index] ~= nil).toBe(true)
		end
	end)

	it("builds each plot on its layout origin with every gameplay anchor", function()
		for _, plot in plots do
			local index = plot:GetAttribute(GameConfig.Attributes.PlotIndex)
			local origin = WorldLayout.Plots[index]
			local pad = plot:FindFirstChild("Pad") :: BasePart
			expect(pad.CFrame.Position.X).toBeNear(origin.Position.X)
			expect(pad.CFrame.Position.Z).toBeNear(origin.Position.Z)
			expect((plot :: Model).ModelStreamingMode).toBe(Enum.ModelStreamingMode.Atomic)
			local markers = plot:FindFirstChild("Markers")
			expect(markers:FindFirstChild("ScannerAnchor") ~= nil).toBe(true)
			expect(markers:FindFirstChild("SpawnPoint") ~= nil).toBe(true)
			local label = plot:FindFirstChild("OwnerSign"):FindFirstChild("OwnerLabel", true)
			expect(label ~= nil and label:IsA("TextLabel")).toBe(true)
		end
	end)

	it("gives every lab enough chambers for the max Containment Wing level", function()
		for _, plot in plots do
			local chambers = plot:FindFirstChild("Chambers"):GetChildren()
			expect(#chambers).toBe(WorldLayout.Plot.ChamberSlotCount)
			local slots = {}
			for _, chamber in chambers do
				slots[chamber:GetAttribute(GameConfig.Attributes.SlotIndex)] = true
				expect(chamber:FindFirstChild("AlienAnchor") ~= nil).toBe(true)
			end
			for slot = 1, WorldLayout.Plot.ChamberSlotCount do
				expect(slots[slot]).toBe(true)
			end
		end
	end)

	it("spawns players in front of their lab facing the gate, with clear walks to the road and the door", function()
		local gate = WorldLayout.District.ExtractionGate.Position
		for _, plot in plots do
			local origin = WorldLayout.Plots[plot:GetAttribute(GameConfig.Attributes.PlotIndex)]
			local spawnPoint = plot:FindFirstChild("Markers"):FindFirstChild("SpawnPoint") :: BasePart
			local position = spawnPoint.CFrame.Position
			local towardGate = (Vector3.new(gate.X, position.Y, gate.Z) - position).Unit
			expect(spawnPoint.CFrame.LookVector:Dot(towardGate)).toBeNear(1)
			local ground = position * Vector3.new(1, 0, 1)
			local roadEdge = Vector3.new(math.sign(ground.X) * WorldLayout.District.RoadWidth / 2, 0, ground.Z)
			expect(routeBlockers(ground, roadEdge, 3)).toBeEmpty()
			local doorway = (origin * CFrame.new(0, 0, -8)).Position
			expect(routeBlockers(ground, doorway, 3)).toBeEmpty()
			-- The default camera sits ~12 studs behind the character; keep that space open.
			local cameraSpot = (spawnPoint.CFrame * CFrame.new(0, 3, 12)).Position
			expect(Geometry.blockers(solidParts, cameraSpot, 0)).toBeEmpty()
		end
	end)

	it("leaves room for a hovering capsule at every scanner anchor", function()
		-- Specimen Capsule v0.2 is ~1.9 x 3.2 studs with a centered origin.
		for _, plot in plots do
			local anchor = plot:FindFirstChild("Markers"):FindFirstChild("ScannerAnchor") :: BasePart
			for _, offset in
				{
					Vector3.new(0, -1.6, 0),
					Vector3.new(0, 1.6, 0),
					Vector3.new(0.95, 0, 0),
					Vector3.new(-0.95, 0, 0),
					Vector3.new(0, 0, 0.95),
					Vector3.new(0, 0, -0.95),
				}
			do
				expect(blockers(anchor.CFrame.Position + offset, 0)).toBeEmpty()
			end
		end
	end)

	it("keeps the main route from the plaza through the Extraction Gate clear", function()
		local plaza = WorldLayout.District.DefaultSpawn.Position
		local beyondGate = Vector3.new(0, 0, WorldLayout.District.RoadNorthZ - 20)
		expect(routeBlockers(plaza, beyondGate, 3)).toBeEmpty()
	end)

	it("tags exactly one Extraction Gate and one Upgrade Station", function()
		expect(#tagged(GameConfig.Tags.ExtractionGate)).toBe(1)
		expect(#tagged(GameConfig.Tags.UpgradeStation)).toBe(1)
	end)

	it("has a single neutral fallback spawn inside the district", function()
		local spawns = descendantsOfClass(world, "SpawnLocation")
		expect(#spawns).toBe(1)
		local spawn = spawns[1] :: SpawnLocation
		expect(spawn.Neutral).toBe(true)
		expect(WorldLayout.isInside(WorldLayout.District.Bounds, spawn.CFrame.Position)).toBe(true)
	end)
end)

describe("World blockout › desert extraction region", function()
	local spawns = tagged(GameConfig.Tags.SpecimenSpawn) :: { BasePart }
	local validTiers = {}
	for _, tier in GameConfig.Specimen.SpawnTiers do
		validTiers[tier] = true
	end

	it("places enough specimen spawns, all inside the desert with valid metadata", function()
		expect(#spawns).toBeAtLeast(24)
		for _, spawnPoint in spawns do
			expect(spawnPoint:GetAttribute(GameConfig.Attributes.RegionId)).toBe("desert")
			expect(validTiers[spawnPoint:GetAttribute(GameConfig.Attributes.SpawnTier)]).toBe(true)
			expect(WorldLayout.isInside(WorldLayout.Desert.Bounds, spawnPoint.CFrame.Position)).toBe(true)
		end
	end)

	it("puts at least six starter spawns within a short walk of the gate", function()
		local gateExit = Vector3.new(0, 0, WorldLayout.District.RoadNorthZ)
		local starters = 0
		for _, spawnPoint in spawns do
			if spawnPoint:GetAttribute(GameConfig.Attributes.SpawnTier) == "Starter" then
				starters += 1
				local flat = spawnPoint.CFrame.Position * Vector3.new(1, 0, 1)
				expect((flat - gateExit).Magnitude).toBeAtMost(220)
			end
		end
		expect(starters).toBeAtLeast(6)
	end)

	it("gives every site at least three spawns and at least one secret", function()
		local perSite, secrets = {}, 0
		for _, spawnPoint in spawns do
			local site = spawnPoint:GetAttribute(GameConfig.Attributes.SiteId)
			perSite[site] = (perSite[site] or 0) + 1
			if spawnPoint:GetAttribute(GameConfig.Attributes.SpawnTier) == "Secret" then
				secrets += 1
			end
		end
		for _, site in { "Starter", "CrashCrater", "Outpost", "NestRidge" } do
			expect(perSite[site] or 0).toBeAtLeast(3)
		end
		expect(secrets).toBeAtLeast(1)
	end)

	it("never buries a spawn inside geometry", function()
		local problems = {}
		for _, spawnPoint in spawns do
			local center = spawnPoint.CFrame.Position
			for _, probe in { center, center + Vector3.new(0, 1, 0) } do
				for _, name in blockers(probe, 0.1) do
					table.insert(problems, `{spawnPoint.Name} inside {name}`)
				end
			end
		end
		expect(problems).toBeEmpty()
	end)

	it("rests every spawn on solid ground", function()
		local floating = {}
		for _, spawnPoint in spawns do
			local below = spawnPoint.CFrame.Position - Vector3.new(0, 2, 0)
			if #blockers(below, 0) == 0 then
				table.insert(floating, spawnPoint.Name)
			end
		end
		expect(floating).toBeEmpty()
	end)

	it("keeps spawns at least 6 studs apart", function()
		local crowded = {}
		for i = 1, #spawns do
			for j = i + 1, #spawns do
				if (spawns[i].CFrame.Position - spawns[j].CFrame.Position).Magnitude < 6 then
					table.insert(crowded, `{spawns[i].Name} / {spawns[j].Name}`)
				end
			end
		end
		expect(crowded).toBeEmpty()
	end)

	it("keeps the trail from the gate to the junction and on to each site walkable", function()
		-- Routes meet the junction pad's edge: its signpost pole stands at the very center
		-- and players walk around it. They also stop short of each site's centerpiece.
		local desert = WorldLayout.Desert
		local gateExit = Vector3.new(0, 0, WorldLayout.District.RoadNorthZ)
		local function padEdge(toward: Vector3): Vector3
			return desert.Junction + (toward - desert.Junction).Unit * 12
		end
		expect(routeBlockers(gateExit, padEdge(gateExit), 3)).toBeEmpty()
		for siteName, center in desert.Sites do
			local approach = desert.Junction:Lerp(center, 1 - 70 / (center - desert.Junction).Magnitude)
			local problems = routeBlockers(padEdge(center), approach, 3)
			if #problems > 0 then
				error(`route to {siteName} blocked:\n    {table.concat(problems, "\n    ")}`)
			end
		end
	end)
end)

describe("World blockout › art direction and budgets", function()
	local allowed = {}
	for _, group in { Palette.Core, Palette.World, Palette.UI } do
		for _, color in group do
			allowed[color:ToHex()] = true
		end
	end

	it("colors every part and sign from the palette (no default grey)", function()
		local offenders = {}
		for _, part in allParts do
			if part.Transparency < 1 and not allowed[part.Color:ToHex()] then
				table.insert(offenders, `{part:GetFullName()} #{part.Color:ToHex()}`)
			end
		end
		for _, label in descendantsOfClass(world, "TextLabel") do
			if not allowed[(label :: TextLabel).TextColor3:ToHex()] then
				table.insert(offenders, label:GetFullName())
			end
		end
		expect(offenders).toBeEmpty()
	end)

	it("never uses the default Plastic material", function()
		local offenders = {}
		for _, part in allParts do
			if part.Material == Enum.Material.Plastic then
				table.insert(offenders, part:GetFullName())
			end
		end
		expect(offenders).toBeEmpty()
	end)

	it("anchors everything and respects Roblox part size limits", function()
		local offenders = {}
		for _, part in allParts do
			local size = part.Size
			local largest = math.max(size.X, size.Y, size.Z)
			local smallest = math.min(size.X, size.Y, size.Z)
			if not part.Anchored or largest > 2048 or smallest < 0.05 then
				table.insert(offenders, part:GetFullName())
			end
			if part:IsA("Part") and part.Shape == Enum.PartType.Ball and (size.X ~= size.Y or size.Y ~= size.Z) then
				table.insert(offenders, `{part:GetFullName()} (non-uniform ball)`)
			end
		end
		expect(offenders).toBeEmpty()
	end)

	it("stays inside the blockout performance budget", function()
		expect(#allParts).toBeAtMost(3000)
		expect(#descendantsOfClass(world, "PointLight")).toBeAtMost(16)
		expect(#descendantsOfClass(world, "ParticleEmitter")).toBeAtMost(8)
		expect(#descendantsOfClass(world, "SurfaceGui")).toBeAtMost(120)
		local neon = 0
		for _, part in allParts do
			if part.Material == Enum.Material.Neon then
				neon += 1
			end
		end
		-- Glow is an accent, not the look.
		expect(neon / #allParts).toBeAtMost(0.12)
	end)

	it("never names GUI objects Name or Size (they collide with built-in properties)", function()
		local offenders = {}
		for _, gui in descendantsOfClass(world, "GuiBase") do
			if gui.Name == "Name" or gui.Name == "Size" then
				table.insert(offenders, gui:GetFullName())
			end
		end
		expect(offenders).toBeEmpty()
	end)

	it("encloses the play area with invisible, camera-transparent boundaries", function()
		local walls = tagged(GameConfig.Tags.Boundary) :: { BasePart }
		expect(#walls).toBe(8)
		for _, wall in walls do
			expect(wall.CanCollide).toBe(true)
			expect(wall.CanQuery).toBe(false)
			expect(wall.Transparency).toBe(1)
		end
	end)

	it("keeps landmark models persistently streamed", function()
		local district = world:FindFirstChild("LabDistrict")
		for _, name in { "MainFacility", "ExtractionGate" } do
			expect((district:FindFirstChild(name) :: Model).ModelStreamingMode).toBe(Enum.ModelStreamingMode.Persistent)
		end
	end)
end)

describe("World blockout › orientation", function()
	local district = world:FindFirstChild("LabDistrict")
	local desert = world:FindFirstChild("DesertRegion")

	local function labelOn(part: Instance, face: Enum.NormalId): string?
		for _, gui in part:GetChildren() do
			if gui:IsA("SurfaceGui") and gui.Face == face then
				return (gui:FindFirstChildWhichIsA("TextLabel") :: TextLabel).Text
			end
		end
		return nil
	end

	it("labels the gate EXTRACTION ZONE on the district side and LAB DISTRICT on the desert side", function()
		local beam = district:FindFirstChild("ExtractionGate"):FindFirstChild("Beam") :: BasePart
		-- Front faces along LookVector, Back faces against it.
		expect(beam.CFrame.LookVector:Dot(Vector3.new(0, 0, -1))).toBeNear(1)
		expect(labelOn(beam, Enum.NormalId.Back)).toBe("EXTRACTION ZONE")
		expect(labelOn(beam, Enum.NormalId.Front)).toBe("LAB DISTRICT")
	end)

	it("turns the upgrade station's screen toward the road", function()
		local screen = district:FindFirstChild("UpgradeStation"):FindFirstChild("Hologram") :: BasePart
		expect(screen.CFrame.LookVector.Z < -0.9).toBe(true)
		local interact = district:FindFirstChild("UpgradeStation"):FindFirstChild("InteractPoint") :: BasePart
		expect(interact.CFrame.Position.Z < screen.CFrame.Position.Z).toBe(true)
	end)

	it("aligns every trail strip with its segment", function()
		local DesertRegion = use("ServerStorage.Tooling.WorldBlockout.DesertRegion")
		local strips = {}
		for _, part in desert:FindFirstChild("Trails"):GetChildren() do
			if part.Name == "Trail" then
				table.insert(strips, part)
			end
		end
		expect(#strips).toBe(#DesertRegion.Trails)
		for _, segment in DesertRegion.Trails do
			local a, b = segment[1], segment[2]
			local middle = (a + b) / 2
			local closest, best = nil, math.huge
			for _, strip in strips do
				local distance = (strip.CFrame.Position - middle).Magnitude
				if distance < best then
					closest, best = strip, distance
				end
			end
			expect(best).toBeAtMost(0.5)
			expect(math.abs(closest.CFrame.LookVector:Dot((b - a).Unit))).toBeNear(1)
		end
	end)

	it("turns every chamber ID plate toward the lab interior", function()
		for _, plot in district:FindFirstChild("Plots"):GetChildren() do
			local origin = WorldLayout.Plots[plot:GetAttribute(GameConfig.Attributes.PlotIndex)]
			local center = (origin * CFrame.new(0, 0, 6)).Position
			for _, chamber in plot:FindFirstChild("Chambers"):GetChildren() do
				local plate = chamber:FindFirstChild("IdPlate") :: BasePart
				local toCenter = (center - plate.CFrame.Position) * Vector3.new(1, 0, 1)
				expect(plate.CFrame.LookVector:Dot(toCenter.Unit) > 0.9).toBe(true)
			end
		end
	end)

	it("keeps the outpost's fences on the outpost", function()
		local site = WorldLayout.Desert.Sites.Outpost
		for _, fence in desert:FindFirstChild("ResearchOutpost"):GetChildren() do
			if fence.Name == "SecurityFence" then
				for _, post in fence:GetChildren() do
					local offset = (post :: BasePart).CFrame.Position - site
					expect(math.abs(offset.X) <= 64 and math.abs(offset.Z) <= 50).toBe(true)
				end
			end
		end
	end)

	it("faces the restricted-airspace signs toward the players (south)", function()
		for _, sign in desert:FindFirstChild("DistantFacility"):GetChildren() do
			if sign.Name == "Sign" then
				local board = sign:FindFirstChild("Board") :: BasePart
				expect(board.CFrame.LookVector.Z > 0.9).toBe(true)
			end
		end
	end)
end)

describe("World blockout › generator", function()
	it("is deterministic and matches the world saved in the place", function()
		local WorldBlockout = use("ServerStorage.Tooling.WorldBlockout")
		local first = fingerprint(WorldBlockout.build())
		expect(fingerprint(WorldBlockout.build()) == first).toBe(true)
		expect(fingerprint(world) == first).toBe(true)
	end)
end)
