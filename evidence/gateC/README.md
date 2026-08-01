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
