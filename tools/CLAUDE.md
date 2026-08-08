# `tools/` — règles locales

Ne duplique pas le `CLAUDE.md` racine. Ce fichier ne contient que ce qui mord
**ici**, et chaque piège listé a réellement coûté quelque chose.

## Le piège qui échoue en silence : `cmd | tail` masque le code retour

```bash
tools/validate_fast.sh 2>&1 | tail -40      # $? est celui de TAIL, pas du script
```

Commis le 2026-08-08. Le script imprimait `VALIDATE_FAST : ROUGE` et le shell
rendait **0**. Un « portail vert » a été annoncé au propriétaire sur cette base.

```bash
tools/validate_fast.sh > log 2>&1; RC=$?    # sans tube
cmd | tee log; RC=${PIPESTATUS[0]}          # avec tube, si nécessaire
```

## Un script de validation ne retourne JAMAIS 0 sur une étape sautée

`.claude/rules/evidence.md`. Une étape impossible sort en **3 (BLOQUÉ)**, jamais
en 0. `validate_release.sh` le fait ; toute nouvelle étape doit le faire aussi.

Corollaire mesuré : `BLOCKERS` est consommé **au début** de `validate_release.sh`.
Y ajouter une entrée plus bas ne l'affiche nulle part — porter le blocage jusqu'au
verdict par une variable dédiée (voir `BANDS_BLOCKED`).

## Une capture vient d'un arbre COMMITTÉ

Le manifeste doit porter `repo_dirty: false` et le hash du commit prouvé. Ordre :
commiter le code → capturer → commiter la preuve. Une capture prise d'un arbre
sale ne prouve rien et ne doit pas être versée.

## `unproject_position` : l'axe Y ment en exécution `--script`

`probe_north_star_values.gd` rééchelonne vers 1280×720 en supposant le même
rapport d'aspect que la viewport. Une exécution `--script` ne l'a pas. Les
emprises **X sont utilisables, les Y non** — sur ISS-037 elles ont désigné le
mauvais nœud pendant deux itérations.

Pour identifier un nœud à coup sûr, la méthode qui tranche vraiment : **le
repeindre d'une couleur impossible, recapturer, mesurer le pixel.**

## Énumérer par `GeometryInstance3D`, pas `MeshInstance3D`

La végétation est en `MultiMeshInstance3D`. Une sonde qui ne collecte que des
`MeshInstance3D` la déclare absente — silencieusement.

## Godot et Blender ne sont pas dans le dépôt

`tools/setup_godot.sh` (~25 min) et `tools/setup_blender.sh` (~2 min). Sans
Blender, le niveau 3b reste ROUGE : la continuité des personnages n'est **pas**
vérifiée, et c'est le comportement correct.
