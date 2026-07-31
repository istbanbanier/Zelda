# Preuves du Gate 0

**Commit de référence** : `b1ba9b9a992b170714938c29ed94fb1db629e238`
(« Gate 0 : corrige les défauts de la SECONDE revue adverse »).

Tous les fichiers de ce dossier ont été produits **après** ce commit, sur un arbre
dont les seules modifications étaient ces fichiers de preuve eux-mêmes. C'est
pourquoi `env_report.txt` indique `arbre_propre : non` et le manifeste de capture
`"repo_dirty": true` : une preuve datée ne peut pas être écrite sans salir l'arbre
qu'elle décrit. Aucun fichier de code, de scène ou de documentation n'a changé
entre le commit et la production de ces preuves.

**Aucun de ces fichiers n'a été retouché à la main** — la version précédente de ce
dossier contenait un manifeste dont le champ `png` avait été réécrit après coup, ce
qui en faisait autre chose qu'un artefact machine. Le champ `png` de
`pipeline_lab.json` pointe donc vers `evidence/captures/`, chemin de production
(non versionné) ; le PNG identique est archivé ici à côté.

## Contenu

| Fichier | Produit par | Code retour |
|---|---|---|
| `env_report.txt` | `tools/env_report.sh` | 0 |
| `validate_fast.log` | `tools/validate_fast.sh` | **0** (VERT, 12 tests) |
| `validate_release.log` | `tools/validate_release.sh` | **3** (BLOQUÉ — attendu) |
| `pipeline_blender_gltf.log` | `tools/blender/run_export.sh` | 0 |
| `pipeline_lab.png` / `.json` | `tools/godot/capture_reference.gd` | 0 |
| `negative_controls/*.log` | contrôles négatifs, voir ci-dessous | 1, 5 ou 6 |

## Contrôles négatifs

Un harnais qui ne peut pas rougir n'a aucune valeur. Les deux revues adverses du
Gate 0 ont chacune démontré qu'il restait vert sur des pannes réelles. Le dossier
`negative_controls/` archive les journaux des scénarios d'échec **réinjectés**,
avec leur code retour :

| Fichier | Scénario | Code attendu |
|---|---|---|
| `N9_parse_error_script_non_reference.log` | erreur de syntaxe dans un `.gd` non référencé | 1 |
| `N1_ressource_manquante_push_error.log` | `load()` d'un asset absent + `push_error` | 1 |
| `N3_contournement_contrat.log` | test neutralisant le contrat pour masquer 2 assertions fausses | 1 |
| `N4_scene_sans_geometrie.log` | capture d'une scène ciel + caméra, zéro mesh | 5 |
| `N5_commit_indetermine.log` | capture avec `git` indisponible | 6 |
| `N2_playthrough_collecte.log` | test déposé dans `tests/playthrough/` | 1 |

## Lecture rapide

- `validate_release.log` sort en **3** et non en 0 : la capture réussit, mais les
  niveaux 4, 6 et 7 ne sont pas exécutés. Un script qui saute des étapes ne
  retourne pas vert. **Ne jamais lire ce 3 comme un PASS de gate visuel.**
- `pipeline_lab.json` porte `commit`, `repo_dirty` et les statistiques de contenu.
  La capture est en outre refusée si la scène ne contient aucun `VisualInstance3D`.

## Ce que ces preuves ne prouvent pas

- **Aucune performance** : le rendu est logiciel (llvmpipe). Aucun budget de frame
  n'en découle.
- **Aucune qualité artistique** : `PipelineLab` vérifie l'outillage, ce n'est pas
  une composition. Le WOW Gate reste non noté.
- **Aucun gameplay** : la Phase A n'a pas commencé.
- **Aucune exhaustivité** : les contrôles négatifs couvrent les classes d'échec
  identifiées par deux revues. Rien ne garantit qu'il n'en reste aucune autre.
