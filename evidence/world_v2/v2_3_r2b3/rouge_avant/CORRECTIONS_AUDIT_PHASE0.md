# Corrections de l'instrument après la phase 0 de l'audit indépendant

L'audit a rendu trois constats **bloquants** sur `tools/mesure_boititude.py`,
qui est du lead. Les trois se sont reproduits à l'identique. Ils sont corrigés
ici, avant que la voie A ne rende quoi que ce soit.

## 1. Un nom de mesh inconnu rendait `RC=0` et « OK »

```
$ mesure_boititude.py SM_Farm_Ruins.glb --mesh Debris_A --plafond 25
les meshes retenus   0   0.0%
OK : hexa 0.0% <= plafond 25.0%        RC=0
```

Les noms réels sont `SM_Farm_Debris_A` / `_B`. **Un portail qui rend vert sur un
ensemble vide est pire qu'un portail absent** : il produit une ligne de rapport
qu'on recopie dans un gate. Deux documents du dépôt employaient déjà le nom
court — `rouge_avant/LISEZMOI.md` et l'entrée ISS-060 de `KNOWN_ISSUES.md`.

Corrigé : un nom introuvable **BLOQUE en code 2** et liste les noms présents.

## 2. Le plancher d'arête minimale rejetait les assets qui le justifiaient

J'avais relâché `arete_min` de 0,03 à 0,005 m après avoir lu `BranchE` à
0,007089 sur l'arbre. **Je n'avais lu que la fin de ma propre sortie.** Le
minimum réel du même fichier est `_Heart` à **0,003941**, deux lignes plus haut.

| asset accepté | `arete_min` | passait mon plancher de 0,005 ? |
|---|---:|---|
| grotte `r2a358` | 0,000365 | **non** |
| pont de pierre | 0,000573 | **non** |
| quai du village | 0,008750 | oui |
| arbre foudroyé (`_Heart`) | 0,003941 | **non** |
| mur du village | 0,029280 | oui |

Trois assets **gelés et validés** auraient été refusés par mon propre plancher.

Cause de fond, et c'est elle qui compte : `arete_min` est une **statistique
d'ordre extrême** — un triangle sur 3 574 la fixe. Aucune valeur ne sépare une
écharde légitime d'une pulvérisation. La ligne TOTAL ne l'agrégeait d'ailleurs
même pas : le plancher portait sur une grandeur que l'instrument n'exposait
jamais globalement.

**Remplacé par la mesure proposée par l'audit** : `aire_fine` = part de l'aire
portée par des triangles dont la plus longue arête est sous 2 mm.

| asset accepté | `aire_fine` |
|---|---:|
| les huit mesurés | **0,0000 %** |

Plancher retenu : **`aire_fine ≤ 1 %`**. Zéro rejet parmi les acceptés, marge
immense, et la grandeur est **robuste** : il faut réellement pulvériser la
géométrie pour la faire monter.

## 3. Le liant tombait à 0 % sous quatre perturbations invisibles

Triangle d'aire nulle, subdivision coplanaire au barycentre, coin décalé de
12 µm, pavé réparti sur deux primitives. Dans les quatre cas l'image ne bouge
pas d'un pixel et le pavé cesse d'être compté. `Debris_A` porte **déjà trois
primitives**. Le risque n'est pas la fraude : c'est le **vert accidentel après
un remaillage**.

Corrigé sur quatre points :

- les primitives d'un même mesh sont **fondues** avant analyse ;
- les triangles d'aire nulle sont **écartés** avant tout comptage ;
- le soudage passe de 10 µm à **0,1 mm** — 5× sous la plus fine arête d'un
  asset accepté ;
- nouveau prédicat **`pave6`** : exactement 6 plans, et exactement 8 sommets
  appartenant chacun à au moins 3 plans. Un sommet de subdivision coplanaire
  n'appartient qu'à un plan : il ne compte pas comme coin.

**Le LIANT est désormais `hexa` OU `pave6`.** C'est un renforcement strict : tout
ce que `hexa` attrapait, le liant l'attrape encore. Le plafond reste **25 %**.

L'`--autotest` passe de 5 à **10 cas**, dont les cinq perturbations ci-dessus.
Il échouait sur trois d'entre elles avant correction.

## Continuité des chiffres avec R2B.2

| grandeur | R2B.2 | après correction | écart |
|---|---:|---:|---|
| liant, GLB entier | 79,6 % | **79,8 %** | +0,2 |
| `equidistance` | 42,1 % | **42,2 %** | +0,1 |
| `Debris_A` / `_B` | 96,8 % | **96,8 %** | 0 |
| triangles | 2 080 | **2 076** | **−4** |

L'écart s'explique entièrement : **le fichier contient 4 triangles d'aire nulle**
(tous dans `GableBreak`), désormais écartés. Le budget réel est donc 2 076, pas
2 080 — et le manifeste d'assets, lui, annonce 1 996.

## Recalibrage du plafond — mon témoin était mauvais

J'avais calibré 25 % sur l'arbre foudroyé (10,4 %). L'audit a proposé un témoin
de **la même famille d'objet** :

| asset accepté | liant |
|---|---:|
| `SM_Dungeon_RubbleLarge` (tas de gravats, 10 composantes) | **0,00 %** |
| `SM_Dungeon_RubbleSmall` (tas de gravats, 9 composantes) | **0,00 %** |
| pont de pierre, 15 784 tris | 0,00 % |
| grotte `r2a358`, 20 948 tris | 0,00 % |
| mur et quai du village | 0,00 % |
| pylône | 6,71 % |
| arbre foudroyé | 10,41 % |

**Un tas de gravats accepté de ce projet rend 0,00 %.** Le plafond de 25 % n'est
donc pas seulement atteignable : il est **généreux**. Il ne bouge pas — la
directive l'interdit et il n'y a aucune raison de le durcir en cours de passe —
mais viser 24 % serait passer le portail en manquant la cible.
