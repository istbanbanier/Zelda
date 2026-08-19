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

## 17. La plaque grise est IDENTIFIÉE : c'est le socle, et sa cause est un golden master sans UV0

Suite du §16. Je ne me suis pas arrêté au soupçon.

### Coupe verticale dans l'image, à `x = 300`

| y | RGB |
|---:|---|
| 500 → 536 | (85–99, 68–80, 50–58) — pierre chaude du mur |
| **548 → 680** | **(64–65, 64, 59)**, sur **132 pixels de haut** |
| 692 → 716 | (54–57, 80–86, 61–62) — herbe |

**Zéro variation sur 132 pixels.** Ce n'est pas de l'herbe à l'ombre — celle-ci
reste verte et varie. C'est une **surface géométrique unique à couleur
constante**, à arête supérieure franche, entre la maçonnerie texturée et le
gazon. Le recadrage ×1,5 (`zoom_bande_grise.png`) ne laisse aucun doute :
**une dalle grise absolument unie, sans texture, sans relief, sans grain.**

C'est le **socle d'assises**, et c'est très exactement « une plaque opaque sans
matière » — le point 4 des exigences de la ferme, mot pour mot : « supprimer
toute lecture de panneau beige ou de **carton découpé** ».

### La cause, trouvée dans le code puis vérifiée sur les octets

`_socle_assises()` lofte l'anneau de socle à partir de **`SM_Village_Wall.glb`**.
Mesuré par moi sur le fichier :

- **2 primitives, 0 avec `TEXCOORD_0`** ; matériaux `MAT_Village_WallStone` et
  `MAT_Village_Coping` ;
- et il est **golden master GELÉ** — ligne 6 de `GM_BASELINE_SHA256.txt`,
  sha256 `24f39047…`.

**Le socle ne peut donc pas recevoir de texture par UV : son maillage n'en a
pas, et on n'a pas le droit d'y toucher.** Voilà pourquoi il rend gris uni
pendant que les murs voisins, eux, viennent de recevoir la pierre du kit. Le
contraste que je vois dans l'image est la conséquence directe de la correction
d'A : en texturant les murs, elle a rendu le socle **plus** visible qu'avant.

### La sortie, sans toucher au gelé

`StandardMaterial3D` sait plaquer **sans UV** : `uv1_triplanar`, avec
`uv1_world_triplanar` et `uv1_scale`. Une projection triplanaire sur
l'**override runtime** donnerait au socle la matière du kit sans modifier d'un
octet le golden master.

Deux gardes indispensables, et la seconde est critique :

1. vérifier ces propriétés contre la **4.7.1 installée** avant de s'en servir —
   je les donne de mémoire, elles doivent être prouvées ;
2. **l'override doit rester local à `abandoned_farm_place.gd`.**
   `SM_Village_Wall` sert aussi au **hameau de la rivière**, qui est un lieu
   GELÉ ayant passé sa revue. Un matériau modifié en amont changerait un lieu
   que la directive interdit de toucher.

Ce n'est pas une réserve de forme : c'est le chemin par lequel une correction
légitime deviendrait une violation de périmètre.

### Ce que je RETIRE de mon alerte du §16

La part grise n'est **pas** du bâti partout, et je l'ai vérifié plutôt que de
laisser courir le chiffre. Sur `ferme_composition`, la plus grande composante
grise (7,15 %) a pour boîte `X 986..1276 · Y 31..309` et une couleur moyenne
(89, 94, 95) : c'est le **relief de fond en haut à droite**, pas la ferme.

Donc : **le gris est un candidat de bâti, pas une preuve de bâti.** Sur
`ferme_seuil` c'est le socle ; sur `ferme_composition` c'est la montagne.
L'attribution reste le travail de l'audit, et ma mesure ne fait que désigner où
regarder.

### Hors périmètre, noté

`ferme_composition` montre une petite fleur ronde saumon dont le canal rouge
sature à **255** en pleine zone d'ombre. Ce n'est pas un placeholder — le
recadrage montre une corolle sur tige, un asset de flore réel. Végétation gelée,
je n'y touche pas ; c'est chaud pour §1.4 de la bible mais minuscule.

## 18. Le socle est CONFIRMÉ par attribution indépendante — et deux mesures se recoupent

L'audit a attribué la composante que j'avais seulement soupçonnée :

| grandeur | sa mesure sur `c44f430b` | ma mesure sur l'état livré par A |
|---|---|---|
| taille | 92 173 px = **10,00 %** | **11,62 %** (et 10,12 % sur R2B.1) |
| boîte | `X 3–949 · Y 542–703` | `X 3–949 · Y 530–703` |
| couleur | RGB (65, 64, 59) | RGB (64, 64, 58) |
| **attribution** | **`FERME_socle_bati` à 99,3 % de pureté** | — |

**Boîtes identiques en X au pixel près**, 12 px d'écart en Y, couleurs à une
unité par canal — deux instruments écrits séparément, deux états différents, le
même objet. `FERME_socle_bati` ne contient que `Socle` comme géométrie **rendue** :
`Fermette_plinthe` et `Fermette_sol` sont des `K.collider_box`, donc invisibles.
Le terrain tombe dans `reste`, qui ne recueille que **0,7 %** de cette
composante.

