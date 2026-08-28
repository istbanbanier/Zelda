# ISS-074 — INVENTAIRE : ce qui existe déjà pour peupler World V2

**Statut : HISTORIQUE (relevé daté)** · 2026-08-28 · relevé sur pièces à la
base `a8d2f77` par un agent d'exploration en lecture seule, recoupé par le
lead. Ancres : chemins et symboles, jamais de numéros de ligne. Ce document
nourrit le contrat (`iss074_peuplement_world_v2.md`) ; en cas de divergence
avec le code, le code a raison et l'écart se consigne.

## 1. Les cinq familles — prêtes au combat, sans loot

Socle : `scripts/enemies/enemy_base.gd` (`EnemyBase`) — machine à 12 états
(`IDLE, PATROL, SUSPICIOUS, INVESTIGATE, CHASE, REPOSITION, ATTACK, RETREAT,
STAGGERED, FLEE, RETURN, DEAD`), patrouille par `patrol_offsets` relatifs à
l'origine de territoire, perception par cadence (`PERCEPTION_INTERVAL` 6
frames physiques ; préfiltre distance → cône → double raycast de LOS torse
1,0 m / tête 1,6 m, masque monde statique), ouïe par `NoiseEvents` (sprint
12 m, impact 10 m, rupture 14 m, flèche 8 m ; rayon effectif borné par
`hearing_range` du tuning), mémoire → enquête → retour, territoire borné
(`max_pursuit_distance`), alerte alliée, fuite à la mort d'un allié, stagger
par `PoiseComponent`, mort §12.10 (hurtbox éteintes, couche 0, physique
coupée), séparation locale.

| Famille | Script | Tuning | Signature comportementale |
|---|---|---|---|
| `raider_red` | `raider_red.gd` | `raider_red_default.tres` | recule après une esquive réussie du joueur ; fuit à la mort d'un allié |
| `raider_blue` | `raider_blue.gd` | `raider_blue_default.tres` | contournement en bande, réouverture de distance, esquive d'une lourde (cooldown 8 s) ; seul consommateur d'`UtilityBrain` |
| `raider_black` | `raider_black.gd` | `raider_black_default.tres` | garde frontale à jauge (`PostureComponent`, arc 60°, dégâts ×0,25), combo 2-3, ouverture à la rupture |
| `ravine_troll` | `ravine_troll.gd` | `ravine_troll_default.tres` (`uses_large_navmesh`) | balayage/vertical/slam (`resources/combat/troll/*.tres`), onde de choc, lancer de rocher, point faible dorsal, token lourd |
| `centaur_hunter` | `centaur_hunter.gd` | `centaur_hunter_default.tres` (`uses_large_navmesh`) | cri, charge en ligne, salve plafonnée (3 flèches), orbite, abandon à la frontière |

Couverture de test : `tests/integration/test_enemy_base.gd`, `test_raider*.gd`,
`test_ravine_troll.gd`, `test_centaur_hunter.gd`, `test_bestiary_gate.gd`,
`test_raider_visual.gd`, `test_combat_coordinator.gd`, `test_utility_brain.gd`.

