# TEST REPORT

Chaque section indique la **commande exacte**, le code retour et le résultat observé.
Un résultat sans commande reproductible ne vaut pas comme preuve (§0.7).

---

## Campagne du 2026-07-31 — Phase 0 / Gate 0

**Environnement** : Ubuntu 24.04.4, Linux 6.18.5 x86_64, 4 cœurs, 15 Gio RAM,
**aucun GPU**, **aucun affichage**.
**Moteur** : Godot 4.7.1-stable, commit `a13da4feb8d8aefc283c3763d33a2f170a18d541`,
compilé sur place (`target=editor`, linuxbsd x86_64).
**Blender** : 4.0.2, exporter `io_scene_gltf2` 4.0.44, numpy 1.26.4.

---

### T-01 — Existence et identité de la version du moteur

```bash
git ls-remote --tags https://github.com/godotengine/godot | grep 4.7.1-stable
```
**Résultat** : `a13da4feb8d8aefc283c3763d33a2f170a18d541  refs/tags/4.7.1-stable`.
`version.py` du tag confirme `major=4 minor=7 patch=1 status="stable"`.
**Verdict** : ✅ PASS — la version exigée par §5.1 existe et est épinglée.

---

### T-02 — Noms des réglages projet vérifiés dans la source

```bash
grep -rn 'physics/3d/physics_engine' /opt/src/godot/servers/physics_3d/physics_server_3d.cpp
grep -rn 'register_server("Jolt Physics"' /opt/src/godot/modules/jolt_physics/register_types.cpp
grep -rn 'rendering/renderer/rendering_method' /opt/src/godot/main/main.cpp
grep -n 'CONFIG_VERSION' /opt/src/godot/core/config/project_settings.h
```
**Résultat** : les quatre clés confirmées (lignes 1163, 59, 2642, 161).
Le module `modules/jolt_physics` est bien présent dans l'arbre source du tag.
**Verdict** : ✅ PASS — `project.godot` n'utilise aucun nom de réglage supposé.

---

### T-03 — Options CLI utilisées par l'outillage

```bash
grep -oE '"--(import|quit-after|quit|headless|check-only|script|path|rendering-driver)"' \
  /opt/src/godot/main/main.cpp | sort -u
```
**Résultat** : les 8 options existent dans 4.7.1.
**Verdict** : ✅ PASS — aucune commande décorative reposant sur un flag inventé.

---

### T-04 — Pipeline Blender → glTF → validation

```bash
tools/blender/run_export.sh
```
**Code retour** : `0`.

`SM_TestCube.glb` (2 520 octets) :

| Contrôle | Attendu | Obtenu |
|---|---|---|
| Format | GLB v2 | GLB v2 ✅ |
| Générateur | Khronos glTF Blender I/O | v4.0.44 ✅ |
| Dimensions | 1 × 1 × 1 m | `[1.0, 1, 1.0]` ✅ |
| Bas au sol (min Y) | ≈ 0 | `0` ✅ |
| Matériaux | 1 nommé | `MAT_TestCube` ✅ |
| Caméras / lumières | 0 | 0 ✅ |
| Triangles | 12 | 12 ✅ |

`SK_TestRigAnim.glb` (16 276 octets) :

| Contrôle | Attendu | Obtenu |
|---|---|---|
| Dimensions | 0,3 × 2 × 0,3 m | `[0.3, 2, 0.3]` ✅ |
| Bas au sol (min Y) | ≈ 0 | `0` ✅ |
| Skin | 1 | 1 ✅ |
| Os | 2 | `bone_root`, `bone_upper` ✅ |
| Animations | 1 nommée | `AN_TestRig_Idle`, 6 canaux / 6 samplers ✅ |
| Caméras / lumières | 0 | 0 ✅ |

**Verdict** : ✅ PASS — la **moitié source** du pipeline (§7.15) est vérifiée :
échelle métrique, conversion Z-up → Y-up, pivot au sol, matériaux nommés, armature
et clip animé traversent correctement l'export.

