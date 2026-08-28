# KNOWN ISSUES

Sévérités (§21.10) : `S0` corruption/perte de données · `S1` crash, softlock,
progression impossible · `S2` système majeur incorrect, caméra injouable, chute
majeure de performance · `S3` défaut visible ou contournable · `S4` polish.

Aucun `S0`/`S1` ouvert n'est admis pour un build candidat.

---

## ISS-051 — Deux instruments de mesure d'épaisseur étaient biaisés, et l'un est le mien · `S3` · PARTIEL

- **Vu** : 2026-08-16, en confrontant les instruments à une réponse connue
  analytiquement (`tools/cave_collar_calibration.py` : tube de rayon `r` dans un
  cylindre de rayon `R`, collerette exactement `R − r`).
- **`cave_collar.py` méthode B sous-estimait d'exactement une maille de raster.**
  Biais / pas = −1,00 à quatre pas différents, et invariant quand l'épaisseur
  passe de 0,30 à 1,20 m : le biais suit le pas et ignore la grandeur mesurée,
  signature de discrétisation. **CORRIGÉ** (`+ pas`), biais 0,0000 sur huit
  formes. Vérification qui ne dépend d'aucune reprise : 0,5657 mesuré avant la
  correction, au pas de 0,05, plus 0,05, donne 0,6157 — la valeur publiée après.
- **La calibration a sorti un défaut de plus** : la coupe classait le plan par
  UNE seule rangée de rayons le long de +X. Un rayon rasant perd une
  intersection et la parité de toute la fin de rangée s'inverse. Sur le cylindre,
  18 289 cases creuses étaient déclarées « air libre » et l'ouverture valait
  **zéro case** — sur une forme dont l'ouverture est un disque parfait. Vote sur
  quatre parités désormais.
- **`plot_cave_section.py` SUR-ÉVALUE, et ce n'est pas corrigé.** Biais jusqu'à
  **+0,0897 m**, croissant quand le rayon de la galerie diminue (0,8 m → +0,090 ;
  2,0 m → 0,000). Signature d'une origine de rayon hors de l'axe du cercle : le
  rayon parcourt une corde, pas un rayon. Au porche (`hw` 1,70–1,90) le biais
  attendu est de +0,00 à +0,03 m.
- **Ce qui reste valide** dans les lectures de cet outil : les COMPTES (rayons
  sans aucune roche) et la STRUCTURE des blocs (`ROCHE 0,20 · vide 1,10 ·
  ROCHE 3,84`) ne dépendent pas de l'échelle. Seuls les chiffres absolus
  d'épaisseur sont à corriger vers le bas.
- **Enseignement, et il vaut plus que les deux correctifs** : deux instruments
  biaisés en sens contraires peuvent converger et donner l'illusion d'une preuve.
  Ma coupe lisait 0,10 m là où le B corrigé lit 0,1000 m ; j'ai cité cette
  convergence comme un argument, et la calibration montre qu'elle était fragile.
  **Une convergence entre instruments non calibrés n'est pas une validation.**
- **Reste ouvert** : le `controle_epaisseur` du générateur et la sphère inscrite
  de `probe_cave_collerette.py` ne sont pas calibrés. Le cylindre existe et prend
  une minute.

## ISS-052 — Le contrôle d'appuis de `world_v2_places` compare la hauteur du terrain à elle-même · `S2` · OUVERT

- **Vu** : 2026-08-16, par lecture de code pendant l'intégration R2a-3.5.2.
  Aucune exécution Godot — la chaîne est établie maillon par maillon.
- **La chaîne fermée** :
  - `waterfall_cave_place.gd` déclare l'appui à
    `declare_support(Vector3(x, ground_local_y(x, z), z))` ;
  - `world_v2_place.gd` : `ground_local_y()` rend
    `_ground.call(world.x, world.z) - global_position.y` ;
  - `world_v2_places_builder.gd:73` injecte `_ground` par
    `place.call("bind_terrain", Callable(_heightmap, "height_at"))` ;
  - `tests/world_v2/test_world_v2_places_contract.gd`,
    `test_les_fondations_epousent_le_terrain_gele` (a), compare
    `absf(world_point.y - height_at(x, z))` à `SUPPORT_TOLERANCE_M = 0,65`.
  - le lacet de 45° est porté par `ouvrage`, **pas** par le nœud du lieu :
    `to_global` est une translation pure et `y` est préservé exactement.
- **Conséquence** : `_ground` **est** le `height_at` que le test interroge. L'écart
  vaut **0 par construction**. **Le contrôle ne peut pas échouer.**
- **Le code le dit déjà** : « leur hauteur est lue sur le terrain gelé, donc
  l'écart au sol est nul par construction ». La phrase était là ; personne n'en
  avait tiré que l'assertion correspondante était vide.
- **Anti-motif nommé** : `PROMPT4_METHOD` §2 — « la comparaison d'une constante
  avec elle-même », « toute assertion qui ne rougirait pas réellement en cas de
  régression ».
- **Portée au-delà de la grotte** : `stone_bridge_place.gd:237` construit ses
  appuis avec le même `ground_local_y`, donc bénéficie du même acquittement
  automatique. **Le pont est un golden master validé.**
