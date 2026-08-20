# ISS-059 — la chaîne causale, nommée et mesurée

Passe R2B.3.1, 2026-08-20. Base `06b865b`. Godot `4.7.1.stable.custom_build.a13da4feb`.
Toutes les mesures viennent de `tools/godot/sonde_iss059_proprietaire.gd`, lancée
par `tools/lancer_godot.sh` (verrou canonique + `XDG_DATA_HOME` isolé).
RC relevé à chaque invocation : un RC non nul veut dire **rien mesuré**, jamais
« zéro fuite ».

---

## 0. La question, et la réponse en une ligne

La bissection de R2B.3 s'était arrêtée sur : *« quel objet retient les
`PackedScene` épinglées à l'instanciation ? La sonde le montre, elle ne le
nomme pas. »*

**Il n'y a pas un objet, il y en a trois, et ce sont trois variables `static`
de GDScript sans propriétaire ni fin de vie :**

```
WorldV2PlaceKit._scene_cache      (scripts/world_v2/poi/world_v2_place_kit.gd:71)
   └─ 89 PackedScene, chargées par `load(path)` depuis assets/**/*.gltf|glb
        └─ SceneState
             └─ ArrayMesh · StandardMaterial3D · CompressedTexture2D · Image

AssetRegistry._model_cache        (scripts/core/asset_registry.gd:61)
   └─ 21 PackedScene   (dont 3 communes avec le cache ci-dessus)
        └─ mêmes sous-ressources

WorldV2PlaceKit._material_cache   (scripts/world_v2/poi/world_v2_place_kit.gd:54)
   └─ 98 StandardMaterial3D DUPLIQUÉS et teintés par `apply_tone()`
```

`89 + 21 − 3 = 107`. C'est **exactement** le compte de `PackedScene` vivantes
relevé par la bissection, et exactement son compte de `SceneState` (une par
`PackedScene`). Ce n'est pas un ordre de grandeur : c'est une égalité, et la
contre-épreuve indépendante a vérifié que la **différence symétrique entre
l'union des chemins des deux caches et l'ensemble des `PackedScene` fuitées est
VIDE** — identité, pas cardinalité.

---

## 1. Quelle scène porte la fuite — pas trois, une seule

La bissection localisait le résidu « entre la 71ᵉ et la 74ᵉ scène », donc sur
trois scènes à départager. Chacune a été montée puis démontée seule, par paires,
et toutes ensemble, dans un processus neuf à chaque fois.

| scénario | fin de cycle (dans le processus) | ObjectDB | resources | Material | Shader | Mesh | Texture |
|---|---|---:|---:|---:|---:|---:|---:|
| témoin (rien monté) | `objets=1590 ressources=13` | 0 | 0 | 0 | 0 | 0 | 0 |
| **`ResonancePylon.tscn` seule** | `objets=1630 ressources=35` | **0** | **0** | **0** | 0 | 0 | 0 |
| **`WorldV2.tscn` seule** | `objets=2875 ressources=861` | 951 | 626 | **281** | 11 | **214** | 65 |
| `WorldV2Bootstrap.tscn` seule | `objets=9056 ressources=968` | 949 | 625 | 281 | 11 | 214 | 65 |
| paire WorldV2 + Bootstrap | — | 951 | 626 | 281 | 11 | 214 | 65 |
| paire WorldV2 + Pylône | — | 951 | 626 | 281 | 11 | 214 | 65 |
| paire Bootstrap + Pylône | — | 951 | 626 | 281 | 11 | 214 | 65 |
| les trois | — | 951 | 626 | 281 | 11 | 214 | 65 |

Journaux : `matrice_c1/`. Trois lectures :

1. **Le pylône est innocent.** Zéro ligne. La bissection ne pouvait pas le
   savoir : elle ajoutait les trois scènes d'un bloc.
2. **`WorldV2.tscn` seule porte la signature entière**, en **22 secondes** au
   lieu des 97 de la sonde d'origine.
3. **Toute combinaison contenant `WorldV2` donne le même chiffre.** Ajouter des
   scènes n'ajoute rien : c'est une allocation qui SATURE, pas une dose par
   scène.

### 1.1 Une correction à porter au dossier : `Bootstrap` n'est pas un montage

`WorldV2Bootstrap.tscn` n'ajoute pas un nœud : son `_ready()` appelle
`SceneFlow.go_to(WorldV2)`, qui fait `change_scene_to_file()`. La scène devient
`current_scene` et **reste dans `root`** — la sonde n'en tient aucune référence
et ne la démonte jamais. Le compteur le dit sans ambiguïté : `noeuds=3858` en fin
de cycle contre `noeuds=23` pour `WorldV2` seule.

