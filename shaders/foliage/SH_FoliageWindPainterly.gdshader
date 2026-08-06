// SH_FoliageWindPainterly — déclinaison FEUILLAGE du style (bible
// §21.4 + décision verrouillée n°2) : le vent de SH_FoliageWind au
// sommet (vertex) + le modèle de lumière peinte de
// SH_CharacterPainterly (light). Utilisée par le HeroShotLab ; la
// vallée garde son shader graybox tant que la propagation V4 n'est pas
// décidée (AD-004).
//
// Le vent : balancement basse fréquence dont l'amplitude croît avec la
// hauteur du vertex (la base d'une touffe ne glisse pas sur le sol),
// phase par position MONDE — deux brins voisins ondulent presque en
// phase, un brin lointain non. Aucun recalcul CPU (§7.5).
shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform vec4 albedo_color : source_color = vec4(0.4, 0.6, 0.25, 1.0);
uniform float roughness_value : hint_range(0.0, 1.0) = 0.9;

uniform float sway_amplitude = 0.07;
uniform float sway_speed = 1.3;
// Hauteur du maillage source : normalise VERTEX.y en facteur 0-1.
uniform float blade_height = 0.55;

// Ombres froides / lumières chaudes (§1.4) — mêmes ancres que le
// shader personnage.
uniform vec4 shadow_tint : source_color = vec4(0.42, 0.48, 0.60, 1.0);
uniform vec4 warm_tint : source_color = vec4(1.06, 0.98, 0.88, 1.0);
uniform float ramp_low : hint_range(0.0, 1.0) = 0.22;
uniform float ramp_high : hint_range(0.0, 1.0) = 0.58;
uniform float ramp_soft : hint_range(0.01, 0.5) = 0.16;
uniform float wrap : hint_range(0.0, 1.0) = 0.3;
uniform float shadow_floor : hint_range(0.0, 1.0) = 0.26;


void vertex() {
	float height_factor = clamp(VERTEX.y / blade_height, 0.0, 1.0);
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float phase = world_pos.x * 0.35 + world_pos.z * 0.28;
	VERTEX.x += sin(TIME * sway_speed + phase)
		* sway_amplitude * height_factor;
	VERTEX.z += cos(TIME * sway_speed * 0.8 + phase)
		* sway_amplitude * 0.6 * height_factor;
}


void fragment() {
	ALBEDO = albedo_color.rgb;
	ROUGHNESS = roughness_value;
}


void light() {
	// Half-Lambert : la lumière enveloppe le brin (un plan fin cull_off
	// a des normales dures — le wrap est encore plus important ici).
	float wrapped = clamp((dot(NORMAL, LIGHT) + wrap) / (1.0 + wrap),
		0.0, 1.0);
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
