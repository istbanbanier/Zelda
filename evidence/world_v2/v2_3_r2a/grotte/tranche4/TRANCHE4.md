# Grotte — R2a-3.4 : composition extérieure en trois amas

Ce document ne contient **aucun verdict artistique**. Il livre la cause mesurée
du rejet R2a-3.3, la construction qui la corrige, les chiffres avant/après et ce
qui reste ouvert. Le jugement visuel appartient au lead.

| rôle | commit |
|---|---|
| source géométrique, `.blend` et `.glb` | `24bfe6b` |
| arbre utilisé pour les captures | `24bfe6b` (`repo_dirty: false`) |

---

## Le rejet, et sa cause mécanique

> « les silhouettes 55° et 100° évoquent une forteresse crénelée ; les masses
> principales lisent comme des tours rocheuses répétées ; l'asymétrie de largeur
> recherchée n'existe pas »

Mesure établie en R2a-3.3 : quatre sommets de **1,07 · 1,12 · 1,12 · 1,26 m**,
coefficient de variation **0,06**.

### Ce que j'ai mesuré, et qui ferme le dossier

La chaîne modèle → Godot (`export_yup`) → `LACET_DEG = 45` → caméra orthogonale
de `capture_silhouette.gd` donne, à l'azimut *a* :

```
x_ecran = 0,7071 · [ X·(sin a + cos a) + Y·(cos a − sin a) ]
```

soit `0,9847·X − 0,1737·Y` à 55°. **À l'azimut d'approche, la silhouette lit
presque exactement le X du modèle.** En projetant les 98 roches posées sur
200 colonnes et en cherchant qui porte la crête :

| | |
|---|---:|
| colonnes dont la crête est portée par **une seule** roche (2ᵉ à plus de 0,45 m dessous) | **81 %** |
| écart médian au second porteur | **1,03 m** |
| porteurs du faîte de chacune des trois masses | **1 · 1 · 1** |

Et la mesure qui rend le reste inévitable, prise sur les 600 sommets du module :
le faîte sculpté de `template-detail` fait **0,93 m de large à 0,60 m sous son
sommet, quel que soit l'axe de projection** (vérifié à 0°, 45°, 90°).

> Tant qu'une roche porte seule un sommet, la largeur de ce sommet vaut
> 0,93 × son échelle. Les échelles allaient de 1,10 à 1,35 : les quatre sommets
> **ne pouvaient pas** différer de plus de 7 %. Le cv 0,06 était arithmétique.
> Aucune repose ne l'aurait changé.

---

## La construction : chaque faîte porté par plusieurs volumes

Un faîte d'amas est désormais l'union de plusieurs roches dont les sommets sont
à la même cote et dont les plateaux se **chevauchent en x écran**. Le pas d'une
rangée se mesure donc en x écran, pas en mètres modèle, et doit rester sous la
largeur de faîte du module.

Le levier ne déplace **aucune borne** : `poser_rocher()` acceptait déjà `ech` en
triplet et vérifie chaque composante contre `[0,55 ; 1,55]`. Un triplet sort du
rapport hauteur/largeur unique du module (1,65) sans ajouter de module au kit.
L'anisotropie est bornée à 2,0, contrôle nouveau dans `poser_rocher()`.

### Deux pièges mesurés, écrits dans le fichier parce qu'ils se reprennent

**1. Les inclinaisons d'une même rangée doivent être de même signe.** Premier
jet : `tangage` et `roulis` alternés ±6°, pour la variété. Mesuré — un roulis de
±6° sur une roche de 5,4 m déplace son sommet de ±0,28 m ; deux voisines
inclinées en sens opposés voient l'écart entre leurs plateaux **doubler**, et un
creux de **1,05 m** s'ouvre là où le calcul en promettait 0,15. C'est ce creux
qui coupait la dominante en deux masses.

**2. Une seule direction de rangée se projette identiquement aux deux azimuts.**

| direction | facteur à 55° | facteur à 100° | écart |
|---|---:|---:|---:|
| (1 ; 0,00) | 0,985 | 0,574 | 42 % |
| (1 ; −0,30) | 0,993 | 0,785 | 21 % |
| **(1 ; −0,64)** | **0,924** | **0,924** | **0 %** |
| (1 ; −0,90) | 0,848 | 0,974 | 13 % |

L'épaule courait d'abord sur (1 ; −0,94) : régler la vue d'approche déréglait le
trois-quarts, et inversement. **J'ai perdu quatre passes là-dessus avant de
poser l'équation.** La dominante et le contrefort sont sur la direction
invariante ; l'épaule reste légèrement en dehors, ce qui l'élargit au
trois-quarts sans casser son col — mettre les trois rangées sur la même droite
ferait de la formation un mur de 18 m de long et 4 m de large.

### Le fond plat, et pourquoi il a imposé d'enfoncer les roches

À `ez = 0,80` les roches de faîte étaient basses et larges — bon pour le
plateau — mais leur **fond plat** se retrouvait à 3,82 m, au-dessus du flanc de
leur socle, et pendait en surplomb. `controle_plage_plane` a rendu
**12,05 m² centrés en (−5,52 ; 5,98 ; 3,77)** pour un seuil de 12,00 : refus.
À `ez = 1,25` le fond descend à 1,87 m, sous le flanc du socle (2,17 m), et la
mesure retombe à **4,18 m²**.

