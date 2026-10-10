-- The validator must catch each class of broken configuration. Each case deep-copies the
-- real configuration, breaks one thing, and checks the validator names the problem.

local ConfigValidator = use("ReplicatedStorage.Shared.ConfigValidator")

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, inner in value do
		copy[key] = deepCopy(inner)
	end
	return copy
end

local function brokenBundle(mutate: (any) -> ()): any
	local bundle = deepCopy(ConfigValidator.defaultBundle())
	mutate(bundle)
	return bundle
end

describe("ConfigValidator", function()
	it("accepts an untouched copy of the real configuration", function()
		expect(ConfigValidator.validate(brokenBundle(function() end))).toBeEmpty()
	end)

	it("rejects palette drift from the creative direction", function()
		local errors = ConfigValidator.validate(brokenBundle(function(bundle)
			bundle.Palette.Core.Cyan = Color3.fromHex("#00FFFF")
		end))
		expect(errors).toContainMatch("Palette.Core.Cyan does not match")
	end)

	it("rejects an alien with an unknown rarity", function()
		local errors = ConfigValidator.validate(brokenBundle(function(bundle)
			bundle.AlienDefinitions.ById.glorp.rarity = "legendary"
		end))
		expect(errors).toContainMatch("unknown rarity 'legendary'")
	end)

	it("rejects an alien that no region can produce", function()
		local errors = ConfigValidator.validate(brokenBundle(function(bundle)
			local specimenTable = bundle.RegionDefinitions.ById.desert.specimenTable
			for index = #specimenTable, 1, -1 do
				if specimenTable[index].alienId == "nebula" then
					table.remove(specimenTable, index)
				end
			end
		end))
		expect(errors).toContainMatch("'nebula' cannot be found in any region")
	end)

	it("rejects a catalog order that misses a species", function()
		local errors = ConfigValidator.validate(brokenBundle(function(bundle)
			table.remove(bundle.AlienDefinitions.Order)
		end))
		expect(errors).toContainMatch("AlienDefinitions.Order is missing 'nebula'")
	end)

	it("rejects upgrade prices that do not increase", function()
		local errors = ConfigValidator.validate(brokenBundle(function(bundle)
			bundle.UpgradeDefinitions.ById.jetpack_fuel.levels[3].cost = 100
		end))
		expect(errors).toContainMatch("jetpack_fuel' level 3: cost must be")
	end)

	it("rejects an upgrade level that makes a stat worse", function()
		local errors = ConfigValidator.validate(brokenBundle(function(bundle)
			bundle.UpgradeDefinitions.ById.extraction_rig.levels[2].stats.PickupSeconds = 1.5
		end))
		expect(errors).toContainMatch("'PickupSeconds' gets worse")
	end)

	it("rejects an upgrade level that costs credits but improves nothing", function()
		local errors = ConfigValidator.validate(brokenBundle(function(bundle)
			bundle.UpgradeDefinitions.ById.lab_capacity.levels[2].stats.ChamberSlots = 3
		end))
		expect(errors).toContainMatch("improves nothing")
	end)

	it("rejects labs too small for the max Containment Wing level", function()
		local errors = ConfigValidator.validate(brokenBundle(function(bundle)
			bundle.WorldLayout.Plot.ChamberSlotCount = 6
		end))
		expect(errors).toContainMatch("ChamberSlotCount %(6%) is below")
	end)

	it("rejects more players per server than plots", function()
		local errors = ConfigValidator.validate(brokenBundle(function(bundle)
			bundle.GameConfig.MaxPlayersPerServer = 8
		end))
		expect(errors).toContainMatch("MaxPlayersPerServer must not exceed the 6 plots")
	end)

	it("rejects an onboarding species missing from the starter region", function()
		local errors = ConfigValidator.validate(brokenBundle(function(bundle)
			bundle.GameConfig.Onboarding.FirstSpecimenAlienId = "unknown_alien"
		end))
		expect(errors).toContainMatch("FirstSpecimenAlienId 'unknown_alien'")
	end)

	it("rejects shared (competitive) spawning until it is implemented", function()
		local errors = ConfigValidator.validate(brokenBundle(function(bundle)
			bundle.RegionDefinitions.ById.desert.spawnMode = "Shared"
		end))
		expect(errors).toContainMatch("Shared %(competitive%) spawning is reserved")
	end)

	it("rejects a missing spawn mode", function()
		local errors = ConfigValidator.validate(brokenBundle(function(bundle)
			bundle.RegionDefinitions.ById.desert.spawnMode = nil
		end))
		expect(errors).toContainMatch("spawnMode must be PerPlayer")
	end)

	it("rejects a client→server remote without a rate limit", function()
		local errors = ConfigValidator.validate(brokenBundle(function(bundle)
			bundle.NetworkDefinitions.Remotes.RequestPurchaseUpgrade.rateLimit = nil
		end))
		expect(errors).toContainMatch("RequestPurchaseUpgrade': client→server remotes need a rateLimit")
	end)

	it("rejects an unbounded string argument", function()
		local errors = ConfigValidator.validate(brokenBundle(function(bundle)
			bundle.NetworkDefinitions.Remotes.RequestRecoverCapsule.args[1].maxLength = nil
		end))
		expect(errors).toContainMatch("string arg 'capsuleId' needs a maxLength")
	end)

	it("rejects overlapping plots", function()
		local errors = ConfigValidator.validate(brokenBundle(function(bundle)
			bundle.WorldLayout.Plots[2] = bundle.WorldLayout.Plots[1] * CFrame.new(0, 0, 10)
		end))
		expect(errors).toContainMatch("Plots%[1%] overlaps plot 2")
	end)

	it("reports problems instead of crashing on a gutted bundle", function()
		local errors = ConfigValidator.validate({} :: any)
		expect(#errors > 0).toBe(true)
	end)
end)