**Ce n'est donc pas du sol à l'ombre. C'est du bâti, et c'est le socle.**

Et l'audit a produit à cette occasion un cas témoin qui a **corrigé son propre
attendu** : il attendait 1 composante pour une plaque neutre sur fond uni,
l'outil en rend 2 — parce que **le fond est lui aussi parfaitement plat**. Son
attendu était faux, le code avait raison. Conclusion qu'il en tire et que je
reprends : **un `max` toutes teintes ne se lit jamais seul, il se lit avec
l'identité de sa composante.** Ici 99,3 % de socle, et c'est ce qui en fait un
constat plutôt qu'un chiffre.

## 19. Une impression que la mesure N'A PAS confirmée

Sur `ferme_laterale`, les deux pilastres clairs m'ont paru trop lumineux pour
une ruine, et j'allais le signaler. Mesuré avant de le dire :

| surface | luminance |
|---|---:|
| pilastre clair | **0,437** |
| mur de pierre texturé | 0,267 |
| gravats au pied | 0,278 |
| pan de toit tombé | 0,184 |

`VISUAL_ASSET_BIBLE` §1.5 place la roche entre **0,35 et 0,65**. Le pilastre à
0,437 est **dans la bande** ; c'est le **mur**, à 0,267, qui est sous la bande —
il tombe dans celle des ombres (0,18–0,38).

Donc mon impression de contraste était réelle, mais mon diagnostic était
inversé : le pilastre n'est pas trop clair, la maçonnerie texturée est trop
sombre. Je ne renvoie rien à l'agent A sur cette base — un écart de valeur
d'ensemble se juge à la revue visuelle, pas par un envoi de plus. Consigné pour
qu'elle l'ait sous les yeux.

## 20. Ce que la ferme donne à voir aujourd'hui, vue par vue

Inspection en taille réelle des six captures de travail d'A.

| vue | ce qui marche | ce qui reste |
|---|---|---|
| `ferme_seuil` | la pierre du kit se lit comme de la pierre appareillée à bout portant ; intérieur, chevrons et pan tombé lisibles | **le socle, 11,6 %, dalle grise unie** |
| `ferme_laterale` | ruine crédible : toiture rompue, pan tombé, gravats texturés, poteaux | maçonnerie sous la bande de valeur (§19) |
| `ferme_arriere` | maçonnerie texturée franche, chaînages d'angle nets | mur d'apparence intacte à ce cadrage |
| `ferme_approche` | silhouette de ruine lisible à 16 m | un **grand pan crème sans matière** sur la face gauche |
| `ferme_composition` | tuiles désaturées, ruine lisible à 19 m | la composante grise ici est le **relief de fond**, pas la ferme |
| `ferme_arriere`/`approche` | — | — |

Le geste le plus efficace de la passe est sans conteste la texture de kit sur la
maçonnerie neuve : elle retire la lecture de plaque là où elle était la plus
visible. Ce qui reste est **du bâti non texturable par UV** — socle et,
probablement, le pan crème de `ferme_approche`.

## 21. Note de périmètre — l'audit a écrit dans `tools/CLAUDE.md`

La directive interdit aux agents de toucher à la documentation partagée. L'audit
y a ajouté une règle locale de 16 lignes : `| head` tue un outil d'analyse par
**SIGPIPE avant son `json.dump`**, la console affiche un résultat crédible et
**aucun fichier n'est écrit** — piège payé deux fois dans la même passe, la
seconde en croyant à un défaut de nommage.

**J'intègre le contenu** : il est mesuré, daté, de la même famille que le piège
de `flock` que je venais d'y consigner, et il appartient exactement à ce
fichier. Je note l'écart de périmètre sans en faire une affaire — sa raison
d'être était d'éviter les conflits d'édition, et ses seize lignes s'ajoutent en
fin de fichier là où les miennes sont au milieu.

## 22. Point 6 corrigé — vérifié sur le GLB, et l'agent B me contredit avec raison

### Ce que j'ai remesuré moi-même sur `SM_ThunderstruckTree.glb`

| grandeur | avant | après | plafond |
|---|---:|---:|---:|
| emprise en plan des racines | 4,52 m | **3,02 m** | 3,60 |
| rapport d'aspect | 5,26 : 1 | **3,33 : 1** | 4,20 |
| Y max **hors** collider | 0,280 m | **0,253 m** | 0,32 inchangé |
| Y max **dans** l'emprise du collider | 0,875 m | 0,922 m | — |
| triangles | 3 574 | **3 574** | 6 000 |

Chiffres identiques à ceux de B. Le plafond de traversabilité n'a pas bougé et
la marge s'est **agrandie** (0,253 contre 0,280). Longueurs des bois tombés :
3,90 · 2,51 · 2,01 · 1,45 · 1,09 m — une hiérarchie franche, point 7 tenu.

