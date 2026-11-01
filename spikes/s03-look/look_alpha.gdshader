shader_type spatial;
render_mode depth_draw_never, cull_disabled;
// Flaechen/Umrisse, die nur in der Karte sichtbar sind: echtes Alpha-Blending mit map_blend.
// Gleiche Vertex-Kodierung wie look.gdshader (network = 1 -> Band mit UV.x/UV2).

uniform float map_blend : hint_range(0.0, 1.0) = 0.0;
uniform float network = 0.0;
uniform float widen = 0.0;
uniform float max_alpha = 0.9;
uniform float emission_lift = 0.3;

void vertex() {
	vec3 v = VERTEX;
	if (network > 0.5) {
		v.xz += UV2 * UV.x * widen;
	}
	VERTEX = v;
}

void fragment() {
	vec3 lin = pow(COLOR.rgb, vec3(2.2));
	ALBEDO = lin;
	ROUGHNESS = 1.0;
	EMISSION = lin * emission_lift;
	ALPHA = map_blend * max_alpha;
}
