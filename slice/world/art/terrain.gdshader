// Terrain-Material S7 (Sophie): Hoehe/Steigung -> Gras / Fels / Schnee / Aue, Fluss-Rinne.
// Farben = Palette S-08 (data/palette_s08.json: gras, berg_stein, berg_schnee, wasser). Variation <= ca. +-5 % Helligkeit,
// damit Marker/Ghost-Kontrast (3:1) gegen den Hintergrund erhalten bleibt. Weltkoordinaten, keine Texturen.
shader_type spatial;
render_mode cull_back, diffuse_lambert;

uniform vec3 c_gras  : source_color = vec3(0.451, 0.580, 0.361);  // 115,148,92
uniform vec3 c_aue   : source_color = vec3(0.490, 0.600, 0.349);  // Gras, etwas gelbgruener/feuchter (abgeleitet)
uniform vec3 c_fels  : source_color = vec3(0.502, 0.451, 0.380);  // 128,115,97 berg_stein
uniform vec3 c_schnee: source_color = vec3(0.949, 0.949, 0.969);  // 242,242,247 berg_schnee
uniform vec3 c_wasser: source_color = vec3(0.251, 0.502, 0.800);  // 64,128,204
uniform vec3 c_ufer  : source_color = vec3(0.420, 0.440, 0.330);  // Uferschlamm, nur schmaler Saum

uniform float wasser_hoehe = 0.0;       // Wasserspiegel des Flusses (m, Welt-Y)
uniform float aue_hoehe = 14.0;         // Aue = Band ueber dem Wasserspiegel (m)
uniform float rinne_saum = 1.5;         // Uferstreifen ueber Wasser (m)
uniform float fels_ab_hang = 0.42;      // Steigung (1 - n.y) ab der Fels beginnt
uniform float fels_voll_hang = 0.62;    // volle Felsfarbe
uniform float fels_ab_hoehe = 380.0;    // darueber zunehmend Fels (Waldgrenze)
uniform float schnee_linie = 780.0;     // Schneegrenze (m)
uniform float schnee_breite = 90.0;     // Uebergang
uniform float schnee_max_hang = 0.55;   // steiler = kein Schnee
uniform float rauschen_skala = 0.012;   // 1/m
uniform float rauschen_staerke = 0.05;  // Helligkeitsvariation
uniform sampler2D fluss_maske : hint_default_black, filter_linear, repeat_disable; // optional: R=Rinne (1=Wasser), G=Aue
uniform vec4 maske_rect = vec4(0.0, 0.0, 1.0, 1.0);                // xy = Welt-Ursprung (x,z), zw = Ausdehnung (m); zw=1 -> aus
uniform float tiefen_dunkel = 0.28;     // Wasser dunkler je Tiefe unter Spiegel (pro 10 m)
uniform float m_pro_einheit = 1.0;      // W-02 (Felix): Meter je Szeneneinheit (S7-Welt: 25, 1 Feld = 1,0); Testszene: 1

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
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * m_pro_einheit;
	w_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(w_nrm);
	float hang = 1.0 - n.y;
	float h = w_pos.y;
	float nz = vnoise(w_pos.xz * rauschen_skala) * 0.6 + vnoise(w_pos.xz * rauschen_skala * 4.7) * 0.4;
	float var = 1.0 + (nz - 0.5) * 2.0 * rauschen_staerke;

	// Aue (flaches Band ueber Wasser) vs. Gras
	float aue_h = 1.0 - smoothstep(wasser_hoehe + rinne_saum, wasser_hoehe + aue_hoehe, h);
	float aue_m = 0.0;
	if (maske_rect.z > 1.5) {
		vec2 uv = (w_pos.xz - maske_rect.xy) / maske_rect.zw;
		aue_m = texture(fluss_maske, uv).g;
	}
	float aue = max(aue_h * (1.0 - smoothstep(0.05, 0.25, hang)), aue_m);
	vec3 col = mix(c_gras, c_aue, aue) * var;

	// Fels: steil oder hoch
	float f_hang = smoothstep(fels_ab_hang, fels_voll_hang, hang);
	float f_hoch = smoothstep(fels_ab_hoehe, fels_ab_hoehe + 260.0, h + (nz - 0.5) * 60.0) * smoothstep(0.08, 0.3, hang + 0.15);
	float fels = max(f_hang, f_hoch);
	col = mix(col, c_fels * (0.94 + 0.12 * vnoise(w_pos.xz * 0.05)), fels);

	// Schnee: ueber Schneegrenze, nicht an Steilwaenden
	float s = smoothstep(schnee_linie, schnee_linie + schnee_breite, h + (nz - 0.5) * 70.0);
	s *= 1.0 - smoothstep(schnee_max_hang * 0.7, schnee_max_hang, hang);
	col = mix(col, c_schnee, s);

	// Fluss-Rinne: unter Wasserspiegel Wasserfarbe, schmaler Ufersaum
	float tief = max(wasser_hoehe - h, 0.0);
	float rinne = 1.0 - smoothstep(0.0, 0.6, h - wasser_hoehe);
	if (maske_rect.z > 1.5) {
		vec2 uv2 = (w_pos.xz - maske_rect.xy) / maske_rect.zw;
		rinne = max(rinne, smoothstep(0.5, 0.7, texture(fluss_maske, uv2).r));
	}
	float ufer = (1.0 - smoothstep(0.6, rinne_saum, h - wasser_hoehe)) * (1.0 - rinne);
	col = mix(col, c_ufer, ufer * 0.6);
	vec3 wcol = c_wasser * (1.0 - clamp(tief / 10.0 * tiefen_dunkel, 0.0, 0.45));
	col = mix(col, wcol, rinne);

	ALBEDO = col;
	ROUGHNESS = mix(0.95, 0.35, rinne);
	SPECULAR = mix(0.15, 0.5, rinne);
}