**Une différence de métrique à ne pas lire comme un désaccord** : B annonce
« surface sous 0,30 m : 59,1 → 47,7 % », je compte **82,5 % des sommets** sous
0,30 m. B mesure une **aire**, je compte des **sommets** — et un comptage de
sommets est biaisé vers les zones finement maillées. La mesure d'aire est la
bonne ; je consigne l'écart pour que personne ne croie plus tard que l'un de
nous s'est trompé.

### Là où B m'a contredit, mesure à l'appui, et où il a raison

J'avais attribué **à la jupe de racine** l'aile sombre qui traverse `arbre_pied`.
B a recapturé après sa correction, l'aile était **toujours là**, et il a mesuré
les angles depuis la caméra imposée :

- **`Roots` : 19,8°** · **`BranchA` : 56,1°** · `BranchD` : 12,2°
- champ horizontal 89°, recadrage inspecté 62°

La masse qui traverse tout le cadre **ne pouvait pas** être la jupe : c'était
`BranchA`, un bois de 4,20 m dont le pied gonflait à **0,68 m de diamètre**,
posé à plat et vu presque en enfilade. Renflement ramené à 0,54 m et relevé
porté à 0,38 : la pièce s'appuie au lieu de gésir.

**Ma correction restait juste — la jupe ÉTAIT une plaque, la mesure le dit — mais
elle ne pouvait pas, seule, faire disparaître ce que je voyais.** J'avais raison
sur le défaut et tort sur son auteur. C'est exactement ce qu'on attend d'un agent
qui connaît sa géométrie mieux que le lead ne lit une image.

### Ce que l'image donne maintenant, et ce qui reste

`arbre_pied` après correction : la masse au pied est **franchement plus
compacte**, on distingue des contreforts séparés, des échardes, un bois relevé
à droite avec du jour dessous. Le grand drap continu a disparu.

**Résidu nommé, non bloquant** : `BranchA` garde une lecture de **madrier** sous
cet angle rasant précis — bords parallèles, dessus plat. C'est une pièce vue
presque en enfilade depuis **une** caméra imposée. La directive interdit de
remplacer un cadrage défavorable ; je le porte donc tel quel à la revue plutôt
que d'en faire un blocage technique.

### Trois déclarations de B que je retiens

1. **La hauteur passe de 0,86 à 0,91 m** pour que deux contreforts cessent de se
   recouvrir en projection — et B démontre que ce n'est pas ce qui porte le
   résultat : à hauteur gelée à 0,86, l'aspect vaudrait **3,51 : 1**, déjà sous
   le plafond de 4,20. Le gain vient de la largeur.
2. **Un défaut introduit puis corrigé** : le relevé avait détaché un chicot resté
   au sol, écrêté à 0,02 — « un losange brun plat posé sur l'herbe ». Vu à l'œil
   au recadrage, **par aucune assertion**.
3. **Un effet de bord assumé** : fermer le trou noir de `arbre_fracture` en
   donnant un fond au surplomb fait passer **C4d de 4,58 à 3,66**, plancher 3,50.
   Déclaré plutôt que dissimulé, et toujours au-dessus du plancher.

### Le contrôle qui manquait, écrit par B

`C2e` : **rapport d'aspect ≤ 4,20 : 1** ET **largeur ≤ 3,60 m**. La seconde borne
est la bonne trouvaille : *le rapport seul se trafiquerait en relevant la jupe ;
la largeur en mètres ne se trafique par rien.* Rouge d'abord sur le GLB livré à
**5,26 : 1 et 4,52 m** — mes valeurs exactes.

## 23. La graine balayée — acceptée, et pourquoi

L'agent A a déclaré de lui-même avoir **balayé la graine** du bruit d'arrachement
contre l'indicateur, ce qui est un réglage sur la mesure. Je lui ai demandé la
distribution plutôt que le seul chiffre retenu, parce qu'une graine ne coûte
rien à changer : la recherche est illimitée et 27 tirages finissent par en
trouver un qui plaît.

Distribution mesurée, configuration figée, indicateur `min(linéaire, log)` sur
l'arête **contiguë** :

| | |
|---|---:|
| minimum | 9,7 % |
| **Q1** | **14,1 %** |
| **médiane** | **15,7 %** |
| Q3 | 17,9 % |
| maximum | 26,0 % |
| passent le plancher de 12 % | **22 / 27 — 81 %** |
| graine retenue `6,3` | 21,8 %, **rang 24/27** |

**La médiane ET le premier quartile passent le plancher.** La dentelure est donc
irrégulière **par construction** : même une graine sous la médiane satisfait le
critère, et le résultat ne repose pas sur le tirage. Accepté.

**Et il faut dire l'autre moitié, que A dit lui-même** : `6,3` est au rang 24 sur
27, dans le quartile haut. Ce n'est pas une graine médiane. La formulation
honnête, qui ira au rapport, est donc : *indicateur 21,8 % sur une graine choisie
au rang 24/27 dans une famille dont la médiane vaut 15,7 % et dont 81 % des
tirages passent.* Les deux moitiés de la phrase comptent.

