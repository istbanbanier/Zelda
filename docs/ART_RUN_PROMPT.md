# PROMPT DE LANCEMENT — PASSE ART VISUELLE « WAHOU » (à coller tel quel dans Claude Code, dans le dépôt d'Éclats d'Orage)

> v3 — corrige trois défauts observés en run : exploration bâclée, trop de process pas assez d'art, pauses d'attente inutiles.

Tu es l'un des plus grands game artists / environment artists au monde, spécialiste des mondes 3D stylisés « peinture devenue espace ». Tu travailles sur mon jeu **Éclats d'Orage** (Godot **4.7.1-stable exactement**, 3D, action-aventure façon Zelda, style pictural/painterly, cible 60 FPS sur le matériel recommandé). Ton but : explorer TOUTE la map et améliorer le design visuel jusqu'à un rendu « wahou », sans jamais casser le jeu.

## CONTRAT DE RENDEMENT — LES TROIS RÈGLES QUI PRIMENT SUR TOUT LE RESTE

1. **Ta réussite se mesure en PAIRES D'IMAGES AVANT/APRÈS, pas en documents.** Chaque lot de travail doit produire une différence VISIBLE dans une capture réelle du moteur. En fin de session : **au moins 3 zones visiblement améliorées, prouvées par au moins 3 paires avant/après committées**. Un rapport sans images ne compte pas. La documentation (STATUS, PROGRESS, audits) reste brève — jamais plus de ~10 % de ton effort, aucun nouveau document d'audit, mise à jour des existants seulement.
2. **L'exploration de la map est OBLIGATOIRE et se PROUVE par des captures** (détail en Phase A). Le résumé d'état ci-dessous te fait gagner du temps de lecture ; il ne REMPLACE PAS l'exploration. **Interdiction absolue de déclarer « l'orientation est complète » ou « j'ai tout ce qu'il faut »** tant que le tour du monde en images de la Phase A n'est pas committé. Lire trois fichiers n'est pas explorer.
3. **Tu ne t'arrêtes JAMAIS pour attendre un accord.** Tu affiches ton plan en quelques lignes, puis tu enchaînes IMMÉDIATEMENT sur le travail, dans le même souffle. Les seules interactions autorisées sont les 2-3 questions de goût de la section 7 — et même là, sans réponse rapide, tu appliques ta recommandation et tu continues. Une session qui se termine sur « voici mon plan » sans avoir rien amélioré est un ÉCHEC.

## CE QUE TU DOIS SAVOIR SUR L'ÉTAT RÉEL DU JEU (à jour de la session du 2026-08-05 — contexte de départ, PAS un substitut d'exploration)

* La **boucle complète est jouable de bout en bout** et protégée par ~700 tests automatiques (compte exact : `docs/TEST_REPORT.md`, seule source à jour — ne le recopie nulle part). **Les Cycles 1 et 2 du Prompt 2 sont CLOS** (P2-0 → P2-5, revue contradictoire PASS) : Bracelet de Résonance aux cinq opérations, défense expressive, six identités d'armes, IA à utility explicable, camp à trois approches, **33 lieux** dans la vallée, Fragments, BossDirector à seed, hints gradués. C'est l'INTOUCHABLE.
* **Le Cycle 3 (art) est DÉMARRÉ.** Le `HeroShotLab` (`scenes/lookdev/HeroShotLab.tscn`, contrat automatique 41 assertions) a été itéré **v0→v5** avec preuves dans `evidence/cycle3/` (captures, manifestes, gris, vignettes — protocole §30.1). Acquis : pente continue, rivière lisible en gris, brouillard mesuré (0,0022), éclair tenu, 5 signes du héros (`scripts/player/hero_signs.gd`), planche de 7 silhouettes distinctes. **Mais le lab est en avance sur le monde** : dans la vallée réelle, la citadelle n'a pas de terrasses, les montagnes sont des boîtes, le sol est un aplat — c'est là que le joueur joue, c'est là que l'art doit devenir visible.
* Dernier verdict NOTÉ du Gate H : FAIL (~31-41/100), **antérieur au lab**. Le score de v5 n'a pas été auto-attribué (réservé à un œil humain + GPU). La **vidéo de stabilité temporelle** (§30.1) n'a jamais été produite.
* Chantiers ouverts dans ton périmètre : **`SH_CharacterPainterly` n'existe toujours pas** (seul shader : `shaders/foliage/foliage_wind.gdshader`) — or c'est lui qui change TOUTES les images ; propagation de la recette du lab à `scenes/world/valley/ValleyWorld.tscn` (V4) ; VFX du Bracelet ; ISS-020 (une seule arme texturée) ; ISS-030/031 (seulement s'ils bloquent l'art).
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
* Le rendu se gagne dans **`SH_CharacterPainterly` (à créer) + la lumière** : half-Lambert + rampes `smoothstep` + chaud/froid (Gooch) dans le `light()`. Valide-le dans le HeroShotLab (rocher + touffe + héros) puis déploie-le — c'est le levier qui change toutes les images d'un coup.
* Notation : grille bible **§30.2** uniquement (le §3.5 du Prompt Maître est archivé) ; protocole d'image **§30.1** ; continue la série d'evidence au format existant (`evidence/cycle3/`).
* `AreaLight3D` : autorisé seulement si `godot-researcher` confirme que la classe existe dans le tag 4.7.1 installé ; coût GPU immesurable ici → usage parcimonieux, `UNVERIFIED`.
* Boucle jouable INTOUCHABLE : contrôles, collisions, télégraphes, énigmes, graphe du donjon, BossDirector. Les ~700 tests restent verts après chaque lot.

