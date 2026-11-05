extends SceneTree
## WA-03a (TA): Licht/Umgebung der Prototyp-Welt nach der Auslagerung nach world/proto_licht.gd.
## WA-03b (05.11.2026): SOLL-Werte bewusst auf das neue Relief-Licht angehoben (RL-1, Messung sprints/s8/umsetzung/WA-03b.md).
## Vorher (WA-03a, Stand S7): Sonne (-42, 38, 0), Energie 0,52, Umgebung Quelle Farbe, Energie 0,36, kein Relief im Shader.
## Headless:  godot --headless --path slice -s res://tests/proto_licht_test.gd

const SOLL_SONNE_ROT := Vector3(-27, -135, 0)
const SOLL_SONNE_FARBE := Color(1.0, 0.92, 0.78)
const SOLL_SONNE_ENERGIE := 0.69
const SOLL_UMGEBUNG_FARBE := Color(0.74, 0.81, 0.92)
const SOLL_UMGEBUNG_ENERGIE := 0.31
const SOLL_HIMMEL_ANTEIL := 0.5
const SOLL_SCHUMMER := 0.01
const SOLL_TOENUNG := 0.06

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
	ok(ProtoLicht.SONNE_ROT_GRAD == SOLL_SONNE_ROT, "ProtoLicht: Sonnenwinkel (-27, -135, 0)")
	ok(is_equal_approx(ProtoLicht.SONNE_ENERGIE, SOLL_SONNE_ENERGIE), "ProtoLicht: light_energy 0,69")
	ok(is_equal_approx(ProtoLicht.UMGEBUNG_ENERGIE, SOLL_UMGEBUNG_ENERGIE), "ProtoLicht: Umgebungslicht 0,31")
	# 2) Werte in der Welt-Szene
	var s: Node = (load("res://proto/prototyp_welt.tscn") as PackedScene).instantiate()
	s.kette_modus = "fest"              # S8 AT-08: Szenen-Default ist "leer"; dieser Test misst die feste Kette
	root.add_child(s)
	await process_frame
	var sun: DirectionalLight3D = s.sun
	var env: Environment = s.env
	ok(sun != null and env != null, "Welt: sun und env gesetzt")
	ok(sun.rotation_degrees.is_equal_approx(SOLL_SONNE_ROT), "Welt: Sonnenwinkel %s" % sun.rotation_degrees)
	ok(is_equal_approx(sun.light_energy, SOLL_SONNE_ENERGIE), "Welt: light_energy %.2f" % sun.light_energy)
	ok(sun.light_color.is_equal_approx(SOLL_SONNE_FARBE), "Welt: Sonnenfarbe %s" % sun.light_color)
	ok(sun.shadow_enabled and is_equal_approx(sun.shadow_opacity, 0.5), "Welt: Schatten an, Deckung 0,5")
	ok(sun.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS, "Welt: 2 Splits")
	ok(env.ambient_light_source == Environment.AMBIENT_SOURCE_SKY and is_equal_approx(env.ambient_light_sky_contribution, SOLL_HIMMEL_ANTEIL), "Welt: Umgebungslicht Himmel, Anteil %.2f" % env.ambient_light_sky_contribution)
	ok(is_equal_approx(env.ambient_light_energy, SOLL_UMGEBUNG_ENERGIE), "Welt: Umgebungslicht %.2f" % env.ambient_light_energy)
	ok(env.ambient_light_color.is_equal_approx(SOLL_UMGEBUNG_FARBE), "Welt: Umgebungsfarbe %s" % env.ambient_light_color)
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
	# 5) WA-03b: Relief im Terrain-Shader, Richtung passt zur Sonne der Szene
	var sd: Vector3 = -sun.global_transform.basis.z
	var rx := ProtoLicht.sonnenrichtung_xz()
	ok(rx.distance_to(Vector2(sd.x, sd.z).normalized()) < 1e-3 and sd.x > 0.0 and sd.z > 0.0,
		"Sonnenrichtung xz %s = Laufrichtung der Szene-Sonne (Licht aus NW, läuft nach SE)" % rx)
	var tm: ShaderMaterial = s.terrain.terrain_mat if s.terrain != null and "terrain_mat" in s.terrain else null
	ok(tm != null and is_equal_approx(float(tm.get_shader_parameter("schummer_staerke")), SOLL_SCHUMMER)
		and is_equal_approx(float(tm.get_shader_parameter("toenung_staerke")), SOLL_TOENUNG)
		and (tm.get_shader_parameter("schummer_richtung") as Vector2).distance_to(rx) < 1e-4,
		"Terrain-Material: Schummerung %.2f, Tönung %.2f, Richtung = Sonne" % [SOLL_SCHUMMER, SOLL_TOENUNG])
	print("Prüfungen OK: %d, FAIL: %d" % [n_ok, n_fail])
	quit(1 if n_fail > 0 else 0)
