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

## Revue contradictoire (contexte frais) — rendue le 2026-08-01

La revue a **ré-exécuté** les preuves (dépôt principal + clone frais : RC=0,
133 tests à l'époque ; playground lancé ; release RC=3) et joué ses propres sondes
adverses. Verdicts par critère :

| # | Critère | Verdict revue | Écart avec la proposition |
|---|---|---|---|
| 1 | Parcours complet sans blocage | **PASS** | — (rejoué 3×, pilote sans triche vérifié dans le code) |
| 2 | Caméra jamais dans la géométrie | **PASS** | le « ~1 400 images » de la proposition n'était pas archivé — corrigé : le nombre de ticks sondés entre désormais dans le message d'assertion |
| 3 | Jitter caméra | **NON VÉRIFIÉ** | — (confirmé honnête) |
| 4 | Sprint/endurance §9.1 | **PASS** | — |
| 5 | Saut : apex, coyote, buffer | **PASS avec réserve** | « PASS — 3 cas dédiés » surestimait : les *mécanismes* étaient prouvés, les *valeurs 0,12 s* non défendues (mutation à 5,0 s → suite verte) |
| 6 | Marche 0,30–0,38 m | **PASS** | contre-exemple hors nominal (diagonale) — voir constats |
| 7 | Escalade §9.2 | **PASS** | — |
| 8 | Mantle §9.3/§7.12 | **PASS** | — |
| 9 | Latence 1 tick | **PASS** | — |
| 10 | Ressenti humain §21.4 | **NON VÉRIFIÉ** | protocole vérifié **réellement exécutable** (10 coordonnées du plan confrontées une à une aux transforms de la scène) |
| 11 | AZERTY + manette | **BLOQUÉ** | statut annoncé conforme aux documents |

**Verdict global de la revue : BLOQUÉ / EN ATTENTE — aucun `FAIL`.** Identique à
la proposition, mais établi par ré-exécution indépendante, avec trois réserves de
qualité de preuve.

## Constats de la revue et traitement (même jour, commits post-`c31534c`)

| # | Constat | Traitement |
|---|---|---|
| 1 | Fenêtres de saut non défendues : `coyote_time`/`jump_buffer` à 5,0 s → suite verte | 2 tests comportementaux ajoutés (fenêtre qui **se ferme**, tampon qui **expire**) + valeurs §8.2 épinglées ; contrôles V1/V2 : ÉCHEC confirmé |
| 2 | Vitesses circulaires : tests comparés à `tuning.*`, dérive du `.tres` invisible | `test_locomotion_tuning_matches_the_spec` épingle §8.2 valeur par valeur ; contrôle V3 (`run_speed = 12`) : ÉCHEC confirmé |
| 3 | Poussée diagonale à 45° contre la marche : jamais franchie | déclencheur remplacé — écoute des collisions de glissement (D-020 amendée) ; en le traitant, découverte que la mesure fondatrice de D-020 était un **artefact** (le joueur avait saisi le mur, pas heurté) ; test diagonal ajouté ; contrôle V4 : ÉCHEC confirmé |
| 4 | Logs de contrôles négatifs sans ligne `RC=` finale (règle B6) | convention appliquée : V1–V4 la portent, Q3 régénéré avec elle ; les logs antérieurs restent intacts (falsifier une archive est interdit), leur limite est documentée dans le README |
| 5 | « 26 contrôles négatifs » dans PROGRESS ; il y en avait 31 | compte retiré de PROGRESS — il vit dans le README d'evidence, par série |
| 6 | Saut perdu pendant un mantle ; mantle gratuit à endurance nulle | ni exigé ni interdit par la spec : consignés en questions ouvertes R-012 et R-013, à trancher en Phase C |

Suite après traitement : **137 tests, RC=0**, plancher 137.

## Verdict final du Gate B

**BLOQUÉ / EN ATTENTE** — le plus faible des onze critères :

- critère 11 `BLOQUÉ` sur la dette **CONTROLLER-001** (essai manette, Gate A) ;
- critères 3 et 10 `NON VÉRIFIÉ` : les six essais humains du protocole
  (`docs/MANUAL_VALIDATION.md`, section Gate B) n'ont pas été joués — aucun écran ici.

**Aucun `FAIL`. Le volet automatique est clos** : code, instrumentation,
couverture renforcée par la revue, 137 tests verts. La suite appartient à
l'opérateur (six essais, preuves dans `evidence/gateB/manual/`) et au propriétaire
(décision d'entamer ou non la Phase C avec un Gate B explicitement `EN ATTENTE`,
comme D-012 l'a fait pour le Gate A).
