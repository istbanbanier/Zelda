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
| 1. Import des ressources | 0 erreur ✅ |
| 1b. Parse de **tous** les `.gd` (`--check-only`, syntaxe et typage statique) | 8 scripts, 0 erreur ✅ |
| 2. Tests unitaires et d'intégration | **13 réussis, 0 échoué** ✅ |
| 2b. Erreurs signalées dans le journal (`ERROR:` inclus) | aucune ✅ |
| 3. Scène principale | chargée et quittée proprement ✅ |
| 4. Plancher de couverture | 13 tests pour un plancher de 13 ✅ |

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
| Géométrie | géométries visibles comptées après stabilisation, minimum exigé 1 (obtenu : 2) |
| Couleurs distinctes (échantillon) | 705 |
| Écart-type de luminance | 0,1988 |
| Commit | inscrit dans le manifeste, capture refusée s'il est indéterminé |

**Contenu vérifié à l'image** : cube ocre et cylindre turquoise rendus, éclairés,
proportions 1 m / 2 m, matériaux corrects, aucune surface magenta.

**Ce que les statistiques ne prouvent pas** : couleurs distinctes et écart-type
détectent une image *uniforme*, pas une image *fausse* ni une image *vide de
contenu utile* — la 3e revue a produit 906 couleurs avec un simple ciel. Le
comptage de géométrie visible (T-09) ferme ce cas précis. Juger qu'un rendu est
*correct* exigera la comparaison à une image de référence (§21.8), non encore
construite faute de contenu.

**Limites maintenues** :
- llvmpipe est un rendu **logiciel** : aucune mesure de performance n'en découle
  (§20.1) ; `docs/PERFORMANCE.md` reste sans mesure.
- Prouve le **pipeline**, pas la qualité artistique. Le WOW Gate reste **non noté** :
  il n'existe aucune scène North Star.
- Aucun périphérique audio (ISS-004) : test audio impossible ici.

**Verdict** : ✅ PASS pour le pipeline de capture · ⛔ gates visuel et performance
toujours BLOQUÉS.

---

### T-08 — Contrôles négatifs du harnais (après DEUX revues adverses)

Les deux revues adverses du Gate 0 ont rendu **FAIL**, chacune en démontrant que le
harnais pouvait rester vert alors qu'il ne détectait plus les échecs. La seconde a
notamment cassé les correctifs de la première. Chaque défaut est désormais verrouillé
par un contrôle négatif **rejoué et archivé** dans `evidence/gate0/negative_controls/`.

| Défaut | Scénario injecté | Attendu | Obtenu |
|---|---|---|---|
| D2 | erreur d'exécution GDScript dans un test | ROUGE | `RC=1` ✅ |
| D3 | fichier de test n'étendant pas `GateTestCase` | ÉCHEC | `RC=1` ✅ |
| — | méthode `test_*` sans aucune assertion | ÉCHEC | `RC=1` ✅ |
| D5 | `validate_release.sh` sautant les niveaux 4/6/7 | BLOQUÉ | `RC=3` ✅ |
| D6 | capture d'une scène vide (Node3D nu) | ÉCHEC | `RC=4`, aucun PNG ✅ |
| **N9** | parse error dans un script **non référencé** | ROUGE | `RC=1`, « 1 script en erreur de parsing sur 8 » ✅ |
| **N1** | ressource manquante + `push_error` dans un test | ROUGE | `RC=1`, « erreurs signalées pendant la suite » ✅ |
| **N3** | test redéfinissant `set_reporter()` et `get_check_count()` pour masquer 2 assertions fausses | ÉCHEC | `RC=1`, les 2 échecs remontés ✅ |
| **N4** | capture d'une scène **sans géométrie** (ciel + caméra) | ÉCHEC | `RC=5`, « 0 VisualInstance3D », aucun PNG ✅ |
| **N5** | capture avec `git` indisponible | ÉCHEC | `RC=6`, aucun PNG ✅ |
| **N2** | test déposé dans `tests/playthrough/` | collecté | `RC=1`, échec remonté ✅ |
| — | retour à l'état nominal | VERT | `RC=0`, **12 tests** ✅ |

**Correctifs structurels de la seconde passe** :
- **N9** : nouveau niveau `1b` — chaque `.gd` du dépôt est parsé individuellement
  avec `--check-only`. L'import ne parse que les scripts atteignables ; la promesse
  « parse smoke » était fausse pour tout script non référencé.
- **N1** : le filtre d'erreurs du niveau 2 couvre désormais `ERROR:` générique, au
  lieu d'une liste de messages précis qui laissait passer ressource manquante,
  `push_error` et échec de chargement.
- **N3** : *(cette correction a été réfutée par la 3e revue — voir T-09)*.
- **N4** : *(cette correction a été réfutée par la 3e revue — voir T-09)*.
- **N5** : la capture échoue si le commit est indéterminé, **avant** toute écriture
  (la première correction laissait un PNG orphelin sans manifeste).
- **N2** : `tests/playthrough` ajouté aux racines collectées.

**Honnêteté sur ce que T-08 ne prouve pas** : ces contrôles montrent que le harnais
rougit sur les classes d'échec **identifiées à ce jour**. Ils ne démontrent pas
qu'il n'en reste aucune autre — les deux revues successives sont précisément la
preuve du contraire. La comparaison d'images de référence (§21.8), seule capable de
juger qu'un rendu est *correct* et pas seulement *non vide*, reste à construire
quand il y aura du contenu à comparer.

---

### T-09 — Troisième revue adverse : deux correctifs réfutés, huit défauts nouveaux

La 3e revue a démontré que **deux** correctifs de la passe précédente ne tenaient pas,
et en a trouvé huit autres. Ce tableau remplace les affirmations correspondantes de
T-08, qui étaient fausses.

| Défaut | Ce qui était affirmé à tort | Ce que la revue a démontré | Correctif |
|---|---|---|---|
| N3 | « le contrat n'est plus contournable en redéfinissant une méthode » | 3 vecteurs : redéfinir `check()` (les helpers l'appellent en dispatch virtuel) ; `_failures.clear()` ; `_checks += 42`. `check_equal(2, 3)` passait **vert**. | La comptabilité sort du cas de test : `GateTestRecorder`, créé et lu par le runner seul. Le runner **refuse** tout fichier qui déclare localement une méthode du contrat. |
| N4 | « le comptage des `VisualInstance3D` garantit la géométrie attendue » | `Light3D` **est** un `VisualInstance3D` → scène ciel + soleil acceptée, 906 couleurs. Idem `MeshInstance3D` sans maillage, et vrai cube sous parent masqué (`visible` local ≠ `is_visible_in_tree()`). | Seules comptent les `GeometryInstance3D` **visibles dans l'arbre** et porteuses d'une ressource réelle. Comptage déplacé après stabilisation. |
| B1 | — | Renommer un fichier de test faisait disparaître 3 tests, suite **verte**. | Plancher de couverture (`MIN_TESTS`) au niveau 4. |
| B2 | — | Un fichier de test illisible était avalé, runner **RC=0**. | `script.can_instantiate()` vérifié avant `new()`. |
| B3 | — | « 0 réussi, 0 échoué » sortait en **RC=0**. | Une exécution sans aucun test est un échec. |
| B4 | « parse réel » | `--check-only` ne résout pas les appels dynamiques : `n.methode_inexistante()` passe. | Aucune correction possible à ce niveau — **limite désormais écrite** dans le script et ici. Le niveau 1b vérifie la syntaxe et le typage statique, rien de plus. |
| B5 | — | `tests/playthrough/` n'existait pas dans HEAD : le correctif N2 était inerte sur un clone frais. | `.gitkeep` versionné. |
| B6 | — | Les journaux archivés ne portaient pas les codes retour revendiqués. | Chaque contrôle négatif archive maintenant son `RC=` en fin de fichier. |
| B7 | — | Affirmations réfutées dans `TEST_REPORT` et `tests/test_case.gd`. | Corrigées ici et dans le code. |
| B8 | — | `STATUS` classait « image de référence » en `Validé` alors qu'elle n'est pas versionnée. | Ramené à `NON VÉRIFIÉ`. |

#### Contrôles négatifs rejoués et archivés (`evidence/gate0/negative_controls/`)

| Scénario | Attendu | Obtenu |
|---|---|---|
| N3 v1 — redéfinition de `check()` | ÉCHEC | `RC=1`, « redéfinit des méthodes du contrat (check) » ✅ |
| N3 v2 — effacement des échecs | ÉCHEC | `RC=1`, l'échec remonte ✅ |
| N3 v3 — gonflement du compteur | ÉCHEC | `RC=1`, l'assertion fausse remonte ✅ |
| N4a — ciel + caméra + lumière seule | ÉCHEC | `RC=5`, « 0 géométrie visible », aucun PNG ✅ |
| N4b — `MeshInstance3D` sans maillage | ÉCHEC | `RC=5`, aucun PNG ✅ |
| N4c — cube sous parent masqué | ÉCHEC | `RC=5`, aucun PNG ✅ |
| B1 — renommage d'un fichier de test | ÉCHEC | `RC=1`, « 10 tests pour un plancher de 13 » ✅ |
| B2 — fichier de test illisible | ÉCHEC | `RC=1`, aux niveaux 1b **et** 2 ✅ |
| nominal | VERT | `RC=0`, **13 tests** ✅ |

#### Limite que je n'essaie plus de masquer

Le harnais arrête la **perte de signal accidentelle** — câblage oublié, refactor,
fichier renommé, asset supprimé — et les vecteurs précisément démontrés. Il
n'arrête pas un auteur de test qui mentirait délibérément : il reste possible de
remplacer l'enregistreur depuis une méthode de test. Trois revues ont chacune
réfuté une affirmation d'exhaustivité ; cette section n'en formule donc aucune.

---

### T-10 — Quatrième revue adverse : N3 et N4 rouverts, intégrité des preuves en défaut

La 4e revue a rouvert deux défauts que je croyais fermés, et relevé que deux de mes
propres journaux de preuve ne provenaient pas du code qu'ils prétendaient valider.

| Défaut | Ce qui était affirmé à tort | Démonstration | Correctif |
|---|---|---|---|
| Q1 | « le runner refuse tout fichier qui déclare une méthode du contrat » | `func<TAB>check(` est du GDScript valide et échappait au scan, qui testait `begins_with("func ")` avec un espace littéral. `check_equal(2, 3)` passait **vert**. | Regex tolérant tout blanc et `static`. |
| Q2 | idem | Le scan ne lisait que le fichier de test : une **classe de base intermédiaire** (nommée hors du motif `test_*`, donc jamais collectée) redéfinissait `check()` sans être vue. C'est exactement la classe « refactor » que le harnais prétendait couvrir. | Remontée de la chaîne `get_base_script()` **et**, surtout, sonde comportementale. |
| Q3 | « le plancher exige une modification explicite du fichier » | `head -1` prenait la **première** ligne `=== RÉSULTAT`, qu'un test pouvait imprimer lui-même : 9 tests réels, « 99 » annoncés, VERT. `MIN_TESTS=0` en variable d'environnement suffisait aussi. | `tail -1`, refus des lignes en double, plancher devenu constante non surchargeable. |
| Q4 | « le comptage de géométrie visible ferme ce cas » | Le comptage porte sur l'**arbre de scène**, jamais sur ce que la caméra voit. Cube à z=9000 ou à l'échelle nulle → **RC=0**, PNG de ciel pur, 1087 couleurs distinctes. | Rendu différentiel : la scène est rendue une seconde fois géométrie masquée, et les deux images doivent différer. |
| Q5 | « tous les fichiers de preuve ont été produits après ce commit » | Deux journaux contenaient une chaîne (`VisualInstance3D`) supprimée du code deux commits plus tôt. Ils validaient une version antérieure. | **Tous** les contrôles négatifs régénérés avec le code courant. |
| Q6 | `evidence/gate0/README.md` republiait le critère `VisualInstance3D` | Contredisait le code et T-09. | Corrigé. |
| Q7 | « chaque journal se termine par `RC=` » | `nominal_validate_release.log` n'en portait aucun. | Vérifié fichier par fichier : 18/18. |
| Q8 | `STATUS` justifiait « Validé » par T-08 | Les lignes N3 et N4 de T-08 avaient été rétractées par T-09. | Ramené à `Fonctionnel`, preuve = T-10. |

