# ISS-059 — plan de bissection de la signature de fin de processus

**Statut de ce document : PLAN. Aucune mesure Godot n'a été prise pour l'écrire.**
Tout ce qui suit est soit une lecture de fichier du dépôt, soit une arithmétique
sur des journaux DÉJÀ commis. Chaque prédiction est marquée comme telle et reste
`NON VÉRIFIÉ` jusqu'à exécution.

Auteur : agent « plan de bissection ». Dépôt `/home/user/Zelda`, branche
`claude/world-v2-reconstruction`, HEAD `291a6219`.

---

## 1. Deux faits obtenus à coût zéro, qui réduisent le problème avant de dépenser une minute

### Fait n°1 — `ObjectDB` ne porte AUCUNE information indépendante : le résidu vaut 240, quatre fois

Recompté sur les quatre journaux commis, sans relancer quoi que ce soit :

```
grep -oE '[0-9]+ (ObjectDB instances|resources still|RID allocations of type .[A-Za-z0-9]*(DummyMaterial|DummyShader|DummyMesh|DummyTexture))[A-Za-z]*' <log>
```

| journal | tests | ObjectDB | Material | Shader | Mesh | Texture | Σ RID | **ObjectDB − Σ RID** | resources |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `v2_3_r2a/.../validate_fast_r2a358.log` | 904 | 3 409 | 3 057 | 13 | 42 | 57 | 3 169 | **240** | 238 |
| `v2_3_r2b/integration/validate_fast_integree.log` | 916 | 5 103 | 4 749 | 14 | 42 | 58 | 4 863 | **240** | 239 |
| `v2_3_r2b1/integration/validate_fast.log` | 933 | 5 103 | 4 749 | 14 | 42 | 58 | 4 863 | **240** | 239 |
| `v2_3_r2b2/validation/validate_fast_R2B2.log` | 943 | 5 203 | 4 849 | 14 | 42 | 58 | 4 963 | **240** | 239 |

Le résidu est **exactement 240** dans les quatre cas, à trois mois et 39 tests
d'écart. Et l'écart R2a→R2B se décompose exactement :
`ΔObjectDB 1694 = ΔMaterial 1692 + ΔShader 1 + ΔTexture 1`.

**Conséquence opératoire** : il n'y a **qu'une seule variable** à mesurer,
`DummyMaterial`. `ObjectDB`, `resources`, `DummyShader`, `DummyMesh` et
`DummyTexture` forment un plancher constant (240 + 114 objets), insensible au
contenu ajouté — profil d'un cache `ResourceLoader` et d'autoloads, pas d'une
fuite de test. Toute la suite de ce plan ne lit donc **que la ligne
`DummyMaterial`**. Cela divise par cinq la surface d'observation.

### Fait n°2 — l'hypothèse « proportionnel au nombre de tests » est DÉJÀ falsifiée par les journaux commis

R2B.1 ajoute **17 tests** et **0 matériau** (4 749 → 4 749, identique au chiffre
près). R2B.2 ajoute 10 tests et 100 matériaux. Un dosage par méthode de test
donnerait ~117 au premier et ~69 au second : les deux sont faux, et le premier
l'est absolument. **H-TEST est mort avant la première seconde de Godot.**

Ce qui distingue les 17 tests de R2B.1 : ce sont des tests `world_v2`, et le lot
`world_v2` **entier** sort déjà à zéro ligne de fuite.

---

## 2. Inventaire réel des lots (lecture de `tools/godot/test_runner.gd` et de `tests/`)

`TEST_ROOTS` = `tests/unit`, `tests/integration`, `tests/playthrough`,
`tests/world_v2`. Les chemins sont triés : l'ordre d'exécution est donc
**integration → playthrough → unit → world_v2**, déterministe.

| lot | fichiers | méthodes `test_` | montages `ValleyWorld` | appelle `restore_root()` | mesuré seul ? |
|---|---:|---:|---:|---:|---|
| `integration` | 135 | 704 | **73** (25 fichiers) | **1 / 135** | **JAMAIS** |
| `playthrough` | 6 | 7 | 2 (`flow_wiring_path`, `physical_run`) | 3 / 6 | 3 fichiers sur 6 (`boot_smoke`, `boss_run`, `dungeon_run`) → 0 |
| `unit` | 21 | 137 | 0 | 1 / 21 | oui → 0 |
| `world_v2` | 31 | 99 | 0 (monde V2) | **24 / 31** | oui → 0 |

