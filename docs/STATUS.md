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
| F | Graphe électrique, 4 salles, salle centrale, antichambre | **ACCEPTÉ POUR CONTINUATION — VALIDATION HUMAINE DIFFÉRÉE** (`docs/GATE_F_AUDIT.md`) : F.1 à F.8 livrés ; donjon résolu de bout en bout depuis une sauvegarde vierge ET une sauvegarde intermédiaire |
| G | Arène, boss 3 phases, solvabilité, victoire | Non commencé |
| H | Art « wahou », WOW Gate ≥ 85/100 | **En cours** — passe H-1 (2026-08-04) : montagnes en prismes, nuage cumuliforme, spire de citadelle, feuilles olive (22 assertions, `test_phase_h_silhouettes.gd`). Baseline §30.2 ≈ 40/100 → ≈ 47/100 (H-1, `vista_h1_silhouettes`) → ≈ 50/100 (H-2 a-d) → **≈ 52/100** (H-3 a-c, `vista_h3c_final`, commit 77d02fc) — auto-évalué, revue contradictoire à faire. H-3 : la crête descend en PENTE (SpawnSlope testée), héros au bord de la rupture, vallée en contrebas, éclair sur spire dans le cadre. Sanctuaire forestier déplacé (34, 94), navmesh rebaké. H-4 : plafonds du fond nord + flore de pente (3600 brins épousant l'inclinaison, testé) — **≈ 53/100** (`vista_h4_ciel_fleurs`, commit 409153a). H-5 : crête à 32 m, contrebas 30 m (testé), fumée du camp suivie (invariant S3) — **≈ 55/100** (`vista_h5_contrebas`, commit 1634c12). Fausse alerte S1 donjon réfutée (R-017 : contention CPU — ISS-024 ouvert). H-6 : couronne de capture + 3 lignes d'énergie + contreforts + pierre bronze — **≈ 56/100** (`vista_h6_citadelle`, commit c400df7). Le solde 56→85 reste un chantier d'ASSETS (matériaux painterly, camp lisible, silhouettes sculptées). Le rendu llvmpipe borne la preuve : composition/couleur oui, performance jamais (ISS-002) |
| I | LOD, profilage, presets, exports, session 60 min | **Partiel** — volet EXPORT prouvé (2026-08-04) : preset `Linux x86_64` versionné, templates compilés depuis `/opt/src/godot`, binaire local 371 Mo qui répond `--version`, et Release CI `playtest-3038fc5` avec binaire autonome exporté par le runner (Godot 4.7.1-stable officiel). Profilage GPU et session 60 min restent **Bloqués** — ISS-002 |
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

## Phase G — jalons G.1 et G.2 : arène du Gardien et combat de boss

| Élément | État | Preuve |
|---|---|---|
| Arène §16.1 — disque de **38 m** (bornes 32-42), mur circulaire continu, trois zones de sol distinctes, aucun pilier au centre | **Fonctionnel** | `--filter=boss_arena` : la géométrie est mesurée (`CylinderShape3D`, rayons emboîtés), et le disque est balayé à la recherche d'un obstacle de cadrage |
| Quatre pylônes de mise à la terre, branchés sur le **même graphe** que le donjon (§16.3) | **Fonctionnel** | `test_a_raised_pylon_is_powered_by_the_ground_rail` : dresser allume, couper le puits de terre éteint — un mât rétracté ne peut pas toucher le rail |
| Anneau de terre fermé = un **cycle** du graphe (§15.2 pt. 5) | **Validé** | `test_the_closed_ground_ring_terminates` : 50 recalculs chronométrés, courant faisant le tour des 24 nœuds |
| §16.6 — le Gardien reste dans l'arène ; il ne pousse pas le joueur dehors | **Fonctionnel** | deux tests de 240 ticks, joueur placé hors arène puis collé au mur |
| §16.6 — la caméra élargit distance et FOV **progressivement** | **Fonctionnel** | `test_the_camera_widens_progressively_near_the_boss` : plus grand pas mesuré < 0,25 m/tick, retour au cadrage normal après la mort |
| §16.6 — checkpoint juste avant, retry qui relance le COMBAT | **Fonctionnel** | l'arène relit le checkpoint de l'antichambre (armes, flèches, santé) ; `retry_target()` pointe sur l'arène ; rechargement chronométré |
| §17.2 — barre de boss originale (vie réelle + nom de phase) | **Fonctionnel** | `test_the_hud_shows_a_boss_bar_only_in_the_arena` |
| §15.11 jusqu'à l'arène : le seuil sud reste ouvert vers l'antichambre | **Fonctionnel** | `test_the_arena_is_never_a_one_way_trap`, dans les deux sens |
| §16.2 — machine à dix états, transitions **idempotentes** | **Validé** | `test_a_health_threshold_never_fires_twice` : seuil traversé, remonté, retraversé |
| §16.1 — les 5 s d'éveil existent vraiment | **Fonctionnel** | défaut trouvé par test : `_enter()` étant idempotent, l'INTRO n'était jamais armée et le Gardien basculait en phase 1 au premier tick |
| §16.3 — armure ×0,2 sans invulnérabilité, DEUX pylônes pour la mise à la terre, étourdissement 6 s, noyau exposé puis armure refermée | **Fonctionnel** | `--filter=boss_guardian` (5 tests dédiés) |
| §16.4 — cristaux révélés en phase 2, destructibles, noyau exposé à leur chute | **Fonctionnel** | `test_the_crystals_appear_in_phase_two_and_open_the_core` |
| §16.4 — le métal renvoie pendant la surcharge, le bois non, la résistance électrique amortit | **Fonctionnel** | joué avec les VRAIES armes du jeu (gourdin, lame conductrice) et le vrai buff |
| §16.5 — fenêtre de télégraphe au sol **chronométrée** entre 0,7 et 1,0 s, borne fermée | **Validé** | `test_the_ground_strike_gives_a_real_warning_window` : un télégraphe réglé à 0,05 s est ramené à 0,7 |
| §16.5 — phase 3 « +10 à +18 %, pas doublement » | **Validé** | distance parcourue mesurée en phase 1 et en phase 3 |
| §16.2/§16.8 — la mort coupe attaques, hitboxes et timers ; la victoire est écrite | **Fonctionnel** | `test_death_cuts_everything_and_writes_the_victory`, relecture du fichier |
| §16.7 — **solvabilité** avec le loot garanti, marge 30-50 % | **Validé** | `test_the_guardian_is_beatable_with_the_guaranteed_loot` : c'est ce test qui a fait descendre les PV de 900 (marge -16 %, combat impossible) à 560 (+35 %) |
| §16.6 — « boss visible ≥ 80 % du temps en lock-on » | **Fonctionnel** (partie automatisable) | 180 positions autour de l'arène, projection écran réelle ; le confort de cadrage reste un jugement humain |
| Ressenti du combat, lisibilité des télégraphes, durée réelle d'une première victoire (§16.1 : 4-7 min) | **EN ATTENTE** (verdict humain) | `docs/MANUAL_VALIDATION.md` |
| Conclusion §16.8 (coffre final, tempête qui se dissipe, écran de victoire) | **Non commencé** | jalon G.3 |

## Phase H — lot H.1 : le Gardien devient un hero asset

| Élément | État | Preuve |
|---|---|---|
| Modèle ORIGINAL du boss, procédural et reproductible | **Fonctionnel** | `tools/blender/make_storm_guardian.py` (seed 20260803) → `SK_StormGuardian.glb` ; `--filter=guardian_asset` 6/6 |
| Cotes de VISUAL_ASSET_BIBLE §15.1 (8-10 × 5-7 × 5,2-6 m) | **Validé** | mesurées **dans Godot** sur la géométrie importée : 9,58 × 5,30 × 5,60 m, min Y = 0 |
| Anatomie exigée : six appuis, tête à trois plaques, épaules de bronze, queue segmentée à fourche, anneau incomplet en trois segments, noyau fendu | **Validé** | `test_the_anatomy_the_bible_asks_for_is_actually_there` : 20 assertions par NOM de mesh |
| 27 meshes séparés parce que le gameplay les manipule (§16.4, §16.5) | **Fonctionnel** | cristaux révélés/cachés sur le vrai modèle, plaques qui pendent en phase 3 |
| Les volumes de combat sont DANS le corps visible | **Validé** | `test_the_combat_volumes_sit_inside_the_body_you_can_see` : hurtbox de noyau à moins d'un mètre du noyau modélisé, cristaux à moins de 1,2 m |
| Le noyau s'allume quand l'armure s'ouvre (§16.3) | **Fonctionnel** | matériau propre à l'instance, émission mesurée avant/après |
| Licence et provenance | **Validé** | création originale du projet — `ATTRIBUTIONS.md`, `docs/assets/ASSET_MANIFEST.csv` |
| Densité de surface (bible §4.5 : 110-160k tris LOD0) | **PARTIEL assumé** | 6 324 triangles : silhouette et structure présentes, détail de surface absent. Consigné au manifeste |
| Animation du boss (§16.1 : entrée 5-8 s, dégâts visuels progressifs) | **Non commencé** | rig 22 os livré ; les clips viennent au lot suivant |
| Trois pillards, colosse, chasseur en silhouettes distinctes | **PARTIEL** | pillards faits (lot H.2) ; colosse et chasseur restent dus (H.3, H.4) |

## Phase H — lot H.2 : trois pillards, trois corps

| Élément | État | Preuve |
|---|---|---|
| Géométrie ORIGINALE pour braise, azur et obsidienne | **Fonctionnel** | `tools/blender/make_raiders.py` → trois `.glb` ; `--filter=raider` 22/22 |
| Le squelette des animations est CONSERVÉ (65 os UAL) | **Validé** | `gltf_inspect` : `skin:Armature 65 os` sur les trois ; `AL_RaiderStates.res` s'applique sans retargeting |
| Tailles de VISUAL_ASSET_BIBLE §14.1-14.3 | **Validé** | mesurées dans Godot : 1,42 · 1,63 · 1,88 m, dans leurs bandes et ORDONNÉES |
| Silhouettes réellement distinctes, pas des recolorations | **Validé** | `test_the_three_families_have_distinct_bodies_not_just_distinct_tints` : le briseur est 19 % plus large, les maillages ont des comptes différents |
| Traits de famille : excroissances vers l'arrière, crête verticale, visière fendue, plaques inégales | **Implémenté** | construits par profil dans le script ; **la lisibilité en silhouette noire à 25 m reste un essai humain** |
| §5.4 — matériaux propres à chaque exemplaire | **Validé** | isolation rendue inconditionnelle ; régression du télégraphe attrapée par `test_the_real_raider_mounts_the_model_and_keeps_its_gameplay_volumes` |
| Textures et détail de surface | **Non commencé** | couleurs de matériau seules, aucune texture. Consigné au manifeste |

## Phase H — lots H.3 et H.4 : colosse et chasseur, modèles bâtis

| Élément | État | Preuve |
|---|---|---|
| Colosse des ravins — modèle ORIGINAL rigged | **Implémenté** | `tools/blender/make_creatures.py` → `SK_RavineTroll.glb` (2 580 tris, 8 os) ; haut **3,97 m**, bande §14.4 = 3,7-4,3 |
| Traits exigés : torse incliné, bassin massif, bras ASYMÉTRIQUES dont un à croissance rocheuse, petites jambes puissantes, nodule minéral pâle entre omoplate et nuque | **Implémenté** | construits pièce par pièce dans le script ; **pas encore vérifiés dans Godot** |
| Chasseur quadrupède — modèle ORIGINAL rigged, corps inférieur NON équin | **Implémenté** | `SK_CentaurHunter.glb` (3 240 tris, 6 os) ; haut **3,20 m** (bande 3,0-3,5), long **4,69 m** (bande 4,0-4,8) |
| Traits exigés : quatre pattes à trois doigts, épaules avant plus hautes, queue de lames, torse supérieur né EN AVANT du bassin, plaque frontale et mandibules latérales | **Implémenté** | idem |
| Montage dans `RavineTroll.tscn` et `CentaurHunter.tscn` | **Fonctionnel** | `--filter=creature_assets` 4/4 : modèles montés, graybox masqués (les DEUX boîtes du chasseur), cotes vérifiées **dans Godot** — colosse 3,97 m, chasseur 3,20 × 4,69 m |
| §12.4 — le nodule point faible est du côté de la hurtbox arrière ×2 | **Validé** | `test_the_weak_point_nodule_sits_on_the_side_the_back_hurtbox_guards` |
| §12.5 — corps ALLONGÉ, pas un cheval | **Validé** | plus de 2,5 fois plus long que large, et plus long que haut |
| Les deux créatures regardent le côté où elles frappent | **Validé** | `test_both_creatures_face_the_direction_they_strike` |
| Envergure du colosse (4,06 m) plus large que sa capsule (rayon 1,1 m) | **Limite assumée** | règle ART-P0 : le modèle est un visuel, la capsule reste l'autorité de gameplay. Le joueur peut passer « à travers » les bras tendus |
| Animations propres au colosse et au chasseur | **Non commencé** | rigs livrés (8 et 6 os), aucun clip — les deux créatures gardent leur pose de repos |
| Silhouettes des cinq familles en aplat noir à 25 m (§30.3 de la bible) | **FAIL** | `evidence/phaseH/lineup_silhouettes.png` : la ligne des sept sujets est capturée, mais plusieurs corps se lisent en pièces détachées (ISS-018). Le critère ne peut pas être jugé tant que l'assemblage n'est pas fini |
| Assemblage des volumes (aucune articulation ouverte) | **PARTIEL** | passe de mordant faite sur les trois pillards et le tronc du colosse ; avant-bras et pieds du colosse, chasseur entier et extrémités du Gardien restent ouverts (ISS-018, S2) |
| Bibliothèque de silhouettes étendue à SEPT sujets (héros + cinq familles + boss) | **Fonctionnel** | `test_the_silhouette_lineup_mounts_every_character_of_the_game` : personne ne chevauche son voisin, le plus grand fait plus du triple du plus petit |
| Captures depuis le VRAI moteur | **Fonctionnel** | `evidence/phaseH/lineup_matiere.png` et `lineup_silhouettes.png`, avec leurs manifestes JSON |

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
| Électricité | Graphe générique, pas booléens de salle | ✅ 4 salles + les pylônes du boss sur le MÊME graphe (`--filter=electric_graph`, `boss_arena`) |
| Donjon | Quatre salles et anti-softlock | ✅ automatique (`docs/GATE_F_AUDIT.md`) ; lisibilité **EN ATTENTE** humaine |
| Boss | Trois phases et solvabilité | ✅ automatique (`docs/GATE_G_AUDIT.md`) : trois phases traversées par un run joué, solvabilité mesurée à +35 % de marge ; ressenti **EN ATTENTE** humaine |
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

## Phase H — lot H.6 : assemblage des personnages (ISS-018, ISS-019)

Commits `30ae2d3`, `29a3303`, `be96545`.

| Fonctionnalité | État | Preuve |
|---|---|---|
| Assemblage des volumes — aucune articulation ouverte | **Validé** | `check_continuity.py` sur les six `.glb` livrés : un seul corps solidaire, 43 / 60 / 113 / 20 / 26 / 24 morceaux, aucun détaché. Journaux `evidence/pipeline/continuity_*.log` |
| Contrôle automatique de continuité (ISS-019) | **Validé** | niveau 3b de `tools/validate_fast.sh`. Contrôle NÉGATIF : pièce déplacée de 0,60 m → code 1 ; modèle réparé → code 0 |
| Corps des pillards | **Fonctionnel** | corps CC0 Quaternius conservé (12 894 tris, PBR) au lieu des primitives ; stature 1,42 / 1,65 / 1,88 m, carrure 0,90 à 1,26, teintes de faction exportées en `baseColorFactor` vérifié dans le `.glb` |
| Chasseur — jonction torse/quadrupède | **Fonctionnel** | tronc de liaison ajouté, cage portée à 1,00 m de profondeur, épaules et hanches ; haut 3,41 m (bande 3,0-3,5), long 4,20 m (bande 4,0-4,8) |
| Colosse — avant-bras, mains, jambes, pieds | **Fonctionnel** | membres bâtis à leur portée pleine ; haut 4,03 m (bande 3,7-4,3) |
| Gardien — extrémités et jonctions | **Fonctionnel** | anneau réorienté tangentiellement et abaissé pour traverser le dos, queue, câbles, plaques et cristaux rattachés ; long 9,38 m · large 5,24 m · haut 5,59 m (bandes §15.1 : 8-10 / 5-7 / 5,2-6) |
| Planche d'inspection par angles | **Fonctionnel** | `scenes/tests/CharacterTurntable.tscn`, `--creature=<id>` : face, trois quarts, profil, dos, aplat noir |
| Silhouettes des cinq familles en aplat noir à 25 m (§30.3) | **NON VÉRIFIÉ** | la planche est capturable et les corps sont assemblés, mais le jugement « deux silhouettes ne se confondent pas » est un essai HUMAIN — `docs/MANUAL_VALIDATION.md` |
| Qualité sculpturale des créatures | **Limite assumée** | colosse, chasseur et Gardien restent des assemblages de primitives : cotes justes, volumes solidaires, lisibles — mais sans sculpture. Aucun score visuel n'est revendiqué |

## Phase H — lot H.7 : prairie de crête à la densité de la bible

| Fonctionnalité | État | Preuve |
|---|---|---|
| Densité de la prairie (§7.2 : 7-14 touffes/m² en zone héroïque) | **Validé** | `test_the_meadow_reaches_the_density_the_bible_asks_for` : densité mesurée par m² sur chaque cellule, bande 4-14, deux cellules au moins en zone héroïque, ≥ 10 000 touffes sur la crête |
| Partition en cellules (§7.5 : 24-48 m) | **Validé** | quatre cellules de 23 m, largeur vérifiée par le même test |
| Forme du brin (§3.1 : herbe longue 0,65-0,95 m au premier plan) | **Fonctionnel** | éventail de sept brins de 3,6 cm, ployés vers la pointe, normales inclinées à 72 % vers le ciel ; hauteur 0,41 à 0,74 m selon l'instance |
| Premier plan de la vue d'ouverture (§3.2 : « pente herbeuse sur les 22-30 % inférieurs ») | **Fonctionnel** | `evidence/phaseH/vista_prairie.png` — comparer à `evidence/artQ6/ref_vista.png` |
| Score WOW de la vue d'ouverture (§30.2) | **NON VÉRIFIÉ** | la notation demande un œil humain et un GPU réel (ISS-002). Le reste du cadre est encore graybox : montagnes en boîtes grises, citadelle sans terrasses, sol en aplat vert, cubes de placeholder |

## Monde ouvert — lot MO.4 : ancrages et récompenses des 31 lieux

Commits `2bf440f`, `018b8b6`.

| Fonctionnalité | État | Preuve |
|---|---|---|
| Un ancrage explicite et nommé par lieu (§3) | **Validé** | `test_every_place_carries_exactly_one_anchor` : 31 lieux, 31 ancrages, aucun orphelin, aucun sans point d'approche déclaré |
| Emplacement éprouvé physiquement — sol, dégagement, couloir | **Validé** | positions produites par `tools/godot/probe_reward_anchors.gd` sur la vallée montée, figées dans la table de chaque bâtisseur |
| Accès et retour démontrés par un corps | **Validé** | `test_a_body_reaches_every_reward_and_leaves_again` : `RewardAnchorAudit` marche l'aller puis le retour sur les 31 ancrages ; 14 défauts au premier passage, 0 après correction des causes |
| Traversée du belvédère prouvée sans navmesh (D-042) | **Validé** | ancrage `requires_traversal`, corps parti du pied de l'échine, montée de 20 m sous gravité |
| Variété des récompenses (§3) | **Validé** | `test_the_rewards_are_varied_and_none_is_missing` : 5 natures, aucune au-delà de 45 % du total |
| Armes au sol réellement ramassables (`WeaponPickup`) | **Validé** | `test_ground_weapons_are_real_pickups` : E ramasse, inventaire plein refuse, l'arme refusée reste au sol |
| Fragments d'histoire lisibles et annoncés une fois | **Validé** | `test_story_fragments_are_read_once` |
| Identifiants persistants uniques | **Validé** | `test_reward_identifiers_are_unique_across_the_whole_valley` sur coffres, armes, ingrédients et fragments |
| Aucun second butin après sauvegarde/rechargement | **Validé** | `test_rewards_survive_a_real_save_and_reload` : aller-retour réel par `user://slot0` |
| Restauration des découvertes au rechargement | **Corrigé** | le journal était appliqué AVANT que les lieux ne se déclarent : aucune découverte n'était jamais restaurée. `_build_open_world()` passe devant `_apply_save()` |
| Inspection visuelle de chaque ancrage | **En cours** | `scenes/tests/RewardAnchorShot.tscn` ; captures dans `evidence/rewards/` |
| Condition d'ouverture des récompenses de territoire et d'énigme | **Non commencé** | six lieux concernés, nommés par `DiscoveryRewards.deferred_gates()`. Le coffre est réel et persistant ; le verrou n'existe pas |

## Phase H — lot H.8 : armes de production et étagement de l'horizon

Commits `d5b4c79`, `9d107a2`.

| Fonctionnalité | État | Preuve |
|---|---|---|
| Les six armes portent un modèle de production (ISS-020) | **Fonctionnel** | `test_every_weapon_carries_its_own_production_model` : six modèles distincts, chacun instanciable et porteur de géométrie. Dimensions dans les bandes §16 |
| Pose des armes au sol | **Fonctionnel** | les armes de plus de 1,05 m sont fichées en terre, hauteur déduite de la boîte englobante après rotation. `evidence/rewards/logging_hamlet.png` |
| Textures des cinq nouvelles armes | **Non commencé** | facteurs PBR plats ; seule l'Épée usée a ses cartes peintes. ISS-020 reste ouvert sur ce point |
| Trois plans dans la vue d'ouverture (§1.3) | **NON CONCLUANT** | crêtes brisées et deux rangs lointains posés, mais la seule mesure produite — l'écart de valeurs sur la bande d'horizon — passe de 25 à 24 points, soit une différence négligeable et **dans le mauvais sens**. Un diff de pixels n'est pas une amélioration esthétique. À trancher par une comparaison visuelle indépendante et des mesures correctement orientées |
| Citadelle détachée de la montagne (§30.2) | **NON CONCLUANT** | la bordure a été éclaircie et la pierre assombrie, mais aucune mesure ne démontre que le monument se détache. Revendication retirée |
| Score WOW de la vue d'ouverture (§30.2) | **NON VÉRIFIÉ** | la notation demande un œil humain et un GPU réel (ISS-002). La vallée reste un graybox : citadelle sans terrasses, montagnes en boîtes, sol en aplat |
