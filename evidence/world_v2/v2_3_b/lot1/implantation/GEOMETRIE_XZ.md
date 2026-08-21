# Lot 1 — implantation, PHASE 1 : ce qui se mesure sans le moteur

**VIVANT** jusqu'à la publication de `SITES.md`, qui le remplacera comme
source. Voie A, 2026-08-21.

Ce document ne contient que des grandeurs du **plan XZ**, calculées à partir
de fichiers committés et gelés : les polylignes de
`resources/world_v2/world_v2_layout.json`, les littéraux de
`scripts/world_v2/world_v2_cameras_builder.gd`, les demi-largeurs de
`scripts/world_v2/world_v2_heightmap.gd`, et les seuils de
`tests/world_v2/test_world_v2_places_contract.gd`. Aucun nombre n'est recopié
à la main : l'outil les extrait, et **échoue en 3 si un motif est absent**.

Reproduction, à la ligne près :

```bash
python3 tools/mesure_implantation_lot1.py            # tableau
python3 tools/mesure_implantation_lot1.py --json     # document
```

Sorties versées : `geometrie_xz.txt`, `geometrie_xz.json`.

## Ce que cette phase NE dit PAS

Hauteur du terrain, pente, eau sous le site, végétation gelée : **`NON
VÉRIFIÉ`**. Ces quatre grandeurs sortent de `WorldV2Heightmap` et du monde
monté ; elles sont le travail de `tools/godot/sonde_implantation_lot1.gd`, et
elles arrivent en phase 2. Rien ici ne permet d'écrire `POSABLE` pour un
sujet — au mieux « rien ne s'y oppose dans le plan ».

Un portage Python de `height_at()` aurait donné ces nombres tout de suite. Il
a été **écarté volontairement** : ce serait une seconde source de vérité pour
le relief, qui divergerait de la première sans que personne ne le remarque.
Le relief se mesure là où il est défini.

## Seuils réellement appliqués (lus dans le code, pas dans la prose)

| grandeur | valeur | source |
|---|---:|---|
| `ROUTE_CLEAR_M` (lieu) | 1,2 m | `test_world_v2_places_contract.gd` |
| `SITE_XZ_TOLERANCE_M` | 0,5 m | idem |
| `ROOT_GROUND_TOLERANCE_M` | 1,0 m | idem |
| `SUPPORT_TOLERANCE_M` | 0,65 m | idem |
| bande creusée, cours principal | 9,5 m | `RIVER_BED_HALF_W` + `RIVER_BANK_W` |
| bande creusée, affluent | 6,3 m | `TRIB_BED_HALF_W` + `TRIB_BANK_W` |
| dégagement du lac | 16,0 m | rayon 14 (layout) + 2 |
| visée libre | 60 % du trajet | `CLEAR_SIGHT_FRACTION`, `test_world_v2_cameras.gd` |

Rappel du contrat du lot : le `ROUTE_CLEAR_M = 2,3 m` du §4 de
`WORLD_V2_POI_CONTRACTS.md` est l'exclusion **végétale**, gelée avec V2.2.
Un lieu répond au 1,2 m ci-dessus.

