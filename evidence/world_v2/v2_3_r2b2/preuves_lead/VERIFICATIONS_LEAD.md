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

## 10. Caméras imposées — vérifiées champ par champ, aucun cadrage remplacé

La directive §7 exige de réutiliser **impérativement** les caméras R2B.1 et
interdit de remplacer un cadrage défavorable. Vérifié, et pas par sondage :

- `evidence/world_v2/v2_3_r2b1/shots_r2b1.json`, sha256 `3eeb8d4aa68bf462…` —
  **inchangé** depuis R2B.1 ;
- manifeste de l'agent B (`.../arbre/apres/manifest.json`) : commit `c6ee953b34`,
  `repo_dirty: false`, **15 vues comparées, 15 identiques, 0 divergente, 0 hors
  référence**, sur `from`, `look` et `fov` à 1e-9 près.

## 11. Ordre d'intégration — une dépendance que la vérification a révélée

Le manifeste de B porte `sha256: None` pour ses deux rôles de provenance. Ce
n'est pas une négligence de B : l'ajout du sha256 au manifeste de capture vit
dans `tools/godot/capture_poi_batch.gd`, **modifié par l'agent A**, et l'arbre de
travail de B ne l'a pas.

Conséquence directe sur l'ordre du cherry-pick, et elle n'est pas cosmétique :
le §7 exige que les captures finales portent le **hash des GLB capturés**. Cette
exigence n'est satisfaite que par le changement d'A. Donc **la voie A entre
avant mes captures finales**, sans quoi mes propres preuves naîtraient sans les
empreintes que la directive réclame.

Ordre retenu :

1. voie A (ferme) — apporte `capture_poi_batch.gd` (sha256 au manifeste) et le
   correctif du verrou `validate_fast.sh` en arbre de travail ;
2. voie B (arbre) ;
3. résolution du seul conflit attendu, `docs/assets/ASSET_MANIFEST.csv`, par
   **propriété d'asset** : ligne `SM_Farm_Ruins` de A, ligne
   `SM_ThunderstruckTree` de B, les 198 autres lignes inchangées ;
4. import Godot headless — **piège mesuré en R2B** : après un cherry-pick qui
   apporte un `.glb`, la suite rougit en « aucun maillage visuel » tant que
   `--headless --path . --import` n'a pas été rejoué ;
5. mes captures finales, au SHA intégré, arbre propre ;
6. l'audit rejoue au SHA.

### Le correctif de verrou d'A, vérifié plutôt que cru

A modifie `tools/validate_fast.sh`, infrastructure partagée : le verrou passait
par `$PROJECT_DIR/.git/validate_fast.lock`, or **dans un arbre de travail git
`.git` est un FICHIER**, d'où `Not a directory` et un `BLOQUÉ` (code 3) alors
qu'aucune suite ne tournait. A bascule sur `git rev-parse --git-common-dir`.

Vérifié par moi sur les trois arbres :

| arbre | `--git-common-dir` rend |
|---|---|
| `/home/user/Zelda` (principal) | `.git` — **relatif**, donc préfixé par `PROJECT_DIR` : chemin **identique à avant** |
| `/home/user/zelda-r2b2/a_ferme` | `/home/user/Zelda/.git` — absolu, utilisé tel quel |
| `/home/user/zelda-r2b2/b_arbre` | `/home/user/Zelda/.git` — idem |

Le comportement dans l'arbre principal est donc **inchangé au caractère près**,
et `--git-common-dir` (et non `--git-dir`) est le bon choix : c'est le `.git`
**partagé**, or deux arbres de travail partagent `user://saves` — leurs suites
DOIVENT se sérialiser.

## 12. Réserve de l'agent B que je lève moi-même à l'intégration

B signale honnêtement que son A/B à 94 m compare **deux commits différents**, le
verrou Godot partagé ayant fait expirer ses deux tentatives d'A/B à commit
identique. Sa mitigation est que la ROI exclut la ferme.

Ce n'est pas suffisant et B le dit. Je lève la réserve après intégration, où je
tiens le verrou : deux commits qui ne diffèrent **que** par
`SM_ThunderstruckTree.glb` — l'intégré, et un commit jetable où seul l'ancien
GLB est restauré. Deux arbres propres, un seul fichier d'écart, la mesure
devient attribuable.

## 13. J'ai rejoué moi-même la mesure d'aplats sur les deux états antérieurs

`tools/mesure_aplats.py` ne dépend que de Pillow — `numpy` est cassé dans ce
conteneur, l'outil ne s'en sert pas. Je n'ai donc pas eu besoin du verrou Godot
pour reproduire les chiffres au lieu de les lire.

### Ferme — R2B puis R2B.1

