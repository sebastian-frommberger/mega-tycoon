shader_type spatial;
// Phase 4 Welle 1 (Felix): Material des Straßenbands (proto_strassenband.gd). Keine Kacheln, keine Fugen:
//   UV.x = Querlage, normiert auf die halbe Fahrbahn (0 Mitte, ±1 Fahrbahnkante, |u| > 1 Bankett/Graben)
//   UV.y = Bogenlänge s in Metern (durchgehend über das ganze Band, auch über Brücke)
// Körnung triplanar in Weltkoordinaten (prozedurales Rauschen, keine Textur), damit es an Hängen nicht streckt.
// Mittellinie = dunkle Kiesspur (1820: keine Farbmarkierung), Kanten = Randsteine/Wasserrinne.

uniform vec3 farbe_fahrbahn : source_color = vec3(0.64, 0.58, 0.47);
uniform vec3 farbe_rand : source_color = vec3(0.47, 0.42, 0.35);
uniform vec3 farbe_bankett : source_color = vec3(0.55, 0.52, 0.40);
uniform vec3 farbe_graben : source_color = vec3(0.33, 0.40, 0.24);
uniform float linie_staerke = 0.28;
uniform float bankett_bis = 1.18;

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float koernung(vec2 p) {
	return vnoise(p * 0.9) * 0.55 + vnoise(p * 3.7) * 0.3 + vnoise(p * 11.0) * 0.15;
}

float triplanar(vec3 p, vec3 n) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z + 1e-5);
	return koernung(p.zy) * w.x + koernung(p.xz) * w.y + koernung(p.xy) * w.z;
}

void fragment() {
	float u = abs(UV.x);
	float n = triplanar(wpos, wnrm);
	vec3 c;
	if (u <= 1.0) {
		c = farbe_fahrbahn * (0.86 + 0.28 * n);
		float mitte = (1.0 - smoothstep(0.04, 0.09, u)) * step(0.45, fract(UV.y / 7.0));
		float kante = smoothstep(0.86, 0.97, u);
		c = mix(c, farbe_rand, max(mitte * linie_staerke, kante * 0.75));
	} else if (u <= bankett_bis) {
		c = farbe_bankett * (0.85 + 0.3 * n);
	} else {
		c = farbe_graben * (0.8 + 0.4 * n);
	}
	ALBEDO = c;
	ROUGHNESS = 0.95;
}
