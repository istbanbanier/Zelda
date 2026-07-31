"""Export Blender -> glTF 2.0 (.glb) en ligne de commande (MASTER_SPEC §7.15).

Le preset d'export est explicite : ne jamais dépendre des valeurs par défaut, qui
changent entre versions de l'exporter. Le script interroge la version installée et
journalise les options réellement acceptées, plutôt que de supposer une signature.

Usage :
    blender --background <fichier.blend> --python tools/blender/export_gltf.py -- \
        --out assets/environment/props/SM_TestCube.glb [--animations]

Sortie : le .glb + un log ligne par ligne sur stdout.
"""

import argparse
import os
import sys

import bpy


def parse_args(argv: list) -> argparse.Namespace:
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []
    parser = argparse.ArgumentParser(prog="export_gltf")
    parser.add_argument("--out", required=True, help="chemin .glb de sortie")
    parser.add_argument("--animations", action="store_true", help="exporter les animations")
    parser.add_argument("--collection", default="", help="n'exporter que cette collection")
    return parser.parse_args(argv)


def build_options(args: argparse.Namespace) -> dict:
    """Preset explicite, filtré sur les options réellement supportées ici."""
    wanted = {
        "filepath": os.path.abspath(args.out),
        "export_format": "GLB",
        "export_yup": True,              # Blender Z-up -> glTF/Godot Y-up
        "export_apply": True,            # applique les modificateurs
        "export_texcoords": True,
        "export_normals": True,
        "export_tangents": True,
        "export_materials": "EXPORT",
        "export_cameras": False,         # §7.15 : aucune caméra/lumière par accident
        "export_lights": False,
        "export_extras": False,
        "export_skins": True,
        "export_animations": bool(args.animations),
        "export_force_sampling": True,
        "export_animation_mode": "ACTIONS",
        "export_optimize_animation_size": False,
        "use_selection": False,
        "use_visible": True,
    }
    if args.collection:
        wanted["use_active_collection"] = True

    # L'exporter refuse les mots-clés inconnus, et les noms d'options changent
    # entre versions : filtrer sur les propriétés RNA réellement déclarées par
    # l'exporter installé, jamais sur une signature supposée.
    supported = set(bpy.ops.export_scene.gltf.get_rna_type().properties.keys())

    accepted, rejected = {}, []
    for key, value in wanted.items():
        if key in supported:
            accepted[key] = value
        else:
            rejected.append(key)
    if rejected:
        print("[export_gltf] options non supportées par cette version, ignorées: %s"
              % ", ".join(sorted(rejected)))
    return accepted


def main() -> int:
    args = parse_args(sys.argv)
    print("[export_gltf] Blender %s" % bpy.app.version_string)

    import addon_utils
    for module in addon_utils.modules():
        if module.__name__ == "io_scene_gltf2":
            info = module.bl_info
            print("[export_gltf] io_scene_gltf2 version %s" % (info.get("version"),))
            break
    addon_utils.enable("io_scene_gltf2", default_set=False, persistent=True)

    if args.collection:
        target = bpy.data.collections.get(args.collection)
        if target is None:
            print("[export_gltf] ERREUR: collection introuvable: %s" % args.collection)
            return 2
        bpy.context.view_layer.active_layer_collection = \
            bpy.context.view_layer.layer_collection.children[args.collection]

    out = os.path.abspath(args.out)
    os.makedirs(os.path.dirname(out), exist_ok=True)

    options = build_options(args)
    print("[export_gltf] preset: %s" % ", ".join("%s=%s" % kv for kv in sorted(options.items())
                                                 if kv[0] != "filepath"))
    bpy.ops.export_scene.gltf(**options)

    if not os.path.isfile(out):
        print("[export_gltf] ERREUR: fichier non produit: %s" % out)
        return 3
    print("[export_gltf] OK -> %s (%d octets)" % (out, os.path.getsize(out)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
