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

---

## ERRATUM — corrections issues de la contre-revue (agent C)

Cette preuve n'est pas réécrite : elle est datée, et ce qu'elle a mesuré reste
vrai. Deux de ses **formulations** étaient fausses, et une troisième citait un
nombre que rien ne pouvait recalculer. Les voici corrigées.

**1. « Éprouvé des deux côtés » (C7) — la phrase était en avance sur le code.**
Les chiffres 215/215 et 160/160 étaient bien produits pour les deux
environnements par le jeu, mais `tools/iss071_parite.py` n'appelait
`controle_i4_i5()` que sur le manifeste d'**export**. Le portail ne vérifiait
donc réellement qu'un côté : une régression de sens inverse — un chemin devenu
non chargeable en éditeur — serait passée. Le contrôle porte désormais sur les
deux manifestes, et un scénario de mutation le prouve (voir
`CONTRE_REVUE_CORRECTIONS.md`).

**2. L'empreinte `275954a71a2eb5c5` était une ancre morte (C8).**
Aucun outil du dépôt ne la reproduisait, donc personne n'aurait pu constater
qu'elle avait cessé d'être vraie — précisément ce que `CLAUDE.md` interdit.
L'affirmation qu'elle appuyait, elle, est **exacte** et vérifiée depuis :

```
$ python3 tools/iss071_empreinte_manifeste.py --comparer \
    evidence/world_v2/v2_3_b/iss071/avant/manifeste_editeur.json \
    evidence/world_v2/v2_3_b/iss071/apres/manifeste_editeur_i45.json
931edf1fc7667fa8  …/avant/manifeste_editeur.json
931edf1fc7667fa8  …/apres/manifeste_editeur_i45.json
IDENTIQUES (hors champs volatils : chargeabilite)
```

La valeur juste est **`931edf1fc7667fa8`**, et les quatre manifestes éditeur
archivés (avant, rejeu de déterminisme, après, après+i45) la partagent. La
conclusion tient donc inchangée : **le correctif est un no-op en éditeur**, et
la parité vient d'avoir réparé l'export, non d'avoir nivelé les deux côtés.

**3. Le compte de contrôles passe de 30 à 32**, I4/I5 étant désormais évalué
une fois par environnement.
