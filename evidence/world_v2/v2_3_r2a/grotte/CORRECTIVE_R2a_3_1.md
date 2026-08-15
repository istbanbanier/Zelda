# Grotte du Couchant — corrective R2a-3.1

**Commit prouvé : `71d18174111b9d2a9044a3d182e781ea376b035d`** · `repo_dirty: false`
(voir `manifest.json` et `manifest_silhouettes_grotte.json`).
Scène : `res://scenes/world_v2/WorldV2.tscn`. Renderer Forward+, llvmpipe.

Ce document répond point par point aux huit exigences de la revue, et dit
aussi ce qui n'est pas atteint.

---

## Ce que la première tentative avait raté, et pourquoi

Une première R2a-3.1 a été construite, générée, tous contrôles verts — puis
capturée. Elle n'avait **rien changé** sur la vue d'approche : bouche en
demi-cercle, façade lisse, galerie en tube. Mesuré sur cette capture :
σ = 13,3 sur 300 × 120 px de façade, σ = 5,8 sur la paroi intérieure.

La cause était dans mon propre code. `facette()` quantifiait le **rayon**
mais plaçait le sommet au **vrai azimut**. Un rayon constant sur un secteur
angulaire trace un **arc de cercle** : la section restait ronde, à un saut
de rayon près entre secteurs. La « section polygonale » annoncée n'existait
pas dans le maillage.

`coins()` calcule maintenant les sommets du polygone et `polygonal()`
rééchantillonne en interpolant **linéairement** le long de chaque arête.
Les pans sont plats, les angles francs.

Conséquence d'épaisseur, anticipée et compensée : un polygone dont les
sommets sont sur la courbe est **inscrit**, ses arêtes coupent jusqu'à
1 − cos(π/7) = 9,9 % du rayon, soit 0,47 m sur un corps de 4,7 m — pour une
marge d'épaisseur de roche de 0,09 m. Le polygone du massif est donc
**circonscrit** (× 1/cos(π/N)) : les arêtes retombent sur la courbe et les
sommets débordent, ce qui rend en prime la silhouette plus anguleuse.

---

## Les huit exigences

| # | Exigence | État | Preuve |
|---|---|---|---|
| 1 | Silhouette d'au moins trois masses majeures distinctes | **PASS** | `silhouette_grotte_000.png`, `silhouette_grotte_090.png`, `07_trois_masses.png` |
| 2 | Bouche irrégulière et dissymétrique, sans demi-cercle | **PASS** | `02_approche_joueur.png`, `03_gros_plan_seuil.png` |
| 3 | Extérieur à fractures, ressauts, corniches, variation d'échelle | **PASS** | `06_flanc_strates.png`, `01_composition.png` |
| 4 | Intérieur non cylindrique, largeur et hauteur variables | **PASS** | `04_interieur_sortie.png`, tournette 8 vues |
| 5 | Récompense mise en scène par la géométrie et la lumière | **PARTIAL** | `05_interieur_niche.png` — voir plus bas |
| 6 | Valeurs de roche recalibrées, flanc non brûlé | **PASS** | mesures ci-dessous |
| 7 | Sonde de végétation rejouée autour de la grotte | **PASS** | `VEGETATION_VERDICT.md` |
| 8 | Nom affiché « Grotte du Couchant », ID inchangé | **PASS** | `world_v2_layout.json` |

### 1 — Trois masses, et du côté où le joueur regarde

Le contrefort et la couronne de la première tentative sont tous deux au
**nord**. L'approche du joueur vient du sud-est : elle ne montrait qu'un
dôme nu. Une silhouette à trois masses qui n'existe que vue de dos ne
remplit pas l'exigence.

Deux masses de plus, loftées à part et interpénétrant le corps, ont donc été
ajoutées **du côté de l'approche** : une **visière** en surplomb au-dessus
de la bouche, un **éperon** à côté d'elle. Dégagement mesuré par le
contrôle : éperon 0,83 m de la cavité, contrefort 0,55 m ; visière et
couronne entièrement hors de la bande de hauteur de la cavité.

### 2 — La bouche

Asymétrie renforcée aux trois premières stations : facteurs 1,34 / 0,79 et
linteau incliné de −0,44 rad, soit une clé 44 % plus haute à gauche et 44 %
plus basse à droite. Combinée aux pans plats, l'ouverture est une ligne
brisée penchée.

La **collerette** était un anneau plan — un seul quad par segment entre les
deux peaux. En gros plan, la moitié de l'image était une face grise sans un
accident. Une troisième rangée intercalée, avancée selon l'azimut, en fait
un chanfrein brisé. Premier réglage **refusé** par le contrôle d'épaisseur
(0,52 m pour 0,60 exigés) : un auvent en porte-à-faux amincit la roche qui
le porte.

### 5 — Ce qui n'est que PARTIAL, et pourquoi

Deux mécanismes ont été construits pour relever le sol autour de la
récompense — une **banquette** le long d'une paroi, puis une **tablette**
d'alcôve — puis **mesurés là où ils devaient culminer** : 0,164 m et
0,30 m, c'est-à-dire le palier seul. Ils ne relevaient rien.

