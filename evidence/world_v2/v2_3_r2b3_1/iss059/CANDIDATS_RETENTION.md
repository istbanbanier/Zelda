# ISS-059 — qui retient les `PackedScene` après démontage

Analyse **statique** (lecture de code + source Godot 4.7.1 présente en
`/opt/src/godot`, commit `a13da4f`, tag vérifié). Aucun binaire Godot lancé,
aucun fichier de `scripts/` ni de `docs/` modifié.

Dépôt : `claude/world-v2-reconstruction`, HEAD `06b865b` au démarrage de la
passe. `scripts/core/asset_registry.gd`, `scripts/world_v2/poi/world_v2_place_kit.gd`
et `scripts/core/static_resource_caches.gd` ont changé sous moi pendant la
lecture (ajout de `liberer_caches()` / `StaticResourceCaches`) : le rapport
décrit l'état courant du disque, pas `06b865b`.

---

## 0. Deux artefacts de lecture à retirer AVANT tout classement

### 0.1 « aucun n'a de resource_path » est un artefact du format du rapport

`core/object/object.cpp`, `ObjectDB::cleanup()` :

```cpp
if (obj->is_class("Node"))      extra_info = " - Node path: " + ...;
if (obj->is_class("Resource"))  extra_info = " - Resource path: " + ...;
if (obj->is_class("RefCounted")) extra_info = " - Reference count: " + ...;
```

Trois `if` successifs qui **écrasent** la même variable. En Godot 4, `Resource`
hérite de `RefCounted` : le troisième `if` est donc vrai pour **toute**
ressource, et la ligne imprimée est toujours `- Reference count: N`. Le moteur
**n'imprime jamais** le `resource_path` d'une ressource dans ce rapport.

Conséquence directe : l'observation « les 107 `PackedScene` n'ont pas de
`resource_path` » ne dit rien sur les ressources. Elle ne peut éliminer aucun
candidat, et en particulier elle n'élimine pas les `PackedScene` chargées par
chemin depuis `assets/**.gltf`. La contrainte « plutôt des sous-ressources
embarquées » de l'énoncé de mission **tombe**.

Contre-preuve indépendante dans le dépôt : `matrice_c2/trio.log`, produit par
`--detail=oui`, imprime le `resource_path` de chaque entrée de cache **depuis
le processus** et conclut `kit : 0 entrees SANS resource_path`. Les 89 entrées
ont toutes un chemin `res://assets/environment/…`.

Statut : **PASS** (lu dans la source de la version épinglée).

### 0.2 Monter `WorldV2Bootstrap.tscn` ne monte pas un nœud, ça monte le monde

`scripts/world_v2/world_v2_bootstrap.gd:33` → `_ready()` :
- `_autoquit` vaut `false` (la sonde passe `--scenes=`, `--cycles=`, jamais
  `--autoquit`) ;
- ligne 63 : `flow.call("go_to", WORLD_V2_SCENE)` ;
- `scripts/core/scene_flow.gd:73` `go_to()` → `_load_and_swap()` →
  `get_tree().change_scene_to_file()` en headless.

La scène `WorldV2.tscn` devient donc `current_scene` et **reste dans `root`** :
la sonde n'en tient aucune référence et ne la démonte jamais.

Mesuré, sans interprétation, dans les journaux du dépôt :

| journal | scènes montées | `noeuds` en fin de cycle |
|---|---|---:|
| `ablation/temoin_sans_ablation.log` | worldv2 seul | **23** |
| `matrice_c2/trio.log` | worldv2 + bootstrap + pylone | **3858** |

3 835 nœuds vivants en fin de sonde, alors que les trois `WeakRef` de nœuds
disent `vivant=non`. Ce ne sont pas « trois scènes ajoutées » : c'est un monde
entier construit et laissé en place par un effet de bord du bootstrap.

Portée : cela ne change pas l'attribution ci-dessous (le témoin `worldv2` seul
fuit déjà 951 objets, sans bootstrap), mais toute mesure faite sur `trio`,
`paire_*_boot` ou `seul_bootstrap` compare des choses différentes. Les
comparaisons de la matrice C1/C2 impliquant `bootstrap` sont **NON VÉRIFIÉES**
comme mesures d'un « montage/démontage ».

---

## 1. Réponse à la question posée