- **Ce que le « 8/8 » atteste réellement** : chaque lieu déclare des appuis non
  vides, s'instancie seul, et n'est ni flottant ni enterré (partie (b), sur
  l'AABB visuelle du lieu entier, qui ne regarde **aucun** appui). Il n'atteste
  **rien** de l'appartenance d'un appui au massif. **Ne pas le citer comme preuve
  sur ce point.**
- **Correctif possible, NON APPLIQUÉ dans cette passe** : déclarer l'appui à `y`
  du **modèle** (0,0) au lieu de la hauteur du terrain, ce qui rendrait la
  comparaison signifiante ; ou ajouter un contrôle d'appartenance par colonne
  verticale. Corriger un contrôle vide peut faire rougir un golden master
  validé — c'est une décision de lead, pas d'intégrateur, et sûrement pas au
  milieu d'une passe géométrique.
- **Test de régression** : à écrire avec le correctif — un appui déplacé de 2 m
  doit rougir.

## ISS-054 — La coque de COLLISION porte 62 auto-intersections à 0,457 m, et aucun contrôle ne l'a jamais regardée · `S2` · OUVERT

- **Build** : enveloppe R2a-3.5.2, mesuré sur `cc3596c5` et `c184c8dc`, reproduit
  par l'intégrateur (`RC=0` sur les trois géométries).
- **Observé**, sur `COL_WaterfallCave` :

  | géométrie | paires | enfoncement max | où, en `ay` réel |
  |---|---:|---:|---|
  | R2a-3.4 **livrée** | 7 | **0,020 m** | `+8,37` à `+9,11` |
  | `cc3596c5` | **62** | **0,457 m** | 32 au porche, 28 vers `+2,9…3,1` |
  | `c184c8dc` | **62** | **0,457 m** | identique, ligne pour ligne |

- **Gravité** : 0,457 m d'enfoncement, soit **23 fois** `REPLI_LIVRABLE_MAX_M`,
  sur la géométrie qui **arrête réellement le joueur**. Le maillage visuel, lui,
  reste 33 fois sous le seuil.
- **Attribution certaine** : `cc3596c5` et `c184c8dc` sont identiques ligne pour
  ligne, donc la régression vient **entièrement de l'enveloppe R2a-3.5.2**. Ni la
  passe R2a-3.5.5 ni la calotte nord ne l'ont fabriquée.
- **Cause la plus probable, NON PROUVÉE** : un loft dont la **section change trop
  vite**, pas un loft qui vire. L'hypothèse du coude de 42° est **réfutée** — il
  porte 2 paires sur 62, soit 3 %. Les pénétrations sont aux **deux extrémités**
  du tube, dans les trois géométries, y compris R2a-3.4 en beaucoup plus bénin.
- **Ce qui rend le défaut durable** : ni l'ancien `controle_repli()` ni le
  nouveau `controle_penetration_exacte()` n'est appelé sur `COL_WaterfallCave`.
  Elles étaient déjà là quand R2a-3.5.4 a déclaré la percée fermée et le portail
  conforme. **Personne ne regardait cette coque.**
- **Non corrigé** : hors périmètre de R2a-3.5.5, et `COL_MARGE_LAT` /
  `COL_MARGE_CLE` ne doivent pas bouger sans décision.

## ISS-055 — Le contrôle d'auto-intersection testait des PLANS, pas des triangles bornés · `S2` · CORRIGÉ (2026-08-17)

- **Observé** : `_straddle_points()` publiait **0** pénétration là où un juge
  exact — prédicats en `Fraction`, aucune tolérance — en trouve **6** sur le
  candidat et **10 sur R2a-3.4 livrée et validée**. Il ratait des pénétrations et
  en inventait : « 0 auto-intersection » n'a jamais été vrai sur aucune géométrie.
- **Mode de panne** : celui d'ISS-018 — un test vert qui ne rougirait pas.
- **Corrigé** par `controle_penetration_exacte()` : prédicats exacts, **aucune
  tolérance** (un prédicat exact n'en a pas besoin), seuil `REPLI_LIVRABLE_MAX_M`
  **inchangé**, les deux compteurs imprimés côte à côte dont l'ancien marqué « il
  SOUS-COMPTE ». Sept cas de garde, zéro échec : voit une pénétration de **1 µm**,
  ne compte **aucun** des quatre contacts (arête, sommet, tangence, coplanaires).
- **Angle mort résiduel, mesuré, NON RÉSOLU** : dans la chaîne le contrôle publie
  **4** là où le juge trouve **6** sur le GLB, parce que la triangulation interne
  `bmesh BEAUTY` et celle de l'exportateur divergent sur **2 178 triangles sur
  20 072, soit 10,9 %**. **Le « 4 » du générateur est un MINORANT du « 6 » réel.**
- **Ce que la mesure a corrigé dans mon propre argumentaire** : « 6 contre 10 »
  est vrai sur le compte et **faux sur la sévérité**. Les 10 de R2a-3.4 ont un
  enfoncement **sous le demi-micron** — des contacts tangents ; celles du candidat
  sont mille fois plus profondes, avec des coutures 4,5 fois plus longues.

## ISS-053 — Un appui déclaré de la grotte est à l'air libre, 0,92 m hors du massif · `S3` · OUVERT

- **Build** : base R2a-3.5.2 (`c79341e`), mesuré sur le candidat `cc3596c5`.
- **Observé** : le premier des huit `APPUIS_MODELE`, `(8.14 ; −6.03)`, tombe
  **+0,92 m en dehors** de la coupe du massif au plan `y = 0` (484 segments, sans
  échantillonnage). Les sept autres sont dedans, de 0,09 à 0,67 m.
- **L'hypothèse du surplomb est RÉFUTÉE**, et nettement : la colonne verticale de
  ce point porte **0 impact à toute hauteur** ; les sept autres appuis neufs
  portent **tous exactement 2 impacts**. Sommet de maillage le plus proche en
  projection : 0,74 m. Il n'est ni sous la visière, ni sous l'orteil, ni sous le
  porche évasé.
- **Gravité bornée par la mesure** : `_support_points` n'est lu que par
  `set_meta`, par le filet de test, par `tools/godot/probe_place_metrics.gd` et
  par `riverside_village_place.gd` pour ses propres appuis. **Aucun effet de
  gameplay, aucune collision, aucun navmesh, aucun rendu** — vérifié par
  recherche exhaustive de `get_meta(&"support_points")`. C'est un défaut de
  **véracité** : une déclaration de contact qui ne touche rien.
- **Pourquoi ce n'est pas corrigé ici** : la passe R2a-3.5.2 a un périmètre borné
  à la collerette, et les repères de gameplay n'entrent au tronc qu'en tant que
  base héritée. Déplacer un appui serait une modification de contenu hors
  mandat.
- **Lien** : invisible au filet à cause d'ISS-052. Les deux se corrigent
  ensemble ou pas du tout.
- **Test de régression** : à écrire avec le correctif d'ISS-052.

## ISS-048 — La semelle de la grotte ne dérive plus de la cavité, elle la rencontre · `S3` · OUVERT

- **Build** : géométrie R2a-3.5.2, GLB `8bc8b9f9eb9e…`.
- **Observé** : `SEMELLE_PART_LAT = 1.05` fait porter la semelle sur ±1,05·hw
  autour de l'axe. Depuis la section asymétrique, le vide atteint 1,34 à
  1,69·hw du côté large, plus la poussée de l'alcôve — déficit mesuré
  **−2,50 m** à la station 6.
- **Pourquoi ce n'est PAS un défaut visible** : le plancher existe bel et bien,
  et massivement. Cinq instruments concordent, dont un qui ignore les stations
  (`tools/audit_cave_floor_columns.py`, evidence `r2a352_oracle_plancher/`) :
  **2,89 m de roche sous les 33 colonnes habitables des stations terminales.**
  Le sol est porté par l'enveloppe générale, pas par la semelle.
- **Pourquoi c'est quand même une dette** : la docstring de `rochers_semelle()`
  promet une propriété **dérivée** — « la semelle suit la cavité » — alors
  qu'elle n'est plus que **rencontrée**. Le jour où l'enveloppe s'amincira à cet
  endroit, plus rien ne garantira le plancher, et le commentaire dira le
  contraire du code.
- **Correctif attendu** : faire dépendre `SEMELLE_PART_LAT` de la demi-largeur
  RÉELLE du côté considéré (`CAVITE_ASYM` × `facteur_lateral`), ou bien réécrire
  la docstring pour dire ce qui est vrai. Ne pas toucher à la géométrie tant que
  le contrôle est vert : ce serait modifier une forme validée sur un défaut
  théorique.
- **Test de régression** : à écrire avec le correctif — un profil dont
  l'enveloppe est amincie sous la station 6 doit rougir.

## ISS-049 — Le même défaut d'échantillonnage est réapparu SEPT fois · `S2` · OUVERT

- **Build** : outils de la passe R2a-3.5.x.
- **Le défaut** : un contrôle place ses points à `ax + f·hw`, c'est-à-dire
  **symétriquement et le long de X**, sur une cavité devenue asymétrique et dont
  l'axe tourne. Il mesure alors une station pour une autre.
- **Occurrences connues** : six corrigées lors de R2a-3.5.1 — dont
  `points_interieurs`, qui portait le commentaire « SIXIÈME ET DERNIER ENDROIT
  DE LA MÊME FAUTE ». Il n'était pas le dernier : `carte_du_plancher()` portait
  la septième.
- **Ce que la septième a coûté** : elle a produit **9 lignes fautives sur 33**,
  écart maximal 0,45 m, et c'est elle qui a fait inscrire au cahier des charges
  de R2a-3.5.2 un « défaut de plancher des stations 6 à 8 » **qui n'existe pas
  dans la roche**. Le même contrôle, échantillonné le long de la normale ×
  `facteur_lateral` : **0 faute sur 33**, écart maximal 0,03 m.
- **Pourquoi le commentaire a menti** : il affirmait une exhaustivité que
  personne n'avait vérifiée. Un commentaire qui dit « c'est le dernier » sans
  test qui l'établisse est une promesse, pas un constat.
- **Filet à construire** : un contrôle qui BALAIE les outils à la recherche du
  motif `ax + f * hw` (et variantes) et rougit sur toute occurrence non annotée.
  Tant qu'il n'existe pas, ce ticket reste OUVERT même si les sept occurrences
  connues sont corrigées.
- **Test de régression** : fixture adverse à profil fortement tourné, sur
  laquelle l'échantillonnage le long de X rougit et l'échantillonnage le long de
  la normale passe.

## ISS-050 — Des vides de 0,18 à 1,74 m dorment dans le massif entre la galerie et la paroi · `S4` · OUVERT

- **Build** : géométrie R2a-3.5.2 (base `8bc8b9f9…` et livrable collerette
  `4dd1642f…` — identique dans les deux, donc antérieur à la visière).
- **Mesuré** par `tools/plot_cave_section.py`, qui publie le PREMIER bloc de
  roche là où `controle_epaisseur` publie la SOMME. Sur 24 rayons à `u >= 1`,
  le premier bloc tombe sous 0,80 m, minimum 0,12 m. En regardant ce que le
  rayon traverse vraiment :

  ```
  u 4.75 az 190  ->  ROCHE 0.20   vide 1.10   ROCHE 3.84
  u 4.75 az 180  ->  ROCHE 0.45   vide 1.74   ROCHE 3.21
  u 5.25 az 180  ->  ROCHE 0.58   vide 0.18   ROCHE 0.35  vide 0.91  ROCHE 3.30
  ```

- **Ce n'est PAS un défaut de paroi.** Le bloc mince est une nervure intérieure
  entre la galerie et la poche salle/alcôve ; la paroi réelle vers l'extérieur
  fait 3,2 à 3,9 m. `controle_epaisseur` a raison, et sa docstring avait nommé
  le cas d'avance. Le contrat `EPAISSEUR_MIN_M = 0,80` est tenu.
- **Ce qui reste vrai** : le massif n'est pas plein à cet endroit. Invisible au
  joueur, sans effet sur le gabarit ni sur l'étanchéité (0 percée confirmée),
  mais c'est de la matière fantôme dans le budget de triangles et une surprise
  potentielle pour toute mesure future qui supposerait un solide plein.
- **Limite d'instrument, nommée** : `premiere` ne vaut « la paroi » que s'il
  n'existe aucune structure entre l'axe et le dehors. Sur une cavité à poche
  latérale, cette garantie n'existe pas. Écrit dans l'en-tête de l'outil.
- **Test de régression** : aucun — ce ticket est une observation, pas un
  contrat. Il devient bloquant seulement si un vide interne débouche.

## ISS-045 — Le terrain jouable est plat : deux dalles portent 80 % du monde · `S3` · OUVERT

- **Build** : `6a996a5` et suivants (défaut ANTÉRIEUR, relevé par l'audit du 2026-08-11).
- **Étapes** : sondage physique 32×32, un rayon vertical tous les 16 m
  (`outils_audit/probe_valley_grid.gd` du pack d'audit).
- **Observé** : **991 des 1 024 points ont une pente < 5°** et **815 tombent sur
  `PlainNorth` ou `PlainSouth`** — deux dalles de 512 × 240 et 512 × 260 posées
  à y = 2. Reliefs et landmarks sont POSÉS dessus.
- **Impact** : la vallée n'a ni creux, ni bosse, ni chemin naturel ; les trois
  plans de §1.3 doivent être portés par la couleur seule, faute de volumes.
- **Pourquoi ce n'est pas corrigé** : déplacer le sol déplacerait ~4 000 objets
  posés à des cotes absolues par une dizaine de scripts. C'est le changement le
  plus risqué du dépôt et il n'a pas de filet.
- **Filet à construire AVANT d'y toucher** : généraliser
  `test_opening_dressing_rests_on_ground.gd` à toutes les zones, pour qu'un
  objet enterré ou suspendu rougisse au lieu de se découvrir en capture.
- **Test de régression** : à écrire avec le correctif.
- **Atténué (passe 3, 2026-08-12)** : dix buttes convexes MARCHABLES ajoutées
  en flanc de route (`_build_plain_relief`), navmesh re-cuites, trois
  contrats testés (`test_plains_carry_flanking_relief.gd`) — dont un filet
  anti-enterrement qui a attrapé trois vraies fautes de placement avant
  livraison. Le remodelage des dalles elles-mêmes reste OUVERT.

## ISS-046 — Les chemins sont des bandes posées, pas des chemins · `S3` · CORRIGÉ (2026-08-12)

- **Build** : `6a996a5` et suivants ; corrigé sur la branche de la passe 3.
- **Observé (historique)** : `PathStrip00` occupait **22,2 %** du cadre
  d'ouverture ; les dix segments de `_build_paths()` étaient des `PlaneMesh`
  sans épaisseur flottant à `PATH_CLEARANCE` au-dessus du sol.
- **Corrigé (passe 3)** : chaque pièce, épaulement et langue d'herbe est un
  POLYGONE IRRÉGULIER (`_ground_patch_mesh`, 7-9 sommets de bord) ; étagement
  déterministe anti-couture de 4 mm entre pièces voisines. Test durci :
  `test_paths_belong_to_the_ground.gd` (rouge d'abord : 110 échecs de forme).
- **Piège rencontré et consigné** : la face avant Godot est enroulée en
  HORAIRE — le premier éventail (anti-horaire) rendait le chemin INVISIBLE
  pendant que les tests restaient verts (la leçon ISS-018). C'est la
  recapture de la caméra 5 qui l'a montré.
- **Reste ouvert** : la clarté en plein soleil dépend de la mesure §1.5 par
  caméra ; le verdict d'image appartient à la revue indépendante.

## ISS-047 — La citadelle reste un empilement de boîtes alignées sur les axes · `S3` · CORRIGÉ (2026-08-12, verdict d'image en attente)

- **Build** : `6a996a5` et suivants ; corrigé sur la branche de la passe 3.
- **Observé (historique)** : `CitadelProxy` était fait de `_box_in` axés sur
  le monde — Keep, épaules, tours, spire et contreforts en boîtes nues.
- **Corrigé (passe 3)** : habillage taluté SANS collision — piliers d'angle
  battus sur le Keep, coques d'épaules, manchons de tours, spire et
  contreforts en troncs de pyramide. Les porteurs de collision gardent leurs
  cotes testées et ne pivotent jamais (PT-D1-09). Test rouge d'abord :
  `test_citadel_masses_wear_battered_cladding.gd`.
- **Reste ouvert** : le verdict d'image appartient à la revue indépendante ;
  le Keep et les tours restent des boîtes de collision SOUS l'habillage.

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

## ISS-064 — un flux audio survit au démontage du monde · `S4` · OUVERT

Trouvé le 2026-08-20 en instrumentant ISS-059, pas cherché pour lui-même.

Après le correctif des caches statiques, `WorldV2.tscn` montée puis démontée
laisse au rapport de sortie, en plus du cache de scripts du moteur :

```
  1  AudioStreamWAV            res://assets/audio/sfx/land_soft.wav
  1  AudioStreamPlaybackWAV
```

Journal : `evidence/world_v2/v2_3_r2b3_1/iss059/apres_correctif/worldv2_verbose.log`.

`land_soft.wav` est le son de réception du joueur. Il apparaît parce que le
personnage instancié dans la scène tombe au sol au spawn. Un `AudioStreamPlaybackWAV`
vivant à la sortie veut dire qu'une lecture n'a jamais été arrêtée — le nœud a
probablement été libéré pendant qu'elle jouait.

**Un objet, aucune classe de RID.** Ce n'est pas la fuite d'ISS-059 et ce n'est
pas ce que la directive R2B.3.1 demandait de corriger ; l'élargir au chemin audio
en pleine passe de fuite mémoire aurait été exactement l'élargissement que la
méthode interdit.

**Ce qui n'est PAS su** : d'où vient la lecture. Trois candidats non départagés —
le joueur lui-même, un pool d'`AudioManager`, ou un `AudioStreamPlayer3D` libéré
en cours de lecture. Aucune reproduction hors de `WorldV2` n'a été tentée.

**Précédent de la même famille** : `42ee1db` (2026-08-09), où la cause d'une
signature de fuite était l'ambiance audio.

**Propriétaire** : prochaine session de dette technique.

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

**Occurrence 2026-08-06** (passe art, branche dédiée) : deux tests
save-roundtrip rouges UNE fois dans une suite lancée pendant la fenêtre
de turbulence des redémarrages conteneur
(`test_boss_arena::test_the_arena_restores_the_antechamber_checkpoint`,
`test_dungeon_antisoftlock::test_leaving_and_coming_back_keeps_what_was_solved`).
Classement : intermittence environnementale, PAS un bug — verts ×2 en
isolation ET dans la suite intégrale suivante (**721/721**, arbre
`295fa06`). Analyse : la voie testée est entièrement synchrone
(écriture atomique + relecture, restauration dans `_ready`, deferreds
déterministes par frame) — aucune fenêtre d'attente à blinder n'existe.
Conduite tenue : ne PAS ajouter d'attentes cosmétiques ; relancer sur
machine calme avant de croire un rouge de cette classe.

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

## ISS-032 — Route crête → plaine nord incomplète (S3, ouvert)

`test_valley_world.gd::test_the_route_from_ridge_to_north_plain_is_walkable`
échoue : 9 jalons atteints sur 11 en 1907 ticks, et le marcheur descend à
y = −0,50. **Antérieur à la passe d'habillage** : vérifié par exécution sur
le commit `c9f17fb` (worktree séparé), les chiffres sont IDENTIQUES au tick
près. Introduit par les travaux de jouabilité V5 (`371fd81`) ou antérieurs.

## ISS-033 — `dev_mode.gd` lit le clavier directement (S3, CLOS le 2026-08-06)

**Clos** : `test_input_layer_isolation::test_no_gameplay_script_reads_the_keyboard`
passe desormais avec 696 assertions, verifie par le controleur du chantier
d'assemblage. Corrige entre-temps par la session qui avait introduit le fichier.

`test_input_layer_isolation.gd::test_no_gameplay_script_reads_the_keyboard`
échoue : `scripts/tools/dev_mode.gd` contient `InputEventKey` et `KEY_`,
ce que D-013 interdit au gameplay. Le fichier a été introduit par le commit
`c9f17fb` (« Mode développement »), d'une autre session travaillant sur la
même branche. Correctif attendu : passer par `InputIntent`, ou exclure
explicitement les outils de développement du contrôle si la règle ne les
vise pas — trancher, ne pas laisser rouge.


## ISS-034 — Le kit ne contient aucun pignon de la famille bardeaux (S3, ouvert)

Verifie exhaustivement dans `assets/environment/village` et
`assets/environment/dungeon` : les seules pieces de fermeture de rampant sont
`Roof_Front_Brick4/6/8`, taillees pour la pente des tuiles rondes.
`Roof_Front_Brick6` monte de 4,38 m sur 6,69 m de base ; la pente de bardeaux
de la cabane des bucherons monte de 2,26 m sur 6,00 m — presque le double.
Les deux abouts du toit de la cabane restent donc des triangles ouverts.
**Aucun faux pignon n'a ete bricole** : la limite est ecrite dans le code
au-dessus de la toiture. Correctif possible : modeliser un pignon a la bonne
pente (script Blender), ou passer la cabane aux tuiles rondes.

## ISS-035 — Pas japonais de la rivière suspendus au-dessus du lit (S3, **CORRIGÉ 2026-08-07**)

**Correction, et pourquoi le correctif attendu ci-dessous était faux.** Le
correctif proposé — « dériver la cote de ces pierres du lit » — les aurait
ENTERRÉES. La géométrie, relue dans le code et non estimée : lit à −1,50,
surface de l'eau à −0,55 (ruban de 0,30 m centré à −0,70). Une dalle de 0,16 m
posée sur le lit a son sommet à −1,34, soit **0,79 m sous l'eau** : invisible.

Mesure hors moteur (`tools/gltf_inspect.py`) : les `RockPath_*` sont des dalles
de 0,11 à 0,18 m d'épaisseur. Aucune n'atteint les **0,95 m** qu'il faut pour
aller du lit à la surface. Ce ne pouvait donc pas être des dalles — le défaut
n'était pas une cote, c'était le choix du modèle.

Décision du propriétaire : de vrais rochers posés au fond. Les quatre
placements sont désormais des `Rock_Medium_*` (1,90 à 2,32 m natifs), base à
−1,550 (5 cm dans le lit : un bloc en rivière y est pris, il n'y est pas posé
en équilibre), sommets émergeant de 0,14 / 0,27 / 0,40 / 0,42 m — échelonnés à
dessein, une rangée régulière se voit (§7.4). **Collision ajoutée**, absente
des dalles : on traverse sans dommage une pierre de 16 cm, pas un bloc de 1,4 m.

Garde-fou : `tests/integration/test_river_stones_reach_the_bed.gd`, deux bras.
Dans le monde, chaque rocher doit satisfaire DEUX exigences conjointes — la
base atteint le lit ET le sommet émerge ; un test qui ne vérifierait que la
première validerait une rivière vide. À la source, aucune dalle du kit ne peut
satisfaire les deux, ce qui verrouille le raisonnement plutôt que le résultat.

Décisivité prouvée : sans le correctif, le test rougit sur **2,04 / 1,99 /
2,04 / 1,99 m** — exactement les valeurs mesurées ci-dessous. Avec, il est vert.

---

### Relevé d'origine (conservé)

Mesure faite pendant la passe « arcade / caisse claire / arche » avec
`tools/godot/probe_world_boxes.gd`, sur la vallée réellement montée :

    DressZoneRiver/RockPath_Round_Wide_4    y 0,54..0,70  sol -1,50  → +2,04 m
    DressZoneRiver/RockPath_Round_Thin_5    y 0,49..0,62  sol -1,50  → +1,99 m
    DressZoneRiver/RockPath_Round_Small_1_7 y 0,49..0,66  sol -1,50  → +1,99 m

Le fond du lit (dalle `Riverbed` de `valley_terrain.gd`) est à y = −1,50 ; ces
pierres sont posées à y ≈ 0,5, soit deux mètres au-dessus de lui. Elles ne sont
donc pas des pas japonais : ce sont des galets qui flottent dans le vide, juste
sous la nappe d'eau (y −0,85..−0,55) qui les cache par le dessus mais pas de
biais. Leur cote vient vraisemblablement d'une constante de plaine (y = 2)
diminuée d'une lame d'eau, et non du lit.

Défaut CONSTATÉ et MESURÉ, non corrigé : le fichier fautif
(`valley_terrain.gd`, dressage de zone F) n'était pas dans le périmètre des
trois corrections demandées, et le déplacer touche le tracé du gué. Correctif
attendu : dériver la cote de ces pierres du lit (−1,50) et non de la plaine,
comme l'a fait la travée tombée de l'aqueduc.

## ISS-036 — Deux fruits de la crête sans sol sous eux (S3, ouvert, CANDIDAT)

Trouvé par le **premier balayage complet** de la vallée
(`probe_world_boxes.gd --sweep --float=0.3`), 2026-08-07 :

    Ingredients/valley_ingredient_crest_fruit_01   y 24,00..24,36  sol 2,00  → +22,00 m
    Ingredients/valley_ingredient_crest_fruit_02   y 24,00..24,36  sol 2,00  → +22,00 m

Les deux fruits sont posés à y = 24, ce qui est la bonne cote pour la crête de
départ (spawn à `(0, 24, 170)`, MASTER_SPEC §3.3). Le problème n'est pas leur
hauteur : c'est que le rayon vertical **traverse la crête** et ne trouve de sol
qu'à y = 2, la plaine. Il n'y a donc **aucune collision sous eux**.

Deux lectures possibles, non départagées :

1. les fruits sont posés au-delà du bord collidable de la crête — le joueur
   pourrait les voir sans pouvoir les atteindre, ce qui serait un vrai défaut
   de jeu (un ingrédient est fait pour être ramassé) ;
2. la crête porte à cet endroit une géométrie décorative sans collision, et les
   fruits reposent visuellement dessus — auquel cas c'est la collision du
   terrain qui manque, pas le placement du fruit.

`CANDIDAT`, pas `défaut` : la sonde mesure un écart au sol, elle ne sait pas si
la pièce est censée reposer dessus. Prochaine mesure : relancer la sonde en
région resserrée autour de `(0, 170)` et vérifier si la dalle de crête possède
une collision à ces coordonnées.

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

## ISS-037 — Le chemin de la vue North Star capte l'œil avant la citadelle · `S3` · **CORRIGÉ** (2026-08-08, `5290c11`)

- **Build** : `d8dc3bf` (tronc consolidé), `HeroShotLab`, caméra `VistaCamera_Hero01`,
  1280×720, 20 frames, rendu logiciel llvmpipe.
- **Preuve** : `evidence/ab/heroshot_controle/apres.png`, manifeste
  `apres.json` (`repo_dirty: false`).
- **Mesuré, pas jugé à l'œil** — moyenne sur 12×12 px :

  | Zone | Rendu | Saturation |
  |---|---|---:|
  | bande du chemin | `#F78847` (R=248) | **0,71** |
  | herbe adjacente | `#404937` | 0,24 |
  | herbe au loin | `#5B6C4B` | 0,31 |
  | rocher d'encadrement | `#61624E` | 0,20 |

- **Attendu** : §1.5 place « sol et roche moyens » entre **35 et 65 % de valeur**.
  La bande est à ~97 %. Elle est l'objet le plus lumineux ET le plus saturé de
  l'image.
- **Conséquence** : §1.2 exige que le regard aille héros → herbe → camp → pylône
  → rivière → citadelle. La bande capte le regard en premier et le tire vers le
  bas à droite, hors de la citadelle. C'est un défaut de composition, pas de goût.
- **Cause NON ÉTABLIE.** Trois pistes écartées par la mesure :
  - la couleur déclarée est correcte (`COL_EARTH` = `#8A5A36`, conforme §1.4) ;
  - la texture `T_Ground_Earth_Albedo.jpg` est **verte** (sol forestier moussu) —
    elle ne peut pas produire de l'orange, et son nom est trompeur ;
  - la seule couleur HDR du labo (`Color(1.85, 1.52, 1.16)`) porte sur les
    **rochers**, pas sur le chemin.
  Le test décisif reste à faire : masquer `PathCrest`, recapturer, comparer —
  pour confirmer que la bande EST bien ce nœud avant de corriger quoi que ce soit.
- **CAUSE ÉTABLIE** par test décisif : `PathCrest` repeint en bleu pur → la bande
  devient `#2830FF`. C'est bien lui, et un albédo bleu PUR ressortant à B=255
  révèle un **gain lumineux de ≈ 1,8** dans le labo. `COL_EARTH` a un rouge de
  0,541 ; 0,541 × 1,8 = 0,97, soit les 97 % mesurés. `#8A5A36` est une couleur
  **peinte cible**, pas un albédo. Les rochers portaient déjà la correction
  symétrique (teinte HDR, « sinon ils devenaient des trous noirs ») ; le chemin
  ne l'avait jamais reçue.
- **Correction** : albédo × 0,57. Mesuré après, même caméra :
  chemin `#70483C` valeur **44 %**, saturation 0,47 — dans la bande §1.5, et
  toujours distinct de l'herbe (29 %). Preuve : `evidence/iss037/`
  (`repo_dirty: false`, commit `5290c11`).
- **Mes deux premières hypothèses étaient fausses** et sont conservées ici comme
  garde-fou : la texture « terre » est verte, et la sonde de projection que
  j'avais écrite désignait le mauvais nœud (son axe Y est faux).
- **Test de régression à écrire** : une sonde de valeur/saturation sur la capture
  North Star, qui échoue si une surface de sol dépasse la bande 35–65 % de §1.5.
  Ce test manquait — c'est pourquoi le défaut a survécu à quatre itérations
  (v0→v3) et à une évaluation à 58/100.

### Note de méthode

`T_Ground_Earth_Albedo.jpg` montre de la mousse verte. Qu'une texture nommée
« terre » soit un sol forestier est un défaut d'inventaire à part entière, à
traiter par `asset-license-auditor` / le manifeste, indépendamment de ce ticket.

## ISS-038 — La suite n'est pas déterministe : deux passages, deux verdicts · `S2` · **FERMÉ** (2026-08-08)

- **Build** : `86ef23c` (aucun changement de code entre les deux passages).
- **Observé**, deux exécutions complètes de `tools/validate_fast.sh` à quelques
  minutes d'intervalle :

  | Passage | Résultat |
  |---|---|
  | A (`/tmp/valfast_final.log`) | **804 réussis, 0 échoué** |
  | B (`/tmp/valfast_blender.log`) | **802 réussis, 2 échoués** |

- **Les deux tests fautifs passent en isolation**, systématiquement :
  - `test_cooking_ui.gd::test_the_hud_shows_the_active_buff_and_clears_on_expiry`
    — 5 passes isolées, 5 fois vert ;
  - `test_heads_reach_the_real_valley.gd::test_the_hero_in_the_valley_has_a_head`
    — 2 passes isolées, 2 fois vert.
- **Hypothèse écartée par la mesure** : l'installation de Blender entre A et B
  n'a rien importé de nouveau — `source_assets/.gdignore` existe et aucun
  `.blend.import` n'a été créé. Le projet se protégeait déjà.
- **Cause probable, NON ÉTABLIE** : pollution d'état entre tests (autoload,
  sauvegarde, `GameState`, nœud non libéré). Même famille qu'ISS-024, classée
  « environnementale » à l'époque — cette observation suggère que le classement
  était optimiste.
- **Pourquoi c'est `S2` et pas `S3`** : tant que la suite rend deux verdicts
  différents pour le même code, **aucun « vert » ne prouve rien**. Le 804/0
  obtenu au passage A n'est pas une preuve que la suite est saine ; c'est
  peut-être un tirage favorable. Cela affecte tous les gates.

### FERMÉ — 2026-08-08, preuve au repos ET sous contention

**DEUX causes distinctes, et aucune n'était celle annoncée au premier
correctif.** Un seul symptôme — « la suite rend deux verdicts » — recouvrait
deux défauts sans rapport. C'est pourquoi chaque explication unique a échoué.

**Cause A — une course de PHASE contre un throttle** (`test_cooking_ui`). Le
test attendait dix frames de rendu puis affirmait. Mesuré : les frames tournent
à ~145 im/s en headless (139 sous contention), donc dix frames font 0,069 s —
et le texte du HUD est étranglé à `HUD_TEXT_REFRESH = 0,1 s`
(`gameplay_shell.gd:477`). Dix frames tenaient STRUCTURELLEMENT dans une seule
période de rafraîchissement : selon l'endroit du cycle où le test tombait, le
label avait été rafraîchi ou non. Ce n'était pas une course de vitesse, et la
première explication (« 33 ms de marge à 60 im/s ») était fausse.

**Cause B — une pose mesurée pendant l'ATTERRISSAGE** (`test_heads...`). Le
héros apparaît au-dessus du sol, tombe, et joue `Jump_Land`. Le test lisait la
hauteur du crâne pendant l'accroupissement de réception : 1,07 m au lieu de
1,74. Ni pollution d'état, ni contention — les deux pistes poursuivies, et les
quatre hypothèses éliminées à grands frais, portaient toutes à côté.

**Ce qui a livré la cause B n'est aucun raisonnement** : c'est d'avoir fait
imprimer au test le nom de l'animation qu'il voyait. Une ligne, une exécution.

Le premier correctif s'était trompé de mécanisme : il avait allongé la DURÉE du
buff (0,2 s → 5 s) en gardant le compte de frames. Le passage sous contention a
fait échouer la MÊME assertion. Ce n'était donc pas le buff qui expirait, mais
le **label du HUD qui n'avait pas eu le temps de se rafraîchir**.

**Correctifs finaux**, tous bornés en TEMPS DE JEU et non en frames — un compte
de frames n'est ni une durée ni une garantie de rafraîchissement :

- `_label_reaches(needle, budget_s)` attend l'état du label, 1 s = dix périodes
  de rafraîchissement ;
- `_reaches_rest(anim, budget_s)` attend la posture de repos du héros, 4 s ;
- une borne épuisée fait ÉCHOUER le test, elle ne le fait pas pendre.

**Trois assertions incapables d'échouer, trouvées par `test-coverage-auditor` à
contexte frais et corrigées** : une borne de 600 frames (4,13 s) plus courte que
le buff de 5 s qu'elle était censée observer ; un garde-fou de stabilisation
satisfait par une pose figée ET par une tête en mouvement (pas de 0,80 mm sous
une tolérance de 1 mm) ; un seuil `> 1,2` pour une valeur réelle de 1,74. Les
deux seuils concernés ont été RESSERRÉS, jamais assouplis.

**Preuve, commandes exactes** (`tools/validate_fast.sh`, code retour capturé
sans tube) :

| Condition | Résultat | Code |
|---|---|---:|
| Machine au repos | `804 réussis, 0 échoué` — `VERT` | 0 |
| **4 processus saturant les 4 cœurs** | `804 réussis, 0 échoué` — `VERT` | 0 |

Plus, sur les tests ciblés : 3 passages au repos et 3 sous contention, verts ;
puis 1 + 2 après le correctif final.

**Limites de ce qui est prouvé, à ne pas dépasser** :

- prouvé sur CE conteneur, 4 cœurs, rendu logiciel, et sur DEUX passages
  complets — pas sur une population de passages ni sur une autre machine ;
- la contention simulée est du CPU pur ; ni pression mémoire, ni disque lent,
  ni conteneur bridé n'ont été éprouvés ;
- rien ne prouve qu'aucun AUTRE test du dépôt ne compte des frames au lieu
  d'attendre une condition. C'est la prochaine dette à traiter, et elle est
  nommée en fin de ticket.

### Dette laissée par ce ticket

Chercher les autres tests qui attendent `for i in range(N): await ... frame`
puis affirment. Le motif est le même ; seule la marge diffère. Un test qui
attend une CONDITION bornée est correct, un test qui attend un COMPTE est une
panne en sursis.

### Historique de l'enquête — RÉSOLU À MOITIÉ, état intermédiaire du 2026-08-08

**Cause 1 : un test exigeait que la machine soit RAPIDE. Corrigé et prouvé.**

`test_cooking_ui` appliquait un buff de **0,2 s** puis attendait **dix frames de
rendu** avant d'affirmer qu'il remplaçait l'ancien. À 60 im/s, dix frames font
0,167 s : le test tenait à **33 millisecondes** près. Corrigé (durée portée à 5 s
pour l'assertion de remplacement, qui est instantanée ; l'expiration se prouve
séparément avec une attente généreuse). **Il survit désormais au passage complet
le plus lent de la journée** — la preuve est faite sur la machine.

Règle qui en découle, inscrite dans les deux fichiers de test :
*un test ne peut jamais exiger que la machine soit RAPIDE ; seulement qu'assez
de temps ait passé.*

**Cause 2 : `test_heads_reach_the_real_valley` — TOUJOURS OUVERTE.**

Le crâne mesure 1,15 m au lieu de 1,20 dans la suite complète. Quatre
hypothèses ont été **éliminées par l'expérience**, pas par raisonnement :

| Hypothèse | Expérience | Verdict |
|---|---|---|
| Pose non stabilisée (temps) | garde-fou de stabilisation ajouté | **éliminée** — le garde-fou PASSE et la valeur reste 1,15 |
| Pollution par un test précédent | les 39 prédécesseurs réels rejoués comme préfixe | **éliminée** — vert |
| Pollution par une moitié d'entre eux | bissection en deux moitiés | **éliminée** — les deux vertes |
| Contention CPU | test rejoué sous charge des 4 cœurs | **éliminée** — vert |

Ce qui reste, et n'a pas été testé : une **accumulation** sur un passage très
long (le passage fautif a duré près d'une heure, contre quelques minutes pour le
préfixe) — mémoire, ressources non libérées, état moteur après plusieurs
centaines de scènes montées puis démontées.

**Défaut connu du garde-fou que j'ai ajouté** : il attend que la hauteur du
crâne *cesse de bouger*. Or une pose FIGÉE — animation non démarrée, modèle en
position de liaison — est parfaitement stable. Le garde-fou prouve donc
l'immobilité, pas que l'animation a joué. Si la piste « pose de liaison » est
reprise, c'est ce qu'il faut mesurer à la place.

### Piste EXTERNE, arrivée le 2026-08-08

Le `CLAUDE.md` racine de `levy-street/world-of-claudecraft`, projet comparable
(≈ 9 900 commits, suite lourde), documente le phénomène en une ligne :

> « piping `npm test` through `tail` masks its exit code, **and an unbounded run
> flakes heavy suites under core contention** »

Leur portail complet lance donc les tests **avec un nombre de workers borné**.
Autrement dit : chez eux, une suite lourde qui tourne sans bride sur des cœurs
disputés produit des échecs qui n'ont rien à voir avec le code. C'est exactement
notre signature — des tests verts en isolation, rouges dans la suite, et deux
verdicts pour le même code.

Ce conteneur a **4 cœurs**. Godot y monte des scènes complètes, avec physique et
autoloads, test après test. Les deux passages divergents ont eu lieu dans des
conditions de charge différentes (le second suivait immédiatement une
installation `apt` de Blender, donc un cache disque et une charge différents).

**À éprouver en premier**, avant l'hypothèse de pollution d'état :

1. Rejouer la suite complète trois fois **machine au repos**, sans rien d'autre.
   Si les trois sont identiques, la piste « contention » se renforce.
2. Rejouer la suite complète pendant une charge CPU artificielle. Si les échecs
   reviennent ET se déplacent, c'est la contention, pas l'ordre.
3. Chercher les tests sensibles au TEMPS (`await _settle(n)`, budgets en ticks) :
   sous contention, un nombre fixe de frames physiques ne représente plus la
   même durée réelle. `test_cooking_ui` porte une **expiration de buff** et
   `test_heads_reach_the_real_valley` un **placement après stabilisation** — les
   deux sont exactement de cette famille.

Le point 3 est le plus parlant : les deux tests fautifs dépendent d'un délai.

### Piste d'investigation interne, si la précédente ne donne rien

1. Faire tourner la suite avec un ORDRE inversé ou aléatoire semé, et voir si le
   couple de tests fautifs change. Si oui, c'est bien de la pollution d'ordre.
2. Isoler par paires : lancer chaque test fautif juste après chacun de ses
   prédécesseurs probables, pour trouver le pollueur.
3. Vérifier que chaque test qui monte une scène la retire ET remet `GameState`
   à zéro — plusieurs le font déjà via `_close()`, tous ne le font pas.

## ISS-039 — Le chemin est une dalle POSÉE sur l'herbe, pas creusée dedans · `S3` · OUVERT

- **Vu** : `evidence/iss037/apres_correction.png`, recadrage du premier plan.
- **Observé** : `PathCrest` est un `BoxMesh` de 0,06 m d'épaisseur posé à
  `_slope_height(-9.0) + 0.05`. Sa **tranche** est visible au bord proche : le
  chemin flotte de cinq centimètres au-dessus de l'herbe au lieu d'être creusé
  dedans. À hauteur de héros c'est net, et ça trahit la géométrie.
- **Attendu** (§6.2) : « les chemins sont dessinés par compression de l'herbe,
  terre visible, alignement de pierres, interruption des fleurs » — pas par un
  ruban posé sur le sol.
- **Ne pas confondre avec ISS-037**, qui portait sur la COULEUR et est corrigé.
  Celui-ci est de la géométrie.
- **Piste** : soit creuser le sol sous le chemin, soit supprimer l'épaisseur et
  laisser le masque d'herbe faire le travail (§7.4 : les fleurs se raréfient au
  bord du chemin). La seconde évite un trou de collision.

## ISS-040 — Des cubes non habillés traînent dans la prairie · `S3` · OUVERT

- **Vu** : `evidence/iss037/apres_correction.png`, moitié droite du cadre.
- **Observé** : des cubes bleus et blancs d'environ 20 cm, posés sur l'herbe,
  sans matière ni silhouette. À la distance du premier plan ils lisent
  « placeholder », pas « fleur ».
- **Attendu** (§7.1) : les fleurs sont des ombelles, disques ou grappes, en
  groupes de 5 à 12 — jamais des cubes. Le verdict H-4 nommait déjà le défaut :
  « les fleurs-cubes lisaient Minecraft en gros plan ».
- **À vérifier avant correction** : `test_h7_...les_fleurs_sont_rondes` existe et
  passe. Donc soit il ne couvre PAS le labo `HeroShotLab` (seulement la vallée),
  soit ces cubes ne sont pas des fleurs. **Identifier le nœud d'abord** — la
  méthode qui a tranché sur ISS-037 est la bonne : repeindre d'une couleur
  impossible, recapturer, mesurer.

## ISS-041 — Le pied de la colonne de fumée se soulève de 22 cm à chaque balancement · `S4` · OUVERT

- **Vu** : lecture de `scripts/world/camp_smoke.gd`, confirmé par le calcul.
- **Observé** : la compensation de pivot du cisaillement est **juste en X et
  fausse en Y**. Pour ancrer le pied il faut `_base_height - h(1 - cos(lean))` ;
  le code écrit `+`. Mesuré à `SWAY_DEG = 6` et `h = 20` : le pied dérive de
  **+0,219 m**, alors qu'avec le signe corrigé il tient à **0,000 m**. En X la
  dérive est déjà nulle — ce bras-là est bon, ne pas y toucher.
- **Attendu** : le commentaire du fichier l'énonce lui-même — « le PIED reste
  ancré au feu, la tête dérive comme poussée par le vent ». Un pied qui monte et
  descend deux fois par cycle trahit le proxy, exactement ce que l'auteur
  voulait éviter.
- **Ce n'est PAS la flamme détachée** du rapport de jeu du 2026-08-07 (« un cône
  blanc/bleu à ~3 m à droite du foyer, avec sa propre ombre, qui disparaît quand
  on s'approche »). Vérifié : la compensation horizontale est exacte, donc la
  fumée ne dérive pas latéralement. Cette flamme-là reste **non identifiée** et
  demande une capture au camp, pas une lecture de code.
- **Piste** : corriger le signe, avec un test qui échoue d'abord — sonder la
  position mondiale du sommet de base sur un cycle complet.

## ISS-042 — `probe_world_boxes.gd` inverse le signe sur une pièce ENTERRÉE · `S3` · OUVERT

- **Vu** : balayage du 2026-08-10 sur la vallée entière.
- **Observé** : la sonde tire son rayon depuis 40 cm sous la pièce — départ
  documenté et justifié pour les pièces posées. Mais pour une pièce **enterrée**
  ce départ est à l'intérieur du terrain : le rayon en sort sans le voir et
  rapporte le sol d'en dessous. Elle a donc annoncé « `DressZoneCrest` flotte à
  22 m » là où la vérité mesurée était « enterrée de 8 m », et a signalé **le
  joueur lui-même** comme flottant de 22 m alors qu'il se tient debout sur la
  crête.
- **Conséquence** : ses 507 candidates ne se lisent pas comme une liste de
  défauts. Le joueur flottant est le signal qui doit faire douter du relevé.
- **Contourné, pas corrigé** :
  `tests/integration/test_opening_dressing_rests_on_ground.gd` tire de +200 m et
  exclut les corps du décor lui-même ; c'est lui qui a donné les vraies cotes.
- **Piste** : ajouter à la sonde un second tir venu du ciel et rapporter
  l'écart SIGNÉ (enterré / posé / flottant) au lieu d'un seul mot « flotte ».

## ISS-043 — Neuf lignes de `ASSET_MANIFEST.csv` ne sont pas du CSV valide · `S3` · PARTIEL

- **Vu** : 2026-08-15, en mettant à jour la ligne `SM_WaterfallCave` pour
  R2a-3.3.
- **Observé** : un champ contenant des virgules a été écrit **sans guillemets**,
  si bien que `csv.reader` le découpe en plusieurs colonnes et décale tout le
  reste de la ligne. Sur `SM_WaterfallCave`, la colonne `licence` contenait
  ` gate-rock` et la colonne `budget_tris` contenait un nom de matériau. Le
  fichier s'ouvre sans erreur et se lit très bien à l'œil : **rien ne crie le
  défaut**, et une lecture programmatique en tire des valeurs fausses.
- **Mesuré** : 19 colonnes attendues ; neuf lignes en avaient un autre nombre —
  `Male_Peasant`, `AL_RaiderStates`, `Superhero_Male_FullBody`,
  `SK_StormGuardian`, `AwningTent`, `ui_back`, `ui_error`, `ui_open`,
  `SM_WaterfallCave`.
- **Corrigé** : `SM_WaterfallCave` seule, parce qu'elle relevait du jalon en
  cours. **Les huit autres sont laissées telles quelles** : elles appartiennent
  à des lots gelés, et les toucher serait une propagation hors périmètre.
- **Piste** : un contrôle de forme dans `validate_fast.sh` — compter les
  colonnes de chaque ligne et échouer sur l'écart. Il rougirait aujourd'hui sur
  huit lignes, ce qui est le comportement correct : la dette est réelle.

## ISS-044 — Le filet de praticabilité de la grotte ne regarde jamais sous ses pieds · `S2` · OUVERT

- **Vu** : 2026-08-16, par la sonde `tools/probe_cave_openings.py` de la passe
  R2a-3.4.
- **Observé** : `test_la_grotte_a_un_seuil_et_un_interieur_praticables` est resté
  **VERT** sur une galerie dont le plancher est absent sur 6,5 m. Il marche du
  seuil vers l'intérieur et exige 1,75 m de hauteur libre tous les 0,40 m — il
  vérifie donc ce qu'il y a **au-dessus de la tête**, jamais ce qu'il y a sous
  les pieds.
- **Le même angle mort existait dans le générateur**, et c'est ce qui rend le
  cas instructif : `controle_epaisseur` exclut les rayons descendants en
  justifiant par écrit que « le plancher est garanti autrement, par
  `controle_aucun_jour` » ; or `controle_aucun_jour` ne tire que
  `Vector((0, 0, 1))`, vers le haut. La justification renvoyait à un contrôle
  qui ne faisait pas ce qu'on lui prêtait. **Une circularité entre deux
  contrôles se lit comme une couverture double ; c'est une couverture nulle.**
- **Conséquence mesurée** : le sol visible de la galerie était le sommet de
  l'assise enterrée, 0,38 à 0,53 m sous le profil, et les touffes d'herbe du
  terrain gelé (0,30 m) montaient 0,24 m au-dessus de ce faux sol — visibles à
  l'écran depuis le seuil.
- **Aggravant, et c'est le vrai enseignement** : le générateur **imprimait déjà
  la mesure du défaut** le jour de la livraison. `TRANCHE3.md` publie
  `sol : -0,416` là où le profil attend `-0,040`. La ligne était illisible
  parce qu'elle n'imprime que la valeur mesurée, sans l'attendu à côté.
  **Une télémétrie qui imprime une mesure sans son attendu n'est pas un
  contrôle.**
- **Couvert désormais** par `tests/unit/test_grotte_sans_jour.gd` et
  `tools/probe_cave_openings.py` (rayons descendants, stations 0 à 8 comprises,
  sphère complète). Le filet existant n'est **pas** corrigé : il teste la
  hauteur libre, ce qui reste son objet légitime.
- **Troisième couche, 2026-08-16** : `tools/audit_cave_floor_columns.py`, qui
  répond à la même question **sans connaître les stations** — ni `CAVITE_ASYM`,
  ni `facteur_lateral`, ni `u`. Il balaie des colonnes verticales et lit
  l'alternance roche/vide par parité d'impacts. Il existe parce que les trois
  contrôles précédents partagent tous le même placement de points, et qu'une
  faute dans ce placement les aveugle ENSEMBLE — c'est exactement ce qui vient
  d'arriver (voir ISS-049). Contrôle négatif intégré (`--saboter`) : retirer le
  plancher fait rougir l'oracle sur le même maillage ; retirer seulement le
  sous-sol ne le fait pas.
- **Piste** : ajouter au filet de praticabilité un contrôle de sol sous chaque
  pas, et faire imprimer à `hauteur_du_sol` la valeur attendue à côté de la
  valeur mesurée, avec l'écart. Les deux sont des changements d'une ligne dont
  l'absence a coûté une livraison.

---

## ISS-045 — L'épreuve 5 mesurait un maillage d'un AUTRE worktree, par chemin absolu · `S2` · CORRIGÉ

- **Vu** : 2026-08-16, passe R2a-3.5.3, agent B (épreuves adverses), en lisant
  `tools/probe_cave_adversarial.py` avant de reconstruire l'épreuve 5.
- **Observé** : la constante `MAILLAGE_COLLERETTE` valait le chemin **absolu**
  `/home/user/zelda-r2a352/b_collerette/assets/environment/caves/SM_WaterfallCave.glb`
  — le worktree d'un **autre agent**, d'une **passe précédente**, hors du socle
  `507ef6a`. L'épreuve 5 — la seule des dix qui mesure la géométrie livrée
  plutôt qu'une fixture — ne mesurait donc pas le fichier de son propre arbre.
- **Pourquoi personne ne l'a vu** : le fichier visé portait, ce jour-là, le
  **même sha256** que le candidat du socle (`cc3596c5d68cbfd8`). Vérifié :

  ```
  sha256sum /home/user/zelda-r2a352/b_collerette/assets/environment/caves/SM_WaterfallCave.glb \
            /home/user/zelda-r2a353/b_adverse/assets/environment/caves/SM_WaterfallCave.glb
  cc3596c5…  (identiques)
  ```

  L'épreuve mesurait donc la bonne chose — **par chance**. Rien ne le
  garantissait : il suffisait qu'une session régénère l'autre worktree pour
  que la suite rende un verdict **précis, plausible, et portant sur une
  géométrie que personne n'avait sous les yeux**.
- **Famille du défaut** : identique à celle que `tools/CLAUDE.md` consigne sous
  « exporter à la main après une chaîne interrompue rend l'ANCIEN maillage » —
  *un résultat faux, précis, plausible et parfaitement inutile* — et à ISS-018 :
  mesurer avec assurance quelque chose qui n'est pas ce qu'on croit. Le journal
  n'imprimait pas le chemin mesuré ; seule la lecture du code pouvait le
  révéler.
- **Aggravant** : le défaut est **auto-reproductible**. Chaque nouvelle passe
  crée un worktree neuf ; un chemin absolu y pointe toujours vers le précédent.
  Il aurait donc survécu à R2a-3.5.3, puis à la suivante.
- **Correction appliquée** (`tools/probe_cave_adversarial.py`) :
  1. le chemin est calculé depuis `__file__` (`RACINE_DEPOT`), donc **relatif à
     la racine du dépôt** — chaque worktree mesure le sien ;
  2. absence du fichier → échec **bruyant** consigné dans les échecs de la
     suite, jamais un `SKIP` silencieux ;
  3. le **sha256 mesuré est imprimé** au journal à chaque exécution, à côté du
     chemin complet.
- **Ce qui a été délibérément NON fait, et pourquoi** : l'empreinte n'est **pas
  épinglée**. L'imprimer rend une substitution visible ; l'épingler
  transformerait la suite adverse en **obstacle** dès que la géométrie sera
  corrigée — et une épreuve adversariale qui interdit de réparer son sujet a
  changé de camp. La distinction vaut d'être retenue : *rendre visible* n'est
  pas *rendre impossible*.
- **Leçon transposable** : un chemin absolu vers un autre arbre de travail est
  un défaut de **conception**, pas un détail de confort. Chercher les autres —
  `grep -rn "/home/user/zelda-" tools/ scripts/` — car un instrument mesure
  rarement seul.
- **Recherche effectuée, et elle a trouvé trois autres occurrences** :
  `tools/blender/diag_cave_etapes.py` porte `SOURCE`, `SORTIE` et
  `FICHIER_FEINT` en absolu vers `/home/user/zelda-r2a351/a_profil/` et
  `/home/user/zelda-r2a351/b_sonde/` — deux worktrees de la passe R2a-3.5.1
  qui **n'existent plus** (vérifié : `ABSENT`). Ce fichier n'appartient pas à
  l'agent B et n'a **pas** été modifié.
  **La distinction de gravité mérite d'être notée** : ces trois chemins-là ne
  résolvent plus, donc l'outil **échoue bruyamment** — il ne ment pas. Celui de
  l'épreuve 5 résolvait vers un fichier plausible, et **mesurait en silence**.
  Un chemin absolu cassé est un `S3` ; un chemin absolu qui marche encore par
  hasard est un `S2`.

---

## ISS-056 — `pkill -f` traverse les frontières entre arbres de travail — S2, CONSIGNÉ

**Découvert** : 2026-08-17, passe R2a-3.5.6, **auto-signalé par l'agent A**.

Pour arrêter ses propres calculs, un agent a employé :

```bash
pkill -f cave_
pkill -f "python3 -"
```

Ces motifs ne sont bornés à **aucun** arbre. Ils matchent les processus d'un
worktree voisin aussi bien que les siens. Les processus vus ensuite étaient
vivants, mais rien ne les protégeait, et **le passé reste indécidable** : un
calcul tué avant l'observation est indiscernable d'un calcul jamais lancé.

C'est le dégât que `COMMENT_TRAVAILLER_ENSEMBLE` §1 décrit — une action qui
traverse la frontière entre sessions — et la directive de la passe l'interdisait
nommément.

**Vérification faite sans `pgrep -f`**, en lisant `/proc/<pid>/cwd` : aucun
calcul vivant au moment du constat, donc rien en cours d'endommagement.

**Parades, dans l'ordre de solidité :**

1. **ne jamais employer `pkill -f` ni `pgrep -f`** dans un dépôt à worktrees
   multiples — le motif ne peut pas être rendu sûr, il doit être remplacé ;
2. relever les PID nominativement après avoir lu `/proc/<pid>/cwd` ;
3. faire écrire par chaque commande surveillée un jeton `RC=` en fin de journal.
   **Tout journal sans ce jeton est réputé mort et doit être rejoué** : c'est la
   seule règle qui rende un `kill` détectable après coup.

Même famille que le piège déjà consigné dans `tools/CLAUDE.md` — `pgrep -f` dans
une boucle d'attente se voit lui-même. Les deux viennent de ce que `-f` cherche
dans des lignes de commande complètes, **sans notion d'arbre ni de session**.

## ISS-057 — `blender --background --python` rend `0` même quand le script lève — S2, CONSIGNÉ

**Découvert** : 2026-08-17, passe R2a-3.5.6, par l'agent B. Deux exécutions ont
rendu `RC=0` en ayant échoué.

Blender attrape l'exception du script, l'imprime, puis **quitte normalement**. Le
shell voit 0. **Tout banc Blender de ce dépôt est exposé**, y compris ceux qui
mesurent une géométrie — le verdict porte alors sur une scène vide.

`--python-exit-code 1` corrige le cas nominal ; il ne couvre ni les scripts qui
rattrapent leur propre exception, ni les échecs postérieurs au script.

**Parade** : faire imprimer `FIN NOMINALE` en **dernière** ligne du script et
exiger ce jeton, quel que soit le code retour. Consigné dans `tools/CLAUDE.md`.

**Cas concret** : placer un générateur témoin dans `/tmp` casse
`KIT_ROCHES = parents[3]`, qui remonte trois répertoires depuis `__file__`. D'où
la règle : **ne jamais copier un script de génération hors de son arbre** — il
lit son propre chemin pour trouver ses ressources.

## ISS-058 — le maillage de la bouche est trop grossier pour la loi de rebord — S2, OUVERT

**Découvert** : 2026-08-17, par deux chemins indépendants qui convergent sur une
seule action.

1. **La rampe n'a que cinq paliers.** `LOI-R` est progressive sur `[0 ; 0,80]`,
   mais à l'arête médiane réelle de `SM_WaterfallCave` — **0,3325 m**, mesurée
   sur l'asset livré — elle ne peut porter que 5 valeurs distinctes. Elle n'est
   pas progressive, elle est quasi binaire. Et la lâcheté du majorant de `d` y
   vaut **0,0412 m, soit 82 % de `h = 0,05`** : l'encadrement consomme presque
   toute la marge de la loi.
2. **`Γ` est dentelé d'un facteur 10,6.** `Γ` est bien une courbe simple fermée à
   la bouche — une composante, tous sommets de degré 2, ancre à 0,757 m — mais il
   mesure **116,16 m** quand une ellipse à ses dimensions en mesure **10,99 m**.
   Cause : `Γ` est porté par des arêtes **4,0 à 4,5 fois plus longues** que la
   médiane du maillage, donc la frontière serpente au lieu de suivre une courbe.

**Le remède est le même dans les deux cas, et il n'est pas un filtrage** : un `Γ`
de 11 m ne s'obtiendra pas en filtrant, il s'obtiendra **en maillant**. Raffiner
le maillage au voisinage de la bouche est le seul travail géométrique que cette
passe a identifié comme indispensable et qu'elle n'a pas fait.

**Sens de l'erreur, et il protège** : la dentelure fait plonger `Γ` vers
l'intérieur, donc `d(p)` est localement **sous-estimée** et l'exigence avec elle.
Les `FAIL` publiés sont donc valides et probablement **sous-estimés** ; en
revanche **aucun `PASS` de production ne pourrait être cru** sur cette base.

## ISS-059 — fuites de ressources du PROJET en fin de processus — **FERMÉE le 2026-08-21 par décision du lead (clôture R2B.3.1)**

> **Portée de la fermeture, à lire avant d'invoquer ce ticket.** ISS-059 ne
> couvre QUE les ressources appartenant au projet : matériaux, maillages,
> textures, flux audio, scènes. Elles sont libérées, mesuré et vérifié. Le
> résidu de scripts que le moteur retient dans son propre `GDScriptCache` est
> un domaine DIFFÉRENT, suivi séparément par **ISS-065**, et il n'est pas
> bloquant. Les confondre était l'erreur que cette fermeture corrige : un
> rouge que personne ne peut lever entraîne à ignorer la ligne rouge.
>
> Les deux verdicts sont désormais rendus séparément à chaque `validate_fast` :
> `PROJECT_RESOURCE_LEAK_GATE` (bloquant) et `ENGINE_SCRIPT_CACHE_TELEMETRY`
> (WARN, qui **redevient bloquante** à la moindre dérive).

Constaté le 2026-08-18 au premier `validate_fast.sh` complet depuis V2.3-A.R
(chaque passe R2a-3.x avait interdiction de le lancer). **Les 904 tests sont
verts** ; le rouge vient du filtre N1 sur les diagnostics de sortie du
processus : `3409 ObjectDB instances leaked`, `238 resources still in use`,
fuites RID `DummyMaterial`/`DummyShader`/`DummyMesh`
(`evidence/world_v2/v2_3_r2a/grotte/r2a358_lead/validation/`).

**Préexistant, MESURÉ et non inféré** : la suite complète rejouée à la base
`0b0ef54` (tête Codex, zéro commit R2a-3.5.8) porte la même signature aux
comptes IDENTIQUES. La passe R2a-3.5.8 n'ajoute pas un objet à la fuite.

**Ce qui est cerné** : la fuite n'apparaît sur AUCUN lot isolé — `boot_smoke`,
`world_v2` (56 tests), `unit` (137), `boss_run`, `dungeon_run` sortent tous
avec zéro ligne de fuite. Elle n'existe que sur le processus qui exécute la
suite entière ; le lot `integration` seul dépasse 30 min et n'a pas pu être
isolé dans le budget de la passe. Précédent : `42ee1db` (2026-08-09) — même
famille de symptôme, cause d'alors : l'ambiance audio ; cause actuelle non
identifiée, fenêtre de régression [`f550101` … `0b0ef54`].

**Contournement** : aucun nécessaire pour juger un lot — tout filtre isolé
est propre. **Règle maintenue** : le verdict validate_fast reste ROUGE tant
que la cause n'est pas traitée ; un rouge préexistant ne se rebaptise pas
vert (`PROMPT4_METHOD` §3, discipline du budget rouge).

**Propriétaire** : prochaine session de dette technique — bissection par
moitiés de la liste des tests dans un même processus, puis `--verbose` sur
le sous-ensemble coupable.

**Mise à jour 2026-08-19 (intégration R2B)** : validate_fast rejoué sur la
branche intégrée (`evidence/world_v2/v2_3_r2b/integration/validate_fast_integree.log`) —
**916 tests verts, 0 échoué**, rouge toujours porté par la seule signature de
sortie. Mêmes QUATRE types de RID, aucune classe nouvelle ; l'amplitude a
suivi le contenu : ObjectDB 3409→5103 (+1694), DummyMaterial 3057→4749
(+1692), resources 238→239, DummyShader 13→14, DummyTexture 57→58,
DummyMesh 42→42 inchangé. La passe filtrée `world_v2` (68 tests) sort avec
ZÉRO ligne de fuite : le profil « suite complète seulement » est inchangé, et
la croissance est proportionnelle aux instances de modules des cinq lieux
reconstruits que la suite monte de nombreuses fois — pas une classe de fuite
nouvelle. Le verdict validate_fast reste ROUGE (règle du budget rouge).

**Mise à jour 2026-08-19 (R2B.1)** : rejoué sur la branche intégrée
(`evidence/world_v2/v2_3_r2b1/integration/validate_fast.log`) — **933 tests
verts, 0 échoué**, rouge toujours porté par la seule signature de sortie.
Cette signature est **IDENTIQUE AU CHIFFRE PRÈS** à celle de l'intégration
R2B : ObjectDB 5103, resources 239, DummyMaterial 4749, DummyShader 14,
DummyMesh 42, DummyTexture 58. R2B.1 n'ajoute donc **aucun** objet à la fuite,
alors qu'elle ajoute 17 tests et deux GLB régénérés — **aucune différence
nouvelle par rapport à la base**. Le verdict validate_fast reste ROUGE.

---

### Signature au 2026-08-19, après R2B.2 — QUATRE types identiques, aucune classe nouvelle

`validate_fast.sh` rejoué **une seule fois**, à la fin de R2B.2, au SHA `ea93460`.
**943 tests réussis, 0 échoué.** Le rouge vient exclusivement du filtre N1 sur
les diagnostics de sortie de processus.

| | R2B.1 (933 tests) | **R2B.2 (943 tests)** | écart |
|---|---:|---:|---:|
| `ObjectDB instances` | 5 103 | **5 203** | +100 |
| `resources still in use` | 239 | **239** | **0** |
| `DummyMaterial` | 4 749 | **4 849** | +100 |
| `DummyShader` | 14 | **14** | **0** |
| `DummyMesh` | 42 | **42** | **0** |
| `DummyTexture` | 58 | **58** | **0** |

**Aucune classe nouvelle. Trois types sur quatre sont identiques au chiffre
près.** Le seul écart est de +100 sur `DummyMaterial` et le compte ObjectDB —
c'est-à-dire **le même objet compté deux fois**.

**Explication : HYPOTHÈSE, pas mesure.** Dix tests de plus, et la ferme duplique
désormais un `StandardMaterial3D` par surface pour porter les textures du kit ;
+100 serait donc du contenu et non une fuite nouvelle. **C'est une histoire
plausible et je l'écris comme telle** — le recoupement, compter les surfaces
réellement peintes par `_peindre_glb()` et vérifier que 100 tombe juste, est
demandé à l'audit indépendant. Si le compte ne tombe pas, cette entrée sera
corrigée dans ce sens plutôt que de garder une explication commode.

**Ce qui EST mesuré, en revanche, et qui tient sans l'hypothèse** : quatre
classes sur cinq strictement identiques d'une passe à l'autre. Une fuite nouvelle
aurait fait bouger au moins une classe figée. Ce n'est pas une preuve d'absence
de régression — c'est un faisceau, et il est publié comme tel.

**Recoupement demandé à l'audit indépendant : il REFUSE de me le confirmer.**
Il a vérifié la *structure* — `SM_Farm_Ruins.glb` porte **16 pièces** (compte
indépendant, recoupé avec son propre journal d'ablation) et **4 matériaux** ;
le cache de `_peindre_glb()` est `static`, à clé `instance_id|gain|mode`. Le
nombre de `StandardMaterial3D` dupliqués est donc **borné et petit**, ce qui
rend l'ordre de grandeur plausible. **Mais il ne confirme pas 100 sans
instrumenter Godot, et il ne l'a pas fait.**

**Correction de fait, 2026-08-20 (R2B.3)** : l'audit de R2B.3 a recompté —
`SM_Farm_Ruins.glb` porte **14 pièces, pas 16**, et **2 076 triangles, pas
2 080** (quatre triangles d'aire nulle, tous dans `GableBreak`, sont écartés
dès qu'on les compte correctement ; `docs/assets/ASSET_MANIFEST.csv` annonce
en outre 1 996). Le « 16 » venait de l'audit de R2B.2 et je l'avais recopié
sans le vérifier. L'hypothèse du `+100` reposait en partie sur ce compte : elle
en sort **plus faible encore**, pas plus forte.

**Correction consignée, dans le sens exact qu'il a demandé** : « proportionnel
au contenu ajouté » reste une **histoire plausible et bornée, pas une mesure**.
Elle n'est pas retirée du dossier — elle est rétrogradée au rang d'hypothèse
non recoupée, et le `+100` demeure **NON EXPLIQUÉ**. Détail :
`evidence/world_v2/v2_3_r2b2/preuves_lead/VERIFICATIONS_LEAD.md` §37.

Journal : `evidence/world_v2/v2_3_r2b2/validation/validate_fast_R2B2.log`.

**Non réparé dans cette passe, conformément à la directive.** Le harness global
est donc `ROUGE`, et il est **rapporté comme tel** : la passe ne se déclare pas
verte.

---

### Mise à jour 2026-08-20 (R2B.3) — une VRAIE fuite trouvée et corrigée, mais ce n'est PAS celle-ci

**Verdict : `FAIL` sur une fuite réelle, `NON VÉRIFIÉ` sur la signature de sortie.**

La cause enfin nommée, et ce n'était aucun des deux suspects du dossier.
`WorldV2PlaceKit.scene_for()` faisait `load(path)` **sans rien retenir** : au
démontage la `PackedScene` perdait sa dernière référence, le moteur vidait ses
sous-ressources, et le montage suivant reconstruisait des **matériaux de base
neufs**. Deux caches `static` à clé `base.get_instance_id()` ne pouvaient donc
plus jamais faire mouche — et, étant `static`, ils **gardaient chaque
génération**.

| scénario, un seul processus | avant (c0/c1/c2) | croissance | après |
|---|---|---:|---|
| témoin | 0 / 0 / 0 | 0 | 0 / 0 / 0 |
| ferme | 48 / 75 / 102 | **+27** | 48 / 48 / 48 |
| arbre | 11 / 15 / 19 | **+4** | 11 / 11 / 11 |
| monde | 334 / 536 / 738 | **+202** | 334 / 334 / 334 |

Vingt cycles : 48 → 561, **+27 sur chacun des dix-neuf intervalles, sans
plateau**. Corrigé en retenant la scène, sur le modèle de `AssetRegistry.model()`
dont le commentaire documentait déjà ce danger exact. Filet de régression :
`tests/world_v2/test_world_v2_iss059_cache_kit.gd`.

**Et ce n'est pas la fuite de cette entrée.** 561 matériaux retenus produisent
**zéro** ligne de fuite au rapport de sortie. Les `static` GDScript sont libérés
avant ce rapport.

**Formulation corrigée après audit** : ce constat est une **observation directe**
des 561, pas une déduction depuis le contrôle positif. Le contrôle positif
(100 `MeshInstance3D` orphelins → `200 ObjectDB` / `100 DummyMaterial`) prouve
seulement que **le rapporteur parle** ; un nœud orphelin et un matériau retenu
par un dictionnaire `static` sont deux régimes différents. C'est une **borne
empirique forte, pas un mécanisme**.

**Le `+100` reste NON EXPLIQUÉ**, et le mécanisme proposé par l'audit de la
phase 0 est **falsifié** : `AssetRegistry._model_cache` vaut 0 dans trois
scénarios et 21 dans le monde — jamais son plafond de 48, donc sa purge ne
s'exécute jamais.

**Un fait contre le texte de cette entrée** : « aucun lot isolé ne fuit » est
**trop fort**. `boss_arena` seul émet `2 ObjectDB` + `1 resource` — mais **aucune
ligne de RID, aucun `DummyMaterial`**. Le plancher est petit et sans matériau,
ce qui reformule la bissection : chercher ce qui **multiplie** un petit résidu
par des milliers, pas ce qui le crée.

**Ce qui n'a PAS été obtenu, sans atténuation** : la décomposition du `+100`, et
l'effet du correctif sur la signature. Les deux exigent **deux suites complètes
au MÊME SHA** — la base de la voie B est 6 commits après `ea93460`, où la
signature R2B.2 a été relevée. Statut : **`BLOQUÉ`**, pour non-attribuabilité,
pas pour durée : la suite complète prend **environ une heure**, pas 3 h 30 comme
estimé d'abord par division par une durée qui n'avait pas eu lieu.

### Signature au 2026-08-20, APRÈS le correctif — elle s'est effondrée

`validate_fast.sh` rejoué **une seule fois**, à la fin de R2B.3, isolé. RC 1.
**947 tests réussis, 0 échoué.**

| classe | R2B.2 (`ea93460`) | **R2B.3** | écart |
|---|---:|---:|---|
| `ObjectDB` | 5 203 | **1 003** | **−4 200** |
| `resources still in use` | 239 | **657** | +418 |
| **`DummyMaterial`** | **4 849** | **281** | **−4 568 (−94 %)** |
| `DummyShader` | 14 | **14** | **0** |
| `DummyMesh` | 42 | **214** | +172 |
| `DummyTexture` | 58 | **67** | +9 |

**Et le résidu restant est exactement celui que la sonde de bissection reproduit
en 97 secondes hors de la suite** : `Material 281 · Shader 14 · Mesh 214 ·
Texture 67`, **les quatre au chiffre près**. Ce n'est plus un faisceau : c'est la
même fuite, isolée, rejouable en une minute et demie au lieu d'une heure.

Identité énumérée : 276 `StandardMaterial3D` + 4 `ShaderMaterial`, 214
`ArrayMesh`, 67 `Image` + 64 `CompressedTexture2D`, 107 `PackedScene` avec autant
de `SceneState`, **aucune avec `resource_path`** — des sous-ressources de scènes
épinglées par l'**instanciation** (le chargement seul n'en épingle aucune).
Localisation : tout apparaît **entre la 71ᵉ et la 74ᵉ scène** — `WorldV2.tscn`,
`WorldV2Bootstrap.tscn`, `ResonancePylon.tscn`.

**Une conclusion de la bissection est corrigée ici.** Elle écrivait « la suite
fuit 115 matériaux par maillage et la sonde 1,3 — ce n'est donc pas la même
fuite ». Vrai contre la signature d'**avant** le correctif, faux contre celle
d'**après** : la suite rend aujourd'hui 281/214 = **1,31**, le rapport de la
sonde. Elle comparait un résidu post-correctif à un chiffre pré-correctif ; son
propre §0 signalait cet écart de SHA comme « la limite d'attribution de tout ce
qui suit ».

**Ce qui manquait alors, et qui interdisait de fermer** : **quel objet retient**
les `PackedScene` épinglées à l'instanciation. La sonde le montrait, elle ne le
nommait pas. — *Répondu en R2B.3.1, ci-dessous.*

Preuves : `evidence/world_v2/v2_3_r2b3/iss059/`.

---

### 2026-08-20 (R2B.3.1) — la chaîne causale, nommée par ablation à variable unique

**Il n'y a pas un objet : il y en a trois, et ce sont des variables `static` de
GDScript sans propriétaire ni fin de vie.**

```
WorldV2PlaceKit._scene_cache      (world_v2_place_kit.gd:71)   89 PackedScene
   └─ SceneState └─ ArrayMesh · StandardMaterial3D · CompressedTexture2D · Image
AssetRegistry._model_cache        (asset_registry.gd:61)       21 PackedScene
WorldV2PlaceKit._material_cache   (world_v2_place_kit.gd:54)   98 StandardMaterial3D dupliqués
```

`89 + 21 − 3 communes = **107**` — **exactement** le compte de `PackedScene`
vivantes de la bissection, et son compte de `SceneState`. La contre-épreuve
indépendante a vérifié plus fort que la cardinalité : la **différence symétrique
entre l'union des chemins des deux caches et l'ensemble des `PackedScene`
fuitées est VIDE**.

**Le reproducteur se réduit d'un facteur trois.** La bissection localisait
« entre la 71ᵉ et la 74ᵉ scène », donc trois suspectes. Montées séparément :
`ResonancePylon.tscn` est **innocente** (zéro ligne) ; `WorldV2.tscn` **seule**
porte la signature entière, en **22 s** au lieu de 97 ; toute combinaison qui la
contient donne le même chiffre au chiffre près. C'est une allocation qui
**sature**, pas une dose par scène.

| ablation, juste avant `quit()` | ObjectDB | resources | Material | Mesh |
|---|---:|---:|---:|---:|
| aucune — témoin | 951 | 626 | **281** | **214** |
| `_material_cache` (98 entrées) | 853 | 626 | 183 | 214 |
| `AssetRegistry._model_cache` (21) | 841 | 538 | 251 | 178 |
| `_scene_cache` (89) | 438 | 208 | 136 | 42 |
| `_scene_cache` + `_model_cache` | 312 | 107 | 102 | **0** |
| les cinq conteneurs | **128** | **64** | **4** | **0** |

`_material_cache` retire **exactement 98** matériaux — sa taille — et aucun
maillage : ce sont des `duplicate()`. Les deux caches de scènes emportent
**100 % des maillages**. Les cinq emportent **98,6 % des matériaux**.

**STABLE, PAS CUMULATIF.** Deux cycles montage/démontage dans le même processus :
`objets=2875 ressources=861` aux DEUX cycles, à l'unité près. Avant le correctif
R2B.3 c'était `+27 matériaux par cycle sans palier`. La rétention avait converti
une croissance linéaire en plateau — **ce n'était donc pas la rétention qu'il
fallait corriger, c'était son absence de fin de vie.**

#### Deux affirmations de ce dossier étaient FAUSSES, et sont corrigées ici

1. « Les `static` GDScript sont libérés avant ce rapport. » **Faux.** Si c'était
   vrai, les vider juste avant `quit()` ne changerait rien au rapport. Cela le
   change de 951 à 128.
2. « Les 107 `PackedScene` n'ont pas de `resource_path`, donc ce sont des
   sous-ressources embarquées. » **Artefact du format du rapport.**
   `ObjectDB::cleanup()` enchaîne trois `if` qui écrasent la même variable
   (`Node` → chemin, `Resource` → chemin, `RefCounted` → compteur) ; `Resource`
   héritant de `RefCounted`, le troisième gagne toujours : le moteur n'imprime
   **jamais** le `resource_path` d'une ressource. Contre-preuve prise dans le
   processus : `kit : 0 entrees SANS resource_path`.

Une troisième correction, de méthode : `WorldV2Bootstrap.tscn` n'est **pas** un
montage/démontage — son `_ready()` appelle `SceneFlow.go_to()`, la scène devient
`current_scene` et RESTE dans `root` (`noeuds=3858` contre 23). Les lignes de
matrice qui l'impliquent restent publiées mais sont `NON VÉRIFIÉES` comme
mesures de cycle. Trouvé par la contre-épreuve, pas par le lead.

#### Le correctif, à la source

Un cache de durée de vie « processus » sans propriétaire ne peut pas être
relâché. Trois gestes :

1. `scripts/core/static_resource_caches.gd` — `StaticResourceCaches`, un registre.
2. `static func liberer_caches() -> int` sur les onze porteurs, **inscrite par
   `_static_init()`** — l'inscription est aussi paresseuse que le cache : un
   porteur jamais chargé n'a rien à relâcher.
3. `SceneFlow._exit_tree()` appelle `liberer_tout()` : un autoload quitte l'arbre
   à l'extinction du moteur, avant qu'il ne compte ses fuites.

**Le sens de la dépendance est imposé par un test existant.** Une première
version portait la liste des porteurs dans le noyau, par chemin ;
`test_aucune_reference_croisee_interdite` l'a refusée, et il avait raison. Le
porteur connaît le noyau ; le noyau ne connaît aucun porteur.

| après correctif, 2 cycles | ObjectDB | resources | Material | Shader | Mesh | Texture |
|---|---:|---:|---:|---:|---:|---:|
| témoin | 0 | 0 | 0 | 0 | 0 | 0 |
| `ResonancePylon.tscn` | 0 | 0 | 0 | 0 | 0 | 0 |
| **`WorldV2.tscn`** | **104** | **55** | **0** | **0** | **0** | **0** |

**Les quatre classes de RID de la signature disparaissent** : `281 → 0`,
`214 → 0`, `65 → 0`, `11 → 0`. Cycle 1 = cycle 2.

#### Ce qui reste, énuméré et non résumé

`55 GDScript + 45 GDScriptNativeClass` — le cache de scripts du moteur, qu'un
chargement de `.tscn` épingle ; le témoin est à zéro et les suites lancées par le
runner sortent propres, donc ce résidu appartient au chemin `--script` d'une
sonde, pas au harnais. Plus **un** flux audio, nommé ici pour la première fois :
`res://assets/audio/sfx/land_soft.wav` (`AudioStreamWAV` +
`AudioStreamPlaybackWAV`), le son de réception du joueur qui apparaît au spawn.
Un objet, aucune classe de RID. **Non corrigé** : c'est le chemin audio, hors du
périmètre d'ISS-059. Ticket à ouvrir.

**Dette de conception nommée, non traitée** : la clé de `_material_cache` est
`"%d|%s" % [base.get_instance_id(), tone]`. Un identifiant d'instance est plus
court que la vie du cache ; c'est pour le stabiliser qu'il faut retenir la
`PackedScene`. Changer cette clé supprimerait le besoin de rétention — mais
c'est une modification du comportement de teinte des lieux, en pleine passe où la
géométrie est gelée.

Preuves : `evidence/world_v2/v2_3_r2b3_1/iss059/CHAINE_CAUSALE.md`, matrices
`matrice_c1/` et `matrice_c2/`, ablation `ablation/`, après-correctif
`apres_correctif/`.

#### La suite COMPLÈTE, mesurée une seule fois à la fin — la signature s'effondre

`tools/validate_fast.sh`, une exécution, isolée. **949 tests réussis, 0 échoué.**

| classe | R2B.3 | **R2B.3.1** | écart |
|---|---:|---:|---|
| `ObjectDB instances` | 1 003 | **138** | **−86 %** |
| `resources still in use` | 657 | **74** | **−89 %** |
| **`DummyMaterial`** | **281** | **ligne absente** | **−100 %** |
| **`DummyMesh`** | **214** | **ligne absente** | **−100 %** |
| **`DummyTexture`** | **67** | **ligne absente** | **−100 %** |
| `DummyShader` | 14 | **3** | −79 % |

**Trois des quatre classes de RID disparaissent complètement du rapport.** Ce
n'est pas une reduction de compte : la ligne n'est plus imprimee, donc le
compte est zero.

**LE HARNESS RESTE ROUGE, ET IL EST RAPPORTÉ COMME TEL.** Cinq lignes le
maintiennent rouge, toutes de fin de processus :

```
WARNING: 138 ObjectDB instances were leaked at exit
ERROR:   74 resources still in use at exit
ERROR:   Pages in use exist at exit in PagedAllocator: BucketMedium
ERROR:   Pages in use exist at exit in PagedAllocator: BucketSmall
ERROR:   3 RID allocations of type 'DummyShader' were leaked at exit
```

Les deux lignes `PagedAllocator` sont les `Variant` que portent les objets
survivants : elles suivront le residu, elles ne sont pas une cause distincte.

**CE QUI RESTE, ÉNUMÉRÉ SUR LA SUITE COMPLÈTE ET NON PLUS DÉDUIT.** La passe
précédente laissait la composition des 138 inconnue et refusait de l'extrapoler
depuis la sonde. Elle a depuis été **mesurée** : suite entière relancée en
`--verbose`, 949 tests réussis, 0 échoué, et le vidage décomposé.

| ligne du rapport de sortie | compte | décomposition mesurée |
|---|---:|---|
| `ObjectDB instances were leaked` | **138** | 74 `GDScript` + 61 `GDScriptNativeClass` + 3 `Shader` |
| `resources still in use` | **74** | 71 `.gd` + 3 `.gdshader` |
| `RID allocations 'DummyShader'` | **3** | les 3 `Shader` ci-dessus |

La somme tombe juste au dernier objet, et **il ne reste rien d'autre** : pas un
matériau, pas un maillage, pas une texture, pas un flux audio.

**UNE seule cause, pas deux.** Charger une `.tscn` épingle les `GDScript`
qu'elle attache et leurs `GDScriptNativeClass` : c'est le cache de scripts du
moteur (`GDScriptCache`), qu'**aucune API GDScript ne purge**. Les trois shaders
survivants sont des constantes `preload()` de `scripts/lookdev/hero_shot_lab.gd`,
script lui-même épinglé — donc une **conséquence** des 135 autres, pas une cause
distincte. `liberer_caches()` vide des variables, jamais une table de constantes.

Le résidu est donc **entièrement attribué au moteur**, et plus aucun conteneur
du projet n'y participe. Cela ne rend pas le harnais vert, et ce fichier ne le
prétend pas : cinq lignes de fin de processus subsistent. Le seuil du filtre N1
n'a **pas** été touché, et ne le sera pas pour faire passer un rouge.

Décomposition complète, provenance des 74 `.gd` par dossier, et refus argumenté
du changement cosmétique `preload` → `load` :
`evidence/world_v2/v2_3_r2b3_1/iss059/RESIDU_SUITE_COMPLETE.md`.

Journal : `evidence/world_v2/v2_3_r2b3_1/validation/validate_fast_R2B3_1.log`.

---


---

## ISS-060 — les débris de la ferme sont des pavés droits — **CORRIGÉ TECHNIQUEMENT le 2026-08-20, verdict visuel NON VÉRIFIÉ**

**Mise à jour R2B.3.** Le liant passe de **96,8 % à 0,00 %** sur `SM_Farm_Debris_A`
et `_B`, mesuré par le lead au SHA intégré et reproduit par l'audit indépendant.
`0,00 %` est exactement la valeur des témoins acceptés `SM_Dungeon_RubbleLarge`
et `RubbleSmall`, tas de gravats de la même famille d'objet.

Le geste est **structurel, pas un réglage** : la primitive `eclat()` construit
`k + k + 1` sommets avec `k` borné à [3 ; 7], donc **toujours impair, jamais
huit**. Relevé sur le maillage livré : sommets `[4,9,9,9,9,11,11,11,11,13,13,13]`,
plans `[4,11,13,13,14,16,17,17,17,21,22,22]` — **zéro composante à 8 sommets,
zéro à 6 plans**. `hexa` et `pave6` sont l'un comme l'autre impossibles.

Neuf planchers anti-contournement tenus, non-contamination des 12 autres meshes
vérifiée au sha256 du flux de positions trié (Δemprise 0,00000 sur les trois
axes), sabotage à variable unique (liant 0,0 → 87,0 %, les huit autres planchers
inchangés), restauration byte-identique.

**Ce qui reste ouvert, et c'est le point qui compte** : le liant est
**nécessaire, pas suffisant**. Rien n'empêche un fragment à neuf sommets de
ressembler à une boîte. Ni l'agent ni l'audit n'ont vu le tas — pas de GPU.
**Le verdict visuel appartient à Codex/Istvan.**

Deux changements que la revue doit connaître avant de regarder :
`MAT_Farm_Stone` passe de **0 à 94 triangles (47 %)**, les tuiles de 58 à 36 %,
le bois de 39 à 12 % — le tas change de **matière**, pas seulement de forme ; et
l'emprise de `Debris_A` gagne ~5 % en X comme en Z.

Historique du défaut, conservé :

## ISS-060 (état d'origine) — les débris de la ferme sont des pavés droits à 96,8 % — S3

Mesuré le 2026-08-19 à la clôture de R2B.2, sur `SM_Farm_Ruins.glb` au SHA
`c0374839`. Trois prédicats indépendants, publiés ensemble parce qu'ils
répondent à trois questions différentes :

| prédicat | définition | résultat sur le GLB |
|---|---|---:|
| `hexa` (le liant, plafond 25 %) | 12 triangles + 8 sommets soudés | **79,6 %** |
| équidistance | + 8 coins à 2 % du centroïde | **42,1 %** |
| `droite` | + 6 directions de normale | 9,2 % |

Le liant **échoue** : 79,6 % contre un plafond de 25 (87,2 % avant la passe,
donc 7,6 points de progrès réel qui ne franchissent pas le portail).

**Le domaine du seuil a été mis en cause, puis confirmé par la mesure.** Le lead
a émis l'hypothèse qu'un lieu bâti en modules de kit est légitimement boîteux,
et s'est engagé **par écrit avant la mesure** sur trois issues. La mesure en a
donné une quatrième : `SM_Farm_Ruins.glb` ne contient **aucun** module de kit —
ses quatorze meshes sont tous `SM_Farm_*`, les `Wall_UnevenBrick_*` vivant dans
des fichiers séparés instanciés au runtime — et un module de kit n'est **pas**
une boîte : `Wall_UnevenBrick_Straight` rend **0,0 %** avec quatre composantes
pour 56 triangles, `Corner_Exterior_Brick` **0,0 %** avec vingt-sept. Les deux
GLB héros du hameau gelé sont également à 0,0 %.

**Localisation, qui est ce qui rend le ticket actionnable :**

| pièce | tri | % en pavés (équidistance) | lecture |
|---|---:|---:|---|
| `RoofPan_Intact` / `_Fallen` | 108 ch. | **100,0** | pan de couverture — primitive juste |
| `InteriorFrame` | 72 | **100,0** | ossature — primitive juste |
| `Truss` | 212 | **90,6** | charpente — primitive juste |
| **`Debris_A` / `_B`** | **124 ch.** | **96,8** | **DÉFAUT — des débris n'ont plus de forme** |
| `Rubble_North` / `WallStub_East` | 144 / 84 | **0,0** | moellons déjà irréguliers |

> **La charpente est en pavés droits — c'est juste, un bois est scié d'équerre.
> La maçonnerie est en boîtes déformées — c'est acceptable. Les débris sont en
> pavés droits — c'est le défaut.**

**Geste borné si la revue le demande** : `Debris_A` et `_B` dans
`source_assets/blender/architecture/make_farm_ruins.py`, **248 triangles au
total**, budget disponible **2 420 sur 4 500**. Aucune autre pièce n'est en
cause.

**Ce qui ne doit PAS être fait** : un bruit sous-pixel qui ferait tomber `hexa`
sans rien changer à l'image. Ce contrôle existe parce qu'un pavé parfait se lit
comme du carton ; une correction qui ne se voit pas ne corrige rien.

Deux instruments, deux chiffres, aucune moyenne — les définitions sont dans
`evidence/world_v2/v2_3_r2b2/preuves_lead/VERIFICATIONS_LEAD.md` §28.

---

## ISS-061 — `capture_poi_batch.gd` : le champ `commit` de provenance vaut toujours « inconnu » — S4, OUVERT

Mesuré le 2026-08-19 sur le manifeste de `preuves_lead/captures_r2b2/`.

`_provenance_par_role()` passe le chemin tel quel à `git log -1 --format=%H --
<chemin>`. Avec un chemin `res://assets/…`, git ne connaît pas le préfixe et
rend une sortie vide : le champ vaut `inconnu` pour **tous** les rôles. Le
`sha256`, lui, passe par `FileAccess` qui résout `res://` et fonctionne — c'est
lui que le §7 exige, et il est correct.

**Correctif** : passer un chemin **sans** préfixe. Le code accepte déjà les deux
côté `FileAccess` (`chemin if chemin.begins_with("res://") else "res://" +
chemin`), donc une seule forme suffirait aux deux usages.

Non bloquant : le commit de l'arbre est déjà en tête de manifeste, et la preuve
d'identité du fichier est le sha256.

---

## ISS-062 — le portail de boîtitude reste contournable par FUSION de composantes — S3, OUVERT

Trouvé par l'audit indépendant le 2026-08-20, **après** que les cinq
perturbations précédentes ont été fermées (`tools/mesure_boititude.py`,
autotest 10/10).

Contre-exemple construit et mesuré : **dix-huit pavés droits parfaits**, posés
tangents dès l'origine et **soudés par un coin latéral**, rendent **0,00 % de
liant** et franchissent **les neuf planchers** — emprise en Y identique, aucune
écharde, aire et médiane conformes.

Cause de principe : `hexa` comme `pave6` raisonnent **par composante connexe**.
Le prédicat est donc cassable en changeant *ce qui compte comme une composante*,
et le soudage — que l'on a justement rendu plus tolérant (0,1 mm) pour fermer le
défaut du coin décalé de 12 µm — élargit cette prise.

**Non exploité par la voie A** : ses fragments n'ont aucun pavé à fusionner, et
le relevé du maillage livré ne contient **aucune** composante à 8 sommets ni à
6 plans. Le risque n'est pas la fraude, c'est le **vert accidentel après un
remaillage qui soude**.

Pistes non retenues faute de périmètre : mesurer la boîtitude sur la
**décomposition convexe** plutôt que sur la composante connexe ; ou ajouter un
plancher de **nombre de composantes attendu** par tas, ce qui déplace le
problème sans le résoudre.

### Mise à jour 2026-08-20 — le trou de la SOUDURE est fermé ; un SECOND trou a été trouvé, puis fermé lui aussi

**Soudure — FERMÉ.** `tools/mesure_rectangularite.py` juge les plaques planes et
les angles dièdres, donc **ne raisonne jamais par composante** : la soudure ne le
déplace pas. Autotest 15 cas, dont le contre-exemple exact — 18 pavés tournés
soudés par un coin rendent `rect = 100 %`, `ortho = 100 %`. Sabotage joué :
l'ancien portail rend `liant 0,0 %` et **RC 0** sur une géométrie qui n'est que
des boîtes, le nouveau rend 100,00 % et le filet rougit avec le motif nommé.
Restauration byte-identique.

**Bruit cohérent — trouvé par l'audit adverse, puis fermé.** Déplacer chaque
POSITION UNIQUE de **2 mm** garde les coins soudés — donc l'ancien portail reste
aveugle — mais casse la planéité des faces, donc `part_rectangulaire` s'effondre
à 38,80 %, et `min(RECT, ortho)` la retient. **Les dix contrôles rendaient vert
sur une géométrie qui n'est que des boîtes.** 2 mm sur des arêtes de 189 mm, soit
1,06 % : invisible. La marge de l'instrument valait **un millimètre**.

L'agent avait la mesure et ne l'a pas portée : `iss062/limite_bruitage.txt`
montre, à 20 mm, indice 2,77 % et boîtitude 0,00 % — les deux portails aveugles
sur la même page, dans un fichier sans en-tête cité nulle part.

Correction : **un second plafond, INDÉPENDANT, sur `part_orthogonale` seule**.
Un `min` protège contre le cas où une seule grandeur suffirait à ABSOUDRE ; il ne
protège pas contre le cas où une seule grandeur suffit à ACCUSER. Seuil dérivé
par la **même règle pré-enregistrée** (`iss062/regle_seuil.md`), appliquée à
`ortho` sur la famille NATURE/DÉBRIS : M = 4,80 → plafond **52**.

| | `part_orthogonale` | |
|---|---:|---|
| sujet livré | 14,97 % | PASS |
| pylône · pont · mur acceptés | 15,68 · 6,46 · 4,53 % | PASS |
| sabotage soudé · bruit 2 mm | 100,00 % | **FAIL** |
| bruit 20 mm · 50 mm | 92,72 · 63,50 % | **FAIL** |

Cycle rejoué par le lead : sujet `RC=0`, contre-exemple `RC=1` **avec un seul
écart**, restauration `RC=0` et sha256 `ead79105…` à l'octet près.
Preuves : `evidence/world_v2/v2_3_r2b3/iss062/bruit_coherent/`.

**Le ticket reste OUVERT.** Deux instruments de familles différentes rendent la
régression difficile ; rien ne dit qu'il n'existe pas un troisième contournement,
et aucun des deux ne juge si un tas est beau.

**Propriétaire** : la prochaine passe qui touche un générateur susceptible de
souder. En attendant, le liant reste valable comme **anti-régression** et non
comme preuve de forme — c'est déjà ce qu'énonce ISS-060.

---

## ISS-063 — trois mutex distincts, et `user://` partagé entre tous les worktrees — S2, **CORRIGÉ POUR GODOT le 2026-08-20 ; BLENDER RESTE OUVERT**

Mesuré le 2026-08-20 (R2B.3), constat de la voie A confirmé par le lead et
l'audit.

Le dépôt possède **trois verrous indépendants** : `.git/heavy_tools.lock`
(scripts du dépôt), `validate_fast.lock` (`validate_fast.sh` seul), et
`/tmp/godot.lock` (convention des briefs d'agent, absente du dépôt). Deux
invocations qui prennent chacune un verrou différent **tournent en parallèle**,
et **tous les arbres de travail partagent le même `user://`** — mécanisme
d'ISS-038.

Dégât constaté, pas déduit : deux runners simultanés, mtimes se chevauchant à la
minute près, et un échec **impossible** dans la suite d'une voie —
`test_world_v2_skeleton.gd … slot0 est identique à l'octet près`, alors
qu'aucun chemin ne relie une primitive Blender à un slot de sauvegarde et que le
même test était vert au tour précédent.

**Ce que cela invalide, et rien de plus** : les **suites finales des deux voies
comme verdicts de non-régression**. Tout le reste — boîtitude, morphométrie,
non-contamination, sha256, sabotage, comptes de cache — est hors moteur ou
déterministe, et tient.

Remède immédiat, appliqué par le lead depuis : prendre **les deux verrous du
dépôt**, imbriqués, et jamais `/tmp/godot.lock` seul :

```bash
flock -w 3000 /tmp/godot.lock \
  flock -w 3000 "$(git rev-parse --git-common-dir)/heavy_tools.lock" bash -c '…'
```

Remède de fond, non fait : **un seul** verrou, pris par tout ce qui lance Godot,
et un `user://` distinct par arbre de travail.

**Propriétaire** : prochaine session de dette technique. Tant que ce ticket est
ouvert, deux sessions simultanées produisent des échecs qui n'existent pas.

---

### Correctif R2B.3.1 (2026-08-20) — le remède de fond, pour Godot

**Dette comptée AVANT le correctif**, comme l'exige `PROMPT4_METHOD` §1 :
**13 fichiers exécutables versionnés, 35 sites** lancent le moteur. **Deux**
étaient conformes (`tools/lancer_godot.sh` et son contrôle négatif). **Onze ne
prenaient ni verrou canonique ni cloison.** L'inventaire ligne à ligne est dans
`evidence/world_v2/v2_3_r2b3_1/iss063/INVENTAIRE_POINTS_ENTREE.md`, et la
contre-épreuve indépendante l'a complété de neuf sites, d'un **quatrième**
fichier de verrou (dans un scratchpad de session), d'un lancement Blender en
Python, et d'un vecteur documentaire sous-compté d'un facteur 7.

**Un seul mécanisme** : `tools/lib/godot_env.sh`, sourcé par les scripts.
`godot_verrou_prendre` (verrou canonique `<git-common-dir>/heavy_tools.lock`,
pris SUR UN DESCRIPTEUR pour qu'un échec de verrou ne se confonde pas avec un
échec de commande) et `godot_cloison_arbre` / `godot_cloison_ephemere`
(`XDG_DATA_HOME`). Le `user://` par arbre vit dans `<arbre>/.godot_user`,
ignoré par git et absent de l'archive jouable.

**Onze fichiers convertis**, dont les trois qui comptaient le plus :
`validate_fast.sh` (le plus gros consommateur — il ne se sérialisait avec RIEN),
`.githooks/pre-push` (un moteur par `.gd` modifié, sur un geste quotidien), et
`tools/blackbox_player/server.py` (démarré par `.mcp.json` sans qu'aucune ligne
de shell existe — aucun garde-fou de commande ne peut le voir). Trois attentes
de verrou différentes, chacune justifiée sur place : 5 s pour `pre-push`, 10 s
pour `env_report.sh`, 7200 s pour `setup_godot.sh` qui compile 90 min et
REMPLACE le binaire sous les pieds des moteurs en cours.

**Ce qui ne dépend plus de la discipline d'appel** :
`tests/unit/test_invariants.gd::test_tout_lancement_godot_prend_verrou_et_cloison`.
Prédicat volontairement LARGE : sa première version exigeait un ` --` après le
binaire et RATAIT `tools/capture_ab.sh`, qui lance par tableau d'arguments — la
contre-épreuve a reproduit cette panne. Cycle rouge d'abord tenu : vert →
sabotage (verrou retiré d'un script) → **ÉCHEC nommant le fichier** →
restauration au sha256 → vert.

`CLAUDE.md` enseignait les quatre commandes NUES sans mentionner le lanceur : la
dérive était enseignée, pas subie. Corrigé.

**CE QUI RESTE OUVERT, et pourquoi le ticket ne se ferme pas** :

1. **Blender.** `heavy_tools.lock` est défini comme sérialisant « tout usage
   lourd de Godot **ou Blender** ». Mesuré : **30 fichiers** de `tools/` lancent
   Blender, **4** prennent un verrou. Hors périmètre de la directive R2B.3.1 §2,
   qui parle des points d'entrée Godot — non élargi de moi-même.
2. **La commande tapée à la volée** n'écrit aucun fichier : aucun test ne la
   voit. Un hook `PreToolUse` la couvrirait, au prix de faux positifs sur tout
   fichier qui PARLE du binaire. Décision du propriétaire.
3. **Le `kill` par `pgrep -x godot`** de `tools/blackbox_player/play.sh` : un
   verrou ne protège pas d'un `kill`.
4. **`tools/cave_oracle_batterie.py --verrou`** : opt-out officiel du verrou
   partagé, avec un chemin absolu par défaut.
5. **46 lignes de commandes nues dans 19 fichiers de `docs/`** et le `README`.

Preuves : `evidence/world_v2/v2_3_r2b3_1/iss063/CORRECTIF.md`.

---

## ISS-065 — le moteur retient ses scripts jusqu'à la sortie (`GDScriptCache`) — **LIMITATION MOTEUR, NON BLOQUANTE, SURVEILLÉE**

Ouverte le 2026-08-21 en séparant ISS-059 en deux domaines. Ce ticket n'est pas
un bug du projet et n'a **aucun correctif disponible depuis GDScript** : il
existe pour que la limitation soit *suivie*, pas oubliée — et pour qu'une dérive
redevienne visible.

### Le fait

Charger une `.tscn` épingle les `GDScript` qu'elle attache, plus leurs
`GDScriptNativeClass`. Godot les conserve dans son cache de scripts interne
jusqu'à la fin du processus, et les imprime alors comme « fuite ». Aucune API
GDScript ne purge ce cache : `liberer_caches()` vide des variables `static` du
projet, ce qui est un autre sujet, et n'a par construction aucune prise sur les
tables du moteur.

### L'enveloppe mesurée, pas déduite

Suite complète en `--verbose`, une exécution. La décomposition tombe juste au
dernier objet — c'est ce qui autorise à parler d'attribution plutôt que de
corrélation :

| ligne imprimée par le moteur | compte | décomposition |
|---|---:|---|
| `ObjectDB instances were leaked` | 138 | 74 `GDScript` + 61 `GDScriptNativeClass` + 3 `Shader` |
| `resources still in use` | 74 | 71 `.gd` + 3 `.gdshader` |
| `RID allocations 'DummyShader'` | 3 | les 3 `Shader` ci-dessus |

Il ne reste **ni matériau, ni maillage, ni texture, ni flux audio** : les classes
de RID qui portaient ISS-059 ne sont plus imprimées du tout.

Les trois `Shader` sont des constantes `preload()` de
`scripts/lookdev/hero_shot_lab.gd`, script lui-même épinglé. Une constante vit
dans la table de constantes de son script : tant que le script est retenu, elle
l'est aussi. C'est donc une **conséquence** des 135 autres objets, pas une cause
distincte — et le portail le vérifie mécaniquement en cherchant le `preload`
dans le dépôt, plutôt que de le déclarer dans une table qu'on pourrait mentir.

### Ce qui est refusé, et pourquoi c'est écrit plutôt que caché

Remplacer ces trois `preload()` par des `load()` paresseux retirerait la ligne
`DummyShader` entière du rapport. Ce n'est **pas** fait :

- cela ne rendrait rien vert — les 135 objets de script demeurent ;
- `hero_shot_lab.gd` est un laboratoire de look-dev, hors du chemin critique ;
- retoucher du code légitime pour retrancher des lignes d'un rapport qui reste
  rouge relève du même travers qu'ajuster un seuil pour flatter un verdict.

### Comment la dérive redevient bloquante — et ce que chaque niveau voit VRAIMENT

Une première rédaction de ce paragraphe promettait que la télémétrie « sort en
code 2 dès qu'une classe croît, qu'une extension nouvelle apparaît, ou qu'un
répertoire de provenance inconnu entre dans l'ensemble ». **C'était une
intention, pas un garde-fou** : le mode qui juge ces trois choses n'était appelé
par aucun chemin automatique du dépôt. La revue contradictoire l'a démontré par
un `grep`. Corrigé, et écrit ici tel que le câblage l'exécute :

| niveau | ce qu'il compare | ce qu'il ne peut PAS voir |
|---|---|---|
| `validate_fast` étape 2b, **à chaque passe** | les trois comptes agrégés au chiffre près, et les classes de RID | l'attribution : une substitution à somme nulle passe |
| `validate_release` étape 4b, **avant livraison** | chaque classe, chaque chemin, l'égalité mesure/explication, les provenances | — |

Les deux rendent **code 1** si une classe de RID étrangère apparaît (portail A,
une ressource du projet survit) et **code 2** si l'enveloppe a bougé sans qu'une
classe étrangère apparaisse (télémétrie B, bloquante). La distinction compte :
ajouter six scripts de lieu épingle six `GDScript` de plus, donc déplace les
comptes — signaler cela « une ressource du projet survit » enverrait chercher un
défaut là où il n'y en a pas.

Entériner une nouvelle enveloppe se fait par
`tools/gate_fuite_composition.sh --entériner`, avec une justification écrite
dans `docs/DECISIONS.md`. Ce geste **refuse d'écrire tant que le portail A est
rouge** : sans cette garde, entériner une passe qui fuit gravait la fuite dans
la ligne de base, et la passe suivante repassait au vert. Le contrat lui-même
est **gelé** (`docs/contrats/gel_v2_3_b.sha256`) : le modifier à la main rougit.

### Ce qui lèverait ce ticket

Une API moteur permettant de purger `GDScriptCache`, ou une version de Godot qui
ne compte plus ces objets comme fuite. À réévaluer à chaque montée de version.

Preuves : `evidence/world_v2/v2_3_r2b3_1/iss059/RESIDU_SUITE_COMPLETE.md` et
`evidence/world_v2/v2_3_r2b3_1/cloture/`.

## ISS-066 — `gltf_inspect.py` ne contrôle jamais `COLOR_0` : un asset à couleurs de sommet peut sortir VIDE et être déclaré VALIDE — S3, OUVERT

**Trouvé** le 2026-08-24 par la voie C du lot 1.R, en fabriquant les stèles de
la Porte des fleurs. **Vérifié indépendamment par le lead** en relisant l'outil.

L'exporter glTF de Blender n'écrit `COLOR_0` que si le **matériau consomme
l'attribut** (nœud Color Attribute → Base Color) ; il faut de plus que la couche
soit l'attribut de couleur **actif ET de rendu** — une couche créée par bmesh ne
l'est pas d'office. Sans ces deux conditions, le `.glb` sort avec `POSITION` et
`NORMAL` seulement.

Et l'outil de validation ne le voit pas. `tools/gltf_inspect.py` contrôle
`POSITION` (erreur), `NORMAL` (avertissement), `TEXCOORD_0` (avertissement) et
`JOINTS_0` (erreur si skin attendu). **`COLOR_0` n'apparaît nulle part dans le
fichier.** Un asset dont toute la matière repose sur les couleurs de sommet peut
donc perdre sa matière en silence et repartir avec un `VALIDE`.

C'est le mode de panne que `PROMPT4_METHOD` §2 nomme « le test qui ne peut pas
échouer » : le contrôle est vert parce qu'il ne regarde pas.

**Mesure du cas réel** : le `.glb` des stèles est passé de 80 324 à 128 132
octets une fois les deux conditions réunies ; la face rendue est passée d'une
étendue de luminance de **1 niveau** (aplat) à **31–32 niveaux**.

**Contournement en vigueur** : le producteur d'un asset à couleurs de sommet
vérifie explicitement la présence de `COLOR_0` (taille du `.glb`, ou lecture des
`attributes` du JSON glTF) et ne se fie pas au verdict de l'outil. Côté Godot,
`flower_field_place.gd` force `vertex_color_use_as_albedo` sur une COPIE du
matériau importé — si l'import cessait de le poser, la pierre redeviendrait un
aplat sans qu'aucun test ne rougisse.

**Ce qui lèverait ce ticket** : une ligne d'information « `COLOR_0` : présent /
absent » dans le rapport de l'outil, et un drapeau strict (`--exige-couleurs`)
qui échoue quand l'asset l'exige. Non fait ici : `gltf_inspect.py` est un outil
PARTAGÉ et l'objectif unique du lot 1.R est la corrective visuelle de six lieux.
À traiter dans un lot d'outillage, avec un test rouge d'abord.

## ISS-067 — le visuel des récompenses n'appartient à aucun monde : sphère unie ou coffre de kit saturé, dans QUATRE lieux sur six — S2, OUVERT, hors périmètre du lot 1.R

**Constaté** le 2026-08-24 par la voie C (sphère verte au pied de la grande
stèle du champ, sphère jaune au sanctuaire, coffre à la tour et au cimetière),
**vérifié par le lead sur le code ET sur l'image** :
`scripts/interaction/ingredient_pickup.gd` construit un `SphereMesh` ; et sur
`voie_b/apres/barrow_cemetery_joueur.png`, le coffre est l'objet le plus clair
ET le plus saturé du cadre (orange vif + bleu-gris), d'une famille de teinte
étrangère à toute matière du monde. Le défaut n'appartient donc à aucun lieu :
il appartient au système d'interaction, partagé et antérieur au lot.

**Sévérité relevée de S3 à S2** après mesure de l'étendue : quatre lieux sur
six sont touchés, et le défaut se manifeste au moment exact où le lieu doit
tenir sa promesse — sa récompense.

**Décision de lead du 2026-08-24 (lot 1.R), pour ne pas dépasser le périmètre**
tout en rendant les lieux jugeables : un lieu est autorisé à **habiller son
PROPRE exemplaire** — teinte par surface sur une COPIE du matériau, sans muter
la ressource partagée, exactement la technique déjà employée pour les pierres
de kit. Contraintes dures : l'objet reste lisible comme un contenant ouvrable ;
la récompense, son ancre, son identifiant et la logique d'octroi ne bougent pas.
Ce qu'un lieu ne peut PAS faire, et qui reste dans ce ticket : remplacer le
modèle.

**Pourquoi cela compte au-delà de l'esthétique.** L'addendum de direction
artistique demande que la récompense « paraisse appartenir à l'histoire du lieu,
pas à un coffre posé au milieu ». Une sphère unie flottant dans l'herbe contredit
cette intention **partout à la fois**, et elle le fait dans des captures dont le
sujet est un lieu — au risque qu'une revue impute au lieu un défaut qu'il ne
possède pas.

**En attendant** : le signaler explicitement à toute revue visuelle qui verra ces
captures, pour que le constat aille au bon endroit.

**Ce qui lèverait ce ticket** : un visuel d'ingrédient tiré des modèles réels
(les sept ingrédients ont chacun une forme décrite dans
`VISUAL_ASSET_BIBLE` §17.2), posé au sol et non flottant. Chantier de la passe
« props de gameplay », pas de la corrective d'un lot de lieux.

## ISS-068 — `ASSET_MANIFEST.csv` n'est lu par AUCUN test : un sha256 faux y a vécu, et huit lignes sont malformées — S3, OUVERT

**Trouvé** le 2026-08-24 par le lead, en vérifiant ses propres écritures du lot
1.R plutôt qu'en les croyant.

`docs/assets/ASSET_MANIFEST.csv` est présenté partout comme une **preuve** de
provenance : source, licence, export, empreinte, cotes. Aucun test ne l'ouvre.
`tests/` et `tools/validate_fast.sh` ne contiennent pas une seule occurrence de
son nom. C'est la même famille que ISS-066 — un contrôle vert parce qu'il ne
regarde pas — mais appliquée au document qui **atteste** de la chaîne d'assets.

**Ce que le manque a laissé passer**, mesuré sur les quatre lignes du lot 1.R :

| Ligne | Inscrit | Disque | Verdict |
|---|---|---|---|
| `SM_Watchtower_Ruin` | `8d1b56bf` | `d7c710e9` | **FAUX** |
| `SM_Barrow_Stones` | *(aucun)* | `8ffc48ec` | **manquant** |
| `SM_Shrine_Vestige` | `a48af851` | `a48af851` | juste |
| `SM_FlowerField_Steles` | `fb32ba37` | `fb32ba37` | juste |

`8d1b56bf` ne correspond à aucune version du GLB dans l'histoire : le fichier
n'a qu'un seul blob, posé par `9bb38a1`. La note de la ligne affirmait pourtant
que la valeur avait été recalculée sur l'arbre intégré.

**Deuxième défaut, structurel** : le format n'a **pas de colonne `sha256`**.
L'empreinte vit dans le texte libre de `notes`, sous forme de préfixe à huit
caractères. Une preuve rangée dans un champ de prose ne peut pas être contrôlée
sans expression régulière, et une ligne peut donc n'en porter aucune sans que
rien ne proteste.

**Troisième défaut, préexistant** : sur 204 lignes, **huit portent 20 à 22
colonnes** au lieu de 19 — `Male_Peasant`, `AL_RaiderStates`,
`Superhero_Male_FullBody`, `SK_StormGuardian`, `AwningTent`, `ui_back`,
`ui_error`, `ui_open`. Des virgules non échappées dans des champs libres. Aucun
lecteur ne s'en plaint puisqu'il n'y a pas de lecteur.

**Fermeture partielle déjà en place** : `tools/verifier_manifeste_lot1r.py`
vérifie les quatre lignes du lot 1.R — export présent, préfixe sha256 conforme,
nombre d'octets annoncé conforme — et a été éprouvé par sabotage (sha faussé →
RC 1 nommant l'écart ; restauré → RC 0). Il ne couvre **que ces quatre lignes**.

**Ce qui lèverait ce ticket** : un contrôle du manifeste **entier** dans
`validate_fast.sh`, avec une colonne `sha256` dédiée, la réparation des huit
lignes malformées, et un contrôle négatif qui prouve qu'il rougit. Chantier de
la passe « chaîne d'assets », pas de la corrective d'un lot de lieux — mais il
ne doit pas se perdre : c'est le document dont dépend la revue de licences.

**Piège de méthode né du même contrôle** : la première version du vérificateur
prenait la **première** occurrence de « N octets » dans les notes, donc la
valeur *périmée* que la note cite avant de la corriger. Elle rougissait sur une
ligne juste. Un garde-fou qui rougit à tort finit désactivé dans l'heure
(`PROMPT4_METHOD` §1, règle 2).

## ISS-069 — 24 des 32 commits cités par les preuves du lot V2.3-B n'existent plus : la capture en arbre détaché tue son propre pointeur de provenance — S2, OUVERT

**Trouvé** le 2026-08-24, d'abord par un relecteur du pré-screen, **puis
vérifié indépendamment par le lead** — un balayage de tous les sha40 cités
sous `evidence/world_v2/v2_3_b/`, chacun soumis à `git cat-file -t`.

| Mesure | Valeur |
|---|---:|
| Commits cités par les preuves du lot | **32** |
| Présents dans le dépôt | **8** |
| **Absents** | **24** |
| Parmi les 8 présents, ancêtres de HEAD | 7 |

Les absents ne sont pas des détails d'étape. Ils incluent :

- `dd3de2eb`, `7b31316e`, `0894bd55` — les manifestes des **silhouettes de la
  baseline lot 1**, c'est-à-dire du **corpus que le détecteur R-D3 compare** ;
- `0f94194d` — le verdict R-D3 `PASS` du lot 1.R, déjà repassé `NON VÉRIFIÉ`
  pour cette raison ;
- les manifestes de toutes les itérations des voies A et C (`v1`…`v5`,
  `avant`, `apres2`, `iter2`…).

## Le mécanisme, et pourquoi il est systémique

Les captures sont faites dans un **arbre de travail détaché** (la règle du
dépôt : un worktree par tâche). L'outil de capture inscrit dans son manifeste
le `HEAD` de cet arbre. Ensuite le lead **cueille les fichiers** par
cherry-pick — les PNG et les JSON entrent dans la branche, **le commit de
l'arbre, non**. L'objet finit par disparaître (recréation de conteneur, ou
simple absence de référence).

Résultat : la preuve survit, **son pointeur de provenance meurt**. Le manifeste
continue d'afficher `repo_dirty: false` et un sha d'apparence sérieuse que
personne ne peut vérifier. C'est la forme la plus insidieuse du problème, parce
que le document a l'air plus rigoureux que s'il n'avait rien écrit.

**Piège de méthode associé** : `git rev-parse --short <40 hex>` **abrège sans
vérifier l'existence** et répond de bonne grâce sur un objet absent. Seuls
`git cat-file -t` et `git merge-base --is-ancestor` répondent vraiment.

## Ce qui n'est PAS remis en cause

Les images elles-mêmes. Elles sont committées, leur contenu est intact, et les
mesures faites dessus restent des mesures. Ce qui est perdu, c'est la capacité
de **relier une image à l'état de code exact** qui l'a produite — donc de
rejouer une capture à l'identique, ou de prouver qu'une preuve n'a pas été
prise sur un arbre différent de celui qu'elle annonce.

## Déjà corrigé pour le lot 1.R

Les manifestes de `evidence/world_v2/v2_3_b/lot1r/final/` citent `7c58573a`,
qui **est** un ancêtre de HEAD : la passe a été lancée dans le dépôt principal,
sur un arbre committé et poussé. C'est la conduite à généraliser.

## Ce qui lèverait ce ticket

1. Faire échouer bruyamment tout outil de capture dont le `HEAD` n'est **pas
   un ancêtre d'une branche poussée** — un manifeste ne doit pas pouvoir
   naître avec un pointeur mort.
2. Un contrôle, dans `validate_fast.sh`, qui balaye `evidence/` et rougit sur
   tout sha40 introuvable — avec la liste exacte.
3. Décider du sort des 24 pointeurs morts : soit recapturer sur HEAD, soit les
   marquer `PROVENANCE PERDUE` dans leur manifeste. **Ne pas les laisser
   afficher un sha invérifiable.**

Chantier de la chaîne de preuve, pas de la corrective d'un lot de lieux — mais
il touche la crédibilité de tout le dossier, d'où S2.

## ISS-070 — Sanctuaire : la fenêtre du seuil manquait la marge de capsule d'un centimètre (0,89 m mesuré, 0,90 exigé) — S3, **FERMÉ le 2026-08-25**

**Trouvé** le 2026-08-25, à l'intégration du LOT 1.R.1, par la sonde
`tools/godot/probe_sanctuaire.gd` une fois ses deux défauts d'instrument
corrigés (axe pré-rotation, puis marche mesurée sur le collider de sa propre
destination — l'en-tête de la sonde porte les deux récits).

- **Mesure** : entre les deux montants du seuil (nef recomposée R3, colliders
  déclarés `Sanctuaire_montant_ouest`/`_est`), à la station z de nef −3,20 et
  à 0,55 m du sol, la fenêtre libre totale vaut **0,89 m** (0,34 + 0,55). Le
  critère de la sonde est diamètre de capsule + marge : 0,80 + 2 × 0,05 =
  **0,90 m**. Journal : `evidence/world_v2/v2_3_b/lot1r1/sondes/`.
- **Ce que ça veut dire, ni plus ni moins** : le diamètre NU de la capsule
  (0,80 m) passe avec 9 cm de jeu total ; c'est la marge de robustesse de la
  sonde qui manque, d'un centimètre, au point le plus étroit du seuil. Aucun
  blocage constaté ; aucun parcours réel joué non plus (la franchissabilité
  humaine du seuil reste NON VÉRIFIÉE, comme l'avait déclaré la voie B).
- **Pourquoi rien n'a été « corrigé »** : la voie B est close, la géométrie du
  seuil est un choix de composition (« deux montants franchement inégaux »),
  et élargir la marge ou déplacer une pierre d'un centimètre pour verdir une
  sonde serait exactement le déplacement de seuil que le dépôt s'interdit. Le
  FAIL reste au journal comme mesure.
- **Prochaine action si le verdict visuel rouvre le sanctuaire** : écarter le
  montant le moins chargé de ~2 cm dans le générateur, ré-exporter, rejouer la
  sonde — et seulement dans ce cadre-là.

### FERMETURE — LOT 1.R.2, le 2026-08-25

Le verdict visuel a rouvert le sanctuaire (rejet Codex : « le seuil et l'axe
rituel ne sont pas immédiatement lisibles »), et la corrective de composition
ouvrait le seuil de toute façon : la condition posée ci-dessus est remplie.

- **Mesure finale : fenêtre libre 1,31 m** à z de nef −3,20, contre 0,89 m,
  pour un critère inchangé de 0,90 m. Journal :
  `evidence/world_v2/v2_3_b/lot1r2/sanctuaire/sondes/probe_APRES.log`
  (`VERDICT : PASS`, RC 0) ; l'état rouge d'avant est archivé à côté, dans
  `probe_AVANT_ROUGE.log`, pour que la correction soit comparable.
- **Ce qui a changé** : l'entraxe des montants passe de 1,20 à 1,62 en x de
  nef (1,863 m réels). Pas 2 cm comme envisagé — le calcul de la voie B se
  faisait sur le CÔTÉ des colliders et non sur leur demi-largeur EFFECTIVE
  une fois tournés (24° et −58°), ce qui explique de rater la cible d'un
  centimètre : la largeur utile vaut 0,392 et 0,357 m, pas 0,32 et 0,25.
- **Aucun seuil n'a été déplacé** pour obtenir ce vert. `MARCHE_MAX`,
  `CAPSULE_R` et le plafond d'identité sont ceux de la voie B, et la sonde a
  GAGNÉ un contrôle : §2c balaie la vraie capsule du héros (Ø 0,80 m) à
  travers le seuil dans les deux sens de traversée — 100 % du trajet sans
  contact à l'entrée comme à la sortie. Un rayon est infiniment fin ; on ne
  referme pas un défaut d'un centimètre avec le seul instrument qui l'a
  mesuré.
- **Reste NON VÉRIFIÉ** : la franchissabilité HUMAINE du seuil. Aucune
  manette, aucun écran ici — cette part-là relève de
  `docs/MANUAL_VALIDATION.md` et n'a pas bougé.

## ISS-071 — La build EXPORTÉE ne résout aucun modèle indexé par balayage de répertoire : 1 094 placements manqués, 110 modèles absents — S1, OUVERT

**Trouvé** le 2026-08-26 par le test de fumée §4 de la clôture LOT 1.R.2, sur
l'export Linux autonome du SHA validé `919511d`. **Aucune suite du dépôt ne
pouvait le voir** : le défaut n'existe QUE dans une build exportée, et toutes
nos suites tournent en exécution éditeur. C'est l'angle mort exact que ce test
de fumée existait pour couvrir, et il l'a couvert au premier passage.

- **Mesure**, journal produit par le processus testé lui-même
  (`evidence/world_v2/v2_3_b/lot1r2/cloture/fumee_build_exportee/session1_stdout.log`,
  2 222 lignes) :

  | | build exportée | exécution éditeur |
  |---|---:|---:|
  | `[world_v2] kit : modèle inconnu` | 457 | 0 |
  | `modèle végétal introuvable` | 631 | 0 |
  | `[flower_field] modèle inconnu` | 4 | 0 |
  | `[flower_field] modèle de dalle inconnu` | 2 | 0 |
  | **appels de placement manqués** | **1 094** | **0** |
  | modèles distincts | **110** | 0 |

  Une cellule de MultiMesh végétal dont le modèle manque est sautée ENTIÈRE —
  `_emit_model_cells()` rend `false` sans rien émettre — donc le nombre
  d'objets réellement absents à l'écran est très supérieur à 1 094. Inventaire
  nominatif : `…/fumee_build_exportee/inventaire_modeles_absents.txt`.

- **Cause, PROUVÉE par un laboratoire** (`…/fumee_build_exportee/lab_dir_access/`),
  pas déduite. Deux fonctions indexent les modèles en balayant un répertoire et
  en gardant les noms qui finissent par `.glb` ou `.gltf` :
  `WorldV2PlaceKit.scene_for()` et `AssetRegistry.model()` — et la seconde sert
  de recours à la première, ce qui explique qu'aucune n'ait rattrapé l'autre.

  Projet minimal, deux modèles importés, exporté avec les mêmes templates
  officiels 4.7.1 :

  ```
  --- BUILD EXPORTÉE ---            --- MÊME SONDE, ÉDITEUR ---
  get_files() rend 2 entree(s)      get_files() rend 5 entree(s)
    [Floor_WoodLight.gltf.import]     [Floor_WoodLight.bin]
    [SM_Barrow_Stones.glb.import]     [Floor_WoodLight.gltf]
                                      [Floor_WoodLight.gltf.import]
                                      [SM_Barrow_Stones.glb]
                                      [SM_Barrow_Stones.glb.import]
  load(gltf) = true                 load(gltf) = true
  ```

  **Le fichier source n'est pas empaqueté du tout** : seul son fichier de
  métadonnées `<nom>.gltf.import` entre dans le PCK, le maillage vivant sous
  `res://.godot/imported/<nom>.gltf-<md5>.scn`. Un balayage qui teste `.glb` ou
  `.gltf` ne trouve donc jamais rien, tandis que `load()` sur un chemin
  explicite réussit : la redirection est transparente pour un chemin, pas pour
  un listage.

  **Hypothèse fausse corrigée en route** : j'avais d'abord écrit que le PCK
  rangeait la ressource sous `<nom>.gltf.remap`. Le binaire porte bien 343
  entrées `.remap` — mais pour des `.tres` et des `.gd`, aucune pour un `.gltf`
  ni un `.glb`. Plausible, et faux ; c'est le lab qui a tranché, pas la lecture.

- **Portée exacte**, ni exagérée ni minimisée
  (`…/fumee_build_exportee/PORTEE_DU_DEFAUT.md`) :
  - `preload()` / `load("res://…")` **fonctionnent**. Les six lieux gelés
    chargent donc bien leur asset propre ; aucune erreur de leur part au journal.
  - Le monde se monte entièrement : 64 chunks, 4 régions de navigation,
    **15 scènes posées**, terrain/herbe/falaises/héros dessinés, caméra et
    déplacement réactifs (mesurés : RMSE 0,1482 à la souris, 0,0549 en marche).
  - Mais **les six lieux gelés appellent tous le kit** (7, 7, 8, 2, 6 et 4
    sites d'appel), et le champ des mille fleurs perd en plus ses modèles de
    fleurs. Leur masse est là, leur habillage non : la build ne montrerait pas
    les six lieux tels qu'ils ont été validés sur captures éditeur.

- **Ancienneté** : ce n'est PAS une régression du lot 1.R.2. Ni
  `world_v2_place_kit.gd` ni `asset_registry.gd` n'appartiennent aux 46
  fichiers gelés ; le balayage existe depuis `5428e96` (V2.3-A) pour le premier
  et depuis le « Lot 9 » pour le second. **La build déjà publiée
  `world-v2-playtest-lot1-d78f007` a été téléchargée depuis GitHub et lancée
  ici : sur 145 s d'observation, 534 `modèle inconnu` et 631 `modèle végétal
  introuvable`.** Les comptes ne se comparent pas au chiffre près d'une build à
  l'autre — durées et séquences diffèrent — mais les deux sont très loin de
  zéro. Istvan joue donc, depuis au moins le 24 août, un monde privé de ces
  modèles.

- **Conséquence** : aucune Release LOT 1.R.2 n'a été publiée. La clôture est
  `PARTIAL`.

- **Pistes de correction, NON APPLIQUÉES** — elles sortent du périmètre de
  cette clôture et touchent la résolution d'assets de tout le jeu :
  1. accepter aussi le suffixe `.import` au balayage
     (`file.trim_suffix(".import")` avant le test d'extension), dans les **deux**
     fonctions à la fois — corriger une seule laisserait l'autre en recours muet ;
  2. ou remplacer le balayage par un index construit à l'import et versionné,
     qui ne dépend plus de la façon dont le moteur empaquette ses fichiers.

  Dans les deux cas le correctif doit être **ROUGE D'ABORD**, et le rouge n'est
  atteignable que sur une build exportée : il faut donc d'abord un portail qui
  exporte, lance et compte ces lignes. Sans lui, le même angle mort se
  refermera. Les deux instruments écrits pour cette clôture — `fumee.py` et
  `lab_dir_access/` — sont archivés à côté de la preuve et sont le point de
  départ de ce portail.

## ISS-072 — L'horloge du moteur est décrochée du temps mural dans ce conteneur (facteur 17 à 76) : aucune mesure temporelle n'y est possible — S2, OUVERT

**Reproduction.** Lancer la build exportée sous Xvfb + Mesa llvmpipe, presser
`F3` pour démarrer l'enregistrement DevMode, ne rien faire pendant 120 s
murales, presser `F3`. Compter les événements `position` du journal :
`DevMode._process()` en écrit un par seconde de `delta` accumulé.

**Attendu** : ~120 événements. **Observé** : **7**. Rapport 0,058.

| Exécution | Mural | `position` | Rapport | F4 |
|---|---:|---:|---:|---:|
| Campagne de saut complète | 152 s | 2 | 0,013 | 111 |
| Sonde dédiée, aucun F4 | 120 s | 7 | 0,058 | 0 |

**Ce qui rend le défaut coûteux, c'est qu'il est INTERNE ET SILENCIEUX.** Le
moteur annonce dans le même temps **7,3–7,7 FPS** et aucune image au-delà de
150 ms — chiffres parfaitement rassurants, et incompatibles avec les
précédents. Rien n'avertit ; il faut aller compter les échantillons.

**Hypothèse réfutée**, à ne pas reposer : « c'est la relecture GPU de
`capture_screenshot()` dans `mark()` ». La sonde ci-dessus ne presse **aucun**
`F4` et mesure quand même 0,058.

**Conséquence opérationnelle.** Tout protocole qui envoie des consignes en
temps mural et attend une réponse à un instant donné du jeu est caduc ici :
une phase de repos de 2,3 s murales vaut quelques centièmes de seconde de jeu.
C'est ce qui a fermé S1.1 en `BLOQUÉ` — un contrôle négatif rendant 6
marqueurs élevés sur 23 sans le moindre appui sur Espace.

**Portée.** Ce défaut appartient à l'ENVIRONNEMENT, pas au jeu. Il ne dit rien
de la gravité, du saut ni de la fluidité sur une vraie machine. Ne pas le
citer comme un défaut du produit.

**Contournement.** Aucun connu depuis ce conteneur. `CLAUDE.md` l'écrivait
déjà pour le rendu : *« utilisable pour la régression visuelle, jamais pour
une mesure »* — la règle vaut aussi pour le temps. Les vérifications
temporelles passent par `docs/MANUAL_VALIDATION.md`.

**Garde-fou posé.** `tools/fumee_gravite.py` publie désormais un point
`cohérence de l'horloge du moteur`, évalué **avant** tout critère temporel et
imprimé même quand le reste est vert. Hors de la bande 0,5–2,0, le verdict
d'ensemble est `BLOQUÉ`.

Preuves : `evidence/world_v2/v2_3_b/iss071/s1_1_gravite/`.

## ISS-073 — La boucle est OUVERTE dans le build livré : donjon, boss et victoire inatteignables depuis « Nouvelle partie » — S1, CORRIGÉ EN ÉDITEUR, EN ATTENTE DE LA BUILD

**Découvert** le 2026-08-27 par l'audit des 18 domaines, **vérifié à la main**
avant publication. Douze des dix-huit audits ont buté dessus depuis leur propre
angle sans qu'aucun voie qu'il s'agissait du même défaut.

**Reproduction.** Lancer le jeu, « Nouvelle partie », chercher l'entrée du
donjon. Elle n'existe pas.

**Mesures.**

| Vérification | Résultat |
|---|---|
| `grep -rn "SceneDoor" scripts/world_v2/ scenes/world_v2/` | **aucune occurrence** |
| `scripts/ui/main_menu.gd:14` | `WORLD_SCENE = "res://scenes/world_v2/WorldV2.tscn"` |
| Retours pointant encore vers `ValleyWorld.tscn` (V1) | **4** |

Les quatre : `scripts/ui/victory_screen.gd:18` · `scripts/ui/gameplay_shell.gd:22`
· `scripts/world/citadel_vestibule.gd:170` · `scripts/tools/reward_anchor_shot.gd:20`.

Le seuil `dungeon_gate` existe mais n'est qu'un `Node3D` nu posé par
`world_v2_markers_builder.gd`. La seule porte vers `CitadelVestibule.tscn` vit
dans `scripts/world/valley_terrain.gd`, monde V1 que le menu n'ouvre plus.

**Gravité.** C'est une rupture de la priorité n°2 du `CLAUDE.md` — « boucle
complète jusqu'à la victoire ». Et c'est un défaut qui **invalide les mesures
des autres** : aucune durée de campagne n'est mesurable tant qu'il tient, donc
tout dimensionnement d'heures repose sur du vide.

**Pourquoi aucun test ne l'a vu.** Les suites `tests/world_v2/` vérifient
abondamment le monde V2 *pour lui-même* — terrain, routes, hydrologie,
traversée physique — mais **aucune ne franchit le seuil**. Le contrat de
traversée s'arrête au marqueur. C'est le mode de panne d'ISS-018 dans un autre
domaine : des tests verts qui mesurent une grandeur voisine de celle qui
compte.

**Correction attendue** : une `SceneDoor` vers le donjon dans World V2, les
quatre constantes redressées, et **un test qui franchit réellement le seuil** —
écrit rouge d'abord, sinon le défaut reviendra sans bruit.

Coût estimé : faible. Effet : total. C'est l'étape 0 du chemin critique
(`docs/V2_LONG_GAME_ROADMAP.md`).

### Correction du 2026-08-28 — `03e8b9d`, `b2e5bb1`

**Ce qui a été fait.** Une vraie `SceneDoor` au seuil §3.3 `(0, 34, -210)`
(`scripts/world_v2/world_v2_dungeon_door.gd`), une ancre de retour 4 m devant
elle, la consommation de `pending_spawn` dans `WorldV2Root` avec priorité au
retour de transition, et deux des quatre références V1 redressées.

**Deux des quatre n'étaient PAS des coupables**, et le dire compte autant que
la correction :

| Référence | Verdict |
|---|---|
| `victory_screen.gd::VALLEY_SCENE` | chemin de campagne → redressé vers World V2 |
| `citadel_vestibule.gd::exit_door.target_scene` | chemin de campagne → redressé |
| `gameplay_shell.gd::world_scene_path` | `@export` dont `WorldV2.tscn:87` surcharge DÉJÀ la valeur ; le changer casserait le « Réessayer » du monde V1 — **laissé intact** |
| `reward_anchor_shot.gd::VALLEY` | outil de capture du monde V1, jamais atteint en jeu — hors sujet |

Ma première version du test comptait `gameplay_shell` comme coupable : c'était
un faux positif, corrigé et documenté dans le test lui-même.

**Preuve.** `tests/world_v2/test_world_v2_iss073_boucle.gd` (5 cas) et
`tests/world_v2/test_world_v2_iss073_chaine.gd` (4 cas), écrits ROUGES d'abord
— 8 échecs sur l'arbre d'avant. Ils marchent réellement jusqu'au seuil et
appuient sur la touche d'interaction ; appeler `SceneDoor.interact()` ou
`SceneFlow.go_to()` leur est explicitement interdit. Cinq sabotages joués,
dont un qui reproduit le symptôme exact : retour mesuré en `(0, 170)` — le
spawn initial — au lieu de `(0, -210)`.

**Un quatrième chemin de retour, trouvé après coup.** Mourir dans le vestibule
ramenait aussi dans la vallée V1 : « Réessayer » recharge
`GameplayShell.world_scene_path`, dont la valeur par défaut est V1, et le
vestibule ne la surchargeait pas — contrairement aux six salles du donjon et
à l'arène. Mon premier portail ne l'a pas vu parce qu'il n'énumérait que les
`SceneDoor`. Corrigé en `0600251`, avec le cas rouge qui a nommé la coupable
avant la correction.

**Pourquoi l'issue n'est pas encore FERMÉE.** Ces tests tournent dans
l'éditeur headless. ISS-071 a montré ce que vaut cet angle-là : un défaut qui
n'existe QUE dans une build exportée. La fermeture attend donc deux choses —
la boucle rejouée dans la build exportée, et l'essai réel d'Istvan sur la
candidate. Détail : `evidence/world_v2/iss073/README.md`.

## ISS-074 — Le monde livré ne contient AUCUN adversaire, et son vide est protégé par un contrat de test — S2, OUVERT

Le conteneur `Encounters` est exigé par `scripts/world_v2/world_v2_root.gd:23`
puis **jamais rempli**. Aucune référence à `EnemyBase`, `CombatCoordinator` ou
`scenes/enemies/` sous `scripts/world_v2/`. Les douze à treize instances
d'ennemis du dépôt vivent **toutes dans le monde V1**.

Et le vide est **verrouillé** : `tests/world_v2/test_world_v2_places_contract.gd:251`
compte tout acteur comme un « acteur prématuré », donc un écart. Le contrat
était juste quand les lieux étaient des coquilles ; il est devenu un garde-fou
qui empêche le peuplement.

**Ce n'est pas un bug du contrat, c'est un contrat qui a survécu à sa raison.**
Le remplacer par un **budget d'IA** — un plafond d'agents actifs, pas une
interdiction — est la correction, et elle doit être faite avant le peuplement,
pas pendant.

Conséquence de second ordre relevée par l'audit : aucun respawn, aucun
`LootComponent`, aucune `LootTableDefinition`. Tuer ne rapporte rien, et le
contenu de combat d'une partie est fini et consommable une fois.

## ISS-075 — Zéro localisation, et la dette croît à chaque phrase écrite — S3, OUVERT

Mesuré : **zéro appel `tr(` réel** dans `scripts/` (le motif `tr(` seul matche
`str(` — vérifié avec une limite de mot), **aucun** fichier de traduction,
**aucune** section d'internationalisation dans `project.godot`.

Toute la fiction du jeu tient aujourd'hui dans quatre fragments de deux phrases
codés en dur dans `DiscoveryRewards.PLAN`.

**Pourquoi c'est urgent alors que le volume est minuscule.** C'est précisément
parce qu'il est minuscule. Externaliser quatre fragments coûte une heure ;
externaliser les 30 000 à 80 000 mots qu'exigerait une campagne de 30-50 h
coûte plusieurs fois le prix de leur écriture. **La localisation ne se rattrape
pas** : elle se pose avant d'écrire, ou elle se paie deux fois.