#### La correction de fond sur le contrat de test

Les trois tentatives précédentes reposaient sur une inspection *statique* :
« ce fichier déclare-t-il `check()` ? ». Trois revues l'ont contournée (méthode
redéfinie, membres manipulés, tabulation, classe de base). L'inspection statique
est remplacée par une **sonde comportementale** exécutée avant chaque fichier :
le runner injecte un enregistreur neuf, appelle lui-même les quatre méthodes du
contrat et vérifie que **quatre** assertions parviennent bien à cet enregistreur.
Aucune astuce de syntaxe ni chaîne d'héritage ne passe ce contrôle, parce qu'il ne
lit rien : il mesure un effet.

#### La correction de fond sur la capture

Même logique. Compter des nœuds répond à « la scène contient-elle de la
géométrie ? », jamais à « cette géométrie apparaît-elle à l'image ? ». La capture
rend donc la scène **deux fois** — normalement, puis géométrie masquée — et exige
que les deux images diffèrent d'au moins 0,2 % des pixels échantillonnés. Sur la
scène de référence : **1,414 %**. Sur les trois attaques de la revue : **0,000 %**.

#### Contrôles négatifs rejoués (`evidence/gate0/negative_controls/`, 18 journaux)

| Scénario | Attendu | Obtenu |
|---|---|---|
| Q1 — `func<TAB>check(` | ÉCHEC | `RC=1` ✅ |
| Q2 — classe de base intermédiaire | ÉCHEC | `RC=1` ✅ |
| Q3 — faux résumé imprimé par un test | ÉCHEC | `RC=1`, « 2 lignes === RÉSULTAT » ✅ |
| Q4a/b/c — géométrie hors champ, échelle nulle, derrière la caméra, **avec ciel** | ÉCHEC | `RC=7`, contribution 0,000 %, aucun PNG ✅ |
| Q4a/b/c — mêmes scènes **sans ciel** | ÉCHEC | `RC=4` (uniformité), aucun PNG ✅ |
| D2, D3, N1, N9, N3v2, B1, B2 | ÉCHEC | `RC=1` ✅ |
| nominal | VERT / BLOQUÉ | `RC=0` (13 tests) / `RC=3` ✅ |

#### Ce que je n'affirme toujours pas

Quatre revues, quatre `FAIL`, et trois d'entre elles ont réfuté un correctif de la
précédente. Aucune affirmation d'exhaustivité n'est faite ici. Les limites connues
et assumées : un auteur de test peut encore remplacer l'enregistreur depuis une
méthode de test ; `--check-only` ne résout pas les appels dynamiques ; le contrôle
de contribution prouve que la géométrie apparaît, **pas** qu'elle apparaît
correctement — cela exigera la comparaison à une image de référence (§21.8), qui
n'a pas de sens tant qu'il n'y a pas de contenu à comparer.

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

---

# Jalon B.1 — Player, CameraRig, locomotion (2026-08-01)

## Commande et résultat

```bash
tools/validate_fast.sh; echo $?
```

**Code retour** : `0` — VERT.

| Niveau | Résultat |
|---|---|
| 0. Version | `4.7.1.stable.custom_build.a13da4feb` ✅ |
| 1. Import des ressources | 0 erreur ✅ |
| 1b. Parse de **tous** les `.gd` | 0 erreur ✅ |
| 2. Tests unitaires et d'intégration | **80 réussis, 0 échoué** ✅ |
| 2b. Erreurs signalées dans le journal | aucune ✅ |
| 3. Scène principale (Boot → MainMenu, lancement réel) | ✅ |
| 4. Plancher de couverture | 80 tests pour un plancher de 80 ✅ |

> **Nombre de tests de référence : 80.** C'est ici, et nulle part ailleurs, qu'il
> doit être lu. Un chiffre recopié dans un autre document diverge au premier ajout.

Nouveaux fichiers de test : `tests/integration/test_locomotion.gd` (12 cas) et
`tests/integration/test_camera_rig.gd` (9 cas). Tous pilotent le contrôleur par
`InputIntent` injectée — **aucune touche simulée**, aucun périphérique requis.

## Contrôles négatifs rejoués

Un test qui ne peut pas échouer ne prouve rien. Chaque défense de B.1 a été cassée
volontairement, la suite relancée, l'état restauré.

