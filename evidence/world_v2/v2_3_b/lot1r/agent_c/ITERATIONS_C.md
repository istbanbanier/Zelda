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
