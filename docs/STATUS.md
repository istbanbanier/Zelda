# STATUS — état par fonctionnalité

Vocabulaire imposé (§0.2) : `Non commencé` · `Implémenté` (raccordé) ·
`Fonctionnel` (testé en scène exécutable) · `Validé` (conforme, sans régression) ·
`Bloqué`. Tout critère non testé est `NON VÉRIFIÉ`, jamais implicitement réussi.

**Dernière mise à jour** : 2026-08-01 · **Phase** : B (jalons B.0 à B.5 livrés) · **Gate A gelé** : `9414fd0` · **Commit courant** : voir `git log`

## Verdict Gate A : **ACCEPTÉ AVEC RÉSERVE / BLOQUÉ SUR LA VALIDATION MANETTE**

Décision du propriétaire, 2026-08-01 (D-012). **Ce n'est pas un `PASS`** : §23.1
exige « clavier AZERTY **et** manette fonctionnels », et la manette n'a pas été
testée. La Phase B est autorisée à démarrer, la dette est portée explicitement.

Le nombre de tests de référence est publié dans `docs/TEST_REPORT.md` — il ne doit
pas être recopié ailleurs, sous peine de diverger (défaut relevé par le test de
reprise).

Protocole prêt à exécuter : **`docs/MANUAL_VALIDATION.md`**, outillé par
`tools/manual_validation_kit.sh` et `scenes/tests/InputAudit.tscn`.
Procédure opérateur macOS : **`docs/MANUAL_GATE_A.md`**.

| Étape de validation manuelle | État |
|---|---|
| 1. Lancement sur machine avec écran | **PASS** *(déclaré, sans capture)* |
| 2. Clavier AZERTY réel, `Q` = gauche | **PASS** *(déclaré, sans capture)* |
| 3. Manette | **BLOQUÉ** — aucune manette ; dette **CONTROLLER-001** |
| 4. Lisibilité et focus du MainMenu | **PASS** *(déclaré, sans capture)* |
| 5. Reprise depuis une session neuve | **PASS** — 1 min 12 s, `evidence/gateA/05_reprise.md` |
| 6. Archivage des preuves | partiel — rapport et reprise archivés, captures absentes |

`tools/manual_validation_kit.sh --finalize` sort toujours en **3 (BLOQUÉ)** : les
captures d'écran manquent. C'est cohérent — le manifeste ne certifie pas ce qu'il
n'a pas vu.

## Verdict Gate C : **ACCEPTÉ POUR CONTINUATION AVEC VALIDATION HUMAINE DIFFÉRÉE** (D-024)

Décision du propriétaire, 2026-08-01, sur revue contradictoire à passe unique
(`evidence/gateC/REVUE.md`, code jugé `78f2b9a`) : les quatre critères du Gate C
— combat gagnable, une touche par swing, aucune référence invalide, esquive avec
i-frames — sont **PASS au volet automatique**, rejoués par le réviseur
(validate_fast VERT RC=0, import propre, 75 scripts parsés, 0 chemin `res://`
manquant). Constat majeur D1 (S2) : **la mort du joueur n'existait pas** —
corrigée le jour même (`Mode.DEAD`, pillard qui lâche le cadavre) avec
régression rejouant la sonde du réviseur (`test_player_death.gd`) ; D3 corrigé ;
D2 (lignes `RC=` des logs W/X/Y) annoté sans régénération. Ce verdict n'est PAS
un `PASS` : ressenti, manette et AZERTY physiques restent dus à la passe finale.
Reste de la Phase C consigné : checkpoint/retry après la mort (Phase E),
hit-stop/VFX/sons (§10.7), durabilité de l'arc en tirs.

## Verdict Gate B : **ACCEPTÉ POUR CONTINUATION / VALIDATION HUMAINE FINALE DIFFÉRÉE** (D-021)

Décision du propriétaire, 2026-08-01, sur revue contradictoire rendue : les essais
manuels (manette comprise) sont reportés à la **passe finale** et ne bloquent pas
la poursuite ; les limitations GPU ne bloquent pas le Gate B. La revue n'avait
démontré **aucun défaut bloquant** ; ses constats non bloquants étaient déjà tous
traités. **Ce n'est pas un `PASS`** : dettes VALIDATION-B-001 et CONTROLLER-001
ouvertes, à solder avant toute déclaration `Final`. La Phase C est autorisée.

### Historique du verdict — revue du 2026-08-01

Revue à contexte frais rendue et archivée : `evidence/gateB/REVUE.md`. **Aucun
`FAIL`** — huit critères `PASS` par ré-exécution indépendante (clone frais
compris), mais le verdict global est le plus faible des onze : jitter et essais
humains `NON VÉRIFIÉ` (protocole prêt, pas joué), manette `BLOQUÉ`
(CONTROLLER-001). Les six constats de la revue sont **traités le jour même** :
deux trous de couverture fermés (fenêtres de saut, dérive du `.tres`), un
contre-exemple corrigé (marche abordée en diagonale, D-020 amendée), convention
`RC=` appliquée aux logs, compte de contrôles retiré de PROGRESS, deux questions
de design consignées (R-012, R-013).

**Le volet automatique est clos.** La suite : six essais humains
(`docs/MANUAL_VALIDATION.md`, section Gate B), et décision du propriétaire pour
la Phase C.

## Verdict Gate 0 : **GELÉ / ACCEPTÉ AVEC RÉSERVES** (décision propriétaire, D-006)

Ce n'est **pas** un `PASS` : aucune des quatre revues adverses ne l'a prononcé.
Les critères 3, 4 et 5 sont `PASS`. Le critère 1 reste `NON VÉRIFIÉ` (vérifié par
relecture, pas par une session réellement repartie de zéro). Le critère 2 a vu tous
ses défauts bloquants corrigés et couverts par 18 contrôles négatifs rejoués, sans
qu'une revue l'ait pour autant validé. Réserves détaillées : D-006.

---

## Résumé en une ligne