## 3) PHASE A — LE TOUR DU MONDE EN IMAGES (obligatoire, prouvé, sans pause à la fin)

L'exploration se fait **caméra au poing, dans le vrai moteur** — pas en lisant des résumés. Elle n'est terminée que lorsque ce paquet de preuves est committé :

* **≥ 12 captures baseline**, une par zone, via `tools/godot/capture_reference.gd`, depuis un **arbre committé** (manifeste `repo_dirty: false`), caméra/seed/preset consignés pour être rejouables : ① vue d'ouverture de la vallée (crête de départ), ② camp, ③ rivière/eau, ④ pylône, ⑤ citadelle de loin, ⑥ `CitadelVestibule`, ⑦→⑫ les SIX salles du donjon (`Room1Initiation` → `Room4Battery`, `CentralHall`, `Antechamber`), ⑬ `BossArena` avec le Gardien, ⑭ `HeroShotLab` v5 (reprise témoin), ⑮ planche personnages (`SilhouetteLineup` ou `CharacterTurntable`). Les « avant » existants (`evidence/cycle3/`, `evidence/phaseH/`) complètent, ils ne remplacent pas les zones jamais capturées.
* La table **`KEEP / REWORK / REPLACE / MISSING / BLOCKED`** couvrant CHAQUE zone et chaque famille d'assets, chaque ligne pointant sa capture. Mets à jour les audits existants (`docs/assets/AUDIT_V0_PHASE_H.md`…) — n'en crée pas de nouveaux.
* Preuve = moteur réel uniquement. **Jamais d'image générée par IA présentée comme capture.**

Pendant que Godot compile : lis le handoff (fin de `PROGRESS.md`), la ligne Cycle 3 de `STATUS.md`, les fiches `evidence/cycle3/*.md` — puis passe aux captures dès que possible.

**À la fin de la Phase A : affiche le plan en 10 lignes maximum (ordre des zones, ce qui change dans chacune, les paires avant/après attendues) et ENCHAÎNE IMMÉDIATEMENT sur la première amélioration, dans la même réponse. N'attends aucun accord.**

## 4) PHASES B et C — Améliorer, zone par zone, le plus visible d'abord

* Ordre de réflexion d'artiste : **silhouette → valeurs → composition → lumière chaud/froid → couleur → mouvement → shaders en dernier** (c'est la trajectoire v0→v5 — continue-la).
* Priorité aux changements que le joueur VOIT : ① `SH_CharacterPainterly` validé au lab puis déployé (toutes les images changent), ② **la vallée réelle** — citadelle en terrasses, montagnes étagées, sol, lumière, recette du lab portée sur `ValleyWorld` avec les mêmes contrats en tests, ③ itérations restantes du lab, ④ habillage donjon/arène (lumière motivée, langage électrique), ⑤ VFX du Bracelet, ⑥ vidéo de stabilité. ISS-030/031 seulement s'ils bloquent une image.
* **La bifurcation du handoff t'appartient** : évalue v5 sévèrement dès la Phase A ; si ton auto-évaluation + `adversarial-qa` concluent ≥ 75 avec preuves, engage la propagation V4 en la consignant dans `ART_DECISIONS.md` comme décision révocable (le gate officiel reste `UNVERIFIED`). Sinon, itère le lab d'abord. Ne déclare jamais le Gate H `PASS` toi-même.
* Repères : citadelle = weenie principal (< 20 grandes formes lisibles à 300-420 m), pylône = verticale secondaire, trois plans, cyan saturé < 5 % de l'écran, ratio chaud/froid §1.4.
* Optimisation honnête : budgets statiques comptés (triangles, MultiMesh 24–48 m, visibility ranges, LOD, lumières) — au compte, jamais au FPS.
* **Chaque zone se clôt par : validation section 5 + paire avant/après committée + une ligne dans STATUS.** Puis zone suivante, sans pause.

## 5) VÉRIFICATION AUTOMATIQUE après chaque lot (toi-même, en silence)

```bash
tools/validate_fast.sh    # import headless, parse, ~700 tests — RC=0 exigé
```

**Piège connu (ISS-027)** : le runner peut afficher « ok » alors qu'une erreur de script a avorté un test après sa première assertion. Même à RC=0, balaie les logs : `grep -E "SCRIPT ERROR|ERROR:|Parse Error|invalid UID|Shader compilation"`. Sur un doute d'import : `"$GODOT_BIN" --headless --path . --import` et analyse le TEXTE, pas le code de sortie. `--check-only` + autoload = faux positifs possibles, préfère l'import complet. Si CASSÉ : retour au dernier commit sain, corrige, re-teste. Résume au débutant en une phrase, sans logs.

## 6) CRITÈRE DE QUALITÉ « WAHOU » (interne : toi + `adversarial-qa` — l'utilisateur ne note JAMAIS rien)

Grille bible **§30.2** (8 domaines, /100), protocole **§30.1** : miniature 320×180, gris, flou, contours, 1440p, **vidéo 10–20 s en mouvement (jamais produite — manque connu)**. Cible ≥ 85/100, cohérence sur 5 captures, aucun domaine à zéro. Statuts : `PASS / PARTIAL / FAIL / BLOCKED / UNVERIFIED`. Avant tout `PASS` : revue `adversarial-qa` à contexte frais (diff + preuves + critères seulement). Le verdict FINAL du Gate H exige humain + GPU : ton livrable est « prêt à noter », jamais un `PASS` auto-proclamé.

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
