# ISS-059 — bissection : ce qui a été MESURÉ, et ce qui reste

Agent « bissection ISS-059 », 2026-08-20. Dépôt `/home/user/Zelda`, branche
`claude/world-v2-reconstruction`, HEAD `ebcd782`. Godot
`4.7.1.stable.custom_build.a13da4feb`.

`--headless` est **obligatoire ici** : la signature
`RendererDummy::DummyMaterial` n'existe que sous le renderer factice. Rendu
logiciel, **aucune mesure de performance n'est produite** ; les durées ne
servent qu'au budget.

Isolation ISS-063 : `XDG_DATA_HOME=/tmp/ud_bissect` sur **chaque** invocation,
sérialisation sur `.git/heavy_tools.lock`, `timeout` explicite, redirection
vers fichier (jamais de tube depuis Godot). RC relevé et publié à chaque fois.

Budget Godot consommé : **≈ 40 min** sur 45 (journal : `journal.txt`).

---

## 0. Un fait à coût zéro qui conditionne toute lecture

Le `4 849 DummyMaterial` a été relevé au SHA **`ea93460`** (R2B.2). Entre
`ea93460` et le HEAD mesuré ici :

```
$ git diff --stat ea93460..HEAD -- scripts/
 scripts/world_v2/poi/world_v2_place_kit.gd | 48 ++++++++++++++++++++++++++++--
$ git diff --stat ea93460..HEAD -- scenes resources shaders
 (vide)
$ git diff --stat ea93460..HEAD -- assets
 assets/architecture/farm/SM_Farm_Ruins.glb | Bin 205128 -> 211852 bytes
```

**Un seul fichier de `scripts/` a changé** : le correctif ISS-059 de R2B.3
(`d195c58`), qui retient désormais les `PackedScene` du kit. Toutes mes mesures
sont donc prises **APRÈS** ce correctif, le `4 849` **AVANT**. Ce n'est pas un
détail de forme : c'est la limite d'attribution de tout ce qui suit.

---

## 1. Bloc A — le montage de la vallée n'est PAS le multiplicateur

Chaque ligne a son témoin. Contrôles anti-piège passés sur **chaque** journal :
`grep -c '^filtre: …'` = 1 (le drapeau a bien été lu — un `--filtre=` mal écrit
serait ignoré en silence), `grep -c '^=== RÉSULTAT:'` = 1 (le processus a
imprimé son verdict : aucune mesure n'est un `timeout` déguisé en zéro), nombre
de lignes `  ok ` conforme, nombre de fichiers distincts conforme.

| # | configuration | montages `ValleyWorld` | tests | RC | durée | `ObjectDB` | `resources` | **`DummyMaterial`** |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| T1 | `test_boss_arena.gd` — **témoin sans vallée** | **0** | 11 | 0 | 44 s | 2 | 1 | **0** |
| A1 | `test_valley_atmosphere.gd` | **3** | 3 | 0 | 45 s | 2 | 1 | **0** |
| A2 | `test_valley_dressing.gd` | **9** | 10 | 0 | 97 s | **0** | **0** | **0** |
| A3 | **les 43 fichiers d'`integration` qui montent la vallée** | **130** | **177** | 0 | **1 483 s** | **0** | **0** | **0** |

Témoins commis au même code (`evidence/world_v2/v2_3_r2b3/validation/`) :
`--filter=world_v2` (31 fichiers, 99 tests) → 0 / 0 / 0 ;
`--filter=boot_smoke` (monte `WorldV2` par `SceneFlow`) → 0 / 0 / 0.

**Ce que A3 tue.** Le plan pariait `73 × 66,4 = 4 849`. J'ai mesuré **130
montages** dans un seul processus — presque le double du dénominateur du pari —
et la sortie est **vide de bout en bout**.

| hypothèse | prédiction à 130 montages | mesuré | verdict |
|---|---:|---:|---|
| H-MONTAGE (dose par montage, 66,4) | ≈ 8 632 | **0** | **FALSIFIÉE** |
| H-CACHE (constante saturante ≈ 66) | ≈ 66 | **0** | **FALSIFIÉE** |
| H-SEUIL (coude sous pression) | grand nombre au-delà du coude | **0** à 130 montages / 177 tests / 1 483 s | **FALSIFIÉE** pour tout seuil sous ces valeurs |

**Et ce qui NE bouge pas, publié aussi** : le petit résidu `2 ObjectDB +
1 resource` n'est ni dosé ni monotone — il vaut 2 avec **zéro** montage (T1),
2 avec **trois** (A1), et **0** avec neuf (A2) puis 130 (A3). Ce n'est donc pas
un plancher additif ; c'est un résidu **ponctuel et dépendant de l'ordre**.

---

## 2. Bloc B — la sonde de chargement : le multiplicateur n'est pas le montage, et le résidu constant a un mécanisme

Sonde `tools/godot/probe_iss059_charge.gd` : mêmes autoloads que le runner,
aucun test, un seul processus. `--mode=aucun` est le **témoin** — même
processus, mêmes autoloads, zéro chargement.

| # | mode | fichiers | RC | durée | `ObjectDB` | `resources` | `Material` | `Mesh` | `Texture` |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| T2 | `aucun` — **témoin** | 0 | 0 | 0 s | **0** | **0** | 0 | 0 | 0 |
| B1 | `glb` (chargés, non instanciés) | 47 | 0 | 3 s | **0** | **0** | 0 | 0 | 0 |
| B2 | `scenes` (chargées, non instanciées) | 82 | 0 | 9 s | **137** | **73** | **0** | 0 | 0 |
| B3 | `tout` (`.tscn` + `.glb`) | 129 | 0 | 13 s | **137** | **73** | **0** | 0 | 0 |

**Attribution à variable unique** : 47 GLB chargés n'ajoutent **rien** (B1 = T2,
et B3 = B2). Le résidu vient des seuls `.tscn`.

