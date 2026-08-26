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

---

## D-016 — L'épuisement se lève à un seuil de réserve, pas à la première unité

- **Date** : 2026-08-01 · **Phase** : B.2 · **Statut** : ADOPTÉE
- **Contexte** : §9.1 décrit ce qui arrive à zéro — « sprint → course, lâcher du
  mur, lourde refusée, épuisement » — mais ne dit **pas** à quelle condition
  l'épuisement se lève. L'implémentation littérale le levait dès que la jauge
  repassait au-dessus de zéro.
- **Défaut mesuré, pas supposé** : sprint maintenu, jauge vidée. La régénération
  démarre après 1 s ; à la première unité rendue, l'épuisement se levait, le sprint
  repartait **un seul tick** (0,017 s), revidait la jauge et l'épuisement
  revenait. Le test a compté **7 cycles en 15 secondes**. Le joueur aurait vu sa
  vitesse osciller entre 6 et 9 m/s six fois par seconde de course.
- **Choix** : l'épuisement se lève quand le verrou de 0,45 s est écoulé **et** que
  la réserve atteint `exhaustion_recovery_threshold` (20, soit environ 1,7 s de
  sprint à 12/s). Le seuil est borné au maximum de la jauge, sinon un réglage
  supérieur à 100 rendrait la récupération impossible.
- **Portée délibérément limitée à l'effort continu** : `can_sustain()` tient compte
  de l'épuisement, `can_spend()` non. Une esquive payable doit rester possible dès
  le verrou écoulé ; ce sont les efforts soutenus qui bégaient, pas les actions
  ponctuelles.
- **Rejeté** : allonger le verrou d'épuisement à la place. Il est exprimé en
  secondes et §9.1 en fixe la valeur ; le régler pour compenser un seuil manquant
  aurait masqué le vrai paramètre et faussé une valeur de la spec.
- **Valeur hors spec, donc à réévaluer** : 20 est un point de départ crédible, pas
  un résultat mesuré sur un joueur. Le premier essai humain de traversal (§21.9)
  doit le confirmer ou le corriger.
- **Vérifié par** : `test_stamina.gd::test_a_held_sprint_produces_usable_bursts_not_a_stutter`,
  qui mesure la durée de la seconde rafale — un tick sans le seuil, plus d'une
  seconde avec. Contrôle négatif `N3_seuil_de_recuperation_retire`.

---

## D-017 — Pousser vers une paroi suffit à s'y accrocher

- **Date** : 2026-08-01 · **Phase** : B.3 · **Statut** : ADOPTÉE
- **Contexte** : §9.2 décrit l'escalade en détail — sondes, distances, vitesses —
  mais ne nomme **aucune touche**. §8.5 n'en réserve pas non plus : les dix-huit
  actions de l'InputMap sont toutes attribuées, et aucune ne concerne la paroi.
- **Choix** : l'accroche se déclenche quand le joueur pousse vers une paroi
  saisissable, au sol comme en l'air. Aucune entrée nouvelle.
- **Pourquoi** : ajouter une action obligerait à la lier au clavier **et** à la
  manette, à l'inscrire au remapping (§17.5) et à la documenter — pour un geste que
  le joueur fait déjà. `CONTROLLER-001` étant ouverte, chaque action nouvelle est
  une liaison manette de plus qui ne sera vérifiée qu'à l'essai manuel.
- **Conséquence à surveiller** : une paroi longeant un chemin s'accroche sans qu'on
  l'ait demandé. Le garde-fou est le filtre d'angle (D-018) et le refus des
  surplombs ; si le désagrément se confirme à l'essai humain, la réponse est un
  seuil d'intention (durée de poussée), pas une touche dédiée.
- **Rejeté** : réserver une action `climb`. Plus explicite, mais coûteux sur tous
  les périphériques et redondant avec la direction déjà donnée.
- **Vérifié par** : `test_climbing.gd::test_pushing_into_a_wall_grabs_it` et son
  jumeau négatif `test_an_unclimbable_surface_is_refused`, sur deux parois de
  géométrie identique.
- **Suite, 2026-08-04 — la conséquence surveillée s'est produite.** Un playtest
  externe indépendant, sur Godot officiel et vraies entrées, a rapporté :
  « courir normalement contre un arbre, une maison ou un mur du donjon déclenche
  l'escalade sans intention explicite ; le personnage peut rester suspendu, la
  caméra traverse alors tronc, toit ou mur ». Le remède prévu ici a donc été
  appliqué tel quel : `ClimbTuning.grab_intent_delay_s`, 0,22 s d'appui continu
  vers la paroi, **au sol uniquement**. En l'air l'accroche reste immédiate —
  personne ne saute vers un mur par accident, et attendre ferait manquer le
  rebord visé. Aucune touche n'a été ajoutée : D-017 tient toujours.
  Vérifié par `test_brushing_a_wall_while_running_does_not_grab_it`, qui compare
  l'accroche avec et sans seuil sur le même trajet. Ce test a dû être réécrit
  deux fois : les deux premières versions restaient vertes seuil désarmé, donc
  ne prouvaient rien.

---

## D-018 — Un `Mode` à trois valeurs plutôt que la `StateMachine` de §8.1

- **Date** : 2026-08-01 · **Phase** : B.3 · **Statut** : ADOPTÉE, à réviser en Phase C
- **Contexte** : §8.1 énumère vingt états (`Idle`, `Climb`, `Mantle`, `LightAttack`,
  `Dodge`, `Stagger`…). L'escalade et le mantle en réclament un mécanisme.
- **Choix** : le contrôleur porte un `enum Mode { LOCOMOTION, CLIMBING, MANTLING }`,
  et la logique de chaque mode vit dans un composant — sondes dans
  `ClimbingComponent`, rebord dans `LedgeDetectorComponent`, franchissement dans
  `ActionAlignmentComponent`.
- **Pourquoi** : construire la machine complète maintenant reviendrait à écrire
  dix-huit états vides, dont la moitié appartient à un combat qui n'existe pas. Ce
  serait de la structure spéculative, et §7.14 met en garde contre l'inverse de la
  méthode : bâtir l'échafaudage avant de savoir ce qu'il porte.
- **Ce que ce choix n'excuse pas** : la `StateMachine` de §8.1 reste due. Elle
  arrivera en Phase C, quand les états de combat auront un contenu, et le `Mode`
  sera absorbé — pas conservé en parallèle.
- **Rejeté** : une machine à états nodale immédiate. Elle aurait figé une hiérarchie
  d'états avant de connaître les besoins du combat, avec un coût de migration
  supérieur à celui de trois valeurs d'énumération.

### Amendement 2026-08-01 — C.2 : l'absorption a eu lieu, en place

Les états de combat existent (`ATTACKING`, `DODGING`) et la promesse est tenue
**sans machine nodale** : le `Mode` à cinq états, une fonction de traitement par
état, des gardes ordonnées pour les priorités et des transitions explicites, EST
la machine de §8.1 — plate. La convertir en nœuds n'ajouterait aujourd'hui ni un
comportement ni un test : ce serait la structure spéculative que §7.14 proscrit.
Ce constat sera réexaminé si un état exige une hiérarchie (sous-états de visée,
Phase C.3+) — le critère de bascule est un BESOIN, pas un compte d'états. L'IA du
pillard a sa propre machine (enum également), distincte par conception : §12.7
la fait vivre côté ennemi.

---

## D-022 — Le pillard pilote en direct, sans navmesh, jusqu'à la Phase D

- **Date** : 2026-08-01 · **Phase** : C.2 · **Statut** : ADOPTÉE, à échéance
- **Contexte** : §12.7 demande `NavigationRegion3D` + `NavigationAgent3D`. Les
  arènes de la Phase C — CombatLab, scènes de test — sont des sols plans et vides.
- **Choix** : le `raider_red` se dirige en ligne droite vers sa cible (poursuite,
  repli), sans navmesh. Sa perception respecte déjà §12.7 en entier : cône par
  cadence (1 tick sur 6, §12.9), raycast de LOS, « aucune vision à travers mur »
  testée, et un impact reçu révèle l'attaquant.
- **Pourquoi** : un navmesh sur un rectangle vide ne teste rien du navmesh — il
  ajoute une dépendance de bake à chaque scène de test pour un chemin qui est
  toujours la ligne droite. Le pilotage arrivera avec une géométrie qui le met
  réellement à l'épreuve (Phase D), et `EnemyTuning` n'aura pas à changer.
- **Échéance dure** : à la Phase D, AUCUN ennemi n'entre dans la vallée sans
  `NavigationAgent3D`. Cette décision expire avec le premier terrain non plan.
