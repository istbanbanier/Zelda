// SH_WorldV2Ground — matériau de PAYSAGE du terrain V2 (phase V2.2-B).
//
// Transposition du modèle painterly validé (SH_CharacterPainterly, décision
// verrouillée n°2) au sol continu de la vallée : half-Lambert enveloppant,
// deux paliers FONDUS, chaud/froid réservé au soleil, plancher d'ombre,
// respiration macro et grain monde — plus ce qui n'existe que pour un
// terrain : familles de surface mélangées par PENTE (herbe → roche), routes
// INTÉGRÉES au sol par un bord bruité (jamais un ruban plaqué), humidité
// des berges, cendres de la Marche de l'Orage.
//
// Données par SOMMET, cuites par le bâtisseur (une seule vérité, aucune
// couture de chunk possible : tout est échantillonné en espace monde) :
//   COLOR.rgb  = teinte peinte de région, transitions déjà LARGES (grille
//                floutée ~10 m — §10 : jamais la couleur seule, mais la
//                couleur d'abord) ; COLOR.a = masque de route adouci ;
//   CUSTOM0.r  = humidité (lit, berges, lac) ; CUSTOM0.g = cendres ;
//   CUSTOM1    = teinte de DIAGNOSTIC V2.1 — cachée par défaut
//                (diagnostic_amount = 0), directive §11.
//
// Les teintes de sommet sont en espace ALBÉDO, pas en couleur cible : la
// lumière a un gain ≈ 1,4-1,8 NON LINÉAIRE (leçon mesurée, scripts/CLAUDE.md,
// ISS-037) — la valeur rendue se mesure sur la capture, jamais prédite.
shader_type spatial;
render_mode specular_disabled;

// -- peinture (mêmes réglages de base que le shader personnage) --------------
uniform vec4 shadow_tint : source_color = vec4(0.42, 0.48, 0.60, 1.0);
uniform vec4 warm_tint : source_color = vec4(1.16, 1.0, 0.86, 1.0);
uniform float ramp_low : hint_range(0.0, 1.0) = 0.22;
uniform float ramp_high : hint_range(0.0, 1.0) = 0.52;
uniform float ramp_soft : hint_range(0.01, 0.5) = 0.21;
uniform float wrap : hint_range(0.0, 1.0) = 0.4;
uniform float shadow_floor : hint_range(0.0, 1.0) = 0.14;
// Plafond peint : une pente face au soleil ne BRÛLE pas (mesuré cam05 :
// mare à 68 %% de luma contre 33 %% à côté — au-dessus de la bande §1.5).
// Le peintre mute la masse la plus éclairée ; le plafond fait pareil.
uniform float lit_ceiling : hint_range(0.5, 1.0) = 0.78;

// -- familles de matière -----------------------------------------------------
// Roche ocre des pentes fortes (albédo — la surface module autour du gris).
uniform vec4 rock_color : source_color = vec4(0.46, 0.36, 0.28, 1.0);
// Terre des routes (albédo ; ISS-037 : la terre pleine rendait 0,97).
uniform vec4 earth_color : source_color = vec4(0.315, 0.25, 0.20, 1.0);
// Cendres de la Marche (désaturées, froides — l'orage n'est PAS du cyan).
uniform vec4 ash_color : source_color = vec4(0.34, 0.33, 0.36, 1.0);
// Fond humide : le lit tire vers le froid, jamais vers le noir.
uniform vec4 wet_bed_color : source_color = vec4(0.20, 0.27, 0.28, 1.0);

// La pente où l'herbe cède à la roche (composantes Y de la normale monde).
// 46° est la limite de marche : l'herbe tient un peu au-delà, la roche
// domine bien avant la paroi d'escalade.
uniform float rock_up_full : hint_range(0.0, 1.0) = 0.574; // ~55 degrés
uniform float rock_up_none : hint_range(0.0, 1.0) = 0.788; // ~38 degrés
// Strates de la roche : bandes horizontales larges, chaudes en arête.
uniform float strata_strength : hint_range(0.0, 0.3) = 0.05;
uniform float strata_frequency : hint_range(0.1, 4.0) = 0.5;

// -- surfaces réelles (ambientCG CC0, ART-T1 — AD-006 : la couleur photo
// reste subordonnée, le relief monte franchement) ----------------------------
uniform sampler2D grass_albedo : source_color, hint_default_white,
	filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_rough : hint_default_white, filter_linear_mipmap,
	repeat_enable;
uniform sampler2D rock_albedo : source_color, hint_default_white,
	filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_rough : hint_default_white, filter_linear_mipmap,
	repeat_enable;
