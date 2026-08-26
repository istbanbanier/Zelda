# LOT 1.R.2 — LA SOURCE AUX REFLETS · journal de l'agent SOURCE

Sujet : `valley.poi.turquoise_spring.01`. Arbre `/home/user/wt1r2-source`,
base `529d767`. Verdict à corriger (Codex, lecture aveugle, REJET) :

> « Le turquoise permet d'identifier une source, mais le lieu ne possède pas
> encore la présence d'un POI : l'eau reste une petite tache sombre ; la
> couronne ressemble à des blocs indépendants disposés autour d'un point ;
> arrivée, vasque et déversoir ne forment pas une lecture continue ; aucun
> élément ne domine réellement la caméra joueur. »

---

## 0. CE QUE JE VOIS MOI-MÊME, À TAILLE RÉELLE

`lot1r1/revue_intermediaire/vues/turquoise_spring_joueur.png`, ouverte en
grand. Le cadre se lit en quatre bandes horizontales : ciel jusqu'à ~y 90,
talus brun de 90 à 350, une rangée de rochers bleu-lavande de 230 à 380, une
bande d'herbe de 415 au bas. L'eau tient dans l'interstice. Les six masses ont
la même valeur, la même teinte, à peu près la même taille et sont posées à peu
près à la même distance d'un centre : je lis « des cailloux autour d'une
flaque », pas « une source ». Rien n'indique par où l'eau arrive.

Le verdict décrit exactement l'image. Je n'ai rien à lui opposer.

## 1. DEUX MESURES AVANT DE TOUCHER À QUOI QUE CE SOIT

### 1.1 Le sol gelé, sous le lieu (`sol_grille.json`)

Sonde `outils/sonde_sol_source.gd`, moteur, monde monté. Grille locale 1 m,
x ∈ [−18 ; 12], z ∈ [−12 ; 12]. Ce qu'elle apprend :

* le pad est **plat à 0,00 m** sur x ∈ [−9 ; +2], z ∈ [−8 ; +8] — une grande
  terrasse, pas une cuvette ;
* la paroi part de x ≈ −10 et monte vite : +0,98 m à x −11, +3,58 à −13,
  +7,00 à −15, +10,37 à −17 ;
* le sol remonte aussi avec |z| près de la paroi (+1,58 m en (−10 ; +6)) :
  le lieu est au fond d'un demi-entonnoir ouvert vers l'est ;
* le lit creusé de l'affluent est là où le contrat le dit : −1,00 m en
  (+6 ; −6), et il descend encore vers l'est.

Conséquence de conception : **la seule verticale disponible sur le site est
celle qu'on y bâtit.** Il n'y a pas de dénivelé naturel à exploiter entre la
vasque et le déversoir ; la marche du déversoir devra être construite.

### 1.2 La présence de l'eau, au pixel (`outils/mesurer_eau.py`)

Bande turquoise calibrée sur la capture elle-même (échantillons dans l'en-tête
de l'outil : eau H 189 S 0,54 ; herbe H 135–149 S 0,25 ; roche H 213 S 0,28 ;
ciel S 0,04). Premier jet de la bande — H 150–212, S ≥ 0,20 — attrapait
**l'herbe entière** et annonçait « 21 % du cadre » : compteur jeté, refait.

Mesure de référence, commit `9ecf10d` (les fichiers du lieu n'ont pas bougé
entre `9ecf10d` et `529d767` : `git diff --stat` vide) :

| vue | part du cadre | boîte de l'eau | colonne d'eau la plus haute |
|---|---:|---|---:|
| `turquoise_spring_joueur` | **0,81 %** | 418 × 70 px | **35 px** |
| `turquoise_spring_identite` | 0,89 % | 281 × 73 px | 55 px |

Trente-cinq pixels de haut sur sept cent vingt. « Petite tache » n'est pas une
impression : c'est 0,81 % du cadre.

### 1.3 Pourquoi elle est plate — la géométrie, pas la couleur

`outils/projeter.py` projette un point local dans la caméra gelée (base de
`Camera3D.look_at`, `fov` = angle VERTICAL, `KEEP_HEIGHT`). La caméra joueur
est en local (+9,5 ; +1,7 ; 0) et regarde vers l'ouest.

Une nappe HORIZONTALE de 7,9 m de diamètre, vue de 1,62 m de haut à 15 m,
sous-tend `atan(1,62/11,0) − atan(1,62/18,9) = 3,5°`, soit **39 px** de haut.
C'est le chiffre mesuré (35 px). Agrandir le disque ne rend presque rien :
la hauteur écran d'une surface horizontale au ras varie comme l'inverse de la
distance, pas comme le rayon.