Identité, obtenue en 11 s (`S3_charge_tout_verbose.log`, décomposée par
`decompose_verbose.py`) :

```
lignes « Leaked instance » : 136
   72  GDScript
   61  GDScriptNativeClass
    3  Shader
« Resource still in use » : 73 chemins, TOUS des res://…/*.gd
```

**Le résidu constant de la suite est expliqué, et ce ne sont pas des
matériaux : ce sont des scripts.** Charger une `.tscn` épingle les `GDScript`
qu'elle attache, plus leurs `GDScriptNativeClass`. Cela rend compte du
`ObjectDB − Σ RID = 240` constant sur quatre journaux et des
`238 → 239 resources` : l'ensemble des scripts du projet est stable, le contenu
ne l'est pas.

---

## 3. Bloc C — la signature à matériaux se reproduit, et elle tient à quatre scènes

Même sonde, `--instancie=oui` : chaque `.tscn` est instanciée **une fois**,
ajoutée à la racine, puis démontée. L'ordre est alphabétique et stable ;
`--limite=N` prend les N premières, donc les sous-ensembles sont **emboîtés**.

| # | scènes instanciées | RC | durée | `ObjectDB` | `resources` | **`Material`** | `Shader` | `Mesh` | `Texture` |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| C1 | 20 | 0 | 22 s | **0** | **0** | **0** | 0 | 0 | 0 |
| C2 | 41 | 0 | 28 s | **0** | **0** | **0** | 0 | 0 | 0 |
| C3 | 70 | 0 | 69 s | **0** | **0** | **0** | 0 | 0 | 0 |
| C4 | **71** (= 70 + `ValleyWorld.tscn`) | 0 | 78 s | **2** | **1** | **0** | 0 | 0 | 0 |
| C5 | **74** (= 71 + `WorldV2` + `WorldV2Bootstrap` + `ResonancePylon`) | 0 | 97 s | **995** | **648** | **281** | **14** | **214** | **67** |
| C6 | 82 (= 74 + les **8 lieux POI**) | 0 | 98 s | **993** | **647** | **281** | **14** | **214** | **67** |

**Trois lectures, toutes à variable unique :**

1. **Rien ne fuit jusqu'à la 70ᵉ scène.** Boot, boss, personnages, salles de
   donjon, ennemis, environnement, interactables, laboratoires, joueur, scènes
   de test, UI, armes, terrain d'entraînement, vestibule : **innocents**, tous
   instanciés dans le même processus.
2. **`ValleyWorld.tscn` seule n'apporte que le résidu ponctuel** (2 + 1), le
   même qu'`A1` et `T1`. **Zéro matériau.**
3. **Tout le reste apparaît d'un coup entre la 71ᵉ et la 74ᵉ scène** —
   `WorldV2.tscn`, `WorldV2Bootstrap.tscn`, `ResonancePylon.tscn`. Et **les
   huit lieux POI ajoutés ensuite n'ajoutent rien** (C6 ≈ C5, à ±2 près) :
   ils sont déjà montés par `WorldV2`.

Identité à 82 scènes (`S6_instancie_verbose.log`, 994 instances énumérées) :

