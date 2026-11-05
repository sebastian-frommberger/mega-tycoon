// Prototyp-Welt (Phase 4, TA): Gelaende mit Bodenkarte (08_landschaft Weg A, EIN Sampler).
// proto_boden.png: RGB = Klassenfarbe (sRGB, Palette 08), A = Klasse * 20 + 10. filter_nearest + Rauschversatz der
// Abtastposition -> Klassenkanten scharf, aber nicht als 25-m-Treppe (Rand ausgefranst um +-rand_versatz_m / 2).
// Prozedural darueber: Kronentupfen im Wald, Gewann-Streifen im Acker, Fels an steilen Flanken, Ufersaum an Seen/Teichen
// (Hoehe ueber Pegel, bis 4 stehende Gewaesser als Uniform). Szene in Metern (1 Einheit = 1 m).
shader_type spatial;
render_mode cull_back, diffuse_lambert;

uniform sampler2D boden : source_color, filter_nearest, repeat_disable;
uniform sampler2D schlag : filter_nearest, repeat_disable;       // Ackerschlaege (proto_terrain.gd _schlag_textur): R Furchenrichtung / PI, G Schlag-Kennung, B 255 = Acker
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
// WA-03b Relief (RL-1), Werte setzt ProtoLicht.terrain_parameter(); Standard 0 = aus (Rueckfall, A/B):
uniform float schummer_staerke = 0.0;        // Hangschummerung: Helligkeit +-s auf Haengen ab schummer_voll_hang Neigung
uniform vec2 schummer_richtung = vec2(0.7071, 0.7071);   // xz-Laufrichtung des Sonnenlichts (normiert)
uniform float schummer_voll_hang = 0.15;     // |n.xz| (~ Neigung), ab der die Schummerung voll wirkt; darunter linear
uniform float toenung_staerke = 0.0;         // Hoehentoenung: Tal satter (gruener), Kuppe trockener (gelblich, entsaettigt)
uniform float hoehe_tal_m = 40.0;
uniform float hoehe_kuppe_m = 110.0;

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

// WA-04 Stufe A (S8): weiche Klassenuebergaenge, Makro-Variation, Detailtextur nah, Ackerschlaege im Shader.
// Schalter stufe_a (Standard an); aus = Stand WA-03b (Rueckfall, A/B). Texturzugriffe je Fragment mit stufe_a:
// 2 x boden (eigene Klasse + Nachbar ueber der naechsten Texelkante), 2 x detail (nur < detail_fern_m), 0 x schlag.
uniform bool stufe_a = true;
uniform sampler2D detail : filter_linear_mipmap, repeat_enable;   // proto_detail.png (prozedural, tools_proto/ta_boden_detail.py)
uniform float uebergang_m = 2.5;             // halbe Breite der Klassenueberblendung (m), also ca. 5 m Uebergang
uniform float saum_rauschen_m = 5.0;         // Rauschverschiebung der Klassengrenze (m), bricht gerade Stuecke
uniform float makro_staerke = 0.045;         // Helligkeit +-, Skalen 260 m / 700 m
uniform float makro_ton = 0.025;             // leichte Tonverschiebung gelb/gruen
uniform float detail_staerke = 0.15;
uniform float detail_a_m = 7.3;              // Kachelgroesse Massstab A (m)
uniform float detail_b_m = 2.9;              // Massstab B (m), um 35 Grad gedreht
uniform float detail_nah_m = 90.0;           // bis hier volle Staerke (Kameraabstand)
uniform float detail_fern_m = 300.0;         // ab hier aus, keine Zugriffe
uniform float schlag_m = 175.0;              // Gewann-Zelle (7 Felder, wie _schlag_textur)
uniform float rain_m = 2.0;                  // Feldrain zwischen Schlaegen
uniform vec3 c_rain : source_color = vec3(0.400, 0.490, 0.300);
// WA-05 Ufer aus Distanzfeld (5 m, tools_proto/ta_ufer_sdf.py): Wert * 255 / 4 - 32 = Abstand zur glatten Fluss-Uferlinie (m, + = Land)
uniform sampler2D ufer_sdf : filter_linear, repeat_disable;
uniform bool ufer_sdf_an = false;
uniform vec4 sdf_rect = vec4(-1002.5, -1002.5, 4005.0, 3605.0);   // xy = Welt von Texel 0 (Knoten 0 - 2,5 m), zw = Ausdehnung
uniform float ufer_band_m = 4.0;             // Schlammsaum an Land ab der glatten Uferlinie
uniform vec3 c_aue : source_color = vec3(0.490, 0.600, 0.349);    // #7D9959 auenboden: Wasserklasse ausserhalb des Saums

