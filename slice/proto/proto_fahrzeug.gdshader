shader_type spatial;
// Phase 4 Welle 2 (Felix): Fahrzeug-Platzhalter mit Haltung und Gangart über INSTANCE_CUSTOM (15 §B4 Schritt 6, K31).
// INSTANCE_CUSTOM: x Gangphase 0..1 (aus der Fahrstrecke, gedeckelte Frequenz), y Wippen (m), z Rollen (rad, + = linke
// Modellseite hebt sich), w Nicken (rad, + = Bug hoch). Instanz-Transform trägt nur Position + Gier (orthonormal, E7).
// Teile über COLOR.a × 10: 0 Wagenkasten, 1 Rad (dreht um Achse, Drehpunkt UV2 = (y, z)), 2/3 Bein Phase A/B
// (schwingt um die Hüfte UV2), 4 Pferdekörper (wippt halb). Farbe = COLOR.rgb.
render_mode diffuse_lambert, specular_disabled;

uniform float rad_verhaeltnis = 1.2;   // Rad 3 U/s zu Bein 2,5 Hz
uniform float bein_winkel = 0.45;      // rad
varying vec3 farbe;

vec2 dreh(vec2 p, vec2 piv, float a) {
	vec2 d = p - piv;
	return piv + vec2(cos(a) * d.x - sin(a) * d.y, sin(a) * d.x + cos(a) * d.y);
}

void vertex() {
	vec4 c = INSTANCE_CUSTOM;
	farbe = COLOR.rgb;
	float teil = floor(COLOR.a * 10.0 + 0.5);
	float ph = c.x * TAU;
	vec3 v = VERTEX;
	vec3 n = NORMAL;
	if (teil > 0.5 && teil < 1.5) {
		float a = ph * rad_verhaeltnis;
		v.yz = dreh(v.yz, UV2, a);
		n.yz = dreh(n.yz, vec2(0.0), a);
	} else if (teil > 1.5 && teil < 3.5) {
		float a = sin(ph + (teil > 2.5 ? PI : 0.0)) * bein_winkel;
		v.yz = dreh(v.yz, UV2, a);
		n.yz = dreh(n.yz, vec2(0.0), a);
	}
	if (teil < 0.5) {
		v.y += c.y;
	} else if (teil > 3.5) {
		v.y += c.y * 0.4;
	}
	float p = c.w;
	float r = c.z;
	mat3 rr = mat3(vec3(cos(r), sin(r), 0.0), vec3(-sin(r), cos(r), 0.0), vec3(0.0, 0.0, 1.0));
	mat3 rp = mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, cos(p), -sin(p)), vec3(0.0, sin(p), cos(p)));
	VERTEX = rp * rr * v;
	NORMAL = rp * rr * n;
}

void fragment() {
	ALBEDO = farbe;
	ROUGHNESS = 0.9;
}