| # | Mutation appliquée | Test visé | Résultat attendu | Obtenu |
|---|---|---|---|---|
| C1 | Épaule reposée sur la `Camera3D` (le défaut d'origine) | `test_shoulder_offset_survives_the_spring_arm` | ÉCHEC | ÉCHEC ✅ |
| C2 | Sonde volumique retirée (retour au rayon simple) | `test_spring_arm_pulls_the_camera_in_front_of_a_wall` | ÉCHEC | ÉCHEC ✅ |
| C3 | Interpolation FOV à poids fixe (0,08) | `test_fov_interpolation_is_framerate_independent` | ÉCHEC | ÉCHEC ✅ |
| C4 | Interpolation FOV à poids 1,0 (snap franc) | `test_fov_widens_on_sprint_without_snapping` | ÉCHEC | ÉCHEC — « progression de 6.00° » ✅ |
| C5 | Butées de pitch supprimées | `test_pitch_is_clamped_to_the_specified_range` | ÉCHEC | ÉCHEC — « butée basse franchie : -14332.5° » ✅ |
| C6 | `max_floor_angle_deg` relevé à 70° **dans le `.tres`** | `test_steep_slope_is_rejected` | ÉCHEC | ÉCHEC — « Y 0.00 -> 4.31 » ✅ |
| C7 | Nœud intercalé sous le `SpringArm3D` | `test_camera_is_a_direct_child_of_the_spring_arm` | ÉCHEC | ÉCHEC — « parent réel : Intercale » ✅ |
| C8 | Caméra petite-fille décalée de 1 m sur l'axe du bras | `test_spring_arm_pulls_the_camera_in_front_of_a_wall` | ÉCHEC | ÉCHEC — « dégagement -0,638 m » ✅ |

Logs archivés : `evidence/gateB/negative_controls/C1…C8*.log`. Après chaque
contrôle, les fichiers mutés ont été restaurés et comparés à l'octet près à leur
état d'origine avant de passer au suivant.

### Deux enseignements que ces contrôles ont produits, et qui ne sont pas cosmétiques

- **C6 a d'abord donné un faux négatif.** La mutation portait sur la valeur par
  défaut de `@export` dans `locomotion_tuning.gd` ; le test est resté vert et se
  lisait « le test ne mesure pas ce qu'il prétend ». La ressource réellement
  chargée est `locomotion_default.tres`, qui sérialise sa propre valeur. Règle
  adoptée : muter la ressource chargée, jamais la valeur par défaut du script
  (R-006bis).
- **C7 a réfuté la justification écrite dans le code.** Le commentaire affirmait
  qu'une caméra non-enfant-direct « traverserait les murs ». Faux : avec un nœud
  intercalé à position nulle, l'anti-traversée tient toujours. Le vrai mécanisme,
  isolé par C8, est qu'un descendant conserve un décalage dont le cast ne tient pas
  compte. Le commentaire et l'en-tête du test ont été corrigés pour dire ce qui a
  été mesuré (R-006ter, D-014).

## Défauts réels trouvés pendant B.1

| # | Défaut | Comment il a été trouvé | Correctif |
|---|---|---|---|
| B1-1 | Rampe de test en **boîte tournée** : sa face basse formait un surplomb, la capsule passait **sous** la rampe au lieu de la gravir. `is_on_floor()` vrai, `is_on_wall()` faux, aucun drapeau ne signalait l'anomalie. | sonde imprimant position et drapeaux à chaque tick | rampes reconstruites en **prismes pleins** (`ConvexPolygonShape3D`), sans dessous |
| B1-2 | Décalage d'épaule de 0,32 m **silencieusement perdu** : `SpringArm3D` réécrit la position de ses enfants directs. §8.3 n'était pas tenu, sans aucun signe. | sonde relisant `camera.position` après quelques frames | décalage porté par le bras (D-014) |
| B1-3 | Caméra s'arrêtant à **0,8 mm** de la face du mur — techniquement en deçà, visuellement dedans. | assertion de dégagement, initialement écrite en `< 29.75` : passait sur la frontière exacte | sonde volumique (D-015) |

## Limites de B.1 — à ne pas confondre avec des oublis

- **Le sprint n'a aucun coût.** `StaminaComponent` (§9.1) arrive en B.2. Écrit dans
  l'en-tête de `player_controller.gd`, pas seulement ici.
- **Le ressenti n'est pas testé.** §10.6 exige des mesures de latence en ticks et un
  essai humain ; rien d'automatique ne les remplace.
- **L'absence de jitter caméra n'est pas testée.** La traversée l'est ; le jitter
  demande une observation en mouvement à framerate réel.
- **Aucun modèle, aucune animation.** `VisualRoot` est un `Node3D` vide qui
  s'oriente. §7.14 interdit d'appeler « personnage » un pivot nu.
- **CONTROLLER-001 reste ouverte.** B.1 est intégralement piloté par intention
  injectée : cela prouve que le contrôleur n'exige pas de clavier, **jamais** que la
  manette fonctionne.

---

# Jalon B.2 — Endurance (2026-08-01)

## Commande et résultat

```bash
tools/validate_fast.sh; echo $?
```

**Code retour** : `0` — VERT.

| Niveau | Résultat |
|---|---|
| 0. Version | `4.7.1.stable.custom_build.a13da4feb` ✅ |
| 1 / 1b. Import et parse de **tous** les `.gd` | 0 erreur ✅ |
| 2. Tests unitaires et d'intégration | **100 réussis, 0 échoué** ✅ |
| 2b. Erreurs signalées dans le journal | aucune ✅ |
| 3. Scène principale (Boot → MainMenu, lancement réel) | ✅ |
| 4. Plancher de couverture | 100 tests pour un plancher de 100 ✅ |

> **Nombre de tests de référence : 100.** C'est ici, et nulle part ailleurs, qu'il
> doit être lu.

Nouveau fichier : `tests/unit/test_stamina.gd` (15 cas, delta piloté à la main,
aucun tick physique). 5 cas ajoutés à `tests/integration/test_locomotion.gd` pour
le câblage réel au contrôleur.

## Défaut réel trouvé pendant B.2

**Le sprint bégayait au lieu de repartir.** L'implémentation littérale de §9.1
levait l'épuisement dès que la jauge repassait au-dessus de zéro. Sprint maintenu :
la régénération démarre après 1 s, la première unité rendue relance le sprint pour
**un seul tick** (0,017 s), la jauge se revide, l'épuisement revient.
`test_reaching_zero_raises_exhaustion_once` a compté **7 émissions du signal en
15 secondes** au lieu d'une.

Ce n'était pas visible en relisant le code : chaque ligne respectait §9.1. C'est le
test qui a nommé le défaut, et le comptage de signaux qui l'a rendu lisible.

Correctif : seuil de récupération (D-016), hors §9.1 donc explicitement marqué
comme valeur du projet, à confirmer par un essai humain (§21.9).

## Contrôles négatifs rejoués

| # | Mutation appliquée | Test visé | Obtenu |
|---|---|---|---|
| N1 | le sprint n'appelle plus `try_sustain()` | `test_sprint_drains_stamina` | ÉCHEC — « obtenu 0.0000 » ✅ |
| N2 | `can_sustain()` ignore épuisement et réserve | `test_exhaustion_drops_the_sprint_back_to_running` | ÉCHEC — « obtenu 9.0000 » ✅ |
| N3 | seuil de récupération retiré (**le défaut d'origine**) | `test_a_held_sprint_produces_usable_bursts_not_a_stutter` | ÉCHEC — « 0.017 s (un tick = 0.017 s) » ✅ |
| N4 | régénération au régime nominal dès la première image | `test_regeneration_ramps_in_instead_of_snapping` | ÉCHEC ✅ |
| N5 | délai de régénération ignoré | `test_regeneration_waits_the_declared_delay` | ÉCHEC — « obtenu 93.78 » ✅ |
| N6 | `exhaustion_lockout` mis à 0 **dans le `.tres`** | `test_the_exhaustion_lockout_refuses_an_otherwise_affordable_cost` | ÉCHEC ✅ |
| N7 | `try_spend()` prélève malgré le refus | `test_an_unaffordable_cost_is_refused_and_consumes_nothing` | ÉCHEC — « obtenu 0.0000 » ✅ |
| N8 | `has_move()` retiré : le sprint immobile consomme | `test_holding_sprint_while_standing_still_costs_nothing` | ÉCHEC — « obtenu 88.0000 » ✅ |

Logs archivés : `evidence/gateB/negative_controls/N1…N8*.log`. Fichiers mutés
restaurés et comparés à l'octet près entre chaque contrôle.

N6 mute la ressource et non la valeur par défaut du `@export`, conformément à la
règle tirée de B.1 (R-006bis) — muter le script n'aurait rien cassé.

## Limites de B.2 — à ne pas confondre avec des oublis

- **Les coûts d'escalade, d'esquive et d'attaque lourde sont déclarés, pas
  consommés.** §9.1 les fixe ; les câbler sans escalade ni combat serait du code
  mort. `docs/STATUS.md` dit lequel est actif.
- **Aucune jauge à l'écran.** Les signaux `changed` / `exhausted` / `recovered`
  sont émis et attendent l'UI de §17.2.
- **Ni souffle ni animation d'épuisement** (§9.1, §18.2) : aucun périphérique audio
  ici (ISS-004), aucune animation avant la Phase H.
- **Le seuil de récupération n'est pas validé par un joueur.** 20 est un point de
  départ raisonné, pas une mesure de ressenti (§21.9).
- **CONTROLLER-001 reste ouverte.**

---

# Jalon B.3 — Escalade et mantle (2026-08-01)

## Commande et résultat

```bash
tools/validate_fast.sh; echo $?
```

**Code retour** : `0` — VERT.

| Niveau | Résultat |
|---|---|
| 0. Version | `4.7.1.stable.custom_build.a13da4feb` ✅ |
| 1 / 1b. Import et parse de **tous** les `.gd` | 0 erreur ✅ |
| 2. Tests unitaires et d'intégration | **124 réussis, 0 échoué** ✅ |
| 2b. Erreurs signalées dans le journal | aucune ✅ |
| 3. Scène principale (Boot → MainMenu, lancement réel) | ✅ |
| 4. Plancher de couverture | 124 tests pour un plancher de 124 ✅ |

> **Nombre de tests de référence : 124.** C'est ici, et nulle part ailleurs, qu'il
> doit être lu.

Nouveaux fichiers : `tests/integration/test_climbing.gd` (14 cas) et
`tests/unit/test_action_alignment.gd` (9 cas).

## Quatre défauts réels trouvés pendant B.3

| # | Défaut | Comment il a été trouvé | Correctif |
|---|---|---|---|
| B3-1 | **Le contrôle de dégagement de capsule refusait tout rebord dégagé.** Posée exactement sur la surface d'arrivée, la capsule la **touche** ; avec une marge de requête de 2 cm, tout franchissement se déclarait `blocked`. Doublement trompeur : le cas nominal échouait, et le test du plafond passait en accusant le rebord au lieu du plafond. | le cas nominal échouait, le cas « refusé » réussissait — la combinaison a mis sur la piste | capsule décollée de 5 cm, marge de requête nulle |
| B3-2 | **Le trajet de franchissement traversait le rebord.** Une interpolation directe du pied au dessus coupe le coin ; le contrôle de capsule annulait à mi-parcours, comme il doit. Le mantle ne s'achevait jamais. | après B3-1, le franchissement démarrait puis s'annulait | trajet en deux temps (monter, puis avancer) via `begin_path()` — c'est la réponse à **R-009** |
| B3-3 | **Bande d'angles infranchissable.** Seuil de paroi à 50°, sol praticable à 46° : entre les deux, le joueur glisse sans pouvoir s'accrocher. Aucune erreur, aucun test rouge — un piège silencieux. | en écrivant le test du filtre d'angle, en cherchant quelle surface l'exercerait | seuils alignés à 46° et invariant verrouillé par un test (D-019) |
| B3-4 | **La branche « surplomb » n'était couverte par aucun test.** | le contrôle négatif P2 a retiré l'exigence de contact aux pieds **sans rien casser** | paroi flottante ajoutée au bac à sable, test dédié |

B3-4 mérite d'être souligné : c'est le contrôle négatif qui a révélé le trou, pas
une relecture. Un test qui reste vert alors qu'on casse le code qu'il prétend
couvrir en dit plus long qu'un test qui rougit.

## Contrôles négatifs rejoués

| # | Mutation appliquée | Test visé | Obtenu |
|---|---|---|---|
| P1 | `is_surface_climbable()` accepte tout | `test_an_unclimbable_surface_is_refused` | ÉCHEC ✅ |
| P2 | contact aux pieds non exigé | `test_an_overhang_is_refused` | ÉCHEC ✅ *(vert avant l'ajout du test — voir B3-4)* |
| P3 | contrôle de dégagement de capsule retiré | `test_a_ledge_under_a_ceiling_refuses_the_mantle` | ÉCHEC — bascule en `blocked_midway` ✅ |
| P4 | trajet de mantle en ligne droite | `test_reaching_a_ledge_mantles_onto_it` | ÉCHEC — « le franchissement doit s'achever » ✅ |
| P5 | l'escalade ne consomme plus d'endurance | `test_climbing_drains_stamina` | ÉCHEC — « obtenu 0.0000 » ✅ |
| P6 | seuil de paroi reporté à 50° **dans le `.tres`** | `test_no_angle_is_both_unwalkable_and_unclimbable` | ÉCHEC ✅ |
| P7 | `floor_snap_length` non rétabli au lâcher | `test_releasing_the_wall_restores_ground_settings` | ÉCHEC ✅ |
| P8 | saut d'escalade gratuit | `test_climb_jump_costs_stamina_and_pushes_off` | ÉCHEC — « obtenu 0.0000 » ✅ |

Logs archivés : `evidence/gateB/negative_controls/P1…P8*.log`. Fichiers restaurés
et comparés à l'octet près entre chaque contrôle.

**P3 est instructif** : la mutation ne rend pas le franchissement possible, elle
déplace seulement le refus du détecteur de rebord vers le contrôle de mi-parcours
(`blocked_midway`). Il existe donc deux lignes de défense, et le test les
distingue par la raison rapportée.

## Limites de B.3 — à ne pas confondre avec des oublis

- **Le lissage de la normale n'est pas testé.** Le code existe et est
  framerate-independent, mais le bac à sable n'a que des parois planes : rien à
  lisser. Un test exigerait une paroi irrégulière.
- **Le déplacement latéral n'est pas mesuré.** Il facture bien 16/s, mais aucun
  test ne vérifie les 1,65 m/s de §9.2.
- **L'annulation en cours de franchissement n'a pas de test dédié.** Elle est
  exercée indirectement par P3.
- **`ClimbRest` et les corniches de repos** (§8.1, §9.3) relèvent du level design.
- **Aucune IK de main, aucune animation** (§9.2) : il n'y a ni squelette ni modèle.
- **« Aucun snap visible » est mesuré, pas vu.** Le plus grand pas est borné et la
  trajectoire continue ; aucun œil humain n'a regardé un franchissement.
- **CONTROLLER-001 reste ouverte.**

---

# Jalon B.4 — Franchissement de marche et parcours enchaîné (2026-08-01)

## Commande et résultat

```bash
tools/validate_fast.sh; echo $?
```

**Code retour** : `0` — VERT.

| Niveau | Résultat |
|---|---|
| 0. Version | `4.7.1.stable.custom_build.a13da4feb` ✅ |
| 1 / 1b. Import et parse de **tous** les `.gd` | 0 erreur ✅ |
| 2. Tests unitaires, d'intégration et de parcours | **129 réussis, 0 échoué** ✅ |
| 2b. Erreurs signalées dans le journal | aucune ✅ |
| 3. Scène principale (Boot → MainMenu, lancement réel) | ✅ |
| 4. Plancher de couverture | 129 tests pour un plancher de 129 ✅ |

> **Nombre de tests de référence : 129.** C'est ici, et nulle part ailleurs, qu'il
> doit être lu.

Nouveau fichier : `tests/playthrough/test_traversal_course.gd` — premier test du
répertoire `playthrough`, resté vide depuis le Gate 0.

## Le parcours enchaîné

`scenes/tests/TraversalCourse.tscn` : sol → marche 0,32 m → rampe 40° → plateau →
vide de 2 m → plateau d'arrivée → tour de 4 m à escalader et franchir. Un pilote
scripté tient « avant » et saute au bord du vide. **Aucune triche** : pas de
téléportation, pas d'état forcé, aucune méthode de debug (§0.8).

13 assertions, dont trois qui ne relèvent d'aucun test unitaire :

- **chaque capacité a réellement servi** — compteurs sur `stepped_up`,
  `grabbed_wall` et `mantle_finished`. Sans eux, un parcours réussi par un chemin
  imprévu passerait pour une validation du traversal ;
- **la caméra n'est jamais dans la géométrie** — une sphère de 12 cm testée au
  point de vue à **chaque tick** du parcours. C'est la mesure la plus directe de
  §23.1 : non pas que le bras se raccourcisse, mais que l'œil ne soit jamais dans
  la roche. Résultat : 0 image sur ~1 400 ;
- **l'état final est cohérent** — ni accroché, ni en franchissement, accroche au
  sol rétablie.

Un filet de sécurité est posé sous le vide. Il ne fait pas partie du parcours :
sans lui, un saut raté produirait une chute infinie que le test lirait comme
« toujours en mouvement ». Avec lui, l'échec est **observable**.

## Défaut réel trouvé pendant B.4

**`is_on_wall()` est faux contre un mur.** Plaqué contre le mur de 6 m du bac à
sable, poussant depuis deux secondes, `is_on_wall()` renvoie `false` — mesuré. Le
franchissement de marche y était adossé : il se serait tu précisément dans les
situations qu'il doit traiter. Remplacé par une comparaison entre distance
demandée et distance parcourue (D-020).

## Contrôles négatifs rejoués

| # | Mutation appliquée | Test visé | Obtenu |
|---|---|---|---|
| Q1 | `_try_step_up()` n'est plus appelé | `test_a_low_step_is_climbed_by_walking` | ÉCHEC — « obtenu 0.0004 » ✅ |
| Q2 | contrôle de dégagement au-dessus retiré | `test_a_step_under_a_low_ceiling_is_refused` | ÉCHEC — le joueur traverse jusqu'à z = −38,30 ✅ |
| Q4 | `_try_step_up()` retiré, parcours enchaîné | `test_the_full_traversal_course...` | ÉCHEC dès le segment 1, en cascade ✅ |

### Deux contrôles négatifs **non concluants**, et ce qu'ils apprennent

Ils sont archivés au même titre que les autres : un contrôle qui ne casse rien est
un résultat, pas un échec de procédure.

- **Q3** — retrait *simultané* du dégagement avant **et** du contrôle de
  praticabilité : `test_a_tall_wall_is_not_treated_as_a_step` reste **vert**. Cause
  mesurée : devant un mur plein, la sonde descendante ne trouve aucun sol
  (`test_move` renvoie `false`) et la fonction refuse avant d'atteindre ses
  contrôles. C'est une défense en profondeur réelle — mais ce test ne valide
  **aucune ligne en particulier**, seulement un comportement observable. C'est écrit
  dans sa docstring.
- **Q5** — retour au déclencheur `is_on_wall()` : la suite reste **verte**. Aucun
  test ne distingue les deux déclencheurs. Le changement de D-020 repose sur une
  mesure directe, pas sur un test, et le test concerné le dit.

Logs archivés : `evidence/gateB/negative_controls/Q1…Q5*.log`.

## Limites de B.4

- **Le déclencheur de franchissement n'est pas départagé par un test** (Q5).
- **Le cas « mur » ne valide aucune ligne précise** (Q3).
- **Le parcours est joué par un pilote scripté, pas par une personne.** Il prouve
  l'absence de blocage mécanique, pas l'agrément.
- **La caméra est vérifiée contre la géométrie, pas contre le jitter** (§8.3) :
  aucune observation en mouvement à framerate réel.
- **Aucune mesure de latence en ticks** (§10.6).
- **CONTROLLER-001 reste ouverte.**

---

# Jalon B.5 — Latence instrumentée et protocole manuel Gate B (2026-08-01)

## Commande et résultat

```bash
tools/validate_fast.sh; echo $?
```

**Code retour** : `0` — VERT. **133 réussis, 0 échoué**, plancher 133.

> **Nombre de tests de référence : 133.** C'est ici, et nulle part ailleurs, qu'il
> doit être lu.

## Mesures de latence (§10.6, §23.1)

`LatencyInstrument` pose l'intention **entre deux ticks** — la position temporelle
exacte d'un événement de périphérique relayé par `PlayerInputReader` — puis compte
les ticks jusqu'au premier effet observable.

| Mesure | Essais | Pire cas | En ms (60 Hz) |
|---|---|---|---|
| Intention de déplacement → vitesse horizontale | 5 | **1 tick** | 16,7 |
| Demande de saut (repos) → vitesse verticale | 5 | **1 tick** | 16,7 |
| Stabilité inter-essais | 5 | min = max | — |

§23.1 (« entrée mouvement visible au tick physique suivant ») est donc **mesuré**,
pas affirmé. Le pire cas est exigé, pas la moyenne : une latence intermittente est
une latence.

**Périmètre honnête** : c'est le pipeline intention → mouvement. La latence
périphérique → intention et la latence d'affichage sont hors de portée headless —
§10.6 les exclut d'ailleurs (« hors latence écran/périphérique »). L'affichage
debug à l'écran viendra avec le `CombatLab` (Phase C) ; l'instrument est écrit pour
y être branché tel quel.

## Contrôles négatifs rejoués

| # | Mutation | Test visé | Obtenu |
|---|---|---|---|
| L1 | `ground_acceleration` à 0,3 **dans le `.tres`** | `test_movement_responds_at_the_next_physics_tick` | ÉCHEC — « min 3, max 3, moyenne 3.00 tick(s) (50.0 ms) » ✅ |
| L2 | `_try_jump()` réordonné avant `_update_timers()` | `test_jump_responds_at_the_next_physics_tick` | ÉCHEC — « min 2, max 2, moyenne 2.00 tick(s) (33.3 ms) » ✅ |

L2 reproduit exactement la régression que §10.6 vise : une action tardive **par
architecture** — le buffer posé ce tick n'est vu qu'au suivant. Le test la chiffre.

## Protocole manuel et terrain d'essai

- `docs/MANUAL_VALIDATION.md`, section Gate B : six essais (caméra contre murs,
  escalade et refus, mantle sous plafond, endurance nulle, ressenti, parcours à la
  main), chacun avec but, procédure, critère PASS et preuve attendue.
- `TraversalPlayground.tscn` : sandbox + joueur + panneau d'état (endurance, mode,
  vitesse, événements journalisés). **Lancé réellement** en headless : souris
  capturée, aucun log d'erreur, RC=0. Ce que ce lancement ne prouve pas : le rendu
  à l'écran et la jouabilité — c'est précisément l'objet du protocole.
- Silhouette graybox (capsule + nez d'orientation) sur le joueur : le strict
  minimum pour qu'un opérateur voie le corps et son orientation. Ce n'est **pas**
  un personnage (§7.14).

## Limites de B.5

- **L'essai humain n'a pas eu lieu** : le protocole est prêt, pas joué. Ressenti,
  jitter et lisibilité restent `NON VÉRIFIÉ`.
- **La falaise irrégulière de §21.4 n'est pas jugeable en graybox** (parois
  planes) : l'essai B-2 le consigne et sera rejoué en Phase D.
- **CONTROLLER-001 reste ouverte** — et le protocole Gate B dit explicitement
  qu'il ne la lève pas.

---

# Revue contradictoire du Gate B et clôture du volet automatique (2026-08-01)

## Verdict

**Gate B : BLOQUÉ / EN ATTENTE — aucun `FAIL`.** Rendu par la revue à contexte
frais après ré-exécution indépendante (dépôt principal **et** clone frais, RC=0 ;
playground lancé ; release RC=3 conforme). Détail par critère et traitement des
constats : `evidence/gateB/REVUE.md`.

## Commande et résultat après traitement des constats

```bash
tools/validate_fast.sh; echo $?
```

**Code retour** : `0` — VERT. **137 réussis, 0 échoué**, plancher 137.

> **Nombre de tests de référence : 137.** C'est ici, et nulle part ailleurs, qu'il
> doit être lu.

## Ce que la revue a démontré, et ce qui en a été fait

| Démonstration de la revue | Réponse |
|---|---|
| `coyote_time`/`jump_buffer` mutés à **5,0 s** dans le `.tres` : 133/133 vert | deux tests comportementaux — la fenêtre de coyote doit **se fermer**, le tampon doit **expirer** avant un long atterrissage — plus l'épinglage §8.2 valeur par valeur ; V1/V2 rougissent désormais |
| tests de vitesse **circulaires** (mesure comparée à `tuning.*`) | `test_locomotion_tuning_matches_the_spec` : 12 valeurs de §8.2 épinglées ; V3 (`run_speed = 12`) rougit |
| poussée diagonale à 45° contre la marche : **jamais franchie** | déclencheur remplacé par l'écoute des collisions de glissement ; test diagonal ajouté ; V4 rougit sur la face **et** la diagonale |

## Correction d'une justification fausse (D-020 amendée)

En traitant le contre-exemple diagonal, la mesure fondatrice de D-020 s'est
révélée être un **artefact** : « `is_on_wall()` faux contre le mur de 6 m » — le
joueur n'était pas contre le mur, il l'avait **saisi** (x = 29,33 = exactement la
distance de paroi de 0,42 m ; en escalade le corps est tenu sans contact). La
sonde de collisions de glissement l'a montré : `collisions=0` parce qu'il n'y a
pas de contact à avoir, et, en poussée diagonale contre la marche, une collision
bien réelle de normale (0 ; 0,12 ; −0,99).

Conséquences honnêtes : D-020 porte un amendement daté, la docstring qui citait la
fausse mesure est corrigée, **Q5 est caduc** (sa mutation visait un déclencheur
disparu) et son log est conservé comme archive datée, jamais retouché. Le test qui
départage désormais les variantes de déclencheur est le cas diagonal — ce qui
manquait à Q5.

## Chaîne des trois déclencheurs de franchissement de marche

1. `is_on_wall()` — écarté sur une mesure **mal interprétée** (artefact ci-dessus) ;
2. distance parcourue vs demandée — muet en diagonale (contre-exemple de la revue) ;
3. **collisions de glissement + poussée dirigée dedans** — mesuré présent de face
   et en diagonale, jamais sur sol libre, donc aucun faux déclenchement pendant
   une accélération.

## Limites au moment de la clôture du volet automatique

- Les six essais humains ne sont **pas joués** : jitter, ressenti, lisibilité
  restent `NON VÉRIFIÉ`.
- Le mur saisissable est agrippé avant tout contact : le cas « mur non
  saisissable heurté de face » n'existe pas dans le bac à sable actuel — Q3 reste
  non concluant, pour deux raisons empilées désormais documentées.
- R-012 (saut pendant mantle) et R-013 (coût du mantle) sont des questions de
  design ouvertes, pas des défauts.
- **CONTROLLER-001 reste ouverte.**

---

# Jalon C.0 — Fondations de dégâts (2026-08-01)

## Contexte d'ouverture de la Phase C

Gate B clos par décision propriétaire **D-021** : « accepté pour continuation,
validation humaine finale différée ». La revue n'avait démontré aucun défaut
bloquant ; ses constats non bloquants étaient tous traités. Dettes ouvertes et
enregistrées : VALIDATION-B-001, CONTROLLER-001 — à solder à la passe finale.

## Commande et résultat

```bash
tools/validate_fast.sh; echo $?
```

**Code retour** : `0` — VERT. **151 réussis, 0 échoué**, plancher 151.

> **Nombre de tests de référence : 151.** C'est ici, et nulle part ailleurs, qu'il
> doit être lu.

Nouveaux fichiers : `scripts/combat/damage_event.gd`, `damage_formula.gd`,
`scripts/components/{health,hitbox,hurtbox}_component.gd`,
`tests/unit/test_damage.gd` (7 cas), `tests/integration/test_hit_detection.gd`
(7 cas, physique réelle — les chevauchements sont de vrais chevauchements).

## Le critère du Gate C, prouvé dans les deux sens

« Une touche par swing » : 30 frames de chevauchement continu → **1 coup**
(`test_an_overlapping_swing_hits_exactly_once`). Contrôle négatif W1 — set des
cibles retiré → **30 coups, santé 100 → 0**. Le chiffre du dommage évité est
archivé, pas allégué.

## Défaut réel trouvé pendant C.0

**`Area3D.monitoring` coupé puis rallumé entre deux ticks perd les chevauchements
pour toujours** (R-014). Symptôme : le second swing d'un enchaînement ne touchait
jamais — `overlaps=0` six frames après réactivation, hurtbox en plein
chevauchement. Mesuré à la sonde, pas déduit. Correctif : `monitoring` permanent,
fenêtre portée par `_active` + balayage coupé hors fenêtre (§5.4). Sans le test
du second swing, ce bug serait arrivé jusqu'au combat réel en C.1, où il aurait
été un « coup fantôme » intraçable.

## Contrôles négatifs

W1–W4, tous ÉCHEC comme attendu, logs avec `RC=` dans
`evidence/gateC/negative_controls/`. Détail : `evidence/gateC/README.md`.

## Limites de C.0 — à ne pas confondre avec des oublis

- **Aucune arme, aucun ennemi, aucun état d'attaque** : la hitbox s'active par
  méthode, personne ne l'appelle encore en gameplay. C.1 branche l'épée, le
  combo et le premier pillard.
- **Poise, recul, élément transportés mais non consommés** — la jauge de poise
  et les réactions arrivent en C.1/C.2.
- **Résistance et armure neutres** — branchées aux buffs (§13.5) et aux
  définitions d'ennemis (C.2) ; leur place dans la formule est déjà testée.
- **Le joueur n'a ni hurtbox ni santé câblées** — C.1, avec le premier échange
  de coups.
- Dettes de validation humaine inchangées : VALIDATION-B-001, CONTROLLER-001.

---

# Jalon C.1 — Épée, combo, premier échange (2026-08-01)

## Commande et résultat

```bash
tools/validate_fast.sh; echo $?
```

**Code retour** : `0` — VERT. **165 réussis, 0 échoué**, plancher 165.

> **Nombre de tests de référence : 165.** C'est ici, et nulle part ailleurs, qu'il
> doit être lu.

Nouveaux fichiers : `resources/combat/attack_definition.gd` + 3 `.tres` d'épée,
`scripts/combat/attack_controller.gd`, `scenes/tests/CombatDummy.tscn`,
`scenes/tests/CombatLab.tscn` (lancé réellement, RC=0),
`tests/unit/test_attack_controller.gd` (9 cas),
`tests/integration/test_combat_exchange.gd` (6 cas). L'InputMap n'a pas changé —
l'action `attack_light` existait depuis A.1 avec sa liaison manette.

## Le premier échange, chiffré

Quatre appuis couchent un pillard braise (45 PV, §12.1) : 12 ; 12,6 ; 15,6 —
le combo complet fait 40,2, le mannequin y survit — puis 12 (nouveau combo, la
remise à zéro est prouvée par le montant). Le cadavre coupe sa hurtbox : marteler
ensuite ne produit plus rien (§12.10).

## Trois défauts réels trouvés pendant C.1

| # | Défaut | Correctif |
|---|---|---|
| C1-1 | **Mon arithmétique, pas le code** : le test affirmait que le combo complet (40,2) tue 45 PV. Corrigé dans le test — et transformé en preuve plus riche : la survie au combo + la mort au 4ᵉ coup prouvent la remise à zéro |
| C1-2 | **Appui unique perdu à l'arrêt** : le monde `queue_free` du test précédent survit une frame ; le joueur apparaissait posé dessus (y = 0,87 mesuré), chutait, et l'appui arrivait en plein vol — consommé par le portail `is_on_floor()`. Le setup attend désormais l'ÉTAT atterri, jamais un nombre de ticks |
| C1-3 | **Appui de fin de combo avalé** : le buffer mourait à l'idle — un appui 0,1 s avant la fin du 3ᵉ coup était perdu, l'entrée avalée que §10.6 interdit. Report ajouté : à la fin du dernier coup, un appui frais relance un combo à zéro ; un appui périmé ne relance rien (2 tests) |

C1-2 mérite le détail : le symptôme — appui unique perdu, martèlement
fonctionnel — ressemblait à un bug de front d'intention. La sonde en contexte
isolé fonctionnait parfaitement ; seule la sonde EN CONTEXTE DE RUNNER a montré
`sol=false` puis la position fantôme. Une mesure dans le mauvais contexte aurait
« prouvé » que tout allait bien.

## Contrôles négatifs

X1–X4, tous ÉCHEC comme attendu, logs avec `RC=` dans
`evidence/gateC/negative_controls/`. X4 chiffre la perte : sans le terme
« attack » de §10.3, les coups 2 et 3 retombent à 12,0.

## Limites de C.1 — à ne pas confondre avec des oublis

- **Personne ne frappe le joueur** : sa hurtbox et sa santé sont câblées mais
  aucun ennemi n'attaque (C.2, premier pillard avec IA).
- **Ni esquive, ni i-frames, ni lock-on, ni stagger** (C.2). `cancel()` attend le
  stagger qui l'appellera.
- **Ni hit-stop, ni VFX, ni son** (§10.7) : les valeurs sont déclarées dans les
  `.tres`, aucun système de présentation ne les consomme.
- **`base_damage` est provisoire** sur le contrôleur d'attaque : la
  `WeaponDefinition` de §5.9 le portera en C.3 avec la durabilité.
- **Le CombatLab est un embryon** : mannequins, panneau, journal — la timeline
  dessinée, l'historique d'inputs avec raisons de rejet et l'export CSV de §10.8
  viennent avec les systèmes qu'ils instrumentent.
- **Le ressenti n'est pas prouvé** : §10.6 exige aussi un essai humain — même
  dette de passe finale que le traversal.

---

# Jalon C.2 — Esquive, i-frames, lock-on, premier pillard (2026-08-01)

## Commande et résultat

```bash
tools/validate_fast.sh; echo $?
```

**Code retour** : `0` — VERT. **186 réussis, 0 échoué**, plancher 186.

> **Nombre de tests de référence : 186.** C'est ici, et nulle part ailleurs, qu'il
> doit être lu.

Nouveaux fichiers : `DodgeDefinition` + `.tres`, `PoiseComponent`,
`LockOnComponent`, `EnemyTuning` + `raider_red_default.tres`, `club_1.tres`,
`RaiderRed` (scène + IA), 21 cas de test (`test_dodge`, `test_lock_on`,
`test_raider`). Le `CombatLab` gagne un pillard vivant à 12 m.

## Le cas central, §12.1 au complet

Le pillard télégraphie 0,8 s (mesuré ≥ 0,65, jamais avant), frappe pour 8
(gourdin bois §11.1) un joueur immobile — et face à une **esquive réelle
chronométrée sur son annonce** (déclenchée +0,65 s, i-frames 0,02–0,27 couvrant
la fenêtre active 0,80–0,95), le coup ne porte pas **et le pillard recule** :
état de repli, distance mesurée. Le tutoriel vivant fonctionne, en assertion.

## Défauts trouvés pendant C.2 — tous dans mes tests, aucun dans le code livré

| # | Défaut | Leçon |
|---|---|---|
| C2-1 | La hitbox de test gardait le masque par défaut (1) : elle ne voyait pas la couche Hurtbox (32) du joueur — la première assertion des i-frames passait **pour la mauvaise raison** (aucun coup ne portait jamais) | c'est le contrôle inverse — « le coup DOIT porter hors fenêtre » — qui l'a révélé. Toujours prouver les deux sens (B3-1) |
| C2-2 | Deux tests posaient le pillard **derrière** le joueur : l'épée frappait dans le vide, la poise ne montait jamais | une géométrie de test se vérifie contre l'orientation réelle du personnage |
| C2-3 | À 2 m, la première attaque du pillard partait **pendant le `_setup`**, avant le branchement des signaux — annonce manquée, chronomètre faux | brancher les signaux avant que l'événement ne puisse exister : distance de spawn = marge de temps |
| C2-4 | L'élan résiduel de fin d'esquive (~1,2 m) sortait le joueur de la sphère de frappe du second coup | une mesure post-action tient compte de la cinétique complète, pas de la durée nominale |
| C2-5 | Mon assertion « rien n'est prélevé » ignorait la régénération repartie pendant l'attente | vérifier « jamais descendu sous X », pas « figé à X » |

## Contrôles négatifs

Y1–Y5, tous ÉCHEC, logs avec `RC=` dans `evidence/gateC/negative_controls/`.
**Y5** fait rougir la valeur du télégraphe **dans les deux sens** : la mesure
comportementale (« 0,13 s ») et l'enveloppe épinglée (« 0,10 ») — la doctrine
issue de la revue du Gate B, appliquée en routine.

## Limites de C.2 — à ne pas confondre avec des oublis

- **Le joueur encaisse sans réaction** : ni état Hurt, ni knockback appliqué, ni
  anti-stunlock (§10.5) — C.3, avec la protection que §10.5 exige.
- **Pas de changement de cible** (`target_prev/next` liés depuis A.1, logique à
  venir) ni de hit-stop/VFX/son (§10.7).
- **D-022** : pilotage direct sans navmesh (expire à la Phase D), audition
  différée aux événements sonores.
- **Le ressenti du duel n'est pas prouvé** — le CombatLab avec pillard vivant est
  prêt pour l'essai humain (dettes de passe finale).

---

# Jalon C.3 — Attaque lourde, réaction du joueur, arc (2026-08-01)

## Commande et résultat

```bash
tools/validate_fast.sh; echo $?
```

**Code retour** : `0` — VERT. **200 réussis, 0 échoué**, plancher 200.

> **Nombre de tests de référence : 200.** C'est ici, et nulle part ailleurs, qu'il
> doit être lu.

Nouveaux fichiers : `heavy_1.tres` (lourde ×1,8, poise 25, hit-stop 0,08),
`HurtTuning` + `hurt_default.tres` (réaction 0,25 s, grâce 0,85 s),
`BowTuning` + `bow_default.tres` (48 m/s, 9 de dégâts, pool 8),
`ArrowProjectile` (balistique par balayage, CCD §5.3), `BowComponent` (pool,
origine-poitrine), `switch_target` directionnel dans `LockOnComponent`,
mode `HURT` du joueur ; 14 cas de test (`test_heavy_and_hurt`, `test_bow`,
changement de cible dans `test_lock_on`).

## Les cas centraux

- **Lourde** (§10.2, §9.1) : 12 × 1,8 = 21,6 de dégâts et 20 d'endurance mesurés
  sur le même coup ; **refusée** à jauge 10 — rien ne part, rien n'est prélevé ;
  une seule lourde brise la poise du pillard (25 ≥ 20) là où il fallait deux
  coups légers.
- **Réaction** (§8.1 Hurt, §10.5) : le `knockback` transporté depuis C.0 est
  enfin consommé — recul mesuré dans la direction du coup, contrôle rendu après
  0,25 s ; deux coups en cadence **blessent tous les deux** mais seul le premier
  renverse (la grâce protège le contrôle, jamais les PV) ; la grâce expirée, la
  réaction revient.
- **Arc** (§10.4, §11.1) : 9 de dégâts là où la caméra regarde ; chute de
  gravité mesurée (vy ≈ −4 après 1/3 s) ; un mur à 0,8 m arrête la flèche, le
  mannequin derrière est intact ; la flèche meurt à sa **première** victime
  (deux mannequins alignés : 9 / 0) ; le pool refuse le tir excédentaire au lieu
  d'instancier ; le tir exige la visée tenue.
- **Changement de cible** (§8.4) : trois cibles dont une derrière un mur — pas
  vers la droite caméra, pas de boucle aux bords, jamais à travers le mur.

## Défaut trouvé dans le code livré — corrigé le jour même

`_on_hit_received` était écrit **mais jamais connecté** au signal de la hurtbox :
les dégâts passaient, la réaction n'existait pas. La première exécution de
`test_heavy_and_hurt` l'a démontré (4 assertions rouges), la connexion manquante
est posée dans `_ready`, et **Z5** rejoue la panne à l'identique en contrôle
négatif. Deux défauts de mes tests corrigés au passage : la mesure d'endurance
ignorait la régénération pendant le recovery (C2-5 récidivé — mesurer
**immédiatement après le prélèvement**), et la géométrie du changement de cible
se comptait depuis le joueur au lieu de la **caméra** (épaule x +0,32 : la
« gauche » du joueur n'est pas celle de la caméra).

## Contrôles négatifs

Z1–Z6, tous ÉCHEC, logs avec `RC=` dans `evidence/gateC/negative_controls/`.
Détail et enseignements : `evidence/gateC/README.md`.

## Limites de C.3 — à ne pas confondre avec des oublis

- **Pas de munitions** : l'arc tire sans flèches comptées — l'inventaire de
  §11.3 et la durabilité « 28 tirs » arrivent en C.4.
- **Dégâts d'arc sans point faible exploité** : le multiplicateur est raccordé
  (même formule §10.3 que la mêlée), aucun ennemi n'expose encore de point
  faible — troll en Phase D.
- **Pas de réticule, ni de hit-stop/VFX/son** (§10.7) — présentation à venir.
- **Le ressenti (lourde, recul, visée) n'est pas prouvé** — dettes d'essai
  humain de la passe finale, comme depuis B.5.

---

# Jalon C.4 — Inventaire, durabilité, rupture (2026-08-01)

## Commande et résultat

```bash
tools/validate_fast.sh; echo $?
```

**Code retour** : `0` — VERT. **214 réussis, 0 échoué**, plancher 214.

> **Nombre de tests de référence : 214.** C'est ici, et nulle part ailleurs, qu'il
> doit être lu.

Nouveaux fichiers : `WeaponDefinition` (§5.9) + les **six** `.tres` de la table
§11.1, `WeaponInstance` (état mutable séparé : `instance_id`, `definition_id`,
`current_durability`), `InventoryComponent` (8 armes, flèches à part),
14 cas de test (`test_weapon_data`, `test_durability`). Le `base_damage = 12`
provisoire du contrôleur d'attaque (C.1) est remplacé : l'export devient la
valeur **mains nues** (3, D-023), l'arme équipée fournit dégâts ET portée.

## Les cas centraux

- **L'invariant de CLAUDE.md** : deux exemplaires créés de la même définition —
  user l'un de 5 points laisse le jumeau à 24 ET la définition à 24. Le contrôle
  AA4 (durabilité écrite dans la ressource partagée) fait rougir les trois
  directions et 15 assertions en cascade.
- **Usure au contact seulement** (§11.2) : deux moulinets dans le vide = 0 point ;
  un coup qui touche = 1 point. AA2 (usure au début du geste) rougit.
- **Rupture** (§11.2) : à zéro — exemplaire retiré, suivante équipée d'office,
  puis mains nues qui restent un état de combat (épée 12, gourdin 8, poings 3
  mesurés sur le même mannequin). La coupe est effective AU MILIEU du tick :
  deux mannequins dans le même volume, arme à 1 point → une seule victime
  (78 = 90 − 12) ; avec durabilité → les deux (66).
- **Portée §11.1 raccordée** : mannequin à 2,4 m — l'épée (1,7 m) ne touche pas,
  la lance (2,7 m) touche pour 10. Même position, même geste.
- **Avertissement à 25 %** : émis au passage sous le quart, une seule fois.
- **Flèches comptées** (§11.3) : 8 → 7 après un tir ; carquois vide, cadence
  purgée → aucun tir ne part.

## Défaut trouvé dans MON test par son propre contrôle négatif

L'assertion « à zéro flèche, aucun tir » restait verte quand AA6 retirait le
portail : la **cadence** de l'arc bloquait le second tir à la place du compteur —
verte pour la mauvaise raison (récidive de C2-1, chaque système de refus
concurrent doit être purgé avant de tester celui qu'on vise). Test corrigé,
mutation rejouée, deux assertions rouges.

## Contrôles négatifs

AA1–AA6, tous ÉCHEC, logs avec `RC=` dans `evidence/gateC/negative_controls/`.
Détail : `evidence/gateC/README.md`.

## Limites de C.4 — à ne pas confondre avec des oublis

- **L'arc n'est pas un exemplaire d'inventaire** : ses « 28 tirs » de durabilité
  (§11.1) ne sont pas décomptés — la définition `simple_bow.tres` existe et
  attend le raccordement (avec les coffres, Phase D, ou l'UI d'inventaire §17.3).
- **Pas d'entrée clavier pour changer d'arme** (`equip_next` est une API) — la
  sélection rapide passe par l'UI d'inventaire (§17.3), hors périmètre C.
- **Pas d'usure visuelle ni de son d'avertissement** (§11.2 : « son altéré,
  usure visuelle ») — le signal `durability_warned` existe, la présentation
  arrive en Phase H.
- **Ramassage au sol inexistant** : les armes entrent par API ; le flux coffre →
  loot arrive en Phase D (§11.4).

---

# Jalon D.0 — Vallée de Néris : intégration graybox (2026-08-01)

## Commande et résultat

```bash
tools/validate_fast.sh; echo $?
```

**Code retour** : `0` — VERT. **221 réussis, 0 échoué**, plancher 221.

> **Nombre de tests de référence : 221.** C'est ici, et nulle part ailleurs, qu'il
> doit être lu.

Nouveaux fichiers : `ValleyWorld.tscn` (sol 512 × 512 m, spawn sud §3.3, camp à
(45, 0, 65) avec trois pillards, coffre `valley.chest.camp.01`, gourdin au sol),
`valley_world.gd` (flux VALLEY, filet anti-hors-monde), `Chest.tscn`/`chest.gd`
(loot garanti versé une fois, ID stable §19.3), `WeaponPickup.tscn`/
`weapon_pickup.gd`, geste d'interaction §14.2 dans le contrôleur (2,2 m, cône
avant), « Nouvelle partie » et « Continuer » → `SceneFlow.go_to(vallée)`.
Inclut la revue du Gate C du même jour : `Mode.DEAD` + `test_player_death.gd`.

## Les cas centraux

- La vallée charge avec joueur au spawn (atterri), trois pillards, coffre et
  arme au sol ; le flux passe à VALLEY.
- Ramassage : l'interaction verse le gourdin dans l'inventaire, l'objet
  disparaît ; inventaire PLEIN → l'arme reste au sol, rien n'est perdu.
- Coffre : hache + 12 flèches versées une fois ; le second appui ne donne RIEN
  (§11.4 « jamais de second loot » — en session ; persistance Phase E).
- Le menu atteint réellement la scène (`can_go_to` vrai sur la constante).

## Pièges mesurés pendant D.0

- Un **StaticBody3D ajouté puis déplacé** passe un tick dans le joueur : Jolt
  dépénètre le personnage (~0,6 m mesurés) et l'objet sort de la portée
  d'interaction. Règle : POSITIONNER AVANT `add_child`.
- « Nouvelle partie » exécutant une vraie transition, les tests du menu doivent
  BLOQUER `SceneFlow` (occupé) pendant l'appui : sinon la scène du runner est
  remplacée et l'arbre reste en pause — cascade sur toutes les suites suivantes.

## Limites de D.0 — dites sans détour

- **Sol plat** : ni relief, ni rivière, ni pylône, ni citadelle, ni composition
  North Star — c'est une INTÉGRATION, pas le monde de §3.3. Le navmesh (D-022)
  arrive avec le premier relief.
- **« Continuer » repart du spawn** : l'application de l'état sauvegardé arrive
  avec SaveSystem complet (Phase E).
- **Pas d'invite d'interaction à l'écran** (§14.2 : reticle/outline — UI §17).
- Pas de bords de monde : filet anti-chute à −20 m en attendant le relief.

---

# Jalon D.1 — Relief macro, proxys, navmesh (2026-08-01)

## Commande et résultat

```bash
tools/validate_fast.sh; echo $?
```

**Code retour** : `0` — VERT. **225 réussis, 0 échoué**, plancher 225.

> **Nombre de tests de référence : 225.** C'est ici, et nulle part ailleurs, qu'il
> doit être lu.

`ValleyTerrain` (blockout déclaratif : dalles + prismes convexes, cotes §3.3),
proxys pylône/citadelle émissifs, soleil ouest 22° + ciel/brume §3.4,
`VistaCamera_Hero01` (§3.2, constantes fixes), navmesh baké versionné
(`valley_navmesh.tres`, 488 polygones) + suivi serveur manuel dans le pillard.

## Les risques critiques, chacun son test

- **Spawn sûr** : atterrissage sur la crête à y ≈ 24, proxys présents aux cotes.
- **Parcours praticable** : pilote scripté sans triche — crête → descente en S →
  terrasse du camp → sortie → gué ouest → plaine nord, 11 jalons dans l'ordre,
  jamais sous le niveau du monde, sans blocage (~35 s simulées).
- **Navigation ennemie** : pillard posé au FOND d'une salle en U des ruines —
  le pilotage direct s'y coince par construction ; il sort par l'ouverture SUD
  (prouvé par sa trajectoire) et ARRIVE au contact du joueur posté derrière le
  mur (~10 s). 21 hauteurs de relief sondées par rayons aux points clés.
- **Chute hors monde** : sous −20, repêché au spawn de la crête.
- **Chargement normal** : scène chargée avec joueur/camp/coffre/pillards, flux
  VALLEY ; le menu atteint la scène (`can_go_to`).

## Pièges moteur mesurés (détail : D-025)

Le suiveur de `NavigationAgent3D` compare waypoints en 3D contre des hauteurs
voxelisées → deux modes de gel selon le seuil, plus un troisième en reposant la
cible à cadence fixe (réinitialisation de l'index). Sondé trois fois, remplacé
par le suivi serveur manuel. Une sonde qui appelle `get_next_path_position`
CONSOMME l'avancement : l'observation doit se faire de l'intérieur.

## Limites de D.1

- Lit de rivière sans EAU (matériau/shader : habillage, après C.5-sur-crête).
- Un seul coffre ; les huit de §4.1 et le validateur d'IDs viennent avec les
  emplacements définitifs. Pas de bords de monde (filet à −20 m maintenu).
- Le S de la rivière est un lit rectiligne graybox ; la composition fine de
  §3.2 (ruban guidant le regard) attend l'habillage.
- Proxys = masses aux bonnes places, pas de l'art (§7.14 respecté : rien de
  « final »).

---

# Jalon D.1R — Version corrective post-playtest n° 1 (2026-08-01)

## Commande et résultat

```bash
tools/validate_fast.sh; echo $?
```

**Code retour** : `0` — VERT. 251 réussis à la fin des cinq sous-jalons, puis
**254 réussis, 0 échoué, plancher 254** après les trois régressions issues de
la revue contradictoire consolidée (`evidence/gateD/REVUE_D1R.md` : QA-D1R-01
duplication de pickup, QA-D1R-02 settings hostile, QA-D1R-03 écran de mort
modal — trois S3 corrigés le jour même).

> **Nombre de tests de référence : 254.** C'est ici, et nulle part ailleurs,
> qu'il doit être lu.

Exécuté après CHAQUE sous-jalon (D.1R.1 → D.1R.5), pas seulement à la fin.

## Les 18 régressions exigées, réparties en 5 suites nouvelles

- `test_mouse_camera.gd` (6) : delta souris → rotation en radians appliqués
  tels quels (le double-échelonnage ÷25 réintroduit ferait échouer la mesure
  d'angle) ; 360° de lacet sans butée ; canal stick distinct (vitesse×delta) ;
  pause réellement suspensive (le monde ne bouge plus) ; sensibilité écrite et
  relue depuis `user://settings.cfg` ; bornes MIN/MAX.
- `test_body_separation.gd` (4) : à vrais CharacterBody3D — le joueur ne
  traverse PAS un pillard (distance finale mesurée), le pillard ne traverse
  pas le joueur, deux pillards convergents gardent ≥ 1 m d'écart (séparation),
  le détour navmesh de la salle en U reste prouvé après changement de masques.
- `test_hud_and_inventory.gd` (9) : barres branchées aux VRAIS signaux (une
  perte de vie bouge la barre), flèches/arme/durabilité affichées, invite
  refusée SANS ligne de vue (paroi interposée = aucune invite), inventaire Tab
  pause + équipe + réordonne, molette hors lock = arme / pendant lock = cible.
  Réticule-en-visée et plafond de notifications : implémentés et lus, **non
  assertés** (QA-D1R-04) — vérification visuelle au playtest n° 2.
- `test_world_bounds_and_death.gd` (6) : anneau montagneux continu (16 rayons,
  aucun trou, tout `unclimbable`), chute repêchée TÔT au dernier point sûr,
  panneau de mort + cible de retry, écran de mort MODAL (QA-D1R-03), porte
  citadelle → vestibule, vestibule explorable + sortie → DEVANT la porte (tag
  `citadel_door` honoré). Le détour navmesh de la salle en U vit dans
  `test_valley_world.gd` (attribution corrigée, QA-D1R-04).
- `test_save_continuity.gd` (3) : coffre ouvert + arme prise → autosave →
  rechargement → inventaire/durabilité/équipée/flèches restaurés et coffre
  ouvert SILENCIEUX ; pickup ramassé JAMAIS réapparu (QA-D1R-01) ; partie
  neuve → no-op, gourdin bien au sol.

## Pièges mesurés pendant D.1R

- Un corps physique positionné APRÈS `add_child` passe un tick à l'origine —
  dépénétration Jolt : le joueur a été catapulté +4,6 m par une
  montagne-fantôme à l'origine. Règle : position AVANT add_child, partout.
- Headless refuse `MOUSE_MODE_CAPTURED` (reste VISIBLE, mesuré) — d'où le
  seam `wants_mouse_captured()` testable.
- Les mannequins de test en couche 4 dépénétraient le joueur avec les
  nouveaux masques → balayage position-avant-add sur 9 suites.

## Limites de D.1R

- Le rendu/ressenti réel (souris, lisibilité HUD, feel §10.6) reste à valider
  par le playtest humain n° 2 — les tests prouvent des liaisons et des
  distances, pas un appui de touche (CLAUDE.md).
- Vestibule = graybox honnête ; donjon quatre salles : Phase F.
- Sauvegarde minimale (armes/flèches/coffres/équipée) ; schéma §19.1 complet :
  Phase E.

---

# Passe visuelle V4.1 — lots V4.0 à V4.6 (2026-08-01)

## Commande et résultat

```bash
tools/validate_fast.sh; echo $?
```

**Code retour** : `0` — VERT à CHAQUE lot. **270 réussis, 0 échoué, plancher
270** (261 → +4 atmosphère V4.1, +4 repères V4.3 — comptés en V4.2/V4.3 —,
+5 style HUD/inventaire V4.4/V4.5).

> **Nombre de tests de référence : 270.** C'est ici, et nulle part ailleurs,
> qu'il doit être lu.

## Suites nouvelles

- `test_valley_atmosphere.gd` (3) : orage LOCAL borné épargnant la crête,
  éclair qui FRAPPE puis s'éteint (états et lumière mesurés dans le temps),
  soleil chaud + brume bornée qui étage sans noyer.
- `test_valley_dressing.gd` (8) : eau serpentant DANS le lit sans collision,
  prairie MultiMesh partitionnée posée sur la bande avant de la crête (seam
  origins/tints — le RenderingServer headless ne relit pas les tampons),
  chemins visuels des deux routes, pics deux rangées + contreforts frappés
  par rayon, camp habité (tentes physiques, feu chaud), pylône runique,
  façade monumentale aux marches mesurées ≤ 0,31 m, vestibule 26,5 m à
  braseros.
- `test_hud_style.gd` (5) : rubis qui se vident DANS L'ORDRE (somme = santé
  affichée), jauge d'endurance visible pendant l'usage seulement, plaque de
  cible suivant la vraie vie de l'ennemi, durabilité segmentée depuis
  l'instance, inventaire 8 cartes + détail comparé à la ressource .tres.

## Lancements réels et perfs

Vallée, vestibule, boot→menu : 300 frames Xvfb chacun, zéro erreur de script
après chaque lot. Perf llvmpipe INDICATIVE (jamais un budget) :
29,1 s → 42,7 s (V4.1, glow plein-écran en software) → 46,9 s (V4.2) →
49,2 s (V4.3) pour 300 frames 720p. Échelle de dégradation §20.8 : Phase I.

## Limites honnêtes

- Le RESSENTI visuel (lisibilité, ambiance, vent, HUD en jeu) plafonne à
  EN ATTENTE du regard humain — les captures llvmpipe prouvent la
  composition, pas la qualité perçue sur GPU réel.
- Le pack V4 binaire n'est pas encore dans le dépôt (voir
  source_assets/concepts/final_v4/README.md).
- La capture vista tient l'éclair en frappe majeure (mode VALLEY_VISTA,
  documenté) — en jeu la cadence est irrégulière temps-réel.

---

# E.2 fondations + ART-Q0 — nuit du 2026-08-02

## E.2 (fondations) — commit f9a0e0d

```bash
tools/validate_fast.sh   # RC=0
```
**292 tests** (plancher monté 285 → 292). 7 nouveaux tests unitaires PURS
(`test_cooking_rules.gd`) : bornes 1-5 ingrédients, soin sommé/clampé,
famille dominante + puissance cumulée + durée 60+30/compatible,
épice +45 s sans changer la famille (cas extrême réel 270 s), ragoût
instable ×0.3 sans effet, buff appliqué/remplacé/expiré (minuterie pilotée
à la main, déterministe), snapshot/restore en primitives via le chemin
normal des signaux.

## ART-Q0 — acquisition et ingestion Quaternius

**Acquisition** (hors dépôt, `/tmp/eclats-quaternius.X2JMwF/`) :

```bash
curl --fail --location --retry 3 -o <archive> <browser_download_url>  # ×7, RC=0
sha256sum *.zip   # 7/7 IDENTIQUES aux digests GitHub de la Release
file *.zip        # 7/7 « Zip archive data » (aucune page HTML)
unzip -tq         # 7/7 OK
zipinfo -1 | grep -E '^/|^[A-Za-z]:|\.\.'   # 7/7 : AUCUN chemin dangereux
```

Licences : CC0 1.0 Universal lue dans `License*.txt` de CHAQUE archive.

**Ingestion** (12 modèles, inscrits dans ATTRIBUTIONS/MANIFEST avant build) :

```bash
python3 tools/gltf_inspect.py <modele>.gltf          # 12/12 VALIDE en place
python3 tools/gltf_inspect.py Male_Ranger.gltf --expect-skin   # VALIDE
godot --headless --path . --import                   # zéro erreur
tools/validate_fast.sh                               # RC=0
```

**294 tests** (plancher monté 292 → 294). Nouveaux tests
(`test_asset_pipeline.gd`) :
- `test_the_q0_delivered_assets_resolve_with_real_meshes` : les ONZE ids
  livrés (env ×5, prop ×3, arch ×3) résolvent ET montent au moins un
  `MeshInstance3D` avec un maillage réel — un wrapper vide échoue.
- `test_the_hero_candidate_keeps_its_rig_through_the_godot_import` :
  1 armature, **65 os**, meshes skinnés après import Godot.

Compatibilité squelette (script de comparaison par noms, hors moteur) :
Male_Ranger = UAL1 = UAL2 = 65 os, différences ensemblistes vides.

**Captures** (renderer réel llvmpipe via Xvfb, manifestes JSON liés) :
`evidence/artQ0/calibration_q0_neutral.png` et
`calibration_q0_valley_light.png` — rangée complète (les 11 livrés + jalons
orange des manquants + préview héros T-pose étiquetée « candidat »).

---

# Nuit ART-Q1→Q7 — 2026-08-02 (suite de l'entrée ART-Q0 ci-dessus)

Chaque lot : import → tests ciblés → `tools/validate_fast.sh` (RC=0) →
lancement/captures Xvfb → commit isolé poussé. Plancher monotone :
292 → 294 (Q0) → 300 (Q1) → 304 (Q2) → 307 (Q3) → 309 (Q4) → 311 (Q5) →
**312** (Q6). Zéro plancher baissé, zéro seuil affaibli.

## Suites ajoutées

- `test_hero_visual.gd` (7) : bibliothèque cuite (12 clips, bouclage
  explicite), audit root motion (boucles 0,000 m, node_motion=false),
  scène héros (65 os, 3 sockets aux bons os), montage dans le VRAI
  Player.tscn (graybox masqué, capsule 1,8 m intacte, épée dans la main),
  pilote d'états (idle/run/sprint mesurés sur le vrai contrôleur, sens
  unique), mort jouée UNE fois sans double bascule, teinte sélective
  (tenue teintée, peau vierge).
