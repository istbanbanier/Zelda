# P2-5 — Preuves de clôture (Cycle 2, Prompt 2)

**Date** : 2026-08-05 · **Arbre prouvé** : `e284ffd` (propre,
`repo_dirty: false`) · **Environnement** : conteneur headless, Godot
4.7.1-stable custom build (`a13da4feb`), rendu logiciel — aucune mesure
de performance revendiquée ici.

## Jalon ROADMAP

« P2-5 Donjon/Boss : migration des salles vers les lois communes,
solveur/hints, boss director à patterns tagués. »

## Les quatre tranches, chacune fail-first (rouge prouvé avant le vert)

| Tranche | Commit | Rouge | Vert | Non-régression |
|---|---|---|---|---|
| 1. BossDirector (P2 §10.5) | `bde635d` | contrats absents | `test_boss_director` 5/5 (122 assertions) | suites boss 38/38 ; playthrough boss 1/1 |
| 2. Posture du boss (P2 §10.2) | `98ff665` | 0/11 | `test_boss_posture` 5/5 (22) | boss 43/43 ; playthrough boss inchangé (0/560, mêmes phases) |
| 3. Lois du donjon (P2 §4.2/§9.2) | `85a56e7` | 1/10 (le test-gardien §13.5 vert avant ET après — c'est son rôle) | `test_dungeon_laws` 6/6 | salles 44/44 ; réactions 7/7 ; playthrough donjon 2/2 |
| 4. Hints gradués (P2 §9.8) | `e284ffd` | échec de fichier (classe absente) | `test_puzzle_hints` 5/5 (19) | salles 44/44 ; donjon 2/2 |

Solveur du jalon : hérité du Gate F —
`test_room3_relays.gd::test_the_solver_proves_a_solution_exists`
(preuve exhaustive 256 configurations) + quatre salles solvables au
playthrough depuis sauvegarde vierge.

## Suites intégrales (commande : `$GODOT_BIN --headless --path . --script tools/godot/test_runner.gd`)

| Arbre | Résultat |
|---|---|
| `bde635d` (post-tranche 1) | **688/688, zéro échec** |
| `85a56e7` (post-tranches 2-3) | **699/699, zéro échec** |
| `e284ffd` (clôture, post-tranche 4) | **704/704, zéro échec** |

Queue du log de clôture : `integration_704_tail.log` (ce dossier).
Détail des campagnes : `docs/TEST_REPORT.md`, section « Campagne du
2026-08-05 (soir) ».

## Limites honnêtes

- Aucune validation manuelle (ni écran, ni clavier, ni manette) : la
  lisibilité RÉELLE des hints à l'écran et le ressenti du combat boss
  restent `EN ATTENTE` machine utilisateur (`docs/MANUAL_VALIDATION.md`).
- La présentation des hints est un graybox assumé (ligne discrète) ;
  l'option §12.3 (désactivés/contextuels/renforcés) attend l'écran
  d'options.
- Verdict de la revue contradictoire à contexte frais (HEAD `1337550`) :
  **PASS** — suite intégrale rejouée par la revue elle-même (704/704,
  code 0), contre-exemple tenté et échoué, cinq critères PASS, sept
  faiblesses non bloquantes → ISS-028 à ISS-031. Détail :
  `docs/TEST_REPORT.md`, campagne du 2026-08-05 (soir).
