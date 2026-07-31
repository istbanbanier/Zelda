# RÈGLES D'IMPORT ET CONVENTIONS D'ASSETS

Source : MASTER_SPEC §7.15. Ces règles sont vérifiées automatiquement par
`tools/gltf_inspect.py` autant que possible, et par l'import Godot ensuite.

## Chaîne obligatoire

```
source_assets/blender/**.blend   (source, hors res://)
        │  tools/blender/export_gltf.py   preset explicite, options vérifiées par RNA
        ▼
assets/**/*.glb                  (échange, versionné)
        │  tools/gltf_inspect.py          validation hors moteur
        │  godot --headless --import      validation moteur
        ▼
res://  ressources importées      (jamais éditer .godot/imported à la main)
```

## Unités et orientation

- Blender en **unités métriques**, `scale_length = 1.0`.
- **1 unité Godot = 1 m.** Y vertical côté Godot ; l'export force `export_yup=True`.
- Bas de l'objet au sol : **min Y ≈ 0** dans le `.glb`. Vérifié automatiquement ;
  un écart > 1 cm lève un avertissement.
- Rotation et échelle **appliquées** avant export, sans détruire les besoins du rig.
- Pivot intentionnel, jamais laissé au centre par défaut sans raison.

## Nommage

| Préfixe | Usage |
|---|---|
| `SM_` | mesh statique |
| `SK_` | mesh skinné |
| `MAT_` | matériau |
| `T_` | texture |
| `AN_` | animation |
| `COL_` | collision |
| `SOCKET_` | point d'attache |

Suffixes de LOD : `_LOD0` … `_LOD3`.

## Contenu exportable

- Une collection exportable par asset.
- **Aucune caméra, lumière ou helper** exporté par accident — l'export les désactive
  explicitement (`export_cameras=False`, `export_lights=False`) et l'inspecteur
  **échoue** si une caméra ou `KHR_lights_punctual` apparaît dans le `.glb`.
- UV0 propre obligatoire ; UV1/UV2 si lightmap requise ; densité texel documentée.
- Normales personnalisées et tangentes exportées.
- Moins de slots matériaux possible ; atlas et trimsheets pour l'architecture répétée.
- Armature propre, poids normalisés, noms d'os stables.
- Animations nommées ; durée, fps, loop et root motion documentés ; **aucune action
  de test exportée** dans un asset de production.
- Aucune texture au chemin absolu, aucun fichier dépendant d'un chemin privé.

## Vérifications automatiques actuelles

`tools/gltf_inspect.py` contrôle : en-tête GLB et cohérence des chunks · version
glTF · comptages meshes/matériaux/textures/nœuds/skins/animations · triangles ·
présence de POSITION, NORMAL, TEXCOORD_0, JOINTS_0 · bounding box, dimensions et
position du sol · absence de caméra/lumière · canaux d'animation non vides.

Codes retour : `0` valide · `1` invalide.

## Vérifications encore manuelles

Boucle d'animation sans saut, déformations extrêmes, qualité de skinning, densité
texel réelle, cohérence des atlas, absence de ressource rose après import Godot,
scène d'aperçu LOD0/1/2 + collision + skeleton. À automatiser dès qu'un moteur est
disponible en continu.

## Interdits

- Modifier à la main le cache `.godot/imported/`.
- Faire dépendre un livrable de l'import `.blend` direct (dépendance de poste).
- Introduire un asset dans le build avant son inscription dans `ATTRIBUTIONS.md`.
