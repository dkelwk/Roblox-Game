--!strict
--[[
	ConfigValidator — cross-checks every shared definition module.

	Runs on server boot (the server refuses to start gameplay on any error) and in the test
	suite. Takes an optional bundle so tests can feed deliberately broken configs; every check
	is defensive so a malformed config produces an error message rather than a crash.
]]

local Config = script.Parent.Config

export type Bundle = {
	Palette: any,
	RarityDefinitions: any,
	AlienDefinitions: any,
	UpgradeDefinitions: any,
	RegionDefinitions: any,
	GameConfig: any,
	WorldLayout: any,
	NetworkDefinitions: any,
}

local ID_PATTERN = "^[a-z][a-z0-9_]*$"
local IDLE_STYLES = { Drift = true, Hop = true, Waddle = true, Crackle = true, Rumble = true, Orbit = true }
local REGION_KINDS = { Hub = true, Extraction = true }
local ARG_TYPES = { string = true, number = true, boolean = true }

local ConfigValidator = {}

function ConfigValidator.defaultBundle(): Bundle
	return {
		Palette = require(Config.Palette),
		RarityDefinitions = require(Config.RarityDefinitions),
		AlienDefinitions = require(Config.AlienDefinitions),
		UpgradeDefinitions = require(Config.UpgradeDefinitions),
		RegionDefinitions = require(Config.RegionDefinitions),
		GameConfig = require(Config.GameConfig),
		WorldLayout = require(Config.WorldLayout),
		NetworkDefinitions = require(script.Parent.Network.NetworkDefinitions),
	}
end

local function isPositiveNumber(value: any): boolean
	return type(value) == "number" and value > 0 and value == value and value ~= math.huge
end

local function isNonNegativeInteger(value: any): boolean
	return type(value) == "number" and value >= 0 and value % 1 == 0
end

local function isNonEmptyString(value: any): boolean
	return type(value) == "string" and #value > 0
end

-- Checks that `order` lists exactly the keys of `byId`, each once.
local function checkOrder(errors: { string }, label: string, byId: any, order: any)
	if type(order) ~= "table" then
		table.insert(errors, `{label}.Order is missing`)
		return
	end
	local seen = {}
	for _, id in order do
		if seen[id] then
			table.insert(errors, `{label}.Order lists '{id}' twice`)
		elseif byId[id] == nil then
			table.insert(errors, `{label}.Order lists unknown id '{id}'`)
		end
		seen[id] = true
	end
	for id in byId do
		if not seen[id] then
			table.insert(errors, `{label}.Order is missing '{id}'`)
		end
	end
end

local function checkPalette(errors: { string }, palette: any)
	if type(palette) ~= "table" or type(palette.CoreHex) ~= "table" or type(palette.Core) ~= "table" then
		table.insert(errors, "Palette must define CoreHex and Core")
		return
	end
	for name, hexValue in palette.CoreHex do
		local color = palette.Core[name]
		if typeof(color) ~= "Color3" then
			table.insert(errors, `Palette.Core.{name} is missing`)
		elseif color:ToHex():upper() ~= (hexValue :: string):sub(2):upper() then
			table.insert(errors, `Palette.Core.{name} does not match {hexValue}`)
		end
	end
end

local function checkRarities(errors: { string }, rarities: any)
	if type(rarities) ~= "table" or type(rarities.ById) ~= "table" then
		table.insert(errors, "RarityDefinitions.ById is missing")
		return
	end
	local seenOrder = {}
	for key, rarity in rarities.ById do
		local label = `Rarity '{key}'`
		if rarity.id ~= key then
			table.insert(errors, `{label}: id field '{rarity.id}' does not match its key`)
		end
		if not isNonEmptyString(rarity.displayName) then
			table.insert(errors, `{label}: displayName is required`)
		end
		if typeof(rarity.color) ~= "Color3" then
			table.insert(errors, `{label}: color must be a Color3`)
		end
		if not isNonNegativeInteger(rarity.discoveryBonus) then
			table.insert(errors, `{label}: discoveryBonus must be a non-negative integer`)
		end
		if type(rarity.revealTier) ~= "number" or rarity.revealTier < 1 or rarity.revealTier > 3 then
			table.insert(errors, `{label}: revealTier must be 1..3`)
		end
		if type(rarity.order) ~= "number" then
			table.insert(errors, `{label}: order must be a number`)
		elseif seenOrder[rarity.order] then
			table.insert(errors, `{label}: order {rarity.order} is shared with '{seenOrder[rarity.order]}'`)
		else
			seenOrder[rarity.order] = key
		end
	end
	checkOrder(errors, "RarityDefinitions", rarities.ById, rarities.Order)
end

