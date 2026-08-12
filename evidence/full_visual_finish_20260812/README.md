# Finition visuelle du monde entier — preuves du 2026-08-12

**HISTORIQUE.** Ce dossier décrit un état daté ; la vérité vivante est
`docs/STATUS.md`.

Branche `claude/full-world-visual-finish`. Jeu livré au commit
`0b2810665a8004bd9ec74dfcfbbb9a7750a06010` (release GitHub
`playtest-full-visual-0b28106`, macOS vérifié avant et après publication).
Bibliothèque d'assets Codex fusionnée depuis
`codex/world-asset-library-20260812` (11 packs CC0 en quarantaine).

Moteur : Godot **4.7.1-stable officiel** (`a13da4feb`). Captures : xvfb +
llvmpipe **logiciel** — régression visuelle uniquement, jamais une mesure de
performance. Toutes les captures de `poi/` viennent d'un arbre COMMITTÉ
(`manifest.json`, `repo_dirty: false`), avec vignettes 320×180 et niveaux
de gris (§30.1).

## Ce qui a été fait (9 lots)

| Lot | Contenu | Vérification |
|---|---|---|
| 1 | Teintes de prairie en lobes organiques (fini les rectangles), 22 buttes marchables sur toute la carte, chaînes de berges | relief 3/3, filet anti-enterrement, carte avant/après |
| 2 | Trois masses boisées (39 arbres à tronc-collision posés sur le sol réel, sous-bois MultiMesh 195 instances, lisières), navmesh re-cuite | dressing 10/10, parcours physiques verts |
| 3 | Rivière habitée sur 480 m (roseaux MultiMesh, pierres), terrasse du pylône talutée 4 faces | dressing 10/10 |
| 4 | Toits village/hameaux ramenés dans la palette §1.4, crypte enterrée sous berges affleurantes, falaise d'apprentissage talutée (couloir d'escalade épargné) | village 7/7, hameaux 7/7, grottes 8/8, escalade 16/16 |
| 5 | Citadelle inchangée À DESSEIN — D-052 : le kit Castle est au pas de 1 m, les masses font 10-50 m | décision consignée |
| 6 | Donjon : 8 espaces habillés par agent (identités par salle), 10 GLB + 2 textures CC0 promus | 92 tests verts, captures intérieures des 6 salles |
| 7 | Acteurs vérifiés en capture (camp vivant a1 ; monture et héros recadrés en reprise) | plans a1-a3 |
| 8 | VFX réduits à l'existant (fumée, orage, foudre) — aucun défaut ciblé à corriger, packs particules restés en quarantaine | décision au STATUS |
| 9 | UI finie par agent : menu, HUD, inventaire, pause, options (débordement 720p **775 → 642 px mesurés**), victoire, 6 sons CC0 | 45 tests UI verts |

## Batterie finale

- `validate_fast` : **VERT — 845 tests, 0 échec, code retour 0, un seul
  résumé** (`scratchpad` du conteneur ; verdict recopié ici).
- Parcours physiques : vallée 1/0, donjon (solveur) 2/0, boss 1/0,
  démarrage complet 1/0.
- Sauvegardes/reprise : couvertes par la suite (save_continuity et
  playthroughs verts).
- Joueurs boîte noire (verdicts complets dans `evidence/blackbox_player/`) :
  - **occasionnel A** (`occasionnel_A_20260812_190222`) : notes 4-6/10 —
    vallée agréable et guidage naturel salués ; caméra souris inconstante
    sous le harnais, boucle dans la rivière à l'approche du camp, jamais
    de combat engagé ;
  - **explorateur E** (`explorateur_E_20260812_192127`) : notes 6-7/10 —
    « plusieurs zones distinctes et des recoins cachés donnent envie de
    voir le reste » ; a levé le drapeau silhouette du héros (ISS-048),
    la pose debout en selle (ISS-050), l'éclair-silhouette (ISS-051) et
    des faces internes de terrain (ISS-052) ;
  - **expérimenté D** (`experimente_D_20260812_194224`) : notes 4-7/10 —
    a traversé la vallée et ENGAGÉ le combat au camp ; chargement muet
    (ISS-049), feedback d'impact jugé faible, une masse plate vert clair
    près du bassin devant le camp (ISS-053), pas de marqueurs (choix de
    design §2.3 — guidage par curiosité, à éprouver sur vrai écran).
- Livraison macOS : release `playtest-full-visual-0b28106`, asset re-téléchargé
  et re-vérifié (SHA-256 conforme, structure .app complète, Mach-O universel,
  signature ad hoc).

## Tableau final par lieu (revue des 39 captures de `poi/`)

