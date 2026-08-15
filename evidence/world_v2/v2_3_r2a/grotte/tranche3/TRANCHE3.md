# Grotte — R2a-3.3 : extérieur reconstruit en roches CC0

Ce document ne contient **aucun verdict artistique**. Il livre les diagnostics
demandés, les mesures qui ont guidé chaque décision, ce qui a été corrigé après
lecture des captures, et ce qui reste ouvert.

## Les trois SHA, distingués

Le rapport de la tranche 2 nommait `44e9200` comme « commit prouvé » alors que
les manifestes portaient `1fb57d3`. Les trois rôles ne sont pas
interchangeables, et sont donc nommés séparément :

| rôle | commit |
|---|---|
| source géométrique — `make_waterfall_cave.py` + `.blend` | `8368550` |
| GLB exporté depuis cette source | `8368550` (même commit : source, `.blend` et `.glb` ensemble) |
| arbre utilisé pour les captures | `73dc20a` |

Le second commit n'ajoute que la ligne de manifeste d'asset et `ISS-043` ; il
ne touche ni la géométrie ni le GLB. Les manifestes de capture portent
`73dc20a` et `repo_dirty: false`.

---

## Le pivot, et ce qui l'a imposé

`anneau_exterieur()` ne produit plus aucune surface visible. Il ne sert plus
qu'à la **coque de collision**, qui n'est jamais rendue — l'emploi que le lead
a explicitement autorisé. `anneau_interieur()` sert au **volume négatif** : la
cavité est un solide fermé qu'on soustrait de la roche, si bien que la bouche
n'est plus une collerette dessinée mais la trace de découpe du tube.
`masse_annexe()`, `MASSES_ANNEXES` et `controle_annexe_hors_cavite()` sont
supprimés — les garder aurait refait l'erreur de la télémétrie morte.

### Le chiffre que neuf contrôles verts ne voyaient pas

`tools/measure_module_relief.py` a été écrit pour trancher. Il mesure la plus
grande **plage plane connexe** — littéralement le plus grand pan plat que
l'œil voit — que ni le nombre de familles de normales ni la part d'aire ne
révèlent :

| | familles | plus grande famille | **plage plane connexe** |
|---|---:|---:|---:|
| loft rejeté en tranche 2 | 162 | 7,5 % | **60,93 m²** |
| `template-detail` (kit) | 68 | 8,1 % | **2,59 m²** |

Les deux premières colonnes déclaraient les deux objets équivalents. La
troisième dit ce que le lead a vu.

---

## Dimensions natives des modules, mesurées AVANT implantation

Grille du kit : 4 m. Hauteur de mur : 4,05 m.

| module | dimensions natives (m) | tri | plage plane | relief |
|---|---|---:|---:|---:|
| `template-detail` | 2,64 × 2,81 × 4,35 | 320 | **2,59 m²** | 0,344 |
| `gate-rock` | 4,00 × 2,45 × 4,05 | 360 | 7,24 | 0,156 |
| `template-wall-half` | 2,00 × 1,81 × 4,05 | 192 | 8,10 | 0,201 |
| `template-corner` | 4,00 × 4,00 × 4,40 | 564 | 11,31 | 0,431 |
| `template-wall` | 4,00 × 2,16 × 4,05 | 440 | 16,20 | 0,236 |
| `template-wall-top` | 4,00 × 4,50 × 1,13 | 148 | 18,00 | 0,106 |
| `gate-overhang` | 4,00 × 2,05 × 0,80 | 104 | — | **0,000** |

**Un seul est un rocher.** Les autres sont de la panneauterie de donjon : leur
dos est plat par construction, et le rebouchage qui en fait des solides ajoute
encore un plan entier. Mesuré sur la formation : 8,82 m² de plage plane au
piédroit droit avec `template-wall-half`, puis 15,88 m² au linteau avec
`gate-rock` et `gate-overhang`. La formation est donc bâtie de
`template-detail` seul, à 98 exemplaires, échelle 0,55 à 1,55 — la variété par
l'échelle, le lacet, le tangage, le roulis et le groupement.

