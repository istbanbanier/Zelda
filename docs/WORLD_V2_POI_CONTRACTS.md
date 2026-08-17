# WORLD V2 — CONTRATS DES LIEUX MODULAIRES (V2.3) — VIVANT

Directive V2.3 (2026-08-14). Base gelée : `V2_2_FINAL_SHA=775aa32`.
Ce document est la source d'autorité de V2.3-0 : inventaire, familles,
kits, budgets et contrats de raccordement. Le layout
(`resources/world_v2/world_v2_layout.json`) reste seul maître de l'ID,
de la position et de l'orientation — ce document ne duplique aucune
coordonnée.

## 1. Principes non négociables

1. **Le terrain est gelé.** Un lieu s'adapte par fondations,
   soubassements, pilotis, marches, jupes, gravats et transitions.
   Jamais de remodelage de la heightmap, de l'eau, des routes, du
   navmesh ni des caméras gelées.
2. **Une `PackedScene` autonome par lieu**, chargeable seule,
   positionnée par les données du layout — zéro coordonnée de POI codée
   en dur dans un script de lieu.
3. **IDs et récompenses canoniques inchangés.** Les interfaces
   existantes de découverte/coffre/récompense/interaction sont
   consommées, jamais modifiées.
4. **Aucun acteur** (ennemi, PNJ, IA) en V2.3.
5. **Périmètre V2.3-A** : uniquement les neuf sujets du lot pilote.
   Les 22 autres POI restent des marqueurs après inventaire.

## 2. Inventaire canonique (31 POI + 3 sites + camp + pylône)

Source : `world_v2_layout.json` (`pois`, `systemic_sites`,
`cave_entrances`, `checkpoints`, `spec_anchors`). Les huit familles :

| Famille | POI | Grammaire visuelle |
|---|---|---|
| village (3) | riverside_village, logging_hamlet, mining_post | bâti habité : murs kit 2 m, toits, circulation, place |
| ruine (4) | watchtower_ruin, ancient_aqueduct, abandoned_farm, storm_caravan | pierre ocre géométrique, arches brisées, gravats fusionnés |
| vestige (4) | ruined_observatory, barrow_cemetery, old_rampart, forest_shrine | plus ancien que la ruine : masses tombées, racines, céramique ivoire |
| grotte (3) | waterfall_cave, abandoned_mine, hollow_crypt | poche intérieure BÂTIE contre le relief, seuil lisible, 2 issues sûres |
| souterrain (2) | hidden_passage, crystal_hollow | faille/fissure, passage court, lumière motivée |
| repère naturel (5) | ancient_tree, turquoise_spring, flower_field, stone_bridge, overlook_summit | nature composée : arbre doyen, source, arche de pierre |
| merveille (5) | veil_falls, watchers_circle, wind_gorge, storm_grove, thunderstruck_tree | unique, silhouette forte, raconte l'orage |
| territoire (5) | ember_raider_camps, azure_patrol_run, obsidian_bastion, colossus_lair, hunter_range | architecture tactique : couverts, accès, sorties, ancres de récompense — SANS acteurs |

Sites systémiques (comportement INTACT, habillage seulement) :
`conductive_basin` (arc_link), `magnetic_bridge` (polarite),
`earth_altar` (ground). S'y ajoutent le **camp/checkpoint**
(`checkpoints[camp]`, région r05) et le **pylône**
(`spec_anchors.pylon`, landmark de r07), hero asset architectural.

Chaque lieu sert au moins deux fonctions parmi : route, récit,
décision, préparation, découverte, récompense, panorama. La fonction
est déjà donnée par le layout (`category`, `reward`, `notes`) ; le
bâti doit la raconter sans texte.

## 3. Kits réutilisables (inventaire mesuré, rien à télécharger)

Tout est déjà importé, attribué (CC0, `ATTRIBUTIONS.md` ART-Q0/Q8/K1/Q9)
et mesuré dans `docs/assets/ASSET_MANIFEST.csv` :

