# V2.3-B lot 1 — VOIE B : plan des six lieux, écrit AVANT la construction

**VIVANT** pendant le lot, **HISTORIQUE** après. Fichier propre à la voie B ; il ne
touche aucun document de continuité partagé.

Toute mesure de terrain ci-dessous vient d'un **port Python de
`scripts/world_v2/world_v2_heightmap.gd`** (fonction pure et déterministe), écrit
pour pouvoir planifier pendant que le verrou Godot était pris. **Statut :
`NON VÉRIFIÉ` tant que le recoupement sous moteur n'est pas fait** (phase 2,
`tools/godot/probe_site_section.gd`). Le port ne reprend pas les seaux spatiaux :
ils sont équivalents au calcul direct pour `height_at` — la marge de seau (28 m)
dépasse la portée de creusement (24 m), et les pads sont filtrés par la même
condition de portée, dans le même ordre.

## 0. Ce que le terrain gelé impose, et qui a décidé de tout le reste

Chaque `v2_site` porte un **pad de rayon 9 m, fondu 12 m** (`_add_site(…, 9.0, 12.0)`).
Sous 9 m du centre, le sol est **exactement plat à l'altitude du layout**. Au-delà,
il rejoint le relief. C'est ce plat de 9 m qui rend les six lieux constructibles, et
c'est sa lisière qui donne à chacun son bord.

| lieu | ce que le relief donne (Δ altitude, m, depuis le centre) |
|---|---|
| `watchtower_ruin` | plat jusqu'à r=3 ; **falaise à l'EST** : −2,2 à 6 m, −11,9 à 12 m, −14,0 à 15 m et plat ensuite. Pente 6→13 m = 1,55 m/m ≈ **57°** (le shader de sol rend « roche » au-delà de 55°). Monte doucement à l'ouest (+2 à 40 m). |
| `turquoise_spring` | plat jusqu'à r=9 ; **paroi à l'OUEST** : +0,98 à 11 m, +8,73 à 16 m, +13,72 à 20 m, +14,0 au-delà (≈ **54°**). Descend au NORD-EST vers la tête de l'affluent. |
| `overlook_summit` | dôme : plat jusqu'à r≈10, puis chute **SSE** (−3,2 à 15 m, −9,7 à 20 m) et **OSO** (−6,1 à 20 m, −13,7 à 40 m). Marchable : la butte est large (r=30) et son fondu est doux. |
| `forest_shrine` | soucoupe : plat jusqu'à r≈10, puis −2,5 à −4,9 m à 16-20 m **dans toutes les directions**. |
| `barrow_cemetery` | steppe : ±1 m sur 40 m dans toutes les directions sauf NE (+7,6 à 40 m). |
| `flower_field` | plat au N/E/O ; **monte au SE** vers la crête de départ (+3,7 à 16 m, +7,3 à 20 m). |

Deux conséquences que je n'aurais pas devinées sans mesurer :

1. **Le guet et la source sont les deux faces du MÊME mur.** 24 m les séparent, 14 m
   de dénivelé : `26 − 12`. Le profil est à `+14,0` à 26 m à l'ouest de la source, et
   à `−14,0` à 15 m à l'est du guet. Depuis la vasque, l'œil à 1,7 m voit le sommet
   de la tour à 20,4 m d'altitude relative là où la lèvre n'est qu'à 14,0 — **le haut
   de la tour se lit sur le ciel, son pied reste caché par la lèvre**. C'est le cadre
   commun que le brief demande, et il est donné par le terrain, pas fabriqué.
2. **L'affluent NAÎT au lieu de la source.** Premier point de `west_tributary_xz` :
   `(-130, 34)`, soit **8,49 m** au nord-est du site. `_trib_bed_curve(0) = 11,0` et
   la surface d'eau y vaut `11,6` — **40 cm sous le pad de la source (12,0)**. La
   vasque n'a donc rien à inventer : elle déverse vers un lit qui existe déjà, en
   pente douce, et le déversoir du lieu doit pointer là.

