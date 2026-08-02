# Audit du Gate D — réouverture (ordre corrigé du 2026-08-02)

Base : MASTER_SPEC §22 Phase D (items 16-20), §12 (bestiaire), §23
(gates d'acceptation). Preuves rejouées au commit `056788c`
(validate_fast VERT, 329 tests) — aucun ancien verdict repris sans
rejeu. Le verdict d'un item est le PLUS FAIBLE de ses critères.

## Matrice de preuve

| Item | Critère | Preuve rejouée | Verdict |
|---|---|---|---|
| 16 | Terrain 512 m, composition North Star en formes simples | `--filter=world_dressing` 4/4 (couloir de vista balayé en entier depuis le lot 16) ; `evidence/v4lot16/vista_post_review.png` capturée à l'arbre PROPRE (repo_dirty:false, 95b757d) : trois plans, citadelle + éclair, pylône, camp | **PASS** |
| 17 | Camp, falaise, rivière, pylône, citadelle, chemins | mêmes suites + `--filter=camp_props` 3/3 (camp habité 30 éléments), `--filter=valley` (rampes, gués, corniches testés en D.1) ; les huit zones portent des compositions testées par comptage | **PASS** |
| 18 | Huit coffres, ingrédients, checkpoint | 4 coffres dans la vallée (`valley.chest.camp/river_ledge/cliff_top/pylon`) — CONFORME à la répartition §11.4 (« trois dans la vallée, un au camp ») ; les 4 autres appartiennent aux salles du donjon (Phase F). 12 ingrédients posés (9 E.1 + 3 lot 12), 7 familles testées (`--filter=ingredients` 4/4). Checkpoint `valley.camp.start` sauvegardé/testé | **PARTIEL** — 4/8 coffres placés ; solde structurellement lié à la Phase F, consigné |
| 19 | Quatre autres ennemis (après le premier pillard) | `resources/enemies/` : UN SEUL tuning (`raider_red_default.tres`). `scenes/enemies/` : UNE seule scène. Le lot V4-13 n'a produit que des VARIANTES VISUELLES (greffes de pièces sur wrappers) — aucune famille nouvelle : ni stats, ni arme, ni états, ni perception propres | **FAIL** — 0/4 familles |
| 20 | Partie extérieure complète graybox (terminable) | Boucle spawn→camp→citadelle jouable (`--filter=valley_world`), MAIS la densité de rencontre de §4.3 et les rencontres des routes 2/3 dépendent de l'item 19 | **PARTIEL** — bloqué par 19 |

## Verdict global : **FAIL** (item 19)

Le Gate D est ROUVERT. La passe artistique V4 (lots 1-17) reste
conservée mais ne ferme pas ce gate : « un humain recoloré ou équipé
différemment ne constitue pas automatiquement une nouvelle famille »
(ordre corrigé, aligné sur §12 : « les trois pillards ne doivent pas
être de simples recolorations » — silhouette ET proportions ET arme ET
animations ET rythme ET décisions).

## Plan de fermeture (jalons bornés, ordre corrigé)

1. **D-EN.0** — socle commun extrait de `raider_red` (perception LOS,
   chemin navmesh, séparation, feedback) + MÉMOIRE de dernière position
   3-8 s (§12.7, absente aujourd'hui) + TERRITOIRE et retour (§12.9,
   absents) ; `raider_red` re-testé à l'identique.
2. **D-EN.1** — pillard azur : 85 PV, LANCE (portée propre),
   contournement, alerte des alliés (rayon limité), maintien de
   distance, esquive d'une lourde télégraphiée (cooldown 6-10 s).
3. **D-EN.2** — briseur d'obsidienne : 150 PV, masse lourde, combo 2-3
   coups, GARDE frontale à jauge, résistance au stagger élevée,
   ouverture après combo.
4. **D-EN.3** — coordinateur de combat (§12.8) : 2 tokens mêlée max,
   1 token lourd, libération garantie, plafond 10-14 IA actives.
5. **D-EN.4** — colosse des ravins : ~420 PV, 3,5-4,5 m, balayage /
   frappe verticale / coup au sol à ONDE DE CHOC évitable, lancer de
   rocher, point faible dos, renversement, navigation à sa taille.
6. **D-EN.5** — chasseur quadrupède : ~650 PV, centauroïde original,
   territoire signalé + frontière d'abandon, charge en ligne, salve
   d'arc, combo rapproché, cri d'annonce, repositionnement circulaire,
   récompense optionnelle.
7. **D-EN.6** — placements dans la vallée (camp mixte rouge/azur,
   obsidienne gardien de récompense, colosse au ravin, chasseur en
   territoire facultatif), aplats NOIRS des cinq familles à la même
   échelle, batterie de tests transverses (occlusion, mémoire, retour,
   coordination, séparations, poursuite bornée, cadavres inertes, loot
   unique, plafond d'IA), revue contradictoire du Gate D.

Chaque jalon : tests verts, validate_fast VERT, commit isolé, push.
