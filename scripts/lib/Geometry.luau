--[[
	Geometry — point-in-part tests for specs (exposed to spec files as `Geometry`).
]]

local Geometry = {}

-- Whether `point` lies inside `part`, shrunk by `margin`. Wedges are treated as boxes,
-- which over-approximates them (safe for "nothing is buried" checks).
function Geometry.contains(part: any, point: any, margin: number): boolean
	local localPoint = part.CFrame:PointToObjectSpace(point)
	local half = part.Size / 2
	if part:IsA("Part") and part.Shape.Name == "Ball" then
		return localPoint.Magnitude < half.X - margin
	elseif part:IsA("Part") and part.Shape.Name == "Cylinder" then
		local radius = math.min(half.Y, half.Z)
		return math.abs(localPoint.X) < half.X - margin
			and math.sqrt(localPoint.Y ^ 2 + localPoint.Z ^ 2) < radius - margin
	end
	return math.abs(localPoint.X) < half.X - margin
		and math.abs(localPoint.Y) < half.Y - margin
		and math.abs(localPoint.Z) < half.Z - margin
end

-- Collidable parts under `root`, excluding any part carrying `excludeTag`.
function Geometry.solidParts(root: any, excludeTag: string?): { any }
	local parts = {}
	for _, descendant in root:GetDescendants() do
		if
			descendant:IsA("BasePart")
			and descendant.CanCollide
			and not (excludeTag and descendant:HasTag(excludeTag))
		then
			table.insert(parts, descendant)
		end
	end
	return parts
end

-- Full names of every part in `parts` containing `point`.
function Geometry.blockers(parts: { any }, point: any, margin: number): { string }
	local names = {}
	for _, part in parts do
		if Geometry.contains(part, point, margin) then
			table.insert(names, part:GetFullName())
		end
	end
	return names
end

return Geometry