27 tirages et non 29 : deux graines donnent une arête de moins de cinq colonnes,
où l'indicateur n'est pas défini.

## 24. Une correction que je NE demande PAS — mesurée avant d'y renoncer

Sur `ferme_approche`, le grand pan crème au cœur du bâtiment m'a paru un aplat
majeur : c'est la **face plâtre intérieure** du module de kit, vue par le flanc
ouvert de la ruine. `T_Plaster_BaseColor.png`, `_Normal` et `_ORM` **existent**
dans le dépôt, et l'agent A vient de construire exactement la machinerie qui
saurait les brancher.

J'allais donc lui demander une passe de plus. J'ai mesuré d'abord :

| vue | plus grande composante **beige** | grise |
|---|---:|---:|
| `ferme_approche` | **0,25 %** | 1,25 % |

Le pan crème n'est **une grande composante plate dans aucune vue mesurée**. Mon
œil l'a grossi parce qu'il est clair et central, pas parce qu'il est grand.

**Je n'envoie rien.** Une passe de plus en fin de session, sur une lane presque
close, pour un défaut que trois instruments ne voient pas, serait du périmètre
gagné sur une impression. Consigné pour la revue visuelle, qui tranchera avec
ses yeux — c'est son travail, pas celui d'un seuil.

## 25. Le socle, implémenté — ce que l'agent A a fait de mes deux gardes

Mes deux gardes étaient : vérifier les propriétés contre la 4.7.1 installée, et
garder l'override local à la ferme. A les a traitées ainsi :

1. `uv1_triplanar`, `uv1_world_triplanar`, `uv1_scale` — **présentes et
   affectables sur le 4.7.1-stable installé, vérifiées par sonde avant usage**,
   et non reprises de ma mémoire. C'est la règle du projet appliquée à ma propre
   suggestion.
2. Projection **monde et non locale**, et c'est mesuré : chaque run du socle
   porte `scale.x = longueur / ASSISE_L`, donc une projection locale s'étirerait
   différemment sur chaque côté. La contrepartie habituelle du triplanaire monde
   — l'objet qui glisse dans sa texture quand il bouge — ne s'applique pas : le
   socle ne bouge jamais.
3. **Périmètre contrôlé, pas espéré** : matériau importé **dupliqué** avant toute
   écriture ; clé de cache portant désormais le **mode** (`|tri` / `|uv`) — sans
   lui, un appelant non triplanaire de la ferme aurait reçu le matériau du socle ;
   et un contrôle E qui **recharge `SM_Village_Wall.glb` à neuf** pour exiger que
   son matériau de base soit resté nu. Il rougirait sur une fuite.

Golden masters vérifiés par moi dans son arbre : **6/6 OK**, `SM_Village_Wall`
toujours à `24f39047…`.

Reste à voir l'image : une propriété affectable n'est pas une matière à l'écran.

## 26. Voie B close — `6f8ec80`, et l'A/B à caméra identique montre le point 6

L'arbre de travail de B est **propre** (seul `PLAN_B_ARBRE_R2B2.md` reste non
committé, comme demandé) et ses **golden masters sont 6/6 OK**. Lane close.

J'ai inspecté `ab_pied_point6.png`, montage à **caméra strictement identique** :

- **avant** — une aile sombre continue s'étale à droite du tronc, fondant jupe de
  racine et bois tombé en **une seule masse** à bord festonné. C'est la plaque ;
- **après** — l'aile a disparu. La masse racinaire est compacte autour du tronc,
  le bois tombé est une pièce **distincte**, et l'herbe se voit entre les
  éléments.

Le point 6 se lit dans l'image, pas seulement dans les nombres. C'est la
différence entre un contrôle vert et une correction réussie, et ici les deux
coïncident.

Détail sans conséquence : un petit losange brun plat subsiste en bas du panneau
« après » du montage. C'est très probablement le chicot détaché que B a corrigé
au commit **suivant** (`b9b9a13`) ; la capture finale `apres_point6/arbre_pied.png`
ne le montre plus. Noté pour qu'un relecteur du montage ne le prenne pas pour un
défaut résiduel.

### Agent B n'est plus joignable

Sa session n'a plus de transcript — même incident qu'en R2B.1 avec deux agents.
Sa voie était **déjà déclarée close** et son arbre est propre : rien n'est perdu.
Les corrections restantes, s'il en fallait, seraient de mon fait et signées comme
telles dans le message de commit.

## 27. Intégration — `ea6b51f`, 49 commits sur `c44f430b`

Cherry-pick **strict**, aucun merge, aucun rebase des voies. Six commits de la
voie ferme (`a8ddb0c` → `1178e12`), treize de la voie arbre (`2736505` →
`6f8ec80`), puis mes commits de lead.

### Le seul conflit attendu, résolu comme prévu