- `test_raider_visual.gd` (4) : grammaire d'attaque distincte
  (Melee_Hook), 3 variantes aux teintes mesurées, montage dans la vraie
  scène IA (gourdin dans la main, télégraphe sur matériaux ACTIFS,
  capsule 1,6 m), états IA → clips par signal, mort sans double tilt.
- `test_camp_props.gd` (3) : coffre rigged ouvert par SON clip avec loot
  atomique intact, application d'état sans loot ni geste, camp réel avec
  collisions et anneau de 8 galets.
- `test_nature_biome.gd` (2) : 12 arbres réels sur 12 collisions de
  troncs intactes (variation lacet/échelle mesurée), phrases végétales
  groupées (serré < 3 m ET vide > 15 m — anti-grille).
- `test_citadel_dressing.gd` (2) : 6 piles modulaires sur collisions
  intactes, portails de pierre, SceneDoors préservées.

## Défauts réels trouvés et corrigés pendant la nuit

- Chemin dur `VisualRoot/WeaponPivot` dans test_hud_and_inventory :
  cascade de 19 tests perdus quand le pivot a rejoint la main (Q1).
- « material is null » (RenderingServer headless) : la mise à jour
  différée citait des matériaux teintés déjà libérés — surcharges vidées
  à NOTIFICATION_EXIT_TREE (Q2, cause racine lue dans la source moteur).