Deux modules ont été **écartés** :

* `template-corner`, le meilleur relief du kit, **résiste à la réparation** :
  après soudure, résolution d'auto-intersection et quatre passes de
  rebouchage, il conserve 10 arêtes de bord. Un solide dont je ne peux pas
  prouver qu'il est plein n'entre pas dans un booléen ;
* `template-wall-detail-a` passe **tous** les contrôles — fermé, sans
  auto-intersection, 16,81 m³ — et fait pourtant échouer l'union. Il a fallu
  une bissection roche par roche pour le voir : les sept premières donnent 0
  arête irrégulière, `Bouche_Joue` en donne 57 d'un coup.

> « Fermé et sain » ne veut pas dire « utilisable dans un booléen ». Seule la
> bissection le dit.

---

## Ce qui a été essayé, mesuré, et abandonné

Le journal est dans le code, à côté de chaque décision. Résumé :

| tentative | résultat mesuré |
|---|---|
| union séquentielle, un modificateur par masse | 87 arêtes irrégulières |
| collection unique, 35 opérandes | 155 |
| `use_hole_tolerant` par-dessus | 132 — son nom promet l'inverse de ce qu'il fait ici |
| seconde passe du solveur sur son propre résultat | 62 |
| lots de six, sources subdivisées | 280 |
| **remaillage volumétrique 0,12 m** | **0 arête de bord, 0 non-manifold, 1 coque** |

Deux passes de « rugosité » destinées à casser les dalles ont également été
implémentées puis retirées, chacune sur sa propre mesure : déplacement
vertical fonction de (x, y) → 50 paires croisées à 0,0286 m, parce qu'un tel
déplacement **cisaille** les surfaces verticales ; déplacement selon la
normale vers l'extérieur → 66 paires à 0,0465 m, parce que dans une fissure
les deux parois ont leurs normales tournées l'une vers l'autre.

Et une correction de fond du champ de strates : le quantificateur `round()`
introduisait une **discontinuité de 0,47 m** dans le déplacement, qui
déchirait toute face à cheval sur une limite de lit. Il est devenu une marche
continue et monotone, donc un homéomorphisme vertical, donc **incapable** de
replier une surface saine — c'est démontré, pas espéré.

---

## La gaine, et les deux fois où elle s'est trompée

Le contrôle d'épaisseur par rayon nomme précisément le point le plus mince.
J'y ai répondu **seize fois** en ajoutant une roche là où il pointait ; à
chaque exécution il désignait un autre azimut. C'est le symptôme d'une méthode
fausse : je corrigeais une mesure au lieu de garantir la propriété.

`rochers_gaine()` la garantit par construction : pour chaque station du
chemin, une couronne de roches sur des azimuts fixes, à un rayon dérivé de la
demi-largeur et de la clé. Si `CAVITE` change, la gaine suit.

### Premier défaut : la gaine décidait de la crête

Un relevé **« faite par rang »** a été ajouté au générateur pour ne plus avoir
à deviner. Il a chiffré ce que la capture précédente montrait :

| rang | z max avant | z max après |
|---|---:|---:|
| majeur | 9,16 m | 9,16 m |
| intermédiaire | 7,29 m | 7,29 m |
| **gaine** | **8,26 m** | **6,01 m** |
| secondaire | 2,82 m | 2,82 m |

Un demi-mètre sous les masses majeures, sur trente-cinq positions régulières
le long du tube : le sommet de la formation était une rangée de dents,
c'est-à-dire la « pointe arbitraire » interdite, en série. Une gaine dont le
rôle est d'être invisible ne peut pas porter la silhouette.

### Deuxième défaut : la première correction a ouvert un jour