`docs/assets/ASSET_MANIFEST.csv`, par **propriété d'asset** : fichier de A, ligne
`SM_ThunderstruckTree` de B. Vérifié après coup — les deux lignes conformes à
leur voie, **aucune autre ligne ne diffère de la version d'A**, 200 lignes, et
les **14 doublons d'identifiant sont préexistants au même compte** (`DeadTree_1`,
`Shield_Wooden`, `Chain_Coil`, …). Consignés, pas réparés.

### Une faute de ma part, attrapée par le contrôle du §8

Ma résolution a écrit le fichier avec `csv.writer(f)`, dont le `lineterminator`
par défaut est `\r\n` : **200 retours chariot** dans un fichier qui n'en avait
aucun, ni à la base ni chez A. `git diff --check` les a vus comme 200 espaces en
fin de ligne.

Le contenu était juste, la **forme** changeait tout le fichier. C'est le dégât
exact qu'une résolution de conflit peut enfouir, et la raison d'être de ce
contrôle. Corrigé en commit **additif**, 81 312 → 81 112 octets, 0 CR.

Restent 49 lignes à espace final : **préexistantes** (49 à la base, 49 ici),
espaces à l'intérieur d'un champ CSV de notes.

### La suite intégrée a trouvé un vrai défaut, et c'était le bon

**94 réussis, 1 échoué** :

> `thunderstruck_tree : l'inspection VALIDE porte sur 200544 octets, le GLB du
> dépôt en fait 200548 — journal d'un AUTRE fichier`

Cause : l'agent B a rejoué sa chaîne au commit `7f09f55`, puis a corrigé le
point 6 en **trois commits suivants** qui ont changé le GLB. Les journaux de
pipeline attestaient donc l'état d'avant. Aucun mensonge, un oubli — et un oubli
qu'aucune relecture humaine n'aurait vu, les deux fichiers portant le même nom.

**J'ai rejoué la chaîne entière** (make → export → inspection), pas seulement le
journal qui rougissait : rafraîchir le seul log en échec serait faire passer le
test au lieu de rétablir la vérité.

> **Et le résultat mérite d'être dit : le GLB régénéré est IDENTIQUE OCTET POUR
> OCTET à celui livré** — `c44f9c1e474de23f`, 200 548 octets.

Le générateur Blender de l'arbre est donc **reproductible**, ce qui n'avait
jamais été démontré sur ce sujet et ce qui donne son sens à la chaîne contrôlée.
Le `.blend`, lui, change à chaque génération : il porte des horodatages, pas la
géométrie. `test_world_v2_r2b_farm_tree` : **4/4** après correction.

### Signatures

Deux de mes commits étaient non signés — j'avais passé `-c commit.gpgsign=false`
alors que `commit.gpgsign=true` est configuré. **Je ne les ai pas corrigés
pendant que la suite tournait** : le `git rebase` commence par un checkout qui
retire brièvement du disque le correctif du manifeste, et ce dépôt a déjà
fabriqué huit faux échecs de sauvegarde le 2026-08-11 en laissant deux processus
partager un arbre de travail. Corrigé **après** la suite, et le hash d'arbre est
**identique avant et après le rebase** — seule la signature a changé.

### Vérifications d'intégration

| contrôle | résultat |
|---|---|
| golden masters | **6/6 OK** |
| GLB ferme intégré == voie A | `9c7b94e1848d…`, **oui** |
| GLB arbre intégré == voie B | `c44f9c1e474d…`, **oui** |
| budgets | ferme **2 080** / 4 500 · arbre **3 574** / 6 000 |
| UV0 ferme | **25/25** primitives |
| arbre propre | oui |
| push | fast-forward, local == distant |

## 28. Boîtitude — j'ai mesuré moi-même, et j'ai d'abord cassé mon propre instrument

### Le bug que j'ai commis, et comment je l'ai vu

Ma première version du détecteur a rendu **0,0 %** de boîtes canoniques sur
`SM_Farm_Ruins.glb`. Je ne l'ai pas cru : l'audit annonçait 79,6 %, et une pièce
comme un pan de couverture est visiblement un pavé.

Cause : j'avais fusionné **le soudage par position** et **la connexité** dans une
seule union-find. Chaque composante s'effondrait donc sur un unique sommet
racine, et aucune ne pouvait présenter huit sommets. Le test « 8 sommets » ne
pouvait jamais être vrai — l'instrument répondait toujours « aucune boîte ».

**Je l'ai attrapé parce que le résultat était invraisemblable, pas parce que le
code m'a alerté.** C'est le sixième instrument de cette passe à mesurer autre
chose que la question posée, et le troisième qui est de moi.

Corrigé : soudage par position d'abord, union-find sur les **identifiants
géométriques** ensuite.

### Ma mesure, avec son prédicat écrit

Prédicat : **composante de 12 triangles exactement, 8 sommets géométriques
distincts après soudage, les 8 à équidistance du centroïde à 2 % près** — la
propriété qui caractérise un pavé droit quelle que soit son orientation.