Une surface **VERTICALE** de 2,4 m à 18 m sous-tend `2,4/18 = 7,6°`, soit
**≈ 85 px** — deux fois et demie la nappe entière, en un seul élément.

C'est là que bascule la conception de ce lot : **l'eau doit avoir de la
hauteur, pas de la surface.** Et une eau qui a de la hauteur à une source, ce
n'est pas un artifice : c'est l'arrivée — précisément ce que le verdict dit
manquant.

---

## 2. CE QUI A CHANGÉ, ET POURQUOI

### 2.1 Le rocher : une couronne circulaire devient deux rives et une ouverture

La silhouette de référence (`lot1r1/.../silhouette_turquoise_spring_000.png`)
montre **trois masses noires de tailles voisines, régulièrement espacées**.
C'est le verdict de Codex, écrit par un instrument qui ne lit pas le français.
La cause était dans la table `MASSES` de `make_spring_maw.py` : quatre masses
de hauteurs voisines (3,80 / 3,60 / 1,90 / 3,00), une seule teinte, des lobes
répartis autour de la vasque. Une table qui décrit un anneau produit un anneau.

| pièce | rôle | hauteur rendue | valeur |
|---|---|---:|---|
| `SM_Spring_Buttress` | rive principale, SUD | 7,02 m | ardoise froide, sombre |
| `SM_Spring_Spout` | la lèvre d'arrivée | 3,63 m | très sombre, pétrole (trempée) |
| `SM_Spring_Shelf` | rive secondaire, NORD | 1,44 m | gris pâle, SÈCHE |
| `SM_Spring_Sill` | seuil du déversoir, EST | 0,73 m | la plus sombre (trempée en permanence) |

L'est-nord-est est **vide** : c'est par là que l'eau sort. Les cinq lobes du
contrefort descendent en marches jusqu'à l'écrin du fruit, et les éboulis de
pied sont des lobes fondus — ils imbriquent les masses dans le sol sans coûter
un module au budget D7.

Écart de valeur mesuré entre la masse la plus claire et la plus sombre :
**0,183** (plancher du contrôle : 0,14). Sur la version rejetée il était nul
par construction.

### 2.2 L'eau : de la surface, non — de la HAUTEUR

La mesure de §1.3 commande tout : au ras, une nappe horizontale ne rend rien,
une surface verticale rend tout. Trois surfaces d'eau, un seul maillage, un
seul matériau :

* **l'arrivée** — un voile de 3,05 m sur la face est de la lèvre, vu sous
  ≈ 70° d'incidence au lieu de 6, donc sans le vernis de ciel qui délavait la
  teinte ; bords effilochés tirés séparément à gauche et à droite ;
* **la vasque** — BÂTIE : un lit et une berge de gravier trempé, plan d'eau à
  +0,22 m au-dessus du pad, crête de 0,30 à 0,48 m. L'eau n'est plus vue
  contre l'herbe pâle qui la délavait par son alpha de rive ;
* **le déversoir** — une échancrure où la crête tombe au niveau de l'eau, une
  marche bâtie, puis le fil vers l'affluent.

Les quatre surfaces (lit, berge, nappe, fil) partagent le **même rayon haché** :
elles ne peuvent pas diverger d'un centimètre, et un centimètre d'écart entre
l'eau et son lit est un liseré noir.

### 2.3 Mesure au pixel, référence → final

Même outil, même bande turquoise calibrée, mêmes caméras GELÉES.

| | référence `9ecf10d` | final | rapport |
|---|---:|---:|---:|
| eau, part du cadre — **caméra joueur** | 0,81 % | **2,08 %** | ×2,6 |
| colonne d'eau la plus haute — joueur | 35 px | **112 px** | ×3,2 |
| boîte de l'eau — joueur | 418 × 70 px | 715 × 254 px | |
| eau, part du cadre — identité | 0,89 % | **1,21 %** | ×1,4 |
| colonne la plus haute — identité | 55 px | 96 px | ×1,7 |
| teinte de l'eau — joueur | H 188,2 S 0,539 | H 186,9 S 0,523 | inchangée |

La teinte ne bouge pas : ce lot ne portait pas sur la couleur, et elle n'a pas
été touchée.

---

## 3. R-D3 — CINQ RÉGLAGES DANS LE NOIR, PUIS LES MASQUES IMPRIMÉS

Contre le belvédère (dont les silhouettes sont GELÉES), la première version de
ce rework rendait IoU 0,4895 à 30 m et 0,4896 à 80 : sous le seuil officiel,
au-dessus de la limite stricte du lot (seuil − 0,010).

| essai | résultat |
|---|---:|
| `demi_b` 2,25 → 1,72 (affiner la tour) | 0,5037 |
| `demi_b` 2,25 → 2,75 (élargir la tour) | 0,4960 |
| lèvre 2,95 → 3,95 m | 0,4958 |
| table déplacée à l'est | 0,5032 |

