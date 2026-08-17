# Preuves — World V2, phase V2.0 (architecture, contrats, carte directrice, squelette)

**Statut : HISTORIQUE** (dossier de preuves daté — les documents vivants sont
`docs/WORLD_V2_MASTERPLAN.md`, `docs/WORLD_V2_SYSTEM_CONTRACTS.md`,
`docs/WORLD_V2_SAVE_MIGRATION.md`).

- **Base V1** : `58d4996839abfe95dcbed89dd896f755d1977238` — tête de
  `claude/full-world-visual-finish` (= `base_sha.txt`), un commit au-dessus du
  tag `playtest-full-visual-0b28106`.
- **Branche livrée** : `claude/world-v2-reconstruction`, créée depuis la base
  ci-dessus et poussée par push NORMAL — aucun force-push n'a été exécuté.
  `claude/world-v2-reconstruction-khgmlu` n'est qu'un pointeur résiduel de
  l'outillage de session, resté à son état initial (le merge de la PR #8,
  sans le commit d'evidence des 31 POI) ; il ne porte aucun travail V2.
  Historique V2.0 : exactement 6 commits avant la correction documentaire
  de clôture.
- **Environnement** : Godot 4.7.1-stable recompilé (`a13da4feb`),
  Blender 4.0.2, rendu logiciel llvmpipe (aucune mesure de performance ici).

## Ce que cette phase prouve — et les commandes exactes

| Preuve | Commande | Verdict | Fichier |
|---|---|---|---|
| Parse des 6 nouveaux scripts + runner modifié | `godot --headless --path . --check-only --script <f>` ×7 | 7/7 RC=0 | — |
| Contrats V2.0 (carte, isolation, squelette, sauvegarde) | `godot --headless --path . --script tools/godot/test_runner.gd -- --filter=world_v2` | **8/8, RC=0** | `tests_world_v2_VERT_8_0.log` |
| Boot Smoke V1 — le flux normal mène toujours à la vallée V1 jouable | idem `--filter=boot_smoke` | 1/1 (21 assertions), RC=0 | `boot_smoke_v1_VERT_1_0.log` |
| Sauvegarde V1 intacte (mécanisme + continuité + position + fusion) | idem `--filter=test_save` | 15/15, RC=0 | `save_tests_VERT_15_0.log` |
| Suite complète | `tools/validate_fast.sh` | **VERT — 853 réussis / 0 échoué, RC=0** (niveau 3b compris, plancher de couverture respecté) | `validate_fast_VERT_853_0.log` |

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

## Captures (renderer réel, arbre committé `3913431`, `repo_dirty: false`)

| Fichier | Ce qu'il montre — vérifié à l'œil avant d'être revendiqué |
|---|---|
| `capture_v2_squelette.png` (+ `.json`) | le squelette V2 par sa caméra de diagnostic : sol temporaire orange étiqueté « SOL TEMPORAIRE — SQUELETTE V2.0 », le VRAI héros posé dessus, le VRAI HUD raccordé (cristaux de vie, « Épée usée 24/24 », « Flèches : 8 ») |
| `capture_v1_flux_normal.png` (+ `.json`) | la vallée V1 par sa VistaCamera : héros de dos, herbe, village, rivière, citadelle sous l'orage, monture — le monde V1 rend comme avant (le Boot Smoke prouve la chaîne Boot → menu → vallée) |

Ordre tenu cette fois : code committé → capture → commit de la preuve
(la revue contradictoire avait rejeté la version précédente de ce README,
qui annonçait ces fichiers avant leur existence — voir
`REVUE_CONTRADICTOIRE.md`).

### Note d'exactitude sur le log de suite

`validate_fast.sh` a été lancée pendant que les corrections de revue
(documents et deux champs du layout) étaient apportées à l'arbre de
travail. Le verdict s'applique néanmoins à l'arbre livré : les `.gd`,
`.tscn` et `.tres` étaient identiques du début à la fin (aucun commit ne
les touche après `ca3ab63`), les documents `.md` ne sont lus par aucun
test, et les deux champs de layout modifiés (bande altitudinale d'une
région, formulation d'un espace de donjon) ne sont lus par aucun test —
les tests `world_v2`, qui lisent ce fichier, s'exécutent en dernier et
sont verts dans le log avec le contenu final.

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
