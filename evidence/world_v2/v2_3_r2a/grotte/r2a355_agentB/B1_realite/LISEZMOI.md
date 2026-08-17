# B1 — les défauts signalés sont-ils réels ? Verdict exact, sans tolérance

Instrument : `tools/cave_exact_intersect.py`. Il n'ouvre pas Blender, n'utilise
aucun BVH, aucun epsilon. Les coordonnées d'un GLB sont des float32, donc des
rationnels dyadiques : `Fraction` les représente sans perte et un déterminant
3×3 de Fractions est exact. Le signe rendu est le vrai signe.

Définition appliquée, sans seuil : **deux triangles se pénètrent si
l'intersection de leurs intérieurs relatifs est non vide.** Deux faces
partageant une arête se coupent le long de cette arête, qui est dans la
frontière des deux — aucune pénétration. Le calcul n'échantillonne pas le
segment d'intersection : il résout les inégalités barycentriques strictes
comme un intervalle ouvert exact en `t`.

## L'instrument a été éprouvé avant d'être cru

`00_autotest_discriminant.log` — dix cas dont la réponse est connue d'avance,
dix verdicts corrects, tous symétriques par échange des arguments. Dont :

| cas | attendu | obtenu |
|---|---|---|
| arête commune, non coplanaires | CONTACT | CONTACT |
| sommet commun seulement | CONTACT | CONTACT |
| tangence pointe sur face | CONTACT | CONTACT |
| **pointe qui entre de 1 µm** | **PENETRATION** | **PENETRATION** |
| triangle dégénéré colinéaire | DEGENERE | DEGENERE |

Un cas a d'abord « échoué » : plans parallèles distincts, attendu
`PARALLELE_DISJOINT`, obtenu `DISJOINT`. C'est **mon attente qui était fausse**
— la séparation par plan attrape le cas plus tôt et `DISJOINT` est le verdict
géométriquement correct. J'ai corrigé le cas de test, pas l'instrument.

`02_invariance_permutation.log` — le contre-test qui avait démasqué le bruit
flottant dans l'historique de ce projet. Une permutation d'axes avec
changement de signe est une isométrie **exacte** en virgule flottante : aucun
bit ne change, seul l'ordre. Compte obtenu : **6 / 6 / 6** sous identité,
permutation `(z, x, −y)` et miroir `(−x, y, z)`. L'instrument mesure la
géométrie, pas son repère.

## Verdict 1 — le triangle d'aire nulle est RÉEL, et sa cause est mécanique

`01_glb_c184c8dc_exact.log`, maillage `SM_WaterfallCave`, face **10486** :

```
s0 = (-1.263276935, -0.643638015, 3.099800587)
s1 = (-1.504409909, -0.639240623, 3.098918915)
s2 = (-1.745542884, -0.634843230, 3.098037243)
arêtes 0.241174679 / 0.241174679 / 0.482349358 m
deux sommets confondus : NON
```

Aire **exactement** nulle au produit vectoriel rationnel. Trois sommets
**distincts** et **exactement colinéaires** : `s1` est le milieu exact de
`s0s2` sur les trois coordonnées. C'est la signature d'un sommet inséré au
milieu d'une arête droite par une découpe booléenne.

**La cause du survivant est établie.** `soustraire()` nettoie par
`bmesh.ops.dissolve_degenerate(dist=1e-5)`, qui s'attaque aux **arêtes
courtes**. La plus courte arête de cette face fait **0,241 m — 24 100 fois la
tolérance**. Le nettoyage existant ne pouvait structurellement pas la voir.
Ce n'est pas un réglage trop bas : c'est un critère qui ne porte pas sur la
bonne grandeur.

Repère : le centre `(−1.5044, −0.6392, 3.0989)` du GLB est le
`(−1.504, −3.099, −0.639)` des logs Blender, à la conversion Y-up près
`(x, y, z)_blender → (x, z, −y)_gltf`. Même face, même point.

## Verdict 2 — les paires d'auto-intersection sont RÉELLES, et il y en a plus

La paire annoncée par le générateur — faces `12973/12989`, centres
`(2.01, −2.18, −0.69)` et `(2.25, −1.78, −0.67)` en repère Blender — est
**confirmée comme pénétration réelle** par calcul exact. **Ce n'est pas un
faux positif.** Point intérieur commun publié dans le log.

Mais le compte est faux dans l'autre sens :

| maillage | annoncé par `controle_repli()` | **mesuré exact** |
|---|---:|---:|
| `SM_WaterfallCave` (c184c8dc) | 2 | **6** |
| `COL_WaterfallCave` (c184c8dc) | *non mesuré* | **62** |
| `SM_WaterfallCave` (**R2a-3.4 livrée**) | **0** | **10** |
| `COL_WaterfallCave` (R2a-3.4 livrée) | *non mesuré* | **7** |

Deux amas dans le visuel du candidat : autour de `(0.28, −2.24, 1.78)` et
autour de `(2.0…2.5, −2.2, −0.69)`, tous deux en repère Blender. Le second est
celui que le générateur voit. Le facteur commun de l'amas est la face `12973`,
un triangle de plus de 2 m d'arête, quasi-plan, qui traverse le relief fin
voisin — signature d'un collapse de décimation trop agressif.

## Le fait qui dépasse mon mandat, et que je remonte

**« 0 auto-intersection » n'a jamais été vrai, sur aucune géométrie, y compris
celle qui a été livrée et validée.** R2a-3.4 en porte **10** dans son maillage
visuel pendant que `controle_repli()` en publie **0**.

Le compteur ne mesure pas ce que son nom dit. `_straddle_points()` teste si les
sommets de chaque face sont des deux côtés du **plan** de l'autre, au-delà de
`TOLERANCE_TANGENCE_M = 1e-4`. Deux triangles **bornés** peuvent se pénétrer
sans satisfaire ce test, et le satisfaire sans se toucher. C'est le mode de
panne d'ISS-018 tel que `PROMPT4_METHOD` §2 le décrit : un test vert qui ne
rougirait pas en cas de régression.

Corollaire pour la directive : le candidat `c184c8dc` est **meilleur** que la
version livrée sur ce critère (6 contre 10) tout en étant le seul à porter la
face d'aire exactement nulle. Le gate « zéro » ne peut pas être arbitré par
moi ; je publie les nombres.
