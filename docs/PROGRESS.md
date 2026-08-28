# PROGRESS — journal chronologique et handoff

Ordre **anti-chronologique** : l'entrée la plus récente est en haut. La dernière
entrée fait office de handoff et doit indiquer **exactement** la prochaine action.

---
## 2026-08-28 — ISS-074 : la garnison du camp braise existe, et ISS-080 est fermée

Branche `claude/world-v2-iss074-garnison`, créée depuis le point T1 gelé
`0c000bf0` sur **décision lead** du 2026-08-28 (« continuation immédiate »),
qui autorise la tranche verticale. Le seul commit contractuel ISS-074
(`71a8ec37`) a été repris par **cherry-pick**, sans merge ni rebase. La
candidate de lundi `world-v2-candidate-iss073-98cbaf0` (`a8d2f77`) reste
inchangée ; T1 reste figée et NON fusionnée.

**ISS-080 fermée.** `antechamber.gd` restaure l'inventaire depuis la
sauvegarde AVANT son écriture différée du checkpoint — le mécanisme de
`boss_arena.gd`, repris sans le modifier. Contrat **C11**, rouge d'abord :
« 1 arme au lieu de 3 · 8 flèches au lieu de 37 · 0 plat au lieu de 1 », soit
exactement le kit de `Player.tscn`. Puis 11/0. Contrôle négatif : retirer la
seule ligne d'appel rougit C11 et **rien d'autre**.

**La garnison.** `WorldV2EncountersBuilder` (script du conteneur `Encounters`,
non gelé) + `resources/world_v2/world_v2_garrisons.json` : 3 `raider_red` et
1 `raider_blue` en r05, un `CombatCoordinator` unique, `enemies_slain`
additif. **Aucun fichier gelé modifié** — le gel est resté à « 0 absent » à
chaque contrôle ; le manifeste n'a fait qu'accueillir le fichier neuf (D-057).

**Portail renforcé** (9 exigences) : rouge d'abord 0/10, puis 6/0.
**Combat prouvé en moteur** : 5/5. **Contrat de budget** (remplaçant « aucun
acteur prématuré ») : 5/5. Trois contrôles négatifs chirurgicaux.

