# Phase 0 Report — Inspection, Planning and Foundation

Date: 2026-10-10 · Branch: `claude/raid-area-51-roblox-xkij03`

## A. What was inspected

| Target | Finding |
|---|---|
| Roblox Studio connection | **Not available.** This session runs in a cloud container with no Studio/MCP connection, so the existing place could not be opened, inspected, played or screenshotted. |
| Repository `dkelwk/Roblox-Game` | **Empty.** No commits and no branches, so no scripts, models or place files from the prototype. |
| Other repositories | None accessible to this session (checked). |

The prototype features named in the directive (scanner state machine, Glorp, lab bases,
jetpack, collection concept, credits display, UI experiments) **were not available to
inspect**. They remain design references only. Nothing was migrated, and no claim is made
about their quality.

## B. Reuse evaluation

Not possible without access. To evaluate the prototype later, any of these works:

1. Connect a Studio MCP session so the place can be inspected directly.
2. Export the prototype place (`.rbxl`) or selected models/scripts into this repository
   on a separate branch (`prototype-reference`).
3. Paste the scanner, jetpack and Glorp scripts for review.

The evaluation will use the blueprint's rules: server authority, data-driven config,
testable logic, no monolithic scripts. Expect ideas and art to carry over more than code.

## C. Reboot established safely

- The existing game was **not touched** (it was never reachable from this session).
- The reboot is a fresh Rojo project in this repository. It builds a **new** place file,
  `build/RaidArea51.rbxl`, that shares nothing with the live place.
