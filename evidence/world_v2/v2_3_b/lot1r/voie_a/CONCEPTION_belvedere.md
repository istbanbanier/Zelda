# CONCEPTION — Belvédère du guetteur (`valley.poi.overlook_summit.01`)

Voie A · lot 1.R · répond à `ADDENDUM_DA.md`. État au moment d'écrire :
checkpoint sûr v2 committé (`42b6292`) — matières corrigées sur mesure
(captures v1), géométrie NON figée, en attente d'arbitrage entre les deux
compositions ci-dessous.

## Émotion recherchée

**L'ascension et le vertige** (imposée). L'effort de la montée, puis
l'ouverture brutale : le sommet n'est pas un objet qu'on regarde, c'est un
seuil qu'on franchit — et derrière, toute la vallée.

## Micro-histoire (sans texte)

Un guetteur montait ici chaque soir surveiller la vallée. Les roches de la
crête, taillées par le vent d'ouest, penchent toutes du même côté ; entre
elles, il avait son passage. Sur la seule pierre plate, face au vide, il a
laissé son arc — il n'est jamais redescendu le chercher.

## Lecture aux trois distances

- **80–120 m** (depuis la route en contrebas, NO ou NE) : la butte la plus
  haute de l'est porte une couronne rocheuse ébréchée — deux dents grises
  contre le ciel, un creux entre elles. Promesse : « il y a un passage
  là-haut, et il donne sur quelque chose ».
- **30–50 m** (dans la montée) : la route en S, la crête à gauche qui
  grossit, l'avant-poste détaché à droite ; on commence à voir DU CIEL à
  travers la brèche — le sommet est un vide, pas un mur.
- **5–15 m** (au sommet) : la marche, la tablette, l'arc posé contre le
  vide ; derrière lui, d'un coup, la crête de départ à 250 m et toute la
  vallée. Le regard passe PAR-DESSUS la récompense vers le panorama.

## Élément héroïque unique

**La brèche** : le vide cadré entre la crête et l'avant-poste, tourné vers
l'ouest-sud-ouest — c'est LE cadre du « regard de retour » du layout
(cam05 y vit déjà). Aucun autre lieu du lot n'est bâti autour d'un vide.

## Palette, lumière, matières (valeurs RENDUES, mesurées sur capture)

Mesures faites sur les captures v1/v2 (llvmpipe, lumière du monde gelée) —
jamais sur l'albédo (gain ≈ 1,8, non linéaire) :

- falaises V2.2 gelées (fond) : gris-rose poussiéreux ≈ RGB(205,180,165),
  arêtes chaudes ≈ (230,200,175) ;
- `Rock_Medium_*` rendu : gris-vert froid ≈ (120,125,110) à l'ombre,
  (170,175,155) au soleil, coiffe mousse ≈ (140,160,95) — c'est la matière
  du lieu ;
- herbe du sommet : vert olive du terrain ≈ (70,110,60) + herbes sèches
  (TONE_DRY rendu ocre clair) ;
- INTERDITS mesurés : coiffe « grass » Kenney nue = MENTHE ≈ (110,230,205)
  (v1, refusée ici même) ; `SM_Dungeon_*` = terracotta (rejet Codex).

