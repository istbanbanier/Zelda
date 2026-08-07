# KNOWN ISSUES

Sévérités (§21.10) : `S0` corruption/perte de données · `S1` crash, softlock,
progression impossible · `S2` système majeur incorrect, caméra injouable, chute
majeure de performance · `S3` défaut visible ou contournable · `S4` polish.

Aucun `S0`/`S1` ouvert n'est admis pour un build candidat.

---

## ISS-001 — Binaires officiels Godot et Blender injoignables · `S2` · OUVERT (contourné)

- **Build** : Phase 0, environnement d'exécution conteneurisé.
- **Étapes** : `curl -I https://godotengine.org` · `curl -I https://downloads.godotengine.org`
  · `curl -I https://download.blender.org`
- **Attendu** : HTTP 200. **Observé** : `CONNECT tunnel failed, response 403` — refus
  de la politique d'egress, pas une panne réseau. `archive.ubuntu.com`, `pypi.org`,
  `registry.npmjs.org` et `github.com` (git) répondent normalement.
- **Fréquence** : systématique.
- **Contournement en place** : moteur compilé depuis le tag git (D-001), Blender
  installé depuis le dépôt Ubuntu (D-002).
- **Propriétaire** : administrateur de l'environnement — seul lui peut lever le blocage.
- **Test de régression** : `tools/env_report.sh` affiche les versions réellement
  installées à chaque session.

## ISS-002 — Aucune capacité de rendu : GPU et affichage absents · `S2` · OUVERT

- **Étapes** : `ls /dev/dri` → absent · `echo $DISPLAY` → vide.
- **Impact** : bloque les niveaux **6 et 7** de la pyramide de validation —
  profilage, frame pacing, session longue, export. Donc bloque **Gates H, I et J**,
  et interdit la notation WOW fine du Gate C.5. Le niveau 5 (capture) est, lui,
  praticable en rendu logiciel : voir le contournement mesuré ci-dessous.
- **N'affecte pas** : import, parse, tests unitaires et d'intégration headless,
  logique de jeu, données, sauvegarde, graphe électrique — soit tout le chemin
  jusqu'au Gate G (graybox jouable).
- **Contournement mesuré (R-004)** : `xvfb-run` + Mesa **llvmpipe** rend réellement
  en Forward+ et produit des PNG exploitables — vérifié sur
  `scenes/tests/PipelineLab.tscn`. La **régression visuelle** (niveau 5) est donc
  possible ici ; seuls les niveaux **6 (performance)** et **7 (soak/export)**
  restent hors de portée.
