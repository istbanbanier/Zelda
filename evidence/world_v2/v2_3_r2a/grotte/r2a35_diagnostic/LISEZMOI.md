# R2a-3.5 — mesures d'une géométrie dont LE PORTAIL EST ROUGE

**Rien ici n'est une preuve de réussite.** Le générateur sort en **2**. Ces
mesures existent parce qu'un portail rouge sur la composition nous rendait
aveugles à tout l'aval — la soustraction tient-elle, la sonde trouve-t-elle un
trou, l'épaisseur s'effondre-t-elle — trois questions sans rapport avec le
défaut qui bloque. Une mesure sur une géométrie rouge est une information tant
qu'elle est étiquetée ; ce qui est interdit, c'est de la présenter comme une
preuve.

Le maillage mesuré n'est **pas** versé au chemin livrable. Il vit sous
`assets/environment/caves/prototypes/`, dans l'arbre de travail seulement.

## Ce qui est ACQUIS, et c'est l'arbitrage du lead exécuté

> « Déplacer le vide intérieur, pas sacrifier la silhouette extérieure. »

Écart horizontal entre la crête de chaque tranche et l'axe de la galerie —
mesuré par `tools/plot_cave_section.py` sur le **GLB livré**, jamais sur les
objets Blender :

| | R2a-3.4 (rejeté) | R2a-3.5 |
|---|---:|---:|
| au seuil | 0,00 m | 0,00 m |
| **moyen** | **2,84 m** | **1,06 m** |
| **maximum** | **7,95 m** | **2,29 m** |

Le chiffre de gauche a été publié **avant** d'avoir vu la nouvelle géométrie
(`f4a3df5`), précisément pour qu'il ne puisse pas être choisi après coup. La
galerie ne longe plus les cols : elle est sous la masse dominante.

## Le sommet plat a disparu, et deux instruments indépendants le disent

Largeur au sommet des trois masses, azimut 55 :

| | R2a-3.4 | R2a-3.5 |
|---|---:|---:|
| sommets | 5,58 / 3,60 / 2,18 m | **1,54 / 2,02 / 1,58 m** |

Les 5,58 m étaient la mesure des tables horizontales rejetées. Le ruban de
crête à largeur variable rend un sommet plat impossible **par construction**.

Et les emprises, mesurées par deux chaînes qui ne partagent aucun code :

| | générateur (volumes sources) | `measure_silhouette_masses.py` (image rendue) |
|---|---|---|
| azimut 55 | 5,90 / 7,37 / 3,65 | **5,89 / 7,34 / 3,75** |

Trois centimètres d'écart entre une mesure faite sur les volumes Blender avant
soustraction et une mesure faite sur les pixels d'une silhouette rendue par
Godot. C'est la convergence de deux instruments indépendants, pas une
répétition du même calcul.

## Les six défauts bloquants, mesurés

| # | défaut | mesure | seuil |
|---|---|---|---|
| 1 | azimut 100 : deux masses au lieu de trois | 2 | 3 |
| 2 | plage plane en façade | **9,01 m²** en (−4,68 ; 1,63 ; 2,24) | 6,00 m² |
| 3 | porche : le rayon sort par un jour | 5 rayons, station 0, azimuts 0–26° | 0 |
| 4 | épaisseur de paroi / de collerette | **0,11 m** / 0,18 m | 0,80 / 0,60 |
| 5 | plancher au porche | écart **+0,956 m** | 0,25 |
| 6 | le sol voit le ciel | (4,27 ; 2,58) et (4,47 ; 2,88) | 0 |

Et la sonde indépendante, qui est l'autorité sur les trous :
**385 percées confirmées**, toutes sur `paroi_plus_x`. Épaisseur minimale
0,00 m ; 218 rayons sur 1 188 sous le minimum contractuel de 0,60 m.

## La cause des défauts 3 à 6, et elle est unique

Marge latérale de l'enveloppe autour de la galerie, station par station :

| station | côté `+normale` | côté `−normale` |
|---|---:|---:|
| 1 | 1,07 | 3,24 |
| 2 | 0,91 | 6,88 |
| 3 | **0,07** | 7,63 |
| 4 | **ouvert** | 7,51 |
| 5 | **ouvert** | 7,10 |
| 6 | **ouvert** | 7,09 |
| 7 | 0,32 | 8,01 |
| 8 | 0,76 | 8,63 |

