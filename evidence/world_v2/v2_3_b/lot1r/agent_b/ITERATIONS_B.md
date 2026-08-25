# Journal d'itérations — agent B (tour · sanctuaire · cimetière)

Règle : chaque entrée est écrite **avant** la modification —
défaut → cause supposée → levier → changement attendu dans les pixels →
caméra qui doit le montrer. Après : parse, capture, ouverture du PNG à taille
réelle, comparaison, décision. Deux itérations sur la même hypothèse sans
changement visuel = on cesse de régler des constantes et on vérifie
scène / SHA / caméra / matériau / visibilité.

Base A/B : `evidence/world_v2/v2_3_b/lot1r/agent_b/base/` (commit `486556c`,
manifeste propre, 17 vues — les 7 caméras gelées de mes trois lieux + 10
diagnostiques reprises telles quelles de `shots_apres.json`, aucune déplacée).

---

## T1 — Tour de guet : la matière des pièces tombées, et le palier mis en scène

### Défaut

Trois constats de l'audit contradictoire (3ᵉ passage, état `e18d075`) :

- **B-f-4** — « Grande dalle tan au sol, faces planes, arêtes droites, valeur
  unique mesurée (**141 constant**) », `watchtower_gp_breche` (858-1042,
  478-570).
- **B-f-3** — « Les blocs tombés au pied sont des polygones plats posés sur
  l'herbe : arêtes parfaitement droites, aucune épaisseur visible sous cet
  angle, aucun enfoncement dans le sol. »
- **B-f-2** — « Le coffre rend une petite cabane à pignon bleu-gris avec un
  disque brun […] sa famille de teinte n'appartient à aucune matière du lieu. »

Et le constat de mission : la récompense est **au sol, au pied de la brèche** —
donc atteinte AVANT toute ascension. « Du palier, le paysage est la
récompense » n'est pas joué : le palier ne récompense rien.

### Cause supposée — et elle est mesurée, pas devinée

`SM_Watchtower_Ruin.glb` est **le seul des trois GLB de la voie B à ne pas
porter `COLOR_0`** (vérifié en lisant le JSON des trois fichiers : le cimetière
et le sanctuaire l'ont, la tour non). Or ses pièces `tombee` sont peintes côté
Godot par un **aplat** (`ALBEDO_TOMBEE`), sans carte. Une surface sans texture
et sans couleur de sommet ne peut rendre qu'une valeur unique : le constat
transverse de l'audit (point 19) dit exactement pourquoi — sur des faces quasi
verticales sous ce ciel, l'irradiance ambiante domine, donc la facettisation ne
rapporte presque rien.

Pour le palier : il mesurait 1,42 × 1,15 m, dont 1,15 × 0,95 m réservés à la
capsule du joueur par la garde 3 du générateur. Il n'y avait **littéralement
pas la place** d'y poser autre chose — d'où l'absence de mise en scène.

### Levier

1. `make_watchtower_ruin.py` : `COLOR_0` sur les cinq pièces, **consommée** par
   le matériau (nœud Color Attribute multiplié dans Base Color), couche active
   ET de rendu, + garde qui refuse d'enregistrer sans elle (ISS-066 ;
   `gltf_inspect.py` ne regarde jamais `COLOR_0`). Lits d'assise calés sur
   `ASSISE` pour le fût — sur de la maçonnerie les lits sont horizontaux et
   leur pas n'est pas libre — et sur le plus grand axe pour les pièces tombées.
   Contraste fort sur les tombées (seule matière possible), doux sur le fût
   (qui porte déjà une carte).
2. `watchtower_ruin_place.gd` : `vertex_color_use_as_albedo = true` — geste
   jumeau, l'un sans l'autre ne produit aucun pixel.
3. Vigie agrandie à 1,90 × 1,38–1,72 m (~2,9 m² au lieu de ~1,6), **la boîte de
   la garde 3 ne bougeant pas d'un millimètre** ; parapet rompu (cinq moellons
   inégaux, deux ouvertures : l'arrivée de l'escalier et la brèche du parapet
   lui-même) ; pierre de vigie adossée au mur sud.
4. Ancre de récompense sur la dalle, à l'est, hors du volume de la capsule ;
   `requires_traversal = true` et `traversal_base` au seuil de la brèche.
   Position locale, approche et drapeau seulement — ni `Kind`, ni identifiant,
   ni table de butin, ni système.
5. Habillage local du coffre sur une **copie** de matériau (45 % de
   désaturation + refroidissement), recette déjà employée au cimetière.

### Changement attendu dans les pixels

- Les pans tombés et le talus cessent d'être des découpes : un profil de
  luminance en travers d'une plaque doit passer d'une **étendue 0** à une
  étendue de plusieurs dizaines de niveaux.
- Le parement intérieur se creuse (terme `creux`) : le pan sombre doit cesser
  de lire comme « un second appareil collé au premier » (B-f-1).
- Le coffre disparaît du sol de la brèche et apparaît sur le palier, moins
  saturé, à côté d'une pierre basse ; le palier cesse d'être une dalle nue.

### Caméras qui doivent le montrer

- matière : `watchtower_gp_breche` (la dalle à 141 constant), `watchtower_gp_arase` ;
- palier : `watchtower_gp_vigie_pov` (le POV du palier) ;
- mise en scène : `watchtower_ruin_joueur` (le coffre ne doit plus y être au sol) ;
- silhouette inchangée à vérifier : `watchtower_ruin_identite`.

### Après capture — `it/t1/` (arbre SALE, diagnostic, non versé comme preuve)

Chaîne : `export_lieux_voie_b.sh watchtower_ruin` VERT (1 182 tris, budget
12 000 ; `COLOR_0` 5 pièces, active ET de rendu, étendue min 0,707 ; dalle de
vigie 2,862 m²) · `--import` RC=0 · `--check-only` RC=0 · capture RC=0.

**Deux refus du générateur avant le vert, et tous deux sont des acquis.**

1. « vigie absente (4 sommets à z=3,05 dans le quart SO) ». La garde comptait
   les sommets vérifiant `x < −0,30 et y < −0,55` — ce n'étaient pas les
   bornes du quart sud-ouest, c'était **la position du bord déchiré de la
   dalle d'alors**. En agrandissant la dalle, son bord est parti au nord et la
   garde a refusé une dalle **deux fois plus grande** que celle qu'elle
   acceptait. Elle mesurait la forme d'hier. Remplacée par une AIRE (lacet de
   Gauss sur le contour réel) dont le plancher est **l'ancienne dalle
   elle-même**, recalculée dans le code : 1,546 m². La garde ne peut donc pas
   accepter moins qu'avant. Mesure publiée : 2,862 m².
