# RAPPORT B — PHASE V2.2 : FONDATION ARTISTIQUE DU PAYSAGE EXTÉRIEUR

Date : 2026-08-13. Branche : `claude/world-v2-reconstruction`. Base d'audit :
`38c87b1` (V2_1_FINAL_SHA, `base_sha.txt`). Le SHA de clôture est celui du
dernier commit de la phase — vérifié égal au distant au moment du push final.

## 1. Ce qui a été réellement construit

La vallée whitebox VALIDÉE en V2.1 a reçu sa fondation artistique, sans
qu'aucun contrat spatial ne bouge (« le visuel s'adapte au monde validé ») :

- **Terrain** : `SH_WorldV2Ground` — le modèle painterly validé du projet
  (half-Lambert, paliers fondus, Gooch solaire, plancher d'ombre, plafond
  peint) transposé au sol continu ; teintes de région à transitions LARGES
  (grille floutée), routes INTÉGRÉES au bord bruité, humidité des berges,
  cendres de la Marche, strates de roche par pente ; surfaces ambientCG
  déjà attribuées (couleur subordonnée, relief franc — AD-006) ; UN matériau
  partagé par les 64 chunks — aucune couture possible par construction.
  Calibrage en SIX passes de capture mesurées (le gain de ce monde diffère
  du lab V1) : bandes §1.5 tenues, hiérarchie sol < ciel partout.
- **Végétation** : bâtisseur cellulaire (MultiMesh 32 m, graine fixe,
  déterminisme testé) aux identités du masterplan §4 — bosquets au Bois,
  phrases de fleurs en prairie, roseaux aux berges, morts dans la Marche,
  crête sans arbres, vide de steppe assumé ; troncs et gros rochers en
  collisions SIMPLES (les seules permises §7) + navigation re-cuite,
  reproductible bit-à-bit (vérifié par la revue).
- **Eau** : profondeur par sommet (turquoise de gué → pétrole du bol),
  courant local, mousse de rive cassée, lac en éventail — géométrie, gués
  et niveaux GELÉS.
- **Ciel/atmosphère/orage** : ciel peint (miel côté soleil ouest), brume de
  distance qui SÉPARE les trois plans (calibrée en trois passes — la
  première effaçait le monde), cellule d'orage LOCALE au-dessus de la zone
  citadelle en masses grumeleuses (deux passes « soucoupe » mesurées puis
  cassées au maillage), éclair-événement à cœur blanc cadencé par Timer.
- **Silhouettes de bordure** : les boîtes whitebox remplacées par des
  crêtes déchiquetées — la COLLISION V2.1 reste la boîte exacte (72 azimuts
  verts).

Hors périmètre, RESPECTÉ : aucun POI bâti, aucun ennemi, aucun donjon V2,
aucune migration, layout JSON intouché (vérifié par diff en revue).

## 2. La preuve

| Preuve | Où |
|---|---|
| Contrat paysager écrit FAIL-FIRST (rouge archivé avant l'habillage) | `contrat_paysager_ROUGE_avant_habillage.log` |
| Suite complète world_v2 verte, rejouée à HEAD par la revue | `suite_complete_c3_verte.log` + `revue_contradictoire.md` |
| validate_fast final : 887 réussis / 0 échoué, RC=0 | `validate_fast_final.log` |
| Contrôles négatifs A/B/C/D rouges NOMMÉS puis retour vert | `controles/` |
| Angle mort méta/moteur DÉMONTRÉ et archivé (pas caché) | `controles/controle_E_meta_moteur_ANGLE_MORT.log` |
| A/B des six fenêtres gelées (avant = série V2.1 committée) | `captures/capture_cam01..06.png` + gris |
| Cartes du monde entier (matériaux, diagnostic), couture, régions, éclair | `captures/` |
| Revue contradictoire à contexte frais : PASS, réserves traitées | `revue_contradictoire.md` |

## 3. Les régressions que les contrats ont attrapées (et leurs leçons)

1. Rocher à 7 m du gué est → sonde physique rouge → marges de couloir par
   RAYON de collider, gués à 12 m des blocs (ISS-032 : la largeur utile
   n'est pas la largeur du tablier).
2. Rocher dans l'AXE de cam03 → fenêtre bouchée → exclusion du COULOIR DE
   VISÉE (plan + hauteur), pas seulement un rayon autour de l'œil.
3. « ValleyWorld » dans un nom de nœud → suite d'isolation rouge → renommé.
4. L'éclair vivait DANS le nuage (visait une flèche inexistante) — vu à la
   capture, jamais par un test : l'inspection d'image reste irremplaçable.

## 4. Trouvaille d'ingénierie

Le renderer dummy du headless `--script` jette les données d'instance
MultiMesh (set no-op, get identité, AABB vide — source 4.7.1). Un test
headless qui lit un MultiMesh teste le renderer factice. Réponse : plan de
plantation en méta écrit dans la même boucle que l'écriture moteur — le
headless prouve le PLAN, la capture prouve le RENDU, et l'angle mort entre
les deux est un artefact archivé, pas un secret.

## 5. Ce que ce rapport NE dit PAS

Aucun verdict artistique n'est auto-déclaré (§17) : ni « wahou », ni
« final », ni « professionnel ». Le verdict d'image appartient à Codex,
Istvan et son frère — les A/B et les cartes sont prêts pour ce jugement.
Aucun chiffre de performance (llvmpipe interdit toute mesure). Les résidus
mesurés sont listés dans `README.md` (mare claire r01, valeur des routes en
gris, facettes de ruban aux coudes, lamelles de crêtes, fleurs roses,
nuage détaché du proxy) — matière de la prochaine passe, pas des excuses.

## 6. Prochaine action la plus rentable (non faite)

Au choix du lead : (a) passe artistique 2 du paysage sur les résidus
consignés + filet plan/capture pour l'angle mort E ; (b) enveloppe du
donjon V2 (différée par la redéfinition — le fil de détente
`test_world_v2_dungeon_pins.gd` est déjà en place) ; (c) verdict artistique
externe sur les A/B avant toute suite. Jamais V2.3 sans directive.
