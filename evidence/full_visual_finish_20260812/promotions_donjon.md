# Journal — habillage visuel du donjon (agent DONJON/ARCHITECTURE)

Date : 2026-08-12 · branche `claude/full-world-visual-finish` · aucun commit,
aucun test lancé, aucun Godot lancé (contrat du chantier). Validation attendue :
captures par l'intégrateur.

## Promotions (10 modèles, tous `=== VALIDE ===` à `tools/gltf_inspect.py`)

Licence des deux packs : **CC0 1.0 Universal**, vérifiée dans
`asset_library/inbox/<pack>/PROVENANCE.md` et `License.txt` (auteur Kenney,
pages officielles kenney.nl, SHA-256 des archives consignés dans les
PROVENANCE). L'intégrateur fusionne dans `ATTRIBUTIONS.md` et
`docs/assets/ASSET_MANIFEST.csv` depuis ce tableau.

| Source exacte (asset_library/inbox/…) | Destination (assets/environment/dungeon/) | Tris | Dim. (m) | Emploi |
|---|---|---:|---|---|
| kenney_modular_cave_1_0/Models/GLB format/template-wall.glb | SM_Dungeon_CaveWall.glb | 440 | 4,0 × 4,05 × 2,16 | parois rocheuses salle 2 (murs E/S/N) |
| kenney_modular_cave_1_0/…/template-wall-half.glb | SM_Dungeon_CaveWallHalf.glb | 192 | 2,0 × 4,05 × 1,81 | bouche-trous de la même paroi |
| kenney_modular_cave_1_0/…/template-wall-top.glb | SM_Dungeon_CaveWallTop.glb | 148 | 4,0 × 4,5 × 1,13 | corniche au sommet de la bande rocheuse (salle 2) |
| kenney_modular_cave_1_0/…/gate-rock.glb | SM_Dungeon_CaveArch.glb | 360 | 4,0 × 4,05 × 2,45 | arches AVEUGLES plaquées sur murs pleins (salle 2 nord, salle 4 nord) |
| kenney_modular_cave_1_0/…/template-detail.glb | SM_Dungeon_CaveRock.glb | 320 | 2,64 × 4,35 × 2,81 | formations rocheuses de coins (salles 2 et 4, arène) |
| kenney_castle_2_0/Models/GLB format/wall-pillar.glb | SM_Dungeon_PillarStub.glb | 186 | 1,0 × 1,31 × 1,0 | bornes de quai ×1,5 (salle 4) |
| kenney_castle_2_0/…/rocks-large.glb | SM_Dungeon_RubbleLarge.glb | 150 | 1,20 × 0,5 × 1,35 | gravats (salles 1-2, hall, arène) |
| kenney_castle_2_0/…/rocks-small.glb | SM_Dungeon_RubbleSmall.glb | 140 | 1,03 × 0,5 × 1,11 | gravats (toutes salles, vestibule) |
| kenney_castle_2_0/…/flag-banner-long.glb | SM_Dungeon_Banner.glb | 68 | 0,04 × 2,17 × 0,63 | bannières (salle 3, hall, antichambre, arène) — TOUJOURS teintées par `material_override` (ivoire/bronze) car les couleurs du kit sortent de la palette §12.1 |
| kenney_castle_2_0/…/tower-square-arch.glb | SM_Dungeon_ArchBlock.glb | 308 | 0,93 × 1,01 × 0,93 | arcades aveugles mises à l'échelle (salle 3 ×3,4, hall ×4,2) |

