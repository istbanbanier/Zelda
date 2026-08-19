# Vérifications personnelles du lead — R2B.2, AVANT intégration

Règle de la directive : « le lead reproduit personnellement tous les contrôles ».
Ce fichier consigne ce que j'ai vérifié **moi-même sur les octets**, pas ce que
les agents m'ont rapporté. Chaque ligne est une mesure, pas une lecture de
journal. Ce qui est faux ou infondé y reste écrit avec la correction.

Fait sur les arbres de travail des agents, avant tout cherry-pick.

## 1. Manifeste d'assets — l'agent A n'a PAS débordé de son périmètre

`git diff` montrait **trois** lignes touchées, dont deux golden masters gelés
(`SM_Pylon_Resonance`, `SM_WaterfallCave`). J'ai comparé **champ par champ**
après lecture CSV, et non ligne par ligne :

| ligne | champs modifiés |
|---|---|
| `SM_Pylon_Resonance` | **aucun** |
| `SM_WaterfallCave` | **aucun** |
| `SM_Farm_Ruins` | `version` 2→3 · `echelle_m` · `textures` · `budget_tris` 1336→1996 · `notes` |

Les deux premières lignes ne diffèrent que par le **remise en forme des
guillemets** d'un `csv.writer` : les champs sont identiques. J'allais accuser A
d'avoir touché des lignes gelées ; la mesure dit le contraire, et je le note ici
plutôt que de l'effacer.

Contrôles d'intégrité du fichier entier :

- 200 lignes avant, **200 après** ; aucun identifiant ajouté ni disparu ;
- **une seule ligne sémantiquement modifiée** : `SM_Farm_Ruins` ;
- aucune ligne ne change de nombre de colonnes ;
- les **8 lignes héritées non conformes** (`Male_Peasant`, `AL_RaiderStates`,
  `Superhero_Male_FullBody`, `SK_StormGuardian`, `AwningTent`, `ui_back`,
  `ui_error`, `ui_open`) sont **toujours non conformes** après passage du
  `csv.writer`. Elles n'ont pas été réparées en silence, ce qui est la règle :
  une dette héritée se consigne, elle ne se corrige pas au passage.

Conflit d'intégration attendu : `docs/assets/ASSET_MANIFEST.csv` est le **seul**
fichier commun aux voies A et B hors `evidence/`. Résolution par propriété
d'asset, comme en R2B.1 : ligne `SM_Farm_Ruins` de A, ligne
`SM_ThunderstruckTree` de B.

## 2. GLB de la ferme — lu sur les octets, en-tête glTF décodée à la main

`assets/architecture/farm/SM_Farm_Ruins.glb` chez A :

- matériaux : `MAT_Farm_Wood`, `MAT_Farm_BrokenWood`, `MAT_Farm_Tiles`,
  `MAT_Farm_Stone` — **exactement les clés** de `TEXTURES_PAR_MATERIAU` dans
  `abandoned_farm_place.gd`. Le journal d'échelle UV de A affiche des noms
  raccourcis (`Wood`, `Stone`) ; j'ai cru un instant à une clé qui ne
  correspondrait jamais et donc à un repli silencieux sur la couleur plate. Le
  GLB dit non : les noms complets sont bien là ;
- **25 primitives sur 25 portent `TEXCOORD_0`.** C'est le point 1 de la
  directive, vérifié sur le fichier et pas sur un journal ;
- **0 image embarquée**, cohérent avec le choix d'A de brancher les cartes du
  kit côté Godot (≈ 30 Mo de PNG contre 199 Ko de GLB).

Les neuf cartes référencées existent toutes sous
`assets/environment/village/` : `T_UnevenBrick`, `T_WoodTrim`, `T_RoundTiles`,
en `_BaseColor` / `_Normal` / `_Roughness`, de 1,2 à 4,4 Mo.

Le contrôle d'A lit `get_active_material(s).albedo_texture` — donc le matériau
**après override runtime** — et porte un plancher `SURFACES_MIN` avec le motif
« le contrôle ne regarde rien ». C'est la garde d'anti-vacuité posée au budget
du camp braise en R2B.1, reprise par A de lui-même. Le repli silencieux d'un
`load()` qui rendrait `null` serait donc attrapé.

## 3. Couronnement nord de la ferme — le contrôle passe, l'enveloppe est une règle

`profil_arase_nord.log` : σ 0,621 m, point bas 1,14 m, 28 % des colonnes sous
2,60 m — VERT. J'ai repris les 25 hauteurs :