| Kit | Contenu | Usage V2.3 |
|---|---|---|
| `assets/environment/dungeon/` (42 gltf Quaternius *Medieval Village MegaKit*) | murs 2×3,12 m brique/plâtre, portes, fenêtres, angles, sols, toits, escaliers, lierre, gravats | village, ferme, ruines |
| `assets/environment/village/` (53 gltf) | toitures complètes, surplombs, balcons, lucarnes | toits du lot pilote |
| `assets/environment/props/` (45 gltf) | caisses, tonneaux, bannières, établis, charrette, lanternes | vie des lieux |
| `SM_Dungeon_*.glb` (10 Kenney) | pilier tronqué, arche, gravats, parois de grotte, bannière | ruines, poche de grotte |
| `assets/environment/cliffs/` + `rocks/` | blocs de falaise, dalles `RockPath_*` (non employées) | fondations, sols de camp |
| V1 procédural | `AwningTent` (auvent asymétrique 3 appuis), `CampfireProp`, recettes `RiversideVillage`/`hamlets`/`_build_farm`/`_build_stone_bridge`/pylône proxy | camps, feux, transposition directe |
| Helpers obligatoires | `KitPlacement.seat()` (origines fautives), `KitScale`, `SettlementGround` (assise sur heightmap), `AssetRegistry.model()` | toute pièce posée |

Quarantaine `asset_library/inbox/` (`.gdignore`) : promotion uniquement
sur défaut visuel mesuré, avec attribution AVANT le build (règle
`ASSET_LIBRARY_EXPANSION_20260812.md`).

## 4. Budgets de complexité par lieu

Budgets de départ (plafonds, pas des objectifs) — mesurés au manifeste
de preuve, jamais « au feeling » :

| Type de lieu | Modules kit | Nœuds visuels | Collisions |
|---|---:|---:|---:|
| micro-POI naturel (arbre, source) | ≤ 12 | ≤ 30 | ≤ 6 |
| ruine/vestige | ≤ 40 | ≤ 80 | ≤ 20 |
| camp (checkpoint ou territoire) | ≤ 45 | ≤ 90 | ≤ 24 |
| village/hameau | ≤ 90 | ≤ 160 | ≤ 40 |
| grotte (seuil + poche) | ≤ 50 | ≤ 90 | ≤ 30 |
| hero asset (pylône) | ≤ 60 | ≤ 100 | ≤ 16 |

Règles de facture communes :

- matériaux : `StandardMaterial3D` dupliqués, `roughness ≥ 0.95`,
  `metallic_specular ≤ 0.1`, tons `_category_tone` (olive/ocre) —
  le même langage painterly que la végétation V2.2 ;
- pas de symétrie automatique, pas de répétition équidistante : chaque
  rangée de modules varie rotation/échelle/usure ;
- silhouette d'abord : chaque lieu doit se lire en aplat noir à sa
  distance de lecture (miniature de la planche de silhouettes) ;
- cyan réservé aux sites systémiques et au pylône, jamais décoratif ;
- accessoire toujours porté par une surface (jamais posé sur du vide) ;
- routes 2,3 m, gués 12 m (collision), checkpoints 4,5 m, caméras
  gelées 6 m + couloir de visée : mêmes exclusions que la végétation ;
- testabilité headless : tout bâtisseur écrit ses origines en
  métadonnées (`instance_origins` ou équivalent par scène).

## 5. Architecture des scènes et du placement

```
scenes/world_v2/poi/        # une PackedScene par lieu du lot pilote
scenes/world_v2/kits/       # sous-scènes réutilisables (module assis, feu…)
scenes/world_v2/landmarks/  # pylône (puis citadelle en V2.3-B)
resources/world_v2/poi/     # ressources de données par lieu si besoin
scripts/world_v2/poi/       # scripts des scènes ci-dessus
```

Placement : un bâtisseur unique (`WorldV2PoiBuilder`) lit le layout,
résout `poi_id → PackedScene` par un registre déclaratif, instancie la
scène à `v2_site` (ancré au sol par sondage heightmap), lui passe l'ID.
Un POI sans scène enregistrée garde son marqueur V2.2 — aucun faux
lieu. Le registre est la SEULE liste ; aucun script de lieu ne connaît
sa position.

## 6. Contrats de raccordement (interfaces existantes — mesurées)