**Deux défauts réels trouvés et corrigés pendant ce test** :
- ISS-R01 : preset d'export vide dû à une mauvaise API d'introspection.
- ISS-R02 : `numpy` absent du Blender Ubuntu, exporter glTF inutilisable.

Le premier a été détecté parce que la validation a échoué sur fichier manquant —
la chaîne d'outils a fait son travail au lieu de retourner un faux vert.

---

### T-05 — `tools/validate_fast.sh` (niveaux 1-3)

```bash
tools/validate_fast.sh; echo $?
```
**Code retour** : `0` — VERT. Log : `evidence/gate0/validate_fast.log`.

| Niveau | Résultat |
|---|---|
| 0. Version | `4.7.1.stable.custom_build.a13da4feb` ✅ |
| 1. Import / parse smoke | 0 parse error ✅ |
| 2. Tests unitaires et d'intégration | **11 réussis, 0 échoué** ✅ |
| 2b. Erreurs d'exécution dans le journal | aucune ✅ |
| 3. Scène principale | chargée et quittée proprement ✅ |

Sortie relue depuis le moteur en exécution :

```
[boot] Godot            : 4.7.1-stable (custom_build)
[boot] renderer         : forward_plus
[boot] physique 3D      : Jolt Physics
[boot] tick physique    : 60 Hz
```

**Verdict** : ✅ PASS.

---

### T-05c — Import glTF côté moteur (§0.5)

`tests/integration/test_gltf_import.gd`, en headless :

| Contrôle | Obtenu |
|---|---|
| Cube : 1 surface, 1 × 1 × 1 m, base à Y ≈ 0 | ✅ |
| Cube : matériau résolu (aucune surface magenta) | ✅ |
| Rig : `Skeleton3D`, 2 os `bone_root` / `bone_upper` | ✅ |
| Rig : `AnimationPlayer`, `AN_TestRig_Idle`, durée > 0, pistes > 0 | ✅ |
| Rig : hauteur 2,0 m | ✅ |

**Verdict** : ✅ PASS — combiné à T-04, la chaîne Blender → glTF → Godot est
prouvée de bout en bout.

---

### T-05d — Défaut trouvé : Godot tentait d'importer les `.blend`

**Observé** au premier import :
```
ERROR: Blender path is invalid or not set, check your Editor Settings.
   at: query (modules/gltf/editor/editor_scene_importer_blend.cpp:552)
```
**Cause** : `source_assets/` étant dans le dossier du projet, Godot voulait importer
les `.blend` via Blender — la dépendance de poste que D-003 interdit.
**Correctif** : `.gdignore` dans `source_assets/`, `docs/`, `evidence/`, `builds/`.
**Verdict** : ✅ corrigé, couvert par le niveau 1.

---

### T-06 — Capture depuis le renderer réel

```bash
tools/validate_release.sh; echo $?
```
**Code retour** : `3` — **BLOQUÉ**, et c'est le résultat correct : le niveau 5
réussit mais les niveaux 4, 6 et 7 ne sont pas exécutés, donc le script ne retourne
pas vert.

Le niveau 5 lui-même **réussit** — la capture fonctionne, contrairement à
l'hypothèse initiale de R-004. Manifeste `evidence/captures/pipeline_lab.json` :

| Champ | Valeur |
|---|---|
| Scène | `res://scenes/tests/PipelineLab.tscn` |
| Résolution | 1920 × 1080, 40 frames attendues |
| Méthode de rendu | `forward_plus` |
| Pilote | `llvmpipe (LLVM 20.1.2, 256 bits)` |
| Couleurs distinctes (échantillon) | 705 |
| Écart-type de luminance | 0,1988 |
| Commit | inscrit dans le manifeste |

**Contenu vérifié à l'image** : cube ocre et cylindre turquoise rendus, éclairés,
proportions 1 m / 2 m, matériaux corrects, aucune surface magenta.

