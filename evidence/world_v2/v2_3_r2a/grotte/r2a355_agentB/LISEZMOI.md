# R2a-3.5.5 — Agent B, robustesse de la chaîne

Socle : `f39b232`, worktree `/home/user/zelda-r2a355/b_chaine`. Jamais poussé.

| GLB | empreinte | octets |
|---|---|---:|
| avant (socle intact) | `c184c8dc0c0e754a` | 1 490 320 |
| après correction | `5bd1b4f5115bfd35` | 1 490 392 |

Delta **+72 octets**. Le nombre de triangles, de sommets et d'arêtes est
**identique** : la correction triangule un unique n-gone en amont de
l'export, ce qui change l'ordre des indices, pas la surface.

## Les deux défauts, et ce qu'ils sont vraiment

### Triangle d'aire nulle — RÉEL, attribution HÉRITÉE RÉFUTÉE, **CORRIGÉ**

Trois sommets **distincts** et **exactement colinéaires** (`s1` est le milieu
exact de `s0s2`), plus courte arête **0,241 m**. `dissolve_degenerate(dist=1e-5)`
ne pouvait structurellement pas le voir : son critère porte sur la longueur
des arêtes, et celle-ci vaut **24 100 fois** la tolérance. Ce n'était pas un
seuil trop bas, c'était le mauvais critère.

**L'attribution héritée disait « né à la soustraction ». C'est faux.** Mesuré :
après `soustraire()`, le maillage Blender contient **zéro** face d'aire nulle,
mais un **n-gone à 13 côtés** (polygone 7802) portant un triplet consécutif
colinéaire. Le triangle plat est fabriqué par la **triangulation d'export**.

Correction : `_desamorcer_ngones_colineaires()`, appelée en fin de
`soustraire()`. Elle triangule *uniquement* les n-gones porteurs d'un triplet
colinéaire exact, puis résout par bascule d'arête les triangles plats
résiduels. Chirurgical : **1 face sur 17 458**, **0 bascule nécessaire**.
Une bascule est purement topologique — aucun sommet déplacé, ni surface, ni
volume, ni silhouette modifiés.

### Auto-intersections — RÉELLES, sous-comptées, **NON CORRIGÉES**

Les paires signalées **ne sont pas des faux positifs** : calcul exact sans
tolérance, point intérieur commun publié. Mais le compte est faux :

| maillage | annoncé par `controle_repli()` | mesuré exact |
|---|---:|---:|
| `SM_WaterfallCave` (candidat) | 2 | **6** |
| `COL_WaterfallCave` (candidat) | *jamais mesuré* | **62** |
| `SM_WaterfallCave` (**R2a-3.4 livrée**) | **0** | **10** |
| `COL_WaterfallCave` (R2a-3.4 livrée) | *jamais mesuré* | **7** |

Attribution rejouée sur mon socle : **0** pénétration après remaillage,
retrait de bulles et stratification ; **4** après décimation, toutes dans le
même amas. L'attribution « décimation » est **confirmée**. Les 2 pénétrations
de l'autre amas apparaissent à la soustraction.

### Profondeurs — le chiffre qui décide, et il nuance le comparatif

| géométrie | paires | enfoncement max | couture max | seuil |
|---|---:|---:|---:|---:|
| candidat, visuel | 6 | **0,000612 m** | 0,570 m | 0,020 m |
| R2a-3.4, visuel | 10 | **0,000000 m** | 0,125 m | 0,020 m |
| candidat, collision | 62 | **0,457261 m** | 0,944 m | — |
| R2a-3.4, collision | 7 | **0,020325 m** | 0,915 m | — |

Les six du visuel sont **33 fois sous le seuil** : le contrôle réparé reste
vert, honnêtement. Mais « le candidat est meilleur » n'est vrai que **sur le
compte** : les 10 pénétrations de R2a-3.4 ont un enfoncement **sous le
demi-micron**, mille fois moindre, avec des coutures 4,5 fois plus courtes.

Le vrai point noir est ailleurs : **la coque de collision du candidat, avec
0,457 m d'enfoncement — 23 fois le seuil du visuel** — contre 0,020 m pour
R2a-3.4. C'est une régression réelle, et aucun contrôle ne la regarde.
Ticket B2.

## Le contrôle réparé, et son angle mort résiduel

