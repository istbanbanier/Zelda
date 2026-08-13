# Preuves V2.1 — vallée whitebox physiquement traversable

Phase : V2.1, branche `claude/world-v2-reconstruction`, base de phase `0da6c8d`,
état final prouvé : commit `487f9d6` (les fichiers datés ci-dessous portent
chacun leur SHA). Ce dossier prouve la **vérité spatiale** de la vallée V2 —
relief, eau, lieux, routes, limites, navigation, traversée réelle — et
seulement cela. Aucun habillage artistique n'est revendiqué : le monde est un
whitebox de diagnostic et chaque capture le montre tel quel.

## Verdicts

| Critère | Statut | Preuve |
|---|---|---|
| 64 chunks raccordés, UNE fonction de hauteur, collisions séparées | PASS | `world_v2_suites_finales.log` (coutures comparées échantillon par échantillon) ; contrôle A |
| Relief réel (ni dalles, ni replat V1 — ISS-045) | PASS | plat <1° = 13,0 % (plafond 30) — `metrics_world_v2.json` |
| Ancres §3.3 littérales, sol physique conforme | PASS | suite ancres ; hauteurs mesurées 24/6/18/34 exactes — `metrics_world_v2.json` |
| 31 POI + 3 sites + 5 grottes (IDs épinglés) + checkpoints + accès donjon | PASS | suite ancres ; manifeste des lieux dans `metrics_world_v2.json` |
| Hydrologie : contenance, 3 gués praticables (ISS-032), lac en bol, pont sur l'eau | PASS | suite hydrologie ; profondeurs de gué 0,30–0,35 m |
| Routes : sol physique continu au mètre (tablier compris) | PASS | suite routes ; contrôle B |
| Limites : 72 azimuts fermés, gardes `unclimbable` VISIBLES hors zone jouable | PASS | suite limites ; contrôle C |
| Six fenêtres de composition posées et dégagées | PASS | suite caméras + 6 captures inspectées une à une |
| Navigation cuite par quadrant, ancres reliées, lac = île | PASS | suite navigation ; polygones 2758/2416/2953/3192, arrivées ≤0,75 m — `metrics_world_v2.json` |
| Traversée RÉELLE : 4 routes au pilote InputIntent, zéro téléportation | PASS | suite traversal (garanties PAR TICK : jamais sous le monde, aucun saut >3 m, arrivée vivant) |
| Protections : SCHEMA_VERSION == 4, ancres du layout littérales | PASS | suite protections |
| V1 intacte | PASS | revue contradictoire : `git diff 0da6c8d..HEAD -- scripts/world/ scenes/world/ scripts/save/` vide |
| Tests qui savent rougir | PASS | 3 contrôles négatifs archivés + rouge waterways historique (bb80761) |
| validate_fast.sh sur l'état final | voir `validate_fast_final.log` | RC archivé en tête du log |
| Revue contradictoire à contexte frais | PASS avec réserves non bloquantes | `revue_contradictoire.md` |

## Journaux

- `world_v2_suites_finales.log` — 33/33 au commit final (en-tête : date, SHA, commande).
- `validate_fast_final.log` — suite complète du dépôt (niveaux 1-3) sur l'état final.
- `controles/controle_A_couture_{ROUGE,VERT}.log` — chunk c4r3 décalé de 0,35 m :
  « frontière est de c3r3 : écart 0.003 à l'échantillon 5 » ; restauré, re-vert.
- `controles/controle_B_tablier_{ROUGE,VERT}.log` — collision du tablier retirée :
  « river_route : marche de 1.40 m/m en (-22, -58) » ; restauré, re-vert.
- `controles/controle_C_breche_{ROUGE,VERT}.log` — garde 7 absent : « azimut 70° :
  brèche » + compte 35/36 ; restauré, re-vert.
- `metrics_world_v2.json` — métriques et manifestes extraits du monde MONTÉ
  (`tools/godot/probe_world_v2_metrics.gd`), datés et reliés au commit.

## Captures (arbre COMMITTÉ, manifestes `repo_dirty: false`)

Six fenêtres 1280×720 (llvmpipe — régression visuelle uniquement, JAMAIS une
mesure) : `capture_cam01_spawn_vista` … `capture_cam06_plateau_vallee`, chacune
inspectée réellement avant toute revendication. Elles prouvent des RELATIONS
SPATIALES : descente de crête et routes divergentes (cam01), camp→gué
est→pylône (cam02), pylône→steppe→rampe (cam03), falaise→cuvette (cam04),
belvédère→crête (cam05), plateau→vallée entière avec le tablier du pont
au-dessus de la gorge du bras nord (cam06).

**L'inspection a mordu** : la première série (commit `415a3c4`) montrait un
premier plan ABSENT — l'enroulement du maillage de terrain rendait le DESSOUS
du monde, invisible depuis presque tous les angles de jeu, et la note ISS-018
d'origine affirmait l'inverse sans capture. Pièce conservée :
`capture_cam01_AVANT_enroulement_415a3c4.png`. Correctif : commit `487f9d6`
(enroulement inversé, culling par défaut) ; les 33 tests re-passés dessus.
Aucun test de collision ne pouvait voir ce défaut — seule l'image le pouvait.

## Trouvailles d'ingénierie de la phase (mesurées, documentées au point d'usage)

