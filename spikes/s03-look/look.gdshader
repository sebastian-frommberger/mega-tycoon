shader_type spatial;
// S-03 Look-Test: ein Shader fuer alle Materialien, Ausfuehrung ueber Uniforms.
// Morphing statt Austausch: Hoehen werden in der Karte abgeflacht, Details (Schornsteine, Kran,
// Bahnsteig) schrumpfen in der Betriebsstufe auf ihren Ankerpunkt, das Netz wird verbreitert
// -> kein Mesh-Swap, kein Popping. (Kein Dither: Screen-Door-Rauschen war im ersten Lauf sichtbar.)
// Vertex-Kodierung: UV.y = 1 -> Detail (UV.x = Basishoehe, UV2 = Ankerpunkt xz);
//                   network = 1 -> Band (UV.x = Seite -1/+1, UV2 = Lateralvektor xz).

uniform float map_blend : hint_range(0.0, 1.0) = 0.0; // 0 Diorama/Betrieb, 1 Karte
uniform float mid_blend : hint_range(0.0, 1.0) = 0.0; // 0 Nah, 1 Betrieb (Details weg)
uniform float flatten_min = 0.14;      // Y-Skalierung der Koerper in der Karte
uniform float flatten_on = 1.0;        // 0 = nicht abflachen (Fahrzeuge, Patches)
uniform float use_detail = 0.0;        // 1 = UV.y markiert Detail-Geometrie
uniform float network = 0.0;           // 1 = Band-Mesh
uniform float widen = 0.0;             // Zusatz-Halbbreite des Bandes in m (negativ = schrumpfen)
uniform float veh_scale = 1.0;         // Skalierung der Instanzen (Fahrzeuge)
uniform float desat_amount = 0.5;      // Entsaettigung in der Karte
uniform vec3 map_color = vec3(-1.0);   // <0 = nicht ueberschreiben, sonst Kartenfarbe (sRGB)
uniform float ground_pattern = 0.0;    // 1 = Boden-Raster/Feldvariation
uniform float emission_lift = 0.35;    // Aufhellung in der Karte (flach beleuchtet)

varying vec3 wpos;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	vec3 v = VERTEX;
	if (network > 0.5) {
		v.xz += UV2 * UV.x * widen;
	} else {
		if (use_detail > 0.5 && UV.y > 0.5) {
			v.xz = mix(v.xz, UV2, mid_blend);
			v.y = mix(v.y, UV.x, mid_blend);
		}
		v.y *= mix(1.0, flatten_min, map_blend * flatten_on);
	}
	v *= veh_scale;
	VERTEX = v;
	wpos = (MODEL_MATRIX * vec4(v, 1.0)).xyz;
}

void fragment() {
	vec3 c = COLOR.rgb;
	if (ground_pattern > 0.5) {
		vec2 g = floor(wpos.xz / 70.0);
		c *= 0.90 + 0.18 * hash21(g);
		// 10-m-Raster (= 1 Logikfeld), nur in Nah sichtbar
		vec2 f = abs(fract(wpos.xz / 10.0 - 0.5) - 0.5) / max(fwidth(wpos.xz / 10.0), vec2(0.0001));
		float line = 1.0 - min(min(f.x, f.y), 1.0);
		c = mix(c, c * 0.88, line * 0.5 * (1.0 - mid_blend));
	}
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(l), map_blend * desat_amount);
	if (map_color.r >= 0.0) {
		c = mix(c, map_color, map_blend);
	}
	// Vertex-Farben und Uniforms sind sRGB gemeint, Godot liest sie linear -> hier umrechnen
	vec3 lin = pow(c, vec3(2.2));
	ALBEDO = lin;
	ROUGHNESS = 0.92;
	SPECULAR = 0.1;
	EMISSION = lin * map_blend * emission_lift;
}