Lumière : celle du monde gelé (soleil d'ouest). Le lieu est un sommet : les
masses prennent la lumière chaude sur leurs faces ouest, ombres froides
vers la vallée — aucune lumière locale nécessaire.

## Mouvements / effets locaux nécessaires

- herbes sèches et deux buissons secs dans le vent global (le semis V2.2
  anime déjà la butte) ;
- RIEN d'autre : le spectacle de ce lieu est le panorama, pas un VFX.
  Un effet de particules au sommet concurrencerait la vue.

## Références visuelles (décrites)

1. Les **tors de Dartmoor** : piles de strates granitiques grises,
   arrondies et penchées, posées sur une butte d'herbe rase — des masses
   FONDUES qui semblent sortir de la colline, jamais posées dessus.
2. Les **belvédères de parcs nationaux** cadrés par deux masses : deux
   rochers encadrent le vide, le sentier passe entre — la vue est
   composée par la roche, pas cachée par elle.
3. Une **crête calcaire au couchant** (Vercors) : faces à l'ombre bleutées
   et froides, arêtes hautes chaudes — le contraste chaud/froid donne le
   relief sans contour.
4. Le principe du **premier plan qui s'ouvre** en peinture de paysage :
   une diagonale sombre au premier plan (la crête), une trouée claire au
   second (la brèche), le sujet lumineux au fond (la vallée).

## Assets existants : utilisables / bloquants

**Utilisables** (jugés sur capture) : `Rock_Medium_1/2/3` (seule famille
qui rend « roche » — gris-vert, facettée, coiffe mousse) ; `rock_largeA/C`
et `rock_smallB` UNIQUEMENT re-teintés par surface (`_teinte_kenney`,
corps roche froide / coiffe ocre sec) et en strates basses ; `Bush_Common`
teinté sec ; le terrain gelé lui-même (la butte est le vrai socle).

**Bloquants** : `SM_Dungeon_CaveWallTop/CaveWallHalf/CaveRock` (terracotta,
rejet Codex — bannis) ; `cliff_half/blockSlope/large_rock` en masses
dressées (rendu v1 mesuré : coins beiges à faces planes, « tente de
cirque », coiffe menthe) — inutilisables comme sujet vertical même
re-teintés, tolérables seulement couchés/enterrés en strate.

## DEUX COMPOSITIONS

### A — « La mâchoire » (checkpoint v2 actuel, à pousser)

Crête = un rocher maître `Rock_Medium_3` ×2,2 (~4,6 m visibles) penché,
fondu dans une strate basse `rock_largeA` re-teintée, épaulé au sud par
`Rock_Medium_1` ; avant-poste détaché `Rock_Medium_2` ×1,75 + dalle de
pied à (15 ; −3) ; brèche diagonale OSO entre les deux groupes ; tablette
et arc au bord sud, face au vide.

- Pour : bimodalité D3 CONSERVÉE telle quelle (seuils 0,493/0,491/0,546
  déjà tenus par cette structure) ; distances route/cam05 déjà calculées ;
  matière qui rend déjà « roche » au moteur ; zéro asset neuf.
- Contre : silhouette moins « dent dressée » que l'ancienne corne — le
  sommet culmine à ~4,6 m au lieu de 6,3 ; le vertige repose davantage
  sur le vide que sur la hauteur des pierres.

### B — « Les marches du guetteur »

Une SEULE dent maîtresse (6–7 m), GLB Blender dédié « dent de crête »
stratifiée (profil en fruit, ressauts, crête vive — ≤ 8k tris, chaîne
`source_assets/blender/environment/` complète), au NE ; et un ESCALIER
NATUREL de trois strates géantes demi-enterrées qui monte du sud-ouest
vers la tablette — l'ascension elle-même devient la mise en scène ;
l'avant-poste se réduit à un éclat bas pour garder du ciel à l'est.

- Pour : silhouette unique dans le corpus (dent + gradins) ; « l'effort »
  se lit dans la géométrie ; la dent Blender remplace définitivement le
  vocabulaire kit sur ce lieu.
- Contre : RISQUE D3 mesurable — une dent unique rapproche la lecture
  mono-masse de la Grotte du couchant (IoU à re-mesurer AVANT
  engagement) ; coûte un asset Blender (~1 session avec sa validation) ;
  les gradins ajoutent 2–3 modules → budget D7 12/12 à re-négocier
  (les buissons sautent).

### Recommandation argumentée

**A.** L'intention imposée (« les roches mettent en scène la vue ») est
mieux servie par la brèche que par une dent spectaculaire : le sujet du
lieu est le panorama, et A dépense son budget de lisibilité sur le vide,
pas sur la pierre. A est aussi la seule des deux dont la conformité D3
est déjà démontrée par la structure en place, et elle ne demande aucun
asset neuf. B ne vaut son coût que si la revue juge la crête A trop
timide À LA CAPTURE — auquel cas la dent Blender est chiffrée et la
brèche/bimodalité restent le squelette.

## Parcours joueur (20–40 s, points monde + regards)

1. **(150, 24, 36)** sur `heights_route`, regard (168, 26, 52) —
   promesse : la couronne ébréchée sur la butte.
2. **(158, 24, 42)** (waypoint route), regard (168, 25, 52) — montée,
   la crête grossit, l'avant-poste se détache à droite.
3. **(163, 23.5, 47)** regard (170, 24, 54) — du ciel apparaît DANS la
   brèche : le sommet est un passage.
4. **(168, 23.2, 52)** (site), regard (0, 26, 170) — RÉVÉLATION : la
   brèche cadre la crête de départ et toute la vallée.
5. **(171.8, 23.4, 57.6)** la tablette, regard plongeant (120, 8, 90) —
   l'arc au premier plan, la vallée derrière : la capture à montrer.
6. Sortie NE vers **(190, 21, 30)**, regard (240, 30, 0) — regard de
   sortie vers les hauteurs de l'orient.
