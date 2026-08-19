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
