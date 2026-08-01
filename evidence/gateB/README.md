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

## Ce que Gate B exigera encore, et que rien ici ne couvre

- Parcours de traversal rejoué **réellement**, pas seulement compilé (§22, Gate B).
- Ressenti et latence en ticks (§10.6) : mesure instrumentée + essai humain.
- Absence de jitter caméra (§8.3) : observation en mouvement à framerate réel.
- Tests manuels de §21.4 touchant le traversal : caméra contre tous types de murs,
  falaise irrégulière, mantle sous plafond, sprint à endurance nulle.
- **CONTROLLER-001** : l'essai manette. Aucun test automatique ne la lèvera jamais.