uniform sampler2D earth_albedo : source_color, hint_default_white,
	filter_linear_mipmap, repeat_enable;
uniform sampler2D earth_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float grass_tile_m : hint_range(0.3, 12.0) = 5.5;
uniform float rock_tile_m : hint_range(0.3, 12.0) = 3.5;
uniform float earth_tile_m : hint_range(0.3, 12.0) = 4.5;
uniform float surface_blend : hint_range(0.0, 1.0) = 0.55;
uniform float surface_desaturate : hint_range(0.0, 1.0) = 0.7;
uniform float surface_normal_depth : hint_range(0.0, 2.0) = 0.95;
// Le détail s'éteint à distance : une tuile de 4 m vue à 300 m ne produit
// que du grésillement (leçon de la première capture de vallée V1).
uniform float surface_fade_near : hint_range(5.0, 200.0) = 45.0;
uniform float surface_fade_far : hint_range(10.0, 600.0) = 150.0;

// -- grain et macro (contre l'aplat, sans microbruit §1.6) -------------------
uniform sampler2D grain_texture : hint_default_white, filter_linear_mipmap,
	repeat_enable;
uniform float grain_strength : hint_range(0.0, 0.4) = 0.10;
uniform float grain_scale : hint_range(0.02, 2.0) = 0.35;
uniform float grain_roughness : hint_range(0.0, 0.5) = 0.18;
uniform float macro_variation : hint_range(0.0, 0.3) = 0.07;
uniform float macro_scale : hint_range(0.005, 0.2) = 0.03;

// Bord de route BRUITÉ : la terre mord l'herbe irrégulièrement (§14 :
// intégrée, pas plaquée). Échelle du bruit de bord en espace monde.
uniform float route_edge_scale : hint_range(0.05, 2.0) = 0.55;
uniform float route_edge_bite : hint_range(0.0, 1.0) = 0.45;

// -- diagnostic V2.1, CACHÉ par défaut (directive §11) -----------------------
uniform float diagnostic_amount : hint_range(0.0, 1.0) = 0.0;

varying vec3 world_position;
varying vec4 v_mask; // r humidité, g cendres — CUSTOM0 n'existe qu'au vertex.
varying vec4 v_diag;


void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_mask = CUSTOM0;
	v_diag = CUSTOM1;
}