---

## Avant / après, aux deux azimuts

Mesuré sur les volumes sources par `controle_amas()`, à l'entaille de lecture
0,90 m :

| | emprises (m) | porteurs du faîte | proéminences (m) |
|---|---|---|---|
| avant 55° | 1,14 · 1,07 · 1,14 | **1 · 1 · 1** | 1,98 / 2,88 / 10,39 |
| après 55° | **5,66 · 3,58 · 2,17** | **8 · 5 · 4** | 1,67 / 7,57 / 2,53 |
| après 100° | **6,42 · 3,64 · 2,22** | **8 · 5 · 4** | 1,51 / 7,53 / 2,47 |

Rapports d'emprise : 1,58 et 1,65 à 55° (max/min 2,62) ; 1,76 et 1,64 à 100°
(max/min 2,89). Les deux cols entaillent de 1,67 et 2,53 m à 55° — rapport 1,51,
écart 0,86 m ; de 1,51 et 2,47 m à 100°.

Faîte dominant décentré de **14,2 %** (55°) et **13,0 %** (100°) du milieu de
l'emprise, et il n'est plus au-dessus de la bouche.

**Trois masses aux deux azimuts ET aux quatre entailles** (0,60 · 0,90 · 1,20 ·
1,50 m) : la lecture ne tient pas au choix d'un seuil.

---

## La silhouette rendue confirme la prédiction à 5 cm près