```
  276  StandardMaterial3D      \
    4  ShaderMaterial          / = 280 ≈ 281 RID DummyMaterial
  214  ArrayMesh                 = 214 RID DummyMesh   (exact)
  107  PackedScene
  107  SceneState
   73  GDScript
   67  Image  +  64 CompressedTexture2D ≈ 67 RID DummyTexture
   61  GDScriptNativeClass
    5  Shader,  4 Animation,  3 NoiseTexture2D,  3 FastNoiseLite, …
avec resource_path : 0 sur 994
```

Les `PackedScene` **épinglées** (107, avec autant de `SceneState`) portent leurs
sous-ressources : matériaux, maillages, images. Le chargement seul n'en épingle
aucune (bloc B) ; c'est **l'instanciation** qui les épingle.

---

## 4. Le garde-fou : pourquoi je ne conclus PAS que c'est la fuite de la suite

Le chiffre est joli, donc je le soupçonne. **Le profil n'est pas le même**, et
c'est mesurable :

| | suite complète R2B.2 (`ea93460`) | sonde C6 (82 scènes, HEAD) |
|---|---:|---:|
| `ObjectDB` | 5 203 | 993 |
| `resources still in use` | **239** | **647** |
| `DummyMaterial` | **4 849** | **281** |
| `DummyMesh` | **42** | **214** |
| `DummyTexture` | 58 | 67 |
| `DummyShader` | **14** | **14** |
| **rapport matériaux / maillages** | **115,5** | **1,31** |

`DummyShader` tombe au chiffre près, et `DummyTexture` est proche. Mais la
suite fuit **115 matériaux par maillage** et la sonde **1,3**. Une fuite de
sous-ressources de scène — ce que la sonde produit — vient par paquets
matériau + maillage + image. La suite, elle, fuit des matériaux **presque
sans maillages**.

**Conséquence, et c'est la réduction de domaine la plus utile de cette passe :**
les 4 849 matériaux de la suite ne sont **pas** des sous-ressources de scènes
épinglées. Ce sont des matériaux **créés à l'exécution** — `StandardMaterial3D.new()`,
`ShaderMaterial.new()`, `.duplicate()` — dont le porteur ne crée pas de maillage.
Le dépôt en compte **129 sites** de création et **31** de duplication.

Second désaccord, publié aussi : le lot `world_v2` (99 tests, 31 fichiers) et
`boot_smoke` montent `WorldV2` **par le runner** et sortent **propres**, alors
que la même scène instanciée par la sonde fuit. La différence tient au démontage
(la sonde fait `remove_child` + `queue_free` + une frame ; les tests appellent
`restore_root()`) ou à l'ordre. **Je ne l'ai pas tranché : `NON VÉRIFIÉ`.**

---

## 5. Verdict

**Domaine RÉDUIT, cause du `+100` NON ATTEINTE. ISS-059 reste OUVERT.**

**Éliminé, avec la mesure qui l'élimine :**

| éliminé | mesure |
|---|---|
| le montage de `ValleyWorld` comme multiplicateur | A3 : 130 montages, 177 tests, 1 483 s → **0 ligne** |
| la dose par montage (H-MONTAGE) | A1/A2/A3 : 3 → 0, 9 → 0, 130 → 0 |
| le cache saturant (H-CACHE) | idem : jamais la constante ≈ 66 |
| tout seuil sous 130 montages / 177 tests / 1 483 s (H-SEUIL) | A3 |
| les 43 fichiers d'`integration` qui montent la vallée | A3 |
| les 70 premières scènes du projet (boot, boss, personnages, donjon, ennemis, environnement, interactables, labos, joueur, tests, UI, armes, vestibule) | C3 |
| les 8 lieux POI comme contributeurs propres | C6 ≈ C5 |
| les 47 GLB comme source du résidu | B1 = T2, B3 = B2 |
| « les matériaux fuités sont des sous-ressources de scène » | §4 : rapport 115,5 contre 1,31 |

**Établi :**

- le résidu constant `≈ 240 ObjectDB / 239 resources` de la suite est **des
  `GDScript` + `GDScriptNativeClass` épinglés par le chargement des `.tscn`**
  (bloc B, identité énumérée) ;
- une signature à matériaux **se reproduit en 97 s** et se localise à
  `WorldV2.tscn` / `WorldV2Bootstrap.tscn` / `ResonancePylon.tscn` (C4 → C5) ;
- ce n'est **pas** la même fuite que celle de la suite (§4).

**Ce qui reste :**