## 1. Les contraintes qui interdisent, mesurées avant de poser quoi que ce soit

- **`cam05_belvedere_crete` est POSÉE SUR le belvédère** : `(166, 54)`, à **2,83 m**
  du site `(168, 52)`, visant `(0, 26, 170)`. Direction locale ≈ `(−0,82 ; +0,573)`.
  Tout point local à `x > 0` est **derrière** la caméra (produit scalaire négatif) :
  la masse du sommet va donc **à l'est**, et l'ouverture reste à l'ouest-sud-ouest,
  ce qui est exactement le « regard de retour » que le layout demande.
- **La route 2 traverse le belvédère** : `heights_route` porte le waypoint littéral
  `[168, 52]`, entre `[158, 42]` (NO) et `[190, 30]` (NE). Le filet échantillonne la
  route au mètre et refuse tout collider dont l'AABB XZ passe à moins de **1,2 m**
  (`ROUTE_CLEAR_M` du **test**, pas les 2,3 m de la végétation). La diagonale NE est
  donc un couloir : toutes mes masses restent à ≥ 3,5 m de la ligne
  `(0,0) → (+22,−22)`, vérifié par distance perpendiculaire.
- **`cam03` passe à 14,0 m du cimetière**, mais son rayon y est **17,1 m au-dessus du
  sol** : mes tertres culminent à 2,1 m, aucun risque. `cam02` passe à 38,2 m du
  sanctuaire (rayon 6,6 m au-dessus du sol), `cam04` à 33,8 m et **au-delà** de sa
  fraction surveillée. Les quatre autres n'approchent aucun de mes six.
- **La route 2 frôle le sanctuaire à ≈ 7,3 m** (segment `[80,80]→[120,90]`) et
  **2 à 3 m plus bas**. « Invisible de la route » ne peut donc pas venir de la
  distance : il vient de la **hauteur** (rien au-dessus de 2,4 m) et d'un **rideau de
  fougères et de buissons sur l'arc nord-est**. C'est honnête et c'est vérifiable.
- **`anchor.r08` est à 5,66 m** du cimetière (local `(+4, +4)`). Aucun tertre ne le
  couvre : le Tertre Moyen est déplacé à `(+9,0 ; +6,5)`, soit 5,6 m de son bord.
- **Bandes d'eau interdites** : 9,5 m (cours principal), 6,3 m (affluent), lac+2 m.
  Le seul lieu concerné est la source, à 8,49 m de l'affluent — **conforme**, et
  aucune de ses pièces ne porte de collider à moins de 5 m de la tête du lit.

## 2. Ce que le kit sait faire — mesuré, pas supposé

`python3 tools/gltf_inspect.py` sur chaque module employé. Point capital pour les
budgets : **chaque module du kit ne porte qu'UN maillage** (`meshes: 1`), donc
`modules ≈ MeshInstance3D`. Les surfaces multiples sont des matériaux, pas des nœuds.

