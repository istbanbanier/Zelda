# R2a-3.5.5 — agent A, étape A1 : où est l'argmin d'épaisseur, et pourquoi

**Type de document : HISTORIQUE.** Journal daté d'une mesure. Il ne fait
autorité sur rien ; les instruments qu'il cite, si.

| | |
|---|---|
| géométrie mesurée | `assets/environment/caves/SM_WaterfallCave.glb` |
| sha256 | `c184c8dc0c0e754a61624e1d3542a8b70fa496334366a17889bb4c41ade028ed` |
| octets | 1 490 320 |
| maillage | `SM_WaterfallCave` **nommément** — `COL_WaterfallCave`, le tube plein qui bouche la galerie, est exclu |
| instrument | `tools/cave_argmin_localiser.py` (écrit pour cette mesure) |
| journaux | `localiser_c184c8dc.log` · `marge_c184c8dc.log` · `profil_module_R.log` · `simulation_azimuts.log` |

Aucun Blender n'a tourné. Le GLB de référence était déjà au tronc du
worktree ; tout ce qui suit se mesure hors moteur.

---

## 0. Le résultat en une ligne

**La roche manque à la VERTICALE (97,1 %), l'argmin est DANS l'emprise
longitudinale de la calotte, aucune étape de chaîne n'a rien raboté, et la
cause est que `CALOTTE_COUVERTURE_M` est calculée sur la HAUTEUR DE BOÎTE
d'un module qui ne remplit pas sa boîte.**

Deux hypothèses ont été réfutées par la mesure, et une troisième — non
envisagée au départ — est établie.

---

## 1. La direction — c'est elle qui commande

| | |
|---|---:|
| argmin (modèle) | `(1,036 ; 5,173 ; 2,316)`, face intérieure 19341 |
| argmin (Godot) | `(1,036 ; 2,316 ; −5,173)` |
| lecture | **0,6613 m** |
| borne garantie (`h = 0,10`) | 0,5613 m |
| point extérieur le plus proche | `(0,885 ; 5,221 ; 2,958)`, face 1589 |
| vecteur argmin → extérieur | `(−0,151 ; +0,049 ; +0,642)` |
| unitaire | `(−0,228 ; +0,074 ; +0,971)` |
| **part verticale** | **97,1 %** — 13,9° du zénith |
| part horizontale | 24,0 %, dont +Y (nord) 7,4 % |

**C'est un défaut de COUVERTURE, pas d'emprise latérale.** La surface
extérieure du massif est à `z = 2,958` juste au-dessus d'un point de paroi
à `z = 2,316`. Il manque de la roche **au-dessus**, presque exactement à
l'aplomb.

Conséquence directe pour le correctif : épaissir vers `+Y` n'aurait servi à
rien. C'est bien la voie que je proposais en second recours ; la mesure
l'écarte.

---

## 2. La projection — l'argmin n'est PAS au-delà de la fin du chemin

Hypothèse à réfuter : « `ay = 5,17` contre une dernière station à `ay = 3,17`,
donc le point est deux mètres au-delà du chemin ». **Faux.**

| | |
|---|---:|
| segment le plus proche | stations **4 → 5** |
| paramètre local `t` | 0,9124 — **libre**, non écrêté (`t_libre = 0,9124`) |
| indice de station `u` | 4,9124 |
| **paramètre cumulé `s`** | **+3,8413 m** depuis le seuil |
| pied de projection | `(2,550 ; 2,540)` |
| distance à la courbe | **3,0370 m** en (x,y) — et la même en 3D |
| côté | `−3,037` → joue **GAUCHE / NORD** |
| pied sur une extrémité de polyligne ? | **non** — intérieur du segment |

Le pied tombe à l'intérieur d'un segment **interne**. `station_de_cavite`
n'a rien écrêté, et le drapeau d'écrêtage est publié à chaque conversion.

Les deux mètres d'écart en `ay` sont **intégralement latéraux** : la normale
au chemin y est à 86,7 % alignée sur `+Y`, donc un déport de 3,04 m sur la
joue nord déplace le point de 2,63 m en `ay` sans avancer d'un pas le long
de la galerie. C'est la propriété que `rochers_calotte_nord()` documente
déjà — `hw · gauche` vaut jusqu'à 4,23 m et « la normale y est à ~85 %
alignée avec −Y ».

