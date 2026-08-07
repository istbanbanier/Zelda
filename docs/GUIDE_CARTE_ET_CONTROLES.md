# Guide du débutant — la carte et les commandes

Ce guide est écrit pour quelqu'un qui n'a jamais lancé le jeu.
Tout ce qui suit a été **lu directement dans le code**, pas recopié d'un autre
document. Quand le code et un autre fichier `docs/` se contredisent, c'est le
code qui a raison, et c'est le code qui est écrit ici.

Deux mots de vocabulaire, une fois pour toutes :

- **mètre** : le jeu utilise le mètre comme unité. 1 pas ≈ 1 m. Le héros mesure
  1,78 m. Quand ce guide dit « 92 m », c'est la longueur d'un terrain de foot.
- **coordonnées (x, z)** : la position d'un lieu sur la carte, comme sur un plan.
  `x` = gauche/droite, `z` = avant/arrière. La hauteur (`y`) est ignorée ici :
  elle ne sert pas à se repérer sur une carte vue du dessus.

---

## Comment lancer le jeu

Le binaire Godot est `godot` (ou le chemin donné par la variable `GODOT_BIN`).
Il faut un écran : ces commandes ne fonctionnent pas en mode « headless ».

| Ce que vous voulez | Commande exacte |
|---|---|
| La partie normale | `godot --path /home/user/Zelda` |
| Le terrain d'entraînement | `godot --path /home/user/Zelda res://scenes/world/TrainingGrounds.tscn` |

**La partie normale.** La commande ouvre `scenes/boot/Boot.tscn` (c'est la scène
de démarrage déclarée dans `project.godot`), qui enchaîne sur le menu principal.
Là, cliquez sur **Nouvelle partie** — ou **Continuer** si une sauvegarde existe.
Le menu charge ensuite `scenes/world/valley/ValleyWorld.tscn`, la vallée.

**Le terrain d'entraînement.** C'est une scène séparée, sans histoire ni ennemi :
cinq épreuves numérotées qui apprennent les cinq pouvoirs du Bracelet, chacune
avec son panneau explicatif planté à côté. **Commencez par là.** C'est aussi le
seul endroit où le vol libre fonctionne (voir la section « mode développement »).

---

# PARTIE 1 — LA CARTE

## Se repérer : où est le nord ?

C'est la question qui compte, et le code y répond sans ambiguïté. Dans
`scripts/world/valley_terrain.gd`, les quatre murs de montagne qui ferment la
vallée sont posés ainsi :

```
["BorderNorth", Vector2(0, -mid), ...]      <- le nord est du côté z négatif
["BorderSouth", Vector2(0,  mid), ...]      <- le sud est du côté z positif
["BorderWest",  Vector2(-mid, 0), ...]      <- l'ouest est du côté x négatif
["BorderEast",  Vector2( mid, 0), ...]      <- l'est  est du côté x positif
```

Donc, dans ce jeu :

| Direction | Axe | Ce qui s'y trouve |
|---|---|---|
| **Nord** | `z` qui **diminue** (va vers le négatif) | la citadelle, le donjon, les gros ennemis |
| **Sud** | `z` qui **augmente** | votre point de départ |
| **Est** | `x` qui **augmente** | le pylône, la forêt, le chasseur |
| **Ouest** | `x` qui **diminue** | la falaise d'escalade, le village |

Deux autres preuves dans le code confirment la même chose : les grandes dalles
de terrain s'appellent `PlainNorth` pour `z` de −256 à −4 et `PlainSouth` pour
`z` de 16 à 256, et un commentaire de `valley_landmarks.gd` décrit le pied
**est** d'une falaise qui occupe `x` de −140 à −80 — donc l'est est bien du
côté des `x` qui montent.

**À retenir : tout le jeu va vers le nord.** Vous démarrez au sud, la citadelle
est plein nord. Si vous ne savez plus où aller, allez vers la citadelle.

## La taille du monde et ses limites

| Mesure | Valeur |
|---|---|
| Sol jouable | environ **500 m × 500 m** |
| Limites | de **−250 m à +250 m** en `x` comme en `z` |
| Ce qui vous arrête | quatre murs de montagne, hauts de 70 m |
| Peut-on les escalader ? | **non** — le code les met dans le groupe `unclimbable` |

Il n'y a pas de mur invisible : ce sont de vraies montagnes, et elles refusent
l'escalade. Vous ne pouvez pas sortir de la vallée.

## Votre point de départ

