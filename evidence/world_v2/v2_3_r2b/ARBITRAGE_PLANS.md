# V2.3-A.R2B — arbitrage des trois plans (lead, 2026-08-19)

Les trois plans sont reçus, fondés sur des captures réellement ouvertes et
des modules vérifiés au manifeste. Tous trois sont APPROUVÉS avec les
décisions suivantes. Base d'implémentation : le SHA publié avec le
checkpoint GM4 (worktrees créés par le lead à ce moment-là).

## Décisions transverses

1. **Fichiers de tests** : les contrôles négatifs de chaque agent vivent
   dans un fichier NEUF à son nom — `test_world_v2_r2b_camps.gd` (A),
   `test_world_v2_r2b_farm_tree.gd` (B), `test_world_v2_r2b_basin.gd` (C)
   — sous tests/world_v2/. Personne ne touche les tests communs existants ;
   le lead relit et intègre. Écrits ROUGES d'abord, rouge archivé.
2. **ASSET_MANIFEST.csv** : AUCUN agent n'y touche (fichier partagé). Les
   lignes à ajouter (A : Roof_Log, Floor_WoodDark_Half1 ; B : ses GLB
   originaux) sont LISTÉES dans les rapports ; le lead les ajoute à
   l'intégration, avant tout commit de géométrie (règle assets.md).
3. **export_architecture.sh** : seul B en a besoin (sujets farm/arbre) ;
   il est le SEUL autorisé à l'éditer dans son worktree ; intégration lead.
4. **Outils de mesure** : un agent peut créer ses instruments sous tools/
   (pas de gameplay, pas de framework) ; `check_value_bands.py` cité par C
   n'existe pas encore — C l'écrit et le livre avec son couloir.
5. **Golden masters** : réutiliser un GLB gelé en LECTURE (B : socle
   SM_Village_Wall) est autorisé ; le modifier, jamais. Preuve
   avant/après par sha256 des quatre GLB, faite par le lead à l'intégration.

## Agent A — camps (APPROUVÉ)

- (a) Pas de nouveau module Blender pour A : poteaux `Corner_Exterior_Wood`,
  pieux par `Prop_WoodenFence_Single` charbon penchés + rubble + chicots
  `DeadTree` réduits — comme proposé.
- (b) **Fumée : les 6 boîtes translucides sont SUPPRIMÉES sans
  remplacement** dans cette passe. Une vraie fumée (VFX) est hors budget
  R2B ; l'identité de la halte se lit par toit, bannières, wagon, feu
  allumé. Jugé en A/B aux caméras mi-distance.
- (c) `CampfireProp` (scripts/world/props/) est HORS périmètre R2B : le
  camp-checkpoint garde le feu canonique tel quel (le filet l'épingle) ;
  dette visuelle consignée au rapport final. Le braise n'en pose aucun.
- Vigilances tenues : cam02_camp_pylone (perp < 1,5 m avec la VRAIE
  demi-emprise des toits), 4 couloirs de route en AABB monde, secteur
  203-244° du braise inchangé.

## Agent B — ferme + arbre (APPROUVÉ)

- Voie Blender accordée : `SM_Farm_Truss`, `SM_Farm_RoofPan_Intact/Fallen`,
  `SM_Farm_Debris_A/B`, `SM_ThunderstruckTree` — générateurs sous
  source_assets/blender/, garde-fous du pipeline R2a (jeton de fraîcheur,
  --python-exit-code 1, gltf_inspect, budgets annoncés AVANT modélisation :
  ferme ≤ 4 500 tris, arbre ≤ 6 000).
- `_scorched_ground` : EXEMPTION accordée (mesh épousant le terrain, même
  pratique que rock_floor_mesh) — l'exemption est NOMMÉE dans son contrôle
  négatif, pas silencieuse.
- Le piège `Floor_Brick` pivot centré est consigné : poser par
  probe_kit_seating, jamais à l'œil.

## Agent C — bassin (APPROUVÉ)

- Lampes : **option B retenue** — remplacer le MESH de Socle/Fût seulement,
  Noyau + matériau + lambda power_changed intacts, dans
  conductive_basin_place.gd uniquement.
- Cyan ajouté : zéro — confirmé comme exigence, pas une préférence.
- L'anneau `DoorFrame_Round_Brick` semi-enterré : oui, avec Δsol sous
  empreinte ≤ 0,07 m sinon module 1 m.

## Rappels communs

Aucun agent ne pousse ; commits locaux propres dans son worktree ;
flock pour tout godot/blender ; pgrep -f/pkill interdits (deux incidents
cette session : le garde de validate_fast attrapé par la CHAÎNE
test_runner.gd dans la ligne de commande d'un shell parent, puis dans les
greps des agents de plan — ne mettez jamais cette chaîne dans une commande
pendant qu'une validation tourne). Verdict artistique : lead/Codex/Istvan,
jamais auto-déclaré.