- The [Blueprint § 11](BLUEPRINT.md#11-environments-and-reboot-safety) explains how to
  publish it as a separate development experience and keep DataStore testing isolated.

## D. Implementation blueprint

See [BLUEPRINT.md](BLUEPRINT.md): folder structure, service responsibilities, world
layout, milestone M1, dependency graph, Blender, VFX and UI workflows, test strategy, and
open questions.

## E. What was built

| Item | Repo path | Studio location |
|---|---|---|
| Rojo project and Lighting/Atmosphere setup (ShadowMap, warm desert atmosphere, restrained bloom, `StreamingEnabled`) | `default.project.json` | `Lighting`, `Workspace` |
| Palette design system (directive palette exact, plus world, UI and plot-accent tones) | `src/shared/Config/Palette.luau` | `ReplicatedStorage.Shared.Config.Palette` |
| Game config: version, server size, data store, economy, specimen, scanner state timings, jetpack, onboarding targets, tags, attributes | `src/shared/Config/GameConfig.luau` | `…Config.GameConfig` |
| Rarity tiers (common / rare / epic) | `src/shared/Config/RarityDefinitions.luau` | `…Config.RarityDefinitions` |
| Six alien species with stable ids, income, colors and idle presets | `src/shared/Config/AlienDefinitions.luau` | `…Config.AlienDefinitions` |
| Three upgrades with full level/price tables | `src/shared/Config/UpgradeDefinitions.luau` | `…Config.UpgradeDefinitions` |
| Regions (Lab District hub, Groom Lake Dunes) with spawn odds | `src/shared/Config/RegionDefinitions.luau` | `…Config.RegionDefinitions` |
| World layout (all positions, plots, bounds) | `src/shared/Config/WorldLayout.luau` | `…Config.WorldLayout` |
| Network contract: 9 remotes with arg schemas and rate limits | `src/shared/Network/NetworkDefinitions.luau` | `ReplicatedStorage.Shared.Network` |
| Cross-module config validator | `src/shared/ConfigValidator.luau` | `ReplicatedStorage.Shared.ConfigValidator` |
| Init/Start lifecycle loader | `src/shared/Util/ModuleLoader.luau` | `ReplicatedStorage.Shared.Util` |
| Server entry point (refuses to start on invalid config) | `src/server/Main.server.luau` | `ServerScriptService.Server.Main` |
| Client entry point | `src/client/Main.client.luau` | `StarterPlayerScripts.Client.Main` |
| World blockout generator | `src/tooling/WorldBlockout/` | `ServerStorage.Tooling.WorldBlockout` |
| Generated world | `assets/generated/World.rbxm` (build output) | `Workspace.World` |
| Build, test, check and preview tooling | `scripts/`, `tools/` | — |
| Blender pipeline and pilot asset | `blender/` | not imported yet |

**World blockout contents** (1,711 parts; budget ≤ 3,000):

- **Lab district (801 parts):** paved district, main road with cyan guide lights, plaza
  with fallback spawn and Upgrade Station, Main Facility (hangar, annexes, control tower
  with cyan home beacon, radar dish), and the oversized Extraction Gate with an energy
  curtain.
- **Six labs (114 parts each):** open entrance, windows and skylight, scanner station,
  eight containment chambers, owner sign, per-lab accent color, spawn and scanner markers.
- **Desert region (901 parts):** trail network with markers, signposted junction, truck
  wreck with starter capsules, Crash Crater (saucer, crystals), Research Outpost (damaged
  lab, depot, climbable comms tower, broken checkpoint, fences), Nest Ridge (stepped mesa,
  ramp, nests, crystals, spire), dunes, rocks, plants, boundary ridges, north fence,
  distant Area 51 skyline, and 4 ambient dust emitters.
- **Specimen spawns:** 28 tagged points (6 Starter, 15 Standard, 4 Elevated, 3 Secret).
- **Boundaries:** 8 invisible walls that block players but not cameras.
- **Totals:** 10 point lights, 4 particle emitters; Neon parts are 10.9% of parts (budget
  12%).

**Blender assets created/exported:** `SpecimenCapsule`. The script is
`blender/scripts/build_specimen_capsule.py`, with outputs `blender/export/SpecimenCapsule.fbx`,
`blender/source/SpecimenCapsule.blend` and the preview
[`docs/previews/SpecimenCapsule.jpg`](previews/SpecimenCapsule.jpg). It uses 1,376
triangles (prop budget 1,500).

## F. Tests performed

| Check | Result |
|---|---|
| `stylua --check` (src, scripts, tests) | Pass |
| Selene: game code (Roblox std), specs, Lune scripts | 0 errors, 0 warnings |
| luau-lsp 1.70.1 strict analysis of `src/` with Roblox definitions + Rojo sourcemap | 0 errors (it initially flagged real typing problems in 4 files; all fixed in code, none suppressed) |
| Rojo 7.7.1 build | Pass |
| Lune specs: 51 total | **51 pass** |
| ↳ Config (10) | validator clean, exact directive palette, 6 species/3 rarities, income rises with rarity, honest odds (≥ 70% common, ≤ 5% epic), first upgrade affordable within the 5-minute target (~3m50s), upgrade stat lookup, plot orientation, region bounds |
| ↳ ConfigValidator (15) | each class of broken config is caught with a specific message; no crash on a gutted bundle |
| ↳ Bootstrap (4) | server boots on real config; **refuses** to start on invalid config; Init-before-Start ordering; non-modules ignored |
| ↳ World (22) | plot anchors, chambers, spawn facing and clear walk to road/door; clear route plaza → gate → junction → each site; spawns never buried, always supported, ≥ 6 studs apart; palette-only colors; no default Plastic; size limits; budgets; boundaries; persistent landmarks; generator determinism; no GUI named `Name`/`Size` |
| Harness self-test | A deliberately failing spec makes the runner exit 1 |
| Blender FBX round-trip | Re-imported names and dimensions match |
| Visual review (Blender renders, [docs/previews](previews)) | Inspected 8 world shots + the capsule; issues found and fixed below |

**Issues found by visual review and fixed:**

- Rocks looked like crates; they are now tapered strata stacks with caps and boulders.
- Dunes looked like logs; they are now wide, shallow swells kept clear of the district.
- The mesa was a single box; it now has stepped strata, an overhanging cap and talus.
- The district was too uniformly white; each lab now has an accent color.
- The outpost's collapsed roof read as a ramp; the roof is now split with the front half
  fallen in.
- Coplanar roof end caps would z-fight in Roblox; arched roofs now overhang.
- The gate curtain was too opaque to see through.
- Capsule shading artifacts are fixed with angle-based sharp edges.

## G. What failed or remains unverified

Everything below needs Roblox Studio or a device. None of it has been observed in the engine.

- **Roblox rendering:** real lighting, Atmosphere/Bloom/ColorCorrection values, SurfaceGui
  text legibility (Builder Sans), and Neon intensity. The previews are Blender
  approximations.
- **WedgePart orientation** (mesa ramp, talus, console screens). It follows the standard
  convention (vertical face at +Z, slope descending to −Z) but has not been seen in Studio.
  If the ramp faces the wrong way, flip its yaw in `DesertRegion.buildNestRidge`.
- **Player movement:** walkability of slopes and dunes, jetpack reachability of the secret
  spawns, and real walking time from spawn to the first capsule.
- **Streaming behavior** of Atomic plots and Persistent landmarks on low-memory devices.
- **Client bootstrap** (`Main.client`) was not executed. Lune cannot emulate
  `game.Loaded`/PlayerScripts.
- **FBX import** into Roblox's 3D Importer (scale with Scale Unit = Stud, orientation,
  pivot, split into MeshParts by material).
- **Mobile performance** of the blockout (MicroProfiler on a phone).

## H. Recommended next steps

1. **You:** publish `build/RaidArea51.rbxl` as a new development experience. Walk the
   loop route, check the ramp direction and signage, and send screenshots of the gate view,
   a lab, and Nest Ridge. Or connect a Studio MCP session so I can do this directly.
2. **Creative director:** answer the open questions in
   [Blueprint § 12](BLUEPRINT.md#12-open-questions-for-the-creative-director) and approve
   or redirect the capsule pilot and the lab/district look.
3. **Me:** start Milestone M1, beginning with NetworkService + PlotService, then
   PlayerDataService.
4. **Phase 5 asset order once approved:** ScannerStation → ContainmentChamber → LabShell →
   Glorp, so the core loop's hero objects are upgraded first.
