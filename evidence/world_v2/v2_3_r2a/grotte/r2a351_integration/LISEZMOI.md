# R2a-3.5.1 — fusion des trois agents, mesurée · PORTAIL ENCORE ROUGE

**Rien ici n'est une preuve de réussite.** Le générateur sort en **2**. Ce qui
suit est mesuré sur le maillage produit en mode diagnostic, qui n'est **pas**
versé au chemin livrable.

Base commune des trois agents : `34c305d`. Les patches sont applicables d'un
bloc et fusionnent **sans conflit** (`git merge-file`, 0 conflit).

## L'ordre du lead, appliqué

> « À partir de la station 2, construire une section intérieure asymétrique :
> côté `+normal`, limiter le vide au gabarit réel du joueur ; côté `−normal`,
> déporter l'élargissement de la salle, l'alcôve et la récompense. »
>
> « La demi-largeur actuelle de 4,20 m n'est pas le gabarit du joueur. »

`GABARIT_DEMI_LARGEUR_M = 0,95 m`. À la station 5 le vide côté mince passe de
**3,48 m à 0,99 m**, et la largeur retirée est **rendue** au côté épais : la
largeur totale de la salle est conservée. Le contrefort basal autorisé en repli
**n'a pas été construit** — après asymétrie ces stations portent 0,87 à 0,90 m
de paroi, et le justifier aurait demandé une mesure qui n'existe plus.

## Ce qui est vert

| critère | mesure | seuil |
|---|---:|---:|
| **épaisseur de paroi** | **0,87 m** | 0,80 |
| trois masses, azimut 55 | 3 | 3 |
| trois masses, **azimut 100** | **3** | 3 |
| trois masses, azimut 225 | 3 | 3 |
| ratio d'emprises, azimut 55 | **2,16** | 2,00 |
| plage plane globale | 8,36 m² | 12,00 |
| **plage plane en façade** | **4,63 m²** | 6,00 |
| plancher | 0 faute | 0 |
| le sol voit le ciel | 0 | 0 |
| fermeture, connexité, auto-intersection | vertes | — |
| budget de triangles | dans la bande | — |
| **raster des cinq surfaces** | **0 case ouverte** | 0 |

L'azimut 55 n'est plus fragile : le ratio passe de **2,02** (+1 %) à **2,16**
(+8 %). Vérifié par deux instruments qui ne partagent aucun code.

## Ce qui reste rouge

| défaut | mesure | seuil |
|---|---:|---:|
| **collerette** au porche (station 0, azimut 32°) | **0,48 m** | 0,60 |
| rayons sortant par un jour, station 0, azimuts 39–64° | 5 | 0 |
| **percées confirmées** | **38** (23 toit, 15 `paroi_plus_x`) | 0 |

## Le chiffre d'étanchéité, même instrument des deux côtés

| géométrie | percées confirmées |
|---|---:|
| R2a-3.5, avant cette passe | **403** |
| cavité asymétrique seule | 162 |
| **fusion cavité + enveloppe** | **38** |

Et il faut le lire comme un **plancher**, pas un plafond : l'échantillonneur du
contrôle 2 place ses points à `ax + f·hw` — symétriquement, et le long de X. Sur
un profil devenu très asymétrique il ne couvre que **36 % du côté large** aux
stations 4 à 8. La correction est en cours ; tant qu'elle n'est pas passée, 38
est un minorant et le dire fait partie du chiffre.

## Un écart entre deux instruments, que je ne tranche pas

`tools/plot_cave_section.py` rend, sur cette même géométrie : **zéro station
trouée** et **zéro rayon de paroi sans roche** dans la galerie, 24 rayons sur
986 sous 0,80 m. La sonde, elle, confirme 38 percées.

Les deux échantillonnent différemment — l'un sur l'axe analytique station par
station, l'autre par la sphère complète depuis des points intérieurs. **L'écart
est le sujet**, et il sera réconcilié comme l'a été celui des contrôles 2 et 4.
Publier le chiffre confortable serait ici un choix, pas une mesure.

## Ce que le porche demande, et pourquoi ce n'est pas un conflit de contrat

La collerette est mesurée aux stations 0 et 1 (`if i <= 1`). La station 0 est le
**porche**, 1,15 m en avant du seuil : une section qui est l'ouverture. Exiger
0,60 m de roche tout autour semble contradictoire — et pourtant **R2a-3.4 le
tenait**, avec un minimum à la station 1.

La différence est nommée dans l'ancien code : `MASSIF` portait une **« visière
saillante »** à la station 0. La nouvelle enveloppe ne l'a pas. Ce n'est donc
pas un contrat impossible, c'est une pièce manquante — et c'est exactement la
« **lèvre rocheuse épaisse** » et le « linteau naturel et irrégulier » que la
cible de la bouche demande.

Deux façons d'ajouter la matière ont été mesurées et échouent toutes deux :
porter la lèvre à `dp = 2,70` **mure le porche** (station 0 passe de « aucune
matière » à 1,00–1,55 m), et un biais de 0,42 fait tomber la collerette à
**0,08 m** en transformant le jambage en coquille mince. La forme qui reste à
essayer est une **visière** — de la matière **au-dessus et sur les côtés** de
l'ouverture, pas devant elle.

## Fichiers

| fichier | contenu |
|---|---|
| `generateur_A_plus_C.patch` | cavité asymétrique + enveloppe, fusion sans conflit |
| `outils_B.patch` | sonde, coupe, auto-test, contrôle négatif |
| `chaine_fusion.log` | la chaîne complète, chaque faute imprimée |
| `sonde_fusion.log` | les 38 percées, par surface |
| `profil_asymetrique.png` | demi-largeur du vide et roche restante, **par côté** |
| `carte_epaisseur.png` | épaisseur station × azimut, les deux parois séparées |
| `coupe_technique.png` | enveloppe, galerie, écart crête↔axe |
| `journal_minima.csv` | station, côté, azimut, valeur, seuil |
| `c_silhouette/` | les trois azimuts avant/après, plage plane, tentatives écartées |

Aucun seuil n'a baissé dans cette passe. Aucune géométrie n'est versée au chemin
livrable. Le tronc construit toujours la géométrie R2a-3.4 et reste vert.
