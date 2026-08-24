# CONCEPTION — Tour de guet (`valley.poi.watchtower_ruin.01`)

Intention imposée (ADDENDUM_DA) : **la sentinelle abandonnée** — hauteur,
solitude, mélancolie. De loin une silhouette brisée qui promet un point de
vue ; en approchant, les anciens niveaux et le chemin d'ascension ; du
sommet, le paysage est la récompense avant les flèches.

## Émotion et micro-histoire

Émotion : mélancolie de veille — quelqu'un a guetté ici pendant des années,
puis la falaise a gagné. Micro-histoire sans texte : la tour s'est ouverte
du côté où le sol se dérobe (l'est) ; l'angle nord-est est parti dans la
pente, la couronne l'a suivi ; les corbeaux et les trous de solives disent
DEUX planchers disparus ; l'escalier scellé dans la maçonnerie monte encore
— mais il ne mène plus qu'à la ligne du premier plancher, et au vide. Le
coffre de flèches est resté à l'abri du seul angle encore couvert : le
guetteur n'est jamais revenu le chercher.

## Lectures aux trois distances

- **80–120 m** (depuis la vallée, en contrebas est) : une dent unique et
  brisée sur la lèvre de la falaise, diagonale ouest→est, ciel dans la
  brèche. Fonction de repère d'orientation (contrat conservé).
- **30–50 m** : quatre arases franchement différentes (8,95 / 6,45 / 5,85 /
  3,05 m), gradins d'assise, pans tombés dans l'herbe, talus au pied de la
  brèche — l'effondrement a une DIRECTION.
- **5–15 m** : l'épaisseur du mur dans les jambages de la brèche, le
  parement intérieur dans l'ombre, les corbeaux, les bouts de solives,
  l'escalier, le coffre. La matière est la pierre du monde (T_UnevenBrick).

## Élément héroïque unique

La **brèche-porte nord-est** : on entre dans la sentinelle PAR sa blessure,
et l'intérieur sombre encadre le coffre. Aucun autre lieu du lot n'a
d'intérieur architecturé.

## Palette et valeurs RENDUES (mesurées sur `iter/tour3/`, llvmpipe)

- mur au soleil : p50 ≈ 0,33, p90 ≈ 0,38 (bande §1.5 « sol/roche » 0,35–0,65
  — la façade est au BAS de la bande ; une remontée de teinte d'un cran
  reste possible en calibration finale) ;
- parement intérieur : p50 ≈ 0,23 (bande « ombres » 0,18–0,38 ✓) ;
- pièces tombées : ≈ 0,27 ; herbe voisine : ≈ 0,35.
Palette : gris-ocre froid de la maçonnerie, ombres bleutées de l'intérieur,
herbe verte, aucun accent saturé — la mélancolie est une affaire de valeurs.

## Mouvements et effets locaux

- lierre sur la face nord (existant), herbes hautes au pied des pans tombés ;
- vent : rien de spécifique (végétation V2.2 gelée porte déjà le vent) ;
- pas de lumière locale : le lieu vit de la lumière du monde, l'intérieur
  sombre EST l'effet.

## Références (décrites)

1. Tours de guet écroulées d'Écosse (brochs) : fût qui survit d'un seul
   côté, diagonale de ruine, pierre sèche sans mortier apparent.
2. La ferme `SM_Farm_Ruins` du dépôt (validée) : gradins d'assise, dents
   survivantes, talus de moellons — même famille de formes.
3. Aquarelles de ruines de Turner : masse claire au soleil, intérieur
   avalé par l'ombre, silhouette qui promet plus qu'elle ne montre.
4. Tours génoises corses : plan compact, porte unique surélevée, un seul
   volume lisible de très loin.

## Assets utilisables / bloquants

- UTILISABLES : `SM_Watchtower_Ruin.glb` (dédié, généré, 1 122 tris —
  arases rompues, brèche, escalier scellé, talus, pans, bloc de couronne) ;
  cartes `T_UnevenBrick_*`, `T_WoodTrim_*` (CC0 déjà attribuées) ;
  `rock_largeC` (pied sud-ouest) ; `Prop_Vine1`, buissons.
- BLOQUANTS (retirés) : `Wall_UnevenBrick_Straight` (plans sans chant),
  `SM_Dungeon_ArchBlock/Rubble*/CaveRock` (rendu terracotta),
  `Stairs_Exterior_Straight` (volées flottantes).

## DEUX compositions

### A — « La déchirure vers le vide » (implémentée, iter/tour3)

Fût carré, mur ouest 9 m, effondrement diagonal vers la falaise est,
brèche NE = entrée, escalier intérieur jusqu'à la ligne du premier
plancher (3,05 m, non praticable), coffre au sol de l'angle abrité, talus
et deux pans tombés, bloc de couronne pris dans la pente à 6,4 m.
+ : silhouette-repère très lisible, contrats/colliders déjà verts, zéro
surface praticable nouvelle (aucun risque de chute/navmesh).
− : « du sommet, le paysage » n'est pas joué — le point de vue reste au
pied de la tour (la lèvre de falaise à 3 m au sud-est donne déjà un
panorama, mais il n'appartient pas à l'ascension).

### B — « La vigie retrouvée » (à arbitrer)

Même fût et même brèche, mais l'escalier CONTINUE : le palier du premier
plancher devient une demi-dalle praticable (3,05 m, appuyée sur les murs
ouest et nord, garde-corps = l'arase du mur nord à hauteur de hanche), et
la couronne ouest s'abaisse d'un cran pour ouvrir le REGARD vers l'est :
du palier, on voit la vallée PAR la brèche, au-dessus du coffre. Le
paysage devient la récompense de l'ascension, les flèches viennent après.
+ : joue l'intention de l'addendum mot pour mot ; unique dans le lot.
− : une surface praticable à 3 m — collider de dalle, garde-fou de chute,
test manuel de saut/réception à prévoir ; le budget colliders passe à ~9.

**Recommandation : B**, parce que l'intention « le paysage est la
récompense avant les flèches » est une instruction de mise en scène, pas
une décoration — et A ne la joue pas. Si le lead juge le risque praticable
trop coûteux pour ce lot, A est complète, verte et livrable telle quelle.

## Parcours joueur (20–40 s, monde ; hauteurs à lire au sol)

1. P1 (−138, ~20, 56) — promesse : la dent brisée sur la lèvre, ciel dans
   la brèche (regard ONO).
2. P2 (−148, ~26, 47) — approche : les quatre arases se séparent, le talus
   apparaît (regard O).
3. P3 (−155,5, ~27, 39,5) — pied de la brèche : jambages, intérieur sombre
   (regard O).
4. P4 (−162, ~27,3, 40) — révélation : l'intérieur — escalier, corbeaux,
   coffre dans l'ombre (regard NO puis haut).
5. (compo B) P5 palier (−162,5, ~30,3, 39,5) — le paysage par la brèche
   (regard E, plongée vers la vallée) ; (compo A) P5 lèvre sud-est
   (−156, ~27, 36) — panorama (regard SE).
6. P6 — récompense : coffre, puis sortie par la brèche, regard vers le
   pylône au sud-est.
