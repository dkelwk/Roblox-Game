--!strict
--[[
	NetworkDefinitions — the complete list of remotes and their contracts.

	The server creates every remote from this table at startup; nothing else may create
	remotes. Every client→server remote declares its argument schema and a per-player rate
	limit, and the server's network layer enforces both before any handler runs.

	Clients only ever send *intent* ("recover capsule X", "buy upgrade Y"). Amounts, rewards,
	results and prices are always decided on the server.
]]

local WorldLayout = require(script.Parent.Parent.Config.WorldLayout)

export type ArgType = "string" | "number" | "boolean"

export type ArgSpec = {
	name: string,
	type: ArgType,
	-- string
	maxLength: number?,
	-- number
	integer: boolean?,
	min: number?,
	max: number?,
}

export type RemoteDefinition = {
	kind: "Event" | "Function",
	direction: "ToServer" | "ToClient",
	-- Server service that owns (handles or sends) this remote.
	owner: string,
	-- ToServer only.
	args: { ArgSpec }?,
	rateLimit: { count: number, perSeconds: number }?,
}

local ID_LENGTH = 40

local function stringArg(name: string, maxLength: number): ArgSpec
	return { name = name, type = "string", maxLength = maxLength }
end

local function integerArg(name: string, min: number, max: number): ArgSpec
	return { name = name, type = "number", integer = true, min = min, max = max }
end

local function booleanArg(name: string): ArgSpec
	return { name = name, type = "boolean" }
end

local NetworkDefinitions = {}

NetworkDefinitions.FolderName = "Remotes"

local Remotes: { [string]: RemoteDefinition } = {
	-- Client → Server intents
	RequestRecoverCapsule = {
		kind = "Event",
		direction = "ToServer",
		owner = "SpecimenService",
		args = { stringArg("capsuleId", ID_LENGTH) },
		rateLimit = { count = 4, perSeconds = 1 },
	},
	RequestDepositCapsule = {
		kind = "Event",
		direction = "ToServer",
		owner = "ScannerService",
		args = {},
		rateLimit = { count = 2, perSeconds = 1 },
	},
	RequestContinueDiscovery = {
		kind = "Event",
		direction = "ToServer",
		owner = "ScannerService",
		args = {},
		rateLimit = { count = 2, perSeconds = 1 },
	},
	RequestPlaceAlien = {
		kind = "Event",
		direction = "ToServer",
		owner = "AlienCollectionService",
		args = {
			stringArg("specimenId", ID_LENGTH),
			integerArg("slotIndex", 1, WorldLayout.Plot.ChamberSlotCount),
		},
		rateLimit = { count = 4, perSeconds = 1 },
	},
	RequestPurchaseUpgrade = {
		kind = "Event",
		direction = "ToServer",
		owner = "UpgradeService",
		args = { stringArg("upgradeId", 32) },
		rateLimit = { count = 3, perSeconds = 1 },
	},
	ReportJetpackState = {
		kind = "Event",
		direction = "ToServer",
		owner = "JetpackValidationService",
		args = { booleanArg("thrusting") },
		rateLimit = { count = 15, perSeconds = 1 },
	},

	-- Server → Client pushes
	PlayerDataChanged = {
		kind = "Event",
		direction = "ToClient",
		owner = "PlayerDataService",
	},
	ScannerStateChanged = {
		kind = "Event",
		direction = "ToClient",
		owner = "ScannerService",
	},
	DiscoveryRevealed = {
		kind = "Event",
		direction = "ToClient",
		owner = "ScannerService",
	},
}

NetworkDefinitions.Remotes = Remotes

return NetworkDefinitions
