# PLAN_B — lot 1.R, agent B : tour · sanctuaire · cimetière

**Possédés** : `scripts/world_v2/poi/{watchtower_ruin,forest_shrine,barrow_cemetery}_place.gd` ·
`source_assets/blender/architecture/{make_watchtower_ruin,make_forest_shrine,make_barrow_stones}.py` (+ `.blend`) ·
`assets/architecture/{watchtower,shrine,barrow}/*.glb` · tout nouveau fichier local à ces trois lieux.

**Hypothèses visuelles** (une par lieu, tirées de l'audit contradictoire, 3ᵉ passage) :
1. **Tour** — la silhouette est acquise (B-f-15) ; ce qui manque est la MISE EN SCÈNE et la matière des pièces tombées. Mesuré : `SM_Watchtower_Ruin.glb` est le SEUL des trois GLB sans `COLOR_0`, et ses pièces `tombee` sont un aplat pur → B-f-3/B-f-4 « 141 constant ».
2. **Sanctuaire** — B-f-6 : « cinq plaques grises verticales » coupées par un tronc ; B-f-13 : montants à 94 constant. Le GLB PORTE `COLOR_0` : la variation n'arrive donc pas jusqu'aux pixels, ou le cadre ne montre pas le lieu.
3. **Cimetière** — B-f-11 : tertres « tentes de papier plié » (arête faîtière, sommet plat) ; réserve lead « très bruns et sombres ». La loi de FORME est en cause, pas la matière (ils varient déjà 76→99).

**Modification principale → résultat attendu dans l'image → caméra qui doit le montrer** :
- Tour : `COLOR_0` (strates + pied sombre) sur le GLB, consommé par le matériau ; ancre de récompense déplacée sur le palier haut + parapet rompu/pierre de vigie. → les pans tombés cessent d'être des découpes ; la récompense vient APRÈS l'ascension. → `watchtower_gp_breche`, `watchtower_gp_vigie_pov`, `watchtower_ruin_joueur`.
- Sanctuaire : offsets LOCAUX du lieu pour dégager l'axe des trois caméras gelées + cœur rituel dominant les murs + valeurs sol/mousse. → un seuil, une enceinte, un cœur — pas cinq plaques. → `forest_shrine_joueur`, `shrine_gp_nef`, `shrine_gp_route_p1` (qui doit montrer PEU).
- Cimetière : profil des dômes (affaissement, débord, aucune arête faîtière), hiérarchie des tertres, stèles davantage enfouies ; valeur rendue mesurée sur capture. → des dos de terre, pas des tentes. → `barrow_cemetery_joueur`, `barrow_gp_gueule`.

**Première capture de diagnostic** : lot unique après `--import`, caméras gelées des trois lieux + `watchtower_gp_breche`/`gp_vigie_pov`, `shrine_gp_nef`/`gp_route_p1`, `barrow_gp_gueule`/`gp_chemin` — état de départ `de43152`, pour A/B honnête.

**Contrôle ciblé** : `lancer_godot.sh --check-only` sur le script touché · `gltf_inspect.py` + relecture du JSON du GLB pour `COLOR_0` · capture batch · **Read du PNG à taille réelle** · mesure de luminance là où l'audit a donné un chiffre (aplat, tertres) · emprise après tout changement de famille (R-D3).

**Checkpoint** : commit de ce plan, puis **un commit `art(lot1.r): …` au moins par lieu**, dans l'ordre tour → sanctuaire → cimetière. Journal `ITERATIONS_B.md` écrit AVANT chaque itération.