| | |
|---|---|
| Position | **(x = 0, z = 146)**, à 32,3 m d'altitude |
| Où c'est | sur la crête herbeuse, au **sud** de la vallée |
| Ce que vous voyez | la vallée en contrebas, et la citadelle droit devant, au nord |

Toutes les distances de ce guide sont mesurées **depuis ce point**, à vol
d'oiseau. Le vrai trajet à pied sera plus long : il y a des reliefs à contourner.

## Les trois grands repères du chemin principal

Ce ne sont pas des « lieux à découvrir » : ce sont les trois jalons de
l'aventure. Ils sont visibles de loin, exprès.

| Repère | (x, z) | Distance | Direction | À quoi ça sert |
|---|---|---|---|---|
| **Le camp** | (45, 65) | **93 m** | nord-est | Feu de cuisine + premiers ennemis |
| **Le pylône** | (115, −25) | **206 m** | nord-est | Grande tour cyan : on y apprend l'Arc Link |
| **Porte de la citadelle** | (0, −198) | **344 m** | plein nord | L'entrée du donjon. Le but du jeu. |

La **citadelle** elle-même est la montagne-monument bâtie derrière cette porte,
sur un plateau posé à (0, −210), à 34 m de haut. Vous la voyez depuis le
départ : c'est la grande silhouette au centre de l'horizon. La porte s'ouvre
avec la touche d'interaction et charge le vestibule, puis le donjon.

## Les 33 lieux de la vallée, du plus proche au plus lointain

Chaque lieu se « déclare » quand vous en approchez (le jeu tient un journal des
découvertes) et chacun cache une récompense : un coffre, une arme posée au sol,
un ingrédient ou un fragment d'histoire.

| # | Lieu | (x, z) | Distance | Direction |
|---:|---|---|---:|---|
| 1 | Le Champ des mille fleurs | (−34, 112) | 48 m | nord-ouest |
| 2 | Sanctuaire forestier | (34, 94) | 62 m | nord-est |
| 3 | Ferme abandonnée | (−16, 78) | 70 m | nord |
| 4 | Observatoire en ruine | (76, 128) | 78 m | est |
| 5 | Camps des pillards braise | (72, 112) | 80 m | nord-est |
| 6 | Poste minier de la falaise | (−68, 86) | 91 m | nord-ouest |
| 7 | L'Arbre foudroyé | (−92, 148) | 92 m | plein ouest |
| 8 | La Source aux reflets | (−72, 78) | 99 m | nord-ouest |
| 9 | Pont magnétique | (−34, 44) | 108 m | nord-ouest |
| 10 | Bassin conducteur | (16, 28) | 119 m | nord |
| 11 | Territoire du chasseur | (128, 150) | 128 m | plein est |
| 12 | Village de la rivière | (−70, 36) | 130 m | nord-ouest |
| 13 | Passage dérobé de l'Éperon | (−134, 122) | 136 m | ouest |
| 14 | Aqueduc ancien | (−12, 10) | 137 m | nord |
| 15 | L'Arche de pierre | (−21, 10) | 138 m | nord |
| 16 | Tour de guet effondrée | (−128, 82) | 143 m | nord-ouest |
| 17 | La Chute du Voile | (150, 118) | 153 m | est |
| 18 | Hameau des bûcherons | (110, 40) | 153 m | nord-est |
| 19 | Grotte de la cascade | (−118, 26) | 168 m | nord-ouest |
| 20 | Le Belvédère du guetteur | (168, 40) | 199 m | nord-est |
| 21 | Le Cercle des Veilleurs | (−132, −28) | 218 m | nord-ouest |
| 22 | L'Arbre doyen | (−96, −62) | 229 m | nord-ouest |
| 23 | Cimetière du tertre | (58, −78) | 231 m | nord |
| 24 | Ronde des pillards azur | (78, −78) | 237 m | nord-est |
| 25 | Crypte oubliée | (−60, −90) | 244 m | nord |
| 26 | Bastion des briseurs d'obsidienne | (−140, −60) | 249 m | nord-ouest |
| 27 | La Gorge du Vent | (68, −96) | 251 m | nord |
| 28 | Caravane foudroyée | (−38, −120) | 269 m | nord |
| 29 | Mine abandonnée | (160, −70) | 269 m | nord-est |
| 30 | Le Bois Courbé | (−8, −152) | 298 m | nord |
| 31 | Courtine effondrée | (−104, −138) | 302 m | nord-ouest |
| 32 | Tanière du colosse des ravins | (150, −140) | 323 m | nord-est |
| 33 | Cavité de cristal | (−140, −150) | 327 m | nord-ouest |

