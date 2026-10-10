--!strict
--[[
	StudioAudit — measures the world so blockout decisions are based on numbers.

	Studio command bar (Edit mode, or the server/client view during a playtest):
		require(game.ServerStorage.Tooling.StudioAudit).run()

	Offline: `lune run scripts/audit` prints the same instance-level report for the built place.
	In Studio, `run` also asks SceneAnalysisService for live triangle and draw-call counts per
	render pass when that API is available to the calling context.
]]

export type Group = { name: string, instances: number, partsEach: number, totalParts: number }

export type Report = {
	parts: number,
	byShape: { [string]: number },
	byZone: { [string]: number },
	collision: { canCollide: number, canTouch: number, canQuery: number, smallCollidable: number },
	rendering: {
		castShadow: number,
		transparent: number,
		neon: number,
		roundedPrimitives: number,
		materialColorCombos: number,
	},
	effects: { [string]: number },
	streaming: { [string]: number },
	repeated: { Group },
}

-- Collidable parts smaller than this (largest dimension, studs) are flagged for review:
-- small props players can snag on, usually better as CanCollide=false decoration.
local SMALL_COLLIDABLE = 4

local EFFECT_CLASSES =
	{ "PointLight", "SpotLight", "SurfaceLight", "ParticleEmitter", "Beam", "Trail", "SurfaceGui", "TextLabel" }

local StudioAudit = {}

local function shapeOf(part: BasePart): string
	if part:IsA("MeshPart") then
		return "Mesh"
	elseif part:IsA("WedgePart") then
		return "Wedge"
	elseif part:IsA("CornerWedgePart") then
		return "CornerWedge"
	elseif part:IsA("TrussPart") then
		return "Truss"
	elseif part:IsA("Part") then
		return (part :: Part).Shape.Name
	end
	return part.ClassName
end

local function countParts(root: Instance): number
	local count = 0
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") then
			count += 1
		end
	end
	return count
end

function StudioAudit.measure(root: Instance): Report
	local report: Report = {
		parts = 0,
		byShape = {},
		byZone = {},
		collision = { canCollide = 0, canTouch = 0, canQuery = 0, smallCollidable = 0 },
		rendering = { castShadow = 0, transparent = 0, neon = 0, roundedPrimitives = 0, materialColorCombos = 0 },
		effects = {},
		streaming = {},
		repeated = {},
	}
	local combos: { [string]: boolean } = {}
	local groups: { [string]: { instances: number, parts: number } } = {}

	for _, className in EFFECT_CLASSES do
		report.effects[className] = 0
	end

	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") then
			local part = descendant :: BasePart
			report.parts += 1
			local shape = shapeOf(part)
			report.byShape[shape] = (report.byShape[shape] or 0) + 1
			if shape == "Ball" or shape == "Cylinder" then
				report.rendering.roundedPrimitives += 1
			end
			if part.CanCollide then
				report.collision.canCollide += 1
				local size = part.Size
				if math.max(size.X, size.Y, size.Z) < SMALL_COLLIDABLE then
					report.collision.smallCollidable += 1
				end
			end
			if part.CanTouch then
				report.collision.canTouch += 1
			end
			if part.CanQuery then
				report.collision.canQuery += 1
			end
			if part.Transparency < 1 then
				if part.CastShadow then
					report.rendering.castShadow += 1
				end
				if part.Transparency > 0 then
					report.rendering.transparent += 1
				end
				if part.Material == Enum.Material.Neon then
					report.rendering.neon += 1
				end
				combos[`{part.Material.Name}:{part.Color:ToHex()}`] = true
			end
		elseif descendant:IsA("Model") then
			local model = descendant :: Model
			local key = model.Name:gsub("%d+$", "")
			local group = groups[key] or { instances = 0, parts = 0 }
			group.instances += 1
			group.parts += countParts(model)
			groups[key] = group
			local mode = model.ModelStreamingMode.Name
			report.streaming[mode] = (report.streaming[mode] or 0) + 1
		end
		for _, className in EFFECT_CLASSES do
			if descendant.ClassName == className then
				report.effects[className] += 1
			end
		end
	end

	for _, zone in root:GetChildren() do
		report.byZone[zone.Name] = if zone:IsA("BasePart") then 1 else countParts(zone)
	end
	for _ in combos do
		report.rendering.materialColorCombos += 1
	end
	for name, group in groups do
		if group.instances >= 3 then
			table.insert(report.repeated, {
				name = name,
				instances = group.instances,
				partsEach = group.parts / group.instances,
				totalParts = group.parts,
			})
		end
	end
	table.sort(report.repeated, function(a, b)
		return a.totalParts > b.totalParts
	end)
	return report
end

local function sortedLines(map: { [string]: number }): string
	local keys = {}
	for key in map do
		table.insert(keys, key)
	end
	table.sort(keys)
	local parts = {}
	for _, key in keys do
		table.insert(parts, `{key} {map[key]}`)
	end
	return table.concat(parts, ", ")
end

function StudioAudit.format(report: Report): string
	local lines = {
		`Parts: {report.parts}`,
		`  by zone: {sortedLines(report.byZone)}`,
		`  by shape: {sortedLines(report.byShape)}`,
		`Collision: CanCollide {report.collision.canCollide}, CanTouch {report.collision.canTouch}, CanQuery {report.collision.canQuery}, small collidable (<{SMALL_COLLIDABLE} studs) {report.collision.smallCollidable}`,
		`Rendering: CastShadow {report.rendering.castShadow}, transparent {report.rendering.transparent}, Neon {report.rendering.neon}, rounded primitives {report.rendering.roundedPrimitives}, material+color combos {report.rendering.materialColorCombos}`,
		`Effects: {sortedLines(report.effects)}`,
		`Model streaming modes: {sortedLines(report.streaming)}`,
		"Repeated groups (≥3 instances, by total parts):",
	}
	for _, group in report.repeated do
		table.insert(
			lines,
			string.format(
				"  %-16s ×%-3d %5.1f parts each = %d",
				group.name,
				group.instances,
				group.partsEach,
				group.totalParts
			)
		)
	end
	return table.concat(lines, "\n")
end

-- Live render statistics from Studio's Scene Analysis (triangles and draw calls per pass).
-- Returns nil where the service or method is unavailable (offline, or insufficient context).
function StudioAudit.sceneAnalysis(): any
	local ok, result = pcall(function()
		local service = (game :: any):GetService("SceneAnalysisService")
		return service:GetTriangleCompositionAsync()
	end)
	return if ok then result else nil
end

function StudioAudit.run(root: Instance?): Report
	local target = root or workspace:FindFirstChild("World")
	assert(target, "Workspace.World not found; build the place with `lune run scripts/build`")
	local report = StudioAudit.measure(target)
	print(`[RA51 audit] {target:GetFullName()}\n{StudioAudit.format(report)}`)
	local scene = StudioAudit.sceneAnalysis()
	if scene ~= nil then
		print("[RA51 audit] Scene Analysis triangle composition:", scene)
	else
		print("[RA51 audit] Scene Analysis unavailable here; use Window › Performance Summary › Scene Analysis")
	end
	return report
end

return StudioAudit
