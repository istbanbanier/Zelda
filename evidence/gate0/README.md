# Preuves du Gate 0

**Commit de référence** : `ecca33134c26e9d8405b08e614c5ab2e5550983a`
(« Gate 0 : corrige la TROISIEME revue adverse »).

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
| `validate_fast.log` | `tools/validate_fast.sh` | **0** (VERT, 13 tests, plancher 13) |
| `validate_release.log` | `tools/validate_release.sh` | **3** (BLOQUÉ — attendu) |
| `pipeline_blender_gltf.log` | `tools/blender/run_export.sh` | 0 |
| `pipeline_lab.png` / `.json` | `tools/godot/capture_reference.gd` | 0 |
| `negative_controls/*.log` | contrôles négatifs, voir ci-dessous | 1, 5 ou 6 |

## Contrôles négatifs

Un harnais qui ne peut pas rougir n'a aucune valeur. Les deux revues adverses du
Gate 0 ont chacune démontré qu'il restait vert sur des pannes réelles. Le dossier
`negative_controls/` archive les journaux des scénarios d'échec **réinjectés**,
avec leur code retour :

| Fichier | Scénario | Code |
|---|---|---|
| `D2_erreur_execution.log` | erreur d'exécution GDScript dans un test | 1 |
| `D3_hors_contrat.log` | fichier de test n'étendant pas `GateTestCase` | 1 |
| `N1_ressource_manquante.log` | `load()` d'un asset absent + `push_error` | 1 |
| `N9_parse_error_script_non_reference.log` | erreur de syntaxe dans un `.gd` non référencé | 1 |
| `N3v2_effacement_des_echecs.log` | test tentant d'effacer les échecs enregistrés | 1 |
| `Q1_redefinition_par_tabulation.log` | `func<TAB>check(` pour échapper au scan de source | 1 |
| `Q2_classe_de_base_intermediaire.log` | classe de base intermédiaire redéfinissant `check()` | 1 |
| `Q3_faux_resume.log` | test imprimant un faux « === RÉSULTAT » | 1 |
| `Q4a_geometrie_hors_champ.log` / `Q4a_ciel_*` | cube à z=9000, sans puis avec ciel | 4 / 7 |
| `Q4b_echelle_nulle.log` / `Q4b_ciel_*` | cube à l'échelle nulle, sans puis avec ciel | 4 / 7 |
| `Q4c_derriere_camera.log` / `Q4c_ciel_*` | cube derrière la caméra, sans puis avec ciel | 4 / 7 |
| `B1_perte_de_couverture.log` | fichier de test renommé, tests disparus | 1 |
| `B2_fichier_test_illisible.log` | fichier de test avec erreur de parsing | 1 |
| `nominal_validate_fast.log` | exécution nominale | 0 |
| `nominal_validate_release.log` | exécution nominale de `validate_release.sh` | 3 |

Chaque journal se termine par la ligne `RC=<code>` réellement observée, **et a été
produit par le code du commit de référence**. La 4e revue avait relevé que deux
journaux archivés provenaient d'une version antérieure du script de capture
(chaîne « VisualInstance3D », remplacée depuis) : tous ont été régénérés.

Les variantes `Q4*_ciel_*` reproduisent l'attaque exacte de la revue — un ciel
procédural fournit 906 couleurs distinctes, **plus** que la capture de référence
(705), donc le contrôle d'uniformité ne suffit pas. Elles échouent en **7** grâce
au contrôle de contribution ; les variantes sans ciel échouent plus tôt, en **4**.

## Lecture rapide

- `validate_release.log` sort en **3** et non en 0 : la capture réussit, mais les
  niveaux 4, 6 et 7 ne sont pas exécutés. Un script qui saute des étapes ne
  retourne pas vert. **Ne jamais lire ce 3 comme un PASS de gate visuel.**
- `pipeline_lab.json` porte `commit`, `repo_dirty` et les statistiques de contenu.
  La capture est refusée si la scène ne contient aucune **géométrie visible**
  (`GeometryInstance3D` avec ressource réelle, visible dans l'arbre) **et** si
  masquer cette géométrie ne change pas l'image : c'est la seule preuve qu'elle
  apparaît réellement à l'écran, et non qu'elle existe quelque part dans la scène.

## Ce que ces preuves ne prouvent pas

- **Aucune performance** : le rendu est logiciel (llvmpipe). Aucun budget de frame
  n'en découle.
- **Aucune qualité artistique** : `PipelineLab` vérifie l'outillage, ce n'est pas
  une composition. Le WOW Gate reste non noté.
- **Aucun gameplay** : la Phase A n'a pas commencé.
- **Aucune exhaustivité.** Trois revues adverses successives ont chacune réfuté
  une affirmation d'exhaustivité, la deuxième et la troisième en cassant les
  correctifs de la précédente. Ces contrôles couvrent les classes d'échec
  identifiées à ce jour, rien de plus. Le harnais arrête la perte de signal
  accidentelle ; il n'arrête pas un auteur de test qui mentirait délibérément.
