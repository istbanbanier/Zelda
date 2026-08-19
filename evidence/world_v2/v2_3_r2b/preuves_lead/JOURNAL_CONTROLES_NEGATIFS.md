# Journal des contrôles négatifs — V2.3-A.R2B

Règle appliquée : chaque contrôle a été écrit et exécuté ROUGE d'abord, sur
l'état d'avant travaux (base 5f821e5), avant toute construction. Les journaux
bruts, avec jeton `RC=`, sont committés dans les dossiers des voies. Après
travaux, chaque contrôle est VERT sans qu'aucun seuil ait été assoupli.

## Voie A — camps (`tests/world_v2/test_world_v2_r2b_camps.gd`, 5 contrôles)

Rouge archivé : `../camps/rouge_avant/test_runner_rouge.log` — `0 réussi(s), 5 échoué(s)`, RC=1.

| Contrôle | Ce que le rouge a prouvé |
|---|---|
| peau du camp-checkpoint en modules | 38 maillages procéduraux hors exemption (PoteauHalle_*, ToileHalle_*) |
| aucune toile commune entre les deux camps | 2 AwningTent partagés + aucun appentis propre au braise |
| camp braise éteint, sans bleu ni flamme | 1 CampfireProp actif, 3 surfaces émissives (Flame*), 3 bannières au bleu du kit |
| guet braise = signal vertical | aucun plancher Floor_WoodDark, 0 poteau sur 4 exigés |
| halle couvre une masse réelle | aucun module Roof_* — la halle n'existait pas en modules |

Vert final : `../camps/verts/controles_r2b_camps_vert.log` (RC=0),
`../camps/verts/world_v2_61sur61.log`.

## Voie B — ferme + arbre (`tests/world_v2/test_world_v2_r2b_farm_tree.gd`, 4 contrôles)

Rouge archivé : `../ferme_arbre/rouge_avant/journal_rouge_5f821e5.log` — `0 réussi(s), 4 échoué(s)`, RC=1.

| Contrôle | Ce que le rouge a prouvé |
|---|---|
| zéro bloc procédural hors exemption SolBrule | 84 écarts (socle_*_* runtime sur la ferme) |
| charpente portée par les murs | aucun pan intact, aucun pan tombé, aucun gravat, aucune charpente |
| arbre = asset GLB valide et monté | GLB absent, aucun nœud SM_ThunderstruckTree monté |
| pipeline Blender frais et vérifié | 10 écarts (sujets absents d'export_architecture.sh, générateurs absents, pas de jeton FIN NOMINALE, pas d'inspection glTF VALIDE) |

Contrôle négatif supplémentaire du générateur (garde-fou actif, pas un test) :
`../ferme_arbre/pipeline/controle_negatif_hauteur_REFUS.log` —
`[thunderstruck_tree] ERREUR: hauteur 15.02 hors de [10 ; 12] — REFUS d'enregistrer`, RC=2.
Le piège documenté « Blender rend 0 même quand le script lève » est couvert par
le jeton FIN NOMINALE exigé au journal de génération.

Vert final : `../ferme_arbre/vert_apres/journal_vert_apres_retouches_12sur12.log`,
`journal_vert_world_v2_60sur60_HEAD_final.log` (RC=0).

## Voie C — bassin (`tests/world_v2/test_world_v2_r2b_basin.gd`, 3 contrôles)

Rouge archivé : `../bassin/rouge_avant/r2b_basin_rouge.log` — `0 réussi(s), 3 échoué(s)`, RC=1.

| Contrôle | Ce que le rouge a prouvé |
|---|---|
| habillage du bassin vient du kit avec UV | 72 primitives procédurales hors kit (Margelle_*) |
| comportement et contrat préservés | 2 blocs de l'ancienne margelle DANS l'eau garantie |
| lampes gardent leur noyau, habillage n'émet pas | socles/fûts encore en BoxMesh (option B non appliquée) |

Vert final : `../bassin/verts/r2b_basin_3sur3.log` (RC=0),
`../bassin/verts/world_v2_59sur59.log`, `../bassin/verts/places_8sur8.log`.

## Après intégration (lead)

Les trois familles rejouées ensemble sur la branche intégrée : voir
`../integration/suite_w2_integree.log` (attendu 68 = 56 + 5 + 4 + 3).
Golden masters byte-identiques avant/après : `GM_BASELINE_SHA256.txt`, 6/6 OK.