2. « 1 sommet dans le volume de la capsule ». `moellon` déplace ses huit
   sommets de ±0,30 : une pierre de centre `c` et de taille `d` s'étend de
   `c ± 0,575·d`. Placer le CENTRE hors de la boîte ne suffit pas. La garde
   nomme désormais les coordonnées fautives — deviner lequel des huit sommets
   dépasse coûte une demi-heure, et l'a coûtée ici.

**Mesures avant → après**, mêmes lignes que l'audit, mêmes fichiers :

| Sujet | Vue, ligne | Base | it/t1 |
|---|---|---|---|
| Pièce tombée, premier plan | `..._joueur`, y=515, x 640→820 | 27 valeurs, étendue 84,9 | **36 valeurs**, étendue 70,3 |
| Plaque tan | `..._joueur`, y=478, x 890→1060 | 32 valeurs, étendue 82,8 | **39 valeurs**, étendue 99,2 |
| Coffre (RVB moyen) | `gp_vigie_pov` | — | (66, 65, 66) |

La plaque tan a bougé : elle **est** donc bien une pièce `tombee` du GLB. Elle
a été identifiée par l'intervention, pas par un `unproject_position` dont
`tools/CLAUDE.md` dit que l'axe Y ment en exécution `--script`.

### Ce que je VOIS à taille réelle

- Pièces tombées : **visible mais faible**. Chaque facette a gagné un dégradé
  interne là où elle rendait un gris uni ; les silhouettes, elles, restent des
  polygones plats à arêtes droites posés sur l'herbe. `COLOR_0` apporte du
  dégradé, pas de la structure : le reste de B-f-3 est un défaut de **forme et
  d'assise**, pas de matière. → traité en T2 par l'enfoncement, pas par plus
  de couleur.
- Palier : **visible et net**. `gp_vigie_pov` montre vallée, rivière, hameau et
  pylône, avec le parapet rompu à droite du cadre et le coffre sur la dalle.
  L'intention « du palier, le paysage est la récompense » est jouée.
- **Régression introduite, et elle est à moi** : à 1,3 m de l'œil, le coffre
  occupe le quart de la vue-récompense et masque le bas du paysage. C'est
  précisément l'acquis que l'audit portait au crédit du lieu (B-f-15). Corrigé
  en T2.
- **L'habillage n'a pas fait ce que je croyais** : RVB moyen (66, 65, 66),
  donc neutre en moyenne — mais les ferrures, qui portent une TEXTURE, restent
  franchement bleues. Mes facteurs (0,74 / 0,77 / 0,83) atténuaient le bleu
  MOINS que le rouge : recopiés du cimetière, où l'intention était de
  refroidir un coffre trop chaud. Ici l'objet est déjà bleu ; il fallait
  l'inverse.

---

## T2 — trois lieux dans un même lot (caméras disjointes)

Trois hypothèses indépendantes, jugées chacune sur ses propres vues. Elles
sont regroupées en une seule chaîne parce que le verrou du moteur est PARTAGÉ
avec les autres agents et qu'un lancement coûte à tout le monde ; elles restent
séparément attribuables parce qu'aucune ne touche les cadres d'une autre.

### T2-a — Tour : rendre le palier habitable sans sacrifier la vue

Défaut : le coffre masque le paysage (régression de T1) ; les pièces tombées
n'ont pas d'assise ; les ferrures du coffre sont bleues.
Cause : dalle trop courte (1,90 m) — le mobilier ne pouvait aller que dans
l'axe du regard ; aucun enfoncement sur le talus ; facteurs de teinte inversés.
Levier : baie est (dalle 2,325 m), coffre et pierre de vigie recalés, talus
enfoncé de 14 cm et traînée de 11 cm, facteurs de teinte inversés (bleu ×0,64).
Attendu : le coffre recule de 1,3 à 1,7 m (surface apparente ×0,58) et quitte
le centre ; le talus perd sa ligne de contact nette ; les ferrures grisent.
Caméras : `watchtower_gp_vigie_pov`, `watchtower_ruin_joueur`.

### T2-b — Sanctuaire : donner au lieu une EMPRISE

Défaut : le lieu occupe **1,7 % de sa propre vue d'identité** (155 × 100 px
mesurés sur `base/forest_shrine_identite.png`) ; B-f-6 le dit depuis la vue
joueur. Et de près, chaque pierre porte une bande de mousse à bord net et
horizontal, toutes à la même hauteur relative — une pierre trempée dans la
peinture.
Cause : la hauteur est INTERDITE comme levier (contrat d'invisibilité depuis
la route, 2,4 m). Restait l'emprise, qui n'avait jamais été employée. Et
`pied = 0,30 · haut` est une constante par pièce, donc une ligne de niveau.
Levier : enceinte élargie ×1,5 (entraxe du seuil 2,68 → 3,90 m) + quatre
marques d'angle basses sans collider + dallage porté de 3 à 9 dalles
irrégulières ; chaussette de mousse modulée par l'orientation (face abritée à
l'est) et par un grain de position.
Attendu : depuis l'identité, une empreinte plus sombre que l'herbe dessine un
périmètre là où il n'y avait qu'un tas ; de près, aucune bande de mousse
horizontale.
Caméras : `forest_shrine_identite`, `forest_shrine_joueur`, `shrine_gp_nef`,
et `shrine_gp_route_p1` qui doit continuer à montrer PEU.

### T2-c — Cimetière : l'ombrage du tertre, et les stèles peintes

Défaut, vu à l'agrandissement de `base/barrow_cemetery_joueur.png` : le dos du
tumulus est rond — la géométrie est corrigée — mais il est couvert de bandes
claires et sombres rayonnant de la crête à la lisière : une **citrouille**. Et
les stèles portent quatre à cinq bandes horizontales franches à pas régulier.
Cause, trouvée à la ligne : `_triangle_degrade` calculait la normale de FACE
et l'appliquait aux trois sommets — c'est la définition de l'ombrage plat, et
aucun réglage de profil ne pouvait le corriger. Les passes précédentes
attaquaient la forme ; ce qui restait radial était **l'éclairage**. Pour les
stèles : à 0,65, la marche de quantification domine l'onde et impose des
paliers plats.
Levier : normales lissées par différences finies sur la grille du dos
(`_normales_de_grille`), y compris l'éventail de crête ; poids de la marche
0,65 → 0,32.
Attendu : le dos devient une masse continue sans structure angulaire ; les
stèles gardent leur étendue (23 valeurs, 97 niveaux mesurés) mais perdent
leurs paliers.
Caméras : `barrow_cemetery_joueur`, `barrow_gp_gueule`, `barrow_cemetery_identite`.

