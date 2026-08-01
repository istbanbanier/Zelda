// SH_FoliageWind (MASTER_SPEC §7.9, §7.5) — version graybox V4.2.
//
// Balancement basse fréquence + mouvement fin des pointes : l'amplitude croît
// avec la hauteur du vertex (une base de touffe ne glisse pas sur le sol), la
// phase vient de la position MONDE (deux brins voisins ondulent presque en
// phase, un brin lointain non — aucune vague uniforme). Teinte par instance
// via COLOR (MultiMesh use_colors). Aucun recalcul CPU (§7.5).
shader_type spatial;
render_mode cull_disabled;

uniform vec3 albedo: source_color = vec3(0.4, 0.6, 0.25);
uniform float sway_amplitude = 0.07;
uniform float sway_speed = 1.3;
// Hauteur du maillage source : normalise VERTEX.y en facteur 0-1.
uniform float blade_height = 0.55;

varying vec3 tint;

void vertex() {
	tint = COLOR.rgb;
	// Origine de la touffe AU SOL : VERTEX.y va de 0 à blade_height.
	float height_factor = clamp(VERTEX.y / blade_height, 0.0, 1.0);
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float phase = world_pos.x * 0.35 + world_pos.z * 0.28;
	VERTEX.x += sin(TIME * sway_speed + phase) * sway_amplitude * height_factor;
	VERTEX.z += cos(TIME * sway_speed * 0.8 + phase)
		* sway_amplitude * 0.6 * height_factor;
}

void fragment() {
	ALBEDO = albedo * tint;
	ROUGHNESS = 0.9;
}
