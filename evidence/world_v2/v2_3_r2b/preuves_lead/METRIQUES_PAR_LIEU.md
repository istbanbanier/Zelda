# Métriques par lieu — V2.3-A.R2B (intégration lead)

Mesures relevées par les instruments des trois voies (sonde `probe_kit_seating`,
sonde temporaire agent A archivée dans `../camps/sonde_mesures.txt`,
`tools/gltf_inspect.py`, `tools/check_value_bands.py`). Rendu logiciel llvmpipe :
aucune de ces valeurs n'est une mesure de performance.

Plafonds de référence : `docs/WORLD_V2_POI_CONTRACTS.md` §4
(camp ≤ 45 modules, ≤ 90 nœuds visuels, ≤ 24 collisions).

| Lieu | Modules | Meshes visuels | Colliders | Triangles (~) | Écarts consignés |
|---|---:|---:|---:|---:|---|
| Camp du checkpoint | 34 | 47 | 5 | 30 711 | dans les plafonds |
| Camp braise (`ember_raider_camps.01`) | 54 | 82 | 11 | 46 833 | **modules +9 au-dessus du plafond 45** — dépassement ACCEPTÉ par le lead (voir ci-dessous) |
| Ferme abandonnée | modules kit + 1 GLB original | — | boîtes Godot sur murs existants | 676 (SM_Farm_Ruins, budget verrouillé avant modélisation) | aucun |
| Arbre foudroyé | 1 GLB original + habillage kit | — | boîte Godot tronc | 977 (SM_ThunderstruckTree, générateur refuse hauteur hors [10;12]) | aucun |
| Bassin conducteur | ≥ 12 modules kit asservis (`MIN_DRESSING_MESHES=12` testé) | — | kit | — | bandes de valeur margelle : baseline p90 = 89 % → final p50 = 49,4 % / p90 = 66,3 % (cible p50 ∈ [35;65], p90 ≤ 70) |

## Dépassement accepté — camp braise

- 54 modules contre 45 au plafond de contrat, ~46 833 tris contre un budget
  indicatif +8k du plan : dépassement consigné par l'agent A dans sa sonde,
  accepté par le lead à l'intégration.
- Justification : le total (46 833 tris pour le POI entier) reste très en
  dessous des budgets frame de MASTER_SPEC §20.2 ; la silhouette verticale
  (tour de guet) était le signal mesuré manquant à 94 m ; l'enceinte complète,
  le guet et le butin étaient nommés par le plan approuvé.
- Postes dominants identifiés par le manifeste : DeadTree_1 (6 169 tris),
  DeadTree_2 (6 557 tris), Chain_Coil (3 744 tris — candidat n°1 à la coupe si
  le budget prime un jour).

## Provenance des chiffres

- Camps : `../camps/sonde_mesures.txt` (arbre 309773a, sonde supprimée après
  archivage ; l'instrument durable est `tools/godot/probe_kit_seating.gd`).
- Ferme/arbre : `../ferme_arbre/pipeline/architecture_*_inspect.log`
  (`tools/gltf_inspect.py`, triangles épinglés).
- Bassin : `../bassin/bandes_valeur.log` (jeton FIN NOMINALE) et
  `../bassin/verts/probe_kit_seating_12_modules.log`.
