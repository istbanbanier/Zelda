# PROGRESS — journal chronologique et handoff

Ordre **anti-chronologique** : l'entrée la plus récente est en haut. La dernière
entrée fait office de handoff et doit indiquer **exactement** la prochaine action.

---

## 2026-08-01 — A.2 gelé, protocole de validation humaine préparé

**A.2 validé et gelé sur `9414fd0`** par décision du propriétaire.

### Livré

`docs/MANUAL_VALIDATION.md` : protocole en six étapes, écrit pour être exécuté
**sans moi** par une personne disposant d'un écran, d'un clavier AZERTY et d'une
manette. Chaque étape a ses commandes exactes, ses preuves attendues et ses
critères `PASS`/`FAIL` — jamais « vérifier que ça marche ».

`tools/manual_validation_kit.sh` prépare `evidence/gateA/`, y dépose le rapport
d'environnement et un gabarit de rapport à remplir. Son mode `--finalize` écrit un
manifeste (commit, machine, versions, SHA-256 de chaque preuve) et **sort en code 3
tant qu'une preuve manque** — cohérent avec `validate_release.sh`, et empêchant de
clore la campagne sur un dossier incomplet.

`scenes/tests/InputAudit.tscn` : **sans elle, le protocole serait inexécutable.**
À ce stade il n'existe ni joueur ni monde, donc appuyer sur `Q` ne produit rien de
visible. La sonde rend l'InputMap observable et, surtout, interroge la disposition
clavier réelle du système via `DisplayServer.keyboard_get_keycode_from_physical()` :
elle affiche quel nom la disposition courante donne à la position liée à
« gauche ». Sur AZERTY, ce doit être « Q ». L'invariant devient objectif et
capturable, au lieu d'être ressenti.

Quatre tests verrouillent la sonde elle-même : si une action est ajoutée à
l'InputMap sans être ajoutée à la sonde, la validation manuelle testerait un
sous-ensemble sans que personne ne s'en aperçoive.

### État des gates

- **Gate 0** : `GELÉ / ACCEPTÉ AVEC RÉSERVES` (D-006).
- **Gate A** : **`EN ATTENTE`**. Volet automatisable vert — 52 tests. Les six
  contrôles humains sont `NON VÉRIFIÉ`, et `--finalize` le confirme : 13 preuves
  manquantes, code 3.

**La Phase B ne démarre pas.** Elle attend le verdict du Gate A.

---

## 2026-08-01 — Session 1 (suite) — Durcissement du harnais, gel du Gate 0

**Quatre revues adverses à contexte frais, quatre `FAIL`.** Chacune a trouvé des
défauts réels ; trois ont réfuté un correctif de la précédente. C'est le résultat le
plus utile de la Phase 0 : sans elles, un harnais qui ne détectait plus rien aurait
été déclaré vert.

### Défauts corrigés, par revue

- **1re** (D1-D17) : erreur d'exécution comptée « ok » ; test sans reporter avalant
  ses assertions ; `validate_release.sh` vert en sautant des étapes ; capture d'une
  scène vide indiscernable d'une vraie.
- **2e** (N1-N11) : parse error dans un script non référencé → vert ; filtre
  d'erreurs trop étroit (asset supprimé invisible) ; contrat de test contournable ;
  comptage de couleurs ne distinguant pas plein de vide.
- **3e** (B1-B8) : contrat contournable par 3 vecteurs de plus ; `Light3D` compté
  comme géométrie ; perte de couverture par renommage ; fichier de test illisible
  avalé ; « 0 test exécuté » sortant en 0.
- **4e** (Q1-Q8) : `func<TAB>check(` et classe de base intermédiaire échappant au
  scan ; plancher de couverture franchissable par un faux résumé imprimé ; géométrie
  hors champ acceptée ; **deux journaux de preuve produits par une version
  antérieure du code**.

### Les deux corrections de fond

Les tentatives 1 à 3 reposaient sur de l'**inspection statique** — lire le code pour
deviner s'il triche. Toutes ont été contournées. Remplacées par de la **mesure** :

