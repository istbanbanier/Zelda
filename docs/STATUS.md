# STATUS — état par fonctionnalité

Vocabulaire imposé (§0.2) : `Non commencé` · `Implémenté` (raccordé) ·
`Fonctionnel` (testé en scène exécutable) · `Validé` (conforme, sans régression) ·
`Bloqué`. Tout critère non testé est `NON VÉRIFIÉ`, jamais implicitement réussi.

**Dernière mise à jour** : 2026-08-01 · **Phase** : A (jalon A.1) · **Commit** : voir `git log`

## Verdict Gate A : **EN ATTENTE** — validation humaine non réalisée

Ni `PASS`, ni `FAIL`. Tout ce qui est vérifiable sans écran est vert (52 tests),
mais six contrôles de §21.4 exigent une machine avec écran, clavier AZERTY et
manette, dont ce conteneur ne dispose pas (ISS-002, ISS-004).

Protocole prêt à exécuter : **`docs/MANUAL_VALIDATION.md`**, outillé par
`tools/manual_validation_kit.sh` et `scenes/tests/InputProbe.tscn`.

| Étape de validation manuelle | État |
|---|---|
| 1. Lancement sur machine avec écran | NON VÉRIFIÉ |
| 2. Clavier AZERTY réel, `Q` = gauche | NON VÉRIFIÉ |
| 3. Manette | NON VÉRIFIÉ |
| 4. Lisibilité et focus du MainMenu | NON VÉRIFIÉ |
| 5. Reprise réelle depuis une session neuve | NON VÉRIFIÉ |
| 6. Archivage des preuves | NON VÉRIFIÉ |

`tools/manual_validation_kit.sh --finalize` sort actuellement en **3 (BLOQUÉ)** :
13 preuves attendues manquent. La Phase B ne démarre pas avant le verdict.

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
tourne, `validate_fast.sh` est vert (13 tests, plancher épinglé). **Aucun gameplay n'existe.** La
notation visuelle et les mesures de performance restent impossibles ici : rendu
logiciel llvmpipe uniquement, aucun GPU.

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
| `docs/DECISIONS.md` | ✅ | 5 décisions avec alternatives rejetées |
| `docs/RESEARCH_LEDGER.md` | ✅ | 5 entrées + 5 questions ouvertes |
| `docs/KNOWN_ISSUES.md` | ✅ | 5 ouverts (ISS-001 à ISS-005), 2 résolus |
| `docs/TEST_REPORT.md` | ✅ | résultats et commandes exactes |
| `docs/PERFORMANCE.md` | ✅ | protocole ; aucune mesure (assumé) |
| `docs/ART_BIBLE.md` | ✅ | North Star analysée, palette, budgets |
| `ATTRIBUTIONS.md` | ✅ | 4 ressources, toutes générées par le projet |
| `evidence/` | ✅ | `evidence/gate0/` |

---

## Phases A à J — non commencées

| Phase | Système | État |
|---|---|---|
| A | Boot, autoloads, InputMap AZERTY, couches de collision | **A.1 et A.2 livrés et gelés (`9414fd0`)** ; Gate A **EN ATTENTE** de validation humaine |
| B | Player, caméra, locomotion, endurance, escalade, mantle | Non commencé |
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
| Sonde d'entrée (outil de validation) | **Fonctionnel** | `test_input_probe.gd`, 4 cas : la sonde reste synchronisée avec l'InputMap | 2026-08-01 |
| Protocole de validation manuelle | **Implémenté** | `docs/MANUAL_VALIDATION.md` + `tools/manual_validation_kit.sh` (mode `--finalize` sort en 3 tant qu'il manque une preuve) | 2026-08-01 |

**Reste avant Gate A** : les six étapes de `docs/MANUAL_VALIDATION.md`, toutes
hors de portée de ce conteneur. Le protocole est écrit, outillé et exécutable par
une personne disposant du matériel ; il n'attend plus que d'être joué.

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
