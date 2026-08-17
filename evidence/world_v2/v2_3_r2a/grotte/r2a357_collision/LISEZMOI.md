# Collision — les 16 ramenées à 4, la cause nommée, et une hypothèse du lead réfutée

Statut : mesures de l'agent A, reçues le 2026-08-17. Rien commité, rien poussé.

## 1. Le patch `MASSIF` est sécurisé — c'était le maillon fragile

Il ne vivait que dans un arbre de travail, en modifications non enregistrées.

```
sha256  5b9d473418fbdb1db7ea607f1d794dfbb410bd8a6cb03cd3bc891a07b7325e93
442 lignes · 20 952 octets
```

Et il porte **trois choses, pas une** : le lissage `MASSIF`, le désamorçage des
n-gones colinéaires, et le compteur exact `controle_penetration_exacte`. Un patch
qui transporte plus que son titre est un patch qu'il faut décrire avant
d'intégrer.

## 2. Les 16 — un seul défaut, pas une distribution

Toutes dans une boîte de **1,0 × 0,4 × 1,0 m**, appariées face par face contre un
atlas des 442 sommets (appariement **442/442**) : cavité stations 5-7 × enveloppe
stations 7-9, azimuts 9-11. **Un unique sommet de cavité sorti de l'enveloppe** —
station 6, azimut 10, indice 130 : celui qui porte l'enfoncement de 0,245 m.

## 3. La cause, nommée avant d'être corrigée

> `COL_MARGE_LAT` est soustrait de `hw` **seulement**. L'élargissement d'alcôve
> (`ALCOVE["ampl"] = 1,20 m`) est ajouté **après**, à pleine amplitude.

La cavité de collision respecte donc la marge de passage partout **sauf dans
l'alcôve**, où il manque exactement une marge. Épaisseur de roche à la station 6 :
**`+0,092 m` avant lissage, `−0,042 m` après**.

**Chronique, pas régression** : le lissage a remonté toutes les autres stations et
fait basculer celle-là. Et 0,09 m n'est pas une marge — deux polygones facettés se
croisent entre leurs sommets bien avant que leurs sommets se touchent.

## 4. Mon hypothèse de courbure est RÉFUTÉE, par la mesure

J'avais relayé que les 16 pourraient être le résidu du mécanisme « tube plus large
que son virage », le ratio restant `> 1` après réparation. **Faux.**

| | ratio | pénétrations |
|---|---:|---:|
| seule station encore ≥ 1 — `MASSIF` 3 | **1,086** | **0** |
| stations qui en portent — cavité | 0,13 / 0,08 / 0,04 | oui |
| stations qui en portent — massif | 0,93 / 0,45 / 0,24 | oui |

Les stations fautives ont les ratios **les plus bas** de leurs tables. La
corrélation est nulle, et même inversée.

Note annexe utile : l'estimateur de l'agent reproduit **mon** relevé
(`2,53 → 1,09`) et non celui du patch (`2,73 → 1,15`). C'est donc le texte du
patch qui se trompe de chiffre, pas les deux mesures indépendantes.

## 5. Le correctif — `16 → 4`, et pourquoi pas zéro

`retrait_alcove` porté à l'amplitude de l'alcôve ; `construire()` lui passe
`COL_MARGE_LAT` — **pas une constante nouvelle**. Les deux autres appelants
gardent `0,0` : ils servent le maillage visible.

| | avant | après |
|---|---:|---:|
| `cav×env` sur le GLB exporté | 16 | **4** |
| enfoncement | 0,245 m | 0,2438 m |
| `SM_WaterfallCave` | `f51919de…` | **identique au bit près** |
| `COL_WaterfallCave` | `d36e70aa…` | `391d8b21…` |

**Zéro n'est pas atteint**, et la raison est nommée : le levier est dilué d'un
facteur 6, parce que les anneaux sont des polygones ré-échantillonnés et que le
sommet fautif tombe **sur une arête**, pas sur un coin porteur de l'alcôve.