Les `.glb` ne sont PAS importés : ils attendent l'import de l'intégrateur.
Tout le code de chargement passe par `AssetRegistry.model()` (repli silencieux
si absent — les salles restent exactement ce qu'elles étaient).

### Textures externes (correction post-constat intégrateur, 2026-08-12)

Les GLB Kenney ne sont pas autosuffisants : chacun référence une texture
EXTERNE `Textures/colormap.png` — et les deux packs ont chacun un
`colormap.png` DIFFÉRENT sous le même nom (sha256 distincts). Un sous-dossier
par pack aurait cassé `AssetRegistry.model()` (scan NON récursif du dossier
plat, et `asset_registry.gd` est hors de mon périmètre). Correction retenue :
l'URI du chunk JSON de chaque GLB promu a été réécrite (script Python,
padding GLB respecté, chunk BIN intact) vers deux noms distincts, et les deux
textures ont été promues à côté. Les 10 GLB repassent `gltf_inspect.py`
`=== VALIDE ===` après réécriture.

| Source exacte | Destination | Référencée par |
|---|---|---|
| kenney_modular_cave_1_0/Models/GLB format/Textures/colormap.png (sha256 4a19ed0e…) | assets/environment/dungeon/Textures/colormap_cave.png | les 5 SM_Dungeon_Cave*.glb |
| kenney_castle_2_0/Models/GLB format/Textures/colormap.png (sha256 66fd49be…) | assets/environment/dungeon/Textures/colormap_castle.png | SM_Dungeon_PillarStub/RubbleLarge/RubbleSmall/Banner/ArchBlock.glb |

Licence : CC0 1.0 (mêmes packs, mêmes PROVENANCE.md). À reporter dans
`ATTRIBUTIONS.md` / `ASSET_MANIFEST.csv` avec les GLB. Note : les GLB promus
ne sont donc plus les octets EXACTS des fichiers sources — seule l'URI
d'image diffère ; la géométrie, les matériaux et le binaire sont inchangés.

## Mécanisme

- `DungeonRoom.dress_prop()` (nouveau, `scripts/dungeon/dungeon_room.gd`) :
  prop d'habillage PUR — aucune collision, nom explicite, teinte optionnelle
  par aplat (`StandardMaterial3D`, pour les bannières). Repli `null` si le
  modèle n'est pas importé.
- Chaque salle appelle `_build_dressing()` en fin de `_ready()`. La passe
  générique `RoomDressing` (briques/pilastres, différée) reste inchangée et
  se superpose : mes panneaux muraux vivent à ≥ 0,3 m des faces pour éviter
  le z-fighting avec ses briques (offset roche 0,45 m).