Total collecté 947, cohérent avec les 943 exécutés de R2B.2.

**Le seul lot jamais isolé est celui qui porte les 73 montages de la vallée V1.**
La phrase « aucun lot isolé ne fuit » n'a donc jamais été testée là où le contenu
se trouve.

Syntaxe du filtre, vérifiée dans le code (`_read_filter`, `_matches`) :
- lu dans `OS.get_cmdline_user_args()` → **obligatoirement après `--`** ;
- `--filter=` et rien d'autre ;
- **plusieurs sous-chaînes séparées par des virgules**, retenues en OU, comparées
  par `path.contains(needle)` sur le chemin COMPLET.

C'est ce dernier point qui rend ce plan possible : on peut exécuter un
sous-ensemble arbitraire de fichiers dans un seul processus.

---

## 3. Hypothèses concurrentes, classées

`M(x)` = nombre de `DummyMaterial` fuités par un processus exécutant `x`.
`m` = nombre de montages de `ValleyWorld.tscn` dans ce processus.
Dénominateur de référence : **4 849 / 73 montages = 66,4 matériaux par montage.**

| # | nom | énoncé | prédit | statut avant mesure |
|---|---|---|---|---|
| **H-MONTAGE** | dose par montage de la vallée V1 | chaque montage de `ValleyWorld` laisse un lot constant de matériaux ; additif dans un processus | `M = 66,4 × m` | **favorite** — 73 montages × 66,4 = 4 849 au chiffre près, et les trois lots propres ont 0 montage V1 |
| **H-CACHE** | accumulateur statique saturant | un cache `static` retient **une génération**, pas une par montage | `M ≈ 66` quel que soit `m ≥ 1` | plausible : le patron est attesté dans ce dépôt (`WorldV2PlaceKit.scene_for`, corrigé R2B.3) |
| **H-SEUIL** | plancher de pression | rien ne fuit sous un seuil de nœuds/mémoire, puis tout fuit | courbe à coude, pas droite | faible, mais c'est la seule qui explique « aucun lot seul ne fuit » sans contredire le fait n°2 |
| **H-INTERACTION** | il faut la coexistence de deux lots | `M(A) + M(B) ≪ M(A ∪ B)` | tous les sous-ensembles à 0 | **à ne tester qu'en dernier** : c'est la seule hypothèse chère |
| ~~H-TEST~~ | dose par méthode de test | `M = 6,9 × méthodes` | — | **FALSIFIÉE** (fait n°2), coût zéro |
| ~~H-KITPLACEMENT~~ | `KitPlacement._base_cache` retient des matériaux | — | — | **FALSIFIÉE** par lecture : `scripts/world/kit_placement.gd` ne met en cache que des `float` (`_base_offset`), aucune ressource |

H-MONTAGE et H-CACHE prédisent la même chose pour `m = 1` et divergent
totalement dès `m = 3`. C'est cette divergence qu'on achète en premier.

---

## 4. Les mesures, ordonnées par pouvoir discriminant ÷ coût

Toutes utilisent la même forme (§6). On ne lit qu'une chose : la ligne
`DummyMaterial`.

### E1 — dose-réponse INTRA-FICHIER (la mesure qui tranche)

`tests/integration/test_valley_dressing.gd` : 10 méthodes, dont **9 montent
`ValleyWorld`** et une monte le vestibule. Un seul fichier, donc un seul contenu :
aucun confondant entre les points de la courbe.

On produit trois points en **renommant temporairement** des méthodes
`func test_…` → `func x_…` (le runner ne collecte que `test_*`), sha256 relevé
avant et après, restauration byte-identique exigée.

| point | méthodes actives | montages `m` | H-MONTAGE prédit | H-CACHE prédit | H-SEUIL prédit |
|---|---:|---:|---:|---:|---:|
| E1a | 1 | 1 | ≈ 66 | ≈ 66 | ≈ 0 |
| E1b | 3 | 3 | ≈ 199 | ≈ 66 | ≈ 0 |
| E1c | 10 (fichier intact) | 9 | ≈ 598 | ≈ 66 | 0 **ou** ≈ 598 |

