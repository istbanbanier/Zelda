# WORLD V2 — MATRICE DES CONTRATS DE SYSTÈMES

**Statut : VIVANT** · Phase V2.0 · Base V1 : `58d4996` (`claude/full-world-visual-finish`)
Version exécutable de cette matrice : `evidence/world_v2/v2_0/contract_matrix.json`.

Cette matrice répond à la question 1 et 2 de la phase V2.0 : **quels systèmes
sont conservés sans modification, et quels tests portent des hypothèses
spatiales V1**. Elle a été établie par lecture réelle du code (chaque ligne
cite ses fichiers), pas par déduction depuis les documents.

## 0. Statuts autorisés

| Statut | Signification opposable |
|---|---|
| `PROTECTED_UNCHANGED` | consommé par ses interfaces existantes ; **aucune modification** pendant toute la campagne V2 sauf défaut démontré + autorisation |
| `DUAL_WORLD` | conçu pour servir plusieurs mondes (injection, exports par instance, groupe par scène) ; V2 en crée **ses instances**, le code partagé ne bouge pas |
| `V1_SPATIAL_REPLACE` | contenu spatial propre à la V1 ; V2 en construit un équivalent ; la version V1 reste intacte et lançable jusqu'au gate V2.9 |
| `MIGRATION_REQUIRED` | un contrat additif est nécessaire (schéma, routage) ; écrit et testé avant d'être activé |
| `BLOCKED` | inutilisable en l'état pour V2 ; blocage nommé |

Règle de lecture : le statut d'une famille est celui de son élément **le plus
contraignant** ; les sous-lignes précisent.

## 1. La matrice

### 1.1 Systèmes du joueur — tous `PROTECTED_UNCHANGED`

