# PROGRESS — journal chronologique et handoff

Ordre **anti-chronologique** : l'entrée la plus récente est en haut. La dernière
entrée fait office de handoff et doit indiquer **exactement** la prochaine action.

---

## 2026-07-31 — Session 1 — Phase 0 : initialisation et continuité

**Jalon pris** : Phase 0 uniquement, jusqu'au Gate 0. Aucun gameplay.

### Ce qui a été fait

1. **Lecture intégrale** du cahier des charges (2358 lignes), conservé en
   `docs/MASTER_SPEC.md` comme source de vérité.
2. **Audit de l'environnement** : dépôt vide sans commit, Godot absent, Blender
   absent, aucun GPU, aucun affichage, politique réseau restrictive.
3. **Résolution de la disponibilité du moteur.** Les binaires officiels sont
   inaccessibles (egress 403). Après avoir écarté Godot 3.5.2 d'apt (mauvaise
   version majeure) et vérifié que ni PyPI ni npm ne distribuent le moteur, le tag
   `4.7.1-stable` a été trouvé accessible en lecture git et compilé depuis la
   source, épinglé au commit `a13da4fe`.
4. **Système de continuité complet** (§0.3) : les 12 artefacts obligatoires, plus
   `RISKS.md` et `BUILD_ENVIRONMENT.md`. `CLAUDE.md` tenu sous 150 lignes.
5. **Outillage de preuve** : `env_report.sh`, `setup_godot.sh`, `validate_fast.sh`,
   `validate_release.sh`, `test_runner.gd`, `capture_reference.gd`.
6. **Pipeline d'assets Blender → glTF vérifié de bout en bout**, deux bugs réels
   trouvés et corrigés au passage (voir ISS-R01 et ISS-R02).
7. **Réglages moteur vérifiés dans la source du tag**, pas supposés : noms exacts de
   `physics/3d/physics_engine`, `"Jolt Physics"`, `rendering_method`, `CONFIG_VERSION`.

### Ce qui n'a pas été fait, et pourquoi

- **Aucune mesure de performance ni score visuel.** La capture, elle, s'est
  révélée possible via Xvfb + llvmpipe (rendu logiciel) — hypothèse R-004
  infirmée dans le bon sens. Mais llvmpipe interdit toute mesure, et il n'existe
  aucune scène North Star à noter. Gates H, I et J restent bloqués ici.
- **Aucune scène laboratoire** (`StyleLab`, `HeroShotLab`…) : elles n'ont de sens
  qu'avec un rendu, et §7.16 exige de les capturer. Les créer aveuglément
  produirait des coquilles vides.
- **Aucun gameplay** : c'est le périmètre de la Phase A. La consigne était de ne
  pas dépasser la Phase 0.
- **L'image de référence n'a pas pu être versionnée** : fournie dans la
  conversation, pas comme fichier (ISS-003). Son analyse est consignée.

### Décisions prises

D-001 (compiler Godot depuis la source), D-002 (Blender 4.0.2 Ubuntu),
D-003 (`.glb` seul format d'échange), D-004 (validation glTF hors moteur),
D-005 (`validate_release.sh` sort en BLOQUÉ plutôt qu'en faux vert).

### Erreurs commises et corrigées

- Introspection de l'exporter glTF par la mauvaise API : le preset partait vide et
  aucun `.glb` n'était produit. Détecté par le script de validation, pas deviné.
- Dépendance numpy manquante dans le Blender Ubuntu, invisible jusqu'à l'exécution
  réelle de l'export.

Les deux confirment la règle : une chaîne d'outils n'est vérifiée que lorsqu'elle
a réellement tourné.

---

## HANDOFF — prochaine action exacte

> **Prochaine session : Phase A, jalon A.1 — fondation exécutable.**

Avant tout, dans un conteneur neuf :

```bash
tools/setup_godot.sh          # ~60-120 min — LANCER EN ARRIÈRE-PLAN IMMÉDIATEMENT
apt-get install -y blender python3-numpy
tools/env_report.sh           # confirmer les versions obtenues
tools/validate_fast.sh        # doit être vert avant d'écrire la moindre ligne
```

Pendant la compilation, travailler sur ce qui n'exige pas le moteur : données,
documentation, définitions de `Resource`.

Contenu du jalon A.1, dans cet ordre :

1. **InputMap AZERTY** dans `project.godot`, table de §8.5. Vérifier explicitement
   que `Q` est mappé sur « gauche » et **jamais** sur le lock-on.
2. **Couches de collision nommées** (§5.7) : World Static, Player, Enemy, Player
   Hitbox, Enemy Hitbox, Hurtbox, Projectile, Physics Prop, Interactable, Climb
   Probe, Conductive, Water/Danger, Navigation Obstacle, Camera Collision.
   Chaque masque reste minimal.
3. **Autoloads** (§5.6) : `GameState`, `SaveSystem`, `AudioManager`, `SceneFlow`,
   `EventBus`. Ne pas y dupliquer de références fragiles au joueur ou aux ennemis.
4. **Boot réel** (§6.1) remplaçant le placeholder actuel de `scripts/core/boot.gd` :
   `SceneFlow`, `FadeLayer`, `LoadingUI`, overlay debug désactivé en build final.
5. **Tests** : étendre `tests/unit/` — présence et unicité des actions d'entrée,
   cohérence des couches de collision, autoloads chargés.

**Gate A** : le projet ouvre et se lance, zéro parse error, InputMap AZERTY correct.
Le lancer réellement, ne pas se contenter d'un import vert.

### Pièges connus pour la prochaine session

- Ne pas croire un souvenir d'API : la doc en ligne est bloquée, la source du tag
  sous `/opt/src/godot` est la référence. Utiliser l'agent `godot-researcher`.
- Ne pas déclarer Gate A `PASS` sans revue `adversarial-qa` à contexte frais.
- Ne pas commencer la Phase B avant que Gate A soit vert.