- **Aussi différé** : l'audition de §12.6 (15 m) attend les événements sonores de
  §12.7 — le champ est déclaré dans `EnemyTuning`, non consommé, et le test du
  « dos du pillard » documente cette absence.

---

## D-019 — Le seuil de paroi est borné par l'angle de sol praticable

- **Date** : 2026-08-01 · **Phase** : B.3 · **Statut** : ADOPTÉE
- **Contexte** : §8.2 fixe la pente marchable à environ 46°. §9.2 ne donne **aucun**
  angle minimal pour qu'une surface compte comme paroi ; il a fallu en inventer un.
- **Défaut introduit puis corrigé** : le premier jet retenait 50°, valeur d'apparence
  raisonnable. Elle ouvrait une bande de quatre degrés — 46° à 50° — où le joueur
  glisse sans pouvoir s'accrocher. Un piège invisible : aucune erreur, aucun test
  rouge, juste une pente sur laquelle on retombe sans comprendre.
- **Choix** : `ClimbTuning.min_wall_angle_deg` ≤ `LocomotionTuning.max_floor_angle_deg`,
  les deux à 46°. Toute surface qui ne se marche pas se grimpe.
- **Verrouillé par un test** : `test_no_angle_is_both_unwalkable_and_unclimbable`
  compare les deux ressources, qui s'ignorent par ailleurs. Contrôle négatif P6.
- **Limite honnête** : la relation est vérifiée, pas *dérivée*. Deux ressources
  distinctes restent deux valeurs à tenir cohérentes ; le test est le garde-fou.

---

## D-020 — Le franchissement de marche se déclenche sur un blocage mesuré, pas sur `is_on_wall()`

- **Date** : 2026-08-01 · **Phase** : B.4 · **Statut** : ADOPTÉE
- **Contexte** : §8.2 exige une marche de 0,30–0,38 m franchie sans saut. Mesuré
  d'abord, implémenté ensuite : `move_and_slide()` n'en monte **aucune**. Une
  marche de 0,32 m arrête le personnage net — `is_on_wall()` vrai, position figée
  trois secondes, aucune erreur. Le franchissement est donc un shape cast
  explicite, pas un réglage du moteur.
- **Le déclencheur, lui, a dû changer.** La première version s'adossait à
  `is_on_wall()`. Mesure contradictoire : plaqué contre le mur de 6 m du bac à
  sable, poussant depuis deux secondes, `is_on_wall()` renvoie **faux**. Un
  déclencheur qui se tait précisément là où il faudrait décider est inutilisable —
  même si, par chance, il fonctionnait contre la marche.
- **Choix** : comparer la distance réellement parcourue dans le tick à celle qui
  était demandée. En deçà de la moitié, le tick est bloqué et un franchissement est
  tenté. C'est une mesure du résultat, pas une lecture d'un drapeau du moteur dont
  la sémantique nous échappe.
- **Honnêteté sur la vérification** : **aucun test ne distingue les deux
  déclencheurs.** Le contrôle négatif Q5 a remis `is_on_wall()` et la suite est
  restée verte. Le changement repose sur la mesure directe, pas sur un test — et
  cela est écrit dans le test concerné plutôt que passé sous silence.
- **Coût** : trois `test_move` par tick **uniquement** quand le déplacement est
  entravé. Nul en marche normale.

### Amendement 2026-08-01 — post-revue Gate B : la justification était fausse, le déclencheur a changé

- **L'artefact** : la mesure fondatrice de cette décision — « plaqué contre le mur
  de 6 m, `is_on_wall()` renvoie faux » — était mal interprétée. Le joueur n'était
  pas plaqué contre le mur : il l'avait **saisi** (§9.2). La position mesurée,
  x = 29,33, est exactement la distance de paroi (0,42 m de la face) ; en mode
  escalade le corps est tenu sans contact, donc ni collision ni `is_on_wall()`.
  Découvert en traitant le contre-exemple de la revue contradictoire.
- **Le contre-exemple de la revue** : poussée à 45° contre la marche, le
  déclencheur « distance parcourue vs demandée » restait muet — le glissement
  diagonal conserve ~71 % de la distance. Jamais franchie.
- **Décision amendée** : le déclencheur écoute les **collisions de glissement**
  rapportées par `move_and_slide()` — normale plus raide que le sol praticable,
  composante horizontale non nulle, poussée du joueur dirigée dedans
  (`WALL_PUSH_MIN_DOT`). Mesuré présent en poussée diagonale (normale
  0 ; 0,12 ; −0,99) comme de face, et jamais sur sol libre.
- **Vérifié par** : `test_a_step_is_climbed_when_approached_diagonally` — le test
  qui départage réellement les variantes de déclencheur, ce que Q5 avait montré
  manquant — et le contrôle négatif V4. Q5 est **caduc** : sa mutation visait un
  code qui n'existe plus sous cette forme.


---

## D-021 — Gate B clos « accepté pour continuation », validation humaine finale différée

- **Date** : 2026-08-01 · **Phase** : B → C · **Statut** : DÉCISION PROPRIÉTAIRE
- **Décision, aux termes du propriétaire** : les essais manuels à la manette sont
  reportés à la passe finale et ne bloquent pas la poursuite ; les limitations GPU
  de l'environnement ne bloquent pas le Gate B ; seuls d'éventuels défauts P0/P1
  réellement démontrés par la revue devaient être corrigés ; pas de deuxième revue
  contradictoire ; si rien de bloquant ne subsiste, Gate B est clos « **accepté
  pour continuation, validation humaine finale différée** » et la Phase C démarre.
- **Constat d'application** : la revue (`evidence/gateB/REVUE.md`) n'a démontré
  **aucun défaut bloquant** — ses mots : « aucun défaut de code bloquant trouvé ».
  Ses six constats non bloquants ont tous été traités au commit `806ef9b`
  (137 tests, RC=0). Il n'y avait donc aucun P0/P1 à corriger.
- **Ce que ce verdict n'est pas** : un `PASS`. Le vocabulaire de §0.2 tient — les
  critères jitter (§8.3), ressenti (§21.4) et manette (§23.1) restent
  `NON VÉRIFIÉ`/`BLOQUÉ` jusqu'à la passe finale. La dette est enregistrée :
  **VALIDATION-B-001** (essais humains du Gate B) s'ajoute à **CONTROLLER-001**
  (manette, D-012). Aucune des deux ne sera jamais levée par un test automatique.
- **Précédent** : même mécanique que D-012 pour le Gate A — le propriétaire assume
  explicitement le risque de continuer, la dette est portée par écrit, et la
  passe finale la solde ou la transforme en `FAIL`.

---

## D-023 — Choix d'implémentation armes/durabilité non fixés par la spec (C.4)

- **Date** : 2026-08-01 · **Phase** : C · **Statut** : ACTÉ
- **Contexte** : §11.1–§11.3 fixent la table des armes, « huit armes », « aucun
  doublon d'instance », l'usure « jamais dans le vide » et la rupture — mais
  laissent quatre points ouverts. Chaque choix ci-dessous est testé.
- **Décisions** :
  1. **Usure par CIBLE touchée**, pas par swing : un moulinet qui traverse deux
     pillards coûte deux points (`hit_confirmed` est l'événement d'usure). Rejeté
     « par swing qui a touché au moins une cible » : demande un état par swing de
     plus, sans gain de lisibilité — révisable en équilibrage.
  2. **La rupture coupe la fenêtre AU MILIEU du tick** : `_process_target`
     revérifie `_active` par cible ; la victime suivante de la même frame n'est
     pas touchée. C'est la lecture stricte de « couper hitbox » (§11.2), prouvée
     par le test des deux mannequins (78 = une seule victime).
  3. **Mains nues : dégâts 3, portée 1,2 m** — §11.1 n'en donne pas ; en dessous
     du gourdin (8, 1,6 m) pour que la pire arme reste préférable aux poings.
     `base_damage` exporté du contrôleur = valeur mains nues ; l'ennemi sans
     inventaire (pillard) s'en sert comme « arme de corps ».
  4. **Portée raccordée à la géométrie** : la FACE AVANT du volume de frappe est
     posée à `reach_m` de l'axe (la demi-profondeur est lue sur la forme réelle,
     pas codée en dur). La lance touche à 2,4 m, l'épée non — testé.
  5. **Dotation de départ du bac à sable** : épée usée + 8 flèches dans
     `Player.tscn` — préserve les nombres de C.1–C.3 (12 ; 12,6 ; 15,6 ; 21,6) et
     disparaîtra au profit du butin réel (coffres, Phase D).
  6. **Set d'attaques partagé pour la 0.1** : toutes les armes de mêlée déclarent
     le set d'épée dans `attack_set` — les « combos par arme » de §7.12 sont une
     passe d'animation (Phase H), pas une donnée manquante. La lourde reste sur le
     contrôleur, hors définition d'arme, même logique.

