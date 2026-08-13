// SH_WorldV2Sky — ciel de fin d'après-midi de la vallée (V2.2-C, §9.1 bible).
//
// Un dégradé PEINT, pas une simulation : miel pâle vers le soleil (ouest,
// haut-gauche des fenêtres nord), bleu pastel à l'opposé, zénith bleu-gris
// discret — le ciel ne concurrence jamais la citadelle (§9.1). Aucun nuage
// ici : le nuage d'orage est de la GÉOMÉTRIE locale au-dessus de la
// citadelle (directive §15 : l'orage n'assombrit QUE sa zone).
shader_type sky;

uniform vec3 zenith_color : source_color = vec3(0.44, 0.58, 0.70);
uniform vec3 horizon_cool : source_color = vec3(0.72, 0.84, 0.90);
uniform vec3 horizon_warm : source_color = vec3(0.98, 0.87, 0.64);
uniform vec3 ground_color : source_color = vec3(0.38, 0.42, 0.44);
// Direction HORIZONTALE du soleil (vers où il se trouve), normalisée.
uniform vec3 sun_direction = vec3(-0.943, 0.0, -0.333);
uniform float warm_spread : hint_range(0.5, 8.0) = 2.4;


void sky() {
	float up = clamp(EYEDIR.y, -1.0, 1.0);
	if (up < 0.0) {
		COLOR = ground_color;
	} else {
		// Chaleur : forte près de l'horizon CÔTÉ soleil, fond pastel ailleurs.
		float toward_sun = clamp(dot(normalize(vec3(EYEDIR.x, 0.0, EYEDIR.z)),
			normalize(sun_direction)) * 0.5 + 0.5, 0.0, 1.0);
		float warm_amount = pow(toward_sun, warm_spread) * (1.0 - up);
		vec3 horizon = mix(horizon_cool, horizon_warm, warm_amount);
		COLOR = mix(horizon, zenith_color, smoothstep(0.0, 0.55, up));
	}
}
