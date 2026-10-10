"""
RAID AREA 51 — shared Blender pipeline helpers.

Every asset script imports this module so all assets share one scale, palette, naming
convention, triangle budget and export setup.

Conventions
-----------
* 1 Blender unit = 1 Roblox stud. Import FBX into Roblox with Scale Unit = Stud.
* Model with Z up and the asset's front facing -Y. Export converts to Roblox's Y-up/-Z-forward.
* Asset origin: bottom-center for props that sit on the ground, geometric center for
  carried/floating items. Documented per asset in docs/ASSET_MANIFEST.md.
* One mesh object per Roblox material + palette color, named
      <Part>__<RobloxMaterial>__<PaletteToken>      e.g. Body__SmoothPlastic__Steel
  Roblox colors MeshParts from the palette at bind time, so stylized assets need no
  textures and stay consistent with Palette.luau.
* Palette colors are read from src/shared/Config/Palette.luau, the single source of truth.
* Stylized low-poly (docs/ART_DIRECTION.md): radial segment counts come from
  `radial_segments(radius)` so density is consistent across assets; hard surfaces are flat
  shaded with one-segment chamfers; only organic forms use smooth shading; no subdivision.

Runs under `blender -b -P <script>` or the `bpy` wheel (`python <script>`).
"""

import math
import os
import re

import bpy  # must load before bmesh/mathutils when running from the bpy wheel

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
PALETTE_SOURCE = os.path.join(ROOT, "src", "shared", "Config", "Palette.luau")
EXPORT_DIR = os.path.join(ROOT, "blender", "export")
SOURCE_DIR = os.path.join(ROOT, "blender", "source")
PREVIEW_DIR = os.path.join(ROOT, "docs", "previews")

# Triangle ceilings per asset tier for the low-poly style, sized for mid-range phones.
# Exceeding one fails the build. Raise only with on-device measurements.
TRIANGLE_BUDGETS = {
    "hero": 4000,  # scanner station, lab shell, gate
    "creature": 2000,  # each alien
    "prop": 800,  # capsule, consoles, chambers
    "scatter": 250,  # rocks, plants, crates: repeated in bulk
}

SMOOTH_ANGLE = math.radians(35)


def radial_segments(radius):
    """Sides for a curved surface of this radius (studs). One table keeps density consistent."""
    if radius < 0.25:
        return 6
    if radius < 1.0:
        return 8
    if radius < 3.0:
        return 12
    if radius < 8.0:
        return 16
    return 24

ROBLOX_MATERIALS = {"SmoothPlastic", "Glass", "Neon", "Metal", "Sand", "Sandstone"}


def load_palette():
    """Parse Palette.luau into {token: (r, g, b)} in linear 0..1 space."""
    with open(PALETTE_SOURCE, encoding="utf-8") as handle:
        source = handle.read()
    core = dict(re.findall(r'(\w+) = "#([0-9A-Fa-f]{6})"', source))
    tokens = {}
    for name, value in re.findall(r"(\w+) = hex\(([^)]*)\)", source):
        literal = re.match(r'"#([0-9A-Fa-f]{6})"', value)
        reference = re.match(r"Palette\.CoreHex\.(\w+)", value)
        hex_value = literal.group(1) if literal else core.get(reference.group(1)) if reference else None
        if hex_value:
            tokens.setdefault(name, hex_value)
    for name, hex_value in core.items():
        tokens.setdefault(name, hex_value)
    return {name: _hex_to_linear(value) for name, value in tokens.items()}


def _srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _hex_to_linear(value):
    return tuple(_srgb_to_linear(int(value[i : i + 2], 16) / 255) for i in (0, 2, 4))


PALETTE = load_palette()


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0


