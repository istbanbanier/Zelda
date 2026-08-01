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

- **Date** : 2026-07-31 · **Statut** : **RÉSOLU — oui, partiellement**
- **Ce qui change selon la réponse** : les Gates C.5, H et I reposent entièrement
  sur des captures issues du moteur (§21.5). Sans elles, aucun score WOW ne peut
  être annoncé — jamais estimé.
- **Constat initial** : la machine n'a **aucun GPU** (`/dev/dri` absent), aucun
  affichage (`DISPLAY` vide). `xvfb-run` et Mesa/llvmpipe sont présents.
- **Expérience réalisée** : `scenes/tests/PipelineLab.tscn` (cube + rig importés,
  soleil, sky, caméra) capturée via
  `xvfb-run -a -s "-screen 0 2560x1440x24" godot --rendering-driver opengl3 --audio-driver Dummy`.
- **Mesure** : PNG 1920 × 1080 produit après 40 frames. Manifeste :
  `rendering_method=forward_plus`, `rendering_driver=llvmpipe (LLVM 20.1.2, 256 bits)`,
  `display_server=X11`. À l'image : les deux assets rendus, éclairés, matériaux
  corrects, aucune surface magenta.
- **Décision** : `tools/validate_release.sh` exécute réellement le niveau 5. La
  **régression visuelle** est donc possible dans cet environnement, ce qui n'était
  pas acquis. Le contrôle de non-régression du pipeline peut être automatisé dès
  maintenant plutôt que reporté.
- **Limites maintenues** :
  - llvmpipe est un rendu **logiciel** : aucune mesure de performance n'en découle
    (§20.1). Les niveaux 6 et 7 restent bloqués.
  - Les couleurs et le filtrage peuvent différer d'un GPU réel : les tolérances de
    comparaison visuelle devront être larges, et toute notation artistique fine
    exigera un vrai GPU.
  - Aucun périphérique audio (ALSA absent) : le test audio réel est impossible ici.
- **Réévaluer** : dès qu'une machine avec GPU est disponible — refaire une capture
  de la même scène et comparer.

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

## R-006bis — Un contrôle négatif qui mute la valeur par défaut d'un `@export` ne prouve rien

- **Date** : 2026-08-01 · **Phase** : B.1 · **Statut** : RÉSOLU, règle adoptée
- **Ce qui change selon la réponse** : la fiabilité de **tous** les contrôles
  négatifs portant sur du réglage. Un contrôle négatif qui ne casse rien renvoie
  « le test reste vert » et se lit à tort comme « le test est robuste ».
- **Constat, obtenu par accident puis reproduit** : pour vérifier que
  `test_steep_slope_is_rejected` mesure bien `max_floor_angle`, la valeur par
  défaut du script `locomotion_tuning.gd` a été passée de 46 à 70°. Le test est
  resté **vert** — lecture naturelle : « le test ne teste pas ce qu'il prétend ».
  C'était faux. La ressource réellement chargée est `locomotion_default.tres`, qui
  **sérialise sa propre valeur** ; la valeur par défaut du script n'est utilisée
  que pour une instance créée par `LocomotionTuning.new()`. En mutant le `.tres`,
  le test échoue comme attendu : « une pente à 60° ne doit pas être gravie :
  Y 0.00 -> 4.31 ».
- **Règle adoptée** : un contrôle négatif sur un réglage mute **la ressource
  effectivement chargée**, jamais la valeur par défaut du script. En cas de doute,
  relire le `.tres` avant de conclure.
- **Portée** : aucun contrôle négatif antérieur n'est invalidé — les ressources de
  tuning n'existent que depuis B.1. La règle vaut pour la suite.
- **Limite** : ce piège est silencieux par construction. Rien dans le moteur ne
  signale qu'une valeur par défaut est masquée par une ressource sérialisée.

---

## R-006ter — `SpringArm3D` : ce que le nœud fait réellement à ses enfants

- **Date** : 2026-08-01 · **Phase** : B.1 · **Statut** : RÉSOLU
- **Ce qui change selon la réponse** : la structure du `CameraRig` (§8.3) et la
  tenue du critère « la caméra ne traverse pas les murs » (§23.1).
- **Méthode** : documentation en ligne inaccessible (ISS-001) ; tout ci-dessous est
  **mesuré** sur le binaire 4.7.1-stable installé, dans `TraversalSandbox.tscn`.
- **Mesures** :

  | Configuration | Résultat mesuré |
  |---|---|
  | `Camera3D` enfant direct, `position.x = 0,32` | relue en `x = 0` — décalage effacé |
  | Nœud intercalé à position nulle, caméra dessous | caméra au bout du bras, anti-traversée intacte |
  | Nœud intercalé décalé de 1 m | décalage effacé (c'est lui l'enfant direct) |
  | Caméra petite-fille décalée de 1 m | **0,64 m au-delà** de la face du mur |
  | `margin` = 0,01 / 0,25 / 0,50 | longueur identique : 1,2650 m — sans effet ici |
  | `shape` = sphère r = 0,20 | caméra à 29,549 (face à 29,75) |
  | `shape` = sphère r = 0,35 | caméra à 29,399 — dégagement exactement égal au rayon |

- **Décisions qui en découlent** : D-014 (épaule sur le bras) et D-015 (sonde
  volumique).
- **À réévaluer** : si une version ultérieure de Godot est un jour imposée, ces
  sept mesures sont à rejouer avant de croire le code encore correct.

---

## Questions ouvertes pour les phases suivantes

| ID | Question | Phase | Décidera |
|---|---|---|---|
| R-006 | Interpolation physique : gain réel vs coût sur la cible ? (§20.9) | B | activer ou non |
| R-007 | Terrain : ArrayMesh déterministe ou addon audité/épinglé ? (§7.4) | D | pipeline terrain |
| R-008 | SDFGI demi-résolution vs LightmapGI sur la vue d'ouverture ? (§7.7) | H | preset High |
| R-009 | Substitut au motion warping : `ActionAlignmentComponent` suffit-il au mantle ? (§7.12) | B | qualité du mantle |
| R-010 | Nuage d'orage : couches de dômes vs raymarch Cinematic ? (§7.6) | H | coût de la North Star |