- Retenue de réception du pilote visuel en ms MURALES : instable quand
  les ticks headless battent le temps réel — passée en ticks (§20.9, Q5).
- Noms de galets en collision (@auto@) : noms explicites (Q3).

## Revue contradictoire (ART-Q7)

`evidence/artQ7/REVUE.md` : **PASS global**, 8 lots rejoués, 7 règles de
l'ordre PASS, zéro S0-S3, quatre S4 traités (repo_dirty resserré aux
fichiers suivis + recapture post-commit ; ISS-013/ISS-014 consignés ;
audits régénérés). validate_fast rejoué par le réviseur : 312/312, RC=0.

---

## Phase G — jalons G.1 à G.4 (2026-08-03)

Environnement : Godot 4.7.1-stable custom_build a13da4feb, Linux headless
sans GPU, Forward+ / Jolt, `tools/validate_fast.sh`.

Commandes exactes :

```bash
export GODOT_BIN=/usr/local/bin/godot
godot --headless --path . --import
godot --headless --path . --script tools/godot/test_runner.gd -- --filter=boss
tools/validate_fast.sh
```

### Nouveaux fichiers de test

- `tests/integration/test_boss_arena.gd` (11) : géométrie du disque mesurée
  sur la forme de collision, absence d'obstacle central, pylônes branchés
  sur l'anneau de terre (avec la preuve INVERSE : puits coupé = pylône
  dressé mais éteint), cycle fermé chronométré sur 50 recalculs, boss tenu
  dans l'arène, joueur non poussé à travers le mur, cadrage caméra
  progressif (plus grand pas mesuré), checkpoint relu, cible du retry,
  barre de boss, seuil sud dans les deux sens.