---

## D-024 — Gate C clos « accepté pour continuation avec validation humaine différée » · D.0 ordonné sans C.5 préalable

- **Date** : 2026-08-01 · **Phase** : C → D · **Statut** : DÉCISION PROPRIÉTAIRE
- **Décision, aux termes du propriétaire** : une **unique** revue contradictoire
  du Gate C, limitée à une passe, sans nouvelle boucle de contrôles négatifs, de
  documentation ou de revue récursive ; correction des seuls défauts
  reproductibles bloquant le chemin critique ; verdict prononcé « accepté pour
  continuation avec validation humaine différée ». Puis **D.0 immédiatement** :
  `ValleyWorld.tscn` 512 × 512 m, chargée depuis « Nouvelle partie », intégrant
  le Player, le combat existant, un camp avec ennemis, un coffre et des armes
  ramassables — « aucun laboratoire ou rapport supplémentaire ne doit précéder
  cette intégration ».
- **Exécution** : revue rendue (`evidence/gateC/REVUE.md`) — 4 critères PASS
  rejoués ; D1 (mort du joueur inexistante, S2, chemin critique du combat)
  **corrigé** avec régression rejouant la sonde du réviseur ; D3 (garde
  manquante, S4) corrigé ; D2 (lignes `RC=` des logs W/X/Y invalides comme
  preuve) **annoté** sans régénération, conformément à la limite d'une passe.
- **Conséquence assumée sur la ROADMAP** : la marche `C.5 → D` est réordonnée
  par le propriétaire — l'intégration D.0 précède le benchmark artistique. Le
  verrou C.5 (interdiction d'AGRANDIR/habiller la vallée si la micro-scène
  North Star ne tient pas) reste dû avant la production artistique de la
  vallée ; D.0 est une intégration graybox, pas un habillage.
- **Comme D-021** : ce verdict n'est PAS un `PASS`. Dettes maintenues :
  CONTROLLER-001, VALIDATION-B-001, ressenti §10.6/§10.8, hit-stop/VFX/sons.

---

## D-025 — D.1 : relief macro d'un bloc, C.5 redéfini sur le monde réel, navigation par requêtes serveur

- **Date** : 2026-08-01 · **Phase** : D · **Statut** : DÉCISION PROPRIÉTAIRE (portée) + ADAPTATIONS MESURÉES
- **Portée ordonnée** : relief macro complet de `ValleyWorld` en une passe (crête,
  descente en S, terrasse du camp, lit de rivière, falaise à corniches, terrasse
  du pylône, forêt, ruines, plateau monumental) avec proxys VISIBLES du pylône et
  de la citadelle ; navmesh après stabilisation du relief ; **C.5 n'est plus une
  scène indépendante** — son `HeroShotLab` utilise la vraie crête et la vraie
  vallée pour valider caméra, lumière, matériaux pilotes et végétation proche
  AVANT propagation ; pas de nouveau cycle de revue ; tests limités aux risques
  critiques ; livrable avec capture depuis la caméra de départ.
- **Blockout par dalles + prismes convexes** (rejeté : heightmap procédurale —
  pentes non garanties à l'aveugle ; le blockout donne des cotes exactes que les
  tests vérifient, et la leçon B.1 sur les prismes pleins s'applique telle
  quelle).
- **Amendement D-022 — navigation** : le navmesh est baké depuis les collisions
  (`tools/godot/bake_valley_navmesh.gd`, ressource versionnée) mais le SUIVI est
  manuel via `NavigationServer3D.map_get_path` + index de waypoint avancé en 2D.
  Le suiveur intégré de `NavigationAgent3D` est écarté sur MESURE : il compare
  agent et waypoint en 3D alors que les waypoints vivent à la hauteur voxelisée
  du navmesh (~0,45 m au-dessus des pieds) — seuil 0,4 : gel sur place ; 0,8 :
  validation prématurée et gel contre un coin ; reposer `target_position` à
  cadence fixe réinitialise l'index (troisième gel). Trois sondes successives,
  puis changement d'hypothèse (règle des deux tentatives). L'agent reviendra si
  l'évitement de §12.9 le justifie.

---

## D-026 — D.1R : choix d'implémentation du jalon correctif post-playtest

- **Date** : 2026-08-01 · **Phase** : D (correctif D.1R) · **Statut** : ACTÉ
- **EventBus, premier signal admis** : `gameplay_notification(text)` — émetteurs
  réels sans lien (coffres, armes au sol, rupture d'arme côté contrôleur),
  récepteur réel (HUD de `GameplayShell`), aucun propriétaire naturel. Le test
  de vacuité devient un REGISTRE de signaux admis.
- **Unités de regard** : souris = radians (pixels × sensibilité), appliqués tels
  quels ; stick = vitesse angulaire × delta. Sensibilité 0,0004–0,005 rad/px,
  défaut 0,0015, persistée dans `user://settings.cfg` (§19.1 : options séparées
  des sauvegardes).
- **Pause et inventaire suspendent l'arbre** (`GameplayShell` en
  `PROCESS_MODE_ALWAYS`) — §13.4 : aucune minuterie de gameplay ne court.
- **Molette** : arme suivante/précédente hors verrouillage, cible pendant — le
  verrouillage consomme les fronts en premier, aucun conflit possible.
- **Retry de mort** : recharge le monde-checkpoint (la vallée), qui applique la
  sauvegarde ; le loot acquis aux coffres survit, la position repart du spawn
  documenté.
