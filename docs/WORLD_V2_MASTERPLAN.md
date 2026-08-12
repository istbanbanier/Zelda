# WORLD V2 — CARTE DIRECTRICE DE LA VALLÉE DE NÉRIS RECONSTRUITE

**Statut : VIVANT** · Phase V2.0 · Base V1 : `58d4996` (`claude/full-world-visual-finish`)
Données d'implantation faisant foi : `resources/world_v2/world_v2_layout.json` —
ce document explique les **relations** ; le JSON porte les **nombres**. En cas de
désaccord entre les deux, corriger le JSON puis ce document, dans cet ordre.

Ce plan décrit la nouvelle vallée AVANT sa construction (V2.1+). Il ne remplace
aucun cahier des charges : `MASTER_SPEC` §3 fixe la composition North Star,
`PROMPT2_SPEC` §6 les trois routes, `VISUAL_ASSET_BIBLE` §6 la géologie. Ce
document les **applique** à une topographie unique, avec les 31 lieux existants.

---

## 0. Pourquoi une reconstruction, et ce qu'elle ne touche pas

`docs/WORLD_ATLAS.md` (2026-08-06) a établi le diagnostic : le terrain V1 est un
plan plat portant des dalles rectangulaires (`_slab()`), la rivière est une bande
droite, la citadelle un proxy de boîtes, le centre et les angles de la carte sont
vides (ISS-045, ISS-039, ISS-032). Les passes visuelles d'août ont amélioré les
silhouettes sans changer cette nature : **on a peint un graybox au lieu de le
remplacer**.

World V2 reconstruit le **contenu spatial et visuel**. Elle ne touche pas aux
systèmes protégés (déplacement, combat, IA, inventaire, cuisine, sauvegarde,
Bracelet, graphe électrique, boss, UI — la matrice exacte est dans
`docs/WORLD_V2_SYSTEM_CONTRACTS.md`). La V1 reste lançable et servie par le flux
normal jusqu'au gate final V2.9.

## 1. Invariants d'implantation (hérités, non négociables)

Les ancres relationnelles de `MASTER_SPEC` §3.3 sont conservées à l'identique —
elles portent la composition North Star déjà validée par fenêtres de projection
(`HeroShotLab`, Cycle 3) :

| Ancre | Position | Source |
|---|---|---|
| Spawn (crête de départ) | `(0, 24, 170)`, regard vers −Z | §3.3 — la V1 a dérivé à `(0, 32.3, 146)` sur mesure de capture ; V2 repart de l'ancre §3.3 et retunera pareillement SUR CAPTURE, la relation seule est invariante |
| Camp | `(45, 6, 65)` | §3.3 |
| Pylône | `(115, 18, −25)` | §3.3 |
| Rivière | S autour de `Z = 10` | §3.3 |
| Falaise d'apprentissage | ouest, `X = −80` à `−145` | §3.3 |
| Forêt claire | sud-est du centre | §3.3 |
| Entrée du donjon | `(0, 34, −210)` | §3.3 |
| Montagnes non jouables | 550–1 200 m (visuel) | §3.3 |

Emprise : **512 × 512 m** centrés, `1 unité = 1 m`, `Y` vertical, `+Z` = sud
(côté spawn), `−Z` = nord (côté citadelle), `−X` = ouest (soleil). Zone jouable
bornée par un anneau de relief crédible (rayon utile ≈ 235 m, anneau frontalier
jusqu'à ≈ 292 m) — aucune paroi invisible exposée.

Ce qui CHANGE : tout le reste. Le sol devient un vrai relief continu, la rivière
un vrai bassin versant, le centre et les angles reçoivent une identité, et les
31 lieux sont recomposés le long de trois routes qui se croisent.

## 2. Les grandes masses (macro, 80–500 m)

Lecture nord-sud, du spawn vers la citadelle :

1. **Le balcon sud** — la crête de départ (y ≈ 24) court d'est en ouest sur le
   bord sud ; elle domine toute la vallée et se raccorde à l'anneau frontalier.
   Sa rupture de pente (z ≈ 150) est la ligne d'ouverture North Star : pente
   continue ≈ 8° côté vallée (leçon Cycle 3 : un bord de plateau plat masque
   tout), épaulements rocheux encadrant le cadre à gauche et à droite.
2. **La cuvette sud** — deux plaines vallonnées (y 2–10, buttes de 1,5–3 m) de
   part et d'autre de la descente : Prairie des Mille Fleurs à l'ouest, Bois du
   Levant à l'est, séparées par la sente du camp sur sa terrasse (y = 6).
3. **Le sillon de la rivière** — le Val de Néris entaille la bande `Z 10 ± 30`
   d'est en ouest (lit y ≈ −1,5, berges 0–3), puis tourne au nord vers `X ≈ −25`
   et descend en bras nord jusqu'au lac de l'Orage (pied des ruines centrales).
   C'est le seul creux continu de la carte : il se lit de la crête comme un
   ruban turquoise en S (§3.2).
4. **Les épaules** — falaises du Couchant à l'ouest (parois y 2 → 26, LA grande
   paroi escaladable) ; Hauteurs de l'Orient à l'est (terrasses y 14–30 portant
   pylône, belvédère, mine, source de la rivière à la Chute du Voile).