L'attribution est **déjà faite expérimentalement**, dans ce dépôt, par
`tools/godot/sonde_iss059_proprietaire.gd --ablation=` :
`evidence/world_v2/v2_3_r2b3_1/iss059/ablation/`. Vider un conteneur juste avant
`quit()` et voir le rapport de sortie perdre ses objets *nomme* le porteur.

| ablation | ObjectDB fuités | `resources still in use` | DummyMaterial | DummyMesh |
|---|---:|---:|---:|---:|
| aucune (témoin) | 951 | 626 | 281 | 214 |
| `_material_cache` (98) | 853 | 626 | 183 | 214 |
| `AssetRegistry._model_cache` (21) | 841 | 538 | 251 | 178 |
| `WorldV2PlaceKit._scene_cache` (89) | 438 | 208 | 136 | 42 |
| `_scene_cache` + `_model_cache` | 312 | 107 | 102 | **0** |
| les cinq conteneurs | **128** | **64** | 4 | 0 |

Le porteur principal est donc **`WorldV2PlaceKit._scene_cache`**, secondé par
**`AssetRegistry._model_cache`**, puis **`WorldV2PlaceKit._material_cache`**.

Et l'arithmétique tombe juste, ce qui vaut confirmation :

- `_scene_cache` = **89** entrées (`trio.log`), `_model_cache` = **21** ;
- intersection **3** (`CommonTree_4`, `DeadTree_1`, `DeadTree_2` — ils portent
  `refs=3` au lieu de `refs=2` dans le journal, exactement parce que deux caches
  les tiennent) ;
- 89 + 21 − 3 = **107 `PackedScene` distinctes**, et 107 `SceneState`
  (une par `PackedScene`).

Le compte de 107 de la bissection est **exactement** l'union des deux caches
statiques. Ce n'est pas un ordre de grandeur, c'est une égalité.

---

## 2. Liste ordonnée des candidats

### C1 — `WorldV2PlaceKit._scene_cache` — **CONFIRMÉ, porteur principal**

- `scripts/world_v2/poi/world_v2_place_kit.gd:71` — `static var _scene_cache: Dictionary = {}`
- rempli par `scene_for()` ligne 99 : `_scene_cache[model_name] = scene`
- plafond `SCENE_CACHE_MAX = 256` (ligne 51) **au-dessus** des 212 modèles
  existants : la branche de vidage ligne 97-98 n'est jamais atteinte.

Compatible : 89 entrées mesurées ; l'ablation en retire 513 objets du rapport ;
chaque entrée est une `PackedScene` de `.gltf`/`.glb` qui tient ses `ArrayMesh`,
`StandardMaterial3D`, `CompressedTexture2D` et `Image` internes — d'où la chute
de 214 → 42 `DummyMesh`.

Incompatible : rien. La seule objection possible (« pas de `resource_path` ») est
levée en §0.1.

### C2 — `AssetRegistry._model_cache` — **CONFIRMÉ, porteur secondaire**

- `scripts/core/asset_registry.gd:61` — `static var _model_cache: Dictionary = {}`
- rempli ligne 107 ; plafond `MODEL_CACHE_MAX = 48` (ligne 65), atteint 21 ici.

Compatible : ablation seule −110 objets ; combinée à C1, `DummyMesh` tombe à 0.
C'est le second cache par lequel passe la végétation
(`world_v2_vegetation_builder.gd:813`, `_model_mesh()`).

Incompatible : rien.

### C3 — `WorldV2PlaceKit._material_cache` — **CONFIRMÉ, porteur des matériaux**

- `scripts/world_v2/poi/world_v2_place_kit.gd:54`
- rempli ligne 151 avec des `StandardMaterial3D` **dupliqués**, clé
  `"%d|%s" % [base.get_instance_id(), tone]`.

Compatible : 98 entrées, ablation seule −98 objets exactement, `DummyMaterial`
281 → 183 (−98). Les 276 `StandardMaterial3D` du rapport se décomposent en
~180 matériaux de base tenus par les 107 `PackedScene` + 98 teintés.

Point de conception à signaler : la clé contient `base.get_instance_id()`. Cet
identifiant est **par instance d'objet**, donc plus court que la vie du cache.
Le commentaire (lignes 55-70) le reconnaît et en déduit qu'il faut garder C1
vivant pour stabiliser la clé. C'est une dépendance mutuelle entre deux caches :
C1 ne peut plus être vidé sans faire diverger C3. Autrement dit, le plafond de
C1 (256) est aujourd'hui un **plafond qu'il ne faut jamais atteindre**, pas une
soupape ; s'il l'était, la fuite de R2B.3 (+27 matériaux par montage de la
ferme) reviendrait.