**Dettes du bestiaire, écrites dans le code lui-même** : la ressource est
`EnemyTuning`, pas l'`EnemyDefinition` de §5.9 (son en-tête le dit) ; AUCUN
loot (`LootComponent`/`LootTableDefinition` inexistants — grep vide) ;
`State.REPOSITION` déclaré mais jamais entré (l'orbite vit dans `CHASE`) ;
`raider_red_default.tres` roule sur les défauts de mémoire/poursuite.

## 2. Systèmes transverses

- **Coordination** : `combat_coordinator.gd` (`CombatCoordinator`), groupe
  `combat_coordinator` — `MELEE_TOKENS = 2`, `HEAVY_TOKENS = 1`,
  `MAX_ACTIVE_AI = 14`, gouvernance par cadence, plafond d'activité par
  distance avec `sleep_for_activity_cap()`. **Sans coordinateur dans la
  scène, le token est accordé d'office** (`_request_attack_token` rend vrai).
- **Navigation** : aucun `NavigationAgent3D` dans le dépôt —
  `EnemyBase._pursuit_direction_toward()` appelle
  `NavigationServer3D.map_get_path()` par cadence (`REPATH_INTERVAL` 15,
  recalcul seulement si le but a bougé de 1,5 m), repli ligne directe.
  `_navigation_map()` : si `uses_large_navmesh`, cherche le groupe
  `large_navigation`, sinon la carte du monde.
- **V1, spawn** : `valley_world.gd::_spawn_bestiary()` — table LITTÉRALE de
  9 lignes (scène, position, lacet, patrouille), + 3 `RaiderRed` posés en
  dur dans `ValleyWorld.tscn` (12 instances). `ValleyTerritories` pose le
  DÉCOR des cinq territoires et expose `patrol_route()`/`frontier_marks()`
  — **aucun appelant de production ne les consomme** : décor et peuplement
  n'ont jamais été reliés.
- **Persistance des morts** : AUCUNE — ni le payload V1 ni le payload V2 ne
  portent un champ ennemi. Tout remontage ressuscite tout ; tuer ne
  rapporte rien et ne se souvient de rien.

## 3. Ce que World V2 possède déjà

- `WorldV2.tscn` porte le conteneur **`Encounters`** (Node3D), exigé par
  `WorldV2Root.REQUIRED_CONTAINERS` — **vide, référencé par aucun autre
  fichier**.
- Navmesh V2 : `resources/world_v2/nav/world_v2_navmesh_q{0..3}.tres`,
  quatre quadrants, `AGENT_RADIUS 0.7 / AGENT_HEIGHT 1.8`
  (`tools/godot/bake_world_v2_navmesh.gd`) — **aucun équivalent « grandes
  carrures »** : pas d'`OUT_LARGE`, pas de groupe `large_navigation` en V2 ;
  colosse et chasseur retomberaient EN SILENCE sur le maillage 0,7 m.
- Territoires : **1 construit sur 5** — `EmberRaiderCampPlace`
  (`valley.poi.ember_raider_camps.01`) : enceinte ovale, DEUX brèches
  (ouest 180°, nord-est 42°), flanc éboulé, guet à ≥ 4,5 m, foyer éteint,
  appentis, butin décoratif — « territoire ennemi SANS acteurs » par
  contrat, saturé à 45/45 modules (plafond exécutable
  `test_world_v2_r2b1_braise.gd`). `azure_patrol_run`, `obsidian_bastion`,
  `colossus_lair`, `hunter_range` restent des marqueurs.
- Le layout (`world_v2_layout.json`) porte `regions[].encounters` en prose
  (`r02` « patrouille braise légère en lisière », `r05` « garnison braise du
  camp », `r06` « territoire du chasseur (SE, facultatif) », `r08`
  « patrouille azur ; bastion des briseurs », `r10` « tanière du colosse »,
  `r01`/`r11` « aucune ») — **lue par aucun script ni test**.
- Le verrou actuel :
  `test_world_v2_places_contract.gd::test_aucun_acteur_et_les_routes_restent_libres`
  — compte le groupe `enemies` sur TOUT le monde et exige 0, puis balaie
  `$Places` contre tout script de `scripts/enemies/` ou `scripts/ai/`.
  Autorité amont : `docs/WORLD_V2_POI_CONTRACTS.md` §1.4.
- Fait d'isolation : la liste d'interdits V2→V1
  (`test_world_v2_skeleton.gd`) n'inclut PAS `scenes/enemies/*.tscn` — les
  scènes d'ennemis sont du contenu partagé, pas du contenu spatial V1.

## 4. Budgets déjà écrits qui CONTRAIGNENT le peuplement

- MASTER_SPEC §12.6 : la table vision/audition/vitesses, déjà reportée dans
  les `.tres`.
- §12.8-12.10 : 2 tokens mêlée + 1 lourd ; « limiter à 10-14 IA pleinement
  actives » ; « navmesh validé avec capsule de chaque famille » ; « générer
  loot une fois, sauvegarder si nécessaire ».
- PROMPT2_SPEC §8.2-8.7 : perception honnête (jamais la position du joueur
  lue), 2 mêlées max en Aventure, « aucun cercle passif », « profiler un
  combat avec le nombre maximal d'ennemis prévu », gate `AILab` — **aucun
  `AILab` n'existe**, aucune mesure IA dans `evidence/`.
- WORLD_V2_MASTERPLAN §8 : ≥ 12 m de rayon dégagé par rencontre + couverture
  + sortie ; zones calmes garanties (crête, prairie, lit de rivière, source,
  sanctuaire, belvédère, berges) ; jamais sur un checkpoint ni une école du
  Bracelet.
- WORLD_V2_SYSTEM_CONTRACTS : IA en `PROTECTED_UNCHANGED` (systèmes) +
  `V1_SPATIAL_REPLACE` (implantations) — « V2 fournit SES implantations
  depuis `world_v2_layout.json` ».
- Gel V2.3-B : 44 fichiers énumérés au sha256, dont `world_v2_layout.json`,
  `world_v2_root.gd` et le camp braise. **Le gel n'interdit pas d'AJOUTER**
  (`V2_3_B_PLAN.md` §5) : un `world_v2_encounters_builder.gd` neuf n'y
  rougit pas ; toucher au layout ou à la racine exige une décision datée.

## 5. Table de synthèse

| Brique | État |
|---|---|
| Cinq familles (combat, perception, tests) | **prêt** — sauf loot |
| Nav V2 agent 0,7 m | **prêt** (4 quadrants testés) |
| Nav V2 grandes carrures (colosse, chasseur) | **absent** |
| Coordination (tokens, plafond 14) | **prêt** — jamais instancié en V2 |
| Spawn/placement V2 | **absent** (`Encounters` vide, prose du layout morte) |
| Territoires V2 construits | **1 / 5** (camp braise, saturé 45/45) |
| Contrat autorisant les acteurs | **absent** — l'inverse est en vigueur |
| Persistance des morts | **absent** (aucun champ, V1 comme V2) |
| Loot / EnemyDefinition | **absent** — dette écrite dans `enemy_tuning.gd` |
| Profilage IA en V2 / AILab | **absent** — budget CPU INCONNU, pas « acquis » |
