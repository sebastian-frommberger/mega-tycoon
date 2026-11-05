extends SceneTree
## Phase 4 Welle 2 (Aylin): Bilder der Schilder in der Prototyp-Welt + Kontrastmessung im gerenderten Bild.
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/proto_schilder_shots.gd -- <out_dir>
## Bilder: schilder_1_uebersicht (Fernzeichen), _2_dorf (Vollschild), _3_markt (Nahstufe), _4_ohne_modelle (A2),
## _5_tooltip_dorf, _6_tooltip_stadt, _7_muehle_nah, _8_weiler_nah, _9_see (Voll im Mittelfeld) + Ausschnitte (2×).
## Messung: je sichtbares Schild im Bild: Text (98. Perzentil der Leuchtdichte) gegen Platte (Median), Platte und Rand
## gegen die Umgebung (Ring 4–7 px außerhalb). Schreibt <out_dir>/../kontrast_bild.csv.

const Schilder := preload("res://proto/proto_schilder.gd")

var s: Node
var sch
var out := ""
var zeilen: Array[String] = ["bild;schild;stufe;text_zu_platte;platte_zu_umgebung;rand_zu_umgebung;schild_zu_umgebung_max"]
var min_text := 99.0
var min_umg := 99.0
var min_rand := 99.0
var min_schild := 99.0


func _initialize() -> void:
	s = load("res://proto/prototyp_welt.tscn").instantiate()
	s.kette_modus = "fest"              # S8 AT-08: Szenen-Default ist "leer"; dieser Test misst die feste Kette
	root.add_child(s)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


static func _lum(c: Color) -> float:
	return Color(c.r, c.g, c.b).srgb_to_linear().get_luminance()


func _messen(name: String, img: Image) -> void:
	var vp := Rect2(Vector2.ZERO, Vector2(img.get_width(), img.get_height()))
	for e in sch.liste():
		if not e["sichtbar"] or e["alpha"] < 0.95:
			continue
		var r: Rect2 = e["rect"]
		if not vp.encloses(r.grow(10.0)):
			continue
		var inner := r.grow(-4.0)
		var lums: Array[float] = []
		for y in range(int(inner.position.y), int(inner.end.y)):
			for x in range(int(inner.position.x), int(inner.end.x)):
				lums.append(_lum(img.get_pixel(x, y)))
		lums.sort()
		if lums.size() < 20:
			continue
		var platte: float = lums[lums.size() / 2]
		var text: float = lums[int(lums.size() * 0.98)]
		var ring: Array[float] = []
		var o := r.grow(7.0)
		for y in range(int(o.position.y), int(o.end.y), 2):
			for x in range(int(o.position.x), int(o.end.x), 2):
				var p := Vector2(x, y)
				if r.grow(4.0).has_point(p) or p.y > r.end.y - 1.0:       # Ring ohne Zeiger unten
					continue
				ring.append(_lum(img.get_pixel(x, y)))
		if ring.is_empty():
			continue
		ring.sort()
		var umg: float = ring[ring.size() / 2]
		var c_text := (text + 0.05) / (platte + 0.05)
		var c_umg := (maxf(platte, umg) + 0.05) / (minf(platte, umg) + 0.05)
		# Rand: heller Saum der Platte (obere Kante, mittlere 60 %, 1–2 px innen) gegen die Umgebung
		var rand: Array[float] = []
		for x in range(int(r.position.x + r.size.x * 0.2), int(r.position.x + r.size.x * 0.8)):
			for dy in [1, 2]:
				rand.append(_lum(img.get_pixel(x, int(r.position.y) + dy)))
		rand.sort()
		var rl: float = rand[rand.size() / 2]
		var c_rand := (maxf(rl, umg) + 0.05) / (minf(rl, umg) + 0.05)
		var c_max := maxf(c_rand, c_umg)
		zeilen.append("%s;%s;%s;%.2f;%.2f;%.2f;%.2f" % [name, e["id"], ["Fern", "Voll", "Nah"][e["stufe"]], c_text, c_umg, c_rand, c_max])
		min_text = minf(min_text, c_text)
		min_umg = minf(min_umg, c_umg)
		min_rand = minf(min_rand, c_rand)
		min_schild = minf(min_schild, c_max)