### Les mêmes lieux, rangés par famille

**Village et hameaux (3)** — les endroits construits, avec des murs et des toits.

| Lieu | (x, z) | Distance |
|---|---|---:|
| Poste minier de la falaise | (−68, 86) | 91 m |
| Village de la rivière | (−70, 36) | 130 m |
| Hameau des bûcherons | (110, 40) | 153 m |

**Grottes et souterrains (5)** — on y entre, il y fait sombre.

| Lieu | (x, z) | Distance |
|---|---|---:|
| Passage dérobé de l'Éperon | (−134, 122) | 136 m |
| Grotte de la cascade | (−118, 26) | 168 m |
| Crypte oubliée | (−60, −90) | 244 m |
| Mine abandonnée | (160, −70) | 269 m |
| Cavité de cristal | (−140, −150) | 327 m |

**Territoires ennemis (5)** — cinq zones dangereuses, une par famille d'ennemi.
Chacune garde un coffre. Aucune n'est obligatoire.

| Territoire | Qui y vit | (x, z) | Distance |
|---|---|---|---:|
| Camps des pillards braise | les plus faibles | (72, 112) | 80 m |
| Territoire du chasseur | le chasseur centaure, très dangereux | (128, 150) | 128 m |
| Ronde des pillards azur | archers et lanciers | (78, −78) | 237 m |
| Bastion des briseurs d'obsidienne | ennemis lourds et blindés | (−140, −60) | 249 m |
| Tanière du colosse des ravins | le géant de 4 m | (150, −140) | 323 m |

**Lieux de Résonance (2)** — ils servent à apprendre les pouvoirs du Bracelet.

| Lieu | (x, z) | Distance |
|---|---|---:|
| Pont magnétique | (−34, 44) | 108 m |
| Bassin conducteur | (16, 28) | 119 m |

**Ruines, vestiges et merveilles naturelles (18)** — tout le reste : les
paysages remarquables et les restes du monde d'avant.

## Les ennemis déjà posés sur la carte

Neuf ennemis sont placés à la main dans `valley_world.gd`, en plus de ceux des
territoires. Ils **patrouillent** : ils ne restent pas plantés. Ils sont posés
exprès sur la route du nord, pour qu'on ne puisse pas atteindre la citadelle
sans en croiser un seul.

| Ennemi | (x, z) | Distance | Direction |
|---|---|---:|---|
| Pillard azur | (58, 30) | 130 m | nord-est |
| Briseur d'obsidienne | (−104, 62) | 134 m | nord-ouest |
| Pillard azur | (92, 16) | 159 m | nord-est |
| Chasseur centaure | (150, 52) | 177 m | nord-est |
| Pillard braise | (20, −49) | 196 m | nord |
| **Colosse des ravins** | (22, −64) | 211 m | nord |
| Pillard azur | (15, −99) | 245 m | nord |
| Pillard azur | (26, −118) | 265 m | nord |
| Pillard braise | (−24, −148) | 295 m | nord |

Le **colosse des ravins** à 211 m est posé volontairement en travers de la rampe
qui monte au donjon : impossible de l'éviter du regard. Le **chasseur centaure**
à 177 m est le combat le plus dur de la vallée — ce n'est pas un passage obligé.

## Un itinéraire simple pour une première partie

1. Descendez la crête vers le **nord-ouest** : le Champ des mille fleurs (48 m)
   vous donne de l'herbe d'endurance.
2. Filez au **camp** (93 m, nord-est) : c'est là qu'est le feu de cuisine.
3. Poussez jusqu'au **pylône** (206 m, nord-est) pour apprendre l'Arc Link.
4. Prenez plein **nord** vers la **porte de la citadelle** (344 m). Prévoyez de
   croiser le colosse en chemin.

---

# PARTIE 2 — COMMENT JOUER

## Avant tout : pourquoi les touches « tombent bien » sur AZERTY

Le jeu n'enregistre pas la **lettre** d'une touche, il enregistre sa **position
physique** sur le clavier (dans le code : `physical_keycode`). Résultat : les
touches restent au même endroit sous vos doigts quel que soit le clavier, mais
la **lettre inscrite dessus change** entre AZERTY et QWERTY.

C'est pour ça que sur un clavier français vous vous déplacez en **ZQSD** et que
`Q` va bien à gauche, sans avoir rien à régler.