5. **La steppe nord** — plaine du Nord (y 2–8) montant en contreforts (y 10–18)
   vers le plateau du donjon ; les Ruines du Cœur occupent le centre exact de la
   carte (terrasses géométriques y 4–8) — le centre n'est plus vide.
6. **La Marche de l'Orage** — couloir nord-centre assombri par le nuage : lac,
   bois courbé, rampe processionnelle (`(0,2,−110)` → `(0,34,−165)`), plateau du
   donjon (y = 34) et citadelle. Végétation raréfiée, traces de foudre.
7. **L'anneau frontalier** — crêtes et cols (y 40–70) fermant les quatre côtés,
   avec les montagnes lointaines au-delà (silhouettes non jouables).

Trois hauteurs réellement exploitables (§4.1) : le sillon (−1,5–3), les plaines
et terrasses (2–10), les épaules et plateaux (14–34).

## 3. Bassin versant et rivière

La rivière cesse d'être un décor : elle a une source, des affluents, un sens.

- **Source** : la Chute du Voile (`veil_falls`), cascade tombant des Hauteurs de
  l'Orient (y ≈ 20) au bord est du Bois du Levant.
- **Cours amont** : d'est en ouest dans le sillon `Z 10 ± 30`, en S (deux
  inflexions minimum — contrat déjà testé par le HeroShotLab), trois gués
  francs (est/route du camp, centre/pont de pierre, ouest/village).
- **Affluent ouest** : la Source aux reflets (`turquoise_spring`) descend des
  falaises du Couchant et rejoint le cours principal au village de la rivière.
- **Coude nord** : à `X ≈ −25`, le cours tourne vers −Z (bras nord), longe les
  Ruines du Cœur — le pont magnétique (site systémique P2-4) le franchit.
- **Exutoire** : le lac de l'Orage au pied de la Marche (y ≈ 0, autour de
  `(−15, −140)`), eau dormante conductrice sous le nuage — il termine le ruban
  visuel qui guide vers le donjon (§7.6) et disparaît en chute souterraine dans
  l'anneau frontalier.

