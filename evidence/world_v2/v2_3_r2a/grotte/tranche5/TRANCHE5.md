# Grotte — R2a-3.5 : plancher dérivé et fond fermé

Aucun verdict artistique. Ce document livre la cause mesurée, la construction
dérivée qui la corrige, les chiffres avant/après, et ce qui reste ouvert.

| rôle | commit |
|---|---|
| source, `.blend`, `.glb`, manifeste | `5500b7a` |
| base | `6a18751` |

---

## Les deux défauts, et pourquoi neuf contrôles ne les voyaient pas

L'agent B a écrit `tools/probe_cave_openings.py` **hors du générateur**, et son
docstring nomme la circularité en deux lignes de code :

* `controle_epaisseur()` écarte les rayons descendants — `if math.sin(theta) <
  -0.30: continue` — en justifiant que « le plancher est garanti autrement : par
  `controle_aucun_jour` » ;
* `controle_aucun_jour()` ne tire que `Vector((0.0, 0.0, 1.0))`, vers le **haut**.

Chacun renvoyait à l'autre. Rien n'avait jamais regardé le sol.

| défaut mesuré sur le GLB livré | valeur |
|---|---|
| plancher absent | de `y = −0,29` à `y = +6,25` (stations 1 à 5), 66 fautes sur 455 points |
| sol réellement rencontré | `z ≈ −0,45`, c'est-à-dire le sommet de l'assise enterrée |
| fond de galerie ouvert | `1,50 × 1,25 m`, `x[+0,97 ; +2,47]`, `z[+1,02 ; +2,27]` |
| convergence | **536 rayons sur 736** vers cinq mailles voisines autour de `y ≈ 9,2` — un vrai trou |

> **AVERTISSEMENT DE LECTURE — CE RAPPORT A PORTÉ DES CHIFFRES FAUX D'UN
> FACTEUR DIX, ET LA CORRECTION EST ICI.** La première version mesurait avec
> `--rapide`, sans le dire. Ce drapeau échantillonne dix fois moins : pas
> longitudinal 0,50 m au lieu de 0,25, trois fractions latérales au lieu de
> cinq, deux hauteurs au lieu de trois. Il rendait « 81 → 13 percées » là où
> la mesure complète rend **736 → 113**, et « plancher absent de y +0,00 à
> +5,50 » là où elle rend **y −0,29 à +6,25**.
>
> Les rapports d'amélioration étaient justes (÷6,2 contre ÷6,5) parce que
> l'échantillon était cohérent — mais un rapport de livraison n'annonce pas
> une sous-population sans la nommer. Tous les chiffres ci-dessous viennent
> désormais de `python3 tools/probe_cave_openings.py <glb>` **sans drapeau**.

---

## Une semelle dérivée, pas une rustine

L'emprise mesurée invite à rustiner jusqu'à l'emprise, et le docstring de
`rochers_gaine()` raconte déjà ce que ça coûte : *« j'ai répondu seize fois en
ajoutant une roche là où il pointait […] je corrigeais une mesure au lieu de
garantir la propriété »*.

`rochers_semelle()` garantit la propriété : **pour chaque station de `CAVITE` et
chaque position latérale de la demi-largeur**, il existe de la matière continue
entre le profil de sol et l'assise. 53 roches, aucune cote recopiée ; si
`CAVITE` ou `PALIER` change, la semelle suit.

Le pas — longitudinal **et** latéral — est borné par la largeur de faîte du
module (0,93 × ech), la même arithmétique que les amas de R2a-3.4 : deux roches
plus proches que cela ont leur plateau qui se recouvre, et le creux entre elles
reste sous 0,15 × ez. `SEMELLE_MARGE_M` (0,60 m) domine largement ce creux.

Le sommet de chaque roche est à `sol + marge` ; **la soustraction de la cavité
vient ensuite y tailler le plancher réel**, qui est donc exactement le profil
déclaré et non la surface d'une roche.

## Le fond : trois causes, trois corrections dérivées

1. `rochers_gaine()` sautait `i >= len(CAVITE) - 1`, donc la **station 8**, celle
   où le trou est mesuré. Elle gaine désormais toutes les stations sauf le
   porche, plus un **anneau de calotte** derrière la dernière.
2. `ASSISE["y1"] = 9,10` s'arrêtait avant la station 8 (9,25) et l'apex (9,55) :
   porté à **10,60**. `z1` **ne bouge pas** — l'assise couvre 13 m × 13,7 m, la
   remonter au-dessus du terrain ferait un plateau de roche plat tout autour.
3. **L'alcôve creusait sans remblai.** `ALCOVE["ampl"] = 1,20` élargit la cavité
   aux stations 5-7, azimut 180° ; son lobe compensateur `dos_alcove` vit dans
   `LOBES`, consommé par `anneau_exterieur()` qui, depuis le pivot R2a-3.3, ne
   produit plus que la coque de collision jamais rendue. **Le creusement a
   survécu au pivot, le remblai non.** La gaine reçoit maintenant la *même*
   formule de poussée que celle qui creuse.

---