Ancrer le **sommet** de chaque roche à `cle + marge` ramenait bien la crête à
4,56 m — en donnant la même hauteur à tous les azimuts, donc en faisant
descendre les diagonales hautes de 2,4 m. Le contrôle a répondu à l'exécution
suivante : *station 6, azimuts 51 à 71°, « 0 croisement — le rayon sort par un
JOUR »*. Le placement radial n'était pas un détail de forme ; c'est lui qui
garantissait la couverture.

La crête se plafonne donc par la **taille**, pas par la position : placement
radial conservé, échelle de 1,45 à 1,15, et `GAINE_MARGE_M` devient
l'enfoncement du centre au-delà de la paroi (1,60 → 0,55 m). La roche mord
alors 0,95 m de paroi au lieu de 0,32, et porte encore 1,95 m vers le dehors
pour 0,80 exigés.

Un troisième passage a été nécessaire : à sept azimuts, l'épaisseur tombait à
**0,16 m, station 5, azimut 109°** — la salle, la station la plus large, où un
pas de 30° laisse 1,58 m de corde à 3,05 m de rayon. Neuf azimuts ramènent le
pas à 23°.

> Trois exécutions, trois mesures, trois causes différentes. Aucune n'aurait
> été trouvée à l'œil, et la première correction « évidente » était fausse.

---

## Journal des contrôles, chaîne verte, RC = 0

```
98 roches posees : 63 gaine, 16 majeur, 11 intermediaire, 8 secondaire,
                   plus l'assise enterree
faite par rang   : majeur 9.16, intermediaire 7.29, gaine 6.01, secondaire 2.82
remaillage voxel 0,12 m : 202 952 tris -> 1 coque, 0 bulle, 2 ecailles retirees
                          0 arete de bord, 0 non-manifold, 924,5 m3
stratification          : 0 paire croisee, repli maximal 0,0000 m
decimation              : 202 928 -> 19 000 tris (ratio 0,094)
soustraction            : 1 coque, connexite 1 avant et apres
budget                  : 20 444 tris dans [12 000 ; 25 000]
plage plane > sol       : 3,45 m2, centree en (-2,10 ; 8,29 ; 2,05)  seuil 12,00
plage plane en facade   : 2,36 m2, centree en ( 1,33 ; 0,04 ; 6,89)  seuil  6,00
epaisseur               : 1,05 m en paroi, 1,30 m au linteau
  paroi la plus mince      station 6, azimut 186°, z 1,31
  collerette la plus mince station 1, azimut 135°, z 1,28
gabarit                 : capsule r=0,45 h=1,85 aux 7 stations
aucun jour              : 25 rayons verticaux, croisements pairs et >= 2
sol : -0,416 seuil · 0,185 salle · 0,386 niche · 0,510 voisin
```

`gltf_inspect` : **VALIDE** — 2 nœuds, 21 324 triangles,
15,52 × 11,89 × 15,76 m.

### Un chiffre à ne pas mal lire

`tools/measure_module_relief.py` sur le `.glb` livré rend une très grande
plage plane. C'est le **dessous du socle enterré**, une dalle que personne ne
verra jamais, et le fichier contient aussi la coque de collision. Le contrôle
côté Blender écarte ce qui est sous le terrain et ce qui appartient à la
cavité : il rend 3,45 m². Les deux chiffres sont justes ; un seul répond à la
question posée. L'outil porte cet avertissement et un filtre `--maillage=`.

---

## Deux caméras de preuve étaient fausses, et la baseline le prouve

C'est le défaut le plus embarrassant de cette tranche, parce qu'il ne vient
pas du maillage.

**Le « gros plan du seuil » ne cadrait pas le seuil.** À `fov` 28° depuis
(−101,9 ; 4,65 ; 7,6) visant (−106,15 ; 4,70 ; 3,35), la visée traverse la
bouche et cadre l'intérieur de la galerie, un piédroit occupant la moitié
droite. J'ai d'abord cru à un défaut de la reconstruction — jusqu'à ouvrir la
**capture R2a-3.1 à la même caméra** : la même masse grise occupe la même
moitié droite, sur un maillage entièrement différent. Le défaut est dans le
cadrage, pas dans la roche.

