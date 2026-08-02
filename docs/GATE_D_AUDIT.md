# Audit du Gate D — réouverture (ordre corrigé du 2026-08-02)

Base : MASTER_SPEC §22 Phase D (items 16-20), §12 (bestiaire), §23
(gates d'acceptation). Preuves REJOUÉES, jamais reprises d'un résumé.

## Historique

| Passe | Date | Verdict | Motif |
|---|---|---|---|
| 1 | 2026-08-02 (commit `056788c`) | **FAIL** | item 19 : une seule famille ennemie sur cinq |
| 2 | 2026-08-02 (après D-EN.0..6) | voir ci-dessous | les cinq familles livrées et testées |

## Matrice de preuve — passe 2

| Item | Critère | Preuve rejouée | Verdict |
|---|---|---|---|
| 16 | Terrain 512 m, composition North Star en formes simples | `--filter=world_dressing` 4/4 ; `evidence/v4lot16/vista_post_review.png` capturée à l'arbre PROPRE (`repo_dirty:false`) : trois plans, citadelle + éclair, pylône, camp | **PASS** |
| 17 | Camp, falaise, rivière, pylône, citadelle, chemins | `--filter=world_dressing`, `--filter=camp_props` 3/3, `--filter=valley` ; huit zones habillées, comptages testés | **PASS** |
| 18 | Huit coffres, sept ingrédients, checkpoint | 4 coffres dans la vallée (conforme à la répartition §11.4 : « trois dans la vallée, un au camp ») ; les 4 autres appartiennent aux salles du donjon (Phase F). 12 ingrédients, 7 familles testées (`--filter=ingredients` 4/4). Checkpoint `valley.camp.start` sauvegardé/testé | **PARTIEL** — 4/8 placés ; solde structurellement lié à la Phase F, consigné |
| 19 | Cinq familles ennemies réellement distinctes | `--filter=bestiary` 5/5 (**107 assertions**), + 5 suites par famille : braise 22/22, azur 5/5, obsidienne 5/5, colosse 5/5, chasseur 5/5, socle 5/5, coordinateur 3/3. Silhouettes : `evidence/gateD/bestiary_flat.png` (aplats noirs, même échelle) | **PASS** |
| 20 | Extérieur complet, terminable, sans zone vide injustifiée | La vallée porte les cinq familles à leur poste (test dédié) ; boucle spawn→camp→citadelle jouable (`--filter=valley_world`) | **PASS automatique** — l'essai humain manque |

## Ce que l'item 19 prouve, famille par famille (§12.1-§12.5)

| Famille | PV | Arme / portée | Comportement propre PROUVÉ |
|---|---:|---|---|
| Pillard braise | 45 | gourdin 1,6 m | télégraphe long, recul sur esquive réussie, **fuite** à la mort d'un allié |
| Pillard azur | 85 | **lance** 2,4 m | contournement latéral mesuré, distance rouverte pendant le cooldown, **esquive** d'une lourde télégraphiée (cooldown 8 s), alerte 14 m |
| Briseur d'obsidienne | 150 | masse, chaîne de 3 | **combo** par la vraie fenêtre, **garde frontale à jauge** (amorti ×0,25, rupture = stagger), poise 60 (deux coups d'épée ne le couchent pas) |
| Colosse des ravins | 420 | bras 3,2 m | **onde de choc** évitable par saut (les deux cas mesurés), **lancer de rocher** balistique annoncé, **point faible dorsal ×2**, carrure qui refuse une porte de 1,6 m |
| Chasseur quadrupède | 650 | lames 2,6 m | **cri** d'annonce immobile, **charge en ligne figée** (donc esquivable), **salve de 3 flèches** puis repos, orbite, **abandon à la frontière** |

Aucune famille ne partage ses PV, sa portée, sa carrure ni un seul
identifiant de contrat d'attaque (vérifié par assertion croisée).

## Exigences transverses de l'ordre corrigé