1. **Sonde comportementale du contrat de test** : le runner appelle lui-même les
   quatre méthodes d'assertion et vérifie qu'elles atteignent son enregistreur.
   Ne lit rien, mesure un effet — insensible à la syntaxe et à l'héritage.
2. **Rendu différentiel pour la capture** : la scène est rendue deux fois, dont une
   géométrie masquée, et les images doivent différer. Référence : 1,414 % des pixels.
   Les trois attaques : 0,000 %.

### Décision

D-006 : Gate 0 **gelé, accepté avec réserves** sur décision du propriétaire — pas
`PASS`. La boucle durcissait un harnais contre un auteur de test hostile alors que
le projet n'a aucun gameplay et que son risque dominant est l'art (RSK-01).

### Vérification de clôture (2026-08-01)

| Contrôle | Résultat |
|---|---|
| Arbre Git propre, synchronisé avec l'origine | ✅ |
| `validate_fast.sh` nominal | `RC=0` (compte de tests : voir `docs/TEST_REPORT.md`) |
| `validate_release.sh` nominal | `RC=3` (BLOQUÉ, attendu) |
| Contrat de test — classe de base intermédiaire | `RC=1` ✅ |
| Capture — géométrie hors champ avec ciel | `RC=7`, aucun PNG ✅ |
| Erreur d'exécution dans un test | `RC=1` ✅ |
| Manifeste de capture rattaché à un commit existant | ✅ |

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

> **Gate A : `EN ATTENTE`.** Rien de neuf ne commence avant son verdict.

### Action suivante, et elle n'est pas de mon ressort

Exécuter `docs/MANUAL_VALIDATION.md` sur une machine avec écran, clavier **AZERTY**
et manette. Six étapes, environ une heure hors reconstruction de Godot :

```bash
tools/manual_validation_kit.sh        # prépare evidence/gateA/ et le rapport
# … jouer les six étapes du protocole, déposer les captures …
tools/manual_validation_kit.sh --finalize   # manifeste ; sort en 3 s'il manque une preuve
```

### Ensuite, selon le résultat

- **Six `PASS`** → déclarer Gate A `PASS` dans `STATUS`, `TEST_REPORT` et ici,
  puis démarrer la **Phase B — Traversal**.
- **Un `FAIL`** → ouvrir l'entrée correspondante dans `docs/KNOWN_ISSUES.md` avec
  sa sévérité, corriger, rejouer **la seule étape concernée**, re-conclure.
- **Matériel indisponible** → Gate A reste `EN ATTENTE`. Ne pas le contourner :
  les tests automatiques prouvent qu'une liaison existe dans `project.godot`, pas
  qu'une personne appuyant sur `Q` va vers la gauche.

### Contenu prévu de la Phase B, à ne pas entamer avant le verdict

1. `Player` en `CharacterBody3D`, hiérarchie de §6.2.
2. `CameraRig` : pivots + `SpringArm3D`, `Camera3D` enfant direct (§8.3).
3. Locomotion caméra-relative, valeurs de §8.2, **toute la logique dans
   `_physics_process()`** (§20.9).
4. `StaminaComponent` avant le sprint : §9.1 fixe déjà ses valeurs.
5. Tests : latence d'entrée en ticks, pentes, marches, plafond, caméra ne
   traversant aucun mur.

### Pièges connus

- Doc en ligne bloquée : la source du tag sous `/opt/src/godot` est la référence.
- Un `MainLoop` par `--script` n'a ni autoloads ni `Engine.get_main_loop()` pendant
  `_init()` (D-009) ; le runner compense, ne pas défaire.
- Toute méthode de test avec `await` doit être attendue, **et la boucle appelante
  aussi** (D-010) — sinon des tests disparaissent en silence, suite verte.
- Ne pas faire déclencher un `push_error` de production par un test : isoler la
  décision (modèle `can_go_to()`).
- Relever `MIN_TESTS` dans `tools/validate_fast.sh` à chaque ajout de test.