local function checkAliens(errors: { string }, aliens: any, rarities: any)
	if type(aliens) ~= "table" or type(aliens.ById) ~= "table" then
		table.insert(errors, "AlienDefinitions.ById is missing")
		return
	end
	local rarityById = if type(rarities) == "table" and type(rarities.ById) == "table" then rarities.ById else {}
	for key, alien in aliens.ById do
		local label = `Alien '{key}'`
		if alien.id ~= key then
			table.insert(errors, `{label}: id field '{alien.id}' does not match its key`)
		end
		if type(key) ~= "string" or not key:match(ID_PATTERN) then
			table.insert(errors, `{label}: id must be lowercase snake_case`)
		end
		if not isNonEmptyString(alien.displayName) then
			table.insert(errors, `{label}: displayName is required`)
		end
		if rarityById[alien.rarity] == nil then
			table.insert(errors, `{label}: unknown rarity '{alien.rarity}'`)
		end
		if not isPositiveNumber(alien.creditsPerSecond) then
			table.insert(errors, `{label}: creditsPerSecond must be > 0`)
		end
		if not isNonEmptyString(alien.description) then
			table.insert(errors, `{label}: description is required`)
		end
		if not isNonEmptyString(alien.modelName) then
			table.insert(errors, `{label}: modelName is required`)
		end
		if not IDLE_STYLES[alien.idleStyle] then
			table.insert(errors, `{label}: unknown idleStyle '{alien.idleStyle}'`)
		end
		local colors = alien.colors
		if type(colors) ~= "table" then
			table.insert(errors, `{label}: colors table is required`)
		else
			for _, slot in { "primary", "secondary", "glow" } do
				if typeof(colors[slot]) ~= "Color3" then
					table.insert(errors, `{label}: colors.{slot} must be a Color3`)
				end
			end
		end
	end
	checkOrder(errors, "AlienDefinitions", aliens.ById, aliens.Order)
end

local function checkUpgrades(errors: { string }, upgrades: any)
	if type(upgrades) ~= "table" or type(upgrades.ById) ~= "table" or type(upgrades.Stats) ~= "table" then
		table.insert(errors, "UpgradeDefinitions must define ById and Stats")
		return
	end
	for key, upgrade in upgrades.ById do
		local label = `Upgrade '{key}'`
		if upgrade.id ~= key then
			table.insert(errors, `{label}: id field '{upgrade.id}' does not match its key`)
		end
		if not isNonEmptyString(upgrade.displayName) or not isNonEmptyString(upgrade.description) then
			table.insert(errors, `{label}: displayName and description are required`)
		end
		local levels = upgrade.levels
		if type(levels) ~= "table" or #levels < 2 then
			table.insert(errors, `{label}: needs at least two levels`)
			continue
		end
		if levels[1].cost ~= 0 then
			table.insert(errors, `{label}: level 1 is the free starting level and must cost 0`)
		end
		local statKeys = {}
		for stat in levels[1].stats or {} do
			statKeys[stat] = true
			if upgrades.Stats[stat] == nil then
				table.insert(errors, `{label}: unknown stat '{stat}'`)
			end
		end
		for index = 2, #levels do
			local previous, current = levels[index - 1], levels[index]
			local levelLabel = `{label} level {index}`
			if not isNonNegativeInteger(current.cost) or current.cost <= previous.cost then
				table.insert(errors, `{levelLabel}: cost must be an integer greater than level {index - 1}`)
			end
			local improvesSomething = false
			for stat in statKeys do
				local before, after = previous.stats[stat], current.stats and current.stats[stat]
				local statDefinition = upgrades.Stats[stat]
				if type(after) ~= "number" then
					table.insert(errors, `{levelLabel}: missing stat '{stat}'`)
				elseif statDefinition and type(before) == "number" then
					local better = statDefinition.better == "higher"
					if (better and after < before) or (not better and after > before) then
						table.insert(errors, `{levelLabel}: '{stat}' gets worse`)
					elseif after ~= before then
						improvesSomething = true
					end
				end
			end
			for stat in current.stats or {} do
				if not statKeys[stat] then
					table.insert(errors, `{levelLabel}: stat '{stat}' is not present on level 1`)
				end
			end
			if not improvesSomething then
				table.insert(errors, `{levelLabel}: costs credits but improves nothing`)
			end
		end
	end
	checkOrder(errors, "UpgradeDefinitions", upgrades.ById, upgrades.Order)
end

local function checkBounds(errors: { string }, label: string, bounds: any)
	if type(bounds) ~= "table" or type(bounds.MinX) ~= "number" or type(bounds.MaxX) ~= "number" then
		table.insert(errors, `{label}: bounds are missing`)
	elseif bounds.MinX >= bounds.MaxX or bounds.MinZ >= bounds.MaxZ then
		table.insert(errors, `{label}: bounds Min must be less than Max`)
	end