Quatre coups dans le noir, dans les deux sens, sans modèle. Ce qui a débloqué
n'est pas un cinquième réglage : c'est d'**imprimer les deux masques
normalisés côte à côte**, au couple d'angles fautif (belvédère 90° × source 0°).
Ils disent la même chose d'un coup d'œil — les deux sujets sont des **bandeaux
plats** au bas d'une toile portrait : sept demi-lignes sur quarante-huit pour
le belvédère, douze pour la source, aires 576 et 846 pour 476 en commun.

La variable est donc le **rapport hauteur / emprise** : 6,23 / 16,49 = 0,38.
La tour passe de 5,90 à 7,60 m (rendu 7,02), le rapport à **0,478**, et le
bandeau devient un profil. C'est aussi le seul des cinq essais qui serve le
verdict artistique — « aucun élément ne domine réellement la caméra joueur ».

**Verdict R-D3 final : PASS.** Témoin dégénéré signalé aux trois distances.

| distance | pire paire de la source | IoU | seuil | limite stricte | marge |
|---:|---|---:|---:|---:|---:|
| 30 m | `watchtower_ruin` | 0,4628 | 0,4931 | 0,4831 | **+0,0203** |
| 80 m | `watchtower_ruin` | 0,4658 | 0,4912 | 0,4812 | **+0,0154** |
| 160 m | `watchtower_ruin` | 0,4548 | 0,5458 | 0,5358 | **+0,0810** |

La paire du belvédère est sortie du haut du tableau. Verdict écrit dans
`verdict_d3_source.json` — jamais dans le `--out` par défaut, qui est celui du
lead.

---

## 4. LES CINQ CONTRÔLES CIBLÉS

`outils/sonde_source.gd`, sur la scène MONTÉE, avec les vrais maillages et les
vrais colliders. Journal : `sonde_finale.json`. **Verdict PASS, 0 écart.**

Elle a rougi quatre fois avant de rendre un vert, et **trois de ces rougeurs
étaient les siennes** — c'est ce qui la rend croyable :

1. « 5,308 m de jour sous le contrefort » : la cellule était sous un SURPLOMB,
   que le générateur EXIGE. Plafond de 0,60 m ajouté.
2. cellules de 0,50 m alors que deux sommets voisins de l'anneau de base sont
   distants de 0,64 m : le contrôle mesurait l'échantillonnage du maillage et
   non son assise. Maille portée à 1,20 m. **Un instrument plus fin que son
   sujet ne mesure que lui-même.**
3. distances de 995 à 997 m au cours d'eau : le heightmap n'est pas un NŒUD
   mais une propriété `_heightmap` du monde ; la recherche échouait et la
   distance à une polyligne VIDE rend 999. Le contrôle passait au vert **en
   n'ayant rien mesuré**. Il échoue désormais si ses données manquent.

La quatrième était RÉELLE et a été corrigée dans le lieu : `Source_seuil` à
6,28 m de la polyligne de l'affluent pour une bande interdite de 6,30.

| contrôle | résultat |
|---|---|
| **1. continuité arrivée → vasque → déversoir** | VISIBLE sur `final/turquoise_spring_joueur.png` : une lame verticale de 112 px sort de la formation, tombe dans la vasque, qui se vide par une échancrure vers le fil. Un seul maillage, un seul matériau. Description, pas verdict. |
| **2. absence de surface flottante** | MESURÉ. Les quatre masses ont un jour maximum NÉGATIF sous toute leur emprise (−0,248 / −0,797 / −0,527 / −0,400 m) : elles descendent partout sous le sol. `FondVasque` tient dans [+0,01 ; +0,48] du sol, `NappeSource` dans [+0,045 ; +3,35] et jamais en dessous. |
| **3. marche réelle** | MESURÉ. Capsule joueur (r 0,40, h 1,70) sur grille de 0,5 m : 1 459 cases libres, **1 458 joignables depuis l'est**. Les cinq cibles de berge et l'ancre de récompense sont joignables. **Témoin négatif** (cœur du contrefort) NON joignable — sans lui, le contrôle verdirait à vide. |
| **4. budget re-sondé sous moteur** | `sonde_budget_lot1.gd` : **11 modules / 13 visuels / 6 collisions** pour un plafond micro de 12 / 30 / 6. Aucun dépassement. Part d'aire runtime 0,0 % (les deux maillages sont nommés dans l'exemption D1a). |
| **5. récompense et interaction INCHANGÉES** | `git diff 529d767 HEAD` sur `discovery_rewards.gd`, `world_v2_layout.gd/.json` et `TurquoiseSpringPlace.tscn` : **vide**. L'ancre est toujours `_seated(-2.4, 2.6) + (0, −0.06, 0)`, le `place_id`, la sphère de découverte (r 12) et le `display_name` sont mot pour mot ceux de la base. C'est la BERGE qui se retire devant le fruit (marge mesurée 1,44 m), jamais la récompense qui s'écarte. |

