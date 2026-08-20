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

## `flock -w N` : un RC non testé est un résultat PERDU qui ressemble à un résultat

Mesuré le 2026-08-19, R2B.2, par l'audit indépendant sur son propre script.

Quand `flock -w N` expire, il rend **1 et n'exécute PAS la commande**. Une
boucle qui ne teste pas ce code imprime l'en-tête de l'itération suivante et
passe à la vue d'après : le journal montre `### ferme_seuil` puis
`### ferme_facade`, ce qui **ressemble exactement à une progression normale**.
Deux vues ont été perdues ainsi, sans un seul message d'erreur.

```bash
flock -w 3600 /tmp/godot.lock timeout 900 "$GODOT_BIN" ... ; RC=$?
if [ "$RC" -ne 0 ]; then
  echo "BLOQUE: <vue> RC=$RC — verrou non obtenu ou rendu échoué, RIEN écrit" >&2
  exit 3          # jamais 0, jamais « on continue »
fi
```

Deux règles, et la seconde compte autant que la première :

1. **tester le RC après tout `flock`, et s'arrêter au premier échec** plutôt
   que de continuer sur du vide ;
2. **dimensionner `-w` sur la plus longue prise légitime, pas sur son propre
   travail.** Une suite d'intégration tient le verrou **50 minutes** ; un
   `-w 400` (6,7 min) ou un `-w 1800` (30 min) expire alors qu'aucune anomalie
   n'a eu lieu. Une heure est le bon ordre de grandeur quand plusieurs arbres
   de travail partagent la machine.

`validate_fast.sh` ne tombe pas dans ce piège : il utilise `flock -n` et sort
en **3 (BLOQUÉ)**, bruyamment. Le piège est dans les commandes ad hoc.

## Le verrou suit le DÉPÔT, pas le répertoire

Dans un arbre de travail git, `.git` est un **fichier**, pas un dossier :
`$PROJECT_DIR/.git/validate_fast.lock` rend `Not a directory` puis
`flock: 9: Bad file descriptor`, donc **BLOQUÉ (code 3) alors qu'aucune suite ne
tourne**. Mesuré le 2026-08-19 depuis `/home/user/zelda-r2b2/a_ferme`.

`validate_fast.sh` résout désormais son verrou par
`git rev-parse --git-common-dir`. **`--git-common-dir` et non `--git-dir`** :
c'est le `.git` **partagé**, et c'est bien ce qu'on veut — deux arbres de
travail partagent `user://saves`, donc leurs suites doivent se sérialiser.
Dans l'arbre principal la commande rend `.git` relatif, préfixé par
`PROJECT_DIR` : le chemin est identique à l'ancien, au caractère près.

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

## `^` en Python n'est PAS multiligne par défaut — et `re.S` ne le corrige pas

Mesuré le 2026-08-16, deux tours perdus.

```python
re.search(r"^CAVITE = \[\n(?:.*?\n)*?\]", source, re.S)   # ne trouve RIEN
re.search(r"^CAVITE = \[\n(?:.*?\n)*?\]", source, re.S | re.M)   # correct
```

`re.S` (DOTALL) fait que `.` mange les sauts de ligne ; il ne dit **rien** de
`^`, qui reste ancré au début de la chaîne tant que `re.M` est absent. Le
motif a donc l'air multiligne, se lit comme multiligne, et ne peut matcher
qu'à l'offset 0.

Ce qui rend le piège coûteux, c'est la **vérification qui ment ensuite** : j'ai
contrôlé le succès par `grep "1.68,  4.13"` sur le fichier, obtenu une ligne, et
conclu « appliqué ». La ligne venait d'un autre bloc. Un `grep` sur une valeur
qui apparaît à plusieurs endroits ne prouve pas qu'un remplacement précis a eu
lieu.

Deux règles qui en sortent :

1. **Faire échouer bruyamment.** Un `str.replace()` dont le motif est absent ne
   fait rien et ne dit rien. Vérifier la présence avant, ou lever.
2. **Vérifier en relisant l'endroit exact**, pas en cherchant une valeur :
   `sed -n '/^CAVITE = \[/,/^\]/p' fichier` puis lire la ligne attendue.

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

