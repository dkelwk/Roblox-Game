-- Shared configuration: correctness, art-direction fidelity and onboarding pacing.

local AlienDefinitions = use("ReplicatedStorage.Shared.Config.AlienDefinitions")
local ConfigValidator = use("ReplicatedStorage.Shared.ConfigValidator")
local GameConfig = use("ReplicatedStorage.Shared.Config.GameConfig")
local Palette = use("ReplicatedStorage.Shared.Config.Palette")
local RarityDefinitions = use("ReplicatedStorage.Shared.Config.RarityDefinitions")
local RegionDefinitions = use("ReplicatedStorage.Shared.Config.RegionDefinitions")
local UpgradeDefinitions = use("ReplicatedStorage.Shared.Config.UpgradeDefinitions")
local WorldLayout = use("ReplicatedStorage.Shared.Config.WorldLayout")

describe("Shared configuration", function()
	it("passes the cross-module validator", function()
		expect(ConfigValidator.validate()).toBeEmpty()
	end)

	it("keeps the creative-direction palette exactly", function()
		expect(Palette.CoreHex).toEqual({
			Navy = "#101A2C",
			Blue = "#243A55",
			Cyan = "#3CE8E4",
			Mint = "#7BF5B4",
			Sand = "#F4C98D",
			Cream = "#F5F6F9",
			Orange = "#FF875B",
			Purple = "#AC8CFF",
			Gold = "#FFD76A",
		})
	end)

	it("defines the six launch species in catalog order", function()
		expect(AlienDefinitions.Order).toEqual({ "glorp", "munch", "zib", "voltix", "craggle", "nebula" })
	end)

	it("uses exactly three rarity tiers, each with at least one species", function()
		expect(RarityDefinitions.Order).toEqual({ "common", "rare", "epic" })
		local counts = {}
		for _, alien in AlienDefinitions.ById do
			counts[alien.rarity] = (counts[alien.rarity] or 0) + 1
		end
		for _, rarityId in RarityDefinitions.Order do
			expect(counts[rarityId] ~= nil).toBe(true)
		end
	end)

	it("pays more per second for rarer species", function()
		local worstByRarity, bestByRarity = {}, {}
		for _, alien in AlienDefinitions.ById do
			local rate = alien.creditsPerSecond
			worstByRarity[alien.rarity] = math.min(worstByRarity[alien.rarity] or math.huge, rate)
			bestByRarity[alien.rarity] = math.max(bestByRarity[alien.rarity] or 0, rate)
		end
		for index = 2, #RarityDefinitions.Order do
			local lower, higher = RarityDefinitions.Order[index - 1], RarityDefinitions.Order[index]
			expect(worstByRarity[higher] > bestByRarity[lower]).toBe(true)
		end
	end)

	it("keeps starter-region odds honest: mostly commons, epics under 5%", function()
		local region = RegionDefinitions.ById[RegionDefinitions.StarterRegionId]
		local total, byRarity = 0, {}
		for _, entry in region.specimenTable do
			local rarity = AlienDefinitions.ById[entry.alienId].rarity
			byRarity[rarity] = (byRarity[rarity] or 0) + entry.weight
			total += entry.weight
		end
		expect(byRarity.common / total).toBeAtLeast(0.7)
		expect(byRarity.epic / total).toBeAtMost(0.05)
	end)

	it("lets a new player afford a first upgrade within the onboarding target", function()
		-- Assumes the first extraction lands on the target time, reveals the guaranteed
		-- onboarding species, and that species then earns in a chamber.
		local onboarding = GameConfig.Onboarding
		local alien = AlienDefinitions.ById[onboarding.FirstSpecimenAlienId]
		local bonus = RarityDefinitions.ById[alien.rarity].discoveryBonus
		local cheapest = math.huge
		for _, upgrade in UpgradeDefinitions.ById do
			cheapest = math.min(cheapest, upgrade.levels[2].cost)
		end
		local credits = GameConfig.Economy.StartingCredits + bonus
		local secondsToAfford = math.max(0, cheapest - credits) / alien.creditsPerSecond
		expect(onboarding.TargetFirstExtractionSeconds + secondsToAfford).toBeAtMost(
			onboarding.TargetFirstUpgradeSeconds
		)
	end)

	it("resolves upgrade stats by level and fails loudly on typos", function()
		expect(UpgradeDefinitions.getStat("jetpack_fuel", 1, "FuelSeconds")).toBe(4)
		expect(UpgradeDefinitions.getStat("jetpack_fuel", 99, "FuelSeconds")).toBe(12)
		expect(function()
			UpgradeDefinitions.getStat("jetpak_fuel", 1, "FuelSeconds")
		end).toThrow("Unknown upgrade")
		expect(function()
			UpgradeDefinitions.getStat("jetpack_fuel", 1, "Fuel")
		end).toThrow("has no stat")
	end)

	it("places six plots that face the road", function()
		expect(#WorldLayout.Plots).toBe(6)
		for _, origin in WorldLayout.Plots do
			local towardRoad = Vector3.new(-math.sign(origin.Position.X), 0, 0)
			expect(origin.LookVector:Dot(towardRoad)).toBeNear(1)
		end
	end)

	it("answers region membership from bounds", function()
		expect(WorldLayout.isInside(WorldLayout.Desert.Bounds, WorldLayout.Desert.Junction)).toBe(true)
		expect(WorldLayout.isInside(WorldLayout.Desert.Bounds, WorldLayout.District.Plaza.Center)).toBe(false)
		expect(WorldLayout.isInside(WorldLayout.District.Bounds, WorldLayout.Plots[1].Position)).toBe(true)
	end)
end)