| pièce | comp. | tri | tri en boîtes | % |
|---|---:|---:|---:|---:|
| `RoofPan_Intact` | 9 | 108 | 108 | **100,0** |
| `RoofPan_Fallen` | 9 | 108 | 108 | **100,0** |
| `InteriorFrame` | 6 | 72 | 72 | **100,0** |
| `Debris_A` | 11 | 124 | 120 | **96,8** |
| `Debris_B` | 11 | 124 | 120 | **96,8** |
| `Truss` | 21 | 212 | 192 | **90,6** |
| `JoistStubs` | 9 | 76 | 48 | 63,2 |
| `Jamb_Door` | 9 | 108 | 36 | 33,3 |
| `Jamb_Breach` | 7 | 92 | 24 | 26,1 |
| `GableBreak` | 14 | 308 | 24 | 7,8 |
| `Rubble_Wall` | 16 | 184 | 12 | 6,5 |
| `WallBreak_North` | 16 | 336 | 12 | 3,6 |
| `WallStub_East` | 4 | 84 | 0 | **0,0** |
| `Rubble_North` | 12 | 144 | 0 | **0,0** |
| **TOTAL** | **154** | **2 080** | **876** | **42,1 %** |

### Deux instruments, un facteur deux, et je ne choisis pas le mien

L'audit rend **79,6 %**, je rends **42,1 %**. Les deux dépassent le plafond de
25 %, donc **le verdict ne change pas** — mais un facteur deux sur un liant qui
échoue mérite mieux qu'un haussement d'épaules. Prédicat de l'audit demandé.

Même règle que pour le 16,1 contre 18,3 de l'arête : **les deux chiffres au
rapport avec leur définition, jamais une moyenne.**

### Ce que la localisation change à la question

**Les boîtes sont la CHARPENTE** — pannes, solives, pans de couverture,
ossature. Un madrier **est** un pavé droit, et c'est la primitive juste pour du
bois de charpente. À l'inverse, `Rubble_North` et `WallStub_East` sont déjà à
**0,0 %** : la fonction `moellon()` produit des volumes irréguliers.

Le portail ne dit donc pas « la maçonnerie est en cubes ». Il dit **« la
charpente est en madriers droits »**. C'est une question différente, et c'est
celle qui va à la revue.

### L'échelle à trois barreaux — l'écart n'était pas une erreur

L'audit a implémenté mon prédicat dans son outil et **reproduit mon 42,1 % au
dixième**. Nos deux chiffres ne se contredisaient pas : ils mesurent trois
questions différentes.

| prédicat | définition | résultat |
|---|---|---:|
| `hexa` (le liant) | 12 triangles + 8 sommets soudés | **79,6 %** |
| équidistance (le mien) | + 8 coins à 2 % du centroïde | **42,1 %** |
| `droite` | + 6 directions de normale | **9,2 %** |

« Solide à huit coins », « pavé quelle que soit son orientation », « pavé aligné
sur les axes ». Mes deux hypothèses sur l'écart étaient fausses **dans les deux
sens** : l'audit a une mesure plus lâche **et** une plus stricte que la mienne.

**Et il m'a corrigé sur les moellons.** J'avais écrit que `Rubble_North` à 0,0 %
prouve que `moellon()` produit des volumes irréguliers. Faux : il rend **100 %
sous `hexa`** et 0 % sous l'équidistance. `moellon()` produit des **boîtes
déformées** — un cube dont on a bougé les coins. Mon 0,0 % ne disait pas
« irrégulier », il disait « pas un pavé droit ».

### Le second défaut nommé par l'audit — RÉFUTÉ par la mesure

L'audit a écrit : « `RoofPan_Fallen` à 100 % de pavés, **géométriquement
identique** au pan intact — la chute n'a pas été modélisée, seulement la pose ».
J'ai vérifié avant de le porter au rapport.

| | X | Y | Z |
|---|---|---|---|
| `RoofPan_Intact` | 0,000…3,550 | 0,000…**0,143** | −3,400…+3,400 |
| `RoofPan_Fallen` | 0,000…3,150 | 0,000…**2,161** | −1,766…+1,717 |

Et le test décisif : le **spectre des distances au centroïde**, invariant par
toute transformation rigide et donc insensible à la pose, diffère de
**1,854 m au maximum** sur 216 sommets de part et d'autre. Deux formes
identiques à une rotation près auraient un spectre identique au millième.

**Le pan tombé est plié, pas incliné. La chute EST modélisée.**

Ce que les deux nombres de l'audit disaient réellement : même **compte** de
triangles, même **composition en boîtes**. Une identité de statistique, pas de
géométrie. L'audit l'a reproduit, puis a trouvé qu'il **avait la donnée** dans
son propre relevé du point zéro et avait conclu à partir d'un autre chiffre sans
se relire. La règle qu'il en tire, et que je reprends : **avant d'affirmer que
deux géométries sont identiques, exiger un invariant de forme — spectre, volume,
aire, boîte — jamais un compte de primitives.**

### Ce qui reste, et la formule qui va à la revue

`Debris_A` et `_B` à **96,8 % de pavés** tient : le constat repose sur la
composition, pas sur une comparaison entre meshes. Et le jugement de l'audit sur
la charpente est le bon — un bois de charpente est scié d'équerre.

