# CONCEPTION — Sanctuaire forestier (`valley.poi.forest_shrine.01`)

Intention imposée (ADDENDUM_DA) : **le sacré repris par la nature** —
calme, mystère, respect. La forêt révèle progressivement une construction
absorbée par arbres et mousse. Un seuil, un centre rituel, une lumière ou
une ouverture qui guide le regard. PAS des murs déposés entre les arbres.

## Émotion et micro-histoire

Émotion : le silence qu'on baisse d'instinct — on est chez quelqu'un
d'ancien. Micro-histoire sans texte : un peuple d'avant la vallée a dressé
ici des pierres autour d'une table d'offrande ; la forêt a repris le
dallage, couché une pierre, cassé la table — mais quelqu'un dépose ENCORE
une offrande (l'épice rare posée sur l'autel) : le lieu n'est pas mort,
il est seulement plus vieux que nous. Contrainte d'identité conservée :
invisible depuis la route (rien au-dessus de 2,4 m hors troncs, rideau
végétal sud sans collider), découvert en entrant par le nord.

## Lectures aux trois distances

- **80–120 m** : RIEN — c'est le contrat du lieu (la curiosité seule y
  mène). La promesse est négative : une poche d'ombre plus dense dans le
  bois, deux troncs plus vieux que les autres.
- **30–50 m** : les fûts des pins cadrent des masses grises basses entre
  les fougères — de la pierre TAILLÉE, donc une main humaine, mais pas
  un mur.
- **5–15 m** : le seuil (deux pierres dressées inégales, une marche
  enfoncée), l'axe court vers la table brisée, la mousse dans les creux,
  l'offrande. La révélation est intime, pas monumentale.

## Élément héroïque unique

La **table d'offrande brisée encore servie** : une dalle fendue en deux,
un pan glissé, et l'épice rare posée dessus — le seul lieu du lot où la
récompense EST la narration.

## Palette et valeurs RENDUES (mesurées sur `avant/forest_shrine_joueur.png`)

- sous-bois : ≈ 0,30 ; troncs : ≈ 0,16 ; falaise lointaine : ≈ 0,57.
- cible pierre ancienne : 0,32–0,45 rendu (plus sombre que la pierre de la
  tour — elle vit à l'ombre), mousse dans les creux 0,26–0,34, à VÉRIFIER
  par capture (le gain d'ombre du monde est non linéaire, scripts/CLAUDE).
- interdit : le beige `SM_Dungeon_*` (cause mesurée du rejet) et tout
  accent saturé — le seul point chaud est l'épice orange doré (récompense).

## Mouvements et effets locaux

- fougères et rideau sud existants (vent V2.2) ;
- champignons au pied des pierres (existants au kit) ;
- AUCUNE lumière locale ajoutée : la « lumière qui guide » est une
  TROUÉE — les trois troncs plantés par le lieu sont déplacés pour ouvrir
  un puits de jour au-dessus de l'autel (le contraste clairière/couvert
  guide le regard sans un seul lumen ajouté).

## Références (décrites)

1. Alignements néolithiques sous futaie bretonne : pierres dressées
   moussues, à demi avalées, aucun mur.
2. Chapelles rupestres abandonnées des Pyrénées : un seuil encore net,
   un intérieur rendu au lierre.
3. Jardins de mousse japonais (Saihō-ji) : la mousse comme matière
   PRINCIPALE, valeurs sourdes, lumière tamisée en taches.
4. La « ruine pédagogique » du contrat §24.4 de la bible : des vestiges
   qui enseignent un langage sans texte.

## Assets utilisables / bloquants

- UTILISABLES : `Fern_1`, `Bush_Common`, `Mushroom_*`, `Plant_7`,
  `Pine_3`/`CommonTree_3` (troncs du lieu, déplaçables), `Pebble_*`,
  `Floor_UnevenBrick` (dallage avalé, teinte mousse) ; nouveau GLB dédié
  `SM_Shrine_Vestige.glb` (pierres levées brisées à profils tous
  différents, table fendue, seuil — budget ≤ 6 k tris).
- BLOQUANTS (à retirer) : `SM_Dungeon_PillarStub` (moignons beige — cause
  mesurée du rejet), `SM_Dungeon_ArchBlock` (autel-cube beige),
  `RockPath_Square_Wide` en couverture (dalle trop propre).

## DEUX compositions

### A — « L'anneau rompu » (évolution de l'existant)

Cinq pierres levées BRISÉES à profils tous différents (4 debout inégales
0,8–2,3 m, 1 couchée en travers), autel-table fendu au centre, seuil au
nord, dallage avalé, brèche principale de l'anneau vers le nord.
+ : continuité avec l'implantation validée (appuis, colliders quasi
inchangés) ; lecture « cercle sacré » immédiate.
− : même effondré, un anneau reste un ANNEAU — parenté de silhouette avec
le futur `watchers_circle` (qui possédera le cercle intact) ; le regard
tourne autour du centre au lieu d'être GUIDÉ vers lui.

### B — « La nef avalée » (recommandée)

Un AXE court sud-nord : le seuil (deux montants inégaux + marche enfoncée)
au nord, deux rangées basses de socles/pierres rompues (0,4–1,1 m) qui
convergent vers la table d'offrande adossée à une pierre de chevet plus
haute (2,1 m, la seule verticale), les troncs du lieu déplacés pour
ouvrir la trouée de jour au-dessus de la table. La pierre couchée barre
à demi la nef — on l'enjambe pour approcher.
+ : joue mot pour mot « un seuil, un centre rituel, une lumière qui guide
le regard » ; supprime toute parenté avec `watchers_circle` (D3 par
construction) ; hiérarchie centrale forte.
− : déplace davantage l'existant (appuis et colliders à redéclarer) ; la
pierre de chevet approche le plafond des 2,4 m (2,1 m mesuré, marge fine).

**Recommandation : B** — l'anneau, même rompu, reste la silhouette d'un
autre lieu du layout ; la nef donne au regard UNE direction et à la
récompense un écrin. A reste disponible si le lead veut minimiser le
déplacement des appuis validés.

## Parcours joueur (20–40 s, monde ; sol ≈ 7,0 sur tout le pad)

1. P1 (84, 7, 81) — sur la route : RIEN à voir (c'est la promesse du
   lieu) ; une ombre plus dense au nord (regard N).
2. P2 (81, 7, 76) — on quitte la route par l'ouest : masses grises entre
   les fougères (regard NE).
3. P3 (86, 7, 70,5) — le seuil nord : deux montants inégaux, la marche
   (regard S, l'axe s'ouvre).
4. P4 (86, 7, 72,5) — la nef : les socles convergent, la pierre couchée
   à enjamber, la trouée de jour sur la table (regard S).
5. P5 (86, 7, 74) — révélation/récompense : la table fendue, l'épice
   dorée (regard bas puis haut vers la trouée).
6. P6 (86,5, 7, 76) — sortie : dos à la table, la route réapparaît entre
   les fougères (regard S) — on comprend qu'on est passé à 7 m sans rien
   voir.
