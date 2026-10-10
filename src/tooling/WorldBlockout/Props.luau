--!strict
--[[
	Props — reusable blockout props sharing one shape language: chunky, rounded where the
	primitive set allows, warm-colored, with glow used only as an accent.

	Every builder takes a ground CFrame `at` (Y = ground height). A prop that has a readable
	front faces along `at.LookVector`.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local Kit = require(script.Parent.Kit)

local World = Palette.World
local Sandstone = Enum.Material.Sandstone
local Glass = Enum.Material.Glass
local Neon = Enum.Material.Neon

local Props = {}

-- Stylized desert rock: a tapered stack of strata (wide base narrowing upward) under an
-- overhanging cap, with boulders at its foot. Reads as a designed hoodoo/mesa silhouette.
function Props.rockCluster(parent: Instance, at: CFrame, scale: number, rng: Kit.Rng): Model
	local model = Kit.model(parent, "RockCluster")
	local tiers = rng:int(2, 4)
	local baseWidth = rng:range(9, 13) * scale
	local baseDepth = baseWidth * rng:range(0.7, 0.95)
	local spin = rng:range(0, 90)
	local y = -0.6 * scale
	local shrink = 1
	for tier = 1, tiers do
		shrink = 1 - (tier - 1) * 0.2
		local height = rng:range(3.5, 6) * scale
		Kit.block(
			model,
			"Rock",
			Vector3.new(baseWidth * shrink, height, baseDepth * shrink),
			at
				* CFrame.new(rng:range(-0.5, 0.5) * scale, y + height / 2, rng:range(-0.5, 0.5) * scale)
				* Kit.yaw(spin + rng:range(-8, 8)),
			if tier % 2 == 1 then World.Rock else World.RockLight,
			Sandstone
		)
		y += height - 0.2 * scale
	end
	Kit.block(
		model,
		"RockCap",
		Vector3.new(baseWidth * shrink + 1.6 * scale, 1.2 * scale, baseDepth * shrink + 1.6 * scale),
		at * CFrame.new(0, y + 0.5 * scale, 0) * Kit.yaw(spin + rng:range(-6, 6)),
		World.RockLight,
		Sandstone
	)
	for _ = 1, rng:int(1, 3) do
		local size = rng:range(2.5, 4.5) * scale
		local foot = at * Kit.yaw(rng:range(0, 360)) * CFrame.new(0, size * 0.35, -(baseWidth * 0.5 + size * 0.35))
		Kit.block(
			model,
			"Boulder",
			Vector3.new(size, size * 0.8, size * 0.9),
			foot * CFrame.Angles(math.rad(rng:range(-15, 15)), math.rad(rng:range(0, 90)), math.rad(rng:range(-15, 15))),
			World.RockDark,
			Sandstone
		)
	end
	return model
end

function Props.crystalCluster(
	parent: Instance,
	at: CFrame,
	scale: number,
	color: Color3,
	withLight: boolean,
	rng: Kit.Rng
): Model
	local model = Kit.model(parent, "CrystalCluster")
	local count = rng:int(4, 6)
	for index = 1, count do
		local height = rng:range(5, 11) * scale * (if index == 1 then 1.3 else 1)
		local width = rng:range(1.2, 2.2) * scale
		local angle = (index / count) * 360 + rng:range(-20, 20)
		local lean = if index == 1 then 0 else rng:range(14, 30)
		local base = at * Kit.yaw(angle) * CFrame.new(0, 0, if index == 1 then 0 else -1.2 * scale)
		Kit.part(model, {
			name = "Shard",
			size = Vector3.new(width, height, width),
			cframe = base * CFrame.Angles(math.rad(-lean), 0, 0) * CFrame.new(0, height / 2 - 0.5, 0) * Kit.yaw(45),
			color = color,
			material = Glass,
			transparency = 0.15,
		})
	end
	local core = Kit.ball(model, "Core", 1.6 * scale, (at * CFrame.new(0, 1, 0)).Position, color, Neon)
	core.CanCollide = false
	if withLight then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 16 * scale
		light.Brightness = 1.2
		light.Shadows = false
		light.Parent = core
	end
	return model
end

function Props.crateStack(parent: Instance, at: CFrame, rng: Kit.Rng): Model
	local model = Kit.model(parent, "CrateStack")
	local count = rng:int(1, 3)
	local layout = {
		Vector3.new(0, 0, 0),
		Vector3.new(4.6, 0, 0.6),
		Vector3.new(2.2, 4.2, 0.2),
	}
	for index = 1, count do
		local cframe = at * CFrame.new(layout[index] + Vector3.new(0, 2.1, 0)) * Kit.yaw(rng:range(-12, 12))
		Kit.block(model, "Crate", Vector3.new(4.2, 4.2, 4.2), cframe, World.FacilityCream)
		Kit.block(model, "CrateBand", Vector3.new(4.35, 0.9, 4.35), cframe, World.AlertOrange)
	end
	return model
end

function Props.barrier(parent: Instance, at: CFrame): Model
	local model = Kit.model(parent, "Barrier")
	Kit.block(model, "Body", Vector3.new(8, 2.6, 2.2), at * CFrame.new(0, 1.3, 0), World.FacilityCream)
	Kit.block(model, "Stripe", Vector3.new(8.05, 0.7, 2.25), at * CFrame.new(0, 1.6, 0), World.AlertOrange)
	Kit.block(model, "Foot", Vector3.new(8, 0.6, 3), at * CFrame.new(0, 0.3, 0), World.Steel)
	return model
end

-- Security fence from a to b (ground positions), with posts roughly every `spacing` studs.
function Props.fence(parent: Instance, a: Vector3, b: Vector3, spacing: number?): Model
	local model = Kit.model(parent, "SecurityFence")
	local delta = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local length = delta.Magnitude
	local segments = math.max(1, math.round(length / (spacing or 12)))
	local direction = delta.Unit
	local frame = CFrame.lookAt(a, a + direction)
	for index = 0, segments do
		local post = frame * CFrame.new(0, 0, -length * index / segments)
		Kit.column(model, "Post", 1.1, 9, post, World.Steel)
		Kit.column(model, "PostCap", 1.4, 0.6, post * CFrame.new(0, 9, 0), World.AlertOrange)
	end
	local middle = frame * CFrame.new(0, 0, -length / 2)
	Kit.part(model, {
		name = "Mesh",
		size = Vector3.new(0.25, 6.5, length),
		cframe = middle * CFrame.new(0, 4.6, 0),
		color = World.Steel,
		transparency = 0.55,
	})
	Kit.block(model, "RailTop", Vector3.new(0.5, 0.5, length), middle * CFrame.new(0, 8, 0), World.SteelDark)
	Kit.block(model, "RailLow", Vector3.new(0.5, 0.5, length), middle * CFrame.new(0, 1.2, 0), World.SteelDark)
	return model
end

function Props.lightPost(parent: Instance, at: CFrame): Model
	local model = Kit.model(parent, "LightPost")
	Kit.column(model, "Base", 1.8, 0.8, at, World.SteelDark)
	Kit.column(model, "Pole", 0.8, 8, at, World.Steel)
	local lamp = Kit.ball(model, "Lamp", 1.8, (at * CFrame.new(0, 8.6, 0)).Position, World.FacilityCream, Neon)
	lamp.CastShadow = false
	return model
end

function Props.plant(parent: Instance, at: CFrame, scale: number, rng: Kit.Rng): Model
	local model = Kit.model(parent, "DesertPlant")
	if rng:next() < 0.5 then
		-- Round shrub
		local count = rng:int(2, 3)
		for _ = 1, count do
			local diameter = rng:range(2.4, 4) * scale
			local offset = Vector3.new(rng:range(-1.4, 1.4), diameter * 0.32, rng:range(-1.4, 1.4)) * scale
			Kit.ball(model, "Tuft", diameter, (at * CFrame.new(offset)).Position, World.Sage)
		end
	else
		-- Stylized desert tree: trunk, two raised arms, round tufts
		local height = rng:range(6, 9) * scale
		Kit.column(model, "Trunk", 1.2 * scale, height, at, World.SageDark)
		Kit.ball(model, "Tuft", 3.4 * scale, (at * CFrame.new(0, height + 0.8 * scale, 0)).Position, World.Sage)
		for _, side in { -1, 1 } do
			local armBase = at
				* CFrame.new(0, height * 0.55, 0)
				* Kit.yaw(rng:range(0, 360))
				* CFrame.Angles(0, 0, math.rad(32 * side))
			local armLength = 3.6 * scale
			Kit.column(model, "Arm", 0.9 * scale, armLength, armBase, World.SageDark)
			Kit.ball(
				model,
				"Tuft",
				2.6 * scale,
				(armBase * CFrame.new(0, armLength + 0.6 * scale, 0)).Position,
				World.Sage
			)
		end
	end
	return model
end

function Props.nest(parent: Instance, at: CFrame, scale: number, rng: Kit.Rng): Model
	local model = Kit.model(parent, "AlienNest")
	local diameter = 10 * scale
	Kit.ball(model, "Shell", diameter, (at * CFrame.new(0, -diameter * 0.22, 0)).Position, World.NestShell)
	Kit.column(model, "Rim", diameter * 0.82, 0.5, at * CFrame.new(0, diameter * 0.26, 0), World.NestViolet)
	for index = 1, 3 do
		local angle = index * 120 + rng:range(-15, 15)
		local position = (at * Kit.yaw(angle) * CFrame.new(0, diameter * 0.32, -diameter * 0.16)).Position
		local egg = Kit.ball(model, "Egg", 1.7 * scale, position, World.AlienMint, Neon)
		egg.CanCollide = false
	end
	return model
end

-- Free-standing sign whose readable face looks along `at.LookVector`. Returns the model and
-- the front-facing label so callers can rename or update it.
function Props.sign(parent: Instance, at: CFrame, text: string, width: number): (Model, TextLabel)
	local model = Kit.model(parent, "Sign")
	for _, side in { -1, 1 } do
		Kit.column(model, "Post", 0.8, 7, at * CFrame.new(side * (width / 2 - 1), 0, 0.3), World.Steel)
	end
	local board = Kit.block(model, "Board", Vector3.new(width, 2.6, 0.5), at * CFrame.new(0, 5.6, 0), World.HazardNavy)
	local front = Kit.label(board, text, Enum.NormalId.Front, World.FacilityCream)
	Kit.label(board, text, Enum.NormalId.Back, World.FacilityCream)
	Kit.block(model, "Trim", Vector3.new(width, 0.35, 0.55), at * CFrame.new(0, 7.05, 0), World.EnergyCyan)
	return model, front
end

-- Knee-high trail marker with a small reflector, used to lead players along paths.
function Props.trailMarker(parent: Instance, at: CFrame): Model
	local model = Kit.model(parent, "TrailMarker")
	Kit.column(model, "Post", 0.9, 3.4, at, World.FacilityCream)
	local reflector =
		Kit.block(model, "Reflector", Vector3.new(0.95, 0.7, 0.95), at * CFrame.new(0, 3, 0), World.EnergyCyan, Neon)
	reflector.CastShadow = false
	return model
end

function Props.console(parent: Instance, at: CFrame): Model
	local model = Kit.model(parent, "Console")
	Kit.block(model, "Body", Vector3.new(3.4, 3.4, 2.2), at * CFrame.new(0, 1.7, 0), World.Floor)
	Kit.part(model, {
		name = "Screen",
		shape = "Wedge",
		size = Vector3.new(3.4, 1.2, 2.2),
		cframe = at * CFrame.new(0, 4, 0),
		color = World.EnergyCyan,
		material = Glass,
		transparency = 0.2,
	})
	return model
end

return Props
