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
