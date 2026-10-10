# First Studio Verification

This is the first time the reboot runs in the real engine. Work through it in order; it takes
about 30–45 minutes. Run it in the **development** place only (see
[STUDIO_SETUP.md](STUDIO_SETUP.md)). With Claude Code + Studio MCP (workflow A), Claude can run
every step and capture the screenshots itself.

Phase 1 starts once sections 1–2 pass and sections 3–7 show no blocking problems.

## 1. Structure

In the Explorer, confirm:

```
ReplicatedStorage.Shared        Config (7 modules), Network.NetworkDefinitions, ConfigValidator, Util.ModuleLoader
ServerScriptService.Server      Main (Script), Services (empty folder)
ServerStorage.Tooling           WorldBlockout, InspectionShots, StudioAudit, AssetBinder
StarterPlayer.StarterPlayerScripts.Client   Main (LocalScript), Controllers (empty)
Workspace.World                 BaseSand, Boundaries, LabDistrict (Plots: Plot1–Plot6), DesertRegion
Lighting                        Atmosphere, Bloom, ColorGrade, SunRays (Technology: ShadowMap)
```

## 2. Runs cleanly

Press **Play** (F5). Pass criteria:

- Output shows `[RA51] Server v0.1.0 running 0 services`.
- **No red errors or yellow warnings** from our scripts. Copy any that appear.
- The character spawns on the cyan pad in the plaza. That is expected for now: lab
  spawning is Phase 1, step 1.

## 3. Audit numbers

In **Edit** mode, run in the command bar:

```lua
require(game.ServerStorage.Tooling.StudioAudit).run()
```

Copy the whole output. It should match the offline numbers in
[BLOCKOUT_AUDIT.md](BLOCKOUT_AUDIT.md) (1,711 parts). It also tries to print Scene Analysis
triangle and draw-call data. If it says that is unavailable, open **Window → Performance
Summary → Scene Analysis → Triangle composition** during Play instead.

## 4. Inspection shots

In **Edit** mode, frame each shot from the command bar and take a screenshot:

```lua
local Shots = require(game.ServerStorage.Tooling.InspectionShots)
Shots.frame("spawn-view")   -- repeat with each id below; Shots.list() prints them all
```

| # | Shot id | Check |
|---|---|---|
| 1 | `spawn-view` | You can tell where you are, and the gate down the road is visible as the objective. Lab scale feels right against a character (drop one in with Play). |
| 2 | `gate` + `desert-entrance` | Gate reads **EXTRACTION ZONE** from the district side. Curtain is see-through. Trail, signpost and the three landmarks are readable. Skyline frames the view. |
| 3 | `lab` | Lab silhouette, accent color, oversized entrance, windows and skylight, and the **VACANT LAB** sign facing the road. |
| 4 | `lab-interior` | Scanner is the centerpiece. All 8 chambers are visible with walking room. Not too dark, not overly teal. |
| 5 | `nest-ridge` | **Ramp rises toward the mesa top.** If it's a cliff facing the trail, the wedge orientation assumption is wrong. Report it, and it's a one-line fix. |
| 6 | `capsule` | After section 6: capsule scale, colors and hover position at the scanner. |

The `crash-crater`, `outpost` and `overview` shots are optional extras. Compare each
screenshot with the Blender preview of the same name in `docs/previews/`. Note anything that
differs in lighting, color or legibility.

## 5. Walk the route (Play)

1. Walk from the plaza through the gate to the junction and time it. It's 438 studs, so
   expect about 27 s at the default walk speed of 16. From a lab spawn (Phase 1) it will be
   15–25 s.
2. Walk through the curtain (it must not block you). Walls, fences and chamber glass must
   block you.
3. Walk up the Nest Ridge ramp to the mesa top.
4. Climb the Outpost comms tower truss.
5. Note anything you snag on: small props, plants, trail markers.

The saucer-top and spire-top secret spawns need the jetpack (Phase 2), so they're
unreachable on foot for now. That is expected.

## 6. Import the Specimen Capsule

1. **Avatar/Home → Import 3D** → select `blender/export/SpecimenCapsule.fbx`.
2. In the importer, set **File Dimensions → Scale Unit = Stud** (1 Blender unit = 1 stud).
   Keep the parts as separate MeshParts, then **Insert**.
3. Command bar:

   ```lua
   local capsule = workspace.SpecimenCapsule  -- or whatever the importer named it
   print(require(game.ServerStorage.Tooling.AssetBinder).bind(capsule), "parts bound")
   capsule:PivotTo(workspace.World.LabDistrict.Plots.Plot1.Markers.ScannerAnchor.CFrame)
   require(game.ServerStorage.Tooling.InspectionShots).frame("capsule")
   ```

4. **Pass:**
   - 11 parts bound;
   - about 1.9 × 3.2 × 1.9 studs;
   - upright, handle on top;
   - hovering just above the scanner seat;
   - faceted (flat-shaded) look preserved;
   - glass see-through.

## 7. Mobile check

1. **Test → Device emulator:** a small phone in landscape (for example iPhone SE) and one
   notched phone.
2. Repeat shots 1, 2 and 4. Check sign legibility, and that nothing important sits under the
   jump/thumbstick zones.
3. **Performance Stats** (⌘⌥F7): note CPU and GPU frame times on `lab-interior` and
   `desert-entrance`.
4. Optional, but the most valuable: publish the dev place and play it on a real phone.

## Results

Fill this in (or paste screenshots and output into chat).

| Item | Result | Notes |
|---|---|---|
| 1. Structure | ☐ pass ☐ fail | |
| 2. Play: Output clean | ☐ pass ☐ fail | |
| 3. Audit / Scene Analysis | triangles: ___ draw calls: ___ | |
| 4.1 spawn-view | | |
| 4.2 gate / desert-entrance | | |
| 4.3 lab | | |
| 4.4 lab-interior | | |
| 4.5 nest-ridge ramp | ☐ rises ☐ cliff | |
| 4.6 capsule | | |
| 5. Route walk | plaza→junction ___ s | |
| 6. Capsule import | scale ☐ ok, colors ☐ ok, shading ☐ ok | |
| 7. Mobile | CPU ___ ms / GPU ___ ms | |