`silhouette_grotte_t4_055.png` et `_100.png`, capturées depuis le commit
`24bfe6b` avec `repo_dirty: false`, après un import Godot complet du worktree
(`godot --headless --path . --import`, sans lequel la capture aurait rendu la
géométrie du cache et non celle qui vient d'être exportée). Renderer
`forward_plus`, adaptateur llvmpipe, projection orthogonale, 900 × 1200,
`--clip-below=3.0`, 0,000 % hors bandes sur les deux vues, 1841 instances de
décor masquées.

Mesuré par `tools/measure_silhouette_masses.py` à l'entaille 0,90 m :

| | prédit sur les volumes sources | mesuré sur le PNG |
|---|---|---|
| 55° | 5,66 · 3,58 · 2,17 m | **5,66 · 3,62 · 2,22 m** |
| 100° | 6,42 · 3,64 · 2,22 m | **6,46 · 3,67 · 2,31 m** |

L'accord est à 5 cm. C'est ce qui justifie de mesurer la composition dans le
générateur plutôt qu'après export : le chiffre y est le même, et il arrive
quarante minutes plus tôt.

Balayage complet des entailles sur les images rendues :

| entaille | 55° | 100° |
|---|---|---|
| 0,60 m | 3 masses, cv 0,37 | 3 masses, cv 0,42 |
| 0,90 m | 3 masses, cv 0,37 | 3 masses, cv 0,42 |
| 1,20 m | 3 masses, cv 0,37 | 3 masses, cv 0,41 |
| 1,50 m | 3 masses, cv 0,33 | 3 masses, cv 0,34 |
| 3,00 m | 1 masse | 1 masse |

Pour mémoire, la formation rejetée donnait 4 masses de cv **0,06** à 0,60 m.

### Le trou blanc au centre des deux images n'est pas nouveau

Il apparaît **au même endroit et à la même taille** sur
`tranche3/silhouette_grotte_t3_055.png`, c'est-à-dire sur un maillage
entièrement différent. C'est la bouche vue à travers le culling des faces
arrière par l'outil de silhouette, pas un jour dans la roche —
`controle_aucun_jour` reste vert (25 rayons verticaux, croisements pairs et ≥ 2)
et la coque est fermée (0 arête de bord, 0 non-manifold).

---

## Le contrôle, et ce qu'il ne prétend pas

`controle_amas()` mesure la composition **sur les volumes sources**, en secondes,
là où la faute est encore réparable — au lieu d'un PNG capturé trois quarts
d'heure plus tard après export. Il calcule l'enveloppe supérieure **exacte** par
intersection des triangles avec le plan de chaque colonne, et non par
échantillonnage de sommets : un module réparé porte 90 sommets, une colonne de
8 cm n'en contient souvent aucun, et le profil inventerait des encoches
inexistantes — mesuré, la version par sommets rendait 5 masses là où la version
exacte en rend 3.

> **Ses seuils sont des planchers de non-régression, fixés APRÈS avoir mesuré la
> composition obtenue.** Ils garantissent qu'une passe suivante ne ramènera pas
> le créneau. Ils ne prononcent aucun gate visuel, et le compteur de proéminences
> reste une télémétrie.

`tools/measure_silhouette_masses.py` gagne au même titre un drapeau **optionnel**
`--exige=masses,largeur_min,emprise_min,emprise_max`. Sa sortie par défaut est
inchangée **au caractère près** (vérifié par `diff` contre la version de `HEAD`
sur le manifeste de la tranche 3).

### Le contrôle est rouge sur la formation rejetée

```
$ python3 tools/measure_silhouette_masses.py <manifeste tranche3> \
      --entaille=0.90 --exige=3,2.40,12.0,19.0
ECHEC : silhouette_grotte_t3_055.png : une masse de 1.15 m de large, 2.40 m exiges
ECHEC : silhouette_grotte_t3_055.png : une masse de 1.35 m de large, 2.40 m exiges
ECHEC : silhouette_grotte_t3_100.png : quatre masses de 1.07 a 1.88 m
RC=1
```

---

## Journal des contrôles du générateur, RC = 0

```
122 roches posees : 63 gaine, 35 majeur, 16 intermediaire, 8 secondaire,
                    plus l'assise enterree
faite par rang    : majeur 9.52, intermediaire 6.87, gaine 6.01, secondaire 2.82
composition       : 3 amas aux deux azimuts et aux quatre entailles
solidarite        : 1070 paires en intersection reelle, aucune roche isolee
remaillage 0,12 m : 1 coque, 0 arete de bord, 0 non-manifold, 985 m3
stratification    : 0 paire croisee, repli maximal 0,0000 m
soustraction      : 1 coque, connexite 1 avant et apres
auto-intersection : 0 paire, repli maximal 0,0000 m (seuil 0,020)
budget            : 20 450 tris dans [12 000 ; 25 000]
plage plane > sol : 4,18 m2, centree en (6,41 ; -0,55 ; 4,65)   seuil 12,00
plage plane facade: 4,18 m2                                     seuil  6,00
epaisseur         : 1,09 m en paroi, 0,61 m au linteau          min 0,80 / 0,60
  paroi la plus mince      station 4, azimut 0deg,   z 1,30
  collerette la plus mince station 1, azimut 154deg, z 1,28
gabarit           : capsule r=0,45 h=1,85 aux 7 stations
aucun jour        : 25 rayons verticaux, croisements pairs et >= 2
sol : -0,413 seuil · 0,185 salle · 0,386 niche · 0,510 voisin
```

`gltf_inspect` : **VALIDE** — 2 nœuds, 21 330 triangles, 17,20 × 12,42 × 15,76 m.

---

## Ce que je signale plutôt que de le laisser passer

**1. L'épaisseur au linteau tombe à 0,61 m pour un seuil de 0,60.** Elle valait
1,30 m en R2a-3.3. Le point est nommé par le contrôle : *station 1, azimut 154°,
z 1,28*, c'est-à-dire le jambage gauche de la bouche, que les roches retirées du
flanc ouest couvraient. **Le critère passe, mais avec 1,7 % de marge.**

J'ai tenté d'y remettre de la matière (une roche de jambage à (−1,90 ; 0,30),
faîte 4,18 m, sous la cote du col donc sans effet sur la crête). Mesuré : **le
minimum n'a pas bougé d'un centimètre** et le budget a gagné 2 triangles. Le
fichier interdit de garder un mécanisme qui ne produit rien — je l'ai retirée
plutôt que de laisser un commentaire qui promette un effet inexistant. Le
correctif appartient à la spécification du seuil de l'agent B, qui rouvre cette
zone au tour suivant ; y empiler de la roche maintenant créerait exactement le
conflit de fusion que j'ai promis d'éviter.

**2. `hauteur_du_sol` sous le seuil : −0,413 m contre −0,416 m publié.** Écart de
3 mm, imputable à la stratification. Les trois autres repères sont **identiques
au millimètre** (0,185 / 0,386 / 0,510), donc `MODELE_SALLE` et `MODELE_NICHE`
restent valides et `waterfall_cave_place.gd` n'est pas touché. L'agent B signale
par ailleurs que le chiffre −0,416 est lui-même suspect (0,38 m d'écart avec le
profil annoncé par le code) : je ne conclus rien là-dessus.

**3. Le « contrefort droit » est plus petit et plus bas, pas plus profond.** La
consigne dit « visuellement en retrait ». Il est plus petit (2,17 m contre 5,66),
plus bas de 2,46 m que la dominante, et séparé d'elle par le plus profond des
deux cols. Sa position en Y est en revanche **vers l'avant**, pas vers
l'arrière : la contrainte de séparation aux deux azimuts l'exige. Je le signale
au lieu de prétendre avoir satisfait le mot.

**4. L'emprise passe de 15,60 à 18,24 m à l'azimut d'approche** (+17 %). Les
roches restent dans l'empreinte de l'assise à l'exception des extrémités, comme
c'était déjà le cas. Aucun appui déclaré (`APPUIS_MODELE`) n'a bougé.

**5. Ce que je n'ai pas fait**, conformément au mandat : aucune capture en
perspective (elles contiennent les fleurs V2.2 et changeront après le correctif
de l'agent A) ; aucun document de continuité modifié ; aucune propagation à un
autre POI ; `validate_fast.sh` non lancé.

**6. `docs/assets/ASSET_MANIFEST.csv`** : seule la ligne `SM_WaterfallCave` est
touchée, et elle reste à 19 colonnes correctement quotées. Les lignes 21, 22,
148, 150 et 157 restent mal formées — c'est ISS-043, préexistant.
