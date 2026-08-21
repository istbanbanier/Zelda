# V2.3-B lot 1 — contrat, écrit AVANT la construction

**VIVANT.** Autorité sur ce que le lot 1 doit livrer. Écrit par le lead avant
que quiconque ne pose une géométrie : un contrat rédigé après coup décrit ce
qu'on a fait, pas ce qu'on devait faire.

Base : le commit de clôture R2B.3.1. Six sujets, choisis et justifiés dans
`docs/V2_3_B_PLAN.md` §4.

## 1. Les six sujets, et l'intention de chacun

| id | famille | site v2 | intention en une phrase | récompense canonique |
|---|---|---|---|---|
| `valley.poi.watchtower_ruin.01` | ruine | (-160, 26, 40) | une verticale cassée qui donne le nord depuis la moitié ouest de la vallée | 15 flèches |
| `valley.poi.overlook_summit.01` | repère naturel | (168, 22, 52) | le point le plus haut de l'est ; monter jusque-là **donne l'arc** | arc simple |
| `valley.poi.turquoise_spring.01` | repère naturel | (-136, 12, 40) | une eau vive qui sort de la falaise, à 24 m du guet : ils se lisent ensemble | fruit de soin |
| `valley.poi.forest_shrine.01` | vestige | (86, 7, 74) | petit, sous couvert, invisible de la route — la curiosité seule y mène | épice rare |
| `valley.poi.barrow_cemetery.01` | vestige | (56, 4, -64) | des masses tombées dans la steppe, lecture funéraire sans un mot | hache lourde |
| `valley.poi.flower_field.01` | repère naturel | (-56, 5, 124) | la respiration à portée du spawn, premier lieu que le joueur atteindra | herbe d'endurance |

## 2. Ce qui rend un sujet du lot 1 ACCEPTABLE

Par POI, tous obligatoires :

1. **Scène raccordée**, pas un marqueur : entrée dans `REGISTRY` de
   `world_v2_places_builder.gd`, `PackedScene` autonome, `class_name` dérivant
   de `WorldV2Place`, `default_place_id()` constant.
2. **Position issue du layout SEUL.** Aucune coordonnée de site dans le script.
   Le filet §7.4 des contrats rougit sur un placement codé en dur.
3. **Fondations sur le terrain gelé** : chaque appui structurel déclaré par
   `declare_support()`, et sondé contre `height_at`. Rien ne flotte, rien n'est
   enterré.
4. **Zéro obstruction**, aux seuils RÉELLEMENT APPLIQUÉS AUX LIEUX — voir le
   piège de nommage ci-dessous : `ROUTE_CLEAR_M = 1,2 m` autour de chaque
   échantillon de route, `SITE_XZ_TOLERANCE_M = 0,5 m` d'écart maximal entre la
   racine et le site du layout, `ROOT_GROUND_TOLERANCE_M = 1,0 m`,
   `SUPPORT_TOLERANCE_M = 0,65 m` sur chaque appui déclaré. Les bandes creusées
   de l'eau sont interdites à tout site : **9,5 m** de demi-largeur sur le cours
   principal, **6,3 m** sur l'affluent, **2 m** de dégagement autour du lac
   (rayon 14).
5. **Navigation conservée** : le navmesh cuit est gelé ; aucun collider de lieu
   n'empiète sur les couloirs marchés. Les six caméras gelées exigent un trajet
   **libre jusqu'à 60 %** de la distance vers leur cible
   (`CLEAR_SIGHT_FRACTION = 0.6`, masque 1).

