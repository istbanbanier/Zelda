# STATUS — état par fonctionnalité

## World V2 — reconstruction du monde (2026-08-13, `claude/world-v2-reconstruction`)

| Phase | État | Preuve |
|---|---|---|
| V2.0 — squelette dual-monde, carte directrice, contrats | Validé | `evidence/world_v2/v2_0/` ; suites `tests/world_v2/test_world_v2_skeleton.gd`, `test_world_v2_layout.gd` |
| V2.1 — vallée whitebox physique (relief, hydrologie, routes, limites, navigation, traversée réelle) | **Validé — Gate PASS** | `evidence/world_v2/v2_1/README.md` (verdicts par critère), revue contradictoire archivée, `validate_fast_final.log` ; SHA final dans `docs/PROGRESS.md` |
| V2.2 — fondation artistique du paysage (matériau painterly, végétation cellulaire, eau, ciel/orage, silhouettes) | **Fonctionnel — gate technique PASS en revue contradictoire** | `evidence/world_v2/v2_2/README.md`, `revue_contradictoire.md`, `validate_fast_final.log`, contrôles négatifs A-D + angle mort E |
| V2.2 — enveloppe du donjon | Différée par directive du lead | fil de détente `tests/world_v2/test_world_v2_dungeon_pins.gd` en place |
| V2.3-0 — socle technique des lieux (registre, placement par layout, filets, contrôles négatifs) | **PASS prononcé par le lead** | `evidence/world_v2/v2_3/`, suites `test_world_v2_places_contract.gd`, `test_world_v2_places_behavior.gd` |
| V2.3-A — lot pilote, 9 sujets : gate ARTISTIQUE | **REJETÉE par le lead** | verdict du lead ; planches de preuve vides et ligne de base mal étiquetée |
| V2.3-A.R — passe corrective : preuves réparées, 9 sujets repris | chaîne technique et preuves SHA **PASS** ; gate artistique **ÉCHEC** | verdict du lead ; `evidence/world_v2/v2_3/MANIFESTE_V23AR.md` ; `validate_fast` 899/0 |
| V2.3-A.R2a — changement de pipeline, 4 golden masters | **En cours** | base `c946b0e` ; hameau · pont · grotte · pylône seulement |
| R2a-0 — enquête pipeline (Blender, pivots CC0, `gltf_inspect`) | **PASS prononcé par le lead** | `evidence/world_v2/v2_3_r2a/README.md` |
| R2a-4 — pylône, 1er golden master | « progrès majeur, pas encore golden master » (lead) | trois faiblesses nommées + preuve invalide (`repo_dirty: true`) |
| R2a-4.1 — pylône, golden master 1/4 | **PASS artistique ET technique prononcé par le lead — GELÉ au code `4165801`** | `evidence/world_v2/v2_3_r2a/README.md` §R2a-4.1 ; 7 vues + 2 manifestes `commit 4165801` / `repo_dirty: false` ; `world_v2_places` 8/8 ; `gltf_inspect` VALIDE |
| R2a-2 pont — golden master 2/4 | **PASS visuel prononcé par le lead — GELÉ à partir de `9f25e78`** | verdict du lead ; réserves non bloquantes (intrados plat, tympans sobres) ; note du layout corrigée en `9583e25` (traversée en aval du gué, offset 28,8 m mesuré) |
| R2a-3 grotte — golden master | **FAIL visuel prononcé par le lead** | sept défauts nommés : miche lisse, bouche en demi-cercle, tunnel cylindrique, silhouettes génériques, niche sans composition, flanc surexposé |
| R2a-3.1 grotte — corrective | **NON VÉRIFIÉ — livré, en attente du verdict visuel du lead** | `evidence/.../grotte/CORRECTIVE_R2a_3_1.md` ; commit `71d1817`, `repo_dirty: false` ; 7 vues + tournette 8 + 2 silhouettes isolées ; sections POLYGONALES (le premier jet quantifiait le rayon et traçait des arcs) ; visière et éperon côté approche ; épaisseur 1,12 m / collerette 0,75 m ; places 8/8 ; végétation gelée sans intersection. **7 exigences PASS, exigence 5 (mise en scène de la récompense) PARTIAL, déclarée telle.** |
| R2a-3.3 grotte — extérieur reconstruit en roches CC0 | **NON VÉRIFIÉ — livré, en attente du verdict visuel du lead** | `evidence/.../grotte/tranche3/TRANCHE3.md` ; géométrie et GLB au commit `8368550`, captures au commit `73dc20a`, `repo_dirty: false` sur tous les manifestes. `anneau_exterieur()` ne rend plus rien (collision seule) ; 98 roches du kit CC0, remaillage volumétrique, cavité soustraite comme solide. Chaîne verte RC = 0 : 20 444 tris, plage plane 3,45 m² global et 2,36 m² en façade, épaisseur 1,05 m en paroi et 1,30 m au linteau, coque fermée, 1 composante, gabarit aux 7 stations, aucun jour ; `gltf_inspect` VALIDE. **La consigne « trois masses larges et asymétriques » n'est PAS atteinte et c'est mesuré** : 4 sommets de largeur 1,07 à 1,26 m, cv 0,06, sur l'azimut réel d'approche (`tools/measure_silhouette_masses.py`). Deux caméras de preuve héritées étaient fausses — démontré par la baseline R2a-3.1 à la même caméra — conservées pour les A/B, doublées de caméras justes. Masses jaunes : `Flower_4_Group` V2.2, identifiées, **non corrigées** (propagation). |
| R2a-3.4 grotte — corrective multi-agent | **NON VÉRIFIÉ — livré, en attente du verdict visuel du lead** | `evidence/.../grotte/tranche4_final/R2A_3_4.md`. Cinq SHA distingués : flore `4ed364b`, baseline `8900375`, géométrie `504ecbe`, capture `55c4803` (`repo_dirty: false`). **Flore V2.2** : `Flower_4_Group` 2,841 m → 0,545 m par `KitScale`, bande (0,69 ; 0,99) ; rouge reproduit, 4 verts, témoin d'invariance éprouvé. **Composition** : 3 masses de 5,58 / 3,60 / 2,18 m, cv 0,37, stables à quatre entailles et deux azimuts — contre 4 masses à cv 0,06 ; cause mesurée (faîte du module 0,93 m, 81 % de portage solo). **Seuil** : plancher 66 fautes → 0, fond ouvert → plein, percées 761 → 73 toutes isolées, filet `test_grotte_sans_jour` rouge → 67/0. **NON SATISFAITE** : sonde `FAIL` global sur 73 percées isolées ; linteau 0,61 m pour un seuil de 0,60 ; contrefort droit pas « en retrait » ; contrôle 3 de la sonde `PARTIAL`. Conflit de spécifications nommé : épaissir pour fermer et creuser pour trois masses tirent sur la même roche. |
| R2a-3.5.8 grotte — candidat au 4ᵉ golden master INTÉGRÉ sous `candidates/` | **Techniquement VERT — NON VÉRIFIÉ visuellement, en attente du verdict Codex/Istvan ; R2a-3.4 reste la production** | `evidence/.../grotte/r2a358_lead/RAPPORT_FINAL.md`. GLB `5ff4ec6e…` commité à `assets/environment/caves/candidates/`, byte-identique sur deux exports de reconstruction (worktree propre puis arbre committé). Collider : zéro auto-intersection réelle au juge du tronc, reproduit par le lead. `SM_` bit-identique à la baseline sous trois instruments. Traversabilité (agent B) : canonique courbe sans faute, capsule au chiffre près du relevé 3.5.7, champ paroi sous marge figée, poche ≥ plancher de conception — verdict au fil du couteau tenu par deux appuis et reproduit par le lead à instrument indépendant. Bascule de revue `WORLD_V2_GROTTE_CANDIDAT=r2a358` (capture seulement) ; boot→WorldV2 vert avec et sans. 15 captures d'arbre committé inspectées une à une + 4 montages A/B contre R2a-3.4 + tracés d'instrument du collider. Déclassement du balayage de domaine appliqué (décision gelée `cca1778`). |
| **GM4 — grotte R2a-3.5.8 PROMUE en production** | **PASS visuel du lead (2026-08-19) — GOLDEN_MASTERS=4/4, gelés** | Verdict rendu sur les 15 captures + 4 montages A/B. Grotte par défaut = `assets/environment/caves/SM_WaterfallCave_r2a358.glb` (`5ff4ec6e…`, git mv sans un octet touché) ; R2a-3.4 conservée à son chemin comme fallback (`WORLD_V2_GROTTE_FALLBACK=r2a34`, outillage). Filet grotte corrigé : marche la route canonique COURBE publiée en meta (mesure agent B) et sonde sous les surplombs — rouge corde archivé, 8/8 route, 8/8 fallback. 5 captures de promotion sans variable, arbre committé. Réserves non bloquantes du verdict : intérieur austère, strates arrière chargées, porche anguleux — matière R2B+, pas de corrective géométrique. |
| R2a-1 hameau — golden master 3/4 | **PASS visuel conditionnel prononcé par le lead — condition LEVÉE, gelable** | `evidence/.../hameau/VEGETATION_VERDICT.md` : emprise complète sondée, 78 instances gelées dedans, **aucune intersection** ; cas le plus serré 0,35 m, à côté et non dedans ; aucune reconstruction, végétation V2.2 intacte |
| **V2.3-A.R2B — cinq lieux pilotes reconstruits (3 agents + lead)** | **Techniquement VERT — NON VÉRIFIÉ visuellement, en attente de la revue Codex/Istvan** | 21 commits cherry-pickés (voies A camps / B ferme+arbre / C bassin) depuis la même base `5f821e5`. 12 contrôles négatifs ROUGES d'abord archivés puis verts, seuils inchangés (`evidence/world_v2/v2_3_r2b/preuves_lead/JOURNAL_CONTROLES_NEGATIFS.md`). Suite world_v2 intégrée **68/68, RC=0** ; boot smoke 23 assertions RC=0 ; golden masters **byte-identiques 6/6** avant/après (`GM_BASELINE_SHA256.txt`). 2 œuvres Blender originales committées avec générateurs (SM_Farm_Ruins 676 tris, SM_ThunderstruckTree 977 tris) ; 16 régularisations Quaternius CC0 au manifeste ; zéro ressource téléchargée. 5 montages A/B à caméra identique + carte + planches couleur/gris + métriques (`preuves_lead/`). validate_fast : **916/916 tests verts ; harness global ROUGE sur ISS-059** — mêmes 4 types de RID, aucune classe nouvelle, passe filtrée propre, amplitude proportionnelle au contenu (consigné à ISS-059). Dépassement camp braise (54 modules/plafond 45) consigné et accepté. |

