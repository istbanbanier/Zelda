// SH_WorldV2Water — eau stylisée de la vallée (phase V2.2-C).
//
// Le contrat visuel de la bible (§8.2 / SH_WaterStylized) transposé au
// budget d'une fondation : couleur par PROFONDEUR (turquoise de gué →
// pétrole du lac), rides à deux échelles qui dérivent avec le COURANT,
// mousse de rive brisée là où l'eau meurt sur la berge — jamais un aplat
// bleu, jamais une dépendance écran (pas de SSR, pas de réfraction :
// fallback §27 compatible d'emblée).
//
// Données par SOMMET, cuites par le bâtisseur d'hydrologie :
//   COLOR.r  = facteur de profondeur 0-1 (surface − lit, borné) ;
//   COLOR.gb = direction du courant en plan, encodée 0-1 (0,5 = immobile).
// La géométrie, les gués et le niveau de l'eau sont GELÉS (V2.1) : ce
// shader habille, il ne déplace rien — un défaut physique resterait nu.
shader_type spatial;
render_mode cull_disabled;

uniform vec4 shallow_color : source_color = vec4(0.20, 0.44, 0.45, 0.60);
uniform vec4 deep_color : source_color = vec4(0.10, 0.27, 0.33, 0.90);
uniform vec4 foam_color : source_color = vec4(0.72, 0.80, 0.78, 0.85);
uniform sampler2D wave_noise : hint_default_white, filter_linear_mipmap,
	repeat_enable;
uniform float wave_scale : hint_range(0.02, 0.6) = 0.14;
uniform float wave_speed : hint_range(0.0, 0.3) = 0.045;
uniform float wave_strength : hint_range(0.0, 1.0) = 0.30;
// Profondeur (en facteur 0-1) sous laquelle la rive mousse.
uniform float foam_depth : hint_range(0.01, 0.5) = 0.16;

varying vec3 world_position;
varying float depth_factor;
varying vec2 flow_dir;


void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	depth_factor = COLOR.r;
	flow_dir = COLOR.gb * 2.0 - 1.0;
}


void fragment() {
	vec2 uv = world_position.xz * wave_scale;
	vec2 drift = flow_dir * TIME * wave_speed * 4.0;
	// Deux échelles, deux vitesses : jamais une vague uniforme (§7.6).
	float n1 = texture(wave_noise, uv + drift
		+ vec2(TIME * wave_speed, TIME * wave_speed * 0.6)).r;
	float n2 = texture(wave_noise, uv * 1.9 - drift * 0.7
		+ vec2(-TIME * wave_speed * 1.3, 0.0)).r;
	float ripple = n1 * 0.6 + n2 * 0.4;

	float depth = clamp(depth_factor, 0.0, 1.0);
	vec4 water = mix(shallow_color, deep_color, depth);
	water.rgb *= 1.0 + (ripple - 0.5) * wave_strength;

	// Mousse de rive FINE ET CASSÉE (§8.2) : eau très mince × bruit.
	float foam = (1.0 - smoothstep(0.0, foam_depth, depth))
		* smoothstep(0.48, 0.78, texture(wave_noise, uv * 2.3 + drift).r);
	water.rgb = mix(water.rgb, foam_color.rgb, foam * foam_color.a);

	ALBEDO = water.rgb;
	ALPHA = clamp(water.a + foam * 0.25, 0.0, 1.0);
	ROUGHNESS = 0.18;
	SPECULAR = 0.4;
}
