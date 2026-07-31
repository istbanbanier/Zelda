# RESEARCH LEDGER

Protocole §0.5 : une entrée = question précise, ce qui change selon la réponse,
sources, constat, mini-expérience, mesure, décision, limites, date de réévaluation.
Une liste de liens non appliquée n'est pas un apprentissage.

Statuts : `RÉSOLU` · `À VÉRIFIER` (affirmation non confirmée par une source primaire
ou une mesure locale) · `OUVERT`.

---

## R-001 — La version 4.7.1-stable existe-t-elle réellement, et sous quel commit ?

- **Date** : 2026-07-31 · **Statut** : RÉSOLU
- **Ce qui change selon la réponse** : tout. Si 4.7.1 n'existait pas, il faudrait
  documenter une migration vers une autre version stable (§5.1).
- **Méthode** : la documentation en ligne et les pages de téléchargement étant
  bloquées par la politique réseau, interrogation directe du dépôt Git officiel :
  `git ls-remote --tags https://github.com/godotengine/godot`.
- **Constat mesuré** : le tag `4.7.1-stable` existe et pointe sur
  `a13da4feb8d8aefc283c3763d33a2f170a18d541`. Le fichier `version.py` du tag
  confirme `major=4, minor=7, patch=1, status="stable"`. Tags voisins observés :
  `4.6.3-stable`, `4.7-stable`.
- **Décision** : version épinglée au commit dans `tools/setup_godot.sh`, qui refuse
  de construire un autre commit. Voir D-001.
- **Limite** : confirme la version du **moteur**, pas les signatures d'API. Toute
  API incertaine doit être vérifiée dans la source du tag ou testée localement.

---

## R-002 — Quels sont les noms exacts des réglages projet pour Forward+ et Jolt en 4.7.1 ?

- **Date** : 2026-07-31 · **Statut** : RÉSOLU
- **Ce qui change selon la réponse** : un nom erroné dans `project.godot` est
  silencieux — le projet tournerait avec le mauvais moteur physique sans erreur.
- **Méthode** : la doc en ligne étant inaccessible, lecture de la **source du tag**,
  qui est la source primaire la plus fiable :
  - `servers/physics_3d/physics_server_3d.cpp:1163` →
    `PhysicsServer3DManager::setting_property_name = "physics/3d/physics_engine"`
  - `modules/jolt_physics/register_types.cpp:59` → serveur enregistré sous le nom
    exact `"Jolt Physics"` (avec l'espace, sensible à la casse)
  - `main/main.cpp:2642` → `"rendering/renderer/rendering_method"`
  - `core/config/project_settings.h:161` → `CONFIG_VERSION = 5`
- **Mini-expérience** : `tests/unit/test_smoke.gd` relit ces trois réglages à
  l'exécution et échoue si l'un d'eux ne vaut pas la valeur attendue. La convention
  n'est donc pas seulement écrite, elle est testée.
- **Limite** : confirme que le réglage est **demandé**. Que Jolt soit réellement
  actif au runtime devra être vérifié en Phase A sur une simulation réelle.

---

## R-003 — L'exporter glTF de Blender 4.0.2 accepte-t-il le preset visé ?

- **Date** : 2026-07-31 · **Statut** : RÉSOLU
- **Ce qui change selon la réponse** : un mot-clé inconnu fait échouer l'export
  entier ; une option supposée présente mais absente change silencieusement le
  résultat (orientation, tangentes, animations).
- **Méthode** : introspection RNA de l'opérateur installé —
  `bpy.ops.export_scene.gltf.get_rna_type().properties.keys()` → 75 propriétés.
- **Erreur commise et corrigée** : première implémentation via
  `inspect.signature(...idname_py)`, qui renvoie la signature de la *méthode*, pas
  les propriétés de l'opérateur ; toutes les options étaient donc rejetées et
  l'export produisait un preset vide. Détecté parce que le fichier `.glb` n'était
  pas produit et que la validation a échoué — le script de validation a fait son
  travail.
- **Constat** : les 17 options du preset visé sont toutes supportées par
  `io_scene_gltf2` v4.0.44.
- **Dépendance découverte** : le paquet Ubuntu de Blender n'embarque pas `numpy`,
  dont l'exporter dépend → `ModuleNotFoundError`. Corrigé par `python3-numpy`.
- **Réévaluer** : à chaque changement de version de Blender.

---

## R-004 — Peut-on produire une capture depuis le renderer réel dans cet environnement ?

- **Date** : 2026-07-31 · **Statut** : À VÉRIFIER
- **Ce qui change selon la réponse** : les Gates C.5, H et I reposent entièrement
  sur des captures issues du moteur (§21.5). Sans elles, aucun score WOW ne peut
  être annoncé — jamais estimé.
- **Constat** : la machine n'a **aucun GPU** (`/dev/dri` absent), aucun affichage
  (`DISPLAY` vide). `xvfb-run` et Mesa/llvmpipe sont présents, donc un rendu
  **logiciel** est théoriquement possible avec `--rendering-driver opengl3`.
- **Expérience prévue** : dès le binaire disponible, `tools/validate_release.sh`
  tente la capture via Xvfb + llvmpipe et consigne le résultat réel.
- **Position tenue tant que non mesuré** : la capture est déclarée **NON VÉRIFIÉE**.
  Même en cas de succès, un rendu llvmpipe ne vaut **pas** comme mesure de
  performance (§20.1) — seulement comme preuve de non-régression visuelle grossière.

---

## R-005 — Git LFS est-il réellement disponible pour les binaires lourds ?

- **Date** : 2026-07-31 · **Statut** : OUVERT
- **Ce qui change selon la réponse** : §7.15 impose de vérifier que LFS est
  réellement disponible **avant** d'en dépendre pour `.blend`, `.glb`, textures
  maîtres, audio et vidéo.
- **Constat** : `git lfs` n'est pas installé sur cette machine, et la prise en
  charge côté dépôt distant n'est pas confirmée.
- **Décision provisoire** : `.gitattributes` prépare le suivi LFS mais **n'est pas
  activé**. Les assets de test actuels sont minuscules (2,5 Ko et 16 Ko) et
  versionnés normalement. Ne pas migrer vers LFS avant confirmation, sous peine de
  produire un dépôt que personne ne peut cloner correctement.
- **À faire** : confirmer la disponibilité LFS côté distant, puis décider.

---

## Questions ouvertes pour les phases suivantes

| ID | Question | Phase | Décidera |
|---|---|---|---|
| R-006 | Interpolation physique : gain réel vs coût sur la cible ? (§20.9) | B | activer ou non |
| R-007 | Terrain : ArrayMesh déterministe ou addon audité/épinglé ? (§7.4) | D | pipeline terrain |
| R-008 | SDFGI demi-résolution vs LightmapGI sur la vue d'ouverture ? (§7.7) | H | preset High |
| R-009 | Substitut au motion warping : `ActionAlignmentComponent` suffit-il au mantle ? (§7.12) | B | qualité du mantle |
| R-010 | Nuage d'orage : couches de dômes vs raymarch Cinematic ? (§7.6) | H | coût de la North Star |