**La vue « trois masses » regardait le dos.** Elle était prise depuis
(−95 ; 6,2 ; −11,5), c'est-à-dire du côté opposé à l'approche du joueur, qui
vient de (+X, +Z). La consigne dit « trois masses depuis l'approche réelle ».

Correction, et ce qui est conservé :

| plan | caméra | rôle |
|---|---|---|
| `t3_02_approche_joueur` | inchangée | approche joueur ; côté droit de l'A/B |
| `t3_03_gros_plan_seuil` | **inchangée**, bien que fausse | côté droit de l'A/B — un A/B n'a de sens qu'à caméra identique |
| `t3_04_seuil_cadre` | nouvelle | le gros plan du seuil réellement demandé |
| `t3_07_trois_masses` | **nouvelle**, azimut d'approche | les trois masses depuis l'approche réelle |
| `t3_08_flanc_arriere` | ancienne caméra « trois masses » | conservée pour information, nommée pour ce qu'elle est |

---

## Silhouettes — dans l'azimut réel d'approche

L'azimut n'est pas choisi : il est **dérivé** de la caméra d'approche.
`capture_silhouette` place la caméra en
`centre + Vector3(cos a, 0, sin a) · d`. La caméra d'approche est à
(−100 ; 3,42 ; 12) pour un sujet visé en (−106 ; 4,6 ; 3,6), soit un décalage
de (+6 ; · ; +8,4) — donc `a = atan2(8,4 ; 6) ≈ 55°`. La seconde vue est à
100°, soit 45° de plus : le trois-quarts demandé.

Les deux images sont bimodales par construction — l'outil refuse d'écrire une
image qui ne l'est pas (0,000 % hors bandes sur les deux) — et la jupe
enterrée est écartée par `--clip-below=3.0`, ce qui retire 2,28 m de masse
enterrée du cadre ; sans quoi on jugerait un bloc rectangulaire qui n'existe
pas pour le joueur. Emprise cadrée : 21,04 × 9,61 × 21,04 m, sujet 15,5 % et
14,8 % de l'image.

### « Trois masses larges et asymétriques » : la mesure, pas l'impression

`tools/measure_silhouette_masses.py` (nouveau) lit le profil supérieur de la
silhouette et retient les sommets par **proéminence topographique** — la
hauteur d'un sommet au-dessus du plus haut des deux cols qui l'encadrent. Une
marche d'escalier a une proéminence nulle et ne peut donc pas être comptée.
L'échelle est refaite depuis le manifeste avec l'arithmétique exacte de l'outil
de capture : **0,0280 m/pixel**.

Le seuil d'entaille n'est pas un réglage à choisir après coup ; le balayage est
donné en entier :

| entaille | vue 55° (approche) | vue 100° (trois-quarts) |
|---|---|---|
| 0,60 m | **4 masses**, largeurs 1,07 · 1,12 · 1,12 · 1,26 m, **cv 0,06** | 4 masses, 1,07 à 1,54 m, cv 0,15 |
| 1,50 m | 3 masses, moyenne 2,23 m, cv 0,39 | 2 masses, moyenne 3,97 m, cv 0,09 |
| 3,00 m | 1 masse, 8,50 m | 1 masse, 3,95 m |

Ce que ces chiffres disent, sans interprétation : à l'entaille la plus fine, la
formation présente **quatre sommets de largeur pratiquement identique** — un
coefficient de variation de 0,06 signifie moins de 7 % d'écart entre eux. La
consigne demandait « trois masses majeures **larges et asymétriques** » ;
l'asymétrie de largeur n'y est pas à cette échelle de lecture. À 1,50 m
d'entaille la vue d'approche rend 3 masses avec cv 0,39, ce qui est la lecture
la plus proche de la consigne, et à 3,00 m tout se fond en une seule.

