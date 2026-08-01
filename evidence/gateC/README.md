# evidence/gateC — Phase C (combat)

Preuves datées rattachées au commit qui les a produites (§0.7). Convention `RC=`
en fin de chaque log de contrôle négatif (règle B6, appliquée depuis la revue du
Gate B).

## Jalon C.0 — Fondations de dégâts (2026-08-01)

| Log | Mutation | Test visé | Résultat |
|---|---|---|---|
| `W1_degats_a_chaque_frame` | set des cibles touchées retiré | `test_an_overlapping_swing_hits_exactly_once` | ÉCHEC — **30 coups en 30 frames, santé 100 → 0** ✅ |
| `W2_formule_sans_clamp` | clamp de §10.3 retiré | `test_formula_never_returns_negative_damage` | ÉCHEC — « obtenu −45.0000 » ✅ |
| `W3_mort_non_idempotente` | garde `_dead` retirée | `test_death_is_emitted_once_and_is_final` | ÉCHEC — « died : attendu 1, obtenu 2 » ✅ |
| `W4_tir_ami_autorise` | contrôle d'équipe retiré | `test_friendly_fire_is_refused_by_team` | ÉCHEC — l'allié perd 10 PV ✅ |

W1 chiffre l'interdit central de §10.1 : sans le set des cibles déjà touchées,
un chevauchement de 30 frames devient 30 coups et la victime meurt d'un seul
swing. C'est le critère « une touche par swing » du Gate C, prouvé dans les deux
sens.

## Piège moteur consigné pendant C.0

`Area3D.monitoring` coupé puis rallumé entre deux ticks laisse la liste de
chevauchements **définitivement vide** (R-014). Les hitbox gardent donc
`monitoring` allumé en permanence ; la fenêtre active est portée par `_active`
et le balayage. Sans cette mesure, un swing sur deux aurait été muet — un bug de
gameplay presque intraçable.


## Jalon C.1 — Épée, combo, premier échange (2026-08-01)

| Log | Mutation | Test visé | Résultat |
|---|---|---|---|
| `X1_coup_sans_anticipation` | startup sauté, hitbox allumée au premier tick | fenêtre active | ÉCHEC ✅ |
| `X2_enchainement_hors_fenetre` | condition de fenêtre retirée | enchaînement à la fenêtre | ÉCHEC — enchaîne dès la recovery ✅ |
| `X3_buffer_immortel` | le buffer ne décroît plus | expiration de l'appui | ÉCHEC ✅ |
| `X4_multiplicateur_ignore` | terme « attack » de §10.3 ignoré | montants du combo | ÉCHEC — « obtenu 12.0000 » aux coups 2 et 3 ✅ |

## Piège d'infrastructure consigné pendant C.1

Le monde `queue_free` du test précédent survit une frame : le joueur du test
suivant peut apparaître **posé sur sa géométrie fantôme** (mesuré : y = 0,87 au
lieu de 0,1), chuter quand elle disparaît, et voir son premier appui consommé en
l'air par le portail `is_on_floor()`. Symptôme trompeur : l'appui unique échouait,
le martèlement réussissait. Règle : attendre l'**état** (atterri), jamais un
nombre de ticks fixe — la leçon de B.2, version infrastructure.


## Jalon C.2 — Esquive, i-frames, lock-on, premier pillard (2026-08-01)

| Log | Mutation | Test visé | Résultat |
|---|---|---|---|
| `Y1_iframes_jamais_ouvertes` | l'esquive n'ouvre plus la fenêtre | i-frames + esquive chronométrée | ÉCHEC — le coup porte pendant la roulade ✅ |
| `Y2_esquive_gratuite` | coût et refus d'endurance retirés | coût de l'esquive | ÉCHEC — « obtenu 0.0000 » ✅ |
| `Y3_verrouillage_a_travers_mur` | LOS ignorée à l'acquisition | mur de §8.4 | ÉCHEC ✅ |
| `Y4_repli_supprime` | le pillard ignore l'esquive réussie | repli de §12.1 | ÉCHEC — « état : attack » ✅ |
| `Y5_telegraphe_escamote` | startup du gourdin à 0,1 s **dans le `.tres`** | télégraphe, comportement ET enveloppe | ÉCHEC ×2 — « 0.13 s » mesuré + « 0.10 » épinglé ✅ |

Y5 illustre la doctrine post-revue-B au complet : la valeur de spec est défendue
par un test d'enveloppe ET par une mesure comportementale — la mutation fait
rougir les deux, indépendamment.

## Jalon C.3 — Attaque lourde, réaction du joueur, arc (2026-08-01)

| Log | Mutation | Test visé | Résultat |
|---|---|---|---|
| `Z1_portail_endurance_lourde_retire` | `can_spend` retiré de la lourde | refus à jauge 10 | ÉCHEC — le mannequin encaisse 21,6 ✅ |
| `Z2_grace_antistunlock_annulee` | `stunlock_grace` → 0 **dans le `.tres`** | second coup en cadence | ÉCHEC — le contrôle est repris, stun-lock possible ✅ |
| `Z3_origine_de_fleche_avancee` | origine du tir avancée de 1,5 m | mur à 0,8 m | ÉCHEC — le mannequin abrité prend 9 ✅ |
| `Z4_vitesse_de_fleche_mutee` | `arrow_speed` 48 → 80 dans le `.tres` | enveloppe §10.4 | ÉCHEC — « vitesse hors §10.4 : 80.0 » ✅ |
| `Z5_connexion_hurtbox_retiree` | connexion hurtbox → contrôleur retirée | réaction + grâce | ÉCHEC ×4 — dégâts passés, zéro réaction ✅ |
| `Z6_recul_non_applique` | impulsion de recul seule retirée | déplacement dz | ÉCHEC ×1 — le mode HURT s'ouvre, dz = 0,00 ✅ |

**Z5 rejoue un défaut réel du code livré.** La première exécution de
`test_heavy_and_hurt` a trouvé `_on_hit_received` écrit **mais jamais connecté**
à la hurtbox : les dégâts passaient (la hurtbox blesse la santé directement),
la réaction restait lettre morte — 4 assertions rouges, mêmes lignes que Z5.
Corrigé le jour même (connexion dans `_ready`), et Z6 précise la granularité :
sans l'impulsion, seule l'assertion de déplacement rougit — chaque assertion
surveille sa pièce, pas un effet de bord d'une autre.

Z3 chiffre pourquoi l'origine du tir est LA POITRINE et ne s'avance jamais
(§10.4) : avancée de 1,5 m, elle passe derrière un mur mince et la flèche
naît de l'autre côté.
