# Le maillage est FERMÉ — et une affirmation versionnée était fausse

**Ce dossier corrige un document déjà poussé.** Le §30.1 du handoff et
`../r2a352_toit_mince/LISEZMOI.md` écrivaient que deux inondations 3D
s'échappaient « par le **dessous ouvert du modèle**, qui est ouvert par
conception — un rocher planté dans le terrain ».

**C'est faux.** Signalé par l'agent C de la passe R2a-3.5.3, **reproduit
indépendamment par l'intégrateur** avec son propre lecteur GLB avant d'être
accepté.

## La mesure

`tools/cave_topology_check.py`, Python pur, aucune dépendance.

| géométrie | nœud | bord libre | non-manifold | `χ = V−E+F` | genre |
|---|---|---:|---:|---:|---:|
| candidat `cc3596c5` | `SM_WaterfallCave` | **0** | **0** | 0 | **1** |
| `BASE352` `8bc8b9f9` | `SM_WaterfallCave` | **0** | **4** | 4 | non défini |
| R2a-3.4 livrée `8bf1a1b3` | `SM_WaterfallCave` | **0** | **0** | −2 | **2** |
| les trois | `COL_WaterfallCave` | 0 | 0 | 2 | 0 |

**Zéro bord libre sur les trois géométries.**

### Le piège qu'il fallait éviter pour que ce chiffre veuille dire quelque chose

Un GLB range la géométrie **par matériau** : six primitives ici, et les sommets
sont **dupliqués à chaque couture**. Compter les arêtes primitive par primitive
rendrait des milliers de « bords libres » qui n'en sont pas. Il faut **souder par
position** avant de compter.

Deux agents de cette passe ont trouvé cette contrainte **indépendamment**, l'un
pour son sabotage, l'autre pour son oracle. C'est le meilleur signe qu'elle est
réelle.

## Le banc à réponse connue — sans lui, cet outil ne pourrait pas échouer

Un outil qui annonce « 0 bord libre » et n'a jamais été confronté à un maillage
ouvert ne mesure rien de vérifiable. Trois formes dont la topologie est un **fait
mathématique**, pas une mesure :

```
tetraedre ferme              V=4   E=6   F=4    libres=0   khi=2    OK
tetraedre ampute d'1 face    V=4   E=6   F=3    libres=3   khi=1    OK
tore 8x8                     V=64  E=192 F=128  libres=0   khi=0    OK
```

**Un défaut trouvé et corrigé dans l'outil pendant sa propre écriture** : le banc
éprouvait `_topologie()` pendant que la lecture GLB recalculait tout en ligne. Le
vert du banc n'aurait donc rien dit du chemin réellement emprunté — exactement ce
que la docstring de `_topologie()` dénonce, commis dans le même fichier.
Corrigé ; les chiffres du GLB sont **identiques avant et après** le refactor,
vérifié par `diff`.

## Ce que la correction change, et ce qu'elle ne change pas

**Ne change pas** : le fait observé — les deux inondations atteignent le bord de
la grille — reste vrai. Et le verdict d'épaisseur n'en dépendait pas :
`EPAISSEUR_MIN_M` porte sur la roche, pas sur l'accès.

**Change** : la mauvaise cause servait d'excuse à l'indétermination. Le maillage
étant fermé, la joignabilité **redevient décidable**, et le masque « limite
inférieure » que la directive envisageait pour l'oracle est **inutile** — le plus
large des deux angles morts disparaît avant d'être écrit.

## LA QUESTION OUVERTE — un genre non nul reste à expliquer

Une grotte à une seule bouche est topologiquement une **bosselure** : genre 0.
Le candidat est de genre **1**, la géométrie **livrée** de genre **2**. Chacune
porte donc une ou deux **anses** — une boucle de matière, ou un trou traversant.

Deux hypothèses, et elles ne se valent pas :

- **arche naturelle** — visière, orteil, pied formant un pont ; légitime et
  cohérent avec la composition voulue ;
- **trou traversant entre la cavité et le dehors** — c'est-à-dire une **percée**,
  que toutes les sondes annoncent à **0**.

Confié à l'agent C, **à réfuter plutôt qu'à confirmer**. Le genre est un
invariant **global** : il établit qu'une anse existe, jamais où. Il faut donc
l'apparier à une inondation pour localiser.

**Statut : NON VÉRIFIÉ.**

## Un fait de gate, au passage

`BASE352` porte **4 arêtes non-manifold** quand le candidat en porte **0**.
Ajouter la collerette les a donc **réparées** — plausible si la visière recouvre
la zone fautive, **non vérifié**. « 0 non-manifold » est un item du gate : le
candidat le tient, la base ne le tenait pas.

## Reproduction

```sh
python3 tools/cave_topology_check.py --banc     # banc a reponse connue
python3 tools/cave_topology_check.py            # les trois geometries
```

Journal : `fermeture_et_genre.log`, avec les empreintes lues **avant** mesure.
