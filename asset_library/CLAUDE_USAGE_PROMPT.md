# Annexe prête à donner à Claude — exploitation de la bibliothèque mondiale

Copier ce bloc **à la suite** du prochain prompt de production de la carte.

---

Tu travailles sur **Zelda / Éclats d'Orage**. Une bibliothèque d'assets externe,
préparée et auditée par Codex, existe sur la branche :

`codex/world-asset-library-20260812`

## Obligation de reprise

Avant toute production de la carte :

1. vérifie que cette branche distante existe et relève son SHA exact ;
2. intègre-la à ta branche de travail sans réécrire ses commits ;
3. lis entièrement :
   - `asset_library/README.md` ;
   - `asset_library/SELECTION_REPORT.md` ;
   - `asset_library/ASSET_CATALOG.csv` ;
   - `asset_library/MAP_COVERAGE.md` ;
   - `asset_library/INVENTORY.csv` ;
   - `asset_library/SOURCE_ARCHIVE_SHA256.csv` ;
4. confirme dans ta restitution le nombre réel de packs et fichiers indiqué par
   l'inventaire, sans recopier un nombre estimé du rapport ;
5. traite `asset_library/inbox/` comme une quarantaine hors build, jamais comme un
   dossier à copier en bloc dans `assets/`.

## Hiérarchie obligatoire des sources

Pour chaque lieu, utilise dans cet ordre :

1. les assets déjà importés et inutilisés du dépôt ;
2. les packs déjà déposés, notamment KayKit Dungeon ;
3. la bibliothèque landed de Codex ;
4. les candidats `CATALOG` seulement si un manque précis reste démontré ;
5. une création originale Blender/glTF pour les silhouettes héroïques et formes
   propres à Éclats d'Orage.

Ne télécharge jamais un nouveau pack parce qu'il « pourrait servir ». N'importe un
asset que si tu peux nommer le lieu, le rôle visuel, la caméra et le défaut qu'il
résout.

## Contrat de promotion d'un asset

Pour chaque sélection depuis `asset_library/inbox/` :

1. choisis le minimum de modèles nécessaire à un seul lot cohérent ;
2. vérifie la licence et la provenance livrées avec le pack ;
3. inscris la promotion dans `ATTRIBUTIONS.md` puis
   `docs/assets/ASSET_MANIFEST.csv` **avant** la copie vers `assets/` ;
4. renomme selon les préfixes `SM_`, `SK_`, `T_`, `MAT_`, `AN_` ;
5. vérifie échelle 1 unité = 1 m, Y vertical, pivot, min Y, matériaux et textures ;
6. passe chaque GLB par `tools/gltf_inspect.py`, puis import Godot headless ;
7. crée collision et LOD adaptés à l'usage — ne récupère pas aveuglément une
   collision de pack ;
8. harmonise palette et roughness sans détruire le fichier source ;
9. prouve visuellement l'intégration depuis la caméra de jeu ;
10. ne supprime l'asset de quarantaine ni sa provenance.

## Affectations prioritaires

- `kenney_castle_2_0` : vieille fortification, tour, bastion et modules secondaires
  de la citadelle ; jamais silhouette entière de la citadelle.
- `kenney_modular_cave_1_0` : cinq POI souterrains, avec variation de volume et
  transition roche/architecture.
- `kenney_fantasy_town_2_0` : village, hameau, ferme et poste minier, par fonctions
  et groupes plutôt que maisons intactes posées en grille.
- `kenney_graveyard_5_0` : cimetière du tertre et crypte ; écarte les modèles trop
  comiques ou toute nouvelle famille d'ennemis.
- `kenney_survival_2_0` : camps, caravane et territoire du chasseur.
- `kenney_watercraft_2_1` : barques, radeaux et quais seulement ; écarte tout navire
  moderne ou disproportionné.
- audio/VFX : remplacement de placeholders après audition ou revue d'image ; jamais
  pour annoncer une nouvelle mécanique ni masquer une géométrie faible.

La matrice exhaustive lieu → kit → composition vit dans
`asset_library/MAP_COVERAGE.md` et prime sur une recherche improvisée.

## Interdictions

- aucun asset Nintendo, symbole ou rip ;
- aucun pack payant copié dans le dépôt public ;
- aucun asset `CATALOG` présenté comme téléchargé ;
- aucun import massif de toute la quarantaine ;
- aucune ville, grotte, ruine ou camp lu comme une démo de pack ;
- aucun modèle Poly Haven haute densité utilisé sans LOD/bake et preuve de style ;
- aucun plugin Terrain3D/route installé dans le projet principal sans audit de code,
  branche d'essai isolée et preuve de compatibilité Godot 4.7.1 ;
- aucun VFX, brouillard, bloom ou lumière servant à cacher une macro-forme faible.

## Travail attendu pour toute la carte

Procède par familles cohérentes et non par 31 micro-commits :

1. terrain/rivière/chemins ;
2. villages/ferme/mine ;
3. ruines/cimetière/sanctuaire ;
4. grottes/souterrains ;
5. territoires ennemis/camps ;
6. merveilles naturelles et végétation ;
7. citadelle extérieure ;
8. donjon et arène ;
9. vie, audio et VFX ;
10. inventaire/menu pause seulement si le prompt principal l'autorise.

Dans chaque famille : établis 2 à 4 caméras représentatives, transforme toute la
famille, lance les tests sélectifs pendant l'itération, puis un seul gate complet à
la fin. Rejoue le parcours physique après terrain/collision/navigation. Ne déclare
jamais le gate visuel réussi toi-même : livre les captures finales à Codex.

## Restitution obligatoire

À la fin de chaque famille, donne : assets promus avec leurs IDs de pack, lieux
couverts, fichiers de manifeste/attribution modifiés, captures, tests, poids ajouté,
blocages et candidats encore en quarantaine. Un pack présent ne vaut pas une preuve
d'intégration.

---