1. **`NavigationMesh.agent_max_slope` est en DEGRÉS** (source 4.7.1) —
   `deg_to_rad(44)` = 0,77° : seuls les plateaux de pads pavaient (archipel
   mesuré à la sonde). Corrigé dans `tools/godot/bake_world_v2_navmesh.gd`.
   **Le bake V1 (`bake_valley_navmesh.gd`, symbole `_make_mesh`) porte le même
   défaut latent** : le navmesh V1 livré ne pave que le quasi-plat et les
   ennemis V1 retombent en pilotage direct sans le dire. Hors périmètre V2.1
   (la V1 ne doit pas bouger) — à consigner dans `docs/KNOWN_ISSUES.md` à la
   prochaine session V1 (relevé aussi par la revue contradictoire, réserve A3).
2. **Les itérations asynchrones de carte de navigation ne se terminent jamais
   en headless `--script`** (id d'itération figé à 1 ; la V1 souffre du même
   mal). Le monde V2 force les itérations synchrones — correct pour une carte
   statique cuite, et cela rend la navigation PROUVABLE.
3. **Les contours de quadrants cuits séparément divergent à leur couture**
   (~1,3 m, `edge_max_error` de Recast) — marge de connexion d'arêtes portée à
   2 m après balayage mesuré (0,25/0,5/1,0 : coupé ; 2,0 : raccordé) ; aucune
   bande élaguée plus étroite que 2 m, donc aucune fausse connexion possible.
4. **Le lit du bras nord (28°) descend naturellement dans le bol du lac** — la
   pente seule n'isolait pas « l'île » ; obstruction d'eau profonde DÉCLARÉE
   (`NavigationObstacle3D` creusée au bake), c'est la règle « on ne patrouille
   pas sous 5 m d'eau » exprimée là où le bake la lit.

## Réserves de la revue contradictoire et leur traitement

- **A1** (le dépôt a bougé pendant la revue — commit d'evidence `5bbe679` créé
  entre deux lectures de l'agent) : reconnu ; contenu evidence-only, régularisé,
  consigné ici. La règle « une seule session à la fois » aurait dû geler
  l'arbre pendant toute la revue.
- **A2** (handoff PROGRESS manquant) : corrigé — entrée V2.1 dans
  `docs/PROGRESS.md`.
- **A3** (défaut latent V1 non consigné dans KNOWN_ISSUES) : hors périmètre
  d'écriture de la phase ; porté ICI et dans `docs/PROGRESS.md` (lu à chaque
  démarrage de session) avec action proposée, non exécutée.
- **A4** (preuves sans manifeste daté/SHA) : corrigé — tous les artefacts
  produits après la revue portent date + commit ; les journaux de contrôles
  négatifs antérieurs sont datés par leur commit d'entrée (`5bbe679`).
- **D1** (seuil de gué = pile la frontière de marchabilité) : assumé — le
  seuil EST la pente de marche contractuelle §8.2 (tan 46° = 1,0355), pas un
  nombre choisi pour passer ; l'échec initial mesurait 1,05 > 1,0355, le
  terrain a dû être réellement corrigé, et le parcours réel du trajet
  principal traverse ce gué à pied (garde-fou permanent).
- **D2** (branche morte dans la légalité de traversée du pont) : corrigé en
  `415a3c4` — rayon du tablier mesuré depuis son centre.
- **D3** (liste canonique des POI en constante de production) : compensé par
  `test_world_v2_layout.gd` qui ancre la liste contre les bâtisseurs V1
  (source indépendante) — constat de la revue elle-même.
- **D4** (grottes comptées, pas épinglées) : corrigé en `415a3c4` — cinq IDs
  épinglés un par un.

## Limites honnêtes / NON VÉRIFIÉ

- **Reproductibilité du bake de navigation : NON VÉRIFIÉ indépendamment** (la
  revue, en lecture seule, ne pouvait pas re-cuire) — vérifiée par l'ordre des
  commits seulement. À rejouer librement : `tools/godot/bake_world_v2_navmesh.gd`.
- Rendu llvmpipe : régression visuelle uniquement ; niveaux 6-7 impossibles ici.
- `shortcut.hidden_passage` : l'entrée demande de l'ESCALADE — le pilote de
  traversal ne grimpe pas ; preuve physique reportée à la phase qui outillera
  un pilote grimpeur. `village_ford` : traversé à pied (route de la rivière) ;
  `citadel_door_return` : porte V1 conservée ; `gorge_arc_step` : mécanique
  Arc Step (phase ultérieure) — extrémités au sol vérifiées.
- `wind_gorge` est porté par une crête-col, pas une entaille — la « gorge »
  sculptée appartient à l'habillage.
- Contrôles manuels §21.4 : impossibles dans ce conteneur — `EN ATTENTE` via
  `docs/MANUAL_VALIDATION.md`.

## Revue contradictoire

**PASS** (contexte frais, l'agent a REJOUÉ lui-même les 33 tests et vérifié la
V1 byte-pour-byte) — réserves A1-A4/D1-D4 toutes non bloquantes, traitées
ci-dessus. Détail : `revue_contradictoire.md`. La revue a examiné l'état
`5bbe679`→`415a3c4` ; le correctif d'enroulement (`487f9d6`) lui est
POSTÉRIEUR — trouvé par l'inspection de captures qu'elle n'avait pas à faire,
re-validé par la suite complète sur l'état final.
