// Prototyp-Welt (Phase 4, TA): Baum-Material fuer MultiMesh. Vertexfarbe: RGB = Grundfarbe (Stamm braun, Krone gruen),
// A = 1 Krone / 0 Stamm. Instanzfarbe (MultiMesh use_colors) toent den Baum; Godot multipliziert sie in COLOR
// (geprueft im Compatibility-Renderer: ohne use_colors ist COLOR im MultiMesh schwarz).
shader_type spatial;
render_mode cull_back, diffuse_lambert;

varying vec3 farbe;

void vertex() {
	farbe = COLOR.rgb;
}

void fragment() {
	ALBEDO = farbe;
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
}
