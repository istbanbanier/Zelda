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