def material(roblox_material, token):
    """A preview material matching how Roblox will render this part (color from the palette)."""
    if roblox_material not in ROBLOX_MATERIALS:
        raise ValueError(f"Unsupported Roblox material {roblox_material}")
    if token not in PALETTE:
        raise ValueError(f"Unknown palette token {token}; add it to Palette.luau first")
    name = f"{roblox_material}__{token}"
    existing = bpy.data.materials.get(name)
    if existing:
        return existing
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    color = (*PALETTE[token], 1.0)
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = {"Glass": 0.05, "Metal": 0.3, "Neon": 0.5}.get(roblox_material, 0.45)
    if roblox_material == "Metal":
        bsdf.inputs["Metallic"].default_value = 0.8
    if roblox_material == "Glass":
        bsdf.inputs["Alpha"].default_value = 0.35
    if roblox_material == "Neon":
        bsdf.inputs["Emission Color"].default_value = color
        bsdf.inputs["Emission Strength"].default_value = 3.0
    return mat


def collection(name):
    coll = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(coll)
    return coll


def _finish(obj, coll, part, roblox_material, token, bevel, shading):
    """Name, color and file the object. shading: "flat" (hard surface) or "smooth" (organic)."""
    if shading not in ("flat", "smooth"):
        raise ValueError(f"shading must be 'flat' or 'smooth', got {shading}")
    obj.name = f"{part}__{roblox_material}__{token}"
    obj.data.materials.append(material(roblox_material, token))
    for c in obj.users_collection:
        c.objects.unlink(obj)
    coll.objects.link(obj)
    if bevel > 0:
        # A single-segment chamfer: catches light on edges without adding curvature.
        modifier = obj.modifiers.new("Bevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = 1
        modifier.limit_method = "ANGLE"
    obj["ra51_shading"] = shading
    return obj


def cylinder(
    coll, part, roblox_material, token, radius, depth, location, sides=None, bevel=0.0, capped=True, shading="flat"
):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=sides or radial_segments(radius),
        radius=radius,
        depth=depth,
        location=location,
        end_fill_type="NGON" if capped else "NOTHING",
    )
    return _finish(bpy.context.active_object, coll, part, roblox_material, token, bevel, shading)


def box(coll, part, roblox_material, token, size, location, bevel=0.0, shading="flat"):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.active_object
    obj.scale = size
    bpy.ops.object.transform_apply(scale=True)
    return _finish(obj, coll, part, roblox_material, token, bevel, shading)


def icosphere(coll, part, roblox_material, token, radius, location, subdivisions=2, shading="flat"):
    """Faceted sphere; subdivisions=2 is 80 triangles, the default for small rounded forms."""
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, radius=radius, location=location)
    return _finish(bpy.context.active_object, coll, part, roblox_material, token, 0, shading)


def torus(
    coll,
    part,
    roblox_material,
    token,
    major,
    minor,
    location,
    rotation=(0, 0, 0),
    major_segments=None,
    minor_segments=4,
    shading="flat",
):
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major,
        minor_radius=minor,
        major_segments=major_segments or radial_segments(major),
        minor_segments=minor_segments,
        location=location,
        rotation=rotation,
    )
    return _finish(bpy.context.active_object, coll, part, roblox_material, token, 0, shading)


def finalize(coll, origin=(0, 0, 0)):
    """Apply modifiers and transforms, and put every object's origin at the asset origin."""
    bpy.context.scene.cursor.location = origin
    for obj in coll.objects:
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        for modifier in list(obj.modifiers):
            bpy.ops.object.modifier_apply(modifier=modifier.name)
        # Flat: every face its own normal (faceted). Smooth: soft, but edges sharper than
        # SMOOTH_ANGLE stay crisp. Exported as FBX normals.
        smooth = obj.get("ra51_shading") == "smooth"
        for poly in obj.data.polygons:
            poly.use_smooth = smooth
        if smooth:
            obj.data.set_sharp_from_angle(angle=SMOOTH_ANGLE)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
        obj.select_set(False)


def triangle_count(coll):
    total = 0
    for obj in coll.objects:
        mesh = obj.data
        mesh.calc_loop_triangles()
        total += len(mesh.loop_triangles)
    return total


def bounds(coll):
    xs, ys, zs = [], [], []
    for obj in coll.objects:
        for v in obj.data.vertices:
            world = obj.matrix_world @ v.co
            xs.append(world.x)
            ys.append(world.y)
            zs.append(world.z)
    return (min(xs), min(ys), min(zs)), (max(xs), max(ys), max(zs))