Règles de construction (V2.1+) : berges à épaulement (leçon ISS-032 : la largeur
utile n'est pas la largeur du tablier), plages basses alternant avec rochers et
roseaux, aucune section rectiligne de plus de ~40 m, profondeur lisible aux gués.

## 4. Les régions

Onze régions. Un lieu de FRONTIÈRE peut être mentionné dans chaque région
qu'il touche, mais il n'appartient qu'à UNE région dans
`world_v2_layout.json` — le JSON fait foi, la mention croisée n'est pas une
contradiction. Pour chacune : identité, fonction, altitude, silhouette, repère,
transitions, densité, ennemis, POI, récompenses, caméra, risques. Les bornes,
positions et ancres de sauvegarde exactes vivent dans `world_v2_layout.json`
(`regions[]`).

### R01 — Crête de l'Aube (départ)

- **Identité** : balcon herbeux fleuri dominant toute la vallée ; le lieu le plus
  soigné du jeu (60 premières secondes, §0.8).
- **Fonction** : ouverture North Star, apprentissage marche/course/saut, Pulse.
- **Altitude** : plateau 22–26, rupture à z ≈ 150, descente continue ≈ 8°.
- **Silhouette** : crête en selle entre deux épaulements rocheux ; herbes longues
  au vent en premier plan.
- **Repère principal** : la citadelle plein nord ; fumée du camp à mi-droite.
- **Transitions** : entrée = début de partie (aucune) ; sorties = descente en S
  vers le gué est (route de la rivière) et sente est vers le camp.
- **Densité** : végétale forte (phrases d'herbe §7.4), zéro combat, 1 coffre
  d'apprentissage à l'écart du cadre d'ouverture.
- **Ennemis** : aucun.
- **POI** : aucun — la crête reste vierge ; la curiosité part vers le bas.
- **Caméra** : `VistaCamera_Hero01` (§3.1) — fenêtres §1.1 tenues ; aucun
  objet statique à moins de 4 m de l'objectif (leçon caméra 5, passe 3).
- **Risques** : refaire un bord de plateau qui masque la vallée (Cycle 3 v0) ;
  sur-densité d'herbe qui bouche le cadre.

### R02 — Prairie des Mille Fleurs (sud-ouest)

- **Identité** : prairie vallonnée ouverte, la respiration du jeu.
- **Fonction** : récolte, apprentissage de la carte, premier choix de route.
- **Altitude** : 3–10, buttes marchables 1,5–3 m.
- **Silhouette** : houle herbeuse ponctuée d'arbres isolés ; l'Arbre foudroyé
  marque l'horizon ouest.
- **Repère** : l'Arbre foudroyé (`thunderstruck_tree`) et ses repousses.
- **Transitions** : depuis la descente de crête (S) ; vers le village par le gué
  ouest, vers les falaises par la Source.
- **Densité** : fleurs en phrases, clairières vides de 2–8 m ; faible en props.
- **Ennemis** : patrouille braise légère en lisière (tutoriel vivant).
- **POI** : `flower_field`, `abandoned_farm`, `thunderstruck_tree`.
- **Récompenses** : herbe d'endurance, fruit de soin, savoir (épice).
- **Caméra** : plans larges sans occlusion ; aucun couloir.
- **Risques** : scatter uniforme (§7.17) ; le vide qui redevient du remplissage.

### R03 — Val de Néris (la rivière)

- **Identité** : le sillon frais et sûr ; eau turquoise, roseaux, pierres humides.
- **Fonction** : route 1 (sûre), conductivité/eau, guidage du regard vers le nord.
- **Altitude** : lit −1,5 ; berges 0–3.
- **Silhouette** : ruban en S entaillé, ponts et gués en accents horizontaux.
- **Repère** : l'Arche de pierre (`stone_bridge`) au gué central.
- **Transitions** : gué est (crête/camp), gué ouest (prairie/village), bras nord
  (ruines → lac de l'Orage).
- **Densité** : forte aux berges (roseaux, galets), calme sur l'eau.
- **Ennemis** : aucun dans le lit ; embuscades azur possibles aux gués nord.
- **POI** : `riverside_village`, `stone_bridge` ; en frontière : `ancient_aqueduct`
  (au coude nord — séparé du pont de pierre, qui reste au gué central : en V1
  les deux étaient à 2 m l'un de l'autre ; région JSON : r09) et
  `waterfall_cave` (derrière la cascade de l'affluent ouest ; région JSON :
  r04).
- **Sites systémiques** : `conductive_basin` (bassin conducteur, école Arc Link),
  `magnetic_bridge` (pont magnétique, sur le bras nord).
- **Récompenses** : épée usée, fragments d'histoire, champignon.
- **Caméra** : berges dégagées à hauteur d'épaule ; jamais de paroi à < 1 m du
  bras de caméra dans le lit.
- **Risques** : couture berge/plaine (épaulements obligatoires) ; eau chargée
  illisible (langage §8.2 de la bible).

### R04 — Falaises du Couchant (ouest)

- **Identité** : muraille ocre stratifiée, LA paroi d'apprentissage (§3.3).
- **Fonction** : école d'escalade et d'endurance, verticalité, récompense au
  sommet (autel de terre — école Ground).
- **Altitude** : pied 2–4, corniches étagées, sommet 24–26.
- **Silhouette** : strates horizontales cassées de diagonales ; la Tour de guet
  en dent sur la crête.
- **Repère** : la Tour de guet (`watchtower_ruin`), visible de la prairie.
- **Transitions** : pied par la prairie ou le village ; sommet vers le
  Passage dérobé (angle SO) et regard de retour sur toute la cuvette sud.
- **Densité** : minérale ; végétation de fissure sur les routes sûres (§6.4).
- **Ennemis** : aucun sur la paroi ; poste braise au pied nord.
- **POI** : `watchtower_ruin`, `mining_post`, `turquoise_spring`,
  `waterfall_cave` (entrée basse), `hidden_passage` (angle SO).
- **Site systémique** : `earth_altar` (sommet, sanctuaire de la falaise).
- **Récompenses** : flèches ×2, fruit de soin, champignon, coffre du passage.
- **Caméra** : mode Climb — dégagement dorsal ≥ 5 m sur toute la paroi ;
  corniches de repos cadrables.
- **Risques** : surplombs non signalés `unclimbable` ; l'exclusion de la paroi
  d'escalade est TESTÉE en V1 (`test_mesas_wear_talus`) et doit le rester en V2.

### R05 — Terrasse du Camp

- **Identité** : clairière fortifiée à trois pôles (repos / stockage / garde),
  triangle testé en V1 (`test_camp_composes_three_activity_poles`).
- **Fonction** : première vraie rencontre (3 approches §5.6 P2), cuisine,
  checkpoint `camp`.
- **Altitude** : terrasse 6, talus vers la plaine 2.
- **Silhouette** : basse et horizontale, rompue par le feu et deux bannières.
- **Repère** : la colonne de fumée (voile, pas pilier — contraste mesuré V1).
- **Transitions** : sente de la crête (S), lisière du Bois (E), gué est (O),
  steppe nord (N).
- **Densité** : props de camp concentrés aux trois pôles, vide central.
- **Ennemis** : la garnison braise du camp (rencontre scénarisée à 3 approches).
- **POI** : aucun en propre — le camp est un espace de jeu, les camps braise
  du Bois (`ember_raider_camps`) restent le territoire ennemi dédié.
- **Récompenses** : coffre du camp, feu de cuisine, arme au râtelier.
- **Caméra** : approche frontale, infiltration par herbes, hauteur par le
  talus est — les trois lisibles sans couloir de caméra.
- **Risques** : re-poser un doublon de foyer (défaut V1 corrigé) ; props qui
  bouchent la fuite.

### R06 — Bois du Levant (forêt claire sud-est)

- **Identité** : forêt claire en bosquets, lisières et clairières — jamais un
  mur d'arbres (lignes de vue 15–40 m, §7.2 bible).
- **Fonction** : route 3 (combat/infiltration), récolte boisée, angle SE.
- **Altitude** : 4–12, montant vers l'est.
- **Silhouette** : canopées plates espacées, la trouée de l'Observatoire.
- **Repère** : l'Observatoire en ruine sur sa butte (`ruined_observatory`).
- **Transitions** : lisière du camp (O), sente des Hauteurs (N), angle du
  Chasseur (SE, signalé §12.5).
- **Densité** : bosquets de 3–9 arbres + respirations ; sous-bois en cellules.
- **Ennemis** : camps braise (`ember_raider_camps`), territoire du chasseur
  (`hunter_range`, angle SE, facultatif et clairement borné).
- **POI** : `logging_hamlet`, `forest_shrine`, `ruined_observatory`,
  `ember_raider_camps`, `hunter_range`, `veil_falls` (bord est, la cascade
  source — à cheval avec R07 ; région JSON : r07).
- **Récompenses** : gourdin, épice rare, fragment, coffres de territoire.
- **Caméra** : troncs à collision (V1 : 39 arbres-collision) mais élagage des
  branches sous 2,6 m sur les sentes ; fade dither si occlusion.
- **Risques** : forêt-mur ; chasseur qui poursuit hors de son territoire
  (contrat §12.5 : il abandonne à la frontière).

### R07 — Hauteurs de l'Orient

- **Identité** : terrasses rocheuses sèches, vent fort, la verticale technologique.
- **Fonction** : route 2 (hauteurs), écoles Arc Step, panorama, raccourcis.
- **Altitude** : 12–30 — la gorge du Vent entaille le plancher à 12 ;
  éperon du pylône à 18 ; belvédère perché à ~22.
- **Silhouette** : mesas taluées (leçon passe 3) portant le pylône — la seule
  grande verticale entre camp et citadelle.
- **Repère** : le pylône (`(115, 18, −25)`), anticipé depuis le camp.
- **Transitions** : sente du Bois (S), gorge du Vent vers la steppe (NO),
  raccourci Arc Step vers les contreforts (école posée à la gorge).
- **Densité** : minérale, herbes sèches, ancrages Arc Step visibles.
- **Ennemis** : archers azur aux terrasses (poste de guet).
- **POI** : `overlook_summit` (à gravir, arc simple au sommet — regard de
  retour sur la crête de départ), `abandoned_mine`, `wind_gorge` (frontière
  R07/R08), `veil_falls` (source, partagé avec R06).
- **Récompenses** : arc simple, hache (mine), herbe d'endurance (gorge).
- **Caméra** : mode Vista au belvédère ; gorge = couloir assumé, caméra
  resserrée testée contre les parois.
- **Risques** : l'éperon du pylône doit rester une TERRASSE dégagée (vide
  visuel autour du landmark, §6.1) ; gorge trop étroite pour la caméra.

### R08 — Steppe du Nord et Contreforts

- **Identité** : steppe ouverte balayée, tumulus et pierres levées — le nord
  ancien et funéraire.
- **Fonction** : traversée tendue vers le donjon, territoires lourds, angle NO.
- **Altitude** : plaine 2–8, contreforts 10–18 au nord.
- **Silhouette** : horizontale immense, ponctuée de menhirs et du Doyen.
- **Repère** : l'Arbre doyen (`ancient_tree`), seul grand arbre du nord.
- **Transitions** : gués nord de la rivière (S), gorge du Vent (E), rampe
  processionnelle (N), angle de cristal (NO).
- **Densité** : basse, groupes de pierres, herbe rase — le vide y est une
  identité, pas un oubli (respirations §4.3).
- **Ennemis** : patrouille azur (`azure_patrol_run`), bastion des briseurs
  (`obsidian_bastion`, gardien d'une forte récompense §12.3).
- **POI** : `barrow_cemetery`, `old_rampart`, `watchers_circle`,
  `ancient_tree`, `obsidian_bastion`, `azure_patrol_run`, `crystal_hollow`
  (angle NO, souterrain).
- **Récompenses** : hache lourde, flèches, fragments, épice, énigme du cristal.
- **Caméra** : plans très larges ; le nuage d'orage entre en cadre au nord.
- **Risques** : steppe = plaine vide V1 si les buttes et groupes manquent ;
  patrouilles qui convergent toutes (tokens §12.8 restent la loi).

### R09 — Ruines du Cœur (centre)

- **Identité** : le centre n'est plus vide — terrasses géométriques d'une cité
  ancienne, canaux de Résonance à sec, le langage du donjon enseigné dehors
  (§24.4 bible : ruine pédagogique).
- **Fonction** : croisement des trois routes, énigme d'extérieur, anticipation
  du donjon.
- **Altitude** : terrasses 4–8 au-dessus de la steppe.
- **Silhouette** : murs bas orthogonaux volontairement distincts du relief
  naturel ; la Crypte en tumulus enterré (acquis du lot 4 V1).
- **Repère** : l'aqueduc ancien qui enjambe le bras nord (`ancient_aqueduct`,
  déplacé au coude — il relie visuellement ruines et rivière).
- **Transitions** : bras nord et pont magnétique (O), steppe (N et E), sente
  du camp (SE).
- **Densité** : modules de ruine + gravats, végétation d'interstice.
- **Ennemis** : poste braise retranché dans les murs (couvertures réelles).
- **POI** : `hollow_crypt` (déplacée au cœur des ruines), `ancient_aqueduct`
  (frontière R03/R09), `storm_caravan` (bord nord, sur la route du donjon ; région JSON : r10).
- **Récompenses** : lame conductrice (crypte), lance (caravane), fragment.
- **Caméra** : ruelles ≥ 4 m entre murs porteurs ; pas de plafond bas hors
  crypte.
- **Risques** : ruines génériques (grammaire §11.1 bible obligatoire) ;
  couloir caméra dans la crypte (mode Interaction).

### R10 — Marche de l'Orage (approche du donjon)

- **Identité** : le seuil — herbe qui cède aux cendres, sol vitrifié, foudre.
- **Fonction** : montée de tension, préparation (baies), entrée du donjon,
  checkpoint `dungeon_gate`.
- **Altitude** : lac 0, marche 2–10, rampe 2 → 34, plateau 34.
- **Silhouette** : la rampe processionnelle axiale (`(0,2,−110)` → `(0,34,−165)`)
  sous la masse de la citadelle ; le Bois Courbé plié par le vent.
- **Repère** : la citadelle elle-même ; le lac de l'Orage en miroir sombre.
- **Transitions** : steppe (S), rampe → plateau → porte (N) ; retour permanent
  par la rampe (aucun verrou de retour).
- **Densité** : raréfiée voulue ; traces de charge, arcs résiduels au sol.
- **Ennemis** : tanière du colosse (angle NE, `colossus_lair`) ; aucun combat
  imposé sur la rampe elle-même.
- **POI** : `storm_grove`, `storm_caravan` (frontière R09/R10),
  `colossus_lair` (angle NE).
- **Récompenses** : baies de résistance (avant le donjon — garantie §11.4),
  lance, lame conductrice (tanière).
- **Caméra** : contre-plongée contrôlée sur la rampe (la citadelle domine sans
  sortir du cadre) ; mode Vista au plateau (regard de retour : TOUTE la vallée).
- **Risques** : rampe = couloir d'ennui si vide ; le lac conducteur doit
  télégraphier ses états (§8.2 bible) sans tout teinter cyan.

### R11 — Anneau frontalier (non jouable)

- **Identité** : crêtes, cols et chutes fermant le monde.
- **Fonction** : limite naturelle crédible, silhouettes d'horizon, sources
  visuelles des eaux.
- **Altitude** : 40–70 (anneau), montagnes lointaines au-delà.
- **Silhouette** : peigne de crêtes avec cols en selle (76 selles V1 — l'acquis
  anti-couture du sprint est conservé comme PRINCIPE).
- **Transitions** : aucune — tout franchissement est bloqué par le relief.
- **Caméra** : jamais de face verticale nue à hauteur de regard.
- **Risques** : la couture bordure/crêtes (défaut V1 encore ouvert) ; un col
  qui laisse voir le vide hors monde.

## 5. Les trois routes et le trajet principal

**Trajet principal** (première partie, 25–40 min) : crête → descente en S →
gué est → camp (checkpoint, cuisine, 3 approches) → sente du pylône → école
Arc Link au pylône → gorge du Vent → steppe → rampe processionnelle → plateau
(checkpoint) → donjon → boss → victoire. C'est le chemin le plus enseigné, pas
le seul.

**Route de la Rivière** (sûre, systémique — eau/conductivité) : gué est →
village → remontée du bras nord → pont magnétique → lac de l'Orage → rampe.
Récolte abondante, zéro combat imposé, plus longue.

**Route des Hauteurs** (verticale, endurance) : camp → Bois du Levant →
belvédère (à gravir) → mine → éperon du pylône → raccourci Arc Step de la
gorge → contreforts → plateau. Exigeante, panoramas, la plus courte une fois
maîtrisée (≥ 20 % de gain pour un expert, contrat §5.3 P2).

**Route des Ruines** (combat/infiltration) : camp → steppe est → Ruines du
Cœur (crypte, poste retranché) → caravane → rampe. Butin le plus dense,
opposition la plus forte.

Les trois routes se CROISENT aux Ruines du Cœur et au pied de la rampe ; les
gués et le pont magnétique sont les rotules. Chaque route offre au moins un
regard de retour (belvédère → crête ; sommet de falaise → cuvette sud ;
plateau → vallée entière).

**Raccourcis de retour** : passage dérobé (angle SO ↔ pied de falaise),
Arc Step de la gorge (hauteurs ↔ steppe), gué du village (prairie ↔ val),
porte de la citadelle → vallée (existant, conservé).

## 6. Lignes de vue et anticipation des repères

Contrat de composition (vérifiable par fenêtres de projection, méthode
Cycle 3) :

1. **Depuis la crête** : citadelle (but lointain), pylône (verticale droite),
   fumée du camp (but proche), ruban de rivière — les fenêtres §1.1.
2. **Depuis le camp** : le pylône s'anticipe (crête des Hauteurs), la
   citadelle disparaît — elle se re-révèle au pylône (révélation progressive).
3. **Depuis le pylône** : première vue plongeante sur la steppe, le nuage et
   la rampe — le chemin restant se lit.
4. **Depuis le belvédère** : regard de RETOUR sur la crête de départ et la
   distance parcourue (§6.1 : trois points de regard croisé minimum).
5. **Depuis le plateau du donjon** : toute la vallée — la récompense spatiale
   avant l'intérieur.
6. **Le lac de l'Orage** reflète la citadelle : le ruban guide jusqu'au bout.

Masquages voulus : le Bois du Levant cache l'observatoire jusqu'à sa trouée ;
les ruines cachent la crypte ; la gorge cache la steppe puis la révèle d'un
coup (compression → ouverture).

## 7. Les 31 lieux (et les 3 sites systémiques)

Règle absolue : **aucun lieu ne disparaît**. Les 31 identifiants §19.3 de
`docs/POI_MAP.md` sont tous repris, identités et récompenses conservées ;
seules les POSITIONS et la mise en scène changent. Le manifeste exécutable est
`world_v2_layout.json` (`pois[]`, 31 entrées, positions V1 ET V2 côte à côte) —
test protecteur : `tests/world_v2/test_world_v2_layout.gd`.

Corrections de répartition par rapport à V1 (constat WORLD_ATLAS : couronne
60–170 m, centre et angles vides) :

- **le centre reçoit les Ruines du Cœur** (`hollow_crypt` y déménage,
  l'aqueduc s'ancre au coude du bras nord) ;
- **les quatre angles reçoivent une identité** : Passage dérobé (SO),
  Territoire du chasseur (SE), Tanière du colosse (NE), Cavité de cristal
  (NO) — quatre lieux existants poussés en poche d'angle, dans le rayon
  jouable ;
- **l'aqueduc et le pont de pierre sont séparés** (2 m d'écart en V1) ;
- les cinq territoires ennemis s'espacent sur les trois routes au lieu de la
  même couronne.

Les 3 sites systémiques du Bracelet (P2-4) sont conservés au même titre :
`magnetic_bridge` (bras nord), `conductive_basin` (val, près du gué est),
`earth_altar` (sommet de la falaise d'apprentissage). Ils sont dans
`world_v2_layout.json` (`systemic_sites[]`) — ils ne comptent pas dans les 31
mais portent le même contrat de préservation.

**Entrées de grottes** (5) : grotte de la cascade (falaise ouest, derrière la
chute de l'affluent), mine abandonnée (Hauteurs), crypte oubliée (Ruines du
Cœur), passage dérobé (angle SO), cavité de cristal (angle NO). Chacune est
une POCHE INTÉRIEURE avec seuil lisible — pas un simple trou de terrain.

## 8. Espaces de combat, espaces calmes

- **Combat scénarisé** : camp (3 approches), camps braise, patrouille azur,
  bastion, poste des ruines, gorge du Vent (embuscade), territoires colosse et
  chasseur (facultatifs, bornés, signalés).
- **Espace requis** : chaque rencontre a ≥ 12 m de rayon dégagé pour les
  tokens mêlée + une couverture + une sortie de fuite lisible (§12.8, §10.5).
- **Calmes garantis** : crête, prairie, lit de rivière, source, sanctuaire,
  belvédère, berges du lac — aucune perception ennemie n'y déborde.
- Les zones de combat n'empiètent jamais sur un checkpoint ni sur une école
  du Bracelet.

## 9. Points de sauvegarde

Checkpoints narratifs (inchangés dans leur logique, repositionnés en V2) :
`camp` (terrasse), `dungeon_gate` (plateau), puis ceux du donjon (salle
centrale, antichambre) et `victory` — la chaîne exacte vit dans
`world_v2_layout.json` (`checkpoints[]`). Chaque région porte en plus un
**ancrage sûr de région** (`region_anchors[]`) : position plane, au sol, hors
combat, hors eau — c'est la cible de la migration de sauvegarde
(`docs/WORLD_V2_SAVE_MIGRATION.md`), jamais un point de spawn de gameplay.

## 10. Donjon V2 — enveloppe architecturale (plan, pas construction)

La LOGIQUE des salles est un contrat protégé : quatre énigmes, graphe
électrique, solutions, anti-softlock, hints, portes, checkpoints, boss —
`Room1Initiation`, `Room2Vertical`, `Room3Relays`, `Room4Battery`,
`CentralHall`, `Antechamber`, `BossArena` gardent leurs scripts et leurs
constantes de gameplay. V2 reconstruit **l'enveloppe** : volumes, matière,
lumière, présentation — en consommant les 42 modules de donjon CC0 déjà
importés (constat WORLD_ATLAS §4 : ils n'ont jamais servi au donjon).

Topologie (inchangée) : vestibule → salle 1 → salle centrale (hub) →
salles 2/3/4 en branches → antichambre → arène. Retour possible de chaque
branche vers le hub ; aucun verrou de retour avant l'arène.

| Espace | Contrainte immuable (gameplay) | Dimensions utiles | Caméra | Élément focal | Aperçu de l'objectif | Transformation visuelle attendue |
|---|---|---|---|---|---|---|
| Vestibule | déclencheur de porte, retour vallée (`citadel_door`) | ~24 × 16 m, h ≥ 8 | Explore | grande porte à anneau | fresque du langage électrique | acquis V1 conservé (seul intérieur réussi) — raccord au nouveau kit |
| Salle 1 — Initiation | bloc poussable `(0; 0,81; 3)` → plaques à `z = −4`, source/récepteur/reset, solution imperdable | ~20 × 14 m, h ≥ 6 | Explore | la rainure source→récepteur au sol | porte à 2 segments visible dès l'entrée | canal creusé lisible, propagation §19.2 bible |
| Salle centrale | 3 anneaux récepteurs, carte murale, porte du boss ; hub des branches | ~30 × 30 m, h ≥ 12, galerie à y = 6 | Explore élargi | la carte murale en relief | les trois branches ET la porte du boss visibles du centre | verticalité réelle, lumière par circuit |
| Salle 2 — Circuit vertical | puits d'escalade `x = −6,2`, mezzanine `y = 16,5`, ascenseur, électrodes rythmées, corniches de repos | ~18 × 14 m, h ≥ 20 | Climb | le puits et ses électrodes | l'interrupteur supérieur visible du sol | le puits devient une cheminée architecturale |
| Salle 3 — Relais | 4 colonnes rotatives, ports orientés, 256 configurations validées par solveur | ~22 × 22 m, h ≥ 8 | Explore | les 4 colonnes | segments qui s'allument progressivement | colonnes = vraies machines lourdes (§19.5 bible) |
| Salle 4 — Batterie | batterie `(−9,5; 0,6; 2)`, planche bois, bassin d'eau conductrice, sockets, récupération hors-limites | ~24 × 16 m, h ≥ 6 | Explore | le bassin et sa passerelle | le second mécanisme visible derrière l'eau | l'eau parle les lois (états §8.2 bible) |
| Antichambre | checkpoint, coffre garanti, cuisine, baies, retour possible, aperçu de l'arène | ~16 × 12 m, h ≥ 6 | Interaction | le feu et la fresque bois/métal | fenêtre sur l'arène | seuil calme avant l'examen |
| Arène | rayon jouable 19 m, mur r 19,6 × h 13, rail r 14, 4 pylônes de terre espacés de 90° (aux diagonales de l'arène), zones sol distinctes, pas de colonne centrale | disque Ø 38 m | Boss | le Gardien et son noyau | la porte d'entrée reste le seul accès logique | sol à trois matières, gradins en ruine, ciel d'orage visible |

Pour chaque espace, la V2.1+ devra prouver : contraintes de gameplay rejouées
(suites donjon/boss vertes inchangées), dégagement caméra mesuré (SpringArm
4,0–4,6 m + marge), élément focal identifiable en silhouette (§30.3 bible).

## 11. Architecture de construction (rappel des décisions V2.0)

Détail dans `docs/WORLD_V2_SYSTEM_CONTRACTS.md` §5. Résumé opposable :

- terrain en **chunks** de 64 m (grille 8 × 8), maillages sculptés
  (Blender/glTF ou `ArrayMesh` déterministe) — PAS des milliers de BoxMesh
  dans un script unique ;
- collisions séparées de l'habillage ; navigation re-cuisible par région ;
- POI = `PackedScene` autonomes posées par DONNÉES (`world_v2_layout.json`),
  identifiants persistants §19.3 inchangés ;
- végétation en cellules MultiMesh bornées (24–48 m) ;
- capture par cellule et par POI (outil de série V1 réutilisé) ;
- aucune boucle monde-entier par frame ; aucun script V2 ne modifie la V1.

## 12. Ce que V2.1 doit livrer (première tranche après ce plan)

La vallée **whitebox complète et physiquement traversable** : relief continu
conforme aux régions (altimétries du JSON), rivière creusée avec gués,
routes praticables, limites fermées, navigation cuite, spawn et checkpoints
posés — zéro habillage, zéro POI décoré, mais chaque site accessible à pied
et chaque ligne de vue du §6 vérifiée par capture de sonde. Les preuves :
parcours physiques rejoués + captures des 6 fenêtres de composition.
