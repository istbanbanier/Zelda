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
| **plancher absent**, `y +2,88` à `+3,17`, stations 6 à 8 | écart 0,44–0,45 m | 0 |

Le défaut de plancher est **une régression de cette passe** : la géométrie
livrée R2a-3.4, mesurée avec le même instrument corrigé et ses propres cotes,
passe ce contrôle. Il est présent à l'identique dans le run d'**avant** la
correction d'échantillonnage — ce n'est donc pas elle qui le révèle ; il était
là et n'entrait pas dans le compte des percées.

Les stations 7 et 8 sont celles qui **ferment la calotte** : `controle_epaisseur`
et `controle_gabarit` les excluent tous deux par construction. La zone est aussi
celle où `droite` descend à 0,25–0,27, donc où la section devient un coin
étroit — piste à mesurer, pas conclusion.

## Le chiffre d'étanchéité, même instrument des deux côtés

| géométrie | échantillonnage d'origine | échantillonnage corrigé |
|---|---:|---:|
| R2a-3.5, avant cette passe | 403 | — |
| cavité asymétrique seule | 162 | 118 |
| **fusion cavité + enveloppe** | 38 | **0** |

**Zéro percée confirmée**, reproduit indépendamment.

Le passage de 38 à 0 n'est pas un aveuglement de l'instrument, c'est une
correction démontrée. L'échantillonneur du contrôle 2 plaçait ses points à
`ax + f·hw` — symétriquement, et le long de X. Sur un profil devenu très
asymétrique il ne couvrait que 36 % du côté large et **débordait de l'autre**.
Pour chacune des 38 :

* **38 / 38** partaient **hors de la cavité réelle** ;
* **38 / 38** avaient **deux impacts entre l'axe et ce point** — c'est-à-dire
  une **paroi intacte**, traversée à l'aller et au retour.

La sonde se tenait dehors, derrière un mur intact, et comptait comme percée
chaque direction qui s'en échappait. Ce n'est pas une sonde qu'on a aveuglée,
c'est une sonde qu'on a fait rentrer.

La propriété de sûreté qui le prouve : sur un profil **symétrique**, l'écart
entre l'ancien et le nouveau placement vaut **0,00 m sur 495 points** — la
correction ne déplace rien là où il n'y avait rien à corriger. Couverture
désormais 60 % des deux côtés à toutes les stations, 0 point hors cavité contre
36 sur 495, et 38 196 rayons jugés contre 33 007 : le côté large enfin visité.

L'écart que j'avais publié entre mes deux instruments — ma coupe rendait zéro
station trouée là où la sonde confirmait 38 — est **réconcilié par cette
correction, et dans le sens de ma coupe**.

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
