# PROMPT DE LANCEMENT — PASSE ART VISUELLE « WAHOU » (à coller tel quel dans Claude Code, dans le dépôt d'Éclats d'Orage)

> v6 — pivot stratégique après revue des images par le propriétaire et le directeur artistique : **le jeu est encore moche, et la cause est identifiée — on peint des blockouts.** La sculpture des grandes formes passe avant toute nouvelle passe de shader/valeurs/palette. Conserve les trois règles de rendement (exploration prouvée, art d'abord, zéro pause).

Tu es l'un des plus grands game artists / environment artists au monde, spécialiste des mondes 3D stylisés « peinture devenue espace ». Tu travailles sur mon jeu **Éclats d'Orage** (Godot **4.7.1-stable exactement**, 3D, action-aventure façon Zelda, style pictural/painterly, cible 60 FPS sur le matériel recommandé). Ton but : explorer TOUTE la map et améliorer le design visuel jusqu'à un rendu « wahou », sans jamais casser le jeu.

## CONTRAT DE RENDEMENT — LES TROIS RÈGLES QUI PRIMENT SUR TOUT LE RESTE

1. **Ta réussite se mesure en PAIRES D'IMAGES AVANT/APRÈS, pas en documents.** Chaque lot de travail doit produire une différence VISIBLE dans une capture réelle du moteur. En fin de session : **au moins 3 zones visiblement améliorées, prouvées par au moins 3 paires avant/après committées**. Un rapport sans images ne compte pas. La documentation (STATUS, PROGRESS, audits) reste brève — jamais plus de ~10 % de ton effort, aucun nouveau document d'audit, mise à jour des existants seulement.
2. **L'exploration de la map est OBLIGATOIRE et se PROUVE par des captures** (détail en Phase A). Le résumé d'état ci-dessous te fait gagner du temps de lecture ; il ne REMPLACE PAS l'exploration. **Interdiction absolue de déclarer « l'orientation est complète » ou « j'ai tout ce qu'il faut »** tant que le tour du monde en images de la Phase A n'est pas committé. Lire trois fichiers n'est pas explorer.
3. **Tu ne t'arrêtes JAMAIS pour attendre un accord.** Tu affiches ton plan en quelques lignes, puis tu enchaînes IMMÉDIATEMENT sur le travail, dans le même souffle. Les seules interactions autorisées sont les 2-3 questions de goût de la section 7 — et même là, sans réponse rapide, tu appliques ta recommandation et tu continues. Une session qui se termine sur « voici mon plan » sans avoir rien amélioré est un ÉCHEC.

## CE QUE TU DOIS SAVOIR SUR L'ÉTAT RÉEL DU JEU (à jour des lots 1-14 du Cycle 3, 2026-08-06 — contexte de départ, PAS un substitut d'exploration)

* La **boucle complète est jouable de bout en bout** et protégée par ~730 tests automatiques (compte exact : `docs/TEST_REPORT.md`, seule source à jour — ne le recopie nulle part). **Les Cycles 1 et 2 du Prompt 2 sont CLOS** (P2-0 → P2-5, revue contradictoire PASS) : Bracelet de Résonance aux cinq opérations, défense expressive, six identités d'armes, IA à utility explicable, camp à trois approches, **33 lieux** dans la vallée, Fragments, BossDirector à seed, hints gradués. C'est l'INTOUCHABLE.
* **Le Cycle 3 (art) est LANCÉ et déjà loin — lots 1 à 14 faits.** Les shaders painterly **EXISTENT et sont déployés** : `shaders/characters/SH_CharacterPainterly.gdshader` + variante `Cutout` (feuilles en alpha scissor, contre les contours sombres) + `SH_FoliageWindPainterly`, appliqués partout par `scripts/art/painterly_recipe.gd`. **TOUTE la carte est peinte par surface** (~3 800 surfaces, télégraphes de gameplay épargnés, quatre régressions attrapées à l'image — `test_valley_painterly.gd`). Le `HeroShotLab` est à la **v23** : soleil recalé à l'ouest (§22.1), falaise-guide en modules Kenney (AD-006), géologie unifiée à l'ancre ocre, vraies textures ambientCG qui MODULENT la peinture à 70 % (§1.6, AD-007), grain procédural `FastNoiseLite` (AD-001), rive plantée (saules et souches moussus Quaternius), palette recalée par MESURE (sol `#BBBE5C`, lointain refroidi `#C5BFA3`). Preuves : `evidence/cycle3/` v0→v23, dont l'avant/après de la vallée (`valley_avant.png` / `valley_v1_peinte.png`).
* **La vidéo de stabilité existe** : `scenes/lookdev/StabilityDolly.tscn` + `tools/video/assemble_webp.py` (webp 10-20 s, produite pour le lab v6 et v13). Étends-la aux autres zones — ne la réinvente pas.
* **Approvisionnement d'assets — fait environnemental crucial** : les sites d'assets sont bloqués par le proxy (403), **seul GitHub passe**. Le propriétaire dépose les packs CC0 (release GitHub `assets-1` ou dossier `incoming_assets/`). Déjà déposés, attribués, EN ATTENTE de sélection/import : **Kenney Nature Kit, KayKit Dungeon, Quaternius Ultimate Nature (150 OBJ)**. Chaîne obligatoire, désormais testée : licence → `ATTRIBUTIONS.md` → manifeste → peinture → habillage → capture. Besoin non couvert = liste de courses claire remise à l'utilisateur, et tu continues sur autre chose.
* Deux auto-évaluations SÉVÈRES déjà rendues (`evidence/cycle3/2026-08-06_eval_v5_severe.md`, `eval_v9_severe.md`) ; le score humain sur GPU reste dû ; dernier verdict noté du Gate H : FAIL (~31-41/100), antérieur à tout cela.
* **Le tour du monde en images EXISTE** (`evidence/tour_du_monde/`, 11 zones, table de verdicts dans l'audit — session du 2026-08-06). Ses verdicts : vestibule de la citadelle = le plus bel intérieur du jeu (KEEP) ; **les six salles du donjon = boîtes brunes plates (REWORK)** ; **l'arène du boss = déficit visuel n°1** (disque gris nu où le Gardien se perd) ; bestiaire = silhouettes distinctes mais corps en primitives. La vraie carte a aussi révélé et fait corriger 4 régressions que le lab de 80 m ne montrait pas (mipmaps, carte délavée, nuage blanchi, sol gris) ; le terrain est EXCLU de la recette painterly (décision mesurée, assumée).
* **AD-008 — leçon capitale de la dernière session** : la peinture du donjon a été tentée, MESURÉE, puis RETIRÉE (matière gagnée mais luminance 17 % → 9-11 % sur un donjon déjà trop sombre — ISS-025 — et marques de sol de l'arène ternies 45,5 → 16,3). **La recette painterly est calibrée pour un SOLEIL : un intérieur à petites lampes exige son propre réglage. L'éclairage du donjon passe AVANT sa peinture.** `paint_room()` est écrit et documenté, non appelé — ne le rebranche pas sans avoir refait l'éclairage.
* La citadelle a gagné son socle en terrasses et ses contreforts (§2.4, lot 16) — gain honnête mais largement masqué depuis la vue d'ouverture par les falaises du plan moyen.
* **LE DIAGNOSTIC QUI COMMANDE CETTE PASSE (revue d'images du 2026-08-06, propriétaire + direction artistique) : le jeu est encore moche, et ce n'est PAS un problème de peinture.** Regarde `evidence/cycle3/herolab_v23_saules.png`, `valley_v1_peinte.png` et `evidence/tour_du_monde/13_arene_boss.png` : la citadelle est un empilement de cubes gris, le nuage une galette noire, le pylône une pile de cubes, les falaises des dalles à texture étirée, le sol une moquette verte ou une dalle grise, les saules des blobs fondus, les fleurs des cubes flottants, l'arène un disque nu où le Gardien est une boîte à pattes. **MASTER_SPEC §7.14 l'avait prédit : « aucun shader ne transforme automatiquement une géométrie faible en direction artistique haut de gamme. »** Vingt-trois itérations de valeurs/palette ont été posées sur des blockouts — c'est la limite atteinte. Ce qui est déjà bon et se garde : le héros, les rochers dorés, le pin, la direction chaud/froid de la lumière, les marques de sol lisibles de l'arène.
* Handoff détaillé : dernière entrée de `docs/PROGRESS.md` — **elle est à la FIN du fichier**, malgré l'en-tête.

## PRÉ-REQUIS ABSOLU

La personne qui te lance est **débutante totale** : elle ne connaît rien au game dev, à Godot, à git, ni au terminal. Tu décides de TOUT toi-même, comme l'expert senior que tu es. Tu ne demandes JAMAIS d'arbitrer une question technique, une grille de notation, une licence, un shader, un compromis de performance. Chaque décision : tu la prends, tu la consignes dans `docs/ART_DECISIONS.md` (qui existe — respecte son format : date, décision, options rejetées, raison ; ses décisions verrouillées priment), et tu continues.

## LIMITES ABSOLUES DE TA MACHINE (ISS-002, `docs/BUILD_ENVIRONMENT.md`)

* Conteneur Linux **headless, sans GPU, sans écran, sans audio**. Captures via Xvfb + llvmpipe (rendu **logiciel**) : valables pour composition, valeurs et régression visuelle — **JAMAIS pour des FPS**.
* **INTERDIT d'écrire « le jeu tourne à 60 FPS »**. Formule honnête : « le jeu se lance et ses tests passent ; les budgets de la bible sont tenus ; la fluidité réelle reste à confirmer sur un vrai PC — `UNVERIFIED` ». Tiens `docs/PERFORMANCE.md` avec les **budgets statiques** comptés (triangles §4.5, densités §7.2, lumières §26.6).
* **Le score /100 appartient à un humain sur GPU.** Ta boussole interne : les contrats mesurables (fenêtres §1.1, bandes de valeurs §1.5, verdict du gris §30.1) + une auto-évaluation sévère (la précédente s'était surestimée de 15-25 points), consignée `UNVERIFIED`, jamais présentée comme un gate.

## 0) Réglages de session (fais-le maintenant)

* `ultrathink` sur les décisions difficiles, effort maximum (`ultracode`) sur toute la session.
* Sous-agents en parallèle autorisés, **avec git worktrees**. RÈGLE DURE (MASTER_SPEC §0.6) : deux agents ne touchent jamais la même scène, le même `.tres`/`.glb` ou le même import ; toi seul intègres et tu relances TOUS les tests après intégration.
* Agents du dépôt à utiliser : **`adversarial-qa`** (revue à contexte frais avant tout `PASS`), **`godot-researcher`** (vérifier une API contre le tag 4.7.1 installé — exemple réel : `Color.distance_to` n'existe pas en 4.7.1), **`blackbox-player`** (joue au jeu à l'image seule — vérifie que tes changements aident un vrai joueur, cf. BL-02/BL-03 de `REMAINING_BLOCKERS.md`).
* Autonomie (auto-accept) totale ; les garde-fous ci-dessous restent non négociables.

## 1) SÉCURITÉ D'ABORD (le débutant ne sait pas réparer — donc tu ne casses jamais)

1. **Vérifie que le moteur est là** : `"$GODOT_BIN" --version` (défaut `/usr/local/bin/godot`). Souvent ABSENT dans un conteneur neuf : lance `tools/setup_godot.sh` immédiatement **en tâche de fond** (~90 min) et fais les lectures de la Phase A pendant la compilation — les captures commencent dès que le moteur est prêt.
2. **`git fetch origin` d'abord, pars du tip le plus avancé** (le travail est réparti sur plusieurs branches `claude/…`). Travaille sur ta branche de session dédiée, JAMAIS la principale. **Pousse après chaque lot** — le conteneur est éphémère, ce qui n'est pas poussé peut disparaître.
3. Commits fréquents en français clair (ex. `Vallée : citadelle en terrasses, avant/après committé`). Pas de FPS dans les messages.
4. Jamais de suppression sans état committé. Remplacement d'asset = **swap testé** (l'ancien ne meurt qu'après vérification en jeu du remplaçant). Committe les `.uid` et `.import` ; ne touche jamais `.godot/imported/` à la main.
5. Si un lot casse le projet : `git reset --hard` sur le dernier commit sain (jamais au-delà du poussé), corrige, re-teste. Jamais de projet cassé en fin de session.
6. `docs/STATUS.md` + `docs/PROGRESS.md` (handoff avec la prochaine action exacte, **ajouté en fin de fichier**) ; `KNOWN_ISSUES.md` si un échec survit. Bref — voir règle de rendement n° 1.

## 2) Documents et principes verrouillés (lecture = un moyen, pas un livrable)

Ordre de priorité en conflit : `docs/ART_DECISIONS.md` > `docs/VISUAL_ASSET_BIBLE.md` (Prompt 3 : QUOI) > `docs/PROMPT2_SPEC.md` > `docs/MASTER_SPEC.md` > `docs/ART_DIRECTION_MODE.md` (Prompt 4 : COMMENT). Règles `.claude/rules/*.md` contraignantes. Lis ce dont tu as besoin quand tu en as besoin — pas de séance de lecture intégrale.

Verrouillé (ne pas rouvrir) :

* Painterly « illustration peinte devenue espace 3D » : ramps adoucies, 2–3 niveaux d'ombre fondus. INTERDIT : toon dur, contours noirs.
* Le rendu se gagne dans **`SH_CharacterPainterly` + la lumière** — le shader EXISTE (half-Lambert + rampes `smoothstep` + chaud/froid Gooch dans le `light()`, variante `Cutout` pour les feuilles), déployé par `scripts/art/painterly_recipe.gd`. **Améliore la recette en place, ne crée pas de doublon** : toute retouche se valide d'abord au HeroShotLab, puis se re-propage par la recette.
* Notation : grille bible **§30.2** uniquement (le §3.5 du Prompt Maître est archivé) ; protocole d'image **§30.1** ; continue la série d'evidence au format existant (`evidence/cycle3/`).
* `AreaLight3D` : autorisé seulement si `godot-researcher` confirme que la classe existe dans le tag 4.7.1 installé ; coût GPU immesurable ici → usage parcimonieux, `UNVERIFIED`.
* Boucle jouable INTOUCHABLE : contrôles, collisions, télégraphes, énigmes, graphe du donjon, BossDirector. Les ~700 tests restent verts après chaque lot.

## 3) PHASE A — LE TOUR DU MONDE EN IMAGES (obligatoire, prouvé, sans pause à la fin)

**Un tour du monde complet a été fait le 2026-08-06** (`evidence/tour_du_monde/`, 11 zones + table de verdicts). Tu ne le refais pas de zéro : tu le METS À JOUR — recapture toute zone modifiée depuis, complète ce qui manque, et re-vérifie les verdicts avant de t'y fier. S'il datait de plusieurs sessions ou si les zones ont beaucoup bougé, refais-le en entier. L'exploration se fait **caméra au poing, dans le vrai moteur** — pas en lisant des résumés. Elle n'est terminée que lorsque ce paquet de preuves est committé :

* **≥ 12 captures baseline**, une par zone, via `tools/godot/capture_reference.gd`, depuis un **arbre committé** (manifeste `repo_dirty: false`), caméra/seed/preset consignés pour être rejouables : ① vue d'ouverture de la vallée (crête de départ), ② camp, ③ rivière/eau, ④ pylône, ⑤ citadelle de loin, ⑥ `CitadelVestibule`, ⑦→⑫ les SIX salles du donjon (`Room1Initiation` → `Room4Battery`, `CentralHall`, `Antechamber`), ⑬ `BossArena` avec le Gardien, ⑭ `HeroShotLab` v5 (reprise témoin), ⑮ planche personnages (`SilhouetteLineup` ou `CharacterTurntable`). Les « avant » existants (`evidence/cycle3/`, `evidence/phaseH/`) complètent, ils ne remplacent pas les zones jamais capturées.
* La table **`KEEP / REWORK / REPLACE / MISSING / BLOCKED`** couvrant CHAQUE zone et chaque famille d'assets, chaque ligne pointant sa capture. Mets à jour les audits existants (`docs/assets/AUDIT_V0_PHASE_H.md`…) — n'en crée pas de nouveaux.
* Preuve = moteur réel uniquement. **Jamais d'image générée par IA présentée comme capture.**

Pendant que Godot compile : lis le handoff (fin de `PROGRESS.md`), la ligne Cycle 3 de `STATUS.md`, les fiches `evidence/cycle3/*.md` — puis passe aux captures dès que possible.

**À la fin de la Phase A : affiche le plan en 10 lignes maximum (ordre des zones, ce qui change dans chacune, les paires avant/après attendues) et ENCHAÎNE IMMÉDIATEMENT sur la première amélioration, dans la même réponse. N'attends aucun accord.**

## 4) PHASES B et C — Améliorer, zone par zone, le plus visible d'abord

* Ordre de réflexion d'artiste : **silhouette → valeurs → composition → lumière chaud/froid → couleur → mouvement → shaders en dernier** (c'est la trajectoire v0→v5 — continue-la).
* **RÈGLE v6 — INTERDIT de lancer une nouvelle passe de shader, de valeurs ou de palette tant que les blockouts ci-dessous n'ont pas été remplacés** (§7.14). Le chantier, dans l'ordre, avec la même méthode procédurale Blender qui a produit le Gardien (`tools/blender/make_storm_guardian.py` — elle marche, généralise-la) :
  ① **`make_citadel.py`** : la citadelle en < 20 grandes formes (socle en terrasses 55 % de la masse, deux ailes, quatre contreforts, tours de hauteurs différentes, spire en 5 segments, couronne — bible §2.4/§11.3), remplaçant l'empilement de cubes ; validée en SILHOUETTE NOIRE depuis la vue d'ouverture avant tout matériau.
  ② **`make_pylon.py`** : le pylône §11.2 (base tripode, fût effilé, canaux, anneau incomplet, fourche) au lieu de la pile de cubes.
  ③ **Nuage d'orage multi-couches** (§9.2 : base sombre aplatie, masse dense, bords chauds côté soleil, 2 nappes) au lieu du blob.
  ④ **Terrain et falaises** : dalles remplacées par les modules Kenney cliff DÉJÀ importés (`assets/environment/cliffs/`) composés en strates ; sol en mélange herbe/terre/roche — plus de moquette uniforme ni de dalle grise sous l'herbe.
  ⑤ **Arbres et fleurs** : blobs remplacés par Ultimate Nature (150 OBJ déposés) ; les fleurs deviennent de vraies formes, plus des cubes flottants.
  ⑥ **Arène du boss** : sol à trois matériaux réels, bord architectural bas, quatre pylônes présents, gradins en ruine (§15.5 de la bible) — plus un disque nu ; puis son éclairage (AD-008), puis seulement la peinture intérieure et le KayKit du donjon.
* Après CHAQUE remplacement : recapture depuis la même caméra, compare en silhouette et en vignette — c'est la grande forme qui doit lire, pas le détail. Échelle et air : la citadelle doit lire LOIN et GRANDE (300-420 m, brume d'étagement §1.3) ; le brouillard cesse d'être du lait ; le grain/speckle des captures est un défaut à éliminer, pas un style.
* Ensuite seulement : créatures en primitives (colosse, chasseur — même méthode), armes (ISS-020), VFX du Bracelet (§20.3), vidéos `StabilityDolly`. Règle AD-008 maintenue : une recette calibrée pour un éclairage ne se propage jamais telle quelle à un autre — mesure, et retire ce qui régresse.
* **Cap réaliste à consigner (AD proposé)** : avec des kits CC0 low-poly, des scripts procéduraux et zéro sculpteur humain, le registre atteignable — et très montrable — est le **low-poly stylisé cohérent sous lumière painterly** (l'élégance d'un Tunic ou d'un A Short Hike), pas le photoréalisme peint de la référence. Vise la COHÉRENCE et la silhouette dans ce registre ; c'est ainsi qu'on obtient le « wahou » avec ces moyens.
* **La bifurcation du handoff t'appartient** : ré-évalue la dernière version du lab sévèrement dès la Phase A ; si ton auto-évaluation + `adversarial-qa` concluent ≥ 75 avec preuves, engage la propagation V4 en la consignant dans `ART_DECISIONS.md` comme décision révocable (le gate officiel reste `UNVERIFIED`). Sinon, itère le lab d'abord. Ne déclare jamais le Gate H `PASS` toi-même.
* Repères : citadelle = weenie principal (< 20 grandes formes lisibles à 300-420 m), pylône = verticale secondaire, trois plans, cyan saturé < 5 % de l'écran, ratio chaud/froid §1.4.
* Optimisation honnête : budgets statiques comptés (triangles, MultiMesh 24–48 m, visibility ranges, LOD, lumières) — au compte, jamais au FPS.
* **Chaque zone se clôt par : validation section 5 + paire avant/après committée + une ligne dans STATUS.** Puis zone suivante, sans pause.

## 5) VÉRIFICATION AUTOMATIQUE après chaque lot (toi-même, en silence)

```bash
tools/validate_fast.sh    # import headless, parse, ~700 tests — RC=0 exigé
```

**Piège connu (ISS-027)** : le runner peut afficher « ok » alors qu'une erreur de script a avorté un test après sa première assertion. Même à RC=0, balaie les logs : `grep -E "SCRIPT ERROR|ERROR:|Parse Error|invalid UID|Shader compilation"`. Sur un doute d'import : `"$GODOT_BIN" --headless --path . --import` et analyse le TEXTE, pas le code de sortie. `--check-only` + autoload = faux positifs possibles, préfère l'import complet. Si CASSÉ : retour au dernier commit sain, corrige, re-teste. Résume au débutant en une phrase, sans logs.

## 6) CRITÈRE DE QUALITÉ « WAHOU » (interne : toi + `adversarial-qa` — l'utilisateur ne note JAMAIS rien)

Grille bible **§30.2** (8 domaines, /100), protocole **§30.1** : miniature 320×180, gris, flou, contours, 1440p, **vidéo 10–20 s en mouvement via `StabilityDolly` (webp — déjà produite pour le lab, à étendre à chaque zone retravaillée)**. Cible ≥ 85/100, cohérence sur 5 captures, aucun domaine à zéro. Statuts : `PASS / PARTIAL / FAIL / BLOCKED / UNVERIFIED`. Avant tout `PASS` : revue `adversarial-qa` à contexte frais (diff + preuves + critères seulement). Le verdict FINAL du Gate H exige humain + GPU : ton livrable est « prêt à noter », jamais un `PASS` auto-proclamé.

## 7) LES SEULS moments où tu poses une question (maximum 2 à 3 sur toute la run — zéro est très bien aussi)

Uniquement un choix de goût pur, décidable sans aucune connaissance, via l'outil de question à choix multiples, en français ultra-simple, ta reco marquée « (Recommandé) », chaque option illustrée d'une capture réelle : « Voici 2 images de la vallée : A ou B ? Je recommande A parce qu'elle est plus douce et chaleureuse. » Sans réponse rapide ou sur « à toi de voir » : tu appliques ta reco, tu la consignes dans `ART_DECISIONS.md`, et **tu continues sans interrompre le travail**. Tout le reste : tu décides seul.

## 8) COMMENT TU RAPPORTES (français simple, zéro jargon — et toujours des images)

Après chaque zone, un point court avec la paire avant/après : « J'ai amélioré la lumière de la vallée — avant/après ci-dessous. Le jeu se lance toujours et ses tests passent tous. » Jamais de FPS inventé. Terme technique inévitable = une ligne d'explication entre parenthèses. Ligne optionnelle « Ce que ça veut dire : … ». **Le rapport ne remplace jamais le travail : il le suit.**

## 9) Fin de session

Contrôle du contrat de rendement : **≥ 3 zones visiblement améliorées, ≥ 3 paires avant/après committées** — sinon dis-le honnêtement et explique pourquoi. `tools/validate_fast.sh` vert, tout committé **et poussé**, STATUS / PROGRESS (handoff en fin de fichier) / ART_DECISIONS à jour, résumé final simple : ce qui a changé, les avant/après, les budgets tenus, et « ce que tu pourras regarder plus tard sur ton propre écran » (`docs/MANUAL_VALIDATION.md` — dont la notation §30.2 du HeroShotLab). Ne laisse jamais le projet cassé.

**Commence maintenant : lance la compilation de Godot en fond si le binaire manque, démarre le tour du monde en images de la Phase A, affiche ton plan en 10 lignes — et enchaîne immédiatement sur la première amélioration sans attendre mon accord.** `ultrathink`

---

## Guide de lancement pour débutant absolu (aucune connaissance supposée)

Vous n'avez presque rien à faire : Claude fait le travail.

1. La session tourne **dans le cloud** (Claude Code sur le web) : rien à installer sur votre ordinateur. Si Claude dit que « Godot compile », c'est normal — il fabrique lui-même le logiciel du jeu dans sa machine distante (~1 h 30) et travaille pendant ce temps.
2. Votre jeu est le dépôt GitHub `istbanbanier/zelda` (le dossier qui contient `project.godot`). Collez simplement ce prompt dans une nouvelle session Claude Code ouverte sur ce dépôt.
3. Pour juger de vos propres yeux plus tard : ouvrez le projet dans Godot 4.7.1 et suivez `docs/MANUAL_VALIDATION.md` — regarder la scène `HeroShotLab` et dire si elle vous plaît aide énormément Claude à continuer dans la bonne direction.
