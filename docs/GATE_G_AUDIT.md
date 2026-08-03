# Audit du Gate G — Gardien de l'Orage

Base : MASTER_SPEC §16 (présentation, machine à états, trois phases, caméra
et arène, solvabilité, victoire), §22 Phase G, §23.1. Critère de sortie du
gate, tel que `docs/ROADMAP.md` l'énonce : **« run complet graybox 25-40 min
sans debug ; boss mathématiquement solvable avec le loot garanti »**.

Preuves rejouées au commit de HEAD, jamais reprises d'un résumé.

## Matrice de preuve — items de la Phase G

| # | Item §22 | Preuve rejouée | Verdict |
|---|---|---|---|
| 29 | Arène et pylônes | `--filter=boss_arena` 11/11 : disque mesuré à 38 m par sa `CylinderShape3D`, trois zones emboîtées, disque balayé à la recherche d'un obstacle central, quatre pylônes à 14 m branchés sur un anneau de terre fermé | **PASS** |
| 30 | Boss phase 1, puis 2, puis 3 | `--filter=boss_guardian` 12/12 : armure ×0,2 non-invulnérable, deux pylônes (pas un) pour la mise à la terre, cristaux révélés en phase 2, renvoi conducteur borné à la surcharge, télégraphe chronométré, gain de vitesse de phase 3 mesuré par la distance parcourue | **PASS** |
| 31 | Solvabilité, durabilité, checkpoint | `test_the_guardian_is_beatable_with_the_guaranteed_loot` (calcul) **et** `--filter=boss_run` (run joué) ; checkpoint relu par l'arène, retry qui relance le combat | **PASS** |
| 32 | Victoire et conclusion | `--filter=boss_victory` 7/7 : coffre final, rail éteint, ciel qui s'ouvre partiellement, cinématique passable, écran de victoire à trois issues | **PASS** |

## Matrice de preuve — exigences §16, une par une

| § | Exigence | Preuve | Verdict |
|---|---|---|---|
| §16.1 | Arène circulaire 32-42 m | `test_the_arena_is_a_disc_between_32_and_42_metres` : **38 m**, mesurés sur la forme de collision | **PASS** |
| §16.1 | Quatre pylônes de mise à la terre | `test_nothing_stands_in_the_middle_of_the_arena` : quatre, tous à 14 m ±0,1 | **PASS** |
| §16.1 | Zones de sol distinctes | trois couronnes emboîtées (noyau 6 m, combat 14 m, marge 19 m) | **PASS** |
| §16.1 | Aucun pilier bloquant durablement la caméra | le disque est balayé : rien au-dessus du sol sous 13 m du centre | **PASS** |
| §16.1 | Animation d'entrée 5-8 s | **défaut trouvé par test** : `_enter()` étant idempotent, l'INTRO n'était jamais armée et le Gardien passait en phase 1 au premier tick. Corrigé ; l'éveil est vérifié dans `test_the_camera_widens_progressively_near_the_boss` | **PASS** |
| §16.1 | Barre de vie originale | `test_the_hud_shows_a_boss_bar_only_in_the_arena` : bandeau ardoise/or, vie réelle, nom de phase | **PASS** |
| §16.2 | Machine à dix états | `state_name()` couvre les dix états de la spécification ; le run les traverse | **PASS** |
| §16.2 | Transitions idempotentes, un seuil ne déclenche pas deux fois | `test_a_health_threshold_never_fires_twice` : seuil franchi, soigné, refranchi | **PASS** |
| §16.2 | La mort interrompt tout, une seule fois | `test_death_cuts_everything_and_writes_the_victory` : hurtbox muettes, hitbox inactives, pylônes rabaissés, second coup sans effet | **PASS** |
| §16.3 | L'armure réduit fortement sans invulnérabilité obscure | `test_the_armour_divides_damage_without_making_him_invulnerable` : 100 dégâts entrent, moins de 30 passent, jamais zéro | **PASS** |
| §16.3 | DEUX pylônes orientés/connectés | `test_two_pylons_ground_him_and_expose_the_core` : avec un seul, l'arc part sur le joueur | **PASS** |
| §16.3 | Mise à la terre = étourdissement 5-8 s, noyau vulnérable | 6 s, noyau `monitorable` et point faible ×2,5 ; l'armure se referme ensuite | **PASS** |
| §16.3 | Les pylônes utilisent le MÊME système électrique que le donjon | `test_a_raised_pylon_is_powered_by_the_ground_rail` : couper le puits de terre éteint un pylône DRESSÉ. La connexion est géométrique (sabot sur siège), pas un drapeau | **PASS** |
| §16.4 | Deux cristaux conducteurs, destructibles | `test_the_crystals_appear_in_phase_two_and_open_the_core` : invisibles et intouchables hors phase 2, 60 PV chacun | **PASS** |
| §16.4 | Métal en surcharge = risque, bois = pas de risque | `test_conductive_weapons_backfire_during_overload_and_wood_does_not` : joué avec le gourdin et la lame conductrice réels, et hors fenêtre pour prouver que le risque est FENÊTRÉ | **PASS** |
| §16.4 | La résistance électrique réduit dégâts et durée | `test_electric_resistance_softens_the_backlash` : renvoi mesuré avec et sans le buff | **PASS** |
| §16.5 | Vitesse +10 à +18 %, pas de doublement | `test_phase_three_speeds_up_within_the_specified_band` : distance parcourue comparée entre phase 1 et phase 3 | **PASS** |
| §16.5 | Éclairs marqués au sol 0,7-1,0 s avant impact | `test_the_ground_strike_gives_a_real_warning_window` : fenêtre chronométrée, et un télégraphe réglé à 0,05 s est ramené à 0,7 | **PASS** |
| §16.5 | Noyau exposé après destruction des cristaux | même test que §16.4 : `is_armoured()` retombe à faux | **PASS** |
| §16.6 | Boss visible ≥ 80 % du temps en lock-on | `test_the_guardian_stays_in_frame_while_locked_on` : 180 positions autour de lui, projection écran réelle | **PASS** (partie automatisable) |
| §16.6 | Caméra qui élargit distance et FOV progressivement | `test_the_camera_widens_progressively_near_the_boss` : plus grand pas < 0,25 m par tick, retour au cadrage normal après la mort | **PASS** |
| §16.6 | Le boss ne pousse pas le joueur à travers les murs | `test_the_guardian_cannot_push_the_player_through_the_wall` : 240 ticks, joueur collé au mur | **PASS** |
| §16.6 | Nav/steering garde le boss dans l'arène | `test_the_guardian_never_leaves_the_arena` : joueur placé à 30 m dehors | **PASS** |
| §16.6 | Checkpoint juste avant | `test_the_arena_restores_the_antechamber_checkpoint` : armes, flèches et santé relues | **PASS** |
| §16.6 | Retry en moins de 20 s | `test_retry_reloads_the_arena_not_the_valley` : cible du bouton + chargement chronométré. La durée RESSENTIE reste un essai humain | **PARTIEL** |
| §16.7 | Test qui échoue si le boss est mathématiquement impossible | `test_the_guardian_is_beatable_with_the_guaranteed_loot`. **Il a échoué à sa première exécution** : marge -16 %. Les PV sont passés de 900 à 560 | **PASS** |
| §16.7 | Marge de 30-50 % au-dessus du minimum | **+35 %**, borne haute testée aussi | **PASS** |
| §16.7 | Aucune arme rare exigée | le même test vérifie que la lame conductrice SEULE ne suffit pas | **PASS** |
| §16.8 | Arrêter hazards et projectiles | `test_the_cyan_goes_quiet_when_he_dies` : le rail entier s'éteint | **PASS** |
| §16.8 | Tempête qui se dissipe partiellement | `test_the_storm_partially_clears_after_the_victory` : ciel, brouillard et lumière mesurés, sans saut et sans redevenir un midi bleu | **PASS** |
| §16.8 | Coffre final | `test_the_final_chest_appears_only_after_the_guardian_falls` : absent avant, au centre après, butin certain | **PASS** |
| §16.8 | Sauvegarde `boss_defeated` | relue depuis le fichier dans deux tests distincts | **PASS** |
| §16.8 | Courte cinématique passable | `test_the_conclusion_can_be_cut_short_by_opening_the_chest` | **PASS** |
| §16.8 | Écran victoire : recommencer / continuer / menu | `test_the_victory_screen_offers_three_real_ways_out` : trois issues, cycle de focus fermé, cibles vérifiées ; confirmation avant d'écraser | **PASS** |