Le seul piège : **la touche du Pulse est marquée `A` sur un clavier AZERTY et
`Q` sur un QWERTY.** Ce n'est pas une erreur, c'est la même touche physique. Le
tutoriel du terrain d'entraînement affiche d'ailleurs « Touche A ».

Dans les tableaux ci-dessous, la colonne **AZERTY** est celle à lire si votre
clavier est français.

## Se déplacer

| Action | AZERTY | QWERTY | Manette |
|---|---|---|---|
| Avancer | `Z` | `W` | Stick gauche ↑ |
| Aller à gauche | `Q` | `A` | Stick gauche ← |
| Reculer | `S` | `S` | Stick gauche ↓ |
| Aller à droite | `D` | `D` | Stick gauche → |
| Sauter | `Espace` | `Espace` | `A` (bouton du bas) |
| Sprinter (maintenir) | `Maj gauche` | `Maj gauche` | Presser le stick gauche (L3) |

Le sprint vide l'endurance. À zéro, vous repassez automatiquement en course :
vous n'êtes jamais bloqué, vous ralentissez.

## La caméra

| Action | Clavier/souris | Manette |
|---|---|---|
| Regarder autour | Bouger la **souris** | Stick droit |

La sensibilité de la souris se règle dans **Options** depuis le menu principal
ou le menu pause, et le réglage est sauvegardé.

## Grimper

**Il n'y a pas de touche pour grimper.** C'est automatique : marchez contre une
paroi prévue pour l'escalade en gardant la direction appuyée, et le héros
s'accroche tout seul après un court instant.

| Action | Comment |
|---|---|
| S'accrocher | Avancer contre une paroi escaladable et **garder la direction appuyée** |
| Monter, descendre, aller sur le côté | Les touches de déplacement (`ZQSD`) |
| Sauter depuis la paroi | `Espace` |
| Lâcher la paroi | Arrêter d'appuyer, ou vider l'endurance |

Grimper vide l'endurance. À zéro, **le héros lâche la paroi et tombe** : c'est
prévu, ce n'est pas un bug. Regardez la jauge avant de vous lancer.

## Combattre

| Action | AZERTY | QWERTY | Manette |
|---|---|---|---|
| Attaque légère (enchaînable) | **Clic gauche** | Clic gauche | `RB` / `R1` |
| Attaque lourde | `R` | `R` | Gâchette droite `RT` |
| Garde / parade (maintenir) | **Clic droit** | Clic droit | Gâchette gauche `LT` |
| Esquive (roulade) | `Ctrl gauche` | `Ctrl gauche` | `B` (bouton de droite) |
| Verrouiller une cible | `C` ou **clic molette** | `C` ou clic molette | Presser le stick droit (R3) |
| Cible précédente | `X` ou **molette vers le bas** | idem | Stick droit ← |
| Cible suivante | `V` ou **molette vers le haut** | idem | Stick droit → |
| Viser à l'arc (maintenir) | **Clic droit** | Clic droit | Gâchette gauche `LT` |

**Garder et parer, c'est le même bouton.** Vous maintenez le clic droit avec une
arme de mêlée en main :

- si vous prenez un coup **dans les 0,12 seconde** qui suit le début du maintien,
  c'est une **déviation parfaite** : vous encaissez très peu et l'ennemi est
  déséquilibré ;
- si vous maintenez depuis plus longtemps, c'est un **blocage** ordinaire : ça
  coûte de l'endurance et ça passe à 20 % des dégâts ;
- la garde ne protège que **devant vous**, sur un cône de 135° ;
- si l'endurance tombe à zéro pendant un blocage, la garde **casse**.

Autrement dit : la parade se joue au **timing**, pas en restant appuyé.

⚠️ **L'arc ne tire pas.** Voir la section « Commandes qui ne font rien ».

## Le Bracelet de Résonance — les cinq pouvoirs

C'est la mécanique signature du jeu. Deux pouvoirs ont leur propre touche ; les
trois autres passent tous par le **focus**.

### Les deux pouvoirs à touche directe

| Pouvoir | AZERTY | QWERTY | Manette | Ce que ça fait |
|---|---|---|---|---|
| **Pulse** | `A` | `Q` | Croix directionnelle ↑ | Révèle pendant quelques secondes tout ce qui réagit au Bracelet, dans un rayon de 10 m. **Ne traverse pas les murs.** |
| **Ground** (mise à la terre) | `T` | `T` | Croix directionnelle ← | Vide la charge électrique d'une cible proche. Il faut être **à moins de 3 m**, **au sol**, et **ne pas bouger** pendant l'amorce. |

