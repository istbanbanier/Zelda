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

**Vérification due (demande du coordinateur)** : l'emprise du sanctuaire
change (≈ 2,7 × 4,5 m → ≈ 4,7 × 5,5 m). Le verdict R-D3 doit donc être rejoué
sur silhouettes — `tools/godot/capture_silhouette.gd` puis
`tools/lot1_repetition.py` — avant la clôture. Le filet D4 et l'ancre de
récompense ne sont PAS concernés ici : le lieu n'a pas été déplacé, aucune
caméra gelée n'a bougé, aucun collider nouveau n'est apparu (les quatre
marques d'angle sont sous la hauteur de marche) et l'ancre reste sur la table.
