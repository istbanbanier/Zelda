# Hameau — sonde de végétation rejouée sur l'emprise entière

Exigé par la revue R2a : « rejouer la sonde de végétation maintenant
corrigée autour de toute l'emprise du hameau. Archiver les positions et
distances réelles. »

## Ce qu'il a fallu réparer d'abord

La sonde ne savait rendre que des **comptes** — « N instances dans R
mètres ». Ça ne répond pas à la question posée : une touffe à 6 m est
dehors, une touffe à 0,2 m d'un mur aussi, et aucun total ne distingue les
deux. Un mode `--place=` a été ajouté : il confronte chaque position du
semis gelé aux **AABB monde** des maillages du lieu et imprime les
positions et les distances.

Il écarte du verdict les pièces de plus de 14 m d'emprise ou de moins de
0,80 m de haut : ce sont des sols, des pavages et des jupes, et une touffe
qui les « traverse » pousse simplement à côté. Il exige aussi que le pied
de la plante soit sous l'arase de la pièce — au-dessus, elle pousserait sur
un toit qui n'existe pas.

## Mesure

| | |
|---|---|
| emprise monde du lieu | x [−109,9 ; −75,4] · z [20,0 ; 45,6] · y [0,0 ; 14,3] |
| pièces bâties retenues | **107** |
| instances de semis gelé dans le monde | **16 651** |
| instances dans l'emprise du lieu | **78** (marge 0) / 80 (marge 0,35 m) |

## Verdict — AUCUNE INTERSECTION

Test strict, marge 0 : **aucune instance de semis gelé ne tombe dans
l'emprise d'une pièce bâtie.** Code retour 0.

Avec une marge de 0,35 m, un seul cas remonte : `veg_c6r8_grass` en
(−82,56 ; 3,22 ; 35,65) contre `PoteauAvant_0` dont l'emprise commence à
z = 36,00. L'écart réel est donc de **0,35 m exactement** — la touffe est à
côté du poteau, pas dedans. C'est la marge qui la fait apparaître, pas la
géométrie.

Distances les plus courtes, pièce par pièce : `Corner_Exterior_Wood` à
0,14 m, `Crate_Wooden` à 0,08 m, `Barrel_Apples` à 0,33 m. Les entrées à
0,00 m (toitures, `SM_VillageQuay_Piles`, `Barrel`, `Crate_Wooden`) sont
des pièces dont l'emprise **XZ** contient une plante mais dont la tranche
**verticale** l'exclut : un toit trois mètres au-dessus d'une touffe n'est
pas une intersection.

Journaux : `vegetation_emprise.log` (marge 0,35) et
`vegetation_emprise_strict.log` (marge 0).

## Conséquence

La condition posée par la revue est remplie. **Le hameau se gèle sans
reconstruction ni recapture générale.**