## Quand un rayon cesse de rencontrer des faces, cela veut dire PLEIN

Mesuré le 2026-08-16, sur `tools/audit_cave_floor_columns.py` : **trois verdicts
faux avant un juste**, et les trois sont la même erreur de lecture.

Un rayon descendant qui traverse un solide compte ses impacts par parité :
entre le 1er et le 2e il y a de la matière, entre le 2e et le 3e du vide, et
ainsi de suite. La question piège est celle de la **fin de course** :

| impacts | état après le dernier | signification |
|---|---|---|
| nombre **impair** | **dans la roche** | solide ouvert par le bas — un rocher planté dans le terrain. Le cas le plus SÛR. |
| nombre **pair** | dans l'air | le solide s'est refermé, ou le vide s'échappe vers le bas |

Les trois fautes commises, dans l'ordre :

1. « parité impaire = vide ouvert vers le bas » — l'exact contraire. Trois
   colonnes dont le rayon s'enfonçait de trois mètres **dans** la matière ont
   été déclarées trouées.
2. `sous_plancher = None` quand il n'y a plus d'impact après l'entrée dans le
   plancher, puis `ferme = False`. Même inversion, **autre branche du même
   fichier, vingt minutes plus tard**. Quatre colonnes au sol infiniment épais
   déclarées trouées.
3. Le minimum d'épaisseur ignorait la fenêtre du verdict : après avoir saboté
   les stations terminales, l'outil imprimait encore « minimum 2,521 m », chiffre
   exact mais mesuré à la bouche. **Un chiffre juste au mauvais endroit est un
   chiffre faux.**

La leçon n'est pas « la parité est subtile ». Elle est : cette lecture s'écrit
**une** fois, dans une fonction nommée, et se réutilise — pas une fois par
branche, où on la redérive et où on se trompe. Et tout filtre appliqué au
verdict (`--fenetre`) doit être appliqué **aussi** aux mesures publiées à côté,
sinon les deux répondent à des questions différentes.

Corollaire de méthode, et il vaut pour tout contrôle de ce dépôt : **le
sabotage doit retirer la chose testée, pas ce qui est en dessous.** Un premier
contrôle négatif retirait la matière sous `z = 0` alors que le plancher vit à
`z ≈ 0,1..0,37` : il laissait la peau du plancher intacte, l'outil restait
vert, et on aurait pu en conclure que l'outil était aveugle. Vérifier ce que le
sabotage a réellement enlevé (`SABOTAGE : N triangles retirés`) avant de croire
le verdict qu'il produit.
## `export_architecture.sh` sans argument régénère QUATRE assets gelés

Mesuré le 2026-08-16, par lecture du script — trouvé par l'audit d'intégration
de la passe R2a-3.5.2.

```bash
tools/blender/export_architecture.sh                 # régénère les CINQ sujets
tools/blender/export_architecture.sh waterfall_cave  # celui qu'on voulait
```

`DEMANDE="${1:-}"`, puis dans la boucle :

```bash
[ -n "$DEMANDE" ] && [ "$DEMANDE" != "$ID" ] && continue
```

Quand `DEMANDE` est vide, la garde ne se déclenche jamais et **aucun sujet
n'est sauté**. La liste `SUJETS` contient `pylon`, `stone_bridge`,
`waterfall_cave`, `village_quay`, `village_wall` : oublier un mot réécrit donc
le pylône, le pont et le hameau — **trois des quatre golden masters validés**.

Ce qui rend le piège dangereux, c'est qu'il ne s'ouvre pas par malveillance et
qu'il ne dit rien : la commande réussit, le script imprime son vert, et la
sortie du périmètre ne se voit que dans `git status`, plus tard, quand trois
binaires ont bougé sans raison. C'est la même famille que le vert obtenu en ne
faisant rien, déjà consigné dans ce même script vingt lignes plus haut.

**Règle : l'argument de sujet est obligatoire.** Toute commande de chaîne
écrite dans un document, un script, un journal de preuve ou un rapport le porte
explicitement. Une commande citée de mémoire sans sujet est un défaut de
rédaction, pas une abréviation.

Contrôle après coup, avant de mesurer quoi que ce soit :

