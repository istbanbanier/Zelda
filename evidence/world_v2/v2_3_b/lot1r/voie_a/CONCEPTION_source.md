# CONCEPTION — La Source aux reflets (`valley.poi.turquoise_spring.01`)

Voie A · lot 1.R · répond à `ADDENDUM_DA.md`. État au moment d'écrire :
checkpoint sûr v3 committé (`71f7cea`) — eau au shader V2.2, bouche en
rochers, matières corrigées sur mesure ; géométrie NON figée, en attente
d'arbitrage entre les deux compositions ci-dessous.

## Émotion recherchée

**Le secret rafraîchissant** (imposée). Une découverte intime dans un
ravin sombre : la première tache turquoise du monde-ouest, qu'on veut
approcher avant même de savoir qu'il y a une récompense.

## Micro-histoire (sans texte)

L'eau qui a taillé les falaises du couchant ressort ici, au pied du mur,
par une fente entre trois pierres. Elle remplit une vasque, déborde en un
fil vers l'affluent — c'est donc ELLE qui fait naître la rivière de
l'ouest. Quelqu'un, un jour, a posé trois dalles pour franchir le fil à
pied sec ; le fruit qui pousse au bord n'a jamais été cueilli.

## Lecture aux trois distances

- **80–120 m** (du haut du ravin ou de la route du village) : un repli
  sombre au pied de la falaise du couchant, et dedans une tache turquoise
  minuscule — la SEULE couleur froide saturée du ravin. Promesse : « il y
  a quelque chose de vivant en bas ».
- **30–50 m** : le ravin s'assombrit ; trois rochers gris-vert massés au
  pied de la paroi ; le miroir d'eau et son fil brillant qui file vers le
  nord-est ; les dalles qui l'enjambent. On comprend origine → bassin →
  sortie d'un seul regard.
- **5–15 m** : la bouche sombre entre les mâchoires, l'eau qui en sort,
  la mousse cassée de la rive, les reflets ; au-dessus, la paroi monte
  d'un coup de 14 m (le guet est invisible, sa tour se détache sur le
  ciel). Le fruit corail attend au bord est.

## Élément héroïque unique

**La bouche** : le creux fermé entre trois rochers d'où l'eau SORT — pas
une arche, pas un trou décoratif : l'origine visible de l'affluent, avec
la première note turquoise du monde-ouest juste devant.

## Palette, lumière, matières (valeurs RENDUES, mesurées sur capture)

- ravin (terrain gelé, ombre + brume) : brun sombre ≈ RGB(75,60,55) sur
  la paroi, vert éteint ≈ (85,105,80) au sol ;
- eau rendue (shader V2.2, llvmpipe) : rive/mousse ≈ (200,210,200),
  corps ≈ (140,165,170), fil ≈ (170,195,195) — à comparer côte à côte
  avec le gué de l'affluent (capture `spring_gue_riviere`), même moteur ;
- mâchoires `Rock_Medium` à l'ombre : gris-bleu-vert ≈ (70,85,80) —
  mesuré v2, c'est la bonne matière pour « zone plus sombre, minérale » ;
- margelles : roche froide humide (albédo posé 0,34/0,35/0,38), coiffe
  mousse olive sombre (0,24/0,28/0,17) — vérif sur capture v3 ;
- INTERDITS mesurés : nappe blanche (StandardMaterial + gain, rejet
  Codex), arche `SM_Dungeon_*` terracotta, coiffe menthe Kenney (v1),
  anneau noir du lit débordant (v1-v2, corrigé en v3) ; le cyan de
  Résonance reste réservé aux sites systémiques.

Lumière : celle du monde gelé — le ravin est DÉJÀ l'ombre du lieu ; c'est
le contraste ombre/turquoise qui fait le secret. Aucun éclairage qui
déboucherait le ravin.

## Mouvements / effets locaux nécessaires

- l'eau EST le mouvement : rides à deux échelles + dérive du courant vers
  le déversoir (déjà porté par les couleurs de sommet du shader V2.2) ;
- souhaitable après arbitrage : une brume basse TRÈS discrète au ras de
  la vasque (GPUParticles3D local, budget mesuré) et 2-3 lucioles/pollen
  sombres — uniquement si la géométrie tient seule sans eux ;
- PAS de VFX d'éclaboussure permanent : la source suinte, elle ne jaillit
  pas — le calme fait partie du secret.

## Références visuelles (décrites)

1. Une **source vauclusienne** : vasque turquoise laiteuse au pied d'une
   falaise calcaire, l'eau sort d'un porche noyé SOMBRE — le contraste
   trou noir / eau claire est le sujet.
2. Les **pozas en escalier** (travertin) : margelles minérales arrondies
   qui retiennent l'eau, seuils par où elle déborde en films minces.
3. Un **ravin de sous-bois humide** : pierres moussues gris-vert, lumière
   tamisée, une seule trouée claire — tout le reste est éteint.