### C4 — Les autres caches `static` du dépôt — **compatibles avec le résidu, non mesurés séparément**

Inventaire exhaustif des `static var` de `scripts/` (balayage complet) :

| fichier:ligne | variable | contenu |
|---|---|---|
| `scripts/world/kit_placement.gd:36` | `_base_cache` | `float` par nom de modèle — **pas de ressource** |
| `scripts/world_v2/world_v2_vegetation_builder.gd:765` | `_grass_materials` | `ShaderMaterial` |
| `scripts/world_v2/world_v2_ground_material.gd:16,17` | `_shared`, `_grain` | `ShaderMaterial`, `NoiseTexture2D` |
| `scripts/art/painterly_recipe.gd:32,33,34` | `_grain`, `_shader`, `_shader_cutout` | `NoiseTexture2D`, `Shader` ×2 |
| `scripts/ui/hud_style.gd:132` | `_ui_streams` | flux audio |
| `scripts/lookdev/hero_shot_lab.gd:522` | `_grain` | `NoiseTexture2D` |
| `scripts/world_v2/poi/abandoned_farm_place.gd:143` | `_cache_materiaux` | matériaux |
| `scripts/world_v2/poi/riverside_village_place.gd:150` | `_cache_teintes` | matériaux |
| `scripts/world_v2/poi/thunderstruck_tree_place.gd:51` | `_cache_materiaux` | matériaux |
| `scripts/components/hitbox_component.gd:31`, `scripts/inventory/weapon_instance.gd:25`, `scripts/world/kit_placement.gd:38,39`, `scripts/art/painterly_recipe.gd:110` | compteurs / drapeau | scalaires — **jamais des ressources** |

Compatible avec le résidu de 128 objets / 64 ressources / 4 `DummyMaterial` /
2 `DummyShader` / 9 `DummyTexture` après `--ablation=tout` : les shaders et
`NoiseTexture2D` de `painterly_recipe` et `world_v2_ground_material` sont
précisément 2 `Shader` + textures de bruit.

Incompatible avec le gros de la fuite : ces conteneurs sont de taille 1 à 4 et
ne peuvent pas porter 107 `PackedScene`.

Ces onze porteurs sont **déjà** dans `StaticResourceCaches.PORTEURS`
(`scripts/core/static_resource_caches.gd:62-74`) : la couverture des `static var`
est complète au moment où j'écris. Vérifié par comparaison ligne à ligne de
l'inventaire ci-dessus avec la table.

### C5 — Constantes `preload()` (`GDScript::constants`) — **ÉLIMINÉ par la mesure**

Six `preload` de scènes dans tout `scripts/` :

- `scripts/world_v2/poi/abandoned_farm_place.gd:58,60` → `SM_Farm_Ruins.glb`, `SM_Village_Wall.glb`
- `scripts/world_v2/poi/riverside_village_place.gd:58,60` → `SM_Village_Quay.glb`, `SM_Village_Wall.glb`
- `scripts/world_v2/poi/stone_bridge_place.gd:40` → `SM_StoneBridge_Arch.glb`
- `scripts/world_v2/poi/thunderstruck_tree_place.gd:32` → `SM_ThunderstruckTree.glb`

Le mécanisme existe : `GDScript::clear()` (`modules/gdscript/gdscript.cpp`) vide
`member_functions`, `member_indices`, `static_variables`,
`static_variables_indices` — mais **pas `constants`**. Une constante `preload`
survit donc à `clear()` et ne meurt qu'avec l'objet `GDScript`.

Mais la mesure l'élimine : avec `--ablation=tout`, il reste **0
`DummyMesh`** au rapport. Ces cinq `.glb` distincts portent de la géométrie ;
s'ils étaient encore tenus, leurs `ArrayMesh` seraient comptés. Ils ne le sont
pas. **ÉLIMINÉ.**

### C6 — Connexions de signaux jamais déconnectées — **ÉLIMINÉ par la sémantique du moteur**

Réponse précise à la question posée, lue dans la source 4.7.1 :

- `core/variant/callable.h` : un `Callable` ordinaire stocke
  `alignas(8) StringName method;` et une **union** `{ uint64_t object; CallableCustom *custom; }`.
  Le champ `object` est un `ObjectID`, **pas** une `Ref`.
