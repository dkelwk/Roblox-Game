# Art Direction — Stylized Low-Poly

RAID AREA 51 uses one consistent look for every model, environment, interaction, UI
component and effect: **polished stylized low-poly science fiction**. Low-poly means
deliberate, efficient and finished, never unfinished.

## Pillars

1. **Intentional silhouettes.** Every object reads as a recognizable shape at phone distance.
   Test it as a black silhouette at 64 px.
2. **Clean, simplified forms.** Chunky proportions, few large planes, rounded forms built from
   deliberate facets (octagons, not 64-gons).
3. **Flat + smooth shading.** Hard surfaces are flat-shaded and faceted. Organic forms are
   smooth-shaded (alien bodies, domes, plants).
4. **Colorful materials.** Palette colors only. Bright, warm desert under a friendly sky;
   facilities in cream and steel; accents in cyan, mint and orange.
5. **Glow is an accent.** Neon marks energy, interaction and rarity. It is never a surface
   finish.

**Avoid:** hyperrealism, sculpted detail, subdivision surfaces, mixed geometry density,
generic Roblox block buildings, Toolbox assets, and large neon surfaces.

## Geometry rules

**Radial density.** Every curved surface uses `ra51_pipeline.radial_segments(radius)`, so
density is identical across assets:

| Radius (studs) | Sides |
|---|---|
| < 0.25 | 6 |
| 0.25 – 1 | 8 |
| 1 – 3 | 12 |
| 3 – 8 | 16 |
| ≥ 8 | 24 |

- **Spheres:** icosphere with 2 subdivisions (80 triangles) for small rounded parts. 3
  subdivisions only for hero rounds.
- **Edges:** one-segment chamfers (about 8–15% of the edge's smaller dimension) on edges
  that catch light. No multi-segment fillets.
- **Topology:** no subdivision modifiers and no hidden interior geometry. Leave ends open
  where they are covered (glass tubes inside bands, struts inside caps).
- **Triangle ceilings** (`TRIANGLE_BUDGETS`; the build fails above them):
  - hero: 4,000 (scanner station, lab shell, gate)
  - creature: 2,000 (each alien)
  - prop: 800 (capsule, consoles, chambers)
  - scatter: 250 (rocks, plants, crates)
- **Scale:** 1 Blender unit = 1 stud. Characters are about 5 studs tall, and doorways,
  steps and props are sized against that.

## Shading

| Surface | Shading |
|---|---|
| Architecture, machinery, props, rocks, crystals, crates | **Flat** (faceted) |
| Alien bodies, glass domes, plants, soft organic shapes | **Smooth**, with edges sharper than 35° kept crisp |
| Mixed assets | Per part. Example: Glorp's smooth jelly body with flat fins. |

## Materials and color

- **Palette tokens only** (`src/shared/Config/Palette.luau`). Exported meshes are named
  `<Part>__<RobloxMaterial>__<PaletteToken>`, and `AssetBinder` applies the color in Studio.
  No textures by default.
- **Roblox materials:**
  - **SmoothPlastic:** the default.
  - **Glass:** windows, chambers and domes only. It causes overdraw on phones, so use it
    sparingly.
  - **Neon:** accents only.
  - **Sand / Sandstone:** under review. Their textures add grain that may fight the clean
    look; decide in Studio whether to switch to SmoothPlastic.
- **Neon budget:** about 10% of visible parts in any view at most. Neon should mean
  something: an energy source, an interactable, an occupied chamber or a rarity.
- **Accent colors:** each player lab has one accent (`Palette.PlotAccents`). Rare purple and
  Epic gold are reserved for rarity presentation.

## Native Roblox geometry vs Blender meshes

| Use native parts | Use Blender MeshParts |
|---|---|
| Ground plates, roads, sidewalks, paving, plain walls, boundaries: flat planes that already fit low-poly | Anything rounded: Roblox Ball/Cylinder primitives render smooth and high-resolution, which clashes with the faceted style |
| Invisible markers, colliders and trigger volumes | Signature objects: scanner, chambers, gate, lab shell, saucer, mesa, rocks, crystals, plants, nests, dunes |
| Rapid blockouts before art approval | Anything repeated many times (modular kit pieces) |

Smooth voxel Terrain is not used because it conflicts with the faceted style.

## Aliens

- Cartoon proportions: big head or eyes, simple limbs, **one signature feature** each (Glorp's
  fins, Zib's single eye, Voltix's antennae, Craggle's crystals, Nebula's orbiting stars).
- Smooth bodies with flat accessories. Readable silhouettes. Expressive idle presets
  (`AlienDefinitions.idleStyle`).
- **Appearance never encodes rarity.** Zib is purple and Common. Rarity lives only in UI
  frames, badges, lighting and discovery VFX.

## VFX

- **Runtime:** Roblox particles, beams, trails, lights and tweens, played through
  `VFXController` presets.
- **Shapes:** low-poly effect meshes (faceted scan rings, shard bursts) and crisp, simple
  sprite shapes (diamonds, triangles, soft circles) made in Blender. No photographic smoke.
- **Light:** short, bright and readable. No full-screen flashes; quality tiers scale
  particle counts.

## UI

- Premium futuristic terminal: deep navy panels, cyan accents, Builder Sans.
- Chamfered or angled corner accents echo the chamfered geometry.
- Icons and alien portraits are flat-lit renders of the actual low-poly assets, so UI and
  world match.
- Rarity frames and badges carry the rarity colors. Body colors never do.

## Review checklist (every asset)

1. Silhouette reads at 64 px.
2. Density follows the radial table.
3. Chamfers are single-segment.
4. Shading is flat or smooth per the table.
5. Palette tokens only.
6. Under the triangle ceiling.
7. FBX round-trip passes.
8. Preview approved.
9. Imported and bound in Studio.
10. In-engine screenshot compared with the Blender preview.

**Reference:** `blender/scripts/build_specimen_capsule.py` (v0.2) is the first asset built to
these rules. See `docs/previews/SpecimenCapsule-comparison.jpg`.