### Les trois pouvoirs qui passent par le focus

Le principe est toujours le même :

> **Maintenez `G`**, visez avec la caméra, puis **clic gauche** pour confirmer.

Ce que fait le clic dépend uniquement de **ce que vous visez** — le jeu choisit
le bon pouvoir tout seul.

| Vous visez… | Pouvoir déclenché | Détail |
|---|---|---|
| Un **cône cyan** (ancrage) | **Arc Step** | Une ruée horizontale vers l'ancrage. Portée 10 m, coûte 20 d'endurance. |
| Un **port** de mécanisme | **Arc Link** | 1er clic = la source (retenue), 2e clic **sans lâcher `G`** = le récepteur. Le courant circule entre les deux. |
| Un **objet métallique** | **Polarité** | Clic gauche = **attirer** l'objet vers vous. `Maj gauche` + clic = **repousser** (voir l'avertissement plus bas). |
| Une **surface chargée** | **Ground** | Même effet que la touche `T`. |

| Commande du focus | AZERTY | QWERTY | Manette |
|---|---|---|---|
| Maintenir le focus | `G` | `G` | `LB` / `L1` |
| Changer de cible visée | `X` / `V` ou molette | idem | Stick droit ← / → |
| Confirmer | **Clic gauche** | Clic gauche | `RB` / `R1` |
| Annuler | **Lâcher `G`** | Lâcher `G` | Lâcher `LB` |

Trois choses à savoir :

1. **Lâcher `G` annule tout ce qui est en cours**, y compris le premier port
   d'un Arc Link commencé. Un lien déjà posé, lui, reste.
2. Tant que `G` est maintenu, **votre épée et le verrouillage sont suspendus** :
   le clic gauche sert au Bracelet, pas à frapper.
3. L'Arc Link ne **crée** jamais d'énergie. Il transporte un courant qui existe
   déjà. S'il ne se passe rien, c'est que la source n'est pas alimentée.

## Objets, menus et survie

| Action | AZERTY | QWERTY | Manette | Détail |
|---|---|---|---|---|
| Interagir | `E` | `E` | `X` (bouton de gauche) | Ouvrir un coffre, ramasser, ouvrir une porte, **cuisiner** |
| Inventaire | `Tab` | `Tab` | `Y` (bouton du haut) | Armes, ingrédients, plats |
| Plat rapide (manger) | `F` | `F` | Croix directionnelle ↓ | Consomme le plat équipé, immédiatement |
| Pause | `Échap` | `Échap` | `Start` / `Menu` | Menu pause et options |

**Cuisiner** n'a pas de touche dédiée : approchez-vous d'un **feu de camp** et
appuyez sur `E`. L'atelier de cuisine s'ouvre, vous choisissez 1 à 5
ingrédients, vous confirmez. Le premier feu est au camp, à 93 m du départ.

## Le mode développement (F3, F4, F5)

Ce sont des **touches brutes**, volontairement hors du système de commandes : on
ne peut pas les remapper et elles ne peuvent entrer en conflit avec rien. Elles
fonctionnent partout, tout le temps.

| Touche | Ce que ça fait |
|---|---|
| `F3` | **Démarre / arrête un enregistrement** de session. Affiche un panneau avec les FPS et les ralentissements. |
| `F4` | **Signale un problème** : pose un marqueur horodaté + une capture d'écran. |
| `F5` | Prend une **capture d'écran**. |

⚠️ **`F4` et `F5` ne font rien tant que `F3` n'a pas été pressé.** Le code sort
immédiatement si aucun enregistrement n'est en cours. Ordre à respecter :
`F3` d'abord, puis `F4` / `F5`.

Il existe aussi un **vol libre** (traverser le décor pour aller voir la carte de
haut) :

| Action | Touche | Manette |
|---|---|---|
| Activer / couper le vol | `F2` | `Back` / `Select` |
| Monter | `Espace` | Bouton `Guide` |
| Descendre | `Ctrl gauche` | Croix directionnelle → |

⚠️ **Le vol libre ne marche que dans le terrain d'entraînement.** Voir juste
en dessous.

## Commandes déclarées qui ne font rien

Ce sont des commandes qui **existent dans la configuration du jeu** mais qui
n'auront aucun effet quand vous appuierez. Ne perdez pas de temps à les essayer.

### 1. Le tir à l'arc — **cassé, sans contournement**