| **V2.3-A.R2B.1 — corrective ferme + arbre, budget braise** | **CONTRÔLES TECHNIQUES VERTS · PORTAIL VISUEL DU LEAD EN ÉCHEC SUR `ferme_seuil` → passe close en PARTIAL** — NON VÉRIFIÉ visuellement, revue Codex/Istvan attendue | 27 commits cherry-pickés de trois voies depuis `7c3d3ca`, intégrés à `e2bf32a`. Suite `world_v2` **85/85 RC=0** (68 + 8 ferme + 8 arbre + 1 braise) ; boot 23 assertions RC=0 ; **golden masters 6/6 byte-identiques** ; `gltf_inspect` VALIDE ; budgets de triangles INCHANGÉS (ferme 1 624/4 500, arbre 2 526/6 000). **Ferme** : cause mesurée — le mur de kit n'a pas de tranche, face intérieure = quad de 6 m² en 2 triangles ; bug réel corrigé — **quatre** murs présentaient leur face brique VERS L'INTÉRIEUR (le message de commit disait cinq ; le code en fait quatre, corrigé par l'audit R2B.2) ; portail visuel du lead max ≤ 8 % PASS sur six vues, total ≤ 12 % **FAIL sur `ferme_seuil`** (23,74 → 35,46 %) car les onze pièces neuves n'ont pas d'UV0 et lisent comme des plaques — **PARTIAL assumé, dette nommée**. **Arbre** : cause mesurée — plan de fourche à 9,0° où la caméra de silhouette regarde dedans (recalculé par le lead) ; 8 portails verts, anisotropie 1,81 → 1,17, raie dominante du disque 68 → 23 % ; le lead a REFUSÉ la 3ᵉ rupture qui consommait la cime vivante ; l'agent a été démenti par sa propre mesure sur les racines et n'a rien touché ; son 8ᵉ portail passait au vert sur la géométrie r02 — attrapé et corrigé par lui. **Braise** : 45/45 modules, **marge nulle assumée**, poteau de palissade 280° remis sur arbitrage après que l'A/B l'a montré visible ; le portail passait au VERT sur un camp VIDE (`0 ≤ 45`) — **planchers 30/45/4 posés par le lead**, cycle prouvé. Preuves : 15 montages A/B à caméras vérifiées identiques, `evidence/world_v2/v2_3_r2b1/`. |

| **Clôture R2B.3.1 + ouverture V2.3-B** | **R2B.3 PASS VISUEL ET TECHNIQUE (verdict du lead sur les quatre planches : Debris_A, Debris_B, ferme_laterale, ferme_orb090 — quatre PASS) · ISS-059 PROJET FERMÉE · ISS-065 ouverte (limitation moteur, non bloquante, surveillée) · GO_V2_3_B=TRUE** | Double verdict rendu séparément à chaque validate_fast : `PROJECT_RESOURCE_LEAK_GATE` **VERT** (bloquant, liste blanche, 12 fixtures de contrôle négatif) · `ENGINE_SCRIPT_CACHE_TELEMETRY` **WARN — résidu moteur connu et stable**, contrat committé `docs/contrats/residu_cache_moteur.json`, dérive → code 2 bloquant. Validation finale : **949 tests, 0 échec** ; sonde de cycles : empreintes identiques (2876/862/23/0) ; RC du script = 1 sur DEUX MÉPRISES DU JUGE (filtre générique re-jugeant le domaine de 2b ; garde 2c comptant les lignes de fin de processus), corrigées et prouvées par rejugement des mêmes journaux + contre-épreuve — détail au rapport de clôture. Gel V2.3-B exécutable : 43 fichiers sha256, cycle rouge tenu, ajouter ≠ toucher. GLB inchangés depuis `06b865b` (diff vide). Revue contradictoire de l'outillage : FAIL rendu, huit défauts corrigés dont deux bloquants (commentaire mensonger sur la sévérité ; `--entériner` qui gravait un rouge). Lot 1 : trois voies livrées en worktrees (24 commits + 2 sauvetages), inspection passe 1 faite, cueillette APRÈS l'enregistrement RC=0 sur le commit de clôture. Preuves : `evidence/world_v2/v2_3_r2b3_1/cloture/`. |
| **V2.3-A.R2B.3.1 — fermeture d'ISS-059 + points d'entrée ISS-063 + dossier léger** | **CAUSE NOMMÉE ET CORRIGÉE À LA SOURCE · SIGNATURE EFFONDRÉE · HARNESS ENCORE ROUGE → PARTIAL** — aucune géométrie touchée, verdict visuel toujours NON VÉRIFIÉ | Base `06b865b` après **une troisième recréation de conteneur** (fast-forward strictement additif). **ISS-059 — la chaîne causale est nommée, pas déduite** : ce ne sont pas des sous-ressources embarquées mais **trois variables `static` de GDScript sans propriétaire ni fin de vie** — `WorldV2PlaceKit._scene_cache` (89 `PackedScene`), `AssetRegistry._model_cache` (21), `WorldV2PlaceKit._material_cache` (98 matériaux dupliqués). `89 + 21 − 3 communes = **107**`, **exactement** le compte de la bissection ; la contre-épreuve a vérifié plus fort que la cardinalité — **différence symétrique VIDE** entre l'union des chemins des caches et l'ensemble des `PackedScene` fuitées. **Reproducteur réduit d'un facteur trois** : `WorldV2.tscn` SEULE porte la signature, en **22 s** au lieu de 97 ; `ResonancePylon.tscn` est innocente ; toute combinaison la contenant donne le même chiffre — allocation qui **sature**. **Ablation à variable unique** : `_material_cache` retire exactement 98 matériaux (sa taille) et zéro maillage ; les deux caches de scènes emportent **100 % des maillages** ; les cinq emportent **98,6 % des matériaux** (281 → 4, 214 → 0). **STABLE, PAS CUMULATIF** : deux cycles dans le même processus donnent `objets=2875 ressources=861` aux DEUX, à l'unité près. **Correctif à la source** : `liberer_caches()` sur onze porteurs, inscrite par `_static_init()` auprès de `StaticResourceCaches`, appelée par `SceneFlow._exit_tree()` — ce n'est pas la rétention qu'il fallait corriger (elle borne une fuite pire : `+27/cycle sans palier`), c'est son **absence de fin de vie**. Résultat : `DummyMaterial 281 → **0**`, `DummyMesh 214 → **0**`, `DummyTexture 65 → **0**`, `DummyShader 11 → **0**` ; ObjectDB 951 → 104. **Trois affirmations du dossier corrigées, deux étaient fausses** : les `static` GDScript ne sont PAS libérés avant le rapport ; le moteur n'imprime JAMAIS le `resource_path` d'une ressource (trois `if` qui écrasent la même variable dans `ObjectDB::cleanup()`), donc l'observation qui excluait les caches était un artefact ; `WorldV2Bootstrap` n'est pas un montage/démontage (`SceneFlow.go_to()`, la scène RESTE dans `root`, 3 858 nœuds contre 23). Les deux dernières viennent de la contre-épreuve, pas du lead. **Résidu restant, énuméré** : 55 `GDScript` + 45 `GDScriptNativeClass` (cache de scripts du moteur, absent du témoin et des suites du runner) + **un flux audio** `land_soft.wav` → **ISS-064 ouverte**. **ISS-063 — le correctif ne dépend plus du lanceur** : dette comptée AVANT (13 fichiers, 35 sites, **11 sans verrou ni cloison**), mécanisme unique `tools/lib/godot_env.sh`, **onze fichiers convertis** dont `validate_fast.sh` (ne se sérialisait avec RIEN), `.githooks/pre-push` (un moteur par `.gd` à chaque push) et `server.py` (démarré par `.mcp.json`, invisible à tout garde-fou de commande). Trois attentes distinctes justifiées sur place (5 s / 10 s / 7200 s). `/tmp/godot.lock`, le TROISIÈME verrou, retiré du dépôt et de `tools/CLAUDE.md`. **Deux invariants exécutables, cycle rouge d'abord tenu** : vert → sabotage → **ÉCHEC nommant le fichier** → restauration au sha256 → vert. Le prédicat de lancement est volontairement LARGE : sa première version exigeait un ` --` et **ratait `capture_ab.sh`** qui lance par tableau d'arguments — panne reproduite par la contre-épreuve. `CLAUDE.md` enseignait les quatre commandes NUES : corrigé. **DOSSIER LÉGER** : 4 planches JPEG dérivées des PNG, 1280 px, 563–707 Ko sous 900 000, recadrage littéralement identique des deux côtés, aucune retouche différentielle vérifiée **sur les pixels** (1,368 contre 1,353), 8 SHA recalculés, déterminisme confirmé. Deux défauts du contrôleur corrigés : garde-fou de poids réglé à 921 600 au lieu de 900 000, et pied de provenance à 0,68 % de hauteur porté à 1,10–1,45 %. **VALIDATE_FAST, une seule exécution à la fin : 949 tests réussis, 0 échoué, HARNESS ROUGE — et rapporté comme tel.** La signature de sortie s'effondre : `ObjectDB 1003 → 138 (−86 %)`, `resources 657 → 74 (−89 %)`, et **les lignes `DummyMaterial` (281), `DummyMesh` (214) et `DummyTexture` (67) DISPARAISSENT du rapport** — pas réduites, absentes. `DummyShader 14 → 3`. Cinq lignes de fin de processus maintiennent le rouge, dont deux `PagedAllocator` qui sont les `Variant` des objets survivants, pas une cause distincte. **Résidu ÉNUMÉRÉ SUR LA SUITE COMPLÈTE, plus déduit** : la passe laissait la composition des 138 inconnue et refusait de l'extrapoler ; elle a été **mesurée** (suite entière en `--verbose`, 949/0). 138 objets = 74 `GDScript` + 61 `GDScriptNativeClass` + 3 `Shader`, 74 ressources = 71 `.gd` + 3 `.gdshader`, et les 3 RID `DummyShader` sont ces mêmes 3 shaders — **la somme tombe juste au dernier objet, il ne reste ni matériau, ni maillage, ni texture, ni flux audio**. **UNE cause, pas deux** : charger une `.tscn` épingle ses `GDScript` et leurs `GDScriptNativeClass` — le cache de scripts du moteur, qu'aucune API GDScript ne purge ; les 3 shaders sont des constantes `preload()` de `hero_shot_lab.gd`, script lui-même épinglé, donc une **conséquence** des 135 autres. Le résidu est donc entièrement attribué au moteur, **plus aucun conteneur du projet n'y participe** — ce qui ne rend pas le harnais vert et n'est pas présenté comme tel. Le changement cosmétique `preload` → `load`, qui retirerait la ligne `DummyShader` sans rien rendre vert, est **refusé et argumenté** dans `iss059/RESIDU_SUITE_COMPLETE.md`. **Le seuil du filtre N1 n'a pas été touché.** **Aucune géométrie touchée** : `SM_Farm_Ruins.glb` reste `ead79105e3deaf70` octet pour octet. Preuves : `evidence/world_v2/v2_3_r2b3_1/`. |
| **V2.3-A.R2B.3 — micro-corrective des débris + ISS-059** | **FORME GAGNÉE ET MESURÉE DEUX FOIS · FUITE NON EXPLIQUÉE → passe close en PARTIAL** — NON VÉRIFIÉ visuellement, revue Codex/Istvan attendue | Base `291a621` après **deux recréations de conteneur** (fast-forward strictement additif, jamais de reset). **DÉBRIS** : liant de boîtitude **96,8 → 0,00 %**, indice de rectangularité **71,42 → 0,32 %** — `0,00 %` est la valeur des tas de gravats acceptés du kit, pas 24,9. Geste **structurel** : `eclat()` rend `k+k+1` sommets, `k ∈ [3;7]`, donc **toujours impair, jamais huit** ; relevé sur le maillage livré, **zéro composante à 8 sommets, zéro à 6 plans**. Neuf planchers tenus + deux nouveaux ; non-contamination des 12 autres meshes vérifiée au sha256 du flux de positions trié (Δemprise 0,00000) ; ferme 2 224/4 500 ; UV0 27/27 ; `gltf_inspect` VALIDE. **ISS-062 — deux trous, deux fermetures** : la **soudure** (18 pavés soudés par un coin rendaient 0,00 %) fermée par un **second instrument d'une autre famille**, invariant à la soudure ; puis le **bruit cohérent à 2 mm**, trouvé par l'audit adverse — il rendait **les dix contrôles verts sur une géométrie qui n'est que des boîtes**, avec une marge d'UN millimètre — fermé par un **second plafond indépendant sur `ortho` seule**, dérivé par la règle pré-enregistrée (M=4,80 → 52). Trois sabotages joués, trois restaurations byte-identiques. **ISS-063 — démontré et corrigé** : `user://` ne dérive pas du répertoire de travail, tous les arbres en partageaient un seul ; `XDG_DATA_HOME` par invocation dans `tools/lancer_godot.sh`, qui prend aussi le verrou du dépôt et **refuse `--filtre=`**. Suites rejouées SEULES : `world_v2` **99/0 RC=0** (contre 96/1 contaminé — l'échec `slot0` **disparaît**), `boss_arena` **11/0**, boot smoke 23 assertions, golden masters **6/6 avant et après**. **ISS-059 — signature effondrée, cause non atteinte** : `DummyMaterial` **4 849 → 281 (−94 %)**, ObjectDB 5 203 → 1 003, après correction d'une vraie fuite cumulative (`WorldV2PlaceKit` chargeait sans retenir : monde 334/536/738 → 334/334/334). Le résidu restant est **exactement** celui qu'une sonde reproduit en **97 s** hors de la suite — `281 · 14 · 214 · 67`, les quatre au chiffre près — et se localise entre la 71ᵉ et la 74ᵉ scène. **Manque : quel objet retient les `PackedScene`.** Sans causalité, pas de fermeture. **ABLATION** : plancher A/A à **0 pixel** sur 11 vues aux seuils 1/8/32 ; les deux tas dessinent **0,41 % à `ferme_orb090`, 0,02 % sur deux orbites, et EXACTEMENT RIEN sur `ferme_seuil`, `ferme_arriere` et `ferme_orb270`** — corriger `Debris_A/B` ne change presque pas l'image à distance normale, ce qui domine étant l'anneau de gravats voisin, **hors périmètre**. **Réserves portées à la revue** : le tas passe à **47 % de pierre** (il lisait « bois et tuile ») ; l'emprise gagne ~5 % ; le liant est **nécessaire, pas suffisant**. `validate_fast` : **947 tests verts, 0 échoué, harness ROUGE sur ISS-059 seul**. Preuves : `evidence/world_v2/v2_3_r2b3/`. |
| **V2.3-A.R2B.2 — fermeture visuelle ferme + arbre** | **MATIÈRE OBTENUE ET MESURÉE · UN LIANT DE FORME EN ÉCHEC → passe close en PARTIAL** — NON VÉRIFIÉ visuellement, revue Codex/Istvan attendue | 19 commits cherry-pickés de deux voies depuis `c44f430b` (A ferme, B arbre ; C = audit indépendant, zéro géométrie de production). Suite `world_v2` **95/95 RC=0** ; boot **23 assertions** RC=0 ; **golden masters 6/6** ; `gltf_inspect` VALIDE sur les deux GLB ; budgets ferme **2 080/4 500** et arbre **3 574/6 000**. **FERME — ce qui est obtenu** : UV0 dépliées **25/25 primitives** (0 avertissement `gltf_inspect` contre 23) ; textures du kit branchées au runtime, densité UV mesurée à **1,6 % du kit** sur la pierre ; tableaux rentrés (signe d'axe Y-up corrigé, ils saillaient de 42 cm DEVANT la façade) ; pignon descendu de 0,55 m dans le mur (recouvrement 0,06 → **0,61 m**) ; module nord-est RETIRÉ et remplacé par un arrachement en gradins ; **socle texturé par projection triplanaire monde** sans toucher au golden master `SM_Village_Wall` (0 UV0, gelé) — sa plus grande composante plate passe de **11,44 % (grise, invisible au portail) à 3,67 % (beige)** ; aplat `max` sur `ferme_seuil` **7,32 → 2,92 %**, les six vues sous 8. **Liant de densité d'aplat (part attribuée ÷ couverture écran, plafond 45 %) : `ferme_seuil` 69,3 → 5,7 %, `ferme_laterale` 62,5 → 0,0 % — VERT, et sous la densité du kit lui-même (34,4 %), aucun seuil relevé** ; les trois voies de contournement fermées chacune par son témoin (dilution : aplat 16,67 → 1,14 ; rétrécissement : couvertures 19,84 et 18,48, l'une MONTE ; suppression : anti-vacuité VERTE) et **coût d'ablation NÉGATIF (−2,79 · −3,18)** — les pièces ajoutées dessinent moins d'aplat que la maçonnerie qu'elles masquent, résultat qu'aucun contournement ne produit. **FERME — ce qui échoue** : `hexa` **79,6 %** contre un plafond de 25 (87,2 % avant, donc 7,6 points de progrès réel). Trois prédicats publiés — `hexa` 79,6 · équidistance **42,1** · `droite` 9,2. Localisation : la charpente est en pavés droits (juste — un bois est scié d'équerre), la maçonnerie en boîtes déformées (acceptable), **les débris `Debris_A/B` en pavés droits à 96,8 % — c'est le défaut**. **ARBRE** : 20 assertions vertes ; fourche **9,0° → 38,9°**, la caméra de silhouette voit 2,744 m d'écart (**100,3′ d'arc à 94 m**) là où les deux moitiés se superposaient ; cicatrice, CV lissé sur 3 stations **0,155 → 0,392** ; racines **4,52 m / 5,26 : 1 → 3,02 m / 3,33 : 1** et traversabilité **0,382 → 0,253 m** sous le `step_height` de 0,34 — défaut préexistant corrigé au passage. **Lisibilité à 94 m préservée (point 9) : remplissage 11,2/11,7 → 11,2/11,6 %, et le témoin du kit `CommonTree_1` est RIGOUREUSEMENT identique (27,2/27,5 → 27,2/27,5) — donc l'écart est lu dans le même repère** ; l'emprise, elle, a bougé (8,70 → 8,72 X, 8,48 → 8,46 Z) : la géométrie a changé sans que le remplissage change. **Résidus nommés** : `BranchA` garde une lecture de madrier sous l'angle rasant de `arbre_pied` ; l'arbre n'a **aucun UV0** (témoin publié, hors des neuf points de la directive). **ISS-059 corrigée en toute honnêteté** : l'audit indépendant a vérifié la structure (16 pièces, 4 matériaux, cache `static` borné) mais **REFUSE de confirmer le +100 sans instrumenter Godot** — l'explication « proportionnel au contenu ajouté » est donc rétrogradée en **hypothèse non recoupée**, le +100 reste **NON EXPLIQUÉ**, et seul le faisceau des quatre classes figées (239→239, 14→14, 42→42, 58→58) porte le constat — **ce n'est pas une preuve d'absence de régression**. Preuves : 15 caméras imposées **inchangées** (sha256 du plan vérifié, 15/15 identiques champ par champ), 19 vues d'orbite ajoutées, 6 triptyques `R2B / R2B.1 / R2B.2`, 2 planches en niveaux de gris, manifestes à `repo_dirty: false` portant le **sha256 des GLB capturés**. `evidence/world_v2/v2_3_r2b2/`. |

`GO_V2_3_B=FALSE` : aucune propagation aux 31 POI. `GO_V2_3_R2B=TRUE`
exécuté — les cinq lieux pilotes (camp checkpoint, camp braise, ferme,
arbre foudroyé, bassin) sont reconstruits ; les quatre golden masters
restent gelés.

**Règle de production changée (verdict R2a)** : un script de scène ne fabrique
plus la surface artistique finale sous forme d'assemblages de `BoxMesh`, de
plaques ou de fragments visibles. Il garde l'instanciation, l'implantation, les
interfaces fonctionnelles, les collisions simples et les variations contrôlées.
La peau vient de modules CC0 assemblés ou de meshes Blender à source conservée ;
les primitives sont réservées aux collisions, sondes et supports **invisibles**.

Le verdict ARTISTIQUE de V2.2 appartient à Codex, Istvan et son frère
(directive §17) — seuls les défauts techniques mesurables sont jugés ici ;
résidus consignés dans le README d'evidence.

## Finition visuelle monde entier (2026-08-12, `claude/full-world-visual-finish`)

| Lot | État | Preuve |
|---|---|---|
| 1 — relief/teintes tout le terrain | Fonctionnel | 22 buttes marchables, teintes en lobes organiques, tests relief 3/3, carte `evidence/full_visual_finish_20260812/` |
| 2 — masses boisées | Fonctionnel | 39 arbres à tronc-collision + sous-bois MultiMesh, navmesh re-cuite, dressing 10/10 |
| 3 — rivière pleine longueur + terrasse pylône | Fonctionnel | roseaux MultiMesh + talus, dressing 10/10 |
| 4 — POI harmonisés | Fonctionnel | toits village/hameaux en palette, crypte enterrée, falaise talutée ; captures avant/après |
| 5 — citadelle | Inchangée à dessein | D-052 : le kit Castle est au pas de 1 m, les masses de la citadelle font 10-50 m — l'habillage taluté de la passe 3 reste la bonne échelle |
| 6 — donjon (agent) | Fonctionnel | 8 espaces habillés, 10 GLB promus, 92 tests verts, captures intérieures |
| 7 — acteurs | Vérifié en capture | a1-a3 du jeu final de preuves |
| 8 — VFX | Réduit à l'existant | fumée du camp, orage, foudre déjà en place ; packs particules restés en quarantaine (aucun défaut ciblé à corriger) |
| 9 — UI (agent) | Fonctionnel | débordement 720p corrigé (775→642 px MESURÉS), 45 tests UI verts, 6 sons CC0 promus |

Verdict d'image : appartient à la revue indépendante de Codex, jamais auto-déclaré.


Vocabulaire imposé (§0.2) : `Non commencé` · `Implémenté` (raccordé) ·
`Fonctionnel` (testé en scène exécutable) · `Validé` (conforme, sans régression) ·
`Bloqué`. Tout critère non testé est `NON VÉRIFIÉ`, jamais implicitement réussi.

## Passe 3 — les six défauts de la revue Codex (2026-08-12, `claude/vslice-pass3-silhouettes`)

Base : `2c4fbf9` (merge PR #7), après verdict **ÉCHEC** du gate visuel
indépendant. Preuves : `evidence/vslice_pass3_20260812/` (README, tableau
défaut → cause → test rouge → correctif → APRÈS, baseline `avant/` et jeu
`final/` des six caméras).

| Défaut Codex | État | Preuve |
|---|---|---|
| Caméra 5 bouchée (RuinWall03 à 2,6 m de l'œil) | **Validé** | `test_no_gate_camera_has_a_static_wall_against_its_lens` rouge d'abord ; picking par rayon |
| Nuage-proxy (arche lisse, spire transperçante) | **Fonctionnel** | 22 grumeaux ≤ 22 m, plancher y ≥ 108, bord chaud ; la régression « enclume-soucoupe » attrapée à la recapture et le test élargi |
| Citadelle en masses rectangulaires | **Fonctionnel** | habillage taluté (piliers, coques, manchons) — `test_citadel_masses_wear_battered_cladding.gd` ; image à juger par Codex |
| Chemin en plaques/coutures | **Fonctionnel** | polygones irréguliers + anti-couture 4 mm ; 110 échecs de forme avant ; l'enroulement horaire attrapé à la recapture (leçon ISS-018) |
| Camp sans triangle | **Fonctionnel** | trois pôles testés par centroïdes (`test_camp_composes_three_activity_poles.gd`), 2 bannières, vide central |
| Mesas orange / répétitions triangulaires | **Fonctionnel** | gamme roche −⅓ désaturée, strates, rangs 4/7/6 ; **caméra 6 conforme §1.5 pour la première fois** (sol_p95 100 → 87,5) |
| Relief du corridor | **Fonctionnel** | 10 buttes marchables de flanc, navmesh re-cuites, parcours physiques rejoués ; le filet anti-enterrement a attrapé 3 fautes réelles ; ISS-045 (dalles) reste OUVERT |
| §1.5 sur les six caméras | **Fonctionnel** | jeu `final/` : 5/6 conformes ; caméra 5 en verdict non pertinent (bandeau haut sans ciel), reporté tel quel |
| Gate visuel de la tranche | **NON VÉRIFIÉ** | le verdict appartient à la seconde revue indépendante de Codex |

**Dernière mise à jour** : 2026-08-06 · **Phase** : Passe art « wahou » sur branche `claude/eclats-art-visual-pass-tyfhgc` — Lots 1-16 FAITS (tour du monde en images : 11 zones capturées + table de verdicts ; TOUTE la carte peinte 3768 surfaces ; citadelle en terrasses ; peinture du donjon tentée puis RETIRÉE sur mesure — AD-008) (v18 : grain procédural + SIX textures ambientCG CC0 déposées par le propriétaire, licences inscrites avant build et test qui le vérifie ; deux corrections de palette mesurées) (v15 : habillage aux 13 modèles Quaternius CC0 du dépôt + variante découpe du painterly pour les feuilles) (v13, éval fin de journée ≈ 71,5 UNVERIFIED < 75 — pas de V4 ; revue contradictoire consignée, corrections prouvées) : éval sévère v5 = 58/100 → AD-004 ; `SH_CharacterPainterly` trois pilotes 3/3 ; PREMIÈRE vidéo de stabilité §30.1 (18,1 s, Movie Maker fixed-fps, `herolab_v6_stabilite.webp`) — elle a révélé l'herbe FIGÉE, corrigée par `SH_FoliageWindPainterly` (sondes 0,00 → 1,6-2,0) ; Lot 4 : le lab ENTIER peint (`test_painterly_lab` — zéro surface mate nue, 3 émissifs justifiés), capture v8, bandes §1.5 intactes · **Gate A gelé** : `9414fd0` · **Commit courant** : voir `git log`

## Tranche verticale d'ouverture — lots A à D (2026-08-11, `claude/new-session-840w2o`)

Base : `6a996a5`, obtenue en fusionnant LOCALEMENT
`origin/claude/vertical-slice-opening-polish` dans la branche de session, qui
en était **13 commits en arrière**. Le SHA `c8fc1ab` annoncé par le prompt de
reprise n'existe dans aucune référence du dépôt. Détail : `PROGRESS.md`.

Preuves : `evidence/vertical_slice_20260811/` — six paires avant/après,
vignettes, niveaux de gris, manifestes et relevés.

| Élément | État | Preuve |
|---|---|---|
| Six caméras de gate NOMMÉES et rejouables | **Validé** | `ValleyWorld.GATE_CAMERA_NAMES`, `tools/capture_vslice_gate.sh` |
| Hiérarchie des valeurs §1.5 sur le chemin d'ouverture | **Fonctionnel** | `check_value_bands.py` : 1 caméra conforme sur 6 → **4 sur 6** |
| Trois plans distincts sur la vue d'ouverture | **Implémenté** | écart haut/milieu 1,9 → 5,3 points. Mieux orienté, pas encore franc |
| Rampe processionnelle repeinte en vert (55,5 % du cadre) | **Validé** | `test_ground_carriers_keep_their_material.gd`, contrôle négatif à 16 assertions rouges |
| Face sud du plateau lue comme un mur | **Fonctionnel** | falaise à trois rangs ; plus de plan plein sur les caméras 5 et 6 |
| Anneau montagneux en peigne | **Fonctionnel** | crêtes et jupes recouvrantes ; reste à juger par un œil externe |
| `prop.tent` / `prop.campfire` livrés et consommés | **Validé** | `AwningTent`, `CampfireProp`, `test_asset_pipeline.gd` |
| Colonne de fumée : voile et non pilier, ET visible de la crête | **Validé** | contraste mesuré +22,6 → +1,6 → **+39,7** |
| Terrain plat (96,8 % sous 5°) | **Non commencé** | intact depuis l'audit — aucun relief touché |
| Chemins « bandes posées » (22,2 % du cadre d'ouverture) | **Non commencé** | lot C non fait |
| Citadelle en empilement de boîtes | **Non commencé** | lot B non terminé |
| Débordement Options/Commandes à 720p | **Non commencé** | lot F non fait |
| Score North Star | **NON VÉRIFIÉ** | aucun évaluateur indépendant n'a noté ces captures |
| Trois joueurs boîte noire | **NON VÉRIFIÉ** | `tools/blackbox_player/` non lancé dans cette session |
| Suite complète après verrou anti-concurrence | **Validé** | 823/0, RC=0, un seul résumé — les 8 échecs étaient DEUX runners entrelacés (`validate_fast_VERT_823_apres_verrou.log`) |
| Caméra de descente désenterrée + sonde des six caméras | **Validé** | `test_gate_cameras_are_not_buried.gd`, contrôle négatif rouge |
| Citadelle : vides, brèche, courtines, terrasses talutées | **Fonctionnel** | `test_citadel_carries_voids_and_asymmetry.gd` rouge d'abord ; image finale à juger par Codex |
| Chemins en tronçons plaqués au sol | **Fonctionnel** | `test_paths_belong_to_the_ground.gd` (10 échecs mesurés avant) ; `final/02+05` |
| Talus des mesas, paroi d'escalade intacte | **Fonctionnel** | `test_mesas_wear_talus.gd` — l'exclusion de la paroi est testée |
| Matrice de traçabilité des 87 constats d'audit | **Validé** | `AUDIT_TRACEABILITY.csv` + `AUDIT_FILES_USED.md` |
| Gate « tranche verticale professionnelle » | **ÉCHEC** | voir `evidence/vertical_slice_20260811/README.md` §4 — verdict d'image et North Star : Codex |

## Tranche verticale d'ouverture — lot 1 (2026-08-10, `claude/vertical-slice-opening-polish`)

Base : `02d5212` (le build du playtest en cours), retenue après constat d'une
divergence — voir `PROGRESS.md`. Godot et Blender ont dû être installés dans le
conteneur avant toute mesure.

| Élément | État | Preuve |
|---|---|---|
| Plancher de référence, arbre propre | **Validé** | `validate_fast.sh` VERT RC=0, niveau 3b compris (Blender installé) |
| Capture de référence de la vue d'ouverture | **Fonctionnel** | `evidence/vslice/baseline/01_vista.png` + manifeste, arbre committé |
| Décor de la crête et de la descente posé au sol | **Validé** | `test_opening_dressing_rests_on_ground.gd` — ROUGE d'abord (28 pièces fautives sur 33, écarts nommés), VERT après |
| Effet visuel du correctif sur `VistaCamera_Hero01` | **NON VÉRIFIÉ** | la capture change très peu : le décor de la crête est majoritairement hors de ce cadrage. Le gain est ailleurs, et personne ne l'a encore vu à l'écran |
| Trois joueurs blackbox de l'Étape 1 | **Non commencé** | ≈ 100 min, séquentiels obligatoires |
| Composition, lisibilité, cadrage, guidage | **Non commencé** | aucun jugement de rendu n'est porté par cette session |

Ce lot corrige une **géométrie fausse**, pas une direction artistique. Il ne doit
pas être présenté comme une amélioration visuelle : c'est une condition
préalable pour que le décor déjà écrit existe à l'écran.

## Playtest du 2026-08-07 — les quatre réparations

Défauts pris dans l'ordre où le joueur les rencontre
(`evidence/blackbox_player/session_20260807_141313` : 74 min, 0 coffre,
0 ingrédient, donjon jamais atteint).

| Défaut | État | Preuve |
|---|---|---|
| 1. `E` ne produit jamais rien | **Validé** | La chaîne n'était PAS cassée : `tools/godot/diagnose_interaction.gd` → **55/55 atteignables** (53/55 avant correction). Le défaut était le SILENCE sur du décor. `test_interact_is_never_silent` 4/4 : refus annoncé, martèlement cadencé (≤ 3 messages pour 8 appuis), tous les ingrédients atteignables. Les deux fruits de la crête étaient enterrés de **8,00 m** (sondé) — les ramassables se posent désormais sur le sol réel |
| 2. L'arc ne tire jamais | **Validé** | `test_bow_fires_on_left_click` 2/2. Fail-first VÉRIFIÉ : sans le correctif le test reproduit le symptôme exact du joueur, compteur **« 8 → 8 »**. Hors visée le clic reste l'épée (cas de non-régression) |
| 3. Ni héros ni ennemis n'ont de tête | **Validé** | Les sources n'en contenaient AUCUNE (capuche seule ; rien au-dessus du cou pour les pillards). `test_characters_have_heads` 2/2 – 26 assertions : géométrie réelle (2 516 tris), os `Head` à la cote attendue, crâne de 0,167 à 0,223 m, échelle déduite du squelette |
| 4. Caméra dans le héros / sous le terrain | **Validé** | Cause lue dans `spring_arm_3d.cpp:196` (aucune distance minimale, `motion_delta` → 0). `test_camera_never_enters_the_hero` 3/3 : plancher tenu, héros redevenu opaque en reculant, zéro azimut sous le sol sur 12 au bord de la rivière |
| Sensibilité souris | **NON VÉRIFIÉ** | Bornes déclarées dans la scène et curseur système recentré quand la souris est rendue. Mais « au maximum par défaut » vient d'un testeur à souris SYNTHÉTIQUE (curseur qui bute au bord de l'écran — impossible avec une souris capturée sur une vraie machine). **Demande les mains du propriétaire**, pas un test |

## Prompt 2 — état (cadence, `ROADMAP.md`)

| Jalon | État | Preuve |
|---|---|---|
| P2-0 audit | **Fait** | `PROMPT2_AUDIT.md`, golden path 4/4 (2026-08-05) |
| P2-1 latence + labs | **Fonctionnel** | `test_p2_latency.gd` 2/2 : ≤ 1 tick via chaîne réelle ; `LabOverlay` ; D-047/D-048 |
| P2-2 Bracelet | **Fonctionnel** (cœur) | LES CINQ opérations fail-first : lois 6/6, profils 2/2, Pulse 5/5, Arc Link 6/6, Polarité 5/5, Arc Step 5/5, Ground 3/3. **Focus/sélection JOUABLE** : `test_resonance_focus` 6/6 (axe de visée, hystérésis, dispatch par nature de cible, épée verrouillée en focus) + Ground direct (T). `ResonanceLab` jouable (1/1, retours visuels par états). Liens éphémères par design (D-049). **P2-2 : TERMINÉ hors présentation** (VFX/audio → passe visuelle Cycle 3) |
| P2-3 défense expressive | **En cours** | tranche 1 : garde/déviation parfaite/GuardBreak/Clarity 4/4 fail-first (`test_guard_deflect`) via `damage_gate` générique de la hurtbox ; **posture** faite : `PostureComponent` partagé 3/3 (rupture unique, recharge, `posture_damage` de bout en bout, Briseur migré sans régression, parade→posture si portée) ; **identités d'armes** faites : 5 lourdes de famille en data 2/2-45 assertions (gourdin projette, hache brise 12, lame électrique, épée +0,04 s de fenêtre, lance porte), la lourde suit l'arme équipée ; **utility explicable** fait : `UtilityBrain` (trace top-3 + raisons) 2/2, azur refactoré à comportement identique (22/22 raiders verts) ; tokens déjà conformes §12.8 ; **camp 3 approches** fait 2/2 : diversion par Pulse prouvée systémique (jamais ALERT sans voir), caisse métallique chargeable par campement (Polarité/Ground). **P2-3 : TERMINÉ** |
| P2-4 exploration | **Fait** | POI Bracelet 1/3 : autel de terre 2/2 (cœur pré-chargé au sanctuaire, Ground → stèle s'allume, recharge lente ré-arme) ; **pont magnétique** 2/2 (composant autonome : repousser → verrouillage/alignement/portance, définitif par mise à la terre ; placement vallée après sonde de terrain) ; correctif `charge_decay_enabled` (les cœurs de POI attendent le joueur) ; pont PLACÉ (site sondé −34/3/44, 32ᵉ lieu, ancre PUZZLE saine 33/33) ; **bassin conducteur** fait 3/3 (UN Arc Link source→eau traverse l'eau et allume le récepteur, dissolution rend tout ; 33ᵉ lieu, site sondé 16/2/28) ; **Fragments** faits 4/4 (Écho trace directionnelle sans auto-bruit, Flux +15 endurance sur terre ≥ 2 avec cooldown 10 s, Élan 35 % d'élan borné à la course). éclats POSÉS aux trois écoles (17 assertions) + persistance save (`fragments` + suppression au chargement). **P2-4 : TERMINÉ** |
| P2-5 lois communes | **En cours** | tranche 1 : **BossDirector** (P2 §10.5) fail-first 5/5 (122 assertions) — bibliothèque taguée (portée/phases/cooldown/poids), légalité seule éligible, anti-répétition si alternative, seed consignée et rejouable (seed 42 = même séquence ×15), historique ; StormGuardian migré (le `randf()` pur remplacé, cadences historiques 2,2/1,7 et 3,4/2,6 conservées, `director_seed` exporté) ; suites boss 38/38 post-intégration. tranche 2 : **posture du boss** (P2 §10.2) fail-first 0/11→5/5 (22 assertions) — le Gardien porte le `PostureComponent` PARTAGÉ (max 36 = 3 lourdes de hache), rupture = noyau nu 3,5 s < 6 s de la terre, intention brise-garde seule nourrit, éveil/fenêtre ouverte exclus, terre remet à neuf ; boss 43/43, playthrough inchangé. tranche 3 : **l'eau du donjon parle les lois** (P2 §4.2/§9.2) fail-first 1/10→6/6 — la nappe `WATER_ZONE` porte la matière `eau` + arbitre garanti, mouille ce qui entre (tension ou pas), relaie l'électricité à la matière baignée (métal chargé au couplage humide, bois jamais), terre = relais suspendu, chemin de dégâts §13.5 INTACT (test-gardien vert avant ET après), planche salle 4 = bois ; salles 44/44, réactions 7/7, donjon 2/2. tranche 4 : **hints gradués** (P2 §9.8) fail-first rouge→5/5 (19 assertions) — `PuzzleHintTracker` partagé, 3 échecs OBSERVÉS → la loi, 6 → la cause, 9 → la relation, le temps seul n'ouvre RIEN, salle résolue = silence ; branché aux échecs RÉELS des quatre salles (reset pressé, hors-limites, décharge subie) via `install_hints`, textes par salle. Solveur : hérité Gate F (preuve 256 configurations salle 3 + 4 salles solvables). **P2-5 : TERMINÉ — revue contradictoire PASS** (5 critères PASS, 7 faiblesses non bloquantes → ISS-028 à 031) |
| Cycle 3 — V2 HeroShotLab | **En cours** | tranche 1 : lab CONSTRUIT (le manque nommé par la revue Gate H) — 5/5 fail-first (41 assertions) : éléments §11.1 présents, caméra §3.1 (FOV 44° vertical = 71,4° horizontal), fenêtres §1.1 par projection directe (héros 41,6 % X, camp 63,5 %, pylône 77 %, citadelle 50,5 %), rivière en S (2 inflexions — correction #3), trois plans réels (90/105/316 m). Captures v0→v1→v2→v3 consignées (`evidence/cycle3/`, arbres committés) : 6 défauts v0 corrigés (cause racine : le bord de plateau occultait la vallée → pente continue 8°) ; v2 = éclair majeur TENU (§21.5), phrases d'herbe §7.4 + fleurs, horizon montagneux ; v3 = passe de VALEURS §1.5 sur verdict du test en gris §30.1 (rivière à berges lisible hors couleur, citadelle 35-60 %, brouillard au point d'équilibre 0,0022). Contrat 5/5 maintenu à chaque itération ; score /100 réservé à la machine utilisateur. **Passe art 2026-08-06** : v4-v5 (5 signes du héros, planche silhouettes §30.3), éval sévère v5 = **58/100 `UNVERIFIED`** → AD-004 (itérer avant V4) ; v6 = **`SH_CharacterPainterly` Fonctionnel** (`test_painterly_pilot` 3/3 - 28 assertions, trois pilotes : rocher/touffe/héros, texture d'albedo conservée, ramps adoucies contractuelles ; bandes §1.5 intactes — `2026-08-06_herolab_v6.md`) |
| Validation du 2026-08-05 | tranches | dernier passage complet : **745/745** (arbre `980612c`, passe art Lots 1-16 — commit publié dans la release jouable `playtest-95dd423`) ; revue P2-5 : PASS ; les deux intermittences save-roundtrip de la veille sont CLASSÉES (ISS-024, environnementales — vertes en isolation ET dans deux suites intégrales) — voir `TEST_REPORT.md` |

## Verdict Gate A : **ACCEPTÉ AVEC RÉSERVE / BLOQUÉ SUR LA VALIDATION MANETTE**

Décision du propriétaire, 2026-08-01 (D-012). **Ce n'est pas un `PASS`** : §23.1
exige « clavier AZERTY **et** manette fonctionnels », et la manette n'a pas été
testée. La Phase B est autorisée à démarrer, la dette est portée explicitement.

Le nombre de tests de référence est publié dans `docs/TEST_REPORT.md` — il ne doit
pas être recopié ailleurs, sous peine de diverger (défaut relevé par le test de
reprise).

Protocole prêt à exécuter : **`docs/MANUAL_VALIDATION.md`**, outillé par
`tools/manual_validation_kit.sh` et `scenes/tests/InputAudit.tscn`.
Procédure opérateur macOS : **`docs/MANUAL_GATE_A.md`**.

| Étape de validation manuelle | État |
|---|---|
| 1. Lancement sur machine avec écran | **PASS** *(déclaré, sans capture)* |
| 2. Clavier AZERTY réel, `Q` = gauche | **PASS** *(déclaré, sans capture)* |
| 3. Manette | **BLOQUÉ** — aucune manette ; dette **CONTROLLER-001** |
| 4. Lisibilité et focus du MainMenu | **PASS** *(déclaré, sans capture)* |
| 5. Reprise depuis une session neuve | **PASS** — 1 min 12 s, `evidence/gateA/05_reprise.md` |
| 6. Archivage des preuves | partiel — rapport et reprise archivés, captures absentes |

`tools/manual_validation_kit.sh --finalize` sort toujours en **3 (BLOQUÉ)** : les
captures d'écran manquent. C'est cohérent — le manifeste ne certifie pas ce qu'il
n'a pas vu.

## Verdict Gate C : **ACCEPTÉ POUR CONTINUATION AVEC VALIDATION HUMAINE DIFFÉRÉE** (D-024)

Décision du propriétaire, 2026-08-01, sur revue contradictoire à passe unique
(`evidence/gateC/REVUE.md`, code jugé `78f2b9a`) : les quatre critères du Gate C
— combat gagnable, une touche par swing, aucune référence invalide, esquive avec
i-frames — sont **PASS au volet automatique**, rejoués par le réviseur
(validate_fast VERT RC=0, import propre, 75 scripts parsés, 0 chemin `res://`
manquant). Constat majeur D1 (S2) : **la mort du joueur n'existait pas** —
corrigée le jour même (`Mode.DEAD`, pillard qui lâche le cadavre) avec
régression rejouant la sonde du réviseur (`test_player_death.gd`) ; D3 corrigé ;
D2 (lignes `RC=` des logs W/X/Y) annoté sans régénération. Ce verdict n'est PAS
un `PASS` : ressenti, manette et AZERTY physiques restent dus à la passe finale.
Reste de la Phase C consigné : checkpoint/retry après la mort (Phase E),
hit-stop/VFX/sons (§10.7), durabilité de l'arc en tirs.

## Verdict Gate B : **ACCEPTÉ POUR CONTINUATION / VALIDATION HUMAINE FINALE DIFFÉRÉE** (D-021)

Décision du propriétaire, 2026-08-01, sur revue contradictoire rendue : les essais
manuels (manette comprise) sont reportés à la **passe finale** et ne bloquent pas
la poursuite ; les limitations GPU ne bloquent pas le Gate B. La revue n'avait
démontré **aucun défaut bloquant** ; ses constats non bloquants étaient déjà tous
traités. **Ce n'est pas un `PASS`** : dettes VALIDATION-B-001 et CONTROLLER-001
ouvertes, à solder avant toute déclaration `Final`. La Phase C est autorisée.

### Historique du verdict — revue du 2026-08-01

Revue à contexte frais rendue et archivée : `evidence/gateB/REVUE.md`. **Aucun
`FAIL`** — huit critères `PASS` par ré-exécution indépendante (clone frais
compris), mais le verdict global est le plus faible des onze : jitter et essais
humains `NON VÉRIFIÉ` (protocole prêt, pas joué), manette `BLOQUÉ`
(CONTROLLER-001). Les six constats de la revue sont **traités le jour même** :
deux trous de couverture fermés (fenêtres de saut, dérive du `.tres`), un
contre-exemple corrigé (marche abordée en diagonale, D-020 amendée), convention
`RC=` appliquée aux logs, compte de contrôles retiré de PROGRESS, deux questions
de design consignées (R-012, R-013).

**Le volet automatique est clos.** La suite : six essais humains
(`docs/MANUAL_VALIDATION.md`, section Gate B), et décision du propriétaire pour
la Phase C.

## Verdict Gate 0 : **GELÉ / ACCEPTÉ AVEC RÉSERVES** (décision propriétaire, D-006)

Ce n'est **pas** un `PASS` : aucune des quatre revues adverses ne l'a prononcé.
Les critères 3, 4 et 5 sont `PASS`. Le critère 1 reste `NON VÉRIFIÉ` (vérifié par
relecture, pas par une session réellement repartie de zéro). Le critère 2 a vu tous
ses défauts bloquants corrigés et couverts par 18 contrôles négatifs rejoués, sans
qu'une revue l'ait pour autant validé. Réserves détaillées : D-006.

---

## Résumé en une ligne

Le système de continuité et le pipeline d'assets sont en place et **vérifiés par
exécution réelle** — Blender → glTF → import Godot → renderer → PNG. Godot 4.7.1
tourne, `validate_fast.sh` est vert (nombre de tests : voir `docs/TEST_REPORT.md`,
seule source à jour). Le premier gameplay existe : **un joueur se déplace, saute,
sprinte et grimpe une pente, caméra à l'épaule qui ne traverse pas les murs**
(B.1), son sprint est limité par l'endurance de §9.1 (B.2), il grimpe les parois
puis franchit les rebords (B.3), et un parcours enchaîné — marche, pente, saut
par-dessus un vide, escalade, franchissement — est joué de bout en bout par un
pilote scripté sans triche (B.4). La latence intention → mouvement est
**instrumentée et mesurée à 1 tick** (B.5), et le protocole d'essais humains du
Gate B est prêt à jouer. Il n'a ni animation, ni modèle. La notation
visuelle et les mesures de performance restent impossibles ici : rendu logiciel
llvmpipe uniquement, aucun GPU.

---

## Phase 0 — Initialisation

| # | Élément | État | Preuve | Dernier test |
|---|---|---|---|---|
| 0.1 | Inspection dépôt, outils, versions, réseau | **Validé** | `evidence/gate0/env_report.txt`, `docs/BUILD_ENVIRONMENT.md` | 2026-07-31 |
| 0.1 | Vérification de l'image de référence | **NON VÉRIFIÉ** | analyse dans `docs/ART_BIBLE.md` §1.1, mais l'image n'est pas versionnée (ISS-003) : une session neuve ne peut ni la rejouer ni la contredire | 2026-07-31 |
| 0.2 | Système de continuité (§0.3) | **Validé** | 12 artefacts présents, voir tableau ci-dessous | 2026-07-31 |
| 0.3 | Commandes de parse/test/capture | **Fonctionnel** (contrôles négatifs T-10 ; T-08 a été partiellement rétracté) | `tools/validate_fast.sh`, `test_runner.gd`, `capture_reference.gd` | 2026-07-31 |
| 0.3 | Scène laboratoire de pipeline | **Fonctionnel** | `scenes/tests/PipelineLab.tscn` capturée depuis le renderer | 2026-07-31 |
| 0.3 | Laboratoires de look-dev (§7.16) | **Non commencé** | reportés en Phase C.5 : sans contenu à juger, ce seraient des coquilles | — |
| 0.3 | Journal de recherche | **Validé** | `docs/RESEARCH_LEDGER.md`, 5 entrées sourcées | 2026-07-31 |
| 0.4 | Godot 4.7.1 vérifié | **Validé** | `evidence/gate0/env_report.txt` : `4.7.1.stable.custom_build.a13da4feb` | 2026-07-31 |
| 0.4 | Renderer Forward+ configuré | **Validé** | relu au runtime : `[boot] renderer : forward_plus` | 2026-07-31 |
| 0.4 | Jolt configuré | **Validé** | relu au runtime : `[boot] physique 3D : Jolt Physics` | 2026-07-31 |
| 0.4 | Blender / glTF vérifiés | **Validé** | `evidence/gate0/pipeline_blender_gltf.log` | 2026-07-31 |
| 0.5 | Import cube + matériau | **Fonctionnel** | `test_gltf_import.gd` : 1 m, base Y≈0, matériau résolu | 2026-07-31 |
| 0.5 | Import rig + clip animé | **Fonctionnel** | `test_gltf_import.gd` : 2 os, `AN_TestRig_Idle` | 2026-07-31 |
| 0.6 | Risques classés | **Validé** | `docs/RISKS.md` : 9 risques, gravité, probabilité, plan et signal d'alerte | 2026-07-31 |

### Artefacts de continuité exigés par §0.3

| Artefact | Présent | Contenu réel |
|---|---|---|
| `docs/MASTER_SPEC.md` | ✅ | 2358 lignes, cahier des charges intégral |
| `CLAUDE.md` | ✅ | < 150 lignes, importe MASTER_SPEC |
| `docs/ROADMAP.md` | ✅ | 12 phases, dépendances, critères de sortie |
| `docs/STATUS.md` | ✅ | ce fichier |
| `docs/PROGRESS.md` | ✅ | journal + handoff |
| `docs/DECISIONS.md` | ✅ | décisions avec alternatives rejetées (D-001…) |
| `docs/RESEARCH_LEDGER.md` | ✅ | 5 entrées + 5 questions ouvertes |
| `docs/KNOWN_ISSUES.md` | ✅ | ISS-001…ISS-005 ouverts + dette CONTROLLER-001 |
| `docs/TEST_REPORT.md` | ✅ | résultats et commandes exactes |
| `docs/PERFORMANCE.md` | ✅ | protocole ; aucune mesure (assumé) |
| `docs/ART_BIBLE.md` | ✅ | North Star analysée, palette, budgets |
| `ATTRIBUTIONS.md` | ✅ | 4 ressources, toutes générées par le projet |
| `evidence/` | ✅ | `evidence/gate0/` |

---

## Phases A à J — vue d'ensemble

| Phase | Système | État |
|---|---|---|
| A | Boot, autoloads, InputMap AZERTY, couches de collision | **A.1 et A.2 livrés et gelés (`9414fd0`)** ; Gate A **EN ATTENTE** de validation humaine |
| B | Player, caméra, locomotion, endurance, escalade, mantle | **Clos par D-021 : accepté pour continuation** — volet automatique vert (137 tests), dettes VALIDATION-B-001 + CONTROLLER-001 à la passe finale |
| C | Santé, hitbox, combo, esquive, lock-on, arc, durabilité | **Clos par D-024 : accepté pour continuation** — 4 critères PASS rejoués en revue, D1 (mort du joueur) corrigé + régression, dettes humaines à la passe finale |
| C.5 | `HeroShotLab`, première composition North Star | Non commencé — notation WOW bloquée (voir ISS-002) |
| D | Terrain 512 m, camp, rivière, pylône, citadelle, coffres, CINQ familles ennemies | **ACCEPTÉ POUR CONTINUATION — VALIDATION HUMAINE DIFFÉRÉE** (`docs/GATE_D_AUDIT.md`, passe 2) : items 16/17/19 PASS, 18 PARTIEL (4 coffres sur 8, solde en Phase F, documenté), 20 PASS automatique sans essai humain. Les cinq familles de §12 existent, diffèrent par stats/arme/portée/carrure/comportement et sont testées (107 assertions transverses + 47 par famille) |
| E | Récolte, cuisine, buffs, sauvegarde et migrations | **ACCEPTÉ POUR CONTINUATION — VALIDATION HUMAINE DIFFÉRÉE** (`docs/GATE_E_AUDIT.md`) : les huit items §22 Phase E PASS sur preuves rejouées, chaîne complète récolte→cuisine→buff→save/load testée de bout en bout. Non couvert : animation de cuisson (Phase H) et essai humain |
| F | Graphe électrique, 4 salles, salle centrale, antichambre | **ACCEPTÉ POUR CONTINUATION — VALIDATION HUMAINE DIFFÉRÉE** (`docs/GATE_F_AUDIT.md`) : F.1 à F.8 livrés ; donjon résolu de bout en bout depuis une sauvegarde vierge ET une sauvegarde intermédiaire |
| G | Arène, boss 3 phases, solvabilité, victoire | **ACCEPTÉ POUR CONTINUATION — VALIDATION HUMAINE DIFFÉRÉE** (`docs/GATE_G_AUDIT.md`) : items §16 automatisables PASS, run boss joué de bout en bout ; « 25-40 min » NON VÉRIFIÉ faute de joueur. Ligne corrigée le 2026-08-05 — elle contredisait ROADMAP et l'audit (relevé par la revue contradictoire) |
| H | Art « wahou », WOW Gate ≥ 85/100 | **FAIL — revue contradictoire du 2026-08-05** (contexte frais, `TEST_REPORT.md`) : North Star prouvée ≈ 31-41/100 (l'auto-évaluation ≈ 56 était trop généreuse de 15-25 pts), 2 des 5 captures de gate aveugles, chemin critique en placeholders assumés, HeroShotLab jamais construit. Vice de forme corrigé : la capture précédait H-7c — recapture depuis HEAD au commit suivant. Cinq corrections ordonnées adoptées (lumière, cadrages, rivière, camp dans le cadre, éclair à cœur blanc + vidéo). Le solde relève des cycles 3-4 de la cadence (`ROADMAP.md`) |
| I | LOD, profilage, presets, exports, session 60 min | **Partiel** — volet EXPORT prouvé (2026-08-04) : preset `Linux x86_64` versionné, templates compilés depuis `/opt/src/godot`, binaire local 371 Mo qui répond `--version`, et Release CI `playtest-3038fc5` avec binaire autonome exporté par le runner (Godot 4.7.1-stable officiel). Profilage GPU et session 60 min restent **Bloqués** — ISS-002 |
| J | DemoRoute, vidéo 3 min, revue externe | **Bloqué** — ISS-002 |

Les phases A à G restent **entièrement réalisables** dans cet environnement : elles
ne dépendent pas du rendu, seulement de l'exécution headless.

---

## Phase A — jalons A.1 et A.2

| Élément | État | Preuve | Dernier test |
|---|---|---|---|
| InputMap AZERTY, 18 actions (§8.5) | **Fonctionnel** | `test_input_map.gd` : Q = gauche, lock-on jamais sur Q | 2026-08-01 |
| 14 couches de collision nommées (§5.7) | **Fonctionnel** | `test_input_map.gd::test_collision_layers_are_named` | 2026-08-01 |
| 5 autoloads (§5.6) | **Fonctionnel** | `test_autoloads.gd`, 9 cas | 2026-08-01 |
| Écriture atomique de sauvegarde (§19.2) | **Fonctionnel** | `test_save_system.gd`, 6 cas | 2026-08-01 |
| Boot réel (§6.1) | **Fonctionnel** | lancé réellement, sortie `[boot]` dans `validate_fast` niveau 3 | 2026-08-01 |
| Menu principal (§17.3) | **Fonctionnel** | `test_main_menu.gd`, 8 cas : cycle de focus, boutons désactivés non focalisables, confirmation d'écrasement | 2026-08-01 |
| Transition Boot → MainMenu (§6.1) | **Fonctionnel** | `validate_fast` niveau 3 : lancement réel sur 90 frames, trace d'arrivée exigée | 2026-08-01 |
| Simulation physique Jolt (§5.3) | **Fonctionnel** | `test_physics_simulation.gd` : chute de 4 m, arrêt à 0,5 m, stabilisation | 2026-08-01 |
| Masques de collision par entité | Non commencé | aucune entité n'existe encore | — |
| Apparence et lisibilité du menu | **NON VÉRIFIÉ** | exige un écran ; seule la structure est testable ici | — |
| `InputAudit` + entrée debug du menu | **Fonctionnel** | `test_input_audit.gd` (4 cas) et `test_main_menu.gd` (entrée debug absente hors développement) | 2026-08-01 |
| Protocole de validation manuelle | **Implémenté** | `docs/MANUAL_VALIDATION.md` + `tools/manual_validation_kit.sh` (mode `--finalize` sort en 3 tant qu'il manque une preuve) | 2026-08-01 |

**Reste avant Gate A** : les six étapes de `docs/MANUAL_VALIDATION.md`, toutes
hors de portée de ce conteneur. Le protocole est écrit, outillé et exécutable par
une personne disposant du matériel ; il n'attend plus que d'être joué.

---

## Phase B — jalon B.0 : couche d'entrée

Livré **avant** tout code de joueur, et volontairement : la Phase B se développe
au clavier alors que la manette n'est pas testée (CONTROLLER-001). Sans cette
séparation, du gameplay finirait par supposer un clavier et la dette deviendrait
impayable sans réécriture.

| Élément | État | Preuve |
|---|---|---|
| `InputIntent` — intention typée, ignorante du périphérique | **Fonctionnel** | `test_input_layer_isolation.gd` |
| `PlayerInputReader` — seul lecteur de l'InputMap | **Fonctionnel** | idem |
| Actions caméra manette (`look_*`, stick droit) | **Fonctionnel** | sans elles, la caméra n'aurait été pilotable qu'à la souris |
| Générateur d'InputMap autoritatif (retire les actions inconnues) | **Fonctionnel** | contrôle négatif `B1_action_sans_liaison_manette.log` |
| Les 4 contraintes de D-012 vérifiées par test | **Fonctionnel** | 2 contrôles négatifs archivés |

---

## Phase B — jalon B.1 : Player, CameraRig, locomotion

Tous les cas ci-dessous pilotent le contrôleur par `InputIntent` **injectée** :
aucune touche n'est simulée, aucun périphérique n'est requis. C'est le bénéfice
direct de D-013, et la raison pour laquelle B.1 est vérifiable ici malgré
CONTROLLER-001.

| Élément (§) | État | Preuve |
|---|---|---|
| `PlayerController` en `CharacterBody3D` (§6.2, §8.2) | **Fonctionnel** | `test_locomotion.gd`, 12 cas |
| Marche / course / sprint pilotés par l'amplitude (§8.2) | **Fonctionnel** | 3 cas : 3,5 / 6,0 / 9,0 m/s mesurés |
| Déplacement caméra-relatif (§8.2) | **Fonctionnel** | `test_movement_is_camera_relative` : écart de direction mesuré après un quart de tour |
| Saut, apex ≈ 1,40 m (§8.2) | **Fonctionnel** | `test_jump_reaches_expected_apex` |
| Coyote time 0,12 s et jump buffer 0,12 s (§8.2) | **Fonctionnel** | 2 cas |
| Pente franchissable à 40°, refusée à 60° (§8.2) | **Fonctionnel** | 2 cas, dont la contre-épreuve |
| Corps à rotation nulle, seul `VisualRoot` s'oriente | **Fonctionnel** | `test_body_never_rotates` |
| `CameraRig` : pivots + `SpringArm3D`, `Camera3D` enfant direct (§8.3) | **Fonctionnel** | `test_camera_rig.gd`, 9 cas |
| Anti-traversée de mur (§23.1) | **Fonctionnel** | bras raccourci **et** dégagement mesuré devant la face |
| Butées de pitch −65°/+45° (§8.3) | **Fonctionnel** | `test_pitch_is_clamped_to_the_specified_range` |
| FOV sprint sans snap, interpolation framerate-independent (§8.3) | **Fonctionnel** | 2 cas, dont une comparaison 60 Hz / 120 Hz |
| Réglages dans une `Resource` de `resources/tuning/` (§5.4) | **Fonctionnel** | `locomotion_default.tres`, enveloppes §8.3 vérifiées par test |
| **Endurance (§9.1)** | **Fonctionnel** — voir jalon B.2 | `test_stamina.gd` (15 cas) et `test_locomotion.gd` (5 cas) |
| Escalade et mantle (§9.2, §9.3) | **Fonctionnel** — voir jalon B.3 | `test_climbing.gd` (14 cas), `test_action_alignment.gd` (9 cas) |
| Dégâts de chute (§8.2) | **Non commencé** | le signal `landed(impact_speed)` existe et porte déjà la vitesse d'impact |
| Ressenti, latence en ticks (§10.6) | **NON VÉRIFIÉ** | exige un essai humain à framerate réel ; aucun équivalent automatique |
| Absence de jitter caméra (§8.3) | **NON VÉRIFIÉ** | la traversée est testable ici, le jitter demande une observation en mouvement |

---

## Phase B — jalon B.2 : endurance

`StaminaComponent` est un composant (§5.8), pas une branche du contrôleur : le
sprint le consomme dès maintenant, l'escalade (§9.2), l'esquive et l'attaque lourde
(§10.2) s'y brancheront sans le modifier.

| Élément (§9.1) | État | Preuve |
|---|---|---|
| Réserve de 100, jamais hors bornes | **Fonctionnel** | `test_stamina.gd`, 3 cas |
| Sprint à 12/s, câblé au contrôleur | **Fonctionnel** | `test_sprint_drains_stamina` — mesuré via le joueur réel |
| Sprint immobile gratuit | **Fonctionnel** | `test_holding_sprint_while_standing_still_costs_nothing` |
| Course sans coût | **Fonctionnel** | `test_running_without_sprinting_costs_nothing` |
| **À zéro : sprint → course** | **Fonctionnel** | `test_exhaustion_drops_the_sprint_back_to_running` — vitesse mesurée, pas jauge |
| Régénération après 1 s, à 22/s | **Fonctionnel** | 3 cas |
| Reprise progressive sur 0,20 s | **Fonctionnel** | `test_regeneration_ramps_in_instead_of_snapping` |
| Verrou d'épuisement de 0,45 s | **Fonctionnel** | 2 cas, dont celui qui documente qu'il est masqué par le délai de régénération |
| Seuil de récupération (hors §9.1) | **Fonctionnel** | `test_a_held_sprint_produces_usable_bursts_not_a_stutter` — défaut réel corrigé, D-016 |
| Coût d'esquive et d'attaque lourde | **Implémenté**, non consommé | déclarés dans le `.tres` ; la Phase C les câblera. Un coût déclaré n'est pas une fonctionnalité |
| Coûts d'escalade (18/s, 16/s, 20) | **Fonctionnel** depuis B.3 | `test_climbing.gd` : escalade et saut d'escalade mesurés |
| Jauge contextuelle près du héros (§17.2) | **Non commencé** | les signaux `changed` / `exhausted` / `recovered` sont émis et attendent l'UI |
| Souffle et animation d'épuisement (§9.1, §18.2) | **Non commencé** | aucun périphérique audio ici (ISS-004) ; aucune animation avant la Phase H |

---

## Phase B — jalon B.3 : escalade et mantle

Trois composants (§5.8), aucun n'appartenant au contrôleur : les sondes répondent,
le contrôleur décide. `ActionAlignmentComponent` est celui de §7.12 — il servira
aussi aux coffres, à la cuisine et au pylône.

| Élément | État | Preuve |
|---|---|---|
| Trois sondes tête / torse / pieds (§9.2) | **Fonctionnel** | `test_climbing.gd`, refus nommés |
| Accroche en poussant vers la paroi (D-017) | **Fonctionnel** | `test_pushing_into_a_wall_grabs_it` |
| Refus des groupes interdits (§9.2) | **Fonctionnel** | `test_an_unclimbable_surface_is_refused` — géométrie identique, seul le groupe change |
| Refus des surplombs (§9.2 : « vides/concavités ») | **Fonctionnel** | `test_an_overhang_is_refused` |
| Filtre d'angle de paroi | **Fonctionnel** | `test_the_angle_filter_rejects_a_surface_below_the_threshold` |
| Aucune bande d'angles ni marchable ni escaladable (D-019) | **Fonctionnel** | `test_no_angle_is_both_unwalkable_and_unclimbable` |
| Montée à 2,0 m/s (§9.2) | **Fonctionnel** | `test_climbing_rises_at_the_declared_speed` |
| Coût d'escalade 18/s (§9.1) | **Fonctionnel** | `test_climbing_drains_stamina` |
| À zéro : lâcher du mur (§9.1) | **Fonctionnel** | `test_exhaustion_releases_the_wall`, raison `exhausted` |
| Saut d'escalade : 0,9 m, 20 d'endurance (§9.2, §9.1) | **Fonctionnel** | `test_climb_jump_costs_stamina_and_pushes_off` |
| Lissage de la normale (§9.2) | **Implémenté** | code présent et framerate-independent ; **aucun test** — il faudrait une paroi irrégulière que le bac à sable n'a pas |
| Franchissement d'un rebord (§9.3) | **Fonctionnel** | `test_reaching_a_ledge_mantles_onto_it` |
| Ascension de 4 m conclue par un franchissement | **Fonctionnel** | `test_climbing_a_tall_wall_ends_in_a_mantle` — l'enchaînement complet |
| Refus sous plafond (§9.3, §21.4) | **Fonctionnel** | `test_a_ledge_under_a_ceiling_refuses_the_mantle`, raison `blocked` |
| Correction plafonnée, aucun snap (§7.12, §9.3) | **Fonctionnel** | `test_action_alignment.gd` : plus grand pas mesuré |
| Annulation en cours de franchissement (§7.12) | **Implémenté** | seconde ligne de défense, révélée par le contrôle négatif P3 ; aucun test ne la déclenche seule |
| Déplacement latéral sur paroi 1,65 m/s (§9.2) | **Implémenté**, non mesuré | le code existe et facture 16/s ; aucun test ne vérifie la vitesse |
| `ClimbRest` / corniches de repos (§8.1, §9.3) | **Non commencé** | relève du level design, pas du contrôleur |
| IK visuelle des mains (§9.2) | **Non commencé** | Phase H — il n'y a ni squelette ni modèle |

---

## Phase B — jalon B.4 : franchissement de marche et parcours enchaîné

| Élément | État | Preuve |
|---|---|---|
| Marche de 0,30–0,38 m franchie sans saut (§8.2) | **Fonctionnel** | `test_a_low_step_is_climbed_by_walking` |
| Refus sous un plafond trop bas | **Fonctionnel** | `test_a_step_under_a_low_ceiling_is_refused` |
| Un mur n'est pas une marche | **Fonctionnel** *(comportement, pas couverture — voir Q3)* | `test_a_tall_wall_is_not_treated_as_a_step` |
| Enveloppe §8.2 respectée | **Fonctionnel** | `test_step_height_stays_within_the_spec_envelope` |
| **Parcours enchaîné complet** (§22, Gate B) | **Fonctionnel** | `test_traversal_course.gd`, 13 assertions |
| Caméra jamais dans la géométrie sur tout le parcours (§23.1) | **Fonctionnel** | sonde au point de vue à chaque tick : 0 image sur ~1 400 |
| Chaque capacité réellement employée | **Fonctionnel** | compteurs sur `stepped_up`, `grabbed_wall`, `mantle_finished` |
| Déclencheur de franchissement (D-020) | **Implémenté** | justifié par une mesure ; **aucun test ne le départage** de l'ancien (Q5) |
| Latence en ticks (§10.6, §23.1) | **Fonctionnel** — voir jalon B.5 | `LatencyInstrument` + `test_latency.gd` : 1 tick mesuré, mouvement et saut |

**§8.2 est désormais couvert en entier.**

---

## Phase B — jalon B.5 : latence instrumentée et protocole manuel

| Élément | État | Preuve |
|---|---|---|
| Latence intention → mouvement (§23.1 : « au tick physique suivant ») | **Fonctionnel** | `test_latency.gd` : 5 essais, pire cas **1 tick** (16,7 ms à 60 Hz) |
| Latence de saut depuis le repos (§10.6) | **Fonctionnel** | idem : **1 tick**, stable sur tous les essais |
| Conversion ticks → ms au taux réel | **Fonctionnel** | `test_the_report_converts_ticks_at_the_real_tick_rate` |
| Instrument réutilisable par un affichage debug | **Implémenté** | `LatencyInstrument` ; l'affichage écran viendra avec `CombatLab` (Phase C) |
| Protocole manuel Gate B (§21.4) | **Implémenté** | `docs/MANUAL_VALIDATION.md`, six essais B-1…B-6, prêt à jouer |
| Terrain d'essai jouable | **Fonctionnel** | `TraversalPlayground.tscn` : lancé réellement (headless), souris capturée, panneau d'état, événements journalisés |
| Silhouette graybox du joueur | **Implémenté** | capsule + nez d'orientation ; **pas un personnage** (§7.14), Phase H |
| Ressenti humain (§10.6), jitter (§8.3) | **NON VÉRIFIÉ** | essais B-1 et B-5 du protocole — exigent un écran |

**Ce qui sépare encore le Gate B d'un verdict** : la revue contradictoire (§0.7),
puis les six essais humains du protocole. Le code et l'instrumentation sont
complets.

---

## Phase C — jalon C.0 : fondations de dégâts

Pipeline de §10.1 et formule de §10.3, en composants (§5.8). Aucune arme, aucun
ennemi encore : C.1 branchera l'épée et le premier pillard sur ces fondations.

| Élément (§) | État | Preuve |
|---|---|---|
| `DamageEvent` complet (§10.3 : instigateur, équipe, type, quantité, direction, stagger, point, élément, attack ID) | **Fonctionnel** | `test_the_event_carries_what_the_spec_demands` |
| Formule base×…×weak_point×resistance−armor, clampée (§10.3, §21.2) | **Fonctionnel** | `test_damage.gd`, 3 cas dont l'ordre point faible/armure |
| `HealthComponent` : clamp, mort idempotente, revive | **Fonctionnel** | `test_damage.gd`, 4 cas |
| Invulnérabilité (future porteuse des i-frames §10.2) | **Fonctionnel** | `test_invulnerability_refuses_damage_without_consuming_it` |
| **« Une touche par swing »** (§10.1, critère du Gate C) | **Fonctionnel** | `test_an_overlapping_swing_hits_exactly_once` — 30 frames de chevauchement, 1 coup ; contrôle W1 : sans le set, 30 coups |
| Deux swings = deux coups, attack ID distincts | **Fonctionnel** | `test_a_second_swing_hits_again` |
| Un swing touche chaque cible à portée une fois (§21.4) | **Fonctionnel** | `test_one_swing_hits_every_target_in_range_once` |
| Refus du tir ami par équipe (§10.3) | **Fonctionnel** | `test_friendly_fire_is_refused_by_team` |
| Point faible porté par la hurtbox (§10.3) | **Fonctionnel** | `test_weak_point_multiplier_is_applied_by_the_formula` |
| Fenêtre active par méthode (§10.1) | **Fonctionnel** | `test_an_inactive_hitbox_never_hits` |
| Poise, recul, élément | **Implémenté** — transportés, non consommés | la jauge de poise et le recul appliqué arrivent en C.1/C.2 |
| Résistance et armure côté défenseur | **Implémenté** — paramètres neutres | branchés aux buffs (§13.5) et définitions d'ennemis (C.2) |
| `AttackDefinition` en ressource (§5.9, §10.6) | **Non commencé** | C.1, avec l'épée et le combo |

---

## Phase C — jalon C.1 : épée, combo, premier échange

L'attaque est un contrat de données (§10.6) : `AttackDefinition` porte startup /
actif / recovery / fenêtres, `AttackControllerComponent` l'exécute, le joueur
enchaîne trois légères contre de vrais mannequins.

| Élément (§) | État | Preuve |
|---|---|---|
| `AttackDefinition` en ressource (§5.9, §10.6) | **Fonctionnel** | 3 `.tres` d'épée ; enveloppes §10.2 épinglées (buffer 0,15, fenêtre 25–35 %, hit-stop 0,035–0,055) |
| Hitbox allumée exactement pendant la fenêtre active (§10.1, §10.5) | **Fonctionnel** | `test_the_hitbox_is_active_exactly_during_the_active_window` ; X1 |
| Combo trois légères (§10.2) | **Fonctionnel** | chaîne 0→1→2, jamais d'index 3 ; multiplicateurs 1,0 / 1,05 / 1,3 mesurés sur mannequin |
| Buffer d'attaque 0,15 s, expiration comprise (§10.2) | **Fonctionnel** | 2 cas + X3 |
| Enchaînement dans les derniers 25–35 % de la recovery (§10.2) | **Fonctionnel** | `test_a_buffered_press_chains_at_the_window_not_before` ; X2 |
| Report de buffer en fin de combo (§10.6 : « première fenêtre légale ») | **Fonctionnel** | relance à zéro si l'appui est frais, rien s'il est périmé |
| Attaque engagée au tick suivant l'intention (§10.6, §23.1) | **Fonctionnel** | `test_attack_engages_at_the_next_tick` |
| Mode `ATTACKING` : locomotion figée, gravité conservée | **Fonctionnel** | `test_movement_is_locked_during_the_attack` |
| Hurtbox + santé sur le joueur (§6.2) | **Implémenté** | câblées dans `Player.tscn` ; personne ne frappe encore le joueur (C.2) |
| Premier échange complet : 4 coups couchent un pillard braise (45 PV) | **Fonctionnel** | `test_hammering_delivers_the_full_combo_then_resets` |
| Cadavre inerte (§12.10) | **Fonctionnel** | `test_a_dead_dummy_takes_no_further_hits` |
| `CombatLab` (§10.8) | **Implémenté** — embryon | lancé réellement (RC=0) ; mannequins, panneau, journal des coups ; timeline et export à venir |
| `cancel()` d'interruption (stagger/mort, §16.2) | **Fonctionnel** | testé ; le stagger qui l'appellera arrive en C.2 |
| Esquive + i-frames, lock-on, réactions (§10.2, §8.4) | **Non commencé** | jalon C.2 |
| Attaque lourde, arc (§10.2, §10.4) | **Fonctionnel** | jalon C.3 — voir sa section |
| Hit-stop, VFX, sons (§10.7) | **Non commencé** | valeurs déclarées dans les `.tres`, aucun système de présentation |

---

## Phase C — jalon C.2 : esquive, i-frames, lock-on, premier pillard

| Élément (§) | État | Preuve |
|---|---|---|
| Esquive quatre directions, repère caméra (§10.2) | **Fonctionnel** | `test_dodge.gd` : direction du stick + reculade sans direction |
| I-frames par l'effet : coup refusé DANS la fenêtre, porté APRÈS (§10.2) | **Fonctionnel** | `test_iframes_refuse_a_real_blow_then_expire` ; longueur 0,25 s épinglée dans 0,22–0,27 |
| Coût 15 d'endurance, esquive refusée à jauge insuffisante (§9.1) | **Fonctionnel** | déclaré en B.2, consommé depuis C.2 ; Y2 |
| Dodge cancel : recovery annulable, engagement non (§10.6) | **Fonctionnel** | `test_dodge_cancels_attack_recovery_but_not_startup` |
| Lock-on : acquisition cône caméra 18–24 m (§8.4) | **Fonctionnel** | `test_lock_on.gd`, 7 cas ; enveloppe épinglée |
| « Jamais à travers mur » (§8.4) | **Fonctionnel** | mur réel, même cône — seul le mur change ; Y3 |
| Libérations : mort, distance (hystérésis), bascule (§8.4) | **Fonctionnel** | 3 cas |
| Caméra convergente, butées conservées, strafe face à la cible (§8.4) | **Fonctionnel** | convergence mesurée en angle ; face au mannequin en déplacement |
| Poise → stagger → récupération (§10.3, §12.3) | **Fonctionnel** | 2 coups d'épée (10+10 ≥ 20) étourdissent le pillard une fois |
| **Pillard braise complet** (§12.1, §12.6, §12.7) | **Fonctionnel** | `test_raider.gd`, 8 cas — voir ci-dessous |
| Perception : cône 95°/22 m par cadence, LOS réelle, impact révélateur | **Fonctionnel** | aggro devant, rien dans le dos, rien à travers mur |
| Télégraphe 0,65–0,95 s mesuré ET épinglé | **Fonctionnel** | coup jamais avant 0,65 s (mesuré : ~0,8) ; Y5 dans les deux sens |
| **Repli après esquive réussie** (§12.1) | **Fonctionnel** | esquive réelle chronométrée sur le télégraphe → 0 dégât + distance de repli ; Y4 |
| Duel gagnable (Gate C) | **Fonctionnel** | martèlement → pillard mort, inerte, joueur vivant |
| Changement de cible (§8.4 suivant/précédent) | **Fonctionnel** | jalon C.3 : directionnel, sans boucle, jamais à travers mur |
| Audition (§12.6), navmesh (§12.7) | **Différés** | D-022 — événements sonores et Phase D |
| Réaction de dégât du joueur (§8.1 Hurt), anti-stunlock (§10.5) | **Fonctionnel** | jalon C.3 — voir sa section |

---

## Phase C — jalon C.3 : attaque lourde, réaction du joueur, arc

| Élément (§) | État | Preuve |
|---|---|---|
| Attaque lourde : ×1,8, poise 25, hit-stop 0,08 déclaré (§10.2) | **Fonctionnel** | `test_heavy_and_hurt.gd` : 21,6 de dégâts ET 20 d'endurance mesurés sur le même coup |
| « Lourde refusée » à jauge insuffisante (§9.1) | **Fonctionnel** | à jauge 10 : rien ne part, rien n'est prélevé, mannequin intact ; Z1 |
| Une lourde brise la poise du pillard (25 ≥ 20) | **Fonctionnel** | 1 stagger, pas mort — l'« ouverture claire » version pillard |
| Réaction Hurt : recul + perte de contrôle 0,25 s (§8.1) | **Fonctionnel** | déplacement mesuré dans la direction du coup, contrôle rendu ; Z6 isole l'impulsion |
| Anti-stunlock 0,85 s : protège le CONTRÔLE, jamais les PV (§10.5) | **Fonctionnel** | deux coups en cadence : les deux blessent, seul le premier renverse ; grâce expirée → réaction revient ; Z2 |
| Hurt refusé pendant escalade/mantle/esquive | **Implémenté** | gardes en place ; l'esquive est couverte par les i-frames (C.2), les autres non testés |
| Arc : 9 de dégâts à distance, visée obligatoire (§10.4, §11.1, §8.5) | **Fonctionnel** | `test_bow.gd` ; sans visée, rien ne part |
| Balistique par balayage — CCD, chute de gravité (§5.3, §10.4) | **Fonctionnel** | vy ≈ −4 mesurée après 1/3 s de vol à plat |
| Anti-tir-à-travers-mur : origine-poitrine (§10.4) | **Fonctionnel** | mur à 0,8 m : flèche arrêtée, mannequin abrité intact ; Z3 chiffre la contre-hypothèse |
| La flèche meurt à sa première victime (§10.1) | **Fonctionnel** | deux mannequins alignés : 9 / 0 |
| Pool de flèches sans instanciation en rafale (§20.6) | **Fonctionnel** | 4ᵉ tir refusé à pool 3 ; cadence refuse le tir immédiat |
| Enveloppes : vitesse 42–58, dégâts 9, hit-stop lourd 0,070–0,095 | **Fonctionnel** | épinglées sur les `.tres` livrés ; Z4 |
| Changement de cible directionnel (§8.4) | **Fonctionnel** | 3 cibles dont une derrière un mur : pas à droite, pas de boucle, pas à travers |
| Munitions comptées, réticule, présentation (§11.3, §10.7) | **Non commencé** | C.4 et passe de présentation |

---

## Phase C — jalon C.4 : inventaire, durabilité, rupture

| Élément (§) | État | Preuve |
|---|---|---|
| `WeaponDefinition` immuable + table §11.1 complète (6 armes) | **Fonctionnel** | `test_weapon_data.gd` : les 6 `.tres` épinglés ligne à ligne (dégâts/durabilité/portée/conductivité) ; AA3 |
| **Invariant CLAUDE.md : deux exemplaires ne partagent jamais leur durabilité** | **Fonctionnel** | jumeau ET définition intacts après usure ; AA4 le prouve dans les trois directions (15 échecs en cascade) |
| Usure au contact seulement — « jamais dans le vide » (§11.2) | **Fonctionnel** | 2 moulinets à vide = 0 point ; 1 coup qui touche = 1 point ; AA2 |
| Avertissement à 25 %, une fois, sans spam (§11.2) | **Fonctionnel** | émis au passage sous le quart, jamais deux fois |
| Rupture : hitbox coupée, exemplaire retiré, suivante ou mains nues (§11.2) | **Fonctionnel** | épée 12 → gourdin 8 → poings 3 sur le même mannequin ; coupe au milieu du tick (2 mannequins, 1 point → 1 seule victime) |
| Dégâts et PORTÉE par arme (§11.1) | **Fonctionnel** | lance 2,7 m touche à 2,4 m, épée 1,7 m non — même geste |
| Inventaire : 8 armes max, aucun doublon d'instance (§11.3) | **Fonctionnel** | 9ᵉ refusée, même exemplaire refusé ; AA5 |
| Flèches comptées, consommées par tir, tir refusé à zéro (§11.3) | **Fonctionnel** | 8 → 7 ; carquois vide + cadence purgée → rien ne part ; AA6 |
| Durabilité de l'arc en tirs (28, §11.1) | **Non commencé** | définition présente, décompte au raccordement de l'arc à l'inventaire |
| Entrée clavier de sélection, ramassage, UI (§17.3, §11.4) | **Non commencé** | `equip_next` est une API ; coffres Phase D, UI §17 |

---

## Nuit ART-Q (2026-08-02) — assets de production Quaternius, Q0→Q7

Revue contradictoire à contexte frais : **PASS global, zéro S0-S3**
(`evidence/artQ7/REVUE.md`). Le verdict ESTHÉTIQUE reste humain
(`docs/PLAYTEST_ARTQ.md`).

| Élément | État | Preuve |
|---|---|---|
| Acquisition 7 archives (Release GitHub, CC0 sur pièce) | **Validé** | SHA-256 = digests GitHub, recoupés indépendamment par la revue — `docs/assets/QUATERNIUS_INBOX.md` |
| 18 ids du registre livrés (env ×8, prop ×3, arch ×3, char ×4) + épée | **Fonctionnel** | `test_asset_pipeline` : chaque id livré monte un maillage réel |
| Héros riggé animé dans le VRAI joueur (12 états, sockets main/dos/arc, épée en main, capsule autorité) | **Fonctionnel** | `test_hero_visual` (7 tests) ; audit root motion rejoué par la revue |
| Pillard animé sur la vraie IA + variantes azur/obsidienne | **Fonctionnel** | `test_raider_visual` (4 tests) ; capsule 1,6 m intacte au diff |
| Coffre rigged (clips Chest_Open/Opened), loot/IDs/atomicité intacts | **Fonctionnel** | `test_camp_props` |
| Camp habillé (caisses, tonneaux, galets de foyer) + caméra de contrôle | **Fonctionnel** | `evidence/artQ3/camp_props.png` |
| Forêt réelle sur collisions INCHANGÉES + phrases végétales §7.17 | **Fonctionnel** | `test_nature_biome` ; diff des collisions vide |
| Vestibule : piliers modulaires, portails de pierre, SceneDoors intactes | **Fonctionnel** | `test_citadel_dressing` |
| Liaison turquoise héros↔citadelle (§7.11), peau non teintée | **Fonctionnel** | `test_the_turquoise_tint…` ; `evidence/artQ6/ref_vista.png` |
| `prop.tent`, `prop.campfire` | **Bloqué** (absents des 7 packs) | inventaire consigné — options futures |
| Qualité artistique perçue | **EN ATTENTE** (verdict humain, §0.2) | protocole : `docs/PLAYTEST_ARTQ.md` |

## Phase F — jalons F.1 et F.2 : graphe électrique et salle d'initiation

L'ordre de §22 est respecté : le graphe a été construit et testé en **sandbox
automatisée** avant qu'une seule salle n'existe.

| Élément | État | Preuve |
|---|---|---|
| `ElectricNode` — §15.1 complet (ID stable, ports orientés en local, conductivité, `enabled`, signaux, `set_powered` idempotent, zéro rendu) | **Fonctionnel** | `--filter=electric_graph` (11 tests) |
| `ElectricGraph` — §15.2 point par point (marquage `dirty`, regroupement par tick, contacts réels port-à-port, BFS depuis toutes les sources, cycles bornés, signaux au seul changement) | **Fonctionnel** | idem : cycle de 4 câbles qui termine, 10 marquages = 1 recalcul, 20 ticks inactifs = 0 |
| Salle 1 §15.5 — source, vide court, deux plaques, bloc mobile, propagation visible, porte différée, reset, solution imperdable | **Fonctionnel** | `--filter=room1` (12 tests) ; captures `evidence/F2/` (entrée et salle résolue, arbre propre) |
| Le bloc est poussé **par le joueur**, à la marche, sans téléportation | **Fonctionnel** | `test_the_player_pushes_the_block_and_opens_the_door` : 7 m de poussée réelle, porte ouverte |
| Délai d'ouverture dans la fenêtre 0,6-1,2 s | **Validé** | mesuré tick par tick (`test_the_door_waits_between_06_and_12_seconds`) |
| Propagation lumineuse (le cyan voyage, il ne s'allume pas d'un bloc) | **Fonctionnel** | `test_the_light_travels_along_the_circuit` : le début du circuit est allumé avant sa fin |
| Anti-softlock §15.11 : reset, respawn hors-monde, porte latchée, rechargement en milieu de résolution | **Fonctionnel** | 4 tests dédiés, dont le rechargement depuis le disque |
| Poussée d'objets physiques par le joueur (§14.1, impulsions bornées) | **Fonctionnel** | `PlayerController._push_physics_props` ; masque du joueur étendu à la couche Physics Prop |
| Ergonomie de la poussée, lisibilité de l'énigme sans texte | **EN ATTENTE** (verdict humain) | `docs/MANUAL_VALIDATION.md` |
| Salle 2 §15.6 — ascenseur mort au départ, puits escaladable, électrodes rythmées, aiguillage supérieur, corniches, chute sur palier proche, aucun écrasement | **Fonctionnel** | `--filter=room2` (12 tests) |
| Résistance électrique de §13.5 réellement utile | **Fonctionnel** | `test_electric_resistance_softens_the_shock` : première source de dégâts électriques du jeu |
| Montée réelle du joueur, arrêt de l'ascenseur devant un corps, chute sur palier | **Fonctionnel** | `test_the_player_really_climbs_the_shaft`, `test_the_elevator_stops_rather_than_crushing_the_player`, `test_a_fall_lands_on_the_ledge_below` |
| Ergonomie de l'escalade sous électrodes, lisibilité du rythme | **EN ATTENTE** (verdict humain) | `docs/MANUAL_VALIDATION.md` |
| Salle 3 §15.7 — quatre relais, ports visibles, rotations discrètes, chemin partiel lisible, aucune punition, reset | **Fonctionnel** | `--filter=room3` (8 tests) |
| Solveur automatique de §15.7 : une solution existe, le départ n'en est pas une | **Validé** | `test_the_solver_proves_a_solution_exists` : 256 configurations jouées sur le vrai graphe, 1 solution |
| Salle 4 §15.8 — source, deux mécanismes, batterie transportable, socket explicite, eau conductrice, DEUX solutions, respawn, aucune porte du mauvais côté | **Fonctionnel** | `--filter=room4` (11 tests) |
| Prendre / porter / poser (§14.2) | **Fonctionnel** | `test_the_player_picks_up_carries_and_drops_the_battery` |
| Salle centrale §15.9 — trois récepteurs INDÉPENDANTS, trois anneaux, porte à trois conditions, carte murale, tableau salle→récepteur | **Fonctionnel** | `--filter=dungeon_hub` (10 tests) |
| Antichambre §15.10 — checkpoint, coffre garanti, cuisine, baies, retour, fresque bois/métal, aperçu de l'arène | **Fonctionnel** | idem |
| Donjon ASSEMBLÉ : vestibule → salle 1 → hall → salles 2/3/4 → antichambre, chemins retour, arrivée devant la porte franchie | **Fonctionnel** | `--filter=topology` (5 tests, 75 assertions) |

## Phase G — jalons G.1 et G.2 : arène du Gardien et combat de boss

| Élément | État | Preuve |
|---|---|---|
| Arène §16.1 — disque de **38 m** (bornes 32-42), mur circulaire continu, trois zones de sol distinctes, aucun pilier au centre | **Fonctionnel** | `--filter=boss_arena` : la géométrie est mesurée (`CylinderShape3D`, rayons emboîtés), et le disque est balayé à la recherche d'un obstacle de cadrage |
| Quatre pylônes de mise à la terre, branchés sur le **même graphe** que le donjon (§16.3) | **Fonctionnel** | `test_a_raised_pylon_is_powered_by_the_ground_rail` : dresser allume, couper le puits de terre éteint — un mât rétracté ne peut pas toucher le rail |
| Anneau de terre fermé = un **cycle** du graphe (§15.2 pt. 5) | **Validé** | `test_the_closed_ground_ring_terminates` : 50 recalculs chronométrés, courant faisant le tour des 24 nœuds |
| §16.6 — le Gardien reste dans l'arène ; il ne pousse pas le joueur dehors | **Fonctionnel** | deux tests de 240 ticks, joueur placé hors arène puis collé au mur |
| §16.6 — la caméra élargit distance et FOV **progressivement** | **Fonctionnel** | `test_the_camera_widens_progressively_near_the_boss` : plus grand pas mesuré < 0,25 m/tick, retour au cadrage normal après la mort |
| §16.6 — checkpoint juste avant, retry qui relance le COMBAT | **Fonctionnel** | l'arène relit le checkpoint de l'antichambre (armes, flèches, santé) ; `retry_target()` pointe sur l'arène ; rechargement chronométré |
| §17.2 — barre de boss originale (vie réelle + nom de phase) | **Fonctionnel** | `test_the_hud_shows_a_boss_bar_only_in_the_arena` |
| §15.11 jusqu'à l'arène : le seuil sud reste ouvert vers l'antichambre | **Fonctionnel** | `test_the_arena_is_never_a_one_way_trap`, dans les deux sens |
| §16.2 — machine à dix états, transitions **idempotentes** | **Validé** | `test_a_health_threshold_never_fires_twice` : seuil traversé, remonté, retraversé |
| §16.1 — les 5 s d'éveil existent vraiment | **Fonctionnel** | défaut trouvé par test : `_enter()` étant idempotent, l'INTRO n'était jamais armée et le Gardien basculait en phase 1 au premier tick |
| §16.3 — armure ×0,2 sans invulnérabilité, DEUX pylônes pour la mise à la terre, étourdissement 6 s, noyau exposé puis armure refermée | **Fonctionnel** | `--filter=boss_guardian` (5 tests dédiés) |
| §16.4 — cristaux révélés en phase 2, destructibles, noyau exposé à leur chute | **Fonctionnel** | `test_the_crystals_appear_in_phase_two_and_open_the_core` |
| §16.4 — le métal renvoie pendant la surcharge, le bois non, la résistance électrique amortit | **Fonctionnel** | joué avec les VRAIES armes du jeu (gourdin, lame conductrice) et le vrai buff |
| §16.5 — fenêtre de télégraphe au sol **chronométrée** entre 0,7 et 1,0 s, borne fermée | **Validé** | `test_the_ground_strike_gives_a_real_warning_window` : un télégraphe réglé à 0,05 s est ramené à 0,7 |
| §16.5 — phase 3 « +10 à +18 %, pas doublement » | **Validé** | distance parcourue mesurée en phase 1 et en phase 3 |
| §16.2/§16.8 — la mort coupe attaques, hitboxes et timers ; la victoire est écrite | **Fonctionnel** | `test_death_cuts_everything_and_writes_the_victory`, relecture du fichier |
| §16.7 — **solvabilité** avec le loot garanti, marge 30-50 % | **Validé** | `test_the_guardian_is_beatable_with_the_guaranteed_loot` : c'est ce test qui a fait descendre les PV de 900 (marge -16 %, combat impossible) à 560 (+35 %) |
| §16.6 — « boss visible ≥ 80 % du temps en lock-on » | **Fonctionnel** (partie automatisable) | 180 positions autour de l'arène, projection écran réelle ; le confort de cadrage reste un jugement humain |
| Ressenti du combat, lisibilité des télégraphes, durée réelle d'une première victoire (§16.1 : 4-7 min) | **EN ATTENTE** (verdict humain) | `docs/MANUAL_VALIDATION.md` |
| Conclusion §16.8 (coffre final, tempête qui se dissipe, écran de victoire) | **Non commencé** | jalon G.3 |

## Phase H — lot H.1 : le Gardien devient un hero asset

| Élément | État | Preuve |
|---|---|---|
| Modèle ORIGINAL du boss, procédural et reproductible | **Fonctionnel** | `tools/blender/make_storm_guardian.py` (seed 20260803) → `SK_StormGuardian.glb` ; `--filter=guardian_asset` 6/6 |
| Cotes de VISUAL_ASSET_BIBLE §15.1 (8-10 × 5-7 × 5,2-6 m) | **Validé** | mesurées **dans Godot** sur la géométrie importée : 9,58 × 5,30 × 5,60 m, min Y = 0 |
| Anatomie exigée : six appuis, tête à trois plaques, épaules de bronze, queue segmentée à fourche, anneau incomplet en trois segments, noyau fendu | **Validé** | `test_the_anatomy_the_bible_asks_for_is_actually_there` : 20 assertions par NOM de mesh |
| 27 meshes séparés parce que le gameplay les manipule (§16.4, §16.5) | **Fonctionnel** | cristaux révélés/cachés sur le vrai modèle, plaques qui pendent en phase 3 |
| Les volumes de combat sont DANS le corps visible | **Validé** | `test_the_combat_volumes_sit_inside_the_body_you_can_see` : hurtbox de noyau à moins d'un mètre du noyau modélisé, cristaux à moins de 1,2 m |
| Le noyau s'allume quand l'armure s'ouvre (§16.3) | **Fonctionnel** | matériau propre à l'instance, émission mesurée avant/après |
| Licence et provenance | **Validé** | création originale du projet — `ATTRIBUTIONS.md`, `docs/assets/ASSET_MANIFEST.csv` |
| Densité de surface (bible §4.5 : 110-160k tris LOD0) | **PARTIEL assumé** | 6 324 triangles : silhouette et structure présentes, détail de surface absent. Consigné au manifeste |
| Animation du boss (§16.1 : entrée 5-8 s, dégâts visuels progressifs) | **Non commencé** | rig 22 os livré ; les clips viennent au lot suivant |
| Trois pillards, colosse, chasseur en silhouettes distinctes | **PARTIEL** | pillards faits (lot H.2) ; colosse et chasseur restent dus (H.3, H.4) |

## Phase H — lot H.2 : trois pillards, trois corps

| Élément | État | Preuve |
|---|---|---|
| Géométrie ORIGINALE pour braise, azur et obsidienne | **Fonctionnel** | `tools/blender/make_raiders.py` → trois `.glb` ; `--filter=raider` 22/22 |
| Le squelette des animations est CONSERVÉ (65 os UAL) | **Validé** | `gltf_inspect` : `skin:Armature 65 os` sur les trois ; `AL_RaiderStates.res` s'applique sans retargeting |
| Tailles de VISUAL_ASSET_BIBLE §14.1-14.3 | **Validé** | mesurées dans Godot : 1,42 · 1,63 · 1,88 m, dans leurs bandes et ORDONNÉES |
| Silhouettes réellement distinctes, pas des recolorations | **Validé** | `test_the_three_families_have_distinct_bodies_not_just_distinct_tints` : le briseur est 19 % plus large, les maillages ont des comptes différents |
| Traits de famille : excroissances vers l'arrière, crête verticale, visière fendue, plaques inégales | **Implémenté** | construits par profil dans le script ; **la lisibilité en silhouette noire à 25 m reste un essai humain** |
| §5.4 — matériaux propres à chaque exemplaire | **Validé** | isolation rendue inconditionnelle ; régression du télégraphe attrapée par `test_the_real_raider_mounts_the_model_and_keeps_its_gameplay_volumes` |
| Textures et détail de surface | **Non commencé** | couleurs de matériau seules, aucune texture. Consigné au manifeste |

## Phase H — lots H.3 et H.4 : colosse et chasseur, modèles bâtis

| Élément | État | Preuve |
|---|---|---|
| Colosse des ravins — modèle ORIGINAL rigged | **Implémenté** | `tools/blender/make_creatures.py` → `SK_RavineTroll.glb` (2 580 tris, 8 os) ; haut **3,97 m**, bande §14.4 = 3,7-4,3 |
| Traits exigés : torse incliné, bassin massif, bras ASYMÉTRIQUES dont un à croissance rocheuse, petites jambes puissantes, nodule minéral pâle entre omoplate et nuque | **Implémenté** | construits pièce par pièce dans le script ; **pas encore vérifiés dans Godot** |
| Chasseur quadrupède — modèle ORIGINAL rigged, corps inférieur NON équin | **Implémenté** | `SK_CentaurHunter.glb` (3 240 tris, 6 os) ; haut **3,20 m** (bande 3,0-3,5), long **4,69 m** (bande 4,0-4,8) |
| Traits exigés : quatre pattes à trois doigts, épaules avant plus hautes, queue de lames, torse supérieur né EN AVANT du bassin, plaque frontale et mandibules latérales | **Implémenté** | idem |
| Montage dans `RavineTroll.tscn` et `CentaurHunter.tscn` | **Fonctionnel** | `--filter=creature_assets` 4/4 : modèles montés, graybox masqués (les DEUX boîtes du chasseur), cotes vérifiées **dans Godot** — colosse 3,97 m, chasseur 3,20 × 4,69 m |
| §12.4 — le nodule point faible est du côté de la hurtbox arrière ×2 | **Validé** | `test_the_weak_point_nodule_sits_on_the_side_the_back_hurtbox_guards` |
| §12.5 — corps ALLONGÉ, pas un cheval | **Validé** | plus de 2,5 fois plus long que large, et plus long que haut |
| Les deux créatures regardent le côté où elles frappent | **Validé** | `test_both_creatures_face_the_direction_they_strike` |
| Envergure du colosse (4,06 m) plus large que sa capsule (rayon 1,1 m) | **Limite assumée** | règle ART-P0 : le modèle est un visuel, la capsule reste l'autorité de gameplay. Le joueur peut passer « à travers » les bras tendus |
| Animations propres au colosse et au chasseur | **Non commencé** | rigs livrés (8 et 6 os), aucun clip — les deux créatures gardent leur pose de repos |
| Silhouettes des cinq familles en aplat noir à 25 m (§30.3 de la bible) | **FAIL** | `evidence/phaseH/lineup_silhouettes.png` : la ligne des sept sujets est capturée, mais plusieurs corps se lisent en pièces détachées (ISS-018). Le critère ne peut pas être jugé tant que l'assemblage n'est pas fini |
| Assemblage des volumes (aucune articulation ouverte) | **PARTIEL** | passe de mordant faite sur les trois pillards et le tronc du colosse ; avant-bras et pieds du colosse, chasseur entier et extrémités du Gardien restent ouverts (ISS-018, S2) |
| Bibliothèque de silhouettes étendue à SEPT sujets (héros + cinq familles + boss) | **Fonctionnel** | `test_the_silhouette_lineup_mounts_every_character_of_the_game` : personne ne chevauche son voisin, le plus grand fait plus du triple du plus petit |
| Captures depuis le VRAI moteur | **Fonctionnel** | `evidence/phaseH/lineup_matiere.png` et `lineup_silhouettes.png`, avec leurs manifestes JSON |

## Checklist finale (§26) — état réel

Une case n'est cochée que si une preuve datée la soutient. Ne jamais cocher sur la
base d'une intention. Les cases cochées ci-dessous renvoient toutes à `TEST_REPORT`.

| Domaine | Critère | État |
|---|---|---|
| Build | Ouvre et lance sans erreur bloquante | partiel — se lance en headless (T-05) ; **jamais ouvert dans l'éditeur**, critère de Gate A |
| Continuité | Une session neuve reprend via CLAUDE/STATUS/PROGRESS | ✅ sous réserve (T-07) |
| Recherche | Décisions risquées sourcées, expérimentées, consignées | ✅ |
| Loop | Du spawn à la victoire sans debug | ⬜ |
| Démo | Parcours trois minutes fluide, non truqué | ⬜ |
| AZERTY | ZQSD et Q=gauche | liaison testée ✅ ; essai humain sur clavier AZERTY **non fait** |
| Caméra | Aucun mur/jitter critique | ⬜ |
| Traversal | Sprint, saut, escalade, mantle | ⬜ |
| Combat | Une touche par swing, esquive juste | ⬜ |
| Arc | Visée et projectiles fiables | ⬜ |
| Durabilité | Avertissement, rupture, auto-équipement | logique testée ✅ (C.4) ; usure visuelle et son : Phase H |
| IA | Cinq familles distinctes, LOS réelle | ⬜ |
| Cuisine | 1-5 ingrédients et cinq buffs | ⬜ |
| Électricité | Graphe générique, pas booléens de salle | ✅ 4 salles + les pylônes du boss sur le MÊME graphe (`--filter=electric_graph`, `boss_arena`) |
| Donjon | Quatre salles et anti-softlock | ✅ automatique (`docs/GATE_F_AUDIT.md`) ; lisibilité **EN ATTENTE** humaine |
| Boss | Trois phases et solvabilité | ✅ automatique (`docs/GATE_G_AUDIT.md`) : trois phases traversées par un run joué, solvabilité mesurée à +35 % de marge ; ressenti **EN ATTENTE** humaine |
| Save | Coffres/circuits/inventaire/boss persistants | ⬜ |
| North Star | Score ≥ 85/100 | ⬜ **bloqué** |
| Look-dev | Labs validés | ⬜ **bloqué** |
| Art | Aucun placeholder critique | ⬜ |
| Assets | Blender/glTF/import/manifest/licences reproductibles | ✅ chaîne + 12 premiers assets Quaternius CC0 ingérés (ART-Q0) |
| Animation | IK/alignement sans défaut majeur | ⬜ |
| Audio | Feedback des actions importantes | ⬜ |
| Performance | Mesurée et conforme au preset annoncé | ⬜ **bloqué** |
| Frame pacing | Aucun hitch critique de première utilisation | ⬜ **bloqué** |
| Stabilité | 60 min sans crash | ⬜ **bloqué** |
| Web | Compatibility et fallback cohérent | ⬜ |
| Légalité | Assets originaux/licenciés/attribués | ✅ externe = Quaternius CC0 uniquement, licences sur pièce, ATTRIBUTIONS avant build |

## Phase H — lot H.6 : assemblage des personnages (ISS-018, ISS-019)

Commits `30ae2d3`, `29a3303`, `be96545`.

| Fonctionnalité | État | Preuve |
|---|---|---|
| Assemblage des volumes — aucune articulation ouverte | **Validé** | `check_continuity.py` sur les six `.glb` livrés : un seul corps solidaire, 43 / 60 / 113 / 20 / 26 / 24 morceaux, aucun détaché. Journaux `evidence/pipeline/continuity_*.log` |
| Contrôle automatique de continuité (ISS-019) | **Validé** | niveau 3b de `tools/validate_fast.sh`. Contrôle NÉGATIF : pièce déplacée de 0,60 m → code 1 ; modèle réparé → code 0 |
| Corps des pillards | **Fonctionnel** | corps CC0 Quaternius conservé (12 894 tris, PBR) au lieu des primitives ; stature 1,42 / 1,65 / 1,88 m, carrure 0,90 à 1,26, teintes de faction exportées en `baseColorFactor` vérifié dans le `.glb` |
| Chasseur — jonction torse/quadrupède | **Fonctionnel** | tronc de liaison ajouté, cage portée à 1,00 m de profondeur, épaules et hanches ; haut 3,41 m (bande 3,0-3,5), long 4,20 m (bande 4,0-4,8) |
| Colosse — avant-bras, mains, jambes, pieds | **Fonctionnel** | membres bâtis à leur portée pleine ; haut 4,03 m (bande 3,7-4,3) |
| Gardien — extrémités et jonctions | **Fonctionnel** | anneau réorienté tangentiellement et abaissé pour traverser le dos, queue, câbles, plaques et cristaux rattachés ; long 9,38 m · large 5,24 m · haut 5,59 m (bandes §15.1 : 8-10 / 5-7 / 5,2-6) |
| Planche d'inspection par angles | **Fonctionnel** | `scenes/tests/CharacterTurntable.tscn`, `--creature=<id>` : face, trois quarts, profil, dos, aplat noir |
| Silhouettes des cinq familles en aplat noir à 25 m (§30.3) | **NON VÉRIFIÉ** | la planche est capturable et les corps sont assemblés, mais le jugement « deux silhouettes ne se confondent pas » est un essai HUMAIN — `docs/MANUAL_VALIDATION.md` |
| Qualité sculpturale des créatures | **Limite assumée** | colosse, chasseur et Gardien restent des assemblages de primitives : cotes justes, volumes solidaires, lisibles — mais sans sculpture. Aucun score visuel n'est revendiqué |

## Phase H — lot H.7 : prairie de crête à la densité de la bible

| Fonctionnalité | État | Preuve |
|---|---|---|
| Densité de la prairie (§7.2 : 7-14 touffes/m² en zone héroïque) | **Validé** | `test_the_meadow_reaches_the_density_the_bible_asks_for` : densité mesurée par m² sur chaque cellule, bande 4-14, deux cellules au moins en zone héroïque, ≥ 10 000 touffes sur la crête |
| Partition en cellules (§7.5 : 24-48 m) | **Validé** | quatre cellules de 23 m, largeur vérifiée par le même test |
| Forme du brin (§3.1 : herbe longue 0,65-0,95 m au premier plan) | **Fonctionnel** | éventail de sept brins de 3,6 cm, ployés vers la pointe, normales inclinées à 72 % vers le ciel ; hauteur 0,41 à 0,74 m selon l'instance |
| Premier plan de la vue d'ouverture (§3.2 : « pente herbeuse sur les 22-30 % inférieurs ») | **Fonctionnel** | `evidence/phaseH/vista_prairie.png` — comparer à `evidence/artQ6/ref_vista.png` |
| Score WOW de la vue d'ouverture (§30.2) | **NON VÉRIFIÉ** | la notation demande un œil humain et un GPU réel (ISS-002). Le reste du cadre est encore graybox : montagnes en boîtes grises, citadelle sans terrasses, sol en aplat vert, cubes de placeholder |

## Monde ouvert — lot MO.4 : ancrages et récompenses des 31 lieux

Commits `2bf440f`, `018b8b6`.

| Fonctionnalité | État | Preuve |
|---|---|---|
| Un ancrage explicite et nommé par lieu (§3) | **Validé** | `test_every_place_carries_exactly_one_anchor` : 31 lieux, 31 ancrages, aucun orphelin, aucun sans point d'approche déclaré |
| Emplacement éprouvé physiquement — sol, dégagement, couloir | **Validé** | positions produites par `tools/godot/probe_reward_anchors.gd` sur la vallée montée, figées dans la table de chaque bâtisseur |
| Accès et retour démontrés par un corps | **Validé** | `test_a_body_reaches_every_reward_and_leaves_again` : `RewardAnchorAudit` marche l'aller puis le retour sur les 31 ancrages ; 14 défauts au premier passage, 0 après correction des causes |
| Traversée du belvédère prouvée sans navmesh (D-042) | **Validé** | ancrage `requires_traversal`, corps parti du pied de l'échine, montée de 20 m sous gravité |
| Variété des récompenses (§3) | **Validé** | `test_the_rewards_are_varied_and_none_is_missing` : 5 natures, aucune au-delà de 45 % du total |
| Armes au sol réellement ramassables (`WeaponPickup`) | **Validé** | `test_ground_weapons_are_real_pickups` : E ramasse, inventaire plein refuse, l'arme refusée reste au sol |
| Fragments d'histoire lisibles et annoncés une fois | **Validé** | `test_story_fragments_are_read_once` |
| Identifiants persistants uniques | **Validé** | `test_reward_identifiers_are_unique_across_the_whole_valley` sur coffres, armes, ingrédients et fragments |
| Aucun second butin après sauvegarde/rechargement | **Validé** | `test_rewards_survive_a_real_save_and_reload` : aller-retour réel par `user://slot0` |
| Restauration des découvertes au rechargement | **Corrigé** | le journal était appliqué AVANT que les lieux ne se déclarent : aucune découverte n'était jamais restaurée. `_build_open_world()` passe devant `_apply_save()` |
| Inspection visuelle de chaque ancrage | **En cours** | `scenes/tests/RewardAnchorShot.tscn` ; captures dans `evidence/rewards/` |
| Condition d'ouverture des récompenses de territoire et d'énigme | **Non commencé** | six lieux concernés, nommés par `DiscoveryRewards.deferred_gates()`. Le coffre est réel et persistant ; le verrou n'existe pas |

## Phase H — lot H.8 : armes de production et étagement de l'horizon

Commits `d5b4c79`, `9d107a2`.

| Fonctionnalité | État | Preuve |
|---|---|---|
| Les six armes portent un modèle de production (ISS-020) | **Fonctionnel** | `test_every_weapon_carries_its_own_production_model` : six modèles distincts, chacun instanciable et porteur de géométrie. Dimensions dans les bandes §16 |
| Pose des armes au sol | **Fonctionnel** | les armes de plus de 1,05 m sont fichées en terre, hauteur déduite de la boîte englobante après rotation. `evidence/rewards/logging_hamlet.png` |
| Textures des cinq nouvelles armes | **Non commencé** | facteurs PBR plats ; seule l'Épée usée a ses cartes peintes. ISS-020 reste ouvert sur ce point |
| Trois plans dans la vue d'ouverture (§1.3) | **NON CONCLUANT** | crêtes brisées et deux rangs lointains posés, mais la seule mesure produite — l'écart de valeurs sur la bande d'horizon — passe de 25 à 24 points, soit une différence négligeable et **dans le mauvais sens**. Un diff de pixels n'est pas une amélioration esthétique. À trancher par une comparaison visuelle indépendante et des mesures correctement orientées |
| Citadelle détachée de la montagne (§30.2) | **NON CONCLUANT** | la bordure a été éclaircie et la pierre assombrie, mais aucune mesure ne démontre que le monument se détache. Revendication retirée |
| Score WOW de la vue d'ouverture (§30.2) | **NON VÉRIFIÉ** | la notation demande un œil humain et un GPU réel (ISS-002). La vallée reste un graybox : citadelle sans terrasses, montagnes en boîtes, sol en aplat |
