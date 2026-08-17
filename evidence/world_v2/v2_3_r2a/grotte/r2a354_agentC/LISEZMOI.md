# Agent C — vérification indépendante R2a-3.5.4

**Type : HISTORIQUE.** Rapport daté d'une passe. Ce qui fait autorité, c'est
`docs/CONTRAT_COQUE_STRUCTURELLE.md`, gelé au commit `cca1778`.

Tous les outils portent le préfixe `tools/cave_check_*`. **Aucun ne réutilise
une ligne de l'oracle principal, du générateur, ni des sondes existantes** —
c'est la condition pour que cette vérification vaille quelque chose. Ce qui est
employé : soudure par position · graphe dual des faces · angle solide signé ·
distance exacte point-triangle. Ce qui ne l'est **pas** : grille, voxel, parité
de rayon, EDT, chanfrein, Dijkstra, station de `CAVITE`, seuil en `ay`.

---

## 1. LES SOMMETS PINCÉS — la question posée en premier

**Réponse : ZÉRO sur les quatre géométries. Les genres publiés ne sont pas
falsifiés.**

Commande, code retour et journal : `closure_sommets_pinces.log`, `RC=1`
(le 1 vient des 4 arêtes non-manifold de `BASE352`, pas d'un sommet pincé).

```
python3 tools/cave_check_closure.py \
  assets/environment/caves/SM_WaterfallCave.glb \
  assets/environment/caves/prototypes/SM_WaterfallCave_BASE352.glb \
  /home/user/zelda-r2a354/reference/SM_WaterfallCave_R2a34.glb \
  /home/user/zelda-r2a354/a_percee/assets/environment/caves/SM_WaterfallCave.glb
```

| géométrie | sha256 | bords libres | non-manifold | **pincés** | χ corrigé | genre |
|---|---|---:|---:|---:|---:|---:|
| candidat | `cc3596c5` | 0 | 0 | **0** | 0 | **1** |
| `BASE352` | `8bc8b9f9` | 0 | 4 | **0** | 0 *(corps)* | **1** *(corps)* |
| R2a-3.4 livrée | `8bf1a1b3` | 0 | 0 | **0** | −2 | **2** |
| agent A | `c184c8dc` | 0 | 0 | **0** | 2 | **0** |

Le test manquant est le **lien de sommet** : sur une surface fermée manifold,
le voisinage d'un sommet est un disque, donc son lien — le graphe des arêtes
opposées dans ses faces incidentes — est un **cycle unique**. Un lien à *k*
cycles est un pincement, il retire *k−1* à χ, et **aucun compteur d'arêtes ne
peut le voir** : toutes les arêtes d'un sommet pincé ont exactement deux faces.

Ici il n'y en a aucun. Les χ publiés sont donc les vrais χ.

### Ce que j'ajoute, et que le compteur d'arêtes ne disait pas

`BASE352` n'est pas « genre non défini » tout court. Son **corps principal est
une surface fermée de genre 1** — la même anse que le candidat. Les 4 arêtes
non-manifold viennent de **4 lamelles à volume nul**, chacune faite de deux
triangles portant les **mêmes trois sommets** en enroulement opposé :

| lamelle | aire | sommets | position modèle |
|---|---:|---|---|
| 1 | 0,000206 m² | 3687, 3689, 3690 | (−2,137 ; −1,065 ; 1,612) |
| 2 | 0,000796 m² | 3697, 3698, 3702 | (−1,480 ; −1,078 ; 2,300) |
| 3 | 0,001539 m² | 3700, 3701, 3702 | (−1,053 ; −1,049 ; 2,357) |
| 4 | 0,000263 m² | 7721, 7722, 7771 | (−2,499 ; −1,841 ; −0,408) |

Leurs trois sommets sont quasi colinéaires : ce sont des aiguilles dégénérées,
pas de la géométrie. Cela **renforce** le constat que la percée est héritée de
l'enveloppe : `BASE352` et le candidat portent la même anse, au corps près.

Le χ global de `BASE352` vaut bien **4**, comme publié — je le reproduis.

---

## 2. LE GATE TOPOLOGIQUE — sans grille, sans altitude, sans résolution

C'est la contribution principale, et c'est la formulation « **par chemin** » :
*depuis l'air canonique, existe-t-il un chemin vers le dehors qui n'emprunte
pas la bouche masquée ?*

La barrière du §2.1 est une **coupure d'arcs dans le graphe dual des faces**.
Elle n'ôte aucune cellule, aucun triangle, aucun volume — elle coupe
l'adjacence. **L'épaisseur nulle n'est pas un réglage soigneux, elle est
structurelle** : le défaut `C4`, où une tranche épaisse ampute la cavité au
lieu de la fermer, est impossible par construction.

Conséquence décisive : **ce test n'a aucune résolution**. Si la cavité
communique ailleurs avec le dehors, sceller la bouche ne sépare pas, et cela se
voit pour une communication de **n'importe quelle largeur**. Une inondation au
pas de 6 cm est aveugle en dessous de son pas ; celle-ci ne l'est pas. Elle
**localise** en revanche moins bien qu'une carte — les deux restent appariées,
comme le veut le §6.

### Résultats

| géométrie | barrière valide ? | gate topologique | journal |
|---|---|---|---|
| candidat `cc3596c5` | **aucune, à aucun `ay`** | **ROUGE** | `coque_cc3596c5.log`, `RC=1` |
| agent A `c184c8dc` | oui, dès `ay = −1,615`, périmètre 11,978 m, 95,19 m² | **PASS** | `coque_c184c8dc.log` |
| R2a-3.4 `8bf1a1b3` | oui, dès `ay = −1,972`, périmètre 13,879 m, 156,86 m² | **PASS** | `coque_R2a34.log` |

**L'agent A a fermé l'anse, et je le confirme par un chemin qui ne partage rien
avec le sien** : genre 1 → 0 (avec le test du sommet pincé que l'outil du
coordinateur ne fait pas), et une barrière de bouche qui isole réellement
l'intérieur.

Sur R2a-3.4, les barrières valides apparaissent à `ay = −1,972` (périmètre
13,879 m, 156,86 m² de peau intérieure) puis l'aire intérieure décroît
régulièrement à mesure qu'on coupe plus profond — signature attendue d'une
bouche. **En deçà de `ay = −2,222`, plus aucune barrière ne sépare** : on est
sorti par la bouche. La géométrie livrée se comporte donc comme une grotte.

Sur le candidat, **aucune barrière valide nulle part**. La cavité communique
avec le dehors ailleurs que par sa bouche.

### Trois conditions de validité, chacune apprise à ses dépens

Un contour ne fait une bouche que s'il satisfait les trois :

1. **il isole la graine de 26 témoins de l'enveloppe** — les faces extrêmes du
   maillage dans 26 directions ;
2. **la niche reste du côté graine** — sinon la barrière ampute l'arrière ;
3. **aire(côté graine) < aire(côté dehors)**.

Et parmi les valides, on retient **la plus extérieure**, celle qui enferme le
plus de cavité : prendre l'étranglement le plus étroit amputerait le fond, ce
que le §2.4 interdit.

Les trois conditions sont des **corrections d'erreurs mesurées**, pas des
précautions théoriques :

| critère essayé | ce qu'il a élu |
|---|---|
| périmètre minimal seul | une **verrue de 6 faces**, 0,03 m² |
| + un seul témoin au zénith | une **bissection du massif entier** à `ay = 2,228` : 628,39 m² d'un côté, 638,74 m² de l'autre |
| témoin = face la plus proche d'un point lointain | correct, mais **inutilisable** : la recherche par anneaux partait à 68 m et traversait 136 anneaux vides — quatre minutes sans rien imprimer, la pire façon de se tromper |

### L'épaisseur de `c184c8dc` — et pourquoi le masque décide

`coque_c184c8dc.log`, `RC=1`. Le balayage d'emprise du masque, que je publie
plutôt que de choisir :

| masque | échant. | lecture | borne (`h` = 0,10) | argmin (x ; ay ; az) |
|---:|---:|---:|---:|---|
| 0,00 | 114 376 | 0,0216 | −0,0784 | (1,423 ; **−1,129** ; −0,098) |
| 0,25 | 114 376 | 0,0216 | −0,0784 | (1,423 ; **−1,129** ; −0,098) |
| 0,50 | 114 376 | 0,0216 | −0,0784 | (1,423 ; **−1,129** ; −0,098) |
| 0,75 | 111 432 | 0,0254 | −0,0746 | (1,009 ; **−1,128** ; −0,622) |
| 1,00 | 105 800 | 0,0260 | −0,0740 | (0,792 ; **−1,128** ; −0,635) |
| 1,50 | 91 064 | 0,0565 | −0,0435 | (−0,772 ; **−1,100** ; −0,628) |
| **2,00** | 86 020 | **0,6613** | **0,5613** | (1,036 ; **5,173** ; 2,316) |
| 3,00 | 69 408 | 0,6613 | 0,5613 | (1,036 ; **5,173** ; 2,316) |

Lecture, et elle est nette : **jusqu'à 1,50 m d'emprise, l'argmin reste collé à
`ay ≈ −1,11`** — le rebord du porche, où l'épaisseur vaut 2 à 6 cm. C'est une
**arête**, pas un défaut de coque : au rebord même d'une bouche, l'épaisseur
tend vers zéro par construction. À 2,00 m l'argmin **saute** à `ay = 5,173` et
**s'y stabilise** à 3,00 m.

**Le vrai minimum de coque de `c184c8dc` est donc 0,6613 m, borne garantie
0,5613 m, à modèle (1,036 ; 5,173 ; 2,316).** C'est **`FAIL`** : 0,5613 < 0,80,
et même la lecture optimiste reste sous le seuil.

Ce point est à **`ay = 5,17`, soit 2,0 m au-delà de la dernière station de
`CAVITE`** (`ay = 3,17`). C'est précisément le domaine que l'ancien
`controle_epaisseur` ne regardait pas, et précisément ce que la clause §2.4 a
été écrite pour couvrir.

### Une ambiguïté du contrat, que je signale au lieu de la trancher

Le §2.5 dit que **seule** la bouche est exclue, et que le masque est archivé —
mais il ne définit pas son **emprise**. Or le verdict en dépend :

- emprise < 2,00 m → `FAIL` à 2–6 cm, **au rebord**, ce qui est un artefact ;
- emprise ≥ 2,00 m → `FAIL` à 0,6613 m, **à `ay` = 5,17**, ce qui est réel.

Les deux sont `FAIL`, donc la conclusion sur cette géométrie ne bouge pas. Mais
la **cause publiée** change du tout au tout, et une géométrie future pourrait
basculer de `FAIL` à `PASS` sur ce seul choix. Le contrat étant gelé,
**j'applique la règle du gel : ambiguïté → `BLOQUÉ` + arbitrage du lead**, et je
publie la courbe entière plutôt que d'élire un nombre.

---

## 3. LA BORNE `lecture − h` — ma preuve de couverture était fausse

**Signalé par le lead, vérifié, reproduit, corrigé.**

Mon plan annonçait : *« subdivision jusqu'à circonradius ≤ h : tout point est
alors à ≤ h d'un échantillon »*. C'est faux, et le contre-exemple n'est même
pas exotique.

Ce que j'avais réellement écrit était pire que ce que le lead soupçonnait :
critère de subdivision au **circonradius**, mais échantillon au **centroïde**.
Le mélange est incohérent — le circonradius majore la distance depuis le
*circoncentre*, jamais depuis le centroïde.

```
triangle rectangle isocèle (0,0) (1,0) (0,1)
   circonradius                R = 0,707107   <= h = 0,72  -> ACCEPTÉ
   max_i |V_i − centroïde|       = 0,745356   >  h = 0,72  -> NON COUVERT
   dépassement mesuré : 0,025356 m, soit 3,52 %
```

La borne promettait donc plus qu'elle ne tenait, **dans le sens dangereux**.

### La construction retenue, et sa preuve

1. on part de chaque triangle de la coque ;
2. tant que son **rayon de couverture** `max_i |V_i − G|` dépasse `h`, on le
   coupe en quatre par les **milieux d'arêtes** ;
3. l'échantillon d'un triangle terminal est son **centroïde**.

**Tout échantillon appartient réellement à la face** — le centroïde d'un
sous-triangle d'une face est dans cette face. Jamais de circoncentre, qui sort
du triangle dès qu'il est obtus.

**Preuve de couverture.** Tout point `p` d'un triangle est une combinaison
convexe de ses sommets ; `p ↦ |p − G|` est convexe ; le maximum d'une fonction
convexe sur une enveloppe convexe est atteint en un point extrême, donc en un
sommet. D'où l'**égalité** — pas une majoration prudente :

```
max_{p ∈ T} |p − G|  =  max_i |V_i − G|
```

Les sous-triangles terminaux recouvrent la face ; chaque point appartient à
l'un d'eux ; il est donc à au plus `h` de son centroïde. ∎

**Terminaison, indépendante de la forme.** La subdivision par milieux produit
quatre sous-triangles *semblables* au parent, de rapport 1/2. Comme
`|G − V₁| = |(V₂−V₁) + (V₃−V₁)|/3 ≤ (2/3)·arête_max`, le rayon de couverture
est divisé par deux à chaque niveau **quel que soit l'aplatissement**. Un
triangle obtus converge exactement aussi vite qu'un équilatéral.

**Définition de `h`** : le rayon de couverture maximal admis pour un
sous-triangle terminal. C'est un majorant *prouvé* de la distance de tout point
de la coque à l'échantillon le plus proche, donc — la distance à un fermé étant
1-lipschitzienne — `min_vrai ≥ min_échantillonné − h`.

### La fixture adverse

`tools/cave_check_coverage.py`, journal `couverture_triangle_obtus.log`,
**`RC=0`**. Elle compare trois constructions sur cinq témoins dont quatre
obtus ou dégénérés, et mesure la **couverture réelle** par échantillonnage
dense de la face.

| construction | témoins violant `h` | échantillons hors de la face |
|---|---:|---|
| circonradius + circoncentre | 0 | **256, 4096, 4096** selon le témoin |
| **circonradius + centroïde — mon bug** | **1 sur 5** | 0 |
| **retenue** | **0 sur 5** | **0** |

Deux choses valent d'être dites :

- la construction *au circoncentre* couvre correctement, mais place ses
  échantillons **hors de la surface mesurée** et sur-subdivise
  catastrophiquement — **4 096 échantillons contre 16** pour la même
  couverture sur le témoin à 170° ;
- **la première version de ma fixture n'a rien attrapé et a rendu `RC=1`** en
  refusant de conclure : *« un contrôle qui n'a jamais rougi n'est pas un
  contrôle »*. Elle testait une construction que je n'avais pas écrite. Il a
  fallu reconstruire mon erreur exacte pour qu'elle morde.

---

## 4. LE TROISIÈME VERDICT est implémenté

Conforme au §5.1 gelé :

| cas | verdict |
|---|---|
| `lecture − h ≥ 0,80` | **PASS**, RC 0 |
| `lecture < 0,80` | **FAIL**, RC 1 |
| `lecture ≥ 0,80` et `lecture − h < 0,80` | **BLOQUÉ**, RC 3 |

Le troisième imprime le nombre de points concernés et le `h` qu'il faudrait
pour trancher, avec cette lecture : *rendre FAIL accuserait la géométrie d'un
défaut d'instrument ; rendre PASS violerait le contrat. On refuse de choisir.*
**`h` est imprimé à côté de chaque borne** — une borne sans son `h` n'est pas
une borne.

---

## 5. LA CARTE DES COLONNES OUVERTES — instrument RÉFUTÉ, trace conservée

`tools/cave_check_sky_map.py` porte désormais une bannière `REFUTE`. **Ne pas
citer son aire.** Je suis arrivé à la même conclusion que le coordinateur, par
un autre chemin, et je conserve les mesures intactes.

Le critère — *« depuis `az = 1,50`, zéro traversée en montant, avec de la roche
en dessous »* — confond **toit absent** et **enveloppe simplement plus basse**.

Ce qui l'a montré : la **décomposition en amas**, avec marquage des amas qui
touchent un bord de fenêtre.

Dans la fenêtre de référence, 30 × 30 cm, **3 721 colonnes** — le compte exact
publié :

```
az=1,50 : 2 amas
     873 col.   218,25 cm²  x[0,396 0,530] ay[5,897 6,098]  <== TOUCHE LE BORD, TRONQUÉ
      47 col.    11,75 cm²  x[0,591 0,626] ay[5,853 5,908]
```

En élargissant à 1,2 × 1,2 m :

```
az=1,25 : 2767 col. (tronqué, touche le bord)  +  47 col. 11,75 cm² x[0,591 0,626] ay[5,853 5,908]
az=1,50 : 8286 col. (tronqué, touche le bord)  +  47 col. 11,75 cm² x[0,591 0,626] ay[5,853 5,908]
```

**L'amas compact ne bouge pas** : 47 colonnes, mêmes bornes, à deux altitudes
et à deux tailles de fenêtre. L'autre croît sans cesse et touche toujours le
bord. Sensibilité en altitude dans la même fenêtre : 11,75 cm² (`az ≤ 1,25`)
→ 730 cm² (`az = 2,00`).

**Une aire qui croît avec la fenêtre n'est pas une aire : c'est la fenêtre.**

Trois critères « à moi » ont échoué avant, tous mesurés et tous conservés dans
les docstrings :

| critère | résultat | pourquoi il tombe |
|---|---|---|
| poche voisine à 3 cellules | 11,75 cm² | 1,5 cm de portée : le **centre** du trou est manqué |
| propagation à 0,30 m | 164,25 cm² | l'emprise touche **les deux bords** : le flanc de colline entre |
| inondation d'intervalles depuis la salle | **80 427 colonnes sur 80 427** | l'air de la galerie communique avec le ciel **par la bouche** — fonctionnement normal d'une grotte |

Le troisième échec est le plus instructif : il montre qu'**aucune carte de
colonnes ne peut répondre sans sceller la bouche d'abord**, et que sceller la
bouche est le travail du graphe dual, pas d'une grille.

**Ce qui reste bon** : le *diff* de carte (fermées / persistantes / NOUVELLES)
et le marquage « touche le bord ». C'était le **critère** qui était faux, pas
la comparaison de cartes.

---

## 6. MIGRATION — comment la question se tranche désormais

Le gate topologique la tranche **complètement et sans fenêtre** :

> **PASS ⟹ aucune communication nulle part, de quelque largeur que ce soit
> ⟹ rien n'a migré.**

Il n'y a pas de « ailleurs » où un défaut pourrait s'être déplacé sans être vu :
la séparation est globale ou elle n'est pas. C'est plus fort qu'un balayage
élargi, qui ne couvre jamais que sa fenêtre.

En complément, `cave_check_hull.py` publie l'**argmin localisé** de l'épaisseur,
pas seulement sa valeur — un minimum qui se déplace est une migration
qu'aucun total ne montre.

---

## 7. CONTRÔLE NÉGATIF FERMÉ

`tools/cave_check_negative.py`. Séquence imposée par le §3, dans l'ordre :

1. fermeture prouvée **avant** — 0 bord libre, 0 non-manifold, **0 sommet
   pincé**, genres relevés ;
2. sabotage par **déplacement de sommets** dans un disque, atténuation
   cosinus — **aucune face retirée**, donc la connectivité est intacte et la
   fermeture conservée *par construction* ; re-prouvée quand même, genres
   comparés ;
3. **témoin indépendant** : portée d'un rayon avant / après. Comme
   `distance euclidienne ≤ distance le long d'un rayon`, « rayon < 0,80 »
   **implique** « euclidienne < 0,80 ». L'implication ne vaut que dans ce sens,
   et c'est celui dont on a besoin ;
4. verdict de l'instrument sur le maillage saboté — doit être **ROUGE** ;
5. la source **n'est jamais réécrite** : le sabotage vit dans un fichier
   séparé, donc la restauration est byte-identique *par construction* plutôt
   que par diligence. sha256 publié des deux côtés.

### Résultat — `controle_negatif.log`, **`RC=0`**

Sur `c184c8dc`, masque 2,00 m, `h` = 0,150 :

```
site du sabotage   : (0,993 ; 4,590 ; 2,893)
temoin AVANT / APRES : 0,9853 m -> 0,6000 m      (baisse 0,3853 m)
fermeture apres    : 0 bord libre, 0 non-manifold, 0 pince, genre [0] inchange
triangles retournes: 0
argmin SAIN        : (1,036 ; 5,173 ; 2,316)     lecture 0,6613 m
argmin SABOTE      : (1,134 ; 4,556 ; 2,393)     -> 0,520 m du site
attribue au sabotage : OUI
sha256 source AVANT = APRES = c184c8dc...        (jamais reecrite)
```

**CONCLUANT.** L'argmin s'est déplacé **sur** le site du sabotage.

### Quatre refus successifs, et c'est ce qui rend ce vert croyable

Mon contrôle négatif a rendu **`RC=3` quatre fois avant de conclure**, et
chaque refus était mérité :

| tentative | ce que l'outil a refusé | mesure |
|---|---|---|
| 1 | déclarait `CONCLUANT` sur le seul `RC=1` | le ROUGE venait du **rebord du porche** (argmin à `ay = −1,11`), pas du sabotage — il aurait été obtenu **sans** sabotage. §3 : *« un rouge obtenu pour une autre cause que celle annoncée ne compte pas »* |
| 2 | déplacement 1,16 m dans un disque de 0,40 m | **3 triangles retournés** — surface repliée |
| 3 | disque élargi à 2,90 m | le sabotage entraînait **aussi la paroi opposée** : 1,61 → 0,94 m seulement, au-dessus du seuil. Un sabotage qui déplace les deux bords ne les rapproche pas |
| 4 | filtre d'orientation à seuil **dur** (0,30) | marche entre sommets voisins : **17 à 1 444 triangles retournés** selon le rayon |

La version qui conclut : pondération **continue** par l'alignement de normale,
départ sur un point d'épaisseur ~0,99 m, déplacement 0,385 m, rayon asservi
0,617 m, **43 sommets, 0 repli**.

**La première tentative est la plus instructive** : elle rendait `RC=0` et un
« CONCLUANT » entièrement faux. Un contrôle négatif qui ne vérifie que le code
retour ne vérifie rien — il faut **attribuer** le rouge.

Le pourquoi du déplacement plutôt que l'ablation est mesuré, pas théorique :
retirer des triangles **ouvre** le maillage, la parité n'y définit plus de
dedans, et cinq sabotages sur six n'avaient pas rougi avec un tunnel de 0,35 à
0,65 m de rayon libre — un acquittement par aveuglement.

---

## 8. PLAN DES CAPTURES — préparé, **rien de capturé**

Aucune capture avant le gate technique vert. Quatre points réglés d'avance :

1. **Caméras monde épinglées.** Les 7 perspectives de
   `evidence/.../r2a352_avant/reproduction/shots_r2a352.json` sont des caméras
   monde absolues (`from`, `look`, `fov`) et **réutilisables telles quelles**.
   Aucun cadrage recalculé depuis l'AABB.
2. **`deriver_cameras.py` a ses deux boîtes CODÉES EN DUR** — `BBOX_AVANT` /
   `BBOX_APRES` (union calculée lignes 70-73), soit `8bf1a1b3 ∪ cc3596c5`. Une
   **troisième** géométrie (`c184c8dc`) exige de refaire l'union **avant** tout
   contrôle de dégagement, sinon une caméra peut se retrouver murée sans que
   rien ne le crie.
3. **Silhouettes** : cadrées sur l'AABB **du sujet**. L'écart d'échelle de
   **+4,28 %** publié vaut pour `cc3596c5` et doit être **recalculé** pour
   `c184c8dc`. Les boîtes diffèrent réellement — R2a-3.4 monte à `az = 9,643`
   contre 8,192 pour le candidat.
4. **Règle de lecture, obligatoire** : **A→B = éclairage seul · B→C =
   géométrie seule**, et **jamais A→C seul** sur les vues `03`, `04` et `10`,
   dont respectivement 61 %, 84 % et 15 % des pixels changent par le seul
   éclairage.

---

## 9. CE QUE CETTE VÉRIFICATION NE DIT PAS

- **rien de visuel** — aucun verdict artistique n'appartient à ces instruments ;
- **rien du gabarit ni de la praticabilité** : « séparé du dehors » n'est pas
  « parcourable » ;
- **rien sur l'auto-intersection** : deux nappes qui se traversent sans
  partager de sommet restent invisibles au test de fermeture, et le genre
  corrigé ne les couvre pas non plus ;
- **rien au-delà du pas du balayage de bouche** : la barrière est cherchée sur
  des plans espacés de `--pas-balayage`. Un étranglement plus fin pourrait être
  manqué — mais cela ne peut que **manquer une bouche valide**, donc rendre le
  gate plus sévère, jamais plus laxiste.

---

## Reproduction

```sh
python3 tools/cave_check_closure.py  <glb> [<glb> ...]      # sommets pincés, genre
python3 tools/cave_check_coverage.py                        # fixture adverse, triangles obtus
python3 tools/cave_check_hull.py     <glb> [--anciens-reperes] \
                                     [--h=0.10] [--pas-balayage=0.25]
python3 tools/cave_check_negative.py <glb>                  # contrôle négatif fermé
python3 tools/cave_check_sky_map.py  <glb>                  # RÉFUTÉ — trace seulement
```

Chaque journal de ce répertoire porte son `RC=` en dernière ligne, et chaque
sha256 est lu **avant** la mesure.