func _shot(name: String, schnitt: Array[String] = []) -> void:
	await _frames(8)
	sch.aktualisiere(true)
	await _frames(3)
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out.path_join("schilder_%s.png" % name))
	_messen(name, img)
	for id in schnitt:
		var e: Dictionary = sch.eintrag(id)
		if e["sichtbar"]:
			var r: Rect2 = (e["rect"] as Rect2).grow(24.0)
			r = r.intersection(Rect2(Vector2.ZERO, Vector2(img.get_width(), img.get_height())))
			var c := img.get_region(Rect2i(r))
			c.resize(c.get_width() * 2, c.get_height() * 2, Image.INTERPOLATE_NEAREST)
			c.save_png(out.path_join("schild_%s_%s.png" % [id, name]))
	var z: Dictionary = s.zaehlung()
	var vis := []
	for e in sch.liste():
		if e["sichtbar"]:
			vis.append("%s(%s)" % [e["id"], ["Fern", "Voll", "Nah"][e["stufe"]]])
	print("saved schilder_%s.png  %s  | live %d Dreiecke / %d DC" % [name, ", ".join(vis), z["live_dreiecke"], z["live_dc"]])


func _kamera_auf(x: float, z: float, abstand: float, gier: float) -> void:
	s.ziel = Vector3(x, 0, z)
	s.abstand = abstand
	s.gier = gier
	s._kamera_anwenden()


func _run() -> void:
	await _frames(2)
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else ProjectSettings.globalize_path("res://").path_join("../_out/bilder")
	DirAccess.make_dir_recursive_absolute(out)
	sch = Schilder.bauen(s, s.cam, s.orte, s.terrain)
	await _frames(2)
	s.setze_preset(1)
	await _shot("1_uebersicht", ["erlenbach", "lindenfurt", "erlenmuehle", "gut_kuppenhof"])
	s.setze_preset(2)
	await _shot("2_dorf", ["erlenbach"])
	s.setze_preset(3)
	await _shot("3_markt", ["lindenfurt"])
	s.setze_preset(1)
	s.setze_modelle(false)
	await _shot("4_ohne_modelle")
	s.setze_modelle(true)
	s.setze_preset(2)
	sch.zeige_tooltip("erlenbach")
	await _frames(12)
	await _shot("5_tooltip_dorf")
	s.setze_preset(3)
	sch.zeige_tooltip("lindenfurt")
	await _frames(12)
	await _shot("6_tooltip_stadt")
	sch.zeige_tooltip("")
	var m: Dictionary = sch.eintrag("erlenmuehle")
	_kamera_auf(m["x"], m["z"], 120.0, 0.4)
	await _shot("7_muehle_nah", ["erlenmuehle"])
	var h: Dictionary = sch.eintrag("hasenwinkel")
	_kamera_auf(h["x"], h["z"], 220.0, 0.2)
	await _shot("8_weiler_nah", ["hasenwinkel"])
	s.setze_preset(5)
	await _shot("9_see", ["gut_kuppenhof", "erlenmuehle"])
	_kamera_auf(1500.0, 900.0, 900.0, 0.5)
	await _shot("10_mittel", ["erlenbach", "erlenmuehle"])
	var g: Dictionary = sch.eintrag("gut_kuppenhof")
	_kamera_auf(g["x"], g["z"], 700.0, 0.8)
	await _shot("11_gutshof_voll", ["gut_kuppenhof"])
	var fa := FileAccess.open(out.path_join("../kontrast_bild.csv"), FileAccess.WRITE)
	for z in zeilen:
		fa.store_line(z)
	fa.close()
	print("Bildmessung: %d Schilder, Text zu Platte min %.2f, Platte zu Umgebung min %.2f, Rand zu Umgebung min %.2f, Schild (max aus Platte, Rand) zu Umgebung min %.2f" % [zeilen.size() - 1, min_text, min_umg, min_rand, min_schild])
	quit(0)
