# Passe 3 — preuves du 2026-08-12

**HISTORIQUE.** Ce dossier est daté ; il décrit un état, pas une intention. La
source de vérité vivante reste `docs/STATUS.md`.

Contexte : le gate visuel indépendant de Codex sur l'état `2c4fbf9` est
**ÉCHEC** (tests 832/0 et preuves acceptés, objectif visuel non atteint).
Cette passe reprend depuis ce commit, sur la branche
`claude/vslice-pass3-silhouettes`, et traite EXCLUSIVEMENT les six défauts
relevés — lots B à E, jamais le lot F, ni le donjon, ni le reste de la carte,
ni l'UI.

Moteur : Godot **4.7.1-stable** officiel (`a13da4feb`).
Rendu des captures : `xvfb` + **llvmpipe logiciel**, 1920×1080, 40 frames —
régression visuelle uniquement, jamais une mesure de performance.

---

## Le tableau demandé : défaut → cause réelle → test rouge → correctif → APRÈS

| # | Défaut (revue Codex) | Cause réelle mesurée | Test rouge d'abord | Correctif | APRÈS |
|---|---|---|---|---|---|
| 5 | La moitié gauche de la caméra 5 est un coin gris | `GateCamera_NorthRoad` posée à 2,6 m à l'EST de `RuinWall03` (sommet 0,9 m au-dessus de l'œil) — depuis sa création. Sonde d'emprise muette (AABB fine) ; **picking par rayon** puis repeinture magenta ont tranché | `test_no_gate_camera_has_a_static_wall_against_its_lens` — RuinWall03 touché à 2,1-3,0 m sur 4 colonnes | œil décalé à x = +4 (mur le plus proche > 7 m, route au tiers gauche) | `apres_cam5_nuage/05` |
| 5 | Proxy du nuage : arche grise lisse au sommet de la caméra 6, couronne de spire transperçant le ventre | grumeaux de 27-41 m de rayon, ventre à y 103-105 (spire y 100) | `test_storm_cloud_hangs_above_the_spire.gd` — 3 propriétés, toutes rouges | 22 grumeaux ≤ 22 m, plancher à y ≥ 108, bord chaud côté soleil. **Régression attrapée à la recapture** : l'enclume élargie relisait « soucoupe » depuis la crête — mon test ne comptait que `CloudLayer*`, élargi à toute sphère `Cloud*` (rouge : 47,6 m), enclume remplacée par un anneau de 9 galettes | `apres_nuage_v2/01` et `/06` |
| 1 | Masses rectangulaires dominantes de la citadelle | Keep 34×46×28, épaules, tours, spire, contreforts : `BoxMesh` nus, arêtes verticales parfaites | `test_citadel_masses_wear_battered_cladding.gd` — 4 méthodes rouges | habillage taluté SANS collision : piliers d'angle battus (Keep), coques (épaules), manchons (tours), troncs de pyramide (spire, contreforts). Les porteurs gardent leurs cotes, aucun ne pivote (PT-D1-09) | `apres_citadelle/06` |
| 2 | Chemin en plaques rectangulaires, coutures, bandes | tronçons/épaulements/langues = `PlaneMesh` (rectangles) ; pièces voisines coplanaires au millimètre | `test_paths_belong_to_the_ground.gd` durci — **110 échecs de forme** | `_ground_patch_mesh` : polygones irréguliers 7-9 sommets ; étagement anti-couture 4 mm. **Piège attrapé à la recapture** : enroulement anti-horaire → chemin INVISIBLE, tests verts (leçon ISS-018) — inversé et consigné | `apres_chemins/02` et `/05` |
| 4 | Camp sans triangle repos/cuisine/garde | groupe garde étalé sur 15 m, côté cuisine-garde 7,5 m, 1 tente au repos, 1 bannière, tonneaux au centre | `test_camp_composes_three_activity_poles.gd` — 5 échecs mesurés | tentes regroupées au REPOS (NO), réserve à l'ancien coin de tente (CUISINE), enclume/râtelier/charrette/2 bannières au seuil sud (GARDE), vide central ≥ 4,5 m | `apres_camp/03` |
| 6 | Mesas orange, répétitions triangulaires | gamme `_rock_material` culminant à 0,68 de rouge (~90 % rendu) ; 3 faces × 6 dents au même rythme ; Gorge du Vent à l'albédo peint brut | méthode ajoutée à `test_mesas_wear_talus.gd` — 5 échecs (0 strate, rangs 6/6/6) | gamme roche −⅓ désaturée (terrain + gorge + arêtes) ; rangs 4/7/6 avec dent sautée ; 2 strates horizontales par face + 4 sur le plateau | `apres_mesas/06` — **la caméra 6 passe CONFORME §1.5 pour la première fois** (sol_p95 100 → 87,5) |
| 3 | Corridor plat, grandes surfaces uniformes | ISS-045 : 815/1024 sondages sur deux dalles ; le remodelage n'a pas de filet | `test_plains_carry_flanking_relief.gd` — 3 contrats rouges | 10 buttes convexes MARCHABLES en flanc de route (`_dome_mesh`, collision = visuel), navmesh re-cuites, parcours physiques rejoués (1/0, 2/0). Le filet anti-enterrement a attrapé **3 vraies fautes** de placement (ronde de pillard, ingrédient, coffre) avant livraison | `apres_relief/05` |

Chaque correctif a son commit thématique ; chaque dossier `apres_*` porte
manifestes JSON (commit, `repo_dirty: false`), vignettes 320×180, niveaux de
gris et mesures §1.5.

## Limites honnêtes de la mesure §1.5

`check_value_bands.py` est calibré sur le cadrage North Star (ciel dans les
30 % du haut). Depuis la passe 3, le bandeau haut de la **caméra 5** est
rempli par le nuage, la citadelle et les montagnes — son verdict `VIOLATION`
appartient à la même famille non pertinente que la caméra 6 historique et il
est reporté tel quel, jamais retiré. La caméra 6, elle, est passée
`conforme` après la désaturation de la roche.

## Ce que cette passe NE prétend PAS

1. **Le gate visuel n'est pas déclaré vert.** L'état est prêt pour une
   seconde revue indépendante de Codex ; le verdict d'image lui appartient.
2. **Score North Star : NON VÉRIFIÉ** — aucune note auto-attribuée.
3. ISS-045 (remodelage des dalles), la couture crête/bordure, la monture en
   primitives, le lot F (Options 720p) restent OUVERTS et documentés.
4. Caméra, son, manette, fluidité : non vérifiables dans ce conteneur
   (headless, sans GPU ni périphérique).

## Sprint artistique (même journée, après la passe 3)

Mode sprint demandé par le propriétaire : boucle rapide, validation
complète unique. Cinq transformations, jeu final : `sprint_final/`.

1. prairie MultiMesh du corridor (camp, plaine sud, gué, plaine nord) ;
2. cols d'horizon — la couture crête/bordure ne se découpe plus sur le ciel ;
3. berges du gué habitées (roseaux, pierres du kit CC0) ;
4. toits des abris bois/bronze (le rouge méditerranéen juré avec le monde) ;
5. monture « coureur des steppes » : Blender→glb original (3 412 tris,
   script déterministe versionné), collision et gameplay inchangés.

## Comment rejouer

```bash
export GODOT_BIN=/usr/local/bin/godot
tools/capture_vslice_gate.sh --out-dir=/tmp/verif          # les six caméras
godot --headless --path . --script tools/godot/test_runner.gd  # suite complète
godot --headless --path . --script tools/godot/debug_paint_suspects.gd -- \
    --camera=GateCamera_NorthRoad --pick=300,300           # picking par rayon
```