float ufer_abstand(vec2 p) {
	return texture(ufer_sdf, (p - sdf_rect.xy) / sdf_rect.zw).r * 255.0 / 4.0 - 32.0;
}

int klasse(vec4 b) {
	return int(floor(b.a * 255.0 / 20.0 + 0.01));
}
vec3 kfarbe(vec4 b, int id) {
	return id == 11 ? (ufer_sdf_an ? c_aue : c_ufer) : b.rgb;
}
bool ist_acker(int id) {
	return id == 3 || id == 4;
}

// Voronoi der Schlaege direkt aus Keimpunkten (gejittertes Gitter): x = Richtungsstufe 0..1, y = Abstand zur Schlaggrenze (m)
vec2 schlag_at(vec2 p) {
	// Gitter um 23 Grad gedreht: ein achsparalleles Keimgitter erzeugt bevorzugt achsparallele Grenzen (Treppenmetrik)
	vec2 sc = mat2(vec2(0.9205, 0.3907), vec2(-0.3907, 0.9205)) * (p - boden_rect.xy) / schlag_m;
	vec2 ci = floor(sc);
	vec2 ss[9];
	float d1 = 1e9;
	int k1 = 0;
	for (int k = 0; k < 9; k++) {
		vec2 c = ci + vec2(float(k % 3 - 1), float(k / 3 - 1));
		vec2 s = c + 0.15 + 0.7 * vec2(h21(c + 0.37), h21(c + 11.13));
		ss[k] = s;
		float d = dot(sc - s, sc - s);
		if (d < d1) { d1 = d; k1 = k; }
	}
	vec2 s1 = ss[k1];
	float rb = 1e9;
	for (int k = 0; k < 9; k++) {
		if (k == k1) { continue; }
		rb = min(rb, dot(0.5 * (s1 + ss[k]) - sc, normalize(ss[k] - s1)));
	}
	vec2 i1 = ci + vec2(float(k1 % 3 - 1), float(k1 / 3 - 1));
	int stufe = int(mod(i1.x * 2.0 + i1.y * 3.0, 7.0));
	float klein = h21(i1 + 5.71);
	return vec2((float(stufe) + (klein - 0.5) * 0.4) / 7.0, rb * schlag_m);
}

float streifen(vec2 p, float richtung) {
	float a = richtung * 3.14159265;
	float ph = dot(p, vec2(cos(a), sin(a))) / streifen_m;
	float s = fract(ph);
	float wave = smoothstep(0.42, 0.5, s) * (1.0 - smoothstep(0.92, 1.0, s));
	wave = mix(0.5, wave, clamp(1.0 - fwidth(ph) * 2.0, 0.0, 1.0));
	return 0.95 + 0.065 * wave;
}

float tupfen(vec2 p) {
	float t = vnoise(p / tupfen_m) * 0.65 + vnoise(p / (tupfen_m * 0.45)) * 0.35;
	return mix(1.0 - tupfen_staerke, 1.0 + tupfen_staerke * 0.6, smoothstep(0.3, 0.7, t));
}

