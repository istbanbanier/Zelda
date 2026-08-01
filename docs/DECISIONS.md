# DECISIONS — architecture, art, gameplay

Format : une décision = contexte, options réellement pesées, choix, raison,
conséquences, et condition de réévaluation. Une décision sans alternative rejetée
est une préférence, pas une décision.

---

## D-001 — Godot 4.7.1-stable compilé depuis la source

- **Date** : 2026-07-31 · **Phase** : 0 · **Statut** : ADOPTÉE
- **Contexte** : MASTER_SPEC §5.1 impose Godot 4.7.1-stable exactement. Aucun binaire
  officiel n'est téléchargeable ici : la politique réseau de l'environnement refuse
  `godotengine.org` et `downloads.godotengine.org` (CONNECT → 403). `apt` ne propose
  que Godot 3.5.2 (mauvaise version majeure). Ni PyPI ni npm ne distribuent le moteur
  (`pypi/godot` = bibliothèque DOT, `npm/godot` = processeur d'événements).
- **Options pesées** :
  1. *Rester bloqué et ne rien livrer* — rejeté : la majorité de la Phase 0 ne dépend
     pas de l'exécution du moteur.
  2. *Utiliser Godot 3.5.2 d'apt* — rejeté : mauvaise version majeure, API
     incompatible, invaliderait tout ce qui serait écrit ensuite.
  3. *Compiler 4.7.1 depuis la source* — **choisi** : `github.com` est accessible en
     lecture git, le tag `4.7.1-stable` existe et est épinglable au commit.
- **Choix** : cloner le tag `4.7.1-stable` (commit `a13da4feb8d8aefc283c3763d33a2f170a18d541`)
  et compiler `target=editor` pour linuxbsd x86_64.
- **Conséquences** : `tools/setup_godot.sh` est indispensable à toute session neuve
  (~60-120 min sur 4 cœurs). Le binaire n'est pas versionné dans le dépôt.
  Le commit est vérifié par le script, qui refuse de construire autre chose.
- **Réévaluer si** : la politique réseau change (préférer alors le binaire officiel),
  ou si le projet migre vers une version stable ultérieure — ce qui exige de
  documenter et valider la migration (§5.1).

---

## D-002 — Blender 4.0.2 (paquet Ubuntu) comme DCC de référence de cet environnement

- **Date** : 2026-07-31 · **Phase** : 0 · **Statut** : ADOPTÉE AVEC RÉSERVE
- **Contexte** : `download.blender.org` est également bloqué. Le dépôt Ubuntu noble
  fournit Blender 4.0.2 avec l'exporter `io_scene_gltf2` v4.0.44.
- **Options pesées** : compiler Blender depuis la source (coût très supérieur au
  bénéfice, Blender n'est pas sur le chemin critique du moteur) contre utiliser
  le paquet distribution — **choisi**.
- **Réserve** : 4.0.2 n'est pas la dernière version. §7.15 impose de ne jamais
  supposer les options d'une autre version : `tools/blender/export_gltf.py`
  interroge donc les propriétés RNA réellement déclarées par l'exporter installé
  et journalise toute option rejetée, au lieu de coder en dur un preset.
- **Conséquence mesurée** : le paquet Ubuntu n'embarque pas numpy alors que
  l'exporter glTF en dépend — `python3-numpy` est une dépendance obligatoire du
  poste, consignée dans `docs/BUILD_ENVIRONMENT.md`.
- **Réévaluer si** : un poste de production dispose d'une version plus récente ;
  refaire alors tourner `tools/blender/run_export.sh` et comparer les manifestes.

---

## D-003 — `.glb` comme format d'échange, jamais `.blend` importé directement

- **Date** : 2026-07-31 · **Phase** : 0 · **Statut** : ADOPTÉE
- **Contexte** : §7.15. L'import `.blend` direct par Godot appelle Blender comme
  convertisseur et crée une dépendance de poste.
- **Choix** : les `.blend` restent dans `source_assets/`, hors de `res://` ; seuls
  des `.glb` exportés et validés entrent dans `assets/`.
- **Conséquence** : un export est toujours reproductible en ligne de commande, et
  un poste sans Blender peut quand même construire le jeu.

---

## D-004 — Validation glTF hors moteur en complément de l'import Godot

- **Date** : 2026-07-31 · **Phase** : 0 · **Statut** : ADOPTÉE
- **Contexte** : quand l'import échoue, il faut pouvoir dire si le défaut vient de
  la source ou du moteur. De plus, la moitié « source » du pipeline doit rester
  prouvable même quand le moteur est indisponible.
- **Choix** : `tools/gltf_inspect.py`, pur Python sans dépendance, vérifie en-tête
  binaire, échelle, pivot (min Y ≈ 0), attributs, comptages, skins et animations.
- **Rejeté** : dépendre d'un validateur Khronos externe (réseau bloqué, et une
  dépendance de plus pour un besoin étroit).
- **Limite assumée** : il ne remplace pas l'import Godot ; les deux sont exigés
  avant de déclarer un asset conforme.

---

## D-005 — `validate_release.sh` refuse de s'exécuter sans capacité de rendu

- **Date** : 2026-07-31 · **Phase** : 0 · **Statut** : ADOPTÉE
- **Contexte** : §0.7 et §20.1 interdisent d'annoncer un résultat visuel ou de
  performance non mesuré. Un script qui « passe » en sautant silencieusement les
  étapes impossibles fabrique exactement ce mensonge.
- **Choix** : le script détecte l'absence d'affichage/GPU et sort en **code 3
  « BLOQUÉ »**, distinct de 0 (vert) et 1 (rouge). Un gate ne peut donc pas être
  déclaré PASS par un chemin qui n'a rendu aucune frame.
- **Conséquence** : les Gates C.5, H et I resteront `BLOQUÉ` tant que ce projet
  n'est pas construit sur une machine avec GPU.

---

## D-006 — Gate 0 gelé « accepté avec réserves », sur décision du propriétaire

- **Date** : 2026-08-01 · **Phase** : 0 → A · **Statut** : ADOPTÉE
- **Contexte** : quatre revues adverses à contexte frais ont rendu `FAIL`. Chacune
  a trouvé des défauts réels et trois ont réfuté un correctif de la précédente.
  Tous les défauts bloquants identifiés sont corrigés et couverts par des contrôles
  négatifs rejoués (TEST_REPORT T-08, T-09, T-10). Les critères 3, 4 et 5 du Gate 0
  sont `PASS` depuis la deuxième revue.
- **Problème** : la boucle de durcissement portait sur un harnais de test évalué
  **contre un auteur de test hostile**, alors que le projet n'a aucun gameplay et
  que son risque dominant est ailleurs (RSK-01, art et animation, `G1`).
- **Options pesées** :
  1. *Poursuivre les revues jusqu'à un `PASS` franc* — rejeté : rendements
     décroissants, et rien n'indique qu'une passe supplémentaire ne trouverait pas
     encore un vecteur d'attaque théorique.
  2. *Déclarer `PASS`* — **refusé** : aucune revue ne l'a prononcé, ce serait
     exactement la validation prématurée que §0.7 interdit.
  3. *Geler en « accepté avec réserves » et passer en Phase A* — **choisi par le
     propriétaire du projet**, avec les réserves écrites ci-dessous.
- **Verdict enregistré** : Gate 0 = **GELÉ / ACCEPTÉ AVEC RÉSERVES**, jamais `PASS`.
- **Réserves qui restent ouvertes** :
  - critère 1 (reprise d'une session neuve en < 5 min) : `NON VÉRIFIÉ` — vérifié
    par relecture, pas par une session réellement repartie de zéro ;
  - un auteur de test peut encore remplacer l'enregistreur depuis une méthode ;
  - `--check-only` ne résout pas les appels dynamiques ;
  - le contrôle de contribution prouve que la géométrie apparaît, pas qu'elle
    apparaît correctement — la comparaison à une image de référence (§21.8) reste
    à construire quand il y aura du contenu ;
  - ISS-003 (image North Star non versionnée) et ISS-005 (licence sortante).
- **Réévaluer** : le critère 1 sera exercé pour de vrai au démarrage de la prochaine
  session neuve — c'est son premier acte. Les autres réserves sont réévaluées au
  Gate C.5, quand il existera du contenu visuel à juger.

---

## D-007 — Le voile de fondu appartient à `SceneFlow`, pas à `Boot.tscn`

- **Date** : 2026-08-01 · **Phase** : A · **Statut** : ADOPTÉE
- **Contexte** : §6.1 place `FadeLayer` et `LoadingUI` dans `Boot.tscn`.
- **Problème** : `Boot.tscn` est déchargé au premier changement de scène. Un voile
  de fondu qui y vit disparaît donc au moment exact où il sert — pendant la
  transition. L'écran serait noir sans voile, ou le fondu sauterait.
- **Choix** : `SceneFlow` (autoload, donc persistant) crée et détient son propre
  `CanvasLayer` + `ColorRect`. Écart assumé et documenté par rapport à la lettre de
  §6.1, en respectant son intention : « les transitions ne laissent aucun ancien
  nœud actif ».
- **`LoadingUI`** : non créé. Aucune scène n'est assez lourde pour le justifier et
  rien ne permettrait de mesurer s'il aide. Il arrive en Phase I avec le chargement
  en arrière-plan (§20.10), pas avant.
- **Vérifié par** : `test_autoloads.gd::test_scene_flow_owns_its_fade_layer`.

---

## D-008 — `EventBus` volontairement vide à la Phase A

- **Date** : 2026-08-01 · **Phase** : A · **Statut** : ADOPTÉE
- **Contexte** : §5.6 impose que l'EventBus ne porte que des événements
  **réellement globaux**.
- **Constat** : à la Phase A, aucun événement ne remplit ce critère. Le flux et la
  pause appartiennent à `GameState`, les transitions à `SceneFlow`, la sauvegarde à
  `SaveSystem` ; les dégâts, la mort et le butin appartiendront aux composants de
  l'entité concernée.
- **Options pesées** :
  1. *Pré-déclarer des signaux « au cas où »* — rejeté : API spéculative que
     personne n'écoute, et surtout invitation à tout faire transiter par le bus dès
     la phase suivante, soit exactement le couplage global que §5.6 veut éviter.
  2. *Ne pas créer l'autoload du tout* — rejeté : l'emplacement architectural doit
     exister pour que le premier vrai besoin ne parte pas ailleurs.
  3. *Le créer vide, avec une politique explicite* — **choisi**.
- **Règle d'ajout** : un signal n'entre dans l'EventBus qu'accompagné, dans le même
  changement, d'un émetteur réel, d'au moins un récepteur réel et d'une entrée ici.
- **Vérifié par** : `test_autoloads.gd::test_event_bus_is_intentionally_empty`,
  qui échoue dès qu'un signal est ajouté — l'ajout devient une décision visible en
  revue plutôt qu'une dérive.

---

## D-009 — Le runner de tests reconstitue les autoloads et travaille dans `_initialize()`

- **Date** : 2026-08-01 · **Phase** : A · **Statut** : ADOPTÉE
- **Contexte** : un `MainLoop` personnalisé lancé par `--script` remplace la
  `SceneTree` par défaut. Deux conséquences mesurées sur 4.7.1 :
  1. Godot n'y installe **pas** les autoloads déclarés dans `project.godot` ;
  2. pendant `_init()`, `Engine.get_main_loop()` renvoie `null` — vérifié par sonde.
- **Symptôme** : tous les tests de fondation échouaient dans le runner alors que le
  jeu démarrait correctement — un **faux rouge**, aussi trompeur qu'un faux vert.
- **Choix** : le runner instancie les autoloads déclarés, laisse passer une frame
  pour que leurs `_ready()` s'exécutent, et déplace tout son travail de `_init()`
  vers `_initialize()`.
- **Bénéfice** : la présence, l'instanciation et l'initialisation de chaque autoload
  déclaré deviennent elles-mêmes testées.
- **Limite** : l'ordre d'installation suit celui de `project.godot`. Un autoload qui
  dépendrait d'un autre pendant son `_ready()` exigerait un ordre explicite ; aucun
  ne le fait aujourd'hui.

---

## D-010 — Le runner de tests attend les méthodes asynchrones

- **Date** : 2026-08-01 · **Phase** : A · **Statut** : ADOPTÉE
- **Contexte** : vérifier que Jolt **simule** exige de faire avancer de vraies
  frames physiques, donc des méthodes de test asynchrones.
- **Constat mesuré par sonde (4.7.1)** : un appel synchrone renvoie `NIL` ; l'appel
  d'une méthode contenant `await` rend la main immédiatement en renvoyant un objet
  de coroutine (`TYPE_OBJECT`), qui n'est pas un `Signal`.
- **Défaut réel rencontré** : `_run_script()` est devenue coroutine en attendant
  les tests, mais la boucle d'appel ne l'attendait pas. Deux tests sur trois du
  fichier de physique étaient **silencieusement abandonnés** — la suite affichait
  vert. Seul l'écart de décompte l'a révélé.
- **Choix** : le runner attend la coroutine du test **et** attend `_run_script()`.
  Le plancher `MIN_TESTS` reste la seconde ligne de défense contre cette classe
  d'échec, qui est invisible autrement.
- **Vérifié par** : contrôle négatif `A2_test_asynchrone_echec_tardif.log` — une
  assertion fausse placée après deux `await` est bien attribuée à son test et fait
  sortir le runner en 1.

---

## D-011 — `SceneFlow` laisse toujours passer une frame avant de changer de scène

- **Date** : 2026-08-01 · **Phase** : A · **Statut** : ADOPTÉE
- **Défaut réel** : `Boot._ready()` appelait `SceneFlow.go_to()`, qui appelait
  `change_scene_to_file()` alors que l'arbre ajoutait encore des enfants →
  `ERROR: Parent node is busy adding/removing children`. En mode headless le fondu
  rend la main sans attendre, donc rien ne garantissait le délai que le fondu
  procurait accidentellement en mode graphique.
- **Choix** : `go_to()` attend une frame complète avant le changement, quel que
  soit le mode de rendu. Correction dans `SceneFlow` et non dans `Boot` : tout
  appelant depuis un `_ready()` rencontrerait le même problème.
- **Vérifié par** : niveau 3 de `validate_fast.sh`, qui lance réellement le jeu
  sur 90 frames et exige la trace d'arrivée au menu — un import vert ne suffit pas.

---

## D-012 — Gate A accepté avec réserve, bloqué sur la validation manette

- **Date** : 2026-08-01 · **Phase** : A → B · **Statut** : ADOPTÉE
- **Contexte** : la campagne manuelle du Gate A a été menée sur Mac. Les étapes
  lancement, clavier AZERTY et navigation du menu sont rapportées conformes ;
  aucune manette n'était disponible. La reprise en session à contexte frais a
  ensuite été mesurée et réussie (1 min 12 s, `evidence/gateA/05_reprise.md`).
- **Options pesées** :
  1. *Attendre une manette* — rejeté par le propriétaire : arrêt indéfini du
     projet pour un critère qui n'affecte pas le travail de la Phase B.
  2. *Déclarer `PASS`* — **refusé** : §23.1 exige « clavier AZERTY **et** manette
     fonctionnels ». Un critère non testé est `NON VÉRIFIÉ`, jamais implicitement
     réussi. Ce serait la validation prématurée que §0.7 interdit.
  3. *Accepter avec réserve, dette explicite* — **choisi par le propriétaire**.
- **Verdict enregistré** : Gate A = **ACCEPTÉ AVEC RÉSERVE / BLOQUÉ SUR LA
  VALIDATION MANETTE**. Jamais `PASS`.
- **Dette** : `CONTROLLER-001`, `S2`, à lever **avant la release finale** et
  recommandée avant le Gate C — le combat dépend des gâchettes, des sticks et du
  lock-on d'une façon que le clavier ne représente pas.
- **Contrainte imposée à la Phase B**, pour que la dette reste payable sans
  réécriture :
  - l'InputMap est **séparé** de la logique de gameplay par une couche d'intention ;
  - aucune logique ne dépend du clavier ; rien ne lit `Input.is_key_pressed()` ni
    une constante `KEY_*` hors de la couche d'entrée et de l'outillage ;
  - toute action nouvelle naît avec sa liaison manette, sans exception ;
  - aucun raccourci clavier codé en dur.
  Ces quatre points sont **vérifiés par un test**, pas seulement écrits.
- **Réévaluer** : à la levée de `CONTROLLER-001`, ou au Gate C si elle traîne.

---

## D-013 — La couche d'intention d'entrée sépare le périphérique du gameplay

- **Date** : 2026-08-01 · **Phase** : B · **Statut** : ADOPTÉE
- **Contexte** : la Phase B se développe au clavier alors que la manette n'est pas
  testée (CONTROLLER-001). Le risque n'est pas que la manette soit cassée — les
  liaisons existent — mais que du code de gameplay finisse par **supposer** un
  clavier, rendant la dette impayable sans réécriture.
- **Choix** : le gameplay ne lit jamais l'InputMap directement. Il consomme une
  **intention** typée (`InputIntent`), produite par un seul lecteur
  (`PlayerInputReader`) : vecteur de déplacement normalisé, états maintenus,
  fronts montants. Le gameplay ignore d'où vient l'entrée.
- **Bénéfices concrets** :
  - un test peut injecter une intention sans périphérique, donc la locomotion est
    testable en headless sans simuler de touches ;
  - le remapping (§17.5) et la détection de périphérique (§8.5) auront un seul
    point d'entrée ;
  - une zone morte de stick se traite au même endroit que la normalisation
    clavier, au lieu d'être dispersée.
- **Rejeté** : lire `Input.get_vector()` directement dans le contrôleur du joueur —
  plus court, mais lie la logique au périphérique et rend la dette manette
  invérifiable autrement qu'en jouant.
- **Vérifié par** : `test_input_layer_isolation.gd`, qui échoue si un script de
  gameplay lit une touche ou une constante `KEY_*`.

---

## D-014 — Le décalage d'épaule vit sur le `SpringArm3D`, pas sur la `Camera3D`

- **Date** : 2026-08-01 · **Phase** : B.1 · **Statut** : ADOPTÉE
- **Contexte** : §8.3 exige **deux** choses qui semblent se contredire — une
  `Camera3D` **enfant direct** du `SpringArm3D`, et un décalage d'épaule de
  0,25–0,40 m.
- **Comportement mesuré** sur Godot 4.7.1-stable (pas lu dans une doc, pas déduit) :
  - `SpringArm3D` **réécrit intégralement** la position locale de ses enfants
    directs à chaque image. Une `Camera3D` posée en `x = 0,32` est relue en
    `x = 0` : le décalage disparaît sans erreur ni avertissement. C'est le défaut
    réel qui a motivé cette décision — il était présent et invisible.
  - Un descendant **plus profond** conserve son décalage, mais le cast du bras n'en
    tient pas compte : caméra petite-fille décalée de 1 m sur l'axe du bras,
    mesurée **0,64 m au-delà** de la face du mur du bac à sable. C'est exactement
    la traversée que §23.1 interdit — et la vraie raison de l'exigence « enfant
    direct ».
- **Choix** : le décalage d'épaule est porté par le **bras** ; la caméra reste
  enfant direct, à position nulle. Effet secondaire recherché : l'origine du cast
  se décale aussi, donc l'obstacle est testé depuis l'épaule et non depuis l'axe
  du personnage.
- **Rejeté** : intercaler un nœud d'offset sous le bras — le décalage y est soit
  effacé (enfant direct), soit ignoré par le cast (descendant), selon la
  profondeur. Les deux ont été mesurés.
- **Vérifié par** : `test_camera_rig.gd::test_shoulder_offset_survives_the_spring_arm`
  et `::test_spring_arm_pulls_the_camera_in_front_of_a_wall`, tous deux avec
  contrôle négatif rejoué.

---

## D-015 — La caméra sonde les obstacles avec un volume, pas un rayon

- **Date** : 2026-08-01 · **Phase** : B.1 · **Statut** : ADOPTÉE
- **Contexte** : §8.3 exige « zéro traversée ». Le `SpringArm3D` par défaut lance
  un **rayon**.
- **Comportement mesuré** : avec un rayon, la caméra s'arrête à **0,8 mm** de la
  face du mur — techniquement en deçà, visuellement dedans, et le moindre mouvement
  la fait basculer de l'autre côté. `SpringArm3D.margin` **ne corrige pas** ce
  point : testé à 0,01 / 0,25 / 0,50, la longueur mesurée est restée identique
  (1,2650 m dans les trois cas).
- **Choix** : assigner une `SphereShape3D` de rayon `camera_probe_radius` (0,35 m)
  au bras. Mesuré : la caméra s'arrête exactement à 0,35 m de la face
  (29,75 − 0,35 = 29,40). Le dégagement devient une valeur réglable, pas un hasard.
  La forme est créée dans `_ready()`, jamais partagée depuis la scène : deux
  joueurs ne doivent pas écrire dans la même ressource.
- **Limite assumée** : une sonde volumique rapproche la caméra plus tôt qu'un rayon
  dans les passages étroits. C'est le compromis voulu ici ; s'il devient gênant en
  jeu, c'est `camera_probe_radius` qu'on ajuste, pas la structure.
