# Étape 5 — Reprise dans une session à contexte frais

**Date** : 2026-08-01T01:29:47Z → 01:30:59Z
**Durée mesurée** : **1 min 12 s** (71 591 ms), pour un seuil de 5 min.
**Commit lu** : `f374548`
**Lecteur** : agent à contexte frais, aucune connaissance préalable du projet.
**Consigne donnée** : lire **uniquement** `CLAUDE.md`, `docs/STATUS.md`,
`docs/PROGRESS.md`, `docs/KNOWN_ISSUES.md` ; n'ouvrir aucun autre fichier, ne
lancer aucune commande, ne rien modifier.

## Limite de validité de cette preuve — à lire avant de s'y fier

Ce n'est **pas** littéralement une nouvelle session Claude Code sur un poste neuf.
C'est un agent à **contexte vierge** lisant le dépôt en place. Ce qui est
réellement mesuré : la documentation seule suffit-elle à comprendre l'état du
projet et à ne pas faire de bêtise ? C'est la substance du critère.

Ce qui n'est **pas** mesuré : le clonage à froid, la recompilation de Godot
(~60-120 min) et l'exécution de `validate_fast.sh` sur ce clone. Ces trois points
restent à faire sur le Mac, avec `05_validate_fast.log` comme preuve.

## Résultat

### Q1 — Où en est le projet ?
Réponse correcte : Phase A, A.1 et A.2 livrés et gelés sur `9414fd0` ; Gate 0
`GELÉ / ACCEPTÉ AVEC RÉSERVES` (D-006), Gate A `EN ATTENTE` ; **aucun gameplay
n'existe**. Le lecteur a même relevé que le Gate 0 n'est explicitement pas un
`PASS` et que quatre revues adverses ont rendu quatre `FAIL`.

### Q2 — Prochain jalon et première action ?
Réponse correcte : Phase B — Traversal, **mais elle ne démarre pas** avant le
verdict du Gate A ; la première action est de jouer
`tools/manual_validation_kit.sh` puis le protocole manuel.

### Q3 — Qu'est-ce qui est bloqué, et par quoi ?
Réponse correcte et complète : tableau reliant chaque blocage à son ISS
(ISS-001 à ISS-005), avec la distinction juste entre ce qui est bloqué et le
chemin headless resté praticable jusqu'au Gate G.

### Q4 — Quelle commande avant toute modification ?
Réponse correcte : `tools/validate_fast.sh`, code retour 0 attendu. A relevé
en complément que `validate_release.sh` sortant en 3 est le **comportement
nominal** ici, pas un échec.

### Q6 — Action spontanément proposée ?
**« Ne pas commencer la Phase B, et ne pas toucher au code. »**

C'est le contrôle décisif de `docs/MANUAL_GATE_A.md` §5.2 : une reprise qui aurait
proposé de démarrer la Phase B aurait signé un échec de la continuité.

## Verdict

**PASS** — 1 min 12 s, quatre réponses justes, et refus correct de dépasser le
gate en cours.

---

## Défauts de documentation trouvés par ce test

C'est le vrai apport de l'exercice : cinq incohérences qu'aucune des quatre revues
adverses n'avait relevées, parce qu'elles vérifiaient le code et les preuves, pas
la lisibilité de la documentation par un tiers.

| # | Défaut | Corrigé |
|---|---|---|
| 1 | `STATUS.md` : en-tête « Phase A (jalon A.1) » alors que le tableau annonce A.1 **et** A.2 | ✔ |
| 2 | Nombre de tests incohérent : `PROGRESS` disait « 13 tests », `STATUS` « 52 », la valeur réelle étant 54 | ✔ |
| 3 | `PROGRESS` citait encore `InputProbe.tscn`, renommée `InputAudit.tscn` | ✔ |
| 4 | `STATUS` indiquait « commit : voir `git log` » au lieu du hash gelé — une preuve non rattachable | ✔ |
| 5 | **Aucune porte de sortie documentée** si le matériel reste indisponible : la doc disait « ne pas contourner », sans dire qui peut prononcer un gel ni sous quelle forme. Le projet paraissait donc à l'arrêt indéfini. | ✔ (D-012) |

Le point 5 est le plus important, et il a été relevé spontanément : *« C'est la
question la plus coûteuse et elle devrait figurer dans le HANDOFF. »* La décision
du propriétaire de différer le test manette y répond ; elle est désormais écrite
en D-012 et CONTROLLER-001, au lieu d'être implicite.

Point mineur également relevé : `KNOWN_ISSUES.md` listait ISS-004 avant ISS-003.
