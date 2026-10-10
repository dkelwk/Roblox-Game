"""
Specimen Capsule — the item players recover in extraction regions and carry home.

Pilot asset for the Blender pipeline (pending art approval). Readable at a distance on a
phone: a chunky glass tube with rounded steel caps, a glowing mystery specimen inside, and a
handle on top so it reads as "pick me up".

    blender -b -P blender/scripts/build_specimen_capsule.py
    # or: python blender/scripts/build_specimen_capsule.py   (bpy wheel)

Outputs blender/export/SpecimenCapsule.fbx, blender/source/SpecimenCapsule.blend and
docs/previews/SpecimenCapsule.jpg. Origin: geometric center (it is carried and floats in the
scanner). Height ≈ 2.8 studs.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import ra51_pipeline as pipeline  # noqa: E402

ASSET = "SpecimenCapsule"
TIER = "prop"


def build():
    pipeline.reset_scene()
    coll = pipeline.collection(ASSET)

    # Rounded steel end caps
    pipeline.cylinder(coll, "BaseCap", "SmoothPlastic", "Steel", 0.86, 0.5, (0, 0, 0.25), vertices=20, bevel=0.14)
    pipeline.cylinder(coll, "TopCap", "SmoothPlastic", "Steel", 0.86, 0.46, (0, 0, 2.43), vertices=20, bevel=0.14)
    # Dark trim bands where glass meets steel
    pipeline.cylinder(coll, "BaseBand", "SmoothPlastic", "Floor", 0.8, 0.12, (0, 0, 0.56), vertices=20)
    pipeline.cylinder(coll, "TopBand", "SmoothPlastic", "Floor", 0.8, 0.12, (0, 0, 2.14), vertices=20)
    # Glass tube
    pipeline.cylinder(coll, "Tube", "Glass", "Glass", 0.7, 1.5, (0, 0, 1.35), vertices=24)
    # Three protective struts
    for index in range(3):
        angle = math.radians(index * 120 + 30)
        location = (math.cos(angle) * 0.78, math.sin(angle) * 0.78, 1.35)
        pipeline.cylinder(coll, f"Strut{index + 1}", "SmoothPlastic", "FacilityCream", 0.075, 1.62, location, vertices=8)
    # The mystery specimen glow
    pipeline.sphere(coll, "Specimen", "Neon", "Mint", 0.38, (0, 0, 1.35), segments=12, rings=8)
    # Energy ring on the base cap — swapped to the region's accent color at runtime
    pipeline.torus(coll, "EnergyRing", "Neon", "Cyan", 0.86, 0.05, (0, 0, 0.42))
    # Carry handle
    pipeline.torus(
        coll, "Handle", "SmoothPlastic", "FacilityCream", 0.36, 0.08, (0, 0, 2.7), rotation=(math.pi / 2, 0, 0), major_segments=14
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