**Lecture** : trois points alignés sur une droite de pente ≈ 66 passant par
l'origine ⇒ H-MONTAGE, et l'extrapolation `pente × 73` doit retomber sur 4 849.
Trois points plats ⇒ H-CACHE. Deux zéros puis un grand nombre ⇒ H-SEUIL.
Trois zéros ⇒ H-MONTAGE et H-CACHE tombent ensemble, on passe à E4.

Aucune de ces quatre lectures n'est ambiguë : **la mesure ne peut pas rendre le
même résultat selon que l'hypothèse est vraie ou fausse.** C'est la raison pour
laquelle elle est première.

### E2 — identité des objets fuités, en une minute

E1a relancé **avec `--verbose`**. Godot énumère alors les instances fuitées avec
leur classe et, pour les ressources, leur `resource_path`. Sur ~66 objets le
journal reste lisible.

Prédit si H-MONTAGE : des `StandardMaterial3D`/`ShaderMaterial` sans chemin
(créés par `.new()` — il y a **129 sites** `StandardMaterial3D.new()` /
`ShaderMaterial.new()` dans `scripts/`), rattachés au chantier de la vallée.
Prédit si H-CACHE : des ressources **avec** un `resource_path`, donc retenues par
un cache nommable.

**Cette mesure peut clore le ticket à elle seule** : elle ne dit pas seulement
« combien », elle dit « quoi ». Son coût est celui du plus petit point de E1.

### E3 — témoin négatif

`test_locomotion.gd` : 25 méthodes, **0 montage de la vallée**, 2 `instantiate()`.
Prédit ≈ 0 sous H-MONTAGE comme sous H-CACHE. Un résultat non nul démolit les
deux et rouvre H-TEST par une autre porte que le fait n°2.

C'est le seul contrôle qui protège d'un faux positif de E1 : sans lui, « un
fichier d'intégration fuit » ne se distingue pas de « tout fichier d'intégration
fuit ».

### E4 — additivité entre fichiers (n'exécuter que si E1 rend trois zéros)

`test_valley_atmosphere.gd` seul (3 montages), puis les deux fichiers ensemble
(12 montages). Si `M(les deux) ≫ M(atmosphere) + M(dressing)`, c'est
H-INTERACTION, et seulement alors la bissection par moitiés de `integration`
devient justifiée.

### E5 — clôture (conditionnelle au budget restant)

Les **25 fichiers** qui montent la vallée, en un seul processus : 73 montages,
120 méthodes. Prédit **4 849** sous H-MONTAGE. Si le compte tombe, la
localisation est close : les 110 autres fichiers d'`integration` sont innocents
et le ticket devient un défaut de code nommé, pas une bissection.

Filtre (une seule ligne, virgules) — liste produite par analyse statique :

```
test_bestiary_gate.gd,test_camp_composes_three_activity_poles.gd,test_camp_props.gd,test_citadel_carries_voids_and_asymmetry.gd,test_citadel_dressing.gd,test_citadel_masses_wear_battered_cladding.gd,test_gate_cameras_are_not_buried.gd,test_ground_carriers_keep_their_material.gd,test_hud_and_inventory.gd,test_ingredients.gd,test_kit_scale.gd,test_meals_and_buffs.gd,test_mesas_wear_talus.gd,test_mount_and_dev_fly.gd,test_mouse_camera.gd,test_paths_belong_to_the_ground.gd,test_phase_h_silhouettes.gd,test_plains_carry_flanking_relief.gd,test_riverside_village.gd,test_save_continuity.gd,test_storm_cloud_hangs_above_the_spire.gd,test_valley_atmosphere.gd,test_valley_dressing.gd,test_valley_world.gd,test_world_bounds_and_death.gd
```

### Écartée : `--filter=tests/playthrough`

2 montages seulement, donc ≈ 133 matériaux prédits — un chiffre que E1 donne
déjà, en moins de temps et sans le coût de `physical_run`. Sa seule valeur
propre serait de tester le montage **via `SceneFlow`** plutôt que par
`instantiate()` direct ; à faire seulement s'il reste du budget après E5.

