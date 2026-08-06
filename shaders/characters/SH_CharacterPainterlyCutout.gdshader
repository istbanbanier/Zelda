// SH_CharacterPainterlyCutout — variante DÉCOUPE de LE shader du style (bible §21.1, décision
// verrouillée n°2 : « le rendu se gagne dans SH_CharacterPainterly +
// la lumière »). Peinture, pas physique :
//   - half-Lambert (wrap) : la lumière ENVELOPPE, jamais de noir dur ;
//   - 2-3 paliers FONDUS (smoothstep adouci) — le toon dur est interdit ;
//   - modèle chaud/froid (Gooch) réservé au SOLEIL (LIGHT_IS_DIRECTIONAL,
//     vérifié dans la source 4.7.1) : les ombres tirent vers le froid,
//     la lumière vers le chaud ; le feu de camp garde SA couleur ;
//   - rim discret dépendant de la vue — jamais un contour uniforme ;
//   - spéculaire coupé : le painterly est mat, le brillant viendra des
//     matériaux qui le méritent (métal), pas d'un hotspot plastique.
shader_type spatial;
render_mode specular_disabled, cull_disabled;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.85;
// Le mesh porte-t-il des couleurs de sommets QUI COMPTENT ? Le
// terrain de la vallée en a que son matériau d'origine ignorait :
// les multiplier sans condition rendait le sol gris-bleu.
uniform bool use_vertex_color = false;
uniform float alpha_scissor : hint_range(0.01, 1.0) = 0.5;

// Ombres froides / lumières chaudes (§1.4 : ombre #4C5B75, soleil miel).
uniform vec4 shadow_tint : source_color = vec4(0.42, 0.48, 0.60, 1.0);
uniform vec4 warm_tint : source_color = vec4(1.06, 0.98, 0.88, 1.0);

// Les paliers : pied d'ombre, pied de lumière, largeur du FONDU.
uniform float ramp_low : hint_range(0.0, 1.0) = 0.22;
uniform float ramp_high : hint_range(0.0, 1.0) = 0.58;
uniform float ramp_soft : hint_range(0.01, 0.5) = 0.16;
// Half-Lambert : combien la lumière enveloppe (0 = Lambert brut).
uniform float wrap : hint_range(0.0, 1.0) = 0.3;
// Plancher d'ombre : jamais de noir bouché (§1.5 : ombres 18-38 %).
uniform float shadow_floor : hint_range(0.0, 1.0) = 0.14;

uniform float rim_strength : hint_range(0.0, 1.0) = 0.1;
uniform float rim_power : hint_range(1.0, 8.0) = 3.5;
uniform vec4 rim_color : source_color = vec4(1.0, 0.92, 0.75, 1.0);

// Lot 10 — GRAIN procédural (§21.1) : une texture de bruit généré par
// le moteur casse l'aplat uni. Projeté en espace MONDE (triplanaire
// simplifié sur XZ + Y) pour ne dépendre d'aucune UV : les modèles du
// kit n'ont pas tous des UV utilisables pour du détail.
uniform sampler2D grain_texture : hint_default_white, filter_linear_mipmap,
	repeat_enable;
uniform float grain_strength : hint_range(0.0, 0.4) = 0.12;
uniform float grain_scale : hint_range(0.02, 2.0) = 0.35;
// Le grain creuse aussi la rugosité : une pierre grainée accroche la
// lumière différemment d'une pierre lisse — c'est ça qui « fait matière ».
uniform float grain_roughness : hint_range(0.0, 0.5) = 0.18;

// Lot 11 — SURFACE réelle (textures ambientCG CC0 déposées par le
// propriétaire, ART-T1). La bible INTERDIT la texture photographique
// brute (§1.6/§7.1) : elle ne remplace donc PAS l'albedo peint — elle
// le MODULE, désaturée vers sa luminance, à force réglable. Le vrai
// gain est le RELIEF (normal map) : la lumière peinte a enfin de la
// matière à sculpter.
uniform sampler2D surface_texture : source_color, hint_default_white,
	filter_linear_mipmap, repeat_enable;
uniform sampler2D surface_normal : hint_normal, filter_linear_mipmap,
	repeat_enable;
uniform sampler2D surface_rough : hint_default_white,
	filter_linear_mipmap, repeat_enable;
// Taille d'UNE tuile en MÈTRES (invariant du projet : 1 unité = 1 m).
uniform float surface_tile_m : hint_range(0.3, 12.0) = 4.0;
uniform float surface_blend : hint_range(0.0, 1.0) = 0.0;
uniform float surface_desaturate : hint_range(0.0, 1.0) = 0.7;
uniform float surface_normal_depth : hint_range(0.0, 2.0) = 0.7;
uniform float surface_roughness_blend : hint_range(0.0, 1.0) = 0.5;
// Distance à laquelle le détail de surface s'éteint. Une tuile de 3 m
// vue à 400 m ne porte plus d'information : elle ne produit que du
// grésillement (défaut vu sur la première capture de la vallée
// entière — le laboratoire de 80 m ne pouvait pas le révéler).
uniform float surface_fade_near : hint_range(5.0, 200.0) = 45.0;
uniform float surface_fade_far : hint_range(10.0, 600.0) = 130.0;