`controle_penetration_exacte()` remplace `controle_repli()` sur le livrable.
Prédicats exacts, aucune tolérance, seuil `REPLI_LIVRABLE_MAX_M` **inchangé**
et grandeur bornée **inchangée** (l'enfoncement). Les deux compteurs sont
imprimés côte à côte pour que l'écart reste lisible dans le journal.

Contrôles négatifs des deux gardes
(`B4_controle_negatif/04_discriminant_negatif.log`), 7 cas, 0 échec :

- **il voit une pénétration de 1 µm que l'ancien ratait** — le gain est réel ;
- **il ne compte aucun des 4 cas de contact** (arête commune, sommet commun,
  pointe tangente, coplanaires) — et l'ancien ne les comptait pas non plus.

Donc l'écart 2 → 6 vient **uniquement de pénétrations ratées**, jamais de
faux positifs retirés. Le contrôle est strictement plus strict.

**Angle mort mesuré, et il subsiste.** Dans la chaîne, le contrôle publie
**4** là où le juge indépendant en trouve **6** sur le GLB. Cause mesurée
(`B7_controle_repare/02_triangulation_interne_vs_export.log`) : la
triangulation interne `bmesh BEAUTY` et celle de l'exportateur glTF
**diffèrent sur 2 178 triangles de 20 072**, soit 10,9 %. Le contrôle mesure
donc une triangulation qui n'est pas exactement celle qui part. Progrès de
2 → 4, pas exhaustivité. La correction propre serait de trianguler la chaîne
avant export, ou de faire du juge indépendant une porte post-export — les
deux changent le livrable ou le script d'export, donc relèvent d'un
arbitrage. **`NON VÉRIFIÉ` : aucune des deux n'a été essayée.**

## L'instrument, et pourquoi on peut le croire

`tools/cave_exact_intersect.py` — aucun BVH, aucun epsilon. Les float32 d'un
GLB sont des rationnels dyadiques ; `Fraction` les représente sans perte et
un déterminant 3×3 de Fractions est exact. Définition appliquée : deux
triangles se pénètrent si l'intersection de leurs **intérieurs relatifs** est
non vide. Les inégalités barycentriques sont résolues comme un intervalle
ouvert exact, sans échantillonnage.

Éprouvé avant d'être cru :
- `B1_realite/00_autotest_discriminant.log` — 10 cas connus, 10 verdicts
  corrects, tous symétriques. Une pointe qui entre de **1 µm** est vue.
- `B1_realite/02_invariance_permutation.log` — **6 / 6 / 6** sous identité,
  permutation `(z, x, −y)` et miroir `(−x, y, z)`. Ces transformations sont
  des isométries exactes en virgule flottante. L'instrument mesure la
  géométrie, pas son repère. C'est le contre-test qui avait démasqué le bruit
  flottant dans l'historique du projet.

## Contrôles négatifs — le rouge vient bien de la cause annoncée

| contrôle | attendu | obtenu |
|---|---|---|
| témoin non corrigé, triangle plat | ROUGE **à la position annoncée** | ROUGE, face 10486 en `(−1.5044, −0.6392, 3.0989)` |
| chaîne corrigée | VERT | VERT, 0 triangle d'aire nulle |
| booléen inoffensif, témoin | ouvre le maillage | 20072 → **20071** faces, **3 bords libres** |
| booléen inoffensif, corrigé | n'ouvre rien | 20072 → **20072** faces, **0 bord libre** |

Le dernier est la preuve fonctionnelle : le triangle plat n'était pas un
défaut cosmétique. Le solveur exact de Blender le supprimait de lui-même,
ouvrant un maillage par ailleurs fermé.

## Non-régression

| mesure | avant | après |
|---|---|---|
| V / E / F (visuel) | 10038 / 30108 / 20072 | **identique** |
| bords libres | 0 | 0 |
| non-manifold | 0 | 0 |
| composantes | 1 | 1 |
| genre | 0 | **0** |
| composition, entaille 0,90 | 3/3/3 | **3/3/3** |
| ratios d'emprise | 2,16 / 2,33 / 2,25 | **2,16 / 2,33 / 2,25** |

## Ce qui reste NON VÉRIFIÉ, et ce que je n'ai pas fait

- **Les 6 pénétrations du visuel ne sont pas corrigées.** L'attribution est
  établie ; la correction touche la décimation, donc rebat tout le maillage
  et croise le travail de l'agent A. Elle demande un arbitrage.
- **Les 62 pénétrations de `COL_WaterfallCave` sont une découverte**, hors
  mandat, non corrigées. Ce maillage n'est soumis à aucun contrôle de repli.
- **`controle_repli()` n'a pas été rendu plus discriminant.** Il sous-compte ;
  le corriger relève du même arbitrage.
- Ma première mesure d'attribution, par triangulation en éventail, donnait
  **109 pénétrations fantômes** après soustraction — artefact de mon
  instrument sur les n-gones non convexes. Les chiffres publiés ici ne
  proviennent que d'étapes tout-triangles ou du GLB exporté. Les étapes à
  plus de 26 000 triangles n'ont pas de comptage global.
- Aucun `validate_fast.sh`, aucune capture, aucun verdict artistique.

## Le fait qui dépasse mon mandat

**« 0 auto-intersection » n'a jamais été vrai, sur aucune géométrie, y compris
celle qui a été livrée et validée.** R2a-3.4 en porte 10 pendant que le
contrôle en publie 0. `_straddle_points()` teste si les sommets sont de part
et d'autre du **plan** de l'autre face, au-delà de `TOLERANCE_TANGENCE_M`.
Deux triangles **bornés** peuvent se pénétrer sans satisfaire ce test, et le
satisfaire sans se toucher. C'est le mode de panne d'ISS-018 tel que
`PROMPT4_METHOD` §2 le décrit : un test vert qui ne rougirait pas.
