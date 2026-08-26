# ISS-071 — parité éditeur/export ATTEINTE

**HISTORIQUE.** Fige un état mesuré. L'autorité sur ce que la parité doit
être est `docs/contrats/iss071_parite_resolveurs.md`.

Portail exécuté par le lead, arbre committé, build autonome lancée sous
Xvfb avec un `user://` vierge.

| | |
|---|---|
| verdict | **VERT, code 0** |
| contrôles | 30 exécutés · **0 ROUGE** · 0 BLOQUÉ · 2 NON VÉRIFIÉ |
| binaire avant correctif | `e8e318321386c76e…` |
| binaire après correctif | `889af321c4ea9066…` |

Le sha du binaire CHANGE : le correctif est bien entré dans le PCK. Un sha
identique aurait signifié qu'il n'y était pas.

## Compteurs, tous positifs ET égaux

| grandeur | éditeur | export |
|---|---:|---:|
| WorldV2PlaceKit — index | 215 | 215 |
| WorldV2PlaceKit — noms demandés | 99 | 99 |
| WorldV2PlaceKit — appels demandés | 468 | 468 |
| WorldV2PlaceKit — **appels manqués** | 0 | 0 |
| WorldV2PlaceKit — collisions | 0 | 0 |
| WorldV2PlaceKit — **modules instanciés** | 459 | 459 |
| AssetRegistry — index | 160 | 160 |
| AssetRegistry — noms demandés | 21 | 21 |
| AssetRegistry — appels demandés | 24 | 24 |
| AssetRegistry — **appels manqués** | 0 | 0 |
| AssetRegistry — collisions | 0 | 0 |
| végétation — **cellules émises** | 631 | 631 |
| végétation — cellules manquées | 0 | 0 |
| lieux posés | 16 | 16 |

## Le contrôle que le portail ne peut pas faire

Une parité peut s'obtenir en cassant les DEUX côtés. Le manifeste éditeur
après correctif vaut `674c584288bec953…`, soit exactement celui mesuré
AVANT tout correctif, sur trois exécutions indépendantes. Le correctif est
donc un **no-op en éditeur** : la parité vient de la réparation de
l'export, pas d'un nivellement par le bas.

## `Wall_Arch`, l'anomalie qui devait disparaître

Avant correctif, la build demandait `Wall_Arch` que l'éditeur ne demandait
jamais — seule différence de modèles demandés côté kit. Cause :
`conductive_basin_place.gd` prend `DoorFrame_Round_Brick` quand il se
résout et se replie sur `Wall_Arch` sinon. Le repli partait parce que la
résolution échouait. Après correctif : **`Wall_Arch` n'est plus demandé du
tout**. Sa disparition est un signal positif, pas une régression.

## Ce qui reste NON VÉRIFIÉ à ce stade

Les invariants I4/I5 exigent que TOUT chemin indexé soit chargeable. Le
portail n'a pu l'éprouver que sur les chemins réellement demandés au
montage : 99 sur 215 côté kit, 21 sur 160 côté registre. Les 116 et 139
autres ne bloquent pas la table §4, mais ils ne sont pas prouvés.

---

## Addendum — les deux `NON VÉRIFIÉ` sont fermés

Seconde exécution du portail, avec `--iss071-chargeabilite` des deux côtés :

```
VERDICT ISS-071 : VERT (code 0)
30 contrôle(s) exécutés · 0 ROUGE · 0 BLOQUÉ · 0 NON VÉRIFIÉ

I4/I5 WorldV2PlaceKit : 215 chemins indexés, TOUS éprouvés par un vrai load()
                        215/215 chargés, 0 défaillant
I4/I5 AssetRegistry   : 160 chemins indexés, TOUS éprouvés
                        160/160 chargés, 0 défaillant
```

Éprouvé **des deux côtés** : 215/215 et 160/160 en éditeur comme en export.

Le contrôle de non-régression tient toujours : le manifeste éditeur, comparé
hors du champ `chargeabilite` qui vient d'être ajouté, est **identique** à celui
mesuré avant tout correctif (`275954a71a2eb5c5` sur les deux). Le correctif
reste un no-op en éditeur.
