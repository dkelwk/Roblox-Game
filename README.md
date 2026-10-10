# RAID AREA 51

An alien extraction, creature collection and lab-building game for Roblox. Players fly
into alien-infested regions with experimental jetpacks, recover specimen capsules, scan
them in their own laboratory to discover aliens, and display those aliens in containment
chambers that earn credits for upgrades.

This repository is the **clean reboot**. It is the single source of truth for code,
configuration and the world blockout. The Roblox place file is a build output.

> **Never publish a build over the existing live game place.** Publish to a separate
> development place. See [docs/BLUEPRINT.md § Environments](docs/BLUEPRINT.md#11-environments-and-reboot-safety).

## Quick start

```sh
rokit install                 # installs the pinned toolchain from rokit.toml
lune run scripts/build        # builds build/RaidArea51.rbxl (code + generated world)
```

Open `build/RaidArea51.rbxl` in Roblox Studio, or live-sync into a development place with
`rojo serve` and the Rojo Studio plugin. Run `lune run scripts/build` first so the
generated world exists. Full macOS steps, including connecting Claude Code to Studio's MCP
server, are in [docs/STUDIO_SETUP.md](docs/STUDIO_SETUP.md). The first-run checklist is
[docs/STUDIO_VERIFICATION.md](docs/STUDIO_VERIFICATION.md).

## Checks

```sh
lune run scripts/check        # format, lint, strict types, build and every spec
lune run scripts/test         # build + specs only  (add --no-build to reuse the last build)
lune run scripts/audit        # part/collision/rendering report for the built world
```

## Previews

```sh
lune run scripts/export-preview
blender -b -P tools/preview/render_world.py              # world blockout shots
blender -b -P blender/scripts/build_specimen_capsule.py  # pilot asset: FBX + preview
```

`python <script>` also works with the `bpy` wheel (`pip install bpy==5.2.2`, Python 3.13).
Rendered previews are in [docs/previews](docs/previews).

## Layout

| Path | Studio location | Contents |
|---|---|---|
| `src/shared` | `ReplicatedStorage.Shared` | Config modules, network contracts, validator, utilities |
| `src/server` | `ServerScriptService.Server` | Server entry point and services |
| `src/client` | `StarterPlayerScripts.Client` | Client entry point and controllers |
| `src/tooling` | `ServerStorage.Tooling` | World blockout generator |
| `assets/generated` | `Workspace.World` | Generated world (build output, not committed) |
| `blender/` | — | Asset scripts, `.blend` sources, FBX exports |
| `tests/` | — | Specs run by Lune against the built place |
| `scripts/` | — | Build, test, check and preview scripts (Lune) |
| `docs/` | — | Blueprint, Phase 0 report, asset manifest, previews |

## Documents

- [Implementation blueprint](docs/BLUEPRINT.md): architecture, world layout, milestones, workflows, test strategy, decisions
- [Art direction](docs/ART_DIRECTION.md): the stylized low-poly rules every asset follows
- [Studio setup](docs/STUDIO_SETUP.md) and [first Studio verification](docs/STUDIO_VERIFICATION.md)
- [Blockout audit](docs/BLOCKOUT_AUDIT.md): measured world composition and what becomes Blender meshes
- [Phase 0 report](docs/PHASE0_REPORT.md): what was inspected, built, tested and what remains
- [Asset manifest](docs/ASSET_MANIFEST.md): every planned and produced asset and its status