Cause : une fenêtre d'azimut de 52 à 62° est plus étroite que l'écart entre
deux sommets de la section (40° à 9 facettes). Sans sommet sur lequel
s'appliquer, l'arête droite qui joint ses voisins efface le relief. **Un
relief plus fin que la résolution du polygone n'existe pas** — c'est la
contrepartie du choix de facettes larges. Les deux mécanismes ont été
retirés du code plutôt que laissés en place sans effet.

La mise en scène tient donc à trois choses réellement mesurables : le creux
de l'alcôve (qui, lui, survit — il agit sur le rayon à tous les azimuts de
sa fenêtre), la lampe déplacée pour prendre la récompense **de face** et non
à contre-jour, et le sol qui monte du seuil au fond.

**C'est moins que « mise en scène par la géométrie » ne promet. Je le classe
PARTIAL et non PASS.**

### 6 — Valeurs rendues, mesurées sur les captures livrées

| Zone | Moyenne /255 | σ |
|---|---:|---:|
| Masse au soleil (`01`) | 97,7 | 37,4 |
| Flanc à strates (`06`) | 99,4 | 32,8 |
| Façade au-dessus de la bouche (`02`) | 84,3 | 16,3 |
| Intérieur vu par la bouche (`02`) | 67,9 | 29,5 |
| Paroi intérieure (`04`) | 60,5 | 7,9 |
| Sol intérieur (`04`) | 72,3 | 6,7 |

Le flanc ne brûle plus : la masse au soleil plafonne à 0,38 de moyenne, avec
un écart-type de 37 qui dit que la modulation existe. La façade passe de
σ = 13,3 à σ = 16,3, et surtout ses grands pans sont désormais orientés
différemment, ce que la moyenne ne capture pas mais que les captures
montrent.

Les deux dernières lignes restent basses : **la paroi et le sol intérieurs
n'ont pas de modulation forte**. Une salle éclairée par une source unique et
une ambiante constante ne fabrique pas de contraste sur des pans larges.
C'est le prix du parti pris de facettes larges, et je le déclare plutôt que
de l'habiller.

---

## Contrôles du générateur, tous verts

```
visuel 1288 faces (2464 tris), collision 460 faces (880 tris)
visuel     : 0 arete(s) de bord, 0 non-manifold, volume 541 m3
collision  : 0 arete(s) de bord, 0 non-manifold
4 masses annexes : 0 arete de bord, 0 non-manifold chacune
epaisseur de roche : 1.12 m en paroi (min 0,80), 0.75 m en collerette (min 0,60)
gabarit : capsule r=0,45 h=1,85 passe aux 7 stations du chemin
aucun jour : 25 rayons verticaux, croisements pairs et >= 2
sol sous axe_seuil (0.05, 1.60) : -0.035 m
sol sous salle     (1.05, 6.25) :  0.185 m
sol sous niche    (-1.20, 8.20) :  0.297 m
sol sous voisin   (-1.60, 8.20) :  0.328 m
```

Filets de lieux : **8 réussis, 0 échoué**, dont
`test_la_grotte_a_un_seuil_et_un_interieur_praticables`.

### Trois contrôles ont été rendus honnêtes en cours de route

* **`hauteur_du_sol`** partait d'une altitude fixe et gardait le premier
  impact. Elle rendait 1,544 m à un endroit et −2,078 m à 60 cm de là : le
  départ tombait dans la roche et le « sol » était une face de dessous. Elle
  descend maintenant jusqu'au premier impact dont la **normale regarde vers
  le haut**. C'est elle qui a montré que la récompense **flottait de 0,7 m**.
* **`controle_annexe_hors_cavite`** imprimait `1000000000.00 m` quand il
  n'avait rien à comparer. Une non-mesure se dit ; elle ne se déguise pas en
  marge énorme.
* **Le gabarit** soustrait désormais le palier de la hauteur libre. Sans ce
  terme il mesurait la clé au-dessus d'un sol qui n'est plus là — et il a
  d'ailleurs refusé le premier palier, à 2,04 m pour 2,05 exigés.

---

## Ce qui reste, et que je ne masque pas

1. **Les fleurs gelées devant la bouche.** Le semis V2.2 pose un massif de
   fleurs hautes d'environ 1,5 m à quelques mètres devant l'entrée. Il ne
   traverse rien (sonde : aucune intersection, plante la plus proche entre 6
   et 8 m au-delà de l'emprise), mais il masque le tiers bas de l'ouverture
   sur la vue d'approche. La végétation V2.2 est **gelée** ; la seule
   correction possible sans y toucher serait de déplacer la grotte, ce que
   la revue n'a pas demandé.
2. **Les grands pans du massif en très gros plan.** À moins de 7 m, une
   facette du septagone occupe une large part du cadre. C'est structurel :
   des pans larges se lisent bien à 15 m et mal à 5 m.
3. **Le sol et les parois intérieurs restent peu modulés** (σ 6,7 et 7,9).
4. **Aucun de ces chiffres n'est une mesure de performance.** llvmpipe rend
   en logiciel ; ces captures servent la régression visuelle, jamais un
   budget de frame.