| vue | R2B `max` | R2B `total` | R2B.1 `max` | R2B.1 `total` |
|---|---:|---:|---:|---:|
| `ferme_approche` | 2,39 | 3,92 | **0,80** | **1,43** |
| `ferme_composition` | 2,13 | 3,03 | **0,84** | **1,52** |
| `ferme_arriere` | 1,66 | 6,89 | **1,25** | **4,05** |
| `ferme_facade` | 1,95 | 4,83 | 1,29 | **6,49** |
| `ferme_laterale` | 6,66 | 11,91 | **3,15** | 11,99 |
| `ferme_seuil` | 2,92 | 23,74 | **7,32** | **35,34** |

Mes chiffres reproduisent ceux de l'agent A au centième près : son
`controle_aplats_ferme.py` enveloppe fidèlement `mesure_aplats.py`.

Ce que la table dit, et que ni A ni moi n'avions formulé ainsi : **R2B.1 a
amélioré les vues lointaines et dégradé les vues proches.** Approche et
composition tombent de plus de moitié ; seuil et façade montent. La maçonnerie
ajoutée aide la silhouette de loin et fabrique de la surface plate de près.
C'est exactement le verdict visuel rendu sur les images, retrouvé dans les
nombres.

### Une seconde grandeur invariante d'échelle dormait déjà dans l'outil de R2B.1

La colonne `plats_pct_beige` — « quelle part du bâti beige est décrite par un
seul plan ? » — est **indépendante du cadrage** par construction, et son auteur
l'avait documentée comme telle sans qu'elle serve de portail :

| vue | R2B | R2B.1 |
|---|---:|---:|
| `ferme_seuil` | 55,0 % | **65,7 %** |
| `ferme_laterale` | 57,4 % | 56,2 % |
| `ferme_approche` | 46,6 % | 33,7 % |

Elle raconte la même histoire que la densité d'aplat de l'audit (69,3 % contre
34,4 % pour le kit), par un chemin **entièrement différent** : celui-ci part de
la surface bâtie, celui-là de la couverture d'écran. Deux instruments
indépendants qui désignent le même défaut valent mieux qu'un seul.

Elle sera **publiée à côté** de la densité au verdict. Elle ne devient pas un
troisième liant : je n'en connais pas la bande d'incertitude, et l'audit vient
de me rappeler ce que vaut un rapport dont on ignore le bruit.

### Arbre — le témoin décidé en décision 9, état de départ

| vue | R2B `max`/`total` | R2B.1 `max`/`total` |
|---|---:|---:|
| `arbre_approche` | 2,17 / 2,40 | 2,17 / 2,40 |
| `arbre_fracture` | 0,78 / 3,17 | 0,65 / **1,69** |
| `arbre_pied` | 0,51 / 1,22 | 0,99 / 1,19 |
| `arbre_troisquarts_d` | 0,71 / 1,35 | 0,59 / 1,74 |
| `arbre_troisquarts_g` | 1,36 / 17,49 | 1,33 / **16,20** |
| `arbre_lointain_94` | 0,37 / 0,88 | 0,37 / 0,88 |

**Réserve, et elle est lourde : ces chiffres ne sont PAS attribués à l'arbre.**
`mesure_aplats.py` mesure l'image entière ; sur une vue d'arbre, le terrain, la
ferme et le ciel entrent dans le total. Les 16,20 % de `arbre_troisquarts_g` se
répartissent sur **26 composantes** — une dispersion qui ressemble à du sol, pas
à une plaque. La mesure attribuée est celle de l'audit, et elle seule conclura.

Sous cette réserve, un fait tient déjà : **le `max` de l'arbre ne dépasse jamais
2,17 %**, contre 7,32 % pour la ferme. L'arbre n'a pas le défaut d'aplat de la
ferme, même sans aucune texture. Cela ne dispense pas de le mesurer proprement ;
cela dit seulement où porter l'attention.

## 14. Portée exacte de tout ce qui précède — et l'engagement qui va avec

L'audit indépendant a posé la limite, et elle est juste :

> une mesure prise sur un arbre de travail atteste **cet arbre**, pas le
> livrable.

C'est la règle établie en R2B.1, où `9aa8978806` et `b75e3e5215` n'étaient
ancêtres ni l'un ni l'autre de `e2bf32ab59`. Elle s'applique **à moi** ici :
les §2, §3, §4, §6, §7, §8 et §9 ci-dessus portent sur les arbres de travail
d'A et de B, pas sur ce que je livrerai.

**Engagement, sans exception :** chacune de ces mesures est **rejouée sur le SHA
intégré** avant tout verdict. Un écart entre les deux ne serait pas un détail —
ce serait la preuve que l'intégration a changé quelque chose que personne n'a
vu, et il serait rapporté comme tel.

