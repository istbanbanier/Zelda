# Carte des lieux de la Vallée de Néris

Trente et un lieux significatifs, chacun déclaré au journal des découvertes
sous un identifiant §19.3 (`zone.category.name.index`), chacun portant un
ancrage de récompense éprouvé physiquement.

Repères du terrain : plaine sud `y = 2` pour `z` de 16 à 256 ; plaine nord
`y = 2` pour `z` de −256 à −4 ; lit de rivière (`y = −1,5`) entre `z = 4` et
`z = 16` ; crête de départ `(0, 24, 170)` ; camp `(45, 6, 65)` ; pylône
`(115, 18, −25)` ; donjon `(0, 34, −210)`.

La colonne « récompense » donne la NATURE déclarée par l'ancrage. Le contenu
exact vit dans `DiscoveryRewards.PLAN`.

## Village et hameaux

| Identifiant | Nom affiché | Région | Site | Récompense |
|---|---|---|---|---|
| `valley.poi.riverside_village.01` | Village de la rivière | `riviere` | (−70, 2, 36) | arme au sol — épée usée |
| `valley.poi.logging_hamlet.01` | Hameau des bûcherons | `foret` | (110, 2, 40) | arme au sol — gourdin |
| `valley.poi.mining_post.01` | Poste minier | `falaise` | (−68, 2, 86) | coffre — flèches |

## Ruines

| Identifiant | Nom affiché | Région | Site | Récompense |
|---|---|---|---|---|
| `valley.poi.watchtower_ruin.01` | Tour de guet | `falaise` | (−128, 14, 82) | coffre — flèches |
| `valley.poi.ancient_aqueduct.01` | Aqueduc ancien | `riviere` | (−12, 2, 10) | fragment d'histoire |
| `valley.poi.abandoned_farm.01` | Ferme abandonnée | `plaine_sud` | (−16, 2, 78) | ingrédient — fruit de soin |
| `valley.poi.storm_caravan.01` | Caravane foudroyée | `route_du_donjon` | (−38, 2, −120) | coffre — lance |

## Vestiges

| Identifiant | Nom affiché | Région | Site | Récompense |
|---|---|---|---|---|
| `valley.poi.ruined_observatory.01` | Observatoire en ruine | `prairie_est` | (76, 2, 128) | fragment d'histoire |
| `valley.poi.barrow_cemetery.01` | Cimetière du tertre | `plaine_nord` | (58, 2, −78) | coffre — hache lourde |
| `valley.poi.old_rampart.01` | Fortification ancienne | `contreforts` | (−104, 2, −138) | coffre — flèches |
| `valley.poi.forest_shrine.01` | Sanctuaire forestier | `foret` | (18, 2, 102) | savoir — épice rare |

## Grottes

| Identifiant | Nom affiché | Région | Site | Récompense |
|---|---|---|---|---|
| `valley.poi.waterfall_cave.01` | Grotte de la cascade | `riviere` | (−118, 2, 26) | ingrédient — champignon |
| `valley.poi.abandoned_mine.01` | Mine abandonnée | `hauteurs` | (160, 2, −70) | arme au sol — hache lourde |
| `valley.poi.hollow_crypt.01` | Crypte oubliée | `ruines` | (−60, 2, −90) | coffre — lame conductrice |

## Souterrains

| Identifiant | Nom affiché | Région | Site | Récompense |
|---|---|---|---|---|
| `valley.poi.hidden_passage.01` | Passage dérobé de l'Éperon | `passage` | (−134, 2, 122) | coffre — flèches |
| `valley.poi.crystal_hollow.01` | Cavité de cristal | `cristal` | (−140, 2, −150) | récompense d'énigme *(verrou non implémenté)* |

## Repères naturels

| Identifiant | Nom affiché | Région | Site | Récompense |
|---|---|---|---|---|
| `valley.poi.ancient_tree.01` | L'Arbre doyen | `plaine_nord` | (−96, 2, −62) | ingrédient — épice rare |
| `valley.poi.turquoise_spring.01` | La Source aux reflets | `falaise` | (−72, 2, 78) | ingrédient — fruit de soin |
| `valley.poi.flower_field.01` | Le Champ des mille fleurs | `plaine_sud` | (−34, 2, 112) | ingrédient — herbe d'endurance |
| `valley.poi.stone_bridge.01` | L'Arche de pierre | `riviere` | (−14, 0, 10) | fragment d'histoire |
| `valley.poi.overlook_summit.01` | Le Belvédère du guetteur | `hauteurs` | (168, 0, 40) | arme au sol — arc simple **(à gravir)** |

## Merveilles

| Identifiant | Nom affiché | Région | Site | Récompense |
|---|---|---|---|---|
| `valley.poi.veil_falls.01` | La Chute du Voile | `cascade` | (150, 2, 118) | coffre — flèches |
| `valley.poi.watchers_circle.01` | Le Cercle des Veilleurs | `plaine_nord` | (−132, 2, −28) | fragment d'histoire |
| `valley.poi.wind_gorge.01` | La Gorge du Vent | `gorges` | (68, 2, −96) | ingrédient — herbe d'endurance |
| `valley.poi.storm_grove.01` | Le Bois Courbé | `orage` | (−8, 2, −152) | ingrédient — baie de résistance |
| `valley.poi.thunderstruck_tree.01` | L'Arbre foudroyé | `plaine_sud` | (−92, 2, 148) | savoir — épice rare |

## Territoires ennemis

Les cinq portent une récompense de nature `COMBAT`. Le coffre est réel et
persistant ; la condition « territoire nettoyé » n'est **pas** implémentée.

| Identifiant | Nom affiché | Région | Site | Récompense |
|---|---|---|---|---|
| `valley.poi.ember_raider_camps.01` | Camps de pillards braise | `camps_braise` | (72, 2, 112) | coffre — gourdin |
| `valley.poi.azure_patrol_run.01` | Zone de patrouille azur | `patrouille_azur` | (78, 2, −78) | coffre — flèches |
| `valley.poi.obsidian_bastion.01` | Bastion des briseurs | `bastion_obsidienne` | (−140, 2, −60) | coffre — hache lourde |
| `valley.poi.colossus_lair.01` | Tanière du colosse | `taniere_colosse` | (150, 2, −140) | coffre — lame conductrice |
| `valley.poi.hunter_range.01` | Territoire du chasseur | `territoire_chasseur` | (128, 2, 150) | coffre — arc simple |

## Comment cette table reste vraie

Elle est écrite à la main et peut donc mentir. Ce qui ne ment pas :

- `DiscoveryLog.registered_ids()` et `by_region()` donnent la liste réelle
  au lancement ;
- `test_every_place_carries_exactly_one_anchor` échoue si un lieu perd son
  ancrage ou si un ancrage nomme un lieu inexistant ;
- `tools/godot/probe_reward_anchors.gd` réimprime les coordonnées éprouvées.

En cas de désaccord entre ce document et le jeu, **le jeu a raison**.