Filets rejoués, tous VERTS : `lot1_defauts` 11/11 (D1 à D7), `places_contract`
5/5, `places_behavior` 4/4, `cameras` 3/3.

Gel des trois sujets voisins : `sha256sum -c` sur les 23 fichiers épinglés →
**23 OK**. Aucun n'a bougé.

---

## 5. CE QUI RESTE FAIBLE, AMBIGU OU NON VÉRIFIÉ

Je ne rends **aucun verdict artistique** : ce qui suit décrit ce que je vois.

* **La berge rend brun-gris et assez large** au premier plan de
  `final/spring_gros_deversoir.png`. Elle n'est plus l'anneau sombre de
  l'itération 1 ni le béton de l'itération 2, mais sa matière reste ambiguë :
  entre gravier trempé et terre remuée. **Faible.**
* **Le voile s'écarte de la roche au sommet** vu depuis la caméra d'identité :
  un jour de quelques dizaines de centimètres entre la lame et la face de la
  lèvre. Invisible depuis la caméra joueur (qui regarde le long de −X), visible
  de trois quarts. **Ambigu** — c'est le prix payé pour que la roche cesse
  d'avaler la lame.
* **Un rocher olive du semis V2.2 gelé** se tient au bord ouest de la vasque
  (visible sur `final/spring_gros_arrivee.png`, et déjà présent sur la capture
  de référence AU MÊME PIXEL). Il est chaud et sort de la palette froide du
  ravin. Le journal du lot précédent laissait la question ouverte ; elle est
  close : **il n'est pas à moi**, il n'a pas bougé d'un centième, et le semis
  V2.2 est gelé. **Hors de mon périmètre.**
* **Le lieu occupe toujours la seule bande médiane du cadre joueur.** Le talus
  brun tient la moitié haute, l'herbe vide la moitié basse. C'est la
  conséquence directe de la caméra gelée et de l'implantation ; je n'ai pas de
  levier honnête dessus. **Non résolu, et il ne peut pas l'être sans bouger la
  caméra — ce que le contrat interdit.**
* **NON VÉRIFIÉ** : tout ce qui exige un écran, un clavier ou un GPU. Les
  captures viennent du rendu LOGICIEL (llvmpipe) : elles servent la régression
  visuelle, jamais une mesure de performance. Aucune de mes mesures ne dit ce
  qu'un joueur ressentira.
* **ACTION REQUISE DU LEAD, hors de mon périmètre** :
  `docs/assets/ASSET_MANIFEST.csv` porte l'ancien sha256 et l'ancienne taille
  du GLB ; `tools/verifier_manifeste_lot1r.py` rougira à l'intégration. La
  ligne prête est dans `LIGNE_MANIFESTE_A_REMPLACER.txt`.

---

## 6. ADDENDUM — DEUX RÉÉCRITURES D'HISTORIQUE, ET LA RÈGLE QU'ELLES ONT COÛTÉE

J'ai amendé `7c6f5d8` (message mutilé par des accents graves interprétés par
le shell, et qui annonçait un patch dont l'assertion avait échoué sans que je
le vérifie), puis rebasé quatre commits pour rendre au lead une avance rapide.
Les deux gestes partaient d'une bonne intention et étaient **tous les deux des
fautes** : le lead pousse au fil de l'eau, donc `7c6f5d8` et `4472c4a` étaient
déjà publiés. Chaque réécriture a cassé le fast-forward et l'a obligé à ouvrir
une branche de plus (`source2`, puis `source3`).

La règle, désormais explicite pour toute session sur ce dépôt : **l'historique
est ADDITIF.** Une correction — fût-elle d'un mot dans un message ou d'un
chiffre dans un en-tête — est un NOUVEAU commit. Jamais `--amend`, jamais
`rebase`, jamais `reset --hard`. La raison n'est pas le confort du lead : c'est
que la traçabilité entre une preuve datée et le commit qui l'a produite est
tout ce sur quoi repose la vérification. Un commit réécrit transforme un
manifeste de capture en preuve orpheline — ce qui est exactement arrivé au
manifeste de `final/`, qui pointait vers `4472c4a` devenu introuvable, et qu'il
a fallu regénérer.

Ce que j'aurais dû faire, et ce qu'il faut faire la prochaine fois : laisser le
message fautif en place et pousser derrière lui un commit `correctif(journal)`
qui dit ce que le précédent annonçait à tort. Un message faux corrigé
publiquement vaut mieux qu'un message juste obtenu en effaçant le faux.