**Non traité à ce stade, et assumé** : la valeur rendue du tertre
(p50 = 68,4 contre 113,0 pour l'herbe, soit 45 niveaux d'écart — la réserve
« très bruns et sombres » est confirmée par la mesure). Elle est volontairement
laissée pour l'itération suivante : lisser les normales change la valeur
moyenne, et la recaler maintenant reviendrait à calibrer sur un chiffre
périmé.

### Après capture — `it/t2/` (commit `bc484a2`, manifeste **propre**)

Chaîne : trois GLB régénérés VERT · `--import` RC=0 · trois `--check-only`
RC=0 · capture RC=0. Zone TÉMOIN hors lieu, mesurée dans les mêmes images :
herbe du cimetière p50 113,0 → 113,0 ; herbe du sanctuaire p50 87,8 → 87,9.
**Le monde gelé n'a pas bougé** — les écarts qui suivent appartiennent bien
aux lieux.

#### T2-a Tour — **visible**

| Sujet | Vue, ligne | base | t2 |
|---|---|---|---|
| Éboulis premier plan | `joueur`, y=560 | 37 valeurs | **52 valeurs** |
| Ancien emplacement du coffre | `joueur`, zone | RVB (84, 88, 89) | **(62, 69, 58)** |
| Pixels bleutés du coffre | `gp_vigie_pov` | 53 334 (t1) | **31 624 (−41 %)** |

Ce que je vois : le coffre a quitté le sol et **s'aperçoit là-haut par la
brèche** depuis la vue joueur — on comprend qu'il faut monter. Depuis le
palier, la vallée est rouverte sur les deux tiers gauches et le coffre est
devenu un premier plan de bord de cadre, ferrures gris-fer et non plus bleu
vif. L'éboulis est mieux assis. L'intérieur de la tour montre enfin un plancher
et une tranche d'arase depuis `identite` — la nuance de B-f-1.
**Reste** : la grande plaque tan à droite de la vue joueur est toujours une
face plane à arête droite ; elle a gagné de la matière, pas de la forme.

#### T2-b Sanctuaire — **visible, insuffisant**

Emprise de pierre dans la vue d'identité, mesurée par masque de saturation :
**185 × 134 px → 258 × 154 px**, pixels de pierre 6 684 → 7 980 (+19 %).
`shrine_gp_route_p1` ne montre **toujours rien** du lieu : l'élargissement n'a
pas cassé le contrat d'invisibilité depuis la route, et c'était le risque.

Ce que je vois : le lieu n'est plus coupé en deux par le tronc gelé — il
déborde des deux côtés. Les chaussettes de mousse ne sont plus toutes à la
même hauteur. Mais **chaque chaussette reste une bande à bord net**, et la
cause est structurelle et nommable : la mousse est un MATÉRIAU PAR FACE sur
une pierre de 58 à 196 triangles ; une face est moussue ou ne l'est pas, il
n'existe aucun dégradé possible. Varier la hauteur par face déplace le bord,
elle ne l'adoucit pas. Le corriger demanderait de porter la mousse par
`COLOR_0` ou par une carte, pas par un index de matériau — c'est une reprise
de fond, pas un réglage.
Le lieu ne lit toujours pas « un seuil → une enceinte → un cœur » : le
vocabulaire est un prisme dressé répété neuf fois.

#### T2-c Cimetière — **visible et net sur le tertre**

**La mesure que j'avais choisie n'a rien vu, et c'est le fait le plus utile de
cette itération.** Sur le flanc du dos : p50 68,4 → 69,8, étendue p10-p90
identique à 59,1, valeurs distinctes 61 → 62. Autrement dit rien — alors que
l'image, ouverte à taille réelle, montre sans ambiguïté que les bandes
radiales ont disparu.

Moyenne, percentile et compte de valeurs distinctes sont **aveugles à
l'arrangement spatial** : une surface lisse et une surface rayée peuvent avoir
exactement la même distribution. C'est ISS-018 sous une autre forme — un
chiffre juste sur une grandeur qui n'est pas celle qu'on croit mesurer. D'où
`oscillations()` dans `tools/mesure_valeur.py` : le nombre de renversements de
pente compte les BANDES.

Sur une ligne entièrement dans le tertre secondaire, sans stèle pour polluer :

| Ligne | base | t2 |
|---|---|---|
| y=375, x 1010→1230 | 4 renversements, profil en sauts (72..82, 85..90, 95, 99) | **0 renversement**, rampe continue 75…90 |
| y=390, x 1010→1230 | 2 renversements | **1 renversement** |

Le recadrage à ×4 est sans appel : avant, six à sept panneaux séparés par des
plis nets ; après, un renflement continu. La citrouille est morte.
Les stèles passent de 23 à 33 valeurs distinctes en travers (y=430) : la
quantification s'est adoucie sans perdre l'étendue.

**Reste, et c'est nommé** : le tertre est toujours 43 niveaux sous l'herbe
(69,8 contre 113,0) — la réserve de revue tient. → traité en T3.

---

## T3 — la valeur de la terre, l'assise des stèles, le cœur du sanctuaire

Trois changements, tous en GDScript (aucun générateur touché, donc aucun GLB
régénéré). Journal et raisons complets dans le message du commit `26c9d2d`.
Chaîne exécutée dans l'ordre imposé par `evidence.md` : parse → **commit** →
capture, pour que le manifeste porte un arbre propre et le hash prouvé.

