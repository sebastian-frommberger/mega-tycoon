shader_type spatial;
render_mode cull_disabled, diffuse_lambert;
// Fix-Pass W2 (TA, M7): Bodenflaechen der Prototyp-Welt mit Oberflaechen-Detail statt einfarbigem Grau.
// COLOR = Basisfarbe je Instanz (Toenung wie bisher, Vertexfarbe = ALBEDO). Muster in Weltkoordinaten (m), kein UV, keine Textur:
//   modus 1 Pflaster: Laeuferverband 0,46 x 0,30 m, Stein-Toenung, dunkle Fugen, dazu grossflaechig Abnutzung
//   modus 2 Kies/Hofboden: Koernung 0,16 m, helle und dunkle Steinchen, Fahrspuren-Tonung grossflaechig
// Muster blenden mit dem Pixel-Fussabdruck (fwidth) in den Mittelwert aus: kein Moire in der Ferne.
uniform int modus = 1;
uniform float stein_x_m = 0.46;
uniform float stein_z_m = 0.30;
uniform float fuge_m = 0.022;
uniform float fuge_dunkel = 0.62;
uniform float ton_streuung = 0.20;

varying vec3 w_pos;

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
}

void fragment() {
	vec3 base = COLOR.rgb;
	vec2 p = w_pos.xz;
	float fp = length(fwidth(p));                       // m je Pixel
	float grob = vnoise(p * 0.11) * 0.6 + vnoise(p * 0.37 + 5.3) * 0.4;
	float ton = 0.93 + 0.14 * grob;                     // Abnutzung, bleibt in jeder Entfernung
	vec3 col = base * ton;
	if (modus == 1) {
		vec2 q = p / vec2(stein_x_m, stein_z_m);
		float reihe = floor(q.y);
		q.x += reihe * 0.5 + h21(vec2(reihe, 7.1)) * 3.0;
		vec2 id = floor(q);
		vec2 f = fract(q);
		float r = h21(id + vec2(3.7, 1.3));
		float a_stein = 1.0 - smoothstep(0.08, 0.4, fp / min(stein_x_m, stein_z_m) * 2.0);   // Pixel < halber Stein
		float d = min(min(f.x, 1.0 - f.x) * stein_x_m, min(f.y, 1.0 - f.y) * stein_z_m);
		float fuge = 1.0 - smoothstep(fuge_m * 0.5, fuge_m * 1.5 + fp * 0.5, d);
		float t_stein = 1.0 + (r - 0.5) * ton_streuung;
		col *= mix(1.0, t_stein, a_stein);
		col = mix(col, col * fuge_dunkel, fuge * (0.35 + 0.65 * a_stein));
	} else if (modus == 2) {
		float a_k = 1.0 - smoothstep(0.05, 0.22, fp / 0.16);
		vec2 g = floor(p / 0.16);
		float r = h21(g + 1.7);
		float stein = step(0.82, r) - step(r, 0.12);          // +1 helles, −1 dunkles Steinchen
		col *= 1.0 + stein * 0.16 * a_k + (vnoise(p * 3.1) - 0.5) * 0.08 * a_k;
		float spur = vnoise(vec2(p.x * 0.5, p.y * 0.07) + 11.0);       // gestreckte Tonung (Fahrspuren, Trittbahnen)
		col *= 0.97 + 0.06 * spur;
	}
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
}
