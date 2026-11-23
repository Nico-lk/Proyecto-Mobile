shader_type canvas_item;

// Shader "goo": da brillo de baba, bordes irregulares animados y una
// disolucion progresiva. Se usa tanto en el vomito como en las gotas de
// la estela y de la salpicadura.
uniform vec4 tinte : source_color = vec4(0.62, 1.0, 0.32, 1.0);
uniform float progreso : hint_range(0.0, 1.0) = 0.0;
uniform float fuerza_ruido : hint_range(0.0, 3.0) = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	if (base.a < 0.01) {
		discard;
	}

	// Dos capas de ruido que se mueven con el tiempo para que la baba "hierva"
	float n = ruido(UV * 7.0 + vec2(TIME * 0.7, -TIME * 0.4)) * 0.6
			+ ruido(UV * 16.0 - vec2(TIME * 0.35)) * 0.4;

	float borde = clamp(base.a * (0.6 + 0.8 * n * fuerza_ruido), 0.0, 1.0);
	float umbral = progreso * 1.05;
	float mascara = smoothstep(umbral, umbral + 0.12, borde);
	float alfa = mascara * (1.0 - progreso * 0.9);

	if (alfa < 0.01) {
		discard;
	}

	float brillo = smoothstep(0.45, 1.0, n) * 0.35;
	vec3 color = mix(base.rgb * tinte.rgb, vec3(0.9, 1.0, 0.6), brillo);
	COLOR = vec4(color, alfa);
}