// Variation macro très lente (§21.1) : de grandes respirations de teinte
// en espace monde — contre l'aplat uniforme, sans microbruit.
uniform float macro_variation : hint_range(0.0, 0.3) = 0.06;
uniform float macro_scale : hint_range(0.005, 0.2) = 0.03;

varying vec3 world_position;


void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {
	vec4 sampled = texture(albedo_texture, UV);
	// Découpe : les bords transparents des cartes de feuilles NE
	// dessinent PAS de contour sombre (§1.6) — le seuil coupe net.
	ALPHA = albedo_color.a * sampled.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor;
	vec3 base = albedo_color.rgb * sampled.rgb;
	// Respiration macro : deux ondes lentes croisées, jamais du bruit fin.
	float breath = sin(world_position.x * macro_scale * 6.28318)
		* sin(world_position.z * macro_scale * 4.71238);
	base *= 1.0 + breath * macro_variation;
	// Grain : deux projections monde mélangées par la normale — pas de
	// couture visible, aucune UV requise.
	vec3 grain_uv = world_position * grain_scale;
	vec3 world_normal = normalize(
		(vec4(NORMAL, 0.0) * VIEW_MATRIX).xyz);
	float up = abs(world_normal.y);
	float grain = mix(
		texture(grain_texture, grain_uv.xz).r,
		texture(grain_texture, grain_uv.xy).r,
		clamp(1.0 - up, 0.0, 1.0));
	// Centré sur 0 : le grain assombrit ET éclaircit, il ne salit pas.
	float signed_grain = grain - 0.5;
	base *= 1.0 + signed_grain * grain_strength * 2.0;

	// Surface : même projection monde à deux axes, à l'échelle
	// physique de la tuile. `surface_blend` à 0 = aucune surface,
	// donc les matériaux qui n'en veulent pas ne paient rien.
	float surface_rough_value = 0.0;
	float view_distance = length(VERTEX);
	float surface_reach = surface_blend * (1.0 - smoothstep(
		surface_fade_near, surface_fade_far, view_distance));
	if (surface_reach > 0.001) {
		vec3 tile_uv = world_position / max(surface_tile_m, 0.05);
		vec2 uv_flat = tile_uv.xz;
		vec2 uv_wall = tile_uv.xy;
		float wall = clamp(1.0 - up, 0.0, 1.0);
		vec3 surface = mix(
			texture(surface_texture, uv_flat).rgb,
			texture(surface_texture, uv_wall).rgb, wall);
		// Désaturation : on garde le MODELÉ de la photo, pas sa
		// couleur — la palette reste celle de la bible §1.4.
		float surface_luma = dot(surface, vec3(0.2126, 0.7152, 0.0722));
		surface = mix(surface, vec3(surface_luma), surface_desaturate);
		// Centré sur le gris moyen : la surface éclaircit ET assombrit.
		base *= mix(vec3(1.0), surface / 0.5, surface_reach);
		vec3 packed_normal = mix(
			texture(surface_normal, uv_flat).rgb,
			texture(surface_normal, uv_wall).rgb, wall);
		NORMAL_MAP = packed_normal;
		NORMAL_MAP_DEPTH = surface_normal_depth * surface_reach;
		surface_rough_value = mix(
			texture(surface_rough, uv_flat).r,
			texture(surface_rough, uv_wall).r, wall);
	}
	if (use_vertex_color) {
		base *= COLOR.rgb;
	}
	ALBEDO = base;
	float rough = roughness_value + signed_grain * grain_roughness;
	if (surface_reach > 0.001) {
		rough = mix(rough, surface_rough_value,
			surface_roughness_blend * surface_reach);
	}
	ROUGHNESS = clamp(rough, 0.0, 1.0);
	// Rim : discret, côté lumière implicite par la vue — pas un halo.
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	EMISSION = rim_color.rgb * rim * rim_strength;
}


void light() {
	// Half-Lambert : la lumière enveloppe la forme.
	float wrapped = clamp((dot(NORMAL, LIGHT) + wrap) / (1.0 + wrap),
		0.0, 1.0);
	// Deux paliers FONDUS — la peinture pose de grandes zones, le fondu
	// évite la cassure toon (interdite).
	float band_low = smoothstep(ramp_low - ramp_soft, ramp_low + ramp_soft,
		wrapped);
	float band_high = smoothstep(ramp_high - ramp_soft, ramp_high + ramp_soft,
		wrapped);
	float lit = shadow_floor + (1.0 - shadow_floor)
		* (0.45 * band_low + 0.55 * band_high);
	// Gooch : réservé au SOLEIL — un feu de camp garde sa couleur.
	vec3 grade = LIGHT_IS_DIRECTIONAL
		? mix(shadow_tint.rgb, warm_tint.rgb, lit)
		: vec3(1.0);
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION * grade * lit;
}
