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
	-- Capsules are instanced per player so newcomers always have something to find and
	-- nobody can be locked out by other players clearing the map.
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
