extends SceneTree
## WA-03a (TA): Licht/Umgebung der Prototyp-Welt nach der Auslagerung nach world/proto_licht.gd.
## Vergleicht die Werte in der Welt-Szene mit den ALTEN Werten aus prototyp_welt.gd (Stand vor WA-03a).
## Headless:  godot --headless --path slice -s res://tests/proto_licht_test.gd
## Ab WA-03b (neue Werte, RL-1) werden die ALT_*-Konstanten hier bewusst angepasst.

const ALT_SONNE_ROT := Vector3(-42, 38, 0)
const ALT_SONNE_FARBE := Color(1.0, 0.92, 0.78)
const ALT_SONNE_ENERGIE := 0.52
const ALT_UMGEBUNG_FARBE := Color(0.74, 0.81, 0.92)
const ALT_UMGEBUNG_ENERGIE := 0.36

var n_ok := 0
var n_fail := 0


func ok(c: bool, text: String) -> void:
	if c:
		n_ok += 1
		print("  OK   ", text)
	else:
		n_fail += 1
		print("  FAIL ", text)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("proto_licht_test")
	# 1) Konstanten in proto_licht.gd
	ok(ProtoLicht.SONNE_ROT_GRAD == ALT_SONNE_ROT, "ProtoLicht: Sonnenwinkel (-42, 38, 0)")
	ok(is_equal_approx(ProtoLicht.SONNE_ENERGIE, ALT_SONNE_ENERGIE), "ProtoLicht: light_energy 0,52")
	ok(is_equal_approx(ProtoLicht.UMGEBUNG_ENERGIE, ALT_UMGEBUNG_ENERGIE), "ProtoLicht: Umgebungslicht 0,36")
	# 2) Werte in der Welt-Szene
	var s: Node = (load("res://proto/prototyp_welt.tscn") as PackedScene).instantiate()
	s.kette_modus = "fest"              # S8 AT-08: Szenen-Default ist "leer"; dieser Test misst die feste Kette
	root.add_child(s)
	await process_frame
	var sun: DirectionalLight3D = s.sun
	var env: Environment = s.env
	ok(sun != null and env != null, "Welt: sun und env gesetzt")
	ok(sun.rotation_degrees.is_equal_approx(ALT_SONNE_ROT), "Welt: Sonnenwinkel %s" % sun.rotation_degrees)
	ok(is_equal_approx(sun.light_energy, ALT_SONNE_ENERGIE), "Welt: light_energy %.2f" % sun.light_energy)
	ok(sun.light_color.is_equal_approx(ALT_SONNE_FARBE), "Welt: Sonnenfarbe %s" % sun.light_color)
	ok(sun.shadow_enabled and is_equal_approx(sun.shadow_opacity, 0.5), "Welt: Schatten an, Deckung 0,5")
	ok(sun.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS, "Welt: 2 Splits")
	ok(env.ambient_light_source == Environment.AMBIENT_SOURCE_COLOR, "Welt: Umgebungslicht-Quelle Farbe")
	ok(is_equal_approx(env.ambient_light_energy, ALT_UMGEBUNG_ENERGIE), "Welt: Umgebungslicht %.2f" % env.ambient_light_energy)
	ok(env.ambient_light_color.is_equal_approx(ALT_UMGEBUNG_FARBE), "Welt: Umgebungsfarbe %s" % env.ambient_light_color)
	ok(env.tonemap_mode == Environment.TONE_MAPPER_LINEAR, "Welt: Tonemap linear")
	ok(env.fog_enabled and env.fog_mode == Environment.FOG_MODE_DEPTH and is_equal_approx(env.fog_depth_curve, 1.6), "Welt: Nebel Tiefe, Kurve 1,6")
	ok(env.background_mode == Environment.BG_SKY and env.sky != null, "Welt: Himmel")
	# 3) Knoten haengen an der Welt
	var we_n := 0
	var dl_n := 0
	for c in s.get_children():
		if c is WorldEnvironment:
			we_n += 1
		elif c is DirectionalLight3D:
			dl_n += 1
	ok(we_n == 1 and dl_n == 1, "Welt: genau 1 WorldEnvironment und 1 DirectionalLight3D als Kinder (%d/%d)" % [we_n, dl_n])
	# 4) Kamera-Anpassung (bleibt in prototyp_welt.gd) wirkt weiter auf dieselben Objekte
	ok(sun.directional_shadow_max_distance <= 2500.0 and env.fog_depth_end > env.fog_depth_begin, "Kamera setzt Nebel/Schattenreichweite auf env/sun (Schatten %.0f m)" % sun.directional_shadow_max_distance)
	print("Prüfungen OK: %d, FAIL: %d" % [n_ok, n_fail])
	quit(1 if n_fail > 0 else 0)