void fragment() {
	vec3 world_normal = normalize((vec4(NORMAL, 0.0) * VIEW_MATRIX).xyz);
	float up = clamp(world_normal.y, 0.0, 1.0);
	float wetness = v_mask.r;
	float ash = v_mask.g;
	float route_mask = COLOR.a;

	// 1. Les grandes masses : herbe de région → terre de route → roche de
	// pente → cendres → humidité. L'ordre est celui de la géologie : la
	// roche perce tout, l'eau mouille tout.
	vec3 base = COLOR.rgb;
	// Bord de route irrégulier : le masque adouci est mordu par un bruit
	// monde — jamais une bande nette de largeur constante (§6.2 bible).
	float edge_noise = texture(grain_texture,
		world_position.xz * route_edge_scale * 0.1).r - 0.5;
	// V2.2R famille E : la route n'est plus un ruban de largeur constante —
	// un bruit LENT le long du monde fait varier sa largeur, l'interrompt
	// par endroits (l'herbe regagne le passage) et module sa force.
	float width_noise = texture(grain_texture,
		world_position.xz * 0.014).r;
	float route_w = smoothstep(0.28 + 0.30 * width_noise, 0.85,
		route_mask + edge_noise * route_edge_bite)
		* (0.45 + 0.85 * width_noise);
	base = mix(base, earth_color.rgb, route_w * 0.72);

	float rock_w = 1.0 - smoothstep(rock_up_full, rock_up_none, up);
	// Strates : bandes d'altitude larges, arête chaude, creux froid (§6.3).
	float strata_wave = sin(world_position.y * strata_frequency
		+ texture(grain_texture, world_position.xz * 0.01).r * 3.0);
	vec3 strata_rock = rock_color.rgb
		* (1.0 + strata_wave * strata_strength * vec3(1.15, 1.0, 0.8));
	base = mix(base, strata_rock, rock_w);

	// Cendres : on désature et on refroidit — l'identité de la Marche est
	// la matière éteinte, pas une couleur criarde (§10).
	float base_luma = dot(base, vec3(0.2126, 0.7152, 0.0722));
	base = mix(base, mix(vec3(base_luma), ash_color.rgb, 0.6), ash);

	// Humidité : plus sombre, plus froid, et le lit plein tire vers le fond.
	base *= mix(1.0, 0.82, wetness);
	base = mix(base, wet_bed_color.rgb, smoothstep(0.6, 1.0, wetness) * 0.65);

	// 2. Respiration macro et grain — contre l'aplat, à DEUX échelles
	// séparées (jamais deux bruits de même taille qui se battent, §6.2).
	// Macro par le bruit à TRÈS grande échelle : le produit de sinus de la
	// première passe dessinait une grille de taches régulières (~33 m) sur
	// la prairie — mesuré à la capture, régularité §7.17 interdite.
	float breath = texture(grain_texture,
		world_position.xz * macro_scale * 0.14).r - 0.5;
	base *= 1.0 + breath * macro_variation * 2.0;
	vec3 grain_uv = world_position * grain_scale;
	float grain = mix(texture(grain_texture, grain_uv.xz).r,
		texture(grain_texture, grain_uv.xy).r, clamp(1.0 - up, 0.0, 1.0));
	float signed_grain = grain - 0.5;
	base *= 1.0 + signed_grain * grain_strength * 2.0;

	// 3. Surface réelle : la famille suit la matière dominante. Herbe et
	// terre se projettent à plat (le sol est un sol) ; la roche mélange
	// plat et paroi par la normale, comme les rochers V1.
	float view_distance = length(VERTEX);
	float surface_reach = surface_blend
		* (1.0 - smoothstep(surface_fade_near, surface_fade_far, view_distance));
	float rough = 0.9;
	if (surface_reach > 0.001) {
		vec2 uv_grass = world_position.xz / max(grass_tile_m, 0.05);
		vec2 uv_earth = world_position.xz / max(earth_tile_m, 0.05);
		vec3 tile_rock = world_position / max(rock_tile_m, 0.05);
		float wall = clamp(1.0 - up, 0.0, 1.0);
		vec3 rock_surface = mix(texture(rock_albedo, tile_rock.xz).rgb,
			texture(rock_albedo, tile_rock.xy).rgb, wall);
		vec3 surface = texture(grass_albedo, uv_grass).rgb;
		surface = mix(surface, texture(earth_albedo, uv_earth).rgb, route_w);
		surface = mix(surface, rock_surface, rock_w);
		// AD-006 : modelé conservé, couleur subordonnée à la palette.
		float surface_luma = dot(surface, vec3(0.2126, 0.7152, 0.0722));
		surface = mix(surface, vec3(surface_luma), surface_desaturate);
		base *= mix(vec3(1.0), surface / 0.5, surface_reach);

		vec3 packed_normal = texture(grass_normal, uv_grass).rgb;
		packed_normal = mix(packed_normal,
			texture(earth_normal, uv_earth).rgb, route_w);
		packed_normal = mix(packed_normal, mix(
			texture(rock_normal, tile_rock.xz).rgb,
			texture(rock_normal, tile_rock.xy).rgb, wall), rock_w);
		NORMAL_MAP = packed_normal;
		NORMAL_MAP_DEPTH = surface_normal_depth * surface_reach;

		float surface_rough = mix(texture(grass_rough, uv_grass).r,
			mix(texture(rock_rough, tile_rock.xz).r,
				texture(rock_rough, tile_rock.xy).r, wall), rock_w);
		rough = mix(rough, surface_rough, 0.5 * surface_reach);
	}

	// L'eau abaisse la rugosité (§5.2 : pierre humide 0,35-0,65) ; le grain
	// la fait respirer.
	rough = mix(rough, 0.5, wetness);
	rough += signed_grain * grain_roughness;

	// Diagnostic V2.1 : la vérité whitebox reste disponible, JAMAIS visible
	// par défaut (fil de détente dans la suite de contrat).
	ALBEDO = mix(base, v_diag.rgb, diagnostic_amount);
	ROUGHNESS = clamp(rough, 0.0, 1.0);
}


void light() {
	// Half-Lambert : la lumière enveloppe la forme.
	float wrapped = clamp((dot(NORMAL, LIGHT) + wrap) / (1.0 + wrap), 0.0, 1.0);
	// Deux paliers FONDUS — le toon dur est interdit (§1.6).
	float band_low = smoothstep(ramp_low - ramp_soft, ramp_low + ramp_soft,
		wrapped);
	float band_high = smoothstep(ramp_high - ramp_soft, ramp_high + ramp_soft,
		wrapped);
	float lit = shadow_floor + (1.0 - shadow_floor)
		* (0.45 * band_low + 0.55 * band_high);
	lit = min(lit, lit_ceiling);
	// Gooch réservé au SOLEIL : un feu, une lampe gardent leur couleur.
	vec3 grade = LIGHT_IS_DIRECTIONAL
		? mix(shadow_tint.rgb, warm_tint.rgb, lit)
		: vec3(1.0);
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION * grade * lit;
}