> **La charpente est en pavés droits — c'est juste. La maçonnerie est en boîtes
> déformées — c'est acceptable. Les débris sont en pavés droits — c'est le
> défaut.**

Bien plus utile à une revue que « 79,6 % contre 25 % ».

## 29. Le socle après triplanaire — mesuré sur MES captures finales

| `ferme_seuil` | avant socle | après socle |
|---|---:|---:|
| plus grande composante plate, **toutes teintes** | **11,44 %** (grise) | **3,67 %** (beige) |
| part grise / neutre | 13,77 % | **1,49 %** |
| aplat beige `max` (liant ≤ 8 %) | 7,32 % | **2,92 %** |

La dalle grise unie de 132 pixels de haut a disparu de l'image : le bas du cadre
est de la pierre appareillée. **Le liant passe désormais sur les deux
instruments** — celui de R2B.1, aveugle au gris, et celui que j'ai écrit pour
contourner cet aveuglement. L'angle mort que j'avais trouvé est fermé par une
correction, pas par un argument.

Les six vues au SHA final, aplat beige `max` : approche 0,63 · composition 0,84 ·
façade 0,27 · latérale **0,17** · arrière 0,60 · **seuil 2,92**. Toutes sous 8.

## 30. Ce que les orbites ont montré, et une impression encore infirmée

`ferme_orb045` — un azimut que les six caméras imposées n'offrent pas — montre
la ruine sous un angle très favorable : socle texturé sur tout le pourtour,
travée ouverte, moignon de mur avec ses gravats au pied.

J'y ai vu un grand pan crème sans matière et j'allais le signaler. Mesuré
d'abord : la plus grande composante plate de cette vue fait **9,62 % et elle est
VERTE** — c'est l'herbe. Le beige n'occupe que **1,39 %**. Mon œil a de nouveau
grossi une surface claire et centrale.

**Deuxième fois de la passe qu'une impression visuelle ne survit pas à la
mesure**, et les deux étaient de moi. Je les consigne toutes les deux : un lead
qui ne publie que ses intuitions justes fabrique une réputation, pas une preuve.

## 31. Le hook a évité un manifeste faux

Un fichier non suivi traînait — le composeur de triptyques — **pendant qu'une
capture tournait**. Le manifeste aurait porté `repo_dirty: true`, ce que le §7
refuse, et j'aurais découvert l'invalidité après coup en relisant le manifeste.

Le hook de fin de tour l'a signalé **avant** que le manifeste ne soit écrit.
C'est la quatrième fois de cette passe qu'un garde-fou attrape ce qu'un humain
attentif aurait laissé passer — après `flock` sans RC testé, `| head` qui tue par
SIGPIPE, et un fichier de plan au mauvais format.

## 32. Les preuves du §7 — ce qu'elles portent, et un défaut de l'outil

**`captures_r2b2/`** — les **quinze caméras imposées**, `shots_r2b1.json`
inchangé. Manifeste : commit `c0374839e6`, **`repo_dirty: false`**, renderer
`forward_plus`, adaptateur `llvmpipe`, 1280 × 720.

Empreintes des six rôles, lues **sur l'octet** au moment de la capture :

| rôle | sha256 |
|---|---|
| `glb_ferme` | `9c7b94e1848dc1a1…` |
| `glb_arbre` | `c44f9c1e474de23f…` |
| `gen_ferme` | `35510a603a12dd90…` |
| `gen_arbre` | `429287b8108f5cc7…` |
| `lieu_ferme` | `297048d5105d4afe…` |
| `lieu_arbre` | `86c989b328fa563c…` |

Les deux GLB correspondent exactement à ce que j'avais vérifié à l'intégration.
**C'est l'exigence du §7 — « hash des GLB capturés » — et elle est tenue.**

**Défaut de l'outil, consigné et non corrigé ici** : le champ `commit` de chaque
rôle vaut `inconnu`. `_provenance_par_role()` passe le chemin `res://…` tel quel
à `git log`, qui ne connaît pas ce préfixe. Le `sha256`, lui, passe par
`FileAccess` qui le résout. Un chemin **sans** préfixe fonctionnerait pour les
deux. Je ne relance pas une troisième capture pour un champ redondant — le
commit de l'arbre est déjà en tête de manifeste — mais le défaut est réel et
mérite une ligne dans la prochaine passe.

**Premier lot capturé sans `--provenance`** : son manifeste portait
`provenance: {}`. J'ai refait le lot plutôt que de livrer un manifeste
incomplet. Un drapeau oublié ne se rattrape pas en prose.

**`captures_orbites/`** — les **dix-neuf vues supplémentaires**, manifeste au
commit `16d8a11f0f`, `repo_dirty: false`. Elles s'ajoutent, elles ne remplacent
rien.

**`triptyques/`** — six vues décisives en `R2B / R2B.1 / R2B.2`, aux **trois
mêmes caméras**. Le composeur **refuse** de composer si les trois panneaux n'ont
pas la même taille : un triptyque à trois résolutions comparerait des surfaces
et non des images.