La cause est mécanique et nommée dans le code : la formation est bâtie de
`template-detail` **seul** — le seul module du kit qui soit un rocher — à des
échelles de 0,55 à 1,55. Ce module fait 2,64 × 2,81 × 4,35 m, donc un rapport
hauteur/largeur d'environ 1,6 : posés côte à côte, ils donnent une cadence
verticale de largeur constante. Les six autres modules, qui auraient apporté
d'autres proportions, ont été écartés sur mesure (plage plane, ou impossibilité
de les refermer).

Le levier existe et n'a **pas** été actionné, faute d'être dans le périmètre de
ce point de contrôle : grouper les roches majeures en trois amas d'emprises
franchement inégales, et élargir la bande d'échelles par rang au lieu de la
garder homogène. C'est une décision de composition, elle appartient au lead.

---

## Masses jaunes — identifiées, non corrigées

Dossier séparé : `../masses_jaunes/MASSES_JAUNES.md`, avec les six passes de
masquage à caméra identique et le manifeste.

Ce sont des `Flower_4_Group` de la végétation cellulaire **V2.2**, cellules
`veg_c4r8` et `veg_c4r7`, hautes de 2,14 m et 2,10 m à l'écran. Ce ne sont pas
les fougères du lieu, que j'avais accusées au tour précédent et qui font 15 à
18 pixels.

La cause est un invariant violé, mesurable : `Flower_4_Group` fait 2,487 m en
natif, la bible §3 borne les fleurs à 0,18–0,55 m, et
`scripts/world/kit_scale.gd` existe précisément pour ça — le bâtisseur de
végétation V2 ne l'appelle pas.

**Je n'y ai pas touché** : c'est V2.2, et le modifier serait une propagation.
Le correctif tient en un appel dans `_model_mesh()`, il affecterait toute la
vallée, et la décision revient au lead.

Aucun déplacement de la géométrie du lieu ne peut les sortir du cadre : elles
sont à 6,86 m et 10,07 m de l'**objectif**, pas du sujet, et occupent l'écran
par cette proximité-là. Elles sont toujours présentes sur les captures de
cette tranche, et c'est voulu.

---

## Défauts d'outillage corrigés à la source

Deux outils produisaient des artefacts **plausibles et faux** — la famille de
défauts la plus coûteuse, parce que rien dans l'image ne les crie.

* `compose_ab_montages` acceptait quatre champs et stampait alors « AVANT —
  V2.1 whitebox » / « APRÈS — V2.2R » quelles que soient les images. Il exige
  désormais les six, et les clés de manifeste disent le **côté**, le jalon
  étant une valeur à côté du chemin qu'il décrit ;
* `capture_poi_batch` rendait la géométrie **du cache d'import**. Mesuré le
  2026-08-15 : GLB réexporté à 16:11, cache daté de 10:52, capture identique
  au pixel près à la tranche précédente, code retour 0 et manifeste correct.
  Un garde-fou compare désormais le `source_md5` inscrit par Godot au MD5 réel
  du fichier — le critère de Godot lui-même, pas l'horloge : un premier jet
  fondé sur les dates rougissait à tort sur deux assets dont seul le mtime
  avait bougé, et un garde-fou qui rougit à tort finit désactivé.

---

## Ce que je ne prétends pas

* Aucun verdict artistique : les images sont livrées, le jugement appartient
  au lead.
* L'intérieur final et la niche finale **ne sont pas construits** — la
  consigne était de ne pas y toucher.
* La plage plane « toutes faces confondues » compte la voûte de la galerie.
  L'intérieur relève de son propre jalon.
* `validate_fast.sh` n'a pas été lancé et les 38 captures n'ont pas été
  reprises : la consigne les excluait de ce point de contrôle.
* Aucun chiffre de ce document n'est une mesure de performance : llvmpipe
  rend en logiciel.