| module | dim. natives (m) | min Y | tris | emploi |
|---|---|---:|---:|---|
| `Wall_UnevenBrick_Straight` | 2,00 × 3,12 × 0,41 | 0,000 | 56 | fût du guet |
| `Corner_Exterior_Brick` | 0,53 × 3,02 × 0,58 | −0,007 | 3102 | chaînages d'angle |
| `SM_Dungeon_CaveRock` | 2,64 × 4,35 × 2,81 | 0,000 | 320 | corne du belvédère |
| `SM_Dungeon_CaveWallTop` | 4,00 × 4,50 × 1,13 | 0,000 | 148 | ailes penchées |
| `SM_Dungeon_CaveWallHalf` | 2,00 × 4,05 × 1,81 | 0,000 | 192 | épaules de la fente |
| `SM_Dungeon_CaveArch` | 4,00 × 4,05 × 2,45 | 0,000 | 360 | **la gueule** de la source |
| `SM_Dungeon_PillarStub` | 1,00 × 1,31 × 1,00 | 0,000 | 186 | moignons du sanctuaire |
| `SM_Dungeon_ArchBlock` | 0,93 × 1,01 × 0,93 | 0,000 | 308 | montants, autel, dolmen |
| `SM_Dungeon_RubbleLarge/Small` | 1,20 × 0,50 × 1,35 | 0,000 | 150/140 | gravats |
| `Rock_Medium_1/2/3` | 3,0-3,4 × 1,9-2,3 × 2,5-3,5 | −0,05..−0,32 | 244-522 | épaule, pierre-repère |
| `rock_largeA/C`, `rock_smallB` | 0,78-1,06 × 0,18-0,32 | 0,000 | 24-80 | margelles, éclats |
| `RockPath_*` | 1,0-2,1 × 0,11-0,18 | −0,009 | 783-3500 | dalles, stèles couchées |
| `cliff_half_rock` | 1,00 × 0,50 × 0,42 | 0,000 | 53 | stèles penchées |
| `Fern_1` | 9,05 × 2,69 × 8,49 | −0,247 | 288 | facteur `KitScale` 0,2306 → 0,62 m |
| `Prop_Vine1` | 1,54 × 2,60 × 0,22 | **−2,12** | 82 | à poser à `y = +2,07` (piège consigné, ferme) |

`KitScale.factor()` corrige `cliff_*` (×9 à ×12) et `rock_large*` (×1,1 à ×1,55) ;
`Rock_Medium_*` et `SM_Dungeon_*` tombent déjà juste et restent à 1,0.
`KitPlacement.seat()` est **inopérant** sur tous ces modules (leur `min Y ≤ 0,05`) :
l'assise est entièrement de ma responsabilité, via `ground_local_y()`.

## 3. Les six lieux — silhouette en trois masses, modules, budget

Famille et plafond (`WORLD_V2_POI_CONTRACTS.md` §4) :
micro-POI naturel **≤ 12 modules / 30 nœuds visuels / 6 collisions** ;
ruine et vestige **≤ 40 / 80 / 20**.

---

### 3.1 `watchtower_ruin` — RUINE — prévu **38 / 38 / 7**

**Trois masses.** ① *Le fût cisaillé* : un fût carré de 4 m qui tient 9,1 m à l'ouest
et descend en escalier jusqu'à zéro à l'est — une diagonale franche, pas un moignon
symétrique. ② *Le talus de la brèche* : une masse basse et étalée qui sort du fût
côté est et court jusqu'à la lèvre. ③ *Les blocs pris dans la pente* : deux ou trois
masses isolées sur la face à 57°, sous la lèvre — elles disent que la couronne est
tombée dans le vide.

**Pourquoi ce lieu ne ressemble à aucun des sept.** C'est la seule masse
**orthogonale et élancée** du lot, et la seule dont la ligne haute soit une
**diagonale** : le hameau et la ferme sont larges et coiffés, le pylône est mince et
intact, la grotte est une bouche dans un flanc. Ici, un mur qui s'arrête net.

