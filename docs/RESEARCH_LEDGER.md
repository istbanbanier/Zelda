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

## R-009 — `ActionAlignmentComponent` suffit-il au mantle ? — RÉSOLU : oui, à une condition

- **Date** : 2026-08-01 · **Phase** : B.3 · **Statut** : RÉSOLU
- **Question ouverte depuis le Gate 0** : §7.12 propose ce composant comme
  « substitut ciblé au motion warping ». Tient-il pour le franchissement de §9.3,
  qui exige « aucun snap visible » et une annulation propre ?
- **Réponse mesurée** : oui, **à condition qu'il suive un chemin et non un
  segment**. La version à interpolation directe échouait — non par à-coup, mais
  parce que la droite reliant le pied d'un rebord à son dessus **traverse le
  rebord**. Le contrôle de capsule de §7.12 faisait alors ce qu'on lui demande :
  il annulait à mi-parcours. Le cas nominal ne franchissait jamais, et la cause
  n'était ni le composant ni la géométrie mais la forme du trajet.
- **Correctif** : `begin_path()` accepte une polyligne, parcourue à vitesse
  maîtrisée par abscisse curviligne. Le mantle passe par un sommet situé
  `LEDGE_RISE_CLEARANCE` (6 cm) au-dessus de la surface d'arrivée — monter, puis
  avancer, ce que §9.3 appelle « mantle bas/haut ».
- **Pourquoi pas une courbe** : une Bézier quadratique a été écartée après calcul,
  pas par principe. Pour que les pieds soient déjà au-dessus du rebord au moment
  d'entrer dans son emprise, son point de contrôle devait culminer à 0,40 m
  au-dessus de la cible — un bond visible. La polyligne obtient le même résultat
  avec 6 cm.
- **Ce qui reste non prouvé** : le rendu. « Aucun snap visible » est vérifié par la
  mesure du plus grand pas et par l'absence de discontinuité, pas par un œil
  humain sur une animation — laquelle n'existe pas (Phase H).
- **À réévaluer** : quand `ActionAlignmentComponent` servira aux coffres, à la
  cuisine et au pylône (§7.12). Ces actions n'ont pas d'obstacle sur le trajet ;
  `begin()` devrait leur suffire.

---

## R-011 — Une sonde horizontale ne rencontre jamais une pente douce

- **Date** : 2026-08-01 · **Phase** : B.3 · **Statut** : RÉSOLU, contrainte géométrique
- **Ce qui change selon la réponse** : la couverture réelle du filtre d'angle de
  §9.2, et la façon d'écrire un test qui prétend l'exercer.
- **Constat** : un test devait vérifier qu'une pente à 40° est refusée pour
  `too_shallow`. Elle est refusée — mais pour `no_wall`. Un rayon horizontal parti
  de la hauteur du torse `h` ne rencontre une pente d'angle θ qu'à la distance
  `h / tan θ`. Avec `h = 1,10 m` et une portée d'accroche de 0,70 m, la sonde ne
  touche que les surfaces telles que `tan θ ≥ 1,571`, soit **θ ≥ 57,5°**.
- **Conséquence** : à l'approche depuis le sol, le filtre d'angle ne peut pas
  départager quoi que ce soit — la géométrie s'en charge avant lui. Il agit
  seulement sur les parois irrégulières rencontrées **en cours d'escalade**, où
  l'origine de la sonde est déjà en hauteur (§9.2, « suivre irrégularités »).
- **Décision de test** : le filtre est vérifié là où il agit, sur la pente à 60° du
  bac à sable, en comparant deux seuils sur la même sonde au même endroit. Le test
  d'approche, lui, n'affirme plus qu'une raison de refus qu'il ne peut pas obtenir.
