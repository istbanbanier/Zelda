# ISS-063 — inventaire des points d'entrée Godot

Passe V2.3-A.R2B.3.1, audit statique. Dépôt `/home/user/Zelda`, branche
`claude/world-v2-reconstruction`, HEAD `06b865b`.

**Méthode : lecture seule.** Aucune commande n'a été exécutée : ni le moteur, ni
Blender, ni une suite, ni un verrou. Tout ce qui suit est établi par lecture de
fichiers et par recherche de motifs. Ce que cela ne prouve pas est en dernière
section.

---

## 1. Ce que fait `tools/lancer_godot.sh`

Lu en entier (253 lignes).

**Verrou.** `tools/lancer_godot.sh:178-184` résout
`git -C "$RACINE" rev-parse --git-common-dir`, avec repli `"$RACINE/.git"` si git
répond vide, et préfixe le résultat par la racine s'il est relatif. Le chemin
final est `<git-common-dir>/heavy_tools.lock` — dans l'arbre principal,
`/home/user/Zelda/.git/heavy_tools.lock`. `--git-common-dir` et non `--git-dir` :
c'est le `.git` **partagé** entre arbres de travail, donc le verrou suit le
dépôt. Le verrou est pris sur le descripteur 9, séparément de la commande
(`:196` ouverture, `:207` `flock -w "$ATTENTE" 9`), pour qu'un échec de verrou ne
puisse pas être confondu avec un échec de la commande. Défaut d'attente 3000 s.

**Cloison.** `:150` `USER_DIR="$(mktemp -d /tmp/lancer_godot_ud_XXXXXXXX)"`, puis
`:247` `XDG_DATA_HOME="$USER_DIR" "${CMD[@]}"`. Un répertoire neuf par invocation.
Ménage par `trap` sur EXIT/INT/TERM/HUP (`:157-175`), avec garde `case` qui refuse
de `rm -rf` un chemin ne commençant pas par `/tmp/lancer_godot_ud_`. `--garder-user`
conserve le répertoire et imprime son chemin.

**Ce qu'il refuse.**

| Refus | Ligne | Code |
|---|---|---|
| `--attente=` non entier | `:114-118` | 2 |
| aucun argument pour Godot | `:120-124` | 2 |
| `--filtre` / `--filtre=…` (le runner lit `--filter=`) | `:134-139` | 2 |
| `--filter` sans `=` (ignoré en silence par le runner) | `:140-144` | 2 |
| verrou impossible à ouvrir | `:196-202` | 3 |
| verrou non obtenu après `$ATTENTE` s | `:207-214` | 3 |

**Ce qu'il ajoute.** `--headless` si `--rendu` est absent (`:234-237`) ; retire
`--headless` et enveloppe dans `xvfb-run` si `--rendu` est présent (`:218-229`).

**Jeton.** `RC_GODOT=<n>` en `:252`, écrit **uniquement** si le moteur a été
lancé. Son absence est la preuve que rien n'a tourné.

---

## 2. Contrat annoncé — `docs/KNOWN_ISSUES.md:1923`

Le ticket est titré **« trois mutex distincts, et `user://` partagé entre tous
les worktrees — S2, OUVERT »**. Il énonce :

- trois verrous indépendants : `.git/heavy_tools.lock`, `validate_fast.lock`,
  `/tmp/godot.lock` ;
- « deux invocations qui prennent chacune un verrou différent **tournent en
  parallèle**  » ;
- remède immédiat : prendre **les deux verrous du dépôt, imbriqués** ;
- **« Remède de fond, non fait : un seul verrou, pris par tout ce qui lance
  Godot, et un `user://` distinct par arbre de travail. »**

`docs/STATUS.md:30` décrit ISS-063 comme « démontré et corrigé » par
`lancer_godot.sh`. Les deux textes ne disent pas la même chose : `KNOWN_ISSUES`
dit que le remède de fond n'est pas fait, et il a raison — voir §4.

---

