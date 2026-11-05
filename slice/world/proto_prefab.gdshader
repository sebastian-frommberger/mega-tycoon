shader_type spatial;
// Phase 4 W2 (TA + Sophie): gemeinsames Material aller ProtoPrefabs (1 Material -> 1 Draw Call je MultiMesh).
// Farbe: UV.x = Spalte in der Palette (Klasse x Helligkeitsstufe), Zeile = Variante aus INSTANCE_CUSTOM.y (0..1 -> 4 Zeilen).
// Animation ohne Skelett (UV2.x = Teil * 100 + Drehpunkt-y, UV2.y = Drehpunkt-z, Modellraum in m, Front +z):
//   Teil 1 Rad (dreht um lokale x-Achse, Radius = Drehpunkt-y), 2/3 Pferdebein Phase 0/PI (Pendel um die Huefte),
//   4 Pferderumpf (Wippen), 5 Muehlrad (dreht mit TIME).
// INSTANCE_CUSTOM: x = gang (zurueckgelegte Strecke in m, mod periode_m), y = Variante (0..1), z = Nicken (rad), w = Wanken (rad).
// Nahtlos: Rad- und Schrittzahl je Periode werden auf ganze Umlaeufe gerundet (kein Sprung beim Umbruch von gang).

uniform sampler2D palette : source_color, filter_nearest, repeat_disable;
uniform float palette_zeilen = 4.0;
uniform float periode_m = 20.8;   // FZ-09: 8 Doppelschritte (Halbfloat-Fix), gesetzt von ProtoPrefabs.PERIODE_M
uniform float schritt_m = 2.6;
uniform float bein_winkel = 0.42;
uniform float wipp_m = 0.05;
uniform float muehlrad_rad_s = 0.7;

varying float v_zeile;

void vertex() {
	float teil = floor(UV2.x / 100.0 + 0.001);
	vec2 piv = vec2(UV2.x - teil * 100.0, UV2.y);
	float gang = INSTANCE_CUSTOM.x;
	if (teil > 0.5) {
		float phi = 0.0;
		float hub = 0.0;
		if (teil < 1.5) {
			float n = max(1.0, floor(periode_m / (6.2831853 * max(piv.x, 0.05)) + 0.5));
			phi = 6.2831853 * n * gang / periode_m;
		} else if (teil < 3.5) {
			float n = max(1.0, floor(periode_m / schritt_m + 0.5));
			float ph = (teil < 2.5) ? 0.0 : 3.14159265;
			phi = bein_winkel * sin(6.2831853 * n * gang / periode_m + ph) * step(0.001, abs(gang));
		} else if (teil < 4.5) {
			float n = max(1.0, floor(periode_m / schritt_m + 0.5));
			hub = wipp_m * (1.0 - cos(2.0 * 6.2831853 * n * gang / periode_m)) * step(0.001, abs(gang));
		} else {
			phi = TIME * muehlrad_rad_s;
		}
		// Drehung um die lokale x-Achse durch den Drehpunkt; phi > 0: Oberkante nach +z (Rad rollt vorwaerts)
		float c = cos(phi);
		float s = sin(phi);
		vec2 d = vec2(VERTEX.y - piv.x, VERTEX.z - piv.y);
		VERTEX.y = piv.x + d.x * c - d.y * s + hub;
		VERTEX.z = piv.y + d.y * c + d.x * s;
		vec2 nn = vec2(NORMAL.y, NORMAL.z);
		NORMAL.y = nn.x * c - nn.y * s;
		NORMAL.z = nn.y * c + nn.x * s;
	}
	// Haltung: Nicken um x, dann Wanken um z (um den Ursprung = Bodenmitte)
	float ni = INSTANCE_CUSTOM.z;
	float wa = INSTANCE_CUSTOM.w;
	if (abs(ni) + abs(wa) > 1e-5) {
		mat3 rx = mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, cos(ni), sin(ni)), vec3(0.0, -sin(ni), cos(ni)));
		mat3 rz = mat3(vec3(cos(wa), sin(wa), 0.0), vec3(-sin(wa), cos(wa), 0.0), vec3(0.0, 0.0, 1.0));
		VERTEX = rz * (rx * VERTEX);
		NORMAL = rz * (rx * NORMAL);
	}
	v_zeile = clamp(floor(INSTANCE_CUSTOM.y * palette_zeilen), 0.0, palette_zeilen - 1.0);
}

void fragment() {
	vec3 c = texture(palette, vec2(UV.x, (v_zeile + 0.5) / palette_zeilen)).rgb;
	ALBEDO = c;
	ROUGHNESS = 0.92;
	SPECULAR = 0.25;
}
