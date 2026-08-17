# V2.3-A — Manifeste des scènes, modules, matériaux et ressources

Document de preuve (§7 de la directive V2.3). Les métriques chiffrées
vivent dans `metriques_lieux.log` (sonde `probe_place_metrics.gd`) — ce
manifeste recense la PROVENANCE. Aucune mesure de performance : llvmpipe
ne mesure rien.

## Scènes livrées (couche `Places`, registre `WorldV2PlacesBuilder`)

| place_id | Scène | Script |
|---|---|---|
| `camp` | `scenes/world_v2/poi/CampCheckpointPlace.tscn` | `camp_checkpoint_place.gd` |
| `valley.poi.riverside_village.01` | `poi/RiversideVillagePlace.tscn` | `riverside_village_place.gd` |
| `valley.poi.abandoned_farm.01` | `poi/AbandonedFarmPlace.tscn` | `abandoned_farm_place.gd` |
| `valley.poi.stone_bridge.01` | `poi/StoneBridgePlace.tscn` | `stone_bridge_place.gd` |
| `valley.poi.waterfall_cave.01` | `poi/WaterfallCavePlace.tscn` | `waterfall_cave_place.gd` |
| `valley.poi.thunderstruck_tree.01` | `poi/ThunderstruckTreePlace.tscn` | `thunderstruck_tree_place.gd` |
| `valley.poi.ember_raider_camps.01` | `poi/EmberRaiderCampPlace.tscn` | `ember_raider_camp_place.gd` |
| `valley.poi.conductive_basin.01` | `poi/ConductiveBasinPlace.tscn` | `conductive_basin_place.gd` |
| `pylon` | `scenes/world_v2/landmarks/ResonancePylon.tscn` | `resonance_pylon_landmark.gd` |

Socle partagé : `world_v2_place.gd` (base, terrain lié, supports
déclarés), `world_v2_place_kit.gd` (résolution kit, échelle/assise
corrigées, teintes painterly), `world_v2_places_builder.gd` (placement
par le layout SEUL).

## Modules de kit employés (tous DÉJÀ importés et attribués — rien de
## téléchargé, aucune nouvelle dépendance)

| Source (licence) | Modules employés |
|---|---|
| Quaternius *Medieval Village MegaKit* CC0, ART-Q0 (`assets/environment/dungeon/`, `village/`) | `Wall_Plaster_*`, `Wall_UnevenBrick_*`, `Corner_Exterior_*`, `Floor_{Brick,WoodLight,WoodDark}`, `Roof_RoundTiles_6x6`, `Roof_Front_Brick6`, `Roof_Wooden_2x1_L`, `Stairs_Exterior_Platform`, `Door_1_Round`, `Prop_Vine1/2`, `Prop_WoodenFence_*`, `Prop_MetalFence_Simple`, `Prop_Wagon` |
| Quaternius props CC0, ART-Q0 (`assets/environment/props/`) | `Banner_1/2`, `Crate_Wooden`, `Barrel`, `Barrel_Apples`, `FarmCrate_{Empty,Apple}`, `Stall_Cart_Empty`, `Table_Large`, `Bench`, `Stool`, `Bed_Twin1`, `Cauldron`, `Bucket_Wooden_1`, `Pot_1`, `Bag`, `Pouch_Large`, `Rope_1`, `WeaponStand` |
| Kenney kits CC0 (ART-K1 falaises ; kit donjon promu 2026-08-12) | `cliff_blockSlope_rock`, `rock_largeA/C`, `rock_smallB`, `SM_Dungeon_{ArchBlock,PillarStub,RubbleLarge,RubbleSmall,CaveWall,CaveWallTop,CaveArch,CaveRock}` |
| Quaternius nature CC0 (`foliage/`, `rocks/`) | `CommonTree_4`, `DeadTree_1/2`, `Bush_Common{,_Flowers}`, `Fern_1`, `Plant_1`, `Flower_3/4_Group`, `Grass_Common_Tall`, `Mushroom_Common`, `Rock_Medium_1/2`, `RockPath_*` |
| Procédural V1 réemployé (aucun asset) | `AwningTent` (auvent 3 appuis §10.2), `CampfireProp`, `Campfire` (interactable canonique), `ConductiveBasin` (comportement systémique INTACT) |
| Procédural V2.3 (aucun asset) | pylône (tambours/contreforts/anneau/couronne), jupes de fondation, pilotis du quai, dalles de grotte, fente de l'arbre |

## Matériaux

- Pièces de kit : matériau ACTIF dupliqué par (matériau, teinte), cache
  statique, `roughness ≥ 0,95`, `metallic_specular = 0,1` — le langage
  painterly de la végétation V2.2 (`world_v2_place_kit.gd::apply_tone`).
- Géométrie procédurale : `flat_material()` même règle.
- Émission cyan : UNE bande runique sur le pylône (énergie 1,15) et les
  nœuds actifs du diorama `ConductiveBasin` — nulle part ailleurs.

## Interfaces canoniques consommées sans modification

`RewardAnchor.attach` (7 ancres), `DiscoveryRewards.furnish` (table
PLAN + `persistent_id`), `PointOfInterest` + `DiscoveryLog.bind` (7
lieux), `Campfire` (camp), `ConductiveBasin` + `ElectricGraph` enfant
(bassin). Aucun acteur, aucune IA, aucun PNJ.
