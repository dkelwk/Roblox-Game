-- Studio verification tooling: inspection shots and the audit report.

local GameConfig = use("ReplicatedStorage.Shared.Config.GameConfig")
local AssetBinder = use("ServerStorage.Tooling.AssetBinder")
local InspectionShots = use("ServerStorage.Tooling.InspectionShots")
local Palette = use("ReplicatedStorage.Shared.Config.Palette")
local StudioAudit = use("ServerStorage.Tooling.StudioAudit")

local world = game:GetService("Workspace"):FindFirstChild("World")

describe("InspectionShots", function()
	it("covers every view the creative director asked to inspect", function()
		for _, id in { "spawn-view", "gate", "desert-entrance", "lab", "lab-interior", "nest-ridge", "capsule" } do
			expect(InspectionShots.get(id).id).toBe(id)
		end
	end)

	it("uses unique ids and sensible cameras", function()
		local seen = {}
		for _, shot in InspectionShots.List do
			expect(seen[shot.id]).toBe(nil)
			seen[shot.id] = true
			expect((shot.target - shot.eye).Magnitude).toBeAtLeast(5)
			expect(shot.fieldOfView >= 20 and shot.fieldOfView <= 90).toBe(true)
			expect(#shot.check > 0).toBe(true)
		end
	end)

	it("never places the camera inside geometry", function()
		local solid = Geometry.solidParts(world, GameConfig.Tags.Boundary)
		local problems = {}
		for _, shot in InspectionShots.List do
			for _, name in Geometry.blockers(solid, shot.eye, 0) do
				table.insert(problems, `{shot.id} inside {name}`)
			end
		end
		expect(problems).toBeEmpty()
	end)

	it("rejects unknown shot ids", function()
		expect(function()
			InspectionShots.get("nope")
		end).toThrow("Unknown inspection shot")
	end)
end)

describe("StudioAudit", function()
	local report = StudioAudit.measure(world)

	it("counts every part in the world", function()
		local count = 0
		for _, descendant in world:GetDescendants() do
			if descendant:IsA("BasePart") then
				count += 1
			end
		end
		expect(report.parts).toBe(count)
		local byShape = 0
		for _, n in report.byShape do
			byShape += n
		end
		expect(byShape).toBe(count)
	end)

	it("groups repeated models regardless of numbered names", function()
		local groups = {}
		for _, group in report.repeated do
			groups[group.name] = group
		end
		expect(groups.Plot.instances).toBe(6)
		expect(groups.Chamber.instances).toBe(48)
		expect(groups.Chamber.partsEach).toBeNear(6)
	end)

	it("formats a readable report", function()
		local text = StudioAudit.format(report)
		expect(text:find("Parts: " .. report.parts, 1, true) ~= nil).toBe(true)
		expect(text:find("Repeated groups", 1, true) ~= nil).toBe(true)
	end)

	it("returns nothing from Scene Analysis outside Studio instead of erroring", function()
		expect(StudioAudit.sceneAnalysis()).toBe(nil)
	end)
end)

describe("AssetBinder", function()
	local function importedModel(names: { string }): Model
		local model = Instance.new("Model")
		for _, name in names do
			local part = Instance.new("Part")
			part.Name = name
			part.Parent = model
		end
		return model
	end

	it("applies material and palette color from the export naming convention", function()
		local model = importedModel({ "BaseCap__SmoothPlastic__Steel", "Tube__Glass__Glass", "Specimen__Neon__Mint" })
		expect(AssetBinder.bind(model)).toBe(3)
		local cap = model:FindFirstChild("BaseCap__SmoothPlastic__Steel") :: BasePart
		expect(cap.Material).toBe(Enum.Material.SmoothPlastic)
		expect(cap.Color:ToHex()).toBe(Palette.World.Steel:ToHex())
		local tube = model:FindFirstChild("Tube__Glass__Glass") :: BasePart
		expect(tube.Material).toBe(Enum.Material.Glass)
		expect(tube.Transparency > 0).toBe(true)
		local specimen = model:FindFirstChild("Specimen__Neon__Mint") :: BasePart
		expect(specimen.Color:ToHex()).toBe(Palette.Core.Mint:ToHex())
	end)

	it("knows every token the capsule export uses", function()
		for _, token in { "Steel", "Floor", "Glass", "FacilityCream", "Mint", "Cyan" } do
			expect(AssetBinder.color(token) ~= nil).toBe(true)
		end
	end)

	it("ignores parts outside the convention and reports unknown tokens", function()
		expect(AssetBinder.bind(importedModel({ "Handle" }))).toBe(0)
		expect(function()
			AssetBinder.bind(importedModel({ "Body__SmoothPlastic__Chartreuse" }))
		end).toThrow("unknown material or palette token")
	end)
end)