vec3 boden_stufe_a(vec2 p, vec2 j, float dist, out int id_out) {
	vec2 tsz = vec2(textureSize(boden, 0));
	vec2 q = (p + j * rand_versatz_m - boden_rect.xy) / boden_rect.zw;
	vec2 tx = q * tsz;
	vec2 f = fract(tx);
	vec2 ed = min(f, 1.0 - f);                       // Abstand zur Texelkante je Achse (Texel)
	vec2 off = ed.x < ed.y ? vec2(f.x < 0.5 ? -1.0 : 1.0, 0.0) : vec2(0.0, f.y < 0.5 ? -1.0 : 1.0);
	float e = min(ed.x, ed.y) * boden_rect.z / tsz.x;   // in m (Texel = 25 m)
	vec4 ba = texture(boden, q);
	vec4 bb = texture(boden, (floor(tx) + 0.5 + off) / tsz);
	int ia = klasse(ba);
	int ib = klasse(bb);
	// Klassengrenze organisch verschieben: Rauschen mit Vorzeichen nach Klassenordnung -> beide Seiten sehen dieselbe Grenze
	float wa = 1.0;
	if (ia != ib) {
		float nz = (vnoise(p * 0.19 + 7.1) - 0.5) + (vnoise(p * 0.55 + 2.3) - 0.5) * 0.5;
		float sg = ia < ib ? 1.0 : -1.0;
		wa = smoothstep(-uebergang_m, uebergang_m, e + sg * nz * 2.0 * saum_rauschen_m);
	}
	vec3 ca = kfarbe(ba, ia);
	vec3 cb = kfarbe(bb, ib);
	// klassenabhaengige Muster je Seite (stetig ueber die Grenze)
	if (ist_acker(ia) || ist_acker(ib)) {
		vec2 sl = schlag_at(p);
		float st = streifen(p, sl.x);
		float aa = max(fwidth(sl.y), 1e-3);
		float rain = 1.0 - smoothstep(rain_m * 0.5 - 0.5 * aa - 0.25, rain_m * 0.5 + 0.5 * aa + 0.25, sl.y);
		rain *= clamp(rain_m / (aa * 2.0), 0.0, 1.0) * 0.75;
		if (ist_acker(ia)) { ca = mix(ca * st, c_rain, rain); }
		if (ist_acker(ib)) { cb = mix(cb * st, c_rain, rain); }
	}
	if (ia == 6 || ib == 6) {
		float tp = tupfen(p);
		if (ia == 6) { ca *= tp; }
		if (ib == 6) { cb *= tp; }
	}
	vec3 col = mix(cb, ca, wa);
	if (ufer_sdf_an) {          // WA-05: Schlammsaum aus dem Distanzfeld statt aus der 25-m-Wasserklasse
		float su = ufer_abstand(p) + (vnoise(p * 0.3 + 1.7) - 0.5) * 1.5;
		col = mix(col, c_ufer, 1.0 - smoothstep(ufer_band_m * 0.4, ufer_band_m, su));
	}
	int id_w = wa >= 0.5 ? ia : ib;
	id_out = id_w;
	// Grundrauschen (wie bisher) + Makro-Variation 260/700 m gegen grossflaechige Gleichfoermigkeit
	float nzb = vnoise(p * 0.012) * 0.6 + vnoise(p * 0.056) * 0.4;
	col *= 1.0 + (nzb - 0.5) * 2.0 * rauschen_staerke;
	float mk1 = vnoise(p / 700.0 + 3.3);
	float mk2 = vnoise(p / 260.0 + 8.8);
	float mk = mk1 * 0.6 + mk2 * 0.4;
	float mt = (mk2 - mk1) * 0.7;
	if (id_w != 11) {
		col *= (1.0 + (mk - 0.5) * 2.0 * makro_staerke) * vec3(1.0 + mt * makro_ton * 2.0, 1.0, 1.0 - mt * makro_ton * 2.0);
	}
	// Detailtextur nah: Gras/Erde nach Farbe (stetig), zwei Massstaebe gedreht + Rauschversatz gegen Kachelmuster
	float fade = 1.0 - smoothstep(detail_nah_m, detail_fern_m, dist);
	if (fade > 0.0) {
		vec2 ua = (p + j * 3.0) / detail_a_m;
		vec2 pr = mat2(vec2(0.819, 0.574), vec2(-0.574, 0.819)) * p;
		vec2 ub = (pr - j * 2.0) / detail_b_m + 0.37;
		vec4 ta = texture(detail, ua);
		vec4 tb = texture(detail, ub);
		float gras = smoothstep(0.0, 0.07, col.g - col.r);
		float k = mk1;                          // Mischung der Massstaebe (nicht periodisch, aus dem Makro-Rauschen)
		float vg = mix(ta.r, tb.b, 0.35 + 0.3 * k);
		float ve = mix(ta.g, tb.a, 0.35 + 0.3 * k);
		float v = mix(ve, vg, gras);
		float amp = detail_staerke * fade * (0.75 + 0.5 * mk2);
		col *= 1.0 + (v - 0.5) * 2.0 * amp;
	}
	return col;
}

