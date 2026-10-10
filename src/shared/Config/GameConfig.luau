--!strict
--[[
	GameConfig — global tuning values and shared identifiers.

	All numbers here are starting points for playtesting, not final balance. Prices and
	upgrade stats live in UpgradeDefinitions; spawn odds in RegionDefinitions; per-alien
	income in AlienDefinitions.
]]

local GameConfig = {}

GameConfig.Version = "0.1.0"

-- Must match Game Settings → Places → Max Players. Validated against the number of plots.
GameConfig.MaxPlayersPerServer = 6

GameConfig.Data = {
	-- Bump the store name only for a deliberate wipe; use SchemaVersion + migrations otherwise.
	StoreName = "RA51_PlayerData_v1",
	SchemaVersion = 1,
	AutosaveSeconds = 120,
}

GameConfig.Economy = {
	StartingCredits = 0,
	-- How often chamber income is paid out. Income itself is per second (AlienDefinitions).
	IncomeTickSeconds = 1,
}

GameConfig.Specimen = {
	-- Max distance (studs) between the character and a capsule for a recovery to be accepted.
	RecoverRange = 12,
	-- Max distance between the character and their own scanner for a deposit to be accepted.
	DepositRange = 16,
	-- Spawn point tiers placed in the world (SpawnTier attribute). Starter points sit on the
	-- first trail for onboarding; Elevated need the ramp or jetpack; Secret reward exploration.
	SpawnTiers = { "Starter", "Standard", "Elevated", "Secret" },
}

-- Durations of the authoritative scanner states: Idle → Loading → Scanning → Complete → Resetting → Idle.
GameConfig.Scanner = {
	LoadingSeconds = 1.0,
	ScanningSeconds = 3.0,
	-- Complete holds until the player continues, or auto-continues after this long.
	CompleteTimeoutSeconds = 20,
	ResettingSeconds = 1.0,
}

GameConfig.Jetpack = {
	ThrustAcceleration = 120,
	MaxRiseSpeed = 30,
	AirControlSpeed = 22,
	-- Fuel starts recharging this long after thrust stops.
	RechargeDelaySeconds = 0.75,
	-- Time to refill from empty, regardless of tank size (bigger tanks refill faster per second).
	RechargeSecondsFromEmpty = 3.0,
	-- Server-validated ceiling above local ground.
	MaxAltitudeAboveGround = 90,
}

GameConfig.Onboarding = {
	-- A brand-new player's first scan always reveals this species.
	FirstSpecimenAlienId = "glorp",
	-- Design targets (seconds since joining) that config pacing tests check against.
	TargetFirstExtractionSeconds = 180,
	TargetFirstUpgradeSeconds = 300,
}

-- CollectionService tags placed on world objects. Code must reference these, not literals.
GameConfig.Tags = {
	Plot = "RA51_Plot",
	SpecimenSpawn = "RA51_SpecimenSpawn",
	ExtractionGate = "RA51_ExtractionGate",
	UpgradeStation = "RA51_UpgradeStation",
	Boundary = "RA51_Boundary",
}

-- Attribute names placed on world objects.
GameConfig.Attributes = {
	PlotIndex = "PlotIndex",
	SlotIndex = "SlotIndex",
	RegionId = "RegionId",
	SiteId = "SiteId",
	SpawnTier = "SpawnTier",
}

return GameConfig