**Aucun des six sites n'est sous influence de gué** : le plus proche est
`ford.west` à 43,86 m de la Source aux reflets, quand `FORD_INFLUENCE_M` vaut
24 m. Les bandes creusées gardent donc partout leur largeur ordinaire ; le
profil élargi du gué (jusqu'à 24 m sur le cours principal) ne s'applique à
aucun sujet. C'est une vérification, pas une évidence : elle change la
largeur interdite du simple au double.

## Le tableau

| sujet | site v2 | route la + proche | cours | affluent | lac (centre) | visée la + serrée |
|---|---|---|---:|---:|---:|---|
| `watchtower_ruin` | (-160, 26, 40) | river_route 66,48 | 143,19 | 30,59 | 231,14 | cam04 48,37 |
| `overlook_summit` | (168, 22, 52) | **heights_route 0,00** | 32,06 | 196,98 | 265,24 | **cam05 2,83** |
| `turquoise_spring` | (-136, 12, 40) | river_route 43,86 | 120,64 | **8,49** | 216,89 | cam04 30,00 |
| `forest_shrine` | (86, 7, 74) | heights_route 7,28 | 55,56 | 128,28 | 236,64 | cam05 29,43 |
| `barrow_cemetery` | (56, 4, -64) | main_path 38,18 | 72,80 | 107,63 | 104,00 | cam03 14,00 |
| `flower_field` | (-56, 5, 124) | river_route 35,90 | 123,13 | 105,47 | 267,16 | cam04 45,36 |

Marges (positif = dégagé) :

| sujet | route − 1,2 | cours − 9,5 | affluent − 6,3 | lac − 16,0 |
|---|---:|---:|---:|---:|
| `watchtower_ruin` | +65,28 | +133,69 | +24,29 | +215,14 |
| `overlook_summit` | **−1,20** | +22,56 | +190,68 | +249,24 |
| `turquoise_spring` | +42,66 | +111,14 | **+2,19** | +200,89 |
| `forest_shrine` | +6,08 | +46,06 | +121,98 | +220,64 |
| `barrow_cemetery` | +36,98 | +63,30 | +101,33 | +88,00 |
| `flower_field` | +34,70 | +113,63 | +99,17 | +251,16 |

## Les trois contraintes que la voie B doit connaître AVANT de modéliser

### 1. `overlook_summit` — le site EST un point de passage de route

`heights_route` contient le waypoint `[168, 52]`, qui est exactement le
`v2_site` du Belvédère. La distance du site à la route n'est pas « faible » :
elle est **nulle**. Le filet interdit tout collider de lieu à moins de 1,2 m
d'un échantillon de route, et les échantillons sont pris au mètre le long des
segments : un seul corps de collision posé au centre du site rougit
`test_aucun_acteur_et_les_routes_restent_libres`.

**Où se trouve le couloir, exactement.** Les deux jambes de route qui se
rejoignent au sommet partent toutes les deux vers le **nord** (convention du
layout : `+Z = sud`) : le waypoint précédent `(158, 42)` est à 14,14 m au
nord-ouest, le suivant `(190, 30)` à 31,11 m au nord-est. `cam05` est à 2,83 m
au **sud-ouest**. Le secteur libre de toute contrainte est donc le
**sud-est** — c'est là qu'une masse peut se poser sans toucher ni le couloir de
route ni le champ immédiat de l'objectif.

Ce n'est pas un défaut du layout — c'est son intention : la route des hauteurs
passe PAR le belvédère, on le gravit en chemin. Mais cela impose une facture
précise : **le sommet reste marchable et libre**, et toute masse de collision
(borne, cairn, garde-corps, ruine) s'écarte du couloir. Le contrat annonce
« arme au sol — arc simple » : l'ancre de récompense n'a pas de collider, elle
ne pose pas de problème ; les décors qui l'entourent, si.

### 2. `overlook_summit` — cam05 est posée à 2,83 m du site

`cam05_belvedere_crete` est en `(166, 54)`, regarde `(0, 26, 170)`. Le site
est en `(168, 52)` : **2,83 m derrière l'objectif**. « Derrière » est
mesuré, pas supposé — le produit scalaire de la direction de visée
`(-166 ; 116)` par le vecteur caméra→site `(+2 ; -2)` vaut **−564 m²**, donc
le paramètre d'approche est nul et le point du segment le plus proche est la
caméra elle-même (distance au segment = distance à la caméra = 2,83 m, ce que
le tableau montre).

Deux conséquences opposées, et il faut les tenir ensemble :

* la fenêtre regarde **à l'opposé** du site : une masse posée à l'est du
  sommet ne bouche rien ;
* mais elle est à moins de trois mètres. Toute pièce qui s'avance vers
  l'ouest — un pan de mur, une avancée de plateforme, un arbre — entre dans
  le cône, à un mètre de la lentille, et remplit le cadre.

La hauteur de l'œil est `height_at(166, 54) + 2,4 m` : **elle reste à
mesurer**. Une pièce plus basse que l'œil ne coupe pas le rayon, mais peut
tout de même occuper le bas de l'image — ce que ce filet-là ne mesure pas et
que seule une capture montrera.

### 3. `turquoise_spring` — 2,19 m de marge sur la bande creusée de l'affluent

Le site est à 8,49 m de la polyligne de l’affluent, dont la bande creusée fait
6,30 m. La note du layout le dit : « l'affluent naît juste à l'est ». La marge
utile est donc de **2,19 m**, et elle est directionnelle : vers l'est-nord-est
(le point le plus proche est sur le segment `(-130,34) → (-124,22)`).

Toute jetée, margelle, vasque ou éboulis qui s'avance de plus de 2,19 m vers le
cours entre dans la coupe de berge — c'est-à-dire dans une pente que le
terrain gelé creuse activement, et où rien ne peut s'asseoir proprement.

## Deux points à surveiller, sans être des contraintes

* `forest_shrine` est à **7,28 m** de `heights_route`. Le filet passe
  largement (+6,08 m), mais l'intention écrite au contrat est « invisible de
  la route — la curiosité seule y mène ». Sept mètres, c'est le bord du
  chemin. Soit le couvert végétal gelé fait le travail — à mesurer en phase 2,
  c'est précisément le comptage à 8 m — soit l'intention et le site se
  contredisent, et c'est au lead de trancher.
* `barrow_cemetery` est à **14,00 m** du segment de visée de
  `cam03_pylone_marche`. Latéralement, c'est confortable ; ce qui décide, c'est
  la **garde du rayon au-dessus du sol** au point d'approche, que la sonde
  mesure en phase 2. Un tumulus bas ne coupera rien ; une stèle de six mètres,
  peut-être.

## Voisinage — ce que le lot 1 ne doit pas recouvrir

| sujet | entité de layout la + proche | lieu déjà bâti le + proche |
|---|---|---|
| `watchtower_ruin` | `turquoise_spring` 24,00 m | `waterfall_cave` 60,46 m |
| `overlook_summit` | `veil_falls` 42,52 m | `anchor.pylon` 93,48 m |
| `turquoise_spring` | `watchtower_ruin` 24,00 m | `riverside_village` 41,23 m |
| `forest_shrine` | `logging_hamlet` 38,83 m | `checkpoint.camp` 41,98 m |
| `barrow_cemetery` | `wind_gorge` 46,65 m | `anchor.pylon` 70,72 m |
| `flower_field` | `abandoned_farm` 32,25 m | `abandoned_farm` 32,25 m |

Les 24,00 m entre le guet et la source sont exactement ceux que le contrat du
lot annonce (« à 24 m du guet : ils se lisent ensemble »). Les deux sujets
partagent une lecture : leurs silhouettes doivent se compléter, pas se
concurrencer.

## Défaut trouvé en chemin, dans un outil, NON corrigé

`tools/godot/probe_vegetation_near.gd` compte les instances de végétation en
faisant `multi.global_transform * origines[i]`. Or `instance_origins` contient
déjà des coordonnées **monde** : `_emit_cells()` retranche la position de la
cellule de la transformée envoyée au moteur, **pas** de la méta
(`origins.append(transforms[i].origin)` lit la transformée d'origine, non
décalée). C'est d'ailleurs ainsi que la lit
`test_world_v2_landscape_contract.gd`, qui compare `origin.y` à
`height_at(origin.x, origin.z)` et les segments de route en coordonnées monde.

La sonde ajoute donc la position de la cellule — jusqu'à ±240 m — à chaque
point avant de mesurer une distance. Ses comptes « dans N mètres » portent sur
un autre endroit du monde.

Ce n'est pas corrigé ici : l'outil n'est pas dans le périmètre de la voie A, et
surtout l'en-tête de `thunderstruck_tree_place.gd` — fichier **gelé** — cite
une mesure prise avec lui (« 0 instance gelée dans les 8 m »). Toucher l'outil
sans rejouer cette mesure remplacerait un chiffre douteux par un autre. C'est
remonté au lead, avec sa reproduction.

`tools/godot/sonde_implantation_lot1.gd` se protège du même piège autrement :
elle mesure le **résidu d'ancrage** des deux lectures possibles avant de
compter quoi que ce soit, et **BLOQUE en 3** si les deux se valent.