Les §1, §10, §11 et §13 échappent à cette réserve : le manifeste et les caméras
sont lus dans git et non dans un rendu, et la mesure d'aplats du §13 porte sur
des captures **déjà committées** de R2B et R2B.1.

### Un chiffre de plus, apporté par l'audit en recoupant les miens

L'audit a refait mon arithmétique de fourche — divergence `|+15,0 − (−104,6)|
= 119,6°`, et `atan(2,744 / 94) = 100,3′` — puis a tiré le nombre que ni le
meilleur ni le pire azimut ne montrent seuls :

> **rapport 4,1× entre le meilleur azimut (4,319 m) et le pire (0,675 m).**

Il dit que la lisibilité de la fourche **dépend fortement de l'azimut**. La
caméra de référence à 000° est à 2,744 m, dans la moitié haute de cette plage,
mais un observateur libre à 30° verra quatre fois moins d'écart. Publié tel
quel : c'est une propriété de l'objet, pas un défaut, et la revue visuelle doit
l'avoir sous les yeux plutôt que de la découvrir en tournant autour.

## 15. Inspection visuelle en taille réelle des vues d'arbre — un point de la directive N'EST PAS tenu

Le §7 impose l'inspection individuelle en taille réelle. Faite sur les captures
de l'agent B, puis **remesurée sur les octets du GLB** pour ne pas m'en tenir à
une impression.

### Ce que l'agent B avait lui-même signalé, et que je confirme

- `arbre_fracture` : un **vide noir** subsiste sous la crête, en haut du cadre,
  là où la lèvre surplombe l'écorce. Il ne se lit pas comme une ombre mais
  comme un trou de modélisation.
- `arbre_pied` : le bois tombé de premier plan est un madrier à bords
  parallèles sous cet angle rasant.

Aucun des dix-huit contrôles de B ne les attrape ; il l'écrit lui-même.

### Ce que l'inspection a trouvé en plus, et qui bloque

Directive, point 6 : « donner du volume aux racines — **aucune grande plaque
radiale ne doit rester visible** ».

Sur `arbre_approche`, la masse au pied se lit comme une **aile sombre découpée
posée sur l'herbe** : large, plate, à bords francs, sans relief vertical. Sur
`arbre_pied`, l'angle rasant l'aplatit complètement.

Mesuré sur les 1 456 sommets du nœud `SM_ThunderstruckTree_Roots`, séparés par
l'emprise du collider du tronc (`|x| ≤ 1,05`, `|z| ≤ 0,95`, la borne du contrôle
C2d de B lui-même) :

| | sommets | Y max |
|---|---:|---:|
| **DANS** l'emprise du collider | 460 (32 %) | **0,875 m** |
| **HORS** emprise | 996 (**68 %**) | **0,280 m** (plafond 0,32) |

Emprise X −1,51…+2,02 · Z −1,72…+2,81 · Y 0,015…0,875.
**Rapport d'aspect : 4,52 m de large pour 0,86 m de haut, soit 5,3 : 1.**

Deux lectures, et la seconde est le défaut :

1. **B a utilisé l'autorisation** — 0,875 m près du tronc, là où le collider
   interdit déjà le passage. Le raisonnement est juste et je l'accorde.
2. **68 % de la matière est une jupe de 28 cm étalée sur 2 à 3 m.** C'est elle
   qu'on voit. **Le volume est là où on ne le voit pas ; la platitude est là où
   on la voit.**

Et le contrôle C2a ne peut pas l'attraper : il mesure l'**orientation des
normales** d'une section. Une aile mince a des flancs arrondis en section — d'où
les 33,0 % — tout en formant une galette vue de trois quarts. La grandeur
manquante est le **rapport d'aspect**, ou l'étendue verticale de la silhouette
depuis une caméra basse. Quatrième instrument de la passe à mesurer autre chose
que ce qu'on lui demandait.

La contrainte de traversabilité est réelle et ne bouge pas : `ROOT_STEP_MAX_M`
= 0,32 découle du `step_height` de 0,34, et B vient précisément de corriger le
défaut préexistant. Renvoyé à B avec trois voies compatibles — fragmenter la
jupe, rentrer sa portée de 2,8 m à 1,6–1,8 m, ou les deux — plus l'exigence
d'écrire la mesure qui aurait attrapé la galette, **rouge d'abord à 5,3 : 1**.

### Ce que la vue à 94 m dit, et une observation hors périmètre

`arbre_lointain_94` : l'arbre se lit comme une silhouette verticale sombre à
**fourche visible**. Le point 9 tient à ce cadrage — ce que la mesure de fourche
laissait attendre.

**Hors périmètre, noté et NON corrigé** : ce cadrage montre deux grandes taches
saumon à bords très flous sur l'herbe, sans variation interne. Elles se lisent
comme des taches de mélange plutôt que comme du sol sec. Le terrain appartient à
World V2.2 et à la liste gelée ; je n'y touche pas et je ne la range pas non
plus dans « rien à signaler ». À porter à la revue visuelle.

## 16. LE LIANT D'APLATS EST AVEUGLE AU GRIS — et la plus grande surface plate du seuil est grise

C'est le constat le plus lourd de ma passe, et il porte sur **le seul seuil que
j'avais gardé** : `max ≤ 8 %`.

### Le prédicat, lu dans le code

```python
def est_beige(couleur):
    r, v, b = couleur
    return r > 60 and r > v > b and 18 < (r - b) < 110
