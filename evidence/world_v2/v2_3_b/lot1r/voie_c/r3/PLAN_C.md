# PLAN_C — Champ des mille fleurs (lot 1.R, V2.3-B)

**Fichiers possédés** : `scripts/world_v2/poi/flower_field_place.gd` (principal),
`shaders/world_v2/poi/SH_FlowerFieldSway.gdshader`,
`source_assets/blender/environment/make_flower_field_steles.py` + son `.glb`.

**Hypothèse visuelle** (lue sur `apres4/flower_field_joueur.png`, taille réelle) :
le champ ne peut pas « exploser » parce que le PROCHE est vide. Les 40 % bas du
cadre joueur sont de l'herbe nue — la clairière d'œil fait 2,1 m de rayon et
aucune nappe ne descend sous 6 m de la caméra. Les nappes existantes sont par
ailleurs des taches de ±1,3 m : elles rendent un semis, pas des PHRASES.

**Modification principale**, dans l'ordre :
1. nappe d'avant-plan dense et mixte au pied du joueur, clairière d'œil réduite ;
2. nappes réécrites en LOBES (2-3 ellipses par couleur, phrases larges) avec
   respirations explicites entre elles ;
3. strate HAUTE (échelle ×1,2-1,5) semée dans les nappes pour le profil ;
4. couloir de traversée élargi et lisible entre deux ourlets.

**Résultat attendu dans l'image** : bas du cadre joueur couvert de jaune+blanc à
hauteur de genou ; trois masses de couleur séparées par du vert ; une voie claire
qui monte du coin bas droit vers la Porte ; village toujours petit et lointain.

**Première capture de diagnostic** : batch 4 vues (`identite`, `joueur`,
`gp_nappe`, `gp_chemin`) après `--import`, dans `voie_c/r/iter1/`.

**Contrôle ciblé** : parse `--check-only`, compte d'instances MultiMesh publié
(budget micro D7 = 12 modules / 30 nœuds visuels / 6 collisions), puis test
filtré `lot1_defauts` sur D7 quand la forme est gelée.

**Premier checkpoint** : commit dès la nappe d'avant-plan capturée et inspectée.
