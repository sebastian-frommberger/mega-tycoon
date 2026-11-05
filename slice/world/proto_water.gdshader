// Wasser-Shader (Design Sprint Welt, TEAM-02, Skizze Phase 2). Einfach und billig (Basti E2):
//  - OPAK: keine Transparenz, keine Tiefen-/Screen-Textur, kein Sortieren. Läuft im Compatibility-Renderer (opengl3).
//  - Tiefe kommt als Vertexfarbe (COLOR.r = Tiefe / tiefe_skala_m), gebaut auf DEMSELBEN Knotenraster und derselben
//    Dreiecksteilung wie das Gelände -> die interpolierte Tiefe ist pro Pixel exakt (Wasserspiegel minus Gelände) und
//    läuft an der Uferlinie genau auf 0. Dort wird die Farbe zur Uferfarbe: weiche Kante ohne Alpha.
//  - Bewegung: 2 Sinuswellen + 1 Wertrauschen in festen Richtungen, mit dem Fließvektor (UV, m/s) in zwei Phasen
//    verschoben (Flowmap-Prinzip ohne Textur), nur als Normale (kein Vertex-Versatz). Fresnel mischt eine Himmelsfarbe ein (keine Reflexions-Probe).
//  - Keine Texturen, keine Downloads. Kosten je Pixel: 2 Phasen × (2 cos + 3 Wertrauschen à 4 Hash) + pow, ~200 ALU, 0 Texturzugriffe.
shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec3 c_flach  : source_color = vec3(0.333, 0.565, 0.612);   // #55909C  flaches Wasser (Kiesgrund schimmert)
uniform vec3 c_tief   : source_color = vec3(0.204, 0.373, 0.494);   // #345F7E  tiefe Rinne
uniform vec3 c_ufer   : source_color = vec3(0.420, 0.440, 0.330);   // #6B7054  = terrain.gdshader c_ufer (nasser Uferschlamm)
uniform vec3 c_himmel : source_color = vec3(0.760, 0.840, 0.910);   // = main.gd SKY_HORIZON
uniform float m_pro_einheit = 25.0;      // Meter je Szeneneinheit (S7: 1 Feld = 25 m)
uniform float tiefe_skala_m = 8.0;       // COLOR.r = Tiefe / tiefe_skala_m (Builder world/water_s7.gd)
uniform float tiefe_voll_m = 2.5;        // ab dieser Tiefe volle Tiefenfarbe
uniform float ufer_breite_m = 0.35;      // Tiefe, über die das Wasser in die Uferfarbe läuft (weiche Kante)
uniform float saum_staerke = 0.10;       // heller Saum knapp vor dem Ufer (0 = aus)
uniform float wellen_skala = 0.10;       // 1/m, Grundwelle ~ 10 m
uniform float wellen_staerke = 0.55;     // Neigung der Normalen (Gradient in 1/m skaliert; klein = ruhig)
uniform float fliess_periode_s = 8.0;    // Phasenlänge des Fließversatzes (Flowmap-Prinzip)
uniform float fresnel_staerke = 0.55;    // Anteil Himmelsfarbe bei streifendem Blick
uniform float fresnel_basis = 0.04;
uniform float rauheit = 0.3;
// WA-05 Ufer aus Distanzfeld (nur Fluss): Wasser endet an der glatten Uferlinie (discard), Tiefe am Ufer aus dem Abstand
uniform sampler2D ufer_sdf : filter_linear, repeat_disable;
uniform bool ufer_sdf_an = false;
uniform vec4 sdf_rect = vec4(-1002.5, -1002.5, 4005.0, 3605.0);
uniform float ufer_neigung = 0.12;      // m Tiefe je m Abstand zur Uferlinie (nur im Uferstreifen)

varying vec3 w_pos;
varying float tiefe;
varying vec2 fluss;

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
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * m_pro_einheit;
	tiefe = COLOR.r * tiefe_skala_m;
	fluss = UV;               // Fließvektor m/s (x, z); 0 = stehend
}

// Wellenfeld (Gradient) an Punkt q (in Wellen-Einheiten): 2 Sinus-Züge in FESTEN Weltrichtungen (analytisch) + 1 Rauschen.
// Feste Richtungen sind Absicht: eine je Vertex interpolierte Richtung multipliziert sich mit großen Weltkoordinaten
// und erzeugt Moiré-Streifen je Dreieck (im ersten Test gesehen).
vec2 wellen_grad(vec2 q, out float n0) {
	const vec2 K1 = vec2(0.80, 0.60) * 6.2832;
	const vec2 K2 = vec2(-0.45, 0.89) * 4.71;
	vec2 g = K1 * cos(dot(q, K1) + TIME * 0.9) * 0.3 + K2 * cos(dot(q, K2) - TIME * 0.7) * 0.2;
	n0 = vnoise(q * 2.3);
	g += vec2(vnoise(q * 2.3 + vec2(0.15, 0.0)) - n0, vnoise(q * 2.3 + vec2(0.0, 0.15)) - n0) * 8.0;
	return g;
}

void fragment() {
	float d = max(tiefe, 0.0);
	vec2 p = w_pos.xz;
	if (ufer_sdf_an) {
		float s = texture(ufer_sdf, (p - sdf_rect.xy) / sdf_rect.zw).r * 255.0 / 4.0 - 32.0;
		if (s > 0.0) {
			discard;
		}
		d = mix(-s * ufer_neigung, d, smoothstep(10.0, 25.0, -s));
	}
	// Fließen ohne wachsenden Versatz: zwei Phasen (Flowmap-Prinzip), Versatz bleibt <= fliess_periode_s × Tempo
	float ph1 = fract(TIME / fliess_periode_s);
	float ph2 = fract(TIME / fliess_periode_s + 0.5);
	float wb = abs(1.0 - 2.0 * ph1);
	float n0a; float n0b;
	vec2 ga = wellen_grad((p - fluss * ph1 * fliess_periode_s) * wellen_skala, n0a);
	vec2 gb = wellen_grad((p - fluss * ph2 * fliess_periode_s + vec2(7.3, 3.1)) * wellen_skala, n0b);
	vec2 g = mix(ga, gb, wb) * wellen_skala;
	float n0 = mix(n0a, n0b, wb);
	// am Ufer und im Flachen ruhiger
	float ruhe = smoothstep(0.0, 1.2, d) * mix(0.45, 1.0, clamp(length(fluss) / 0.3, 0.0, 1.0));   // stehendes Wasser ruhiger
	vec3 wn = normalize(vec3(-g.x * wellen_staerke * ruhe, 1.0, -g.y * wellen_staerke * ruhe));
	NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);

	// Farbe nach Tiefe, Uferkante, Saum
	vec3 col = mix(c_flach, c_tief, smoothstep(0.0, tiefe_voll_m, d));
	float saum = saum_staerke * (1.0 - smoothstep(0.05, 0.5, d)) * (0.6 + 0.4 * n0);
	col += vec3(saum);
	float fres = fresnel_basis + (1.0 - fresnel_basis) * pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 5.0);
	col = mix(col, c_himmel, clamp(fres * fresnel_staerke, 0.0, 0.8));
	float ufer = 1.0 - smoothstep(0.0, ufer_breite_m, d);
	col = mix(col, c_ufer, ufer);

	ALBEDO = col;
	ROUGHNESS = mix(rauheit, 0.9, ufer);
	SPECULAR = mix(0.35, 0.1, ufer);
	METALLIC = 0.0;
}