## Critère de sortie du Gate G

| Critère | Preuve | Verdict |
|---|---|---|
| Boss mathématiquement solvable avec le loot garanti | `test_the_guardian_is_beatable_with_the_guaranteed_loot` (calcul, marge +35 %) **et** `test_boss_run.gd` (run joué : le Gardien tombe avec l'équipement du coffre garanti, à travers `DamageFormula` et les vraies hurtbox) | **PASS** |
| Le combat traverse réellement ses trois phases | `test_boss_run.gd` enregistre les phases vues : `phase1 → grounded_stun → transition12 → phase2 → transition23 → phase3`. **Ce contrôle a trouvé un défaut** : les seuils étant gelés pendant l'étourdissement, le Gardien mourait en phase 1 sans jamais montrer §16.4 ni §16.5 | **PASS** |
| Run complet **graybox de 25-40 minutes** sans debug | **NON VÉRIFIÉ.** C'est une durée HUMAINE. Aucun test ne la mesure et aucun chiffre de ce dépôt ne doit être présenté comme telle. La chaîne de scènes est prouvée jusqu'à la victoire (`test_dungeon_run.gd` pour la jambe donjon, `test_boss_run.gd` pour la jambe boss), mais personne n'a joué la partie | **NON VÉRIFIÉ** |

## Ce qui n'est PAS couvert

- **Durée de la première victoire** (§16.1 : 4-7 min) : temps humain, non mesurable ici.
- **Ressenti** : lisibilité des télégraphes, confort de la caméra pendant le
  combat, sensation du renvoi de surcharge, moment juste pour l'écran de
  victoire. Protocole prêt : `docs/MANUAL_VALIDATION.md`, essais G-1 à G-5.
- **Balayage de hitbox pendant le run** : `test_boss_run.gd` postule le
  contact et se donne une précision de deux coups sur trois. La visée d'un
  joueur réel n'est pas simulée — c'est dit dans l'en-tête du fichier.
- **Son** : aucun périphérique audio dans ce conteneur (ISS-004). Les accords
  de phase et le tonnerre appartiennent à la Phase H.
- **Art** : le Gardien est un graybox. Le hero asset de §16.1, les dégâts
  visuels progressifs et les VFX relèvent du Prompt 3 (V8).
- **Performance** : aucune mesure GPU possible (llvmpipe).

## Verdict global

Tous les critères automatisables sont `PASS`, sur des preuves rejouées. Le
critère de sortie « run de 25-40 min » reste `NON VÉRIFIÉ` faute de joueur.

> **ACCEPTÉ POUR CONTINUATION — VALIDATION HUMAINE DIFFÉRÉE**

Aucune case `PASS humain` n'est cochée.