- **Règle position-avant-add_child généralisée** : mesurée trois fois (coffre
  D.0, mannequins de test D.1R.2, montagnes du terrain D.1R.4 — joueur
  catapulté de 4,6 m par une dalle-fantôme à l'origine). Tout corps physique se
  positionne AVANT son entrée dans l'arbre, y compris dans les générateurs.

---

## D-027 — F.2 : comment un joueur pousse 40 kg, et comment la lumière voyage

- **Date** : 2026-08-02 · **Phase** : F (jalon F.2) · **Statut** : ACTÉ
- **Poussée par IMPULSION, jamais par transform** (§14.1). `move_and_slide()` ne
  déplace aucun `RigidBody3D` : la poussée est une impulsion appliquée aux corps
  du groupe `pushable` rapportés par les collisions de glissement. Alternative
  rejetée : écrire le transform du bloc (interdit par §14.1, et le solveur
  reprend la main au tick suivant avec un état incohérent).
- **La poussée se mesure sur la vitesse VOULUE, pas sur la vitesse constatée.**
  Mesuré : contre un obstacle, `move_and_slide()` remet à ~0 la composante
  entrante, l'accélération repart de zéro et l'impulsion plafonne à 5,6 N·s —
  sous le seuil de frottement du bloc, qui reste alors immobile 600 ticks
  durant. Le contrôleur mémorise donc `_desired_horizontal` avant collision.
- **Frottement du bloc à 0,4** (`PhysicsMaterial`). À 1,0 (défaut), le seuil de
  glissement d'un corps de 40 kg dépasse ce qu'une poussée plafonnée peut
  fournir : métal poli sur dalle de pierre, c'est aussi le choix physique juste.
- **Vitesse de poussée plafonnée à 2,2 m/s** (§14.1 « vitesses maximum ») :
  impossible de catapulter un objet d'énigme en sprintant dedans.
- **La porte du puzzle est LATCHÉE ouverte** (§15.11 anti-softlock). Une porte
  qui se refermerait dès que le bloc bouge pourrait enfermer le joueur du
  mauvais côté. Le reset rejoue l'énigme ; il ne retire jamais un acquis.
- **La propagation visible passe par la profondeur BFS**, pas par un timer de
  salle : le graphe publie `hop_depth` avant d'émettre `power_changed`, et la
  présentation en fait un retard (0,05 s par saut). La logique reste
  instantanée — c'est la LUMIÈRE qui voyage (§15.4). Alternative rejetée :
  animer la propagation dans le graphe, qui aurait mêlé rendu et logique et
  rendu les tests de §15.2 dépendants du temps.
- **Une butée matérielle ferme le couloir de poussée.** Mesuré : même lancé à
  40 m/s, le bloc s'arrête au contact et le circuit se ferme. C'est la lecture
  littérale de « solution impossible à perdre » (§15.5).
- **`DungeonRoom` comme coque commune** (une seule couche d'héritage) : reset,
  respawn, sauvegarde fusionnée dans le slot commun et helpers de graybox. Les
  salles 2 à 4 en héritent au lieu de recopier leur anti-softlock.

---

## D-028 — F.3 : aiguiller le courant, battre le danger, ne pas écraser

- **Date** : 2026-08-02 · **Phase** : F (jalon F.3) · **Statut** : ACTÉ
- **Un aiguillage est DEUX nœuds `SWITCH`, pas un booléen.** `ElectricSwitch`
  ferme une branche et en ouvre une autre dans le même geste ; la redirection
  est une propriété du graphe, vérifiable par `--filter=electric_graph` comme
  par la salle. §26 l'exige explicitement : « graphe générique, pas booléens
  de salle ».
- **Les branches doivent être géométriquement SÉPARÉES.** Mesuré : avec les
  deux sorties du carrefour à 0,4 m l'une de l'autre, les branches se
  touchaient directement, les aiguillages étaient contournés et tout le
  circuit s'allumait d'un bloc — électrodes ET porte. Les ports de sortie sont
  désormais distants de plus du double de leur portée, et un test le mesure.
- **Le mur ouest est `unclimbable`.** Sans ce refus explicite (§9.2), on
  grimperait à côté des électrodes et l'énigme de §15.6 n'existerait pas. La
  voie passe par trois blocs décalés dont le toit sert de corniche.
- **La garde haute de l'ascenseur ne surveille pas la tête de son passager.**
  Mesuré : collée à la plateforme, elle prenait le voyageur pour un obstacle et
  l'ascenseur ne démarrait jamais. Elle surveille la tranche 1,9-3,9 m
  au-dessus du plancher ; la garde BASSE, elle, reste collée — c'est là qu'un
  corps se ferait écraser. Alternative rejetée : distinguer le passager par sa
  vitesse ou son contact au sol, fragile et invérifiable.
- **L'aiguillage de la salle 2 est IRRÉVERSIBLE.** Le rebasculer réarmerait les
  électrodes sous les pieds d'un joueur déjà en haut : hostile sans être
  intéressant. Anti-softlock, même famille que la porte latchée de la salle 1.
- **Les électrodes battent, elles ne surprennent pas** (§15.6, « rythme
  observable ») : 1,1 s de décharge pour 1,7 s de calme, phases décalées de
  0,9 s. Un test mesure que la fenêtre calme dépasse le temps de traversée à la
  vitesse d'escalade de §9.2.

---

## D-029 — F.5 : porter un objet, stocker du courant, franchir une eau vive

- **Date** : 2026-08-02 · **Phase** : F (jalon F.5) · **Statut** : ACTÉ
- **Un objet porté est un corps GELÉ en mode cinématique**, suivi au tick
  physique sur un point de port. §14.1 interdit d'écrire le transform d'un
  rigid body ACTIF ; un corps gelé prévu pour cela est le cas légitime.
  Alternative rejetée : reparenter le corps sous le joueur — la physique
  d'un corps reparenté à chaud est une source de bugs sans contrepartie.
- **Le socket n'ajoute AUCUNE règle électrique.** Il cale l'objet, et ce sont
  les PORTS qui se touchent (§15.3). Sans cela, on aurait un booléen
  « batterie posée » que §26 interdit explicitement.
- **La batterie distingue trois choses** (§15.3) : la charge stockée, le
  socket, la décharge. Elle se remplit quand une source extérieure l'alimente,
  débite partout ailleurs, et se vide lentement — 90 s d'autonomie, assez pour
  traverser deux fois, jamais assez court pour piéger.
- **Le canal fait 6 m.** Mesuré sur les valeurs de §8.2 : un saut couvre
  environ 4,1 m au sprint. À 4 m, l'énigme se sautait ; à 6 m, il faut
  vraiment couper le courant ou poser la planche.
- **Les deux solutions de §15.8 existent VRAIMENT**, et chacune a son test :
  couper le courant (au prix du berceau de charge, qui s'éteint avec la
  nappe), ou poser la planche isolante et passer au-dessus. La zone de la
  nappe s'arrête sous le niveau de la planche : c'est la géométrie qui
  protège, pas une exception dans le code.
- **Le levier de la salle 4 est RÉVERSIBLE**, contrairement à celui de la
  salle 2 : il faut pouvoir remettre le courant pour recharger. Ce qui rend
  cela sûr, c'est que l'eau blesse sans tuer (12 points par seconde) et que la
  porte, une fois ouverte, le reste.

---

## D-030 — F.6 : trois circuits qui ne se parlent pas, et un donjon relié

- **Date** : 2026-08-02 · **Phase** : F (jalon F.6) · **Statut** : ACTÉ
- **Les trois branches de la salle centrale sont ÉLECTRIQUEMENT séparées.**
  Une porte du boss branchée sur les trois aurait relié les branches entre
  elles : le courant du premier circuit résolu serait remonté dans les deux
  autres et les trois anneaux se seraient fermés d'un coup. La porte reçoit
  donc une liste de CONDITIONS (`required_paths`) et n'ouvre qu'une fois
  toutes alimentées. Les « lignes continues » de §15.9 sont la présentation
  de chaque récepteur, pas des câbles partagés.
- **Le tableau salle → récepteur est dans le code**, en tête de
  `central_hall.gd`, comme §15.9 l'exige — et un test le rejoue salle par
  salle au lieu de faire confiance au commentaire.
- **La salle 1 n'alimente aucun récepteur.** Elle est sur le CHEMIN
  (vestibule → hall). C'est le cas prévu par §15.9 pour un quatrième puzzle
  séquentiel ; il est documenté plutôt que caché.
- **Le pied d'une rampe s'enterre.** Mesuré : une rampe inclinée posée sur le
  sol présente une tranche de 0,75 m — un mur pour §8.2, dont la marche
  franchissable s'arrête à 0,38 m. La surface doit émerger du sol au niveau
  zéro, sans ressaut.
- **Convention de tag d'apparition** : `<destination>_from_<origine>`. Le tag
  nomme l'ARRIVÉE. Sans cette règle, le même tag servait dans les deux sens et
  le joueur réapparaissait du mauvais côté ; un test vérifie désormais que
  chaque traversée dépose à moins de six mètres du seuil de retour.
- **Chaque salle à énigme a DEUX seuils vers le hall** : celui par lequel on
  entre, et celui que le puzzle ouvre. Le raccourci EST la récompense, et il
  garantit qu'aucune salle ne peut devenir un cul-de-sac.


---

## D-031 — F.6 : un shell sert SON joueur, et un test qui fuit se nomme

- **Date** : 2026-08-03 · **Phase** : F (jalon F.6) · **Statut** : ACTÉ
- **`GameplayShell` se lie au joueur de sa propre scène.** Il prenait le premier
  nœud du groupe `player` : dès que deux mondes coexistent — transition de
  scène, monde préchargé, suite de tests — un shell servait le joueur d'un
  AUTRE monde. Symptôme mesuré : la mort manquée (le panneau n'apparaissait
  jamais, le shell écoutant la santé d'un joueur qui ne mourait pas). Le groupe
  ne sert plus que de repli pour un shell posé seul. Régression couverte par
  `test_shell_binding.gd`.
- **Le runner refuse désormais qu'un test laisse une scène dans l'arbre.** La
  cascade observée était instructive : une assertion périmée (`SealedDoor`,
  supprimée par l'assemblage F.6) provoquait une erreur de script AU MILIEU
  d'un test ; sa fonction s'arrêtait avant le nettoyage ; le vestibule restait
  chargé ; et le parcours de traversal, trente fichiers plus loin, démarrait
  entre ses colonnes. Trois tests rouges, aucun au bon endroit. Le runner
  photographie la racine avant chaque test et échoue le test FAUTIF en nommant
  ce qu'il a laissé.
- **Une attente de test se compte en TEMPS, pas en images.** Le panneau de mort
  part sur un `Timer` de 1,2 s ; l'attendre pendant 300 `process_frame` mesurait
  en réalité la cadence du moteur, qui varie du simple au double en headless
  selon ce qui a tourné avant. Les deux tests concernés attendent maintenant
  4 s de temps réel.


---

## D-032 — G.1 : les pylônes se BRANCHENT, ils ne se cochent pas

- **Date** : 2026-08-03 · **Phase** : G (jalon G.1) · **Statut** : ACTÉ
- **Le drapeau `enabled` ne convient pas à un RELAY.** Première version du
  pylône : le levier basculait `ElectricNode.enabled`. Le graphe ne consulte ce
  drapeau que pour `SOURCE`, `SWITCH` et `BATTERY` — `conducts()` retourne
  `true` sans condition pour tous les autres types. Résultat mesuré à
  l'ouverture de la scène : les quatre pylônes alimentés, cyan, alors qu'aucun
  n'était dressé. Le test `test_a_raised_pylon_is_powered_by_the_ground_rail`
  l'a montré en deux assertions.
- **Corrigé par la GÉOMÉTRIE, pas par une exception dans le graphe.** Le mât est
  télescopique : déployé, son sabot de cuivre descend sur le siège du rail et
  le port du nœud tombe dessus ; rétracté, le sabot est relevé de 1,6 m, très
  au-delà des 0,5 m de portée. C'est exactement la doctrine de §15.3 — « la
  logique ne doit pas s'activer seulement parce que l'objet est proche d'un
  point invisible » — et c'est la même que le bloc de la salle 1, les bras des
  relais de la salle 3 et la batterie de la salle 4. Ajouter `RELAY` à la liste
  des types sensibles à `enabled` aurait marché aussi, mais aurait rendu la
  connexion invisible : rien, à l'écran, n'aurait dit pourquoi le courant passe.
- **L'anneau de terre est un CYCLE, volontairement.** Vingt-quatre câbles
  refermés sur eux-mêmes autour de l'arène, alimentés par un puits au nord.
  §15.2 pt. 5 exige que les cycles soient inoffensifs ; l'arène en fait la
  démonstration en jeu plutôt qu'en test de laboratoire. Cinquante recalculs
  consécutifs sont chronométrés par `test_the_closed_ground_ring_terminates`.
- **La caméra reçoit un SUPPLÉMENT de cadrage, pas un réglage absolu.**
  `CameraRig.set_boss_framing(distance, fov)` s'ajoute à la base et converge
  sur la même courbe framerate-independent que le FOV de sprint (§8.3 : aucun
  snap). Le `SpringArm3D` continue de sonder : reculer ne fait donc jamais
  traverser un mur. Alternative rejetée : un mode caméra dédié qui écrase les
  valeurs — il aurait fallu restaurer l'état d'avant à la sortie, et toute
  sortie manquée aurait laissé la caméra du boss dans la vallée.
- **L'arène n'est pas un piège.** Son seuil sud reste ouvert vers
  l'antichambre, donc vers le feu de cuisine et le coffre garanti. Un joueur
  qui entre sans plat de résistance électrique peut ressortir en préparer un.
  §15.11 ne s'arrête pas à la porte du boss.


---

## D-033 — G.2 : les PV du boss sont DÉRIVÉS de la solvabilité

- **Date** : 2026-08-03 · **Phase** : G (jalon G.2) · **Statut** : ACTÉ
- **900 PV étaient un chiffre inventé ; 560 sont un chiffre calculé.** §16.7
  demande « un test qui échoue si le boss est mathématiquement impossible avec
  le loot garanti » et « une marge de 30-50 % au-dessus du minimum théorique ».
  Écrit d'abord, ce test a immédiatement recalé la valeur choisie : sous des
  hypothèses délibérément pessimistes — deux coups sur trois portent, la moitié
  seulement dans une fenêtre de noyau, le reste sur l'armure à ×0,2 — le loot
  garanti (lame conductrice 26×16, épée usée 12×24, gourdin 8×18) plafonne à
  environ 755 dégâts utiles. Contre 900 PV, la marge valait **-16 %** : le
  combat était infaisable. 560 PV la portent à **+35 %**.
- **La borne HAUTE est testée aussi.** Un boss qu'on abat avec le tiers de son
  arsenal n'est plus un examen de maîtrise. L'assertion encadre donc la marge
  entre 30 et 50 % : toute dérive future, dans un sens comme dans l'autre,
  devra être une décision, pas un effet de bord.
- **Aucune arme rare n'est requise** : le test vérifie en plus que la lame
  conductrice seule ne suffit PAS. Gérer son arsenal fait partie du combat.
- **Deux pièges d'écriture de test, notés parce qu'ils reviendront.** Une lambda
  GDScript capture les variables locales **par valeur** : `var vu := false` puis
  `signal.connect(func(): vu = true)` ne remonte jamais rien — il faut un
  tableau. Et `HitboxComponent.monitoring` reste allumé en permanence par
  conception (R-014) : pour savoir si une hitbox frappe encore, on lit
  `is_active()`, jamais `monitoring`.


---

## D-034 — H.1 : le Gardien cesse d'être une capsule

- **Date** : 2026-08-03 · **Phase** : H (lot H.1) · **Statut** : ACTÉ
- **Le boss est modélisé, pas acheté.** `tools/blender/make_storm_guardian.py`
  construit la bête-machine de VISUAL_ASSET_BIBLE §15.1 depuis des primitives,
  avec un seed fixe : six appuis dont deux antérieurs lourds, dos voûté de
  pierre, trois plaques de céramique sur la tête, épaules de bronze, queue
  segmentée à fourche de terre, anneau vertical incomplet en trois segments,
  noyau fendu au sternum. Aucune anatomie réelle citable, aucune silhouette
  empruntée, aucun asset externe. Alternative rejetée : réutiliser un
  humanoïde du pack et l'agrandir — c'est précisément ce que l'ordre de la
  Phase H interdit.
- **27 meshes NOMMÉS, et c'est le point.** `Core`, `CrystalA/B`,
  `ArmourPlate0..7`, `GuardianRing0..2`, la queue : la phase 2 révèle, la
  phase 3 fait pendre, la mise à la terre allume. Rien de tout cela n'est
  possible depuis une masse unique — le découpage est une exigence de
  gameplay avant d'être un choix d'art.
- **Les volumes de combat ont suivi le modèle, pas l'inverse.** La collision
  et les quatre hurtbox ont été replacées sur la géométrie réelle, et un test
  refuse désormais toute hurtbox qui ne serait pas DANS le corps visible.
  Une hitbox qui flotte à côté du modèle est un mensonge qu'aucune capture ne
  révèle ; la géométrie, elle, le dit.
- **Trois défauts trouvés en mesurant, pas en relisant.**
  1. `matrix_world` est PÉRIMÉE après un reparentage tant que
     `view_layer.update()` n'a pas tourné : Blender annonçait 9,58 m de long
     quand Godot en mesurait 14,50. Les cotes de la bible se vérifient
     désormais **dans Godot**, sur la géométrie importée.
  2. Le parentage « BONE » de Blender accroche l'objet à la QUEUE de l'os,
     pas à sa tête — d'où le décalage. Remplacé par des groupes de sommets à
     poids 1 : chaque volume rigide suit exactement un os, ce qui est de
     toute façon ce que veut une machine de pierre.
  3. La nouvelle boîte de collision, posée sur la masse centrale, avait son
     bas à 0,80 m du sol : le Gardien ne trouvait plus le plancher et tombait
     indéfiniment. Symptôme observé : il était plus LENT en phase 3 qu'en
     phase 1. La boîte part maintenant de zéro.
- **Densité assumée.** 6 324 triangles, très en dessous du plafond de
  110-160k de la bible §4.5. La silhouette, la structure et les matériaux
  sont là ; le détail de surface ne l'est pas. C'est écrit au manifeste
  plutôt que passé sous silence.


---

## D-035 — H.2 : trois pillards, trois CORPS, un seul squelette

- **Date** : 2026-08-03 · **Phase** : H (lot H.2) · **Statut** : ACTÉ
- **La géométrie est neuve, le squelette ne l'est pas.** Les trois corps sont
  construits par `tools/blender/make_raiders.py` autour du squelette UAL à
  65 os déjà présent dans le dépôt, puis liés par poids automatiques.
  Conséquence directe et voulue : `AL_RaiderStates.res` continue de
  s'appliquer sans retargeting. Alternative rejetée : trois rigs neufs — il
  aurait fallu réécrire toutes les animations, c'est-à-dire remplacer un
  système qui marche par un prototype moins complet.
- **Ce qui distingue les familles est désormais MESURÉ.** Le test qui
  vérifiait des teintes vérifie maintenant des corps : tailles dans les
  bandes de la bible (1,42 · 1,63 · 1,88 m), tailles ORDONNÉES, briseur le
  plus large, maillages de comptes différents, palettes distinctes. La
  teinte reste un marqueur de faction, elle n'est plus le seul.
- **Un vrai bug attrapé au passage.** `character_model_sockets.gd` ne
  dupliquait les matériaux QUE s'il y avait une teinte ou une substitution.
  Les nouveaux modèles portent leur couleur dans leur propre matériau, donc
  plus de teinte, donc plus de duplication — et le télégraphe d'attaque, qui
  écrit dans les matériaux d'instance, n'avait soudain plus rien où écrire.
  L'isolation est maintenant INCONDITIONNELLE, ce que §5.4 exigeait déjà
  (« deux exemplaires ne partagent jamais leur matériau »).
- **L'échelle partait deux fois vers glTF.** `export_apply` cuit la
  transformation dans les sommets, et le nœud exporté la reportait :
  Blender annonçait 1,42 m quand Godot mesurait 1,17. Le script APPLIQUE
  désormais l'échelle avant export. Règle générale à retenir : **une cote
  se vérifie dans Godot, sur la géométrie importée** — jamais sur le log de
  l'outil qui l'a produite.

## Règle de travail — ne pas éditer l'arbre pendant une validation

Deux runs de `validate_fast.sh` ont été perdus parce que des scènes
référençant des `.glb` non encore importés ont été ajoutées PENDANT le run :
la première fois deux erreurs isolées, la seconde 62 tests rouges en
cascade. Le contenu du dépôt doit être figé entre le lancement de la
validation et son verdict ; les seules éditions sûres sont celles que Godot
ne charge pas (documentation).

## D-036 — Une taille de boîte est PLEINE, pas une demi-taille (ISS-018)

`bmesh.ops.create_cube(size=1.0)` pose ses sommets à ±0,5 : la « taille »
qu'attendent nos fabriques `add_box` et `limb` est donc la dimension
COMPLÈTE. Trois scripts la traitaient par endroits comme une demi-taille
(`* 0.5`, `* 0.62`, `* 0.52`). Chaque membre, chaque travée de dos, chaque
maillon d'anneau et chaque segment de queue était bâti à la moitié — ou aux
deux tiers — de sa portée, et s'arrêtait avant son articulation. Les
créatures arrivaient donc en pièces détachées, exactement comme si le
pipeline était cassé, alors que le pipeline était juste.

Vérifié plutôt que supposé : un script d'une ligne dans Blender confirme
l'étendue ±0,5. C'est la règle « ne jamais halluciner une API » appliquée à
une bibliothèque qu'on croyait connaître.

Alternative rejetée : compenser en allongeant les portées à la main créature
par créature. C'est ce que la « passe de mordant » précédente avait commencé
à faire — elle traitait le symptôme, masquait la cause, et n'aurait jamais
convergé.

## D-037 — Le critère de continuité est « UN SEUL corps », pas « chaque pièce a un voisin »

Le premier contrôle d'ISS-019 demandait à chaque morceau d'avoir un voisin.
Le chasseur l'a passé alors que ses deux bras flottaient à 11 cm du buste :
chaque bras touchait son propre avant-bras, donc chacun avait bien un
voisin. Le critère retenu est la CONNEXITÉ globale — un seul groupe — ce qui
a immédiatement révélé la même faute sur deux des trois pillards.

Deux autres pièges de mesure, corrigés parce qu'ils faisaient dire au test
n'importe quoi :

- **sans ressoudure des sommets**, l'export glTF sépare les sommets par
  normale et par UV : le Gardien comptait 1520 « îlots » de une face, tous
  voisins les uns des autres, et le contrôle ne voyait aucun défaut ;
- **la distance sommet à sommet** ment sur des boîtes tournées l'une par
  rapport à l'autre — l'anneau du Gardien ressortait « détaché » alors que
  ses maillons s'enfilaient. La mesure retenue va des sommets de l'un vers
  la BOÎTE de l'autre, dans les deux sens.

## D-038 — Le corps des pillards revient au pack CC0, les têtes restent originales

La capture du bestiaire a tranché : les trois pillards bâtis en primitives
étaient des figurines de fil de fer, membres de 4 cm de section, torse en
boîte. Aucune retouche de constantes n'en aurait fait des personnages.

Le pack Quaternius « Universal Base Characters » (CC0, déjà dans le dépôt et
déjà attribué) fournit exactement ce qui manquait : un humanoïde de 12 894
triangles, texturé en PBR, **pesé sur les mêmes 65 os UAL**. Il était importé
puis JETÉ par `load_skeleton`, qui ne gardait que l'armature. Le corps est
désormais conservé ; ne restent construites que les pièces qui distinguent
les familles.

Ce que le pack ne fournit pas : la TÊTE. Les personnages modulaires
Quaternius sont livrés sans tête, ce qui tombe bien — la bible §14.1-14.3
demande des crânes non humains (coin à excroissances arrière, crête osseuse,
visière fendue). Une tête du commerce les aurait rendus identiques.

Distinction des familles, désormais sur quatre axes mesurés : stature
(1,42 · 1,65 · 1,88 m), carrure (X/Y du corps, 0,90 à 1,26), teinte de
faction, tête et armure propres.

Alternative rejetée : rendre les membres procéduraux plus épais. C'était
poursuivre un chemin qui avait déjà produit un résultat inacceptable, et
ignorer un asset légalement disponible, meilleur, et déjà dans le dépôt.

Deux pièges rencontrés, tous deux vérifiés plutôt que supposés :

- l'importateur glTF fabrique une **icosphère d'affichage** pour les os. Elle
  n'est dans aucun fichier : gardée par erreur comme géométrie du corps, elle
  ajoutait une boule de 2 m à l'origine, faisait annoncer 2,42 m de stature
  et comptait comme une pièce détachée. Elle est écartée par son RÔLE
  (`pose_bone.custom_shape`), pas par son nom ;
- le `ShaderNodeMixRGB` hérité n'est **pas** reconnu par l'exporteur glTF
  comme un facteur de couleur de base. Les trois familles sortaient de
  l'export avec la même texture de paysan. `ShaderNodeMix` en RGBA fonctionne
  — vérifié en relisant le `baseColorFactor` du `.glb` produit, pas en
  faisant confiance au rendu Blender.

## D-039 — Une densité se mesure par unité de surface

La prairie de crête portait 1400 touffes sur 2346 m², soit **0,6 touffe/m²**
là où §7.2 en demande 7 à 14 en zone héroïque. Le tiers inférieur du cadre
de §3.2, censé porter « une pente herbeuse riche », était un aplat vert avec
quelques cônes posés dessus.

Le test qui couvrait la prairie demandait « au moins 300 instances par
cellule ». Une prairie vide de sens satisfait ce critère du moment qu'elle
est assez large : le nombre d'instances ne dit rien sans la surface. Le test
compare désormais **instances / m²** aux bandes de la bible, et vérifie que
la largeur des cellules reste dans les 24-48 m de §7.5.

## D-040 — Un brin d'herbe fait 3 cm, et ses normales regardent le ciel

Monter la densité a révélé la vraie faute, invisible tant que la prairie
était clairsemée : la « touffe » était faite de trois quads de **34 cm** de
large qui s'effilaient vers le haut. À la densité de la bible, le premier
plan s'est couvert de petits sapins vert foncé.

Deux causes, séparées :

- la **largeur**. Sept brins de 3,6 cm, écartés, inclinés et ployés vers la
  pointe lisent « touffe » ; trois plaques larges lisent « cône » ;
- les **normales**. `generate_normals()` sur des quads verticaux produit des
  normales horizontales : la touffe ne recevait presque rien du ciel et
  ressortait bien plus sombre que le sol qu'elle prolonge. Les normales sont
  inclinées à 72 % vers le haut — l'usage courant pour l'herbe — et la masse
  s'éclaire au lieu de se découper en carton.

Leçon générale : une densité trop faible **cache** les défauts de forme de
l'élément répété. Corriger la densité d'abord, regarder ensuite.

## D-041 — Une position d'ancrage se MESURE, elle ne se choisit pas

**Contexte.** Trente et un lieux devaient recevoir une récompense. La première
tentative a produit 23 placements « au centre du volume du lieu » : plausibles,
jamais vérifiés, plusieurs dans un mur ou dans le vide. Le test d'alors était
vert — il comptait des coffres.

**Décision.** Les positions viennent d'une sonde physique
(`tools/godot/probe_reward_anchors.gd`) qui monte la vallée réelle et éprouve,
autour de chaque lieu, le sol, le dégagement au gabarit du joueur et le couloir
d'approche. Le résultat est FIGÉ dans la table du bâtisseur, pas recalculé au
lancement : une position trouvée par recherche à chaque démarrage serait
irreproductible et masquerait une régression du terrain.

**Alternative rejetée.** Chercher l'emplacement à la construction. Le monde
serait toujours « correct » et un lieu cassé ne se signalerait jamais.

**Limite honnête.** La sonde prouve la géométrie, pas l'esthétique. Elle a
validé un coffre au milieu d'un bassin — sol réel, accès réel, à demi immergé.
D'où `scenes/tests/RewardAnchorShot.tscn`, qui montre chaque récompense depuis
l'œil du joueur.

## D-042 — Un lieu à gravir refuse la preuve par navigation

**Contexte.** Le belvédère du guetteur est au sommet d'une échine de 36 m. Un
`NavigationServer3D` répond volontiers « accessible » pour ce genre de point,
parce qu'un navmesh ignore la hauteur de saut, l'endurance et les surfaces
réellement escaladables.

**Décision.** `RewardAnchor.requires_traversal` marque ces lieux, et
`RewardAnchorAudit` y exige un corps qui part du PIED déclaré
(`traversal_base`) et arrive réellement, sous gravité, en gravissant ce que le
bâtisseur prétend gravissable. Aucun chemin de navigation n'est accepté comme
preuve.

**Alternative rejetée.** Faire confiance au navmesh et signaler « à vérifier ».
Un critère non testé serait resté `NON VÉRIFIÉ` jusqu'à la livraison.

## D-043 — L'archive jouable se publie en Release, jamais dans le dépôt

**Contexte.** L'archive pèse quelques centaines de mégaoctets. Un dépôt Git la
garderait pour toujours, et la découper en fragments committés reporterait le
problème sur celui qui télécharge.

**Décision.** Un workflow (`.github/workflows/publish-playtest.yml`) reconstruit
le ZIP depuis le commit publié, vérifie `unzip -t`, calcule le SHA-256, crée la
Release et téléverse. Un garde-fou fait échouer le workflow si `git status` voit
le moindre artefact : la protection ne repose pas sur la vigilance de l'auteur.

**Adaptation contrainte.** Le mandataire Git du conteneur de développement
n'autorise que la branche de travail et refuse les refs de tag (HTTP 403). Le
tag ne peut donc pas être poussé depuis la machine qui valide : le workflow
accepte aussi un déclenchement manuel et CRÉE alors le tag
`playtest-<short_sha>` sur le commit qu'il vient de construire. Le tag pointe
toujours exactement sur le commit publié.

---

## D-044 — Le joueur de playtest est un PROCESSUS séparé, pas un sous-agent

**Date** : 2026-08-04. **Contexte** : rendre le playtest réellement en boucle
fermée, avec une séparation technique et non déclarative.

**Décision** : le joueur est un `claude -p` neuf, lancé par
`tools/blackbox_player/play.sh`, dont les outils sont imposés en ligne de
commande (`--allowedTools`, `--disallowedTools`) et se limitent aux cinq outils
du serveur MCP `blackbox`.

**Pourquoi pas un sous-agent de la session courante, comme prévu** :
`.mcp.json` et `.claude/agents/*.md` sont lus au **démarrage** de Claude Code.
Créés en cours de session ils ne sont pas chargés — vérifié deux fois :
`ToolSearch` ne trouvait aucun `mcp__blackbox__*`, et le type d'agent
`blackbox-player` était introuvable. Les deux fichiers restent versionnés :
une session ouverte après ce commit disposera du sous-agent directement, et le
texte de consignes est partagé entre les deux voies.

**Alternative rejetée** : donner `Read` au joueur et lui demander de ne lire
que la capture. Rejetée parce que la séparation serait déclarative — il
pourrait lire le code, la trace ou les tests, et rien ne le prouverait.

**Alternative indisponible** : l'API Computer Use (`computer_20251124`). Ni
`ANTHROPIC_API_KEY`, ni `ANTHROPIC_AUTH_TOKEN`, ni SDK `anthropic` dans ce
conteneur. Vérifié, pas supposé.

---

## D-045 — Le verrouillage par pas est EXTÉRIEUR au jeu

**Date** : 2026-08-04.

**Décision** : suspendre le processus Godot par `SIGSTOP` pendant que le modèle
regarde l'image, le reprendre par `SIGCONT` pendant l'action.

**Pourquoi** : le modèle met plusieurs secondes à décider ; un jeu qui continue
tue le joueur pour une raison étrangère au jeu. Une pause interne aurait exigé
de **modifier le jeu pour le mesurer** — et aurait pu fuiter un état privé vers
le joueur. `SIGSTOP` est invisible du programme suspendu.

**Contrepartie assumée, et écrite dans le protocole** : la durée perçue n'est
pas la durée réelle. Tout enchaînement jugé confortable sous verrouillage doit
être rejoué **sans** suspension avant qu'on affirme qu'il est jouable. Ce rejeu
est un contrôle de faisabilité, pas un nouveau playtest, et ne produit aucune
note.

**Effet de bord corrigé le jour même** : plafonner l'attente à 2,5 s comme les
actions a forcé le premier joueur à prendre huit « décisions » consécutives
pendant un simple écran de chargement, jusqu'à soupçonner un blocage
inexistant. Attendre n'est pas agir : `game_wait` va désormais jusqu'à 8 s.

---

## D-046 — L'échelle du kit végétal se corrige en UN point, pas sept

**Date** : 2026-08-04. **Origine** : premier playtest en boucle fermée.

**Constat mesuré** : le kit `assets/environment/foliage/` a été importé sans
normalisation. `Flower_4_Group` fait 2,49 m quand la bible §3 borne les fleurs
à 0,18–0,55 m ; `Fern_1` fait 9,05 m de large ; `Grass_Common_Tall` 1,87 m pour
une borne à 0,95 m. Sept modules le posaient à l'échelle native.

**Décision** : `scripts/world/kit_scale.gd` porte une table
`asset → [hauteur native mesurée, hauteur visée]` et le facteur en découle par
division. Les sept `_spawn`/`_piece` la consultent ; le facteur du site d'appel
reste une **variation** (0,85 à 1,3 dans l'existant) et se multiplie.

**Pourquoi la table garde les deux hauteurs** : pour rester vérifiable. On peut
remesurer le `.gltf` avec `tools/gltf_inspect.py` et refaire la division. Une
table de facteurs nus serait invérifiable.

**Alternative rejetée** : redimensionner les `.gltf` à la source. Rejetée parce
que ce sont des assets externes attribués ; les modifier ferait diverger le
fichier de sa provenance déclarée dans `ATTRIBUTIONS.md`, pour un gain nul —
l'échelle est une décision de placement, pas une propriété de l'asset.

**Alternative rejetée** : corriger seulement la fleur signalée. Rejetée : le
joueur avait vu UN symptôme ; la mesure de tout le dossier a montré treize
assets hors bornes. Corriger le symptôme aurait laissé la fougère de neuf
mètres en place.

## D-047 — ReactionSystem : nœud de scène découvert par groupe, PAS un autoload

Date : 2026-08-05 (P2-1, préparation P2-2).

Le `ReactionSystem` du Prompt 2 (§4) sera un `Node` instancié par chaque monde
et chaque laboratoire, retrouvé par le groupe `reaction_system` via un helper
statique — jamais un sixième autoload.

**Raisons.** (1) Hermétisme des tests : l'état d'une réaction ne survit jamais
à la scène qui l'a créée — la leçon R-017 (suites mensongères par état
partagé/contention) interdit un arbitre global mutable traversant les suites.
(2) La liste d'autoloads de CLAUDE.md est un invariant stable ; l'étendre
exige plus qu'une commodité de câblage. (3) Un lab peut instancier DEUX
systèmes côte à côte pour comparer des budgets — impossible avec un singleton.

**Alternative rejetée** : autoload à la manière d'`EventBus`. Rejetée car
`EventBus` ne porte que des signaux sans état ; le ReactionSystem porte des
files de paquets et des sous-graphes `dirty` — de l'état mutable, exactement
ce qui pollue les suites.

## D-048 — La latence se mesure en ticks physiques, aux points de vérité

Date : 2026-08-05 (P2-1).

La sonde (`LatencyProbe`) marque la réception au front d'événement dans
`PlayerInputReader._input` — le SEUL lecteur d'InputMap (D-013) — et la
consommation à l'endroit exact du changement d'état (`_try_jump` réussi,
`_mode = ATTACKING`, départ d'esquive), jamais à la lecture de l'intent.
Le critère de gate est en **ticks physiques** ; les millisecondes sont
affichées mais jamais assertées (R-017 : wall-clock non probant ici).

**Alternative rejetée** : mesurer dans `_process` du contrôleur (plus simple,
un seul fichier). Rejetée : cela mesurerait la latence de LECTURE, pas celle
de l'EFFET — un appui lu puis refusé compterait comme consommé, et le refus
perdrait sa raison (P2 §5.7 exige la raison de refus dans l'overlay).

**Articulation avec `LatencyInstrument` (B.5)** — pas un doublon : B.5 mesure
le pipeline intention INJECTÉE → mouvement (il documente exclure le reader,
qu'il court-circuite par D-013) et produit des campagnes statistiques ;
`LatencyProbe` mesure la chaîne RÉELLE événement → `_input` → intent → état,
au fil de l'eau, pour l'overlay et les refus. B.5 prouve le cœur ; P2-1
prouve la chaîne complète et l'expose en continu. Les deux tests coexistent
(`test_latency.gd`, `test_p2_latency.gd`).

## D-049 — Les liens d'Arc Link sont ÉPHÉMÈRES : jamais sauvegardés

Date : 2026-08-05 (clôture P2-2).

P2 §3.3 laisse le choix (« liaisons persistées uniquement si le design le
demande »). Décision : le design ne le demande PAS. Un lien d'Arc Link est un
arc tendu par le Bracelet — il se dissout au changement de scène, au
rechargement d'une sauvegarde et à la destruction d'un port. Trois raisons :
(1) cohérence de fiction — l'arc est une tension entretenue, pas une
installation ; (2) aucune énigme ne doit DÉPENDRE d'un lien posé dans une
session précédente (anti-softlock §15.11 : l'état persistant reste celui des
nœuds réels) ; (3) économie de schéma — pas de migration de sauvegarde pour
un objet dont la durée de vie naturelle est la seconde.

**Alternative rejetée** : persister le lien actif dans le save v4. Rejetée :
un lien restauré dans une géométrie qui a bougé (conducteur déplacé) serait
soit faux, soit silencieusement dissous au premier tick — autant assumer
l'éphémère et l'enseigner par la constance.

## D-050 — Le `fov` de la caméra de jeu est un angle VERTICAL, et il est déclaré comme tel

Date : 2026-08-06 (passe jouabilité V5).

`Camera3D.keep_aspect` vaut `KEEP_HEIGHT` par défaut dans Godot 4.7.1
(`scene/3d/camera_3d.h:76` ; `camera_3d.cpp:287` ne passe `true` à
`set_perspective` que pour `KEEP_WIDTH`). La propriété `fov` décrit donc la
hauteur du champ. Les spécifications du projet (§8.3, VISUAL_ASSET_BIBLE §3.1)
expriment le cadrage en HORIZONTAL. Le réglage portait 70 et 76 en croyant
écrire des degrés horizontaux : la caméra de jeu tournait à **102,5°**.

Décision : garder `KEEP_HEIGHT` — c'est le choix du paysage, un écran plus
large montre plus sur les côtés au lieu de rogner en haut — mais le POSER
explicitement dans `CameraRig._ready()`, et convertir dans le test au lieu de
comparer deux unités différentes. Valeurs : 44° vertical (71,4° horizontal) au
repos, 47° (75,4°) en sprint.

**Alternative rejetée** : passer en `KEEP_WIDTH` pour que `fov` signifie
directement l'horizontal de la spec. Rejetée : cela rogne le champ vertical sur
les écrans moins larges, et rend le comportement du projet différent du défaut
du moteur — une surprise de plus pour la prochaine personne qui lira la valeur.

**Ce que cette décision coûte** : les captures de référence antérieures ont été
prises avec une caméra de composition à 42-44°, jamais avec la caméra de jeu.
Elles ne sont donc pas comparables à ce que voyait le joueur. Les captures V5
sont les premières où les deux coïncident.

## D-051 — La sauvegarde écrit le dernier SOL foulé, jamais la position courante

Date : 2026-08-06 (passe jouabilité V5).

Un playtest en boîte noire a produit une perte de partie définitive : le héros
s'est accroché seul à une pente d'herbe, la caméra est entrée dans le terrain,
l'endurance est tombée à zéro — et la sauvegarde automatique a écrit cette
position. « Continuer » rechargeait dans le trou ; la seule issue était de
perdre la partie. La garde existante (`_is_saved_position_safe`) ne teste que
les nombres valides et les bornes du monde : un trou à l'intérieur de la carte
les franchit sans problème.

Décision : `PlayerController` retient la dernière position où il se tenait
réellement au sol, et c'est CELLE-LÀ que la sauvegarde écrit. On ne peut pas
recharger dans un endroit où l'on n'a jamais pu se tenir debout.

**Alternative rejetée** : un détecteur de blocage qui téléporte le joueur au
bout de N secondes. Rejetée : il traite le symptôme, il est visible en jeu, et
il laisse la sauvegarde corrompue derrière lui. Retenir le sol coupe la classe
entière du défaut, en amont, sans rien montrer au joueur.

**Corollaire appliqué** : on ne s'accroche plus à une paroi au-dessus de la
vitesse de marche, et le seuil d'intention passe de 0,22 s à 0,40 s — 0,22 s de
contact EST le comportement normal de quelqu'un qui court dans un obstacle.


## D-052 — La citadelle ne reçoit PAS le kit Castle : l'échelle ne pardonne pas

Le lot 5 de la finition monde prévoyait de réutiliser `kenney_castle_2_0` sur
la citadelle. Mesuré : les pièces du kit sont au pas de ~1 m (wall-pillar
1,0 × 1,31 m) ; les masses de la citadelle font 10 à 50 m. Les employer
exigerait un facteur ×8-15 qui détruirait la densité de texel et donnerait
un château de jouet gonflé — pire que l'habillage taluté de la passe 3, qui
travaille aux bonnes proportions. Le kit sert donc là où son échelle est
JUSTE : modules du donjon (lot 6), et candidats fortification/tour de guet.
Alternative rejetée : re-modéliser la citadelle en modules — hors budget de
la passe, la silhouette actuelle ayant déjà passé la revue des masses.


## D-053 — Le gel V2.3-B est levé sur deux fichiers, pour poser l'appareil de mesure d'ISS-071

**Le fait.** `tools/gel_verifier.sh` et le filet D8 ont rougi sur
`scripts/world_v2/world_v2_root.gd` et
`scripts/world_v2/world_v2_vegetation_builder.gd`. Ils ont eu raison : j'ai
touché deux fichiers que le gel V2.3-B protège, et le gel l'a dit en secondes.

**Pourquoi il a fallu les toucher.** La directive corrective S1 exige une
parité MESURÉE entre l'exécution éditeur et la build exportée : index nom →
chemin des deux résolveurs, modèles demandés, modèles chargés, modules
instanciés, cellules de MultiMesh émises. Or une build release **n'accepte pas
`--script`** : aucun outil du dépôt ne peut l'atteindre. Le seul endroit d'où
l'on puisse lire l'index RÉEL d'une build installée est le jeu lui-même, une
fois le monde monté — c'est-à-dire `world_v2_root.gd`, après son jalon
« fondation V2 vérifiée ». Et le compte des cellules végétales n'existe qu'à
l'endroit qui les émet, `_emit_model_cells()`.

Sans ces deux points, la parité exigée par la directive resterait une
affirmation. Le défaut d'ISS-071 — 1 094 appels de placement manqués, 110
modèles absents — n'était visible d'aucune de nos suites, précisément parce
qu'elles tournent toutes en éditeur.

**Ce que le changement est, exactement.** `git diff` sur les deux fichiers :
**181 insertions, 0 suppression.** Aucune ligne existante n'est modifiée. Tout
ce qui est ajouté est un appareil de mesure :

- lecture d'un argument de ligne de commande ;
- assemblage d'un manifeste JSON (index, demandes, résolus, manques, collisions) ;
- épreuve de chargeabilité de chaque chemin indexé, par un vrai `load()` ;
- capture des six vues des lieux gelés depuis la build exportée ;
- deux compteurs entiers dans le bâtisseur de végétation.

Chaque chemin ajouté commence par un test de drapeau et **sort immédiatement**
s'il est absent : `--iss071-dump=`, `--iss071-vues=`, `--iss071-chargeabilite=`.
Le chemin de jeu normal ne les rencontre jamais.

**Ce que la mesure dit du risque.** Le manifeste éditeur produit après le
correctif est identique, hors le champ `chargeabilite` qui vient d'être ajouté,
à celui mesuré avant tout correctif — `275954a71a2eb5c5` des deux côtés, sur
plusieurs exécutions indépendantes. Les six vues des lieux gelés, recapturées,
sont comparées à celles d'avant correctif (voir
`evidence/world_v2/v2_3_b/iss071/apres/`).

**Alternative rejetée** : sortir le vidage dans un nœud non gelé, ajouté à
`WorldV2.tscn`. Elle échoue sur un point qui compte : ce nœud n'aurait aucun
signal de fin de montage à attendre et devrait DEVINER, par un nombre de frames
ou un compte de nœuds, que le monde est prêt. Un diagnostic qui se déclenche
trop tôt produit un index PARTIEL et donc un verdict de parité FAUX — un
résultat pire que celui qu'on cherche à éviter. On préfère un gel levé
explicitement et justifié à une mesure fragile.

**Ce que cette levée ne couvre pas.** Les 46 fichiers gelés des six lieux
visuellement acceptés — scènes, scripts de lieu, GLB, générateurs, shaders —
n'ont pas bougé d'un octet : 46/46 au sha256 du disque ET à l'empreinte de blob
git, vérifiés avant, pendant et après. Aucun seuil n'a été abaissé, aucun
critère D1–D8 n'a été changé : seule la LISTE d'empreintes du gel est
régénérée, par la procédure que `gel_verifier.sh` documente lui-même
(`--ecrire` plus justification ici).