### Écartée : bissection par moitiés de `integration`

C'est la méthode proposée par le ticket. Elle coûte deux demi-suites (~2 × 25 min)
pour rendre **un bit** d'information, alors que E1 rend une **pente** pour une
fraction du prix. Elle ne redevient rationnelle que si E1 et E4 échouent tous
les deux, c'est-à-dire sous H-INTERACTION seule.

---

## 5. Budget, et règle d'arrêt

Une seule mesure de durée existe dans le dépôt : les mtimes de
`evidence/validate_fast/` (run du 2026-08-19) donnent
`01b_parse.log` 13:55 → `02_unit.log` 14:59, soit **≈ 64 min pour 933 tests**
avec 73 montages. Elle borne le coût par montage : **≤ 52 s**. Sa borne basse
est inconnue. **Toutes les durées ci-dessous sont donc des ESTIMATIONS
encadrées, pas des mesures** ; E1a les remplace par une vraie valeur dès la
première minute.

| ordre | mesure | montages | plafond `timeout` | coût estimé |
|---|---|---:|---:|---|
| 1 | E1a (1 montage) | 1 | 300 s | 1 – 2 min |
| 2 | E2 (E1a + `--verbose`) | 1 | 420 s | 1 – 3 min |
| 3 | E1b (3 montages) | 3 | 600 s | 1 – 4 min |
| 4 | E1c (fichier intact, 9) | 9 | 900 s | 2 – 9 min |
| 5 | E3 (témoin, 0 montage) | 0 | 900 s | 2 – 6 min |
| — | **sous-total E1+E2+E3** | 13 | — | **7 – 24 min** |
| 6 | E5 (clôture, 73) | 73 | 2 700 s | 8 – 45 min |

**Budget total : 45 min de Godot.** E1+E2+E3 consomment 7 à 24 min ; E5 n'est
lancée que si `t_montage` mesuré à l'étape 1 satisfait
`73 × t_montage + 60 s ≤ (45 min − dépensé)`. Sinon E5 est reportée et déclarée
`BLOQUÉ pour budget`, pas approximée.

**Règle d'arrêt** : si E1a, E1b et E1c rendent trois zéros, arrêter, écrire
`H-MONTAGE et H-CACHE FALSIFIÉES`, et **ne pas** enchaîner sur E4/E5 dans le même
budget — l'interaction demande son propre plan.

---

## 6. Forme d'invocation, et les six pièges qui annulent une mesure

```bash
cd /home/user/Zelda
OUT=evidence/world_v2/v2_3_r2b3/iss059/bissection
mkdir -p "$OUT"

# UNE invocation = UN verrou, import compris (tools/CLAUDE.md).
T0=$(date +%s)
flock "$PWD/.git/heavy_tools.lock" -c \
  "cd /home/user/Zelda \
   && /usr/local/bin/godot --headless --path . --import > $OUT/E1a_import.log 2>&1 \
   && timeout 300 /usr/local/bin/godot --headless --path . \
        --script tools/godot/test_runner.gd -- --filter=test_valley_dressing.gd \
        > $OUT/E1a.log 2>&1"
RC=$?; T1=$(date +%s)
echo "E1a RC=$RC wall=$((T1-T0))s" | tee -a "$OUT/journal.txt"
```

Puis, et seulement ensuite, la lecture — **jamais dans un tube depuis Godot** :

```bash
grep -c '^filtre: test_valley_dressing.gd$' "$OUT/E1a.log"   # doit valoir 1
grep -c '^=== RÉSULTAT:'                    "$OUT/E1a.log"   # doit valoir 1
grep -c '^  ok '                            "$OUT/E1a.log"   # doit valoir le nb de méthodes actives
grep -E 'DummyMaterial' "$OUT/E1a.log"                        # LA mesure
```

1. **`flock` : tester le RC.** `flock -w N` qui expire rend 1 **sans exécuter**.
   Ici on utilise `flock` bloquant, mais le RC doit être lu quand même : un RC
   non nul = RIEN mesuré, jamais « zéro fuite ».
