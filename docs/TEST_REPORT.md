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
tools/validate_fast.sh
```
**Code retour** : `0` — VERT. Log : `evidence/gate0/validate_fast.log`.

| Niveau | Résultat |
|---|---|
| 0. Version | `4.7.1.stable.custom_build.a13da4feb` ✅ |
| 1. Import / parse smoke | 0 parse error, code retour 0 ✅ |
| 2. Tests unitaires | **8 réussis, 0 échoué** ✅ |
| 3. Scène principale | chargée et quittée proprement ✅ |

Sortie de la scène principale, relue depuis le moteur en exécution :

```
[boot] Godot            : 4.7.1-stable (custom_build)
[boot] renderer         : forward_plus
[boot] physique 3D      : Jolt Physics
[boot] tick physique    : 60 Hz
```

**Verdict** : ✅ PASS.

---

### T-05b — Contrôle négatif : le runner détecte-t-il réellement un échec ?

Un test incapable d'échouer ne prouve rien. Un cas d'échec délibéré a été ajouté
temporairement, puis retiré.

| Situation | Code retour attendu | Obtenu |
|---|---|---|
| Avec le test fautif | non nul | `1` ✅ (`8 réussis, 1 échoué`) |
| Après retrait | `0` | `0` ✅ |

**Verdict** : ✅ PASS — la suite peut échouer, donc son vert a une valeur.

---

### T-05c — Import glTF côté moteur (§0.5)

Couvert par `tests/integration/test_gltf_import.gd`, exécuté en headless :

| Contrôle | Obtenu |
|---|---|
| Cube : 1 surface, arêtes 1 × 1 × 1 m, base à Y ≈ 0 | ✅ |
| Cube : matériau résolu (aucune surface rose) | ✅ |
| Rig : `Skeleton3D` avec 2 os `bone_root` / `bone_upper` | ✅ |
| Rig : `AnimationPlayer` avec `AN_TestRig_Idle`, durée > 0, pistes > 0 | ✅ |
| Rig : hauteur 2,0 m | ✅ |

**Verdict** : ✅ PASS — la moitié **moteur** du pipeline est vérifiée. Combinée à
T-04, la chaîne Blender → glTF → Godot est prouvée de bout en bout.

---

### T-05d — Défaut trouvé : Godot tentait d'importer les `.blend`

**Observé** au premier import :
```
ERROR: Blender path is invalid or not set, check your Editor Settings.
Cannot configure blender path in headless mode.
   at: query (modules/gltf/editor/editor_scene_importer_blend.cpp:552)
```
**Cause** : `source_assets/` est dans le dossier du projet ; Godot y a trouvé les
`.blend` et a voulu les importer via Blender — exactement la dépendance de poste
que D-003 interdit.
**Correctif** : `.gdignore` dans `source_assets/`, `docs/`, `evidence/` et `builds/`.
**Après correctif** : import sans aucune erreur ni avertissement.
**Verdict** : ✅ corrigé et couvert par le niveau 1 de `validate_fast.sh`.

---

### T-06 — Capture depuis le renderer réel

```bash
tools/validate_release.sh
```
**Code retour** : `0`.

**Résultat : la capture fonctionne**, contrairement à l'hypothèse initiale (R-004).
Godot rend en **Forward+** via **Mesa llvmpipe** (rastériseur logiciel) sous Xvfb.

| Champ du manifeste | Valeur |
|---|---|
| Scène | `res://scenes/tests/PipelineLab.tscn` |
| Résolution | 1920 × 1080 |
| Frames attendues | 40 |
| Moteur | 4.7.1-stable (custom_build) |
| Méthode de rendu | `forward_plus` |
| Pilote | `llvmpipe (LLVM 20.1.2, 256 bits)` |
| Serveur d'affichage | X11 (Xvfb) |

Preuves : `evidence/captures/pipeline_lab.png` + `pipeline_lab.json`,
`evidence/gate0/pipeline_lab.png`.

**Contenu vérifié à l'image** : le cube ocre (`MAT_TestCube`) et le cylindre
turquoise rigué (`MAT_TestRig`) sont rendus, éclairés, aux bonnes proportions et
avec leurs matériaux — aucune surface magenta. La chaîne Blender → glTF → import →
**renderer réel** → PNG est donc close.

**Limites explicitement maintenues** :
- llvmpipe est un rendu **logiciel**. Aucune mesure de performance ne peut en être
  tirée (§20.1) ; les budgets de `docs/PERFORMANCE.md` restent **non mesurés**.
- Cette capture prouve le **pipeline**, pas la qualité artistique. Le WOW Gate reste
  **non noté** : il n'existe aucune scène North Star à évaluer.
- Défaut d'environnement constaté : aucun périphérique ALSA
  (`ERR_CANT_OPEN` sur `audio_driver_alsa.cpp:97`), Godot se rabat sur le pilote
  audio muet. Contourné par `--audio-driver Dummy`. Le test audio réel (§18) devra
  se faire ailleurs.

**Verdict** : ✅ PASS pour le pipeline de capture · ⛔ les gates visuels et de
performance restent BLOQUÉS faute de GPU et de contenu à évaluer.

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