Défaut → cause → levier → attendu → caméra :
- Tertre 43 niveaux sous l'herbe → albédo `TERRE` calé pour une bande de
  valeur qui n'est plus la bonne → ×1,55, raisonné depuis la sortie sRGB visée
  et non tâtonné → p50 du flanc vers ~90, écart ramené à ~22 niveaux →
  `barrow_cemetery_joueur` (avec la même zone témoin d'herbe).
- Stèles posées sur l'herbe, ligne de contact nette → enfoncement à 0,0 →
  0,26 / 0,20 / 0,15 m + deux inclinaisons d'un cran, colliders suivis →
  les pierres émergent au lieu d'être posées → `barrow_cemetery_joueur`,
  `barrow_gp_chemin`.
- Table du sanctuaire vue de champ, aussi large qu'un socle → jamais élargie →
  +30 % en XZ SEULEMENT (l'axe Y porte `TABLE_DESSUS`, dont dépend l'ancre) →
  le cœur domine les murs → `shrine_gp_nef`, `shrine_gp_coeur`.

### Après capture — `it/t3/` (commit `26c9d2d`, manifeste **`repo_dirty: true`**)

> **Aveu, et il compte.** Le lot `it/t3` est complet et son code est bien celui
> de `26c9d2d`, mais son manifeste porte `repo_dirty: true` : j'éditais CE
> FICHIER pendant que le moteur rendait. Le seul fichier sale au moment de
> l'écriture du manifeste était `ITERATIONS_B.md` — vérifié par
> `git status --porcelain --untracked-files=no`, un document, ni code ni asset.
> Mais `.claude/rules/evidence.md` ne connaît pas les demi-mesures : *« une
> capture prise d'un arbre sale ne prouve rien et ne doit pas être versée »*.
> **`it/t3` est donc un lot DIAGNOSTIQUE, pas une preuve de gate**, et les
> chiffres ci-dessous se lisent comme tels. Le remède est mécanique — recapturer
> d'un arbre propre — et coûte un lot complet (~50 min de verrou partagé) ; je
> le laisse à l'arbitrage du lead plutôt que de le prendre sur le temps commun.
> `it/t2` (`bc484a2`), lui, est propre.

Chaîne : `--import` RC=0 · deux `--check-only` RC=0 · **commit** · capture.
L'ordre est celui d'`evidence.md` — le code est committé AVANT la capture qui
le prouve, pas l'inverse.

#### Cimetière, la valeur — **visible, et l'objectif est atteint à 1,3 niveau près**

| Zone | t2 | t3 |
|---|---|---|
| Flanc éclairé du dos | p50 **69,8**, p10 37,8 | p50 **86,7**, p10 56,4 |
| Herbe TÉMOIN, même image | p50 113,0 | p50 **113,0** |
| Écart tertre ↔ herbe | **43,2 niveaux** | **26,3 niveaux** |

Visé : 20 à 25. Obtenu : 26,3 — un cran au-dessus, sans nouvelle itération,
parce que l'écart restant est du bon ordre et que le tertre doit rester plus
sombre que la steppe. Le p10 qui monte de 37,8 à 56,4 compte autant que la
médiane : le flanc à l'ombre n'est plus un noir bouché.
Le témoin est identique **au dixième** : l'écart appartient bien au lieu.

Ce que je vois : les dos se lisent désormais comme de la **terre sous une
herbe rase**, pas comme des ombres portées. Les trois masses se distinguent
enfin les unes des autres et du sol.

#### Cimetière, l'assise — **visible**

Les trois stèles dressées s'enfoncent de 0,26 / 0,20 / 0,15 m et leurs corps
suivent. Sur la capture, leur pied disparaît dans l'herbe et dans le flanc des
dos au lieu de rencontrer le sol sur une ligne nette : « les tombes émergent de
la colline » cesse d'être une phrase.

#### Sanctuaire, le cœur — **faible**

Largeur de la dalle de table sur `shrine_gp_nef`, ligne y=378 : **236 → 283 px**
(+20 % ; le gain est inférieur aux 30 % appliqués à cause du raccourci
perspectif, ce qui est cohérent). La table est donc mesurablement plus large et
porte maintenant une ombre propre sous son plateau.
Mais je ne prétendrai pas que « le cœur domine les murs » : à cette caméra, le
lieu se lit encore comme une dispersion de fûts gris de même famille. Le gain
est réel et petit.

---

## S2 — sanctuaire : l'itération structurelle demandée par le lead

Le lead a retenu comme cause de rejet **mon propre constat** : « neuf pièces
sur neuf sont le même prisme dressé ». Trois RÔLES dessinés avec UNE forme —
à trois secondes, l'œil répond « des pierres ». Ni la valeur ni l'implantation
n'y pouvaient rien, et les deux passes précédentes l'ont prouvé en les
corrigeant sans que la lecture change.

Quatre gestes, tous dans le générateur que je possède, emprise inchangée :

1. **`SM_Shrine_Coeur`** remplace `SM_Shrine_Table` **et** `SM_Shrine_Chevet` —
   une masse unique : dalle fendue élargie, deux dés, deux **contreforts** bas,
   un **dossier** qui monte derrière. Silhouette d'enclume. Deux prismes de
   moins au compte.
2. **`SM_Shrine_Linteau`** — un bloc **taillé** (trois côtés droits, un bout
   rompu en dents de scie) couché en travers du seuil. La seule pièce du lieu
   qui porte une trace d'outil.
3. **Deux socles couchés** (roulis 90°, enfoncés de 13 cm), choisis pour
   qu'aucune paire couchée ne se fasse face.
4. **Frontière de mousse adoucie par la GÉOMÉTRIE** : les arêtes de la bande de
   transition sont coupées deux fois avant la pose. On ne change pas la règle,
   on change la géométrie qu'elle décore.

### Gardes du générateur, toutes vertes

| Garde | Mesure |
|---|---|
| Plafond d'identité | pièce la plus haute **2,01 m** (générateur 2,20 ; lieu 2,40) |
| Budget | **4 850** tris / 6 000 — la subdivision coûte, elle tient |
| Cœur, emprise | **2,69 × 1,72 m** contre 0,6 × 0,5 pour un socle |
| Fente de la dalle | 332 sommets, glissement **0,288 m** |
| `COLOR_0` | 9 pièces, active ET de rendu |

### Après capture — `it/s2/` (commit `2fcc348`, manifeste **propre**)

| Mesure | t2 | s2 |
|---|---|---|
| Emprise de pierre, vue d'identité | 258 × 180 px | **258 × 178 px** |
| Pixels de pierre, même cadre | 8 465 | **8 851** |

**L'emprise ne bouge pas, la masse augmente** : exactement la consigne du lead
(rester dans ≈4,7 × 5,5 m pour ne pas re-changer la donne R-D3).
`shrine_gp_route_p1` est **identique** à t2 — rien du lieu depuis la route ;
le contrat d'invisibilité tient, et il le devait : le cœur culmine à 2,01 m
contre 2,05 m pour le chevet qu'il remplace, donc plus bas qu'avant.

Ce que je vois, recadré ×2 sur `shrine_gp_nef` : avant, un poteau étroit
traversé d'une planche ; après, une masse à épaules larges avec sa dalle
ombrée dessous et l'offrande posée dessus — un cœur, pas un socle de plus.
Une pierre couchée supplémentaire apparaît au sol. Et les frontières de mousse
qui étaient des lignes droites sont devenues des bords **dentelés à deux
niveaux**.

### Un échec de mesure, et je l'arrête au deuxième essai

J'ai voulu chiffrer la dentelure de la frontière de mousse. **Deux tentatives,
deux résultats identiques au centième entre t2 et s2** — ce qui est
impossible si l'image a changé. Un diff pixel l'a expliqué : la zone qui bouge
est x 320-800, et mon détecteur balayait des colonnes en x 45-200, c'est-à-dire
un **caillou du kit** que mon générateur ne touche pas ; le second essai, lui,
trouvait la frontière herbe/fond avant d'atteindre la pierre.
Conformément à la règle des deux échecs, je n'ai pas réglé une troisième fois :
la dentelure est **constatée à l'œil sur recadrage ×2, non chiffrée**. La
leçon est la même que celle déjà consignée ce soir — vérifier ce que la mesure
regarde AVANT de croire ce qu'elle dit.

---

## Ce qui reste, nommé

1. ~~Sanctuaire — le vocabulaire.~~ **Traité en S2** : le cœur et le linteau
   sortent de la famille du prisme dressé, deux socles sont couchés. Ce qui
   subsiste est voulu — les six pierres de l'enceinte restent des fûts, parce
   qu'une enceinte EST une répétition ; ce sont les trois rôles qui devaient
   se distinguer, et ils se distinguent.
2. ~~Sanctuaire — la mousse.~~ **Traité en S2 par la géométrie** plutôt que par
   la règle : subdivision de la bande de transition avant la pose. Constaté à
   l'œil, **non chiffré** — voir l'échec de mesure ci-dessus.
3. **Cimetière — la forme des stèles.** Ce sont encore des dalles à côtés
   parallèles et bouts coupés net. Enfoncées et inclinées, elles sont mieux
   assises ; elles ne sont pas cassées.
4. **Tour — la grande plaque tan** de la vue joueur reste une face plane à
   arête droite. `COLOR_0` lui a donné du dégradé, pas du volume.
5. **Le coffre**, aux deux lieux qui en portent un, reste l'objet le plus
   saturé de son cadre. Il est habillé LOCALEMENT au maximum de ce qu'une
   copie de matériau permet (−41 % de pixels bleutés à la tour) ; au-delà, le
   modèle est une ressource **partagée** et ne m'appartient pas — c'est le
   point 17 transverse de l'audit, à trancher par le lead.
6. **Vérification R-D3 : DUE, NON EXÉCUTÉE.** L'emprise du sanctuaire change
   (≈ 2,7 × 4,5 m → ≈ 4,7 × 5,5 m) et le coordinateur l'a explicitement
   demandée. Elle exige un lot de silhouettes en aplat noir puis le détecteur :
   ```
   tools/lancer_godot.sh --rendu --path . --script tools/godot/capture_silhouette.gd -- …
   python3 tools/lot1_repetition.py --manifestes <…> --out <…>
   ```
   Je ne l'ai pas lancée : le verrou du moteur est partagé et chaque lot de
   captures a coûté ~50 min ce soir. **Statut : `NON VÉRIFIÉ`**, à ne pas
   convertir en `PASS` par déduction.

**Les deux autres vérifications demandées par le coordinateur sont, elles,
faites et négatives** — c'est-à-dire qu'il n'y avait rien à corriger :
- **filet D4 / caméras gelées** : le sanctuaire n'a pas été DÉPLACÉ, seulement
  élargi ; aucune caméra n'a bougé ; les quatre marques d'angle ajoutées sont
  des `Socle_C` de 0,60 m, sous la hauteur de marche, donc **sans collider** —
  le filet des routes ne compte que les corps solides. Contrôle visuel direct :
  `it/t2/shrine_gp_route_p1.png` ne montre toujours **rien** du lieu depuis la
  route à 7,3 m, ce qui est le contrat d'identité du sanctuaire.
- **ancre de récompense** : au sanctuaire elle n'a pas bougé (la table s'élargit
  en XZ seulement, `TABLE_DESSUS` inchangé à 0,89 m). À la tour elle a bougé
  volontairement — position locale, point d'approche et `requires_traversal`
  uniquement, avec `traversal_base` au seuil de la brèche ; ni `Kind`, ni
  identifiant, ni table de butin, ni système.