- `core/object/object.h:411` : la source range ses connexions dans
  `SignalData::Slot`, la cible garde une liste de retour. Aucune des deux
  structures ne prend de référence forte.

Donc : **non**, une connexion vers un objet vivant ne garde PAS la source en vie,
et ne garde pas non plus la cible. Un signal oublié produit un `ObjectID` mort,
pas une fuite de compteur.

Exception réelle, à ne pas confondre : `Callable.bind(x)` construit un
`CallableCustomBind` qui **conserve** ses `Variant` liés. Un `bind()` sur une
`Resource` retient bien cette ressource. Balayage : aucun `bind()` sur ressource
dans `scripts/world_v2/`. Le seul `Callable` transmis est
`Callable(_heightmap, "height_at")`
(`scripts/world_v2/poi/world_v2_places_builder.gd:73`) — cible `RefCounted`,
donc `ObjectID` sans référence forte. Il ne retient rien ; il peut en revanche
devenir pendouillant, ce qui est un autre sujet.

**ÉLIMINÉ** comme cause de rétention.

### C7 — Autoloads et `Engine.register_singleton` — **ÉLIMINÉ**

`project.godot` déclare six autoloads : `GameState`, `EventBus`, `SaveSystem`,
`AudioManager`, `SceneFlow`, `DevMode`. Aucun `Engine.register_singleton` dans
`scripts/`. Ce sont des `Node`, libérés par `SceneTree::finalize()`. Le témoin
sans aucune scène (`matrice_c2/temoin.log`, autoloads installés, zéro
instanciation) ne fuit pas — c'est la définition même de leur innocence.

**ÉLIMINÉ.**

### C8 — Cache de `ResourceLoader` — **ÉLIMINÉ comme porteur**

En Godot 4, `ResourceCache` indexe par chemin avec des pointeurs **bruts** : il
n'ajoute aucune référence. Une ressource en sort dès que son compteur tombe à
zéro. Il ne peut donc pas être le porteur. C'est d'ailleurs exactement la raison
d'être de C1 et C2, écrite dans leurs commentaires : sans rétention explicite, la
ressource sortait du cache et le fichier était relu.

**ÉLIMINÉ** — mais à conserver comme explication de *pourquoi* C1/C2 existent.

---

## 3. Question 4 : les `static var` sont-elles vidées avant ou après le rapport ?

**Le code source et la mesure ne disent pas la même chose. Je ne tranche pas.**

Ce que dit la source de la version épinglée :

1. `main/main.cpp:5264` (dans `Main::cleanup()`, ouverte ligne 5212) :
   `ScriptServer::finish_languages();`
2. `GDScriptLanguage::finish()` appelle `GDScriptCache::clear()`, puis parcourt
   `script_list` et appelle `scr->clear()` sur chaque script.
3. `GDScript::clear()` contient littéralement `static_variables.clear();` et
   `static_variables_indices.clear();`
4. `main/main.cpp:5392` : `unregister_core_types();` →
   `core/register_core_types.cpp:488` : `ObjectDB::cleanup();` — le rapport.
5. `GDScript::GDScript()` inscrit **inconditionnellement** chaque script dans
   `script_list` (`gdscript.cpp:1319`, pas de garde `DEBUG_ENABLED`).

Lecture de la source : les variables `static` sont vidées **AVANT** le rapport,
donc elles ne devraient pas y apparaître.

Ce que dit la mesure (`ablation/`) : vider `_scene_cache` juste avant `quit()`
fait passer le rapport de 951 à 438. Si `GDScript::clear()` avait déjà relâché
ces entrées, l'ablation n'aurait **aucun** effet sur le rapport. Elle en a un,
énorme.

Les deux ne peuvent pas être vraies ensemble. `scripts/core/static_resource_caches.gd`
(lignes 21-27) tranche déjà en faveur de la mesure. Je ne conteste pas la mesure,
je signale que la source de 4.7.1 dit le contraire et que **la cause de l'écart
n'est pas établie**. Statut : **NON VÉRIFIÉ**.

Deux conséquences pratiques, quelle que soit l'issue :

- si la source a raison, alors `liberer_tout()` n'est pas ce qui assainit le
  rapport, et l'ablation mesure autre chose (ordre de destruction, cascade
  différée) — le correctif marcherait pour une raison qui n'est pas celle écrite ;
- si la mesure a raison, il existe un chemin par lequel un `GDScript` échappe à
  `script_list` ou à `clear()`, et il faut le nommer avant de s'appuyer dessus.

