# Journal d'itérations — agent C (cimetière du tertre)

Règle §9 : chaque entrée est écrite **avant** la modification —
défaut → cause supposée → levier → changement attendu dans les pixels →
caméra qui doit le montrer. Après : parse ciblé, capture, ouverture du PNG à
taille réelle, décision. Deux itérations sur la même hypothèse sans changement
visuel = on cesse de régler des constantes et on vérifie
scène / SHA / caméra / matériau / visibilité.

Worktree exclusif : `/home/user/wt1r1-c`, base `0d77e98`.

---

## Base A/B — et elle n'est PAS celle qu'on croit

Le dossier `lot1r/final/ab13/` porte le commit **`7c58573`**, qui est le PLUS
ANCIEN du lot : entre lui et `HEAD`, `barrow_cemetery_place.gd` a changé de
168 lignes et le GLB a été régénéré. Ses images ne montrent donc pas l'état
jugé.

La base honnête est `lot1r/candidate/ab13/` (commit **`0f90e6e`**,
`repo_dirty: false`), vérifiée identique à `HEAD` au fichier près :

```
git diff --stat 0f90e6e..0d77e98 -- scripts/world_v2/poi/barrow_cemetery_place.gd \
    source_assets/blender/architecture/make_barrow_stones.py assets/architecture/barrow/
(vide)
```

Idem pour les gros plans : `lot1r/candidate/gros_plans/` (`abd8ea0`), même
contrôle, même résultat vide. Ce sont ces deux dossiers qui servent d'avant.

### Mesures de la base (PIL, luminance Rec. 709 sur les octets sRGB)

Sur `candidate/ab13/barrow_cemetery_joueur.png` :

| Zone | p50 | p10 | p90 | RGB moyen |
|---|---:|---:|---:|---|
| Tertre dominant, flanc éclairé | **108,8** | 75,6 | 125,5 | (100, 107, 67) |
| Tertre dominant, dos à l'ombre | 70,5 | 54,7 | 117,9 | (74, 82, 66) |
| Tertre moyen | 115,3 | 68,1 | 120,6 | (103, 113, 79) |
| **Herbe TÉMOIN** (hors lieu) | **110,6** | 102,3 | 118,9 | (104, 117, 68) |
| Coffre | 69,4 | 48,0 | **122,5** | (80, 81, 76) |
| Poteau de gauche | 55,5 | 49,7 | 113,8 | (61, 69, 66) |
| Menhir du seuil | 97,4 | 53,7 | **160,3** | (101, 104, 94) |

**Ce que ces chiffres disent, et c'est le fait central de la passe :** le flanc
éclairé du tertre rend 108,8 quand l'herbe qui le porte rend 110,6 — **1,8
niveau d'écart** — et sa teinte moyenne (100, 107, 67) est celle de l'herbe
(104, 117, 68) au bruit près. Le tertre n'est donc pas « une masse de terre
sous une herbe rase » : c'est **de l'herbe en relief**. C'est exactement le mot
du verdict, « bosses vertes », et il est mesuré.

Le 86,7 du journal de l'agent B n'est pas contredit : il portait sur une AUTRE
zone (`it/t3`, autre lot, autre région du dos). L'objectif « ne pas régresser
la valeur » se lit donc comme : **rester au-dessus de 86,7 sur le flanc
éclairé**, ce qui laisse toute la marge nécessaire pour agir sur la TEINTE.

Et le coffre porte le p90 le plus élevé du cadre après le menhir : c'est
l'objet le plus CLAIR, le seul chaud, et le seul à fort contraste interne
(p50 69 / p90 122). « Le coffre bleu devient le sujet principal » est mesuré
aussi.

---

## C1 — reconstruction : la silhouette des pierres, puis la composition

### Défaut (verdict Codex, inspection réelle)

> « le lieu actuel lit comme des poteaux rectangulaires répartis autour de
> bosses vertes. Le coffre bleu devient le sujet principal. »

Ouvert à ×2 sur `candidate/ab13/barrow_cemetery_joueur.png` (recadrage
230-820 × 180-540), je vois exactement cela et rien d'autre :

1. chaque stèle est un rectangle à **côtés parallèles sur toute sa hauteur**,
   coupé **droit** en haut, portant quatre bandes horizontales franches ;