---

# PASSE 1.R.1 — après le verdict Codex (tour PARTIAL, sanctuaire REJET)

Base A/B : `candidate/ab13/` et `candidate/gros_plans/` — **ce sont bien les
images de HEAD** pour mes deux lieux, et je l'ai vérifié au lieu de le supposer :
`git log` donne `2323be5` comme dernier commit de la tour et `4f66609` comme
dernier du sanctuaire, tous deux ancêtres du commit de capture ; entre le commit
de capture et HEAD, `git log --name-only` ne montre qu'un fichier de code,
`flower_field_place.gd`, qui n'est pas à moi. Aucune recapture de base n'est donc
nécessaire, et c'est ~50 min de verrou partagé économisées.

## R1 — ce que je vois moi-même sur les deux images de base

Ouvertes à taille réelle, plus un recadrage ×2 du cœur de chaque cadre.

**Tour, `watchtower_ruin_joueur.png`.** Le fût occupe x 345-790. À gauche, la
travée est debout, éclairée, texturée. À droite d'elle, **une seule grande masse
sombre de 320 × 450 px** — le parement intérieur du mur ouest et le retour du
mur nord. Trois corbeaux en sortent, le coffre se voit tout en haut à gauche, et
c'est TOUT. Aucune ouverture, aucun plancher, aucun retrait, aucune diagonale.
L'entrée n'est pas un seuil : c'est une encoche sombre entre deux masses sombres.

**La mesure ne dit PAS « aplat », et c'est important.** Profil en travers de
cette masse (`tools/mesure_valeur.py ligne … y=200 x 480→760`) : étendue 79,1 ;
65 valeurs distinctes ; 47 renversements. La carte de brique varie beaucoup.
Le reproche de Codex — « sa plaque intérieure demeure uniforme » — ne porte donc
pas sur la luminance : il porte sur la **structure**. Cinq mètres sur huit de
mur sans un seul événement construit. Aucune quantité de matière ne le corrige ;
il faut des trous, des retraits et des planchers.

**Tour, silhouette 0°.** `silhouette_watchtower_ruin_000.png` : un rectangle
noir plein de 265 × 510 px, **sans un seul trou**. Une ruine qui ne laisse pas
passer le ciel n'est pas une ruine, c'est un bloc. C'est là que « trop mince »
se lit le plus durement : à 86 m (`watchtower_gp_lointain`), la tour est un
bâton de 50 × 95 px qui se confond avec la falaise grise derrière.

**Sanctuaire, `forest_shrine_joueur.png`.** Le tronc gelé occupe x 594-718
(mesuré colonne par colonne sur les pixels bruns, y 300 à 510) — 124 px de
large, du haut du cadre jusqu'au sol. Le cœur est à x 640 : **exactement
derrière**. Le seuil, lui, projette à x 730-813, c'est-à-dire de l'autre côté du
tronc. Le lieu est donc coupé en deux par le tronc, et ses deux pièces
maîtresses sont chacune d'un côté. Rien ne peut se lire ainsi.