## 3. Inventaire des points d'entrée

Colonnes : **verrou** = quel mutex l'invocation prend elle-même ;
**XDG** = `XDG_DATA_HOME` positionné ; **wrapper** = passe par
`tools/lancer_godot.sh` ; **`user://`** = partagé avec les autres processus du
conteneur ; **RC** = le code retour de Godot est relevé et propagé.

### 3.1 Exécutables du dépôt qui lancent réellement le moteur

| chemin:ligne | verrou | XDG | wrapper | `user://` | RC |
|---|---|---|---|---|---|
| `tools/lancer_godot.sh:229` (`--rendu`, via xvfb-run) | `heavy_tools.lock` | **isolé** (`mktemp`) | (c'est lui) | isolé | oui (`RC_GODOT=`) |
| `tools/lancer_godot.sh:238` (headless) | `heavy_tools.lock` | **isolé** | (c'est lui) | isolé | oui |
| `tools/godot/matrice_iss059.sh:21` | via wrapper | via wrapper | **oui** | isolé | oui (`rc` + `RC_GODOT=`) |
| `tools/validate_fast.sh:91` (`--import`) | `validate_fast.lock` **seul** | non | non | **PARTAGÉ** | oui (`IMPORT_RC`) |
| `tools/validate_fast.sh:114` (`--check-only`, boucle) | `validate_fast.lock` | non | non | **PARTAGÉ** | oui (testé par `if !`) |
| `tools/validate_fast.sh:132` (test_runner) | `validate_fast.lock` | non | non | **PARTAGÉ** | oui (`UNIT_RC`) |
| `tools/validate_fast.sh:165` (`--quit-after 90`) | `validate_fast.lock` | non | non | **PARTAGÉ** | oui (`SCENE_RC`) |
| `tools/validate_fast.sh:82` (`--version`) | `validate_fast.lock` | non | non | s.o. | non |
| `tools/validate_release.sh:50` (capture) | **aucun** | non | non | **PARTAGÉ** | oui (`CAP_RC`) |
| `tools/validate_release.sh:69` (North Star) | **aucun** | non | non | **PARTAGÉ** | oui (`NS_RC`) |
| `tools/capture_vslice_gate.sh:92` | **aucun** | non | non | **PARTAGÉ** | à vérifier (non lu en détail) |
| `tools/capture_ab.sh:102` | **aucun** | non | non | **PARTAGÉ** | via `RUN` |
| `tools/capture_ab.sh:128` (`--import` d'un worktree) | **aucun** | non | non | **PARTAGÉ** | oui (`|| {`) |
| `tools/gate_negative_control.sh:125` | **aucun** | non | non | **PARTAGÉ** | capturé en substitution |
| `tools/gate_negative_control.sh:143` | **aucun** | non | non | **PARTAGÉ** | capturé en substitution |
| `tools/gate_select.sh:104` (test_runner filtré) | **aucun** | non | non | **PARTAGÉ** | oui (`RC=$?`) |
| `tools/godot/run_iss059_scenarios.sh:18` | **`/tmp/godot.lock` seul** | non | non | **PARTAGÉ** | oui (`RC=$?`, sort 3) |
| `tools/lancer_godot_autotest.sh:166` | `heavy_tools.lock` (`:165`) | **partagé volontairement** | non | partagé **exprès** | oui |
| `tools/lancer_godot_autotest.sh:169` | idem | idem | non | partagé **exprès** | oui |
| `tools/env_report.sh:23` (`--headless --quit`) | **aucun** | non | non | **PARTAGÉ** | non (avalé par `&&`) |
| `tools/env_report.sh:22` (`--version`) | **aucun** | non | non | s.o. | non |
| `tools/manual_validation_kit.sh:45` (`--version`) | **aucun** | non | non | s.o. | non |
| `.githooks/pre-push:73` (`--check-only`, par fichier) | **aucun** | non | non | **PARTAGÉ** | oui (`if !`) |
| `tools/blackbox_player/server.py:206-211` (Popen) | **aucun** | **isolé** (`:203`, `OUT_DIR/user_home`) | non | isolé | non (Popen détaché) |

`tools/lancer_godot_autotest.sh:166/169` est le **contrôle négatif** du wrapper :
il partage `user://` délibérément pour démontrer la fuite. Il prend bien
`heavy_tools.lock` (`:165`). Ce n'est pas un contournement, c'est une
démonstration ; à conserver tel quel.

`tools/setup_godot.sh:19`, `:21` et `:54` exécutent `"$DEST" --version`. Sans
projet, donc sans `user://` ; sans verrou. Impact nul, cité pour l'exhaustivité.

### 3.2 Lancements indirects — un appelant qui ne sait pas qu'il lance le moteur

| chemin:ligne | ce qu'il lance | conséquence |
|---|---|---|
| `tools/blackbox_player/check_camera.py:36` | `server.py` en sous-processus | lance Godot sans verrou |
| `tools/blackbox_player/smoke_test.py:39` | `server.py` en sous-processus | idem |
| `tools/blackbox_player/play.sh:71-100` | `claude -p --mcp-config` → `server.py` | idem, **et** `:35` tue par `pgrep -x godot` |
| `tools/blackbox_player/negative_controls.sh:26,46` | idem | idem |
| `.mcp.json` (racine, serveur `blackbox`) | `python3 tools/blackbox_player/server.py` | **voir §3.3** |

`play.sh:35` et `negative_controls.sh:26` exécutent
`for pid in $(pgrep -x Xvfb) $(pgrep -x godot); do kill "$pid"; done` **avant** de
démarrer, et `play.sh:105` le refait après. C'est une seconde faille du même
ticket, dans l'autre sens : ce n'est pas seulement un lancement hors verrou,
c'est une **mise à mort** hors verrou de tout moteur du conteneur — y compris
une suite `validate_fast` d'un autre arbre de travail, qui tient pourtant son
propre verrou. Un verrou ne protège pas d'un `kill`.

### 3.3 Le contournement qui n'est pas une commande shell

`.mcp.json` à la racine du dépôt déclare le serveur MCP `blackbox` :

```
"command": "python3", "args": ["tools/blackbox_player/server.py"]
```

Toute session Claude Code démarrée dans ce dépôt charge ce serveur au
démarrage. Un appel d'outil `mcp__blackbox__game_observe` suffit à faire
démarrer Xvfb puis Godot (`server.py:195` puis `:210`) **sans qu'aucune ligne de
shell ne soit écrite**. Aucun garde-fou de commande — hook, alias, wrapper,
`PATH` — ne peut voir ce lancement. `XDG_DATA_HOME` y est isolé (`:203`), donc
`user://` ne fuit pas ; mais aucun verrou n'est pris, et la contention CPU et le
`kill` de §3.2 restent entiers.

C'est le contournement le plus complet de l'inventaire : il échappe à la fois au
lanceur et à tout garde-fou de niveau shell.

### 3.4 Workflows GitHub

| chemin:ligne | nature |
|---|---|
| `.github/workflows/publish-playtest.yml:170` | `"$G" --headless --path . --import` |
| `.github/workflows/publish-playtest.yml:224` | `--export-release "Linux x86_64"` |
| `.github/workflows/publish-playtest.yml:236` | `--export-release "Windows Desktop"` |
| `.github/workflows/publish-playtest.yml:250` | `--export-release "macOS"` |
| `.github/workflows/publish-playtest.yml:284` | `--export-release "Web"` |

Le binaire est téléchargé dans le job (`:162-169`), pas `$GODOT_BIN`. Aucun
verrou, aucun `XDG_DATA_HOME`. **Nuance honnête : ces cinq sites tournent sur un
runner GitHub éphémère, pas dans ce conteneur** — ils ne partagent le `user://`
de personne et ne sont pas la cause d'ISS-063. Ils comptent quand même dans un
inventaire « tous les points d'entrée », parce qu'un correctif fondé sur un
wrapper local ne les couvre pas et ne peut pas les couvrir.

`asset-courier.yml`, `world-asset-library.yml` et `cleanup-releases.yml` ne
lancent pas le moteur (vérifié par recherche de motif).

### 3.5 Documentation copiable-collable — le vecteur le plus fréquent

Ce n'est pas du code exécutable, mais c'est ce qu'une session **copie** quand
elle veut lancer une sonde. Compté :

| source | compte | contenu |
|---|---|---|
| `.gd` avec un `godot --…` en en-tête | **46 fichiers**, 53 lignes | `godot --headless --path . --script tools/godot/<sonde>.gd` |
| dont citant `tools/lancer_godot.sh` | **1** (`tools/godot/sonde_iss059_proprietaire.gd:38`) | |
| `CLAUDE.md:80-83` (racine, chargé à chaque session) | 4 lignes | les quatre commandes nues, sans wrapper |
| `tools/CLAUDE.md:52,137-138,151,528` | 5 lignes | dont `flock … /tmp/godot.lock`, le **troisième** verrou |
| `.claude/agents/godot-researcher.md:21` | 1 | `godot --version` |
| `.claude/agents/test-coverage-auditor.md:130` | 1 | `godot --headless --path . --script …test_runner.gd -- --filter=<nom>` |
| `.sh` sous `evidence/` lançant le moteur | 4 fichiers sur 7 | scripts de passes antérieures, rejouables |

Le `CLAUDE.md` racine est le point le plus lourd : il est chargé
automatiquement dans **chaque** session, il donne les quatre commandes nues sous
« Commandes réelles », et il ne mentionne nulle part `tools/lancer_godot.sh`. Une
session qui suit son fichier de règles contourne le lanceur — non par
négligence, mais **parce qu'on le lui a dit**.

---

## 4. Les trois mutex : lequel est réellement pris, et par qui

| verrou | pris par | fichiers |
|---|---|---|
| `<git-common-dir>/heavy_tools.lock` | 3 sites | `tools/lancer_godot.sh:184`, `tools/lancer_godot_autotest.sh:47`, `tools/cave_oracle_batterie.py:133` (Blender) |
| `<git-common-dir>/validate_fast.lock` | **1 site** | `tools/validate_fast.sh:65` |
| `/tmp/godot.lock` | **1 site** | `tools/godot/run_iss059_scenarios.sh:18` |

Les trois ensembles sont **disjoints**. Conséquences, énoncées sans atténuation :

1. **`validate_fast.sh` ne prend pas `heavy_tools.lock`.** C'est le plus gros
   consommateur de moteur du dépôt (quatre invocations, ~20 min, `user://saves`
   écrit par le runner). Il ne se sérialise avec `lancer_godot.sh` sur **aucun**
   verrou. Deux processus qui prennent des verrous différents ne sérialisent
   rien : ils tournent en parallèle.
2. **`lancer_godot.sh` ne prend pas `validate_fast.lock`** — alors que son
   propre en-tête (`:23`) le **nomme** comme le mutex n°1 du dépôt. Nommer un
   verrou n'est pas le prendre. Symétrie exacte du point 1.
3. **`/tmp/godot.lock` est pris par un seul script du dépôt** et par la
   convention documentée dans `tools/CLAUDE.md:52`. Il ne croise ni l'un ni
   l'autre des deux précédents.
4. **Dix sites listés en §3.1 ne prennent aucun verrou du tout** :
   `validate_release.sh` ×2, `capture_vslice_gate.sh`, `capture_ab.sh` ×2,
   `gate_negative_control.sh` ×2, `gate_select.sh`, `env_report.sh`,
   `.githooks/pre-push`, plus `server.py`. `pre-push` est le plus gênant : il se
   déclenche sur un geste ordinaire (`git push`) et lance un moteur par fichier
   `.gd` modifié.
5. **Les quatre scripts Blender de `tools/blender/` ne prennent aucun verrou**
   (`export_architecture.sh`, `export_cave_echafaudage.sh`,
   `rebuild_characters.sh`, `run_export.sh` : `flock` = 0 dans chacun), alors
   que `heavy_tools.lock` est défini comme sérialisant « TOUT usage lourd de
   Godot **ou Blender** ». Seul `cave_oracle_batterie.py` le prend, et seulement
   si on ne lui passe pas `--verrou` autre chose.

La seule protection croisée existante est **partielle** :
`validate_fast.sh:69` refuse de démarrer si `pgrep -f "test_runner\.gd"` trouve
un processus. Elle ne voit qu'un runner de tests — pas un `--import`, pas une
capture, pas une sonde, pas le joueur boîte noire, et pas un moteur lancé par
`lancer_godot.sh`. Et elle est aveugle dans l'autre sens : rien n'empêche
`gate_select.sh` de démarrer pendant `validate_fast`.

**Verdict sur le contrat d'ISS-063 : PARTIAL.** La cloison `XDG_DATA_HOME` est
réelle et correcte **dans les deux sites qui l'implémentent** (`lancer_godot.sh`,
`server.py`). Elle est absente des vingt autres. Le « remède de fond » annoncé
non fait dans `KNOWN_ISSUES` reste non fait : il n'y a pas un seul verrou, et le
`user://` par défaut reste partagé par tout ce qui ne passe pas par le wrapper.

---

## 5. Correctif proposé — sans le dépendre de la discipline d'appel

Rappel de la directive : *« Le correctif ne doit pas dépendre uniquement d'un
lanceur que certains scripts peuvent contourner. »* Les quatre pistes demandées,
évaluées, puis une recommandation.

### Piste A — garde-fou `PreToolUse` refusant un appel Godot nu

`.claude/settings.json` ne déclare aujourd'hui que `SessionStart` et `Stop`. Il
n'existe **aucun** hook `PreToolUse` : une commande `godot --headless …` tapée
dans un appel Bash n'est interceptée par rien.

- **Coût** : faible. Un script bash qui lit le JSON de la commande proposée et
  rend un refus si elle contient le binaire sans être `tools/lancer_godot.sh`.
- **Ce qu'il attrape** : les commandes ad hoc, qui sont — d'après §3.5 — le
  vecteur dominant, puisque le `CLAUDE.md` racine les enseigne.
- **Angles morts, et ils sont larges** : (a) il ne voit **rien** de §3.3,
  l'appel MCP n'étant pas une commande shell ; (b) il ne voit pas un moteur
  lancé **à l'intérieur** d'un script du dépôt (`bash tools/gate_select.sh` est
  une commande innocente) ; (c) il ne s'applique qu'aux sessions Claude Code, pas
  à `pre-push`, pas à un `cron`, pas à un humain ; (d) c'est un contrôle sur du
  **texte de commande**, donc contournable par `sh -c`, une variable, un alias.
- **Faux positifs** : réels. Ce document, `tools/CLAUDE.md`, et tout script
  parlant du binaire portent le motif. Le hook devrait s'exclure lui-même — le
  piège déjà consigné dans `PROMPT4_METHOD` §1.

### Piste B — test d'invariant scannant le dépôt

`tests/unit/test_invariants.gd` existe (163 lignes, 7 tests) et **fait déjà
exactement ce geste** : `_collect()` (`:99-115`) balaie `SCANNED_ROOTS` et
applique une règle par fichier. L'étendre est mécanique.

- **Forme** : un test qui balaie `tools/`, `.githooks/`, `.github/workflows/`,
  `scripts/` et échoue sur tout fichier contenant une invocation du binaire qui
  ne passe pas par le lanceur, avec une **liste d'exemptions nommée et
  justifiée** (`lancer_godot.sh` lui-même, `lancer_godot_autotest.sh` qui est le
  contrôle négatif, `setup_godot.sh`, les workflows GitHub).
- **Coût** : faible à moyen. Le squelette est là ; il faut mesurer la dette
  d'abord (§3.1 donne 24 sites) et décider ce qu'on exempte.
- **Ce qu'il attrape** : **tout ce qui est versionné**, y compris `pre-push`,
  les workflows, et l'entrée `.mcp.json` si on l'ajoute au balayage. C'est le
  seul mécanisme de la liste qui voie §3.3.
- **Angle mort décisif** : il ne voit **jamais** une commande tapée à la volée.
  Un agent qui écrit `godot --headless --path . --import` dans un appel Bash
  n'écrit aucun fichier, donc aucun test ne rougit.
- **Précaution** : ce test appartient à `validate_fast`, qui met ~20 min. Il
  rougit donc tard. Le doubler d'une règle `pre-push` le rend utile plus tôt.

### Piste C — fonction shell commune sourcée par tous les scripts

- **Coût** : moyen — 24 sites à modifier, tous les scripts à retester.
- **Ce qu'il attrape** : les scripts du dépôt, correctement. C'est le geste qui
  **résout réellement** le problème plutôt que de le signaler.
- **Angle mort, et c'est le fond du sujet** : c'est exactement « dépendre de la
  discipline d'appel », déplacée d'un cran. Rien n'oblige le 25ᵉ script à sourcer
  la fonction. Sans un contrôle qui vérifie qu'on l'a fait, la dérive
  recommence — et c'est la définition même d'un invariant qui se dégrade en
  silence.

### Piste D — réglage projet côté Godot

Aucun réglage de `project.godot` ne déplace `user://` : il dérive de
`application/config/name` et de `XDG_DATA_HOME`, mesuré et consigné dans
`lancer_godot.sh:8-13`. Changer `config/name` par arbre de travail rendrait les
sauvegardes non comparables entre arbres et casserait `tools/dev_report.py:24-26`,
qui code en dur `app_userdata/Eclats d'Orage`. **Écarté.** Aucun réglage projet ne
peut poser un verrou : un verrou est un fait du système de fichiers, pas une
préférence d'application.

### Ce que je recommande

**B + C, dans cet ordre, et pas A seul.**

1. **D'abord C** (la fonction commune, ou plus simplement : faire passer les 24
   sites par `lancer_godot.sh`, en commençant par `validate_fast.sh`), parce que
   c'est le seul des quatre qui **répare** au lieu de signaler. Priorité au sein
   de C : `validate_fast.sh` et `.githooks/pre-push` — le premier parce que c'est
   le plus gros consommateur et qu'il ne se sérialise avec rien, le second parce
   qu'il se déclenche sur un geste quotidien.
2. **Puis B** (le test d'invariant), parce que sans lui, C se dégrade au
   prochain script écrit. B est ce qui rend C durable : il transforme
   « on a corrigé 24 sites » en « le 25ᵉ ne peut pas être écrit ».
3. **A en complément, pas en remplacement**, si le propriétaire accepte son coût
   de faux positifs. Il couvre le seul angle que B ne voit pas — la commande
   jetée à la volée — mais il ne couvre rien d'autre.

**Ce que cette recommandation ne couvre pas, dit clairement :**

- **§3.3, le serveur MCP.** B le voit dans `.mcp.json`, mais interdire l'entrée
  interdirait le joueur boîte noire. Ce qu'il faut, c'est que `server.py` prenne
  `heavy_tools.lock` avant son `Popen` — un changement dans le serveur, pas dans
  un garde-fou. Et **le `kill` de `play.sh:35`/`:105` et de
  `negative_controls.sh:26` reste hors de portée de tout verrou** : rien
  n'empêche un processus de tuer un autre. Il faudrait le restreindre à ses
  propres enfants (le PID de son `Popen`), pas `pgrep -x godot`.
- **Les cinq sites de `publish-playtest.yml`.** Un runner GitHub n'a pas ce
  dépôt monté et n'a rien à sérialiser. Les couvrir n'aurait pas de sens ; les
  exempter explicitement, si.
- **Les 46 en-têtes `.gd` et le `CLAUDE.md` racine.** Ce sont des textes, pas
  des sites d'exécution : aucun contrôle automatique ne les rend faux. Tant que
  `CLAUDE.md:80-83` enseigne la commande nue, la dérive est enseignée. C'est une
  correction de documentation, hors du périmètre de cette passe (interdiction de
  modifier `docs/` et le `CLAUDE.md`), et je la signale au lead.
- **Aucune de ces pistes ne dit quel verrou est le bon.** Le ticket demande « un
  seul verrou ». Choisir `heavy_tools.lock` et retirer `validate_fast.lock` est
  une décision qui change le comportement de la suite (`flock -n`, échec
  immédiat, contre `flock -w 3000`, attente). Elle appartient au propriétaire.

---

## 6. Ce que je n'ai pas vérifié

- **Rien n'a été exécuté.** Pas le moteur, pas Blender, pas une suite, pas
  `lancer_godot.sh`, pas `lancer_godot_autotest.sh`. Le comportement décrit en §1
  est lu dans le code, **pas mesuré**. Que le wrapper isole réellement `user://`
  et que ses refus refusent est **NON VÉRIFIÉ par moi** ; `STATUS.md` l'affirme,
  je ne l'ai pas reproduit.
- **Je n'ai pas démontré une collision.** Que deux des sites listés se
  contaminent effectivement est déduit du fait qu'ils prennent des verrous
  différents et partagent `user://` — c'est un raisonnement, pas une mesure. Le
  dégât mesuré est celui de `KNOWN_ISSUES:1923`, pas un que j'aie reproduit.
- **Je n'ai pas lu intégralement** `capture_vslice_gate.sh`, `capture_ab.sh`,
  `gate_negative_control.sh`, `gate_select.sh`, `validate_release.sh`,
  `server.py`, `negative_controls.sh`. Les colonnes « verrou », « XDG » et
  « wrapper » viennent d'un comptage de motifs (`grep -c flock`, `-c
  XDG_DATA_HOME`, `-c lancer_godot`), fiable pour l'absence. La colonne « RC »
  de `capture_vslice_gate.sh:92` est marquée **à vérifier** : je ne l'ai pas lue.
- **Je n'ai pas lu les 46 en-têtes `.gd` un par un** : le compte de 46 fichiers
  et 53 lignes vient de `grep -rl` et `grep -rn` sur `godot --`. Une invocation
  écrite autrement (variable, chemin absolu, autre casse) échapperait à ce
  motif — un seul motif rate toujours quelque chose, et celui-ci ne fait pas
  exception.
- **Je n'ai pas cherché dans l'historique git** ni dans les autres branches. Un
  point d'entrée supprimé de `HEAD` mais vivant ailleurs n'apparaît pas ici. La
  règle §2 de `COMMENT_TRAVAILLER_ENSEMBLE` demande de vérifier dans tout le
  dépôt ; je ne l'ai pas fait, faute d'autorisation de manipuler git.
- **Je n'ai pas vérifié l'environnement des runners GitHub** : que
  `publish-playtest.yml` tourne bien sur une machine éphémère est une lecture du
  workflow, pas une observation.
- **Je n'ai pas mesuré la dette avant de proposer B.** `PROMPT4_METHOD` §1
  l'exige : compter les violations existantes avant de poser un garde-fou. §3.1
  en donne 24, mais je n'ai pas décidé lesquelles sont des exemptions légitimes —
  c'est la première chose à faire avant d'écrire le test.

---

## 7. CORRECTIONS APPORTÉES PAR LA CONTRE-ÉPREUVE (lead, 2026-08-20)

Cet inventaire a été soumis à un agent dont la mission était de le **réfuter**.
Il a trouvé. Ce qui suit corrige le document plutôt que de le laisser circuler
avec ses erreurs.

### Faux, et corrigé

| affirmation de ce document | ce qui est vrai |
|---|---|
| « Un seul script du dépôt appelle `tools/lancer_godot.sh` » | **Deux** : `tools/godot/matrice_iss059.sh:21` ET `tools/godot/ablation_iss059.sh:19`, ce dernier absent de tout l'inventaire |
| « il y a TROIS mutex » | **Au moins quatre** : `evidence/…/r2a352_avant/reproduction/lancer_plan_b.sh:23` verrouille sur un fichier du scratchpad de session, hors dépôt et hors `/tmp/godot.lock` |
| « 4 fichiers sur 7 » de `.sh` sous `evidence/` lancent le moteur | **7 sur 7**, avec trois régimes de verrou différents dont un inexistant |
| §3.5 compte le vecteur documentaire | **sous-compté d'un facteur ~7** : `README.md:47,48` et **46 lignes dans 19 fichiers de `docs/`** manquaient |
| « les quatre `tools/blender/*.sh` » sont les seuls Blender hors verrou | **un cinquième**, en Python : `tools/cave_oracle_sabotage.py:536` |

### Citations fausses — le fait tient, la preuve ne l'établissait pas

- `tools/validate_fast.sh:65` et `tools/lancer_godot.sh:184` étaient cités comme
  « prend le verrou ». Ces lignes **nomment** le fichier ; la prise est en
  `:66`+`:67` et `:196`+`:207`. C'est exactement la distinction que ce document
  pose en constat n°3 — *nommer un verrou n'est pas le prendre* — et qu'il
  enfreignait dans sa propre preuve.
- `play.sh:35` / `:105` pour le `kill` : le kill est en `:33` et `:111`.
- `negative_controls.sh:46` : n'est pas un kill.
- `validate_fast.sh:69` pour la garde `pgrep` : c'est un `echo`, le test est `:73`.

### Surinterprétation retirée

« L'en-tête de `lancer_godot.sh` nomme `validate_fast.lock` comme mutex n°1 mais
ne le prend pas » : l'en-tête **énumère** les trois mutex pour les distinguer et
dit du sien « C'est celui d'ici ». Il ne revendique rien. Le défaut de fond — les
deux ne se sérialisent pas — reste réel ; la formulation ne l'était pas.

### Un manque de ce document qui, lui, est vide

Il se reprochait de n'avoir pas vérifié les autres branches
(`COMMENT_TRAVAILLER_ENSEMBLE` §2). La contre-épreuve l'a fait : 8 branches
locales, 12 distantes, aucun `.sh`/`.yml`/`.json` absent du disque, et
`git grep` du binaire sur toutes les branches ne rend aucun fichier inconnu.
**Ce point est fermé.**

### Contournements du correctif, mesurés et NON couverts

Trois formes échappent au balayage de fichiers, et elles vivent toutes sous
`evidence/` — des artefacts figés de passes antérieures, pas des points d'entrée
vivants. Le test d'invariant exclut `evidence/` **à dessein** ; c'est une
décision de périmètre, pas un oubli :

- `sh -c "godot …"` — `lancer_plan_b.sh:78` ;
- corps de heredoc injecté dans `bash -s` — `run_all.sh:15` encadrant `:69`, `:73` ;
- binaire nu résolu par le `PATH` — `lancer_cote.sh:67`, `:75`, `:93`.

La quatrième forme, elle, était un vrai trou et **est fermée** : le tableau
d'arguments (`tools/capture_ab.sh:102`, `RUN "$GODOT_BIN" "${args[@]}"`). Le
prédicat du test a été élargi pour l'attraper.

### L'angle mort du MCP est structurel, pas accidentel

Le joueur boîte noire se voit **refuser l'outil Bash par construction**
(`play.sh:102`) tout en recevant les outils `mcp__blackbox__*`. Aucun garde-fou
de niveau shell ne pourra jamais le couvrir — non par oubli, mais parce que ce
chemin est le seul qui lui reste ouvert. D'où le verrou implémenté **dans
`server.py`** plutôt que dans un garde-fou de commande.
