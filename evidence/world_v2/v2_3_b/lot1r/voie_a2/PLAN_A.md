# PLAN_A — agent A, lot 1.R (belvédère + source)

**Fichiers possédés** : `scripts/world_v2/poi/overlook_summit_place.gd` ·
`scripts/world_v2/poi/turquoise_spring_place.gd` · tout NOUVEAU fichier local
à ces deux lieux (shader d'eau, `source_assets/blender/*` + GLB propres).

**Mesuré d'abord** (captures `lot1r/final/ab13`, PIL) — c'est le point de départ :
belvédère masse rendue **H=40° S=0,11 V=0,61** (chaude et PLUS CLAIRE que la
falaise V2.2 H=25° V=0,63) ; source, caméra JOUEUR gelée : **S=0,079 H=137°**
(gris-vert), contre rivière V2.2 S=0,273 H=179° — la nappe blanche est confirmée
au pixel, et elle vient de l'incidence rasante (6° au-dessus du plan d'eau).

**Belvédère — hypothèse** : ça lit « des rochers posés » parce que la matière est
chaude/claire, sans strate, et que l'herbe monte au contact. Levier principal :
teintes froides mesurées à la cible (H 200–225°, V ≈ 0,47–0,52) + une **assise
rocheuse runtime** qui épouse le terrain autour des masses (motif `FondVasque`),
+ strates par masses couchées et décalées. Attendu dans l'image : la formation
devient plus sombre et plus bleue que la falaise du fond, et son pied est de la
ROCHE, plus de l'herbe. Vues : `overlook_summit_identite` (froideur/valeur),
`overlook_gros_crete` (strates, contact au sol).

**Source — hypothèse** : le shader V2.2 (ROUGHNESS 0,18, SPECULAR 0,4, ALPHA 0,6
en rive) rend le ciel au ras et efface la teinte. Levier principal : shader
LOCAL `SH_TurquoiseSpringWater.gdshader` — spéculaire mat, fresnel teinté
sarcelle profonde (jamais blanc), rampe turquoise saturée, rive opaque ; +
géométrie : le déversoir descend vers l'est en gradins pour offrir de l'eau
PLUS PRÈS et moins rasante. Attendu : S ≥ 0,25 et H ∈ [170;195] dans
`turquoise_spring_joueur`, sans dépasser la valeur de la rivière V2.2.

**Contrôle** : parse ciblé de chaque `.gd` touché, `--import`, capture par
`capture_poi_batch.gd` avec les caméras GELÉES recopiées + vues diagnostiques,
lecture des PNG à taille réelle, mesure PIL avant/après. Journal
`ITERATIONS_A.md` écrit AVANT chaque itération. Budget D7 « micro » = 12
modules / 30 visuels / 6 collisions : les deux lieux sont DÉJÀ à 12 modules —
toute pièce ajoutée en remplace une.

**Premier checkpoint** : ce plan, puis le journal + la teinte froide du
belvédère mesurée sur capture.