## ISS-044 — la télémétrie imprime son attendu

`TRANCHE3.md` a publié « sol : −0,416 » là où le profil en attend −0,040. Le
générateur **imprimait la mesure du défaut le jour de la livraison**, et elle
était illisible parce que rien ne se tenait à côté pour dire ce qu'elle aurait
dû valoir.

`sol_de_cavite()` est désormais le **seul décideur** du profil : il recopie la
moitié basse de `anneau_interieur()` et sert à trois endroits — l'altitude de la
semelle, l'attendu de `hauteur_du_sol()`, le verdict de `controle_plancher()`.

```
sol sous axe_seuil  ( 0.05,  1.60) : mesure -0.039 m, attendu -0.040 m
                                     (station 2.00, lateral 0.01), ecart +0.000 m
sol sous salle      ( 1.05,  6.25) : mesure +0.185 m, attendu +0.180 m, ecart +0.005 m
sol sous niche      (-1.20,  8.20) : mesure +0.386 m, attendu +0.410 m, ecart -0.024 m
sol sous voisin     (-1.60,  8.20) : mesure +0.510 m, attendu +0.388 m, ecart +0.122 m
```

La ligne rougit au-delà de `SOL_TOLERANCE_M = 0,25` — même valeur que
`PLANCHER_TOLERANCE_M` dans la sonde, pour que les deux instruments ne puissent
pas être en désaccord. Mon écart de 3 mm signalé au tour précédent a disparu
avec le défaut : le sol est là où le profil le déclare.

---

## Deux pièges mesurés, écrits dans le fichier

**1. Le décalage latéral suit la NORMALE au chemin, pas X.** La galerie
s'infléchit de 31° ; `anneau_interieur()` place ses sommets le long de
`normale = (tangente.y, −tangente.x)`. Un point posé à `ax + f·hw` se retrouve,
dans le coude, **hors de la cavité, dans la roche pleine**. Le contrôle y criait
« aucun sol » — et le tracé des impacts l'a dit en une ligne :

```
impacts (z, normale.z) : -2.75/-1.00
```

Un seul impact, à −2,75, normale vers le bas : le **dessous du solide**, touché
de l'intérieur. J'avais passé deux exécutions à supposer ; la trace a tranché en
une.

**2. La hauteur de départ d'un rayon de plancher se dérive de la section.**
Départ fixe à `attendu + cle·0,45` : à la fraction ±0,75 de la station 8, la
voûte est déjà redescendue à 1,46 m et le départ tombait à 1,80. On reprend donc
la branche haute de `anneau_interieur()`, `z = cle·v^0,75` avec `v = √(1−f²)`.

---

## Journal des contrôles, RC = 0

```
193 roches : 81 gaine, 53 semelle, 35 majeur, 16 intermediaire, 8 secondaire
             (controles du GENERATEUR : ils ne passent pas par la sonde,
              donc ils ne sont pas affectes par --rapide)
faite par rang    : majeur 9.52, intermediaire 6.87, gaine 6.01, semelle 1.55
composition       : 3 amas aux deux azimuts, 5.66/3.58/2.17 et 6.42/3.64/2.22
                    faites portes par 8/5/4 roches — INCHANGE depuis R2a-3.4
remaillage 0,12 m : 1 coque, 0 arete de bord, 0 non-manifold
stratification    : 0 paire croisee, repli 0.0000 m
soustraction      : 1 coque, connexite 1 avant et apres
auto-intersection : 0 paire, repli 0.0000 m
budget            : 20 000 tris dans [12 000 ; 25 000]
plage plane > sol : 4.20 m2                                     seuil 12.00
epaisseur         : 1.09 m en paroi, 0.61 m au linteau          min 0.80 / 0.60
gabarit           : capsule r=0,45 h=1,85 aux 7 stations
plancher          : 96 points sondes VERS LE BAS, 0 faute       tolerance 0.25
aucun jour        : 25 rayons verticaux, croisements pairs et >= 2
```

`gltf_inspect` : **VALIDE** — 20 880 triangles, 17,21 × 13,19 × 16,24 m.

### Sonde de l'agent B, sur le GLB livré

Mesure **complète**, sans `--rapide`, les deux GLB passés au même instrument
(`probe_cave_openings.py`, sha256 `30a708dfb993da0d`) :

| | avant (`6a18751`) | après (`5500b7a`) |
|---|---|---|
| contrôle 1 — plancher | absent de y −0,29 à +6,25, **66 fautes** sur 455 points | **454 points, 0 faute** |
| fond de galerie | ouvert 1,50 × 1,25 m, 536 rayons convergents | **« aucune case ouverte »** |
| contrôle 2 — percées | **736** | **113** |

Le lead mesure 761 sur le GLB de R2a-3.3 (`8368550`) ; mes 736 portent sur
`6a18751`, qui contient déjà la recomposition de R2a-3.4. Les deux chiffres
sont justes, ils ne décrivent pas le même objet.

### Runner filtré — `--filter=world_v2,grotte,cave`