**`planches/`** — niveaux de gris des six vues de ferme et des six d'arbre,
dérivés des captures couleur en luminance Rec. 709. Dérivés et non re-rendus :
mêmes pixels, même caméra, aucun second rendu qui pourrait différer.

### Ce que le triptyque de `ferme_seuil` montre, et pourquoi il compte

Trois panneaux, une seule caméra :

- **R2B** — murs de pierre, une bande grise unie en bas, un grand pan beige plat
  en haut ;
- **R2B.1** — **pire** : quatre pilastres beiges massifs bouchent la baie. C'est
  la régression que la directive a nommée, et le panneau la rend indiscutable ;
- **R2B.2** — les pilastres ont disparu, l'œil traverse jusqu'à l'intérieur et au
  pan de toit tombé, et **le bas du cadre est de la pierre appareillée** au lieu
  d'une dalle grise.

C'est la valeur du triptyque : il montre que la passe intermédiaire a **aggravé**
la vue décisive, et que la correction ne fait pas que revenir en arrière.

## 33. Ce que l'audit indépendant a confirmé sur MES chiffres

Mesures faites par l'audit dans **son** arbre de travail, avec **son** outil, sur
mes captures.

### Le socle — 3,66 contre 3,67

| grandeur | base `c44f430b` | SHA, ma capture | mon chiffre |
|---|---:|---:|---:|
| plus grande composante plate | **10,00 %** `NEUTRE`, RGB (65, 64, 59) | **3,66 %**, TEINTÉE, RGB (63, 36, 18) | 3,67 % |
| part neutre | 11,82 % | **0,00 %** | 1,49 % |

**La plus grande composante n'est plus neutre : elle est teintée.** C'est la
formulation la plus nette du résultat — le socle n'est pas devenu plus petit, il
est devenu de la matière.

L'écart sur la part neutre (0,00 contre 1,49) est une différence de définition,
pas une contradiction : l'audit ne compte que les composantes **retenues**
(≥ `MIN_COMPOSANTE`), je compte tout pixel plat neutre. Les deux disent que le
défaut est levé.

### Caméras — 15/15, zéro écart

`sha256` de `shots_r2b1.json` inchangé à `3eeb8d4aa68bf462…`, manifeste à
`c0374839e6`, `repo_dirty=False`, **égalité stricte champ par champ** sur `from`,
`look` et `fov`. Aucun cadrage remplacé, et ce n'est pas une déclaration : c'est
une comparaison.

### Provenance — cinq empreintes vérifiées contre les blobs réels

`glb_ferme`, `glb_arbre`, `gen_ferme`, `lieu_ferme`, `lieu_arbre` : toutes
exactes. L'audit qualifie mon `commit: inconnu` de **cosmétique** — le `sha256`
épingle le contenu, et le commit se retrouve depuis le dépôt. Ma décision de ne
pas relancer une troisième capture est confirmée par lui, ce qui vaut mieux que
si je l'avais seulement décidée.

### LE MAILLON QUE PERSONNE N'AVAIT POSÉ

L'audit a audité la géométrie à **`ea6b51f6`** ; mes captures sont à
**`c0374839e6`**. Rien ne garantissait que ses nombres et mes images décrivent le
même état.

Il l'a vérifié plutôt que de le supposer :

- les deux GLB sont **identiques** entre les deux commits ;
- `ea6b51f6` est **ancêtre** de `c0374839e6` ;
- `git log ea6b51f6..c0374839e6 -- assets scripts source_assets` est **VIDE**.

Son audit géométrique — boîtitude 79,6 %, UV0 0/25, arbre 10,4 % — s'applique
donc **verbatim** à l'état capturé. Sans ce contrôle, deux séries de preuves
auraient pu décrire deux états différents sans que personne ne s'en aperçoive.
C'est exactement la règle de provenance de R2B.1, appliquée cette fois **entre
deux commits du lead** et non entre un agent et le livrable.

### Triptyques — vérifiés autrement que prévu

Mes triptyques n'ont pas de manifeste JSON, donc le vérificateur de l'audit ne
s'y appliquait pas. Il a découpé les panneaux — séparateurs détectés
automatiquement à `x 0–9 · 863–872 · 1726–1735 · 2589–2598`, panneaux
**853 × 480** — et construit une **matrice de correspondance** contre les trois
lots sources :

| | R2B | R2B.1 | R2B.2 |
|---|---:|---:|---:|
| **panneau 1** | **6,20** | 12,49 | 9,85 |
| **panneau 2** | 12,50 | **6,13** | 12,68 |
| **panneau 3** | 9,59 | 12,48 | **5,92** |

**Matrice diagonale, hors-diagonale au double.** Le résidu de ~6 est l'erreur de
rééchantillonnage, pas une différence de contenu. Les trois panneaux viennent
bien des trois états annoncés.

Un outil qui ne s'applique pas n'est pas une raison de ne pas vérifier : c'est
une raison d'écrire l'autre mesure.
