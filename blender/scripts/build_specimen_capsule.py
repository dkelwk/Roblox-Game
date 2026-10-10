"""
Specimen Capsule — the item players recover in extraction regions and carry home.

v0.2: stylized low-poly rebuild (pending art approval). Readable at a distance on a phone:
an octagonal glass tube between chunky chamfered steel caps, a faceted glowing specimen
inside, an energy ring at the base and a carry handle on top so it reads as "pick me up".
v0.1 (smooth, 1,376 triangles) is superseded; see docs/ASSET_MANIFEST.md for the comparison.

    blender -b -P blender/scripts/build_specimen_capsule.py
    # or: python blender/scripts/build_specimen_capsule.py   (bpy wheel)

Outputs blender/export/SpecimenCapsule.fbx, blender/source/SpecimenCapsule.blend and
docs/previews/SpecimenCapsule.jpg. Origin: geometric center (it is carried and floats in the
scanner). Height ≈ 3 studs.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import ra51_pipeline as pipeline  # noqa: E402

ASSET = "SpecimenCapsule"
TIER = "prop"
SIDES = 8  # octagonal silhouette shared by caps, bands and glass


def build():
    pipeline.reset_scene()
    coll = pipeline.collection(ASSET)

    # Chamfered octagonal steel caps
    pipeline.cylinder(coll, "BaseCap", "SmoothPlastic", "Steel", 0.88, 0.5, (0, 0, 0.25), sides=SIDES, bevel=0.12)
    pipeline.cylinder(coll, "TopCap", "SmoothPlastic", "Steel", 0.88, 0.46, (0, 0, 2.43), sides=SIDES, bevel=0.12)
    # Dark trim bands where glass meets steel
    pipeline.cylinder(coll, "BaseBand", "SmoothPlastic", "Floor", 0.8, 0.12, (0, 0, 0.56), sides=SIDES)
    pipeline.cylinder(coll, "TopBand", "SmoothPlastic", "Floor", 0.8, 0.12, (0, 0, 2.14), sides=SIDES)
    # Faceted glass tube (open ends are hidden inside the bands)
    pipeline.cylinder(coll, "Tube", "Glass", "Glass", 0.72, 1.5, (0, 0, 1.35), sides=SIDES, capped=False)
    # Three square protective struts on the octagon's corners
    for index in range(3):
        angle = math.radians(index * 120 + 22.5)
        location = (math.cos(angle) * 0.8, math.sin(angle) * 0.8, 1.35)
        pipeline.cylinder(
            coll, f"Strut{index + 1}", "SmoothPlastic", "FacilityCream", 0.09, 1.62, location, sides=4, capped=False
        )
    # The mystery specimen: a faceted glowing gem
    pipeline.icosphere(coll, "Specimen", "Neon", "Mint", 0.42, (0, 0, 1.35))
    # Energy ring on the base cap — swapped to the region's accent color at runtime
    pipeline.torus(coll, "EnergyRing", "Neon", "Cyan", 0.9, 0.06, (0, 0, 0.42), major_segments=SIDES)
    # Carry handle
    pipeline.torus(
        coll,
        "Handle",
        "SmoothPlastic",
        "FacilityCream",
        0.36,
        0.09,
        (0, 0, 2.7),
        rotation=(math.pi / 2, 0, 0),
        major_segments=SIDES,
    )

    pipeline.finalize(coll, origin=(0, 0, 1.35))
    return coll


def main():
    coll = build()
    triangles = pipeline.check_budget(coll, TIER)
    (min_x, min_y, min_z), (max_x, max_y, max_z) = pipeline.bounds(coll)
    fbx_path, blend_path = pipeline.export(coll, ASSET)
    preview = pipeline.render_preview(coll, ASSET, distance=1.9)
    pipeline.verify_fbx(fbx_path, coll)
    print(f"{ASSET}: {triangles} triangles (budget {pipeline.TRIANGLE_BUDGETS[TIER]})")
    print(f"bounds: {max_x - min_x:.2f} x {max_y - min_y:.2f} x {max_z - min_z:.2f} studs (X x Y x Z-up)")
    print(f"exported {os.path.relpath(fbx_path, pipeline.ROOT)}")
    print(f"source   {os.path.relpath(blend_path, pipeline.ROOT)}")
    print(f"preview  {os.path.relpath(preview, pipeline.ROOT)}")
    print("FBX round-trip: names and dimensions verified")


if __name__ == "__main__":
    main()
