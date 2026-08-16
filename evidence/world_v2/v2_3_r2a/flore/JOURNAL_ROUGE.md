# Régression florale V2.2 — le rouge, archivé AVANT correction

**Commit mesuré : `59e0adb700ae4790cd93fc2444702a829bf05857`** ·
worktree `/home/user/zelda-r2a34/flore` · Godot 4.7.1-stable
(`custom_build.a13da4feb`) · headless, renderer muet · aucune correction
appliquée.

Journal brut : `journal_rouge_59e0adb.log`.

---

## Ce qui est rouge

```
=== RÉSULTAT: 1 réussi(s), 1 échoué(s) ===
  ÉCHEC test_world_v2_flora_scale.gd::test_aucune_fleur_plantee_ne_depasse_le_plafond_de_la_bible
    la plus haute est Flower_4_Group dans c2r8 (natif 2.4868 m x instance 1.1423) à 2.841 m
    (+50 autres couches en dépassement)
```

Le second test — le témoin d'invariance — est **vert** : il épingle l'état
non corrigé, c'est son rôle.

## La mesure, et sa concordance avec la source

Le moteur lit `Flower_4_Group` à **2,4868 m** de haut. Hors moteur, sur le
même dépôt :

```
python3 tools/gltf_inspect.py assets/environment/foliage/Flower_4_Group.gltf
dimensions_m : [1.7805, 2.4868, 1.3675]
python3 tools/gltf_inspect.py assets/environment/foliage/Flower_3_Group.gltf
dimensions_m : [1.4885, 2.0548, 1.5911]
```

Les deux chiffres coïncident à la quatrième décimale : l'import ne déforme
rien, la faute est bien dans la POSE.

`VISUAL_ASSET_BIBLE` §3 borne les fleurs à **0,18–0,55 m**. Mesuré dans le
monde monté :

| variante | natif | variation posée | hauteur monde | plafond bible |
|---|---:|---:|---:|---:|
| `Flower_4_Group` | 2,4868 m | 0,80–1,15 | **1,99 – 2,84 m** | 0,55 m |
| `Flower_3_Group` | 2,0548 m | 0,80–1,15 | **1,64 – 2,36 m** | 0,55 m |

La plus haute fleur plantée mesure **2,841 m** : plus haute qu'un héros
d'1,78 m de plus d'un mètre, et **5,2 fois** le plafond.

## La cause, en un point de code

`scripts/world_v2/world_v2_vegetation_builder.gd`, `_build_cell` §3 :

```gdscript
_append_model(flowers, flower_model, _ground_transform(p, rng, 0.8, 1.15, -0.03))
```

`_ground_transform` applique une **variation** à la taille **native**. Le
bâtisseur de végétation cellulaire V2.2 est le seul module de World V2 à ne
pas consulter `scripts/world/kit_scale.gd` — le point unique de correction
d'échelle du projet, écrit pour ce défaut exact. L'autre poseur de V2,
`scripts/world_v2/poi/world_v2_place_kit.gd:70` (`module`), l'applique
correctement.

C'est le « huitième module » que l'en-tête de `KitScale` annonçait :
« corriger sept fois, c'est garantir qu'un huitième oubliera ».

## Pourquoi aucun test existant ne l'avait vu

`tests/integration/test_kit_scale.gd` couvre déjà « aucune pièce végétale
plantée ne dépasse son plafond ». Il ne pouvait pas voir celle-ci, pour deux
raisons cumulées :

1. il monte `ValleyWorld.tscn` — le monde V1, pas World V2 ;
2. il énumère des `MeshInstance3D`, alors que la végétation V2 est en
   `MultiMeshInstance3D`.

C'est le piège nommé mot pour mot dans `tools/CLAUDE.md` : « une sonde qui ne
collecte que des `MeshInstance3D` la déclare absente — silencieusement ».

## Lien avec la revue R2a-3.3

Le lead a prononcé **PASS TECHNIQUE — FAIL VISUEL**, dont « les fleurs
géantes masquent l'entrée » de la Grotte du Couchant. Le diagnostic
`../grotte/masses_jaunes/MASSES_JAUNES.md` avait identifié les coupables par
masquage à caméra identique : `Flower_4_Group` des cellules `veg_c4r8` et
`veg_c4r7`, hauteurs apparentes 2,10 et 2,14 m.

Le présent test mesure la même faute **par la géométrie**, sans caméra et
sans jugement d'image : 56 couches en dépassement sur toute la vallée, dont
celles de la grotte. La grotte était le symptôme le plus visible, pas le
périmètre du défaut.

## Le témoin d'invariance, mesuré ici

Épinglé dans le test avant toute correction, reproduit à l'identique sur deux
passages successifs :

| catégorie | instances | somme X | somme Y | somme Z | somme échelles |
|---|---:|---:|---:|---:|---:|
| `grass` | 12 570 | 20 004,2914 | 128 604,1517 | 816 381,5592 | 13 513,6401 |
| `tall` | 1 985 | −87,4601 | 40 697,9946 | 334 611,8255 | 2 128,5345 |
| `reeds` | 7 | −588,1430 | 13,4484 | 135,7969 | 7,5395 |
| `tree` | 197 | 14 889,9664 | 1 900,7008 | 9 588,2803 | 218,0460 |
| `rock` | 698 | 1 788,8191 | 9 815,9115 | −6 175,0403 | 800,5724 |
| `flowers` | 1 194 | −22 648,5969 | 13 960,9344 | 130 360,7182 | *1 162,5143* |

La somme des échelles florales (en italique) est la **seule** grandeur que la
correction a le droit de changer ; elle n'est pas épinglée. Tout le reste est
épinglé et doit survivre bit pour bit.

## Ce que ce document ne prouve pas

Aucune capture ici, donc aucune preuve que la bouche de la grotte est
dégagée à l'écran. Ce point reste `NON VÉRIFIÉ` et relève de la vérification
visuelle du lead. Aucun chiffre de ce document n'est une mesure de
performance : le rendu est muet.
