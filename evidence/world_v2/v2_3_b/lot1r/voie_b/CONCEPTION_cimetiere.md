# CONCEPTION — Cimetière du tertre (`valley.poi.barrow_cemetery.01`)

Intention imposée (ADDENDUM_DA) : **le poids du passé** — silence,
ancienneté, légère inquiétude. On traverse d'abord des signes funéraires
secondaires, puis le tertre dominant. Les volumes racontent plusieurs
époques, affaissements, sépultures. La hache paraît appartenir à
l'histoire du lieu, pas à un coffre posé au milieu.

## Émotion et micro-histoire

Émotion : on marche sur des tombes et on le sait. Micro-histoire sans
texte : PLUSIEURS époques superposées — les tumulus anciens (affaissés,
bords mangés par l'herbe, sommets creusés), les stèles dressées d'une
époque suivante (penchées, l'une couchée), et une intrusion RÉCENTE : le
grand tertre a été OUVERT — la fosse de pillage au sommet, la chambre
mordue au flanc, les déblais encore devant la gueule, et le coffre à la
hache abandonné là, dans les déblais : les pilleurs ne sont pas revenus
le chercher. Le vide entre les masses est l'identité (contrat r08 :
« densité basse voulue — le vide est une identité »).

## Lectures aux trois distances

- **80–120 m** : trois gonflements du sol dans la steppe rase, orientés
  dans le même sens (un champ funéraire s'aligne), le grand nettement
  dominant. Pas de cônes : des dos longs, dissymétriques.
- **30–50 m** : les stèles apparaissent — deux debout penchées, des lames
  couchées à demi enterrées qui font un CHEMIN vers le grand tertre ; le
  creux de pillage se lit sur la crête du dominant.
- **5–15 m** : la gueule de la chambre (montants de pierre grise, linteau
  effondré en travers), les déblais, le coffre dans les déblais, l'herbe
  qui remonte sur les bords des tumulus.

## Élément héroïque unique

Le **tertre dominant éventré** : fosse au sommet, chambre au flanc,
linteau glissé — la seule tombe du lot qu'une main a rouverte, et la
raison d'être de la hache.

## Palette et valeurs RENDUES (mesurées sur `avant/barrow_cemetery_identite.png`)

- tertre actuel : ≈ 0,23 (sous la steppe à 0,42 — les dômes sont DÉJÀ plus
  sombres que l'herbe, c'est correct pour des masses funéraires, à garder
  dans 0,22–0,30) ;
- pierre des stèles : cible 0,30–0,42 rendu, GRISE et froide (le beige
  `SM_Dungeon_*` et les patchs turquoise des chapeaux d'herbe de
  `rock_largeA/C` sont les causes mesurées du rejet — à retirer) ;
- steppe : 0,42 ; falaises lointaines : 0,50.

## Mouvements et effets locaux

- herbes hautes sèches existantes (3 touffes) — le vent V2.2 les porte ;
- AUCUN effet ajouté : le silence est l'effet. Pas de brume locale (la
  steppe est plate et lue de loin, une nappe se verrait comme un disque).

## Références (décrites)

1. Champs de tumulus danois (Jelling, Lindholm Høje) : dos allongés
   orientés, affaissements, pierres dressées éparses entre les tertres.
2. Allées couvertes bretonnes effondrées : montants gris, linteau glissé
   en travers, chambre à ciel à demi ouvert.
3. Barrow-downs de Tolkien (décrits) : l'inquiétude vient de l'ALIGNEMENT
   des masses et du silence, pas d'un décor gothique.
4. Fosses de pillage archéologiques : cratère net au sommet, déblais en
   éventail devant l'ouverture — la blessure raconte l'histoire.

## Assets utilisables / bloquants

- UTILISABLES : générateur runtime des tertres (terrain-hugging,
  exemption D1a nommée — le PROFIL change, la méthode reste) ;
  `Rock_Medium_1/2/3` (atlas gris neutre — ceintures et cairns) ;
  `Grass_Common_Tall` ; nouveau GLB dédié `SM_Barrow_Stones.glb`
  (stèles brisées, lames couchées, montants + linteau de chambre —
  budget ≤ 4 k tris l'ensemble).
- BLOQUANTS (à retirer) : `SM_Dungeon_ArchBlock` et `PillarStub` (chambre
  et stèles beige), `RockPath_Square_Wide` (couverture trop propre),
  `cliff_half_rock` couché (rend des marches beige posées dans l'herbe),
  `rock_largeA/C` en ceinture (chapeaux d'herbe TURQUOISE mesurés sur la
  capture avant).

## DEUX compositions

### A — « Le chemin des morts » (échelonnement)

Les trois tumulus reprofilés (grands axes ~NO-SE alignés sur l'entrée,
flancs dissymétriques, bords irréguliers, fosse de pillage sur le
dominant), et les signes secondaires réorganisés en CHEMIN : depuis
l'entrée nord-ouest, une séquence lame couchée → stèle penchée → lame →
stèle → la gueule de la chambre du dominant. Le coffre reste à la gueule,
dans les déblais.
+ : joue exactement « signes secondaires d'abord, puis le dominant » ;
  colliders quasi inchangés (sphères par tertre adaptées) ; risque D2/D4
  minimal.
− : la chambre reste une morsure de flanc assez discrète — la révélation
  est surtout un cheminement.

### B — « L'allée rouverte » (allée couverte)

Le tertre dominant est traversé par une COURTE allée de pierre (deux rangs
de montants bas, 2,2 m de long, un linteau en place + un glissé), creusée
dans son flanc sud ; le coffre est DANS la bouche de l'allée, sous le
linteau glissé ; la fosse de pillage au sommet perce jusqu'à l'allée
(puits de jour). Les deux autres tumulus et les stèles comme en A.
+ : révélation plus forte (on ENTRE d'un pas dans la tombe) ; la hache
  appartient littéralement à la sépulture.
− : creuser le dôme runtime autour d'une allée praticable complexifie le
  maillage terrain-hugging (trou dans l'exemption D1a à re-mesurer) ; un
  volume semi-fermé sur le coffre risque l'audit d'ancrage (« un coffre au
  fond d'une chambre fermée serait un piège » — en-tête du lieu) ; navmesh
  et caméra à re-vérifier dans la bouche.

**Recommandation : A**, avec la gueule de chambre RENFORCÉE (montants plus
hauts, linteau glissé bien lisible, déblais élargis autour du coffre) :
elle obtient la narration de B (tombe rouverte, hache des pilleurs) sans
creuser le dôme ni enfermer la récompense — les deux risques que le
contrat du lieu documente déjà. B n'est à retenir que si le lead veut une
révélation intérieure et accepte de payer la re-mesure D1a + audit
d'ancrage.

## Parcours joueur (20–40 s, monde ; sol ≈ 5,2, pad plat ±1 m)

1. P1 (48, ~5,7, −52) — promesse : trois dos sombres dans la steppe,
   alignés (regard SE).
2. P2 (51, ~5,4, −57) — premier signe : une lame couchée à demi enterrée
   au bord du pas (regard bas, puis SE vers la stèle penchée).
3. P3 (54, ~5,3, −60) — le chemin des morts : stèle penchée à gauche,
   deuxième lame, le dominant grossit (regard SE).
4. P4 (55, ~5,2, −62,5) — révélation : la fosse de pillage sur la crête,
   puis la gueule de la chambre et ses déblais (regard S).
5. P5 (54,5, ~5,2, −59,5) — récompense : le coffre à la hache DANS les
   déblais, montants gris et linteau glissé au-dessus (regard S).
6. P6 (58, ~5,3, −57) — sortie : entre le dominant et le tertre moyen, le
   vide de la steppe se rouvre (regard NE vers l'ancre de région).