## R1 — géométrie de la vue joueur du sanctuaire, calculée et non estimée

Repère local du lieu (site (86 ; 74)). Caméra `forest_shrine_joueur` en local
(5,5 ; −9,5), visée locale (0 ; 0), fov **vertical** 65° sur 1280 × 720 — donc
`tan_h = tan(32,5°) × 16/9 = 1,1327` pour 640 px.

Avec `f = (−0,5005 ; 0,8645)` et `droite = (−0,8654 ; −0,5011)` (le repère
d'une caméra Godot, `droite = f × haut`, vérifié sur un cas connu) :

| pièce | local | distance a | tan | x écran |
|---|---|---:|---:|---:|
| cœur | (0,00 ; 0,00) | 10,97 | 0,000 | **640** |
| montant A | (−0,94 ; −3,52) | 8,39 | +0,307 | 813 |
| montant B | (0,82 ; −3,74) | 7,32 | +0,159 | 730 |
| marche | (−0,05 ; −3,00) | 8,40 | +0,184 | 744 |
| tronc gelé (déduit du cadre) | ≈ (2,2 ; −4,3) | ≈ 6,2 | +0,044 | 665 |

Le tronc est donc à **0,28 m de l'axe caméra→centre**, 4,8 m devant le cœur :
il est planté exactement là où devrait se trouver le seuil. Aucun réglage de
matière ne répare ça — c'est une question de plan.

**Bande d'occultation du tronc, en tangente : [−0,081 ; +0,138].** Tout ce qui
est derrière lui et dans cette bande est caché. Le cœur doit en sortir.

## R1 — ce que je change, et le changement attendu dans les pixels

### Tour — de la façade au volume habité

| défaut | cause | levier | attendu dans les pixels | caméra |
|---|---|---|---|---|
| « trop mince » | mur de 0,45 m pour 9 m de haut ; empreinte 4,45 m ; jamais une arase vue en coupe | épaisseur 0,45 → 0,85 m en croissant VERS L'EXTÉRIEUR (nu intérieur inchangé à ±1,775) + empattement bas | l'arase de la travée est, vue de dessus à 5,5 m, devient une bande de pierre au lieu d'un fil ; la masse s'élargit de 16 % dans les trois vues | `joueur`, `identite`, `gp_lointain` |
| plaque intérieure sans structure | aucune ouverture, aucun retrait, aucun plancher | baie ouest au 2ᵉ niveau + meurtrière nord ; retrait de maçonnerie continu à 3,05 m et 5,95 m ; fragment de plancher haut | un TROU clair dans la masse sombre ; deux lignes horizontales qui la coupent en registres | `joueur`, `gp_breche` |
| silhouette sans trou | idem | les mêmes ouvertures | la silhouette 0° cesse d'être un rectangle plein | `silhouette_000/090` |
| entrée illisible | la brèche n'a ni seuil, ni linteau, ni jambage lisible | pierre de seuil + linteau rompu couché en avant + jambages relevés | une porte se lit à 5 m | `joueur`, `gp_breche` |
| ascension invisible | l'escalier est dans l'ombre et n'offre aucune diagonale | volée 1 avancée jusqu'au seuil (x 0,85 → 1,28, 7 marches) + mur d'échiffre rampant | une DIAGONALE claire traverse la masse sombre — le seul signe qui dise « on monte » | `joueur`, `gp_breche` |
| gravats non solidaires | le talus est un tas à côté | l'empattement et les jambages donnent au tas une origine visible | le tas part du manque du mur | `joueur` |

### Sanctuaire — recomposer autour de l'arbre gelé

| défaut | cause | levier | attendu dans les pixels | caméra |
|---|---|---|---|---|
| l'arbre masque le lieu | le cœur est à tan 0,000, dans la bande [−0,081 ; +0,138] | **rotation + translation des offsets LOCAUX** : l'axe de nef bascule de ≈ 35° et le lieu glisse de ≈ 1,6 m, pour que cœur ET seuil sortent de la bande **du même côté** | le cœur passe de x 640 à x ≈ 530-570 ; le seuil à x ≈ 420-500 ; le tronc à 665 devient le montant DROIT du cadre | `forest_shrine_joueur` |
| pas de hiérarchie | six socles dressés de 0,70 à 1,13 m contre un cœur de 2,01 m | les six socles + quatre marques d'angle deviennent **trois murets rompus** de 0,55 à 0,85 m, faits de blocs liés | le cœur domine d'un facteur 2,6 au lieu de 1,8 ; l'enceinte cesse d'être un cercle de pierres | `joueur`, `identite` |
| « prismes droits » | fûts isolés à sommet peu cassé | blocs liés à silhouette rompue, enfoncés | une ruine, pas un amas | `identite`, `gp_nef` |

**Ce que je ne touche pas, et je le vérifierai** : l'arbre gelé, les caméras, le
plafond d'invisibilité du générateur, `shrine_gp_route_p1` (doit continuer de
montrer PEU), D7 ≤ 40 modules (le remplacement de 10 pièces par 3 REND 7
modules), l'identifiant et le genre de récompense. L'ancre de récompense du
sanctuaire est posée SUR la dalle du cœur : elle suit le cœur, et je le dis.

## R1 — après capture (`it/r1/`, commit `07c230e`, manifeste **propre**)

Chaîne : générateurs VERTS → export glTF VALIDE → `--check-only` RC=0 sur les
deux scripts → **commit** → `--import` → capture. L'ordre est celui
d'`evidence.md` : le code est committé AVANT l'image qui le prouve.

### Tour — ce que je VOIS à taille réelle

**Visible et net.** La baie du mur ouest est un **trou clair** au milieu de la
masse sombre, à x 577-622 / y 107-175. C'était l'objet de la correction, et
c'est le seul geste dont l'effet ne demande aucune interprétation : une
ouverture se lit parce que ce qu'on voit à travers est plus clair que le mur.

**Visible.** L'empattement double la lecture du pied ; le fût occupe x 260-830
au lieu de 345-790 ; la silhouette 0° porte **deux trous** là où elle était un
rectangle plein de 265 × 510 px. Emprise du lieu, manifeste de silhouette :
**13,11 → 14,06 m** en X (Y et Z inchangés — ils sont portés par les gravats,
pas par le fût).

**ÉCHEC, et il est à moi.** La PORTE n'existe pas dans l'image. Mesuré :
zone de la porte prédite (355-410 × 400-540) p50 **56,3** ; mur voisin
(430-490 × 400-540) p50 **56,8**. Zéro contraste, donc zéro trou.