> **PIÈGE DE NOMMAGE, vérifié dans le code plutôt que dans la prose.** Deux
> constantes s'appellent `ROUTE_CLEAR_M` et ne valent pas la même chose :
> **1,2 m** dans `tests/world_v2/test_world_v2_places_contract.gd`, qui est le
> seuil qui rougit pour un LIEU ; **2,3 m** dans
> `scripts/world_v2/world_v2_vegetation_builder.gd`, qui est l'exclusion
> VÉGÉTALE et appartient au domaine gelé V2.2. Le §4 de
> `WORLD_V2_POI_CONTRACTS.md` annonce en prose « routes 2,3 m, gués 12 m,
> checkpoints 4,5 m, caméras 6 m » : ce sont les valeurs de la végétation. Les
> reprendre pour un lieu serait se donner une marge quatre fois trop large sur
> les gués et deux fois trop large sur les routes — et découvrir l'écart au
> moment du filet.
>
> Autre écart entre document et code : le tableau `sightlines` du layout n'est
> lu par **aucun** code (`grep -rn sightlines scripts/ tests/ tools/` ne rend
> rien). Ce qui est réellement vérifié, ce sont les six caméras gelées.
6. **Interaction canonique** raccordée par `DiscoveryRewards.PLAN` et
   `PointOfInterest.bind(DiscoveryLog)` — la table existe déjà, on ne l'invente
   pas.
7. **Budget respecté** (`docs/WORLD_V2_POI_CONTRACTS.md` §4) : micro-POI naturel
   ≤ 12 modules / 30 nœuds / 6 collisions ; ruine et vestige ≤ 40 / 80 / 20.
8. **Licence et provenance** au manifeste AVANT le build, pour tout asset entrant.
9. **Deux vues propres au minimum, dont une vue joueur**, plus une inspection
   individuelle à taille réelle par le lead.
10. **Manifeste** portant le sha256 du code de capture et `repo_dirty: false`.

## 3. Ce qui rend le LOT acceptable

- un **contrôle négatif nommé par famille de défaut**, rouge d'abord, archivé ;
- suite `world_v2` verte ;
- `PROJECT_RESOURCE_LEAK_GATE` vert ;
- `ENGINE_SCRIPT_CACHE_TELEMETRY` publiée **séparément** — elle dérivera, c'est
  attendu (six scènes de plus épinglent six `GDScript` de plus) et se clôt par
  `tools/gate_fuite_composition.sh --entériner` avec justification ;
- arbre propre avant les captures finales ;
- A/B honnêtes là où le lieu remplace un marqueur ;
- carte du lot et planche de miniatures ;
- checkpoint jouable construit depuis un commit propre.

## 4. Les défauts que ce lot doit se voir interdire

Écrits avant, pour que le contrôle négatif ait quelque chose à viser. Chacun a
déjà coûté une passe sur le lot pilote :

| # | famille de défaut | ce qui le révèle |
|---|---|---|
| D1 | **assemblage de primitives** — un tas de boîtes lisible comme tel à toute distance | liant de boîtitude / rectangularité, plafonds R2B.3 |
| D2 | **bâti flottant ou enterré** | sondage des appuis déclarés contre `height_at` |
| D3 | **répétition** — deux sujets du lot qui se ressemblent, ou qui copient un pilote | comparaison de silhouettes en aplat noir, à trois distances |
| D4 | **obstruction** — collider en travers d'une route, d'un gué, d'un couloir caméra | rejeu des tests de traversée et des six caméras |
| D5 | **placement codé en dur** | recherche de littéraux de position dans les scripts de lieu |
| D6 | **récompense non raccordée** | absence de l'ID canonique dans le journal de découverte |
| D7 | **budget dépassé en silence** | comptage des modules/nœuds/collisions par lieu |
| D8 | **régression sur le gel** | `tools/gel_verifier.sh` |

## 5. Ce que le lead ne délègue pas

Il lit les contrats lui-même, arbitre les trois plans avant toute construction,
**reproduit personnellement** chaque mesure rendue par un agent, tient les
verrous, intègre par cherry-pick sans merge commit, et inspecte chaque capture à
taille réelle. Il prononce le verdict **technique** ; le verdict artistique
appartient au propriétaire.
