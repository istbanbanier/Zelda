# ROADMAP — phases, dépendances, gates

Source : `docs/MASTER_SPEC.md` §22 (ordre d'implémentation) et §23 (gates d'acceptation).
Règle : **aucune phase ne démarre avant que le gate précédent soit `PASS` ou explicitement `BLOQUÉ` et documenté.**

## Vue d'ensemble

| Phase | Objet | Gate | État |
|---|---|---|---|
| 0 | Initialisation, continuité, réduction des risques | Gate 0 | 🔒 **GELÉ / ACCEPTÉ AVEC RÉSERVES** (D-006) |
| A | Fondation (projet, boot, autoloads, inputs, runner) | Gate A | 🟠 **EN ATTENTE** — A.1/A.2 livrés, validation humaine à jouer |
| B | Traversal (player, caméra, locomotion, endurance, escalade) | Gate B | 🟢 **ACCEPTÉ POUR CONTINUATION** (D-021) — validation humaine finale différée (VALIDATION-B-001) |
| C | Combat (santé, hitbox, combo, esquive, lock-on, arc, durabilité) | Gate C | 🟢 **ACCEPTÉ POUR CONTINUATION** — C.0 à C.5 livrés (duel gagnable, arc, durabilité, lock-on) ; validation humaine différée |
| C.5 | Micro-verticale + benchmark artistique `HeroShotLab` | Gate C.5 | 🟠 **EN ATTENTE** — la notation visuelle exige un œil humain sur la crête réelle (V4.1) |
| D | Monde graybox 512 m + cinq familles ennemies | Gate D | 🟢 **ACCEPTÉ POUR CONTINUATION — VALIDATION HUMAINE DIFFÉRÉE** (`docs/GATE_D_AUDIT.md`, passe 3 après revue contradictoire) ; item 18 PARTIEL assumé (4 coffres sur 8, solde en Phase F) |
| E | Récolte, cuisine, buffs, sauvegarde | Gate E | 🔵 **EN COURS** — E.1, E.2a et E.2b livrés ; reste migrations et chaîne complète |
| F | Graphe électrique + 4 salles du donjon | Gate F | ⬜ Non commencé |
| G | Boss trois phases + victoire | Gate G | ⬜ Non commencé |
| H | Art « wahou » | Gate H | ⬜ Non commencé |
| I | Optimisation et livraison | Gate I | ⬜ Non commencé |
| J | Démo 3 min, revue externe, release candidate | Gate J | ⬜ Non commencé |

## Dépendances dures

```
0 ──> A ──> B ──> C ──> C.5 ──> D ──> E ──> F ──> G ──> H ──> I ──> J
                          │                  │
                          └── décide si D    └── F réutilise le graphe
                              peut grandir       électrique pour les
                                                 pylônes du boss (G)
```

- **C.5 est un verrou** : interdiction d'agrandir la vallée (D) si la micro-scène
  reste générique, plate ou incohérente. Score visuel ≥ 75/100 exigé.
- **F avant G** : les pylônes de mise à la terre du boss utilisent le même système
  électrique que le donjon. Ne pas écrire deux implémentations.
- **E avant F** : le donjon exige une sauvegarde fiable pour les tests anti-softlock
  (chargement en milieu de résolution).
- **H après G** : ne pas produire d'assets finaux avant de savoir que la boucle est
  jouable — mais C.5 impose de valider la direction artistique très tôt.

## Critères de sortie par gate

### Gate 0 — Initialisation
- Une nouvelle session reprend le travail via `CLAUDE.md` + `STATUS` + `PROGRESS` en < 5 min.
- Pipeline minimal **import → run → test → capture** reproductible, ou blocage précisément documenté.
- Aucune dépendance ni licence inconnue critique.
- Versions exactes de Godot / Blender / outils consignées dans `docs/BUILD_ENVIRONMENT.md`.
- Risques classés dans `docs/RISKS.md`.

### Gate A — Fondation
Projet ouvre et lance, zéro parse error, InputMap AZERTY correct (`Q` = gauche
**vérifié en jeu**, pas seulement dans `project.godot`).

État : **EN ATTENTE**. Le volet automatisable est vert (52 tests) ; les six
contrôles humains sont décrits et outillés dans `docs/MANUAL_VALIDATION.md` et
n'ont pas encore été exécutés — aucune machine avec écran, clavier AZERTY ou
manette n'est disponible ici. Verdict global = le plus faible des six étapes.

### Gate B — Traversal
Parcours de test complet sans blocage ni caméra cassée ; sprint/saut/escalade/mantle fiables.

État : **ACCEPTÉ POUR CONTINUATION, VALIDATION HUMAINE FINALE DIFFÉRÉE** (D-021).
Revue contradictoire rendue (`evidence/gateB/REVUE.md`) : aucun `FAIL`, volet
automatique clos à 137 tests. Les essais humains (VALIDATION-B-001) et la manette
(CONTROLLER-001) se soldent à la passe finale. Ce n'est pas un `PASS`.

### Gate C — Combat
Combat gagnable, **une touche par swing**, aucune référence invalide, esquive avec i-frames.

### Gate C.5 — Micro-verticale
Micro-démo 60–90 s plaisante, score visuel ≥ 75/100 sur `HeroShotLab`, direction artistique
reproductible, aucun défaut d'architecture imposant de tout reconstruire.

### Gate D — Monde graybox
Vue d'ouverture lisible (3 plans), vallée terminable, aucune zone vide injustifiée.

### Gate E — Systèmes
Chaîne collecte → cuisine (1–5 ingrédients) → buff → save → load validée.

### Gate F — Donjon
Quatre salles solvables depuis sauvegarde vierge **et** depuis sauvegarde intermédiaire ;
aucun softlock ; objets essentiels respawnent.

### Gate G — Boss
Run complet graybox 25–40 min sans debug ; boss mathématiquement solvable avec le loot garanti.

### Gate H — Art
WOW Gate ≥ 85/100, aucun domaine à zéro, cohérence vérifiée sur cinq captures
(vignette, niveaux de gris, flou, silhouettes, 1440p) + vidéo.

### Gate I — Optimisation / livraison
Build candidat reproductible, budgets réellement mesurés sur matériel documenté,
aucun `S0`/`S1`, aucun `S2` critique, exports et reprise vérifiés.

### Gate J — Démo
Trois minutes fluides, non truquées, sans placeholder ; rapport final = build livré exactement.

## Procédure de gate (obligatoire)

1. L'agent principal produit les preuves dans `evidence/<gate>/`.
2. Une revue à **contexte frais** (`adversarial-qa`) reprend les critères un par un,
   joue le scénario malheureux et retourne `PASS` / `FAIL` / `BLOQUÉ` par critère.
3. Tout critère non testé est `NON VÉRIFIÉ` — jamais implicitement réussi.
4. Le verdict du gate est le **plus faible** des critères, pas leur moyenne.
5. Résultat consigné dans `docs/STATUS.md` et `docs/TEST_REPORT.md`.