`_orient_exact`, la fonction morte introduite par `MASSIF`, est retirée — **dans
le patch de correction**, en laissant `massif_lissage.patch` bit-identique à ce
qui a été mesuré. C'est la bonne manière : on ne réécrit pas la pièce qui sert de
référence.

## 6. Le plafond sous 1,75 m — le filet a raison, et les deux instruments aussi

Rejoué **hors Godot** contre la collision : **11 échantillons sous contrat**, le
pire à **0,667 m** de hauteur libre, en repère modèle `(0,92 ; 0,13)`.

La tension que j'avais posée est levée : **les deux disent vrai, ils ne mesurent
pas la même chose.** Le gabarit mesure la **section aux stations** ; le filet
**marche en ligne droite**. La section au seuil est délibérément dissymétrique
(`CAVITE_ASYM[1] = (1,30 ; 0,81)`), demi-largeur de collision 1,053 m côté `+n`,
et la corde tombe à **0,13 m de la paroi**, là où la voûte est retombée sous le
mètre.

**Ce lot ne l'a ni causé ni aggravé** : la peau de cavité aux stations 0-2 est
identique au bit près — 60 sommets, écart `0,000000000 m`. Mais l'enveloppe
station 0 a bougé de **1,014 m** et la rive de **0,507 m** sous le lissage, la
tangente de la station 0 dépendant de la station 1. **Si régression il y a, c'est
là, pas dans la cavité.**

L'agent a **délibérément refusé de corriger** : élargir la joue droite rouvrirait
le défaut dont `CAVITE_ASYM` est dérivée — **385 percées, paroi à 0,11 m** pour
0,80 exigés. Arbitrer entre deux gates bloquants n'est pas son couloir, et il a eu
raison de me le rendre.

### L'hypothèse que je fais tester avant d'arbitrer

Le filet va de `cave_threshold` à `cave_interior` par un **segment droit**. Or
`cave_interior` dérive de `MODELE_SALLE`, qui a bougé de **3,994 m** entre le
tronc et le candidat, et la galerie a un coude.

> Le segment droit ne suivrait plus la galerie : il couperait le virage et
> raserait la paroi. Le plafond à 0,667 m serait alors mesuré **dans la roche du
> coude**, pas sur un trajet praticable.

Cohérent avec les chiffres — une corde à `0,92-1,06` pour une demi-largeur de
`1,053 m` aboutit exactement à 0,13 m de la paroi. Trois épreuves demandées :
relevé le long du **chemin canonique** ; relevé du segment droit avec **l'ancienne
ancre** ; et **érosion du couloir par le rayon de la capsule**, le centre d'une
capsule ne pouvant s'approcher d'une paroi à moins de son rayon.

## 7. `NON VÉRIFIÉ` — et trois sont lourds

- **Zéro n'est pas atteint** : 4 pénétrations subsistent, enfoncement 0,2438 m.
- **Ce GLB n'est pas livrable** : `export_architecture.sh waterfall_cave` est
  **ROUGE** — 29 plaques, la plus mince 0,114 m, au porche. Préexistant, mêmes
  coordonnées qu'au journal de 02:51. Le GLB mesuré vient de
  `export_cave_echafaudage.sh`.
- **71 des 240 sommets d'enveloppe sortent déjà du rocher visible**, jusqu'à
  **2,72 m**. Préexistant, **jamais mesuré jusqu'ici**. Parois invisibles à
  l'extérieur si le terrain ne les recouvre pas — terrain non mesuré.
- **Aucun test Godot lancé** : ni `validate_fast`, ni la capsule joueur, ni les
  7 stations en moteur. **Le franchissement aller-retour reste non vérifié en
  moteur.**
- `balayage_marge_alcove.py` **se contredit** avec `cave_epaisseur_col.py` : il a
  un défaut, ses chiffres n'ont servi à rien et **ne doivent pas être cités**.
