# STATUS — état par fonctionnalité

Vocabulaire imposé (§0.2) : `Non commencé` · `Implémenté` (raccordé) ·
`Fonctionnel` (testé en scène exécutable) · `Validé` (conforme, sans régression) ·
`Bloqué`. Tout critère non testé est `NON VÉRIFIÉ`, jamais implicitement réussi.

**Dernière mise à jour** : 2026-08-01 · **Phase** : B (jalons B.0 à B.2 livrés) · **Gate A gelé** : `9414fd0` · **Commit courant** : voir `git log`

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
(B.1), et son sprint est limité par l'endurance de §9.1 (B.2). Il n'a ni
escalade, ni animation, ni modèle. La notation
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
| B | Player, caméra, locomotion, endurance, escalade, mantle | **B.0 à B.2 livrés** — entrée, player, caméra, locomotion, endurance ; escalade et mantle à venir |
| C | Santé, hitbox, combo, esquive, lock-on, arc, durabilité | Non commencé |
| C.5 | `HeroShotLab`, première composition North Star | Non commencé — notation WOW bloquée (voir ISS-002) |
| D | Terrain 512 m, camp, rivière, pylône, citadelle, coffres | Non commencé |
| E | Récolte, cuisine, buffs, sauvegarde et migrations | Non commencé |
| F | Graphe électrique, 4 salles, salle centrale, antichambre | Non commencé |
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
| Escalade et mantle (§9.2, §9.3) | **Non commencé** | jalon B.3 |
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
| Coûts d'escalade (18/s, 16/s, 20) | **Implémenté**, non consommé | idem, jalon B.3 |
| Jauge contextuelle près du héros (§17.2) | **Non commencé** | les signaux `changed` / `exhausted` / `recovered` sont émis et attendent l'UI |
| Souffle et animation d'épuisement (§9.1, §18.2) | **Non commencé** | aucun périphérique audio ici (ISS-004) ; aucune animation avant la Phase H |

---

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
| Durabilité | Avertissement, rupture, auto-équipement | ⬜ |
| IA | Cinq familles distinctes, LOS réelle | ⬜ |
| Cuisine | 1-5 ingrédients et cinq buffs | ⬜ |
| Électricité | Graphe générique, pas booléens de salle | ⬜ |
| Donjon | Quatre salles et anti-softlock | ⬜ |
| Boss | Trois phases et solvabilité | ⬜ |
| Save | Coffres/circuits/inventaire/boss persistants | ⬜ |
| North Star | Score ≥ 85/100 | ⬜ **bloqué** |
| Look-dev | Labs validés | ⬜ **bloqué** |
| Art | Aucun placeholder critique | ⬜ |
| Assets | Blender/glTF/import/manifest/licences reproductibles | ✅ pour la chaîne ; contenu réel à venir |
| Animation | IK/alignement sans défaut majeur | ⬜ |
| Audio | Feedback des actions importantes | ⬜ |
| Performance | Mesurée et conforme au preset annoncé | ⬜ **bloqué** |
| Frame pacing | Aucun hitch critique de première utilisation | ⬜ **bloqué** |
| Stabilité | 60 min sans crash | ⬜ **bloqué** |
| Web | Compatibility et fallback cohérent | ⬜ |
| Légalité | Assets originaux/licenciés/attribués | ✅ à ce stade (aucun asset externe) |