- `tests/integration/test_boss_guardian.gd` (12) : armure non-invulnérable,
  DEUX pylônes exigés, étourdissement 5-8 s puis armure refermée, seuil de
  PV non rejouable, cristaux de phase 2, renvoi conducteur fenêtré (bois vs
  métal vs hors surcharge), résistance électrique, fenêtre de télégraphe
  chronométrée et bornée, gain de vitesse de phase 3, mort qui coupe tout,
  solvabilité, cadrage en verrouillage.
- `tests/integration/test_boss_victory.gd` (7) : coffre final, rail éteint,
  apaisement mesuré du ciel, cinématique passable, écran de victoire à
  trois issues avec cycle de focus fermé, refus d'annoncer une victoire
  non acquise, confirmation avant écrasement.
- `tests/playthrough/test_boss_run.gd` (1, 17 assertions) : antichambre →
  coffre garanti → arène → victoire, à travers `DamageFormula` et les
  vraies hurtbox, avec durabilité et rupture d'arme.

### Défauts réels trouvés par ces tests

1. **Les pylônes étaient un compteur déguisé.** `ElectricNode.enabled` est
   ignoré par le graphe pour un `RELAY` : les quatre pylônes s'allumaient à
   l'ouverture de la scène. Corrigé par la géométrie (mât télescopique dont
   le sabot descend sur le rail).
