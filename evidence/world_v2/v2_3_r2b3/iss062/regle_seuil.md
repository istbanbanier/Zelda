# ISS-062 — règle de choix du seuil, écrite AVANT toute mesure

Écrite le 2026-08-20, après l'autotest (15/15) et **avant** d'avoir lancé
`mesure_rectangularite.py` sur le moindre fichier `.glb` du dépôt : ni témoin,
ni sujet. Elle est publiée telle quelle pour qu'on puisse vérifier qu'elle n'a
pas été taillée sur mesure après coup.

## Grandeur qui porte le seuil

`indice_boite = min(part_rectangulaire, part_orthogonale)`

Le `min` et pas la moyenne : les deux grandeurs répondent à deux questions
différentes et une seule ne suffit pas. Mesuré à l'autotest, cas 12 : un
cylindre à 24 côtés rend `rect = 66,86 %` et `ortho = 20,70 %`. Sa moyenne
(43,8 %) ressemble à celle d'un caillou ; son `min` (20,70 %) dit la vérité —
ce n'est pas une boîte. À l'inverse une boîte rend 100/100 et son `min` reste
100. Le verdict d'une mesure composite est le plus faible de ses critères, pas
leur moyenne — c'est déjà la règle du dépôt pour les gates.

## Les témoins ne forment PAS une seule famille

Cette distinction est posée avant de mesurer, sur la seule nature des assets :

- **famille NATURE/DÉBRIS** — `SM_Dungeon_RubbleLarge`, `SM_Dungeon_RubbleSmall`,
  `SM_ThunderstruckTree`. Ces assets sont acceptés ET sont censés n'avoir aucune
  raison d'être faits d'angles droits. C'est sur eux que le seuil se calibre.
- **famille ARCHITECTURE** — `SM_StoneBridge_Arch`, `SM_Village_Wall`,
  `SM_Pylon_Resonance`. Un mur, un pylône, une arche taillée SONT légitimement
  faits d'angles droits. Ils sont mesurés et publiés, mais ils ne peuvent pas
  servir de plafond : un instrument qui interdirait à un mur d'être rectangulaire
  interdirait l'architecture.

Corollaire, à dire d'avance : **le plafond ne s'applique qu'aux meshes censés
être des débris ou de la matière naturelle.** L'instrument ne sait pas décider
seul de quelle famille relève un mesh ; c'est au gate de nommer ses meshes.

## Référence haute

Assemblage de boîtes = 100,00 % (`indice_boite`), valeur analytique confirmée
par les cas 2, 3, 3b et 3c de l'autotest, y compris avec des pavés de tailles
différentes, tournés, et soudés par un coin.

## La règle

Soit `M` = le plus grand `indice_boite` observé sur la famille NATURE/DÉBRIS.

1. Si `M > 60,0` : **BLOQUÉ**. L'écart entre un témoin accepté et un assemblage
   de boîtes serait inférieur à 40 points ; la mesure ne sépare pas assez pour
   qu'un seuil veuille dire quelque chose, et il ne faut pas en poser un.
2. Sinon : `plafond = plancher_entier( (M + 100) / 2 )`, c'est-à-dire le milieu
   entre le pire témoin accepté et la référence boîte, arrondi à l'entier
   inférieur.
3. Contrainte de marge, qui prime sur 2 : `plafond >= M + 10`. Un seuil collé au
   pire témoin rendrait rouge un asset légitime au premier remaniement.

Aucune autre clause. Le seuil est entièrement déterminé par `M`, et `M` est
mesuré sur trois fichiers nommés ici avant de les avoir ouverts.

## Ce que le seuil ne dira pas

Franchir le plafond ne prouve pas qu'un asset est beau, ni qu'il respecte la
bible visuelle. Rester sous le plafond ne prouve pas non plus qu'il est bon :
`mesure_rectangularite.py` ne mesure QUE la part d'angles droits.
