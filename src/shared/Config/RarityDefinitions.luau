--!strict
--[[
	RarityDefinitions — presentation and reward tiers for aliens.

	Rarity controls how a discovery is *presented* (color, reveal intensity) and the one-time
	first-discovery bonus. Spawn odds live in RegionDefinitions and income lives on each
	alien, so each number has exactly one home.
]]

local Palette = require(script.Parent.Palette)

export type RarityId = "common" | "rare" | "epic"

export type RarityDefinition = {
	id: RarityId,
	displayName: string,
	-- Ascending value order; used for sorting and comparisons.
	order: number,
	color: Color3,
	-- One-time credits awarded the first time a player discovers a species of this rarity.
	discoveryBonus: number,
	-- 1..3: how much reveal VFX/audio the discovery sequence plays. Higher = more impressive.
	revealTier: number,
}

local RarityDefinitions = {}

local ById: { [string]: RarityDefinition } = {
	common = {
		id = "common",
		displayName = "Common",
		order = 1,
		color = Palette.Core.Mint,
		discoveryBonus = 50,
		revealTier = 1,
	},
	rare = {
		id = "rare",
		displayName = "Rare",
		order = 2,
		color = Palette.Core.Purple,
		discoveryBonus = 200,
		revealTier = 2,
	},
	epic = {
		id = "epic",
		displayName = "Epic",
		order = 3,
		color = Palette.Core.Gold,
		discoveryBonus = 750,
		revealTier = 3,
	},
}
local Order: { RarityId } = { "common", "rare", "epic" }

RarityDefinitions.ById = ById
RarityDefinitions.Order = Order

function RarityDefinitions.get(id: string): RarityDefinition?
	return RarityDefinitions.ById[id]
end

return RarityDefinitions