La cause, trouvée en relisant les cotes et non en tâtonnant : la baie était
percée en `y −2,175..−1,575`, et le **mur sud occupe `y −2,625..−1,775` sur
toute la largeur du fût, angle compris**. Les deux tiers bas de la porte
débouchaient dans la masse de l'angle sud-est. Le générateur comptait bien
cinq baies, `gltf_inspect` disait VALIDE, et l'image ne montrait rien.

> C'est ISS-018 en creux : une garde verte sur une propriété qui n'est pas
> celle qu'on veut garantir. « La baie est percée » n'est pas « on voit à
> travers ». La garde `BAIES_TOTAL == 5` reste utile — elle attrape le refus
> silencieux — mais elle ne peut pas voir une ouverture qui donne sur un mur.

**Faible.** La diagonale de l'escalier existe (assise de moellons sur le
rampant, visible à ×2 vers x 700-800 / y 290-430) mais elle ne s'impose pas :
le rampant est vu de champ, et seule sa crête accroche la lumière.

### Sanctuaire — ce que je VOIS à taille réelle

**Visible et net : l'arbre ne masque plus le lieu.** La composition occupe
x 300-620 ; le tronc gelé (594-718) est passé à droite du sujet. C'était la
cause du REJET, et elle est levée.

**Visible.** Le cœur se lit comme une enclume : dossier vertical, dalle large
ombrée dessous, et l'offrande **posée dessus** — pas flottante. Les murets se
lisent comme des pans de mur liés et moussus ; à ×4 sur la vue d'identité, le
lieu rend « une petite ruine reprise par le bois », ce que dix pierres levées
ne rendaient pas.

**Vérifié et négatif** : `shrine_gp_route_p1` ne montre **rien** du bâti. Le
contrat d'invisibilité tient, et il le devait — c'était le risque du geste.

**Faible.** Le seuil ne se lit pas comme une porte : les deux montants
projettent à x ≈ 333 et 480, soit 147 px d'écart pour 2,02 m d'entraxe à 7 m,
avec trois murets entre eux.

**Régression mesurée, et elle est à moi.** Emprise de pierre dans la vue
d'identité, même masque et même fenêtre (saturation ≤ 0,16, luminance 60-205,
fenêtre 380-980 × 300-600) : **201 × 178 px → 180 × 80 px**. La hauteur du
groupe s'effondre. La cause est géométrique et pas fautive en soi : la nef,
raccourcie de 20 % et tournée de 45°, s'étend beaucoup moins dans la
PROFONDEUR de cette caméra-là, et la profondeur est ce qui faisait la hauteur
d'écran. Mais 80 px, c'est une bande, pas une masse.

> Avertissement de mesure : ce masque n'est PAS celui des passes précédentes
> (qui publiaient 258 × 178 px). Je publie donc l'avant ET l'après avec le
> mien ; seule leur différence est comparable. La grandeur qui l'est
> réellement d'une passe à l'autre est l'`emprise_m` du manifeste de
> silhouette, produite par l'outil.

## R2 — les deux corrections tirées de R1 (commit `fe99130`)

Écrit avant modification. Défaut → cause → levier → attendu → caméra :

- Tour, porte murée → l'angle sud occupe `y ≤ −1,775` → baie déplacée à
  `s ∈ [1,05 ; 1,65]`, soit `y −1,575..−0,975`, 0,20 m de dégagement ;
  jambages, seuil et linteau tombé suivent → un rectangle sombre dans le pan
  éclairé, à x ≈ 420-490 → `watchtower_ruin_joueur`, `gp_breche`.
- Sanctuaire, seuil illisible → 2,02 m d'entraxe et trois murets entre les
  montants → entraxe 1,38 m, linteau incliné de 15° au lieu d'à plat →
  deux montants qu'on relie, et une pièce qui a l'air TOMBÉE →
  `forest_shrine_joueur`.
- Sanctuaire, présence perdue en identité → murets trop bas → crêtes 0,92 /
  0,84 / 0,66 m au lieu de 0,82 / 0,72 / 0,55 → l'emprise remonte sans que le
  rapport cœur/muret descende sous 2,2 → `forest_shrine_identite`.

**Hauteurs de collision RELUES dans le journal de génération**, jamais
déduites de la hauteur demandée : la brisure rabote chaque crête (0,99 demandé
→ 0,92 obtenu). Recopier la consigne aurait posé trois murs invisibles de 7 à
10 cm trop hauts.

## R2 puis R3 — après capture

### R2 (`it/r2/`, commit `fe99130`) — la porte s'ouvre, et elle ne se voit pas

La baie sort de l'angle sud et le contraste APPARAÎT — zone de la porte
435-485 × 380-470 : p50 **52,6** contre **50,1** pour le mur voisin, là où R1
donnait 56,3 contre 56,8. Le trou existe.

Mais à ×4 il rend une **fente de 38 px**, pas une porte. Deux causes, toutes
deux géométriques, toutes deux mesurables, et aucune n'est une affaire de goût :

1. **Les jambages rebouchaient leur propre baie.** Ils étaient centrés SUR les
   bords du jour, avec 0,26 m d'emprise de chaque côté : ils mangeaient 0,34 m
   des 0,60 m d'ouverture.
2. **L'ébrasement.** Le mur fait 0,85 m d'épaisseur et la vue arrive à 19° du
   normal : la joue mange `0,85 × tan 19° = 0,29 m` de jour supplémentaire. Sur
   0,60 m d'ouverture, il ne restait rien.

C'est la contrepartie exacte du geste qui corrige « trop mince » : **un mur
épais mange ses propres ouvertures**. Une baie percée dans un mur de 0,45 m et
la même baie dans un mur de 0,85 m ne montrent pas la même chose, et le calcul
de dégagement doit se faire AVANT, pas se découvrir sur l'image.

### R3 (`it/r3/`, commit `a7202da`) — l'entrée se lit

Baie portée à **0,90 m**, jambages sortis entièrement du jour, arase du mur est
remontée de 1,35 à 2,05 m à son extrémité nord (sans quoi une porte de 1,85 m
n'a pas de linteau là où elle est désormais ; l'écart d'arases que mesure la
garde 1 ne bouge pas — il se calcule sur les hauteurs de DÉPART).

| Mesure, `watchtower_ruin_joueur` | R1 (murée) | R2 | R3 |
|---|---:|---:|---:|
| p50 dans la porte | 56,3 | 52,6 | **42,8** |
| p50 dans le mur voisin | 56,8 | 50,1 | 54,8 |
| **écart** | **0,5** | 2,5 | **12,0** |
| largeur du jour sombre (y = 350) | — | ~38 px | **55 px** |

