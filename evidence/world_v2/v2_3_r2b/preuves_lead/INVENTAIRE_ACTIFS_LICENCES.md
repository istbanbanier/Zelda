# Inventaire des actifs et licences — V2.3-A.R2B

Règle appliquée (`.claude/rules/assets.md`) : aucune ressource TÉLÉCHARGÉE
pendant R2B. Toute la peau visible vient soit de modules CC0 déjà présents
dans le dépôt (archive Quaternius inscrite de longue date), soit de meshes
Blender originaux dont le générateur et la source sont committés.

## Voie A — deux camps (aucun actif nouveau, 16 régularisations)

16 lignes ajoutées à `docs/assets/ASSET_MANIFEST.csv` (2026-08-19) : modules
Quaternius CC0 1.0 des kits Medieval Village / Fantasy Props / Stylized Nature
Standard, déjà dans `assets/environment/`, dont l'usage n'avait jamais été
inscrit au manifeste. Fichiers : Corner_Exterior_Wood, Floor_WoodDark,
Roof_Wooden_2x1(_L/_R), Banner_1, Banner_2_Cloth, Prop_Wagon, Stall_Cart_Empty,
Prop_WoodenFence_Single, SM_Dungeon_RubbleLarge/Small, DeadTree_1/2,
Shield_Wooden, Chain_Coil. Chaque ligne consigne le piège d'assise mesuré
(pivots non standard) par `probe_kit_seating`.

## Voie B — deux œuvres originales (2 actifs nouveaux)

| Actif | Fichier | Tris | Source reproductible | Licence |
|---|---|---:|---|---|
| SM_Farm_Ruins | `assets/architecture/farm/SM_Farm_Ruins.glb` (sha256 9654ba79…) | 676 | `source_assets/blender/architecture/make_farm_ruins.py` + `.blend` committé, export via `tools/blender/export_architecture.sh` | licence projet (œuvre originale) |
| SM_ThunderstruckTree | `assets/architecture/flora/SM_ThunderstruckTree.glb` (sha256 ff582648…) | 977 | `source_assets/blender/environment/make_thunderstruck_tree.py` + `.blend` committé, même chaîne d'export | licence projet (œuvre originale) |

Les deux sont passés par `tools/gltf_inspect.py` puis l'import Godot headless
(journal `../ferme_arbre/pipeline/`). Dette consignée par l'agent B : UV0
minimalistes sur les deux GLB (matériaux plats, pas de textures) — acceptable
pour le style, à revoir si une texture est un jour appliquée.

## Voie C — bassin conducteur (zéro actif nouveau)

Habillage entièrement en modules kit DÉJÀ inscrits : RockPath_* (margelle
appareillée), SM_Dungeon_ArchBlock / PillarStub / Rubble* (arche et ruine),
DoorFrame_Round_Brick, Wall_Arch, Prop_Brick1, Prop_ExteriorBorder_Straight1,
Fern_1, Plant_1, Grass_Common_Tall, Chain_Coil. Aucune ligne de manifeste
nécessaire ; la classe, le graphe électrique et l'état fonctionnel du lieu
sont préservés (vérifié par `test_world_v2_r2b_basin.gd`).

## Golden masters — intacts

`sha256sum -c evidence/world_v2/v2_3_r2b/GM_BASELINE_SHA256.txt` : 6/6 OK
après intégration (grotte 5ff4ec6e, fallback 8bf1a1b3, pylône f98fe307,
pont 032e4389, Quay 177205ea, Wall 24f39047).

## Dette héritée constatée (non corrigée ici)

8 lignes préexistantes du manifeste n'ont pas les 19 colonnes du schéma :
Male_Peasant, AL_RaiderStates, Superhero_Male_FullBody, SK_StormGuardian,
AwningTent, ui_back, ui_error, ui_open. Antérieures à R2B ; consignées au
commit d'intégration, pas réparées en silence.