| Famille | Fichiers maîtres | Interface consommée par V2 | Dépendance spatiale V1 | Tests protecteurs (échantillon) |
|---|---|---|---|---|
| Déplacement / locomotion | `scripts/player/player_controller.gd`, `scripts/components/input_intent.gd`, `player_input_reader.gd`, `action_alignment_component.gd`, `resources/tuning/locomotion_*.tres` | instancier `scenes/player/Player.tscn` (groupes `player`/`damageable`) et le poser sur un `SpawnPoint` ; signaux `landed`/`stepped_up`/`mantle_*` | aucune — la position vient de la scène hôte | `test_locomotion`, `test_traversal_course`, `test_latency`, `test_p2_latency` |
| Sprint / endurance | `scripts/components/stamina_component.gd`, `resources/tuning/stamina_*.tres` | embarqué dans `Player.tscn` ; `try_sustain()`/`try_spend()` | aucune | `test_stamina` |
| Escalade / mantle | `scripts/components/climbing_component.gd`, `ledge_detector_component.gd`, `resources/tuning/climb_*.tres` | embarqué ; **contrat par groupe : V2 pose `unclimbable` sur ses surfaces interdites** (comme le relief de `valley_terrain.gd`, le puits de `room2_vertical.gd` et le mur d'arène de `boss_arena.gd`, tous marqués `unclimbable`) | aucune coordonnée | `test_climbing` |
| Caméra | `scripts/player/camera_rig.gd` | embarquée dans `Player.tscn` ; `set_boss_framing()` pour les arènes | aucune | `test_camera_rig`, `test_camera_never_enters_the_hero`, `test_mouse_camera` |
| Combat (santé/hitbox/combo/esquive/lock-on/poise/posture/garde) | `scripts/combat/attack_controller.gd`, `damage_event.gd`, `damage_formula.gd`, `scripts/components/{hitbox,hurtbox,health,poise,posture}_component.gd`, `lock_on_component.gd` | groupes `damageable`/`lock_on_targets`/`enemies` ; couches nommées `project.godot (layer_names/3d_physics)` ; Resources `AttackDefinition`/`DodgeDefinition`/`GuardTuning` | aucune | `test_hit_detection`, `test_combat_exchange`, `test_dodge`, `test_guard_deflect`, `test_posture`, `test_lock_on` |
| Arc / projectiles | `scripts/combat/bow_component.gd`, `arrow_projectile.gd` | embarqué ; flèches en pool interne | aucune | `test_bow`, `test_bow_fires_on_left_click` |
| Bracelet de Résonance | `scripts/reaction/resonance_controller.gd`, `resonance_target_component.gd`, `resonance_link_node.gd` | embarqué (`Components/ResonanceController`) ; une cible V2 devient détectable en portant un `ResonanceTargetComponent` (groupe `resonance_targets`) | aucune | `test_resonance_{pulse,link,polarity,arc_step,ground,focus}` |
| InputMap / couche d'entrée | `project.godot`, `player_input_reader.gd`, `input_intent.gd`, `user_settings.gd` | V2 ne touche JAMAIS l'InputMap — il instancie le joueur | aucune | `test_input_map`, `test_input_layer_isolation`, `test_invariants` (Q=gauche) |

### 1.2 Systèmes de monde partagés

| Famille | Statut | Interface consommée par V2 | Dépendance spatiale V1 → action V2 |
|---|---|---|---|
| IA (perception/utility/tokens, 5 familles) | `PROTECTED_UNCHANGED` (systèmes) + `V1_SPATIAL_REPLACE` (implantations) | PackedScenes `scenes/enemies/*.tscn` ; territoire = origine AU SPAWN ; `CombatCoordinator` découvert par groupe ; bruit par `noise_events.gd` | les positions V1 vivent dans `valley_world.gd (_spawn_bestiary — table de spawn)` — V2 fournit SES implantations depuis `world_v2_layout.json` (`regions[].encounters`, territoires) |
| Coffres / ramassables / récompenses | `DUAL_WORLD` | `Chest.tscn` (exports `chest_id`/loot), `WeaponPickup.tscn`, `PointOfInterest` (Area3D, `bind(DiscoveryLog)` **par injection** — conçu pour deux mondes), `RewardAnchor` audité par `reward_anchor_audit.gd` | la table `DiscoveryRewards.PLAN` et la mémoire `_taken_pickups`/`_taken_ingredients` de la vallée sont V1 ; V2 crée sa table d'ancrages depuis le layout ; **les IDs §19.3 des lieux/coffres sont CONSERVÉS** (dérivés du POI : `valley.poi.x.01` → `valley.chest.x.01`) — la progression des récompenses survit mécaniquement |
| Cuisine / buffs / ingrédients | `PROTECTED_UNCHANGED` | `RecipeRules.cook()` pur ; `Campfire` groupe `interactable` avec **export `campfire_id`** ; `StatusEffectComponent` | `campfire.gd` code un défaut d'export `campfire_id = valley.campfire.camp.01` — les instances V2 exportent leurs IDs propres |
| Lois de matière / ReactionSystem | `DUAL_WORLD` **par conception** (D-047 : jamais un autoload) | chaque monde instancie SON `ReactionSystem` (groupe `reaction_system`, `locate(tree)`, `submit()`) ; profils `.tres` partagés | aucune |
| Graphe électrique | `PROTECTED_UNCHANGED` | `ElectricGraph` par scène (groupe `electric_graphs`) ; les `ElectricNode` sont des Node3D dont la position mondiale EST la donnée — V2 pose ses nœuds où il veut | spatial par conception, local à la scène hôte ; aucune coordonnée V1 globale |
| Interactions / portes de scène | `DUAL_WORLD` | groupe `interactable` + `interact(player)` ; `SceneDoor.target_scene` export par instance ; `GameState.set_pending_spawn()` | les `target_scene` V1 sont codés en dur (`valley_terrain.gd (porte SceneDoor de la citadelle)` → vestibule ; `citadel_vestibule.gd (portes vers la salle 1 et la vallée)`) — les portes V2 règlent leurs cibles |
| Sauvegarde | `MIGRATION_REQUIRED` (contrat additif) | autoload `SaveSystem` (atomique, schéma 4, migrations par étape) ; fusion par clé dans `slot0` | AUCUN identifiant de monde dans le schéma 4 ; `player_position` bornée aux dimensions V1 (`ValleyWorld.SAVED_POSITION_LIMIT_XZ/_Y`) ; contrat complet : `docs/WORLD_V2_SAVE_MIGRATION.md` |
| Autoloads / flux | `PROTECTED_UNCHANGED` | `/root/{GameState,EventBus,SaveSystem,AudioManager,SceneFlow,DevMode}` ; `SceneFlow.go_to()` est LA porte de toute transition, V2 compris | aucune — les cibles appartiennent aux appelants |
| Resources de définition / tuning | `PROTECTED_UNCHANGED` | chargement des `.tres` ; V2 crée ses propres `.tres` si besoin, ne modifie jamais une définition | aucune |
| HUD / menus / UI | `DUAL_WORLD` (shell) + migration de reprise fine encore requise | instancier `GameplayShell.tscn` par scène jouable et régler l'export `world_scene_path` ; le shell trouve le joueur par groupe ; depuis le checkpoint jouable du 2026-08-17, `main_menu.gd (WORLD_SCENE)` ouvre World V2 pour « Continuer » et « Nouvelle partie » | `gameplay_shell.gd` garde la vallée V1 comme valeur par défaut mais World V2 la remplace dans sa scène ; `victory_screen.gd (const VALLEY_SCENE)` cible encore la V1 ; la migration des positions/états de reprise reste à faire sans activer les prototypes R2a-3.5 |
| Monture / mode dev / vol libre | `DUAL_WORLD` | `Mount.new()` / `DevFlyMode.new()` construits par le monde hôte (modèle `valley_world.gd (mount() / dev_fly())`) ; `DevMode` autoload lit le groupe `player` | instanciation V1 dans la vallée uniquement — V2 instanciera les siens |

### 1.3 Logique protégée du donjon et du boss

| Famille | Statut | Ce qui est verrouillé | Ce que V2 remplace |
|---|---|---|---|
| Énigmes des 4 salles | logique `PROTECTED_UNCHANGED` ; enveloppe `V1_SPATIAL_REPLACE` | `DungeonRoom` (reset, respawn des essentiels, fusion `slot0`), `Room1..4`, `CentralHall`, `Antechamber` : solutions, solveur (256 configurations salle 3), anti-softlock, hints (`PuzzleHintTracker`), briques (`PushableBlock`, `PortableBattery`, `ObjectSocket`, `ElevatorPlatform`, `ResetButton`) | l'enveloppe architecturale (volumes/matière/lumière) — plan par espace dans `WORLD_V2_MASTERPLAN.md` §10 ; les constantes de chaînage (`room1_initiation.gd (const VESTIBULE/HALL)`, `central_hall.gd (constantes des scènes desservies)`, `antechamber.gd (const ARENA et retour)`) seront rebranchées en V2.6+, pas en V2.0 |
| Boss | logique `PROTECTED_UNCHANGED` ; arène `V1_SPATIAL_REPLACE` | `StormGuardian` (machine 10 états idempotente), `BossDirector` (seed reproductible), `GroundingPylon` (vrais nœuds du graphe), posture partagée, solvabilité | l'habillage de l'arène (rayon jouable 19 m, mur 19,6/13, rail 14, pylônes à 90° : contraintes IMMUABLES du masterplan §10) ; `boss_arena.gd (const ANTECHAMBER/GUARDIAN)` (chemins retour/gardien) rebranché en V2.7+ |

### 1.4 Contenu spatial V1 — la cible du remplacement

| Élément | Statut | Note |
|---|---|---|
| `scenes/world/valley/ValleyWorld.tscn` + `valley_world.gd` + `valley_terrain.gd` + 9 bâtisseurs de lieux + navmesh versionnés | `V1_SPATIAL_REPLACE` | reste INTACT comme référence et régression explicite ; depuis le checkpoint jouable du 2026-08-17, le flux normal ouvre World V2. AUCUN bâtisseur V2 ne consomme son contenu spatial (vérifié par `test_world_v2_skeleton.gd`) |
| `scenes/world/citadel/CitadelVestibule.tscn` | `V1_SPATIAL_REPLACE` | seul intérieur réussi de V1 (WORLD_ATLAS §3) — l'enveloppe V2 le CONSERVE comme acquis et s'y raccorde ; épinglé par `tests/integration/test_dungeon_topology.gd` (catégorie B de fait : cet épinglage protège l'acquis conservé) |
| `TrainingGrounds.tscn` | `DUAL_WORLD` | écoles du Bracelet hors monde ; inchangé |

## 2. Classement des tests (question 2 de la phase)

Relevé exhaustif par balayage réel de `tests/` (161 fichiers de test au
2026-08-12 sur la base `58d4996` — chiffre daté, la source à jour est le
runner). **Aucun test n'est supprimé ni assoupli pendant V2.0** — vérifié par
le diff de cette phase, qui n'ajoute que `tests/world_v2/` et une racine de
découverte au runner.

| Catégorie | Compte | Définition | Politique V2 |
|---|---:|---|---|
| **A** — comportement pur | 95 | aucune hypothèse spatiale V1 (règles pures, décors construits par le test, spatial DONJON/ARÈNE sans vallée) | restent identiques, courent tels quels pendant toute la campagne |
| **B** — spatial V1 | 48 | coordonnées/nœuds/caméras de la vallée V1 en dur (`test_valley_*`, `test_camp_*`, `test_citadel_*`, `test_paths_*`, `test_mesas_*`, placements des dioramas…) | **un équivalent V2 est écrit AVANT tout retrait** ; jusqu'au gate V2.9, ils continuent de protéger la V1 |
| **C** — transverses V1 ET V2 | 15 | contrats qui devront tenir sur les deux mondes : sauvegarde (`test_save_*`), POI/ancrages (`test_reward_anchors`, `test_point_of_interest`, `test_discovery_log`), boot (`test_boot_smoke`, `test_flow_wiring_path`), shell (`test_shell_binding`), issues de victoire | V2.1+ ajoute la déclinaison V2 SANS toucher la version V1 |
| **D** — migration (nouveaux) | 0 existants | tests du contrat `world_version` et du routage de reprise | écrits avec la migration (liste exigée dans `WORLD_V2_SAVE_MIGRATION.md` §5) ; en V2.0 : les 2 fichiers de `tests/world_v2/` posent les invariants d'isolation |
| **E** — preuves visuelles baseline | 3 | caméras de gate et silhouettes calées sur les captures V1 (`test_gate_cameras_are_not_buried`, `test_phase_h_silhouettes`, `test_hero_shot_lab`) | servent de BASELINE de comparaison ; jamais « réparés » en remplaçant l'image attendue (§21.8) |

Détail fichier par fichier (48 B + 15 C + 3 E avec l'évidence exacte —
coordonnée, nœud ou chemin trouvé) : `evidence/world_v2/v2_0/contract_matrix.json`,
section `tests`.

## 3. Hypothèses spatiales V1 découvertes hors tests

Relevé pendant l'audit — chacune est une tâche nommée de la campagne, pas une
surprise future :

1. `gameplay_shell.gd (export world_scene_path)` — `world_scene_path` par défaut = vallée V1 (le
   squelette V2 le repointe déjà par export d'instance).
2. `main_menu.gd (_on_continue → _enter_world)` — depuis le checkpoint jouable du
   2026-08-17, « Continuer » et « Nouvelle partie » chargent World V2 ; la reprise
   fine des positions/états V1 reste le morceau central de la migration.
3. `victory_screen.gd (const VALLEY_SCENE)` — les issues de victoire ciblent la vallée V1.
4. `campfire.gd (export campfire_id, défaut « valley.campfire.camp.01 »)` — ID de feu par défaut `valley.campfire.camp.01`.
5. `ValleyWorld.SAVED_POSITION_LIMIT_XZ/_Y` — bornes de position sauvegardée calées sur les
   dimensions V1 (±260 / y ≤ 120) ; V2 définira les siennes dans SA scène.
6. `discovery_rewards.gd` — la table `PLAN` mappe les lieux V1 ; la table V2
   dérive de `world_v2_layout.json`.
7. Chaînage du donjon (`room*.gd`, `central_hall.gd`, `antechamber.gd`,
   `boss_arena.gd (const ANTECHAMBER/GUARDIAN)`, `citadel_vestibule.gd (portes vers la salle 1 et la vallée)`) — constantes de
   scènes V1, rebranchées quand l'enveloppe V2 existera.
8. Le payload de sauvegarde porte un champ interne `schema` INCOHÉRENT entre
   scènes (4 côté vallée, 2 côté menu/victoire/donjon — seul `schema_version`
   d'enveloppe fait autorité). Piège documenté ; la migration V2 n'aggravera
   pas cette dette et ne s'y fiera jamais.

## 4. Ce que V2.0 a réellement raccordé (prouvé par `tests/world_v2/`)

- le VRAI `Player.tscn` (contrôleur, endurance, caméra, Bracelet embarqués)
  apparaît dans `WorldV2.tscn` et repose sur une collision réelle ;
- la VRAIE `GameplayShell.tscn` se lie par groupe et son « Réessayer » cible
  V2 (export d'instance, zéro modification du shell) ;
- `SceneFlow` charge et referme V2 par la même porte que tout le monde ;
- `slot0` traverse un chargement V2 **identique à l'octet près** ;
- aucun fichier V1 ne mentionne `world_v2` ; aucun fichier V2 ne consomme le
  contenu spatial V1 (balayages dans les deux directions, nommés fichier par
  fichier en cas d'échec).

## 5. Décisions d'architecture V2 (opposables à V2.1+)

1. **Terrain** : chunks de 64 m (grille 8×8), maillages sculptés
   (Blender→glTF pour les grandes formes, `ArrayMesh` déterministe pour le
   raccord), collisions simplifiées séparées — JAMAIS des milliers de BoxMesh
   dans un script unique (leçon `valley_terrain.gd`, 3 960 lignes).
2. **Placement par données** : les POI, rencontres et checkpoints V2 se posent
   depuis `world_v2_layout.json` — la donnée est séparée de la construction
   visuelle ; les identifiants persistants §19.3 sont repris à l'identique.
3. **Navigation** : navmesh versionné baké hors-ligne par région (outil
   existant `bake_valley_navmesh.gd` comme modèle), plus la carte séparée
   grandes-carrures (modèle `_setup_large_navigation`, avec libération du RID).
4. **Végétation** : cellules MultiMesh bornées 24–48 m (jamais un MultiMesh
   vallée entière).
5. **Capture** : par cellule et par POI via `capture_poi_batch.gd` (l'outil de
   série V1) piloté par un plan JSON dérivé du layout.
6. **Aucune boucle monde-entier par frame** ; les conteneurs de `WorldV2.tscn`
   sont le SEUL endroit où la construction pose des nœuds.
7. **Aucune nouvelle dépendance externe** : Blender + Godot, comme V1.
8. **V1 jamais modifiée par un script de construction V2** — tenu par le
   balayage d'isolation, dans les deux directions.
