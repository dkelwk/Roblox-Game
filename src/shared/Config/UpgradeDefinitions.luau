--!strict
--[[
	UpgradeDefinitions — every purchasable progression upgrade and its price/level table.

	`levels[1]` is the free starting level and defines the base value of each stat, so base
	stats are never duplicated elsewhere. Prices exist only in this file.
]]

export type StatId = "FuelSeconds" | "ChamberSlots" | "CarryCapacity" | "PickupSeconds"

export type StatDefinition = {
	displayName: string,
	unit: string,
	-- Which direction is an improvement; validated so a level can never be a downgrade.
	better: "higher" | "lower",
}

export type UpgradeLevel = {
	cost: number,
	stats: { [StatId]: number },
}

export type UpgradeDefinition = {
	id: string,
	displayName: string,
	description: string,
	order: number,
	levels: { UpgradeLevel },
}

local UpgradeDefinitions = {}

local Stats: { [StatId]: StatDefinition } = {
	FuelSeconds = { displayName = "Jetpack fuel", unit = "s", better = "higher" },
	ChamberSlots = { displayName = "Containment chambers", unit = "", better = "higher" },
	CarryCapacity = { displayName = "Capsules carried", unit = "", better = "higher" },
	PickupSeconds = { displayName = "Recovery time", unit = "s", better = "lower" },
}

local ById: { [string]: UpgradeDefinition } = {
	jetpack_fuel = {
		id = "jetpack_fuel",
		displayName = "Fuel Cell",
		description = "Stay airborne longer on every flight.",
		order = 1,
		levels = {
			{ cost = 0, stats = { FuelSeconds = 4 } },
			{ cost = 150, stats = { FuelSeconds = 5.5 } },
			{ cost = 600, stats = { FuelSeconds = 7 } },
			{ cost = 2000, stats = { FuelSeconds = 9 } },
			{ cost = 6000, stats = { FuelSeconds = 12 } },
		},
	},
	lab_capacity = {
		id = "lab_capacity",
		displayName = "Containment Wing",
		description = "Power up more chambers to display and earn from more aliens.",
		order = 2,
		levels = {
			{ cost = 0, stats = { ChamberSlots = 3 } },
			{ cost = 250, stats = { ChamberSlots = 4 } },
			{ cost = 900, stats = { ChamberSlots = 5 } },
			{ cost = 3000, stats = { ChamberSlots = 6 } },
			{ cost = 9000, stats = { ChamberSlots = 8 } },
		},
	},
	extraction_rig = {
		id = "extraction_rig",
		displayName = "Extraction Rig",
		description = "Recover capsules faster and carry more of them home.",
		order = 3,
		levels = {
			{ cost = 0, stats = { CarryCapacity = 1, PickupSeconds = 1.0 } },
			{ cost = 400, stats = { CarryCapacity = 1, PickupSeconds = 0.6 } },
			{ cost = 1500, stats = { CarryCapacity = 2, PickupSeconds = 0.6 } },
			{ cost = 4500, stats = { CarryCapacity = 2, PickupSeconds = 0.35 } },
			{ cost = 12000, stats = { CarryCapacity = 3, PickupSeconds = 0.35 } },
		},
	},
}

UpgradeDefinitions.Stats = Stats
UpgradeDefinitions.ById = ById

-- Display order in the upgrade terminal.
UpgradeDefinitions.Order = { "jetpack_fuel", "lab_capacity", "extraction_rig" }

function UpgradeDefinitions.get(id: string): UpgradeDefinition?
	return UpgradeDefinitions.ById[id]
end

-- Returns the stat value at a given level (1-based). Errors on unknown upgrade/stat so
-- typos fail loudly in development rather than silently granting 0.
function UpgradeDefinitions.getStat(upgradeId: string, level: number, stat: StatId): number
	local definition = UpgradeDefinitions.ById[upgradeId]
	assert(definition, `Unknown upgrade '{upgradeId}'`)
	local levelData = definition.levels[math.clamp(level, 1, #definition.levels)]
	local value = levelData.stats[stat]
	assert(value ~= nil, `Upgrade '{upgradeId}' has no stat '{stat}'`)
	return value
end

return UpgradeDefinitions
