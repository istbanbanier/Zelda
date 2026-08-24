// SH_FlowerFieldSway — vent des nappes florales du Champ des mille fleurs.
//
// LOCAL AU LIEU (lot 1.R, voie C) : seul `flower_field_place.gd` le charge.
// C'est la grammaire de vent de la végétation V2.2 (`foliage_wind.gdshader`,
// gelée — relue, jamais modifiée) portée sur un maillage TEXTURÉ :
//   - balancement dont l'amplitude croît avec la hauteur du vertex — la base
//     d'une touffe ne glisse pas sur le sol ;
//   - phase dérivée de la position MONDE : deux fleurs voisines ondulent
//     presque en phase, une fleur lointaine non — aucune vague uniforme ;
//   - variation par INSTANCE via COLOR (MultiMesh use_colors), comme les
//     teintes d'herbe V2.2 — pas de custom data, la V2.2 n'en pose pas.
// Ce que la V2.2 ne fait pas et qu'il faut ici : échantillonner l'atlas
// Quaternius (les pétales vivent dans la texture, pas dans un albédo plat).
// `tone` multiplie l'échantillon — la teinte FINALE se juge sur une capture
// rendue, jamais sur cette valeur (gain ≈ 1,8 non linéaire, scripts/CLAUDE.md).
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D atlas: source_color;
uniform vec4 tone: source_color = vec4(1.0, 1.0, 1.0, 1.0);
// L'atlas Quaternius ne porte NI blanc NI bleu — pétales roses ou jaunes
// seulement (mesuré sur la capture iter1 : la « nappe blanche » rendait
// rose). Une multiplication ne peut pas blanchir : on DÉSATURE d'abord
// vers la luminance, puis `tone` recolore (>1 autorisé pour éclaircir).
uniform float desaturation = 0.0;
// En unités NATIVES du maillage (l'échelle d'instance ~0,2 les ramène au
// monde : 0,25 natif => ~0,05 m rendu).
uniform float sway_amplitude = 0.25;
uniform float sway_speed = 1.3;
// Hauteur native du maillage source : normalise VERTEX.y en facteur 0-1.
uniform float mesh_height = 2.0;

varying vec3 tint;

void vertex() {
	tint = COLOR.rgb;
	float height_factor = clamp(VERTEX.y / mesh_height, 0.0, 1.0);
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float phase = world_pos.x * 0.35 + world_pos.z * 0.28;
	VERTEX.x += sin(TIME * sway_speed + phase) * sway_amplitude * height_factor;
	VERTEX.z += cos(TIME * sway_speed * 0.8 + phase)
		* sway_amplitude * 0.6 * height_factor;
}

void fragment() {
	vec3 base = texture(atlas, UV).rgb;
	float luma = dot(base, vec3(0.299, 0.587, 0.114));
	base = mix(base, vec3(luma), desaturation);
	ALBEDO = base * tone.rgb * tint;
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
}
