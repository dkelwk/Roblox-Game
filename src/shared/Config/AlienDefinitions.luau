--!strict
--[[
	AlienDefinitions — every collectible species.

	`id` is the stable key written to player data. Never rename or reuse an id once it has
	shipped; change `displayName` instead.

	Descriptions and colors are initial creative briefs pending art approval.

	A species' appearance is independent of its rarity (Zib is purple and Common). Rarity is
	presented only through UI frames, badges, lighting and discovery VFX (RarityDefinitions).
]]

local RarityDefinitions = require(script.Parent.RarityDefinitions)

-- Procedural idle presets the chamber/preview presenters know how to play.
export type IdleStyle = "Drift" | "Hop" | "Waddle" | "Crackle" | "Rumble" | "Orbit"

export type AlienDefinition = {
	id: string,
	displayName: string,
	rarity: RarityDefinitions.RarityId,
	-- Credits generated per second while displayed in a containment chamber.
	creditsPerSecond: number,
	description: string,
	colors: {
		primary: Color3,
		secondary: Color3,
		glow: Color3,
	},
	idleStyle: IdleStyle,
	-- Name of the model under ReplicatedStorage.Assets.Aliens (Phase 5).
	modelName: string,
}

local AlienDefinitions = {}

local ById: { [string]: AlienDefinition } = {
	glorp = {
		id = "glorp",
		displayName = "Glorp",
		rarity = "common",
		creditsPerSecond = 2,
		description = "A friendly turquoise jelly. Its little fins flutter whenever it is happy, which is always.",
		colors = {
			primary = Color3.fromHex("#37D3C6"),
			secondary = Color3.fromHex("#B4FFF4"),
			glow = Color3.fromHex("#3CE8E4"),
		},
		idleStyle = "Drift",
		modelName = "Glorp",
	},
	munch = {
		id = "munch",
		displayName = "Munch",
		rarity = "common",
		creditsPerSecond = 3,
		description = "A round orange snacker on stubby legs. Tiny mouth, enormous appetite.",
		colors = {
			primary = Color3.fromHex("#FF9A52"),
			secondary = Color3.fromHex("#FFD7AE"),
			glow = Color3.fromHex("#FFD76A"),
		},
		idleStyle = "Waddle",
		modelName = "Munch",
	},
	zib = {
		id = "zib",
		displayName = "Zib",
		rarity = "common",
		creditsPerSecond = 4,
		description = "A small purple hopper with one huge curious eye. Never stops bouncing.",
		colors = {
			primary = Color3.fromHex("#8E63F2"),
			secondary = Color3.fromHex("#E9DEFF"),
			glow = Color3.fromHex("#7BF5B4"),
		},
		idleStyle = "Hop",
		modelName = "Zib",
	},
	voltix = {
		id = "voltix",
		displayName = "Voltix",
		rarity = "rare",
		creditsPerSecond = 10,
		description = "A crackling blue creature whose antennae glow brighter the more excited it gets.",
		colors = {
			primary = Color3.fromHex("#3D8BFF"),
			secondary = Color3.fromHex("#C4E4FF"),
			glow = Color3.fromHex("#3CE8E4"),
		},
		idleStyle = "Crackle",
		modelName = "Voltix",
	},
	craggle = {
		id = "craggle",
		displayName = "Craggle",
		rarity = "rare",
		creditsPerSecond = 12,
		description = "A slow, sturdy rock-being. Glowing crystals grow along its back as it naps.",
		colors = {
			primary = Color3.fromHex("#B5764E"),
			secondary = Color3.fromHex("#E9B88E"),
			glow = Color3.fromHex("#7BF5B4"),
		},
		idleStyle = "Rumble",
		modelName = "Craggle",
	},
	nebula = {
		id = "nebula",
		displayName = "Nebula",
		rarity = "epic",
		creditsPerSecond = 40,
		description = "A floating cosmic drifter of deep violet, circled by tiny orbiting stars.",
		colors = {
			primary = Color3.fromHex("#3A1E6B"),
			secondary = Color3.fromHex("#7B4FD9"),
			glow = Color3.fromHex("#FFD76A"),
		},
		idleStyle = "Orbit",
		modelName = "Nebula",
	},
}

AlienDefinitions.ById = ById

-- Catalog display order.
AlienDefinitions.Order = { "glorp", "munch", "zib", "voltix", "craggle", "nebula" }

function AlienDefinitions.get(id: string): AlienDefinition?
	return AlienDefinitions.ById[id]
end

return AlienDefinitions
