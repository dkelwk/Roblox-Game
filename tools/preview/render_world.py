"""
Render preview shots of the generated world blockout in Blender.

    lune run scripts/build && lune run scripts/export-preview
    blender -b -P tools/preview/render_world.py -- [--samples 24] [--shots overview,lab]
    # or, with the bpy wheel:  python tools/preview/render_world.py -- ...

Rebuilds every visible part from build/preview/world.json (Roblox Y-up space converted to
Blender Z-up), applies approximate materials and lighting, and renders the InspectionShots
camera views (src/tooling/InspectionShots.luau, the same shots used in Studio) to
build/preview/<shot>.png.

These renders validate layout, silhouette, palette and readability. They are NOT a substitute
for checking lighting, materials and VFX in Roblox Studio.
"""

import argparse
import json
import math
import os
import sys

import bpy  # must load before bmesh/mathutils when running from the bpy wheel
import bmesh
from mathutils import Matrix, Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
PREVIEW_DIR = os.path.join(ROOT, "build", "preview")

def roblox_to_blender(v):
    x, y, z = v
    return Vector((x, -z, y))


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def hex_to_linear(hex_value):
    rgb = [int(hex_value[i : i + 2], 16) / 255 for i in (0, 2, 4)]
    return [srgb_to_linear(c) for c in rgb] + [1.0]


def local_vertices(shape, sx, sy, sz):
    """Vertices and faces of a Roblox primitive in its local (Y-up) space."""
    hx, hy, hz = sx / 2, sy / 2, sz / 2
    if shape == "Ball":
        r = sx / 2
        verts, faces, rings, segs = [], [], 10, 18
        for i in range(rings + 1):
            phi = math.pi * i / rings
            for j in range(segs):
                theta = 2 * math.pi * j / segs
                verts.append((r * math.sin(phi) * math.cos(theta), r * math.cos(phi), r * math.sin(phi) * math.sin(theta)))
        for i in range(rings):
            for j in range(segs):
                a, b = i * segs + j, i * segs + (j + 1) % segs
                faces.append((a, b, b + segs, a + segs))
        return verts, faces
    if shape == "Cylinder":
        r, segs = min(sy, sz) / 2, 28
        verts = []
        for x in (-hx, hx):
            for j in range(segs):
                t = 2 * math.pi * j / segs
                verts.append((x, r * math.cos(t), r * math.sin(t)))
        faces = [tuple(range(segs))[::-1], tuple(range(segs, 2 * segs))]
        for j in range(segs):
            k = (j + 1) % segs
            faces.append((j, k, segs + k, segs + j))
        return verts, faces
    if shape == "Wedge":
        # Roblox wedge: vertical face at +Z (back), slope descending to the bottom-front edge.
        verts = [(-hx, -hy, -hz), (hx, -hy, -hz), (hx, -hy, hz), (-hx, -hy, hz), (-hx, hy, hz), (hx, hy, hz)]
        faces = [(0, 1, 2, 3), (3, 2, 5, 4), (0, 4, 5, 1), (0, 3, 4), (1, 5, 2)]
        return verts, faces
    verts = [(x, y, z) for x in (-hx, hx) for y in (-hy, hy) for z in (-hz, hz)]
    faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    return verts, faces


def material_for(cache, color_hex, roblox_material, transparency):
    key = (color_hex, roblox_material, round(transparency, 2))
    if key in cache:
        return cache[key]
    mat = bpy.data.materials.new(f"{roblox_material}_{color_hex}_{key[2]}")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    color = hex_to_linear(color_hex)
    bsdf.inputs["Base Color"].default_value = color
    roughness = {"Sand": 0.95, "Sandstone": 0.85, "Glass": 0.05}.get(roblox_material, 0.45)
    bsdf.inputs["Roughness"].default_value = roughness
    if roblox_material == "Neon":
        bsdf.inputs["Emission Color"].default_value = color
        bsdf.inputs["Emission Strength"].default_value = 4.0
    if transparency > 0:
        bsdf.inputs["Alpha"].default_value = max(0.08, 1 - transparency)
    cache[key] = mat
    return mat


def build_scene(parts):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    meshes = {}
    material_cache = {}
    for part in parts:
        mat = material_for(material_cache, part["color"], part["material"], part["transparency"])
        bm = meshes.setdefault(mat.name, (bmesh.new(), mat))[0]
        c = part["cframe"]
        position = Vector(c[0:3])
        rotation = Matrix(((c[3], c[4], c[5]), (c[6], c[7], c[8]), (c[9], c[10], c[11])))
        verts, faces = local_vertices(part["shape"], *part["size"])
        created = [bm.verts.new(roblox_to_blender(position + rotation @ Vector(v))) for v in verts]
        for face in faces:
            try:
                bm.faces.new([created[i] for i in face])
            except ValueError:
                pass
    for name, (bm, mat) in meshes.items():
        mesh = bpy.data.meshes.new(name)
        bm.normal_update()
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(mesh)
        bm.free()
        mesh.materials.append(mat)
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.scene.collection.objects.link(obj)


def setup_lighting():
    scene = bpy.context.scene
    world = bpy.data.worlds.new("Sky")
    scene.world = world
    world.use_nodes = True
    background = world.node_tree.nodes["Background"]
    background.inputs["Color"].default_value = (0.55, 0.72, 0.92, 1.0)
    background.inputs["Strength"].default_value = 0.9
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 4.0
    sun.data.angle = math.radians(3)
    sun.data.color = (1.0, 0.95, 0.86)
    sun.rotation_euler = (math.radians(38), 0, math.radians(-35))
    scene.collection.objects.link(sun)


def render(shots, samples, only):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = 1280, 720
    scene.view_settings.view_transform = "AgX"
    camera = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera.data.clip_end = 6000
    for shot in shots:
        if only and shot["id"] not in only:
            continue
        eye, look = roblox_to_blender(shot["eye"]), roblox_to_blender(shot["target"])
        camera.location = eye
        camera.rotation_euler = (look - eye).to_track_quat("-Z", "Y").to_euler()
        if shot.get("orthographicSize"):
            camera.data.type = "ORTHO"
            camera.data.ortho_scale = shot["orthographicSize"]
        else:
            # Match Roblox: fieldOfView is the vertical angle.
            camera.data.type = "PERSP"
            camera.data.sensor_fit = "VERTICAL"
            camera.data.angle_y = math.radians(shot["fieldOfView"])
        scene.render.filepath = os.path.join(PREVIEW_DIR, f"{shot['id']}.png")
        bpy.ops.render.render(write_still=True)
        print(f"Rendered {scene.render.filepath}")


def main():
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--samples", type=int, default=24)
    parser.add_argument("--shots", default="", help="comma-separated shot ids (default: all)")
    args = parser.parse_args(argv)
    with open(os.path.join(PREVIEW_DIR, "world.json")) as handle:
        data = json.load(handle)
    build_scene(data["parts"])
    setup_lighting()
    render(data["shots"], args.samples, {s for s in args.shots.split(",") if s})


if __name__ == "__main__":
    main()
