extends RefCounted
## S-11 Startdialog-Hintergrund: die Karte läuft als langsame Kamerafahrt (Haberau, Fluss, Mittelfurt) und liegt
## hinter einer leicht abgedunkelten, geblurrten Schicht statt hinter einer leeren Fläche. Kein Umbau der Panels:
## main.gd ruft style_dim() beim Aufbau und drift() pro Frame solange der Startdialog offen ist.

const SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform float radius_px = 7.0;
uniform vec4 tint : source_color = vec4(0.10, 0.07, 0.04, 0.16);
void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * radius_px;
	vec3 c = texture(screen_tex, SCREEN_UV).rgb * 0.20;
	c += texture(screen_tex, SCREEN_UV + vec2(px.x, 0.0)).rgb * 0.10;
	c += texture(screen_tex, SCREEN_UV - vec2(px.x, 0.0)).rgb * 0.10;
	c += texture(screen_tex, SCREEN_UV + vec2(0.0, px.y)).rgb * 0.10;
	c += texture(screen_tex, SCREEN_UV - vec2(0.0, px.y)).rgb * 0.10;
	c += texture(screen_tex, SCREEN_UV + px * 1.6).rgb * 0.1;
	c += texture(screen_tex, SCREEN_UV - px * 1.6).rgb * 0.1;
	c += texture(screen_tex, SCREEN_UV + vec2(px.x, -px.y) * 1.6).rgb * 0.1;
	c += texture(screen_tex, SCREEN_UV + vec2(-px.x, px.y) * 1.6).rgb * 0.1;
	float v = smoothstep(0.35, 0.95, distance(SCREEN_UV, vec2(0.5)));
	COLOR = vec4(mix(c, tint.rgb, tint.a + v * 0.16), 1.0);
}
"""

const CENTER := Vector2(380.0, 285.0)


## Blur-Schicht auf eigener CanvasLayer UNTER dem UI (Layer des UI - 1): der Screen-Buffer enthält dort nur die 3D-Karte,
## HUD und Dialog bleiben scharf. Sichtbar genau solange der Startdialog sichtbar ist.
static func attach(m: Node, start_panel: Control) -> void:
	var layer := CanvasLayer.new()
	layer.layer = m.ui.layer - 1
	layer.name = "StartBackdropBlur"
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	rect.material = mat
	layer.add_child(rect)
	m.add_child(layer)
	layer.visible = start_panel.visible
	start_panel.visibility_changed.connect(func(): layer.visible = start_panel.visible)


## Kamerafahrt: Mittelpunkt pendelt zwischen Haberau und Mittelfurt, leichte Gierbewegung und Zoom-Atmung.
## Periode ~ 2-3 min, damit nichts hektisch wirkt.
static func drift(m: Node, t: float) -> void:
	var c := CENTER + Vector2(sin(t * 0.05) * 34.0, cos(t * 0.035 + 0.4) * 62.0)
	m.rig.position = Vector3(c.x, 0.0, c.y)
	m.rig.rotation.y = sin(t * 0.03) * 0.30
	m.zoom = 9.5 + sin(t * 0.045) * 0.8
	m._apply_zoom()