```bash
git status --porcelain assets/    # doit ne montrer QUE l'asset visé
```

## `blender --background --python` rend **0** même quand le script lève

Mesuré le 2026-08-17. Deux exécutions ont rendu `RC=0` en ayant échoué.

Blender attrape l'exception du script, l'imprime sur la sortie, puis **quitte
normalement**. Le shell voit 0. Un banc qui ne vérifie que le code retour conclut
donc « vert » sur un script qui n'a rien exécuté — et **tout banc Blender de ce
dépôt est exposé**, y compris ceux qui mesurent une géométrie.

L'option `--python-exit-code 1` existe et corrige le cas nominal ; elle ne
couvre pas les scripts qui rattrapent eux-mêmes leur exception, ni les échecs
survenus après le script.

Parade, la seule qui ne dépende pas de la façon dont Blender est lancé :

```python
print("FIN NOMINALE")      # DERNIERE ligne du script, apres tout le travail
```

```bash
grep -q "FIN NOMINALE" journal || echo "ECHEC quel que soit RC"
```

C'est la même famille que le jeton `^RC=` déjà consigné plus haut pour les
attentes de verrou : **faire écrire la preuve de succès par la chose surveillée
elle-même**, jamais l'inférer de son enveloppe.

Cas concret rencontré : placer un générateur témoin dans `/tmp` casse
`KIT_ROCHES = parents[3]`, qui remonte trois répertoires depuis `__file__`. Le
script lève, Blender rend 0, et la mesure qui suit porte sur une scène vide.
Corollaire : **ne jamais copier un script de génération hors de son arbre** — il
lit son propre chemin pour trouver ses ressources.

## `diff` sur deux fichiers ABSENTS rend un diff vide, donc `exit 0`

Mesuré le 2026-08-17. Une comparaison a imprimé « IDENTIQUE » **sans rien
comparer**.

```bash
diff a.log b.log && echo IDENTIQUE     # a.log et b.log n'existent pas -> IDENTIQUE
```

`diff` sur des chemins inexistants n'a rien à signaler ; il rend 0, et le `&&`
s'exécute. Le message est vrai au sens littéral — les deux ensembles vides sont
identiques — et faux au sens qui compte.

Parade : **compter ce qui a été réellement comparé**, et le publier.

```bash
[ -s a.log ] && [ -s b.log ] || { echo "ECHEC: fichier absent ou vide"; exit 2; }
n=$(diff a.log b.log | wc -l); echo "$(wc -l < a.log) lignes comparees, $n differences"
```

Même famille que `blender --background` qui rend 0 en ayant levé, et que le
`RC=0` d'un journal mort : **une commande qui réussit en ne faisant rien**. La
règle générale du dépôt, retrouvée une troisième fois en une seule passe :

> un verdict doit publier **la taille de ce qu'il a examiné**, pas seulement son
> résultat. Un « aucune différence » sans « sur N lignes » ne prouve rien.

## Un triangle dégénéré est une propriété d'AIRE, jamais d'indices

Mesuré le 2026-08-17. Un triangle d'aire **exactement nulle** vivait dans un GLB
candidat sans qu'aucun outil du dépôt puisse le voir.

`tools/cave_check_mesh.py` soude les sommets par position quantifiée, puis retire
les faces dégénérées par **égalité d'indices** après remap :

```python
degenere = (ra == rb or rb == rc or ra == rc)     # ne voit que les doublons
```

Une **T-jonction** — trois sommets distincts et colinéaires, le milieu posé sur
l'arête — reçoit trois indices distincts. Elle passe. Démonstration fermée :

```
b milieu exact de a-c, segment 0,482 m
test topologique -> PASSE, l outil ne voit rien
aire exacte      -> 0.0, donc DEGENERE
```

Le produit vectoriel est exactement `(0,0,0)` et `c - a = 2·(b - a)` exact : ce
n'est pas un problème de tolérance, c'est un problème de **grandeur mesurée**.

Parade : mesurer l'aire par produit vectoriel, et publier la **distribution** des
petites aires — pas seulement un compte de zéros. Un seuil unique ne distingue
pas une lamelle fine d'une face nulle ; la distribution, si.

