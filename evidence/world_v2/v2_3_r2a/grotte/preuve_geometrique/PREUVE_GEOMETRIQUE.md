# Grotte du Couchant — preuve géométrique de la sonde

Aucun verdict artistique. Ce document répond à une seule question : **la sonde
mesure-t-elle ce qu'elle prétend mesurer ?** Le chiffre qu'elle rend sur la
grotte ne vaut que dans la mesure où cette question a une réponse.

| | |
|---|---|
| arbre mesuré | worktree `preuve`, détaché, HEAD `8d2143c` |
| asset mesuré | `assets/environment/caves/SM_WaterfallCave.glb`, committé à `504ecbe` (R2a-3.4) |
| outils | `tools/probe_cave_openings.py` · `tools/probe_cave_selftest.py` — Python pur, ni Blender, ni Godot, ni GPU, aucun verrou |
| sorties brutes | `probe_r2a35.log` · `probe_r2a35.json` · `selftest.log`, à côté de ce fichier |
| géométrie de production | **non touchée** |

---

## 1. Ce qui était non prouvé, et ce qui l'est maintenant

La revue R2a-3.5 a retenu un défaut technique bloquant : la transformation
monde → modèle du contrôle 3 était `NON VÉRIFIÉ`. Sa validation par
superposition de silhouette avait **échoué** — 52,4 % de concordance sur
`t3_07`, et décaler l'origine de +3 m *améliorait* le score.

Ce dernier point est le vrai constat, et il est plus grave que « l'origine est
peut-être fausse » : **quand éloigner la réponse améliore la note, c'est la note
qui ne mesure rien.** Il ne fallait donc pas mieux superposer. Il fallait
changer d'instrument.

| | avant | maintenant |
|---|---|---|
| origine monde | option de ligne de commande `--origine-monde -106.0,3.50,3.5` | **dérivée** de `world_v2_layout.json` (`v2_site`) et de `waterfall_cave_place.gd` (`SEUIL_LOCAL`, `LACET_DEG`, `EXHAUSSEMENT`) |
| inverse de la transformation | une seule implémentation | **deux** — chaîne de matrices et forme fermée — qui doivent concorder |
| épreuve | superposition photométrique, non concluante | **géométrie synthétique à pose et trous connus** |
| « percée » | un rayon de parité impaire | **un carré de 0,10 m intégralement percé**, mesuré |
| surfaces cartographiées | plancher, fond | plancher, **toit**, deux parois, fond |
| gate | verdict global | **0 percée confirmée** |

---

## 2. La transformation

### 2.1 Elle est dérivée, plus devinée

```
origine = v2_site + (SEUIL_LOCAL.x, terrain + EXHAUSSEMENT, SEUIL_LOCAL.y)
        = (-110, ·, 6) + (4.0, 3.00 + 0.50, -2.5)
        = (-106.000 ; 3.500 ; 3.500),  lacet 45°
```

L'altitude du **lieu** n'intervient pas, et ce n'est pas une approximation. Le
bâtisseur pose le lieu à `height_at(site)`, puis `ground_local_y()` retranche
exactement ce même `global_position.y` :

```
assise    = height_at(seuil) − height_at(site) + EXHAUSSEMENT
y_ouvrage = height_at(site) + assise = height_at(seuil) + EXHAUSSEMENT
```