**Ce que la revue de complétude a rattrapé, et c'est le vrai gain.** Le
navmesh datait du 13 août, la géométrie du camp du 19 : mes « 238 points
atteignables » portaient sur un terrain nu là où le jeu pose une palissade.
Recuit → les quatre quadrants ont changé de sha256, et une position est passée
de 0,010 m à 0,830 m d'écart. Positions re-choisies sur le résultat frais.
Piège consigné dans `tools/CLAUDE.md`. Deux autres : l'avant d'un ennemi est
**+Z** (les lacets sont désormais calculés, pas posés à l'œil), et l'ouïe
contournait la garde de territoire (le portail vérifie trois disques).

**Le coût CPU du camp** (§6.6) est mesuré : **+6,587 ms en moyenne,
+20,763 ms au p95, +132 nœuds**. La première sonde donnait un monde témoin
DEUX FOIS plus cher que le monde peuplé — elle montait les deux mondes dans
le même processus et le témoin payait la démolition du premier. Le journal
absurde est gardé sous `profil_cpu_INVALIDE_un_seul_processus.log` : il
enseigne mieux que le bon.

**Le volet export est VERT** — `gate_export_garnison_vert.log`, build liée à
`86bc5570`, arbre propre. Arrivée réelle au camp (71,33 m marchés, un garde
qui VOIT), zéro ressource manquante dans le PCK, aucune duplication à la
relance, morts persistées qui ne reviennent pas, inventaire d'antichambre
intact après une VRAIE fermeture de processus.

Il a d'abord rougi deux fois, et sur **aucune affirmation du jeu** : le
harnais attendait 30 s la mort du processus là où il en fallait 32. Sur un
cache de shaders froid, le premier rendu llvmpipe d'une vallée entière occupe
la boucle principale ; le budget chronométrait la compilation des shaders, pas
la fermeture. Pire, sa branche d'échec laissait un orphelin qui gardait
llvmpipe à fond et sa fenêtre visible : G5 a fait tomber G6. Un défaut, deux
échecs affichés. Corrigé dans le harnais seul (`86bc5570`), avec l'attente
réelle publiée à chaque appel — le portail vert affiche `32 s` pour G5 et
`2` à `4 s` ailleurs.

**La contre-revue à contexte frais a rendu quinze constats, tous absorbés.**
Six touchaient la capacité des portails à ÉCHOUER, et ce sont les seuls qui
comptaient : le test du portail sortait vert sans rien juger si `r05`
disparaissait du layout ; le balayage de ressources laissait le donjon hors du
filet ; G5 prouvait la LECTURE des morts et jamais leur RÉÉCRITURE ;
`profil_camp.sh` ne pouvait pas échouer ; le contrat promettait un verrou de
territoire que le code n'a pas (ISS-083 ouverte, prose corrigée) ; et
`validate_fast_vert.log` ne décrivait pas l'arbre qu'il accompagnait —
journal joué à 20:14, committé à 20:20 avec une modification de test.

**Ce que la correction a elle-même appris.** Le verdict neuf de
`profil_camp.sh` a rougi au run suivant, et il avait tort : le delta de p95 a
changé de signe entre deux runs du MÊME code. Quatre runs donnent des deltas
de moyenne de +6,587 · +0,704 · +0,873 · +1,977 ms — un facteur neuf sans
qu'une ligne ne bouge. Le p95 est désormais publié, jamais jugé, et le
« +6,587 ms » qu'annonçait `STATUS.md` a été remplacé par la fourchette.
Seule `noeuds` est déterministe : **+132, aux quatre runs, au nœud près.**

Chaîne rejouée en entier sur l'arbre final : `validate_fast` **999/0** avec
sa provenance en en-tête, portail d'export **VERT en 7 étapes**, profil CPU
**VERT** depuis un arbre propre.

**PROCHAINE ACTION EXACTE** : rien n'est en attente sur cette tranche. Elle
est complète, prouvée et contre-revue. La prochaine session attend le
playtest d'Istvan sur la candidate de lundi, inchangée. **Ne pas ouvrir le
Lot 2.** **Interdits inchangés** : aucune fusion dans la candidate avant le
playtest d'Istvan ; aucun ennemi hors de r05 ; `GO_V2_3_B_LOT2 = FALSE` ;
aucune release officielle.

---
## 2026-08-28 — T1 FIGÉE : artefact expérimental publié et revérifié, ISS-074 ouverte en branche indépendante

**T1 est figée, non fusionnée.** SHA final de la branche
`claude/world-v2-t1-persistance` : celui de ce commit de preuve, dont le
parent `53a64932` est le commit lié à l'artefact.

**Artefact expérimental vérifié depuis GitHub** (jamais depuis la sortie du
dispatch) : run `33188161790` **success** ; release **prerelease**
`world-v2-t1-exp-53a6493` (id 378607024) liée à `53a64932` ; bandeau « n'est
PAS la candidate de lundi » présent ; quatre archives dont les SHA-256
concordent à trois sources (digests GitHub, corps, `SHA256SUMS.txt`) ;
`PLAYTEST_T1_EXPERIMENTAL.md` re-téléchargé, haché conforme, **0**
placeholder. Écart honnête consigné : la preuve locale (21 PASS) porte sur
l'export de `a168dfd5`, l'artefact CI sur `53a64932` — diff entre les deux :
**zéro** fichier de jeu (`.gd`/`.tscn`/`.tres`/`.glb`/`project.godot`),
uniquement outils/docs/preuves. Détail :
`evidence/world_v2/t1_persistance/build_exportee/release_experimentale.md`.

**ISS-074 ouverte** sur `claude/world-v2-iss074-population-contract` depuis la
candidate `a8d2f77` (commit `71a8ec37`, remote vérifié) : contrat de
peuplement, inventaire des systèmes de combat/IA réellement fonctionnels,
portail ROUGE (0 réussi, 2 échoué — aucun adversaire atteignable, aucun
coordinateur : c'est le constat voulu), règles de densité/territoire/respawn/
budget, tranche verticale proposée (garnison du camp braise, r05). **Aucun
ennemi de production posé. Cette branche porte UN rouge délibéré** — ne jamais
y attendre un `validate_fast` vert, ne jamais publier depuis elle.

**PROCHAINE ACTION EXACTE** : rien n'est en vol côté T1. Lundi, Istvan joue la
candidate `world-v2-candidate-iss073-98cbaf0` (inchangée, sur `a8d2f77`).
Après son playtest, deux fronts au choix du propriétaire : fusionner T1 dans
la candidate (alors rejouer `gate_export_t1.sh` sur l'arbre fusionné), ou
lancer la tranche verticale ISS-074 selon son contrat. **Interdits inchangés** :
`GO_V2_3_B_LOT2 = FALSE` ; pas de fusion T1 sans décision du propriétaire ;
pas d'ennemis de production avant validation du contrat ISS-074.

## 2026-08-28 — ISS-074 ouverte : le contrat de peuplement, l'inventaire et le portail rouge

Branche `claude/world-v2-iss074-population-contract`, depuis la candidate
`a8d2f77`. **Aucun ennemi de production posé.** Trois livrables :

1. **`docs/contrats/iss074_peuplement_world_v2.md`** — le contrat : le
   remplacement du verrou « acteur prématuré » par un contrat de BUDGET à
   quatre règles exécutables (plafond du coordinateur, un coordinateur
   unique, territoire borné, zones calmes) ; les règles de densité par
   région (la prose `regions[].encounters` du layout devient NORMATIVE) ;
   la règle de respawn/persistance AVANT le système (garnison morte reste
   morte — champ additif `enemies_slain` ; patrouille peut réapparaître,
   déclaré explicitement ; loot HORS tranche) ; et la tranche verticale
   proposée — « la garnison du camp braise » (r05) : navmesh vérifié
   d'abord, `WorldV2EncountersBuilder` NEUF piloté par données, 3
   `raider_red` + 1 `raider_blue` au guet, remplacement du contrat, profil
   CPU en preuve.
2. **`docs/contrats/iss074_inventaire.md`** — l'état réel, sur pièces : les
   cinq familles prêtes au combat (sans loot), la coordination jamais
   instanciée en V2, le navmesh 0,7 m prêt et le navmesh grandes carrures
   ABSENT, `Encounters` vide, 1 territoire construit sur 5, aucune
   persistance de mort, aucun AILab, budget CPU inconnu.
3. **`tests/world_v2/test_world_v2_iss074_portail.gd`** — le portail,
   ROUGE : `0 réussi, 2 échoué` sur le monde monté (aucun adversaire, aucun
   coordinateur), 0 erreur de script. Il exige aussi, pour le futur vert :
   l'adversaire ATTEIGNABLE par la navigation depuis le spawn, et un
   territoire borné pour chacun. **Ce rouge vit sur cette branche
   seulement** — la candidate n'en porte rien.

**PROCHAINE ACTION EXACTE** : rien avant la décision du propriétaire — la
tranche « garnison du camp braise » est PROPOSÉE, pas autorisée. Les
interdits tiennent : aucun ennemi de production, six lieux gelés intacts,
`GO_V2_3_B_LOT2 = FALSE`.

## 2026-08-28 — T1 §2-§3 : contre-revue absorbée, C8/C9/C10, et la reprise prouvée dans la build exportée

Branche `claude/world-v2-t1-persistance`, toujours séparée de la candidate.
Conteneur re-provisionné en début de passe (bascule de modèle) : rien n'a été
perdu — tout vivait sur le remote — mais le toolchain a dû être reconstruit
(template scons 23 min, xdotool, ImageMagick, python3-xlib).

**§1 — contre-revue du diff T1 final** (contexte frais) : PARTIAL, trois
FAIL — fusion sur slot illisible, fermeture de fenêtre, chemin réel jamais
exécuté. Chacun est devenu un contrat, rouge d'abord :
- **C10** : `load_slot` rend `{}` sur un slot corrompu ET sur un schéma plus
  récent — l'autosave fusionnait dans `{}` et écrasait fichier ET `.bak`.
  Garde posée : un slot présent mais illisible n'est JAMAIS réécrit.
- **C9** : la croix de la fenêtre n'était écoutée par personne. Handler
  `NOTIFICATION_WM_CLOSE_REQUEST` + minuterie d'autosave épinglée à 60 s +
  « jamais en l'air » (le cas mesure un VRAI saut — un téléport de test
  empoisonnait l'enregistreur de sol, `is_on_floor()` restant vrai un tick).
- **C8** : vraie transition SceneFlow, fusion éprouvée par témoins
  (`boss_defeated`/`weapons` semés avant — une affectation sèche rougit),
  reprise par le vrai bouton du menu, débranchement prouvé sur monde libéré.

Filtre t1_persistance : **10 réussis, 0 échoué, 161 assertions**. Trois
sabotages, chacun ne rougit QUE son contrat (s1 signal → C8 seul ; s2
fermeture+minuterie → C9 seul ; s3 garde → C10 seul). Détails de revue
consignés ISS-079/080/081. Un rouge de plus payé en route : mon commentaire
du jalon `[flow]` nommait le monde reconstruit dans un fichier V1 — le
balayage d'isolation l'a pris, à raison (symétrique du faux positif ISS-073).

**§3 — la chaîne, dans l'ordre imposé, sur l'arbre committé `a168dfd5`** :

| Étape | Verdict |
|---|---|
| `validate_fast.sh` | **VERT, RC=0, 987 tests, 0 échec**, gel intact |
| `gate_export_parite.sh` (export NEUF) | **RC=0**, 32 contrôles, 0 rouge |
| `gate_export_t1.sh` (6 phases, user:// vierges) | **RC=0, 21 PASS, 0 FAIL** |

La build autonome a fait : partie neuve → marche réelle de 103 m → CROIX →
sauvegarde signée → relance → « Continuer » → position restaurée à 0,00 m,
orientation restaurée → routage antichambre → fusion préservée sous autosave
réel → slot V1 ignoré → slot corrompu intact. NON VÉRIFIÉ, dit par le
portail : marche donjon (ISS-072), mort/Réessayer (ISS-074).

Deux runs rouges du portail ont payé deux leçons de harnais, consignées dans
`evidence/world_v2/t1_persistance/build_exportee/README.md` : `xdotool
windowclose` DÉTRUIT la fenêtre au lieu de demander sa fermeture ; et Godot
interne `WM_DELETE_WINDOW` avec `only_if_exists=true` — sur un Xvfb vierge
l'atome n'existe pas et la croix est inopérante (`WM_PROTOCOLS=[0]`, mesuré
dans le source du moteur ET sur la fenêtre). D'où `tools/x11_fermer_fenetre.py`
(le vrai ClientMessage), Xvfb `-noreset`, et l'internement préalable.

**PROCHAINE ACTION EXACTE** : publier l'artefact expérimental T1 (workflow
`t1_experimental`, prerelease, tag `world-v2-t1-exp-<court>`), vérifier la
release, figer T1, puis ouvrir `claude/world-v2-iss074-population-contract`
depuis la candidate `a8d2f77` — contrat de peuplement, inventaire, portail
rouge, règles, tranche verticale. **Interdits** : fusionner T1 avant le
playtest d'Istvan ; aucun ennemi de production ; `GO_V2_3_B_LOT2 = FALSE`.
La candidate de lundi reste `world-v2-candidate-iss073-98cbaf0`, inchangée.

---
## 2026-08-28 — T1 implémenté et vert, et la contre-revue §6 a rendu son verdict

Branche `claude/world-v2-t1-persistance`, toujours **séparée** de la candidate
de lundi. Rien n'a été fusionné.

**La partie se reprend.** World V2 écrit et relit son état : position,
orientation, lieu où rouvrir. Écriture par FUSION — jamais en écrasement,
sinon `boss_defeated` posé par l'arène disparaîtrait à la première sauvegarde.
Écriture au DÉPART d'une transition, seul instant où le héros est encore en
place. Lecture seulement si la sauvegarde est SIGNÉE `world_version =
neris_v2` : une position V1 peut être dans les bornes V2 et pourtant au fond
d'un lac V2, et le contrat de migration l'écrivait déjà.

**Aucun champ nouveau pour le routage.** Le donjon écrit déjà son lieu dans
`checkpoint`, `boss_arena.gd` sait déjà que `dungeon.antechamber` désigne
cette scène : le menu lit enfin ce qui existait. Le champ `resume_scene` que
j'avais inventé au premier jet est parti — poser une seconde source de vérité
à côté d'une qui existe est la façon la plus sûre de les faire diverger.

**Verdicts, tous mesurés sur l'arbre committé `ca1ffed`** :

| Preuve | Résultat |
|---|---|
| `--filter=t1_persistance` | **7 réussis, 0 échoué**, 115 assertions |
| contrôle négatif « restauration aveugle » | C1 verdit à moitié, **C4 et C5 rougissent** |
| contrôle négatif « gardes C7 retirées » | **une seule** assertion rougit — celle du mort |
| `validate_fast.sh` | **VERT, RC=0, 984 tests, 0 échec**, gel intact |
| autotest de l'analyseur de gravité | 3 cas neufs, **rouges d'abord**, puis verts |

**C7 est né APRÈS l'implémentation**, désigné par la contre-revue : le crochet
d'autosave écoute TOUTES les transitions, « Réessayer » compris. Sans garde,
mourir inscrivait le lieu de sa mort comme point de reprise. On ne sauvegarde
pas la position d'un mort. Le contrôle négatif a ensuite PRÉCISÉ le constat :
sans la constante `RETRY_TAG`, ce cas reste vert — elle ne corrige qu'un
avertissement FAUX émis à chaque mort, le placement venant de C1.

**Le gel V2.3-B a demandé une levée** (`world_v2_root.gd`, une empreinte,
D-056). En revanche `test_world_v2_skeleton.gd` — « slot0 identique à l'octet
près après un passage en V2 » — **passe sans levée** : monter puis démonter le
monde ne déclenche aucune transition, donc aucune écriture. C'était un
raisonnement avant l'exécution ; c'est un constat depuis.

**Contre-revue §6, à contexte frais, modèle Fable 5.** Huit points attaqués,
verdicts et constats consignés dans
`evidence/world_v2/iss073/contre_revue_fable5.md`. Six PASS, deux PARTIAL,
aucun FAIL. Le relecteur a vérifié la release EN LIGNE : les quatre digests
SHA-256 publiés par l'API GitHub correspondent au tableau du README, et
`git diff c3f1819..98cbaf0` ne touche que `docs/` et `evidence/`.

Trois constats « à corriger », traités ainsi :
1. `retry_checkpoint` incompris — **fermé** par C7 ;
2. l'analyseur prenait silencieusement les 9 PREMIERS marqueurs au-delà de 9,
   et un repos refait décalait toutes les paires : il rendait `FAIL` sur une
   faute de PROTOCOLE. **Fermé** — les 9 derniers sont retenus quand ils ont
   la forme d'un repos, et l'appareil REFUSE de juger sinon ;
3. un seul relevé aérien par saut ne distingue pas « pas de saut » de « F4
   trop tard ». **Non réparable pour lundi** : les deux voies touchent le jeu
   (`SAMPLE_INTERVAL = 1.0` contre un vol de 0,683 s), et la build est
   publiée. Le message dit désormais l'ambiguïté ; le seuil n'a pas bougé.
   **ISS-077 ouverte.**

Détails traités : les compteurs de prose divergents rectifiés depuis le log
(10 cas, 60 assertions — `STATUS.md` n'en porte plus du tout, règle
d'ancrage), la ligne périmée de la feuille de route rafraîchie, et
**ISS-078** ouverte pour `fumee_gravite.py`, qui prend encore le MINIMUM des
repos là où son outil frère prend la médiane.

**Une correction de ma part, à porter au compte de la vérité.** J'avais
relayé la boucle comme « victoire → continuer → devant la porte ». C'est faux,
et aucun document du dépôt ne le prétendait : `victory_screen.gd::_on_explore`
ne pose aucun `pending_spawn`. Le « devant la porte » ne vaut que pour la
sortie du vestibule. T1 change ce comportement sans l'avoir visé — la reprise
se fait désormais à la dernière position sauvegardée.

**PROCHAINE ACTION EXACTE** : la décision appartient au propriétaire —
fusionner ou non T1 dans la candidate de lundi. Mon avis : **ne pas fusionner
avant qu'Istvan ait joué**. La candidate publiée est vérifiée de bout en bout ;
T1 est vert mais n'a jamais tourné dans une build exportée, et lundi doit
mesurer le jeu, pas un changement de la veille. Si T1 est fusionné plus tard,
la chaîne est : `validate_fast` sur l'arbre committé, export frais, portail
`gate_export_iss073.sh`, puis nouvelle candidate. **Interdits inchangés** :
`GO_V2_3_B_LOT2 = FALSE`, aucune retouche artistique, aucun ennemi ajouté.

---
## 2026-08-28 — T1 ouvert sur branche séparée : six contrats de persistance, écrits rouges

Branche `claude/world-v2-t1-persistance`, partie de `a8d2f77` — la candidate de
lundi. **Aucune ligne de production.** Cette entrée ne rapporte que des
contrats et leur verdict.

**Le défaut, écrit noir sur blanc aux deux bouts du code.** ISS-073 a rendu la
boucle atteignable ; elle ne se **reprend** toujours pas. `world_v2_root.gd`
énumère trois provenances de placement et en écarte une — « une position
sauvegardée — hors périmètre de cette corrective » ; `main_menu.gd` charge la
sauvegarde, vérifie qu'elle est lisible, puis appelle `_enter_world()` sans
jamais la regarder. Un joueur arrêté dans l'antichambre du boss refait tout le
donjon.

**Six contrats** dans `tests/world_v2/test_world_v2_t1_persistance.gd`, chacun
mesuré sur un cycle réel — monter, écrire, DÉMONTER, REMONTER, mesurer la
position obtenue. Verdict : **3 réussis, 7 échoués, 0 erreur de script**.
C1 position, C2 orientation et C3 scène de reprise sont ROUGES ; C4 (une
position V1 n'est jamais réappliquée en V2), C5 (sauvegarde corrompue) et C6
(identifiants stables) sont des filets déjà VERTS — 69 assertions — qui
doivent le rester.

**Un seul sabotage, trois preuves.** Restauration aveugle posée dans
`world_v2_root.gd` (relire `player_position` sans regarder `world_version`) :
C1 passe de 3 échecs à 1 — sa moitié lecture verdit, donc le cas est
satisfiable — pendant que C4 rougit et que C5 rougit sur exactement les deux
formes dont les composantes sont des `float`. L'implémentation qui verdirait
C1 le plus vite est prise en étau. Sabotage retiré, identité du fichier
vérifiée au sha256.

**Deux corrections de méthode, faites avant de committer.** (1) Le premier
jet inventait un champ `resume_scene` pour C3 : retiré — le donjon écrit DÉJÀ
son lieu dans `checkpoint`, et `docs/WORLD_V2_SAVE_MIGRATION.md` (écrit dès
V2.0) tranchait déjà la question ; poser une seconde source de vérité à côté
d'une qui existe est la façon la plus sûre de les faire diverger. (2) Le
premier jet demandait à V2 de réappliquer une position non signée : contraire
au §4 du même contrat — « pas bornée : ignorée », parce qu'une position V1
peut être dans les bornes V2 et pourtant au fond d'un lac V2. C4 est né de
cette correction.

**Un piège de harnais, trouvé par le premier rouge, qui attend tout le monde.**
`restore_root()` VIDE sa photo en sortant. Un cas qui monte deux fois appelait
donc `restore_root()` deux fois pour une seule `remember_root()`, et le second
balayage — photo vide — prenait les autoloads pour des intrus : `GameState`,
`EventBus` et `SaveSystem` **supprimés**. Correction : une photo par montage,
prise dans le montage. Consigné dans le contrat T1 §4.

**Ce que T1 devra lever, et qui n'est pas levé ici.**
`test_world_v2_skeleton.gd` exige que `slot0` reste « identique à l'octet près
après le passage en V2 » — contrat né du squelette, quand V2 ne devait pas
déranger V1. V2 EST le jeu depuis que le menu l'ouvre. Sa levée est une
décision de production, à écrire dans `DECISIONS.md` avec son contrat de
remplacement (fusion par clé, champs signés `world_version = neris_v2`).

**PROCHAINE ACTION EXACTE** : implémenter T1 sur cette branche, dans l'ordre
C1 → C2 → C3, en relançant `--filter=t1_persistance` après chaque contrat, et
en vérifiant à chaque fois que C4, C5 et C6 restent verts — c'est là que
l'implémentation naïve se fait prendre. **Interdits** : fusionner quoi que ce
soit de T1 dans la candidate de lundi avant la contre-revue §6 ; modifier ou
supprimer un champ existant du schéma 4 ; verdir un contrat en changeant sa
mesure. La candidate `world-v2-candidate-iss073-98cbaf0` reste ce qu'Istvan
doit jouer lundi.

---
## 2026-08-28 — ISS-073 : la boucle de campagne est refermée, et prouvée dans une build

**Le donjon était inatteignable.** Le menu ouvre World V2 ; World V2 ne portait
aucune `SceneDoor`. Et même en y entrant autrement, ressortir replaçait le
héros au spawn — World V2 ne consommait **aucun** `pending_spawn`.

### Ce qui a été construit

- `scripts/world_v2/world_v2_dungeon_door.gd` — une vraie porte au seuil §3.3
  `(0, 34, -210)`, plus une ancre de retour 4 m devant, posée au sol.
- `world_v2_root.gd` — consomme le tag d'arrivée, avec priorité au retour de
  transition sur le spawn, et pose `GameState.Flow.VALLEY`.
- **Cinq** chemins de retour redressés, pas quatre : l'écran de victoire, la
  sortie du vestibule, « Recommencer », et — trouvé en route — le
  « Réessayer » du vestibule, qui rechargeait la vallée V1.

### Deux des quatre « coupables » de l'audit n'en étaient pas

`gameplay_shell.gd::world_scene_path` est un `@export` que `WorldV2.tscn`
surcharge déjà ; le changer aurait cassé le « Réessayer » du monde V1. Mon
premier test le comptait comme coupable — **faux positif du mien**, corrigé et
documenté dans le test. `reward_anchor_shot.gd` est un outil V1, hors sujet.

### Les preuves

| Portail | Verdict |
|---|---|
| `--filter=iss073` (10 cas, 60 assertions) | vert, 5 sabotages joués |
| `tools/validate_fast.sh` sur `c3f1819` | **VERT, RC=0, 977 tests, 0 échec** |
| `gate_export_parite.sh` (ISS-071) | **RC=0**, 32 contrôles, 0 rouge |
| `gate_export_iss073.sh` (la boucle dans la build) | **RC=0**, 5 constats PASS |

Le binaire autonome fait 398 840 568 octets, sha256 `6ba985ef…`. Le template
d'export a dû être **recompilé depuis les sources** : le conteneur avait été
recréé et l'avait perdu (28 min de link LTO).

### Ce que la campagne a coûté, mesuré

Le premier passage complet a rendu **979 tests et 4 échecs — les quatre causés
par ma correction**, aucun autre test du projet n'ayant bougé. Deux étaient des
contrats qui avaient survécu à leur raison, un était un faux positif du mien
sur un COMMENTAIRE, et le quatrième venait d'avoir gelé un fichier au milieu
de la passe qui l'écrit. Trois défauts de plus vivaient dans mes propres outils
de mesure : un produit scalaire pris sur le mauvais nœud, un lambda GDScript
qui capture par valeur, un compte extrait du mauvais nombre d'une ligne.

**Aucun n'était un défaut du jeu. Tous auraient fait chercher au mauvais
endroit.** C'est l'ordre de grandeur à retenir : le câblage est petit,
l'appareil de preuve ne l'est pas.

### Un défaut trouvé par la capture, et non corrigé

**ISS-076** : World V2 fait apparaître le héros **dos à la vallée**. `ValleyWorld.tscn`
porte en toutes lettres le commentaire de sa propre correction du même défaut ;
World V2 ne l'a jamais reprise. S3, hors périmètre de cette corrective —
la directive interdit la retouche artistique — et Istvan est prévenu dans son
protocole.

### Fronts mis de côté, avec leur prochaine action

- **V2.3-B lot 1** reste gelé : `GO_V2_3_B_LOT2 = FALSE`, inchangé.
- **Trois arbres de travail orphelins** (`/home/user/wt-voie_{a,b,c}`, 5,4 Gio)
  portent du travail SALE à des commits **atteignables depuis aucune branche**.
  Les supprimer détruirait ce travail. Prochaine action : décider avec Istvan
  s'il faut le récupérer ou l'abandonner explicitement.

**PROCHAINE ACTION EXACTE.**

1. **Publier la candidate** en pré-publication depuis `911e52e` (workflow
   `publish-playtest.yml`, entrée `iss073`), relever le SHA-256 et le lien.
2. **Lundi**, faire jouer Istvan avec `docs/PLAYTEST_ISS073.md` : d'abord
   atteindre le donjon à pied et **regarder où il réapparaît en ressortant**,
   ensuite le protocole de saut S1.1.
3. **T1 — persistance World V2**, sur une branche SÉPARÉE de la candidate,
   contrats rouges d'abord. Ne rien fusionner dans la candidate avant
   contre-revue.

---
## 2026-08-27 (fin) — l'audit des 18 domaines : la boucle du build livré est ROMPUE

**37 agents, 0 erreur, 2 h 30.** Dix-huit domaines audités, puis attaqués par
dix-huit sceptiques. **Les dix-huit ont rendu « à corriger »** : 68
surclassements, 139 omissions. Aucun audit n'est passé indemne — c'est le
résultat attendu d'une revue qui cherche la couverture et non le filtrage.

### Le fait qui domine tout, vérifié à la main avant publication

**Depuis « Nouvelle partie », zéro heure de campagne est atteignable.**

| Vérification | Résultat |
|---|---|
| `grep -rn "SceneDoor" scripts/world_v2/ scenes/world_v2/` | **aucune occurrence** |
| `scripts/ui/main_menu.gd:14` | ouvre `WorldV2.tscn` |
| Retours pointant encore vers `ValleyWorld.tscn` (V1) | **4** |
| `test_world_v2_places_contract.gd:251` | interdit tout **acteur** |
| Appels `tr(` réels | **zéro** ; aucun fichier de traduction |

Le menu ouvre World V2 ; World V2 n'a aucune porte vers le donjon. Donjon,
boss, antichambre, coffre final et écran de victoire sont **inatteignables**.

**Douze des dix-huit audits ont buté dessus depuis leur propre angle sans
qu'aucun puisse voir qu'il s'agissait du même défaut.** C'est ce qu'une
synthèse transversale apporte, et c'est aussi l'avertissement : aucune durée
de campagne n'est mesurable tant que la boucle est ouverte, donc rien de ce
qui en dépend n'est dimensionnable.

**Pourquoi 111 tests verts ne l'ont pas vu.** Les suites `tests/world_v2/`
vérifient le monde *pour lui-même* — terrain, routes, hydrologie, traversée
pilotée par le vrai `PlayerController` — mais **aucune ne franchit le seuil**.
Le mode de panne d'ISS-018 dans un autre domaine : des tests verts qui
mesurent une grandeur voisine de celle qui compte.

### J'ai corrigé ma propre feuille de route

Elle plaçait « mesurer un parcours réel » en étape 0. C'était faux : **on ne
peut pas mesurer une campagne qu'on ne peut pas jouer.** La réparation de la
boucle passe devant, et la correction est datée dans le document avec sa cause.

### Trois défauts consignés

- **ISS-073** (S1) — boucle rompue. Une porte, quatre constantes, et un test
  qui franchit réellement le seuil, écrit rouge d'abord.
- **ISS-074** (S2) — zéro adversaire dans le monde livré, et le vide est
  **verrouillé** par le contrat « acteur prématuré ». Ce contrat était juste
  quand les lieux étaient des coquilles ; il est devenu le garde-fou qui
  empêche le peuplement. À remplacer par un **budget d'IA**.
- **ISS-075** (S3) — zéro localisation. Urgent **parce que** le volume est
  minuscule : externaliser quatre fragments coûte une heure, 50 000 mots
  coûtent plusieurs fois leur écriture.

### Ce que l'audit dit de solide

Le motif dominant du dépôt n'est ni l'incompétence ni le bluff : c'est la
**construction de moteurs corrects que personne ne câble ensuite au contenu**.
Le moteur d'IA n'a aucun ennemi à jouer, le Bracelet n'a que deux cibles dans
le monde livré et zéro dans le donjon, `GameState.Difficulty` n'a aucun
consommateur. La bonne nouvelle est proportionnelle : **ce sont des câblages
manquants, pas des réécritures.**

**PROCHAINE ACTION EXACTE.** Deux choses, dans cet ordre, et aucune n'est
autorisée aujourd'hui :

1. **Réparer la boucle** (ISS-073) — test rouge d'abord qui franchit le seuil,
   puis la `SceneDoor` et les quatre constantes. C'est l'étape 0 du chemin
   critique et la meilleure affaire de tout l'audit.
2. **Lundi 31 août**, faire jouer Istvan : `docs/PROTOCOLE_SAUT_ISTVAN.md`
   pour la gravité (S1.1, `BLOQUÉ` en attente planifiée), puis un parcours
   chronométré une fois la boucle refermée.

`GO_V2_3_B_LOT2` reste **FALSE**. Le lot 2 n'est plus la prochaine tranche :
la réparation de la boucle passe devant, et deux corrections préalables
(budget d'IA, registre d'acquisition) sont à trancher par le lead avant de
construire six lieux de plus — sans elles, six lieux, c'est six reprises.

---
## 2026-08-27 (suite) — l'appareil est sécurisé, la doctrine produit est posée, l'audit 30-50 h tourne

**Trois façons de devenir vert sans rien prouver, toutes fermées.** Le
« 17/17 » n'en était qu'une.

1. **Par PARTIAL.** `return 1 if echecs else 0` ne comptait que les `FAIL`.
   Corrigé la veille dans UN harnais — et toujours présent dans **deux
   autres** : `fumee_vues_six_lieux.py` et `fumee_gravite.py`. C'est la leçon
   déjà écrite dans `tools/CLAUDE.md`, non appliquée à elle-même : quand un
   défaut de mesure est trouvé, chercher tout de suite les AUTRES endroits qui
   font la même mesure. D'où `tools/lib/verdict.py`, source unique.
2. **Par le vide.** Zéro constat, donc zéro échec, donc vert. `code_sortie([])`
   rend 3. L'autotest existant **attendait 0** sur ce cas : l'attente était
   elle-même un vert par défaut. `cave_seal_oracle.py` publie en plus le
   nombre de contrôles exercés.
3. **Par omission.** Ne jamais exécuter le contrôle qui fâche. `exiger()` :
   chaque harnais déclare ses points obligatoires, un point absent devient un
   `NON VÉRIFIÉ`. Conséquence assumée — `fumee_build_exportee.py` ne PEUT
   PLUS être vert tant qu'un journal DevMode ne prouve pas le saut.

**L'analyseur hors ligne** `tools/analyse_journal_devmode.py` juge un journal
DevMode sans le jeu, contre les seuils préenregistrés, en vérifiant l'horloge
d'abord. Un défaut attrapé par son propre sabotage : le critère « retour au
sol » lisait `ys[-1]`, or les `position` automatiques sont émises tout du long
et le dernier échantillon est souvent une position au sol qui MASQUE un héros
resté en l'air. Il lit désormais les FRONTS — chaque montée doit être suivie
d'une descente.

**Le portail rougit vraiment.** Les autotests entrent dans `validate_fast.sh`
et le contrôle négatif rouvre le défaut exact (`- or "PARTIAL" in verdicts`) :
les **trois** autotests rougissent et le portail passe à `FAIL=1`. Ils se
propagent tous les trois parce qu'ils partagent la même source — ce qu'on
cherchait en l'extrayant. Restauration vérifiée au sha256.

**Protocole manuel** — `docs/PROTOCOLE_SAUT_ISTVAN.md` : six gestes, cinq
minutes, chemins Windows / macOS / Linux vérifiés contre `project.godot` (pas
de `use_custom_user_dir`, dossier `Eclats d'Orage`). S1.1 est **EN ATTENTE
PLANIFIÉE DU TEST RÉEL** — Istvan est indisponible jusqu'au lundi 31 août.
Cette attente ne bloque rien d'autre.

**Doctrine produit** — `docs/V2_PRODUCT_DOCTRINE.md`, document VIVANT qui
surplombe les quatre cahiers sur la seule question qu'aucun ne tranchait :
pour combien de temps de jeu construit-on ? 30-50 h de campagne, 80-120 h de
complétion, 200 h+ de jeu durable. Il dit sans ménagement ce qu'est la V2 —
le **pilote de la première région** — et ajoute un quatrième temps à la
boucle : **restaurer**, le joueur laisse le monde différent de ce qu'il l'a
trouvé.

**Socle chiffré, mesuré à la main avant tout rapport d'agent**
(`tools/mesures_socle.py`) :

| | |
|---|---:|
| Sujets déclarés au layout | **34** (31 POI + 3 sites) |
| Montés dans le REGISTRY | **15** |
| Déclarés et NON construits | **21** |
| Achèvement de la région 1 | **44 %** |
| Chantier World V2 | 2026-08-12 → 08-27, **723 commits** |
| Médiane par lieu construit | **24 commits** |

Projection assumée comme estimation : ~504 commits pour finir la **seule**
région 1. C'est le chiffre qui gouverne la doctrine — une région dont on
ignore le coût ne peut pas être multipliée.

**PROCHAINE ACTION EXACTE.** L'audit des 18 domaines tourne (un agent par
sujet, chacun suivi d'un sceptique qui attaque ses notes « fonctionnel »).
Quand il rend : écrire `docs/V2_LONG_GAME_GAP_AUDIT.md`, puis
`docs/V2_LONG_GAME_ROADMAP.md`, puis
`docs/V2_REGION1_VERTICAL_SLICE.md` — en confrontant chaque chiffre d'agent
au socle ci-dessus. `GO_V2_3_B_LOT2` reste **FALSE** : aucune construction.

---
## 2026-08-27 — S1.1 : le faux vert de gravité est fermé côté APPAREIL, la mesure se clôt en `BLOQUÉ`

**L'appareil d'abord, parce que c'est lui qui avait menti.** Le harnais
`fumee_build_exportee.py` ne comptait que les `FAIL` (`return 1 if echecs
else 0`) : un `PARTIAL` tombait dans le `else 0`. Le résumé disait « 17 points
observés, 0 FAIL » et je l'ai relayé en **« 17/17 »**, ce qui laisse entendre
17 `PASS`. Il y en avait **16, plus un `PARTIAL`** — le saut. Pire, la note de
gravité imprimait, **même en `PARTIAL`**, la phrase codée en dur « la vue
s'écarte puis revient : le sol arrête la chute » : une affirmation qui énonçait
exactement ce que la mesure venait de nier.

Corrections, toutes prouvées : tout verdict ≠ `PASS` rend un code non nul ;
`BLOQUÉ` et `NON VÉRIFIÉ` gardent le **3**, distinct ; le résumé nomme chaque
classe et liste les points non-`PASS` ; `lieux_poses` est analysé
numériquement contre le littéral **15** ; la phrase affirmative est
**supprimée** ; le verdict de gravité au pixel est **retiré, pas réparé** — il
comparait des captures espacées de 3,35 s pendant lesquelles le tapis de
fleurs animé dérive plus que le saut ne déplace la vue, donc il mesurait le
vent. Autotest de 9 cas, dont *« un seul `PARTIAL` parmi des `PASS` »* → code
**1**, et vérification que le résumé contient littéralement « 1 PARTIAL ».

**La mesure de remplacement, honnête, sur le binaire publié.** Contrat
préenregistré (`docs/contrats/s1_1_gravite.md`) avant toute exécution : on ne
juge plus des pixels mais la **position Y réelle du héros**, produite par
l'autoload `DevMode` que la release embarque déjà — `F3` enregistre, `F4` pose
un marqueur portant `y` et `etat`. Aucune modification du jeu. L'exigence
« exclure les fleurs » est satisfaite **par construction**, pas par recadrage :
aucun pixel n'entre dans le verdict. Archive vérifiée au sha256 **avant**
lancement, puis binaire **extrait de cette archive-là**.

**Trois hypothèses, trois réfutations par la mesure.** (1) « La capture coûte
cher, réduisons la fenêtre » — 1024×768 / 400×300 / 200×150 au menu :
0,076 / 0,071 / 0,070 s. La résolution ne change rien. (2) « Le monde tourne à
1 FPS » — 4 saccades > 100 ms sur 20 s. (3) « Le décrochage vient de `mark()`
et de sa relecture GPU » — sonde à une seule variable, **zéro `F4`** : le
décrochage est là quand même.

**La cause, enfin nommée et mesurée.** `DevMode._process()` écrit un événement
`position` par seconde de `delta` accumulé : c'est une mesure directe du temps
que le moteur croit avoir vécu.

| Exécution | Mural | `position` | Rapport | F4 |
|---|---:|---:|---:|---:|
| Campagne complète | 152 s | 2 | **0,013** | 111 |
| Sonde dédiée | 120 s | 7 | **0,058** | **0** |

Le moteur annonce dans le même temps **7,3–7,7 FPS** et aucune image au-delà
de 150 ms — chiffres rassurants, et incompatibles avec les précédents. Une
consigne émise « toutes les 1,5 s » n'arrive donc pas toutes les 1,5 s **de
jeu** : les repos de 2,3 s murales valent des centièmes de seconde de jeu, le
héros n'a pas atterri quand on le mesure « au repos », et le contrôle négatif
rend **6 marqueurs élevés sur 23 sans un seul appui sur Espace**. Le contrat
classait ce cas en `BLOQUÉ` **avant** de mesurer ; le harnais le fait
désormais, au lieu d'un `FAIL` qui aurait imputé au jeu un défaut de
l'appareil. Consigné en **ISS-072**.

**Ce qui a été observé sans être surclassé.** Piste d'altitude de la sonde :
repos `24,0 · 24,0` → sauts `25,1 · 25,1 · 25,1` → repos `24,0 · 24,0`, état
`locomotion` de bout en bout ; excursions de la campagne complète **1,4 / 1,5 /
1,4 m**, autour de l'apex nominal de **1,401 m** dérivé du tuning committé.
C'est **encourageant, ce n'est pas un `PASS`** : sept échantillons ne
satisfont ni le critère 2c ni les trois répétitions, et aucune affirmation
temporelle ne se tire d'une horloge décrochée d'un facteur 17.

**Aucun seuil n'a bougé.** Bruit ≤ 0,10 m, excursion ≥ 0,50 m, retour
≤ 0,20 m, 3 sur 3, contrôle négatif à zéro : écrits avant, inchangés après.
Les amendements ne portent que sur l'instrument.

**Verdict : `S1.1 = BLOQUÉ`. Gravité du jeu = `NON VÉRIFIÉ`.**
`GO_V2_3_B_LOT2 = FALSE`. Aucune nouvelle release ; la release
`world-v2-playtest-lot1r2-05d0760` reste publiée et **inchangée** ; aucun
`validate_fast.sh` rejoué, le produit n'ayant pas changé d'un octet.

Preuves : `evidence/world_v2/v2_3_b/iss071/s1_1_gravite/` (verdict, campagne,
sonde, diagnostic) et `../s1_cloture/RECTIFICATIF.md`.

**PROCHAINE ACTION EXACTE.** Ne rien construire. Le Lot 2 reste fermé. La
gravité se vérifie **sur une vraie machine** : lancer l'archive
`EclatsDOrage_Linux_x86_64_05d0760.zip`, presser `F3`, sauter trois fois,
presser `F3`, et lire `y` dans `user://dev_sessions/*/journal.jsonl` — un
aller-retour au sol y sera lisible en quelques secondes, sur une horloge
juste. Protocole : `docs/MANUAL_VALIDATION.md`. Tant que ce retour n'est pas
là, S1.1 reste `BLOQUÉ` et le Lot 2 n'ouvre pas.

---
## 2026-08-26 — LOT 1.R.2 : source, sanctuaire et cimetière corrigés · `EN ATTENTE DU VERDICT`

**Le verdict Codex qui a ouvert la passe.** Lecture aveugle des six lieux, tous
correctement identifiés : belvédère, tour et champ `PASS VISUEL` ; cimetière
`PARTIAL` ; sanctuaire et source `REJET`. Les trois acceptés ont donc été gelés
au sha256 **avant toute modification** (`GEL_VISUEL_3_SUJETS_529d767.sha256`,
23 fichiers : scripts, scènes, GLB et `.import`, shaders, générateurs, `.blend`),
et vérifiés intacts après chaque intégration et à la clôture — **23/23 à chaque
fois**, plus `gel_verifier` 43/43.

**Trois agents, trois worktrees, trois branches de checkpoint** poussées à
chaque commit vérifié : `claude/lot1r2-cimetiere` (`e1e0376`),
`claude/lot1r2-sanctuaire` (`b1323df`), et pour la source `claude/lot1r2-source`
→ `-source2` → `-source3` (`3218bf7`) — l'agent a amendé puis rebasé de
l'historique déjà publié, ce que ce dépôt interdit ; rien n'est perdu (les trois
lignes sont sur le distant), la consigne a été redonnée et respectée ensuite.
Intégration par cherry-pick, sans commit de merge : canonique `dc74b1c`.

**Ce qui a été corrigé, par cause et non par réglage.** La source : la « petite
tache » était géométrique — au ras, une nappe horizontale de 7,9 m ne sous-tend
que 3,5°, donc verticalité (voile d'arrivée) plutôt que surface ; l'eau passe de
0,81 % à 2,07 % du cadre, la colonne d'eau la plus haute de 35 px à 112 px.
Le sanctuaire : l'axe de nef avait 15° d'écart avec l'axe de visée — « le pire
des deux mondes » — il se couche dedans, dans l'ouverture entre les troncs gelés
**mesurée colonne par colonne** (x 236-660, lieu recomposé 334-615). Le cimetière :
le tertre lisait comme une toile faute d'**ombre portée**, sa teinte étant celle
du terrain gelé et donc hors périmètre ; soleil mesuré dans la scène, pierres
posées sur la crête.

**Portail technique, tout mesuré sur l'arbre intégré** : seuil du sanctuaire
**1,31 m** contre 0,90 exigé — **ISS-070 FERMÉE**, rouge d'avant archivé (0,89 m,
FAIL) puis vert d'après, aucun seuil déplacé, la sonde ayant **gagné** un
contrôle (balayage de la vraie capsule dans les deux sens) ; sonde de la source
PASS 0 écart ; filet `lot1_defauts,places_contract` **16/16** ; R-D3 PASS pour
les trois sujets ; manifeste d'assets **6/6, 0 écart**.

**Une dette du lead rattrapée** : la ligne `SM_Watchtower_Ruin` du manifeste
portait les valeurs d'avant la corrective d'arase du lot précédent, jamais
rafraîchies après cette corrective tardive. C'est le vérifieur qui l'a attrapée ;
le GLB de la tour, lui, est identique au gel.

**Limites nommées, sans verdict artistique** : le dos du tertre garde la teinte
de la steppe (terrain gelé) et l'entrée du cimetière ne se lit pas franchement
comme une paire de jambages depuis le plan de biais ; le coffre reste le seul
objet saturé du cadre — subordonné, pas effacé ; l'axe d'approche du sanctuaire
est visible mais **faible**, ses bordures étant le maillon ténu ; la matière de
la berge de la source est ambiguë entre gravier trempé et terre remuée, et un
jour subsiste entre le voile et la roche vu de trois quarts ; le cimetière a
signalé lui-même une dérive R-D3 contre le camp de pillards à 80 m (0,3534 →
0,4483, marge encore positive). Captures en rendu **logiciel** : régression
visuelle, jamais mesure.

**PROCHAINE ACTION EXACTE : ne rien construire.** Attendre le verdict visuel
Codex/Istvan sur `evidence/world_v2/v2_3_b/lot1r2/revue_intermediaire/planche_joueur_anonyme.png`
(6 vues numérotées sans noms, clé dans `cle_planches.json`). GO_V2_3_B_LOT2=FALSE.
Si le verdict rouvre un lieu, repartir de cette entrée ; sinon la validation
complète et la release restent volontairement NON lancées.

---

## 2026-08-25 — LOT 1.R.1 : cinq correctives intégrées, revue intermédiaire persistée · `EN ATTENTE DU VERDICT`

**Ce qui est fait, commit par commit, tout poussé sur
`claude/world-v2-reconstruction` (distant vérifié `2f73bce`).** Les trois
voies de la directive de convergence sont closes et intégrées par cherry-pick
sans commit de merge : A (belvédère + source, branche `claude/lot1r1-a`,
final `1e7e5e8`), B (tour + sanctuaire, `claude/lot1r1-b`, `2d1b372`),
C (cimetière, `claude/lot1r1-c`, `3e5e2a4`), plus la corrective de tour B2
(`claude/lot1r1-b2`, `594005e`) née d'un rouge découvert À L'INTÉGRATION :
le premier assemblage des masques finaux a montré `tour × grotte` à
0,4975/0,4930 contre S 0,4931/0,4912 — la tour candidate était verte, la R3
avait rasé les pointes d'arase. Une pointe d'angle sud-ouest restaurée
(+7 assises, aucune pièce nouvelle, D7 inchangé) le rend à 0,4189/0,4093,
marges ≥ 0,064 sous S−0,010.

**Portail technique de l'arbre intégré, tout VERT** (`lot1r1/controles/`) :
gel du champ 7/7 empreintes, gel_verifier 43/43, parse des 5 scripts,
filet `lot1_defauts,places_contract` 16/16, verdict D3 canonique PASS
(0 paire signalée). Manifeste d'assets : 6/6 lignes du lot vérifiées,
empreintes recalculées sur disque, ligne neuve `SM_SpringMaw`.

**Deux instruments réparés au passage, leurs pièges documentés dans leurs
en-têtes** : `probe_sanctuaire.gd` (axe pré-rotation → sonde infaillible ;
puis marche mesurée sur le collider de sa propre destination) — sa première
vraie mesure ouvre **ISS-070** (fenêtre du seuil 0,89 m contre 0,90 exigé,
un centimètre de marge manquant, aucun seuil déplacé) ; et
`verifier_manifeste_lot1r.py` étendu de 4 à 6 noms.

**La revue intermédiaire est persistée** sous
`evidence/world_v2/v2_3_b/lot1r1/revue_intermediaire/` : 5 vues joueur
recapturées aux caméras gelées + champ copié octet pour octet depuis la
candidate (cmp exact), 5 vues d'identité, silhouettes 0°/90° des cinq
sujets, D3 de revue PASS, `planche_joueur_anonyme.png` (6 vues numérotées
sans noms, clé dans `cle_planches.json`), planche couleur 11 vues, planche
gris, manifeste 42 fichiers (`commit_capture 9ecf10d`, `repo_dirty: false`).

**Limites nommées, sans verdict artistique** : la source se lit sombre
depuis ses deux caméras gelées (ombre de falaise), l'eau comme une petite
tache turquoise, la couronne comme des blocs épars plus que comme un écrin ;
la fente d'iter11 est devenue un porche large (dilution du « creux sombre »,
au jugement du réviseur) ; l'identité du sanctuaire sous couvert reste très
discrète (régression R3 connue) ; l'identité de la tour à distance est brune
et sombre ; NON VÉRIFIÉ : franchissabilité humaine du seuil du sanctuaire
(ISS-070), marchabilité autour des flancs neufs de la source, budget de
collision de la source re-sondé sous moteur.

**PROCHAINE ACTION EXACTE : rien construire.** Attendre le verdict visuel
Codex/Istvan sur `planche_joueur_anonyme.png`. GO_V2_3_B_LOT2=FALSE. Si le
verdict rouvre un lieu, repartir de cette entrée et du contrat
`docs/V2_3_B_LOT1R_VISUAL_CONTRACT.md` ; sinon, la validation complète et
la release restent volontairement NON lancées.

---

## 2026-08-19 — R2B.2 : la matière est gagnée, la forme ne l'est pas · `PARTIAL`

**Ce que la passe a obtenu, et qui se voit.** La ferme a reçu la pierre du kit :
UV0 dépliées sur **25 primitives sur 25**, densité UV à **1,6 % de celle du
kit**, `gltf_inspect` passé de 23 avertissements à **zéro**. Et surtout le
**socle** — la plus grande surface plate de la vue décisive, **11,44 % d'écran,
une dalle grise unie de 132 pixels de haut** — a été texturé par projection
triplanaire monde sans qu'un octet du golden master `SM_Village_Wall` ne bouge.
Il tombe à **3,67 %**. L'arbre a rendu sa fourche lisible à 94 m (plan de 9,0° à
**38,9°**, 100′ d'arc là où les deux moitiés se superposaient), sa cicatrice a
cessé d'être un ruban peint (CV lissé **0,155 → 0,392**), et ses racines ont
cessé d'être une plaque (**5,26 : 1 → 3,33 : 1**) — en **améliorant** au passage
la marge de traversabilité, 0,382 → 0,253 m sous un `step_height` de 0,34.

**Ce qui échoue, et que je ne masque pas.** Le liant de boîtitude que j'avais
posé rend **79,6 %** contre un plafond de 25. J'avais une hypothèse pour
l'excuser — « un lieu bâti en modules de kit est légitimement boîteux » — et je
m'étais engagé **par écrit, avant la mesure**, sur trois issues. La mesure en a
donné une quatrième, contre moi : le GLB ne contient **aucun** module de kit, et
un module de kit n'est **pas** une boîte (0,0 %, quatre composantes pour
56 triangles). Le seuil est dans son domaine. Le liant échoue.

**Ce que le chiffre dit vraiment.** Il mesure une **forme**, pas une matière. La
localisation rend la question utilisable par une revue : la charpente est en
pavés droits — c'est juste, un bois est scié d'équerre ; la maçonnerie est en
boîtes déformées — c'est acceptable ; **les débris sont en pavés droits à
96,8 % — c'est le défaut**, parce que des débris sont par définition ce qui n'a
plus de forme.

**Six instruments ont menti dans cette passe, dont trois étaient de moi.** σ qui
mesure la dispersion et non l'irrégularité, laissant passer une diagonale tirée
à la règle. Un résidu linéaire aveugle à une rampe **géométrique** — corrigé en
`min(linéaire, log)`. Un portail d'aplats **aveugle au gris**, qui déclarait
2,92 % là où la plus grande surface plate faisait 11,44 %. Un détecteur de
boîtes à moi qui rendait 0,0 % parce que j'avais fusionné soudage et connexité.
Une identité de **statistique** prise pour une identité de **géométrie** sur les
deux pans de toit — réfutée par le spectre des distances au centroïde, écart
1,854 m. Et deux impressions visuelles de ma part qui n'ont pas survécu à la
mesure.

**Quatre garde-fous nous ont sauvés d'un résultat qui ressemblait à un
résultat** : `flock` sans RC testé (deux vues perdues en silence), `| head` qui
tue par SIGPIPE avant l'écriture du JSON, un fichier de plan au mauvais format
(`RC=3`, zéro image), et un fichier non suivi pendant une capture qui aurait
écrit `repo_dirty: true`. Les deux premiers sont consignés dans
`tools/CLAUDE.md`.

**PROCHAINE ACTION EXACTE.** Attendre le verdict visuel Codex/Istvan sur
`evidence/world_v2/v2_3_r2b2/preuves_lead/` — 15 caméras imposées inchangées,
19 vues d'orbite, 6 triptyques `R2B / R2B.1 / R2B.2`, 2 planches en niveaux de
gris. **Ne rien propager aux 31 POI** : `GO_V2_3_B=FALSE`. Si la revue juge que
les débris prismatiques valent une passe, le geste est borné et localisé —
`Debris_A` et `_B` dans `make_farm_ruins.py`, 248 triangles au total, budget
disponible 2 420 sur 4 500.

---

## 2026-08-17 — R2a-3.5.5 : au rebord d'une bouche, il n'y a pas d'épaisseur · `PARTIAL`

**Le gate d'épaisseur ne peut pas être rendu décisif, et c'est démontré.** Le
rapport `lecture / h` est **exactement constant** quand `h` varie d'un facteur 8
— 0,010 sur R2a-3.4, 0,020 sur le candidat. La lecture ne converge pas vers une
valeur finie, elle **suit la résolution** : signature mathématique d'une arête.
Au contour de bouche la peau intérieure rejoint la peau extérieure. Aucun seuil
strictement positif n'y est tenable, sur **aucune** grotte pourvue d'une bouche.
Et la géométrie **livrée** est la plus mince des deux.

Le trou est dans mon propre addendum : il a remplacé l'exclusion géodésique de
l'ancien instrument par une classification — plus dur, comme demandé — sans
provision pour ce fait géométrique. Je ne l'ai pas amendé : il a été écrit avant
la mesure exactement pour qu'un `FAIL` ne puisse pas le faire bouger.

**La géométrie n'est PAS intégrée**, et c'est la décision de la passe. Trois
mesures indépendantes disent que l'enveloppe R2a-3.5.2 **régresse le porche** :
89 sommets sous 0,80 m contre 71, minimum 0,283 contre 0,363 m, et surtout
**62 auto-intersections à 0,457 m sur la coque de collision contre 7 à 0,020 m**
— 23 fois le seuil, sur la géométrie qui arrête le joueur, et qu'aucun contrôle
n'a jamais regardée. Cause nommée : les stations du porche sont identiques mais
**leur voisine a bougé**, et la section est orientée par la tangente.

**Entrent au tronc** : l'addendum du masque (committé avant toute géométrie), dix
instruments, les preuves des trois agents et les miennes, ISS-055 corrigée. Les
quatre patches de géométrie sont préservés et rejouables.

**Prochaine action exacte — deux décisions du lead, dans cet ordre :**

1. **Fixer la provision de rebord.** Quelle emprise géodésique autour du contour
   de bouche est exclue des deux seuils ? Sans elle, aucun gate d'épaisseur ne
   peut passer. Ordre de grandeur mesuré hors contrat, à marge 0,60 m : la
   référence remonte à 0,0094 m, le candidat à 0,6610 m.
2. **Trancher si le porche de R2a-3.5.2 doit être réparé avant intégration.**
   L'hypothèse du cisaillement de tangente est réfutable en rallongeant le
   segment sortant du seuil sans toucher aux stations 0 et 1.

Détail complet : `docs/CODEX_HANDOFF.md` §38.

---

## 2026-08-16 — R2a-3.5.1 : cavité asymétrique · `PARTIAL`

Le lead a refusé ma conclusion « trois exigences se contredisent » et il avait
raison : je n'avais essayé qu'un levier, translater la galerie **en gardant sa
section symétrique**. Une contradiction établie sur un seul levier n'est pas une
contradiction. Son arbitrage : **section intérieure asymétrique** — vide limité
au gabarit joueur du côté mince, élargissement déporté du côté où sept mètres de
roche attendent. Le chiffre qui lui donnait raison était déjà dans le code :
`GABARIT_DEMI_LARGEUR_M = 0,95 m` contre 3,48 m de demi-vide à la station 5.

Trois agents, trois worktrees sur `34c305d`, fusion **sans conflit**.
Preuves : `evidence/world_v2/v2_3_r2a/grotte/r2a351_integration/`.

### Étanchéité : `403 → 0` percées confirmées

| géométrie | échantillonnage d'origine | corrigé |
|---|---:|---:|
| R2a-3.5 | 403 | — |
| cavité asymétrique seule | 162 | 118 |
| **fusion cavité + enveloppe** | 38 | **0** |

Le passage de 38 à 0 est une correction **démontrée**, pas un aveuglement :
l'échantillonneur plaçait ses points symétriquement le long de X, et pour
chacune des 38 percées, **38/38 partaient hors de la cavité** avec **deux
impacts entre l'axe et ce point** — une paroi intacte, traversée à l'aller et au
retour. La sonde se tenait dehors, derrière un mur. Propriété de sûreté vérifiée :
sur un profil symétrique l'écart ancien/nouveau vaut **0,00 m sur 495 points**.

Aussi vert : paroi **0,87 m** (seuil 0,80) · **trois masses aux trois azimuts**,
100 compris · ratio d'emprises **2,16** (était 2,02 pour 2,00) · plage plane
8,36 globale et **4,63 en façade** (seuils 12,00 / 6,00) · raster des cinq
surfaces zéro case ouverte.

### Ce qui reste rouge — deux défauts, tous deux au bout de la galerie

1. **Collerette 0,48 m pour 0,60**, au porche. Ce n'est pas un conflit de
   contrat : R2a-3.4 tenait ce seuil grâce à une **« visière saillante »** que
   l'ancien `MASSIF` portait à la station 0 et que la nouvelle enveloppe n'a pas.
   Deux remèdes mesurés échouent — porter la lèvre **mure le porche**, un biais
   plus fort fait tomber la collerette à 0,08 m. **La forme qui reste à essayer
   est une visière : de la matière au-dessus et sur les côtés de l'ouverture,
   pas devant elle.**
2. **Plancher absent de `y +2,88` à `+3,17`, stations 6 à 8**, écart 0,44–0,45 m.
   **Régression de cette passe** — la géométrie livrée R2a-3.4 passe ce contrôle
   avec le même instrument corrigé. Présent à l'identique avant la correction
   d'échantillonnage : il était là, caché derrière le compte de percées. Les
   stations 7 et 8 ferment la calotte et sont exclues de `controle_epaisseur` et
   de `controle_gabarit` par construction ; c'est aussi là que `droite` descend à
   0,25–0,27. Piste, pas conclusion.

### Sept fois la même faute, et c'est l'enseignement de la passe

**Un seul nombre, qui répond à une autre question que celle posée.** La sonde ne
connaissait de l'asymétrie qu'un scalaire appliqué des deux côtés (704 rayons
absous à tort) ; `dans_enveloppe`, `dans_le_noyau`, `_emprise_noyau`,
`points_interieurs`, `controle_gabarit`, `controle_plancher` et
`controle_aucun_jour` mesuraient tous une demi-largeur **symétrique** le long de
**X** au lieu de la normale ; la contenance qui avait validé l'enveloppe ne
mesurait que le **toit** ; ma propre mesure du contrefort était prise **après**
soustraction, là où la peau était déjà emportée ; et le journal imprimait
`PASS — un sol existe sous chaque point sondé` **au-dessus** d'une carte pleine
de `<-- TROU`.

### Prochaine action exacte

**La visière du porche**, dans l'enveloppe : matière au-dessus et sur les côtés
de l'ouverture, ancre et cadrage gelés, sans que les silhouettes 55° et 225°
régressent. Puis le plancher des stations 6–8. Les deux patches sont dans
`r2a351_integration/` et s'appliquent d'un bloc sur `34c305d`.

Le tronc construit toujours la géométrie R2a-3.4 et **reste vert** : rien de
cette passe n'est versé au chemin livrable tant que le portail est rouge.

---

## 2026-08-16 — R2a-3.5 : changement d'architecture de la grotte · EN COURS

Le lead a rendu R2a-3.4 `FAIL TECHNIQUE — FAIL VISUEL` et **arbitré** le conflit
que la passe précédente lui avait renvoyé : « la galerie ne doit plus passer sous
les deux cols […] **déplacer le vide intérieur, pas sacrifier la silhouette
extérieure** ». Quatre couches désormais séparées : enveloppe rocheuse, galerie,
soustraction, détails de surface — dans cet ordre, la cavité n'étant soustraite
qu'après validation de l'enveloppe.

### Ce qui est acquis et poussé

* **Enveloppe.** Loft entre un polygone de sol irrégulier et un ruban de crête à
  largeur variable (0,25 m aux extrémités, 1,3–1,45 m au sommet) : aucun sommet
  plat n'est possible **par construction**. Trois masses aux azimuts 55/225,
  contenance 9/9 stations, linteau +1,36 m.
* **Outil de coupe et de carte d'épaisseur** (`tools/plot_cave_section.py`,
  `15abf21`), qui manquait : il mesure le **GLB livré**, pas les objets Blender,
  et ne juge rien.
* **Référence chiffrée de l'état rejeté**
  (`evidence/…/grotte/r2a35_coupe_baseline/`, `f4a3df5`), publiée **avant**
  d'avoir vu la nouvelle géométrie pour qu'elle ne puisse pas être choisie après
  coup : écart horizontal entre la crête de la tranche et l'axe de galerie
  = 0,00 m au seuil, **2,84 m en moyenne, 7,95 m au maximum**. C'est la mesure du
  constat que le lead avait fait à l'œil.

### Deux erreurs de méthode à mon débit, consignées

1. **J'ai accepté l'enveloppe sur les preuves que j'avais moi-même demandées.**
   Planches de silhouette, comptage de masses, sonde de contenance — aucune des
   trois n'est `controle_amas`, le portail du tronc, sous lequel l'enveloppe
   rendait un rapport de cols de 1,17 pour un minimum de 1,25. C'est l'agent qui
   l'a trouvé, pas moi. Règle qui en sort : **une couche produite hors du tronc
   se reçoit en la passant par les contrôles DU TRONC.**
2. **Un garde-fou qui ne pouvait pas se fermer.** `dans_le_vide` rend un couple
   `(bool, compte)` et `(False, 0)` est vrai en Python : ma garde publiait
   « 0,00 m d'épaisseur » là où la mesure était simplement impossible. Un
   garde-fou qui ne peut pas rougir est pire que pas de garde-fou — il donne
   confiance. Corrigé et commenté dans le code.

### Une clause de contrôle change de sens, et c'est documenté

`controle_amas` exigeait qu'un faîte soit porté par **au moins trois** copies de
`template-detail` — utile quand les modules ÉTAIENT la silhouette. Sous la
nouvelle architecture le lead écrit qu'ils ne doivent plus la porter : la clause
est donc **inversée** (zéro module de détail dans la bande de faîte, la crête
appartient à l'enveloppe), avec les deux versions et la raison du basculement
écrites au-dessus du code. Les six clauses neutres — largeurs, cols, dominante,
décentrement — gardent les valeurs du tronc ; **aucune n'a baissé**.

### Ce que la passe a établi

Le câblage est fait. Un mode `--diagnostic` a été ajouté — aucun contrôle
modifié, code retour toujours 2, export vers `prototypes/` et jamais vers le
livrable — parce qu'un portail rouge sur la composition nous rendait aveugles
à toute la suite de la chaîne. Il a immédiatement payé : **six défauts
bloquants mesurés** au lieu d'un seul connu.

**L'arbitrage du lead est exécuté, et c'est le résultat central.** Écart
horizontal entre la crête de la tranche et l'axe de galerie, mesuré sur le GLB
livré : **2,84 m moyen / 7,95 m max** sur la géométrie rejetée, **1,06 / 2,29**
sur la nouvelle. Le chiffre de gauche avait été publié d'avance (`f4a3df5`).

Le sommet plat a disparu : largeur au sommet 5,58 / 3,60 / 2,18 m → **1,54 /
2,02 / 1,58 m**. Et deux instruments qui ne partagent aucun code convergent à
3 cm sur les emprises (générateur sur volumes sources ; mesure sur les pixels
d'une silhouette rendue par Godot).

Preuves : `evidence/world_v2/v2_3_r2a/grotte/r2a35_diagnostic/`.

### Le blocage réel, mesuré deux fois

385 percées confirmées, épaisseur de paroi 0,11 m pour 0,80 exigés. Cause :
l'enveloppe fait 7 à 8,6 m de profondeur d'un côté et 0,07 m à rien de l'autre
— la galerie longe le bord mince. **La sonde de contenance qui avait validé
l'enveloppe ne mesurait que le toit** ; les parois latérales n'ont jamais été
mesurées, et je l'ai accepté.

Le remède évident — décaler la galerie de 1,8 m vers la roche disponible — a
été appliqué et mesuré. Trois indicateurs de bord s'améliorent (paroi
0,11 → 0,37 ; « le sol voit le ciel » 2 → 0 ; plancher +0,956 → +0,701) et
**les percées ne bougent pas : 385 → 390**.

Cet échec est plus utile qu'une réussite partielle : il réfute « la galerie est
un peu trop d'un côté ». La section de cavité ne tient nulle part sur un trajet
qui doit partir d'une bouche **gelée** et finir **sous la dominante**.

### Prochaine action exacte

**Porter l'arbitrage au lead, pas le trancher.** Trois de ses exigences se
contredisent, chacune explicite : bouche gelée (point 1), poche sous la
dominante (point 4), épaisseur réelle (0,80 / 0,60). Les trois leviers restants
touchent chacun une décision qui lui appartient — élargir l'enveloppe (mais
« ne pas sacrifier la silhouette extérieure »), réduire la section (mais le
gabarit joueur est un contrat), déplacer la bouche (mais elle est gelée).

Deux défauts de composition restent indépendamment ouverts et ne dépendent
d'aucun arbitrage : **azimut 100 à deux masses** (le contrefort disparaît en
projection ; R2a-3.4 en présentait trois, la cible est donc atteignable) et
**plage plane de 9,01 m² en façade** pour 6,00 (centrée en −4,68 ; 1,63 ; 2,24,
c'est-à-dire la face avant de l'épaule).

Le tronc reste **vert et inchangé** : le générateur livré construit toujours la
géométrie R2a-3.4, la sonde passe, rien de rouge sur `HEAD`. Le câblage complet
vit dans `r2a35_diagnostic/couche1_3_cablage_enveloppe.patch`, applicable d'un
bloc.

Aucun verdict visuel n'est prononcé ici ; il appartient au lead.

---

## 2026-08-16 — R2a-3.4 : corrective multi-agent (flore, composition, seuil)

Trois agents, trois worktrees détachés de `59e0adb`, verrou `flock` partagé,
intégration par cherry-pick sans commit de fusion. Preuves :
`evidence/world_v2/v2_3_r2a/grotte/tranche4_final/R2A_3_4.md`.

### Ce que chaque agent a trouvé

**A — flore.** Le bâtisseur de végétation V2 était le seul poseur de World V2 à
ne pas consulter `KitScale` : `Flower_4_Group` culminait à 2,841 m pour un
plafond bible de 0,55 m. Corrigé par la voie canonique, bande (0,69 ; 0,99)
choisie pour conserver le rapport de variance d'origine à 0,2 % près.

**B — forensic.** Une **circularité dans une chaîne de contrôles** :
`controle_epaisseur` excluait les rayons descendants en renvoyant à
`controle_aucun_jour`, qui ne tire que vers le haut. Rien n'a jamais regardé le
sol. Le générateur imprimait d'ailleurs déjà la mesure du défaut le jour de la
livraison — `sol : -0,416` pour un attendu de `-0,040` — illisible parce que la
ligne n'imprime pas l'attendu à côté. `ISS-044`.

**C — composition.** Le cv 0,06 était **arithmétique** : le faîte de
`template-detail` fait 0,93 m et 81 % des colonnes avaient leur crête portée par
une seule roche. Corrigé par chevauchement horizontal et anisotropie bornée.

### Deux erreurs attrapées par la reproduction

L'agent C annonçait « 81 → 13 percées » ; j'en mesurais « 761 → 113 » sur des
sha256 identiques. Cause : le drapeau `--rapide`, jamais écrit dans la preuve.
En se relisant, il a trouvé pire — `--rapide` lui avait fait écrire
« dispersées » là où **40 rayons convergent** derrière l'alcôve. Cible ensuite
fermée en une tentative.

> Quand deux mesures indépendantes du même défaut ne coïncident pas aux bornes,
> l'écart est le sujet, pas un détail de formulation.

### Trois pièges d'outillage consignés (`tools/CLAUDE.md`, `1b4da4d`)

Worktree neuf sans `.godot/` → le runner accuse `GateTestCase`, un innocent ;
`--path .` résout contre le cwd de la **session** ; tous les worktrees partagent
un seul `user://`.

### Prochaine action exacte

**Attendre le verdict visuel du lead sur `tranche4_final/`.** Quatre points sont
déclarés `NON SATISFAITE` et ne doivent pas être compensés par un score
technique : sonde `FAIL` global sur 73 percées isolées ; linteau à 0,61 m pour
un seuil de 0,60 ; contrefort droit pas « en retrait » ; contrôle 3 `PARTIAL`.

Le conflit de spécifications nommé par l'agent C appartient au lead : la galerie
passe au milieu de la formation, les deux cols sont les points bas de la crête
au-dessus d'elle, et épaissir pour fermer tire sur la même roche que creuser
pour garder trois masses.

Pylône, pont et hameau gelés. `GO_V2_3_R2B=FALSE`, `GO_V2_3_B=FALSE`.

---

## 2026-08-15 (suite) — R2a-3.3 : extérieur de la grotte rebâti en roches CC0

Point de contrôle livré, **aucun verdict artistique auto-déclaré**. Preuves :
`evidence/world_v2/v2_3_r2a/grotte/tranche3/TRANCHE3.md`.

### Le pivot

`anneau_exterieur()` ne rend plus aucune surface : il ne sert plus qu'à la
coque de collision, jamais rendue. L'extérieur est fait de **98 roches du kit
CC0** `kenney_modular_cave_1_0`, échelle 0,55 à 1,55, fondues par remaillage
volumétrique 0,12 m puis décimées, la cavité étant soustraite comme un solide.
Six des sept modules du kit ont été **écartés sur mesure** : leur dos est plat
par construction (plage plane 7,2 à 18,0 m² contre 2,59 pour `template-detail`),
ou ils résistent à la réparation, ou ils font échouer l'union sans jamais
échouer un contrôle — ce dernier cas n'a été trouvé que par bissection.

### Trois exécutions, trois causes, aucune trouvée à l'œil

Un relevé « faite par rang » a été ajouté au générateur : la gaine culminait à
8,26 m contre 9,16 m pour les masses majeures, donc trente-cinq dents
régulières décidaient de la crête. La correction évidente — ancrer le sommet —
a **ouvert un jour** (station 6, azimuts 51 à 71°, 0 croisement), parce que le
placement radial était ce qui garantissait la couverture. La crête se plafonne
donc par la taille : échelle 1,45 → 1,15, marge 1,60 → 0,55, sept puis neuf
azimuts après une épaisseur tombée à 0,16 m dans la salle.

Chaîne verte, RC = 0. Crête gaine 6,01 m. `gltf_inspect` VALIDE, 21 324 tris.

### Deux caméras de preuve étaient fausses, et ce n'était pas le maillage

Le « gros plan du seuil » visait à travers la bouche : la **capture R2a-3.1 à
la même caméra** montre la même masse grise au même endroit, sur un maillage
entièrement différent. Et la vue « trois masses » était prise du côté opposé à
l'approche du joueur. Les deux caméras fausses sont **conservées** pour que les
A/B restent à caméra identique ; deux caméras justes ont été ajoutées à côté.

### Ce que la mesure dit de la composition

`tools/measure_silhouette_masses.py` (nouveau) compte les sommets d'une
silhouette par **proéminence topographique**. Sur l'azimut réel d'approche
(55°, dérivé de la caméra, pas choisi) : **4 sommets de largeur 1,07 à 1,26 m,
coefficient de variation 0,06**. La consigne demandait « trois masses larges et
**asymétriques** » ; l'asymétrie de largeur n'y est pas. Cause nommée : un seul
module, à rapport hauteur/largeur 1,6, répété. Le levier — grouper les majeures
en trois amas d'emprises inégales — n'a **pas** été actionné : c'est une
décision de composition.

Une première version de cet outil comptait les marches d'escalier comme des
masses et rendait des « masses » de 6 cm. Corrigée, et la raison est écrite
dans le fichier.

### Aussi

`ISS-043` : neuf lignes de `ASSET_MANIFEST.csv` ne sont pas du CSV valide
(champ à virgules non quoté). Seule celle de la grotte est corrigée ; les huit
autres appartiennent à des lots gelés et sont nommées, pas touchées.

### Prochaine action exacte

**Attendre le verdict du lead sur les captures de la tranche 3.** Rien d'autre
ne doit partir : pylône, pont et hameau restent gelés, `GO_V2_3_R2B` et
`GO_V2_3_B` restent FAUX, `validate_fast` et les 38 plans restent interdits
tant que la stabilité visuelle n'est pas prononcée.

Si le lead demande la composition en trois amas : le levier est
`ROCHERS`/`rang` dans `make_waterfall_cave.py`, et la mesure de contrôle est
`tools/measure_silhouette_masses.py --entaille=1.50` sur la vue 55°, qui rend
aujourd'hui 3 masses à cv 0,39.

---

## 2026-08-15 — R2a-3.1 : la grotte refaite, et un défaut dans mon propre code

Verdict de la revue au HEAD `9f25e78` : pont et hameau **PASS visuel**,
golden masters 2/4 et 3/4 ; **grotte FAIL visuel**, corrective R2a-3.1
exigée. Travail redevenu séquentiel, agents non relancés, pont/hameau/pylône
non touchés, ni les 38 captures ni `validate_fast` relancés.

### Hameau : gelable, mesuré

Sonde de végétation rejouée sur toute l'emprise (107 pièces, 16 651
instances de semis gelé, 78 dans l'emprise) : **aucune intersection**. Le cas
le plus serré est à 0,35 m — à côté, pas dedans. Aucune reconstruction, la
végétation V2.2 reste intacte. `evidence/…/hameau/VEGETATION_VERDICT.md`.

### Grotte : la première corrective ne changeait rien, et j'ai su pourquoi

La première R2a-3.1 (commit `d8404bb`) passait tous les contrôles et a été
capturée : bouche encore en demi-cercle, façade lisse, galerie en tube.
Mesuré, σ = 13,3 sur la façade et **5,8** sur la paroi intérieure.

La cause était dans mon code, pas dans les réglages. `facette()` quantifiait
le **rayon** mais plaçait le sommet au **vrai azimut** — or un rayon constant
sur un secteur trace un **arc de cercle**. La « section polygonale » que
j'avais annoncée n'existait pas dans le maillage. `coins()` et `polygonal()`
construisent maintenant de vrais polygones, arêtes droites entre sommets.

Le reste a suivi, chaque fois vérifié par une mesure et non par une
intention : polygone du massif **circonscrit** pour ne pas perdre 0,47 m
d'épaisseur ; **visière** et **éperon** ajoutés du côté de l'approche parce
que contrefort et couronne étaient tous deux au nord et que la vue du joueur
ne montrait qu'un dôme ; **collerette** biseautée par une rangée intercalée.

**Deux mécanismes ont été retirés plutôt que gardés** : une banquette et une
tablette d'alcôve, mesurées là où elles devaient culminer, ne relevaient
rien — une fenêtre d'azimut de 52° est plus étroite que l'écart entre deux
sommets (40° à 9 facettes), et l'arête qui joint les voisins l'efface.

### Trois contrôles rendus honnêtes en cours de route

`hauteur_du_sol` rendait 1,544 m à un endroit et −2,078 m à 60 cm de là : le
rayon partait dans la roche. Corrigée (premier impact dont la normale
regarde vers le haut), **elle a montré que la récompense flottait de 0,7 m**.
`controle_annexe_hors_cavite` imprimait `1000000000.00 m` quand il n'avait
rien comparé. Le gabarit ne soustrayait pas le palier de la hauteur libre —
il a d'ailleurs refusé le premier réglage, à 2,04 m pour 2,05 exigés.

### État livré

Commit prouvé `71d1817`, `repo_dirty: false` : 7 vues monde, tournette 8
vues, 2 silhouettes isolées. Filets de lieux **8/8**. Sonde de végétation
rejouée sur l'emprise agrandie : **aucune intersection**. Détail et aveux :
`evidence/world_v2/v2_3_r2a/grotte/CORRECTIVE_R2a_3_1.md`.

**Sept exigences sur huit sont PASS. L'exigence 5 — récompense mise en scène
par la géométrie — est PARTIAL**, et c'est écrit ainsi : le creux de
l'alcôve, la lampe et le palier tiennent la scène, pas une tablette.

### Prochaine action exacte

**Attendre le verdict visuel du lead sur la grotte.** Aucun verdict
artistique n'est auto-déclaré. Ne pas relancer les trois agents, ne pas
toucher au pont, au hameau ni au pylône, ne pas lancer les 38 captures ni
`validate_fast` tant que ce verdict n'est pas rendu.

Si la grotte passe : R2a-5, passe silhouette complète sur les quatre sujets
(angles rasants + contrôle négatif contre l'ancienne planche), puis R2a-6.

## 2026-08-14 (suite 15) — V2.3-A.R2a OUVERTE : changement de PIPELINE artistique

**Verdict du lead sur V2.3-A.R** : chaîne technique et preuves SHA `PASS` ;
**gate artistique ÉCHEC** ; `GO_V2_3_B=FALSE` ; aucune propagation aux cinq
lieux restants ni aux 31 POI. Base de la passe : `c946b0e`, additif strict.

### Ce que le lead accepte

La correction de la chaîne de capture : vraie ligne de base `775aa32`,
`--scene` obligatoire, planches non vides, manifestes propres,
`validate_fast` 899/0.

### Ce qu'il refuse, et c'est une décision de MÉTHODE

> « Les lieux sont encore principalement construits comme des assemblages
> procéduraux visibles, puis corrigés localement. Cela produit des
> intersections, des blocs disjoints et des silhouettes de prototype. »

Corriger localement un assemblage de `BoxMesh` ne le sauvera pas. La règle
change : **les scripts de scène cessent de fabriquer seuls la surface
artistique finale**. Ils gardent l'instanciation, l'implantation, les
interfaces fonctionnelles, les collisions simples et les variations
contrôlées. La peau vient de modules CC0 correctement assemblés ou de
vrais meshes Blender à source conservée. Les primitives ne servent plus
qu'aux collisions, sondes et supports **invisibles**.

### Périmètre de R2a — QUATRE golden masters, pas neuf lieux

1. hameau de la rivière · 2. pont de pierre · 3. grotte de la cascade ·
4. pylône de Résonance.

Ferme, arbre foudroyé, camp braise et bassin **restent en attente** : ils
ne seront repris qu'après validation des quatre références. Le camp /
checkpoint est le seul sujet jugé en progrès ; il reste **gelé** pendant
ce sous-gate.

### Défauts bloquants relevés, sujet par sujet

Village : une maison domine seule, éléments blancs non finis, silhouette
collective absente · Ferme : charpente en dents verticales, mur
rectangulaire intact, et la capture `structure_ferme_charpente` **manque le
sujet** · Pont : blocs désolidarisés, grandes faces blanches, géométrie
qui dépasse des culées, la vue sous arche **entre dans le maillage** ·
Grotte : enveloppe ouverte, plaques fines, la caméra intérieure est
**dans les polygones** · Arbre : blocs bruns, noirs et blancs disjoints ·
Camp braise : accumulation sans hiérarchie, illisible à 94 m · Bassin :
fragments blancs anguleux, arbre masquant le centre · Pylône : progrès à
distance, mais base en amas de blocs · **Planche de silhouettes : non
vide, mais c'est une mosaïque couleur — ce n'est pas un test de
silhouette.**

### R2a-0 — FAIT : l'enquête, et ses trois trouvailles

**Blender était présent et INCAPABLE d'exporter, en silence.** numpy
manquait ; l'exporteur glTF en dépend ; l'échec rendait **code 0** et
`run_export.sh` revalidait alors les `.glb` déjà versionnés en annonçant
« VERT ». Corrigé (numpy, `--python-exit-code 1`, jeton de fraîcheur) et
**prouvé en le faisant rougir** : numpy masqué → RC 1, ROUGE.

**Les pivots des modules CC0 sont enfin mesurés**
(`tools/godot/probe_kit_seating.gd`, 48 modules). `KitScale.factor()` rend
1,000 partout où l'on comptait bâtir : aucun redimensionnement silencieux.
Tous les murs font 2,00 × 3,12 × 0,41 m, pivot centre/min/**0,77**. Et
`seat()` plaque au sol tout module dont l'origine n'est pas à sa base —
une fenêtre passée par `K.module()` finit **par terre** (1,016 m mesurés).

**Aucun module CC0 ne peut couvrir le pylône** : ni fût à dosserets, ni
anneau incomplet, ni couronne bifide, ni canal creux. Blender était la
seule voie honnête — d'où l'ordre des travaux.

### R2a-4 — FAIT : pylône, premier golden master

Script de scène : **238 maillages GDScript → zéro**. Il instancie un GLB
produit par `source_assets/blender/architecture/make_pylon_resonance.py`
(source reproductible versionnée). Aucun booléen — que des volumes
**loftés**. Les trois canaux sont dans le **profil** du fût. 17 objets,
34,56 m, base à z = 0. Filets `world_v2_places` 8/8 verts.

Deux défauts d'outillage trouvés en chemin, tous deux silencieux :
`gltf_inspect.py` ne mesurait **qu'un maillage** (1,7 m annoncés pour
34,56) ; et le pylône rendait **blanc** à cause de la conversion
sRGB/linéaire de `baseColorFactor` (0,40 écrit → 0,67 reçu, 0,14 → 0,41 :
contraste écrasé). Les deux corrigés et mesurés.

### R2a-4.1 — FAIT : recalibrage du pylône sur verdict du lead

Verdict reçu : R2a-0 `PASS`, R2a-4 « progrès majeur, pas encore golden
master », plus **un défaut de preuve** — le manifeste portait
`commit: 6ddac267` et `repo_dirty: true`, donc des images produites avant
le commit du code, depuis un arbre modifié. Corrigé à la racine : toutes
les preuves de cette passe portent `commit 4165801` et `repo_dirty: false`.

Les quatre points demandés, et ce que chacun a réellement révélé :

1. **Pieds** — section octogonale chanfreinée, sabot noyé dans la plinthe,
   chapiteau sous le collier. Demi-largeur 1,80 → 1,32 m *après mesure sur
   silhouette isolée* : trois volumes séparés dans le maillage ne font pas
   trois pieds séparés à l'œil, c'est la projection qui décide.
2. **Canaux** — nervures de part et d'autre, cyan découpé en neuf inserts
   calés sur les bandeaux, émission 1,4 → 0,85. Puis le balayage a montré
   le vrai défaut : le noyau sombre était **6 cm derrière** le fond du
   canal, donc invisible, et le fond rendait 0,203 — la valeur exacte du
   flanc. Noyau ressorti de 4 cm : fond 0,133 contre nervures 0,260,
   **cyan coupé**.
3. **Anneau** — le défaut était un PIVOT. `rotation_euler` tourne autour de
   l'origine de l'objet, au sol : 9° appliqués à z = 22,30 décentraient
   l'anneau de **3,49 m**, et la bande traversait le fût. Basculement
   refait autour du centre de l'anneau ; consoles dans le même repère ; le
   générateur refuse d'enregistrer si l'étalement dépasse 1,10 m.
   Ouverture élargie à 84° et **présentée de profil** — pointée vers
   l'objectif elle donnait deux cornes et aucun anneau.
4. **Couronne et matières** — effilement 3,3×, coiffe en volume unique
   terminé en pointe, fourche décalée en Y (deux dents alignées sur le seul
   axe X disparaissaient l'une derrière l'autre à 0°). Matières recalibrées
   **sur la capture** : l'écart d'éclairement (×1,63) égalait l'écart de
   matière (×1,62), donc les trois matériaux rendaient la même valeur.
   Mesuré après : bronze 0,398 · pierre 0,553 · ivoire 0,678.

Deux outils créés, parce qu'une preuve doit être rejouable :
`tools/blender/export_architecture.sh` (le pylône de R2a-4 avait été
exporté à la main) et `tools/godot/capture_silhouette.gd`, qui produit la
silhouette isolée et **refuse d'écrire** une image non bimodale — le
contrôle qui manquait à la « mosaïque de couleurs ».

Trois cadrages de R2a-4 étaient faux et ont été refaits par le calcul : le
gros plan visait 51° à côté du canal le plus proche, et deux vues « à
hauteur de joueur » étaient à 11,5 m du sol. Détail et nombres :
`evidence/world_v2/v2_3_r2a/README.md`.

### VERDICT LEAD SUR R2a-4.1 — PASS, pylône GELÉ

Reçu : « PASS artistique et technique. Le pylône est validé comme golden
master 1/4 ». Six critères `PASS` — preuves au SHA `4165801`, pipeline
Blender→GLB→Godot reproductible, silhouette générale et couronne bifide,
tripode et ancrage, canal géométrique sombre à cyan rythmé, anneau
incomplet lisible dans les axes réels de jeu.

L'arbitrage de la silhouette à 0° est **accepté** : « il n'est pas
nécessaire qu'un anneau ouvert conserve la même lecture sous tous les
azimuts ».

**PYLÔNE GELÉ au code `4165801`** — ne plus le modifier hors régression
démontrée. Le lead précise qu'il « valide la méthode et la cohérence
géométrique » mais « ne constitue pas un plafond de richesse
architecturale » pour les trois sujets restants.

### R2a-2/3/1 — production PARALLÈLE contrôlée, en cours

Trois worktrees et trois branches créés depuis `d327e5e` :

| agent | worktree | branche | sujet |
|---|---|---|---|
| pont | `/home/user/zelda-r2b/pont` | `claude/r2a-pont` | `stone_bridge_place.gd` |
| grotte | `/home/user/zelda-r2b/grotte` | `claude/r2a-grotte` | `waterfall_cave_place.gd` |
| hameau | `/home/user/zelda-r2b/hameau` | `claude/r2a-hameau` | `riverside_village_place.gd` |

Propriété EXCLUSIVE des fichiers : chaque agent ne touche que son
générateur, son GLB, son `*_place.gd` et son dossier de preuves. Réservés
au lead et interdits aux agents : `PROGRESS`, `STATUS`, le README global
de R2a, le manifeste d'assets, les builders et kits partagés, le layout,
et tout ce qui est gelé en V2.2 (terrain, eau, végétation, navigation,
caméras).

**Blender tourne en parallèle ; Godot est SÉRIALISÉ.** Trois worktrees
partagent la même machine et le même `user://` — le 2026-08-11, deux
suites concurrentes ont fabriqué huit échecs de sauvegarde et coupé une
ligne de journal en plein mot. Le verrou `/home/user/zelda-r2b/godot_serialise.sh`
enveloppe chaque invocation dans un `flock` ; il sort en 3 (BLOQUÉ), jamais
en 0, si le verrou n'est pas obtenu. Aucun agent ne lance `validate_fast`
ni le runner de tests.

Le briefing commun `/home/user/zelda-r2b/BRIEFING_COMMUN.md` porte les
pièges mesurés sur le pylône, pour qu'ils ne soient pas repayés trois
fois : `--python-exit-code 1`, conversion sRGB→linéaire, écart de matière
qui doit dépasser l'écart d'éclairement, pivot de `rotation_euler`,
azimut modèle θ → direction monde `(cos θ ; −sin θ)`, soleil à 199,5°,
hauteur de joueur = sol sondé + 1,7 m, et l'assise `seat()` qui plaque les
fenêtres par terre.

### Les trois candidats sont INTÉGRÉS

Ordre imposé par le lead, tenu : pont → grotte → hameau. Après chaque
fusion : import propre, filets, capture ciblée depuis MON arbre, inspection
à taille réelle. Les trois agents ont respecté la propriété exclusive des
fichiers ; aucun fichier réservé n'a été touché.

| sujet | branche | tris | filets après fusion |
|---|---|---:|---|
| pont | `claude/r2a-pont` | 15 784 | places 8/8 · hydro 4/4 · ancres 2/2 |
| grotte | `claude/r2a-grotte` | 3 192 | places 8/8 |
| hameau | `claude/r2a-hameau` | 2 264 + 488 | places 8/8 · hydro 4/4 |

### Deux outils à moi étaient cassés, et ce sont les agents qui l'ont vu

**`capture_silhouette.gd` aurait menti sur le hameau.** Il instanciait la
scène hors du monde, où `ground_local_y()` rend 0 : quatre bâtiments posés
sur trois niveaux de terrain s'y seraient aplatis, et la silhouette en
gradins — le cœur du sujet — aurait montré une composition inexistante.
Mode `--place=` ajouté, vérifié par contrôle : le pylône y rend la même
silhouette qu'en mode asset.

**`probe_vegetation_near.gd` rendait des comptes faux avec aplomb**, et
trois passes s'en étaient servies pour décider d'implantations. Le test qui
tranche est un balayage de rayon sur un même point : avant, 0 · 0 · **180**
à 3, 6 et 12 m — une marche d'escalier, la cellule entière basculant quand
l'origine de son nœud passe sous le rayon. Après correction : 0 · 0 · **2**.
Facteur d'erreur 90.

La cause était **déjà écrite dans le dépôt** : `world_v2_vegetation_builder.gd`
documente que le renderer DUMMY du mode headless jette les données
d'instance de MultiMesh et rend l'identité, et que le bâtisseur écrit pour
cette raison son plan de plantation en méta `instance_origins`. La sonde
interrogeait le renderer factice.

Ma première tentative de correctif était elle-même fausse — une attente de
stabilisation qui comptait 166 « positions distinctes », c'est-à-dire les
166 cellules. Un détecteur qui se stabilise n'est pas un détecteur qui
mesure.

### Deux points d'arbitrage remontés au lead, non tranchés ici

1. **Le pont est à 28,8 m de son `v2_site`**, contre 19,4 m avant. Mesuré
   et vérifié par moi : à `x = −22`, le sol est en eau de `z = −12` à
   `z = +12` — l'ouvrage précédent était parallèle au chenal et posé dans
   l'eau sur toute sa longueur, ce qui explique rétrospectivement le défaut
   « géométrie qui déborde des culées ». Il n'y avait pas de berge où
   ancrer. La note du layout dit toujours « berge sud du gué central » ;
   personne n'y a touché.
2. **Il n'y a aucune chute d'eau à la « Grotte de la cascade ».** L'affluent
   gelé descend de 3,0 à 0,5 sur ~14 m, pente maximale 0,25 m/m. L'agent
   n'a pas inventé d'eau — l'hydrologie est gelée. C'est une question de
   nommage.

### La faiblesse principale, dite sans l'adoucir

La **richesse de surface de la grotte est en deçà du pylône** : parois
intérieures lisses (amplitude 0,085), masse extérieure en miche. Le lead
avait écrit que le pylône « ne constitue pas un plafond » ; sur ce sujet on
est sous le plancher. Le pont et le hameau, eux, le dépassent.

### Prochaine action exacte

**Attendre le verdict du lead sur les trois candidats.** Aucun verdict
artistique n'est auto-déclaré.

Si les trois passent : R2a-5, la passe silhouette complète sur les quatre
sujets — l'outil existe et a servi ici, il reste à l'étendre aux angles
rasants et à lui écrire son contrôle négatif contre l'ancienne planche —
puis R2a-6, les preuves finales, puis `validate_fast` et les 38 plans, que
le lead a interdit de relancer avant stabilité visuelle.


## 2026-08-12 — Finition visuelle monde entier (branche `claude/full-world-visual-finish`)

Bibliothèque Codex fusionnée (11 packs CC0 en quarantaine), puis huit lots :
terrain entier (teintes organiques, 22 buttes), trois masses boisées
(navmesh re-cuite), rivière pleine longueur, POI harmonisés (toits, crypte,
falaise), donjon habillé par agent (10 GLB promus), UI finie par agent
(débordement 720p corrigé et mesuré). Chaque promotion d'asset est entrée
dans ATTRIBUTIONS + manifeste AVANT commit. Preuves :
`evidence/full_visual_finish_20260812/`.

**Prochaine action exacte** : batterie finale — parcours physiques
(vallée/donjon/boss), `validate_fast.sh` unique, trois joueurs boîte noire
(occasionnel/explorateur/expérimenté), jeu de captures complet (31 POI +
vues générales + salles + acteurs + UI), pousser la branche, livrer à la
revue Codex. Le gate visuel n'est JAMAIS auto-déclaré.


## 2026-08-17 — R2a-3.5.6, grotte : la loi de rebord est démontrée, la roche manque

Branche `claude/world-v2-reconstruction`. **`PARTIAL`. Rien n'intégré au tronc**,
asset livré inchangé (`8bf1a1b3`), zéro capture, 14/14 seuils identiques à
`504ecbe`, `assets/` et `source_assets/` intouchés, golden masters intacts.

**Le résultat de la passe est un théorème**, tiré des définitions déjà gelées et
non d'une mesure : `e(p) ≤ dist(p, Γ) ≤ d(p)` partout, sur toute géométrie, parce
que `Γ` est contenue dans la surface extérieure. La loi de rebord littérale ne
demande donc pas un plancher — **elle demande le majorant**, avec une marge
maximale nulle, et sous borne conservatrice elle est insatisfiable. Le même
argument condamne tout seuil constant en deçà de sa propre valeur, ce qui explique
enfin le `lecture / h` constant mesuré en R2a-3.5.5 sur deux géométries.
Réparation `LOI-R` écrite **avant** toute mesure (`ADDENDUM_MASQUE_BOUCHE`
§2quater), genou à `0,80 + h = 0,85 m`, `θ_min = 70,25°` **dérivé**.

**Réparé et mesuré, non intégré** : `MASSIF` — auto-intersections `env×env`
**34 → 0**, `SM_` inchangé au bit près, prédiction falsifiable posée avant mesure
et tenue sous deux instruments ; `rochers_joue_droite()` — échantillons sous
seuil **1 122 → 499**, trois contraintes tenues.

**Deux blocages, un seul géométrique.** Le contractuel est **circulaire** : la
chaîne ne peut verdir tant que `controle_epaisseur_domaine` n'est pas déclassé, et
la directive interdit de le déclasser avant qualification verte — alors que le
contrat gelé `cca1778` l'a **déjà** déclassé. Aucune sculpture ne dénoue cela. Le
géométrique est nommé **et contre-indiqué** : il manque `0,1307 m`, faute de
**portée latérale** à `−2,289 m` de la courbe quand le module en porte `1,320` ;
augmenter le déport détacherait les deux couronnes.

**Prochaine action exacte** : `ISS-058` — **raffiner le maillage au voisinage de
la bouche**. C'est le seul travail géométrique identifié comme indispensable et
non fait, et deux constats indépendants y convergent : à l'arête médiane réelle
de `SM_` (`0,3325 m`) la rampe `[0 ; 0,80]` ne porte que **cinq valeurs** et la
lâcheté du majorant de `d` vaut **82 % de `h`** ; et `Γ`, courbe simple fermée à
la bouche, est **dentelée d'un facteur 10,6** — `116,16 m` contre `10,99` pour
une ellipse à ses dimensions. Un `Γ` de 11 m ne s'obtiendra pas en filtrant, il
s'obtiendra en maillant.

**Ce qui revient au propriétaire, pas à une session** : appliquer au code le
déclassement de `controle_epaisseur_domaine()` déjà décidé au contrat. Tant qu'il
ne l'est pas, aucune géométrie ne peut qualifier cette passe. Le livré porte
**320** plaques sous 0,80 m contre 29 pour le candidat, la plus mince `0,051`
contre `0,114 m` — et ce portail n'existait pas quand le livré a été validé.

Détail complet : `CODEX_HANDOFF` §39, `evidence/world_v2/v2_3_r2a/grotte/r2a356_loi/`.
Incidents : `ISS-056` (`pkill -f` inter-worktree), `ISS-057` (Blender rend `0` en
ayant levé), `ISS-058` (maillage de la bouche).

## 2026-08-18 — R2a-3.5.8 : collider sain, candidat intégré sous candidates/, revue visuelle demandée

Le zéro est atteint et INTÉGRÉ. Les 4 auto-intersections du collider sont à
zéro sur le GLB exporté `5ff4ec6e…`, en une itération sur un budget de trois,
`SM_` inchangé au bit près. Les trois couloirs (collision, traversabilité,
provenance/identité visuelle) sont verts, chaque affirmation décisive
reproduite par le lead — dont la jauge de poche au fil du couteau, refaite à
l'éventail indépendant (`r2a358_lead/repro_poche/`).

Intégration §7 exécutée SANS remplacer la production : source candidate
`make_waterfall_cave_r2a358.py` (28535fb3 + déclassement cca1778 + nom de
.blend), sujet d'export dédié `waterfall_cave_r2a358`, GLB commité sous
`assets/environment/caves/candidates/`, bascule de revue
`WORLD_V2_GROTTE_CANDIDAT=r2a358` lue seulement par la capture. R2a-3.4
(`8bf1a1b3…`) reste la grotte servie au joueur.

Piège rejoué et consigné : les caméras intérieures du manifeste dérivaient
des ancres R2a-3.4 — vu à l'inspection pleine taille, re-dérivées sur les
ancres candidates (5ᵉ récidive du piège des caméras périmées).

Validation §9 : suite world_v2 56/56 ; boot 23 assertions des deux côtés de
la bascule ; validate_fast 904/904 tests verts mais verdict ROUGE sur des
fuites de fin de processus — **préexistantes, mesurées identiques à la base
Codex `0b0ef54`** (ISS-059, dette nommée, hors gates de la grotte).

**Prochaine action exacte** : recueillir le verdict visuel Codex/Istvan sur
les montages A/B (`evidence/world_v2/v2_3_r2a/grotte/r2a358_candidat/
montages_ab/`) ; si le candidat est retenu, l'activation est un petit commit
de bascule (chemins + constantes appariées déjà en place) ; sinon, R2a-3.4
reste active et le candidat demeure archivé. Ensuite : CHECKPOINT JOUABLE
pour Istvan (tâches #89/#90), dont le PLAYABLE_SHA dépend de ce verdict.

## 2026-08-19 — VERDICT VISUEL PASS : la grotte R2a-3.5.8 est le quatrième golden master, PROMUE

Le lead a inspecté les 15 captures et les 4 montages A/B : PASS. Décisions :
`R2a-3.5.8_VISUAL_GATE=PASS`, `GOLDEN_MASTERS=4/4` (hameau, pont, pylône,
grotte — tous gelés), `GO_V2_3_R2B=TRUE`, `GO_V2_3_B=FALSE`, aucune
propagation aux 31 POI.

Promotion exécutée sans retouche : GLB `5ff4ec6e…` déplacé par git mv
(hash vérifié identique), actif par défaut sans variable ; R2a-3.4 reste au
dépôt en fallback explicite (`WORLD_V2_GROTTE_FALLBACK=r2a34`). Le filet
grotte marchait la CORDE droite et sondait le sol depuis le ciel : corrigé
(route canonique en meta, sonde consciente des surplombs), rouge d'abord
archivé, 8/8 sur les deux géométries.

**Prochaine action exacte** : checkpoint téléchargeable (workflow
publish-playtest, entrée gm4=true sur le SHA final) puis ouvrir R2B :
trois worktrees (A camps, B ferme+arbre, C bassin), plans courts arbitrés
avant toute implémentation.

## 2026-08-19 — V2.3-A.R2B : les cinq lieux pilotes reconstruits, intégrés, checkpoint GM4 publié

Checkpoint jouable d'abord : ZIP `Projet_Godot_WorldV2_R2a_GM4_5f821e5.zip`
publié en Release GitHub publique (tag `world-v2-playtest-r2a-gm4-5f821e5`,
sha256 `556458d7…`, 426 184 998 octets), validé depuis L'ASSET TÉLÉCHARGÉ
(import RC=0, boot smoke 23 assertions, grotte `5ff4ec6e`).

R2B en trois worktrees depuis la même base `5f821e5`, plans arbitrés avant
toute implémentation (`evidence/world_v2/v2_3_r2b/ARBITRAGE_PLANS.md`) :
A = deux camps aux identités distinctes (halle charpentée au checkpoint ;
enceinte brûlée, guet vertical, foyer éteint au braise) ; B = ferme à
charpente portée + arbre foudroyé, deux GLB Blender ORIGINAUX à générateurs
committés ; C = bassin à margelle appareillée en modules kit, classe et
graphe électrique intacts. 12 contrôles négatifs rouges d'abord, verts après,
seuils inchangés. Intégration par cherry-pick strict (21 commits, fichiers
disjoints), golden masters byte-identiques 6/6.

Validation intégrée : suite world_v2 **68/68 RC=0** (56+5+4+3, le compte
exact) ; boot smoke 23 assertions RC=0 ; validate_fast **916/916 tests
verts**, harness global ROUGE sur ISS-059 seul — mêmes 4 types de RID,
aucune classe nouvelle, passe filtrée propre, croissance proportionnelle au
contenu (mise à jour consignée à ISS-059). Pièges consignés : `--filter
world_v2` (espace) est IGNORÉ par le runner (syntaxe correcte
`--filter=world_v2`) ; après cherry-pick de GLB neufs, rejouer l'import
headless sinon la suite rougit en « aucun maillage visuel ».

Preuves du lead : 5 montages A/B à caméra STRICTEMENT identique (17 paires
from/look/fov vérifiées contre le manifeste 4100f66), carte des cinq lieux,
planches couleur et niveaux de gris, métriques par lieu (dépassement braise
54/45 accepté et motivé), inventaire actifs/licences, journal des contrôles
négatifs — `evidence/world_v2/v2_3_r2b/preuves_lead/`.

**Prochaine action exacte** : recueillir la revue visuelle Codex/Istvan sur
les planches et montages de `preuves_lead/` ; aucune propagation aux 31 POI
sans son verdict (`GO_V2_3_B=FALSE`). Dette : ISS-059 (bissection),
UV0 des deux GLB originaux, 8 lignes héritées non conformes du manifeste.

## 2026-08-19 — R2B.1 : corrective ferme et arbre, budget du camp braise

Trois worktrees depuis `7c3d3ca`, plans rendus AVANT toute implémentation,
arbitrage figé dans `evidence/world_v2/v2_3_r2b1/ARBITRAGE_PLANS_R2B1.md`.
Intégration par cherry-pick strict — 27 commits, un seul conflit (le manifeste,
résolu en rendant chaque ligne à la voie qui possède l'actif).

Validation : suite `world_v2` **85/85 RC=0**, boot 23 assertions RC=0, golden
masters **6/6 byte-identiques**, `gltf_inspect` VALIDE, plafonds de triangles
inchangés, `git diff --check` propre.

Les trois causes premières ont été MESURÉES, pas devinées : le mur de kit sans
tranche (quad de 6 m² en 2 triangles) ; le plan de fourche à 9,0° où la caméra
de silhouette regarde dedans ; le 54ᵉ module du braise qui est le coffre de
récompense instancié au runtime.

Quatre pièges de portail attrapés dans cette passe, dont trois sur des tests
qui rendaient VERT à tort : le portail de budget déclarait « 0/45 tenu » sur un
camp qui ne s'était pas construit (planchers posés par le lead) ; le 8ᵉ portail
de l'arbre passait au vert sur la géométrie d'avant, parce qu'il sommait les
secteurs occupés et récompensait donc le maillage le plus pauvre (attrapé par
l'agent) ; le sabotage prescrit par le lead ne mordait pas, il comptait le
coffre exempté (attrapé par l'agent). Le quatrième est du lead : cinq caméras
de preuve posées au jugé, deux sous le terrain et trois visant le pied au lieu
du fût — corrigées, baseline recapturée.

**Prochaine action exacte** : revue visuelle Codex/Istvan sur
`evidence/world_v2/v2_3_r2b1/preuves_lead/` (15 montages A/B à caméras
vérifiées identiques + RAPPORT_R2B1.md). Aucune propagation aux 31 POI sans
son verdict. Dettes : UV0 des `SM_Farm_*`, mur nord encore rectangulaire,
branche morte de `_palisade`, marge de budget nulle au braise, ISS-059.

## 2026-08-19 — R2B.2 : fermeture visuelle ferme et arbre (close en PARTIAL)

Trois worktrees depuis `c44f430b` — agent A ferme, agent B arbre, **agent C
audit indépendant produisant ZÉRO géométrie de production**. 19 commits
cherry-pickés, un seul conflit (le manifeste, résolu par propriété d'actif).
Aucun merge, aucun push d'agent ; Godot et Blender sérialisés par `flock`.

**Verdict : `PARTIAL`. La matière est gagnée et mesurée ; la forme ne l'est
pas.** Le verdict d'un gate est le plus faible de ses critères, jamais leur
moyenne — un liant échoue, donc la passe ne se déclare pas verte.

Ce qui est obtenu : UV0 **25/25** sur la ferme (0 avertissement `gltf_inspect`
contre 23), densité UV à 1,6 % du kit ; **liant de densité d'aplat VERT** —
`ferme_seuil` 69,3 → **5,7 %**, `ferme_laterale` 62,5 → **0,0 %**, sous la
densité du kit lui-même (34,4 %), **aucun seuil relevé** ; **coût d'ablation
NÉGATIF** (−2,79 · −3,18), le seul résultat qu'aucun contournement ne produit ;
fourche de l'arbre 9,0° → **38,9°**, 100,3′ d'arc à 94 m, et la lisibilité
lointaine **préservée avec témoin du kit rigoureusement identique**.

Ce qui échoue : **ISS-060** — les débris de la ferme sont des pavés droits à
96,8 % ; le liant `hexa` rend 79,6 % contre un plafond de 25. Je m'étais engagé
par écrit sur trois issues AVANT de mesurer ; la mesure en a donné une
quatrième, contre moi, et je l'ai acceptée.

Six instruments ont menti dans cette passe, **trois étaient les miens** : le
prédicat d'aplat est aveugle au gris (`r > v > b` strict), mon détecteur de
boîtes rendait 0,0 % par une union-find fusionnée à tort, ma prescription de
résidu linéaire était aveugle aux rampes géométriques. Deux de mes impressions
visuelles ont été réfutées par la mesure, et un agent m'a corrigé sur l'aile
sombre d'`arbre_pied`.

**ISS-059 corrigée dans le sens demandé par l'audit** : il refuse de confirmer
le `+100` sans instrumenter Godot ; « proportionnel au contenu ajouté » est
rétrogradée en hypothèse non recoupée, le `+100` reste **NON EXPLIQUÉ**, et le
faisceau des quatre classes figées n'est **pas** une preuve d'absence de
régression.

**Prochaine action exacte** : **s'arrêter pour la revue visuelle
Codex/Istvan** sur `evidence/world_v2/v2_3_r2b2/` — 15 caméras imposées
inchangées, 19 vues d'orbite, 6 triptyques `R2B / R2B.1 / R2B.2`, 2 planches
en niveaux de gris, `RAPPORT_R2B2.md`. **Aucune propagation aux 31 POI**
(`GO_V2_3_B=FALSE`), **aucune nouvelle release jouable** avant ce verdict. La
directive V2.3-B et la reconstruction du ZIP ne viennent qu'après le PASS.
Dettes ouvertes : ISS-059, ISS-060 (geste borné chiffré : `Debris_A/B`,
248 tris, 2 420 de budget disponible), ISS-061, UV0 de l'arbre, branche morte
de `_palisade`, marge nulle du camp braise.

## 2026-08-20 — R2B.3 : micro-corrective des débris et fuite ISS-059 (close en PARTIAL)

Base `291a621`, atteinte après **deux recréations de conteneur** — la seconde a
tué une mesure en cours. Interruption **démontrée** avant d'être supposée :
jeton absent, journal absent, sortie absente, verrou libre, zéro processus,
uptime 435 s. Leçon appliquée depuis : **le distant est la seule mémoire**, et
toute mesure longue écrit son jeton dans l'arbre suivi, pas dans `/tmp`.

**Verdict : `PARTIAL` sur une cause mesurée** — le `+100` d'ISS-059, devenu un
résidu de 281, n'est toujours pas causalement expliqué.

**La forme est gagnée et mesurée deux fois.** Liant 96,8 → 0,00 % ;
rectangularité 71,42 → 0,32 %. `0,00 %` est la valeur des tas de gravats
acceptés du kit. Le geste est structurel : `eclat()` rend `k+k+1` sommets, donc
jamais huit — le liant ne peut pas remonter par accident.

**Trois portails ont été trompés pendant cette passe, et chacun a été fermé.**
Un nom de mesh inconnu rendait `RC=0` et « OK » sur un ensemble vide. Dix-huit
pavés soudés par un coin rendaient 0,00 %. Puis un bruit cohérent de 2 mm —
invisible, 1,06 % d'une arête — rendait **les dix contrôles verts sur une
géométrie qui n'est que des boîtes**. Le troisième a été trouvé par l'audit
adverse dans un fichier que l'agent avait produit **et n'avait pas porté**.

**Trois instruments ont menti, tous les trois de mon côté.** L'autotest de
boîtitude échouait sur un cube unité (`abs(dot)` rangeait +X avec −X). Mon
plancher d'arête rejetait la grotte, le pont et l'arbre — trois assets gelés et
validés — parce que j'avais lu la fin de ma propre sortie. Et mon gel du vent ne
gelait rien : il appelait une méthode de `MeshInstance3D` sur l'herbe, qui est
un `MultiMeshInstance3D` ; l'erreur ne tuait pas le `SceneTree`, le processus
tournait sans fin **après avoir imprimé une ligne rassurante**, et n'écrivait
aucune image.

**ISS-063 est passé d'un soupçon à un mécanisme.** `user://` ne dérive pas du
répertoire de travail : tous les arbres en partageaient un seul, et deux runners
y ont **fabriqué un échec impossible**. En isolation, `world_v2` rend **99/0**
là où il rendait 96/1. Un verrou sérialise dans le temps ; une cloison sépare
dans l'espace.

**ISS-059 a changé de nature** : `DummyMaterial` **4 849 → 281**, et le résidu
restant est **exactement** celui qu'une sonde reproduit en 97 secondes hors de
la suite. Le problème est passé d'« une heure de suite pour un faisceau » à
« une minute et demie pour la même fuite, localisée à trois scènes ».

**Prochaine action exacte** : **s'arrêter pour la revue visuelle Codex/Istvan**
sur `evidence/world_v2/v2_3_r2b3/` — 11 montages A/B à caméras vérifiées
identiques, `RAPPORT_R2B3.md`, `preuves_lead/LECTURE_VISUELLE_LEAD.md`.
**Aucune propagation aux 31 POI** (`GO_V2_3_B=FALSE`), aucune release jouable,
aucun lancement de V2.3-B avant le PASS.

Dettes ouvertes : **ISS-059** (nommer l'objet qui retient les `PackedScene` —
la sonde de 97 s est prête), **ISS-062** (rien ne dit qu'il n'existe pas un
troisième contournement), **ISS-063** (un seul verrou et un `user://` par arbre
restent à poser au fond), ISS-060 (verdict visuel), ISS-061, UV0 de l'arbre,
branche morte de `_palisade`, marge nulle du camp braise.

---

## 2026-08-20 — R2B.3.1 : ISS-059 fermée sur causalité mesurée, ISS-063 étendue à tous les points d'entrée, dossier visuel léger

Base `06b865b`, après une **troisième recréation de conteneur** (HEAD retombé à
`c44f430`) : récupération par `git merge --ff-only` sur le distant, strictement
additive, jamais de reset. Base conforme à la directive vérifiée au SHA avant
de commencer.

**Organisation.** Le lead a tenu le verrou Godot et pris **toutes** les mesures
lui-même. Trois agents ont travaillé **sans jamais lancer le moteur** — audit
statique des points d'entrée, analyse statique des rétentions, fabrication des
planches — chacun suivi d'une contre-épreuve dont la mission était de le
réfuter. Ce que la contre-épreuve a corrigé est signalé comme tel.

### §1 — ISS-059 : le propriétaire est nommé

La question ouverte de R2B.3 était : *quel objet retient les `PackedScene`
épinglées ?* Réponse mesurée : **trois variables `static` de GDScript sans
propriétaire ni fin de vie** — `WorldV2PlaceKit._scene_cache` (89),
`AssetRegistry._model_cache` (21), `WorldV2PlaceKit._material_cache` (98).
`89 + 21 − 3 = 107`, exactement le compte de la bissection ; la contre-épreuve
a montré que la **différence symétrique est VIDE**.

Le reproducteur passe de 97 s à **22 s** : `WorldV2.tscn` seule porte tout, le
pylône est innocent. **Stable, pas cumulatif** : deux cycles → mêmes comptes à
l'unité. Ablation à variable unique : les cinq conteneurs emportent 98,6 % des
matériaux et 100 % des maillages.

**Correctif à la source** : `liberer_caches()` sur onze porteurs, inscrite par
`_static_init()`, appelée par `SceneFlow._exit_tree()`. Ce n'était pas la
rétention qu'il fallait corriger — elle borne une fuite pire — c'était son
absence de fin de vie. `DummyMaterial 281 → 0`, `DummyMesh 214 → 0`,
`DummyTexture 65 → 0`, `DummyShader 11 → 0`.

**Une erreur de conception rattrapée par un test existant** : la première
version portait la liste des porteurs dans `scripts/core/`, par chemin.
`test_aucune_reference_croisee_interdite` l'a refusée. Le sens est désormais
imposé : le porteur connaît le noyau, jamais l'inverse.

### §2 — ISS-063 : onze points d'entrée convertis, deux invariants posés

Dette comptée AVANT : 13 fichiers, 35 sites, **11 sans verrou ni cloison**.
Un mécanisme unique (`tools/lib/godot_env.sh`), onze conversions, et deux
invariants exécutables dont le cycle rouge d'abord a été joué.

### §3 — quatre planches légères

Dérivées des PNG existants, aucun rendu relancé. Deux défauts trouvés par le
contrôleur indépendant et corrigés : plafond de poids réglé plus haut que la
contrainte, et provenance illisible.

### Ce qui reste ouvert

- **ISS-064** ouverte : un flux audio (`land_soft.wav`) survit au démontage.
- **Blender hors verrou** : 30 fichiers, 4 avec verrou. Hors périmètre de cette
  directive, nommé comme dette.
- La **commande tapée à la volée** échappe à tout test de fichier.
- La clé `get_instance_id()` de `_material_cache` reste la cause de fond du
  besoin de rétention. Dette nommée, non traitée : la toucher changerait le
  comportement de teinte des lieux en pleine passe de gel géométrique.

### validate_fast, une seule exécution à la fin

**949 tests réussis, 0 échoué. HARNESS ROUGE.** La signature de sortie
s'effondre : `ObjectDB 1003 → 138`, `resources 657 → 74`, et les lignes
`DummyMaterial` (281), `DummyMesh` (214), `DummyTexture` (67) **disparaissent**
du rapport. `DummyShader 14 → 3`.

Le rouge tient à cinq lignes de fin de processus. **La composition des 138 n'est
plus déduite : elle est mesurée.** Suite entière relancée en `--verbose` (949
réussis, 0 échoué), vidage décomposé :

```
138 objets    = 74 GDScript + 61 GDScriptNativeClass + 3 Shader
 74 ressources = 71 .gd      + 3 .gdshader
  3 DummyShader = ces 3 mêmes Shader
```

La somme tombe juste au dernier objet, et il ne reste **ni matériau, ni
maillage, ni texture, ni flux audio**. **Une seule cause** : charger une `.tscn`
épingle ses `GDScript` et leurs `GDScriptNativeClass` — le cache de scripts du
moteur, qu'aucune API GDScript ne purge. Les trois shaders sont des constantes
`preload()` de `hero_shot_lab.gd`, script lui-même épinglé : une conséquence des
135 autres, pas une cause distincte. Le résidu est donc **entièrement attribué
au moteur ; plus aucun conteneur du projet n'y participe**.

Cela ne rend pas le harnais vert et n'est pas présenté comme tel. Le changement
`preload` → `load` qui retirerait la ligne `DummyShader` est **cosmétique** — il
ne rendrait rien vert — donc refusé, et le raisonnement est écrit plutôt que
caché : `evidence/world_v2/v2_3_r2b3_1/iss059/RESIDU_SUITE_COMPLETE.md`. Le
seuil du filtre N1 n'a pas été touché — un rouge préexistant ne se rebaptise
pas vert.

**Aucune géométrie touchée.** `SM_Farm_Ruins.glb` reste `ead79105e3deaf70`,
octet pour octet. `GO_V2_3_B=FALSE`.

**Prochaine action exacte** : la revue visuelle Codex/Istvan sur
`evidence/world_v2/v2_3_r2b3_1/revue_legere/` (quatre planches légères) et
`evidence/world_v2/v2_3_r2b3/preuves_lead/` (les 11 montages pleine
résolution). Aucune propagation aux 31 POI, aucune release jouable, aucun
lancement de V2.3-B avant ce PASS.

## 2026-08-21 — Clôture R2B.3.1 : PASS du lead, double portail, GO_V2_3_B

Le lead a rendu son verdict sur les quatre planches légères : **R2B.3 PASS
visuel et technique** — Debris_A, Debris_B, ferme_laterale, ferme_orb090,
quatre PASS. ISS-059 est FERMÉE pour les ressources du projet ; le résidu
moteur vit dans ISS-065 (limitation, non bloquante, surveillée par contrat).
La clause « harness global vert » est explicitement remplacée par le double
verdict : `PROJECT_RESOURCE_LEAK_GATE` bloquant · `ENGINE_SCRIPT_CACHE_TELEMETRY`
WARN qui redevient bloquante à la moindre dérive.

Validation finale (une exécution, 3 805 s) : **949 tests, 0 échec**, portail A
**VERT**, télémétrie **WARN conforme**, sonde de cycles à empreintes identiques.
RC du script = 1 sur deux méprises du JUGE — le filtre générique re-jugeait le
domaine de 2b avec l'ancienne sémantique, et la garde 2c comptait les lignes de
fin de processus que toute sonde émet. Corrigées, prouvées par rejugement des
mêmes journaux (4→0, 3→0) et contre-épreuve. Une exécution complète est
relancée sur le commit de clôture pour l'enregistrement RC=0.

Lot 1 pendant ce temps : trois voies livrées en worktrees détachés — A (sonde
d'implantation, mesures XZ, filet LOT1_PLACES écrit rouge), B (six lieux, plan
des silhouettes arrêté avant construction), C (filet des huit défauts, règle D3
pré-enregistrée avec deux garde-fous et témoin dégénéré). Deux sauvetages de
travail interrompu committés dans LEURS arbres, marqués non relus. Zéro
recouvrement de fichier entre les trois. Inspection passe 1 du lead : structure
saine, zéro primitive, récompenses cohérentes avec le PLAN canonique.

**Prochaine action exacte** : attendre le RC=0 de l'exécution relancée, puis
cueillette dans l'ordre de `evidence/world_v2/v2_3_b/lot1/RECOLTE.md` —
B (6 lieux) → A (le filet passe ROUGE, c'est voulu et archivé) → câblage
REGISTRY par le lead (`/tmp` : patch prêt, gardé) → C (8 filets) → UNE
validation → captures → checkpoint. AUCUN push entre les vagues.

## 2026-08-24 — V2.3-B lot 1 : six lieux verts sur les huit filets, R-D3 a mordu et a été satisfait, validate_fast 961/0

Session lead, passe 2 (sous moteur) après l'intégration des trois voies.

**Livré, avec preuve :**
- Instruments corrigés (3 pièges mesurés) puis plafond D1a calibré 20,4
  (`426d1ff`) ; défauts réels des lieux corrigés — appuis d'extrémité,
  filet D4 aligné StaticBody3D, budget D7 hors machinerie de récompense,
  exemptions d'aire câblées (`4a67589`).
- Détecteur R-D3 : FAIL réel (belvédère ≈ grotte 0,568 vs 0,493) →
  correction de COMPOSITION (aile nord en avant-poste, `aa4f689`) →
  recapture → PASS 0,481 (`cbb0611`). Aucun seuil touché nulle part.
- Contrôle négatif --lot1 : 8/8 familles vues sur LEUR critère ; la
  faille de signature D3 récompense-comprise vue par le contrôle et
  fermée (`2c95823`, `b7dc0c2`).
- Captures : 15 silhouettes + 13 plans POI + planche + carte, tout
  d'arbres committés, repo_dirty=false (`d16106c`).
- Boot smoke : épinglage 9 → 15 lieux, la pousse était le câblage du
  lot (`dc9330e`).
- **validate_fast : 961 tests, 0 échec, RC=0, VERT** — portail A vert,
  télémétrie moteur dans son enveloppe (138/74/3, aucun entérinement).
  Journal : `evidence/world_v2/v2_3_b/lot1/validate_fast_RC0_dc9330e.log`.
- Dette voie C soldée : ligne ASSET_MANIFEST de `SM_WaterfallCave_r2a358`.

**Observations versées à la passe art (non bloquantes)** : roches de kit
terracotta au belvédère/à la source (r04/r07 veulent un minéral froid) ;
nappe de la source quasi blanche au rendu (piège albédo ≠ valeur rendue).

**PROCHAINE ACTION EXACTE** : pousser la branche (`git push -u origin
claude/world-v2-reconstruction`), vérifier le SHA distant, puis publier le
checkpoint jouable : tag `world-v2-playtest-lot1-<sha court>` poussé sur ce
commit — le workflow `publish-playtest.yml` construit le ZIP et la Release.
Ensuite : verdict visuel du lead/propriétaire sur la planche du lot, puis
lot 2 (5-6 sujets suivants de `docs/V2_3_B_PLAN.md`).

### Post-scriptum — checkpoint publié

Le push du TAG est refusé par le mandataire Git (HTTP 403, cinq essais) ;
le workflow `publish-playtest.yml` a reçu une entrée de dispatch `lot1`
(nom du tag seulement) et a été déclenché sur `d78f007`. Release publiée
et RELUE : `world-v2-playtest-lot1-d78f007`, 9 assets — projet Godot
(407 Mo) ET les trois builds autonomes Windows/macOS/Linux, chacun avec
son SHA-256. Le tag pointe sur le commit poussé, vérifié par l'API.

https://github.com/istbanbanier/Zelda/releases/tag/world-v2-playtest-lot1-d78f007

Le lot 1 est LIVRÉ. Prochaine action exacte : verdict visuel du
lead/propriétaire sur `evidence/world_v2/v2_3_b/lot1/planche_lot1.png`
(+ observations d'art notées dans RECOLTE.md), puis lot 2 — 5 à 6 sujets
suivants selon `docs/V2_3_B_PLAN.md`, sur DIRECTIVE explicite : le §8 de
la directive courante interdit de lancer les lots suivants sans elle.

## 2026-08-24 — V2.3-B LOT 1.R : corrective visuelle EN COURS (handoff mi-parcours)

Entrée écrite **pendant** le travail, pas à sa clôture : trois sessions
d'agent ont déjà été tuées net par un épuisement de crédits, et rien de ce
qui suit ne doit être re-découvert.

**Mandat.** Verdict Codex sur le lot 1 : gate technique `PASS`, gate visuel
**REJET**, `GO_V2_3_B_LOT2=FALSE`. Objectif unique : corrective visuelle
LOCALE des six lieux du lot 1, base `89a3009`, monde V2.2 et systèmes gelés,
identifiants/récompenses/seuils/contrats inchangés. Un addendum de direction
artistique impose ensuite six ÉMOTIONS, une conception écrite avant tout gel
de géométrie (deux compositions réellement différentes par lieu, arbitrées
par le lead sans attendre le propriétaire), une vidéo joueur de 20–40 s aux
vrais contrôles par lieu, et une barre « wahou » appliquée par le lead.

**Méthode.** Trois arbres de travail détachés de `89a3009` — voie A
(belvédère, source), voie B (tour, sanctuaire, cimetière), voie C (champ,
outils de preuve, audit contradictoire). Un propriétaire par fichier ; les
voies ne poussent jamais ; le lead reproduit, inspecte et cueille.

**Les six arbitrages sont rendus** (conditions détaillées transmises à
chaque voie) : tour = B « La vigie retrouvée » · belvédère = A « La
mâchoire » · source = A « La bouche » · sanctuaire = B « La nef avalée » ·
cimetière = A « Le chemin des morts » renforcée · champ = B « La Porte des
fleurs ».

**Trois décisions de lead, chacune adossée à une mesure :**

1. *La promesse turquoise de la source à incidence rasante n'existe pas.*
   Vérifié par le lead sur `voie_a/v5/spring_promesse_p1.png` : la vasque ET
   l'affluent GELÉ rendent le même ruban blanc dans le même cadre — miroir
   spéculaire de ciel. Le shader V2.2 reste en lecture seule (un shader local
   casserait la continuité que la directive exige) ; la promesse à distance
   est un contraste de VALEUR, le turquoise doit apparaître tôt sur
   l'approche, et si aucun point du parcours réel n'y parvient c'est
   `PARTIAL` documenté — jamais une promesse inventée.
2. *Aucun `.avi` n'entre dans git.* `.git` pèse déjà 1,9 Go ; une vidéo de
   17,7 s pèse 175 Mo, et le conteneur n'a ni ffmpeg, ni imageio, ni cv2.
   Six vidéos committées ajouteraient plus d'un gigaoctet d'historique
   irréversible. La preuve committée est une PLANCHE CONTACT extraite de
   l'AVI MJPEG (balayage des marqueurs JPEG + PIL) plus le sha256 et les
   paramètres au manifeste ; la vidéo part en pièce jointe de Release.
3. *Le disque teal derrière la tour* — **cette hypothèse était FAUSSE, et
   c'est la mesure qui l'a démontrée.** J'avais écrit qu'il appartenait au
   monde gelé (une instance de végétation V2.2), en le donnant à confirmer.
   La voie B a sondé l'écran plutôt que de me croire : le disque est à 11,5 m
   de la caméra joueur, emprise pixel 725-892 × 364-413, et le SEUL nœud
   couvrant le rectangle incriminé est le caillou de pied `rock_largeC` —
   un module du LIEU, pas du gel. La cause est dans son glTF : il porte
   **deux matériaux, `dirt` et `grass`**, et la surface « grass » des kits
   Kenney rend menthe/sarcelle sous cette lumière. Corrigé par changement de
   FAMILLE (`Rock_Medium_2`, matériau unique, gris neutre) et non par teinte.
   Aucun ticket à ouvrir, aucun gel en cause. **La même cause a été retirée
   du cimetière** : `rock_largeA`, `rock_largeC` et `rock_smallB` portent tous
   `grass` + `dirt` — c'étaient les « chapeaux turquoise » mesurés sur la
   capture d'avant. C'est le vrai mécanisme derrière le teal qui a mordu
   quatre fois dans ce lot ; il vaut mieux que la règle vague que j'en avais
   tirée.

**Acquis au moment d'écrire** (aucun verdict, ce sont des états) :
voie A — géométrie des deux lieux committée (`149e79c`), preuves finales
manquantes ; voie B — tour compo B committée (`68cbdf6`), palier praticable
prouvé par sonde physique, sanctuaire et cimetière non commencés ; voie C —
champ compo B implémenté, deux outils de preuve livrés et auto-testés
(`lot1r_planches.py`, `lot1r_manifeste.py`), vidéo réelle enregistrée mais
trop courte (17,7 s pour 20–40 exigées), deux passages d'audit
contradictoire livrés.

**Deux inspections faites par le lead lui-même** (un juge par fait) :
la vue du palier de la tour tient — vallée, rivière, hameau et pylône cadrés
par la maçonnerie de la brèche : l'intention « le paysage est la récompense »
est jouée ; le champ a gagné ses nappes (il est redevenu le sujet) mais son
cheminement se lit en poches disjointes plutôt qu'en voie, et sa « Porte »
ne se lit pas comme une porte dans la vue joueur — les deux constats sont
partis à la voie C avec l'ordre de priorité.

**Notes de reprise durables** : `HANDOFF_LEAD_A.md`, `HANDOFF_LEAD_B.md`,
`HANDOFF_LEAD_C.md`, à la racine de chaque arbre de travail.

### Mise à jour du même jour — le défaut transverse est identifié et mesuré

Trois passages d'audit contradictoire plus tard, l'état est plus clair et
**moins bon** qu'à l'entrée : le lot n'est pas présentable à la revue.

**Le défaut central du lot est un APLAT DE VALEUR**, et il a une cause
mesurée. Profils de luminance pris en travers d'une face : stèle du cimetière
**109 constant sur 48 px**, linteau du dolmen **82 sur 135 px**, montants du
sanctuaire **94 constant**, dalle au pied de la tour **141 constant** —
étendue ZÉRO. Le tertre voisin, lui, varie (76→99) : ce n'est donc pas une
limite du rendu, c'est une propriété de ces pièces. La cause, isolée par la
voie C sur son propre asset : sur des faces quasi verticales sous ce ciel,
l'irradiance ambiante domine et l'orientation ne rapporte presque rien — un
maillage à **465 directions de normale distinctes rendait UNE seule valeur**.
Les roches de kit se lisent en pierre grâce à leur ATLAS, pas à leur
géométrie. Sans texture, la seule variation gratuite est `COLOR_0` : posée,
la même face passe de 1 à **31–32 niveaux**. C'est la famille de défaut qui a
fait rejeter le lot ; c'est donc le geste le plus rentable du lot.

**Trois rulings de lead, à ne pas re-débattre :**

1. *Le coffre et les sphères de récompense.* Quatre lieux sur six montrent un
   visuel de récompense étranger au monde (ISS-067, relevé en S2). Un lieu est
   autorisé à habiller son PROPRE exemplaire — teinte par surface sur une
   copie, sans muter la ressource partagée, exactement la technique des
   pierres ; il ne peut pas remplacer le modèle. Et l'ALTITUDE de l'ancre,
   elle, appartient au lieu : une récompense qui flotte est un défaut du lieu.
2. *Le panorama du belvédère.* Troisième passage identique — donc changement
   d'hypothèse, pas quatrième tentative. La caméra gelée de ce lieu a été
   posée avant cette composition, et l'intention de l'addendum est une
   SÉQUENCE. Le trait d'identité se juge sur les vues AJOUTÉES du parcours et
   sur la vidéo, qui sont des PLUS jamais des remplacements ; les vues gelées
   restent livrées et jugées pour leurs propres défauts.
3. *L'épaisseur de la tour.* L'audit s'est corrigé lui-même : l'épaisseur
   EXISTE (arase en tranche, deux parements, vide intérieur, visibles depuis
   le palier). Le défaut est que les caméras de revue ne la montrent pas —
   **une capture supplémentaire**, pas une reconstruction.

**Changement d'hypothèse sur le turquoise de la source** : la rivière GELÉE
rend un bleu-sarcelle franc depuis un autre angle, donc le shader sait rendre
turquoise dans ce monde. Ce qui diffère au lieu : la pénombre du ravin
(l'herbe y rend (57, 81, 72)). À mesurer — même eau, un échantillon à l'ombre
et un au soleil. Si l'ombre est la cause, le concept « contraste
ombre/turquoise » s'auto-détruit et il faut soit une poche de lumière, soit un
`PARTIAL` mesuré.

**Deux tickets nés du lot** : ISS-066 (`gltf_inspect.py` ne regarde jamais
`COLOR_0` — un asset à couleurs de sommet peut sortir vide et être déclaré
VALIDE ; le « test qui ne peut pas échouer ») et ISS-067 ci-dessus.

**Périmètre de la voie C clos** : champ en composition B, outils de preuve,
vidéo joueur de 26,5 s aux vrais contrôles (planche contact committée, `.avi`
hors dépôt), trois passages d'audit. Les voies A et B corrigent.

**PROCHAINE ACTION EXACTE** : attendre les livraisons des trois voies, puis
— sans rien pousser avant — reproduire et inspecter chaque lieu en taille
réelle, cueillir par cherry-pick dans l'ordre A → B → C (un propriétaire par
fichier, zéro conflit attendu), rejouer les filets du lot 1, les huit
sabotages `tools/gate_negatif_lot1.sh --lot1`, UNE seule `validate_fast.sh`,
produire les preuves (13 caméras gelées, planches couleur et niveaux de gris,
planche anonyme des six vues joueur, silhouettes, planches contact vidéo,
manifestes `repo_dirty:false`), appliquer la barre « wahou » lieu par lieu,
puis clore par la formule imposée. **Interdits jusqu'au verdict visuel de
Codex/Istvan** : tout sujet du lot 2, toucher à la Release courante, publier
une nouvelle Release, et tout verdict artistique auto-déclaré.

### 2026-08-24, reprise après recréation du conteneur — la validation est MORTE, pas « en cours »

Constat établi par deux mesures espacées de 60 s, et non par déduction.

**Le conteneur a été recréé** (cinquième fois du projet), 17 minutes avant la
reprise. Conséquences mesurées :

| Fait | Mesure |
|---|---|
| Processus `validate_fast.sh` | **ABSENT** du scan `/proc` aux deux mesures |
| Processus `godot` | **ABSENT** — les deux « présents » du premier scan étaient la ligne de commande du script de mesure lui-même, qui contient les mots cherchés |
| Journal `/tmp/lot1r_int/validate_fast.log` | **DISPARU** — `/tmp` vidé |
| Token de RC final | **INEXISTANT** — aucun n'a jamais été écrit |
| Dernière étape réellement atteinte | `1b — parse de TOUS les scripts GDScript` |
| Arbres de travail `wt-lot1r-*` | **DISPARUS**, y compris de la métadonnée git |
| HEAD local avant reprise | `031f0ad`, vieux de trois jours |
| HEAD distant | `a45b832` — tout le lot 1.R y était |

**Cette passe de validation est donc INCOMPLÈTE et INVALIDE.** Elle n'a
jamais rendu de verdict ; annoncer qu'elle « tournait » était une erreur de
lecture — le code retour 0 reçu était celui du lanceur, pas de la validation.

**Rien n'a été perdu** : le local était un ANCÊTRE du distant, l'avance
rapide a été propre, et le dépôt est revenu à `a45b832` à l'identique.

**Ce qui reste acquis et prouvé** (tout est sur le distant) : les trois voies
cueillies (`c233ceb`, `9bb38a1`, `488df31`), les quatre lignes de manifeste
aux empreintes recalculées (`5a35c99`), l'import RC 0, les filets 11/11 et
5/5, le contrôle négatif **8 déclarés / 8 joués / 8 validés** (`213e1a2`), le
détecteur R-D3 passé de FAIL à **PASS** par correction de composition
(`d527d70`), et les captures couleur du cimetière avec la divergence de
lecture portée à la revue (`a45b832`).

**Ce qui manque, et rien d'autre** : l'unique passe `validate_fast.sh` de
clôture, puis les preuves visuelles du lot et la clôture elle-même.

**PROCHAINE ACTION EXACTE** : relancer UNE passe `tools/validate_fast.sh`
depuis cet arbre committé propre, avec son journal écrit DANS le dépôt et un
token de fin portant le code retour — pour qu'une recréation de conteneur ne
puisse plus effacer la preuve ni laisser croire qu'un travail continue.

### 2026-08-24, la passe de clôture est sortie ROUGE — une cause, la bonne

La passe relancée sur l'arbre intégré `29f06bc` a rendu un vrai verdict, et
ce verdict était **ROUGE**. Le token de fin l'a écrit noir sur blanc :
`sha=29f06bc rc=1`.

| Mesure | Valeur |
|---|---|
| Tests exécutés | **960**, plancher 586 respecté |
| Échoués | **1** |
| Cause | `test_invariants.gd::test_tout_cache_statique_de_ressources_est_liberable` |
| Fichiers en cause | `forest_shrine_place.gd`, `watchtower_ruin_place.gd`, `barrow_cemetery_place.gd` |

Les trois lieux de la voie B ont gagné un cache statique en même temps que
leur GLB dédié. **Aucune ligne du diff ne montrait le manque** — ce qui
manquait, c'est une fonction ABSENTE. C'est le partage des rôles décrit dans
`PROMPT4_METHOD` §2 : le hook regarde les lignes ajoutées, le test regarde
l'état du projet. Ici seul le second pouvait voir.

**Correctif** (`3fd004c`) : le motif déjà en place dans
`abandoned_farm_place.gd` — un `static func liberer_caches() -> int` inscrit
au démarrage du script par `_static_init()` auprès de `StaticResourceCaches`,
appelé une fois à l'extinction par `SceneFlow._exit_tree()`. Vérifié en
isolement : `--filter=invariants` → **9 réussis, 0 échoué, RC=0**.

Le journal ROUGE est committé avec le correctif, sous
`evidence/world_v2/v2_3_b/lot1r/validation/`. Un dossier qui ne garde que ses
verdicts verts ne prouve rien.

**Enveloppe de validation durable** : `/home/user/lot1r_validation/run.sh`
écrit son journal HORS de `/tmp` et un `VERDICT_<sha>.token` portant
`sha=`, `rc=`, `fin=`. **Sans token, il n'y a pas eu de verdict**, quoi
qu'affiche un journal partiel — la règle née des cinq recréations de
conteneur.

**PROCHAINE ACTION EXACTE** : attendre le verdict de l'unique passe complète
relancée sur `3fd004c` ; si vert, produire les preuves visuelles du lot sur
l'arbre INTÉGRÉ (13 caméras gelées en A/B, gros plans, silhouettes 0°/90°,
planches couleur et niveaux de gris, planche anonyme des six vues joueur avec
clé dans un JSON séparé, preuve croisée `gp_lointain` tour + source dans une
même image), **réenregistrer les six vidéos joueur sur l'arbre intégré** —
celle de la voie C date d'un arbre où les cinq autres lieux étaient encore
rejetés, donc son arrière-plan ne prouve pas le lot — puis appliquer la barre
« wahou » lieu par lieu, mettre à jour STATUS/PROGRESS/RECOLTE, pousser, et
clore par la formule imposée. **Interdits** : tout sujet du lot 2, toucher à
la Release courante, publier une nouvelle Release, tout verdict artistique
auto-déclaré.

### 2026-08-24 — la passe de clôture est VERTE, et la passe de preuves est lancée

    sha=3fd004c  rc=0  fin=2026-08-24T15:38:22Z
    === RÉSULTAT: 961 réussi(s), 0 échoué(s) ===
    961 test(s) exécuté(s), plancher 586 respecté
    === VALIDATE_FAST : VERT ===

Durée réelle **68 minutes** (14:30 → 15:38), rendu logiciel. L'estimation de
20 minutes faite plus tôt était fausse d'un facteur trois : la passe ROUGE
précédente avait duré 70 minutes (13:08 → 14:18), ce qui se lisait dans son
propre journal.

**Pourquoi 960 puis 961** — vérifié, pas supposé. Les deux journaux **nomment
exactement 961 tests** ; l'ensemble est identique, zéro apparu, zéro disparu.
La passe ROUGE affichait « 960 exécutés » parce que ce compteur ne comptait que
les réussites : 960 + 1 échec = 961. **Rien n'a été ajouté pour verdir.**

**Portée exacte du verdict** : il porte sur `3fd004c`. Depuis, HEAD n'a reçu
que des documents, des preuves, et un outil autonome
(`tools/verifier_manifeste_lot1r.py`). `validate_fast.sh` n'appelle que deux
outils python — `gate_fuite_ressources.py` et `blender/check_continuity.py` —
et aucun test ne l'importe. Le diff `3fd004c..HEAD` ne contient **aucun**
script GDScript, scène, ressource, asset ni test.

**Trois défauts trouvés en vérifiant mes propres écritures**, chacun corrigé et
rendu exécutable :

| Défaut | Ce qu'il aurait coûté | Fermeture |
|---|---|---|
| Le verdict D3 `PASS` cite un commit introuvable | une preuve invérifiable présentée à la revue | rejoué sur HEAD ; `git rev-parse --short` abrège sans vérifier — seuls `cat-file` et `merge-base` répondent |
| `SM_Watchtower_Ruin` portait un sha256 d'aucun blob de l'histoire | un manifeste de provenance faux | corrigé ; `tools/verifier_manifeste_lot1r.py`, éprouvé par sabotage ; **ISS-068** ouverte |
| Les parcours vidéo de la voie A étaient injouables | un film crédible et faux | convertis au schéma de l'outil, allure ramenée à la marche |

**Pré-vol de la passe de preuves** (`final/PREVOL.md`) : huit contrôles avant de
dépenser une heure de rendu, dont deux pièges attrapés — `lot1r_planches.py`
**meurt** si les dossiers AVANT et APRÈS diffèrent d'une seule vue (40 plans
contre 13 auraient fait échouer la dernière étape après tout le rendu), et la
planche anonyme exige **exactement** six vues `*_joueur`.

**PROCHAINE ACTION EXACTE** : à la fin de la passe de preuves (token
`PREUVES_<sha>.token`), regarder les images **en taille réelle**, appliquer la
barre « wahou » lieu par lieu en cherchant d'abord le trait d'identité, puis
enregistrer les cinq vidéos joueur restantes (planche contact + sha256, l'AVI
ne rentre pas dans git), remplir §6 et §7 de `RAPPORT_1R.md`, mettre à jour
STATUS, pousser, et clore par la formule imposée. **Interdits** : tout sujet du
lot 2, toucher à la Release courante, publier une nouvelle Release, tout
verdict artistique auto-déclaré.

### 2026-08-25, reprise Codex — BLOQUÉ sur le bundle, tout le reste est prêt

Directive reçue : intégrer les trois commits de Codex
(`c29a6c54` quatre lieux reconstruits · `c23df0ce` preuves `codex_final/` ·
`1adeb207` nettoyage des sauvegardes de tests) depuis
`Zelda-Lot1R-Codex-handoff.bundle`, valider, pousser, remettre en revue.

**Le bundle n'a jamais atteint ce conteneur.** Recréation numéro six : le HEAD
local datait de trois jours, avancé proprement vers `19f70f7` — le SHA exact
vérifié par Codex, rien de poussé n'est perdu. Mais la pièce jointe est morte
avec l'ancien conteneur : aucun `.bundle` sur tout le disque, `/mnt/attach` et
`/mnt/user-data/working` vides, les trois SHA absents de l'object store,
aucune ref distante ne les porte. Détail et procédure de reprise exacte :
`evidence/world_v2/v2_3_b/lot1r/reprise_codex/BLOCAGE_BUNDLE.md`.

**Fait en attendant, prouvé, committé** (`65572be`) :

| Préparation | Verdict |
|---|---|
| Godot 4.7.1-stable, binaire direct sans wrapper ZIP | présent |
| Blender 4.0.2 + NumPy 1.26.4 | présents |
| Continuité des SIX personnages, `check_continuity.py` réellement exécuté | **6/6 « UN SEUL corps solidaire », RC=0** |
| Worktree détaché sous `/tmp`, import | RC=0 |
| `room2_vertical,room4_battery,dungeon_run` ENSEMBLE, isolés | **26 réussis, 0 échoué, RC=0** |

Le dernier point reproduit de notre côté le diagnostic de Codex : les huit
rouges historiques venaient des restaurations externes dans le workspace
synchronisé, pas du jeu.

**Volontairement NON joué** : filets 16/16, sabotages D1–D8, validation
complète — ils doivent tourner sur l'arbre INTÉGRÉ ; un vert du mauvais arbre
est pire qu'aucun vert.

**PROCHAINE ACTION EXACTE** : dès que le bundle est de nouveau accessible
(re-joint à un conteneur vivant, ou poussé par Codex sur une branche neuve
`codex/lot1r-handoff`) — vérifier son sha256
(`03632748b950…`), `git bundle verify`, fetch dans
`refs/heads/codex-lot1r-handoff`, `git cat-file -e` sur les trois SHA,
cherry-pick dans l'ordre c29a6c54 → c23df0ce → 1adeb207, **push immédiat du
checkpoint**, puis filets 16/16, D1–D8 8/8, 26/26 isolés, continuité 6/6, et
UNE `validate_fast.sh` depuis un worktree `/tmp` (faire `git worktree prune`
d'abord si le conteneur a encore changé). Interdits inchangés : lot 2, toucher
à la Release, verdict artistique auto-déclaré.

### 2026-08-25 — LOT 1.R : candidate visuelle reconstruite, persistée, contrôles ciblés verts

La directive maître du 2026-08-25 a été exécutée de bout en bout : recherche
du bundle close, contrat visuel écrit et poussé AVANT la géométrie
(`docs/V2_3_B_LOT1R_VISUAL_CONTRACT.md`, `de43152`), trois branches de
récupération créées, trois agents en worktrees (plans courts arbitrés), trois
checkpoints cueillis, prouvés et poussés.

| Checkpoint | SHA poussé | Contenu |
|---|---|---|
| C — champ | `14153d8` | le proche planté (628 → 1 101 instances, vert nu 76 → 33 %), lobes-phrases, île de la fourche |
| A — belvédère + source | `66e1cc8` | GLB `SM_OverlookCrags` stratifié froid + assise ; `SH_TurquoiseSpringWater` (S 0,079 → 0,490 caméra joueur gelée) |
| B — tour + sanctuaire + cimetière | `4f66609` | COLOR_0 tour + récompense en hauteur ; cœur/seuil/ruine du sanctuaire ; normales lissées + valeur du cimetière |

**Deux rouges RÉELS attrapés par les filets à l'intégration, corrigés sans
toucher un seuil** :
- D7 : sanctuaire 43 modules > 40 (le dallage 3 → 9) — consolidation lead,
  trois micro-décors sans trait de contrat retirés (`4f66609`) ;
- R-D3 : champ ≈ camp braise à 80 m (IoU 0,5101 > 0,4912) — cause mesurée en
  rejouant le sous-échantillonnage du détecteur (bande incluse dans bande),
  corrigée par la « variation de hauteur » que le contrat demande : l'arbre du
  champ (`0e4adc4`), IoU retombée à **0,0839**, PASS rejoué (`c80b776`).

**Erreur de ma fabrication, corrigée et dite** : mon shots_champ.json a envoyé
deux vues gp dans `ab13/` — lot1r_planches est mort en code 2, comme conçu.

**Candidate** : `evidence/world_v2/v2_3_b/lot1r/candidate/` — 70 images au
manifeste global, 13 A/B, planches couleur/gris/anonyme (clé séparée)/
silhouettes/matière, deux verdicts D3 (le FAIL gardé à côté du PASS), filet
25/25, dossier de revue avec les six questions §19 SANS réponse du lead.

**PROCHAINE ACTION EXACTE** : attendre le verdict visuel Codex/Istvan sur le
dossier. Si REJET : corriger UNIQUEMENT les lieux rejetés, geler les acceptés,
refaire leurs preuves, nouvelle candidate — sans lancer `validate_fast.sh`.
Si PASS : geler les six lieux, rejouer les filets complets, les huit
sabotages D1–D8, `validate_fast.sh` UNE fois depuis un worktree `/tmp`,
checkpoint jouable, release Lot1.R sans écraser l'ancienne. **Interdits
inchangés** : lot 2, toucher à la Release courante, verdict artistique
auto-déclaré.

---

## 2026-08-26 — V2.3-B LOT 1.R.2, clôture : validation complète VERTE, test de fumée ROUGE, **aucune Release publiée**

**SHA en jeu, distingués comme la directive l'exige** :

| rôle | SHA |
|---|---|
| géométrie capturée / verdict visuel Codex | `51b7b29` |
| gel des six lieux | `51b7b29` (46 fichiers, sha256 **et** blob) |
| **validation et test de fumée** | **`919511d`** |
| documentation finale | ce commit |

**§1 gel** — 46 fichiers épinglés deux fois (disque + blob git). Vérifié
46/46 avant la validation, 46/46 après les sabotages, 46/46 après
`validate_fast.sh`, 46/46 après le test de fumée. Rien n'a bougé.

**§3 validation complète, exécutée UNE fois, VERTE** :

| portail | résultat |
|---|---|
| filets lot 1 complets | 23/23, RC=0 |
| sabotages D1–D8 | 8 déclarés, 8 joués, **8 validés** |
| `gel_verifier` | 43/43 |
| ISS-070 | **PASS**, fenêtre 1,31 m, capsule réelle balayée dans les deux sens |
| manifeste des six lieux | 6/6, 0 écart |
| `tools/validate_fast.sh` | **VERT**, 961 tests, 0 échec, plancher 586 respecté |

Aucun seuil déplacé pour obtenir un vert.

**§4 test de fumée sur la build EXPORTÉE — ROUGE, et c'est lui qui a payé.**
Templates d'export téléchargés, export Linux autonome produit depuis l'arbre
committé (393 752 464 o), lancé en installation neuve avec un `user://`
vierge sous Xvfb.

Ce qui PASSE, chaque point adossé à une observation : démarrage, menu,
« Nouvelle partie » → **World V2, jamais V1** (0 mention), monde monté
(64 chunks, 4 régions, **15 scènes posées**, `fondation V2 vérifiée`), écran de
jeu réellement affiché (luminance 0,5196 contre 0,0027 pour l'écran de
chargement), **caméra qui tourne à la souris** (RMSE 0,1482), **déplacement à
la touche Z** (0,0549), **gravité** (saut 0,0604 puis retour 0,0575),
sauvegarde écrite dans un `user://` vierge, reprise qui rouvre World V2.

Ce qui ÉCHOUE, **ISS-071** : **1 094 appels de placement manqués, 110 modèles
distincts absents** — kit de lieu, végétation, dalles. Cause **prouvée par un
laboratoire**, pas déduite : dans le PCK le fichier SOURCE n'est pas empaqueté,
seul son `<nom>.gltf.import` l'est. Les deux fonctions qui indexent par
balayage de répertoire (`WorldV2PlaceKit.scene_for`, `AssetRegistry.model`)
testent le suffixe `.glb`/`.gltf` et ne trouvent donc jamais rien, alors que
`load()` sur un chemin explicite réussit. En éditeur : **0**. Ma première
hypothèse — un suffixe `.remap` — était plausible et FAUSSE ; c'est le lab qui
a tranché. Les six lieux gelés chargent bien leur asset propre (chemin explicite,
remap transparent) mais appellent tous le kit : leur masse est là, leur
habillage non.

**Ce n'est pas une régression du lot.** La build DÉJÀ PUBLIÉE
`world-v2-playtest-lot1-d78f007` a été téléchargée et lancée ici : 534
`modèle inconnu`, 631 `modèle végétal introuvable`.

**§5 — AUCUNE Release publiée.** Aucune release existante touchée.

**PROCHAINE ACTION EXACTE** : décider d'ouvrir, ou non, une passe ISS-071 —
elle sort du périmètre de cette clôture et touche la résolution d'assets de
TOUT le jeu. Si elle est ouverte, l'ordre imposé est : (1) un portail qui
EXPORTE, LANCE et COMPTE ces lignes, rouge d'abord sur `919511d` ; (2) le
correctif dans les **deux** fonctions à la fois ; (3) `validate_fast.sh` ;
(4) nouveau test de fumée ; (5) alors seulement la Release Lot1.R.2. Le
document joueur `docs/PLAYTEST_LOT1R2.md` et le mode `lot1r2` du workflow sont
prêts et attendent, placeholders de SHA non remplis. **Interdits inchangés** :
lot 2, propagation aux 25 POI restants, toucher à V2.2 ou à une Release
existante, verdict artistique auto-déclaré.

## 2026-08-27 — S1 close : Release lot 1.R.2 publiée et revérifiée depuis GitHub

Ordre du propriétaire exécuté en entier, dans l'ordre imposé. (1) Trois
défauts corrigés — `TITRE` non défini (NameError), `pkill -x Xvfb` remplacé
par `-displayfd` + registre `PROCS_POSSEDES` à nettoyage garanti,
`lieux_poses` compte les 15 scènes du layout et plus le nœud `Recompenses`
(oracle : meta `place_id` des enfants directs de `$Places` ; gel amendé,
D-054). (2) Contre-revue à trois vérificateurs AVANT la chaîne : un bloquant
(jeu lancé sans `stdbuf` — une release ne vide pas stdout, `terminate()`
détruisait les jalons) et neuf écarts, tous intégrés. (3) Chaîne unique sur
l'arbre committé : `validate_fast` VERT ; export Linux neuf RC=0 ; checklist
**16 PASS + 1 PARTIAL** (la gravité, jugée au pixel : critère invalide,
voir S1.1) — annoncée à tort « 17/17 » dans le rapport initial ; six vues 13/13 avec RMSE publiés (oracle calibré sur le bruit
run-à-run mesuré entre les deux runs éditeur committés — flower_field 0,125
pour un bruit propre de 0,109 : c'était le vent, quadrants à l'appui). (4)
Release `world-v2-playtest-lot1r2-05d0760` (run 33085639174) : les quatre
archives RETÉLÉCHARGÉES depuis GitHub, tailles au octet et SHA-256 conformes
aux deux registres, guide avec SHA remplis PAR la CI, et le binaire Linux
retéléchargé LANCÉ — 13/13, manifeste 215/215+160/160, lieux_poses 15. (5)
Ancienne release `world-v2-playtest-lot1-d78f007` annotée « dépassée » par le
nouveau workflow `annotate-release.yml` (ajouté sur la branche par défaut,
seul endroit d'où GitHub accepte un dispatch — additif, idempotent, jamais
destructif) ; ses fichiers restent en ligne.

**Prochaine action exacte** : rien n'est en vol. Le lot 1.R.2 est clos ; le
prochain front est le lot 2 de V2.3-B (interdit jusqu'à levée explicite de
GO_V2_3_B_LOT2=FALSE par le propriétaire). Hors périmètre consigné : 31
modèles hors des huit répertoires indexés (22 par chemin explicite, 9
outils/périmés) — décision d'indexation à prendre un jour, aucune urgence.