### L'emprise de la calotte, convertie en longueur d'arc

Jamais comparée à un `ay`. Les deux bornes sont passées par la **même**
intégration que l'argmin :

| | indice de station | longueur d'arc `s` |
|---|---:|---:|
| `CALOTTE_U0` | 3,50 | **+2,519 m** |
| `CALOTTE_U1` | 7,20 | **+4,880 m** |
| argmin | 4,9124 | **+3,841 m** |

**L'argmin est DEDANS**, avec 1,32 m de marge amont et 1,04 m aval. Aucune
des deux bornes n'a été écrêtée. **L'emprise longitudinale n'est pas en
cause.**

Table complète du chemin, pour que la conversion soit rejouable :

| `u` | `ax` | `ay` | `s` |
|---:|---:|---:|---:|
| 0 | 0,000 | −1,150 | −1,150 |
| 1 | 0,000 | 0,000 | **0,000** (seuil, origine) |
| 2 | 0,220 | 1,050 | +1,073 |
| 3 | 1,000 | 1,620 | +2,039 |
| 4 | 1,820 | 2,120 | +2,999 |
| 5 | 2,620 | 2,580 | +3,922 |
| 6 | 3,100 | 2,880 | +4,488 |
| 7 | 3,400 | 3,060 | +4,838 |
| 8 | 3,580 | 3,170 | +5,049 |

---

## 3. Le générateur responsable — un azimut jamais posé