1. les **92 fichiers d'`integration` qui ne montent pas la vallée** (≈ 527 tests)
   et les 2 fichiers de `playthrough` jamais isolés — hors budget ici ;
2. **quel objet retient** les `PackedScene` épinglées à l'instanciation (la
   sonde le montre, elle ne le nomme pas) ;
3. la **décomposition du `+100`** : elle exige deux suites complètes au MÊME
   SHA (≈ 1 h chacune) — **`BLOQUÉ`**, inchangé ;
4. l'**effet du correctif `d195c58`** sur la signature : mêmes deux suites,
   **`BLOQUÉ`**.

**Le `+100` reste NON EXPLIQUÉ.** Aucune des mesures de cette passe ne le touche.

---

## Annexe — reproduire

```bash
mkdir -p /tmp/ud_bissect
# une mesure du runner
XDG_DATA_HOME=/tmp/ud_bissect flock -w 3000 "$PWD/.git/heavy_tools.lock" \
  timeout 900 /usr/local/bin/godot --headless --path . \
  --script tools/godot/test_runner.gd -- --filter=test_valley_dressing.gd > sortie.log 2>&1
echo "RC=$?"                       # un RC non nul = RIEN mesuré, jamais « zéro fuite »
grep -c '^filtre: '        sortie.log   # doit valoir 1
grep -c '^=== RÉSULTAT:'   sortie.log   # doit valoir 1 — sinon la mesure est BLOQUÉE
grep -E 'ObjectDB|resources still|RID allocations' sortie.log

# une mesure de la sonde
XDG_DATA_HOME=/tmp/ud_bissect flock -w 3000 "$PWD/.git/heavy_tools.lock" \
  timeout 600 /usr/local/bin/godot --verbose --headless --path . \
  --script tools/godot/probe_iss059_charge.gd -- --mode=scenes --instancie=oui \
  > sonde.log 2>&1
python3 evidence/world_v2/v2_3_r2b3/iss059/bissection/decompose_verbose.py sonde.log
```

Journaux : `journal.txt` (RC + durée de chaque invocation) et les `*.log` de ce
dossier. Sonde : `tools/godot/probe_iss059_charge.gd` (non commise — laissée
dans l'arbre pour le lead).

---

## Annexe 2 — une autre session travaillait dans le MÊME arbre, et je le dis

Constaté à la clôture, pas supposé : `git status` montre des fichiers
non commis d'une passe ISS-062 (sabotage/restauration de
`assets/architecture/farm/SM_Farm_Ruins.glb`) écrits pendant ma fenêtre. C'est
exactement le risque de `COMMENT_TRAVAILLER_ENSEMBLE` §1.

Chronologie relevée par `mtime`, à comparer à `journal.txt` :

| heure UTC | événement |
|---|---|
| 12:10:20 → 12:35:45 | **mon** `E_43valley` (A3), RC=0 |
| 12:11:42 | l'autre session modifie `tests/world_v2/test_world_v2_r2b3_debris.gd` |
| 12:21:29 | elle écrit une copie sabotée du GLB **dans `evidence/`** |
| 12:35:49 → 12:35:54 | elle sabote puis **restaure** l'asset et réimporte |
| 12:36:42 → 12:48:54 | **mes** sondes S1 … S8c |
| 12:38:03 | dernière écriture de l'autre session |

Ce qui protège les mesures, vérifié et non supposé :

1. **Chaque** invocation à moi a pris `.git/heavy_tools.lock` et publié son RC ;
   aucune n'a rendu un journal vide sur RC non nul.
2. `assets/architecture/farm/SM_Farm_Ruins.glb` est **identique à `HEAD`** au
   sha256 (`ead79105…`) ; la fenêtre de sabotage (12:35:49–12:35:54) tombe
   **après** la fin d'A3 et **avant** le début de mes sondes.
3. Le fichier de test qu'elle a modifié n'est dans **aucun** de mes filtres :
   A3 a exécuté **43 fichiers distincts**, comptés dans le journal.
4. Tout le bloc C — celui qui porte la localisation causale — tourne **après**
   12:38:03, donc après sa dernière écriture.
5. `XDG_DATA_HOME=/tmp/ud_bissect` isole mon `user://` (ISS-063).

Reste un chevauchement possible de quelques secondes autour de 12:36:42–12:36:47
avec S1 (le témoin, 0 s, 0 fuite). Une exécution concurrente ne peut pas
**injecter** d'objets dans le rapport de sortie de MON processus ; je le
signale quand même plutôt que de le taire.
