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