Conséquence : les lignes `seul_bootstrap`, `paire_*_boot` et `trio` ne mesurent
pas un montage/démontage. Elles restent publiées, mais comme mesures d'un
**monde laissé en place**, `NON VÉRIFIÉES` comme mesures de cycle. L'attribution
ne repose pas sur elles : `WorldV2` seule suffit.

Trouvé par la contre-épreuve, pas par moi.

### 1.2 Une seconde correction : « aucune n'a de `resource_path` » était un artefact

La bissection concluait que les 107 `PackedScene` n'ont pas de `resource_path`,
et en déduisait qu'il s'agissait de sous-ressources embarquées — ce qui excluait
les caches, qui chargent par chemin.

Le rapport de sortie de Godot **n'imprime jamais** le `resource_path` d'une
ressource. `core/object/object.cpp`, `ObjectDB::cleanup()` enchaîne trois `if`
qui écrasent la même variable : `Node` → chemin de nœud, `Resource` → chemin de
ressource, `RefCounted` → compteur de références. En Godot 4, `Resource` hérite
de `RefCounted` : le troisième gagne toujours.

L'observation ne disait donc rien, et la contrainte qu'elle imposait tombe.
Contre-preuve indépendante prise **dans** le processus, avec `--detail=oui` :
`kit : 0 entrees SANS resource_path` — les 89 entrées portent toutes un chemin
`res://assets/environment/…`.

---

## 2. Qui retient — ablation à variable unique

Reproducteur figé (`WorldV2.tscn`, un cycle). Une seule chose varie : quel
conteneur `static` est vidé **juste avant `quit()`**. Vider un conteneur et voir
le rapport de sortie perdre ses objets *nomme* le porteur. C'est un instrument
d'attribution, pas un correctif.

| conteneur vidé (taille) | ObjectDB | resources | **Material** | Shader | **Mesh** | Texture |
|---|---:|---:|---:|---:|---:|---:|
| aucun — témoin | 951 | 626 | **281** | 11 | **214** | 65 |
| `_material_cache` (98) | 853 | 626 | **183** | 11 | 214 | 65 |
| `AssetRegistry._model_cache` (21) | 841 | 538 | 251 | 11 | 178 | 61 |
| `_scene_cache` (89) | 438 | 208 | 136 | 11 | 42 | 56 |
| `_scene_cache` + `_model_cache` | 312 | 107 | 102 | 11 | **0** | 52 |
| **les cinq conteneurs** | **128** | **64** | **4** | 2 | **0** | 9 |

Journaux : `ablation/`. Ce que chaque ligne établit :

- `_material_cache` retire **exactement 98** matériaux — sa taille au chiffre
  près — et **aucun** maillage : ce sont des `duplicate()`, ils ne portent pas de
  géométrie.
- `_scene_cache` retire 145 matériaux et 172 maillages : ce sont des
  `PackedScene` entières avec leurs sous-ressources.
- Les deux caches de scènes ensemble emportent **100 % des maillages**.
- Les cinq ensemble emportent **98,6 % des matériaux** et 100 % des maillages.

### 2.1 Le fait que ces mesures établissent, et qui contredit le dossier

L'entrée ISS-059 affirmait, sur la foi d'une observation indirecte : *« Les
`static` GDScript sont libérés avant ce rapport. »*

**C'est faux, et l'ablation le démontre directement** : si les `static` étaient
libérés avant le rapport, les vider juste avant `quit()` ne changerait rien au
rapport. Or cela le change de 951 à 128. Ils sont donc encore vivants au moment
où le moteur compte ses fuites.

---

## 3. Stable ou cumulatif — la question de la directive

Deux cycles complets montage/démontage dans **le même processus** :

| scénario | fin de cycle 1 | fin de cycle 2 | croissance |
|---|---|---|---:|
| témoin | `objets=1590 ressources=13` | `objets=1590 ressources=13` | **0** |
| `WorldV2.tscn` | `objets=2875 ressources=861` | `objets=2875 ressources=861` | **0** |
| `ResonancePylon.tscn` | `objets=1630 ressources=35` | `objets=1630 ressources=35` | **0** |

Journaux : `matrice_c2/`. **Zéro croissance cumulative, à l'unité près.**

C'est une **allocation bornée et saturante** — un cache — et non une fuite qui
grossit. Le comparer à l'état d'avant R2B.3 rend la chose lisible : avant le
correctif `d195c58`, monter la ferme faisait **+27 matériaux par cycle sans
palier**, jusqu'à 561 en vingt cycles. La rétention a converti une croissance
linéaire en un plateau.

**Ce n'était donc pas la rétention qu'il fallait corriger. C'était son absence de
fin de vie.**

---

## 4. Le correctif, et pourquoi c'est celui-là