2. **Les 5 s d'éveil de §16.1 n'existaient pas.** `_enter()` étant
   idempotent, entrer dans INTRO depuis INTRO ne posait pas le timer : le
   Gardien basculait en phase 1 au premier tick physique.
3. **Le boss était infaisable.** Le test de solvabilité de §16.7 a mesuré
   une marge de **-16 %** avec le loot garanti. Les PV sont désormais
   dérivés du calcul : 560, marge **+35 %**.
4. **Le combat ne montrait jamais les phases 2 et 3.** Les seuils de PV
   étant gelés pendant l'étourdissement, le run complet tuait le Gardien
   dans sa première fenêtre de noyau. Un seuil franchi interrompt
   maintenant la mise à la terre.
5. **Un bouton de l'écran de victoire changeait vraiment de scène pendant
   un test** — détecté par le contrôle de fuite du runner ajouté en F.6.

### Résultat mesuré du run de boss

```
[run boss] 1 mise(s) à la terre · 37 coups (15 noyau, 10 cristal)
           · 1 arme(s) brisée(s)
           · phases : phase1, grounded_stun, transition12, phase2,
                      transition23, phase3
           · vie restante 0/560
```

Ce chiffre est le résultat d'une simulation, pas d'une partie humaine : le
balayage de hitbox est postulé et la précision fixée à deux coups sur
trois. La durée d'une première victoire (§16.1 : 4-7 min) n'est PAS mesurée.