| Exigence | Preuve | Verdict |
|---|---|---|
| Différences de PV et statistiques | assertions croisées sur les 5 (PV, portée, carrure, hauteur) | **PASS** |
| Armes et portées propres | 11 contrats d'attaque, tous d'identifiant unique | **PASS** |
| Télégraphes et attaques propres | startup par contrat, annonces testées (azur, colosse, chasseur) | **PASS** |
| Perception avec occlusion | `test_no_family_sees_through_a_wall` : les 5 restent IDLE derrière un mur | **PASS** |
| Mémoire de dernière position | `test_a_lost_target_becomes_a_memory_then_a_search_then_home` | **PASS** |
| Retour au territoire | même test + `test_pursuit_is_bounded_by_the_territory` (sans oscillation) | **PASS** |
| Coordination des attaques | `test_never_more_than_two_simultaneous_melee_attackers`, token du mort repris | **PASS** |
| Séparation joueur/ennemi | collisions de corps, testées depuis D.1 (`test_body_separation`) | **PASS** |
| Séparation ennemi/ennemi | poussée locale du socle, testée (`test_body_separation`) | **PASS** |
| Navmesh adapté à chaque taille | **deux maillages** cuits (agent 0,7 m : 1098 polygones ; agent 1,2 m : 1044) sur **cartes séparées** ; colosse et chasseur sur la grande | **PASS** |
| Aucune poursuite infinie | frontière de territoire mesurée sur braise ET chasseur | **PASS** |
| Aucun corps bloquant une porte | collision retirée à la mort, vérifié sur les 5 | **PASS** |
| Loot unique et persistant | `--filter=camp_props` (pose ouverte sans re-loot), `--filter=ingredients` | **PASS** |
| Absence de hitbox après la mort | `test_no_family_keeps_an_active_hitbox_after_death` : hurtbox ÉTEINTES (toutes, y compris le dos du colosse), fenêtres de frappe fermées, IA coupée | **PASS** |
| Maximum 10-14 IA actives | `test_the_activity_cap_puts_the_farthest_to_sleep` : 16 vivantes → 14 actives, les 2 plus lointaines dorment | **PASS** |
| Capture de silhouettes en aplats | `evidence/gateD/bestiary_flat.png` + `bestiary_material.png`, même échelle, aucune mise à l'échelle pour la photo (testé) | **PASS** |

## Défauts RÉELS trouvés par cette campagne et corrigés

1. Attaque déclenchée sans être tourné vers la cible (coups dans le vide).
2. Portée d'engagement supérieure à l'extension de la hitbox (boucle de
   coups courts perpétuels) — braise et briseur.
3. Hurtbox secondaire (dos du colosse) encore frappable après la mort.
4. Socle exigeant la hurtbox à la racine, incompatible avec une anatomie
   à point faible orienté.
5. Rocher du colosse né dans sa propre carrure (mort au premier tick).
6. Carte de navigation créée en code jamais libérée (fuite de RID).

## Verdict global

Le plus faible des items : **item 18 PARTIEL** (4 coffres sur 8, solde en
Phase F) et **item 20 sans essai humain**.

> **ACCEPTÉ POUR CONTINUATION — VALIDATION HUMAINE DIFFÉRÉE**

Conformément à l'ordre : aucune case `PASS humain` n'est cochée. Le
protocole d'essai est prêt (`docs/MANUAL_VALIDATION.md`,
`docs/PLAYTEST_PACKAGE.md` §5). Les quatre coffres restants sont
documentés comme appartenant aux salles du donjon (§11.4), et non comme
un oubli.

## Limites honnêtes à cet instant

- Colosse et chasseur sont des **graybox** (capsule / boîtes) : le
  modelage appartient à la Phase H (§22). Leur silhouette est néanmoins
  distincte en aplat, ce que le gate exige.
- Aucun essai clavier/manette possible dans ce conteneur (CLAUDE.md).
- Le rendu des captures est logiciel (llvmpipe) : aucune mesure de
  performance n'en est tirée.