L'enveloppe fait sept à huit mètres de profondeur d'un côté et à peine deux de
l'autre : **la galerie longe le bord mince et le traverse.**

La sonde de contenance qui avait validé l'enveloppe ne mesurait que le
**toit** — « +1,36 m au linteau, +5,39 m au coude, 9/9 stations ». Les parois
latérales n'ont jamais été mesurées, et je l'ai accepté. C'est la même faute
que les trois autres de cette passe : **un seul nombre, qui répond à une autre
question que celle posée.**

Le remède suit l'arbitrage mot pour mot : déplacer la galerie vers `−normale`,
là où sept mètres de roche attendent, sans toucher à l'enveloppe.

## Fichiers

| fichier | ce qu'il montre |
|---|---|
| `silhouette_grotte_r2a35_055.png` | approche — trois masses, sommets vifs |
| `silhouette_grotte_r2a35_100.png` | trois-quarts — **deux** masses, défaut 1 |
| `silhouette_grotte_r2a35_225.png` | arrière — la vue que la revue déclarait bloquante |
| `coupe_technique.png` | enveloppe, galerie, écart crête↔axe, trois sections |
| `carte_epaisseur.png` | épaisseur de première paroi, station × azimut |
| `generateur_diagnostic.log` | la chaîne complète, chaque faute imprimée |
| `sonde_percees.log` | les 385 percées confirmées |
| `couche1_3_cablage_enveloppe.patch` | le câblage, applicable d'un bloc |

Les manifestes portent `repo_dirty: true` : ces captures viennent d'un arbre de
travail, pas d'un commit. C'est cohérent avec leur statut — **diagnostic**, pas
preuve. Une preuve de livraison se capture d'un arbre committé, et il n'y a
rien à livrer tant que le portail est rouge.

---

## Tentative de remède, mesurée, et son échec

Le diagnostic ci-dessus désignait une cause unique : la galerie longe le bord
mince de l'enveloppe. Le remède évident suivait l'arbitrage du lead — déplacer
le vide vers `−normale`, là où sept mètres de roche attendent, sans toucher à
l'enveloppe.

Décalage appliqué : centerline translatée de 0,9 à 1,8 m vers `−normale`,
stations 2 à 8, la bouche gelée au millimètre. Direction fixe pour garder
l'axe monotone en `y`, contrainte de `Profil.u_pour_y` dans la sonde.

Journaux : `generateur_galerie_decalee.log`,
`sonde_percees_galerie_decalee.log`.

| grandeur | avant décalage | après décalage |
|---|---:|---:|
| épaisseur minimale de paroi | 0,11 m | **0,37 m** |
| épaisseur de collerette | 0,18 m | 0,15 m |
| « le sol voit le ciel » | 2 points | **0** |
| écart du plancher au porche | +0,956 m | **+0,701 m** |
| plage plane en façade | 9,01 m² | 9,09 m² |
| rayons sortant par un jour au porche | 5 | 5 |
| **percées confirmées** | **385** | **390** |

Et, comme prévu par construction, la silhouette ne bouge pas d'un centimètre —
`controle_amas` mesure les volumes **avant** soustraction : 5,90 / 7,37 / 3,65
dans les deux cas.

**Ce que cet échec établit, et c'est plus utile qu'une réussite partielle.**
Un déplacement latéral de 1,8 m améliore trois mesures de bord et laisse le
nombre de percées inchangé. Le défaut n'est donc **pas** « la galerie est un
peu trop d'un côté » : la section de cavité — jusqu'à 4,2 m de demi-largeur
avec l'alcôve, 2,92 m de clé — ne tient nulle part sur un trajet qui doit
partir d'une **bouche gelée** et finir **sous la dominante**.

Trois exigences se contredisent, et l'arbitrage appartient au lead :

1. la bouche garde son ancre et sa position (arbitrage R2a-3.5, point 1) ;
2. la poche principale est sous la masse dominante, loin des cols (point 4) ;
3. l'épaisseur est réelle — 0,80 m en paroi, 0,60 m en collerette.

Deux tentatives de repositionnement du vide n'ont pas réconcilié les trois.
Les leviers restants touchent chacun une décision explicite : élargir
l'enveloppe (mais « ne pas sacrifier la silhouette extérieure »), réduire la
section de la galerie (mais le gabarit joueur est un contrat), ou déplacer la
bouche (mais elle est gelée).
