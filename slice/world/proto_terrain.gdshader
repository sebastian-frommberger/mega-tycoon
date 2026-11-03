// Prototyp-Welt (Phase 4, TA): Gelaende mit Bodenkarte (08_landschaft Weg A, EIN Sampler).
// proto_boden.png: RGB = Klassenfarbe (sRGB, Palette 08), A = Klasse * 20 + 10. filter_nearest + Rauschversatz der
// Abtastposition -> Klassenkanten scharf, aber nicht als 25-m-Treppe (Rand ausgefranst um +-rand_versatz_m / 2).
// Prozedural darueber: Kronentupfen im Wald, Gewann-Streifen im Acker, Fels an steilen Flanken, Ufersaum an Seen/Teichen
// (Hoehe ueber Pegel, bis 4 stehende Gewaesser als Uniform). Szene in Metern (1 Einheit = 1 m).
shader_type spatial;
render_mode cull_back, diffuse_lambert;

uniform sampler2D boden : source_color, filter_nearest, repeat_disable;
uniform vec4 boden_rect = vec4(-1000.0, -1000.0, 4000.0, 3600.0);   // xy = Weltursprung der Karte (x,z), zw = Ausdehnung (m)
uniform float rand_versatz_m = 22.0;
uniform vec3 c_ufer : source_color = vec3(0.420, 0.440, 0.330);    // #6B7054 = water.gdshader c_ufer
uniform vec3 c_fels : source_color = vec3(0.502, 0.451, 0.380);    // #807361
uniform float fels_ab_hang = 0.42;
uniform float fels_voll_hang = 0.62;
uniform float rauschen_staerke = 0.05;
uniform float tupfen_m = 9.0;               // Kronentupfen 8-12 m (08 d)
uniform float tupfen_staerke = 0.16;
uniform float streifen_m = 10.0;            // Ackerstreifen 8-15 m (08 b)
uniform vec4 gewaesser[4];                  // (x, z, r_aussen, pegel) stehende Gewaesser
uniform int gewaesser_n = 0;
uniform float ufer_hoehe_m = 0.35;           // Saum ueber dem Pegel

varying vec3 w_pos;
varying vec3 w_nrm;

float h21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	w_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 p = w_pos.xz;
	vec2 j = vec2(vnoise(p * 0.075), vnoise(p * 0.075 + vec2(17.3, 5.1))) - 0.5;
	j += (vec2(vnoise(p * 0.21 + 3.7), vnoise(p * 0.21 + 9.2)) - 0.5) * 0.5;
	vec4 b = texture(boden, (p + j * rand_versatz_m - boden_rect.xy) / boden_rect.zw);
	int id = int(floor(b.a * 255.0 / 20.0 + 0.01));
	vec3 col = b.rgb;
	float nz = vnoise(p * 0.012) * 0.6 + vnoise(p * 0.056) * 0.4;
	col *= 1.0 + (nz - 0.5) * 2.0 * rauschen_staerke;
	if (id == 6) {             // Waldboden: Kronentupfen
		float t = vnoise(p / tupfen_m) * 0.65 + vnoise(p / (tupfen_m * 0.45)) * 0.35;
		col *= mix(1.0 - tupfen_staerke, 1.0 + tupfen_staerke * 0.6, smoothstep(0.3, 0.7, t));
	} else if (id == 3 || id == 4) {   // Acker: Streifen je Gewann (200 x 125 m), Richtung je Block
		vec2 blk = floor(p / vec2(200.0, 125.0));
		float a = h21(blk + 0.37) * 3.14159;
		vec2 dir = vec2(cos(a), sin(a));
		float s = fract(dot(p, dir) / streifen_m);
		col *= 0.95 + 0.065 * smoothstep(0.42, 0.5, s) * (1.0 - smoothstep(0.92, 1.0, s));
	} else if (id == 11) {     // Wasserklasse: sichtbar ist dort nur das Ufer (Wasser kommt als eigenes Mesh)
		col = c_ufer;
	}
	// stehende Gewaesser: Ufersaum nach Hoehe ueber Pegel
	for (int i = 0; i < gewaesser_n; i++) {
		vec4 g = gewaesser[i];
		if (distance(p, g.xy) < g.z) {
			float u = 1.0 - smoothstep(0.05, ufer_hoehe_m, w_pos.y - g.w);
			col = mix(col, c_ufer, u * 0.7);
		}
	}
	// Fels an steilen Flanken (fein)
	float hang = 1.0 - normalize(w_nrm).y;
	col = mix(col, c_fels * (0.94 + 0.12 * vnoise(p * 0.05)), smoothstep(fels_ab_hang, fels_voll_hang, hang));
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.12;
}