- **Limite** : cette borne dépend de trois réglages (`probe_chest_height`,
  `grab_reach_m`, et l'angle). Les changer déplace le seuil de 57,5° sans que rien
  ne le signale.

---

## R-017 — Une suite lancée pendant une capture llvmpipe ment

- **Date** : 2026-08-04 · **Phase** : H-5 · **Statut** : RÉSOLU, règle adoptée
- **Ce qui change selon la réponse** : la confiance dans TOUT verdict de
  `validate_fast` — trois suites successives ont déclaré le donjon cassé
  (S1 apparent : porte du boss fermée, circuits à 1/3 puis 2/3, INSTABLE).
- **Constat (bissection par les journaux)** : vert sur l'arbre H-1 au repos ;
  rouge sur H-2/H-3… qui ont TOUTES tourné pendant des captures llvmpipe ou
  d'autres suites. Contre-épreuve sur machine au repos, arbre final :
  donjon 29+32 assertions vertes, suites électriques 12/10/5 vertes.
  Zéro régression réelle. Les tests d'intégration électriques (batteries,
  portes, débits) dépendent du temps réel par tick — la contention CPU les
  fait dériver. Second facteur : une suite longue lit les fichiers PENDANT
  les éditions de la session (dérive d'arbre) — 4 des 14 rouges étaient un
  test chargé avant son implémentation.
- **Règle adoptée** : sérialiser suites complètes et captures llvmpipe —
  jamais en parallèle ; ne JUGER une suite complète que lancée sur un arbre
  committé et une machine au repos. Un rouge instable (1/3 puis 2/3) est un
  symptôme de contention avant d'être un bug.
- **Dette réelle notée** (KNOWN_ISSUES) : des tests sensibles au wall-clock
  restent fragiles par construction — un budget de ticks logique plutôt que
  du temps réel serait la vraie correction.

---

## R-015 — Silhouette de montagne : `PrismMesh.left_to_right` fait le pic asymétrique

- **Date** : 2026-08-04 · **Phase** : H-1 · **Statut** : RÉSOLU, appliqué
- **Ce qui change selon la réponse** : le remplacement du « mur de gratte-ciels »
  (crêtes et skyline en `BoxMesh`) par des silhouettes de montagne, sans ArrayMesh
  sur mesure ni asset sculpté.
- **Constat** (source `4.7.1-stable`, `doc/classes/PrismMesh.xml`) : `PrismMesh`
  expose `left_to_right` (défaut 0,5) qui déplace le sommet le long de l'arête —
  deux pentes inégales par pic, en une primitive. L'arête court le long de Z local
  (déjà vérifié par le helper `_visual_prism` de V4.2) ; `CylinderMesh` avec
  `top_radius = 0` donne le cône de la pointe de spire (la doc le dit explicitement).
- **Décision** : crêtes (44) et massifs lointains (64) convertis en prismes à sommet
  décentré déterministe (formules sinusoïdales, pas de RNG) ; la spire de la
  citadelle finit en cône. Invariant testé : zéro `BoxMesh` sous `BorderCrests` et
  `FarSkyline` (`test_phase_h_silhouettes.gd`).
- **Limite** : un prisme reste une tente — le vrai modelé attend des masses
  sculptées (Phase H suite). C'est la silhouette qui était fausse, elle seule est
  corrigée ici.

---

## R-016 — La vue rasante mange la variation macro : anisotrope obligatoire

- **Date** : 2026-08-04 · **Phase** : H-2c · **Statut** : RÉSOLU, appliqué
- **Ce qui change selon la réponse** : pourquoi deux versions successives du sol
  moucheté, CORRECTES vues du dessus (sondes : écart-type 0,093-0,094), rendaient
  un aplat parfait dans la vista (stddev inchangé au pixel près).
- **Constat** (mesuré, trois sondes) : (1) la distribution FBM est gaussienne —
  un gradient étalé sur 0..1 donne un quasi-aplat (0,039) ; le resserrer sur la
  bande centrale double le contraste (0,094). (2) Même contrasté, le motif
  disparaît à la caméra de JEU : à 1,7 m du sol, l'angle est rasant, le
  trilinéaire retombe dans les mips basses et moyenne tout motif de ~4 m en
  aplat à quelques mètres. Vue plongeante : moucheté ; vue rasante : rien.
- **Décision** : `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC` sur le
  matériau de sol + motifs portés à ~15 m (fréquence 0,008, tuile 60 m).
  Sonde rasante après correctif : écart-type 0,114, motifs lisibles à l'horizon.
- **Règle durable** : toute validation d'un matériau de SOL se fait en vue
  rasante à hauteur de caméra de jeu — jamais en vue plongeante seule. Le test
  de régression mesure la texture générée (≥ 0,06), la sonde valide la vue.

---

## R-014 — `Area3D.monitoring` coupé puis rallumé entre deux ticks : chevauchements perdus

- **Date** : 2026-08-01 · **Phase** : C.0 · **Statut** : RÉSOLU, règle adoptée
- **Ce qui change selon la réponse** : la manière d'ouvrir et fermer la fenêtre
  active d'une hitbox (§10.1) — et tout futur usage d'`Area3D` intermittent.
- **Constat, mesuré sur le binaire installé** : hurtbox en plein chevauchement ;
  `monitoring = false` puis `monitoring = true` posés dans le même intervalle
  entre deux ticks physiques (fin d'un swing, début du suivant). Résultat :
  `get_overlapping_areas()` reste **définitivement vide** — encore 0 six frames
  plus tard, alors que le premier swing voyait 1 chevauchement dès le tick
  suivant son activation.
- **Règle adoptée** : `monitoring` reste allumé en permanence sur les hitbox ; la
  fenêtre active est portée par un drapeau `_active` et le balayage en
  `_physics_process`, coupé hors fenêtre (§5.4). Le suivi de paires permanent est
  un coût négligeable ; un swing muet un tick sur deux serait un bug de gameplay
  intraçable.
- **Limite** : mesuré pour la séquence off→on dans la même frame. Un toggle
  espacé de plusieurs frames n'a pas été caractérisé — inutile tant que la règle
  ci-dessus tient.

---

## R-014 — Comment un dépôt piloté par agents tient-il sa barre de qualité à grande échelle ?

- **Date** : 2026-08-07 · **Statut** : RÉSOLU (mécanisme adopté), test d'invariants `À VÉRIFIER`
- **Ce qui change selon la réponse** : la façon dont ce projet fait respecter ses
  invariants. Ils sont aujourd'hui entièrement en **prose** dans `CLAUDE.md` : rien
  n'empêche une session de les enfreindre sans s'en apercevoir, et la suite complète
  met une vingtaine de minutes — trop pour tourner en boucle d'édition.
- **Source étudiée** : `levy-street/world-of-claudecraft`, cloné en local et inspecté
  intégralement (branches, tags, historique, refs de PR). Mesures réelles :
  9 873 commits en deux mois (10 juin → 7 août 2026), 570 branches, 46 tags,
  2 623 refs de PR, 836 PR fusionnées sur `main`, ~150 à 344 commits/jour, une
  cinquantaine de contributeurs.
- **Constat mesuré, ce qui rend l'échelle tenable** :
  1. **Une barre en couches, chacune au point le moins cher où elle sert encore.**
     Hook `Stop` (millisecondes, chaque tour) → `pre-push` (secondes) → gate sélectif
     (pré-fusion) → CI → file de fusion → gate nocturne. Chaque couche est explicitement
     documentée avec son coût et si elle bloque (`docs/qa-gate.md`).
  2. **Les invariants sont EXÉCUTABLES, pas seulement écrits.**
     `tests/architecture.test.ts` fait 1 891 lignes et balaye chaque fichier du cœur
     pour interdire `Math.random`, `Date.now`, les imports DOM/Three. La prose dit la
     règle ; le test la fait rougir.
  3. **`CLAUDE.md` hiérarchique** : 51 fichiers, un par répertoire, chargés à la
     demande. La racine tient en ~200 lignes et interdit explicitement d'y dupliquer
     le contenu local.
  4. **Le hook instantané ne contrôle QUE l'indiscutable** (tiret cadratin, emoji,
     `.only(`, `debugger`) et ne lance ni typecheck, ni tests, ni agent — parce
     qu'il se déclenche à chaque tour.
  5. **`fix` (2 573) dépasse `feat` (1 850)**, et `test` est un type de commit de
     premier rang (1 043). La réparation et la vérification ne sont pas un reliquat.
- **Décision adoptée ici** : transposer le **mécanisme**, pas les règles — les
  invariants de ClaudeCraft (tirets, emojis) ne sont pas les nôtres. Créés :
  `.claude/hooks/qa-stop.sh` (quatre invariants durs du `CLAUDE.md` sur les lignes
  ajoutées), `.githooks/pre-push` (mêmes règles sur le diff poussé + `--check-only`
  des `.gd` modifiés), `.claude/hooks/ensure-hooks.sh`, `.claude/settings.json`,
  `tests/unit/test_invariants.gd`. Voir D-0xx et `.claude/hooks/README.md`.
- **Mesure locale, avant construction** : les invariants tiennent aujourd'hui —
  `move_left` est bien lié au `physical_keycode` 65 (`KEY_A`, donc le `Q` d'un
  AZERTY) et non à `keycode` ; `lock_on` est sur `C` ; **zéro** déclaration GDScript
  non typée dans `scripts/`, `tests/`, `tools/` ; aucun terme Nintendo hors `docs/`.
  Le garde-fou est donc une protection **anti-régression**, pas un rattrapage de dette.
- **Preuve du hook** : exécuté sur quatre scénarios — arbre propre (muet), garde
  anti-boucle (muet), trois violations injectées (les trois attrapées avec fichier et
  extrait), huit formes GDScript typées légitimes (`:=`, `: Type =`, `@export`,
  `@export_range`, `static var`, `Array[String]`, `const`, inférence) → **zéro faux
  positif**. Arbre restauré propre après chaque essai.
- **Limite, et elle est nette** : `tests/unit/test_invariants.gd` est **écrit mais
  jamais exécuté** — Godot est absent de ce conteneur (`tools/setup_godot.sh` demande
  ~90 min). Ses chemins de réglages ont été vérifiés statiquement contre
  `project.godot` (section `[debug]` → `debug/gdscript/warnings/...`), rien de plus.
  Statut `À VÉRIFIER` jusqu'au premier `tools/validate_fast.sh` sur une machine avec
  moteur. Le `pre-push` ne peut pas non plus parser les scripts ici, et il le dit
  au lieu de laisser croire le contraire.
- **À réévaluer** : quand Godot sera disponible, exécuter la suite et faire passer
  R-014 en `RÉSOLU` complet. Piste non retenue pour l'instant, faute de CI de test :
  la file de fusion et le gate nocturne de ClaudeCraft, qui supposent une CI qui
  exécute réellement les tests — les trois workflows actuels ne le font pas.

---

## Questions ouvertes pour les phases suivantes

| ID | Question | Phase | Décidera |
|---|---|---|---|
| R-006 | Interpolation physique : gain réel vs coût sur la cible ? (§20.9) | B | activer ou non |
| R-007 | Terrain : ArrayMesh déterministe ou addon audité/épinglé ? (§7.4) | D | pipeline terrain |
| R-008 | SDFGI demi-résolution vs LightmapGI sur la vue d'ouverture ? (§7.7) | H | preset High |
| ~~R-009~~ | ~~Substitut au motion warping~~ | B | **RÉSOLU en B.3** — voir l'entrée R-009 ci-dessus |
| R-010 | Nuage d'orage : couches de dômes vs raymarch Cinematic ? (§7.6) | H | coût de la North Star |
| R-012 | Saut pressé pendant un mantle : perdu aujourd'hui (fronts consommés chaque tick). Faut-il un buffer inter-modes ? | C | ressenti des enchaînements |
| R-013 | Le mantle est gratuit, même à endurance quasi nulle. Coût ou pas ? §9.1 ne le tarife pas. | C | équilibrage traversal |
