# AUDIT — la V2 face à 30-50 h / 80-120 h / 200 h+

Statut : **VIVANT — EN COURS DE COMPLÉTION.** Date d'ouverture : 2026-08-27.

Autorité amont : `docs/V2_PRODUCT_DOCTRINE.md` (l'ambition),
`docs/V2_LONG_GAME_ROADMAP.md` (l'ordre et le coût).

## Comment cet audit est produit, et comment il se lit

Dix-huit domaines, un auditeur par domaine, **puis un sceptique par domaine**
chargé non pas de confirmer mais d'attaquer les notes « fonctionnel » : un
fichier présent n'est pas une preuve d'exécution, et un test dont le nom évoque
le sujet n'en est pas une s'il ne teste qu'une construction d'objet.

Le vocabulaire est celui du dépôt, et il est contraignant :

| Mot | Ce qu'il exige |
|---|---|
| `fonctionnel` | testé dans une scène exécutable — **preuve nommée obligatoire** |
| `présent` | existe et est raccordé, sans preuve d'exécution |
| `prototypé` | existe en placeholder, ou sans raccordement |
| `absent` | rien |

**Cet audit est incomplet à l'heure où il est écrit.** Les domaines rendus
figurent ci-dessous ; les autres arriveront. Publier un audit partiel en le
disant vaut mieux que publier un audit complet en le supposant — et une
référence pendante depuis la feuille de route serait un défaut.

## Le socle chiffré, mesuré indépendamment des agents

Aucun nombre de cette section ne vient d'un sous-agent. Ils sont produits par
`tools/mesures_socle.py`, qui lit le dépôt et l'historique git, et ils servent
à **confronter** les rapports à une base qu'ils n'ont pas écrite.

| Grandeur | Mesure |
|---|---:|
| Sujets déclarés au layout | **34** (31 POI + 3 sites systémiques) |
| Lieux montés dans le REGISTRY | **15** |
| Déclarés et NON construits | **21** |
| Achèvement de la région 1 | **44 %** |
| Chantier World V2 | 2026-08-12 → 08-27, **723 commits** |
| dont touchant un fichier de lieu | **355 (49 %)** |
| Coût médian d'un lieu | **24 commits** (min 15, max 45) |
| `class_name` déclarés dans `scripts/` | **164** |
| Autoloads | **6** |

### Sondes de présence — un système, pas un mot

Un `grep quest` rend treize fichiers ; ils matchent tous `request`. La sonde
cherche donc des `class_name` **déclarés**, plus les autoloads — qui n'ont
jamais de `class_name`, leur nom étant déjà global.

**ABSENTS** — quêtes · dialogues · PNJ · new game + · streaming de région ·
artisanat hors cuisine · marchand/économie · météo/cycle jour.

**PRÉSENTS** — cuisine · sauvegarde · résonance · réactions de matériaux ·
graphe électrique · boss · IA utilitaire · inventaire · état de jeu.

Le socle systémique est là. C'est la **couche de jeu long** qui manque, et
elle forme une chaîne unique : `PNJ → quêtes → narration → rejouabilité`.

### Ce qu'aucun audit ne peut établir depuis ce conteneur

- **Aucun temps de jeu réel n'a jamais été mesuré.** Toute estimation d'heures
  de ce document est un raisonnement, pas une observation.
- Fluidité, budget de frame, hitchs : impossibles ici — pas de GPU, et
  l'horloge du moteur est décrochée du temps mural d'un facteur 17 à 76
  (ISS-072).
- Le ressenti — plaisir, clarté, injustice — appartient au playtest humain.

---

## Domaines audités

### Combat, ennemis et boss

**Importance pour 30-50 h : BLOQUANT**

Le NOYAU de combat est la partie la mieux construite du dépôt : contrat d'attaque data-driven (startup/actif/recovery/buffer/combo), une-touche-par-swing prouvée, garde + déviation parfaite + Clarity, posture et poise séparés, hit-stop et shake consommés depuis l'événement, coordinateur à jetons, directeur de patterns de boss semé et rejouable — le tout adossé à des tests nommés qui échoueraient réellement. Ce n'est pas un prototype : c'est un moteur de combat correct et instrumenté. Mais il n'y a presque rien à combattre. J'ai compté 9 instances d'ennemis dans TOUT le jeu jouable, toutes dans `scripts/world/valley_world.gd` (la vallée V1), posées en solitaires patrouillants ; `scripts/world_v2/` — le pilote déclaré de la première région — ne contient AUCUN ennemi, AUCUN coordinateur, aucune référence à `scenes/enemies/` ; le donjon n'en contient aucun non plus. Le vocabulaire offensif total du jeu est de 21 `AttackDefinition`, dont 8 pour le joueur — et les cinq armes de mêlée partagent littéralement la même chaîne légère (`resources/combat/sword/light_1..3.tres`), seule la lourde diffère. Aucune attaque n'est étiquetée blocable/déviable/imblocable, il n'y a pas d'esquive parfaite, pas d'attaque de sprint, d'esquive-sortie, d'aérienne ni de « dernier éclat », pas de respawn ennemi et pas de progression. Pour 30-50 h, le domaine est un excellent socle sous un contenu quasi vide : la distance n'est pas dans l'architecture, elle est dans le nombre.

| Classement | Nombre |
|---|---:|
| fonctionnel | 14 |
| prototypé | 7 |
| **absent** | 9 |

**Absent :**

- Phase 2 du boss telle que MASTER_SPEC §16.4 la décrit : projectiles électriques + portions de sol électrifiées
- Étiquettes tactiques des attaques (blockable / deflectable / dodgeable / interruptible, imblocable, brise-garde) — P2 §7.1
- Esquive parfaite (fenêtre 0,10-0,16 s, remboursement d'endurance, Clarity)
- Action de « dernier éclat » à durabilité critique (P2 §7.6)
- Attaques de sprint, aériennes/plongeantes, de sortie d'esquive
- Combat dans World V2 (le pilote déclaré de la première région)
- Combat dans le donjon
- Respawn / repopulation des ennemis
- Progression de combat (montée en puissance, déblocages, spécialisation)

**Manques nommés pour 30-50 h (18) :**

- ZÉRO ennemi dans World V2. `scripts/world_v2/` (14 builders) ne référence ni `scenes/enemies/`, ni `EnemyBase`, ni `CombatCoordinator`. La région pilote de la campagne n'a aucun combat. C'est le manque numéro un, et il précède tous les autres.
- ZÉRO ennemi dans le donjon. `scripts/dungeon/*.gd` n'en instancie aucun : on traverse la Citadelle de l'Œil-Tempête, ses quatre salles, sa salle centrale et son antichambre sans rencontrer un adversaire avant le boss.
- 9 instances d'ennemis dans tout le jeu jouable, toutes dans `scripts/world/valley_world.gd`, toutes en solitaires patrouillants. Aucune rencontre de GROUPE n'est posée : le `CombatCoordinator` (2 jetons mêlée, 1 lourd) est testé unitairement mais n'a jamais 3 ennemis à arbitrer dans le monde réel. Le camp ennemi de MASTER_SPEC §4.1, censé porter les « trois approches » de P2 §5.6, n'a aucune garnison placée.
- AUCUN respawn ni repopulation. Le contenu de combat d'une partie est fini, consommable une fois, non renouvelable. Rien ne peut soutenir 30-50 h, encore moins 200 h de « jeu durable ».
- 5 armes de mêlée pour UNE seule chaîne légère partagée (`resources/combat/sword/light_1..3.tres`). Il manque au minimum 4 chaînes légères propres (club, lance, hache, lame conductrice) = 12 `AttackDefinition` à écrire, plus les clips correspondants. P2 §7.5 demande 4-6 actions utiles par famille ; le dépôt en livre 2.
- AUCUNE attaque de sprint, aérienne/plongeante, ni de sortie d'esquive — trois des cinq catégories de P2 §7.5, absentes pour les six familles. Environ 15-18 `AttackDefinition` manquantes.
- AUCUNE action de « dernier éclat » (P2 §7.6) : la durabilité critique n'ouvre aucune décision, elle ne fait que prévenir.
- AUCUNE étiquette tactique sur les attaques (`blockable`, `deflectable`, `dodgeable`, `interruptible`, imblocable, brise-garde). La matrice menace×réponse de P2 §7.4 — six lignes — n'est exprimable ni en données ni en test. Champ à ajouter à `AttackDefinition`, puis à renseigner sur les 21 .tres existants.
- … et 10 autres, dans le rapport brut

**Dette technique :**

- `resources/combat/attack_definition.gd` ment sur son propre code : le commentaire du champ `hit_stop` affirme « aucun système de gel de frame n'existe encore », alors que `_hitstop_timer` est consommé dans `player_controller.gd` ET `enemy_base.gd`. Une doc en retard sur le code est un piège pour la prochaine session.
- `scripts/player/player_controller.gd` fait 2 097 lignes et 92 fonctions. Il porte la locomotion, la caméra, la garde, la parade, l'esquive, la Résonance, les dégâts reçus et la mort. C'est le contre-exemple exact de PROMPT4 §8 (« ce comportement a-t-il besoin de l'état mutable privé de ce coordinateur ? ») : la garde/parade est une unité pure extractible, testable sans scène.
- La garde est branchée sur `intent.aim_held` (`wants_guard: bool = intent.aim_held and not intent.focus_held`) : garder et viser à l'arc partagent la même entrée physique. Aucune action InputMap `guard` dédiée. Conflit fonctionnel à trancher avant d'ajouter la moindre profondeur défensive.
- ISS-015 (docs/KNOWN_ISSUES.md, S3, ouvert) : la SURCHARGE de la phase 2 part sur un intervalle de 9 s ; un joueur efficace traverse la phase 2 sans jamais la rencontrer. L'idée tactique centrale de la phase 2 peut ne jamais s'afficher.
- ISS-016 (S4, ouvert) : `tests/playthrough/test_boss_run.gd` postule le contact — il appelle `HurtboxComponent.receive_hit()` au lieu de faire balayer une vraie hitbox. Le run boss ne prouve donc rien sur la portée, l'angle ni le timing. C'est un test qui ne peut pas rougir sur ces axes (PROMPT4 §2).

**Preuve d'acceptation future.** Un test d'intégration `tests/world_v2/test_world_v2_bestiary.gd` (à créer) doit affirmer, sur la scène World V2 réellement montée : (a) au moins N ennemis instanciés et présents dans le groupe `enemies`, N étant la cible chiffrée arrêtée par le propriétaire ; (b) les cinq familles présentes chacune dans son rôle ; (c) au moins un `CombatCoordinator` dans l'arbre, avec au moins un groupe de 3 ennemis ou plus dont le test prouve que jamais plus de 2 n'attaquent simultanément ; (d) les routes principales de la région restent franchissables avec le bestiaire posé — sur le modèle exact de `test_the_north_road_to_the_citadel_stays_walkable_with_the_bestiary` qui existe déjà pour la vallée V1. Pour les armes : un test qui échoue si deux familles de mêlée partagent la même ressource de chaîne légère, écrit ROUGE d'abord sur l'état actuel (il doit rougir aujourd'hui, sinon il ne prouve rien). Pour le boss : un test qui échoue si une phase quelconque expose moins de trois patterns légaux à distance de mêlée ET à distance d'arc. Pour la lisibilité : chaque `AttackDefinition` d'ennemi porte au moins une étiquette de réponse (blocable / déviable / esquivable / imblocable) et un test balaie l'ensemble des .tres pour en refuser une sans étiquette. Enfin, hors machine : un essai humain documenté dans `docs/MANUAL_VALIDATION.md` mesurant la durée réelle d'une première victoire sur le Gardien (§16.1 : 4-7 min) et le temps de combat cumulé sur un parcours complet de la région — les deux chiffres restent `EN ATTENTE` tant qu'aucun joueur n'a joué, et ne peuvent pas être déduits des tests.

### Déplacement et sensation de contrôle

**Importance pour 30-50 h : MAJEUR**

Le socle de locomotion est le domaine le mieux tenu du dépôt, et il faut le dire aussi clairement que ses manques : réglages entièrement pilotés par ressource (`resources/tuning/locomotion_default.tres`, `climb_default.tres`, `stamina_default.tres`), chaque valeur documentée par l'incident qui l'a produite, et 114 cas de test que j'ai comptés moi-même à travers 13 fichiers — dont des contrôles négatifs, des refus nommés et une latence mesurée par la vraie chaîne d'entrée à 1 tick physique. Marche, course, sprint, saut, coyote, buffer, franchissement de marche par shape cast, pentes, endurance avec hystérésis, escalade à trois sondes, mantle aligné, caméra qui n'entre ni dans le héros ni sous le terrain : tout cela est `fonctionnel` au sens strict du dépôt, et le héros marche les quatre routes de World V2 sans une seule téléportation.

Ce socle est pourtant à peu près la moitié du domaine, et c'est l'autre moitié qui décide de l'agrément sur 30 heures. Elle est vide, et mesurablement : zéro AnimationTree, zéro blend space, zéro root motion, zéro IK, zéro durée de fondu dans tout le dépôt — le héros joue le clip `walk` pendant qu'il escalade une falaise, parce qu'aucun clip d'escalade n'est déclaré. `physics/common/physics_interpolation` est absent de `project.godot`, dont la section `[physics]` ne contient qu'une ligne : sur un écran 120 ou 144 Hz, le personnage saccadera à chaque image, et les cinq appels à `reset_physics_interpolation()` déjà écrits dans le code sont aujourd'hui sans effet.

Le vocabulaire de traversée est celui d'une région, pas d'une campagne. Vault et slide, exigés nommément par PROMPT2 §5.3, sont absents : la chaîne de Flow que la spec demande ne peut pas être assemblée. Les quatre « aides invisibles » de §5.2 n'existent pas. La machine de modes de caméra de §5.5 non plus — trois comportements sont câblés en dur dans `camera_rig.gd`, sans transitions ni priorités. Et `is_surface_climbable()` accepte tout sauf six groupes : dans World V2, un seul site pose `unclimbable`, l'anneau de bordure. Chaque ferme et chaque arbre du monde s'escalade.

Deux constats méritent d'être isolés parce qu'ils sont du travail perdu. La monture — la seule réponse construite au problème d'échelle, 12 cas de test verts, galop à 14 m/s — est instanciée dans `valley_world.gd`, le monde V1, alors que le menu principal charge `WorldV2.tscn` : elle est prouvée et inatteignable. Et VALIDATION-B-001 est ouverte depuis le Gate B, CONTROLLER-001 est `BLOQUÉ`, `docs/STATUS.md` porte encore « Absence de jitter caméra : NON VÉRIFIÉ ».

La phrase qui résume le domaine : **il a été mesuré abondamment et ressenti jamais.** Aucune des 114 assertions ne dit si le mouvement est agréable, et la question posée — l'est-il sans objectif ? — reste sans réponse.

| Classement | Nombre |
|---|---:|
| fonctionnel | 13 |
| prototypé | 3 |
| **absent** | 9 |

**Absent :**

- Machine de modes de caméra (Explore, Sprint, LockOn, Aim, Climb, Interaction, Boss, Vista, Cinematic) — MASTER_SPEC §10.9 et PROMPT2 §5.5
- Vault (franchissement d'obstacle bas) — PROMPT2 §5.3
- Slide après sprint, et saut de paroi (wall leap) — PROMPT2 §5.3
- Aides invisibles de PROMPT2 §5.2 (tolérance de bord, correction latérale de coin, grâce de mantle, conservation de la cible de saut)
- Pipeline d'animation du mouvement : AnimationTree, blend spaces, root motion, IK de pieds et de mains, transitions 0,10–0,22 s (MASTER_SPEC §7.12, §23.3)
- Animation d'escalade et de déplacement latéral sur paroi
- Interpolation physique (MASTER_SPEC §20.9, PROMPT2 §13.3) — fluidité hors 60 Hz
- Remappage complet des commandes, détection du périphérique actif et glyphes correspondants (MASTER_SPEC §8.5, PROMPT2 §12.3)
- Ressenti humain du mouvement : jitter, à-coup, plaisir de contrôle, tests à 30/60/120 FPS

**Manques nommés pour 30-50 h (17) :**

- **Interpolation physique.** Ajouter `physics/common/physics_interpolation=true` à `project.godot` et vérifier les cinq sites appelant déjà `reset_physics_interpolation()` (aujourd'hui no-op), plus les spawns de World V2 qui ne l'appellent pas. Sans cela, le jeu saccade sur tout écran ≠ 60 Hz. Coût : faible. Impact : maximal sur 30-50 h.
- **Animation d'escalade.** `resources/characters/hero_anim_set.tres` déclare 15 clips, aucun d'escalade. Manquent au minimum : montée, descente, latéral gauche/droite, repos sur paroi, accroche, lâcher — 6 clips. Aujourd'hui le héros joue `walk` en l'air, branche `Mode.CLIMBING` de scripts/player/player_visual_driver.gd.
- **Durées de fondu.** Zéro `blend_time` dans tout le dépôt. MASTER_SPEC §7.12 exige des transitions de locomotion en 0,10–0,22 s ; §23.3 interdit le « pop évident ». Il faut au minimum une table de fondus par paire d'états, au mieux un AnimationTree.
- **AnimationTree + blend space de locomotion.** Aujourd'hui la sélection de clip est un escalier à trois seuils de vitesse (`WALK_MAX_SPEED` 4,75 / `RUN_MAX_SPEED` 7,5 dans player_visual_driver.gd) : marcher à 4,74 puis 4,76 m/s change brutalement de clip. Un blend space 1D sur la vitesse planaire est la correction minimale.
- **IK de pieds.** Aucun `SkeletonModifier3D` / `TwoBoneIK3D` / `LookAtModifier3D` dans le dépôt. MASTER_SPEC §23.3 interdit le foot sliding perceptible en locomotion principale ; sans IK ni root motion, il est structurellement garanti sur toute pente — et le monde en est fait.
- **Vault.** Absent. Nécessaire pour que les murets, barrières, rochers bas et débris de World V2 cessent d'être des murs. Sans lui la course est constamment interrompue par des obstacles de 0,5 à 1,2 m qui ne méritent ni un saut ni un mantle.
- **Slide après sprint.** Absent. PROMPT2 §5.3 le demande explicitement comme maillon de la chaîne de Flow.
- **Machine de modes de caméra.** Les 9 modes de MASTER_SPEC §10.9 / PROMPT2 §5.5 n'existent pas ; trois comportements sont câblés en dur dans camera_rig.gd. Manquent en particulier : Aim (visée à l'arc), Climb (la caméra ne se recule pas sur une paroi), Interaction, Vista, Cinematic — et surtout les transitions courtes et interruptibles avec priorités que la spec exige.
- … et 9 autres, dans le rapport brut

**Dette technique :**

- `scripts/player/player_controller.gd` fait 2 097 lignes (mesuré) et porte locomotion, escalade, mantle, attaque, esquive, arc, interaction, lock-on, cuisine rapide, buffs, visuel d'arme et flash de dégâts. Aucune machine à états séparée : le champ `Mode` est un `enum` de 7 valeurs. C'est la dette structurelle n°1 du domaine — PROMPT4 §8 (« ce comportement a-t-il besoin de l'état mutable privé de ce coordinateur ? ») s'applique directement.
- Écart déclaré entre `Mode` (7 valeurs) et les 20 états exigés par MASTER_SPEC §8.1. L'écart est assumé et documenté dans l'en-tête de `scenes/player/Player.tscn` (« StateMachine (§8.1) — le contrôleur porte un Mode couvrant exactement les états implémentés, voir D-018 »), mais il reste un écart : Land, Exhausted, Aim, Stagger, ClimbRest, Interact ne sont pas des états.
- `physics/common/physics_interpolation` absent de `project.godot` — la section `[physics]` ne contient qu'une ligne, `3d/physics_engine="Jolt Physics"` (mesuré). Conséquence : les cinq appels à `reset_physics_interpolation()` que porte le code (`scripts/world/mount.gd`, `scripts/world/valley_world.gd`, `scripts/tools/dev_fly_mode.gd`) sont aujourd'hui des no-op — du code écrit pour un réglage qui n'est pas activé.
- `resources/tuning/stamina_tuning.gd` documente ses propres coûts déclarés-non-câblés ; c'est honnête, mais la ressource porte encore les commentaires « Déclaré pour B.3 — l'escalade n'existe pas encore » alors que B.3 est livré et que `test_climbing.gd` mesure ces coûts. Documentation périmée dans un fichier faisant autorité.
- `LabOverlay` (`scripts/tools/lab_overlay.gd`) affiche mode, sol, vitesse, endurance, fps/tick et dernier refus, mais PAS les grandeurs que PROMPT2 §5.7 nomme : timer de coyote, timer de buffer de saut, normale du sol, cible de mantle, cible d'Arc Step, collision caméra. L'outil de diagnostic du domaine ne montre pas ce qui décide dans le domaine.

**Preuve d'acceptation future.** Le domaine sera acceptable pour une campagne de 30-50 h quand TOUT ce qui suit sera vrai et mesurable, chaque point rattaché à une preuve datée dans `evidence/` :

**1. Fluidité — mesurée, pas déclarée.** `physics/common/physics_interpolation=true` dans `project.godot`, prouvé par un test d'invariant d'état (au sens de PROMPT4 §2) qui lit le réglage. Puis, sur machine réelle avec GPU : le parcours de `TraversalCourse.tscn` capturé en vidéo à 60 Hz ET à 120/144 Hz, sans saccade visible, avec histogramme de frame time publié (p50/p95/p99, nombre de hitches > 33 ms). Ce point est BLOQUÉ dans ce conteneur et doit rester `BLOQUÉ` jusqu'à cette machine — jamais `PASS` par déduction.

**2. Aucun foot sliding perceptible.** Test automatique : sur une piste graduée et sur une pente de 20°, l'écart entre la distance parcourue par la racine et la distance parcourue par le pied de contact reste sous un seuil publié, aux trois cadences 30/60/120. Aujourd'hui ce test ne peut pas exister : il n'y a ni root motion ni IK.

**3. Aucune coupure d'animation.** Un test épingle une table de durées de fondu non nulles pour chaque transition de locomotion (idle↔walk↔run↔sprint, sol↔air, land), et le pilote visuel les applique. Contrôle négatif : mettre un fondu à zéro doit faire rougir le test.

**4. L'escalade a ses propres clips.** `hero_anim_set.tres` déclare `climb_up`, `climb_down`, `climb_left`, `climb_right`, `climb_rest`, et `CharacterAnimSet.missing_states()` mesuré contre le vrai `AnimationPlayer` importé rend une liste vide pour ces cinq états. Le contrôle qui doit rougir aujourd'hui : le pilote ne doit plus jamais jouer `walk` en mode CLIMBING.

**5. La chaîne de Flow existe et s'enchaîne.** Un test de type `test_traversal_course` étendu joue sprint → vault → saut → mantle → Arc Step d'affilée, dix fois de suite, sans état bloqué, sans traversée de collision, sans entrée perdue non intentionnelle, aux trois cadences. C'est le Gate de PROMPT2 §5.7, appliqué à la chaîne complète et non à ses maillons isolés.

**6. Un expert gagne 20 % de temps sur la route de Flow.** PROMPT2 §5.3 pose ce chiffre. Un scénario scripté « novice » (poussées simples) et un scénario « expert » (enchaînement optimal) sur le même segment, temps publiés, écart ≥ 20 % — sans exploit ni traversée de mur.

**7. Le monde décide ce qui s'escalade.** Un test de monde balaie World V2 et exige que 100 % des `StaticBody3D` de bâtiment, d'arbre et de mobilier portent `unclimbable`, et que les parois de falaise prévues ne le portent pas. Contrôle négatif : retirer le groupe d'un mur de ferme doit faire rougir le test.

**8. Le ressenti a été jugé par un humain.** Les six essais de `docs/MANUAL_VALIDATION.md` section Gate B joués et rapportés, avec captures, sur un commit nommé. Notes 1–5 sur contrôle, clarté, plaisir, avec un exemple concret par note (Gate « amusant avant habillage » de PROMPT2 §14.6) : contrôle et clarté ≥ 4, aucun axe < 3. **VALIDATION-B-001 fermée.**

**9. Manette réellement pressée.** CONTROLLER-001 levée par l'étape 3 du protocole Gate A, avec rapport. Tant qu'aucun stick n'a bougé, le statut manette reste `BLOQUÉ`, jamais `PARTIAL`.

**10. Vingt minutes sans objectif.** Le test qui compte vraiment, et qu'aucune machine ne rend : un joueur qui n'a pas construit le jeu explore World V2 vingt minutes sans mission, puis répond à « qu'as-tu eu envie de refaire ? ». Si la réponse ne cite aucun mouvement, le domaine échoue quel que soit l'état des 114 tests.

### Exploration et structure du monde

**Importance pour 30-50 h : BLOQUANT**

Le domaine possède une fondation sérieuse et une surface dérisoire. World V2 est un disque jouable de rayon 235 m — 0,173 km² mesurés — que la route principale traverse en 498 m, soit environ 1,4 minute de course ; l'amplitude verticale jouable déclarée par le layout est de 35,5 m. Cette fondation est réellement prouvée, ce qui est rare : 111 fonctions de test réparties sur 32 fichiers dans tests/world_v2/, dont quatre qui PILOTENT le vrai PlayerController jalon par jalon sur les quatre routes, un monde fermé sur tous les azimuts, une hydrologie qui contient son eau, un navmesh cuit par quadrant. Mais le contenu est un pilote inachevé : scripts/world_v2/poi/world_v2_places_builder.gd::REGISTRY compte 15 lieux construits — 12 des 31 POI du layout, plus le bassin, le camp et le pylône —, les 19 autres n'étant qu'un Node3D nu portant un pilier de diagnostic invisible. Trois vides structurels dominent tout le reste : le conteneur Encounters est exigé par la racine puis jamais rempli, et son vide est même verrouillé par un contrat de test, donc le monde ne contient AUCUN ennemi ; aucune SceneDoor n'existe sous scripts/world_v2/ alors que le menu ne mène plus qu'à World V2 — le donjon, le boss et la victoire sont donc inatteignables par le parcours joueur normal ; et rien dans l'architecture n'amorce une deuxième région, l'emprise étant codée en dur dans WorldV2Heightmap et close par 36 gardes unclimbable. Enfin l'orage, identité annoncée du jeu, est en World V2 un mesh statique dont la visibilité dépend d'une variable d'environnement de capture. Face à une ambition de 30 à 50 heures, ce domaine n'est pas en retard : il est d'un autre ordre de grandeur.

| Classement | Nombre |
|---|---:|
| fonctionnel | 11 |
| présent | 2 |
| prototypé | 4 |
| **absent** | 4 |

**Absent :**

- Les 19 POI restants et 2 des 3 sites systémiques
- Peuplement du monde (ennemis, patrouilles, territoires)
- Liaison monde ouvert -> donjon (fermeture de la boucle)
- Multi-région / streaming spatial / extension du monde

**Manques nommés pour 30-50 h (13) :**

- Liaison donjon : une SceneDoor en World V2 au seuil dungeon_gate (0, 34, -210), plus le redressement des deux retours qui pointent encore vers V1. Sans elle, 0 h de campagne est atteignable. Seul manque à coût faible et à effet total.
- Peuplement : 0 ennemi dans le monde, et le vide est verrouillé par contrat (test_aucun_acteur_et_les_routes_restent_libres). Pour la seule région 1, l'ordre de grandeur crédible est 60 à 120 acteurs répartis en une quinzaine de groupes (les 5 POI de faction du layout en portent la promesse). Il faut lever le contrat, puis écrire son remplaçant (budget d'IA actives, respawn, territoires).
- 19 POI construits sur 31, plus 2 sites systémiques. Au rythme observé — 6 lieux livrés au lot 1 entre le 2026-08-19 et le 2026-08-27, après 4 golden masters et deux passes correctives — finir la seule région 1 est un chantier de plusieurs mois. C'est le débit, pas la difficulté, qui est le problème.
- Surface : 0,173 km2 jouables aujourd'hui. Pour 30-50 h, l'ordre de grandeur usuel d'un action-aventure à exploration est 10 à 40 km2, soit 60 à 230 fois la surface actuelle. (Estimation de ma part, pas un fait du dépôt : ordre de grandeur, pas cible.)
- Nombre de régions : 1 région pilote existe, dont environ 40 % du contenu déclaré est construit. Une campagne de 30-50 h suppose typiquement 5 à 8 régions de cette ambition. Il en manque 4 à 7, ET la première n'est pas finie.
- Nombre de lieux : 15 construits. Pour 30-50 h à la cadence exigée par MASTER_SPEC §4.3 (un élément intéressant toutes les 15 à 30 s), il faut de l'ordre de 250 à 500 sites distincts. Il en manque plus de 95 %.
- Architecture multi-région : n'existe pas. Ni RegionManifest, ni gestionnaire de monde, ni chargement spatial, ni transition région<->région, ni carte globale. world_v2_layout.json doit devenir un format DE région, instancié N fois, avec un graphe de monde au-dessus. Aucun fichier du dépôt n'amorce ce travail.
- Souterrain et intérieurs : 1 poche de 8 m de plafond et 1 rez-de-chaussée d'auberge dans tout le monde. 4 des 5 entrées de grotte déclarées ne mènent nulle part. Un jeu de 30-50 h vit largement sous terre et à l'intérieur ; ici c'est environ 0 % du volume jouable.
- … et 5 autres, dans le rapport brut

**Dette technique :**

- ISS-052 (S2, OUVERT, docs/KNOWN_ISSUES.md) — l'assertion d'appui des lieux compare height_at(x,z) à lui-même : l'écart vaut 0 par construction, le contrôle NE PEUT PAS échouer. Anti-motif nommé par PROMPT4 §2. Porte au moins sur waterfall_cave_place.gd et stone_bridge_place.gd, tous deux « golden masters validés ». La preuve d'ancrage au sol des lieux est donc à refaire.
- Le monde V1 est orphelin mais vivant : environ 800 Ko de GDScript sous scripts/world/ (valley_terrain.gd, valley_relics.gd, valley_wonders.gd, valley_territories.gd, valley_ruins.gd, valley_undergrounds.gd, valley_caves.gd, hamlets.gd, valley_landmarks.gd) qui construisent 33 identifiants valley.poi.* et sont encore couverts par des dizaines de tests d'intégration, alors que le menu n'y mène plus. Double coût de maintenance, et risque permanent de citer une preuve V1 pour un fait V2.
- Deux chemins de scène pointent encore vers le monde V1 depuis des états atteignables : scripts/ui/victory_screen.gd::VALLEY_SCENE et la porte de sortie de scripts/world/citadel_vestibule.gd (exit_door.target_scene). Si le donjon devenait accessible depuis V2, le retour et la victoire renverraient le joueur dans l'autre monde.
- 19 des 31 POI et 2 des 3 sites systémiques du layout n'existent que comme Node3D nu portant un DiagnosticPillar invisible (world_v2_markers_builder.gd::_grounded_node). Le layout, docs/POI_MAP.md et DiscoveryRewards.PLAN (31 entrées) décrivent tous un monde bien plus peuplé que celui qui se monte.
- Les 4 raccourcis (routes.shortcuts) et les 10 ancrages de région sont de la donnée sans effet : des Node porteurs de métadonnées, jamais une géométrie ni un service.

**Preuve d'acceptation future.** Par paliers. PALIER 1 — la boucle se ferme (condition d'entrée, non négociable) : un test de type tests/playthrough/ part du menu, monte World V2, PILOTE le joueur du spawn au seuil du donjon, FRANCHIT la porte et atteint le vestibule, puis revient dans World V2 — jamais dans ValleyWorld.tscn. Modèle existant à étendre : tests/world_v2/test_world_v2_traversal.gd::test_le_trajet_principal_se_marche_du_spawn_a_la_porte, qui s'arrête aujourd'hui à 8 m du seuil. PALIER 2 — la région 1 est complète et peuplée : (a) WorldV2PlacesBuilder.REGISTRY compte 34 entrées (31 POI + 3 sites systémiques) et un test rougit en NOMMANT tout identifiant du layout resté marqueur — l'inverse du silence actuel ; (b) le conteneur Encounters porte un nombre non nul d'acteurs, le contrat test_aucun_acteur_et_les_routes_restent_libres étant remplacé par un contrat de BUDGET (au plus 14 IA pleinement actives, §12.9) et non de vide ; (c) une sonde de densité, exécutée sur le monde monté, publie l'histogramme des distances entre POI voisins et échoue si un segment de route dépasse une distance sans point d'intérêt visible, le seuil étant fixé AVANT la mesure et versionné. PALIER 3 — le monde sait se répéter : (a) une deuxième région existe, décrite par le MÊME format que world_v2_layout.json, montée par le même bâtisseur, sans constante d'emprise codée en dur dans WorldV2Heightmap ; (b) une transition région<->région est marchée par un test, dans les deux sens, avec sauvegarde et reprise au milieu ; (c) un test de charge mesure le pic mémoire et le temps de montage à N régions et échoue sur régression — la fuite ISS-059 a montré que ce filet est indispensable. PALIER 4 — la durée est mesurée, pas déclarée : un parcours automatisé publie, pour chaque région, surface jouable en m2, dénivelé cumulé, nombre de lieux construits, distance totale des routes, nombre de rencontres, nombre de checkpoints ; ces chiffres vivent dans evidence/ daté et rattaché au commit, jamais dans la prose. Aucune heure de campagne ne peut être annoncée sans un parcours humain enregistré selon docs/MANUAL_VALIDATION.md — et ISS-072 (horloge moteur décrochée d'un facteur 17 à 76 en build exportée) doit être fermé AVANT, sans quoi toute mesure de temps est invalide. GARDE-FOU TRANSVERSE : ISS-052 corrigé et son correctif prouvé par un contrôle négatif ; tant qu'une assertion compare height_at à lui-même, « les lieux reposent sur le sol » n'est pas une preuve.

### Pouvoirs d'orage et de résonance (mécanique signature) — Bracelet de Résonance, ReactionSystem, graphe électrique

**Importance pour 30-50 h : BLOQUANT**

Le domaine a un moteur solide et un contenu de démonstration. Les cinq opérations de PROMPT2 §3 existent réellement dans scripts/reaction/resonance_controller.gd (Pulse, Arc Link, Polarité, Arc Step, Ground), plus le Focus, les trois Fragments et un HUD ; le noyau systémique de §4 existe aussi (ReactionSystem à budget borné, 8 profils de matériau sur les 8 exigés, 6 états d'instance, ElementPacket à chaîne anti-boucle). J'ai lu les tests : 46 fonctions réparties sur 13 fichiers, avec de vraies assertions sur du comportement — pas des tests qui ne peuvent pas échouer — et docs/TEST_REPORT.md atteste leur exécution (« Résonance totale : 32/32 »). Ce cœur mérite d'être appelé fonctionnel. Mais l'écart entre ce moteur et l'ambition est brutal : j'ai compté SEPT sites utilisant le Bracelet dans toute la Vallée de Néris (3 caisses de camp, 1 tablier de pont, 2 ports de bassin, 1 cœur d'autel), et ZÉRO dans les quatre salles du donjon, ZÉRO dans le combat de boss, ZÉRO dans le combat et sur les ennemis — grep sur scripts/dungeon/, scripts/boss/, scripts/combat/, scripts/enemies/ ne renvoie rien. Le donjon électrique et le Gardien de l'Orage ont été construits avant le Bracelet et n'ont jamais été migrés : les pylônes du boss se lèvent avec un levier. Un joueur peut donc finir la campagne actuelle sans employer la mécanique signature. S'y ajoutent l'absence totale de progression d'acquisition (les cinq pouvoirs sont donnés à la première frame), l'absence de tuning en données (≈20 constantes en dur, ResonanceActionDefinition jamais écrite), l'absence de VFX 3D, et un orage purement décoratif qui n'émet aucun paquet.

| Classement | Nombre |
|---|---:|
| fonctionnel | 15 |
| prototypé | 2 |
| **absent** | 6 |

**Absent :**

- Intégration du Bracelet aux quatre salles du donjon (PROMPT2 §9.4 Ground, §9.5 Polarité, §9.6 combinaison)
- Intégration du Bracelet au Gardien de l'Orage (PROMPT2 §10.2 : Arc Link puis Ground pour ouvrir le noyau)
- Intégration des lois matière au combat (arme chargée, métal en surcharge, conductivité)
- Ennemis soumis aux mêmes lois (PROMPT2 §4.2 : « le héros, les ennemis, armes, props et mécanismes utilisent les mêmes concepts »)
- Tuning data-driven des opérations (ResonanceActionDefinition, PROMPT2 §3.1)
- Progression d'apprentissage des cinq opérations (PROMPT2 §3.7)

**Manques nommés pour 30-50 h (14) :**

- Intégration au donjon : les 4 salles portent zéro ResonanceTargetComponent. PROMPT2 §9.4 veut Ground appris en Salle 2, §9.5 la Polarité pour orienter les relais, §9.6 la combinaison batterie/eau. Chiffre minimal : environ 12 cibles (2 à 4 par salle), plus une route alternative systémique par salle (§9.1 exige solution principale + alternative + raccourci de maîtrise).
- Intégration au boss : zéro. PROMPT2 §10.2 fait de Arc Link puis Ground la réponse principale d'ouverture du noyau en Phase 1, §10.3 met la Polarité sur un élément d'arène et l'Arc Step comme sortie. Chiffre minimal : 4 pylônes ciblables au Bracelet au lieu du levier, 2 cristaux d'épaule atteignables, 1 élément d'arène polarisable.
- Intégration au combat : la hitbox (scripts/components/hitbox_component.gd) n'émet aucun ElementPacket. Il manque la chaîne arme vers paquet vers ReactionSystem qui rendrait vraie la conductivité déjà affichée dans le HUD, le risque du métal en surcharge (MASTER_SPEC §16.4) et la flèche conductrice.
- Ennemis soumis aux lois : aucun EnemyBase ne porte de MaterialStateComponent. Sans cela, mouiller un ennemi puis le charger — l'exemple canonique de §2.3 — est impossible, et cinq familles d'ennemis restent hors du système.
- L'orage comme système : StormCell n'émet rien. Pour que l'identité annoncée existe, il faut au minimum que la foudre charge les conducteurs, mouille les surfaces et crée des fenêtres tactiques ; sinon « orage » n'est qu'un mot sur une skybox.
- Progression d'acquisition : zéro verrou. Il faut les cinq jalons de §3.7 (Pulse à l'ouverture, Arc Link au pylône, Polarité en extérieur sûr, Arc Step à l'entrée du donjon, Ground en seconde moitié), leur persistance dans la sauvegarde, et leur affichage. Sans cela une campagne longue n'a aucune courbe.
- ResonanceActionDefinition : 5 ressources à écrire (une par opération) pour sortir environ 20 constantes de resonance_controller.gd. PROMPT2 §3.1 l'exige nommément.
- Densité de sites : 7 aujourd'hui en vallée. Pour une seule région tenant 8 à 12 h, l'ordre de grandeur raisonnable est 40 à 60 cibles/sites de Résonance réparties sur les trois routes ; pour 30-50 h et 3 à 4 régions, plusieurs centaines. C'est le manque le plus lourd et le plus lent à combler.
- … et 6 autres, dans le rapport brut

**Dette technique :**

- Tuning entièrement en dur : environ 20 constantes de gameplay (PULSE_RADIUS, LINK_MAX_SPAN, POLARITY_MASS_MAX, ARC_STEP_COST, GROUND_STARTUP, FLUX_REFUND...) sont des const dans scripts/reaction/resonance_controller.gd. PROMPT2 §3.1 exige une ResonanceActionDefinition par opération ; la classe n'existe nulle part (seule mention : un commentaire du fichier lui-même, « à migrer en Resource de tuning »). Conséquence : aucun équilibrage sans recompilation, et aucun lab ne peut rien éditer en jeu.
- Le contrôleur est un fichier unique de 23 Ko portant les cinq opérations, le focus, les fragments, l'oreille du bruit et le pilotage physique. C'est le seuil de la règle de trois de PROMPT4 §8 : _drive_polarity, _drive_ground et la validation de trajet d'Arc Step sont trois responsabilités séparables qu'aucun test ne peut importer isolément.
- Présentation 3D absente : PT-BRACELET-01 (docs/KNOWN_ISSUES.md) a été résolu par un viseur 2D et des lignes de verdict en français. Aucun VFX 3D d'arc, de front de propagation, de charge ou de mise à la terre. Le seul retour dans le monde est scripts/electricity/electric_visual.gd, qui teinte l'albédo d'un StandardMaterial3D — pas le cœur blanc / halo cyan exigé par VISUAL_ASSET_BIBLE §20.3.
- Placeholders sur le chemin systémique : la caisse métallique des camps (valley_territories.gd _metal_crate) est un BoxShape3D + BoxMesh + StandardMaterial3D gris. C'est l'unique cible de Polarité en contexte de combat, et c'est une boîte grise.
- ElementPacket.attenuated() partage volontairement le tableau chain par référence. C'est documenté et voulu, mais c'est un état mutable partagé entre paquets : un appelant qui réutilise un paquet source après attenuated() verra sa chaîne polluée. Aucun test ne couvre ce cas.

**Preuve d'acceptation future.** Le domaine sera acceptable pour une campagne de 30-50 h quand TOUTES les affirmations suivantes seront vraies et mesurables, chacune par un test nommé ou une preuve datée dans evidence/. 1. COUVERTURE MESURÉE, PAS ESTIMÉE : un test d'inventaire parcourt le monde chargé, compte les membres du groupe resonance_targets par kind et par région, et ÉCHOUE sous un plancher inscrit dans le test — plancher proposé pour la première région : au moins 40 cibles, dont au moins 8 arc_anchor, 8 port, 8 polarity, 8 material. Aujourd'hui ce test rougirait à 7. 2. LE DONJON EMPLOIE LA SIGNATURE : chacune des 4 salles porte au moins une cible de Résonance, et un test par salle prouve qu'il existe DEUX chemins de résolution (principal et alternative systémique) conformément à §9.1 ; critère de rougissement : retirer le ResonanceController du joueur doit faire échouer le test de la salle 2 (Ground) et de la salle 3 (Polarité). 3. LE BOSS EMPLOIE LA SIGNATURE : un test de scénario prouve qu'une fenêtre de noyau s'ouvre par Arc Link puis Ground sur deux pylônes, sans passer par ElectricSwitch ; et, symétriquement, un test de solvabilité prouve que le boss reste battable sans Fragment (§2.4). 4. LES LOIS SONT LES MÊMES PARTOUT : un test unique soumet le MÊME ElementPacket électrique à un prop, à un ennemi et au héros, et vérifie que les trois répondent par le même ReactionSystem — aujourd'hui il est impossible à écrire, ni l'ennemi ni le héros ne portant de MaterialStateComponent. 5. LA CONDUCTIVITÉ AFFICHÉE EST VRAIE : un test prouve qu'une arme de conductivité 1,0 et une arme de conductivité 0,05 produisent des résultats DIFFÉRENTS contre une cible chargée ; tant qu'il n'existe pas, la barre « Conductivité » du HUD doit être retirée, car afficher un chiffre inerte est pire que ne rien afficher. 6. LA PROGRESSION EXISTE ET SURVIT : un test de golden path vérifie l'ordre d'acquisition de §3.7 (les cinq opérations refusées avant leur jalon, disponibles après) et un test de sauvegarde vérifie que l'état d'acquisition et les fragments survivent à un cycle sauvegarde/chargement EN DONJON, pas seulement en vallée. 7. LE TUNING EST DONNÉE : resonance_controller.gd ne contient plus aucune constante de gameplay, 5 ressources ResonanceActionDefinition existent sous resources/tuning/, et un test vérifie que modifier la ressource change le comportement. 8. LES DEUX GATES DE PROMPT2 SONT EXÉCUTÉS ET DATÉS : Gate Bracelet §3.9 (dix répétitions par opération, cas normal/limite/annulation/cible détruite/pause/save-load, à 30, 60 et 120 FPS) et Gate ReactionSystem §4.6 (matrice profils x états x paquets, plus charge à 20/50/100 objets réactifs, avec le budget PACKETS_PER_TICK mesuré et non supposé) ; preuve dans evidence/, reliée à un commit, arbre propre. 9. L'ORAGE A UNE CONSÉQUENCE : un test prouve qu'une frappe de StormCell charge un conducteur ou mouille une surface ; tant qu'il échoue, le mot « orage » ne doit pas être présenté comme une identité de gameplay dans aucun document ni aucune livraison. 10. REVUE CONTRADICTOIRE : un agent adversarial-qa à contexte frais tente de terminer la campagne SANS jamais employer une opération du Bracelet — s'il y parvient, le gate est FAIL. C'est le seul critère qui teste réellement la phrase « mécanique signature ».

### Progression, équipement et builds

**Importance pour 30-50 h : BLOQUANT**

Le domaine est solide sur la MÉCANIQUE d'équipement et quasi vide sur la PROGRESSION. Ce qui existe — séparation définition immuable / instance mutable, durabilité de mêlée, inventaire 8 armes, persistance de la durabilité et de l'arme équipée, coffre atomique — est bien construit, testé et mesuré : environ 930 lignes au total pour tout le domaine, ce qui est le bon ordre de grandeur pour une verticale de 40 minutes. Mais il n'existe AUCUN axe de progression : les PV et l'endurance maximale sont des constantes que rien n'augmente (aucune occurrence de `max_health +=` dans `scripts/`) ; les cinq opérations du Bracelet sont toutes disponibles à t=0, sans le moindre verrou d'acquisition (aucun `has_ability` / `is_unlocked` dans `scripts/`) — la progression d'apprentissage en cinq étapes de PROMPT2 §3.7 n'est pas implémentée ; les six armes du départ sont les six armes de la fin, redistribuées onze fois sur trente et un lieux depuis un dictionnaire codé en dur, sans table de butin (`LootTableDefinition` de MASTER_SPEC §5.9 n'existe nulle part). La seule acquisition durable du jeu est constituée de TROIS Fragments de Résonance facultatifs. Le champ `rarity` et le champ `attack_speed` de `WeaponDefinition` sont renseignés dans les six `.tres` et lus par zéro script : la donnée de progression a été prévue puis abandonnée. La durabilité de l'arc (28 tirs) est déclarée et jamais consommée — `apply_hit_wear()` n'a qu'un seul appelant, dans le chemin de contact de mêlée. Enfin, les six « identités d'armes » partagent les mêmes trois attaques légères (`resources/combat/sword/light_1..3.tres` référencées par les cinq armes de mêlée) : seule la lourde diffère. Autrement dit, la V2 n'a pas une progression faible : elle n'en a pas.

| Classement | Nombre |
|---|---:|
| fonctionnel | 10 |
| prototypé | 3 |
| **absent** | 9 |

**Absent :**

- Durabilité de l'arc (28 tirs, §11.1)
- Table de butin pondérée / LootTableDefinition (MASTER_SPEC §5.9, §11.4 « loot pondéré reproductible »)
- Propriété forte lisible par variante d'arme (PROMPT2 §7.6 : isolante, brise-armure, légère, stockage de charge…)
- Action de dernier éclat à l'état Worn (PROMPT2 §7.6)
- Station d'entretien / réparation partielle (PROMPT2 §7.6)
- Progression d'apprentissage du Bracelet en cinq étapes (PROMPT2 §3.7 : Pulse à l'ouverture, Arc Link au pylône, Polarité en extérieur, Arc Step à l'entrée du donjon, Ground en deuxième moitié)
- Croissance de statistiques du héros (PV max, endurance max, conteneurs)
- Économie / monnaie / marchand / crafting hors cuisine
- Armure / slots d'équipement / EquipmentComponent (MASTER_SPEC §5.8)

**Manques nommés pour 30-50 h (11) :**

- Un registre d'acquisition de capacités, persistant et consultable par le monde. Aucun `has_ability` / `is_unlocked` / `ability_gate` n'existe dans `scripts/`. Sans lui, la règle R6 de la doctrine (« une capacité nouvelle doit rouvrir l'ancien monde ») n'a aucun support et les 80-120 h de complétion sont une intention sans mécanisme.
- La progression d'apprentissage du Bracelet en cinq étapes de PROMPT2 §3.7. Les cinq opérations (Pulse, Arc Link, Polarité, Arc Step, Ground) sont disponibles dès la première frame. C'est cinq moments d'acquisition perdus, et cinq classes de verrous de monde impossibles à poser.
- Un axe d'équipement au-delà de six armes fixes. Six définitions, redistribuées onze fois sur trente et un lieux (2 lame conductrice, 3 hache, 2 arc, 2 gourdin, 1 lance, 1 épée). Pour 30-50 h il faut, au minimum chiffré : quatre à cinq paliers de puissance, trois à quatre variantes à propriété forte par famille (PROMPT2 §7.6 : isolante, brise-armure, légère, stockage de charge), soit de l'ordre de 25 à 40 définitions ou instances distinctes contre 6 aujourd'hui.
- Une table de butin (`LootTableDefinition` de MASTER_SPEC §5.9). Zéro occurrence dans le dépôt. Le butin est une constante `PLAN` de 31 lignes dans `scripts/world/discovery_rewards.gd` : non réutilisable, non pondérée, non validable, et à réécrire intégralement à chaque région.
- La différenciation réelle des six familles d'armes. Les cinq armes de mêlée partagent les mêmes trois attaques légères. PROMPT2 §7.5 exige 4 à 6 actions vraiment utiles PAR famille : il en manque donc de l'ordre de 15 à 25 `AttackDefinition` légères, plus les animations correspondantes.
- La condition d'obtention des récompenses de type PUZZLE et COMBAT. `DiscoveryRewards.deferred_gates()` le nomme lui-même : le coffre existe, le verrou non. Un territoire ennemi rend donc son coffre sans être nettoyé — la préparation et la maîtrise (deux des quatre temps de la boucle) ne sont récompensées par rien.
- La durabilité de l'arc (28 tirs). Donnée présente, épinglée par un test, jamais consommée. L'arc est aujourd'hui une arme infinie, ce qui neutralise l'économie de flèches et retire un levier de préparation entier.
- Le cinquième buff de MASTER_SPEC §13.5, la vitalité temporaire. `EFFECT_NAMES` de `scripts/cooking/recipe_rules.gd` n'en déclare que quatre. La cuisine est le principal levier de « préparer » de la boucle ; elle offre quatre choix.
- … et 3 autres, dans le rapport brut

**Dette technique :**

- Champs morts dans le contrat de données central : `WeaponDefinition.rarity` et `WeaponDefinition.attack_speed` sont renseignés dans les six `.tres` et lus par zéro script (grep `.rarity` et `attack_speed` sur `scripts/` : 0 occurrence chacun). Ce sont exactement les deux champs qui porteraient une progression d'équipement — la donnée a été prévue puis jamais branchée, ce qui donne l'illusion d'un système de raretés inexistant.
- `WeaponDefinition.display_name_key` est mort lui aussi (0 lecture) : la table de localisation promise par MASTER_SPEC §2 n'existe pas, et les noms français sont figés en dur dans les `.tres`. Une campagne de 30-50 h multiplie ce coût par chaque nom ajouté.
- `simple_bow.max_durability = 28` est une donnée épinglée par un test (`test_the_six_definitions_match_the_spec_table`) et jamais consommée en jeu : le test est donc VERT sur une valeur sans effet. C'est précisément le mode de panne décrit par PROMPT4 §2 (« le test qui ne peut pas échouer ») appliqué à une donnée d'équilibrage.
- Les cinq armes de mêlée partagent physiquement `resources/combat/sword/light_1..3.tres`. Toute retouche de la chaîne légère d'une famille modifiera les cinq. C'est un couplage de données qui rendra impossible, sans refonte, la différenciation exigée par PROMPT2 §7.5.
- Le butin du monde est une constante `PLAN` de 31 lignes dans `scripts/world/discovery_rewards.gd`. Ajouter une région = éditer un dictionnaire de code. Aucun schéma, aucune validation de cohérence de courbe, aucune pondération, aucune table réutilisable. À l'échelle de plusieurs régions ce fichier devient ingérable.

**Preuve d'acceptation future.** Le domaine sera acceptable quand ces cinq affirmations seront chacune adossées à un test nommé qui ROUGIT sans le correctif (PROMPT4 §2). (1) Verrou d'acquisition : un test charge le monde avec un registre vide et prouve qu'au moins une route et une récompense sont INACCESSIBLES, puis qu'elles s'ouvrent après octroi de la capacité — et que la sauvegarde restitue le registre à l'identique. (2) Courbe d'équipement mesurée : un test parcourt la table de butin de bout en bout et vérifie que la puissance utile attendue (dégâts × durabilité) est monotone non décroissante par palier de progression, et qu'aucun lieu tardif ne rend une arme strictement dominée par une arme du premier palier — le gourdin à 8 dégâts au camp des Pillards rougirait aujourd'hui. (3) Différenciation réelle : un test vérifie que les six familles ne partagent aucune `AttackDefinition` légère (le test échouerait aujourd'hui, les cinq armes de mêlée pointant sur `resources/combat/sword/light_1..3.tres`). (4) Densité de décisions : un test compte les acquisitions permanentes atteignables et exige un plancher chiffré arrêté par le propriétaire — au minimum une décision d'équipement ou de capacité par heure de campagne visée. (5) Aucun champ mort : un test vérifie que tout champ exporté de `WeaponDefinition` est lu par au moins un script du chemin runtime (`rarity`, `attack_speed` et `display_name_key` rougiraient aujourd'hui, à zéro lecture chacun). À quoi s'ajoute une condition non automatisable, qui doit rester `EN ATTENTE` et jamais `PASS` : un joueur humain, après une session, doit pouvoir nommer sans aide ce qu'il a gagné et ce que cela lui a ouvert.

### Quêtes, narration et personnages

**Importance pour 30-50 h : BLOQUANT**

Le domaine est quasi vide, et il faut le dire sans atténuation : il n'existe dans ce dépôt aucun système de quêtes, aucun PNJ, aucun dialogue, aucune cinématique et aucune localisation. La recherche de « quest/quête » ne renvoie que des « question » et des « request » ; la recherche de « dialogue/npc/pnj » sur scripts/, resources/, scenes/, tests/ et tools/ ne touche qu'un seul fichier, et c'est un commentaire d'interface. Ce qui existe se compte sur une main : un StoryFragment (une stèle qui pousse un texte court dans le bus d'événements), un DiscoveryLog qui enregistre les toponymes visités, un terrain d'entraînement qui enseigne le Bracelet par panneaux, un traqueur d'indices d'énigme, et une fresque muette dans l'antichambre. Ces pièces sont bien faites, testées et honnêtes sur leurs limites — mais elles totalisent environ dix phrases de fiction pour tout le jeu, et la narration est délivrée dans un toast de trois secondes qu'aucun écran ne permet de relire. Le monde nomme quatre lieux habités — village, hameau, poste minier, caravane — que personne n'habite. La contradiction est frontale avec l'ambition : docs/V2_PRODUCT_DOCTRINE.md §1 place « une narration qui tient la distance » en quatrième nécessité pour 30 h, « sans quoi 30 h est une corvée », et docs/ROADMAP.md ne mentionne ni quête, ni PNJ, ni narration. Le domaine n'est donc pas en retard sur son plan : il n'en a aucun.

| Classement | Nombre |
|---|---:|
| fonctionnel | 4 |
| présent | 1 |
| prototypé | 1 |
| **absent** | 8 |

**Absent :**

- Système de quêtes (objectif, prérequis, étapes, suivi, récompense conditionnelle)
- PNJ — personnage non hostile avec qui interagir
- Système de dialogue (interlocuteur, répliques, branches, choix)
- Interface de consultation d'un texte déjà lu (journal, codex, carnet)
- Cinématiques et moments scénarisés
- Localisation / externalisation des textes
- Identité du protagoniste et des personnages nommés
- Verrouillage conditionnel d'une récompense (brique de base d'une quête)

**Manques nommés pour 30-50 h (12) :**

- Un système de quêtes complet : ressource QuestDefinition (identifiant stable §19.3, étapes, prérequis, état, récompense), machine d'état par quête, persistance dans la sauvegarde (migration de SCHEMA_VERSION 4 → 5), et un suivi d'objectif dans le HUD. Actuellement : 0 ligne. Pour 30-50 h, l'ordre de grandeur est de 60 à 120 objectifs suivis, dont une dizaine de chaînes principales.
- Des PNJ : 0 aujourd'hui. Une région de 30 h en exige au minimum 15 à 30 (donneurs de quête, marchands, informateurs, compagnons de route), et le dépôt nomme déjà 4 lieux censés être peuplés — riverside_village, logging_hamlet, mining_post, storm_caravan — qui sont vides. Coût unitaire d'un PNJ à mesurer AVANT toute promesse de région supplémentaire (doctrine R2).
- Un système de dialogue : 0 aujourd'hui. Il faut au minimum un modèle de données (interlocuteur, répliques, conditions, choix, conséquences), un écran de dialogue (aucun des 3 écrans existants ne convient), et une persistance des drapeaux de conversation.
- Du volume narratif écrit : environ 10 phrases existent (5 fragments × ~2 phrases), soit à peu près une minute de lecture. Une campagne de 30-50 h avec une narration « qui tient la distance » se situe entre 30 000 et 80 000 mots. L'écart est de trois ordres de grandeur.
- Une localisation, AVANT d'écrire ce volume : aucun .csv de traduction, aucun tr(), aucune section locale dans project.godot. Externaliser 50 000 mots après coup coûte plusieurs fois le prix de l'externaliser avant le premier.
- Une interface de consultation : journal de quêtes, carnet de découvertes lisible, et un « où j'en étais » — que la doctrine R5 exige explicitement « compréhensible en dix secondes » pour des sessions d'une soirée. Rien de tel n'existe : les 3 écrans sont GameplayShell, MainMenu, VictoryScreen.
- Un canal de texte narratif séparé du canal logistique. Aujourd'hui un fragment d'histoire et « Récolté : champignon » passent par le même EventBus.notify() vers la même file de 4 toasts à 3 secondes de vie. Le texte narratif doit être persistant et relisable, pas éphémère et interchangeable avec un message d'inventaire.
- Le verrouillage conditionnel : DiscoveryRewards.deferred_gates() reconnaît que les natures PUZZLE et COMBAT n'ont « pas encore de condition d'ouverture ». Sans « fais X pour obtenir Y », aucune quête n'est représentable, même minimale.
- … et 4 autres, dans le rapport brut

**Dette technique :**

- Le texte narratif est livré dans un toast éphémère : StoryFragment.interact() appelle EventBus.notify(), et scripts/ui/gameplay_shell.gd fixe NOTIFICATION_LIFETIME = 3.0 s avec MAX_NOTIFICATIONS = 4. Un fragment de deux phrases s'affiche trois secondes dans un coin, puis disparaît DÉFINITIVEMENT — aucun écran ne permet de le relire. Le même canal transporte « Récolté : … » et « Réserve de plats pleine » : la narration et la logistique d'inventaire partagent la même file et se chassent l'une l'autre.
- Le contenu écrit est codé en dur dans une table de code, pas en ressources : les 5 fragments vivent dans la constante DiscoveryRewards.PLAN (scripts/world/discovery_rewards.gd), mêlés aux récompenses matérielles (weapon/arrows/ingredient). Ajouter du texte oblige à modifier du GDScript, et aucun rédacteur ne peut travailler sans toucher au code. Contradiction directe avec MASTER_SPEC §2 (« stocker les noms affichés dans des ressources/localisations »).
- Aucune externalisation des chaînes : les display_name des .tres et tous les textes d'interface sont du français brut en dur. Aucun appel tr() dans scripts/. La dette croît linéairement avec chaque mot écrit.
- Le monde nomme des lieux HABITÉS que personne n'habite : valley.poi.riverside_village.01, logging_hamlet, mining_post, storm_caravan. L'en-tête de scripts/world_v2/poi/riverside_village_place.gd se décrit lui-même comme « le lieu habité de la route de la rivière » — et ne pose que de l'architecture. Un village vide n'est pas un décor neutre : il crée une attente narrative qu'il déçoit.
- DiscoveryRewards.deferred_gates() nomme honnêtement un manque déjà connu : les natures PUZZLE et COMBAT « décrivent l'INTENTION du lieu, pas encore une condition d'ouverture ». Il n'existe donc aucun mécanisme de verrouillage conditionnel — la brique de base de toute quête (« fais X pour obtenir Y »).

**Preuve d'acceptation future.** Le domaine ne pourra être accepté que sur des mesures, pas sur des intentions. Doivent être VRAIS et MESURABLES : (1) une ressource QuestDefinition typée existe, avec identifiants §19.3 uniques vérifiés par le validateur d'IDs existant, et un test nommé qui échoue si deux quêtes partagent un identifiant ; (2) un aller-retour complet est prouvé par un test d'intégration du type « accepter une quête → progresser d'une étape → sauvegarder → recharger → la quête est au même point, ni rejouable ni perdue », sur le modèle exact de test_the_place_stays_discovered_across_a_save_and_reload (tests/integration/test_point_of_interest.gd) qui prouve déjà ce contrat pour les découvertes ; (3) la migration SCHEMA_VERSION 4 → 5 est testée sur une sauvegarde v4 réelle, sans perte ni crash ; (4) au moins un PNJ est instancié dans un lieu du monde et un test vérifie qu'un dialogue s'ouvre, se parcourt, se ferme, et rend le contrôle au joueur sans état bloqué — la règle anti-softlock de §15.11 s'applique au dialogue comme au reste ; (5) le texte narratif est relisable après coup : un test vérifie qu'un fragment lu apparaît dans un écran de consultation, ce qui est aujourd'hui impossible (toast de 3 s) ; (6) toutes les chaînes affichées passent par tr() et un fichier de traduction, vérifié par un test qui échoue sur toute chaîne littérale affichée hors localisation ; (7) le COÛT UNITAIRE est publié, comme l'exige la doctrine R2 : temps mesuré pour produire un PNJ complet et une quête complète, sans quoi aucune région supplémentaire ne peut être promise ; (8) un playtest documenté dans docs/PLAYTESTS.md où un testeur qui n'a pas construit le jeu énonce, sans qu'on le lui souffle, quel est son objectif courant et pourquoi — c'est le seul critère qui distingue une narration d'une liste de tâches.

---

## Domaines en attente de rapport

Exploration multi-régions · donjons et énigmes · économie et cuisine ·
récompenses et secrets · rejouabilité · sauvegarde · difficulté · IA ·
interface et accessibilité · performances et export · pipeline de contenu ·
télémétrie et qualité.

Ils seront ajoutés ici avec leurs réfutations. Tant qu'ils manquent, ce
document est `PARTIAL`, et aucune conclusion d'ensemble n'en est tirée au-delà
de ce que le socle chiffré établit seul.
