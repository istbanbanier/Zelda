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
| E | Récolte, cuisine, buffs, sauvegarde | Gate E | 🟢 **ACCEPTÉ POUR CONTINUATION — VALIDATION HUMAINE DIFFÉRÉE** (`docs/GATE_E_AUDIT.md`) — E.1 à E.3 livrés |
| F | Graphe électrique + 4 salles du donjon | Gate F | 🟨 **ACCEPTÉ POUR CONTINUATION — VALIDATION HUMAINE DIFFÉRÉE** (`docs/GATE_F_AUDIT.md`) — ligne corrigée le 2026-08-05, elle contredisait STATUS et l'audit (relevé par la revue contradictoire) |
| G | Boss trois phases + victoire | Gate G | 🟨 **ACCEPTÉ POUR CONTINUATION — VALIDATION HUMAINE DIFFÉRÉE** (`docs/GATE_G_AUDIT.md`) : tous les items §16 automatisables PASS, run boss joué de bout en bout ; le « run de 25-40 min » reste NON VÉRIFIÉ faute de joueur |
| H | Art « wahou » | Gate H | 🟠 **EN COURS** — lots H.1 à H.6 faits : Gardien, trois pillards, colosse et chasseur montés, tous assemblés en un seul corps (ISS-018 clos, contrôle ISS-019 câblé en validate_fast 3b). Le WOW Gate porte sur la vue d'ouverture et n'a pas été rejoué |
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

---

## Cadence complète jusqu'à la fin (2026-08-05, mandat utilisateur)

Ordre imposé par la logique cumulative des prompts : le Prompt 2 (systémique)
AVANT la production d'assets du Prompt 3 — décorer un gameplay qui va rebouger
serait du travail jeté. Chaque jalon = une session bornée, DoD du CLAUDE.md.

### Cycle 1 — Prompt 2, fondations (P2-0 → P2-2)
1. **P2-0 Audit** : `PROMPT2_AUDIT.md`, baseline visuelle/perf, backlog classé.
2. **P2-1 Réponse** : InputLab/TraversalLab (CombatLab existe), instrumentation
   des latences, pipeline d'action data-driven audité 30/60/120.
3. **P2-2 Bracelet** (le cœur) : `ResonanceController` + profils matériaux +
   `ReactionSystem` ; Pulse → Arc Link → Polarité → Arc Step → Ground, chacun
   fail-first dans `ReactionLab` ; Gate Bracelet + Gate ReactionSystem.
   ~4-6 sessions à lui seul, INCOUPABLE (échelle de réduction P2 §18).

### Cycle 2 — Prompt 2, profondeur (P2-3 → P2-5)
4. **P2-3 Combat/IA** : garde/déviation/posture, 6 identités d'armes,
   perception honnête + tokens, camp à trois approches.
5. **P2-4 Exploration** : trois routes nommées, 8-10 POI (base existante),
   progression Bracelet, infiltration/bruit.
6. **P2-5 Donjon/Boss** : migration des salles vers les lois communes,
   solveur/hints, boss director à patterns tagués.

### Cycle 3 — Prompt 3/4, art (Phase H complète, passes V3 → V9)
7. **V3 Héros** : 5 signes §13.1, Bracelet visible (dépend de P2-2).
8. **V4 Vallée** : eau (§8 — MISSING intégral), terrain sculpté, focales.
9. **V5-V6** : props/UI/icônes, famille ennemie pilote puis les quatre.
10. **V7 Donjon** : kit modulaire + éclairage motivé (règle ISS-025).
11. **V8 Boss** : sous-meshes destructibles, arène.
12. **V9 + shaders** : SH_CharacterPainterly d'abord (arbitrage verrouillé n°2),
    VFX, cinématiques. Re-scoring §30.2 à chaque palier, revue contradictoire
    au Gate H final.

### Cycle 4 — Phases I/J (partagées conteneur/humain)
13. Ici : presets, LOD/HLOD, DemoRoute, budgets IA, ISS-024 (budgets en ticks).
14. **Chez l'utilisateur uniquement** (protocole `MANUAL_VALIDATION.md`) :
    60 FPS mesurés, session 60 min, vidéo démo 3 min, AZERTY/manette réels,
    playtests §21.9. Ces critères resteront EN ATTENTE ici — jamais cochés
    sur la foi du conteneur.

Règle de cadence : jamais deux cycles en parallèle ; un gate rouge arrête la
progression ; toute découverte S1/S2 prime sur le jalon en cours.
