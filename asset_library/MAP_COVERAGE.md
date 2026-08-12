# Couverture asset par lieu — Vallée de Néris et Citadelle

Cette matrice couvre les lieux de `docs/POI_MAP.md`, les grandes zones sans POI,
la citadelle et le donjon. Elle ne demande pas de poser un asset partout : les
respirations sont intentionnelles. `Landed` signifie seulement « disponible dans
`asset_library/inbox/` », jamais « prêt à entrer dans le build ».

## Systèmes visuels transversaux

| Besoin | Source prioritaire | Complément | Règle d'emploi |
|---|---|---|---|
| vrai terrain 512 × 512 | Terrain3D à évaluer séparément | textures ambientCG déjà présentes | outil natif seulement après preuve Godot 4.7.1 ; sinon maillage de terrain original |
| chemins et routes | terrain sculpté + matériaux existants | pierres Quaternius existantes | aucune bande PlaneMesh posée sur le sol |
| falaises et gorges | Kenney Nature existant | Quaternius rocks existants | grandes formes originales d'abord, modules pour rupture méso |
| forêt et prairies | Stylized Nature MegaKit existant | Ultimate Nature existant ; KayKit Forest candidat | cellules de densité, silhouettes variées, vides volontaires |
| eau et rives | eau originale du projet | Watercraft landed ; saules Quaternius existants | bateaux et docks ne corrigent pas une rivière droite |
| villages et fermes | Quaternius Village existant | Fantasy Town landed ; Crops candidat | construire des fonctions et activités, pas une collection de prefabs |
| ruines | Castle landed | Ultimate Modular Ruins candidat | vrais vides, ruptures, affaissement et asymétrie |
| grottes | Modular Cave landed | KayKit Dungeon existant pour architecture humaine | lumière motivée, volumes jouables, pas de tunnel cloné |
| vie ambiante | animations Quaternius existantes | animaux et posed humans candidats | densité concentrée près des fonctions ; coût CPU mesuré |
| VFX | Particle + Smoke + Light Masks landed | VFX existants | accent final ; jamais cache-misère géométrique |
| son | RPG Audio + Interface Sounds landed | sons existants | audition humaine, variations, bus et niveaux avant promotion |

## Les 31 lieux

