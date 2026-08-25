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