2. **`--filter=`, pas `--filtre=`.** Un drapeau inconnu est ignoré **en silence**
   et la suite ENTIÈRE part (~64 min). Deux protections, les deux obligatoires :
   le `timeout` ci-dessus, et le contrôle `grep -c '^filtre: …'` qui doit valoir 1.
   Le runner échoue de lui-même si le filtre ne désigne **aucun** fichier
   (« aucun test n'a été exécuté ») — mais **pas** si le drapeau est mal écrit.
3. **`.gd` dans chaque nom.** Le filtre est un `contains` sur le chemin :
   `test_raider` attrape quatre fichiers. Toujours écrire `test_raider.gd`.
4. **Un `timeout` qui frappe ne rend pas « zéro fuite ».** Godot tué par SIGTERM
   n'imprime pas son rapport de sortie. **Si `=== RÉSULTAT:` est absent du
   journal, la mesure est `BLOQUÉ`, pas 0.** RC 124 = timeout ; RC 143 = SIGTERM
   dont l'émetteur n'est pas nommé, donc à ne jamais interpréter seul.
5. **Jamais `godot … | head`.** SIGPIPE tue le processus avant l'écriture du
   fichier : la console montre un résultat crédible et rien n'est écrit.
   Rediriger, puis lire le fichier.
6. **Un seul Godot à la fois, tous arbres confondus.** Tous les worktrees
   partagent un unique `user://`
   (`/root/.local/share/godot/app_userdata/Eclats d'Orage`), et le runner y lit
   `user://logs/godot.log` pour compter les `SCRIPT ERROR`. Deux runners
   concurrents fabriquent des échecs — mesuré, `evidence/world_v2/v2_3_r2b3/debris/31_collision_de_runners.log`.
   `heavy_tools.lock` et `validate_fast.lock` sont **deux mutex distincts** : se
   sérialiser sur l'un ne protège pas de l'autre.

**`--headless` est ici OBLIGATOIRE**, contrairement à la règle des captures : la
signature `RendererDummy::DummyMaterial` n'existe QUE sous le renderer factice.
Une mesure prise sous `xvfb-run` ne porterait pas sur le même objet.

**Restauration** : E1a et E1b modifient `test_valley_dressing.gd`. Relever
`sha256sum` avant la première édition, restaurer, et re-relever : les deux
empreintes doivent être identiques. Journaliser les deux dans `journal.txt`.

---

## 7. Ce que ce plan ne tranchera pas

- **La ligne de code qui retient les matériaux.** E2 donne les classes et les
  chemins des objets fuités ; désigner le détenteur demande une instrumentation
  supplémentaire, hors budget.
- **L'effet du correctif R2B.3 sur la signature.** Il exige deux suites complètes
  au MÊME SHA (~2 h) et reste `BLOQUÉ`, comme consigné au ticket.
- **Le `+100` de R2B.1→R2B.2.** Si E1 établit une pente de 66,4/montage, alors
  `+100` ≈ 1,5 montage — un chiffre non entier, donc **pas** expliqué par la
  pente seule. Le `+100` reste `NON EXPLIQUÉ` à l'issue de ce plan.

---

## 8. Verdict sur la tranchabilité

| question | tranchable en 45 min ? |
|---|---|
| Le multiplicateur est-il le montage de `ValleyWorld` V1 ? | **OUI** — E1, 5 à 15 min, quatre lectures mutuellement exclusives |
| Dose par montage ou cache saturant ? | **OUI** — E1a vs E1b, même fichier, aucun confondant |
| Quelles CLASSES d'objets fuient, avec quel `resource_path` ? | **OUI** — E2, ~1 à 3 min |
| La pente explique-t-elle les 4 849 ? | **PROBABLE** — E5, conditionnée au `t_montage` mesuré à l'étape 1 |
| Quelle ligne de code retient ? | **NON** — hors budget, plan suivant |
| Effet du correctif R2B.3 sur la signature ? | **NON** — `BLOQUÉ`, deux suites au même SHA |

Le pari est explicite : **73 × 66,4 = 4 849**, au chiffre près. Si E1 rend une
pente proche de 66, ce plan a trouvé le multiplicateur. Si elle rend zéro ou une
constante, il l'a **falsifié pour moins de quinze minutes** — ce qui est le
second meilleur résultat, et la raison pour laquelle E1 passe avant tout le reste.
