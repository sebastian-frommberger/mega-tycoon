// Dachfarben-Shader (aus SP-03 KIT_SHADER, scale_terrain.gd): Kenney-Tuerkis-Daecher -> Ziegelrot, Weiss -> warmer Putz.
// Ein ShaderMaterial je Kit-Atlas (tex = Textures/colormap.png des jeweiligen Kits), tint je Kit setzen
// (Strassen 0.62/0.60/0.57, Haeuser 0.88/0.84/0.78, Commercial 0.86/0.80/0.72, Baeume 0.55/0.75/0.42; Strassen/Baeume remap=0).
// Dachton pro Gebaeude leicht variiert (Hash der Instanzposition, funktioniert auch mit MultiMesh).
// Farben aus data/palette_s08.json: stadt_haus_ziegel (178,115,97), stadt_strasse (76,76,82), stadt_haus_hell (209,199,178).
shader_type spatial;
render_mode cull_back;

uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec3 tint = vec3(1.0);
uniform vec3 roof : source_color = vec3(0.698, 0.451, 0.380);   // palette stadt_haus_ziegel
uniform float remap = 1.0;            // 1 = Tuerkis umfaerben (Haeuser), 0 = unveraendert (Strassen, Baeume)
uniform float roof_var = 0.10;        // Helligkeits-/Farbstreuung je Haus
uniform float teal_lo = 0.04;         // Schwellen aus SP-03
uniform float teal_hi = 0.20;

varying float v_var;

void vertex() {
	vec2 p = MODEL_MATRIX[3].xz;
	v_var = fract(sin(dot(floor(p), vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 c = texture(tex, UV).rgb;
	float teal = remap * smoothstep(teal_lo, teal_hi, min(c.g, c.b) - c.r);
	float lum = dot(c, vec3(0.3, 0.5, 0.2));
	vec3 r = roof * (0.46 + lum * 0.6) * (1.0 + (v_var - 0.5) * 2.0 * roof_var);
	r = mix(r, r * vec3(1.12, 0.92, 0.85), step(0.82, v_var));      // einzelne dunklere Rotbraun-Daecher
	ALBEDO = mix(c * tint, r, teal);
	ROUGHNESS = 0.92;
}