La commande `shoot` est bien déclarée sur le **clic gauche** et sur la
**gâchette droite** de la manette. Elle ne se déclenchera jamais.

Pourquoi : le code qui lit les entrées teste les commandes **les unes après les
autres et s'arrête à la première qui correspond** (`player_input_reader.gd`).
Or l'attaque légère est testée **avant** le tir et occupe **le même** clic
gauche ; et l'attaque lourde est testée **avant** le tir et occupe **la même**
gâchette droite. Le tir n'est donc jamais atteint, sur aucun périphérique.

Conséquence concrète : vous pouvez équiper l'arc, vous pouvez viser avec le clic
droit — **mais aucune flèche ne partira**. La fonction qui tire n'a qu'un seul
appel dans tout le jeu, et il est gardé par cette commande inatteignable.
En dehors des tests automatiques, rien ne déclenche un tir.

### 2. Le vol libre en partie normale — inactif

`F2`, ainsi que « monter » et « descendre », ne font rien dans la vallée. Le
module de vol n'est créé que dans le terrain d'entraînement
(`scripts/world/training_grounds.gd`). Dans la partie normale, personne ne lit
ces commandes. Elles fonctionnent **uniquement** dans
`scenes/world/TrainingGrounds.tscn`.

### 3. « Maj + clic » pour repousser un objet — **à vérifier sur machine**

Le tutoriel du terrain d'entraînement affiche : « `Maj gauche` + clic gauche
pour la REPOUSSER ». Cette combinaison est **douteuse** et mérite un essai réel.

Pourquoi le doute : le code demande une correspondance **exacte** de la touche,
et `Maj` est justement la touche de sprint. Un clic effectué pendant que `Maj`
est maintenu porte le modificateur `Maj`, alors que la commande enregistrée n'en
porte aucun. Selon la façon dont le moteur compare les deux, le clic peut être
ignoré — et alors seul « attirer » fonctionnerait.

Je ne peux pas trancher sans lancer le jeu. **Testez-le dans l'épreuve 3 du
terrain d'entraînement** : si la caisse vient toujours vers vous au lieu de
s'éloigner, c'est que la combinaison ne passe pas.

### Ce qui n'est *pas* cassé, malgré les apparences

- **`look_left` / `look_right` / `look_up` / `look_down`** n'ont aucune touche de
  clavier : c'est normal. Ce sont les quatre directions du **stick droit** de la
  manette. À la souris, la caméra passe par un autre chemin et fonctionne.
- **Il n'y a pas de touche « grimper »** : c'est voulu, l'accroche est
  automatique.
- **Il n'y a pas de touche « cuisiner »** : c'est la touche d'interaction `E`
  devant un feu.

---

## Récapitulatif d'une page

**La carte.** Monde de 500 × 500 m, limites à ±250 m, fermé par des montagnes
inescaladables. Vous démarrez au sud en (0, 146). **Le nord, c'est là où `z`
diminue**, et c'est là que tout se passe : camp à 93 m, pylône à 206 m, porte de
la citadelle à 344 m. 33 lieux à découvrir, le plus proche à 48 m, le plus
lointain à 327 m. 9 ennemis posés sur la route du nord, plus 5 territoires.

**Les commandes.** `ZQSD` pour bouger, souris pour regarder, `Espace` pour
sauter, `Maj` pour sprinter. Clic gauche pour frapper, `R` pour frapper fort,
clic droit maintenu pour garder et parer, `Ctrl` pour esquiver, `C` pour
verrouiller. `A` pour le Pulse, `T` pour la mise à la terre, et `G` maintenu +
clic gauche pour les trois autres pouvoirs du Bracelet. `E` pour interagir et
cuisiner, `Tab` pour l'inventaire, `F` pour manger, `Échap` pour la pause.
`F3` puis `F4`/`F5` pour signaler un problème.

**Et surtout : l'arc ne tire pas.** Comptez sur la mêlée.

---

*Guide établi par lecture du code source, sans exécution du jeu. Sources
principales : `project.godot` (section `[input]`),
`scripts/components/player_input_reader.gd`, `scripts/player/player_controller.gd`,
`scripts/reaction/resonance_controller.gd`, `scripts/tools/dev_mode.gd`,
`scripts/tools/dev_fly_mode.gd`, `scripts/world/valley_terrain.gd`,
`scripts/world/valley_world.gd`, `scripts/world/training_grounds.gd`, et les
constantes `SITE_*` des fichiers `scripts/world/valley_*.gd` et `hamlets.gd`.*
