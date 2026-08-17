# Preuves V2.2 — fondation artistique du paysage extérieur

Phase : V2.2 (redéfinie par directive du lead : FONDATION ARTISTIQUE du
paysage — matériaux, végétation, eau, ciel/orage, silhouettes — l'enveloppe
du donjon est différée). Branche `claude/world-v2-reconstruction`, base
d'audit `base_sha.txt` = V2_1_FINAL_SHA (38c87b1). Les fichiers datés
portent chacun leur SHA.

Ce dossier prouve que la vallée VALIDÉE en V2.1 a reçu une peau cohérente
SANS qu'aucun contrat spatial ne bouge : mêmes hauteurs, mêmes gués, mêmes
routes, mêmes caméras, mêmes limites — le visuel s'est adapté au monde,
jamais l'inverse. **Aucun verdict artistique n'est prononcé ici** (§17 de
la directive : il appartient à Codex, Istvan et son frère) — seuls des
défauts techniques mesurables sont jugés, et les résidus sont consignés.

## Verdicts techniques

| Critère | Statut | Preuve |
|---|---|---|
| Contrats V2.1 intacts sous la peau (suites world_v2) | PASS | `suite_complete_c3_verte.log` (42/42 en MILIEU de phase — avant eau/ciel/bordures) ; **rejouée verte à HEAD par la revue contradictoire** et couverte par `validate_fast_final.log` sur l'état final |
| Caméras V2.1 gelées par littéraux | PASS | suite contrat ; contrôle D |
| Matériau de paysage sur les 64 chunks, aucun diagnostic visible | PASS | suite contrat ; contrôle A ; `captures/` |
| Bandes de valeurs §1.5 (sol 35-65, ciel 75-95, hiérarchie sol<ciel) | PASS mesuré | six passes de calibrage consignées (PROGRESS suite 2) ; herbe 47-60 %, falaises ombre 27 %, ciel 80 % |
| Végétation cellulaire ≤ 48 m, déterministe, couloirs dégagés | PASS | suite contrat ; contrôles B et C |
| Collisions nouvelles bornées aux troncs/rochers + nav re-cuite | PASS | bake re-joué ; nav + traversal verts dans les 42/42 |
| Gués praticables avec la végétation (ISS-032) | PASS | régression attrapée PUIS corrigée (colliders ≥ 12 m des gués) — `suite_complete_c3_verte.log` |
| Fenêtres gelées dégagées (couloir de visée) | PASS | régression cam03 attrapée PUIS corrigée — même journal |
| Continuité visuelle inter-chunks | PASS visuel | `captures/vue_couture_chunks.png` (coin de 4 chunks, vue rasante : aucune couture de matière ni de relief) ; `carte_materiaux.png` (monde entier, aucun quadrillage) |
| Orage LOCAL, pas une soucoupe ; éclair cœur blanc | PASS mesuré | trois passes consignées (2 soucoupes mesurées puis cassées au maillage) ; `capture_cam01_eclair.png` |
| validate_fast.sh sur l'état final | PASS | `validate_fast_final.log` (887/0, RC=0) |
| Revue contradictoire à contexte frais (depuis 38c87b1) | **PASS, réserves non bloquantes traitées** | `revue_contradictoire.md` (l'agent a rejoué suites, bake bit-à-bit, contrôle D, capture) |

## Captures (arbre COMMITTÉ, manifestes `repo_dirty: false`)

- `captures/capture_cam01..06.png` — les six fenêtres GELÉES (V2.1),
  côté « APRÈS ». Le côté « AVANT » est la série V2.1 committée :
  `evidence/world_v2/v2_1/capture_cam01_spawn_vista.png` etc. — mêmes
  transforms, mêmes FOV, comparaison directe.
- `captures/capture_cam01..06_gris.png` — niveaux de gris (protocole §30.1).
- `captures/capture_cam01_eclair.png` — l'éclair (cœur blanc, nuage→plateau).
  Premier trajet mesuré INVISIBLE (vivait dans le nuage) puis corrigé.
- `captures/carte_materiaux.png` — le monde entier vu du ciel (0,25 m/px) :
  bassin versant complet, transitions de régions, réseau de routes intégré,
  identités végétales, anneau fermé, orage local.
- `captures/carte_regions.png` — même vue en mode DIAGNOSTIC V2.1
  (teintes de régions), prouvant que le mode caché reste disponible.
- `captures/vue_couture_chunks.png` — vue rasante d'un coin de 4 chunks.
- `captures/region_r01..r10.png` — une capture par région jouable, caméra
  posée sur l'ancre de sauvegarde de la région.

## Trouvaille d'ingénierie de la phase (mesurée, documentée au point d'usage)

**Le renderer DUMMY du headless `--script` jette les données d'instance
MultiMesh** : `set_transform` est un no-op, `get_transform` rend l'identité,
l'AABB est vide (source 4.7.1, `dummy/storage/mesh_storage.h:191,200,202`).
Un test headless qui lit un MultiMesh teste le renderer factice, pas le
monde. Réponse : le bâtisseur écrit son PLAN DE PLANTATION en méta de nœud,
depuis les mêmes valeurs dans la même boucle que l'écriture moteur — le
headless prouve le plan, la capture llvmpipe (vrai renderer) prouve le
rendu. Même famille que les trouvailles V2.1 (itérations nav asynchrones
mortes en headless).

## Contrôles négatifs (les contrats savent rougir)

- `controles/controle_A_materiau_ROUGE.log` — matériau du chunk c3r3
  retiré : « c3r3 : matériau de diagnostic, pas de paysage ».
- `controles/controle_B_ancrage_ROUGE.log` — instances soulevées de 2 m :
  ancrage rouge (8678/8678 écarts, +1,95 m nommé).
- `controles/controle_C_cellule_ROUGE.log` — cellules à 64 m : « emprise
  53 × 32 m (plafond 48) ».
- `controles/controle_D_camera_ROUGE.log` — cam03 déplacée de 5 m :
  « (117,00) au lieu de (112,00) ».
- `controles/controle_retour_VERT.log` — arbre restauré, contrat 6/6.
- `controles/controle_E_meta_moteur_ANGLE_MORT.log` — **pas un rouge/vert :
  un ANGLE MORT documenté**. Transforms moteur décalés de +2 m, méta
  intacte → la suite reste verte (le headless ne voit pas le moteur).
  Couvert par l'inspection des captures et les sondes physiques ;
  démontré d'abord par la revue contradictoire, rejoué et archivé ici.

## Résidus consignés (mesurés, non cachés — pour la passe artistique suivante)

1. Descente de la crête r01 : ~67 % de luma sur pente face au soleil —
   2 points au-dessus de la bande sol, hiérarchie sol<ciel TENUE (67 < 80) ;
   identifiée PAR SONDE DE RAYON comme l'identité r01 sous lumière du soir.
2. En niveaux de gris, la lisibilité des routes au PLAN MOYEN repose
   surtout sur la teinte (or/vert) — l'écart de VALEUR route/herbe est à
   renforcer (« jamais la couleur seule »).
3. Jonction de segments du ruban d'eau visible aux coudes serrés en vue
   rasante (facette pâle, `vue_couture_chunks.png`).
4. Fines lamelles de ciel à certaines jonctions de crêtes de bordure ;
   dalles pâles côté est (cônes lointains vus par un col).
5. Fleurs roses hors palette stricte (asset CC0 tel quel) ; canopées
   lointaines encore vives sans brume rapprochée.
6. Nuage détaché du proxy de citadelle — se résout quand la silhouette de
   citadelle arrivera (TEMPORAIRE V2.2 assumé par la directive §15).
7. Rendu llvmpipe : régression visuelle uniquement, JAMAIS une mesure de
   performance (niveaux 6-7 impossibles ici).

## Limites honnêtes / NON VÉRIFIÉ

- Aucun chiffre de performance n'est donné ni ne doit l'être (llvmpipe).
  Architecture mesurable : tout se construit au chargement (montage
  ~10-14 s, aucun traitement par frame ajouté) ; cellules MultiMesh 32 m ;
  un seul matériau de terrain partagé.
- La stabilité TEMPORELLE (shimmer, vent en mouvement) demande une vidéo
  sur GPU réel — hors de portée du conteneur, à faire sur machine Istvan.
- Contrôles manuels §21.4 : impossibles ici — `EN ATTENTE`
  (`docs/MANUAL_VALIDATION.md`).