**Ce que je VOIS à ×4** : une ouverture avec son ébrasement (l'épaisseur du mur
se lit comme une joue profonde à gauche), le sol clair de l'intérieur visible à
travers, un jambage à droite, et la dalle de seuil qui y conduit depuis le
premier plan. C'est une porte, pas une fente.

**Reste, et je le nomme** : un des jambages rend un rectangle un peu plaqué sur
le parement à ×4. Il n'est pas gênant à taille réelle ; il n'est pas corrigé.

### Le lointain — la tour est moins mince, et c'est chiffré

`watchtower_gp_lointain`, à 86 m, masque sombre `lum < 78` sur la fenêtre
570-680 × 290-410 :

| | avant | après |
|---|---:|---:|
| emprise | 62 × 90 px | **71 × 91 px** |
| pixels sombres | 617 | **1 292** |

Plus large de 15 %, et **deux fois plus dense** : l'empattement et l'épaisseur
ne font pas que grandir la silhouette, ils la remplissent.

### Sanctuaire — le bilan chiffré des deux vues jugées

Même masque, mêmes fenêtres (saturation ≤ 0,16, luminance 60-205).

| | avant | après |
|---|---|---|
| vue JOUEUR, emprise de pierre | 604 × 148 px | **338 × 157 px** |
| vue JOUEUR, pixels de pierre | 1 182 | **2 810** |
| vue IDENTITÉ, emprise de pierre | 201 × 178 px | **174 × 79 px** |
| `shrine_gp_route_p1` | rien du bâti | **rien du bâti** |

Le lieu cesse d'être un semis de 604 px coupé en deux par un tronc : il devient
une masse compacte de 338 px portant **deux fois et demie** la surface de
pierre. La vue d'identité, elle, PERD de la hauteur d'écran, et la cause est
géométrique — la nef raccourcie et tournée de 45° s'étend beaucoup moins dans
la profondeur de cette caméra-là, et cette profondeur est ce qui faisait la
hauteur. C'est un échange, pas un progrès net, et c'est au jugement de le
trancher.

---

## Deux pièges d'outil rencontrés, à verser aux règles locales

1. **`probe_ecran_lot1r.gd` et `probe_vegetation_near.gd` ne peuvent PAS
   localiser un arbre du semis V2.2.** `probe_sanctuaire.gd` l'imprime
   lui-même : « **16 651 transform(s) d'instance rendent l'identité** — les
   positions ci-dessous sont celles de la CELLULE, pas de l'arbre ». Toutes les
   instances de végétation gelée se projettent donc à l'origine de leur cellule.
   Conséquence concrète : le tronc qui masquait le sanctuaire **n'apparaît dans
   la liste d'aucune sonde**, et un recensement à 3 m de sa position estimée
   rend « 0 instance ». J'ai donc travaillé sur ce que l'image donne — bande
   d'occultation x 594-718 mesurée colonne par colonne — et sur une distance
   déduite de la ligne de sol (`y_base ≈ 530 px → D ≈ 5,7 m`), en gardant
   **2,4 m de marge minimale** autour de la position estimée. La position exacte
   du tronc reste **NON VÉRIFIÉE**, et rien dans cette passe n'en dépend.
2. **`probe_sanctuaire.gd` mesure une nef qui n'existe plus.** Sa constante
   `CHEMIN` est écrite en dur sur l'ancien axe (local (−0,05 ; −4,60) →
   (0 ; −0,85)). Après la recomposition, elle échantillonne de l'herbe et rend
   « plus grande marche 0,000 m » — un `PASS` qui ne veut rien dire. Je ne l'ai
   pas modifiée : c'est un fichier de `tools/`, hors de ma voie. **La
   franchissabilité de la nef recomposée est donc NON VÉRIFIÉE**, et il faut
   soit recaler `CHEMIN`, soit le dire dans le verdict.

---

## Clôture R3 — silhouettes et sondes rejouées

Les mesures ci-dessous sont postérieures au commit `3555c22` du journal ; elles
sont versées ici pour que la lecture soit close au même endroit que le reste.

### Emprises orthogonales, avant → après

Silhouettes 900×1200, monde monté, `repo_dirty: false`. « Avant » = état
`candidate`/`final` de la passe précédente ; « après » = R3.

| | avant | après | Δ |
|---|---:|---:|---:|
| tour, emprise X | 13,11 m | **14,06 m** | +0,95 |
| tour, sujet 0° | 13,50 % | 13,37 % | −0,13 |
| tour, sujet 90° | 9,11 % | **9,33 %** | +0,22 |
| sanctuaire, emprise X | 17,05 m | **18,25 m** | +1,20 |
| sanctuaire, emprise Z | 11,48 m | **10,62 m** | −0,86 |
| sanctuaire, sujet 0° | 6,36 % | **5,23 %** | −1,13 |
| sanctuaire, sujet 90° | 6,63 % | **5,95 %** | −0,68 |

Le sanctuaire **occupe moins** l'image orthogonale qu'avant. La cause est la
même que pour la vue d'identité : une nef plus courte, tournée de 45°, s'étend
moins dans la profondeur de chaque axe cardinal. Je ne présente pas cela comme
un gain. Le pari de la passe est que la vue JOUEUR — celle qui a été rejetée —
gagne ce que les vues cardinales perdent ; l'arbitrage appartient à la revue.

### Sondes sur la géométrie R3

`probe_vigie_ascension` : **PASS** — 62 appuis, premier appui 26,00, sommet
28,79, gain 2,79 m, contremarches ≤ 0,38, capsule libre, redescente < 6 m.
L'escalier déplacé reste physiquement praticable, volée 1 → palier tournant →
volée 2.

`sonde_budget_lot1` (D7, monde monté) :

| lieu | famille | modules | visuels | collisions | plafond |
|---|---|---:|---:|---:|---|
| watchtower_ruin | ruine | 15 | 19 | 13 | 40 / 80 / 20 |
| forest_shrine | vestige | 33 | 35 | 12 | 40 / 80 / 20 |

Le sanctuaire était à **40 modules pile** avant la passe. Il est à 33 : la marge
n'était plus qu'un cheveu, elle respire.

### Ce qui reste NON VÉRIFIÉ, et le restera dans le rapport

1. **La position exacte de l'arbre gelé qui masquait le sanctuaire.** Aucune
   sonde ne peut la lire (voir le piège 1 ci-dessus). Tout le placement repose
   sur une bande d'occultation mesurée à l'écran et une distance déduite de la
   ligne de sol, avec 2,4 m de marge.
2. **La franchissabilité de la nef recomposée.** `probe_sanctuaire.gd`
   échantillonne l'ancien axe (piège 2). Son `PASS` est vide de sens ici.
