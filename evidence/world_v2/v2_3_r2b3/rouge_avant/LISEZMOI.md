# R2B.3 — le ROUGE d'avant, posé par le lead avant tout dispatch

`tools/mesure_boititude.py` est écrit par le lead, **pas par la voie qu'il
mesure**. Un portail dont le sujet est propriétaire n'est pas un portail.

## Le liant est `hexa`, et il ne bouge pas

| prédicat | définition | rôle |
|---|---|---|
| `hexa` | composante de 12 triangles ET 8 sommets soudés | **LIANT, plafond 25 %** |
| `equidistance` | + 8 coins à 2 % du centroïde | publié, non liant |
| `droite` | + 6 directions de normale **signée** | publié, non liant |

Le liant est le prédicat le plus **lâche** des trois, à dessein : c'est le seul
qu'on ne puisse pas faire tomber en déplaçant légèrement les coins d'un cube.
Faire passer `hexa` oblige à casser la topologie, pas seulement la métrique.

## Recoupement contre deux mesures antérieures indépendantes

| grandeur | R2B.2 | cet instrument | |
|---|---:|---:|---|
| `hexa` total du GLB | 79,6 % (audit) | **79,6 %** | identique |
| `equidistance` total | 42,1 % (lead) | **42,1 %** | identique |
| `Debris_A` / `_B` | 96,8 % | **96,8 %** | identique |

Trois implémentations écrites séparément qui tombent sur les mêmes chiffres.

## L'instrument a menti avant de servir, et son autotest l'a dit

`--autotest` est passé AVANT la première mesure et a échoué : `droite` rendait
faux sur un **cube unité**. Cause : la grappe de normales utilisait `abs(dot)`,
donc +X et −X tombaient dans la même grappe et un pavé rendait 3 directions au
lieu de 6. Corrigé en normale signée ; commentaire posé dans le code.

C'est le deuxième bug d'instrument attrapé par un cas témoin analytique dans
ce dossier — le premier étant l'union-find fusionnée de R2B.2, attrapée par
l'invraisemblance du résultat et non par le code. La leçon est appliquée :
**l'autotest précède la mesure, et il est obligatoire dans le journal.**

## État figé ici

- base `1491ee466c6b81e23d53655377376164e45da1b3`
- `SM_Farm_Ruins.glb` sha256 `9c7b94e1848dc1a1d33967343ee1c2a7868b38ab239d003de6cf4dcbc3216b3c`
- **`Debris_A` + `Debris_B` : 96,8 % de `hexa`, RC=1 contre le plafond de 25 %.**

Journal brut : `boititude_rouge_1491ee4.log`.
