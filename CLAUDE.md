# RAID AREA 51 — guidance for Claude sessions

Stylized low-poly alien extraction and collection game for Roblox, built as a Rojo project.
**Read [docs/HANDOFF.md](docs/HANDOFF.md) first.** It has the current state, rules, quirks and
next task.

## Current status

- Phase 0 is approved. **Phase 1 has not started.** Don't begin it until
  [docs/STUDIO_VERIFICATION.md](docs/STUDIO_VERIFICATION.md) passes and the creative
  director approves.

## Rules

- **Never open, modify or publish over the original live game.** Work only in the "RAID AREA
  51 [DEV]" place. MCP clients can change any open place.
- **The repo is the source of truth.** Studio is for inspection and testing. Make every
  change in repo files: Rojo syncs repo → Studio only, and Studio-side edits are lost.
- **`Workspace.World` is generated** by `src/tooling/WorldBlockout` from
  `src/shared/Config/WorldLayout.luau`. Change those, then run `lune run scripts/build`.
- **All numbers live in config modules** (`src/shared/Config`). The server is authoritative;
  clients send intents only.
- **Every asset follows [docs/ART_DIRECTION.md](docs/ART_DIRECTION.md)** (stylized low-poly).
  Blender assets are scripted in `blender/scripts/`.
- **Before committing,** `lune run scripts/check` must end with `✓ All checks passed`. Run
  StyLua twice if formatting reports a diff.
- **Report honestly:** say what was verified in Studio, what only offline, and what is
  untested.
- **Lune 0.10.5's `CFrame.lookAt` is buggy.** The test runtime replaces it
  (`scripts/lib/Runtime.luau`). Never compensate for it in game code.

## Commands

```sh
lune run scripts/build            # build/RaidArea51.rbxl (code + generated world)
lune run scripts/check            # format, lint, strict types, build, all specs
lune run scripts/test [--no-build] [filter]
lune run scripts/audit            # world composition report
rojo serve                        # live-sync into the open dev place
```

## In Studio (command bar or MCP `execute_luau`, Edit mode)

```lua
require(game.ServerStorage.Tooling.InspectionShots).frame("spawn-view")  -- .list() for all shots
require(game.ServerStorage.Tooling.StudioAudit).run()
require(game.ServerStorage.Tooling.AssetBinder).bind(workspace.SpecimenCapsule)
```