---

## Phase H — lots H.1 à H.4 (2026-08-03)

Commandes : `blender --background --python tools/blender/<script>.py`,
`blender --background <blend> --python tools/blender/export_gltf.py -- --out <glb>`,
`python3 tools/gltf_inspect.py <glb>`, puis `tools/validate_fast.sh`.

### Nouveaux assets, mesurés

| Asset | Cotes mesurées **dans Godot** | Bande de la bible | Triangles | Os |
|---|---|---|---|---|
| `SK_StormGuardian` | 9,58 × 5,30 × 5,60 m | §15.1 : 8-10 × 5-7 × 5,2-6 | 6 324 | 22 |
| `SK_RaiderRed` | h 1,42 m | §14.1 : 1,40-1,52 | 1 200 | 65 (UAL) |
| `SK_RaiderBlue` | h 1,63 m | §14.2 : 1,58-1,72 | 1 620 | 65 (UAL) |
| `SK_RaiderBlack` | h 1,88 m | §14.3 : 1,85-2,05 | 1 440 | 65 (UAL) |
| `SK_RavineTroll` | h 3,97 m (mesuré Blender) | §14.4 : 3,7-4,3 | 2 580 | 8 |
| `SK_CentaurHunter` | h 3,20 m, long 4,69 m (Blender) | §14.5 : 3,0-3,5 · 4,0-4,8 | 3 240 | 6 |

Les cotes des deux dernières créatures viennent de Blender : **elles ne sont
pas encore vérifiées dans Godot, faute de scène qui les monte.** Toutes les
autres sont mesurées sur la géométrie importée — c'est la seule autorité,
après avoir constaté deux fois que le log de l'outil pouvait mentir.

### Nouveau fichier de test

- `tests/integration/test_guardian_asset.gd` (6) : livraison et import
  propres, cotes de §15.1, anatomie par NOM de mesh, cristaux cachés au
  repos, **volumes de combat DANS le corps visible**, noyau qui s'allume.

### Tests RENFORCÉS (l'exigence a monté avec la Phase H)

- `test_the_three_families_have_distinct_bodies_not_just_distinct_tints`
  remplace un test de TEINTES par un test de CORPS : tailles dans les
  bandes, ordonnées, briseur le plus large, maillages distincts.
- `test_the_character_variants_have_distinct_silhouettes` ne compte plus
  les pièces greffées : il mesure les formes. Une assertion a été RETIRÉE
  parce qu'elle n'était pas mesurable — le rapport largeur/hauteur d'une
  AABB en pose T est dominé par l'envergure des bras et disait le contraire
  de la vérité. Ce critère relève de l'essai humain, et c'est écrit.
- `test_the_turquoise_tint_touches_the_outfit_and_never_the_skin` vérifie
  désormais que la peau garde SA couleur et SA texture, plutôt que
  l'absence de toute surcharge — l'isolation des matériaux est devenue
  inconditionnelle.

### Défauts réels trouvés

1. `matrix_world` PÉRIMÉE après reparentage : Blender annonçait 9,58 m
   quand Godot mesurait 14,50.
2. Le parentage « BONE » accroche l'objet à la QUEUE de l'os.
3. La boîte de collision du Gardien flottait à 0,80 m du sol : il tombait
   indéfiniment, ce qui le rendait plus lent en phase 3 qu'en phase 1.
4. L'isolation des matériaux n'était déclenchée que par une teinte : sans
   teinte, le télégraphe d'attaque n'avait plus rien où écrire.
5. L'échelle partait DEUX fois vers glTF (cuite par `export_apply` ET
   portée par le nœud) : 1,17 m mesuré pour 1,42 m attendu.

## 2026-08-03 — Phase H lot H.6 : continuité des personnages

Environnement : Godot 4.7.1.stable.custom_build a13da4feb, Blender 4.0.2,
conteneur Linux headless sans GPU (rendu logiciel Mesa llvmpipe pour les
captures).

### Commandes exécutées

```bash
tools/blender/rebuild_characters.sh all      # sources -> .glb -> continuité
blender --background --python tools/blender/check_continuity.py -- \
    --glb <modèle> --label <nom> [--gap 0.02] [--report N]
godot --headless --path . --script tools/godot/test_runner.gd -- --filter=creature
godot --headless --path . --script tools/godot/test_runner.gd -- --filter=raider
godot --headless --path . --script tools/godot/test_runner.gd -- --filter=guardian_asset
tools/validate_fast.sh
xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 \
    --script tools/godot/capture_reference.gd -- \
    --scene=res://scenes/tests/CharacterTurntable.tscn --creature=<id> ...
```

### Continuité — six personnages livrés

| Modèle | Morceaux | Verdict |
|---|---:|---|
| `SK_RavineTroll.glb` | 43 | un seul corps solidaire |
| `SK_CentaurHunter.glb` | 60 | un seul corps solidaire |
| `SK_StormGuardian.glb` | 113 | un seul corps solidaire |
| `SK_RaiderRed.glb` | 20 | un seul corps solidaire |
| `SK_RaiderBlue.glb` | 26 | un seul corps solidaire |
| `SK_RaiderBlack.glb` | 24 | un seul corps solidaire |

Tolérance 0,02 m. Géométrie lue APRÈS évaluation du graphe de dépendances,
donc après déformation par l'armature.

### Contrôle négatif du contrôle lui-même

Un test qui ne peut pas échouer ne prouve rien. Une copie du colosse dont le
nodule a été déplacé de 0,60 m est passée au même script :

| Modèle | Sortie |
|---|---|
| colosse avec une pièce déplacée de 0,60 m | **code 1** — « 1 PIÈCE DÉTACHÉE », « 2 GRAPPES SÉPARÉES » |
| colosse réparé | **code 0** — « UN SEUL corps solidaire » |

### Ce que ces mesures ne prouvent pas

La continuité géométrique n'est pas la beauté. Elle établit qu'aucune pièce
ne flotte ; elle ne dit rien de la qualité de sculpture, ni de la lisibilité
des silhouettes en aplat noir à 25 m, qui reste un essai humain (§30.3).

## 2026-08-03 — Validation complète après le lot des ancrages de récompense

**Commit** `b07c9cc` · **Moteur** Godot 4.7.1.stable.custom_build.a13da4feb ·
**Commande** `tools/validate_fast.sh`

| Niveau | Résultat |
|---|---|
| 0. Version du moteur | `[OK]` 4.7.1-stable confirmé |
| 1. Import des ressources | `[OK]` aucun parse error, code retour 0 |
| 1b. Parse de tous les scripts | `[OK]` 221 scripts, aucune erreur |
| 2. Tests unitaires et d'intégration | **584 réussis, 0 échoué** |
| 2b. Journal des tests | `[OK]` aucune erreur signalée |
| 3. Scène d'intégration (Boot → menu) | `[OK]` chargée, transition atteinte, quittée proprement |
| 3b. Continuité des personnages (ISS-019) | `[OK]` 6 modèles, un seul corps solidaire chacun |
| 4. Plancher de couverture | `[OK]` 584 exécutés, plancher 580 |

**Verdict : VERT.**

### Ce que deux passes précédentes ont appris

La première passe (commit `4100da7`) a rendu **3 échecs réels**, tous causés par
les nouvelles récompenses : un test reconnaissait le coffre de découverte au
NOM de son parent — critère devenu faux quand les récompenses sont devenues
filles de leur ancrage — et un autre exigeait « aucun pickup au sol », ce qui
n'avait de sens que tant qu'il n'en existait qu'un. Les deux ont été
**renforcés**, jamais assouplis.

La deuxième passe est à jeter : j'ai lancé un test filtré pendant qu'elle
tournait, et deux processus Godot partagent `user://slot0`. Elle a rendu onze
échecs sur le donjon et le traversal — sans rapport avec le lot — et un compte
de 576 tests au lieu de 584. La règle était déjà consignée (`docs/DECISIONS.md`) ;
elle a été enfreinte, et le résultat n'a servi qu'à le rappeler.

### Preuves visuelles jointes

`evidence/rewards/` — 31 vues, une par récompense, prises depuis le point où le
joueur se tiendra pour interagir, plus `manifest.json` (commit, moteur,
renderer, résolution, caméra et cible de chaque vue).

---

## 2026-08-05 — Revue contradictoire du Gate H (contexte frais)

Agent adversarial-qa, lecture seule, dossier `evidence/phaseH/`. VERDICT :
**FAIL**. North Star (`vista_h7_matiere.png`) scorée §30.2 domaine par
domaine : ≈ 31/90 vérifiables (~41/100 si le mouvement était parfait) —
défauts nommés : éclairage plat zénithal, camp hors cadre, pylône coupé,
éclair sans cœur blanc, trois langages de matériaux incompatibles, échelle
citadelle non crédible, herbe coupée net. §23.2 : 6 FAIL, 6 PARTIAL,
3 UNVERIFIED (aucune vidéo), 1 PASS (originalité/licences). Vices de
procédure relevés et corrigés dans la foulée : capture antérieure au code
livré, gate_boss aveugle non consigné (→ ISS-026), PROGRESS en retard,
lignes F/G contradictoires entre STATUS et ROADMAP. Stabilité temporelle :
BLOQUÉE sans vidéo/GPU réel (machine utilisateur).