| Lieu | Kit principal | Pièces utiles | Composition attendue |
|---|---|---|---|
| Village de la rivière | Fantasy Town + Watercraft | maisons modulaires, quais, barque, caisses | quai en S, trois foyers d'activité, vues ouvertes sur l'eau |
| Hameau des bûcherons | Quaternius Village existant | auvents, bois, clôtures, outils KayKit candidats | scierie, stockage, repos ; clairière travaillée |
| Poste minier | Survival + Fantasy Town | outils, ressources, charpente, petite cabane | front de taille, tri du minerai, abri ; circulation lisible |
| Tour de guet | Castle | tour, escaliers, remparts cassés, drapeaux | silhouette verticale brisée, accès réellement grimpable |
| Aqueduc ancien | Castle + Ruins candidat | arches, piliers, morceaux effondrés | rythme d'arches incomplet traversant la rivière |
| Ferme abandonnée | Fantasy Town + Crops candidat | grange, clôtures, charrette, cultures mortes | cour en triangle, champs irréguliers, traces d'abandon |
| Caravane foudroyée | Survival | charrette existante, caisses, toile, fumée | ligne de voyage rompue, impact de foudre, abri improvisé |
| Observatoire en ruine | Castle + Ruins candidat | plate-forme, colonnes, arc, instruments originaux | cercle incomplet et vue cadrée vers la citadelle |
| Cimetière du tertre | Graveyard | tombes, clôtures, bancs, arbres morts | tertres courbes, familles de tombes, crypte en fond |
| Fortification ancienne | Castle | murs, tours, portes, engins élagués | front défensif asymétrique, brèches et profondeur |
| Sanctuaire forestier | nature existante + Ruins candidat | pierres, colonnes, fleurs, racines | petite architecture absorbée par deux arbres héros |
| Grotte de la cascade | Modular Cave | entrées, arches rocheuses, stalactites | eau comme ligne directrice, seuil visible mais mystérieux |
| Mine abandonnée | Modular Cave + Survival | tunnels, poutres, outils, ressources | cadence creusement/stockage/effondrement, embranchements lisibles |
| Crypte oubliée | Modular Cave + Graveyard | couloir rocheux, dalles, cercueils, grilles | transition terre→pierre humaine, chambre focalisée |
| Passage dérobé de l'Éperon | Modular Cave | fissures, rampes, blocs | passage discret depuis l'extérieur, pas une porte flottante |
| Cavité de cristal | Modular Cave + VFX Particle | roche, pointes originales, masques de lumière | grande cavité sombre, cristal rare comme foyer unique |
| Arbre doyen | nature existante | saule/tronc modifié, racines et pierres | un spécimen original dominant, couronne asymétrique |
| Source aux reflets | nature existante + Watercraft props | roches moussues, roseaux, petits pontons | bassin irrégulier, trois niveaux de rive, eau calme |
| Champ des mille fleurs | nature existante + Crops candidat | fleurs et herbes en nappes | grandes masses colorées, chemin négatif, pas de semis uniforme |
| Arche de pierre | Castle + rocks existants | arche, culées, blocs | vraie portée au-dessus de l'eau, berges intégrées |
| Belvédère du guetteur | Castle + rocks existants | garde-corps cassé, escalier, plateforme | silhouette en balcon et cadrage intentionnel de la vallée |
| Chute du Voile | Modular Cave + nature existante | voûtes rocheuses, fougères, troncs | cascade multi-plans, bassin et embruns sans mur d'eau plat |
| Cercle des Veilleurs | Ruins candidat + rocks existants | menhirs originaux, dalles, herbes | cercle incomplet orienté vers la citadelle |
| Gorge du Vent | rocks/cliffs existants | strates, éboulis, herbes courbées | canyon en S, alternance compression/respiration |
| Bois Courbé | nature existante + Smoke/Particle | arbres inclinés, branches mortes, poussière | direction du vent commune mais silhouettes non clonées |
| Arbre foudroyé | nature existante + Particle | tronc original, branches cassées, charbon | landmark noir lisible de loin, cyan réservé aux résidus actifs |
| Camps de pillards braise | Survival + props existants | auvents, feu, armes, stockage | repos/cuisine/garde et patrouille, vide central jouable |
| Zone de patrouille azur | Castle + props existants | postes minces, bannières, obstacles | route tenue par trois points de surveillance, pas une arène vide |
| Bastion des briseurs | Castle | remparts, porte, tours, débris | masses trapézoïdales lourdes, accès secondaire et brèches |
| Tanière du colosse | Modular Cave + rocks existants | arches rocheuses, blocs, os non spécifiques | échelle 4 m, traces de passage, espace de combat préservé |
| Territoire du chasseur | Survival + nature existante | miradors, cibles, pièges, outils | longues lignes de vue, postes de tir et échappatoires |

## Citadelle et donjon

| Zone | Source | Emploi autorisé |
|---|---|---|
| silhouette extérieure | création originale Blender/glTF | les kits ne doivent fournir que modules secondaires, débris et habillage |
| socle, contreforts, remparts | Castle landed + modules existants | variantes dimensionnées, vides réels, pas de mur cloné |
| vestibule | modules existants | préserver la recette actuellement réussie |
| six salles | KayKit Dungeon déjà déposé en premier | habiller architecture et props sans modifier puzzles ni collisions |
| crypte et sous-sols | Modular Cave + Dungeon | transition roche/architecture, séparation par lumière et matière |
| arène du boss | création originale + Dungeon | bord architectural et gradins ; centre jouable dégagé |

## Interfaces et sensation

`Interface Sounds` peut remplacer les clics provisoires de l'inventaire et du menu
pause après écoute. `Input Prompts` reste au catalogue seulement : le dépôt interdit
le contenu Nintendo et la future promotion doit conserver uniquement clavier/souris
et glyphes génériques. Les VFX landed ne justifient aucune nouvelle mécanique.