Un cache de durée de vie « processus » qui n'a **aucun propriétaire** ne peut pas
être relâché. Trois gestes, à la source :

1. `scripts/core/static_resource_caches.gd` — **`StaticResourceCaches`** : la
   liste des onze porteurs et leur fonction de libération. La résolution est
   PARESSEUSE, par chemin, gardée par `ResourceLoader.has_cached()` : nommer les
   classes ferait charger leurs scripts depuis un autoload au démarrage, ce qui
   AGGRAVERAIT le rapport de sortie que ce module doit assainir.
2. `static func liberer_caches() -> int` sur chacun des onze porteurs. Elle rend
   le nombre d'entrées relâchées : la libération est **mesurable**, pas
   seulement appelée.
3. `SceneFlow._exit_tree()` appelle `StaticResourceCaches.liberer_tout()`. Un
   autoload quitte l'arbre quand la `SceneTree` est détruite — à l'extinction du
   moteur, avant qu'il ne compte ses fuites, et après quoi plus personne
   n'utilise ces caches.

Ce n'est pas un nettoyage de fin de test : c'est le chaînon de cycle de vie qui
n'avait jamais été écrit, en code de production, pour toutes les exécutions.

**Ce qui n'a PAS été fait, et pourquoi** : la cause de fond du besoin de
rétention est la clé de `_material_cache`,
`"%d|%s" % [base.get_instance_id(), tone]`. Un identifiant d'instance est plus
court que la vie du cache ; c'est pour le stabiliser qu'il faut garder la
`PackedScene`. Changer cette clé supprimerait le besoin de rétention — mais
c'est une modification du comportement de teinte des lieux, en pleine passe où
la géométrie est gelée. Consigné comme dette nommée, pas fait ici.

---

## 5. Après correctif — mêmes scénarios, sans ablation

| scénario, 2 cycles | ObjectDB | resources | Material | Shader | Mesh | Texture |
|---|---:|---:|---:|---:|---:|---:|
| témoin | **0** | **0** | 0 | 0 | 0 | 0 |
| `ResonancePylon.tscn` | **0** | **0** | 0 | 0 | 0 | 0 |
| **`WorldV2.tscn`** | **103** | **54** | **0** | **0** | **0** | **0** |
| `WorldV2Bootstrap.tscn` | 101 | 53 | **0** | **0** | **0** | **0** |

Journaux : `apres_correctif/`. Cycle 1 = cycle 2 dans tous les cas.

**Les quatre classes de RID de la signature ISS-059 disparaissent complètement.**
`281 → 0`, `214 → 0`, `65 → 0`, `11 → 0`. ObjectDB `951 → 103`,
resources `626 → 54`.

### 5.1 Ce qui reste, énuméré et non résumé

`apres_correctif/worldv2_verbose.log`, décompté :

```
  55  GDScript
  45  GDScriptNativeClass
   1  AudioStreamWAV            res://assets/audio/sfx/land_soft.wav
   1  AudioStreamPlaybackWAV
```

- Les **100 objets de script** sont le résidu que la bissection avait déjà
  identifié et expliqué : charger une `.tscn` épingle les `GDScript` qu'elle
  attache et leurs `GDScriptNativeClass`. C'est le cache de scripts du moteur,
  pas un conteneur du projet. **Le témoin est à zéro, et les suites lancées par
  le runner sortent également propres** : ce résidu appartient au chemin
  `--script` d'une sonde qui charge des scènes, pas au harnais.
- Le **flux audio** est un vrai petit défaut, nommé ici pour la première fois :
  `land_soft.wav` — le son de réception du joueur, qui apparaît au spawn parce
  que le personnage tombe au sol. Un objet, aucune classe de RID. **Non corrigé
  dans cette passe** : c'est le chemin audio, hors du périmètre d'ISS-059, et le
  corriger à l'aveugle sur une passe de fuite mémoire serait exactement le genre
  d'élargissement que la directive interdit. Ticket ouvert.

---

## 6. Ce qui reste `NON VÉRIFIÉ`

- Que le résidu de 100 objets de script soit **inévitable** : je l'ai expliqué
  et localisé, je n'ai pas démontré qu'aucune API n'en dispose. Aucune n'est
  exposée à GDScript à ma connaissance ; ce n'est pas une preuve.
- L'effet du correctif sur la **suite complète** : mesuré une seule fois, au
  `validate_fast` final de cette passe. Une seule mesure n'est pas une série.
- Le **flux audio** n'a pas été reproduit hors de `WorldV2` : je ne sais pas s'il
  vient du joueur, d'un pool d'`AudioManager`, ou d'un `AudioStreamPlayer3D`
  libéré en cours de lecture.
