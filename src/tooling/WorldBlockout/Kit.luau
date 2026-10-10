--!strict
--[[
	Kit — geometry helpers for the world blockout.

	Every part is anchored, SmoothPlastic unless stated, colored from the Palette, and named.
	A deterministic PRNG keeps scatter placement identical between Lune builds and Studio.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage.Shared.Config.Palette)

local Kit = {}

export type Shape = "Block" | "Cylinder" | "Ball" | "Wedge" | "CornerWedge"

export type PartSpec = {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	shape: Shape?,
	material: Enum.Material?,
	transparency: number?,
	-- Defaults to true. Non-colliding parts also skip touch and query for performance.
	collide: boolean?,
	castShadow: boolean?,
}

local UP_FROM_X = CFrame.Angles(0, 0, math.rad(90))
local PART_TYPES = {
	Block = Enum.PartType.Block,
	Cylinder = Enum.PartType.Cylinder,
	Ball = Enum.PartType.Ball,
}

function Kit.part(parent: Instance, spec: PartSpec): BasePart
	local part: BasePart
	if spec.shape == "Wedge" then
		part = Instance.new("WedgePart")
	elseif spec.shape == "CornerWedge" then
		part = Instance.new("CornerWedgePart")
	else
		local basic = Instance.new("Part")
		basic.Shape = PART_TYPES[spec.shape or "Block"]
		part = basic
	end
	part.Name = spec.name
	part.Anchored = true
	part.Size = spec.size
	part.CFrame = spec.cframe
	part.Color = spec.color
	part.Material = spec.material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Transparency = spec.transparency or 0
	if spec.collide == false then
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
	end
	if spec.castShadow == false then
		part.CastShadow = false
	end
	part.Parent = parent
	return part
end

function Kit.block(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): BasePart
	return Kit.part(parent, { name = name, size = size, cframe = cframe, color = color, material = material })
end

-- Upright cylinder whose base center sits at `base` (the cylinder's axis points along +Y).
function Kit.column(
	parent: Instance,
	name: string,
	diameter: number,
	height: number,
	base: CFrame,
	color: Color3,
	material: Enum.Material?
): BasePart
	return Kit.part(parent, {
		name = name,
		shape = "Cylinder",
		size = Vector3.new(height, diameter, diameter),
		cframe = base * CFrame.new(0, height / 2, 0) * UP_FROM_X,
		color = color,
		material = material,
	})
end

function Kit.ball(
	parent: Instance,
	name: string,
	diameter: number,
	position: Vector3,
	color: Color3,
	material: Enum.Material?
): BasePart
	return Kit.part(parent, {
		name = name,
		shape = "Ball",
		size = Vector3.one * diameter,
		cframe = CFrame.new(position),
		color = color,
		material = material,
	})
end

function Kit.model(parent: Instance, name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

function Kit.folder(parent: Instance, name: string): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

-- Invisible, non-interactive reference point for gameplay code (spawns, anchors, slots).
function Kit.marker(parent: Instance, name: string, cframe: CFrame): BasePart
	local marker = Kit.part(parent, {
		name = name,
		size = Vector3.new(1, 1, 1),
		cframe = cframe,
		color = Palette.Core.Cream,
		transparency = 1,
		collide = false,
		castShadow = false,
	})
	return marker
end

-- Adds readable signage text to one face of a part.
function Kit.label(part: BasePart, text: string, face: Enum.NormalId, textColor: Color3): TextLabel
	local surface = Instance.new("SurfaceGui")
	surface.Name = "Signage"
	surface.Face = face
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 40
	surface.LightInfluence = 0
	surface.Parent = part

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = textColor
	label.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
	label.Parent = surface

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.06, 0)
	padding.PaddingRight = UDim.new(0.06, 0)
	padding.PaddingTop = UDim.new(0.12, 0)
	padding.PaddingBottom = UDim.new(0.12, 0)
	padding.Parent = label
	return label
end

function Kit.yaw(degrees: number): CFrame
	return CFrame.Angles(0, math.rad(degrees), 0)
end

-- CFrame on the ground at (x, z) facing `degrees` of yaw.
function Kit.ground(x: number, z: number, degrees: number?, y: number?): CFrame
	return CFrame.new(x, y or 0, z) * Kit.yaw(degrees or 0)
end

-- Deterministic xorshift32 PRNG. Roblox's Random is not available in every environment the
-- generator runs in, and we want identical layouts everywhere.
export type Rng = {
	next: (self: Rng) -> number,
	range: (self: Rng, min: number, max: number) -> number,
	int: (self: Rng, min: number, max: number) -> number,
}

function Kit.rng(seed: number): Rng
	local state = bit32.band(seed, 0xFFFFFFFF)
	if state == 0 then
		state = 0x9E3779B9
	end
	local rng = {} :: any
	function rng.next(_self: Rng): number
		state = bit32.bxor(state, bit32.lshift(state, 13))
		state = bit32.bxor(state, bit32.rshift(state, 17))
		state = bit32.bxor(state, bit32.lshift(state, 5))
		return state / 4294967296
	end
	function rng.range(self: Rng, min: number, max: number): number
		return min + (max - min) * self:next()
	end
	function rng.int(self: Rng, min: number, max: number): number
		return math.min(max, min + math.floor((max - min + 1) * self:next()))
	end
	return rng
end

-- Distance from point p to segment ab on the XZ plane.
function Kit.distanceToSegment(p: Vector3, a: Vector3, b: Vector3): number
	local ax, az = b.X - a.X, b.Z - a.Z
	local lengthSquared = ax * ax + az * az
	local t = if lengthSquared > 0 then math.clamp(((p.X - a.X) * ax + (p.Z - a.Z) * az) / lengthSquared, 0, 1) else 0
	local dx, dz = p.X - (a.X + ax * t), p.Z - (a.Z + az * t)
	return math.sqrt(dx * dx + dz * dz)
end

return Kit
