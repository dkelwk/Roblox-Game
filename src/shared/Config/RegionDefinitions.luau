--!strict
--[[
	RegionDefinitions — every zone in the world and what can be found there.

	Adding a future region (forest, frozen crash site, ...) means adding an entry here plus its
	world geometry; no gameplay code should special-case region ids.

	Spawn weights are relative within a region's table and are shown to players in-game, so
	keep them honest and readable.
]]

local WorldLayout = require(script.Parent.WorldLayout)

export type RegionKind = "Hub" | "Extraction"

--[[
	How a region's capsules exist (hybrid model):
	  PerPlayer — each player has their own instanced capsules. Reliable for beginners; nobody
	              can be locked out. Used by the starter region.
	  Shared    — one competitive pool everyone races for. Reserved for future advanced regions;
	              NOT implemented yet, so the validator rejects it until SpecimenService supports it.
]]
export type SpawnMode = "PerPlayer" | "Shared"

export type SpecimenEntry = {
	alienId: string,
	weight: number,
}

export type RegionDefinition = {
	id: string,
	displayName: string,
	kind: RegionKind,
	bounds: WorldLayout.Bounds,
	-- Extraction regions only:
	unlockCost: number?,
	spawnMode: SpawnMode?,
	-- PerPlayer regions: how many capsules each player has available at once.
	activeCapsulesPerPlayer: number?,
	capsuleRespawnSeconds: number?,
	specimenTable: { SpecimenEntry }?,
}

local RegionDefinitions = {}

local ById: { [string]: RegionDefinition } = {
	lab_district = {
		id = "lab_district",
		displayName = "Lab District",
		kind = "Hub",
		bounds = WorldLayout.District.Bounds,
	},
	desert = {
		id = "desert",
		displayName = "Groom Lake Dunes",
		kind = "Extraction",
		bounds = WorldLayout.Desert.Bounds,
		unlockCost = 0,
		spawnMode = "PerPlayer",
		activeCapsulesPerPlayer = 6,
		capsuleRespawnSeconds = 25,
		specimenTable = {
			{ alienId = "glorp", weight = 30 },
			{ alienId = "munch", weight = 28 },
			{ alienId = "zib", weight = 24 },
			{ alienId = "voltix", weight = 9 },
			{ alienId = "craggle", weight = 7 },
			{ alienId = "nebula", weight = 2 },
		},
	},
}

RegionDefinitions.ById = ById

-- The extraction region new players are guided to first.
RegionDefinitions.StarterRegionId = "desert"

function RegionDefinitions.get(id: string): RegionDefinition?
	return RegionDefinitions.ById[id]
end

return RegionDefinitions