**Limites maintenues** :
- llvmpipe est un rendu **logiciel** : aucune mesure de performance n'en découle
  (§20.1) ; `docs/PERFORMANCE.md` reste sans mesure.
- Prouve le **pipeline**, pas la qualité artistique. Le WOW Gate reste **non noté** :
  il n'existe aucune scène North Star.
- Aucun périphérique audio (ISS-004) : test audio impossible ici.

**Verdict** : ✅ PASS pour le pipeline de capture · ⛔ gates visuel et performance
toujours BLOQUÉS.

---

### T-08 — Contrôles négatifs du harnais (suite à la revue adverse)

La première revue adverse du Gate 0 a rendu **FAIL** en démontrant que le harnais
pouvait rester vert alors qu'il ne détectait plus les échecs. Chaque défaut est
maintenant verrouillé par un contrôle négatif rejoué :

| Défaut | Scénario injecté | Attendu | Obtenu |
|---|---|---|---|
| D2 | erreur d'exécution GDScript (déréférencement nul) dans un test | ROUGE | `RC=1`, « erreurs d'exécution dans la suite unitaire » ✅ |
| D3 | fichier de test n'étendant pas `GateTestCase` | ÉCHEC | `RC=1`, « doit étendre GateTestCase » ✅ |
| — | méthode `test_*` n'exécutant aucune assertion | ÉCHEC | `RC=1`, « aucune assertion exécutée (couverture illusoire) » ✅ |
| D6 | capture d'une scène **vide** (Node3D nu) | ÉCHEC | `RC=4`, « image uniforme (1 couleur) », **aucun PNG écrit** ✅ |
| D5 | `validate_release.sh` sautant les niveaux 4/6/7 | BLOQUÉ | `RC=3` ✅ |
| — | retour à l'état nominal | VERT | `RC=0` ✅ |

**Correctifs structurels** :
- `tests/test_case.gd` (`GateTestCase`) : le câblage du reporter n'est plus du
  boilerplate recopiable, donc plus oubliable. Le runner **refuse** tout test hors
  de ce contrat.
- Le runner compte les assertions par méthode et échoue si une méthode n'en
  exécute aucune.
- `validate_fast.sh` inspecte le journal à la recherche de `SCRIPT ERROR` : un test
  ne peut plus « réussir » en levant une erreur d'exécution.
- `capture_reference.gd` analyse le contenu de l'image et refuse une image uniforme.
- Le manifeste de capture porte désormais `commit` et `repo_dirty` (défaut D7).
- `tests/unit/test_harness_contract.gd` teste le harnais lui-même.

**Défaut trouvé dans mes propres correctifs** : la première version de
`test_check_counts_assertions` était fausse d'une unité (elle comparait le compteur
avant l'incrément de sa propre assertion) et faisait échouer la suite. Corrigée,
puis re-vérifiée.

**Verdict** : ✅ PASS — le harnais peut désormais rougir sur chacune des classes
d'échec identifiées.

---

### T-07 — Reprise par une session neuve (critère Gate 0)

Protocole : un lecteur ne disposant que du dépôt doit savoir, en moins de 5 minutes,
où en est le projet et quelle est l'action suivante.

Chaîne vérifiée : `CLAUDE.md` (démarrage, commandes, invariants) → `docs/STATUS.md`
(état par fonctionnalité avec preuve) → `docs/PROGRESS.md` (handoff nommant
explicitement le jalon A.1 et ses cinq étapes) → `docs/KNOWN_ISSUES.md` (blocages
connus) → `docs/BUILD_ENVIRONMENT.md` (comment reconstruire l'environnement).

**Limite honnête** : ce critère a été vérifié par relecture de la chaîne
documentaire, **pas** par une session réellement repartie de zéro. Il reste donc
`PASS sous réserve` jusqu'à ce qu'une session neuve l'exerce réellement — ce qui
sera le premier acte de la prochaine session.
