# Blockout Audit — Phase 0 World

Offline numbers come from `lune run scripts/audit` (the same report
`require(game.ServerStorage.Tooling.StudioAudit).run()` prints in Studio). **Rendering cost
has not been measured yet.** Every performance decision below is either a style decision
that doesn't depend on measurement, or is marked *measure first* and waits for Studio numbers
(Scene Analysis and MicroProfiler).

## Measured offline (build of 2026-10-10)

| Metric | Value | Note |
|---|---|---|
| Parts | 1,711 | District 801 (114 per lab), desert 901, boundaries 8, base 1 |
| By shape | Block 899, Cylinder 626, Ball 174, Wedge 11, Truss 1 | |
| **Rounded primitives** (Ball + Cylinder) | **800 (47%)** | Render smooth: clashes with low-poly |
| CanCollide | 1,570 | |
| Small collidables (< 4 studs) | 375 | Fences 69, plants 62, trail markers 54, chamber plates 48, light posts 40, guide lights 22, consoles 16 |
| CanTouch / CanQuery | 1,601 / 1,601 | Static scenery with touch events on |
| Shadow casters | 1,467 | |
| Transparent parts | 160 | Crystal shards 59, chamber tubes 48, windows/skylights 30 |
| Neon parts | 187 (10.9%) | Chamber rings 48, trail reflectors 27, nest eggs 27, guide lights 22, lamps 20 |
| Material+color combinations | 34 | |
| Lights / emitters / SurfaceGuis | 10 / 4 / 82 | SurfaceGuis: 48 are chamber "EMPTY" plates |
| Streaming | 6 Atomic plots, 6 Persistent landmarks | |

### Repeated groups (modular-mesh candidates)

| Group | Instances | Parts each | Total |
|---|---|---|---|
| Plot (whole lab) | 6 | 114 | 684 |
| Chamber | 48 | 6 | 288 |
| RockCluster | 42 | 5.7 | 239 |
| SecurityFence | 8 | 20.2 | 162 |
| DesertPlant | 26 | 4.4 | 114 |
| CrystalCluster | 12 | 5.9 | 71 |
| Scanner | 6 | 11 | 66 |
| LightPost | 20 | 3 | 60 |
| TrailMarker | 27 | 2 | 54 |
| AlienNest | 9 | 5 | 45 |
| CrateStack | 9 | 4 | 36 |

## Findings and recommendations

### 1. Rounded primitives conflict with the low-poly direction (decide now)

Roblox Ball and Cylinder parts render as smooth, high-resolution rounds. Nearly half the
world uses them, mostly in chambers (192), fence posts (138), plants (114), light posts (60),
nests (45) and scanners (42). These become faceted Blender meshes in Phase 5. This is a style
requirement, so it doesn't wait on performance numbers.

### 2. Modular Blender kit (order by impact)

Chamber → Scanner → Lab shell → RockCluster set (3–5 variants) → DesertPlant set →
SecurityFence segment → LightPost → TrailMarker → AlienNest → CrystalCluster → CrateStack →
dunes (3 low-poly variants).

**How many MeshParts per asset** is an open, measurable question:

- **A. One MeshPart per material + color** (current convention, `AssetBinder`). Colors stay
  tied to the palette and are tintable at runtime. The chamber would still be about 5
  MeshParts.
- **B. Palette texture atlas.** One MeshPart per opaque asset, colored by UVs into a tiny
  palette texture. Glass and Neon stay separate. Fewer instances and likely fewer draw
  calls; recoloring needs a re-export.

**Measure first:** build the chamber both ways and compare draw calls and frame time at the
`lab-interior` shot.

### 3. Collision (safe to apply, verify in play)

- **Decoration:** set CanCollide, CanQuery and CanTouch to false on decorative parts
  smaller than 4 studs: plant tufts, reflectors, lamp heads, chamber plates, guide lights.
  Where players must not walk through (fences, crystals, consoles), keep a single invisible
  box collider.
- **CanTouch:** set false on all static scenery. Nothing in the world needs `Touched` events;
  gameplay uses ProximityPrompts and server distance checks.
- **MeshPart fidelity:** Box for small props, Hull for rocks. Never
  PreciseConvexDecomposition on scatter.

### 4. Transparency and overdraw (measure first)

- **Crystal shards** (59 parts at transparency 0.15) should become opaque faceted meshes
  with an emissive core. That is better for the style and removes most transparent parts.
- **Lab interior:** the `lab-interior` view stacks windows, eight chamber tubes and the
  skylight. Measure frame time there on the Mobile device emulator and a real phone.

### 5. Neon with meaning (decide now, apply with the chamber mesh)

Empty chambers shouldn't glow. Their rings stay dark until an alien is placed, which saves
about 48 Neon parts in an empty lab and turns the glow into gameplay feedback. Trail
reflectors (27) and nest eggs (27) stay as wayfinding and alien cues.

### 6. SurfaceGuis (measure first)

The 48 chamber plates reading "EMPTY" are mostly redundant. Plan to show labels only on
occupied chambers in the owner's lab or within proximity, and keep landmark signs.

### 7. Keep as native Roblox geometry

These are flat planes that already fit low-poly and are the cheapest representation:

- ground plates, paving, road, sidewalks;
- district walls, plain slabs, the boundaries;
- invisible markers.

The mesa may stay as stepped native blocks if the faceted kit doesn't improve it
noticeably; compare in Studio.

### 8. Materials (decide in Studio)

Sand and Sandstone textures add grain. Compare them with SmoothPlastic in the `nest-ridge`
and `desert-entrance` shots and pick one look for all terrain-like surfaces.

## Specimen Capsule triangle evaluation

| Version | Triangles | Notes |
|---|---|---|
| v0.1 (smooth) | 1,376 | 20–28-sided cylinders, smooth spheres, multi-segment bevels |
| **v0.2 (low-poly)** | **488 (−65%)** | Octagonal caps, bands and glass; one-segment chamfers; icosphere specimen; open hidden ends |

v0.2 keeps every readable feature (caps, bands, glass, struts, glowing specimen, energy
ring, handle) with a stronger faceted silhouette that matches the art direction. The budget
check enforces the new prop ceiling of 800. See `docs/previews/SpecimenCapsule-comparison.jpg`.

## Studio measurement plan (first session)

For each shot (`InspectionShots.frame(id)`), with Studio graphics quality set to Automatic:

1. Scene Analysis → Triangle composition: record triangles and draw calls (opaque /
   transparent / shadows).
2. Device emulator (a mid-range phone preset): Performance Stats, recording CPU and GPU ms.
3. MicroProfiler (⌘⌥F6) on the `lab-interior` and `desert-entrance` shots.

Record results in `docs/STUDIO_VERIFICATION.md` § Results. Optimizations marked *measure
first* are applied only after these numbers exist.