- AUCUNE logique de puzzle, socket, batterie, porte, hazard, reset, port ni
  collision d'un chemin joueur n'a été modifiée. Aucune rotation sur nœud
  porteur de collision (les rotations vivent sur `MeshInstance3D`/`Node3D`
  sans corps). Lumières AJOUTÉES : 3 au total, toutes énergie ≤ 1,2 et
  portée ≤ 7, motivées (lanterne d'établi, deux torchères).

## Par salle

### Salle 1 — Room1Initiation (`room1_initiation.gd`) — ATELIER/ENTREPÔT
3 poutres de bois au plafond ; coin atelier ouest (Workbench, Anvil,
Shelf_Simple, Bucket_Metal, Lantern_Wall + `WorkbenchLampGlow` é1,2/p7) ;
entrepôt est (2 Crate_Wooden, Barrel, Crate_Metal, Chain_Coil) ; gravats NE
et SW ; 3 fissures hautes (au-dessus des 2 rangs de briques RoomDressing) ;
fronton ivoire au-dessus de la porte du puzzle (dégagé du vantail).

### Salle 2 — Room2Vertical (`room2_vertical.gd`) — PUITS TAILLÉ ROCHE
Parois « Modular Cave » sur murs EST (2 rangs + corniche, en évitant la
colonne montante x=6,7/z−5..−1 et la zone source/aiguillages), SUD (2 rangs +
corniche + panneau enjambant le linteau à y=5) et NORD (2 rangs + corniche).
Mur OUEST volontairement nu : voie d'escalade + électrodes. Portail de roche
aveugle sous la porte de la mezzanine (x=2, écho du seuil du haut, à 3 m du
couloir de l'ascenseur) ; 2 formations rocheuses aux coins sud ; gravats à
l'entrée (à ≥ 2,5 m du déclencheur de porte) ; 4 corbeaux de bronze sous la
lèvre de la mezzanine, HORS du couloir de l'ascenseur (x −0,8..2,8 évité).

### Salle 3 — Room3Relays (`room3_relays.gd`) — GALERIE CÉRÉMONIELLE
Colonnade (4 colonnes nord z=−8,5, 2 sud z=8,5 — module Corner_Exterior_Brick
étiré ×2,9 ≈ 8,7 m) ; 3 arcades aveugles au mur nord ; plinthes + bandeau +
2 nervures de plafond en céramique ivoire ; 2 bordures de sol ivoire cadrant
le champ des relais (marges 2,2-2,4 m) ; 4 bannières teintées ivoire ;
2 torchères sur les colonnes sud + 2 lumières motivées (é0,9/p6) ; gravats
NW ; 2 fissures hautes.

### Salle 4 — Room4Battery (`room4_battery.gd`) — CITERNE HUMIDE
4 bornes de quai (PillarStub ×1,5) aux coins du canal ; 4 margelles de pierre
mouillée le long des lèvres (dégagées des berceaux à planche z ±1) ; mousse
sur berges et pied de mur ; 3 radeaux d'algues sur la nappe (verts désaturés,
jamais cyan) ; traînées de ruissellement nord/sud + plafond taché au-dessus
du canal ; 2 arches rocheuses aveugles au mur nord ; 2 formations rocheuses
de coins ; gravats SE ; chaîne et seau sur les quais.

### Salle centrale — CentralHall (`central_hall.gd`) — CARREFOUR MONUMENTAL
2 colonnes monumentales aux angles sud (×3,6 ≈ 10,9 m) ; 4 colonnes de
soutien sous la galerie (×1,85 ≈ 5,6 m, sous la dalle à 5,75) ; 2 arcades
aveugles flanquant le seuil de la salle 3 ; 4 bannières bronze (sud ×2, est,
ouest — l'ouest au-dessus de la rampe, bas à y=6, la rampe y passe sous) ;
incrustation de sol ivoire au croisement des axes (0,04 m, à 2,4 m du
pilier-récepteur nord) ; 4 frontons ivoire au-dessus des seuils ;
couvre-main ivoire sur le garde-corps ; encadrement ivoire de la porte du
boss à z=−14,78 (le vantail coulisse à z −15,55..−14,95 : 0,17 m de jeu) ;
gravats aux pieds des colonnes sud.

### Antichambre — Antechamber (`antechamber.gd`) — SALLE DE REPOS
2 poutres de bois ; coin armurerie est (WeaponStand + Shield_Wooden, à 4 m du
coffre) ; table de préparation (Table_Large + Bottle_1 + Book_Stack_1 posés
au plateau mesuré 0,81 m) ; banc + sac près du feu (à 3,7 m de l'anneau) ;
réserves NW (Crate_Wooden, Barrel, Pot_1, loin de la fresque) ; 2 bannières
bronze flanquant baie + seuil de l'arène ; cadre ivoire de la fresque à
x=−8,65, DERRIÈRE ses nœuds de démonstration (x=−8,5) ; gravats SW.

### Arène — BossArena (`boss_arena.gd`) — AMPHITHÉÂTRE D'ORAGE
6 arcs de gradins en ruine (2 gradins × 3 blocs par arc, hauteurs 0,5-1,3 m,
r 17,5/18,55) centrés à 67,5/112,5/157,5/202,5/247,5/292,5° — marge ≥ 15°
(≈ 4,5 m) des pylônes, des braseros et du seuil sud ; 3 impacts de foudre
ANCIENS (`_lightning_scar` : disque charbon + 5 éclats rayonnants, gris — le
cyan reste au danger actif), posés à y 0,055-0,06 au-dessus des zones de sol,
à ≥ 2 m du spawn du Gardien, des rainures et du rail ; 2 affleurements de
roche mère + 4 tas de gravats au pied du mur ; 2 bannières bronze sombre ×2
au-dessus des gradins.

### Vestibule — CitadelVestibule (`citadel_vestibule.gd`)
Touche légère (la salle était déjà la mieux habillée) : 3 lierres retombants
(Prop_Vine1/2, origine du modèle EN HAUT — accrochés à y 4,6-5,2) et
2 gravats d'angle, via la table `_dress_interior` existante.

## Risques à vérifier en capture (intégrateur)

1. **Panneaux rocheux salle 2** : relief proud de ~0,45 m SANS collision — un
   joueur qui rase le mur est/sud/nord peut y entrer visuellement. Voulu
   (bas-relief) ; vérifier que ça ne choque pas en caméra d'épaule.
2. **Arches aveugles (CaveArch)** : jambages proud de ~1 m sans collision
   (salle 2 nord, salle 4 nord). Même clip possible au ras du mur.
3. **Bannières (flag-banner-long)** : orientation de la face visible non
   vérifiable hors moteur (mesh possiblement à faces simples). Si une
   bannière est invisible sous un angle, inverser son yaw (+PI). Vérifier
   aussi que la teinte `material_override` couvre bien toutes les surfaces.
4. **Gradins de l'arène** : décor sans collision — un joueur peut marcher au
   travers dans la marge de terre (r 14-19). Hauteurs volontairement basses
   (≤ 1,3 m) pour lire « ruine », pas « plateforme ». À juger en jeu.
5. **Ouverture interne de SM_Dungeon_CaveArch / ArchBlock** non mesurée hors
   moteur (seule la bbox l'est) : les mises à l'échelle (×3,4 salle 3, ×4,2
   hall) sont à contrôler visuellement.
6. **AABB de capture** : `capture_reference_view()` générique cadre l'AABB
   fusionnée — les parois rocheuses de la salle 2 la gonflent de ~1,7 m côté
   extérieur des murs ; le cadrage peut reculer légèrement.
7. **Corbeaux mezzanine (salle 2)** : à 0,25-0,5 m du bord du plateau de
   l'ascenseur (3,6 × 3,6 à x=1/z=1) — j'ai placé les 4 corbeaux HORS de la
   colonne de l'ascenseur, mais vérifier qu'aucun ne frôle le plateau en
   mouvement à l'image.
8. Les `.glb` promus ne sont pas encore importés : avant capture, lancer
   l'import ; tout modèle manquant laisse simplement la salle sans ce prop
   (repli `AssetRegistry.model()` → `null`).
9. `AssetRegistry.model()` indexe TOUT fichier .png ? Non — il ne liste que
   `.gltf`/`.glb`, donc `Textures/colormap_*.png` n'entre pas dans l'index
   des modèles ; en revanche Godot va importer ces .png comme textures au
   premier import : vérifier qu'aucune erreur d'import ne subsiste et que
   les matériaux des 10 modèles sont bien texturés (plus de blanc nu).

## Fichiers modifiés / créés

- `scripts/dungeon/dungeon_room.gd` — helper `dress_prop()` (visuel pur)
- `scripts/dungeon/room1_initiation.gd` — `_build_dressing()` + appel
- `scripts/dungeon/room2_vertical.gd` — idem
- `scripts/dungeon/room3_relays.gd` — idem
- `scripts/dungeon/room4_battery.gd` — idem
- `scripts/dungeon/central_hall.gd` — idem
- `scripts/dungeon/antechamber.gd` — idem
- `scripts/boss/boss_arena.gd` — `_build_dressing()` + `_lightning_scar()`
- `scripts/world/citadel_vestibule.gd` — 5 entrées d'habillage
- `assets/environment/dungeon/SM_Dungeon_*.glb` — 10 promotions (voir tableau)
- `scenes/dungeon/rooms/*.tscn`, `scenes/boss/BossArena.tscn` — INCHANGÉS
  (tout le décor est construit par code, comme le veut le dépôt)