2. les trois tertres sont des dômes verts lisses, sans affaissement lisible,
   à la valeur ET à la teinte de l'herbe ;
3. rien ne dit où le lieu commence — pas d'entrée, pas d'axe ;
4. le coffre est au centre, en pleine lumière, sur l'herbe, seul objet chaud.

### Cause supposée, et elle est dans le code, pas dans le réglage

**Pour les pierres — `dalle()` de `make_barrow_stones.py`.** La section est un
hexagone aplati **constant**, mis à l'échelle par un seul facteur
`conique = 1 − fuseau·t` avec `fuseau` entre 0,06 et 0,22. Les deux arêtes de
silhouette sont donc les mêmes droites à un facteur près : **elles ne peuvent
pas ne pas être parallèles**. Le jitter (±0,23) agit par sommet et par anneau,
donc il bruite le bord, il ne change pas sa direction. La « tête cassée »
abaisse les six sommets du haut d'une quantité proche : le sommet reste une
coupe quasi horizontale. Aucune quantité de matière (`COLOR_0`, teinte,
rugosité) ne corrige une silhouette. C'est le point que le lead impose :
*si « poteaux rectangulaires » subsiste, reprendre la silhouette avant toute
matière.*

**Pour les tertres — `TERRE` dans le lieu.** `Color(0,264 ; 0,287 ; 0,186)` a
son canal VERT dominant. Rendue, elle donne (100, 107, 67) : la teinte de
l'herbe. La valeur n'est pas le problème (elle a été traitée par l'agent B) ;
la TEINTE l'est.

**Pour le coffre.** Il est à 2,2 m au-delà de la jupe du dominant — calculé, pas
estimé : centre du tertre (−3,5 ; −1,5), demi-axes 5,00 × 3,35, azimut 28° ;
l'ancre est à (−1,5 ; +4,3), soit `u = 4,49`, `v = 4,18`, donc `dn > 1` et
`releve = 0`. Il est **sur l'herbe plate**, et la gueule de chambre est 2 m
derrière lui : elle ne l'encadre pas, elle le double.

### Levier

1. **Générateur — la silhouette d'abord.** `dalle()` reçoit un profil de
   largeur **par côté** (quatre points de contrôle : pied, ventre, épaule,
   tête), une **épaule arrachée**, une **entaille** (éclat manquant), une
   **tête cassée en BIAIS** obtenue en tranchant tous les anneaux hauts par un
   plan incliné denté, et une section **octogonale irrégulière** (les deux
   sommets de silhouette n'ont plus la même distance à l'axe). Cinq familles
   de forme distinctes, aucune paire de pièces identique.
   Une garde `controle_silhouette()` mesure le **remplissage** (aire de la
   silhouette / aire de sa boîte), la **variation de largeur** et la
   **dissymétrie gauche/droite**, et compare aux valeurs de l'ANCIENNE formule
   **recalculées dans le code** : la garde ne peut donc pas accepter la forme
   rejetée.
2. **Lieu — la composition.** Entrée funéraire au sud-ouest (paire inégale +
   seuil bas + rupture du sol) ; axe funéraire incomplet en marques
   appariées convergentes ; dominant allongé, abaissé, à crête courbe et
   affaissement franc ; deux sépultures secondaires nettement plus petites et
   d'orientations franchement différentes (34° / 96° / 152°) ; **gueule
   déplacée pour encadrer le coffre** (deux montants de part et d'autre, un
   linteau glissé au-dessus) et **tranchée d'accès creusée dans le flanc sud**
   du dominant ; déblais en deux banquettes allongées qui bordent le coffre.
3. **Teinte de terre** : `TERRE` passe de (0,264 ; 0,287 ; 0,186) à une valeur
   de **même luminance d'albédo** mais à canal ROUGE dominant.
   Luminance Rec. 709 de l'albédo actuel : 0,2748. Cible : 0,272 ± 0,005.

### Changement attendu dans les pixels

- **Silhouette** : sur un profil horizontal pris à mi-hauteur puis aux trois
  quarts d'une stèle, la largeur en pixels doit CHANGER (elle est constante
  aujourd'hui) ; le bord supérieur doit devenir une ligne oblique et non
  horizontale ; au moins une pierre doit montrer une marche d'épaule.
- **Tertre** : le RGB moyen du flanc éclairé doit passer de R < G à **R > G**,
  p50 restant ≥ 86,7 ; l'herbe témoin, hors lieu, ne doit pas bouger.
- **Coffre** : il doit être encadré par deux verticales sombres et surmonté
  d'un linteau ; son p90 doit cesser d'être le plus haut de la zone du lieu.
- **Entrée** : une paire de pierres inégales doit apparaître dans la moitié
  gauche de `barrow_cemetery_joueur`, au premier plan.

### Caméras qui doivent le montrer

`barrow_cemetery_joueur` (entrée, axe, encadrement du coffre, teinte de terre)
· `barrow_cemetery_identite` (hiérarchie des trois masses, orientations)
· `barrow_gp_gueule` (la gueule autour du coffre) · `barrow_gp_chemin`
(l'axe incomplet) · silhouettes 0/90 en aplat noir (le rectangle survit-il ?).

---

### Après capture — `it/c1/` (commit `07db89c`, manifeste **propre**)

Chaîne : générateur VERT (12 pièces, 1 720 tris / 4 000, `COLOR_0` sur 20
primitives / 20 vérifié dans le JSON du GLB) · `--import` RC=0 ·
`--check-only` RC=0 · **commit** · capture RC=0 · silhouettes RC=0.
L'ordre est celui d'`evidence.md` — le code est committé AVANT la capture.

**Zone TÉMOIN hors lieu, mesurée dans les mêmes images** : herbe p50
110,6 → 110,1, RGB (104, 117, 68) → (104, 116, 68). **Le monde gelé n'a pas
bougé** ; tout ce qui suit appartient au lieu.

| Mesure | base (`candidate/ab13`) | `it/c1` |
|---|---:|---:|
| Tertre dominant, **rapport R/V** | 0,926 | **1,115** |
| Tertre dominant, dos éclairé, p50 | 108,8 | **97,4** |
| Tertre dominant, flanc à l'ombre, p50 | 85,6 | 72,5 |
| Tertre dominant, saturation médiane | 0,244 | 0,271 → 0,321 (dos) |
| **Coffre, p90** (sa pointe claire) | **122,5** | **73,0** |
| Coffre, p50 | 69,4 | 54,6 |
| Emprise du lieu (silhouette) | 23,55 × 4,74 × 19,35 m | **23,55 × 4,84 × 19,21 m** |
| Occupation de la silhouette 0° / 90° | 3,98 % / 4,33 % | 3,10 % / 3,60 % |

L'emprise est tenue : X identique au centième, Y +0,10 m, Z −0,14 m.
L'occupation reste très au-dessus du plancher de 2,0 % de l'outil.

### Ce que je VOIS à taille réelle, et où j'ai dépassé la cible

**Acquis, et ils sont nets :**

- **« Bosses vertes » : traité.** Le rapport R/V passe de 0,93 à 1,12 ; les
  trois masses lisent de la terre, plus de l'herbe en relief. Sur la vue
  d'identité, la hiérarchie 1 : 0,51 : 0,28 et les trois orientations se
  lisent d'un coup d'œil : une tombe dominante et deux tombes secondaires.
- **« Poteaux rectangulaires » : traité, et mesuré.** Aucune pierre n'a plus
  de côtés parallèles ; la garde du générateur refuserait l'ancienne forme.
- **Le coffre n'est plus le sujet.** Sa pointe claire tombe de 122,5 à 73,0
  (−40 %), il est encadré par deux montants, et il se détache maintenant sur
  le dos sombre du tertre au lieu de la prairie.
- **La valeur du dos éclairé (97,4) reste au-dessus de l'acquis de l'agent B
  (86,7)** : la consigne « ne pas régresser » est tenue.

**Dépassements, et ce sont les miens :**

1. **Les pierres sont devenues des LAMES.** À ×3 sur `barrow_cemetery_joueur`,
   plusieurs stèles sont des éclats pointus plantés dans le sol, et la pierre
   de tête est une AIGUILLE de 4,36 m — sur l'aplat noir 0°, c'est une
   antenne. J'ai corrigé le rectangle en fabriquant son contraire. Cause
   exacte, et elle est dans mes constantes : les points de contrôle de tête
   descendaient jusqu'à 0,21, et la chute de cassure valait
   `brisure · 1,55 · biais`, soit jusqu'à 0,48 · hauteur d'un seul côté.
2. **Le linteau flotte.** Son extrémité lointaine est PLUS HAUTE que son appui
   sur le montant B : `rotation.x = −9°` relève le bout au lieu de
   l'abaisser (ordre d'Euler YXZ appliqué après le lacet). Il lit comme un
   plongeoir, et sa face supérieure est lichénée donc VERTE.
3. **Les strates de `COLOR_0` sont redevenues des bandes peintes** à cette
   distance : quatre cycles à contraste 0,30 donnent des rubans clairs à
   bord franc sur chaque pierre.
4. **Le tertre est trop SATURÉ** : saturation médiane 0,32 sur le dos éclairé,
   contre 0,265 pour l'herbe et **0,091** pour les sentiers de terre du monde
   gelé. Il lit sable, pas terre sous herbe rase.
5. Les déblais sont un semis d'éclats anguleux gris — du bruit autour du
   coffre plutôt qu'un tas.

---

## C2 — émousser ce que C1 a trop aiguisé

### Défaut

Les cinq points ci-dessus. Le premier est le seul qui compte vraiment : une
pierre funéraire est une masse ÉPAULÉE, pas une lame.

### Cause supposée

Une seule et même erreur de dosage, répétée : j'ai réglé chaque levier à son
maximum pour être certain de tuer le rectangle. Points de contrôle de tête
jusqu'à 0,21 · `biais` jusqu'à 0,92 · chute de cassure `×1,55` · `brisure`
jusqu'à 0,52 · contraste de strate 0,30 sur quatre cycles · albédo à
saturation 0,41.

### Levier

1. Générateur — **plancher de largeur haute** : points de contrôle de tête
   remontés à 0,44 minimum, dispersion par pièce ramenée de ±0,14 à ±0,10,
   `biais` ramené dans 0,34-0,55, chute de cassure `×1,55 → ×0,95`, plancher
   de hauteur restante 0,42 → 0,55.
2. Générateur — **GARDE 5, « pas d'aiguille »** : la largeur à 86 % de la
   hauteur doit valoir au moins 42 % de la largeur maximale, et la largeur au
   sommet au moins 26 %. Avec la garde 4 (« pas de rectangle »), les deux
   encadrent la réponse par le haut ET par le bas — c'est exactement ce qui
   manquait à C1, qui n'avait qu'une borne.
3. Générateur — strates : 4,0 → 2,6 cycles, contraste 0,30 → 0,22, poids de
   la marche 0,32 → 0,14. L'étendue de `COLOR_0` reste très au-dessus du
   plancher de la garde existante (0,12).
4. Lieu — linteau : `rotation.x` **positif** (+14°) et appui à 2,50 m, calculé
   pour que les deux bouts portent (montant A 2,61 m, montant B 2,02 m,
   dénivelé 0,49 m sur 1,98 m de portée) ; lichen du linteau ramené à sa
   seule embase.
5. Lieu — pierre de tête : échelle (1,55 ; 2,76) → (1,95 ; 2,30), soit
   1,33 × 3,63 m au lieu de 1,05 × 4,36 m. Un menhir, pas une antenne. Le
   collider suit.
6. Lieu — `TERRE` désaturée à luminance d'albédo constante : (0,305 ; 0,272 ;
   0,180) → (0,297 ; 0,272 ; 0,216). Saturation d'albédo 0,41 → 0,27, R/V
   conservé au-dessus de 1.
7. Lieu — déblais : deux éclats au lieu de deux, réduits, et relief de flanc
   du tertre 0,115 → 0,17 pour que le dos cesse d'être une dune lisse.

### Changement attendu dans les pixels

- Sur l'aplat noir 0°, la pierre de tête doit devenir une masse dont la
  largeur à mi-hauteur se mesure, et non un trait.
- Sur `barrow_gp_gueule`, le linteau doit toucher les DEUX montants.
- Sur `barrow_cemetery_joueur`, la saturation médiane du dos éclairé doit
  descendre vers 0,20-0,24 (entre le sentier de terre à 0,09 et l'herbe à
  0,265) sans que le p50 repasse sous 86,7.
- Le profil en travers d'une stèle doit conserver son étendue mais perdre ses
  bords de bande francs.

### Caméras qui doivent le montrer

`barrow_cemetery_joueur` · `barrow_gp_gueule` · `barrow_cemetery_identite` ·
silhouettes 0/90.
