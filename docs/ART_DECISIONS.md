# ART_DECISIONS — arbitrages de direction artistique (Prompt 4 §6)

Registre des décisions utilisateur sur les fourches créatives. Une décision
consignée ici prime sur toute initiative (Prompt 4 §0.1). Format : date,
décision, options rejetées, raison.

## En attente d'arbitrage utilisateur

*(aucune fourche soumise pour l'instant — les passes H-1 à H-6 étaient des
corrections mesurées contre la bible, pas des choix créatifs ouverts)*

## Verrouillés par le Prompt 4 §2 (ne pas rouvrir sans demande explicite)

1. Style painterly à ramps adoucies — toon dur et outline noir interdits.
2. Le rendu se gagne dans `SH_CharacterPainterly` + éclairage (chantier V1).
3. Notation unique : grille Prompt 3 §30.2, protocole d'image §30.1,
   baseline C.5 en avant/après. La grille §3.5 du Prompt Maître est archivée.
4. Bestiaire par étapes : une famille pilote de bout en bout d'abord ;
   `ravine_troll` et `centaur_hunter` en dernier.
5. `AreaLight3D` autorisé si coût mesuré dans `LightingLab`.

## Soumis à arbitrage — 2026-08-05 (mandat « Go bloc A→D » : recommandations appliquées par défaut, révocables)

### AD-001 — Matrice de sourcing (voir docs/assets/SOURCING_MATRIX.md)
**Recommandation appliquée** : trépied Quaternius CC0 retouché + procédural
scripté + shaders maison ; aucun téléchargement/achat ; plafonds de la bible
non atteignables déclarés PARTIAL. Alternatives rejetées : packs payants
(interdits par MASTER_SPEC §2), génération d'images comme textures (interdite
par bible §0.2).

### AD-002 — Six planches concept (Prompt 4 §4)
Existant réutilisé comme fiches de finalisation : line-up bestiaire =
`evidence/phaseH/lineup_silhouettes.png` + turntables (planche 2) ; citadelle =
`vista_h6_citadelle` + matrice §2.4 (planche 4). À produire en fiches
descriptives + captures : héros de dos 5 signes (1), pylône trois distances
(3), Bracelet et motifs (5 — dépend du Prompt 2), Gardien fermé/ouvert (6).
**Recommandation** : planches sous forme fiche texte + capture moteur (pas
d'images générées tant que tu ne les demandes pas).

### AD-003 — Typographie
**Recommandation** : rester sur la police par défaut de Godot (MIT, embarquée)
tant que le réseau restreint empêche de vérifier une paire SIL-OFL ; statut
PARTIAL au Gate H.

### AD-004 — Bifurcation du handoff Cycle 3 (2026-08-06, révocable)
**Décision appliquée** : auto-évaluation sévère du HeroShotLab v5 =
**58/100 `UNVERIFIED`** (grille §30.2, rendu logiciel —
`evidence/cycle3/2026-08-06_eval_v5_severe.md`) → en dessous de 75 :
**itération du lab avant toute propagation V4**, dans l'ordre dicté par
les domaines faibles : `SH_CharacterPainterly` (lumière 8/15, matériaux
5/10), puis vidéo de stabilité (mouvement 2/10), puis re-évaluation +
revue contradictoire. Alternatives rejetées : propager tout de suite
(la recette n'est pas finie — on propagerait des albedos plats) ;
attendre le verdict humain sans rien faire (le handoff autorise la
bifurcation autonome consignée). Le score officiel reste à l'humain
sur GPU ; le Gate H n'est PAS déclaré.

### AD-005 — Le contrat d'image §1.1 prime sur la distance caméra §3.1 (2026-08-06, révocable)
**Décision appliquée** : la revue contradictoire a mesuré le héros à
~51 % de hauteur visible (fenêtre §1.1 : 38-45 %). Au FOV verrouillé
(71,4° horizontal), les fenêtres §1.1 (tête 44-48 %, pieds 89-92 %,
hauteur 38-45 %) sont mathématiquement incompatibles avec la distance
caméra §3.1 (4,0-4,5 m). Choix : le contrat d'IMAGE prime (c'est lui
que la grille §30.2 et la revue jugent) — objectif 1,75 m (borne
§3.1), recul 5,0 m ; calcul et mesure : tête 44,7 %, pieds 89,3 %,
hauteur 44,6 %, trois fenêtres tenues. Alternative rejetée : réduire
le FOV sous 65° horizontal (violerait §3.1 aussi et écraserait la
vallée). Au même lot : soleil replacé DEVANT-GAUCHE (azimut 40°,
hauteur 23°) — l'ancien yaw le mettait derrière-droite, contraire à
§22.1, ciel symétrique mesuré 73,6/73,6 par la revue.
