// SH_TurquoiseSpringWater — l'eau de la SOURCE AUX REFLETS, et d'elle seule.
//
// POURQUOI UN SHADER LOCAL PLUTÔT QUE `SH_WorldV2Water`. L'hydrologie V2.2
// est gelée et son shader habille des rivières qu'on regarde d'assez haut.
// Ici la caméra de jugement est GELÉE et presque au ras de l'eau, et c'est
// ce qui casse tout. Géométrie mesurée : `turquoise_spring_joueur` est à
// (−126,5 ; 13,7 ; 40,0), le plan d'eau à ~12,08 m, le centre de vasque à
// 14,9 m — soit une INCIDENCE DE 6,1°.
//
// Mesuré au pixel sur les captures du commit 7c58573 :
//
//   même vasque, caméra haute (`_identite`)  H = 190°  S = 0,237  V = 0,437
//   même vasque, caméra JOUEUR (rasante)     H = 137°  S = 0,079  V = 0,534
//   rivière V2.2 de référence, caméra haute  H = 179°  S = 0,273  V = 0,436
//
// La même eau, le même shader, la même exposition, deux angles : la
// saturation tombe de 0,237 à 0,079 et la teinte quitte le turquoise pour le
// gris-vert. Ce n'est donc PAS un défaut d'albédo — c'est l'incidence. Deux
// mécanismes s'additionnent au ras :
//   1. la composante spéculaire renvoie le CIEL, qui est blanc-bleu, et elle
//      domine d'autant plus que l'angle est rasant (Fresnel) ;
//   2. l'alpha de rive (0,60) laisse passer l'herbe pâle du pad, dont la
//      couleur se mélange à celle de l'eau sur presque toute la surface vue.
// Corriger l'albédo seul ne peut rien contre ni l'un ni l'autre : c'est le
// piège exact de `scripts/CLAUDE.md` transposé à l'angle de vue.
//
// CE QUE CE SHADER FAIT DIFFÉREMMENT, ET RIEN D'AUTRE :
//
//   * L'OPACITÉ MONTE AVEC L'INCIDENCE. Au ras, l'eau devient quasi opaque
//     — ce qui est d'ailleurs vrai physiquement : on voit d'autant moins à
//     travers qu'on regarde de biais. Le fond pâle cesse de délaver la
//     teinte. Vue de haut, l'eau redevient transparente et la vasque garde
//     sa lecture de profondeur.
//   * LE REFLET RASANT EST TEINTÉ, PAS BLANC. Au lieu de laisser la
//     spéculaire du moteur poser un voile blanc, la couche rasante est
//     mélangée DANS l'albédo avec une couleur choisie (`glaze_color`), et la
//     spéculaire est rabattue très bas. On garde donc l'effet « l'eau
//     s'éclaire quand on la regarde de biais » sans qu'il soit blanc.
//     C'est ce qui interdit la « nappe blanche » rejetée.
//   * AUCUNE ÉMISSION. « Eau éclairée de l'intérieur » est l'une des trois
//     causes de rejet écrites au contrat du lieu. La luminosité vient de
//     l'albédo et de la lumière du monde, jamais d'une source inventée.
//
// La convention de sommet est celle de l'hydrologie V2.2, à l'identique —
// c'est ce qui garde la continuité de construction avec la rivière :
//   COLOR.r  = facteur de profondeur 0-1 ;
//   COLOR.gb = direction du courant en plan, encodée 0-1 (0,5 = immobile) ;
//   COLOR.a  = opacité de base.
shader_type spatial;
render_mode cull_disabled;