Statuts : ✓ = identité lisible en capture · ≈ = lisible avec réserve
nommée · ✗ = cadrage raté au premier jet — REPRIS dans `poi_redo/` (10 plans,
manifeste propre) ; le lieu lui-même n'est pas en cause sauf mention.

| # | Lieu | État | Réserve honnête |
|---|---|---|---|
| 01 | Village de la rivière | ✓ | toits en palette depuis lot 4a |
| 02 | Hameau des bûcherons | ✗→repris | cadrage dans une couronne d'arbre |
| 03 | Poste minier | ✓ | face de falaise talutée depuis lot 4a |
| 04 | Tour de guet | ✓ | cabane à toit tissé orange (choix camp) |
| 05 | Aqueduc ancien | ✓ | reflets dans la rivière |
| 06 | Ferme abandonnée | ✓ | |
| 07 | Caravane foudroyée | ✓ | |
| 08 | Observatoire en ruine | ✓ | |
| 09 | Cimetière du tertre | ✓ | stèles, enclos, mousse |
| 10 | Fortification ancienne | ✓ | |
| 11 | Sanctuaire forestier | ✗→repris | cadrage dans le bois du lot 2 |
| 12 | Grotte de la cascade | ≈ | la colline-couverture reste une boîte brute |
| 13 | Mine abandonnée | ≈ | même boîte-colline ; entrée boisée lisible |
| 14 | Crypte oubliée | ✓ | berges de terre du lot 4a |
| 15 | Passage dérobé | ✗→repris | cadrage dans la paroi |
| 16 | Cavité de cristal | ≈ | coffre-boîte sombre, à traiter comme la crypte |
| 17 | L'Arbre doyen | ✓ | deux caissons de dressage un peu bruts |
| 18 | La Source aux reflets | ≈ | brume basse épaisse, lecture voilée |
| 19 | Champ des mille fleurs | ≈ | une plaque de sol du POI à bord droit |
| 20 | L'Arche de pierre | ✗→repris | cadrage dans le tablier |
| 21 | Belvédère du guetteur | ✗→repris | cadrage dans la structure |
| 22 | La Chute du Voile | ✓ | bassin turquoise, très lisible |
| 23 | Le Cercle des Veilleurs | ✓ | |
| 24 | La Gorge du Vent | ✗→repris | parois de gorge = dalles unies (réserve réelle) |
| 25 | Le Bois Courbé | ✗→repris | cadrage dans la canopée |
| 26 | L'Arbre foudroyé | ✓ | masse sombre de bordure derrière |
| 27 | Camps de pillards braise | ✓ | |
| 28 | Patrouille azur | ≈ | mur de gorge uni en fond ; toits de poste non teintés |
| 29 | Bastion des briseurs | ✓ | |
| 30 | Tanière du colosse | ✓ | |
| 31 | Territoire du chasseur | ✗→repris | buisson devant l'objectif |
| g1-g5 | Vues générales 4 coins + centre | ✓ | g1 : face ouest du plateau encore une dalle sombre |
| a1 | Camp vivant (acteurs) | ✓ | deux pillards au feu |
| a2-a3 | Monture, héros de dos | ✓ (poi_redo) | monture cadrée ; héros ivoire/charbon/turquoise APRÈS ISS-048 — plus de lecture « archer vert » |

## Défauts réels restants (pour la prochaine passe — AUCUN n'est masqué)

1. Collines-couvertures des trois grottes = boîtes brutes (12, 13, 16) —
   la recette « berges de la crypte » s'y transpose.
2. Parois de la Gorge du Vent = grandes dalles unies (24, 28).
3. Face OUEST du plateau d'apprentissage = dalle sombre (g1) ; seules les
   faces est/nord ont été talutées.
4. Toits des postes de guet azur (Roof_Wooden en plein soleil) très
   saturés — hors du filtre de teinte du lot 4a.
5. Brume de la Source aux reflets trop dense (18).
6. Chargement muet ~20 s (ISS-049), pose en selle (ISS-050),
   éclair-silhouette au-dessus de la spire (ISS-051), faces internes de
   terrain (ISS-052), masse plate près du bassin du camp (ISS-053) —
   tous relevés par les playtests, consignés, AUCUN masqué.
7. CORRIGÉ pendant la passe : la tunique verte du héros lisait comme la
   silhouette d'une licence existante (ISS-048, deux lectures
   indépendantes) — tissu viré à l'ivoire/charbon à luminance conservée
   (`tools/recolor_hero_tunic.py`, ATTRIBUTIONS mis à jour). La capuche
   comme FORME reste à arbitrer avec le propriétaire.

Le verdict d'IMAGE appartient à la revue indépendante de Codex ; rien ici
ne déclare le gate visuel réussi.