void fragment() {
	vec2 p = w_pos.xz;
	vec2 j = vec2(vnoise(p * 0.075), vnoise(p * 0.075 + vec2(17.3, 5.1))) - 0.5;
	j += (vec2(vnoise(p * 0.21 + 3.7), vnoise(p * 0.21 + 9.2)) - 0.5) * 0.5;
	int id = 0;
	vec3 col;
	if (stufe_a) {
		col = boden_stufe_a(p, j, length(VERTEX), id);
	} else {
	vec2 buv = (p + j * rand_versatz_m - boden_rect.xy) / boden_rect.zw;
	vec4 b = texture(boden, buv);
	id = int(floor(b.a * 255.0 / 20.0 + 0.01));
	col = b.rgb;
	float nz = vnoise(p * 0.012) * 0.6 + vnoise(p * 0.056) * 0.4;
	col *= 1.0 + (nz - 0.5) * 2.0 * rauschen_staerke;
	if (id == 6) {             // Waldboden: Kronentupfen
		float t = vnoise(p / tupfen_m) * 0.65 + vnoise(p / (tupfen_m * 0.45)) * 0.35;
		col *= mix(1.0 - tupfen_staerke, 1.0 + tupfen_staerke * 0.6, smoothstep(0.3, 0.7, t));
	} else if (id == 3 || id == 4) {   // Acker: Streifen je Schlag (Richtung aus der Schlagkarte), kein Blockraster mehr
		vec4 sc = texture(schlag, buv);
		float a = sc.r * 3.14159265;
		vec2 dir = vec2(cos(a), sin(a));
		float ph = dot(p, dir) / streifen_m;
		float s = fract(ph);
		float wave = smoothstep(0.42, 0.5, s) * (1.0 - smoothstep(0.92, 1.0, s));
		// Moire: Streifen blenden mit dem Pixel-Fussabdruck in ihren Mittelwert (0,5) aus, wenn sie kleiner als ~2 Pixel werden
		float fw = fwidth(ph);
		wave = mix(0.5, wave, clamp(1.0 - fw * 2.0, 0.0, 1.0));
		col *= 0.95 + 0.065 * wave;
	} else if (id == 11) {     // Wasserklasse: sichtbar ist dort nur das Ufer (Wasser kommt als eigenes Mesh)
		col = c_ufer;
	}
	}   // Ende Rueckfall (stufe_a aus)
	// WA-03b Hoehentoenung (0 Texturzugriffe, Hoehe aus w_pos.y): hn -1 Tal .. +1 Kuppe
	if (id != 11 && toenung_staerke > 0.0) {
		float hn = smoothstep(hoehe_tal_m, hoehe_kuppe_m, w_pos.y) * 2.0 - 1.0;
		vec3 satt = col * vec3(1.0 - 0.5 * toenung_staerke, 1.0, 1.0 - 0.5 * toenung_staerke);
		vec3 trocken = mix(col, vec3(dot(col, vec3(0.2126, 0.7152, 0.0722))) * vec3(1.08, 1.0, 0.78), toenung_staerke);
		col = hn < 0.0 ? mix(col, satt, -hn) : mix(col, trocken, hn);
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
	// WA-03b Hangschummerung (lichtunabhaengig, flache Flaeche unveraendert): +s zur Sonne, -s abgewandt
	vec3 n = normalize(w_nrm);
	col *= 1.0 + schummer_staerke * dot(n.xz, -schummer_richtung) / max(length(n.xz), schummer_voll_hang);
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.12;
}
