# evidence/gateB — Phase B (traversal)

Preuves datées rattachées au commit qui les a produites. Une affirmation sans
preuve ici est `NON VÉRIFIÉ` (§0.7, `.claude/rules/evidence.md`).

## Jalon B.1 — Player, CameraRig, locomotion (2026-08-01)

| Fichier | Contenu |
|---|---|
| `negative_controls/*.log` | 8 contrôles négatifs rejoués, chacun cassant une défense de B.1 |

Le journal complet de `tools/validate_fast.sh` n'est **pas** versionné (voir
`.gitignore`) : il se régénère en quelques minutes et sa valeur probante tient à sa
fraîcheur, pas à son archivage. Le résultat retenu et les commandes exactes sont
dans `docs/TEST_REPORT.md`, section « Jalon B.1 ».

### Contrôles négatifs

Un test incapable d'échouer ne prouve rien. Chaque défense a été cassée
volontairement, la suite relancée, l'état restauré et vérifié identique à l'octet
près avant de poursuivre.

| Log | Mutation | Test visé |
|---|---|---|
| `C1_epaule_sur_la_camera` | épaule reposée sur la `Camera3D` | `test_shoulder_offset_survives_the_spring_arm` |
| `C2_sonde_volumique_retiree` | retour au rayon simple | `test_spring_arm_pulls_the_camera_in_front_of_a_wall` |
| `C3_fov_poids_fixe` | interpolation FOV à poids fixe | `test_fov_interpolation_is_framerate_independent` |
| `C4_fov_snap` | FOV atteint en une image | `test_fov_widens_on_sprint_without_snapping` |
| `C5_butees_pitch_supprimees` | butées de pitch retirées | `test_pitch_is_clamped_to_the_specified_range` |
| `C6_seuil_de_pente_releve` | `max_floor_angle_deg` → 70° **dans le `.tres`** | `test_steep_slope_is_rejected` |
| `C7_noeud_intercale` | `Node3D` intercalé sous le bras | `test_camera_is_a_direct_child_of_the_spring_arm` |
| `C8_camera_petite_fille_decalee` | caméra petite-fille décalée de 1 m | `test_spring_arm_pulls_the_camera_in_front_of_a_wall` |

Les huit ont échoué comme attendu. Deux méritent une lecture attentive :

- **C6** a d'abord été joué sur la valeur par défaut du `@export` et n'a **rien**
  cassé — faux négatif qui se lisait « le test ne prouve rien ». La ressource
  réellement chargée sérialise sa propre valeur (R-006bis).
- **C7** a **réfuté** la justification alors écrite dans le code : une caméra
  petite-fille à position nulle ne traverse pas les murs. Le vrai mécanisme, isolé
  par **C8**, est qu'un descendant conserve un décalage que le cast du bras ignore.
  Commentaires et en-têtes corrigés en conséquence (D-014).

## Jalon B.2 — Endurance (2026-08-01)

| Log | Mutation | Test visé |
|---|---|---|
| `N1_sprint_gratuit` | le sprint n'appelle plus `try_sustain()` | `test_sprint_drains_stamina` |
| `N2_epuisement_sans_effet` | `can_sustain()` ignore épuisement et réserve | `test_exhaustion_drops_the_sprint_back_to_running` |
| `N3_seuil_de_recuperation_retire` | **le défaut d'origine** : récupération dès la première unité | `test_a_held_sprint_produces_usable_bursts_not_a_stutter` |
| `N4_reprise_sans_rampe` | régénération à plein régime dès la première image | `test_regeneration_ramps_in_instead_of_snapping` |
| `N5_delai_de_regeneration_ignore` | délai de 1 s ignoré | `test_regeneration_waits_the_declared_delay` |
| `N6_verrou_annule_dans_le_tres` | `exhaustion_lockout` à 0 **dans le `.tres`** | `test_the_exhaustion_lockout_refuses_an_otherwise_affordable_cost` |
| `N7_cout_preleve_malgre_le_refus` | `try_spend()` prélève malgré le refus | `test_an_unaffordable_cost_is_refused_and_consumes_nothing` |
| `N8_sprint_immobile_consomme` | `has_move()` retiré | `test_holding_sprint_while_standing_still_costs_nothing` |

**N3 reproduit le défaut réel de B.2** et affiche la rafale mesurée : `0.017 s`,
soit exactement un tick physique. C'est ce chiffre, et non une relecture du code,
qui a établi que l'implémentation littérale de §9.1 faisait bégayer le sprint
(D-016).

**N6** mute la ressource et non la valeur par défaut du `@export` : la règle tirée
de B.1 (R-006bis). Muter le script n'aurait rien cassé et le contrôle aurait conclu
à tort que le test était inutile.

## Jalon B.3 — Escalade et mantle (2026-08-01)

