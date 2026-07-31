# Preuves du Gate 0

**Commit de référence** : `0104b1e7fa185cb07e6b28f030575f08862462ce`
(« Gate 0 : corrige les défauts bloquants trouvés par la revue adverse »).

Tous les fichiers de ce dossier ont été produits **après** ce commit, sur un arbre
dont les seules modifications étaient ces fichiers de preuve eux-mêmes. C'est
pourquoi `env_report.txt` indique `arbre_propre : non` : une preuve datée ne peut
pas être écrite sans salir l'arbre qu'elle décrit. Aucun fichier de code, de scène
ou de documentation n'a changé entre le commit et la production de ces preuves.

## Contenu

| Fichier | Produit par | Code retour |
|---|---|---|
| `env_report.txt` | `tools/env_report.sh` | 0 |
| `validate_fast.log` | `tools/validate_fast.sh` | **0** (VERT) |
| `validate_release.log` | `tools/validate_release.sh` | **3** (BLOQUÉ — attendu) |
| `pipeline_blender_gltf.log` | `tools/blender/run_export.sh` | 0 |
| `pipeline_lab.png` / `.json` | `tools/godot/capture_reference.gd` | 0 |

## Lecture rapide

- `validate_release.log` sort en **3** et non en 0 : la capture réussit, mais les
  niveaux 4, 6 et 7 ne sont pas exécutés. Un script qui saute des étapes ne
  retourne pas vert. **Ne jamais lire ce 3 comme un PASS de gate visuel.**
- `pipeline_lab.json` porte le `commit` et le `repo_dirty` de la capture, ainsi que
  les statistiques de contenu (couleurs distinctes, écart-type de luminance) qui
  prouvent qu'une image a été *rendue* et pas seulement écrite.
- Le champ `png` de la copie archivée a été réécrit pour pointer vers ce dossier ;
  l'original produit par l'outil se trouve dans `evidence/captures/` (non versionné).

## Ce que ces preuves ne prouvent pas

- **Aucune performance** : le rendu est logiciel (llvmpipe). Aucun budget de frame
  n'en découle.
- **Aucune qualité artistique** : `PipelineLab` est une scène de vérification
  d'outillage, pas une composition. Le WOW Gate reste non noté.
- **Aucun gameplay** : la Phase A n'a pas commencé.
