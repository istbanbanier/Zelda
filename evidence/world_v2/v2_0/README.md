# Preuves — World V2, phase V2.0 (architecture, contrats, carte directrice, squelette)

**Statut : HISTORIQUE** (dossier de preuves daté — les documents vivants sont
`docs/WORLD_V2_MASTERPLAN.md`, `docs/WORLD_V2_SYSTEM_CONTRACTS.md`,
`docs/WORLD_V2_SAVE_MIGRATION.md`).

- **Base V1** : `58d4996839abfe95dcbed89dd896f755d1977238` — tête de
  `claude/full-world-visual-finish` (= `base_sha.txt`), un commit au-dessus du
  tag `playtest-full-visual-0b28106`.
- **Branche de la campagne** : `claude/world-v2-reconstruction-khgmlu`
  (repositionnée sur la base ci-dessus au démarrage de la session — la branche
  de session créée par l'outillage pointait sur le merge de la PR #8, qui ne
  contient PAS le commit d'evidence des 31 POI).
- **Environnement** : Godot 4.7.1-stable recompilé (`a13da4feb`),
  Blender 4.0.2, rendu logiciel llvmpipe (aucune mesure de performance ici).

## Ce que cette phase prouve — et les commandes exactes

| Preuve | Commande | Verdict | Fichier |
|---|---|---|---|
| Parse des 6 nouveaux scripts + runner modifié | `godot --headless --path . --check-only --script <f>` ×7 | 7/7 RC=0 | — |
| Contrats V2.0 (carte, isolation, squelette, sauvegarde) | `godot --headless --path . --script tools/godot/test_runner.gd -- --filter=world_v2` | **8/8, RC=0** | `tests_world_v2_VERT_8_0.log` |
| Boot Smoke V1 — le flux normal mène toujours à la vallée V1 jouable | idem `--filter=boot_smoke` | 1/1 (21 assertions), RC=0 | `boot_smoke_v1_VERT_1_0.log` |
| Sauvegarde V1 intacte (mécanisme + continuité + position + fusion) | idem `--filter=test_save` | 15/15, RC=0 | `save_tests_VERT_15_0.log` |
| Suite complète | `tools/validate_fast.sh` | voir `validate_fast_*.log` | `validate_fast_*.log` |

## Contrôle négatif — DÉMONTRÉ, pas déclaré

Deux couches, toutes deux rouges quand on les provoque :

1. **En suite** (rejoué à chaque passage) :
   `test_le_validateur_sait_dire_non` corrompt la carte de 7 façons (world_id
   V1, lieu manquant, ID dupliqué, site hors bornes, récompense vidée,
   checkpoint retiré, carte vide) et exige un refus à chaque fois.
2. **Hors suite** (`controle_negatif_ROUGE_5_4.log`) : retrait RÉEL de
   `valley.poi.hollow_crypt.01` du fichier `world_v2_layout.json` → la suite
   sort ROUGE en 4 points indépendants (carte invalide, compte 30 ≠ 31,
   lieu V1 non couvert, et **l'amorce REFUSE de charger le monde** — le garde
   d'exécution fonctionne aussi), RC=1. Carte restaurée à l'identique ensuite
   (diff vide), suite redevenue verte (8/8).

Premier passage conservé (`tests_world_v2_premier_passage_7_1.log`) : le
balayage des lieux V1 a d'abord attrapé `valley.poi.x.01`, l'EXEMPLE de
documentation de `discovery_rewards.gd:152` — corrigé en excluant les lignes
de commentaire du balayage, sans toucher au seuil. Un test qui a rougi une
fois sur un vrai cas prouve qu'il sait rougir.

## Captures (renderer réel, arbre committé)

| Fichier | Ce qu'il montre |
|---|---|
| `capture_v2_squelette.png` (+ `.json`) | le squelette V2 par sa caméra de diagnostic : sol temporaire marqué « SOL TEMPORAIRE — SQUELETTE V2.0 », vrai héros posé dessus, HUD réel raccordé |
| `capture_v1_flux_normal.png` (+ `.json`) | le menu principal V1, première image du flux normal inchangé (le Boot Smoke ci-dessus prouve la chaîne Boot → menu → vallée jouable) |

Manifestes : `commit` + `repo_dirty: false` exigés (règle
`.claude/rules/evidence.md`) — les captures sont prises APRÈS le commit du
code qu'elles prouvent.

## Fichiers de synthèse

- `contract_matrix.json` — les 23 familles de systèmes avec statut
  (`PROTECTED_UNCHANGED` / `DUAL_WORLD` / `V1_SPATIAL_REPLACE` /
  `MIGRATION_REQUIRED`), interface V2, dépendance spatiale, tests
  protecteurs ; PLUS le classement A/B/C/E des tests existants avec
  l'évidence exacte par fichier (81 entrées classées, comptes au total).
- `world_layout_summary.json` — résumé exécutable de la carte directrice :
  11 régions, 31 POI (positions V1 → V2), 3 sites systémiques, 5 entrées de
  grottes, checkpoints, 8 espaces de donjon, 4 routes.

## Ce que cette phase NE prouve PAS (honnêteté §0.2)

- aucun rendu « monde » : le squelette est un sol orange étiqueté — c'est le
  but, pas une limite ;
- aucune mesure de performance (llvmpipe) ;
- aucun essai humain ; la migration de sauvegarde n'est PAS implémentée
  (contrat seulement, `SCHEMA_VERSION` reste 4) ;
- le verdict d'image de la V1 (seconde revue Codex) reste dû et n'est pas
  affecté par cette phase.