end

local function checkRegions(errors: { string }, regions: any, aliens: any)
	if type(regions) ~= "table" or type(regions.ById) ~= "table" then
		table.insert(errors, "RegionDefinitions.ById is missing")
		return
	end
	local alienById = if type(aliens) == "table" and type(aliens.ById) == "table" then aliens.ById else {}
	local obtainable = {}
	for key, region in regions.ById do
		local label = `Region '{key}'`
		if region.id ~= key then
			table.insert(errors, `{label}: id field '{region.id}' does not match its key`)
		end
		if not REGION_KINDS[region.kind] then
			table.insert(errors, `{label}: unknown kind '{region.kind}'`)
		end
		checkBounds(errors, label, region.bounds)
		if region.kind ~= "Extraction" then
			continue
		end
		if not isNonNegativeInteger(region.unlockCost) then
			table.insert(errors, `{label}: unlockCost must be a non-negative integer`)
		end
		if not isNonNegativeInteger(region.activeCapsulesPerPlayer) or region.activeCapsulesPerPlayer < 1 then
			table.insert(errors, `{label}: activeCapsulesPerPlayer must be at least 1`)
		end
		if not isPositiveNumber(region.capsuleRespawnSeconds) then
			table.insert(errors, `{label}: capsuleRespawnSeconds must be > 0`)
		end
		local specimenTable = region.specimenTable
		if type(specimenTable) ~= "table" or #specimenTable == 0 then
			table.insert(errors, `{label}: extraction regions need a specimenTable`)
			continue
		end
		local seen = {}
		for _, entry in specimenTable do
			if alienById[entry.alienId] == nil then
				table.insert(errors, `{label}: specimenTable references unknown alien '{entry.alienId}'`)
			elseif seen[entry.alienId] then
				table.insert(errors, `{label}: specimenTable lists '{entry.alienId}' twice`)
			end
			if not isPositiveNumber(entry.weight) then
				table.insert(errors, `{label}: weight for '{entry.alienId}' must be > 0`)
			end
			seen[entry.alienId] = true
			obtainable[entry.alienId] = true
		end
	end
	for id in alienById do
		if not obtainable[id] then
			table.insert(errors, `Alien '{id}' cannot be found in any region`)
		end
	end
	local starter = regions.ById[regions.StarterRegionId]
	if starter == nil or starter.kind ~= "Extraction" then
		table.insert(errors, `StarterRegionId '{regions.StarterRegionId}' must be an extraction region`)
	end
end

local function checkGameConfig(errors: { string }, bundle: Bundle)
	local gameConfig, regions, layout = bundle.GameConfig, bundle.RegionDefinitions, bundle.WorldLayout
	if type(gameConfig) ~= "table" then
		table.insert(errors, "GameConfig is missing")
		return
	end
	local plotCount = if type(layout) == "table" and type(layout.Plots) == "table" then #layout.Plots else 0
	if not isNonNegativeInteger(gameConfig.MaxPlayersPerServer) or gameConfig.MaxPlayersPerServer > plotCount then
		table.insert(errors, `GameConfig.MaxPlayersPerServer must not exceed the {plotCount} plots in WorldLayout`)
	end
	local scanner = gameConfig.Scanner or {}
	for _, field in { "LoadingSeconds", "ScanningSeconds", "CompleteTimeoutSeconds", "ResettingSeconds" } do
		if not isPositiveNumber(scanner[field]) then
			table.insert(errors, `GameConfig.Scanner.{field} must be > 0`)
		end
	end
	local onboarding = gameConfig.Onboarding or {}
	local firstAlien = onboarding.FirstSpecimenAlienId
	local starter = type(regions) == "table" and type(regions.ById) == "table" and regions.ById[regions.StarterRegionId]
	local inStarter = false
	if starter and type(starter.specimenTable) == "table" then
		for _, entry in starter.specimenTable do
			if entry.alienId == firstAlien then
				inStarter = true
			end
		end
	end
	if not inStarter then
		table.insert(
			errors,
			`GameConfig.Onboarding.FirstSpecimenAlienId '{firstAlien}' must be found in the starter region`
		)
	end
	local seenTags = {}
	for key, tag in gameConfig.Tags or {} do
		if not isNonEmptyString(tag) or seenTags[tag] then
			table.insert(errors, `GameConfig.Tags.{key} must be a unique non-empty string`)
		end
		seenTags[tag] = true
	end
end

