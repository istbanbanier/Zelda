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

## Exporter à la main après une chaîne interrompue rend l'ANCIEN maillage

Mesuré le 2026-08-16. Le fichier produit avait un **nom neuf**, une **date
neuve**, et des octets **rigoureusement identiques** à ceux de la veille.

`make_waterfall_cave.py` n'enregistre le `.blend` qu'à la **toute dernière
ligne** de `main()`. Une chaîne qui sort en 2 à mi-parcours laisse donc le
`.blend` de la passe précédente en place. Appeler ensuite l'exporteur à la
main exporte cette source périmée, sans un mot.

Le piège est bien pire qu'un simple export raté, parce que **les mesures qui
suivent, elles, réussissent** : la sonde a rendu « 4 percées confirmées » sur
un maillage ancien traversé par la centerline nouvelle. Un résultat faux,
précis, plausible, et parfaitement inutile.

`tools/blender/export_architecture.sh` s'en protège — il pose un jeton et
compare le mtime du `.glb`. **En l'appelant directement, on perd ce
garde-fou**, et c'est ce que j'ai fait.

Parade, quel que soit le chemin employé :

```bash
sha256sum <nouveau.glb> <ancien.glb>   # identiques = rien n'a ete regenere
```

Règle générale : **avant de mesurer un artefact, prouver qu'il vient d'être
produit.** Un mtime ne le prouve pas, un nom de fichier encore moins. C'est
la même famille que l'ISS-018 — mesurer avec assurance quelque chose qui
n'est pas ce qu'on croit.

## Mesurer la largeur d'une masse « juste sous son sommet » mesure sa PLATITUDE

Mesuré le 2026-08-16, et corrigé **deux fois au même endroit logique** parce que
la première correction n'a pas été propagée.

Pour compter les masses d'une silhouette, on découpe le profil supérieur aux
entailles, puis on veut la largeur de chaque masse. La façon évidente — la
largeur du segment à `sommet - entaille` — est un piège :

```
sommet PLAT  -> segment large  -> bonne note
crête VIVE   -> segment étroit -> mauvaise note
```

C'est **l'inverse** de ce qu'on cherche. Sur la grotte R2a-3.4, les
5,58 / 3,60 / 2,18 m que j'avançais comme preuve de « masses larges » étaient
la mesure des tables horizontales que la revue a rejetées. Un plancher fondé
sur ce nombre **rejette la correction demandée**.

La largeur honnête est l'**emprise** : l'étendue de la masse jusqu'au plus haut
de ses deux cols. Elle ne dit rien de la forme du sommet, et c'est précisément
sa qualité. Publier **les deux** — `sommet` et `emprise` — parce qu'un seul
nombre choisit la réponse avant de mesurer.

Corrigé dans `tools/measure_silhouette_masses.py`, dont l'en-tête porte le
récit. **Non propagé** à `controle_amas` de
`source_assets/blender/environment/make_waterfall_cave.py`, où le même chiffre
condamné a continué de servir de plancher (`LARGEUR_RATIO_MIN`,
`LARGEUR_ECART_MIN`) pendant toute une passe.

Leçon transposable : **quand un défaut de mesure est trouvé dans un outil,
chercher tout de suite les AUTRES endroits qui font la même mesure.** Un
générateur, un test et un outil de revue mesurent souvent la même grandeur avec
trois codes différents.

Corollaire sur les seuils : un seuil calibré sur une géométrie **ensuite
rejetée** n'est pas un plancher de qualité, c'est un plancher du défaut. Le
recalibrer sur la géométrie qu'on est en train de juger serait calibrer sur le
sujet. Changer la mesure **et** fixer de nouveaux seuils dans la même passe est
la manière exacte dont un portail s'affaiblit sans que personne ne mente.

## Une boucle d'attente sur `pgrep -f` se voit elle-même et dort pour toujours

Mesuré le 2026-08-16 : une heure de verrou perdue.

```bash
until ! pgrep -f "make_waterfall_cave" > /dev/null; do sleep 15; done   # NE TERMINE JAMAIS
```

La ligne de commande de la boucle **contient le motif**. `pgrep -f` cherche
dans les lignes de commande complètes, il trouve donc la boucle elle-même, la
condition reste fausse, et l'attente est éternelle. Rien ne le crie : le
processus a l'air de travailler.

C'est le même mécanisme que le piège déjà consigné pour les garde-fous
(`PROMPT4_METHOD` §1) — *« les scripts de garde-fou s'excluent eux-mêmes : le
premier push a été refusé par le plancher attrapant sa propre ligne de
motifs »*. Il se reproduit partout où un script cherche un motif qu'il porte.

Trois parades, de la moins bonne à la meilleure :

```bash
pgrep -f motif | grep -v "^$$\$"        # exclut son propre PID — fragile, oublie les enfants
pgrep -x godot                          # -x compare le NOM du binaire, pas la ligne complète
until grep -q "^RC=" journal; do …      # attend un JETON ÉCRIT PAR LA COMMANDE elle-même
```

La troisième est la seule qui ne dépende pas de la façon dont le processus est
nommé, enveloppé (`flock`, `xvfb-run`, `nohup`) ou relancé. Faire écrire
`echo "RC=$?" >> journal` par la commande surveillée, puis attendre ce jeton.

Corollaire : enchaîner une attente de verrou et un travail lourd dans une même
commande de premier plan expose le tout à être mis en arrière-plan puis tué.
Détacher (`nohup`), et écrire le code retour dans le journal — c'est ce qui
permet de distinguer « tué avant de commencer » de « a échoué ».
