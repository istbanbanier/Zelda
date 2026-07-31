# STATUS — état par fonctionnalité

Vocabulaire imposé (§0.2) : `Non commencé` · `Implémenté` (raccordé) ·
`Fonctionnel` (testé en scène exécutable) · `Validé` (conforme, sans régression) ·
`Bloqué`. Tout critère non testé est `NON VÉRIFIÉ`, jamais implicitement réussi.

**Dernière mise à jour** : 2026-07-31 · **Phase** : 0 · **Commit** : voir `git log`

---

## Résumé en une ligne

Le système de continuité et le pipeline d'assets sont en place et vérifiés ;
**aucun gameplay n'existe** ; les gates visuels et de performance sont bloqués par
l'absence de GPU dans l'environnement d'exécution.

---

## Phase 0 — Initialisation

| # | Élément | État | Preuve | Dernier test |
|---|---|---|---|---|
| 0.1 | Inspection dépôt, outils, versions, réseau | **Validé** | `evidence/gate0/env_report.txt`, `docs/BUILD_ENVIRONMENT.md` | 2026-07-31 |
| 0.1 | Vérification de l'image de référence | **Validé** | analyse consignée dans `docs/ART_BIBLE.md` §1.1 | 2026-07-31 |
| 0.2 | Système de continuité (§0.3) | **Validé** | 12 artefacts présents, voir tableau ci-dessous | 2026-07-31 |
| 0.3 | Commandes de parse/test/capture | **Fonctionnel** | `tools/validate_fast.sh`, `test_runner.gd`, `capture_reference.gd` | 2026-07-31 |
| 0.3 | Scènes laboratoire | **Non commencé** | — | — |
| 0.3 | Journal de recherche | **Validé** | `docs/RESEARCH_LEDGER.md`, 5 entrées sourcées | 2026-07-31 |
| 0.4 | Godot 4.7.1 vérifié | *voir TEST_REPORT* | `evidence/gate0/` | 2026-07-31 |
| 0.4 | Renderer Forward+ configuré | *voir TEST_REPORT* | `project.godot`, `test_smoke.gd` | 2026-07-31 |
| 0.4 | Jolt configuré | *voir TEST_REPORT* | `project.godot`, `test_smoke.gd` | 2026-07-31 |
| 0.4 | Blender / glTF vérifiés | **Validé** | `evidence/gate0/pipeline/` | 2026-07-31 |
| 0.5 | Import cube + matériau | *voir TEST_REPORT* | `assets/environment/props/SM_TestCube.glb` | 2026-07-31 |
| 0.5 | Import rig + clip animé | *voir TEST_REPORT* | `assets/characters/hero/SK_TestRigAnim.glb` | 2026-07-31 |
| 0.6 | Risques classés | **Validé** | `docs/RISKS.md`, 9 risques avec plan et signal | 2026-07-31 |

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
| `docs/KNOWN_ISSUES.md` | ✅ | 3 ouverts, 2 résolus |
| `docs/TEST_REPORT.md` | ✅ | résultats et commandes exactes |
| `docs/PERFORMANCE.md` | ✅ | protocole ; aucune mesure (assumé) |
| `docs/ART_BIBLE.md` | ✅ | North Star analysée, palette, budgets |
| `ATTRIBUTIONS.md` | ✅ | 4 ressources, toutes générées par le projet |
| `evidence/` | ✅ | `evidence/gate0/` |

---

## Phases A à J — non commencées

| Phase | Système | État |
|---|---|---|
| A | Boot, autoloads, InputMap AZERTY, couches de collision | Non commencé |
| B | Player, caméra, locomotion, endurance, escalade, mantle | Non commencé |
| C | Santé, hitbox, combo, esquive, lock-on, arc, durabilité | Non commencé |
| C.5 | `HeroShotLab`, première composition North Star | **Bloqué** — ISS-002 (aucun rendu) |
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

## Checklist finale (§26) — état réel

Toutes les cases sont vides et le resteront jusqu'à preuve. Ne jamais cocher sur la
base d'une intention.

| Domaine | Critère | État |
|---|---|---|
| Build | Ouvre et lance sans erreur bloquante | voir TEST_REPORT |
| Continuité | Une session neuve reprend via CLAUDE/STATUS/PROGRESS | voir TEST_REPORT |
| Recherche | Décisions risquées sourcées, expérimentées, consignées | ✅ |
| Loop | Du spawn à la victoire sans debug | ⬜ |
| Démo | Parcours trois minutes fluide, non truqué | ⬜ |
| AZERTY | ZQSD et Q=gauche | ⬜ |
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
| Assets | Blender/glTF/import/manifest/licences reproductibles | partiel — voir TEST_REPORT |
| Animation | IK/alignement sans défaut majeur | ⬜ |
| Audio | Feedback des actions importantes | ⬜ |
| Performance | Mesurée et conforme au preset annoncé | ⬜ **bloqué** |
| Frame pacing | Aucun hitch critique de première utilisation | ⬜ **bloqué** |
| Stabilité | 60 min sans crash | ⬜ **bloqué** |
| Web | Compatibility et fallback cohérent | ⬜ |
| Légalité | Assets originaux/licenciés/attribués | ✅ à ce stade (aucun asset externe) |
