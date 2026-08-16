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

## Deux suites concurrentes fabriquent des échecs de sauvegarde

Le 2026-08-11 : une suite tuée par `pkill` a laissé un godot survivant
(3 processus vivants 1 s après le kill — `pkill` n'attend pas), qui a continué
pendant que la suite suivante démarrait. Les deux partageaient `user://saves`
et le même log : 8 échecs de sauvegarde FABRIQUÉS, une ligne coupée en plein
mot, deux lignes `=== RÉSULTAT`. Les mêmes tests passaient 6/6 isolément.

`validate_fast.sh` sort désormais en 3 (BLOQUÉ) si `pgrep -f test_runner.gd`
trouve un runner. Après un kill, toujours VÉRIFIER la mort réelle avant de
relancer — et se méfier d'un verdict rouge dont le journal porte deux résumés.

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

## Le runner filtré exige `--import` d'abord — sinon il accuse le mauvais coupable

Mesuré le 2026-08-16, sur trois worktrees créés par `git worktree add --detach`.

Un worktree neuf ne contient **aucun `.godot/`**, donc pas de
`global_script_class_cache.cfg`. Sans ce cache, aucun `class_name` n'est
résoluble, et le premier fichier qui en cite un porte le blâme :

```
SCRIPT ERROR: Parse Error: Could not find type "GateTestCase" in the current scope.
          at: GDScript::reload (res://tools/godot/test_runner.gd:215)
```

Ni `GateTestCase` ni `test_runner.gd` ne sont en cause. Le message est
parfaitement crédible et désigne un innocent — on cherche le défaut dans le
test pendant que la cause est un répertoire absent.

`tools/validate_fast.sh` fait l'import lui-même (ligne 76) : le piège
n'apparaît que quand on appelle le runner **directement**, ce qui est
précisément ce qu'on fait quand la suite complète est interdite ou trop
longue. Forme correcte, en un seul verrou :

```bash
flock "$PWD/.git/heavy_tools.lock" -c \
  'cd <worktree> && godot --headless --path . --import > imp.log 2>&1 \
   && godot --headless --path . --script tools/godot/test_runner.gd -- --filter=… > t.log 2>&1'
```

Corollaire plus dangereux : `capture_silhouette.gd` **n'a pas** de garde-fou
de fraîcheur d'import, contrairement à `capture_poi_batch.gd`. Capturer dans
un worktree sans `.godot/` rend une image plausible d'un monde sans assets.

## `--path .` résout contre le cwd, et un sous-agent démarre dans l'arbre PRINCIPAL

Même date. Un appel d'outil shell lancé par un sous-agent hérite du répertoire
de la **session**, pas du worktree de l'agent. Donc :

```bash
flock … -c 'godot --headless --path . …'    # mesure /home/user/Zelda, pas le worktree
```

Un résultat ainsi obtenu porte sur du code que l'agent n'a pas écrit, et rien
dans la sortie ne le crie. Préfixer `cd <worktree> &&`, ou passer `--path` en
absolu.

## Tous les worktrees partagent un seul `user://`

`user://` dérive de `application/config/name`, identique dans tous les arbres :
`/root/.local/share/godot/app_userdata/Eclats d'Orage`. Deux runners
concurrents, même dans des worktrees différents, écrivent donc la même
sauvegarde — c'est le mécanisme d'ISS-038. Un verrou partagé
(`.git/heavy_tools.lock`, `flock`) est la seule protection ; il doit être pris
par **chaque** invocation de Godot ou Blender, quel que soit l'arbre.