4. Le principe pictural du **premier accent froid** : dans un cadre
   désaturé brun-vert, une seule note saturée froide tire l'œil à toute
   distance — c'est le rôle du turquoise ici.
5. Les **pierres de gué japonaises** : trois dalles irrégulières qui
   racontent un passage humain ancien sans un mot.

## Assets existants : utilisables / bloquants

**Utilisables** (jugés sur capture) : `SH_WorldV2Water.gdshader` + bruit
`WorldV2GroundMaterial.grain_texture()` (la continuité de teinte avec la
rivière est DE CONSTRUCTION) ; `Rock_Medium_1/2/3` assagis recette V2.2 ;
`rock_largeA/C` en margelles APRÈS albédo absolu par surface ;
`RockPath_*` (dalles) ; maillages runtime nappe/lit (exemption D1a
nommée, terrain épousé sommet par sommet).

**Bloquants** : `SM_Dungeon_CaveArch` et toute la famille `SM_Dungeon_*`
(terracotta, lecture architecturale — bannis du lieu) ; les pièces
`cliff_*` dressées sur la pente de 54° (plaques beiges flottantes,
mesuré v1) ; la coiffe « grass » Kenney sans re-teinte (menthe) ; un
`StandardMaterial3D` nu pour l'eau (le piège albédo/gain — cause exacte
de la nappe blanche rejetée).

## DEUX COMPOSITIONS

### A — « La bouche » (checkpoint v3 actuel, à pousser)

Une seule vasque au pied de la pente ; bouche = fente sombre entre deux
mâchoires `Rock_Medium` penchées + couronne qui ferme le haut ; anneau
rompu de trois margelles basses (rien à l'ouest) ; bloc tombé au sud ;
fil de déversoir (langue du même maillage d'eau, même shader) qui suit le
sol vers les trois dalles puis s'éteint à 5 m de la tête d'affluent gelée.

- Pour : lecture origine→bassin→sortie en UN regard ; zéro risque D7
  (12/12) ; distances tête d'affluent/caméras déjà calculées ; l'eau et
  sa continuité rivière déjà en place et mesurées.
- Contre : pas de mouvement vertical — le « rafraîchissant » repose sur
  la couleur et le fil, pas sur une chute.

### B — « Les deux miroirs »

Deux vasques étagées : une vasque haute minuscule (∅ 1,2 m) calée entre
les mâchoires à +0,8 m, débordant par un voile court (maillage incliné de
0,4 m, même shader, profondeur faible → mousse) vers la grande vasque ;
margelles réorganisées en croissant aval ; la bouche sombre alimente la
vasque haute.

- Pour : un vrai mouvement VERTICAL (micro-cascade) — le moment
  « wahou » de proximité est plus fort ; l'étagement raconte mieux la
  pression de l'eau sous la falaise.
- Contre : +1 module runtime minimum → budget D7 12/12 à re-négocier
  (une dalle ou une margelle saute) ; le shader rivière n'a jamais servi
  sur un plan INCLINÉ (normales verticales, rides en espace monde XZ) —
  rendu du voile NON GARANTI, à prototyper sur capture avant engagement ;
  risque de lecture « fontaine construite » si le voile est trop régulier.

### Recommandation argumentée

**A**, en poussant la lecture par la couleur (profondeurs du centre) et
le fil. Le secret du lieu est INTIME : une source qui suinte entre des
pierres est plus crédible et plus calme qu'une cascade miniature, et B
paie un prototype de shader + une re-négociation D7 pour un gain qui
n'est pas démontré. Si l'arbitrage choisit B, le voile se prototype
d'abord SEUL dans une mini-scène capturée (une session), et la dalle
médiane du déversoir est la pièce cédée au budget.

## Parcours joueur (20–40 s, points monde + regards)

1. **(−118, 15, 50)** en descendant du nord-est dans le ravin, regard
   (−141, 12, 40) — promesse : la tache turquoise au pied de la falaise.
2. **(−124, 13.5, 44)** approche, regard (−138, 12.5, 40) — le fil
   brille, les dalles se lisent, le ravin s'assombrit.
3. **(−129.5, 12.2, 37.5)** sur la première dalle, regard qui REMONTE le
   fil vers la bouche (−145, 13, 40) — origine, bassin, sortie alignés.
4. **(−138.5, 12.1, 38.5)** au bord est de la vasque — RÉVÉLATION : la
   bouche sombre entre les mâchoires, l'eau qui en sort, la paroi de
   14 m au-dessus ; regard (−146, 14, 40) puis vers le haut (−160, 25,
   40) — la tour du guet se détache sur le ciel.
5. **(−138.6, 12.2, 42.4)** le fruit corail au bord — récompense.
6. Sortie : demi-tour, regard (−124, 12, 28) — le fil de l'eau part vers
   la tête d'affluent : on REPART EN SUIVANT l'eau qu'on vient de voir
   naître.
