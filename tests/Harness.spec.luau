-- The Lune harness must reproduce Roblox math exactly, or generated worlds and specs lie.

local function near(a: Vector3, b: Vector3): boolean
	return (a - b).Magnitude < 1e-4
end

describe("Harness CFrame parity with Roblox", function()
	it("points lookAt toward the target in every direction", function()
		local origin = Vector3.new(3, 2, 1)
		for _, direction in
			{
				Vector3.new(1, 0, 0),
				Vector3.new(-1, 0, 0),
				Vector3.new(0, 0, -1),
				Vector3.new(0, 0, 1),
				Vector3.new(1, 0, -1).Unit,
				Vector3.new(-0.3, 0.4, 0.8).Unit,
			}
		do
			local frame = CFrame.lookAt(origin, origin + direction * 10)
			expect(near(frame.LookVector, direction)).toBe(true)
			expect(near(frame.Position, origin)).toBe(true)
			expect(frame.UpVector.Y > 0).toBe(true)
		end
	end)

	it("keeps lookAt right-handed (RightVector = Look × Up)", function()
		local frame = CFrame.lookAt(Vector3.zero, Vector3.new(0, 0, -5))
		expect(near(frame.RightVector, Vector3.new(1, 0, 0))).toBe(true)
	end)

	it("treats CFrame.new(position, lookAt) like lookAt", function()
		local frame = CFrame.new(Vector3.zero, Vector3.new(0, 0, -5))
		expect(near(frame.LookVector, Vector3.new(0, 0, -1))).toBe(true)
	end)

	it("matches Roblox rotation conventions for Angles", function()
		local r = math.rad
		expect(near(CFrame.Angles(0, r(90), 0).LookVector, Vector3.new(-1, 0, 0))).toBe(true)
		expect(near(CFrame.Angles(0, r(90), 0) * Vector3.new(0, 0, 1), Vector3.new(1, 0, 0))).toBe(true)
		expect(near(CFrame.Angles(r(90), 0, 0) * Vector3.new(0, 0, 1), Vector3.new(0, -1, 0))).toBe(true)
	end)
end)