Il ne reste **qu'une** inconnue documentaire : la hauteur du terrain gelé sous
le seuil (3,00 m, reprise des commentaires d'implantation). Elle est déclarée
`NON VÉRIFIÉ` dans la sortie de la sonde, et le balayage vertical du §2.4 mesure
ce qu'elle change.

### 2.2 Aller-retour : deux implémentations, une tolérance justifiée

`Pose.vers_monde()` est une **chaîne de matrices** (translation · Ry · échange
d'axes), écrite en multipliant des facteurs élémentaires.
`Pose.vers_modele()` est une **forme fermée** écrite à la main. Aucune des deux
n'appelle l'autre — sinon l'aller-retour serait un test qui ne peut pas
échouer.

| | valeur |
|---|---|
| écart mesuré, 14 points et 5 directions | **4,663 × 10⁻¹⁵ m** |
| tolérance `TOLERANCE_ALLER_RETOUR_M` | **1 × 10⁻⁹ m** |

**Pourquoi 10⁻⁹ m, et pas autre chose.** Ce n'est pas un budget d'erreur
géométrique, c'est un plancher de bruit numérique posé au milieu de huit ordres
de grandeur vides :

* **au-dessus du bruit** — les coordonnées valent ~120 m, l'epsilon des
  flottants 64 bits y vaut 1,4 × 10⁻¹⁴ m, la chaîne fait une dizaine
  d'opérations. 10⁻⁹ m est ~5 ordres au-dessus : l'aller-retour ne peut pas
  rougir pour une raison de virgule flottante ;
* **très en dessous de toute faute réelle** — mesuré, pas plaidé : les deux
  mutations ci-dessous produisent **20,000 m** d'écart, soit 2 × 10¹⁰ fois la
  tolérance.

Une tolérance qui laisse 10¹⁰ de marge entre le bruit et la plus petite faute
n'a pas besoin d'être ajustée. Si elle rougit un jour, la transformation est
fausse.

### 2.3 Le test peut échouer — démontré par mutation

| mutation injectée dans la forme fermée | écart de l'aller-retour |
|---|---|
| lacet de signe inversé | **20,000 m** |
| axes Y et Z échangés | **20,000 m** |

Et une vérité de terrain qui n'appartient pas à la sonde :
`waterfall_cave_place.gd` écrit lui-même *« le modèle sort de la bouche vers son
+Z local ; ce lacet l'oriente vers le sud-est monde (0,707 ; 0,707) »*. La
chaîne de matrices rend `(0,7071 ; 0,0000 ; 0,7071)`, écart **1,1 × 10⁻¹⁶**.

### 2.4 Sur la grotte réelle : ce que la mesure borne, et ce qu'elle ne borne pas

Le rayon central de chaque caméra de preuve est transformé en repère modèle, et
l'on mesure la longueur de **vide de galerie** qu'il parcourt avant le premier
triangle. Puis on décale l'origine et l'on regarde si la mesure s'effondre.

Le balayage se fait dans le **repère de la galerie**, et c'est une correction de
méthode née d'une mesure. En axes monde, avec un lacet de 45°, un décalage en
`z` se projette pour moitié *sur l'axe* de la galerie — or glisser l'ouvrage le
long de son propre axe ne sort pas le rayon du tunnel. Premier jet : `dz +2 m`
rendait encore 5,7 m de pénétration et le maximum tombait à `dz +1 m`. On aurait
conclu « mesure plate » alors que la mesure est **aveugle sur cet axe par
construction**.

Pénétration maximale, en mètres (référence à l'origine dérivée : **10,20 m**) :

| axe | −3,0 | −2,0 | −1,0 | −0,5 | **0** | +0,5 | +1,0 | +2,0 | +3,0 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| transverse | 0,00 | **0,00** | 7,05 | 10,20 | **10,20** | 9,80 | 7,20 | **0,00** | 0,00 |
| vertical | 0,00 | **0,00** | 7,15 | 9,10 | **10,20** | 10,25 | 10,25 | 4,80 | 0,40 |
| axial | 9,80 | 10,05 | 10,10 | 10,15 | **10,20** | 9,05 | 6,60 | 6,00 | 5,30 |

**Ce que cela établit** : un écart de 2,0 m est **réfuté** en transverse comme en
vertical — la pénétration tombe à zéro. C'est exactement l'hypothèse qu'hier la
superposition *préférait*.

**Ce que cela n'établit pas** : l'axe **axial** n'est pas contraint, et la sonde
l'écrit au lieu de le taire. Un décalage de 3 m le long de la galerie laisse
encore 9,80 m de pénétration. Cette mesure borne la pose ; elle ne la fixe pas
au centimètre.

La preuve **fine** de la transformation n'est pas là. Elle est au §3.3.

---

## 3. Le cas synthétique — une réponse connue avant la mesure

`tools/probe_cave_selftest.py` fabrique des tunnels rectangulaires dont on
connaît exactement la pose et exactement les trous, les écrit en GLB, et les
soumet **aux mêmes fonctions** que la grotte de production.

### 3.1 Discrimination : six tunnels, deux verdicts

| tunnel | trou | rayons suspects | confirmées (contrôle 2) | confirmées (contrôle 4) | verdict |
|---|---:|---:|---:|---:|---|
| scellé | — | 0 | 0 | 0 | **PASS** |
| toit percé | 0,60 m | 275 | 42 | 1 (`toit`) | FAIL |
| plancher percé | 0,50 m | 159 | 37 | 1 (`plancher`) | FAIL |
| paroi percée | 0,40 m | 80 | 31 | 1 (`paroi_plus_x`) | FAIL |
| fond percé | 0,70 m | 134 | 21 | 1 (`fond`) | FAIL |
| trou d'épingle | 0,04 m | 4 | 0 | 0 | **PASS** |

Deux verts et quatre rouges. Un contrôle rouge partout serait câblé sur
l'échec ; un contrôle vert partout ne mesurerait rien. Les deux sont des tests
qui ne peuvent pas échouer.

### 3.2 Localisation et seuil

| tunnel | centre réel du trou | sortie la plus proche mesurée |
|---|---|---:|
| toit percé | (0,40 ; 4,00 ; 2,50) | **0,21 m** |
| plancher percé | (−0,60 ; 2,50 ; 0,00) | **0,29 m** |
| paroi percée | (1,50 ; 6,50 ; 1,20) | **0,08 m** |
| fond percé | (0,20 ; 9,25 ; 1,40) | **0,07 m** |

Le seuil discrimine, dans les deux sens — et il faut les deux moitiés de la
phrase :

* le trou d'épingle de 0,04 m est **vu** (4 rayons suspects) ;
* il est **refusé** à la confirmation (ouverture mesurée 0,025 m < 0,10 m).

Un seuil qui ne refuse rien n'est pas un seuil ; un seuil qui aveugle la sonde
ne mesure plus.

### 3.3 Ligne de vue : le trou tombe dans la boîte de pixels prédite

Une caméra est posée **en monde** par la chaîne de matrices, face à un tunnel
percé au fond d'un carré de 0,70 m. La boîte de pixels du trou est calculée par
une projection écrite **indépendamment** (monde → pixel), là où la sonde lance
des rayons (pixel → modèle).

| | x | y |
|---|---|---|
| boîte **prédite** | 631 … 673 | 330 … 372 |
| boîte **mesurée** | 632 … 675 | 332 … 371 |
| écart | +1 / +2 px | +2 / −1 px |

Deux pixels sur 1280. C'est ce qu'aucune superposition d'image ne pouvait
établir, pour une raison simple : ici la réponse est connue avant la mesure.

Et la mutation, encore : une origine fausse de **+3 m** — le décalage exact
qu'hier la superposition préférait — change le résultat de façon franche.

### 3.4 Deux défauts trouvés par l'épreuve elle-même

L'épreuve a commencé par rougir, et sur des choses réelles.

1. **L'anneau de bouche du tunnel d'épreuve était enroulé à l'envers.**
   Symptôme : 19 272 pixels perçants au lieu d'une centaine, soit exactement
   60,5 % de la formation — la part de la face avant occupée par l'anneau. Une
   coque dont l'anneau regarde le dedans est invisible sur une capture fixe et
   évidente pour un test de face avant.

2. **Le contrôle 3 jetait le défaut le plus grave.** Il rangeait les rayons
   **sans aucun impact** dans « ne vise pas la formation ». C'est vrai d'un
   pixel de ciel et radicalement faux d'un pixel qui traverse une percée
   franche : un rayon qui passe par un trou net ne rencontre justement aucun
   triangle. Mesure de l'écart, sur le tunnel percé au fond : **10 pixels
   retenus** par l'ancien critère — le liseré rasant du bord — contre **80**
   après correction, pour un trou dont la boîte prédite fait 42 pixels de côté.
   Il voyait le contour, pas le trou.

---

## 4. Ce que « percée confirmée » veut dire

> **RAYON SUSPECT** — un rayon parti du vide de la galerie qui n'en ressort pas
> par la bouche avec une parité paire.
>
> **PERCÉE CONFIRMÉE** — il existe une direction `d` et un point `p` du vide
> tels que **tous** les rayons d'une grille de pas 0,025 m couvrant un **carré
> de 0,10 m de côté**, perpendiculaire à `d` et parallèles à `d`, sortent de la
> formation. Autrement dit : un carré de 10 cm est **intégralement** percé.

Trois raisons, et chacune peut être contestée sur un chiffre :

* **un carré, parce qu'une fente ne se voit pas.** Une fissure de 0,3 mm de
  large et d'un mètre de long produit des dizaines de rayons suspects et n'est
  visible à aucune distance : à 4 m elle sous-tend 0,004°, soit 0,07 pixel dans
  les captures livrées. Exiger une *surface* ne la rejetterait pas ; exiger un
  carré, si.
* **0,10 m, parce que c'est le plus petit trou dont la visibilité est
  démontrable.** Les captures font 1280 × 720 à 40–55° de champ, soit au mieux
  0,058°/pixel. Un carré de 0,10 m vu à la plus grande distance intérieure
  possible (10,4 m, la longueur de la galerie) sous-tend 0,55°, soit ~9 pixels
  de côté. Sous 0,10 m, on ne peut plus l'affirmer.
* **0,10 m, aussi, parce que c'est le double de `EPAISSEUR_ECAILLE_M`** (0,05 m),
  l'épaisseur sous laquelle le générateur déclare lui-même que deux impacts sont
  un pli vu deux fois. Une écaille de décimation ne peut pas produire une percée
  confirmée.

Le seuil est un réglage (`--ouverture`). La conséquence ne l'est pas :
**une seule percée confirmée fait échouer la géométrie.**

Limite honnête : la mesure d'ouverture **sature à 0,30 m** (demi-faisceau
0,15 m). Elle rend donc une borne inférieure, jamais une surestimation — le
biais va dans le sens sûr.

---

## 5. Résultat sur le GLB livré

`SM_WaterfallCave.glb` à `504ecbe`, 19 954 triangles rendus.

| contrôle | résultat | verdict |
|---|---|---|
| 0 — pose dérivée, aller-retour | écart 4,663 × 10⁻¹⁵ m | `PASS` |
| 1 — plancher | 454 points sondés vers le bas, **0 faute** ; carte pleine sur les 33 abscisses | `PASS` |
| 2 — jour, sphère entière | 37 950 rayons jugés, 1 850 écartés par la bouche, **73 rayons suspects** | — |
| 2b — confirmation | 71 amas mesurés, **0 confirmée** ; ouverture maximale **0,000 m** | `PASS` |
| 4 — cinq surfaces | plancher 17 298 · toit 17 298 · parois 8 184 ×2 · fond 4 092 cases, **0 ouverte** partout | `PASS` |
| 3 — ligne de vue | 4 prises, 41 442 pixels sur la formation, **0 suspect**, 0 confirmée | `PASS` |
| **gate** | **0 percée confirmée** | **`PASS`** |

### Les 73 « percées » d'hier étaient 73 rayons, pas 73 trous

Le chiffre publié hier est réel comme comptage de rayons, et faux comme
comptage de trous. La mesure d'ouverture le dit sans ambiguïté : les 73 rayons
se regroupent en **71 amas**, dont l'ouverture est **0,000 m** — pas un seul
n'ouvre deux échantillons contigus. Les faisceaux de confirmation rendent 0 à 7
rayons sortants sur 169.

Le rapport d'hier le pressentait déjà, en écrivant *« un vrai trou fait
converger, un mauvais point disperse »* : la dispersion était visible (≤ 3 rayons
par maille), mais elle n'était pas mesurée, et le mot « percée » a été employé
quand même. Ce sont des rayons rasants et des fentes de décimation
sub-millimétriques.

**Cela ne remet pas en cause les défauts de R2a-3.3.** Le plancher absent sur
6,5 m et le fond ouvert sur 1,50 × 1,25 m étaient des trous mesurés en mètres,
pas des rayons épars. Ils sont aujourd'hui corrigés, et les contrôles 1, 2b et
4 le confirment par trois chemins indépendants.

### Le vert est une mesure, pas un réglage

`EPREUVE 4` retire **six triangles** au toit de la station 4, en mémoire, sans
toucher au fichier :

| maillage | triangles | suspects | confirmées | ouverture max | verdict |
|---|---:|---:|---:|---:|---|
| livré, intact | 19 954 | 73 | 0 | 0,000 m | **PASS** |
| toit percé 0,25 m | 19 948 | 506 | **118** | **0,300 m** | **FAIL** |

Six triangles font basculer le verdict. Sans cette paire, un vert ne
distinguerait pas « la grotte est fermée » de « la sonde ne regarde pas ».

*(Les colonnes de 0,12 m et 0,06 m essayées dans la même série n'ont retiré
**aucun** triangle — les facettes de la cavité sont plus larges que cela. Leurs
lignes remesurent le maillage intact et ne démontrent rien ; elles ne sont pas
comptées comme une épreuve de finesse. La finesse est démontrée sur le
synthétique, §3.2.)*

---

## 6. Limites — ce que ce travail ne prouve pas

* **L'axe axial de la pose n'est pas contraint** par la mesure de pénétration
  (§2.4). Un glissement de 3 m le long de la galerie laisse la mesure
  indifférente, par construction. Il est borné par la dérivation, pas par la
  mesure.
* **La hauteur du terrain gelé sous le seuil (3,00 m) reste documentaire**, donc
  `NON VÉRIFIÉ`. Le balayage vertical montre qu'une erreur de ±1 m ne change
  rien au résultat (pénétration 7,15 à 10,25 m) et qu'une erreur de 2 m serait
  réfutée.
* **Les contrôles 2 et 4 ne sont pas redondants, et ne se remplacent pas.**
  Mesuré sur la mutation du §5 : le contrôle 2 voit la percée (118 confirmées),
  le contrôle 4 ne la voit pas — la surface *extérieure* du massif est restée
  intacte au-dessus du trou. Le contrôle 2 répond « le joueur à l'intérieur
  voit-il dehors » ; le contrôle 4 répond « la coque manque-t-elle ». Le défaut
  de R2a-3.3 était les deux à la fois ; un défaut futur pourrait n'être que l'un.
* **Le noyau des rasters est volontairement étroit** (55 % de la demi-largeur,
  55 % de la clé). Le biais est directionnel et assumé : un raster peut rester
  silencieux sur un trou qui n'ouvre que sur la marge, il n'en fabrique jamais.
* **La mesure d'ouverture sature à 0,30 m.** Borne inférieure, jamais
  surestimation.
* **Rien ici n'est une mesure de performance, ni un jugement artistique.** Aucun
  rendu n'a été fait ; aucune forme n'est jugée.
* **La sonde n'a pas été exécutée sous Godot.** Elle lit le GLB en Python pur.
  Le filet `tests/unit/test_grotte_sans_jour.gd` reste le contrôle côté moteur ;
  il n'a pas été rejoué dans cette session (worktree sans `.godot/`).

---

## 7. Reproduire

```bash
cd <worktree>
python3 tools/probe_cave_selftest.py                       # 29 epreuves, RC=0
python3 tools/probe_cave_openings.py \
    assets/environment/caves/SM_WaterfallCave.glb \
    --manifeste evidence/world_v2/v2_3_r2a/grotte/tranche4_final/manifest.json \
    --json <sortie>.json
```

Ni Godot ni Blender, donc **aucun verrou d'outil lourd**. Codes de sortie :
`0` aucune percée confirmée · `1` défaut mesuré · `3` BLOQUÉ.
