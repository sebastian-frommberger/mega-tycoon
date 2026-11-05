extends RefCounted
## WA-02 (TA): F12 "Stelle merken". Speichert Screenshot (PNG, ohne HUD) + JSON unter user://stellen/.
## Eigene Datei, damit prototyp_welt.gd nur eine Zeile braucht (Mira arbeitet dort ebenfalls).
##   Einhaengen:  const StelleMerken := preload("res://proto/stelle_merken.gd")  und in _unhandled_input
##                elif k == KEY_F12: StelleMerken.merken(self)
## Datei: user://stellen/stelle_<JJJJMMTT>_<hhmmss>_<laufnr>.png + .json (gleicher Name)
## JSON (format 1): Kamera (position, ziel, abstand, gier_rad, gier_grad, pitch_grad, fov), Preset, Sim-Tick, Zeit,
##   welt_seed (aus proto_meta.json "quelle"), build_hash (git, falls ermittelbar; sonst "unbekannt"), Schalter, Engine/Renderer.
## Wiederherstellen (Vorher/Nachher exakt deckungsgleich):  StelleMerken.anwenden(welt, json_dict)

const ORDNER := "user://stellen"
const FORMAT := 1

static var _laufnr := 0


## Taste F12. Laeuft als Coroutine (zwei Frames ohne HUD fuers Bild); Aufrufer muss nicht warten.
static func merken(welt: Node3D) -> void:
	var layer: CanvasLayer = _hud_layer(welt)
	var hud_war_an: bool = layer.visible if layer != null else false
	if layer != null:
		layer.visible = false
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := welt.get_viewport().get_texture().get_image()
	if layer != null:
		layer.visible = hud_war_an
	DirAccess.make_dir_recursive_absolute(ORDNER)
	_laufnr += 1
	var d := Time.get_datetime_dict_from_system()
	var basis_name := "stelle_%04d%02d%02d_%02d%02d%02d_%02d" % [d["year"], d["month"], d["day"], d["hour"], d["minute"], d["second"], _laufnr]
	var fehler := img.save_png(ORDNER.path_join(basis_name + ".png"))
	var info := zustand(welt)
	info["bild"] = basis_name + ".png"
	info["bild_px"] = [img.get_width(), img.get_height()]
	var f := FileAccess.open(ORDNER.path_join(basis_name + ".json"), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(info, "  "))
		f.close()
	var ok := fehler == OK and f != null
	var voll := ProjectSettings.globalize_path(ORDNER)
	print("STELLE_MERKEN %s %s -> %s" % ["ok" if ok else "FEHLER", basis_name, voll])
	_hinweis(welt, ("Stelle gespeichert: %s" % basis_name) if ok else "Stelle NICHT gespeichert (Schreibfehler)", voll)


## Kamera- und Weltzustand als Dictionary (JSON-tauglich).
static func zustand(welt: Node3D) -> Dictionary:
	var cam: Camera3D = welt.get("cam")
	var cp: Vector3 = cam.global_position if cam != null else Vector3.ZERO
	var ziel: Vector3 = welt.get("ziel")
	var abstand: float = welt.get("abstand")
	var gier: float = welt.get("gier")
	var sim = welt.get("proto_sim")
	var meta := _meta(welt)
	var vp_size := welt.get_viewport().get_visible_rect().size
	return {
		"format": FORMAT,
		"zeit_lokal": Time.get_datetime_string_from_system(false, true),
		"zeit_unix": Time.get_unix_time_from_system(),
		"welt_seed": _seed(meta),
		"welt_quelle": _quelle(meta),
		"build_hash": _build_hash(),
		"godot": str(Engine.get_version_info().get("string", "?")),
		"renderer": str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "?")),
		"kamera": {
			"position": [cp.x, cp.y, cp.z],
			"ziel": [ziel.x, ziel.y, ziel.z],
			"abstand": abstand,
			"gier_rad": gier,
			"gier_grad": rad_to_deg(gier),
			"pitch_grad": welt.call("pitch_for", abstand),
			"fov": cam.fov if cam != null else 0.0,
			"folgen": welt.get("folgen"),
		},
		"preset": welt.get("preset_aktiv"),
		"sim_tick": sim.ticks if sim != null else -1,
		"sim_tempo": welt.get("sim_tempo"),
		"startjahr": welt.get("startjahr"),
		"schalter": {
			"modelle": welt.get("modelle_an"),
			"schilder": welt.get("schilder_an"),
			"wasser": welt.get("wasser_modus"),
			"easing": welt.get("easing_an"),
		},
		"fenster_px": [int(vp_size.x), int(vp_size.y)],
	}