- les **16 colonnes du plateau** ont un écart-type de **0,0000 m** : 4,00 m
  d'arase strictement plate ;
- sur les 9 colonnes descendantes, ajustement d'une droite : pente
  −0,919 m/m, **RMS des résidus 0,065 m pour 1,98 m de chute, soit 3,3 %.**

Le sommet de chaque gradin est posé **exactement sur la diagonale**. La cause
est lisible dans `_gradins` : le bruit est appliqué à `x1`, jamais à `z`.

> **σ mesure la dispersion, pas l'irrégularité.** Une diagonale parfaite a une
> grande dispersion. Le contrôle est vert et le défaut est là.

Même famille d'angle mort que celle que l'audit m'a trouvée deux fois sur mes
propres portails. Renvoyé à A : durcir le contrôle par un **résidu à
l'ajustement linéaire**, ROUGE d'abord sur l'état actuel, puis corriger la
cause. La docstring d'A dit elle-même « une diagonale lisse se lit comme une
coupe » : elle a raison, et c'est ce que l'enveloppe fait.

## 4. GLB de l'arbre — budget confirmé, et une absence à publier

`assets/architecture/flora/SM_ThunderstruckTree.glb` chez B :

- **3 574 triangles**, plafond 6 000 : le chiffre annoncé par B est exact, je
  l'ai recompté depuis les accesseurs d'indices ;
- 12 primitives, 8 nœuds, 4 matériaux dont `MAT_Tree_Heartwood`, le quatrième
  que j'avais accordé ;
- **0 primitive avec `TEXCOORD_0`.**

