--!strict
--[[
	InspectionShots — named camera viewpoints for reviewing the world.

	The same shots drive Studio inspection and the Blender preview renders
	(scripts/export-preview → tools/preview/render_world.py), so screenshots from both are
	directly comparable.

	Studio command bar (Edit mode):
		local Shots = require(game.ServerStorage.Tooling.InspectionShots)
		Shots.list()             -- print every shot and what to check there
		Shots.frame("gate")      -- move the editor camera to a shot
		Shots.reset()            -- restore the default field of view
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldLayout = require(ReplicatedStorage.Shared.Config.WorldLayout)
local LabPlot = require(script.Parent.WorldBlockout.LabPlot)

export type Shot = {
	id: string,
	title: string,
	-- What to look for when reviewing this shot.
	check: string,
	eye: Vector3,
	target: Vector3,
	-- Vertical field of view in degrees (Roblox's default camera uses 70).
	fieldOfView: number,
	-- Blender previews render this shot orthographically at this size when set.
	orthographicSize: number?,
}

local DEFAULT_FIELD_OF_VIEW = 70

-- Points in Lab 01's local space (origin at the plot center, -Z toward the road).
local function labPoint(x: number, y: number, z: number): Vector3
	return (WorldLayout.Plots[1] * CFrame.new(x, y, z)).Position
end

-- Approximates Roblox's default third-person camera: ~12 studs behind and above the head.
local spawn = LabPlot.spawnCFrame(WorldLayout.Plots[1])
local desert = WorldLayout.Desert
local sites = desert.Sites

local InspectionShots = {}

InspectionShots.List = {
	{
		id = "spawn-view",
		title = "Lab district from Lab 01's spawn point",
		check = "Player instantly reads where they are and sees the gate as the objective; scale of labs vs character",
		eye = (spawn * CFrame.new(0, 5, 12)).Position,
		target = (spawn * CFrame.new(0, 3, -40)).Position,
		fieldOfView = DEFAULT_FIELD_OF_VIEW,
	},
	{
		id = "gate",
		title = "Extraction Gate from the road",
		check = "Gate silhouette, sign legibility, energy curtain transparency, guide lights",
		eye = Vector3.new(0, 8, -100),
		target = Vector3.new(0, 14, -200),
		fieldOfView = 60,
	},
	{
		id = "desert-entrance",
		title = "Desert entrance just past the gate",
		check = "Trail, junction signpost and the three landmark silhouettes are readable; distant skyline frames the view",
		eye = Vector3.new(0, 9, -162),
		target = desert.Junction + Vector3.new(0, 2, 0),
		fieldOfView = 40,
	},
	{
		id = "lab",
		title = "A complete player laboratory (Lab 01)",
		check = "Facility silhouette, accent color, entrance scale, windows/skylight show the interior, owner sign",
		eye = labPoint(-30, 24, -56),
		target = labPoint(0, 6, 4),
		fieldOfView = 50,
	},
	{
		id = "lab-interior",
		title = "Scanner station and containment chambers",
		check = "Scanner reads as the centerpiece; chambers visible and spaced; walking room around the scanner",
		eye = labPoint(0, 12, -16),
		target = labPoint(0, 4, 18),
		fieldOfView = 60,
	},
	{
		id = "capsule",
		title = "Scanner seat close-up (place the imported capsule here)",
		check = "Imported capsule scale vs scanner seat and character; materials and colors after import",
		eye = labPoint(0, 8.5, -7),
		target = labPoint(0, 6, 3),
		fieldOfView = 40,
	},
	{
		id = "nest-ridge",
		title = "Nest Ridge mesa and its ramp",
		check = "Ramp rises toward the mesa top (not a cliff); nests readable; jetpack-worthy height",
		eye = sites.NestRidge + Vector3.new(-150, 45, 60),
		target = sites.NestRidge + Vector3.new(-35, 12, -18),
		fieldOfView = 45,
	},
	{
		id = "crash-crater",
		title = "Crash Crater and saucer",
		check = "Saucer reads as crashed; crystals glow without overpowering; rim opening faces the trail",
		eye = sites.CrashCrater + Vector3.new(80, 60, 70),
		target = sites.CrashCrater + Vector3.new(2, 4, -5),
		fieldOfView = 45,
	},
	{
		id = "outpost",
		title = "Research Outpost",
		check = "Damage reads clearly; comms tower is climbable; checkpoint gap lines up with the trail",
		eye = sites.Outpost + Vector3.new(60, 50, 95),
		target = sites.Outpost + Vector3.new(0, 8, -5),
		fieldOfView = 45,
	},
	{
		id = "overview",
		title = "Top-down overview",
		check = "Overall layout, paths, landmark spacing",
		eye = Vector3.new(0, 1400, -420),
		target = Vector3.new(0, 0, -421),
		fieldOfView = DEFAULT_FIELD_OF_VIEW,
		orthographicSize = 1500,
	},
} :: { Shot }

function InspectionShots.get(id: string): Shot
	for _, shot in InspectionShots.List do
		if shot.id == id then
			return shot
		end
	end
	error(`Unknown inspection shot '{id}'`)
end

function InspectionShots.frame(id: string)
	local shot = InspectionShots.get(id)
	local camera = workspace.CurrentCamera
	camera.FieldOfView = shot.fieldOfView
	camera.CFrame = CFrame.lookAt(shot.eye, shot.target)
	camera.Focus = CFrame.new(shot.target)
	print(`[RA51] {shot.title} — check: {shot.check}`)
end

function InspectionShots.reset()
	workspace.CurrentCamera.FieldOfView = DEFAULT_FIELD_OF_VIEW
end

function InspectionShots.list()
	for index, shot in InspectionShots.List do
		print(`{index}. {shot.id}: {shot.title}\n    check: {shot.check}`)
	end
end

return InspectionShots
