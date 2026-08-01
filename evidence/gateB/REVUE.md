# Revue du Gate B — Traversal

**Commit examiné** : `c31534c` · **Date** : 2026-08-01 · **Périmètre** : commits
B.0 → B.5 (`70a7784..c31534c`).

Critère de la roadmap : « Parcours de test complet sans blocage ni caméra cassée ;
sprint/saut/escalade/mantle fiables », décomposé en volets vérifiables, plus les
critères chiffrés de §23.1 applicables au traversal.

## Critères et preuves (agent principal — avant revue contradictoire)

| # | Critère | Preuve (chemin + commande) | Verdict proposé |
|---|---|---|---|
| 1 | Parcours complet sans blocage (§22) | `tests/playthrough/test_traversal_course.gd` — pilote scripté sans triche, 13 assertions ; `evidence/gateB/validate_fast.log` RC=0 | PASS |
| 2 | Caméra jamais dans la géométrie (§23.1) | sonde sphérique au point de vue **à chaque tick** du parcours : 0/~1 400 images ; + `test_camera_rig.gd` (anti-traversée, dégagement mesuré) | PASS |
| 3 | Jitter caméra (§8.3 « zéro jitter ») | aucune preuve possible en headless — essai B-1 du protocole | NON VÉRIFIÉ |
| 4 | Sprint fiable, drain 12/s, épuisement → course (§9.1) | `test_stamina.gd` (15 cas), `test_locomotion.gd` (5 cas endurance) | PASS |
| 5 | Saut fiable : apex ~1,4 m, coyote 0,12 s, buffer 0,12 s (§8.2) | `test_locomotion.gd` : 3 cas dédiés | PASS |
| 6 | Marche 0,30–0,38 m franchie en marchant (§8.2) | `test_locomotion.gd` : 4 cas step-up, dont refus sous plafond | PASS |
| 7 | Escalade fiable : accroche, 2,0 m/s, 18/s, refus nommés, épuisement → lâcher (§9.2, §9.1) | `test_climbing.gd` (15 cas) | PASS |
| 8 | Mantle fiable : nominal, refus sous plafond, correction plafonnée, aucun snap **mesuré** (§9.3, §7.12) | `test_climbing.gd` + `test_action_alignment.gd` (9 cas, plus grand pas borné) | PASS |
| 9 | Entrée mouvement visible au tick physique suivant, latence instrumentée (§23.1, §10.6) | `test_latency.gd` : pire cas 1 tick sur 5 essais, mouvement et saut | PASS |
| 10 | Ressenti humain : contrôle, à-coups perçus, §21.4 | protocole prêt (`docs/MANUAL_VALIDATION.md` Gate B), **pas joué** | NON VÉRIFIÉ |
| 11 | AZERTY + manette fonctionnels (§23.1, hérité du Gate A) | Gate A `ACCEPTÉ AVEC RÉSERVE` ; **CONTROLLER-001 ouverte** | BLOQUÉ |

**Verdict global proposé (avant revue contradictoire)** : le plus faible des onze —
**BLOQUÉ / EN ATTENTE** des essais humains et de la dette manette. Aucun `FAIL`
connu côté code.

## Revue contradictoire (contexte frais)

*(complétée ci-dessous après le retour d'`adversarial-qa`)*
