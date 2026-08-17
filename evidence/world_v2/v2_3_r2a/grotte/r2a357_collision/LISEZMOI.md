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

---

## 8. Le `7/8` est un défaut de SONDE, pas de roche — trois mesures, hypothèse confirmée

Les trois épreuves demandées ont été faites, et elles concordent.

| épreuve | résultat |
|---|---|
| **chemin canonique** (polyligne des stations) | **zéro échantillon sous contrat** ; hauteur libre **2,28 à 2,38 m** pour 1,75 exigés, dégagement latéral 0,53 à 0,96 m |
| **corde vers l'ancre du TRONC** `(1,05 ; 0,22 ; −6,25)` | **13 fautifs, pire 0,365 m** — contre 11 et 0,667 m avec l'ancre actuelle. **L'ancienne est PIRE** |
| **érosion par le rayon de capsule** | les 11 fautifs ont **0,013 à 0,045 m** de dégagement là où 0,450 est requis. Le pire point géométrique en a **0,039** |

> **Aucun point fautif n'est occupable, sur aucun des trois trajets.**

Deux conséquences.

**Il n'y a pas de plafond bas dans la galerie.** Le corps donne 2,3 m de hauteur
libre ; le filet échantillonne des points **situés dans la paroi**, d'un facteur
10 à 30 sous ce qu'une capsule exige.

**Et ce n'est pas le déplacement de l'ancre.** Mon hypothèse portait sur les
3,994 m de `MODELE_SALLE` ; la mesure la corrige : la corde rasait déjà la paroi
**avant**, et plus fort. Replacer l'ancre n'y changerait rien. Faire suivre le
chemin canonique à la sonde, oui.

### L'aveu qui rend le reste croyable

Le premier critère d'occupabilité de l'agent était **faux**, et il l'a vu avant de
le rendre. Il mesurait la distance **3D** de l'axe de capsule à toute la
géométrie — or le bas de cet axe est à `sol + R`, donc **le sol est toujours à
exactement `R`**. Le critère plafonnait à 0,450 partout et déclarait la galerie
entière non occupable, axe compris.

> Il rendait le même verdict en tout point : **il ne mesurait rien, et il aurait
> « confirmé » mon hypothèse pour une raison fausse.**

Corrigé en distance **horizontale** dans la bande de hauteur du corps — la capsule
repose sur le sol, le plancher n'est pas un obstacle. Le critère discrimine
alors : **0,96 m sur l'axe contre 0,04 m sur la corde**. C'est cette version qui
produit les chiffres ci-dessus. Même famille qu'ISS-018, attrapée à temps.

## 9. La question qui remplace celle-là, et elle est plus grave

Sur le chemin canonique, les cinq premiers échantillons — porche et seuil — ont
**0,061 à 0,431 m** de dégagement latéral pour 0,450 requis, avec une hauteur
libre pourtant bonne (2,1 à 2,4 m). Au seuil : **0,431 contre 0,450**.

> **L'écart est inférieur à l'erreur d'échantillonnage de l'instrument**
> (barycentrique `subdiv=6`, erreur bornée ~0,08 m).

Un instrument dont l'erreur dépasse la grandeur mesurée **ne peut pas conclure** —
c'est ce que cette série a mis trois passes à apprendre sur l'épaisseur. L'agent a
donc eu raison de laisser `NON VÉRIFIÉ`.

Mais ce n'est plus une question de plafond. C'est **« le joueur peut-il entrer
dans la grotte ? »**, et c'est désormais la dernière inconnue bloquante.

Mesure demandée avec un instrument **exact** — distance point-triangle, pas
d'échantillonnage — contre `COL_` et `SM_`, pour les **deux** rayons en litige
(`0,45` du commentaire générateur, `0,35` de `Player.tscn`).

**Et une contradiction à lever** : le générateur imprime
`gabarit : bande utile par station : 0:2.65, 1:2.65`. Une bande utile de 2,65 m
et un dégagement de 0,431 m au même endroit ne peuvent pas être vrais ensemble.
C'est la troisième fois de cette passe que deux instruments se contredisent ; les
deux fois précédentes, la réponse fut « ils ne mesurent pas la même chose ».

Piste à confirmer ou tuer : `CAVITE_ASYM[1] = (1,30 ; 0,81)` décentre la section,
mais même 0,81 m reste très au-dessus de 0,450. Si le dégagement réel tombe à
0,431, **quelque chose rétrécit la bouche au-delà de la section analytique** —
roches posées, calotte, joue droite.

---

## 10. Le seuil est VERT — la question « le joueur peut-il entrer » est close

Instrument **exact**, distance point-triangle, erreur ~`1e-9 m` :