L'arbre n'a donc **aucune texture**, là où la ferme vient d'en recevoir. Ce
n'est pas hors contrat : le dépliage UV0 est une exigence **de la ferme**
(point 1 de la directive), jamais formulée pour l'arbre, dont les neuf points
portent sur la géométrie, la fracture, les racines et les bois. B a répondu en
géométrie et en paliers de valeur (C5 : luminances 0,133 · 0,218 · 0,431 ·
0,748, trois paliers séparés d'au moins 0,12).

**Je n'invente pas une exigence en cours de passe.** Mais je ne laisse pas non
plus la question sans chiffre : la **densité d'aplat de l'arbre sera MESURÉE et
PUBLIÉE** comme témoin sur ses vues, sans portail. Si elle est mauvaise, c'est
un résidu nommé porté à la revue visuelle — pas un échec technique, et surtout
pas un silence.

## 5. Ce que je n'ai pas encore vérifié

- le contrôle C (aplats) de la ferme **après** le geste : il manque, et c'est la
  mesure décisive de la voie A ;
- l'échelle UV réelle des pièces de la ferme : les chiffres de A en V vont de
  0,034 à 0,082 UV/m contre 0,474 sur le kit. Je n'ai pas compris comment la
  mesure est prise sur une pièce 3D et je ne bâtis rien dessus. **L'arbitre est
  la mesure d'aplats** : si la carte ne mord pas, la part attribuée ne bougera
  pas ;
- la lisibilité de l'arbre à 94 m après les corrections de champ proche
  (point 9 de la directive) : capture en cours chez B.

## 6. Fourche de l'arbre — le défaut que J'AVAIS trouvé en R2B.1 est corrigé, et je l'ai remesuré

En R2B.1 j'avais établi que la caméra de silhouette à l'azimut **000°** regardait
**dans le plan de la fourche** : `chemin_vivant(1) = (2,09 ; 0,33)` et
`chemin_mort(1) = (−1,50 ; −0,24)` donnaient ΔX 3,59 · ΔY 0,57, soit un plan à
**9,0°**. Les deux moitiés se superposaient très exactement sous la vue qui
devait prouver la lisibilité lointaine.

Constantes de B après correction, lues dans le générateur et recalculées par moi :

| | R2B.1 | R2B.2 |
|---|---:|---:|
| azimut du chemin vivant | — | **+15,0°** |
| azimut du chemin mort | — | **−104,6°** |
| divergence des deux azimuts | ≈ coplanaires | **119,6°** |
| plan de la fourche | **9,0°** | **38,9°** |
| écart horizontal des deux cimes | — | **4,371 m** |

Séparation **apparente** des deux cimes selon l'azimut de caméra, à 94 m :

| azimut | écart latéral | angle apparent |
|---:|---:|---:|
| **000°** (caméra de silhouette) | **2,744 m** | **100,3′ d'arc** |
| 030° / 210° (le pire) | 0,675 m | 24,7′ |
| 090° | 3,403 m | 124,4′ |
| 120° / 300° (le meilleur) | 4,319 m | 157,8′ |

La vue qui échouait est passée de **superposition** à **100 minutes d'arc**
d'écart, soit plus d'un degré et demi. Le pire azimut de tout le tour reste à
24,7′, ce qui est encore résolu — et ce n'est aucune des caméras de référence.

Deuxième rupture de cime, exigée au point 2 de la directive : cime morte à
`z = 5,90` et membre arraché à `z = 7,55`, **1,65 m d'écart** — deux ruptures
franchement séparées, à des hauteurs différentes.

Hauteur totale 10,80 m, dans les bornes [10 ; 12] que le générateur refuse de
franchir.

## 7. Cicatrice de l'arbre — mesurée sur l'instrument QUI AVAIT DIAGNOSTIQUÉ le défaut

Le « ruban peint » de R2B.1 avait été établi ainsi : CV **brut** de la largeur
0,402 — rassurant — mais CV **lissé sur 3 stations**, l'échelle que l'œil
intègre, à **0,155**, avec une autocorrélation de rang 1 de −0,483. C'est le
lissage qui révélait la largeur constante sous un bruit station-à-station.

J'ai vérifié que le contrôle C4a de B lisse **de la même façon** — moyenne
glissante `(a + b + c) / 3` — et que son en-tête cite explicitement le 0,402
d'origine comme motif du contrôle. Les deux chiffres sont donc comparables :

| | R2B.1 | R2B.2 |
|---|---:|---:|
| CV de la largeur **lissée sur 3 stations** | **0,155** | **0,392** |

Le rapport largeur max/min lissée est de 3,98, la profondeur radiale du bois nu
va de 0,084 à 0,385 m sur 17 stations (rapport 4,58), et deux plans de rupture
sont détectés avec 7 échardes le long du parcours. La cicatrice n'est plus une
bande de largeur constante.

## 8. Budget de l'arbre — recompté depuis les accesseurs d'indices

**3 574 triangles** pour un plafond de 6 000. Le chiffre annoncé par B est
exact ; je ne l'ai pas lu dans son journal, je l'ai recalculé en sommant
`count / 3` sur les accesseurs d'indices des 12 primitives du GLB.

Racines : hauteur maximale hors collider **0,280 m**, **0 sommet** au-dessus de
0,32. À noter — cela corrige au passage le défaut de traversabilité préexistant
consigné avant la passe (16 sommets de racine à 0,382 m, au-dessus du
`step_height` de 0,34). Ce n'était pas demandé ; c'est acquis.

## 9. Le seul seuil déplacé de la passe côté agent — vérifié, et il est justifié

L'agent B a déplacé un seuil de son propre plan (`40856c1`), ce qui appelle la
règle : « ne pas modifier ou abaisser un seuil pour faire passer une
géométrie ». J'ai vérifié le raisonnement plutôt que le verdict.

Le plan de B proposait « flanc des racines ≥ 28 % » — la part de surface dont
la normale est à plus de 70° de la verticale. B a calculé après coup que pour
une section elliptique cette part vaut ≈ 22 % pour un **cercle parfait**. J'ai
refait le seul calcul vérifiable à la main : sur un cercle, les normales à plus
de 70° de la verticale occupent quatre arcs de 20°, soit **4 × 20 / 360 =
22,2 %**. B a raison au dixième près.

**Un seuil de 28 % exigeait donc une section plus haute que large : une
nageoire, pas un contrefort.** C'est le même défaut que celui de mon propre
critère `total ≤ 12 %` retiré plus haut — un seuil qu'on ne peut atteindre
qu'en fabriquant un autre défaut n'est pas une exigence.

Ce qui rend le geste acceptable n'est pas l'abaissement, c'est ce qui
l'accompagne : B **ajoute** la mesure qui décrit vraiment « une plaque », la
part de surface à moins de 45° de la verticale, plafonnée à 60 %.

| mesure | R2B.1 | seuil | R2B.2 |
|---|---:|---:|---:|
| flanc (normale > 70° de la verticale) | 10,0 % | ≥ 15 % | **33,0 %** |
| surface presque horizontale (< 45°) | 68,5 % | ≤ 60 % | **31,8 %** |

Le second chiffre est le décisif : 31,8 % est **meilleur qu'un cylindre à
section circulaire** (50 %). Ce n'est pas un portail desserré, c'est une
géométrie qui a changé. Et le seuil déplacé n'appartient à aucun des portails
d'aplats que la directive gèle : il naît dans le plan de B et meurt dans son
plan, remplacé par plus exigeant.