```

`r > v > b` **strict** et `r − b > 18` : une surface **neutre** (r ≈ v ≈ b) ne
peut pas satisfaire ce prédicat. L'instrument ne voit donc **que les aplats
beiges chauds**. Personne ne l'avait dit, et son en-tête ne le dit pas non plus.

### Ce que la mesure donne quand on retire ce seul filtre

Même prédicat de platitude, même `SEUIL = 18`, même `MIN_COMPOSANTE = 1500`,
même connexité — **seul le filtre de teinte est retiré** (outil joint,
`aplats_toutes_teintes.py`, écrit par moi) :

| vue (état livré par A) | beige, **vu** | gris/neutre, **invisible** | plus grande composante |
|---|---:|---:|---|
| **`ferme_seuil`** | 21,17 % | **13,77 %** | **11,44 % — GRISE** |
| `ferme_composition` | ~0 | **10,37 %** | 7,15 % grise |
| `ferme_facade` | 0,41 % | **7,72 %** | 3,07 % grise |
| `ferme_laterale` | 0,33 % | **5,67 %** | 2,41 % grise |
| `ferme_approche` | 0,25 % | 1,25 % | — |
| `ferme_arriere` | 4,77 % | 0,47 % | 1,52 % beige |

**Sur `ferme_seuil`, l'agent A rapporte `max = 2,92 %` et passe le liant. La
plus grande surface réellement plate de cette image fait 11,44 %, soit quatre
fois plus — et elle DÉPASSERAIT le plafond de 8 %.** Elle n'est pas comptée
parce qu'elle est grise.

### Ce que j'en sais, et ce que je ne fais que soupçonner

**Mesuré :** boîte `X 3..949 · Y 530..703` sur 1280 × 720, remplissage de sa
boîte 65 %, couleur moyenne **RGB (64, 64, 58)** — écart max-min de **6**, donc
franchement neutre. Présente **avant** le geste d'A : `10,12 %` sur le
`ferme_seuil` de R2B.1, même boîte, même couleur moyenne. Elle passe à 11,62 %.

**Donc : ce n'est pas une régression d'A. C'est un défaut que le portail n'a
jamais vu, ni en R2B.1 ni ici.**

**Soupçonné, non prouvé :** que ce soit le **socle d'assises**. Trois indices —
la bande basse à arête horizontale franche visible dans l'image, la neutralité
de la couleur (de l'herbe à l'ombre resterait verte : `max − min` de l'ordre de
30, pas de 6), et le commentaire d'A lui-même dans
`abandoned_farm_place.gd`, qui parle d'un « écart déjà consigné pour le socle
d'assises » rendant « GRIS UNI ». **L'attribution appartient à l'audit** et à son
instrument ; je ne conclus pas à sa place.

### Une chose que je ne surinterprète pas

Le `TOTAL` toutes teintes tourne autour de **40 %** sur les vues proches, mais
il comprend l'**herbe** et le **ciel**, légitimement plats dans ce rendu. Ce
chiffre-là ne dit rien d'un défaut. Seule la part **grise/neutre**, et surtout la
**plus grande composante grise**, sont des candidats de bâti.

### Conséquence pour le verdict

Le liant `max ≤ 8 %` n'est pas faux : il mesure exactement ce que son prédicat
définit. Mais **il ne mesure pas ce que la directive demande** — « aucune plaque
opaque sans matière » ne parle pas d'une teinte. C'est le **cinquième**
instrument de cette passe à mesurer autre chose que la question posée, et le
premier à être un liant.

Il ne sera **pas relevé, ni abaissé, ni retiré**. Il est **complété** : la part
grise et la plus grande composante grise sont mesurées et publiées à chaque vue,
au même titre que la densité. Si l'attribution confirme le socle, c'est un
**résidu visuel nommé** qui va à la revue — et il pèsera sur la formule de
clôture du §9.