| Log | Mutation | Test visé |
|---|---|---|
| `P1_groupe_unclimbable_ignore` | `is_surface_climbable()` accepte tout | `test_an_unclimbable_surface_is_refused` |
| `P2_sonde_des_pieds_ignoree` | contact aux pieds non exigé | `test_an_overhang_is_refused` |
| `P3_degagement_de_capsule_retire` | contrôle de dégagement retiré | `test_a_ledge_under_a_ceiling_refuses_the_mantle` |
| `P4_trajet_de_mantle_en_ligne_droite` | trajet direct au lieu de deux temps | `test_reaching_a_ledge_mantles_onto_it` |
| `P5_endurance_ignoree_sur_la_paroi` | l'escalade ne consomme plus rien | `test_climbing_drains_stamina` |
| `P6_seuil_de_paroi_au_dessus_du_sol` | seuil à 50° **dans le `.tres`** | `test_no_angle_is_both_unwalkable_and_unclimbable` |
| `P7_accroche_au_sol_non_retablie` | `floor_snap_length` non rétabli | `test_releasing_the_wall_restores_ground_settings` |
| `P8_saut_d_escalade_gratuit` | saut d'escalade sans coût | `test_climb_jump_costs_stamina_and_pushes_off` |

Deux d'entre eux ont appris quelque chose plutôt que confirmé :

- **P2 n'a rien cassé** lors de sa première exécution. Ce n'était pas un test
  robuste, c'était une branche — le refus des surplombs — que **rien** ne couvrait.
  La paroi flottante du bac à sable et `test_an_overhang_is_refused` ont été ajoutés
  pour ça, et P2 a été rejoué contre le nouveau test.
- **P3 ne rend pas le franchissement possible** : il déplace le refus du détecteur
  de rebord vers le contrôle de mi-parcours, et la raison rapportée passe de
  `blocked` à `blocked_midway`. Il y a donc deux lignes de défense, et le test les
  distingue.

## Jalon B.4 — Franchissement de marche et parcours enchaîné (2026-08-01)

| Log | Mutation | Test visé | Résultat |
|---|---|---|---|
| `Q1_franchissement_de_marche_retire` | `_try_step_up()` n'est plus appelé | `test_a_low_step_is_climbed_by_walking` | ÉCHEC ✅ |
| `Q2_degagement_au_dessus_ignore` | contrôle de dégagement au-dessus retiré | `test_a_step_under_a_low_ceiling_is_refused` | ÉCHEC — traverse jusqu'à z = −38,30 ✅ |
| `Q3_mur_confondu_avec_une_marche` | dégagement avant **et** praticabilité retirés | `test_a_tall_wall_is_not_treated_as_a_step` | **vert — non concluant** |
| `Q4_parcours_sans_franchissement_de_marche` | `_try_step_up()` retiré | `test_the_full_traversal_course...` | ÉCHEC dès le segment 1 ✅ |
| `Q5_declencheur_adosse_a_is_on_wall` | retour au déclencheur `is_on_wall()` | `test_a_low_step_is_climbed_by_walking` | **vert — non concluant** |

**Q3 et Q5 sont archivés bien qu'ils n'aient rien cassé.** Un contrôle négatif qui
reste vert est un résultat, pas un raté de procédure — et ces deux-là délimitent
précisément ce que les tests prouvent :

- **Q3** : devant un mur plein, la sonde descendante ne trouve aucun sol et
  `_try_step_up()` refuse **avant** d'atteindre ses contrôles. Défense en
  profondeur réelle, mais le test ne valide aucune ligne en particulier. Sa
  docstring le dit désormais.
- **Q5** : aucun test ne départage le déclencheur retenu (blocage mesuré) de celui
  qu'il remplace (`is_on_wall()`). Le changement repose sur une mesure directe —
  `is_on_wall()` renvoie faux contre le mur de 6 m — et non sur ce test (D-020).

## Jalon B.5 — Latence instrumentée (2026-08-01)

| Log | Mutation | Test visé | Résultat |
|---|---|---|---|
| `L1_acceleration_imperceptible` | `ground_acceleration` à 0,3 **dans le `.tres`** | `test_movement_responds_at_the_next_physics_tick` | ÉCHEC — « min 3, max 3 » mesuré ✅ |
| `L2_saut_reordonne_un_tick_plus_tard` | `_try_jump()` déplacé avant `_update_timers()` | `test_jump_responds_at_the_next_physics_tick` | ÉCHEC — « min 2, max 2, 33,3 ms » ✅ |

**L2 est la mutation qui compte** : elle reproduit la régression d'architecture
que §10.6 vise — une action tardive **par ordre d'exécution**, pas par intention.
Le test la chiffre : 2 ticks au lieu de 1.

## Ce que Gate B exigera encore, et que rien ici ne couvre

- Lissage de la normale de paroi et vitesse latérale (§9.2) : implémentés, **non
  mesurés** — le bac à sable n'a que des parois planes.
- Ressenti humain (§10.6) et jitter caméra (§8.3) : la mesure est instrumentée
  (1 tick), le protocole des essais est écrit (B-1…B-6) — il reste à le **jouer**
  sur une machine avec écran.
- **CONTROLLER-001** : l'essai manette. Aucun test automatique ne la lèvera jamais.
