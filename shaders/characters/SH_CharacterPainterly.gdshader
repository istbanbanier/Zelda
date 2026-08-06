// SH_CharacterPainterly — LE shader du style (bible §21.1, décision
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
render_mode specular_disabled;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.85;

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
uniform float shadow_floor : hint_range(0.0, 1.0) = 0.26;

uniform float rim_strength : hint_range(0.0, 1.0) = 0.1;
uniform float rim_power : hint_range(1.0, 8.0) = 3.5;
uniform vec4 rim_color : source_color = vec4(1.0, 0.92, 0.75, 1.0);

// Variation macro très lente (§21.1) : de grandes respirations de teinte
// en espace monde — contre l'aplat uniforme, sans microbruit.
uniform float macro_variation : hint_range(0.0, 0.3) = 0.06;
uniform float macro_scale : hint_range(0.005, 0.2) = 0.03;

varying vec3 world_position;


void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {
	vec3 base = albedo_color.rgb * texture(albedo_texture, UV).rgb;
	// Respiration macro : deux ondes lentes croisées, jamais du bruit fin.
	float breath = sin(world_position.x * macro_scale * 6.28318)
		* sin(world_position.z * macro_scale * 4.71238);
	base *= 1.0 + breath * macro_variation;
	ALBEDO = base;
	ROUGHNESS = roughness_value;
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
