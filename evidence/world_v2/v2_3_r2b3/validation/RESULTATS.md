# ISS-063 — verdicts du rejeu isolé

Agent « suites rejouées ». Procédure : `PROCEDURE.md` (même dossier).
Rendu logiciel llvmpipe : **aucune mesure de performance n'est produite ici.**

## HEAD réellement testé

Les trois lots ont démarré à **11:37:30Z**, HEAD =
`47e182bd21c95a71838d408796bebb021c815383`. Le dépôt a bougé **deux fois**
pendant la session (`4857c08` → `47e182b` → `ebcd782`), sous l'action d'une
autre session travaillant dans le même arbre.

`git diff --name-only 47e182b..ebcd782` = **8 fichiers, tous sous
`evidence/world_v2/v2_3_r2b3/iss062/`**. Aucun `.gd`, aucun `.tscn`, aucun
`.tres`, aucun fichier sous `assets/`. Les verdicts ci-dessous valent donc aussi
pour le code et les assets d'`ebcd782`.

## Tableau des lots

| lot | commande | réussis | échoués | RC | durée |
|---|---|---:|---:|---:|---:|
| golden masters | `sha256sum -c …/GM_BASELINE_SHA256.txt` | 6/6 OK | 0 | **0** | <1 s |
| import | `godot --headless --path . --import` | — | — | **0** | 11 s |
| `world_v2` | `test_runner.gd -- --filter=world_v2` | **99** | **0** | **0** | 791 s |
| `boss_arena` | `test_runner.gd -- --filter=boss_arena` | **11** | **0** | **0** | 42 s |
| `boot_smoke` | `test_runner.gd -- --filter=boot_smoke` | **1** (23 assertions) | **0** | **0** | 31 s |
| boot scène (`validate_fast.sh` étape 3) | `godot --headless --path . --quit-after 90` | — | — | **0** | 1 s |
| golden masters (re-contrôle après les lots) | idem | 6/6 OK | 0 | **0** | <1 s |

Contrôles anti-piège passés sur chaque journal :

* la ligne `filtre: <lot>` est présente — le drapeau `--filter=` a bien été lu ;
* nombre de fichiers de test distincts = **31 / 1 / 1**, jamais 193 : la suite
  entière n'est pas partie en silence ;
* **une seule** ligne `=== RÉSULTAT` par journal (piège Q3 de `validate_fast.sh`) ;
* aucun journal vide sur un RC non nul : le verrou n'a jamais expiré ;
* `godot_concurrents avant=0 apres=0` pour les trois lots.

## Comparaison avec les verdicts contaminés

| | verdict contaminé | rejeu isolé | conclusion |
|---|---|---|---|
| `world_v2` (journal `debris/27_world_v2_regression_finale.log`) | 96 / 1, RC=1 — `test_world_v2_skeleton.gd::test_le_squelette_porte_le_vrai_joueur_sans_toucher_la_sauvegarde — slot0 est identique à l'octet près` | **99 / 0, RC=0** ; ce test est `ok` avec **24 assertions** | **CONTAMINATION PROUVÉE** |
| `world_v2` (journal `debris/14_world_v2_regression.log`) | 96 / 1, RC=1 — `test_world_v2_r2b_farm_tree.gd::test_le_pipeline_blender_est_frais_et_verifie` (inspection 205 128 o ≠ GLB 211 336 o) | ce test est `ok` | **VRAI défaut, déjà corrigé** par `3d80fe4` : le journal d'inspection commis annonce aujourd'hui 211 852 o, exactement la taille du GLB |
| `boss_arena` | « 2 armes attendues, 1 obtenue ; 20 flèches, 8 obtenues » — **aucun journal de ce texte n'existe dans le dépôt** | **11 / 0, RC=0** ; `test_the_arena_restores_the_antechamber_checkpoint` est `ok` avec 7 assertions | l'échec annoncé était `NON VÉRIFIÉ` ; il **ne se reproduit pas** en isolation |

Écart 97 → 99 tests entièrement expliqué : le fichier
`test_world_v2_iss059_cache_kit.gd` (2 tests) est apparu avec `47e182b`.
`comm` sur les deux listes de fichiers : **rien n'a disparu**, un seul fichier
s'est ajouté.

## Pourquoi la contamination explique ces deux échecs, mécaniquement

`test_world_v2_skeleton.gd:192-194` lit les octets de `slot0` avant, puis après,
et exige l'égalité. `test_boss_arena.gd:289-310` écrit un checkpoint dans
`user://` puis le relit depuis l'arène et compare armes et flèches. Le coffre
garanti de l'antichambre donne « lame conductrice + 12 flèches » — d'où
`1 arme + 8 flèches` **avant** ouverture et `2 armes + 20 flèches` **après**.
Les chiffres annoncés dans l'échec (`1 obtenue`, `8 obtenues`) sont exactement
l'état **d'avant l'ouverture du coffre** : la signature d'un slot de sauvegarde
écrit ou effacé par un **autre** runner entre l'écriture et la relecture.

Les deux tests sont donc précisément ceux qu'un `user://` partagé peut faire
échouer, et ils passent tous deux dès que `XDG_DATA_HOME` isole `user://`.

## Deux constats qui restent ROUGES ou à traiter

### 1. `boss_arena` fuit à la sortie du processus — reproductible en isolation

```
=== RÉSULTAT: 11 réussi(s), 0 échoué(s) ===
WARNING: 2 ObjectDB instances were leaked at exit …
ERROR: 1 resources still in use at exit …
```

Le runner sort **0** : cette signature arrive **après** son verdict. Mais elle
figure dans `UNIT_ERR_PATTERN` de `tools/validate_fast.sh` (étape 2), qui
marquerait donc ce lot **ROUGE**. `world_v2` et `boot_smoke` sont propres
(0 ligne). Ce n'est pas de la contamination : c'est ISS-059, et le lot porteur
mesuré aujourd'hui est **`boss_arena`**, pas `boot_smoke` — le commentaire de
`validate_fast.sh` (« mesuré sur `--filter=boot_smoke` : 2 instances audio et
`amb_valley.wav` ») ne décrit plus l'état actuel.

### 2. Le cache d'import était périmé avant le rejeu

`SM_Farm_Ruins.glb` et `SM_ThunderstruckTree.glb` avaient un `source_md5` de
cache différent du md5 du fichier, alors que les deux fichiers sont identiques à
HEAD : les correctifs `a6d503f` et `3d80fe4` les ont changés après le dernier
import du 19/08. `--import` a été lancé avant les lots ; après coup les deux
`source_md5` égalent les md5 des fichiers.