// Turquoise de rive et pétrole de fond. Plus saturés que ceux de la rivière
// V2.2 : ce lieu est « l'œil turquoise », la seule note froide saturée d'un
// ravin brun-vert, et c'est écrit au contrat.
// v2 — RABATTU SUR MESURE. Le premier jeu a fonctionné, et TROP : dans la
// caméra joueur gelée la saturation est passée de 0,079 à 0,577, et le gros
// plan est monté à 0,727 — plus du double de la rivière V2.2 de référence
// (0,273 dans la même image). Une eau deux fois plus saturée que toute
// l'eau du monde ne lit plus « source turquoise » mais « piscine ». Les
// trois couleurs remontent donc leur canal rouge : l'écart avec la rivière
// doit rester lisible — c'est « l'œil turquoise » du ravin — sans devenir
// une couleur qui n'existe nulle part ailleurs dans la vallée.
uniform vec4 shallow_color : source_color = vec4(0.225, 0.520, 0.500, 0.72);
uniform vec4 deep_color : source_color = vec4(0.100, 0.288, 0.322, 0.96);
uniform vec4 foam_color : source_color = vec4(0.70, 0.82, 0.80, 0.85);
// LA COULEUR DU REFLET RASANT. C'est elle qui remplace le blanc du ciel.
// Volontairement plus CLAIRE et plus saturée que le corps : au ras, la
// surface doit s'allumer en turquoise, pas s'éteindre en gris.
uniform vec4 glaze_color : source_color = vec4(0.340, 0.630, 0.612, 1.0);
uniform float glaze_power : hint_range(0.5, 6.0) = 2.1;
uniform float glaze_strength : hint_range(0.0, 1.0) = 0.55;
// Part d'opacité regagnée au ras (1 = totalement opaque de biais).
uniform float grazing_opacity : hint_range(0.0, 1.0) = 0.95;

uniform sampler2D wave_noise : hint_default_white, filter_linear_mipmap,
	repeat_enable;
uniform float wave_scale : hint_range(0.02, 0.6) = 0.17;
uniform float wave_speed : hint_range(0.0, 0.3) = 0.038;
uniform float wave_strength : hint_range(0.0, 1.0) = 0.26;
uniform float foam_depth : hint_range(0.01, 0.5) = 0.16;
// Spéculaire et rugosité : le hotspot blanc du soleil est ce qu'on cherche
// à éviter. La brillance du lieu passe par `glaze_color`, pas par un miroir.
uniform float water_roughness : hint_range(0.0, 1.0) = 0.42;
uniform float water_specular : hint_range(0.0, 1.0) = 0.10;

varying vec3 world_position;
varying float depth_factor;
varying vec2 flow_dir;
varying float vertex_opacity;


void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	depth_factor = COLOR.r;
	flow_dir = COLOR.gb * 2.0 - 1.0;
	vertex_opacity = COLOR.a;
}


void fragment() {
	vec2 uv = world_position.xz * wave_scale;
	vec2 drift = flow_dir * TIME * wave_speed * 4.0;
	// Deux échelles, deux vitesses : jamais une vague uniforme.
	float n1 = texture(wave_noise, uv + drift
		+ vec2(TIME * wave_speed, TIME * wave_speed * 0.6)).r;
	float n2 = texture(wave_noise, uv * 1.9 - drift * 0.7
		+ vec2(-TIME * wave_speed * 1.3, 0.0)).r;
	float ripple = n1 * 0.6 + n2 * 0.4;

	float depth = clamp(depth_factor, 0.0, 1.0);
	vec4 water = mix(shallow_color, deep_color, depth);
	water.rgb *= 1.0 + (ripple - 0.5) * wave_strength;

	// FRESNEL — 0 de face, 1 au ras. `VIEW` pointe du fragment vers la
	// caméra, `NORMAL` est la normale de surface : leur produit scalaire est
	// le cosinus de l'angle d'incidence. À 6° au-dessus du plan d'eau il
	// vaut cos(84°) ≈ 0,10, donc `rasant` ≈ 0,8 — la couche rasante DOMINE
	// exactement là où la mesure montre que la teinte se perdait.
	float ndv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float rasant = pow(1.0 - ndv, glaze_power);
	// Le vernis ondule avec les rides : une couche rasante uniforme ferait
	// une plaque de couleur, et une plaque se lit comme du plastique.
	float vernis = rasant * glaze_strength * (0.82 + 0.36 * ripple);
	water.rgb = mix(water.rgb, glaze_color.rgb, clamp(vernis, 0.0, 1.0));

	// Mousse de rive FINE ET CASSÉE : eau très mince × bruit.
	float foam = (1.0 - smoothstep(0.0, foam_depth, depth))
		* smoothstep(0.48, 0.78, texture(wave_noise, uv * 2.3 + drift).r);
	water.rgb = mix(water.rgb, foam_color.rgb, foam * foam_color.a);

	ALBEDO = water.rgb;
	// L'OPACITÉ SUIT L'INCIDENCE : au ras, le fond pâle ne délave plus rien.
	float alpha = clamp(water.a + foam * 0.25, 0.0, 1.0);
	alpha = mix(alpha, 1.0, rasant * grazing_opacity);
	ALPHA = alpha * vertex_opacity;
	ROUGHNESS = water_roughness;
	SPECULAR = water_specular;
}