- **Reste bloqué** : notation WOW fine (les couleurs et le filtrage logiciel ne sont
  pas ceux d'un GPU), profilage, frame pacing, session 60 min, export de build.
- **Interdiction associée** : ne jamais publier une mesure de performance obtenue
  en llvmpipe comme budget de frame (§20.1).
- **Propriétaire** : administrateur de l'environnement.

## ISS-003 — Image de référence North Star absente du dépôt · `S3` · OUVERT

- **Contexte** : l'image de référence a été fournie dans la conversation, pas comme
  fichier sur disque. Son analyse a été faite et consignée dans `docs/ART_BIBLE.md`
  (relations de composition mesurées contre §3.2), mais le binaire lui-même n'a pas
  pu être versionné.
- **Impact** : les comparaisons avant/après de §7.16 exigent une référence stable et
  partagée. Sans le fichier, chaque session repart de la description écrite.
- **Action requise (utilisateur)** : déposer l'image à
  `source_assets/concepts/NORTHSTAR_reference.png` et l'inscrire dans
  `ATTRIBUTIONS.md`.
- **Rappel** : cette image reste une **référence de cadrage uniquement**. Elle ne
  doit jamais devenir skybox, matte painting, billboard ou texture (§0.2).

## ISS-004 — Aucun périphérique audio dans le conteneur · `S4` · OUVERT

- **Observé** : `ERROR: Condition "status < 0" is true. Returning: ERR_CANT_OPEN`
  depuis `drivers/alsa/audio_driver_alsa.cpp:97`, puis
  `WARNING: All audio drivers failed, falling back to the dummy driver.`
- **Cause** : pas de carte son ni de serveur audio dans le conteneur.
- **Impact** : nul sur l'import, les tests et la capture. Bloque en revanche toute
  vérification réelle du mixage et des bus audio (§18).
- **Contournement** : `--audio-driver Dummy` passé explicitement par
  `tools/validate_release.sh`, ce qui supprime une erreur trompeuse dans les logs.
- **Propriétaire** : administrateur de l'environnement. À rouvrir en Phase H/I.

## CONTROLLER-001 — Test manuel manette non réalisé · `S2` · **DETTE OBLIGATOIRE**

- **Ouvert le** : 2026-08-01, par décision du propriétaire (D-012).
- **Constat** : la campagne de validation du Gate A a été menée sans manette. Les
  étapes clavier, menu et lancement sont rapportées conformes ; **l'étape manette
  n'a pas été jouée du tout**.
- **Pourquoi ce n'est pas déductible du clavier** : les liaisons manette sont des
  événements d'un autre type (`InputEventJoypadButton`, `InputEventJoypadMotion`),
  et leur correspondance dépend de la base SDL du modèle branché. Un clavier qui
  fonctionne ne dit **rien** d'une manette.
- **Ce que les tests automatiques prouvent** : que chaque action **possède** une
  liaison manette (`test_input_map.gd::test_core_actions_have_gamepad_bindings`).
- **Ce qu'ils ne prouveront JAMAIS** : qu'un bouton pressé produit l'action
  attendue sur un vrai périphérique. **Cette dette ne peut pas être levée par un
  test automatisé, quel qu'il soit.** Ajouter des tests ne la réduit pas.
- **Échéance** : **avant la release finale** (Gate J). Recommandé bien plus tôt —
  avant le **Gate C**, car le combat (§10) dépend des gâchettes, des sticks et du
  lock-on d'une façon que le clavier ne représente pas.
- **Comment la lever** : jouer §4.3 de `docs/MANUAL_GATE_A.md` avec une manette,
  archiver `03_manette_detectee.png` et `03_manette_tableau.md`, puis mettre à jour
  cette entrée **et** le verdict du Gate A.
- **Propriétaire** : propriétaire du projet (matériel requis).

## ISS-005 — Licence sortante du projet non définie · `S3` · OUVERT — décision utilisateur requise

- **Constat** : aucun fichier `LICENSE` ni `COPYING` à la racine, alors que
  `ATTRIBUTIONS.md` range les assets produits sous « licence du projet ».
  Cette licence n'existe donc nulle part.
- **Impact** : les licences **entrantes** sont saines (Godot MIT, exporter glTF
  Apache-2.0, numpy BSD-3, Blender GPL non redistribué). C'est la licence
  **sortante** qui est indéterminée : personne ne peut savoir sous quelles
  conditions le jeu et ses assets sont diffusables.
- **Action requise** : choix du propriétaire du projet (propriétaire, MIT, CC-BY
  pour les assets, etc.). Ce n'est pas une décision technique.
- **Ne bloque pas** la Phase A.

---

## Résolus

## ISS-R01 — Export glTF produisait un preset vide · `S2` · RÉSOLU 2026-07-31

- **Observé** : `tools/blender/export_gltf.py` rejetait ses 17 options et n'écrivait
  aucun `.glb` ; `gltf_inspect.py` échouait sur fichier introuvable.
- **Cause** : introspection via `inspect.signature(bpy.ops.export_scene.gltf.idname_py)`,
  qui décrit la méthode Python et non les propriétés de l'opérateur.
- **Correctif** : filtrage sur `get_rna_type().properties.keys()` (75 propriétés).
- **Régression couverte par** : `tools/blender/run_export.sh`, qui échoue si le
  `.glb` n'est pas produit **et** si la validation glTF le refuse.

## ISS-R02 — Blender Ubuntu sans numpy, exporter glTF inutilisable · `S2` · RÉSOLU 2026-07-31

- **Observé** : `ModuleNotFoundError: No module named 'numpy'` levé depuis
  `io_scene_gltf2/blender/exp/gltf2_blender_gather_tree.py`.
- **Cause** : le paquet Ubuntu de Blender utilise le Python système (3.12.3) et
  n'embarque pas numpy, dont l'exporter dépend.
- **Correctif** : `python3-numpy` (1.26.4), consigné comme dépendance obligatoire
  dans `docs/BUILD_ENVIRONMENT.md`.


---

## VALIDATION-B-001 — Essais humains du Gate B différés à la passe finale

- **Sévérité** : `S2` (même classe que CONTROLLER-001 : critères de §8.3, §21.4 et
  §23.1 non vérifiables sans humain devant un écran)
- **Statut** : **DETTE OBLIGATOIRE**, ouverte par décision propriétaire D-021
- **Contenu** : les six essais de `docs/MANUAL_VALIDATION.md`, section Gate B —
  caméra contre murs (jitter), escalade et refus, mantle sous plafond (à-coups),
  endurance nulle (seuil D-016 au ressenti), latence perçue, parcours à la main.
- **Reproduction** : `godot --path . --debug-collisions scenes/tests/TraversalPlayground.tscn`,
  protocole section Gate B, preuves dans `evidence/gateB/manual/`.
- **Règle** : ne **jamais** considérer cette dette levée par des tests
  automatiques. Elle se solde à la passe finale, avant toute déclaration `Final`.
- **Propriétaire** : opérateur humain (machine avec écran) + Product Owner.

---

## PT-D1 — retour du playtest humain n° 1 (2026-08-01) → jalon correctif D.1R

Source : `evidence/gateD/playtest01/FORMULAIRE.md` (12 constats testeur + audit
de code fourni). Décision propriétaire : C.5 suspendu jusqu'à D.1R rejouable.

| ID | Constat | Sévérité | Traité par |
|---|---|---|---|
| PT-D1-01 | caméra ÷25 (unités souris/stick mélangées) + souris non capturée + ni pause ni sensibilité | S2 | D.1R.1 |
| PT-D1-02 | joueur/pillards se traversent ; pillards superposés | S2 | D.1R.2 |
| PT-D1-03 | aucun HUD ; inventaire inaccessible ; aucune invite d'interaction ; combat illisible | S2 | D.1R.3 |
| PT-D1-04 | chute hors monde possible ; mort sans retry ; citadelle sans entrée | S2/S3 | D.1R.4 |
| PT-D1-05 | « Continuer » n'applique aucun état sauvegardé | S3 | D.1R.5 |

**Résolution D.1R (2026-08-01)** : PT-D1-01 → D.1R.1 (canaux souris/stick
séparés, capture, pause, sensibilité persistée) · PT-D1-02 → D.1R.2 (masques
5/7, séparation locale) · PT-D1-03 → D.1R.3 (HUD, invites avec LOS, inventaire
Tab, molette, feedback graybox, 4 coffres) · PT-D1-04 → D.1R.4 (montagnes
continues, secours précoce au point sûr, écran de mort, citadelle accessible
avec vestibule) · PT-D1-05 → D.1R.5 (restauration minimale : inventaire,
durabilités, arme équipée, flèches, coffres — sans second loot). Tous corrigés
avec régressions ; la CONFIRMATION humaine appartient au playtest n° 2.

**Revue contradictoire consolidée D.1R (2026-08-01,
`evidence/gateD/REVUE_D1R.md`)** : 23 critères rejoués — aucun S0/S1/S2, trois
S3 démontrés et **corrigés le jour même**, chacun avec sa régression :
QA-D1R-01 pickup non persisté → gourdin dupliqué après « Continuer » ;
QA-D1R-02 `settings.cfg` hostile (tableau → 0,0 sous le MIN ; nan traversait
`clampf`) ; QA-D1R-03 Échap/Reprendre recapturait la souris sous l'écran de
mort, Tab ouvrait l'inventaire par-dessus. QA-D1R-04 (S4) : surdéclarations de
TEST_REPORT corrigées — réticule-en-visée et plafond de notifications restent
NON ASSERTÉS, à vérifier visuellement au playtest n° 2.

## Nuit ART-Q (2026-08-02) — revue contradictoire PASS, S4 consignés

| ID | Constat | Sévérité | Propriétaire / échéance |
|---|---|---|---|
| ISS-013 | `tools/gltf_inspect.py` ne mesure la bbox que du PREMIER mesh : dimensions non fiables sur les personnages skinnés multi-meshes (Male_Ranger rapporte 0,23 m) ; la règle « min Y ≈ 0 » y est de fait un simple avertissement | S4 | outillage — améliorer avant le prochain lot de personnages |
| ISS-014 | Coutures d'alignement `WEAPON_GRIP_EULER/OFFSET` lues depuis l'environnement sur le chemin runtime de `_build_weapon_visual` (valeurs figées par défaut, documentées) | S4 | à retirer en Phase I — un build final ne lit pas de réglage visuel dans l'environnement |

## Phase G (2026-08-03)

| ID | Constat | Sévérité | Propriétaire / échéance |
|---|---|---|---|
| ISS-015 | La SURCHARGE de §16.4 peut ne jamais s'afficher : elle part sur un intervalle de 9 s en phase 2, et le run automatisé traverse la phase 2 plus vite que cela. Un joueur efficace pourrait donc ne jamais rencontrer le risque « métal pendant la surcharge », qui est pourtant l'idée tactique de la phase. Le mécanisme est correct et testé (`test_conductive_weapons_backfire_during_overload_and_wood_does_not`) ; c'est son DÉCLENCHEMENT qui est à revoir — par exemple une première surcharge garantie peu après l'entrée en phase 2. | S3 | réglage de combat — à trancher au playtest du protocole G-2 |
| ISS-016 | `test_boss_run.gd` postule le contact : il appelle `HurtboxComponent.receive_hit()` au lieu de faire balayer une vraie hitbox. Il respecte `monitorable` (donc ne frappe pas un noyau fermé) et se donne une précision de deux coups sur trois, mais il ne prouve rien sur la portée, l'angle ni le timing des attaques du joueur. | S4 | à renforcer quand `CombatLab` du Prompt 2 existera (P2-1) |
| ISS-017 | La durée d'une première victoire (§16.1 : 4-7 min) et le délai réel de retry (§16.6 : < 20 s) ne sont mesurés par aucun test — ce sont des temps humains. Le chargement de l'arène est chronométré, le reste ne l'est pas. | S4 | protocole `docs/MANUAL_VALIDATION.md`, essai G-4 |

## Phase H lot H.5 (2026-08-03) — assemblage des modèles générés

| ID | Constat | Sévérité | Propriétaire / échéance |
|---|---|---|---|
| ISS-018 | ~~**Les modèles générés se lisent en pièces détachées.**~~ **CORRIGÉ.** CAUSE RACINE trouvée : `bmesh.ops.create_cube(size=1.0)` pose ses sommets à ±0,5, donc les fabriques `add_box`/`limb` reçoivent une taille PLEINE. Un `* 0.5` traînait sur la longueur de chaque segment dans `make_creatures.py` ET `make_raiders.py`, et les mêmes facteurs `* 0.62` / `* 0.5` dans `make_storm_guardian.py` : chaque membre était bâti à la moitié de sa portée et s'arrêtait à mi-chemin de son articulation. Le « mordant » que les commentaires décrivaient n'avait donc jamais existé. Corrigé à la source, plus quelques pièces mal placées trouvées par mesure (nodule du colosse à 39 cm du dos, ceinture de troncs autour du vide, anneau du Gardien orienté radialement au lieu de tangentiellement, tiers d'anneau entièrement en l'air, bras du chasseur et des pillards sans clavicule). Les six personnages forment maintenant **un seul corps solidaire** : 43, 55, 113, 23, 29 et 27 morceaux, aucun détaché. | S2 | **clos** — vérifié par ISS-019, contrôle négatif inclus |
| ISS-019 | ~~**Aucun test automatique ne voit ce défaut.**~~ **CORRIGÉ.** `tools/blender/check_continuity.py` lit le `.glb` LIVRÉ, évalue le graphe de dépendances (donc APRÈS déformation par l'armature), ressoude les sommets séparés par l'export glTF, découpe en morceaux connexes et exige **un seul corps solidaire** — pas seulement « chaque pièce a un voisin », critère que deux bras flottants satisfaisaient. Câblé en niveau 3b de `tools/validate_fast.sh`. Contrôle négatif : une pièce déplacée de 0,60 m fait sortir le script en code 1, le modèle réparé en code 0. | S3 | **clos** |
| ISS-020 | Diagnostic initial ERRONÉ consigné pour mémoire : j'ai d'abord attribué l'éclatement au skinning (transformation de nœud ignorée par glTF). Un ré-import du `.glb` dans Blender a montré le modèle correctement assemblé après déformation — la cause était la géométrie source, pas le pipeline. Le durcissement appliqué entre-temps (`apply_transforms` avant liaison) reste juste et exigé par `.claude/rules/assets.md`, mais il ne corrigeait pas ce défaut-là. | S4 | consigné, rien à corriger |

## ISS-020 — Cinq armes sur six n'avaient pas de modèle · `S3` · CORRIGÉ le 2026-08-03, sans textures

**Constaté le** 2026-08-03, sur `evidence/rewards/abandoned_mine.png` — la
hache lourde posée au sol de la mine est une boîte olive, pas une hache.

**Reproduction.** `grep -c mesh_scene resources/weapons/*.tres` : seul
`worn_sword.tres` porte un modèle. `WeaponPickup` le dit lui-même dans son
code (« repli contrôlé sur la boîte, normal tant que la bibliothèque est
incomplète ») — le repli fonctionne, mais il est désormais VISIBLE : quatre
des 31 récompenses sont des armes au sol, dont trois sans modèle.

**Portée.** `wood_club`, `spear`, `heavy_axe`, `simple_bow`,
`conductive_blade`. Trois d'entre elles sont sur le chemin des récompenses
(hameau des bûcherons, mine abandonnée, belvédère).

**Ce que cela n'est pas.** Ni un défaut de placement — l'objet repose sur un
sol réel, s'atteint et se ramasse —, ni une régression : la bibliothèque
d'armes était déjà incomplète. Ce lot l'a seulement rendu visible.

**Correction.** Modéliser les cinq armes manquantes (Passe V5 de la bible
visuelle) ou, à défaut, une silhouette de repli par famille qui se lise mieux
qu'une boîte. Tant que ce n'est pas fait, aucune de ces récompenses ne peut
être appelée `final`.

**Correction (commit du lot armes).** `tools/blender/make_weapons.py` bâtit les
cinq modèles manquants d'après VISUAL_ASSET_BIBLE §16 — gourdin torsadé à masse
noueuse, lance à tête foliacée et insert de céramique, hache à coin
dissymétrique et contrepoids minéral, arc composite asymétrique, lame à deux
rails de cuivre séparés par une âme d'ivoire. Dimensions dans les bandes de la
bible, export glTF validé, les six armes portent un modèle distinct
(`test_every_weapon_carries_its_own_production_model`).

**Ce qui reste, et qu'il ne faut pas appeler fini :**

- **aucune texture.** Ces cinq modèles portent des matériaux PBR à facteurs
  plats. L'Épée usée, elle, a ses cartes peintes (base color, MR, normale). Un
  cran au-dessus de la boîte grise, un cran en dessous de l'épée ;
- **densité géométrique faible** : 296 à 504 triangles, contre 1k-8k pour un
  prop selon §4.5. Les silhouettes se lisent, les surfaces sont facettées ;
- **lisibilité au sol inégale.** Les armes longues sont désormais FICHÉES en
  terre plutôt que couchées — une lance de deux mètres couchée dans l'axe du
  regard n'était qu'un trait, et la hache avait carrément disparu d'une
  capture. Après correction, la hache de la mine reste fine vue dans l'axe du
  couloir. Preuve : `evidence/rewards/abandoned_mine.png`.

---

## ~~S1 — Le menu Pause enferme le joueur~~ — RETIRÉ : défaut du HARNAIS

**Ce constat était FAUX et accusait le jeu à tort.** Il est conservé ici parce
qu'une erreur de diagnostic effacée se répète.

Ce qui avait été observé, en session blackbox `session_20260804_031040` : un
panneau « Pause » qui ne se refermait ni par `Échap`, ni par `Entrée`, ni par
`Espace`, ni par un clic — sauf au centre exact du bouton « Reprendre ».

**Cause réelle, mesurée : deux défauts du harnais de test, aucun du jeu.**

1. `game_act` suspendait le processus Godot dans la même milliseconde que la
   dernière entrée. En rendu logiciel une image coûte 100 à 300 ms : la capture
   rendue au joueur était donc ANTÉRIEURE à sa propre action, et le jeu restait
   figé sur cette image. `game_click` attendait déjà 0,45 s — c'est exactement
   pourquoi seuls les clics semblaient fonctionner.
2. La table de touches envoyait les étiquettes AZERTY comme keysyms, alors que
   le jeu mappe des `physical_keycode`. Aucune commande de déplacement
   n'arrivait.

**Vérifié après correction du harnais**, dans le chemin MCP complet : `Échap`
ouvre la pause, `Échap` la referme, le monde reprend. Aucune manipulation
particulière n'est nécessaire.

**Leçon.** Un joueur qui rapporte « la commande ne répond pas » peut décrire
un défaut de l'instrument de mesure. Avant d'ouvrir un ticket contre le jeu,
vérifier que l'entrée atteint réellement le moteur ET que la capture est
postérieure à l'action.

## ~~S2 — Chargement muet~~ — CORRIGÉ (le silence, pas la lenteur)

**Observé.** Entre le clic « Nouvelle partie » et l'affichage de la vallée :
**~64 s** de noir total en session blackbox, **52 s** sur une instance isolée,
**~23 s** sur une instance antérieure. Aucune barre, aucun texte, aucun logo.

Pendant ce temps le processus travaille réellement (CPU actif, état `D`,
mémoire de 1,82 à 1,99 Go). Mais rien à l'écran ne distingue un chargement d'un
plantage : deux joueurs successifs ont commencé à chercher des logs.

**Corrigé.** `SceneFlow.go_to()` appelait `change_scene_to_file()`, synchrone :
elle bloque le thread principal, donc aucune image ne pouvait être dessinée.
Remplacé par `ResourceLoader.load_threaded_request()` (§20.10) avec écran de
chargement, progression réelle et bascule par `change_scene_to_packed()`.

Preuve : `evidence/blackbox_player/fix_ecran_chargement_20260804_103524/` —
capture « Chargement…  46 % » puis vallée jouable. Test de régression
`test_scene_flow_shows_a_loading_screen_that_survives_the_pause`.

**Reste ouvert : la LENTEUR.** Le chargement demeure de l'ordre de 25 à 60 s en
rendu logiciel llvmpipe, sans GPU. Le joueur sait désormais que le jeu travaille,
mais il attend toujours. Mesurer sur matériel représentatif avant d'optimiser.

---

# Apport du playtest externe ChatGPT n°1 — build `8649d7b` (2026-08-04)

Test indépendant, hors du harnais MCP, avec de vraies entrées clavier/souris
sur le Godot 4.7.1 officiel. Rapport et 12 captures :
`evidence/external_playtests/chatgpt_test1_8649d7b/`.

**Ce que ce test confirme d'abord : le jeu répond.** Caméra à la souris,
sensibilité, déplacement, saut, sprint, pause, inventaire, combo (12 / 12,6 /
15,6, lourde 21,6), salle 1 du donjon résolue. Les échecs répétés de nos
joueurs en boîte noire étaient donc bien des défauts du harnais, pas du jeu —
diagnostic désormais recoupé par un environnement tiers.

## S1 — Ouverture du boss injouable en lancement direct (À CONFIRMER en parcours normal)

Constat externe : lancement autonome de `BossArena`, joueur plein de vie mort
vers la **sixième seconde**. Le Gardien ferme la distance dès la fin de
l'intro et enchaîne ; une esquive au réveil ne fait que retarder de ~2 s.
Capture `10-boss-death.png` : joueur mort, boss à pleine vie, **caméra à
l'intérieur du modèle du boss**.

Lecture du code qui rend le constat plausible sans le requalifier :
`INTRO_TIME = 5.0` puis poursuite immédiate, `melee_reach = 6.0` m (énorme),
cooldown 2,2 s, aucun délai de grâce après l'intro. §16.1 exige une entrée
« passable » et une première victoire en 4-7 min ; §16.6 exige le boss visible
80 % du temps — la caméra dans le modèle viole aussi ce point.

À faire : reproduire depuis l'antichambre avec l'équipement garanti avant de
trancher la sévérité définitive ; ajouter une fenêtre de grâce post-intro ;
faire collisionner la caméra avec le corps du boss.

## S2 — L'escalade se déclenche sans intention (CONFIRMÉ dans le code)

Constat externe : courir contre un arbre, une maison ou un mur du donjon
déclenche l'escalade ; le héros reste suspendu ; la caméra traverse tronc/toit
et masque l'écran. Capture `04-auto-climb-tree.png`.

Vérifié dans le code : D-017 fait de « pousser vers une paroi » le seul
déclencheur, et `is_surface_climbable()` accepte TOUT sauf six groupes de refus
(`unclimbable`, `electrified`, `burning`, `spiked`, `fragile_unsupported`,
`water`). Ni les arbres ni les bâtiments du village ne sont dans ces groupes :
tout le décor est donc saisissable par accident.

Pistes, au choix ou combinées : marquer arbres/bâtiments `unclimbable` ;
exiger un maintien franc (durée minimale d'appui vers le mur) avant l'accroche ;
liaison caméra→fade dither (`SH_CameraFadeDither`, §21.12) sur l'obstacle.

## S2 — « Continuer » ne restaure pas la position (CONFIRMÉ dans le code)

Constat externe : `Continuer` recharge bien la partie mais replace le joueur
sur la crête de départ.

Vérifié : `_apply_save()` (`valley_world.gd`) restaure découvertes, armes,
flèches, coffres et pickups — **jamais `player_position`**, pourtant exigée
par §19.1 (« position/rotation sûre du joueur »). Le `SaveSystem` ne l'écrit
pas non plus.

## S2 — Pillard superposé au joueur sans attaquer (À CONFIRMER en vallée)

Constat externe, dans `CombatLab` : le pillard encaisse mais peut rester
chevauché avec le joueur sans porter de coup (`06-raider-overlap.png`).
À reproduire au camp réel avant conclusion — les corps ne devraient de toute
façon jamais s'interpénétrer (§12.7, collisions par couches).

## S3 — Guidage initial absent (RECOUPÉ trois fois)

Constat externe : « aucune mission, direction, marqueur ou indication de but » ;
le camp n'a pas été trouvé naturellement malgré une traversée prolongée. Nos
trois playtests internes disaient déjà la même chose. Même après correction de
la caméra du harnais, le monde lui-même n'oriente pas : pas de fumée visible de
loin, pas de son, pas de cadrage. §2.2/P2 (« curiosité plutôt que checklist »)
exige des affordances, pas des icônes — mais il en faut AU MOINS UNE.

## S3 — Lisibilité du monde (RECOUPÉ)

Mélange de bâtiments détaillés et de grands volumes bruts ; éléments du village
en intersection ; intérieurs vides. Cohérent avec Gate H non atteint — pas un
défaut nouveau, mais une confirmation externe de l'écart.

## ISS-024 — Tests d'intégration sensibles à la contention CPU (S3, ouvert)

Les suites électriques du donjon (`room4_battery`, `dungeon_hub`,
`dungeon_topology`, `dungeon_run`) échouent de manière INSTABLE quand la
machine est chargée (capture llvmpipe ou autre suite en parallèle) : circuits
à 1/3 puis 2/3, porte du boss « fermée ». Reproduit trois fois en H-2→H-5,
réfuté trois fois sur machine au repos (R-017). Cause : timings par temps réel
dans des tests par ticks. Contournement : sérialiser (règle R-017).
Correction de fond : budgets en TICKS logiques dans les tests concernés.

## ISS-025 — Salle électrique quasi noire en capture statique (S3, ouvert — Phase H/V7)

`gate_salle_electrique.png` (caméra intérieure, 60 frames) : la salle 1 rend
presque noir malgré 6 lumières et un WorldEnvironment propres (sondé). En jeu
la lisibilité vient des émissifs du circuit et du mouvement ; en capture fixe,
le § « aucun couloir noir » (§12.8/§22.2 bible) n'est pas tenu. À corriger à
la passe V7 (éclairage motivé du donjon : ambre de circulation plus présent,
exposition stable). La capture reste au dossier telle quelle — §0.2 : on ne
maquille pas une preuve.


## ISS-026 — Caméra de référence du boss enterrée (S3, ouvert)

`gate_boss.png` (v1 et v2) : la caméra AABB finit contre une masse bleu nuit —
ni arène, ni pylônes, ni Gardien. Relevé par la revue contradictoire du Gate H
(défaut équivalent à ISS-025, non consigné à l'époque — corrigé ici). Correctif :
cadrage spécifique à l'arène (surplomb du bord, rayon 19 m) au commit suivant.

## ISS-027 — Faux « ok » du runner : erreur de script après une assertion passée (S2 outillage, RÉSOLU 2026-08-05)

**Observé** le 2026-08-05 (P2-3, `test_weapon_identities`) : un test dont le
script lève une erreur d'exécution (propriété absente sur un objet typé)
APRÈS au moins une assertion passée est compté « ok (1 assertions) » — la
méthode est avortée en silence, ses assertions restantes ne courent jamais.
Le garde-fou existant (« aucune assertion exécutée = couverture illusoire »)
ne couvre que le cas zéro assertion.

**Impact** : un fail-first peut paraître rouge-puis-vert alors que le rouge
était un avortement, pas un échec d'assertion — risque de fausse preuve.
Contournement actuel : lire les `SCRIPT ERROR` du journal du runner (fait
systématiquement dans les sessions récentes).

**Correctif proposé** : le runner devrait détecter qu'une méthode de test
s'est terminée par erreur (comparer un drapeau « fin atteinte » posé par le
test ? intercepter les erreurs de script ?) et la compter ÉCHEC. À traiter
comme tranche outillage dédiée — pas en passant.

**Résolu** : le runner lit le journal de SON processus
(`user://logs/godot.log`, journalisation fichier active par défaut sur
desktop, tournée par exécution) et compte les `SCRIPT ERROR` — la
moindre rend la suite ROUGE (« une suite qui erre n'est pas une
preuve »), avec la ligne de vérité `erreurs de script dans le journal :
N` imprimée à chaque passage. Prouvé par sonde rouge/vert : un test qui
erre après une assertion passée sortait « ok, code 0 » ; il sort
désormais « ÉCHEC ISS-027, code 1 ». Zéro faux positif vérifié sur des
suites saines (hints 7/7, directeur 5/5 — 0 erreur).

## ISS-028 — Bibliothèque du directeur partiellement taguée (S4, ouvert)

Revue contradictoire P2-5 : les tags « danger, côté arène, prérequis,
réponse » et le « budget simultané » de P2 §10.5 n'existent pas dans la
bibliothèque du Gardien (3 patterns : portée/phases/cooldown/poids
seulement). « Pas de répétition excessive » repose sur le seul cooldown
quand UN pattern est légal (< 3,6 m : combo toutes les 2,2 s) — choix
testé (pas de famine) mais non borné en nombre. `_history` croît sans
limite sur un très long combat. À enrichir quand le répertoire du boss
grandira (Phase H/BossLab) ; plafonner l'historique au passage.

## ISS-029 — La parade écrit la posture du boss sans ses gardes (S3, ouvert)

`player_controller.gd` (dispatch parade→posture) écrit directement
`take_posture_damage` sur la cible, sans les gardes de `_on_body_hit`
du Gardien (armure intacte / phase de combat). `_on_posture_broken`
rattrape la rupture hors conditions (reset sans fenêtre), mais la jauge
peut être entamée pendant l'éveil ou une fenêtre ouverte. Exposition
pratique nulle aujourd'hui (le boss n'attaque pas hors phases de
combat — aucune parade possible). À durcir : router le dispatch parade
par la même porte que les coups. Relevé : revue P2-5. À surveiller
aussi au playtest G-2 : le boss est ré-écroulable en boucle par cycles
de 3 lourdes de hache (design « alternative plus lente », coût
d'endurance réel, mais non plafonné en fréquence).

## ISS-030 — Lois de matière : asymétrie vallée/donjon sur l'eau (S3, RÉSOLU 2026-08-05)

Le bassin conducteur de la VALLÉE (`conductive_basin.gd`) est un
`ElectricNode` nu : il ne mouille pas et ne relaie pas à la matière
baignée, contrairement à la nappe du donjon (P2-5 tranche 3). Le
commentaire « même loi que le bassin de la vallée » n'est vrai que pour
« traverse/ne stocke pas ». Migration matière encore partielle : bloc
métallique de salle 1 et batterie de salle 4 restent graphe-seulement.
Unifier lors du prochain passage sur la vallée (Cycle 3, chantier eau).

**Résolu** : `WaterMatterComponent` partagé (matière `eau` sur le NŒUD,
mouillage à l'entrée, relais borné sous tension, terre = suspension) —
utilisé par `ElectricHazard` WATER_ZONE ET `ConductiveBasin` (zone de
baignade ajoutée au bassin, école toujours SÛRE : zéro dégât). Prouvé
fail-first 0/6 → `test_water_unification` 3/3 (dont un VRAI Arc Link) ;
non-régression : lois 6/6, bassin 3/3, salles 44/44, réactions 7/7,
donjon 2/2. Reste graphe-seulement (assumé) : bloc salle 1, batterie
salle 4 (mécanique de charge propre).

## ISS-031 — Hints : sources d'échec inégales selon la salle (S3, RÉSOLU 2026-08-05)

Revue P2-5 : la salle 3 n'a qu'UNE source d'échec (bouton reset) — un
joueur bloqué qui ne presse jamais reset ne verra jamais de hint ; le
« Rappeler l'ascenseur » de la salle 2 est parfois une action légitime
comptée comme échec ; les branchements des salles 2-3 ne sont pas
testés end-to-end (1 et 4 le sont). Enrichir les sources par salle
(rotations sans progrès en salle 3, chute dans le puits en salle 2) et
compléter les tests. Blindage mineur relevé au passage :
`test_grounded_water_pauses_the_relay` devrait affirmer
`before < capacité` pour rester discriminant si le plafond montait.

**Résolu** : salle 3 compte les ROTATIONS SANS PROGRÈS (le geste même de
l'énigme — `turned` + comparaison du courant après recalcul, le
récepteur allumé ne compte jamais « vain ») ; salle 2 compte les CHUTES
aériennes RAPIDES (> 4,5 m à > 5 m/s de moyenne — ni l'ascenseur au
sol, ni la descente d'escalade lente ne comptent) ; les branchements des
quatre salles sont testés end-to-end (7/7) ; le test du relais mis à la
terre est blindé (`before < capacité`). Le « Rappeler l'ascenseur »
légitime compté comme échec (remarque de la revue) reste assumé : c'est
un signal faible parmi trois, pas un déclencheur seul.

---

## PT-BRACELET-01 — Le Bracelet n'avait aucune présentation en jeu (S2)

**Constaté en playtest**, pas en test : « je maintiens G et je clique gauche sur
la source puis sur le bassin et rien ne se passe ».

**Cause** : le Bracelet n'émettait aucun retour hors de `ResonanceLab`.
`ResonanceTargetComponent` déclare lui-même « ce composant ne dessine rien » ;
seul le lab branchait `revealed`/`reveal_ended`. La cible retenue par le focus,
l'étape « premier port retenu » d'un Arc Link en deux temps et la raison d'un
refus n'existaient que dans la sonde de latence — un instrument de MESURE que
seul `LabOverlay` affiche. Le joueur ne pouvait pas distinguer « rien n'est
parti » de « c'est parti et je n'ai pas vu la conséquence ».

Aggravant : `focus_end()` oublie le port A dès que `G` est relâché (P2 §3.8,
comportement voulu) — exigence INVISIBLE sans affichage.

**Résolu** : viseur de Résonance dans `GameplayShell` (anneau qui se referme sur
une cible, losange doublé sur le port retenu, viseur barré au refus, raison
écrite en français), signal typé `PlayerController.resonance_verdict`, et
branchement des signaux `pulse_fired` / `link_dissolved` / `ground_completed` /
`ground_cancelled` qui n'étaient écoutés nulle part.

**Non résolu** : la couverture du chemin JOUEUR manquait aussi côté tests —
`test_conductive_basin` appelait `try_link` directement, jamais
`focus_update` + `focus_confirm`. Un test de visée a été ajouté.

## PT-BRACELET-02 — Le kit `village/` ne contient aucune pièce de mur (S2)

**Constaté en playtest** : « beaucoup de modèles sont étranges, maisons sans
murs, bois qui flotte ».

**Cause mesurée** : `assets/environment/village/` contient 53 pièces — sols,
toits, débords, balcons, portes, escaliers, cheminées — et **zéro** `Wall_*`.
Toutes les pièces de mur (`Wall_UnevenBrick_Straight`, `Wall_Plaster_*`,
`Wall_Arch`…) vivent dans `assets/environment/dungeon/`. Un bâtiment assemblé
depuis le seul kit village ne PEUT donc pas avoir de murs. Le « bois qui
flotte » relève de la même famille : le kit est purement visuel, les collisions
et les cotes de pose sont à la charge des scripts d'assemblage.

**Résolu, et la cause réelle était plus profonde que prévu.** L'audit des
bâtiments a mesuré chaque pièce du kit au lieu de se fier à son nom, et
trouvé trois choses :

1. **Les murs ne manquaient pas.** Tous les scripts de bâtiment posent bien
   des `Wall_*` (résolus depuis `dungeon/`, où ils vivent tous). Les modules
   sont conformes : 2,00 m de large, 3,12 m de haut, mesurés au glTF.
2. **« Le bois qui flotte » était réel et localisé.**
   `Roof_Wooden_2x1_Center` mesure 2,00 × 1,21 × 1,50 m : c'est une TUILE DE
   RANGÉE, à poser en série avec ses embouts `_L`/`_R`. La forge du village
   (`riverside_village`) et la grange de la ferme (`valley_ruins`) en
   posaient UNE SEULE, à 3,12 m au-dessus d'une emprise de 4 × 6 m : 12 % de
   couverture, aucun contact avec un mur. Les deux posent désormais une
   rangée complète, au pas de 1,5 m — la profondeur réelle de la tuile.
3. **Cause racine du silence des tests.** `riverside_village`, `hamlets` et
   `valley_territories` n'attribuaient aucun nom unique aux pièces
   instanciées. Godot rebaptise alors les homonymes `@Node3D@366` : sur les
   cinq murs de la forge, un seul gardait un nom lisible. **Aucun test ne
   pouvait désigner cette géométrie**, ce qui explique qu'un toit flottant
   ait survécu à toute la suite. `ValleyRelics._spawn` se protégeait déjà de
   ce piège ; les trois autres l'ignoraient. Corrigé partout.

**Garde-fou** : `test_roofs_are_supported.gd` vérifie la RÈGLE, pas les deux
corrections — toute toiture EN L'AIR doit couvrir au moins 60 % de l'emprise
des murs qu'elle abrite. Les toitures tombées au sol en sont exemptées : la
`TourDeGuet` est une ruine dont « le cône de toiture gît dans l'herbe », et
c'est intentionnel.

**Non corrigé, assumé** : la forge est un appentis volontairement ouvert sur
deux côtés, et la grange annonce « trois murs » alors que son code n'en pose
que deux. Quelle face doit s'ouvrir est une décision de level design, pas une
correction technique — laissée au jugement de l'auteur.

## PT-LIVRAISON-01 — Monture et vol libre livrés hors du jeu (S2)

**Constaté en playtest** : « pas de monture, pas de F2, rien de tout ce que je
t'avais demandé ». Exact, et le défaut était de livraison, pas de code.

**Cause** : `Mount` et `DevFlyMode` n'étaient instanciés que par
`TrainingGrounds.tscn` — une scène qu'il faut lancer à la main en ligne de
commande. Un joueur qui démarre le jeu normalement (Boot → menu → vallée) ne
les rencontrait jamais. Les onze tests passaient parce qu'ils montaient les
deux à la main : ils prouvaient que les composants FONCTIONNENT, jamais qu'ils
sont ATTEIGNABLES. Un test vert peut coexister avec une fonctionnalité
inaccessible.

**Résolu** : `ValleyWorld` pose la monture sur la crête de départ (à portée de
vue du spawn) et branche le vol libre sur son joueur. Le menu principal gagne
une entrée « Terrain d'entraînement ». Le test
`test_the_valley_itself_carries_the_mount_and_the_fly_mode` vérifie désormais
la PRÉSENCE dans la carte réellement parcourue, pas seulement le comportement.

**Leçon à retenir pour la suite** : tout ce qui est ajouté doit avoir un test
d'ATTEIGNABILITÉ depuis le flux de jeu normal, pas seulement un test de
comportement en scène isolée.
