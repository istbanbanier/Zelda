# D5 — la première version du critère était FAUSSE, et voici la mesure

Daté du 2026-08-21. Rejeu sur le **corpus accepté** — les neuf lieux du lot
pilote validés par le lead — parce que c'est le seul corpus dont on sache
d'avance qu'il ne porte AUCUN placement codé en dur.

## Version 1 : « les deux coordonnées du site dans le même fichier »

Raisonnement de départ : porter `40.0` par hasard est courant, porter `-160`
ET `40` par hasard ne l'est pas. La probabilité tombe au produit de deux
coïncidences.

**Faux.** Mesuré :

| lieu | site | verdict |
|---|---|---|
| `camp` | (45, 65) | **ACCUSÉ** |
| `valley.poi.stone_bridge.01` | (-10, 22) | **ACCUSÉ** |
| `valley.poi.ember_raider_camps.01` | (96, 120) | **ACCUSÉ** |
| les six autres | — | propres |

**3 accusations sur 9 lieux validés.** La cause est visible dès qu'on regarde
les nombres : `45`, `65`, `-10`, `22`, `96`, `120` sont des entiers ronds
banals dans du code de composition — des angles, des rayons, des comptes. Le
produit de deux coïncidences n'est pas petit quand chaque coïncidence est
grosse.

Un filet qui crie au loup sur un tiers du corpus validé finit désarmé. C'est
une façon de perdre un contrôle sans que personne n'ait menti.

## Version 2 : la FORME du défaut

Le défaut n'est pas « le fichier contient 45 et 65 ». C'est « le fichier
CONSTRUIT une position avec le site ». Trois formes cherchées :

1. `Vector3(x, *, z)` dont `x` et `z` sont ceux du site ;
2. `position.x = <site.x>` ou `.z = <site.z>` (avec ou sans `global_`) ;
3. `Transform3D(...)` dont l'origine (champs 10 et 12) porte le site — une
   transformation figée dans une `.tscn` place le lieu tout aussi sûrement
   qu'une ligne de code.

## Mesure de la version 2

Scripts **et** scènes des neuf lieux acceptés :

```
FAUX POSITIFS sur le corpus accepté : 0 / 9 lieux inspectés
```

Contrôles positifs — le critère doit VOIR le défaut :

| forme présentée | trouvé |
|---|---|
| `position = Vector3(-160.0, 26.0, 40.0)` | `Vector3(-160.0, 26.0, 40.0)` |
| `global_position.x = 168.0` | `global_position.x = 168.0` |
| `Transform3D(1,0,0, 0,1,0, 0,0,1, 86, 7, 74)` | trouvé |
| `const S: Vector3 = Vector3(56, 4, -64)` | `Vector3(56, 4, -64)` |

Contrôle négatif — un décalage local anodin `Vector3(1.0, 0.0, 2.0)` : rien.

La quatrième forme est celle que joue le sabotage D5 de
`tools/gate_negatif_lot1.sh` : une constante déguisée en réglage.

## Ce que cette page prouve, et ce qu'elle ne prouve pas

Elle prouve que le critère **discrimine** sur le seul corpus disponible. Elle
ne prouve rien sur les six lieux du lot, qui n'existent pas encore : leur
verdict reste `NON VÉRIFIÉ` jusqu'au rejeu du filet après livraison.

Reproduction : le script de mesure est dans le rapport de la voie C ; le
critère lui-même est `_litteral_de_site()` dans
`tests/world_v2/test_world_v2_lot1_defauts.gd`.
