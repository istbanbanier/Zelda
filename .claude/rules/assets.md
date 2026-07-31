---
description: Règles d'assets 3D et d'import — appliquer à assets/**, source_assets/** et tools/blender/**
globs: ["assets/**", "source_assets/**", "tools/blender/**"]
---

# Assets — règles obligatoires

Base : MASTER_SPEC §7.15 et `docs/assets/IMPORT_RULES.md` (référence complète).

## Avant d'ajouter un asset

1. Vérifier son origine et sa licence. **Aucune ressource sans licence claire
   n'entre dans le build.**
2. L'inscrire dans `ATTRIBUTIONS.md` (source, auteur, licence, modifications)
   **avant** de l'ajouter, pas après.
3. L'inscrire dans `docs/assets/ASSET_MANIFEST.csv`.

## Chaîne obligatoire

`source_assets/**.blend` → `tools/blender/export_gltf.py` → `assets/**.glb` →
`tools/gltf_inspect.py` → import Godot headless.

Un `.glb` qui n'a pas passé `gltf_inspect.py` **et** l'import Godot n'est pas validé.

## Conventions dures

- 1 unité Godot = 1 m ; unités métriques côté Blender ; Y vertical.
- Bas de l'objet au sol : **min Y ≈ 0**.
- Rotation et échelle appliquées avant export.
- Préfixes `SM_` `SK_` `MAT_` `T_` `AN_` `COL_` `SOCKET_`, suffixes `_LOD0..3`.
- Aucune caméra ni lumière exportée par accident — l'inspecteur échoue si présent.
- Budgets de triangles et de textures : voir `docs/ART_BIBLE.md` §5.

## Interdits absolus

- Employer l'image de référence North Star comme skybox, matte painting, billboard
  ou texture de décor. Elle est une référence de cadrage, jamais un asset.
- Copier un contenu appartenant à Nintendo ou à une autre œuvre : personnage,
  costume, silhouette, modèle, texture, rig, animation, carte, salle, interface,
  symbole, musique, son ou dialogue.
- Modifier à la main le cache `.godot/imported/`.
- Présenter une image générée hors moteur comme une capture du moteur. Les images
  générées sont autorisées comme concept ou moodboard, jamais comme preuve.
- Appeler `final` un modèle gris, un rig provisoire ou une animation générique mal
  retargetée.