**Modules** (38) : 13 `Wall_UnevenBrick_Straight` répartis sur trois assises
inégales (7 / 4 / 2, la troisième enfoncée de 0,25 et 0,62 m pour casser l'arase) ·
6 `Corner_Exterior_Brick` (l'angle nord-est manque, il est tombé avec la brèche) ·
2 `SM_Dungeon_ArchBlock` + 1 `SM_Dungeon_RubbleSmall` posés SUR les arases ·
2 `Stairs_Exterior_Straight` (l'escalier intérieur, visible par la brèche) ·
2 `Floor_UnevenBrick` · 2 `SM_Dungeon_RubbleLarge` + 1 `SM_Dungeon_CaveRock` +
2 `Wall_UnevenBrick_Straight` **couchés** + 2 `rock_largeC` (talus et blocs) ·
1 `Prop_Vine1` + 2 `Bush_Common` + 2 `Plant_7` (végétation de fissure, r04).

**Implantation.** Centre du fût à `(−2,2 ; +0,4)` local : sa face est tombe à
`x = −0,2`, soit **4 m avant le début de la pente** (mesurée à r=4). Dégagement
dorsal ouest ≥ 5 m libre de toute masse haute (r04, mode Climb).
**Récompense** : `CHEST` (15 flèches) à l'intérieur, au pied de la brèche.

---

### 3.2 `overlook_summit` — REPÈRE NATUREL — prévu **12 / 12 / 4**

**Trois masses.** ① *La corne* : un bloc rocheux unique de 6,3 m, penché vers
l'ouest-sud-ouest, seul point aigu du sommet. ② *Les deux ailes* : deux fins
rocheux plus bas qui l'encadrent et laissent entre eux une **brèche de 4,4 m ouverte
à l'OSO** — on passe dedans et la vallée s'ouvre. ③ *L'épaule* : deux blocs bas
demi-enterrés au bord de la rupture sud, une tablette où l'**arc** est posé.

**Pourquoi ce lieu ne ressemble à aucun des sept.** C'est le seul dont la silhouette
soit **portée par le terrain** — une butte large de 60 m coiffée d'un unique accent —
et le seul construit autour d'un **vide** (la brèche) plutôt que d'un volume.

**Modules** (12) : `SM_Dungeon_CaveRock` ×1 (corne) · `SM_Dungeon_CaveWallTop` ×1 et
`SM_Dungeon_CaveWallHalf` ×1 (ailes) · `Rock_Medium_1` et `_2` demi-enterrés
(épaule) · `rock_largeC` ×1 (la tablette de l'arc) · `rock_smallB` ×2 ·
`Bush_Common` ×2 (broussaille couchée par le vent) · `Grass_Wispy_Tall` ×2.

**Implantation.** Tout en `x_local > 0` (derrière `cam05`) et à ≥ 3,5 m de la
diagonale de route `(0,0) → (+22,−22)`, distances perpendiculaires calculées :
corne 7,4 m · aile 2 7,8 m · aile 3 8,2 m.
**Récompense** : `WEAPON` (arc simple) sur la tablette, `requires_traversal = false`
— le fondu de la butte a été élargi précisément pour qu'on y **marche** (commentaire
mesuré de `world_v2_heightmap.gd`), prétendre le contraire serait faux.

---

### 3.3 `turquoise_spring` — REPÈRE NATUREL — prévu **12 / 13 / 4**

**Trois masses.** ① *La paroi et sa fente* : le mur de 14 m (terrain gelé, déjà rendu
en roche par le shader au-delà de 55°), percé à son pied d'une arche sombre flanquée
de deux épaules rocheuses. ② *La vasque* : une ellipse claire et basse tenue par un
anneau **rompu** de pierres pâles demi-enterrées. ③ *Le fil qui s'en va* : trois
dalles mouillées et une frange de fougères qui filent au nord-est, droit vers la tête
de l'affluent.

**Pourquoi ce lieu ne ressemble à aucun des sept.** C'est le seul lieu **clair** et
le seul dont la lecture soit **horizontale et brillante au pied d'un vertical** ; la
grotte du couchant est une poche qu'on pénètre, la source est une fente qu'on ne
pénètre pas. Et il partage son cadre avec le guet, ce qu'aucun autre couple ne fait.

**Modules** (12) : `SM_Dungeon_CaveArch` ×1 (la gueule, ×0,62 → 1,2 m d'ouverture) ·
`SM_Dungeon_CaveWallHalf` ×2 (épaules) · `rock_largeA` ×1 + `rock_largeC` ×2
(margelles) · `Rock_Medium_2` ×1 demi-enterré (bloc tombé de la paroi) ·
`RockPath_Round_Small_1` ×2 + `RockPath_Square_Small_1` ×1 (déversoir) ·
`Fern_1` ×1 · `Plant_7` ×1.

**Le seul maillage runtime du lot, et sa raison.** `NappeSource` : la nappe d'eau.
Exemption **nommée**, même famille que `SolBrule` et `rock_floor_mesh` — une nappe
doit être **de niveau** dans une cuvette dont le fond est le terrain gelé, et sa forme
irrégulière est ce qui l'empêche de se lire comme une décalcomanie. Aucun collider,
aucune logique systémique : ce lieu **n'ajoute pas d'eau au monde**, il en montre.
Turquoise de la bible (`#4FAFB2` / `#2A7182`), jamais le cyan de Résonance.
**Récompense** : `INGREDIENT` (fruit de soin) sur la margelle est.

---

### 3.4 `forest_shrine` — VESTIGE — prévu **31 / 31 / 7**

**Trois masses.** ① *La table basse* : un autel horizontal à hauteur de hanche, une
dalle sur deux dés, avec une tablette de **céramique ivoire** posée dessus (grammaire
du vestige, §2.3). ② *L'anneau rompu* : cinq moignons inégaux (0,85 / 1,35 / 1,95 /
2,35 m, plus un **couché en travers**) disposés à pas irréguliers autour d'elle — un
anneau incomplet, motif propre à la technologie du monde. ③ *Le couvert qui l'avale* :
fougères, buissons et trois troncs qui montent bien plus haut que tout le bâti.

**Pourquoi ce lieu ne ressemble à aucun des sept.** Il est le seul dont **rien** ne
dépasse 2,4 m, et le seul conçu pour ne PAS se voir : sa silhouette est un trait
horizontal bas sous des masses végétales. C'est l'inverse exact du guet.

**Modules** (31) : 2 `SM_Dungeon_ArchBlock` + 1 `RockPath_Square_Wide` + 1
`Floor_Brick` ivoire (la table) · 5 `SM_Dungeon_PillarStub` à quatre échelles
(l'anneau) · 3 `Floor_UnevenBrick` enfoncés + 3 `Pebble_*` (le dallage avalé) ·
4 `Fern_1` + 3 `Plant_7` + 3 `Bush_Common` + 3 `Mushroom_*` (la frange) ·
2 `Pine_3` + 1 `CommonTree_3` (le couvert).
**Récompense** : `INGREDIENT` (épice rare) sur la dalle de l'autel.

> **À VÉRIFIER en phase 2** : la végétation V2.2 gelée **n'exclut pas les sites de
> POI** (lu dans `world_v2_vegetation_builder.gd` : elle n'exclut que routes, gués,
> checkpoints et caméras). La note du layout « clairière calme garantie » n'est donc
> **pas** appliquée par du code. `probe_vegetation_near` décidera si mes trois
> troncs sont posables, ou s'ils doublent des arbres gelés — auquel cas ils sautent.

---

### 3.5 `barrow_cemetery` — VESTIGE — prévu **23 modules / 26 nœuds / 6 collisions**

**Trois masses.** ① *Trois tertres* de tailles franchement inégales (r = 6,2 / 4,4 /
3,0 m ; h = 2,10 / 1,35 / 0,80 m), posés en triangle lâche avec **beaucoup de vide
entre eux** — la densité basse est le contrat de r08. ② *La chambre ouverte* : le
grand tertre est **mordu** sur son flanc sud-est par une gueule de dolmen — deux
montants, une dalle de couverture, et la matière qui en a été sortie répandue devant.
③ *Les stèles couchées* : huit dalles éparpillées jusqu'à 16 m, la plupart à plat et
à moitié avalées par l'herbe, deux encore debout et penchées.

**Pourquoi ce lieu ne ressemble à aucun des sept.** C'est le seul lieu **rond et
répété-mais-inégal**, et le seul dont la lecture soit funéraire. Rien d'autre dans le
monde n'a de dôme de terre.

**Trois maillages runtime, et leur raison.** `Tertre_Grand/Moyen/Petit` : un tertre
est un **gonflement du sol**, pas un objet posé dessus. Aucun module de kit ne peut
se raccorder au terrain gelé à sa lisière ; c'est exactement la famille d'exemption
de `SolBrule`. Chaque dôme est irrégulier (rayon haché par secteur, lissé sur trois
voisins — la recette anti-« étoile » de l'arbre foudroyé), et chacun est **ceinturé
de pierres de kit** demi-enterrées : l'œil lit de la pierre et de la terre, pas une
primitive. Collision : **une sphère** par tertre, non une boîte — un dôme se franchit
en marchant, une boîte s'y cogne.
**Récompense** : `CHEST` (hache lourde) à la gueule du dolmen — le layout dit
« coffre », et le `kind` de l'ancrage est ce qui décide.

---

### 3.6 `flower_field` — REPÈRE NATUREL — prévu **12 / 12 / 1**

**Trois masses.** ① *Presque rien* : le lieu est **plat**. ② *La pierre-repère* : un
seul bloc erratique penché, 1,7 m hors sol, demi-enterré. ③ *La fourche* : une ligne
de dalles pâles à demi avalées qui arrive du sud-est (de la crête de départ) et se
**sépare en deux** au pied de la pierre — une branche au nord-ouest, une au sud-ouest.

**Pourquoi ce lieu ne ressemble à aucun des sept — ni aux cinq autres.** C'est le
**seul du lot sans masse verticale**. En aplat noir, les cinq autres sont des volumes ;
celui-ci est une bande vide avec un caillou. Son identité n'est pas un objet, c'est
**une décision** : il est à 32 m de la ferme et 37 m de l'arbre foudroyé, donc il ne
peut ni bâtir ni planter sans les répéter — mais il est le premier lieu atteignable,
et le layout en fait le point du « premier choix de route ». La fourche EST le lieu.

**Modules** (12) : 7 `RockPath_*` demi-enfoncées (la fourche) · 1 `Rock_Medium_1`
penché (la pierre) · 2 `Bush_Common_Flowers` + 1 `Flower_4_Group` +
1 `Grass_Wispy_Tall` (le halo, resserré sur l'angle de la fourche).
La prairie fleurie autour est **celle de la V2.2 gelée** : le lieu ne la repeint pas,
il lui donne un centre — même parti que l'arbre foudroyé, qui a retiré ses propres
fleurs pour laisser la prairie gelée jouer.
**Récompense** : `INGREDIENT` (herbe d'endurance) sous le vent de la pierre.

---

## 4. Récapitulatif des budgets prévus

| lieu | famille | modules | nœuds visuels | collisions | plafond |
|---|---|---:|---:|---:|---|
| `watchtower_ruin` | ruine | 38 | 38 | 7 | 40 / 80 / 20 |
| `overlook_summit` | naturel | 12 | 12 | 4 | 12 / 30 / 6 |
| `turquoise_spring` | naturel | 12 | 13 | 4 | 12 / 30 / 6 |
| `forest_shrine` | vestige | 31 | 31 | 7 | 40 / 80 / 20 |
| `barrow_cemetery` | vestige | 23 | 26 | 6 | 40 / 80 / 20 |
| `flower_field` | naturel | 12 | 12 | 1 | 12 / 30 / 6 |

Ces chiffres sont **prévus**, donc `NON VÉRIFIÉ` : ils seront remplacés par la sortie
de `tools/godot/probe_place_metrics.gd` en phase 2, et c'est celle-là qui compte.

## 5. Ce que la voie B ne fait pas

Aucune inscription au `REGISTRY` (c'est la voie A) · aucun élément gelé touché ·
aucune écriture dans `STATUS`/`PROGRESS`/`KNOWN_ISSUES`/`CLAUDE.md` · aucun ajout à
`world_v2_place_kit.gd` (partagé entre les trois voies : les rares aides dont j'ai
besoin — sphère de collision, dôme de tertre, nappe — vivent dans mes propres
scripts, et je signale au lead celles qui mériteraient de monter dans le kit).