| | verdict |
|---|---|
| capsule `r = 0,45` (commentaire générateur) | **passe partout** |
| capsule `r = 0,35` (`Player.tscn`) | **passe partout** |
| sur `COL_` **et** sur `SM_` | les deux |
| marge la plus faible | **`+0,1213 m`** à la salle — **48× l'erreur de l'instrument** |

**Aucune paroi invisible dans la galerie** : `COL_` est partout `0,10 à 0,30 m` plus
étroit que `SM_`, donc le collider est **dans le vide visible** — c'est la marge de
passage, et elle joue dans le bon sens.

Deux résultats annexes qui ferment des questions ouvertes :

- **la piste `CAVITE_ASYM[1]` est tuée** : rien ne borde le seuil qui le resserre ;
- **la contradiction avec `bande utile 2,65 m` est levée**, et pour la troisième
  fois de cette passe la réponse est « ils ne mesurent pas la même chose » :
  `_section_de_station()` passe `0.0, 0.0`, donc elle mesure la cavité **visible**,
  pas le collider.

> Trois critères d'occupabilité ont été essayés, **deux étaient faux, et pour le
> même motif les deux fois : ils mesuraient le plancher.** C'est désormais écrit
> au-dessus de la fonction, pour que la passe suivante ne le repaie pas.

## 11. La vraie dilution, trouvée — et elle ne suffit pas

Ma proposition était déjà en place : le retrait porte l'amplitude de l'alcôve
**dans `sommet(tf)`**, au niveau des coins, avant `polygonal()`. L'arithmétique le
confirme — à la station 6 un coin tombe à 5,6° de l'azimut de l'alcôve, où la
fenêtre vaut 0,971. Le retrait s'appliquait **déjà à plein**.

La vraie cause est ailleurs, et elle est nette :

> `retrait_lat` est soustrait de `hw` **avant** la multiplication par
> `CAVITE_ASYM`. Au flanc de l'alcôve, `gauche = 1,69` : la paroi recule donc
> réellement de **0,676 m** pendant qu'on ne retranche que `0,40` de
> l'élargissement. **L'alcôve reculait deux fois moins que la paroi qu'elle
> prolonge.**

Corrigé en mettant le retrait à la même échelle, **sans constante nouvelle** —
`COL_MARGE_LAT` et `CAVITE_ASYM` existent toutes deux.

**Et ça ne suffit pas** : sur le GLB exporté, **4 pénétrations, repli
`0,243436 m`** — pratiquement inchangé. `SM_` reste bit-identique.

## 12. Le zéro existe, il est vérifié, et son prix est un arbitrage

| `COL_MARGE_LAT` | alcôve en collision | pénétrations | repli |
|---|---|---:|---:|
| **0,40** (gelé) | 0,524 m | **4** | 0,2434 m |
| 0,50 | 0,355 m | **0** | **0,000000 m** |

Mesuré par `cave_exact_intersect.py` sur le GLB **réellement exporté**, pas en
laboratoire. L'interrupteur est d'une ligne. L'agent ne l'a **pas** actionné.

### Arbitrage du lead : NON. On garde `0,40`.

Trois raisons, et la troisième suffirait seule.

1. **`0,50` ne se dérive d'aucune constante existante.** L'adopter, c'est ajouter
   une valeur réglée — exactement ce que `tools/CLAUDE.md` nomme un plancher
   calibré sur le sujet qu'il juge.
2. **Le prix est visible par le joueur** : `0,845 m` de paroi invisible **dans la
   niche de récompense** — `0,355 m` de collision pour `1,20 m` visible, soit
   trois à huit fois la marge normale, et à l'endroit précis où le joueur doit
   aller. On échangerait un défaut mesurable mais invisible contre un défaut que
   le joueur heurte.
3. **`COL_MARGE_LAT` est une marge de passage, gelée par la directive.** La
   déplacer pour faire passer un gate est le geste que cette série s'interdit.

Le zéro reste **publié, mesuré et atteignable** : si le propriétaire juge que
`0,845 m` de paroi invisible dans la niche est acceptable, l'interrupteur est
d'une ligne. Ce n'est pas à la session de le décider.

## 13. Un piège de mesure qui a failli passer

La bissection avait d'abord été faite au **compteur interne du générateur**. Sur
la même géométrie il rend **`0,2144 m`** là où `cave_exact_intersect.py` sur le
GLB rend **`0,2434 m`** : il **sous-estime le repli de 12 %**.

Le compteur interne est documenté comme minorant du **compte**. Il l'est aussi du
**repli**, et **ce n'était écrit nulle part**. Refait sur le GLB avant de
conclure.