**Expérience à variable unique qui tranche** (dix lignes, aucun monde, aucun
asset) — un script jetable, hors `scripts/`, lancé en `--headless --verbose` :

```gdscript
extends SceneTree
class Porteur extends RefCounted:
    static var garde: Array = []
func _initialize() -> void:
    for i in range(50):
        Porteur.garde.append(StandardMaterial3D.new())
    print("rempli: %d" % Porteur.garde.size())
    quit(0)
```

Lecture du résultat, sans ambiguïté possible :
- si le rapport de sortie annonce ~50 `ObjectDB` fuités et
  `50 RID allocations of type '…DummyMaterial…'` → **les `static var` NE SONT PAS
  vidées avant le rapport** : la mesure a raison, la lecture de `GDScript::clear()`
  est fausse ou incomplète ;
- s'il n'annonce rien → elles **sont** vidées avant, et la baisse observée par
  l'ablation vient d'autre chose ; il faut alors rouvrir l'attribution.

Coût : un lancement de quelques secondes. C'est le contrôle négatif qui manque à
tout le dossier ISS-059, et il ne dépend d'aucune scène du projet.

---

## 4. Question 5 : le compte des modules

| grandeur | valeur | source |
|---|---:|---|
| modèles dans les six dossiers de `MODULE_DIRS` | **212** | `ls assets/environment/{village,dungeon,props,cliffs,rocks,foliage}/*.{gltf,glb}` |
| dont `village` / `dungeon` / `props` / `cliffs` / `rocks` / `foliage` | 53 / 52 / 50 / 8 / 15 / 34 | idem |
| modèles dans les six dossiers de `AssetRegistry.MODEL_DIRS` | **157** | idem, `foliage rocks props dungeon characters/hero characters/enemies` |
| noms de modèles cités en littéral dans `scripts/world_v2/` et `scripts/world/` | **68** | balayage des appels `module(`, `scene_for(`, `AssetRegistry.model(` |
| `_index` après un montage du monde | **212** | `ablation/temoin_sans_ablation.log` |
| `_model_index` après un montage | **157** | idem |
| `_scene_cache` après un montage | **89** | idem |
| `_model_cache` après un montage | **21** | idem |
| union des deux caches de scènes | **107** | 89 + 21 − 3 communs |

Les 68 littéraux + les modèles choisis dynamiquement par la végétation
(`_model_mesh()`, `world_v2_vegetation_builder.gd:813`, tables `FLOWER_MODELS`,
`PEBBLE_MODELS`, arbres) donnent 89 modules réellement posés. Le chiffre de 107
n'est donc pas « de l'ordre de » : il est **exact**, et il est l'union de deux
caches, pas d'un seul. Toute correction qui n'en traite qu'un laisse l'autre.

---

## 5. Ce qui reste NON ATTRIBUÉ

Après `--ablation=tout` (les cinq conteneurs de la sonde vidés) il reste
**128 `ObjectDB`**, **64 `resources still in use`**, 4 `DummyMaterial`,
2 `DummyShader`, 9 `DummyTexture`. Personne ne les a nommés.

Candidats, par ordre de probabilité, tous **NON VÉRIFIÉS** :

1. `scripts/art/painterly_recipe.gd:32-34` — `_grain`, `_shader`, `_shader_cutout`.
   Deux `Shader` : cadre exactement avec les 2 `DummyShader` résiduels.
2. `scripts/world_v2/world_v2_ground_material.gd:16-17` — `_shared` (`ShaderMaterial`),
   `_grain` (`NoiseTexture2D`).
3. `scripts/world_v2/world_v2_vegetation_builder.gd:765` — `_grass_materials`.
4. `scripts/world_v2/poi/{abandoned_farm,riverside_village,thunderstruck_tree}_place.gd`
   — les trois caches de matériaux de lieu.
5. `scripts/ui/hud_style.gd:132` — `_ui_streams`.

La sonde ne sait pas encore vider ces cinq-là : son `_ablation()`
(`tools/godot/sonde_iss059_proprietaire.gd`) ne connaît que `kit_scene`,
`kit_material`, `kit_index`, `registry_model`, `registry_index`.