local function checkWorldLayout(errors: { string }, layout: any, upgrades: any)
	if type(layout) ~= "table" or type(layout.Plots) ~= "table" or type(layout.Plot) ~= "table" then
		table.insert(errors, "WorldLayout must define Plot and Plots")
		return
	end
	local district = layout.District
	checkBounds(errors, "WorldLayout.District", district and district.Bounds)
	checkBounds(errors, "WorldLayout.Desert", layout.Desert and layout.Desert.Bounds)

	-- Every lab must physically fit the maximum Containment Wing level.
	local labCapacity = type(upgrades) == "table" and type(upgrades.ById) == "table" and upgrades.ById.lab_capacity
	local levels = labCapacity and labCapacity.levels
	local finalLevel = type(levels) == "table" and levels[#levels]
	local maxSlots = finalLevel and type(finalLevel.stats) == "table" and finalLevel.stats.ChamberSlots
	if type(maxSlots) ~= "number" then
		table.insert(errors, "UpgradeDefinitions must define lab_capacity with ChamberSlots")
	elseif layout.Plot.ChamberSlotCount < maxSlots then
		table.insert(
			errors,
			`WorldLayout.Plot.ChamberSlotCount ({layout.Plot.ChamberSlotCount}) is below the max ChamberSlots upgrade ({maxSlots})`
		)
	end

	-- Plots must sit inside the district, clear of the road (centered on X = 0), and apart
	-- from each other.
	local half = layout.Plot.Size / 2
	local roadHalf = district and district.RoadWidth and district.RoadWidth / 2 or 0
	for index, origin in layout.Plots do
		local position = origin.Position
		local label = `WorldLayout.Plots[{index}]`
		if district and district.Bounds then
			local b = district.Bounds
			if
				position.X - half < b.MinX
				or position.X + half > b.MaxX
				or position.Z - half < b.MinZ
				or position.Z + half > b.MaxZ
			then
				table.insert(errors, `{label} extends outside the district`)
			end
		end
		if math.abs(position.X) - half < roadHalf then
			table.insert(errors, `{label} overlaps the main road`)
		end
		for otherIndex = index + 1, #layout.Plots do
			local other = layout.Plots[otherIndex].Position
			if
				math.abs(position.X - other.X) < layout.Plot.Size
				and math.abs(position.Z - other.Z) < layout.Plot.Size
			then
				table.insert(errors, `{label} overlaps plot {otherIndex}`)
			end
		end
	end
end

local function checkNetwork(errors: { string }, network: any)
	if type(network) ~= "table" or type(network.Remotes) ~= "table" then
		table.insert(errors, "NetworkDefinitions.Remotes is missing")
		return
	end
	for name, remote in network.Remotes do
		local label = `Remote '{name}'`
		if remote.kind ~= "Event" and remote.kind ~= "Function" then
			table.insert(errors, `{label}: kind must be Event or Function`)
		end
		if remote.direction ~= "ToServer" and remote.direction ~= "ToClient" then
			table.insert(errors, `{label}: direction must be ToServer or ToClient`)
		end
		if not isNonEmptyString(remote.owner) then
			table.insert(errors, `{label}: owner is required`)
		end
		if remote.direction ~= "ToServer" then
			continue
		end
		local rateLimit = remote.rateLimit
		if
			type(rateLimit) ~= "table"
			or not isPositiveNumber(rateLimit.count)
			or not isPositiveNumber(rateLimit.perSeconds)
		then
			table.insert(errors, `{label}: client→server remotes need a rateLimit`)
		end
		if type(remote.args) ~= "table" then
			table.insert(errors, `{label}: client→server remotes need an args schema (an empty table for none)`)
			continue
		end
		for index, arg in remote.args do
			if not isNonEmptyString(arg.name) or not ARG_TYPES[arg.type] then
				table.insert(errors, `{label}: arg {index} needs a name and a type of string/number/boolean`)
			elseif arg.type == "string" and not isPositiveNumber(arg.maxLength) then
				table.insert(errors, `{label}: string arg '{arg.name}' needs a maxLength`)
			elseif arg.type == "number" and (type(arg.min) ~= "number" or type(arg.max) ~= "number") then
				table.insert(errors, `{label}: number arg '{arg.name}' needs min and max`)
			end
		end
	end
end

-- Returns a list of human-readable problems. Empty means the configuration is valid.
function ConfigValidator.validate(bundle: Bundle?): { string }
	local resolved = bundle or ConfigValidator.defaultBundle()
	local errors = {}
	checkPalette(errors, resolved.Palette)
	checkRarities(errors, resolved.RarityDefinitions)
	checkAliens(errors, resolved.AlienDefinitions, resolved.RarityDefinitions)
	checkUpgrades(errors, resolved.UpgradeDefinitions)
	checkRegions(errors, resolved.RegionDefinitions, resolved.AlienDefinitions)
	checkGameConfig(errors, resolved)
	checkWorldLayout(errors, resolved.WorldLayout, resolved.UpgradeDefinitions)
	checkNetwork(errors, resolved.NetworkDefinitions)
	table.sort(errors)
	return errors
end

return ConfigValidator