**Les marqueurs V2.2 restent la couche d'identité, intacte.**
`test_world_v2_anchors.gd` épingle les comptes exacts des groupes
(`world_v2_poi_markers == 31`, `world_v2_site_markers == 3`,
`world_v2_cave_markers == 5` avec noms littéraux), les metas
`place_id`/`planned_site`, et l'ancre du camp doit continuer de voir un
sol du groupe `world_v2_terrain` sous elle. Les lieux V2.3 forment donc
une COUCHE SÉPARÉE : racines de scène dans le nouveau groupe
`world_v2_places`, avec `meta place_id`, sous le nœud `Places` de
`WorldV2.tscn` — aucun lieu ne rejoint les groupes de marqueurs.

Interfaces canoniques réemployées SANS modification :

| Besoin | Interface (mesurée) |
|---|---|
| Découverte | `PointOfInterest` (Area3D, `poi_id`/`display_name`/`region`, `bind(DiscoveryLog)`) |
| Ancre de récompense | `RewardAnchor.attach(host, place, kind, local_at, local_approach)` — nœud `AncrageRecompense`, kinds CHEST/WEAPON/INGREDIENT/RECIPE/STORY/PUZZLE/COMBAT |
| Distribution canonique | `DiscoveryRewards.PLAN` (31 entrées) + `furnish(world)` + convention `persistent_id(place, category)` (`valley.chest.…`, `valley.pickup.…`, `valley.ingredient.…`, `valley.story.…`) |
| Interactables | groupe `"interactable"` + `interact(player) -> bool` + `prompt_verb()` ; classes `Chest`, `WeaponPickup`, `IngredientPickup`, `StoryFragment`, `Campfire` |
| Site systémique bassin | classe `ConductiveBasin` (graphe `ElectricGraph` ENFANT du site — jamais plus haut dans l'arbre, sinon il capte tout le monde) |
| Assise des kits | `KitPlacement.seat()`, `KitScale`, `AssetRegistry.model()` |

Interdits mesurés (`test_world_v2_skeleton.gd`) : aucun fichier V2 ne
contient `scenes/world/valley`, `scripts/world/valley`, `ValleyWorld`
ni `valley_terrain` ; aucun fichier hors V2 ne contient `world_v2`.
Les classes ci-dessus passent ce filtre ; les bâtisseurs `valley_*`
sont interdits — leurs RECETTES sont transposées, jamais appelées.

Contraintes de placement mesurées :

- l'ancre littérale du camp `(45, 6, 65)` (et spawn/pylône/porte) garde
  un rayon vertical LIBRE jusqu'au terrain — aucun collider de lieu
  au-dessus de ces points ;
- les six fenêtres de caméras gelées (`world_v2_capture_cameras`)
  gardent leur segment de visée dégagé (mask 1) ;
- les routes/gués contractuels restent parcourables par le corps
  physique des tests de traversée ; navmesh cuit hors-ligne = GELÉ,
  aucun collider de lieu n'empiète sur les couloirs marchés ;
- le montage de `WorldV2.tscn` ne touche pas `slot0` (comparé à
  l'octet près) et se démonte proprement ;
- reconstruction déterministe : toute pose issue d'un lieu est
  seedée ; la végétation V2.2 étant gelée et déterministe, chaque lieu
  est composé POUR éviter les arbres existants (sondés une fois),
  jamais en modifiant le bâtisseur de végétation.

## 7. Filets techniques (écrits AVANT l'habillage)

Chaque contrôle doit pouvoir rougir ; les rouges nommés sont archivés
dans `evidence/world_v2/v2_3/controles/` avant construction :

1. ID absent ou dupliqué dans le registre des scènes de lieu.
2. POI du lot pilote resté simple marqueur.
3. Scène de lieu non autonome (échec d'instanciation isolée).
4. Placement codé en dur (position dans le script ≠ layout).
5. Récompense/découverte du lot mal raccordée (ID canonique absent).
6. Bâti flottant ou enterré (sondage des fondations vs heightmap).
7. Collision de lieu bloquant une route/un gué contractuels.
8. Grotte sans seconde issue sûre ou softlock.
9. Comportement du bassin conducteur modifié (suite systémique).
10. Checkpoint camp ou ancre pylône altérés.
11. Acteur ennemi/PNJ ajouté prématurément.
12. Régression V2.1/V2.2 (suites existantes rejouées).