def check_budget(coll, tier):
    triangles = triangle_count(coll)
    budget = TRIANGLE_BUDGETS[tier]
    if triangles > budget:
        raise RuntimeError(f"{coll.name}: {triangles} triangles exceeds the {tier} budget of {budget}")
    return triangles


def export(coll, asset_name):
    """Save the .blend source and export an FBX for the Roblox 3D Importer."""
    os.makedirs(EXPORT_DIR, exist_ok=True)
    os.makedirs(SOURCE_DIR, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in coll.objects:
        obj.select_set(True)
    fbx_path = os.path.join(EXPORT_DIR, f"{asset_name}.fbx")
    bpy.ops.export_scene.fbx(
        filepath=fbx_path,
        use_selection=True,
        object_types={"MESH"},
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_UNITS",
        axis_forward="-Z",
        axis_up="Y",
        mesh_smooth_type="FACE",
        use_mesh_modifiers=True,
        add_leaf_bones=False,
        bake_anim=False,
    )
    blend_path = os.path.join(SOURCE_DIR, f"{asset_name}.blend")
    bpy.context.preferences.filepaths.save_version = 0  # no .blend1 backups in the repo
    bpy.ops.wm.save_as_mainfile(filepath=blend_path, compress=True)
    return fbx_path, blend_path


def verify_fbx(fbx_path, coll):
    """Re-import the FBX into a clean scene and confirm names and dimensions survived export.

    Checks the export is self-consistent (scale, axes, object split). The Roblox 3D Importer
    must still be checked once in Studio with Scale Unit = Stud.
    """
    expected_names = sorted(obj.name for obj in coll.objects)
    (ax, ay, az), (bx, by, bz) = bounds(coll)
    expected = (bx - ax, by - ay, bz - az)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=fbx_path, axis_forward="-Z", axis_up="Y")
    imported = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    names = sorted(obj.name for obj in imported)
    if names != expected_names:
        raise RuntimeError(f"FBX object names changed on export: {names} != {expected_names}")
    xs, ys, zs = [], [], []
    for obj in imported:
        for v in obj.data.vertices:
            world = obj.matrix_world @ v.co
            xs.append(world.x)
            ys.append(world.y)
            zs.append(world.z)
    actual = (max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs))
    if any(abs(a - e) > 1e-3 for a, e in zip(actual, expected)):
        raise RuntimeError(f"FBX dimensions changed on export: {actual} != {expected}")
    return actual


def render_preview(coll, asset_name, distance=6.0, height=0.45, samples=32):
    """Three-quarter studio render for art review, saved to docs/previews/<asset>.jpg."""
    scene = bpy.context.scene
    (min_x, min_y, min_z), (max_x, max_y, max_z) = bounds(coll)
    center = ((min_x + max_x) / 2, (min_y + max_y) / 2, (min_z + max_z) / 2)
    size = max(max_x - min_x, max_y - min_y, max_z - min_z)

    world = bpy.data.worlds.new("Studio")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (*PALETTE["Blue"], 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.6

    for name, energy, rotation in (("Key", 3.5, (50, 0, -40)), ("Rim", 2.0, (60, 0, 150))):
        light = bpy.data.objects.new(name, bpy.data.lights.new(name, "SUN"))
        light.data.energy = energy
        light.rotation_euler = tuple(math.radians(a) for a in rotation)
        scene.collection.objects.link(light)

    camera = bpy.data.objects.new("PreviewCamera", bpy.data.cameras.new("PreviewCamera"))
    scene.collection.objects.link(camera)
    scene.camera = camera
    from mathutils import Vector

    target = Vector(center)
    eye = target + Vector((distance * size * 0.55, -distance * size * 0.75, distance * size * height))
    camera.location = eye
    camera.rotation_euler = (target - eye).to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 50

    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = 900, 900
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "AgX"
    os.makedirs(PREVIEW_DIR, exist_ok=True)
    path = os.path.join(PREVIEW_DIR, f"{asset_name}.jpg")
    scene.render.image_settings.file_format = "JPEG"
    scene.render.image_settings.quality = 88
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path