Le point de paroi analytique le plus proche de l'argmin, calculé par le
**même** code que `rochers_calotte_nord()` (mêmes `hw`, `gauche`, `w` majoré,
poussée d'alcôve, linteau incliné) :

| | |
|---|---:|
| azimut `θ` | **126,50°** |
| point de paroi | `(1,017 ; 5,205 ; 2,426)` |
| écart au point mesuré | **0,1160 m** |
| déport latéral `n` | −3,074 m |
| `z` de paroi | 2,426 m |

0,116 m d'écart : **l'argmin est bien sur la paroi intérieure de la
cavité**. C'est de la coque, pas du massif isolé — et c'est bien
`rochers_calotte_nord()` qui a charge de la couvrir.

Or les azimuts **réellement posés** sont `100 · 119 · 138 · 157 · 176`.
`126,50°` tombe entre 119 et 138, à 7,50° du premier. Pas d'azimut : **19°**.
À `|n| = 3,07 m`, la corde entre deux roches vaut **1,015 m**.

C'est le défaut que le générateur a déjà mesuré et corrigé **sur la gaine** :

> « à 3,05 m de rayon, un pas de 30° laisse 1,58 m de corde entre deux
> roches, et une roche du kit ne remplit pas sa boîte. Neuf azimuts ramènent
> le pas à 23°, donc la corde à 1,20 m. »

La correction n'a jamais été transposée à la calotte, restée à
`CALOTTE_AZIMUTS = 5`.

---

## 4. L'étape — AUCUNE. La matière n'a jamais été posée.

C'est la réfutation la plus utile de cette mesure.

Le module du kit est chargé et recentré exactement comme le fait
`charger_module()` (« origine au centre en plan, au bas en hauteur »), puis
posé comme le fait `poser_rocher()` (échelle, `Rz@Rx@Ry`, translation). On
lit alors le sommet de chaque roche **sur la verticale de l'argmin** :

| roche | sommet à l'aplomb |
|---|---:|
| `CalotteNord_2_1` | **2,633 m** |
| `CalotteNord_3_2` | 2,398 m |
| `CalotteNord_3_1` | 2,385 m |
| `CalotteNord_2_2` | 2,051 m |
| `CalotteNord_1_2` | 1,384 m |
| (8 roches traversées sur 23 posées) | |

| | |
|---|---:|
| sommet le plus haut apporté par la calotte | **2,633 m** |
| surface extérieure mesurée sur le GLB | 2,958 m |
| argmin | 2,316 m |
| **épaisseur que la SOURCE promet à la verticale** | **0,317 m** |
| épaisseur mesurée sur le GLB (euclidienne) | 0,6613 m |

La source promet **moins** que ce que le GLB porte. Aucune étape n'a donc
retiré de matière ici — le remaillage et l'union en ont plutôt ajouté un
peu. **« Le booléen creuse » et « la décimation rabote » sont tous deux
écartés, sans avoir eu besoin de Blender.**

> **Écart de 2 mm entre deux tables de ce document.** `localiser_c184c8dc.log`
> travaille sur l'argmin en pleine précision et rend `2,633 / 0,317` ;
> `simulation_azimuts.log` prend le point arrondi `(1,036 ; 5,173 ; 2,316)`
> et rend `2,631 / 0,315`. C'est l'arrondi de publication, rien d'autre — je
> le signale plutôt que d'uniformiser en silence.

### Pourquoi 2,633 et non 4,00

Le générateur croit poser jusqu'à `haut = min(z_paroi + 1,60 ; 4,00)`. Pour
`CalotteNord_2_1` : `base = 1,607`, hauteur de boîte `2,393` → **sommet de
boîte à 4,000 m**. La roche réelle n'y monte qu'à 2,633.

Profil mesuré du module `template-detail`, à l'échelle de la calotte
(hauteur de boîte 2,393 m) :

| distance au centre | hauteur médiane sur 16 azimuts | min | max |
|---:|---:|---:|---:|
| 0,0 m | 2,392 | 2,392 | 2,392 |
| 0,2 m | 2,392 | 2,346 | 2,392 |
| 0,4 m | 2,312 | 1,524 | 2,353 |
| **0,6 m** | **1,050** | 0,730 | 1,797 |
| 0,8 m | 0,949 | 0,186 | 1,794 |
| 1,0 m | 0,714 | 0,000 | 1,727 |
| 1,2 m | 0,230 | 0,000 | 0,697 |

**C'est un pic.** Il tient sa hauteur de boîte sur 0,4 m, puis s'effondre de
56 % en 0,2 m de plus. L'argmin est à **0,560 m** du centre de
`CalotteNord_2_1` — en pleine chute.

> **La cause racine, en une phrase : `CALOTTE_COUVERTURE_M = 1,60` est une
> promesse exprimée en hauteur de BOÎTE, tenue par une roche qui ne remplit
> pas sa boîte, et le pas d'azimut de 19° garantit qu'un point de paroi sur
> deux tombe là où la roche n'est plus.**

---

## 5. La butée `CALOTTE_PLAFOND_M` agit, et elle ne le dit pas

Le commentaire du générateur la présente comme une simple butée de sécurité
— « ce n'est PAS le contrôle principal ». Mesuré :

**7 poses sur 23 sont écrêtées par le plafond de 4,00 m.**

| azimut à `u = 4,9124` | `z_paroi` | couverture obtenue | visée |
|---:|---:|---:|---:|
| 100,0° | 2,902 | **1,098** | 1,60 |
| 119,0° | 2,606 | **1,394** | 1,60 |
| 126,5° (argmin) | 2,426 | 1,574 | 1,60 |
| 138,0° | 2,082 | 1,600 | 1,60 |
| 157,0° | 1,330 | 1,600 | 1,60 |
| 176,0° | 0,342 | 1,600 | 1,60 |

Ce n'est pas la cause du défaut mesuré — 1,098 m resterait au-dessus de
0,80 m. Mais une butée qui mord un tiers des poses sans le dire est
exactement la famille de défaut que cette série débusque, et elle devient
contraignante dès qu'on densifie. **À tracer.**

---

## 6. La marge disponible — le conflit redouté n'existe pas

`tools/cave_fix_marge.py` sur la même géométrie. Rappel de sa définition :
`permis` = le plus petit profil de silhouette aux trois azimuts, moins un
retrait de sécurité de 0,35 m. Toute matière sous `permis` laisse le profil
de silhouette — donc `controle_amas` — rigoureusement inchangé.

| colonne | plafond cavité | sommet actuel | permis | **jeu vertical** |
|---|---:|---:|---:|---:|
| `(+1,00 ; 5,20)` | 2,30 | 3,11 | **4,39** | +1,28 |
| `(+0,80 ; 5,20)` | 2,09 | 2,95 | **4,03** | +1,08 |
| `(+1,00 ; 5,00)` | 2,32 | 3,17 | 4,62 | +1,45 |
| `(+1,00 ; 5,40)` | 2,19 | 3,52 | 3,92 | +0,40 |

(Le « jeu » de la table de l'outil vaut `permis − exigé` ; la colonne
ci-dessus donne `permis − sommet actuel`, c'est-à-dire la roche qu'on peut
encore ajouter.)

**Colonnes sans solution conforme : 0.**

Autour de l'argmin il reste **1,08 à 1,28 m** de hauteur disponible avant le
profil de silhouette. Pour atteindre la cible de 0,90 m euclidien, il faut
monter la surface de `2,958` à environ `2,316 + 0,93 = 3,25 m`, soit
**+0,29 m** — sur 1,08 m disponibles au pire. **Le conflit entre le seuil
d'épaisseur et la composition n'a pas lieu ici.**

---

## 7. Simulation du correctif — mesurée, **non appliquée**

Prédiction chiffrée en mémoire, sans toucher au générateur ni à un fichier :
on rejoue `rochers_calotte_nord()` avec un autre nombre d'azimuts et on
relit le sommet à l'aplomb de l'argmin. Rien n'est écrit, rien n'est
committé, aucun seuil n'est touché.

| `CALOTTE_AZIMUTS` | pas | roches | traversées | sommet à l'aplomb | épaisseur verticale |
|---:|---:|---:|---:|---:|---:|
| **5** (actuel) | 19,00° | 23 | 8 | 2,631 | **0,315 m** |
| 7 | 12,67° | 33 | 12 | 4,001 | **1,685 m** |
| 9 | 9,50° | 43 | 15 | 3,943 | 1,627 m |
| 11 | 7,60° | 53 | 21 | 3,991 | 1,675 m |
| 13 | 6,33° | 63 | 23 | 4,002 | 1,686 m |

Le saut se fait **entre 5 et 7**, et il est brutal : +1,37 m. Au-delà, plus
rien ne progresse — la roche bute alors sur `CALOTTE_PLAFOND_M = 4,00`, ce
qui confirme au passage que la butée gouverne dès qu'on densifie.

Deux réserves, l'une et l'autre à trancher par le portail, pas par moi :

1. **Un sommet à 4,00 dépasse le `permis` des deux colonnes les plus
   contraintes** — 3,92 à `(+1,00 ; 5,40)` et 3,87 à `(+0,80 ; 5,40)`. Il ne
   casse pas le profil pour autant : `permis` inclut déjà 0,35 m de retrait
   de sécurité, donc le dépassement mange la marge sans franchir la
   silhouette. `controle_amas` reste seul juge.
2. **Abaisser le plafond n'est pas gratuit.** À `θ = 100°` la paroi est
   quasi zénithale et sa couverture verticale *est* son épaisseur : un
   plafond sous `2,902 + 0,93 = 3,83 m` y créerait un nouveau défaut là où
   il n'y en a pas. La fenêtre utile est donc étroite — `[3,83 ; 3,87]` — et
   c'est une raison de ne PAS y toucher tant que le portail n'a pas parlé.

---

## 8. Ce qui reste NON VÉRIFIÉ

- **La correction elle-même.** Rien n'a encore été modifié. Tout ce qui
  précède décrit `c184c8dc` tel quel.
- **L'attribution d'étape sous Blender.** Elle est *déduite* du fait que la
  source promet moins que le GLB ne porte (0,315 contre 0,661). C'est un
  argument solide — une chaîne ne peut pas retirer de la matière et en
  laisser davantage — mais ce n'est pas la mesure directe après chacune des
  cinq étapes. Si le lead la veut, elle coûte un passage Blender.
- **Ce qui apporte réellement les 2,958 m.** La calotte n'en pose que 2,631.
  Le complément vient de l'enveloppe, de la gaine ou du gonflement du
  remaillage voxel ; je ne l'ai pas départagé, et ce n'est pas nécessaire
  pour corriger.
- **L'effet d'une densification sur `controle_amas`.** La marge dit qu'il
  *peut* passer. Seul le portail le dira.
- **Le second argmin.** 2 216 échantillons sont sous 0,80 m en lecture.
  Corriger celui-ci découvrira le suivant ; leur distribution n'est pas
  cartographiée.
- **Tout jugement visuel.** Hors de mon mandat et hors de portée de tout
  instrument.
