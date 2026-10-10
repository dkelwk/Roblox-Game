--!strict
--[[
	Palette — the RAID AREA 51 color design system.

	Every color used by world building, UI and VFX must come from here. Never write raw
	Color3 values in gameplay or presentation code. (Per-species alien colors are content
	data and live with each species in AlienDefinitions.)

	`Core` is the creative-direction palette and must not drift from the directive.
	`World` and `UI` are derived tones built for specific jobs; add to them rather than
	inventing one-off colors elsewhere.
]]

local Palette = {}

local function hex(value: string): Color3
	return Color3.fromHex(value)
end

-- Source hex values for Core, kept so tests and docs can verify the palette exactly.
Palette.CoreHex = {
	Navy = "#101A2C", -- Deep UI navy
	Blue = "#243A55", -- Secondary blue
	Cyan = "#3CE8E4", -- Energy cyan
	Mint = "#7BF5B4", -- Alien mint
	Sand = "#F4C98D", -- Warm desert sand
	Cream = "#F5F6F9", -- Facility cream
	Orange = "#FF875B", -- Alert orange
	Purple = "#AC8CFF", -- Rare purple
	Gold = "#FFD76A", -- Epic gold
}

Palette.Core = {
	Navy = hex(Palette.CoreHex.Navy),
	Blue = hex(Palette.CoreHex.Blue),
	Cyan = hex(Palette.CoreHex.Cyan),
	Mint = hex(Palette.CoreHex.Mint),
	Sand = hex(Palette.CoreHex.Sand),
	Cream = hex(Palette.CoreHex.Cream),
	Orange = hex(Palette.CoreHex.Orange),
	Purple = hex(Palette.CoreHex.Purple),
	Gold = hex(Palette.CoreHex.Gold),
}

-- Environment tones. Warm, light, and saturated enough to read on small screens.
Palette.World = {
	-- Desert
	SandLight = hex("#F8D9A8"),
	SandShadow = hex("#E6B276"),
	RockLight = hex("#E39B6A"),
	Rock = hex("#C97B52"),
	RockDark = hex("#9E5C3E"),
	Sage = hex("#8FC48A"),
	SageDark = hex("#5E9A6B"),

	-- Facility
	FacilityCream = hex(Palette.CoreHex.Cream),
	FacilityTrim = hex("#D9E1EC"),
	Steel = hex("#AEBCD0"),
	SteelDark = hex("#6F819C"),
	Floor = hex("#2D4566"),
	Paving = hex("#EADCC4"),
	PavingEdge = hex("#D7C4A4"),
	Road = hex("#34445F"),
	RoadLine = hex(Palette.CoreHex.Cream),
	Glass = hex("#BFF4F2"),

	-- Accents (use sparingly — the world should not drown in glow)
	EnergyCyan = hex(Palette.CoreHex.Cyan),
	AlienMint = hex(Palette.CoreHex.Mint),
	AlertOrange = hex(Palette.CoreHex.Orange),
	HazardNavy = hex(Palette.CoreHex.Navy),
	NestViolet = hex("#7A5BC9"),
	NestShell = hex("#4E3A8A"),

	-- Extra lab accent hues (see PlotAccents)
	AccentSky = hex("#6FB7FF"),
	AccentCoral = hex("#FF7FA8"),
	AccentLime = hex("#C5F06A"),
}

-- One accent per lab plot (trim, entrance glow, sign) so every player's lab is recognizable
-- at a glance. Deliberately avoids the Rare purple and Epic gold, which signal rarity.
Palette.PlotAccents = {
	Palette.Core.Cyan,
	Palette.Core.Orange,
	Palette.World.AccentLime,
	Palette.World.AccentCoral,
	Palette.Core.Mint,
	Palette.World.AccentSky,
}

-- Interface tones. Panels are dark; text and accents are light and high-contrast.
Palette.UI = {
	Panel = hex(Palette.CoreHex.Navy),
	PanelRaised = hex(Palette.CoreHex.Blue),
	Stroke = hex("#3B5679"),
	Text = hex(Palette.CoreHex.Cream),
	TextMuted = hex("#9FB0C8"),
	Accent = hex(Palette.CoreHex.Cyan),
	Positive = hex(Palette.CoreHex.Mint),
	Warning = hex(Palette.CoreHex.Orange),
	Credits = hex(Palette.CoreHex.Gold),
}

return Palette