Le système de continuité et le pipeline d'assets sont en place et **vérifiés par
exécution réelle** — Blender → glTF → import Godot → renderer → PNG. Godot 4.7.1
tourne, `validate_fast.sh` est vert (nombre de tests : voir `docs/TEST_REPORT.md`,
seule source à jour). Le premier gameplay existe : **un joueur se déplace, saute,
sprinte et grimpe une pente, caméra à l'épaule qui ne traverse pas les murs**
(B.1), son sprint est limité par l'endurance de §9.1 (B.2), il grimpe les parois
puis franchit les rebords (B.3), et un parcours enchaîné — marche, pente, saut
par-dessus un vide, escalade, franchissement — est joué de bout en bout par un
pilote scripté sans triche (B.4). La latence intention → mouvement est
**instrumentée et mesurée à 1 tick** (B.5), et le protocole d'essais humains du
Gate B est prêt à jouer. Il n'a ni animation, ni modèle. La notation
visuelle et les mesures de performance restent impossibles ici : rendu logiciel
llvmpipe uniquement, aucun GPU.

---

## Phase 0 — Initialisation

| # | Élément | État | Preuve | Dernier test |
|---|---|---|---|---|
| 0.1 | Inspection dépôt, outils, versions, réseau | **Validé** | `evidence/gate0/env_report.txt`, `docs/BUILD_ENVIRONMENT.md` | 2026-07-31 |
| 0.1 | Vérification de l'image de référence | **NON VÉRIFIÉ** | analyse dans `docs/ART_BIBLE.md` §1.1, mais l'image n'est pas versionnée (ISS-003) : une session neuve ne peut ni la rejouer ni la contredire | 2026-07-31 |
| 0.2 | Système de continuité (§0.3) | **Validé** | 12 artefacts présents, voir tableau ci-dessous | 2026-07-31 |
| 0.3 | Commandes de parse/test/capture | **Fonctionnel** (contrôles négatifs T-10 ; T-08 a été partiellement rétracté) | `tools/validate_fast.sh`, `test_runner.gd`, `capture_reference.gd` | 2026-07-31 |
| 0.3 | Scène laboratoire de pipeline | **Fonctionnel** | `scenes/tests/PipelineLab.tscn` capturée depuis le renderer | 2026-07-31 |
| 0.3 | Laboratoires de look-dev (§7.16) | **Non commencé** | reportés en Phase C.5 : sans contenu à juger, ce seraient des coquilles | — |
| 0.3 | Journal de recherche | **Validé** | `docs/RESEARCH_LEDGER.md`, 5 entrées sourcées | 2026-07-31 |
| 0.4 | Godot 4.7.1 vérifié | **Validé** | `evidence/gate0/env_report.txt` : `4.7.1.stable.custom_build.a13da4feb` | 2026-07-31 |
| 0.4 | Renderer Forward+ configuré | **Validé** | relu au runtime : `[boot] renderer : forward_plus` | 2026-07-31 |
| 0.4 | Jolt configuré | **Validé** | relu au runtime : `[boot] physique 3D : Jolt Physics` | 2026-07-31 |
| 0.4 | Blender / glTF vérifiés | **Validé** | `evidence/gate0/pipeline_blender_gltf.log` | 2026-07-31 |
| 0.5 | Import cube + matériau | **Fonctionnel** | `test_gltf_import.gd` : 1 m, base Y≈0, matériau résolu | 2026-07-31 |
| 0.5 | Import rig + clip animé | **Fonctionnel** | `test_gltf_import.gd` : 2 os, `AN_TestRig_Idle` | 2026-07-31 |
| 0.6 | Risques classés | **Validé** | `docs/RISKS.md` : 9 risques, gravité, probabilité, plan et signal d'alerte | 2026-07-31 |

### Artefacts de continuité exigés par §0.3

| Artefact | Présent | Contenu réel |
|---|---|---|
| `docs/MASTER_SPEC.md` | ✅ | 2358 lignes, cahier des charges intégral |
| `CLAUDE.md` | ✅ | < 150 lignes, importe MASTER_SPEC |
| `docs/ROADMAP.md` | ✅ | 12 phases, dépendances, critères de sortie |
| `docs/STATUS.md` | ✅ | ce fichier |
| `docs/PROGRESS.md` | ✅ | journal + handoff |
| `docs/DECISIONS.md` | ✅ | décisions avec alternatives rejetées (D-001…) |
| `docs/RESEARCH_LEDGER.md` | ✅ | 5 entrées + 5 questions ouvertes |
| `docs/KNOWN_ISSUES.md` | ✅ | ISS-001…ISS-005 ouverts + dette CONTROLLER-001 |
| `docs/TEST_REPORT.md` | ✅ | résultats et commandes exactes |
| `docs/PERFORMANCE.md` | ✅ | protocole ; aucune mesure (assumé) |
| `docs/ART_BIBLE.md` | ✅ | North Star analysée, palette, budgets |
| `ATTRIBUTIONS.md` | ✅ | 4 ressources, toutes générées par le projet |
| `evidence/` | ✅ | `evidence/gate0/` |

---

## Phases A à J — vue d'ensemble

