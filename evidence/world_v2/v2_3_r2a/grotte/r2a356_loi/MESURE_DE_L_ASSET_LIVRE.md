# Ce que porte réellement l'asset livré — mesure directe du GLB

Statut : **VÉRIFIÉ** par moi, le 2026-08-17, sur
`assets/environment/caves/SM_WaterfallCave.glb` du tronc, arbre propre.
Lecture GLB pure Python, soudure par matériau, aucune dépendance Blender.

Aucune des trois passes précédentes n'avait mesuré **l'asset livré** sur ces
grandeurs : toutes mesuraient des candidats. C'est la ligne de base qui manquait.

## 1. Échelle du maillage

| nœud | triangles | arête médiane | arête p75 | aire totale |
|---|---:|---:|---:|---:|
| `SM_WaterfallCave` (rendu) | 19 954 | **0,3325 m** | 0,5597 m | 1 267,13 m² |
| `COL_WaterfallCave` (collision) | 880 | **1,3384 m** | 1,7054 m | 518,68 m² |

### Conséquence : la rampe progressive n'est pas applicable telle quelle

L'agent C a mesuré, sur la peau intérieure de son candidat, 1 008 faces pour
95,19 m² — **0,47 m de côté** — et en a tiré que `d(p)` saute de 0,000 à 0,612 m
**sans valeur intermédiaire**. Ma mesure sur l'asset livré est cohérente au
centimètre près : arête médiane 0,3325 m, p75 0,5597 m.

Donc, indépendamment de `h` :

> **La finesse de la rampe `0 → 0,80 m` est bornée par le maillage, pas par la
> résolution de l'instrument.** Sur cette peau, une loi progressive sur
> `[0 ; 0,80]` n'a que deux ou trois valeurs possibles. Elle n'est pas
> progressive, elle est quasi binaire.

C'est un résultat sur **l'instrument**, pas sur la roche, et il tient quelle que
soit la loi retenue — littérale ou `LOI-R`. Il faut soit raffiner la peau près de
la bouche, soit calculer `d(p)` autrement que par saut de face.

### Conséquence : la collision est quatre fois plus grossière que le rendu

> **Correction du 2026-08-17.** Cette section disait « huit fois » : c'est faux.
> `1,3384 / 0,3325 = 4,03`. L'agent A a reproduit mes deux mesures au chiffre
> près par un autre chemin et relevé l'erreur ; il donne aussi 4,11 sur les trois
> autres géométries, et **22,7** pour le rapport du *nombre de faces* — le
> facteur 8 ne correspond à aucun des deux. La conclusion qualitative ne bouge
> pas, le nombre si.

Arête médiane 1,3384 m contre 0,3325 m. Tout enfoncement mesuré sur
`COL_WaterfallCave` porte donc une incertitude d'un autre ordre que sur le rendu,
et les deux comptes d'auto-intersection ne sont **pas comparables** sans le dire.
C'est exactement pourquoi j'ai demandé à l'agent B de ventiler ses décomptes par
maillage plutôt que de publier un total.

## 2. Triangles dégénérés — le chiffre qui arbitre TICKET-B5

| | `SM_` | `COL_` |
|---|---:|---:|
| aire **exactement** nulle | **0** | **0** |
| aire ≤ `1e-9` m² | **4** | 0 |
| arête ≤ `1e-6` m | 0 | 0 |
| plus petite aire | `1,313e-10` m² | `1,038e-02` m² |
| plus petite arête | `2,088e-05` m | `2,911e-02` m |

Deux lectures, et il faut les tenir ensemble.

1. **« Zéro signifie zéro » est satisfait sur le livré** : aucune face d'aire
   exactement nulle, sur aucun des deux maillages. Le défaut visé par R2a-3.5.5
   §5 appartient au **candidat**, pas à ce qui est en ligne.
2. **Mais quatre lamelles vivent à `1e-10` m²**, soit 0,02 mm d'arête. Un portail
   post-export qui rejetterait les faces sous `1e-9` m² **rougirait l'asset
   livré**.

C'est le TICKET-B5 de l'agent B, chiffré : *« un contrôle exact existe, personne
ne l'a branché, le brancher rendrait rouge du déjà-validé »*. Le nombre est
**4**, et le seuil qui décide se situe entre `1e-10` et `1e-2`. Sans ce chiffre,
l'arbitrage se prenait à l'aveugle ; avec lui, il se prend.

Je ne branche pas ce portail dans cette passe, et je ne recommande pas de le
faire ici : il toucherait aussi les trois golden masters gelés, ce qui est un
choix de barre de qualité et appartient au propriétaire, pas à la session
(`PROMPT4_METHOD` §13).

## 3. Ce que cette mesure n'établit pas

- Rien sur l'épaisseur : ce fichier ne mesure que la géométrie du maillage.
- Rien sur les auto-intersections : elles demandent des prédicats exacts, pas des
  aires.
- Le tri par « peau intérieure » n'est pas fait ici — mes chiffres portent sur
  **tout** le nœud, bouche et extérieur compris. C'est volontaire : ils servent
  d'ordre de grandeur indépendant du masque, donc non contaminés par la
  définition du masque qui est encore en litige.

## Reproduction

```bash
python3 - <<'PY'
import sys, math
sys.path.insert(0, "tools")
from cave_topology_check import lire_glb, accesseur
js, b = lire_glb("assets/environment/caves/SM_WaterfallCave.glb")
# ... parcours des primitives, arêtes et aires par produit vectoriel
PY
```

`tools/cave_topology_check.py` fournit `lire_glb` et `accesseur` ; ils venaient
d'être réparés dans cette même série — l'outil portait trois chemins absolus vers
un worktree disparu et ignorait `sys.argv`, pendant que son banc passait au vert.