## Kamera wie gespeichert setzen (ziel/abstand/gier; die Position folgt aus der Kamerakurve der Welt).
static func anwenden(welt: Node3D, info: Dictionary) -> void:
	var k: Dictionary = info.get("kamera", {})
	var z: Array = k.get("ziel", [0, 0, 0])
	welt.set("folgen", -1)
	welt.set("ziel", Vector3(float(z[0]), 0.0, float(z[2])))
	welt.set("abstand", float(k.get("abstand", 400.0)))
	welt.set("gier", float(k.get("gier_rad", 0.0)))
	welt.call("_kamera_anwenden")


static func _hud_layer(welt: Node) -> CanvasLayer:
	var n: Node = welt.get("hud")
	while n != null and not (n is CanvasLayer):
		n = n.get_parent()
	return n as CanvasLayer


static func _meta(welt: Node) -> Dictionary:
	var pfad := "res://world/data/proto/proto_meta.json"
	var q = welt.get("quellen")
	if q is Dictionary and q.has("terrain_dir"):
		pfad = str(q["terrain_dir"]).path_join("proto_meta.json")
	if not FileAccess.file_exists(pfad):
		return {}
	var v = JSON.parse_string(FileAccess.get_file_as_string(pfad))
	return v if v is Dictionary else {}


static func _quelle(meta: Dictionary) -> String:
	var f = meta.get("fenster", {})
	return str(f.get("quelle", meta.get("quelle", ""))) if f is Dictionary else str(meta.get("quelle", ""))


static func _seed(meta: Dictionary) -> int:
	var re := RegEx.new()
	re.compile("Seed\\s+(\\d+)")
	var m := re.search(_quelle(meta))
	return int(m.get_string(1)) if m != null else -1


## Kurzer Commit-Hash: git (Entwicklerrechner); sonst res://build_hash.txt (falls ein Export sie schreibt); sonst "unbekannt".
static func _build_hash() -> String:
	var dir := ProjectSettings.globalize_path("res://")
	var out: Array = []
	var code := OS.execute("git", ["-C", dir, "rev-parse", "--short", "HEAD"], out, false)
	if code == 0 and out.size() > 0 and str(out[0]).strip_edges() != "":
		var h := str(out[0]).strip_edges()
		var st: Array = []
		if OS.execute("git", ["-C", dir, "status", "--porcelain", "--untracked-files=no"], st, false) == 0 and st.size() > 0 \
				and str(st[0]).strip_edges() != "":
			h += "+dirty"
		return h
	if FileAccess.file_exists("res://build_hash.txt"):
		return FileAccess.get_file_as_string("res://build_hash.txt").strip_edges()
	return "unbekannt"


## Kleiner Hinweis unten links, verschwindet nach 3,5 s (kein Modal).
static func _hinweis(welt: Node, text: String, pfad: String) -> void:
	var cl := CanvasLayer.new()
	cl.layer = 50
	var l := Label.new()
	l.text = text + "\n" + pfad
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(0.96, 0.92, 0.84))
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.05))
	l.add_theme_constant_override("outline_size", 4)
	l.anchor_top = 1.0
	l.anchor_bottom = 1.0
	l.offset_left = 14.0
	l.offset_top = -52.0
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(l)
	welt.add_child(cl)
	var tw := cl.create_tween()
	tw.tween_interval(3.5)
	tw.tween_callback(cl.queue_free)