**67 réussis, 0 échoué.** Le filet de l'agent B est vert :
`test_le_sol_de_la_galerie_existe_sous_le_joueur` et
`test_le_fond_de_la_galerie_est_plein`.

---

## Ce qui reste ouvert, et pourquoi je ne l'ai pas forcé

### Les 113 percées résiduelles — `PARTIAL`, pas vert

La sonde rend toujours `FAIL` global : **113 percées** sur 37 950 rayons.

**ET ELLES NE SONT PAS DISPERSÉES.** C'est la seconde erreur de la première
version de ce rapport, et elle est plus grave que celle des chiffres, parce
qu'elle portait une conclusion. En mode complet, les mailles de 1,5 m
regroupent :

```
19 rayon(s) en x~-0.23 y~+8.76 z~+1.32   (stations de depart 2,3,4,5,6)
17 rayon(s) en x~+0.21 y~+8.92 z~+1.37   (stations de depart 3,4,5,6,7)
 4 rayon(s) en x~+0.65 y~+9.09 z~+1.48   (stations de depart 6,7)
```

Soit **40 rayons dans une même zone**, alimentée par six stations. L'outil
énonce le critère — *« un vrai trou fait converger, un mauvais point
disperse »* — et il converge. Position : `y ≈ 8,8 à 9,1`, `z ≈ 1,3 à 1,5`,
du côté `−x`, c'est-à-dire **le dos de l'alcôve** (stations 5 à 7, azimut
180°). C'est la troisième cause nommée par le lead : j'ai rendu à la gaine la
formule de poussée qui creuse, ce qui a divisé les percées par 6,5 et fermé
le trou du fond, mais **la couverture derrière la poche reste insuffisante**.

Le reste se répartit sur des mailles de 2 ou 3 rayons, dont deux au seuil
(`x~+2,2 ; y~0,0`) qui relèvent de la collerette mince traitée plus bas.

**Quatre leviers ont été essayés, quatre refus, tous d'un contrôle mesuré :**

| tentative | refus |
|---|---|
| gaine posée sur la normale au chemin | `controle_epaisseur` : paroi **0,60 m** contre 1,09 (min 0,80) |
| gaine densifiée, pas 0,85 m, 126 roches | paroi **0,63 m** |
| gaine à l'échelle 1,30 | `controle_amas` : cols **1,18 / 1,37**, rapport 1,16 |
| doublure normale ajoutée, puis plafonnée | `controle_amas` : cols **1,51 / 1,64**, rapport 1,08 |

Ces quatre mesures ont été prises en mode `--rapide` comme le reste ; leurs
**verdicts** (refus par `controle_epaisseur` ou `controle_amas`) ne dépendent
pas de la sonde et restent valides — ce sont des contrôles du générateur.

Le constat est structurel et mérite d'être écrit : **la galerie passe au milieu
de la formation, et les deux cols de la composition sont les points bas de la
crête juste au-dessus d'elle.** Toute matière ajoutée autour du tube remonte donc
vers un col. Épaissir pour fermer les percées et creuser pour garder trois masses
tirent sur la même roche, en sens contraires. Ce n'est pas un manque d'effort,
c'est une contrainte géométrique entre deux spécifications, et son arbitrage
appartient au lead.

Le code de la doublure a été **retiré**, pas commenté : le fichier interdit de
garder un mécanisme qui ne produit rien. Sa trace et ses quatre mesures restent
en commentaire à l'endroit exact où le prochain lecteur voudra la refaire.

### L'épaisseur au linteau reste à 0,61 m pour un seuil de 0,60

Le point est nommé : *station 1, azimut 154°, z 1,28*, le jambage gauche de la
bouche. Deux leviers essayés en plus des quatre ci-dessus :

* élargir `Seuil_Auvent` (1,30 → 1,52) : refusé, il se projette en x écran +1,14
  à 100°, **en plein dans le col est**, et son faîte à 5,43 m le comblait ;
* gainer le porche (`i == 0`) : refusé pour la même raison — à l'azimut 45° cet
  anneau culmine à 4,87 m pour un col est à 4,58.

**La bouche se trouve sous le col est. Épaissir l'une comble l'autre.** Je n'ai
pas desserré le seuil, et je ne prétends pas avoir rendu la marge demandée : elle
reste d'un centimètre, et c'est le même arbitrage que ci-dessus.

L'élargissement de `Bouche_Joue` (1,30 → 1,52), lui, est conservé : elle se
projette sous la dominante aux deux azimuts et ne touche aucun col.

### Autres

* **La jupe enterrée descend de −2,78 à −3,55 m** : la semelle plonge sous
  l'assise au porche, où le profil de sol est le plus bas. Entièrement sous le
  terrain (world y 0,18 pour un terrain à 3,00) ; `controle_assise` vert.
* **Aucune capture en perspective**, aucun document de continuité modifié,
  `validate_fast.sh` non lancé — conformément au mandat.
* La ligne `SM_WaterfallCave` de `docs/assets/ASSET_MANIFEST.csv` reste à 19
  colonnes quotées ; les lignes mal formées d'ISS-043 ne sont pas touchées.