**Expérience à variable unique** : ajouter à `_ablation()` un mot-clé
`caches_restants` qui appelle `StaticResourceCaches.liberer_tout()` (le module
existe déjà, `scripts/core/static_resource_caches.gd:80`) et relancer
`--scenes=worldv2 --ablation=tout+caches_restants`. Si le résidu tombe sous 128,
ces porteurs sont nommés ; s'il ne bouge pas, la cause est ailleurs et il faut
`--verbose` pour lire les classes des 128.

### 5.1 La `PackedScene` de `WorldV2.tscn` elle-même

`ablation/temoin_sans_ablation.log` : `paquet[worldv2] vivant=OUI refs=3`.

Deux de ces trois références appartiennent à la sonde elle-même : dans
`_etat_weakrefs()`, `_paquets_faibles[j].get_ref()` rend un `Variant` qui tient
une référence, et le `p as Resource` local en tient une seconde. **Il reste donc
un seul porteur externe inconnu**, et aucun candidat de ce rapport ne l'explique :
`WorldV2.tscn` n'est ni dans `_scene_cache` (qui n'indexe que
`assets/environment/`), ni dans `_model_cache`, ni `preload`ée nulle part.

**Expérience à variable unique** : dans `_etat_weakrefs()`, relever
`get_reference_count()` **avant** d'affecter la variable locale `pr`, ou plus
simplement lancer avec `--verbose` et lire la ligne
`Leaked instance: PackedScene:<id> - Reference count: N` du rapport de sortie.
Un `N` ≥ 1 au rapport prouve un porteur hors sonde ; `N = 0` prouve que les trois
références étaient celles de la sonde et que ce point est un faux problème.

### 5.2 Un commentaire promet un test qui n'existe pas

`scripts/core/static_resource_caches.gd`, lignes 51-54 :

> « L'INVENTAIRE CI-DESSOUS EST TENU PAR UN TEST, PAS PAR LA VIGILANCE.
> `tests/unit/test_invariants.gd` balaie `scripts/` et échoue si une variable
> `static` pouvant contenir une `Resource` n'apparaît pas ici. »

Vérifié : `tests/unit/test_invariants.gd` compte 163 lignes et **sept** fonctions
de test — `test_azerty_q_moves_left`, `test_left_uses_physical_keycode_not_keycode`,
`test_lock_on_is_never_bound_to_q`, `test_engine_version_is_exactly_4_7_1`,
`test_gdscript_typing_warnings_stay_enabled`,
`test_no_nintendo_content_in_shipped_code`,
`test_reference_image_is_never_a_game_asset`. Aucune ne balaie `scripts/`, aucune
ne mentionne `StaticResourceCaches` ni `static var`.

C'est le mode de panne décrit en `docs/PROMPT4_METHOD.md` §2 : un garde-fou qui
existe en prose et pas en machine. Tant que ce balayage n'est pas écrit, le
douzième cache statique ajouté demain dormira au lieu de rougir. Constat, pas
correction : la décision appartient au lead.

---

## 6. Récapitulatif

| # | candidat | fichier:ligne | verdict |
|---|---|---|---|
| C1 | `_scene_cache` | `scripts/world_v2/poi/world_v2_place_kit.gd:71` | **CONFIRMÉ** — porteur principal (89 `PackedScene`) |
| C2 | `_model_cache` | `scripts/core/asset_registry.gd:61` | **CONFIRMÉ** — porteur secondaire (21) |
| C3 | `_material_cache` | `scripts/world_v2/poi/world_v2_place_kit.gd:54` | **CONFIRMÉ** — 98 matériaux teintés |
| C4 | huit autres caches `static` | table §2 C4 | **PLAUSIBLE** pour le résidu de 128 — NON VÉRIFIÉ |
| C5 | constantes `preload` | six sites, §2 C5 | **ÉLIMINÉ** (0 `DummyMesh` après ablation) |
| C6 | signaux non déconnectés | — | **ÉLIMINÉ** (`Callable` ne tient qu'un `ObjectID`) |
| C7 | autoloads / singletons | `project.godot` | **ÉLIMINÉ** (témoin propre) |
| C8 | cache `ResourceLoader` | — | **ÉLIMINÉ** (pointeurs bruts, aucune référence) |

Trois choses à retenir qui ne sont pas dans la liste : le rapport de sortie
n'imprime jamais de `resource_path` (§0.1) ; monter `WorldV2Bootstrap.tscn`
construit et laisse en place un monde de 3 835 nœuds (§0.2) ; et la source de
Godot 4.7.1 dit que les `static var` sont vidées avant le rapport, ce que la
mesure contredit — non tranché (§3).
