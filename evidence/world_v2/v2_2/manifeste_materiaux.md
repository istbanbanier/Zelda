# Manifeste des matériaux du paysage — V2.2/V2.2R

Document de preuve DATÉ (2026-08-13). Les valeurs par défaut ci-dessous sont
celles des fichiers au moment de la génération ; la source de vérité reste le
code (`shaders/world_v2/`, `scripts/world_v2/world_v2_ground_material.gd`).
Règle d'ancrage : ce document cite des chemins et des symboles ; les chiffres
ne vivent qu'ici, jamais recopiés dans la prose des docs vivants.

## Shaders maîtres (3)

### `shaders/world_v2/SH_WorldV2Ground.gdshader` — sol painterly unifié

Un seul matériau PARTAGÉ pour les 64 chunks (`WorldV2GroundMaterial.create()`),
échantillonné en espace MONDE — aucune couture de chunk par construction.

| Famille de paramètres | Rôle | Valeurs clefs (défauts au 2026-08-13) |
|---|---|---|
| Rampe painterly | 2-3 bandes adoucies (bible §7.9) | `ramp_low 0.22`, `ramp_high 0.52`, `ramp_soft 0.21`, `wrap 0.4` |
| Gooch soleil | ombres froides / lumière chaude | `shadow_tint (0.42,0.48,0.60)`, `warm_tint (1.16,1.0,0.86)` |
| Plancher/plafond de valeur | bandes §1.5 (sol 35-65 %) | `shadow_floor 0.14`, `lit_ceiling 0.78` |
| Surfaces | roche/terre/cendre/lit humide | `rock_color`, `earth_color`, `ash_color`, `wet_bed_color` |
| Pente→roche | strates au-delà de ~38-55° | `rock_up_full 0.574`, `rock_up_none 0.788`, `strata_*` |
| Textures détail | albédo/normal/rough tuilés | `grass/rock/earth_tile_m 5.5/3.5/4.5`, fondu `45→150 m` |
| Grain macro | anti-répétition à deux échelles | `grain_strength 0.10`, `macro_variation 0.07` |
| Routes (V2.2R famille E) | largeur variable, bords mordus, interruptions | `route_edge_scale 0.55`, `route_edge_bite 0.45` + bruit de largeur dans le shader |
| Diagnostic | teintes V2.1 sur demande | `diagnostic_amount 0.0` par défaut (caché) |

Données de sommet : `COLOR.rgb` = peinture de région floutée,
`COLOR.a` = masque de route, `CUSTOM0.r` = humidité, `CUSTOM0.g` = cendre,
`CUSTOM1` = teinte diagnostic V2.1.

### `shaders/world_v2/SH_WorldV2Water.gdshader` — eau stylisée

Ruban MITRÉ continu (V2.2R famille F) ; profondeur par `COLOR.r`, courant
par `COLOR.gb`. `shallow_color (0.20,0.44,0.45,0.60)`,
`deep_color (0.10,0.27,0.33,0.90)`, mousse de rive cassée
(`foam_color`, `foam_depth 0.16`), deux échelles de vagues
(`wave_scale 0.14`, `wave_speed 0.045`).

### `shaders/world_v2/SH_WorldV2Sky.gdshader` — ciel fin d'après-midi

Gradient zénith→horizon avec côté chaud à l'ouest : `zenith_color`,
`horizon_cool`, `horizon_warm (0.98,0.87,0.64)`, `sun_direction`,
`warm_spread 2.4`.

## Textures de surface

`assets/textures/surfaces/` — familles `T_Grass_Field`, `T_Rock_Strata`,
`T_Ground_Earth` (Albedo/Normal/Rough JPG). Provenance et licence :
`ATTRIBUTIONS.md`. Le grain macro est un `NoiseTexture2D` généré
(`WorldV2GroundMaterial.grain_texture()`), aucun fichier.

## Matériaux StandardMaterial3D par catégorie

| Emploi | Construction | Ton |
|---|---|---|
| Crêtes de frontière (GuardMesh/GuardButtress) | couleurs de SOMMET (strates + mottling) sur `vertex_color_use_as_albedo`, normales RECALCULÉES après déplacement (V2.2R) | base `(0.355,0.31,0.29)` / contrefort `(0.30,0.265,0.255)` |
| Pics lointains (FarPeak*) | même crête déchiquetée, ton froid brumeux §9.4 | `(0.35,0.39,0.46)` |
| Orage (cumulonimbus) | 22 blobs déplacés au bruit + coques translucides côté ventre | base `(0.255,0.265,0.335)` → sommet `(0.46,0.43,0.47)` |
| Éclair | matériau émissif à cœur clair | émission 3.5, flanc 0.55 |
| Végétation (modèles CC0) | matériau du modèle DUPLIQUÉ puis assagi (jamais muté en partage) | arbres ×`(0.60,0.63,0.50)`, rochers ×`(0.95,0.88,0.78)`, `roughness ≥ 0.95`, `metallic_specular 0.1` |
| Herbe/roseaux générés | `shaders/foliage/foliage_wind.gdshader`, teinte PAR INSTANCE depuis la peinture de région | roseaux `(0.30,0.42,0.28)` |

## Vérification

- Shaders réellement montés : sonde `tools/godot/probe_world_v2_landscape_metrics.gd`
  (section `shaders_montes`).
- Exposition des captures : `tools/godot/check_capture_exposure.gd`
  (`CLIP_LUMA 0.86`, `CLIP_BLOCK_SHARE 0.008`, fluo `0.32/0.015`) —
  recalibré ROUGE d'abord sur les captures rejetées par le lead
  (`controles/filet_exposition_ROUGE_avant_v22r.log`).