Même famille qu'ISS-018 : **un test vert sur une grandeur qui n'est pas celle
qu'on croit mesurer.** Quand un défaut échappe à un contrôle, demander d'abord ce
que le contrôle mesure réellement, avant de douter du défaut.

## Annoter un journal pendant qu'un processus y écrit **efface l'annotation**

Mesuré le 2026-08-17, et le résultat est un fichier **propre, complet et faux**.

Un agent a annoté « journal abandonné » à la fin d'un log **pendant que le
processus tournait encore**. Un `>>` écrit à la fin **courante** du fichier ; le
processus, lui, continue d'écrire à **son propre offset**, qu'il a mémorisé. Il
repasse donc par-dessus l'annotation et la fait disparaître.

Le fichier se lit ensuite comme une exécution normale et achevée, **sans aucune
trace du fait qu'il mesurait une géométrie abandonnée**. Un lecteur ultérieur le
prend pour un résultat sur le livrable. C'est pire qu'un journal tronqué : un
tronqué se voit, celui-ci non.

Parade, dans cet ordre :

```bash
until grep -q "^RC=" journal; do : ; done      # attendre le jeton, jamais avant
echo "ABANDONNE : mesurait <quoi>" >> journal   # annoter APRES
grep -c "ABANDONNE" journal                     # RELIRE pour verifier
```

**Annoter seulement après le jeton `RC=`, puis relire.** Une annotation qu'on n'a
pas relue n'est pas une annotation.

C'est la même faute, dans la même session, que le stub de
`bpy.ops.wm.save_as_mainfile` écrit et jamais observé : `bpy.ops.wm` re-résout par
`__getattr__`, le jeton de neutralisation n'est jamais sorti, et la course a
réécrit le `.blend` qu'on croyait protégé.

> **Un garde-fou vaut par son observation, pas par son intention.** Écrire qu'on
> protège quelque chose et ne pas vérifier que la protection s'est déclenchée est
> la façon la plus régulière de fabriquer une preuve fausse dans ce dépôt.

## Un conteneur recréé laisse `.godot/imported` décrire un checkout PLUS ANCIEN

Mesuré le 2026-08-20, ouverture de R2B.3. Le conteneur avait été recréé sur
`c44f430b` — **64 commits en retard** sur la branche poussée. Après
`git merge --ff-only`, les fichiers `.glb` étaient ceux de R2B.2, mais
`.godot/imported/` décrivait encore la géométrie d'avant.

`tools/godot/capture_poi_batch.gd` a refusé de capturer, code **3** :

```
[poi] BLOQUÉ : 2 asset(s) modifié(s) depuis leur import. La capture rendrait
la GÉOMÉTRIE PRÉCÉDENTE, et l'image serait parfaitement crédible.
```

C'est le garde-fou qui a fonctionné, pas le piège. **Le piège est ce qui serait
arrivé sans lui** : un lot de captures montrant l'ancienne ferme, avec un
manifeste correct, un `repo_dirty: false` correct et un sha256 de GLB correct —
puisque le GLB, lui, est bien le nouveau. Rien dans la preuve n'aurait signalé
que l'image ne vient pas du fichier annoncé.

Deux conséquences opérationnelles :

1. **Après tout `git merge`, `checkout`, `cherry-pick` ou recréation de
   conteneur qui touche un `.glb`, relancer `godot --headless --path . --import`
   AVANT toute capture ou toute mesure lue depuis le moteur.**
2. Un outil qui rend une image ou une géométrie doit **comparer le mtime de la
   source à celui de son import** et bloquer, pas avertir. Un avertissement dans
   un journal de 400 lignes ne sera pas lu ; un code 3 arrête la passe.

Corollaire pour les mesures **hors moteur** (`gltf_inspect.py`,
`mesure_boititude.py`) : elles lisent le `.glb` directement et ne sont donc
**pas** concernées. D'où un écart possible et déroutant — l'outil Python dit
« 96,8 % » sur la nouvelle géométrie pendant que le moteur dessine l'ancienne.
Quand un chiffre et une image se contredisent, **soupçonner le cache d'import
avant de soupçonner la mesure**.