| Phase | Système | État |
|---|---|---|
| A | Boot, autoloads, InputMap AZERTY, couches de collision | **A.1 et A.2 livrés et gelés (`9414fd0`)** ; Gate A **EN ATTENTE** de validation humaine |
| B | Player, caméra, locomotion, endurance, escalade, mantle | **Clos par D-021 : accepté pour continuation** — volet automatique vert (137 tests), dettes VALIDATION-B-001 + CONTROLLER-001 à la passe finale |
| C | Santé, hitbox, combo, esquive, lock-on, arc, durabilité | **Clos par D-024 : accepté pour continuation** — 4 critères PASS rejoués en revue, D1 (mort du joueur) corrigé + régression, dettes humaines à la passe finale |
| C.5 | `HeroShotLab`, première composition North Star | Non commencé — notation WOW bloquée (voir ISS-002) |
| D | Terrain 512 m, camp, rivière, pylône, citadelle, coffres, CINQ familles ennemies | **ACCEPTÉ POUR CONTINUATION — VALIDATION HUMAINE DIFFÉRÉE** (`docs/GATE_D_AUDIT.md`, passe 2) : items 16/17/19 PASS, 18 PARTIEL (4 coffres sur 8, solde en Phase F, documenté), 20 PASS automatique sans essai humain. Les cinq familles de §12 existent, diffèrent par stats/arme/portée/carrure/comportement et sont testées (107 assertions transverses + 47 par famille) |
| E | Récolte, cuisine, buffs, sauvegarde et migrations | **ACCEPTÉ POUR CONTINUATION — VALIDATION HUMAINE DIFFÉRÉE** (`docs/GATE_E_AUDIT.md`) : les huit items §22 Phase E PASS sur preuves rejouées, chaîne complète récolte→cuisine→buff→save/load testée de bout en bout. Non couvert : animation de cuisson (Phase H) et essai humain |
| F | Graphe électrique, 4 salles, salle centrale, antichambre | **En cours** — F.1 à F.6 livrés (graphe, quatre salles, salle centrale, antichambre, donjon ASSEMBLÉ du vestibule à l'antichambre) ; F.7 et F.8 restants |
| G | Arène, boss 3 phases, solvabilité, victoire | Non commencé |
| H | Art « wahou », WOW Gate ≥ 85/100 | **Bloqué** — ISS-002 |
| I | LOD, profilage, presets, exports, session 60 min | **Bloqué** — ISS-002 |
| J | DemoRoute, vidéo 3 min, revue externe | **Bloqué** — ISS-002 |

Les phases A à G restent **entièrement réalisables** dans cet environnement : elles
ne dépendent pas du rendu, seulement de l'exécution headless.

---

## Phase A — jalons A.1 et A.2

| Élément | État | Preuve | Dernier test |
|---|---|---|---|
| InputMap AZERTY, 18 actions (§8.5) | **Fonctionnel** | `test_input_map.gd` : Q = gauche, lock-on jamais sur Q | 2026-08-01 |
| 14 couches de collision nommées (§5.7) | **Fonctionnel** | `test_input_map.gd::test_collision_layers_are_named` | 2026-08-01 |
| 5 autoloads (§5.6) | **Fonctionnel** | `test_autoloads.gd`, 9 cas | 2026-08-01 |
| Écriture atomique de sauvegarde (§19.2) | **Fonctionnel** | `test_save_system.gd`, 6 cas | 2026-08-01 |
| Boot réel (§6.1) | **Fonctionnel** | lancé réellement, sortie `[boot]` dans `validate_fast` niveau 3 | 2026-08-01 |
| Menu principal (§17.3) | **Fonctionnel** | `test_main_menu.gd`, 8 cas : cycle de focus, boutons désactivés non focalisables, confirmation d'écrasement | 2026-08-01 |
| Transition Boot → MainMenu (§6.1) | **Fonctionnel** | `validate_fast` niveau 3 : lancement réel sur 90 frames, trace d'arrivée exigée | 2026-08-01 |
| Simulation physique Jolt (§5.3) | **Fonctionnel** | `test_physics_simulation.gd` : chute de 4 m, arrêt à 0,5 m, stabilisation | 2026-08-01 |
| Masques de collision par entité | Non commencé | aucune entité n'existe encore | — |
| Apparence et lisibilité du menu | **NON VÉRIFIÉ** | exige un écran ; seule la structure est testable ici | — |
| `InputAudit` + entrée debug du menu | **Fonctionnel** | `test_input_audit.gd` (4 cas) et `test_main_menu.gd` (entrée debug absente hors développement) | 2026-08-01 |
| Protocole de validation manuelle | **Implémenté** | `docs/MANUAL_VALIDATION.md` + `tools/manual_validation_kit.sh` (mode `--finalize` sort en 3 tant qu'il manque une preuve) | 2026-08-01 |

**Reste avant Gate A** : les six étapes de `docs/MANUAL_VALIDATION.md`, toutes
hors de portée de ce conteneur. Le protocole est écrit, outillé et exécutable par
une personne disposant du matériel ; il n'attend plus que d'être joué.

---

## Phase B — jalon B.0 : couche d'entrée

Livré **avant** tout code de joueur, et volontairement : la Phase B se développe
au clavier alors que la manette n'est pas testée (CONTROLLER-001). Sans cette
séparation, du gameplay finirait par supposer un clavier et la dette deviendrait
impayable sans réécriture.

| Élément | État | Preuve |
|---|---|---|
| `InputIntent` — intention typée, ignorante du périphérique | **Fonctionnel** | `test_input_layer_isolation.gd` |
| `PlayerInputReader` — seul lecteur de l'InputMap | **Fonctionnel** | idem |
| Actions caméra manette (`look_*`, stick droit) | **Fonctionnel** | sans elles, la caméra n'aurait été pilotable qu'à la souris |
| Générateur d'InputMap autoritatif (retire les actions inconnues) | **Fonctionnel** | contrôle négatif `B1_action_sans_liaison_manette.log` |
| Les 4 contraintes de D-012 vérifiées par test | **Fonctionnel** | 2 contrôles négatifs archivés |

---

## Phase B — jalon B.1 : Player, CameraRig, locomotion

Tous les cas ci-dessous pilotent le contrôleur par `InputIntent` **injectée** :
aucune touche n'est simulée, aucun périphérique n'est requis. C'est le bénéfice
direct de D-013, et la raison pour laquelle B.1 est vérifiable ici malgré
CONTROLLER-001.

| Élément (§) | État | Preuve |
|---|---|---|
| `PlayerController` en `CharacterBody3D` (§6.2, §8.2) | **Fonctionnel** | `test_locomotion.gd`, 12 cas |
| Marche / course / sprint pilotés par l'amplitude (§8.2) | **Fonctionnel** | 3 cas : 3,5 / 6,0 / 9,0 m/s mesurés |
| Déplacement caméra-relatif (§8.2) | **Fonctionnel** | `test_movement_is_camera_relative` : écart de direction mesuré après un quart de tour |
| Saut, apex ≈ 1,40 m (§8.2) | **Fonctionnel** | `test_jump_reaches_expected_apex` |
| Coyote time 0,12 s et jump buffer 0,12 s (§8.2) | **Fonctionnel** | 2 cas |
| Pente franchissable à 40°, refusée à 60° (§8.2) | **Fonctionnel** | 2 cas, dont la contre-épreuve |
| Corps à rotation nulle, seul `VisualRoot` s'oriente | **Fonctionnel** | `test_body_never_rotates` |
| `CameraRig` : pivots + `SpringArm3D`, `Camera3D` enfant direct (§8.3) | **Fonctionnel** | `test_camera_rig.gd`, 9 cas |
| Anti-traversée de mur (§23.1) | **Fonctionnel** | bras raccourci **et** dégagement mesuré devant la face |
| Butées de pitch −65°/+45° (§8.3) | **Fonctionnel** | `test_pitch_is_clamped_to_the_specified_range` |
| FOV sprint sans snap, interpolation framerate-independent (§8.3) | **Fonctionnel** | 2 cas, dont une comparaison 60 Hz / 120 Hz |
| Réglages dans une `Resource` de `resources/tuning/` (§5.4) | **Fonctionnel** | `locomotion_default.tres`, enveloppes §8.3 vérifiées par test |
| **Endurance (§9.1)** | **Fonctionnel** — voir jalon B.2 | `test_stamina.gd` (15 cas) et `test_locomotion.gd` (5 cas) |
| Escalade et mantle (§9.2, §9.3) | **Fonctionnel** — voir jalon B.3 | `test_climbing.gd` (14 cas), `test_action_alignment.gd` (9 cas) |
| Dégâts de chute (§8.2) | **Non commencé** | le signal `landed(impact_speed)` existe et porte déjà la vitesse d'impact |
| Ressenti, latence en ticks (§10.6) | **NON VÉRIFIÉ** | exige un essai humain à framerate réel ; aucun équivalent automatique |
| Absence de jitter caméra (§8.3) | **NON VÉRIFIÉ** | la traversée est testable ici, le jitter demande une observation en mouvement |

---

## Phase B — jalon B.2 : endurance

`StaminaComponent` est un composant (§5.8), pas une branche du contrôleur : le
sprint le consomme dès maintenant, l'escalade (§9.2), l'esquive et l'attaque lourde
(§10.2) s'y brancheront sans le modifier.

| Élément (§9.1) | État | Preuve |
|---|---|---|
| Réserve de 100, jamais hors bornes | **Fonctionnel** | `test_stamina.gd`, 3 cas |
| Sprint à 12/s, câblé au contrôleur | **Fonctionnel** | `test_sprint_drains_stamina` — mesuré via le joueur réel |
| Sprint immobile gratuit | **Fonctionnel** | `test_holding_sprint_while_standing_still_costs_nothing` |
| Course sans coût | **Fonctionnel** | `test_running_without_sprinting_costs_nothing` |
| **À zéro : sprint → course** | **Fonctionnel** | `test_exhaustion_drops_the_sprint_back_to_running` — vitesse mesurée, pas jauge |
| Régénération après 1 s, à 22/s | **Fonctionnel** | 3 cas |
| Reprise progressive sur 0,20 s | **Fonctionnel** | `test_regeneration_ramps_in_instead_of_snapping` |
| Verrou d'épuisement de 0,45 s | **Fonctionnel** | 2 cas, dont celui qui documente qu'il est masqué par le délai de régénération |
| Seuil de récupération (hors §9.1) | **Fonctionnel** | `test_a_held_sprint_produces_usable_bursts_not_a_stutter` — défaut réel corrigé, D-016 |
| Coût d'esquive et d'attaque lourde | **Implémenté**, non consommé | déclarés dans le `.tres` ; la Phase C les câblera. Un coût déclaré n'est pas une fonctionnalité |
| Coûts d'escalade (18/s, 16/s, 20) | **Fonctionnel** depuis B.3 | `test_climbing.gd` : escalade et saut d'escalade mesurés |
| Jauge contextuelle près du héros (§17.2) | **Non commencé** | les signaux `changed` / `exhausted` / `recovered` sont émis et attendent l'UI |
| Souffle et animation d'épuisement (§9.1, §18.2) | **Non commencé** | aucun périphérique audio ici (ISS-004) ; aucune animation avant la Phase H |

---

## Phase B — jalon B.3 : escalade et mantle

Trois composants (§5.8), aucun n'appartenant au contrôleur : les sondes répondent,
le contrôleur décide. `ActionAlignmentComponent` est celui de §7.12 — il servira
aussi aux coffres, à la cuisine et au pylône.

| Élément | État | Preuve |
|---|---|---|
| Trois sondes tête / torse / pieds (§9.2) | **Fonctionnel** | `test_climbing.gd`, refus nommés |
| Accroche en poussant vers la paroi (D-017) | **Fonctionnel** | `test_pushing_into_a_wall_grabs_it` |
| Refus des groupes interdits (§9.2) | **Fonctionnel** | `test_an_unclimbable_surface_is_refused` — géométrie identique, seul le groupe change |
| Refus des surplombs (§9.2 : « vides/concavités ») | **Fonctionnel** | `test_an_overhang_is_refused` |
| Filtre d'angle de paroi | **Fonctionnel** | `test_the_angle_filter_rejects_a_surface_below_the_threshold` |
| Aucune bande d'angles ni marchable ni escaladable (D-019) | **Fonctionnel** | `test_no_angle_is_both_unwalkable_and_unclimbable` |
| Montée à 2,0 m/s (§9.2) | **Fonctionnel** | `test_climbing_rises_at_the_declared_speed` |
| Coût d'escalade 18/s (§9.1) | **Fonctionnel** | `test_climbing_drains_stamina` |
| À zéro : lâcher du mur (§9.1) | **Fonctionnel** | `test_exhaustion_releases_the_wall`, raison `exhausted` |
| Saut d'escalade : 0,9 m, 20 d'endurance (§9.2, §9.1) | **Fonctionnel** | `test_climb_jump_costs_stamina_and_pushes_off` |
| Lissage de la normale (§9.2) | **Implémenté** | code présent et framerate-independent ; **aucun test** — il faudrait une paroi irrégulière que le bac à sable n'a pas |
| Franchissement d'un rebord (§9.3) | **Fonctionnel** | `test_reaching_a_ledge_mantles_onto_it` |
| Ascension de 4 m conclue par un franchissement | **Fonctionnel** | `test_climbing_a_tall_wall_ends_in_a_mantle` — l'enchaînement complet |
| Refus sous plafond (§9.3, §21.4) | **Fonctionnel** | `test_a_ledge_under_a_ceiling_refuses_the_mantle`, raison `blocked` |
| Correction plafonnée, aucun snap (§7.12, §9.3) | **Fonctionnel** | `test_action_alignment.gd` : plus grand pas mesuré |
| Annulation en cours de franchissement (§7.12) | **Implémenté** | seconde ligne de défense, révélée par le contrôle négatif P3 ; aucun test ne la déclenche seule |
| Déplacement latéral sur paroi 1,65 m/s (§9.2) | **Implémenté**, non mesuré | le code existe et facture 16/s ; aucun test ne vérifie la vitesse |
| `ClimbRest` / corniches de repos (§8.1, §9.3) | **Non commencé** | relève du level design, pas du contrôleur |
| IK visuelle des mains (§9.2) | **Non commencé** | Phase H — il n'y a ni squelette ni modèle |

---

## Phase B — jalon B.4 : franchissement de marche et parcours enchaîné

| Élément | État | Preuve |
|---|---|---|
| Marche de 0,30–0,38 m franchie sans saut (§8.2) | **Fonctionnel** | `test_a_low_step_is_climbed_by_walking` |
| Refus sous un plafond trop bas | **Fonctionnel** | `test_a_step_under_a_low_ceiling_is_refused` |
| Un mur n'est pas une marche | **Fonctionnel** *(comportement, pas couverture — voir Q3)* | `test_a_tall_wall_is_not_treated_as_a_step` |
| Enveloppe §8.2 respectée | **Fonctionnel** | `test_step_height_stays_within_the_spec_envelope` |
| **Parcours enchaîné complet** (§22, Gate B) | **Fonctionnel** | `test_traversal_course.gd`, 13 assertions |
| Caméra jamais dans la géométrie sur tout le parcours (§23.1) | **Fonctionnel** | sonde au point de vue à chaque tick : 0 image sur ~1 400 |
| Chaque capacité réellement employée | **Fonctionnel** | compteurs sur `stepped_up`, `grabbed_wall`, `mantle_finished` |
| Déclencheur de franchissement (D-020) | **Implémenté** | justifié par une mesure ; **aucun test ne le départage** de l'ancien (Q5) |
| Latence en ticks (§10.6, §23.1) | **Fonctionnel** — voir jalon B.5 | `LatencyInstrument` + `test_latency.gd` : 1 tick mesuré, mouvement et saut |

**§8.2 est désormais couvert en entier.**

---

## Phase B — jalon B.5 : latence instrumentée et protocole manuel

| Élément | État | Preuve |
|---|---|---|
| Latence intention → mouvement (§23.1 : « au tick physique suivant ») | **Fonctionnel** | `test_latency.gd` : 5 essais, pire cas **1 tick** (16,7 ms à 60 Hz) |
| Latence de saut depuis le repos (§10.6) | **Fonctionnel** | idem : **1 tick**, stable sur tous les essais |
| Conversion ticks → ms au taux réel | **Fonctionnel** | `test_the_report_converts_ticks_at_the_real_tick_rate` |
| Instrument réutilisable par un affichage debug | **Implémenté** | `LatencyInstrument` ; l'affichage écran viendra avec `CombatLab` (Phase C) |
| Protocole manuel Gate B (§21.4) | **Implémenté** | `docs/MANUAL_VALIDATION.md`, six essais B-1…B-6, prêt à jouer |
| Terrain d'essai jouable | **Fonctionnel** | `TraversalPlayground.tscn` : lancé réellement (headless), souris capturée, panneau d'état, événements journalisés |
| Silhouette graybox du joueur | **Implémenté** | capsule + nez d'orientation ; **pas un personnage** (§7.14), Phase H |
| Ressenti humain (§10.6), jitter (§8.3) | **NON VÉRIFIÉ** | essais B-1 et B-5 du protocole — exigent un écran |

**Ce qui sépare encore le Gate B d'un verdict** : la revue contradictoire (§0.7),
puis les six essais humains du protocole. Le code et l'instrumentation sont
complets.

---

## Phase C — jalon C.0 : fondations de dégâts

Pipeline de §10.1 et formule de §10.3, en composants (§5.8). Aucune arme, aucun
ennemi encore : C.1 branchera l'épée et le premier pillard sur ces fondations.

| Élément (§) | État | Preuve |
|---|---|---|
| `DamageEvent` complet (§10.3 : instigateur, équipe, type, quantité, direction, stagger, point, élément, attack ID) | **Fonctionnel** | `test_the_event_carries_what_the_spec_demands` |
| Formule base×…×weak_point×resistance−armor, clampée (§10.3, §21.2) | **Fonctionnel** | `test_damage.gd`, 3 cas dont l'ordre point faible/armure |
| `HealthComponent` : clamp, mort idempotente, revive | **Fonctionnel** | `test_damage.gd`, 4 cas |
| Invulnérabilité (future porteuse des i-frames §10.2) | **Fonctionnel** | `test_invulnerability_refuses_damage_without_consuming_it` |
| **« Une touche par swing »** (§10.1, critère du Gate C) | **Fonctionnel** | `test_an_overlapping_swing_hits_exactly_once` — 30 frames de chevauchement, 1 coup ; contrôle W1 : sans le set, 30 coups |
| Deux swings = deux coups, attack ID distincts | **Fonctionnel** | `test_a_second_swing_hits_again` |
| Un swing touche chaque cible à portée une fois (§21.4) | **Fonctionnel** | `test_one_swing_hits_every_target_in_range_once` |
| Refus du tir ami par équipe (§10.3) | **Fonctionnel** | `test_friendly_fire_is_refused_by_team` |
| Point faible porté par la hurtbox (§10.3) | **Fonctionnel** | `test_weak_point_multiplier_is_applied_by_the_formula` |
| Fenêtre active par méthode (§10.1) | **Fonctionnel** | `test_an_inactive_hitbox_never_hits` |
| Poise, recul, élément | **Implémenté** — transportés, non consommés | la jauge de poise et le recul appliqué arrivent en C.1/C.2 |
| Résistance et armure côté défenseur | **Implémenté** — paramètres neutres | branchés aux buffs (§13.5) et définitions d'ennemis (C.2) |
| `AttackDefinition` en ressource (§5.9, §10.6) | **Non commencé** | C.1, avec l'épée et le combo |

---

## Phase C — jalon C.1 : épée, combo, premier échange

L'attaque est un contrat de données (§10.6) : `AttackDefinition` porte startup /
actif / recovery / fenêtres, `AttackControllerComponent` l'exécute, le joueur
enchaîne trois légères contre de vrais mannequins.

| Élément (§) | État | Preuve |
|---|---|---|
| `AttackDefinition` en ressource (§5.9, §10.6) | **Fonctionnel** | 3 `.tres` d'épée ; enveloppes §10.2 épinglées (buffer 0,15, fenêtre 25–35 %, hit-stop 0,035–0,055) |
| Hitbox allumée exactement pendant la fenêtre active (§10.1, §10.5) | **Fonctionnel** | `test_the_hitbox_is_active_exactly_during_the_active_window` ; X1 |
| Combo trois légères (§10.2) | **Fonctionnel** | chaîne 0→1→2, jamais d'index 3 ; multiplicateurs 1,0 / 1,05 / 1,3 mesurés sur mannequin |
| Buffer d'attaque 0,15 s, expiration comprise (§10.2) | **Fonctionnel** | 2 cas + X3 |
| Enchaînement dans les derniers 25–35 % de la recovery (§10.2) | **Fonctionnel** | `test_a_buffered_press_chains_at_the_window_not_before` ; X2 |
| Report de buffer en fin de combo (§10.6 : « première fenêtre légale ») | **Fonctionnel** | relance à zéro si l'appui est frais, rien s'il est périmé |
| Attaque engagée au tick suivant l'intention (§10.6, §23.1) | **Fonctionnel** | `test_attack_engages_at_the_next_tick` |
| Mode `ATTACKING` : locomotion figée, gravité conservée | **Fonctionnel** | `test_movement_is_locked_during_the_attack` |
| Hurtbox + santé sur le joueur (§6.2) | **Implémenté** | câblées dans `Player.tscn` ; personne ne frappe encore le joueur (C.2) |
| Premier échange complet : 4 coups couchent un pillard braise (45 PV) | **Fonctionnel** | `test_hammering_delivers_the_full_combo_then_resets` |
| Cadavre inerte (§12.10) | **Fonctionnel** | `test_a_dead_dummy_takes_no_further_hits` |
| `CombatLab` (§10.8) | **Implémenté** — embryon | lancé réellement (RC=0) ; mannequins, panneau, journal des coups ; timeline et export à venir |
| `cancel()` d'interruption (stagger/mort, §16.2) | **Fonctionnel** | testé ; le stagger qui l'appellera arrive en C.2 |
| Esquive + i-frames, lock-on, réactions (§10.2, §8.4) | **Non commencé** | jalon C.2 |
| Attaque lourde, arc (§10.2, §10.4) | **Fonctionnel** | jalon C.3 — voir sa section |
| Hit-stop, VFX, sons (§10.7) | **Non commencé** | valeurs déclarées dans les `.tres`, aucun système de présentation |

---

## Phase C — jalon C.2 : esquive, i-frames, lock-on, premier pillard

| Élément (§) | État | Preuve |
|---|---|---|
| Esquive quatre directions, repère caméra (§10.2) | **Fonctionnel** | `test_dodge.gd` : direction du stick + reculade sans direction |
| I-frames par l'effet : coup refusé DANS la fenêtre, porté APRÈS (§10.2) | **Fonctionnel** | `test_iframes_refuse_a_real_blow_then_expire` ; longueur 0,25 s épinglée dans 0,22–0,27 |
| Coût 15 d'endurance, esquive refusée à jauge insuffisante (§9.1) | **Fonctionnel** | déclaré en B.2, consommé depuis C.2 ; Y2 |
| Dodge cancel : recovery annulable, engagement non (§10.6) | **Fonctionnel** | `test_dodge_cancels_attack_recovery_but_not_startup` |
| Lock-on : acquisition cône caméra 18–24 m (§8.4) | **Fonctionnel** | `test_lock_on.gd`, 7 cas ; enveloppe épinglée |
| « Jamais à travers mur » (§8.4) | **Fonctionnel** | mur réel, même cône — seul le mur change ; Y3 |
| Libérations : mort, distance (hystérésis), bascule (§8.4) | **Fonctionnel** | 3 cas |
| Caméra convergente, butées conservées, strafe face à la cible (§8.4) | **Fonctionnel** | convergence mesurée en angle ; face au mannequin en déplacement |
| Poise → stagger → récupération (§10.3, §12.3) | **Fonctionnel** | 2 coups d'épée (10+10 ≥ 20) étourdissent le pillard une fois |
| **Pillard braise complet** (§12.1, §12.6, §12.7) | **Fonctionnel** | `test_raider.gd`, 8 cas — voir ci-dessous |
| Perception : cône 95°/22 m par cadence, LOS réelle, impact révélateur | **Fonctionnel** | aggro devant, rien dans le dos, rien à travers mur |
| Télégraphe 0,65–0,95 s mesuré ET épinglé | **Fonctionnel** | coup jamais avant 0,65 s (mesuré : ~0,8) ; Y5 dans les deux sens |
| **Repli après esquive réussie** (§12.1) | **Fonctionnel** | esquive réelle chronométrée sur le télégraphe → 0 dégât + distance de repli ; Y4 |
| Duel gagnable (Gate C) | **Fonctionnel** | martèlement → pillard mort, inerte, joueur vivant |
| Changement de cible (§8.4 suivant/précédent) | **Fonctionnel** | jalon C.3 : directionnel, sans boucle, jamais à travers mur |
| Audition (§12.6), navmesh (§12.7) | **Différés** | D-022 — événements sonores et Phase D |
| Réaction de dégât du joueur (§8.1 Hurt), anti-stunlock (§10.5) | **Fonctionnel** | jalon C.3 — voir sa section |

---

## Phase C — jalon C.3 : attaque lourde, réaction du joueur, arc

| Élément (§) | État | Preuve |
|---|---|---|
| Attaque lourde : ×1,8, poise 25, hit-stop 0,08 déclaré (§10.2) | **Fonctionnel** | `test_heavy_and_hurt.gd` : 21,6 de dégâts ET 20 d'endurance mesurés sur le même coup |
| « Lourde refusée » à jauge insuffisante (§9.1) | **Fonctionnel** | à jauge 10 : rien ne part, rien n'est prélevé, mannequin intact ; Z1 |
| Une lourde brise la poise du pillard (25 ≥ 20) | **Fonctionnel** | 1 stagger, pas mort — l'« ouverture claire » version pillard |
| Réaction Hurt : recul + perte de contrôle 0,25 s (§8.1) | **Fonctionnel** | déplacement mesuré dans la direction du coup, contrôle rendu ; Z6 isole l'impulsion |
| Anti-stunlock 0,85 s : protège le CONTRÔLE, jamais les PV (§10.5) | **Fonctionnel** | deux coups en cadence : les deux blessent, seul le premier renverse ; grâce expirée → réaction revient ; Z2 |
| Hurt refusé pendant escalade/mantle/esquive | **Implémenté** | gardes en place ; l'esquive est couverte par les i-frames (C.2), les autres non testés |
| Arc : 9 de dégâts à distance, visée obligatoire (§10.4, §11.1, §8.5) | **Fonctionnel** | `test_bow.gd` ; sans visée, rien ne part |
| Balistique par balayage — CCD, chute de gravité (§5.3, §10.4) | **Fonctionnel** | vy ≈ −4 mesurée après 1/3 s de vol à plat |
| Anti-tir-à-travers-mur : origine-poitrine (§10.4) | **Fonctionnel** | mur à 0,8 m : flèche arrêtée, mannequin abrité intact ; Z3 chiffre la contre-hypothèse |
| La flèche meurt à sa première victime (§10.1) | **Fonctionnel** | deux mannequins alignés : 9 / 0 |
| Pool de flèches sans instanciation en rafale (§20.6) | **Fonctionnel** | 4ᵉ tir refusé à pool 3 ; cadence refuse le tir immédiat |
| Enveloppes : vitesse 42–58, dégâts 9, hit-stop lourd 0,070–0,095 | **Fonctionnel** | épinglées sur les `.tres` livrés ; Z4 |
| Changement de cible directionnel (§8.4) | **Fonctionnel** | 3 cibles dont une derrière un mur : pas à droite, pas de boucle, pas à travers |
| Munitions comptées, réticule, présentation (§11.3, §10.7) | **Non commencé** | C.4 et passe de présentation |

---

## Phase C — jalon C.4 : inventaire, durabilité, rupture

| Élément (§) | État | Preuve |
|---|---|---|
| `WeaponDefinition` immuable + table §11.1 complète (6 armes) | **Fonctionnel** | `test_weapon_data.gd` : les 6 `.tres` épinglés ligne à ligne (dégâts/durabilité/portée/conductivité) ; AA3 |
| **Invariant CLAUDE.md : deux exemplaires ne partagent jamais leur durabilité** | **Fonctionnel** | jumeau ET définition intacts après usure ; AA4 le prouve dans les trois directions (15 échecs en cascade) |
| Usure au contact seulement — « jamais dans le vide » (§11.2) | **Fonctionnel** | 2 moulinets à vide = 0 point ; 1 coup qui touche = 1 point ; AA2 |
| Avertissement à 25 %, une fois, sans spam (§11.2) | **Fonctionnel** | émis au passage sous le quart, jamais deux fois |
| Rupture : hitbox coupée, exemplaire retiré, suivante ou mains nues (§11.2) | **Fonctionnel** | épée 12 → gourdin 8 → poings 3 sur le même mannequin ; coupe au milieu du tick (2 mannequins, 1 point → 1 seule victime) |
| Dégâts et PORTÉE par arme (§11.1) | **Fonctionnel** | lance 2,7 m touche à 2,4 m, épée 1,7 m non — même geste |
| Inventaire : 8 armes max, aucun doublon d'instance (§11.3) | **Fonctionnel** | 9ᵉ refusée, même exemplaire refusé ; AA5 |
| Flèches comptées, consommées par tir, tir refusé à zéro (§11.3) | **Fonctionnel** | 8 → 7 ; carquois vide + cadence purgée → rien ne part ; AA6 |
| Durabilité de l'arc en tirs (28, §11.1) | **Non commencé** | définition présente, décompte au raccordement de l'arc à l'inventaire |
| Entrée clavier de sélection, ramassage, UI (§17.3, §11.4) | **Non commencé** | `equip_next` est une API ; coffres Phase D, UI §17 |

---

## Nuit ART-Q (2026-08-02) — assets de production Quaternius, Q0→Q7

Revue contradictoire à contexte frais : **PASS global, zéro S0-S3**
(`evidence/artQ7/REVUE.md`). Le verdict ESTHÉTIQUE reste humain
(`docs/PLAYTEST_ARTQ.md`).

| Élément | État | Preuve |
|---|---|---|
| Acquisition 7 archives (Release GitHub, CC0 sur pièce) | **Validé** | SHA-256 = digests GitHub, recoupés indépendamment par la revue — `docs/assets/QUATERNIUS_INBOX.md` |
| 18 ids du registre livrés (env ×8, prop ×3, arch ×3, char ×4) + épée | **Fonctionnel** | `test_asset_pipeline` : chaque id livré monte un maillage réel |
| Héros riggé animé dans le VRAI joueur (12 états, sockets main/dos/arc, épée en main, capsule autorité) | **Fonctionnel** | `test_hero_visual` (7 tests) ; audit root motion rejoué par la revue |
| Pillard animé sur la vraie IA + variantes azur/obsidienne | **Fonctionnel** | `test_raider_visual` (4 tests) ; capsule 1,6 m intacte au diff |
| Coffre rigged (clips Chest_Open/Opened), loot/IDs/atomicité intacts | **Fonctionnel** | `test_camp_props` |
| Camp habillé (caisses, tonneaux, galets de foyer) + caméra de contrôle | **Fonctionnel** | `evidence/artQ3/camp_props.png` |
| Forêt réelle sur collisions INCHANGÉES + phrases végétales §7.17 | **Fonctionnel** | `test_nature_biome` ; diff des collisions vide |
| Vestibule : piliers modulaires, portails de pierre, SceneDoors intactes | **Fonctionnel** | `test_citadel_dressing` |
| Liaison turquoise héros↔citadelle (§7.11), peau non teintée | **Fonctionnel** | `test_the_turquoise_tint…` ; `evidence/artQ6/ref_vista.png` |
| `prop.tent`, `prop.campfire` | **Bloqué** (absents des 7 packs) | inventaire consigné — options futures |
| Qualité artistique perçue | **EN ATTENTE** (verdict humain, §0.2) | protocole : `docs/PLAYTEST_ARTQ.md` |

## Phase F — jalons F.1 et F.2 : graphe électrique et salle d'initiation

L'ordre de §22 est respecté : le graphe a été construit et testé en **sandbox
automatisée** avant qu'une seule salle n'existe.

| Élément | État | Preuve |
|---|---|---|
| `ElectricNode` — §15.1 complet (ID stable, ports orientés en local, conductivité, `enabled`, signaux, `set_powered` idempotent, zéro rendu) | **Fonctionnel** | `--filter=electric_graph` (11 tests) |
| `ElectricGraph` — §15.2 point par point (marquage `dirty`, regroupement par tick, contacts réels port-à-port, BFS depuis toutes les sources, cycles bornés, signaux au seul changement) | **Fonctionnel** | idem : cycle de 4 câbles qui termine, 10 marquages = 1 recalcul, 20 ticks inactifs = 0 |
| Salle 1 §15.5 — source, vide court, deux plaques, bloc mobile, propagation visible, porte différée, reset, solution imperdable | **Fonctionnel** | `--filter=room1` (12 tests) ; captures `evidence/F2/` (entrée et salle résolue, arbre propre) |
| Le bloc est poussé **par le joueur**, à la marche, sans téléportation | **Fonctionnel** | `test_the_player_pushes_the_block_and_opens_the_door` : 7 m de poussée réelle, porte ouverte |
| Délai d'ouverture dans la fenêtre 0,6-1,2 s | **Validé** | mesuré tick par tick (`test_the_door_waits_between_06_and_12_seconds`) |
| Propagation lumineuse (le cyan voyage, il ne s'allume pas d'un bloc) | **Fonctionnel** | `test_the_light_travels_along_the_circuit` : le début du circuit est allumé avant sa fin |
| Anti-softlock §15.11 : reset, respawn hors-monde, porte latchée, rechargement en milieu de résolution | **Fonctionnel** | 4 tests dédiés, dont le rechargement depuis le disque |
| Poussée d'objets physiques par le joueur (§14.1, impulsions bornées) | **Fonctionnel** | `PlayerController._push_physics_props` ; masque du joueur étendu à la couche Physics Prop |
| Ergonomie de la poussée, lisibilité de l'énigme sans texte | **EN ATTENTE** (verdict humain) | `docs/MANUAL_VALIDATION.md` |
| Salle 2 §15.6 — ascenseur mort au départ, puits escaladable, électrodes rythmées, aiguillage supérieur, corniches, chute sur palier proche, aucun écrasement | **Fonctionnel** | `--filter=room2` (12 tests) |
| Résistance électrique de §13.5 réellement utile | **Fonctionnel** | `test_electric_resistance_softens_the_shock` : première source de dégâts électriques du jeu |
| Montée réelle du joueur, arrêt de l'ascenseur devant un corps, chute sur palier | **Fonctionnel** | `test_the_player_really_climbs_the_shaft`, `test_the_elevator_stops_rather_than_crushing_the_player`, `test_a_fall_lands_on_the_ledge_below` |
| Ergonomie de l'escalade sous électrodes, lisibilité du rythme | **EN ATTENTE** (verdict humain) | `docs/MANUAL_VALIDATION.md` |
| Salle 3 §15.7 — quatre relais, ports visibles, rotations discrètes, chemin partiel lisible, aucune punition, reset | **Fonctionnel** | `--filter=room3` (8 tests) |
| Solveur automatique de §15.7 : une solution existe, le départ n'en est pas une | **Validé** | `test_the_solver_proves_a_solution_exists` : 256 configurations jouées sur le vrai graphe, 1 solution |
| Salle 4 §15.8 — source, deux mécanismes, batterie transportable, socket explicite, eau conductrice, DEUX solutions, respawn, aucune porte du mauvais côté | **Fonctionnel** | `--filter=room4` (11 tests) |
| Prendre / porter / poser (§14.2) | **Fonctionnel** | `test_the_player_picks_up_carries_and_drops_the_battery` |
| Salle centrale §15.9 — trois récepteurs INDÉPENDANTS, trois anneaux, porte à trois conditions, carte murale, tableau salle→récepteur | **Fonctionnel** | `--filter=dungeon_hub` (10 tests) |
| Antichambre §15.10 — checkpoint, coffre garanti, cuisine, baies, retour, fresque bois/métal, aperçu de l'arène | **Fonctionnel** | idem |
| Donjon ASSEMBLÉ : vestibule → salle 1 → hall → salles 2/3/4 → antichambre, chemins retour, arrivée devant la porte franchie | **Fonctionnel** | `--filter=topology` (5 tests, 75 assertions) |

## Checklist finale (§26) — état réel

Une case n'est cochée que si une preuve datée la soutient. Ne jamais cocher sur la
base d'une intention. Les cases cochées ci-dessous renvoient toutes à `TEST_REPORT`.

| Domaine | Critère | État |
|---|---|---|
| Build | Ouvre et lance sans erreur bloquante | partiel — se lance en headless (T-05) ; **jamais ouvert dans l'éditeur**, critère de Gate A |
| Continuité | Une session neuve reprend via CLAUDE/STATUS/PROGRESS | ✅ sous réserve (T-07) |
| Recherche | Décisions risquées sourcées, expérimentées, consignées | ✅ |
| Loop | Du spawn à la victoire sans debug | ⬜ |
| Démo | Parcours trois minutes fluide, non truqué | ⬜ |
| AZERTY | ZQSD et Q=gauche | liaison testée ✅ ; essai humain sur clavier AZERTY **non fait** |
| Caméra | Aucun mur/jitter critique | ⬜ |
| Traversal | Sprint, saut, escalade, mantle | ⬜ |
| Combat | Une touche par swing, esquive juste | ⬜ |
| Arc | Visée et projectiles fiables | ⬜ |
| Durabilité | Avertissement, rupture, auto-équipement | logique testée ✅ (C.4) ; usure visuelle et son : Phase H |
| IA | Cinq familles distinctes, LOS réelle | ⬜ |
| Cuisine | 1-5 ingrédients et cinq buffs | ⬜ |
| Électricité | Graphe générique, pas booléens de salle | ⬜ |
| Donjon | Quatre salles et anti-softlock | ⬜ |
| Boss | Trois phases et solvabilité | ⬜ |
| Save | Coffres/circuits/inventaire/boss persistants | ⬜ |
| North Star | Score ≥ 85/100 | ⬜ **bloqué** |
| Look-dev | Labs validés | ⬜ **bloqué** |
| Art | Aucun placeholder critique | ⬜ |
| Assets | Blender/glTF/import/manifest/licences reproductibles | ✅ chaîne + 12 premiers assets Quaternius CC0 ingérés (ART-Q0) |
| Animation | IK/alignement sans défaut majeur | ⬜ |
| Audio | Feedback des actions importantes | ⬜ |
| Performance | Mesurée et conforme au preset annoncé | ⬜ **bloqué** |
| Frame pacing | Aucun hitch critique de première utilisation | ⬜ **bloqué** |
| Stabilité | 60 min sans crash | ⬜ **bloqué** |
| Web | Compatibility et fallback cohérent | ⬜ |
| Légalité | Assets originaux/licenciés/attribués | ✅ externe = Quaternius CC0 uniquement, licences sur pièce, ATTRIBUTIONS avant build |
