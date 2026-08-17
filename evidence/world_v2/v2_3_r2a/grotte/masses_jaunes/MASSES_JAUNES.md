# Les masses jaunes devant la bouche — identifiées

**Commit des captures : `79e7ae25a5c6dd0b2a5da5cd9ff4b0d4b0e78c4a`** ·
`repo_dirty: false` · scène `res://scenes/world_v2/WorldV2.tscn` · Forward+ ·
llvmpipe · 1280 × 720.

Manifeste complet : `t2_02_approche_joueur_diagnostic.json`.

---

## Réponse

Les masses jaunes sont des **`Flower_4_Group`** de la végétation cellulaire
**V2.2**, dans les cellules `veg_c4r8` et `veg_c4r7`. Elles n'appartiennent
pas au lieu.

| nœud | catégorie | propriétaire | profondeur | écran | hauteur apparente |
|---|---|---|---:|---:|---:|
| `veg_c4r8_flowers_Flower_4_Group` | végétation | cellule `veg_c4r8` | 6,86 m | (298, 487) | **2,14 m — 216 px** |
| `veg_c4r7_flowers_Flower_4_Group` | végétation | cellule `veg_c4r7` | 10,07 m | (1042, 476) | **2,10 m — 144 px** |
| `veg_c3r8_flowers_Flower_4_Group` | végétation | cellule `veg_c3r8` | 24,39 m | (−43, 236) | 2,30 m |

Et, dans la même mesure, la réfutation définitive de ce que j'avais annoncé
deux tours plus tôt :

| nœud | catégorie | propriétaire | profondeur | hauteur apparente |
|---|---|---|---:|---:|
| `Fern_1` | places | lieu `valley.poi.waterfall_cave.01` | 7,47 m | 0,19 m — **18 px** |
| `Fern_1` | places | lieu `valley.poi.waterfall_cave.01` | 8,68 m | 0,19 m — **15 px** |

Les fougères du lieu font quinze à dix-huit pixels de haut. Elles ne peuvent
masquer le tiers inférieur de rien.

## La preuve par masquage, à caméra strictement identique

Six captures, même œil `(-100,00 ; 3,42 ; 12,00)`, même cible
`(-106,00 ; 4,60 ; 3,60)`, même FOV 55°, une catégorie retirée par image :

| fichier | catégorie retirée | masses jaunes |
|---|---|---|
| `…_00_reference.png` | — | présentes |
| `…_01_sans_places.png` | lieux | présentes |
| `…_02_sans_vegetation.png` | **végétation V2.2** | **disparues** |
| `…_03_sans_terrain.png` | terrain, eau, routes | présentes |
| `…_04_sans_distant.png` | décor distant | présentes |
| `…_05_sans_fx.png` | marqueurs, whitebox | présentes |

Retirer les lieux ne change rien aux masses jaunes ; retirer la végétation
cellulaire les fait toutes disparaître, et la bouche est alors entièrement
dégagée.

## La cause, mesurable et hors de mon périmètre

`Flower_4_Group` mesure **2,487 m** en natif — mesure à la source, hors
moteur :

```
python3 tools/gltf_inspect.py assets/environment/foliage/Flower_4_Group.gltf
dimensions_m : [1.7805, 2.4868, 1.3675]
```

`VISUAL_ASSET_BIBLE` §3 borne les fleurs à **0,18–0,55 m**. Le projet possède
déjà la correction, écrite pour ce défaut exact : `scripts/world/kit_scale.gd`
normalise `Flower_4_Group` de 2,487 m à 0,55 m, et son en-tête dit pourquoi
elle est en un seul point — « corriger sept fois, c'est garantir qu'un
huitième oubliera ».

`scripts/world_v2/world_v2_vegetation_builder.gd` est ce huitième. Il charge
le modèle par `AssetRegistry.model()` et le pose à
`_ground_transform(p, rng, 0.8, 1.15, -0.03)` : un facteur de **variation**
appliqué à la taille **native**. D'où les 2,10 à 2,30 m mesurés à l'écran.

Ce n'est pas une question de goût : c'est l'invariant « 1 unité = 1 m » du
projet, et une violation de §3 de la bible visuelle, mesurée.

**Je n'y touche pas.** Le bâtisseur de végétation appartient à V2.2 ; le
modifier serait une propagation, et l'ordre en vigueur l'interdit. Le
correctif tiendrait en un appel à `KitScale` dans `_model_mesh()`, il
affecterait toutes les cellules de la vallée, et il appartient au lead de
décider s'il ouvre V2.2 pour ça.

## Ce que le lieu peut faire seul, et ce qu'il ne peut pas

La végétation cellulaire ignore les lieux : `_spot_allows()` écarte les
routes, les gués, les checkpoints et les couloirs de visée des caméras
gelées — **pas les POI**. Un lieu ne peut donc pas déclarer une clairière
autour de lui sans toucher au bâtisseur, c'est-à-dire sans propager.

Les deux grappes fautives sont à 6,9 m et 10,1 m de l'objectif, c'est-à-dire
à mi-chemin entre le joueur et la bouche, et non contre elle. Aucun
déplacement de la géométrie du lieu ne peut donc les sortir du cadre : elles
occupent l'écran par leur proximité à la CAMÉRA, pas par leur position par
rapport au sujet. C'est d'ailleurs l'erreur qui avait fait mentir mes trois
sondes précédentes — elles mesuraient une distance à la bouche.

**Statut : `IDENTIFIÉ`, `NON CORRIGÉ`, décision au lead.**

## L'outil, et le piège qu'il porte

`tools/godot/diagnose_screen_occupants.gd` refuse de conclure sous le pilote
de rendu muet : les transformations d'instance d'un `MultiMesh` n'y survivent
pas, et une sonde qui les lit sans afficheur rend des identités puis conclut,
faussement, que rien n'est là. C'est la deuxième moitié de l'explication du
désaccord entre mes sondes.

Aucun chiffre de ce document n'est une mesure de performance : llvmpipe rend
en logiciel.
