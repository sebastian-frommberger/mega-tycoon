extends SceneTree
## W-05 (S7, Mira, Block C): Screenshots Industrie-Lesbarkeit in der S7-Welt (Signalfläche + Plakette + Name + Status).
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/w05_shots.gd -- <out_dir>
## Bilder: w05_uebersicht_4km (Kartenmitte), w05_bergbau_4km, w05_agrar_4km, w05_agrar_1km, w05_bergbau_1km, w05_farm_500m.
## Haberau-HQ, Lizenz für Getreidefarm 1 (Status „ja“), Rest ohne Lizenz.

const Welt := preload("res://world/welt.gd")
const MainScript := preload("res://main.gd")

var m: Node


func _initialize() -> void:
	MainScript.world_override = "s7"
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(path: String) -> void:
	m.toast_time = 0.0
	m.toast_label.text = ""
	await _frames(14)
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(path)
	print("saved ", path, " ", img.get_size())


func z(meter: float) -> float:
	return Welt.zoom_for_distance_m("s7", meter)


func _mid(ids: Array) -> Vector2:
	var s := Vector2.ZERO
	for id in ids:
		var p: Vector3 = m.by_id[id].position
		s += Vector2(p.x, p.z)
	return s / ids.size()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://"
	DirAccess.make_dir_recursive_absolute(out)
	m.place_hq("haberau")
	m.eco.cash_cent = 50_000_000
	m.ui_buy_licence(m.by_id["farm_1"])
	m.ui_buy_licence(m.by_id["kohle_1"])
	m.sim_hover_active = true
	m.sim_hover = Vector2i(-1, -1)
	m.set_speed(0)
	m.focus(Vector2(m.GRID * 0.5, m.GRID * 0.5), z(4000.0))
	await _shot(out.path_join("w05_uebersicht_4km.png"))
	m.focus(_mid(["kohle_1", "erz_1", "kraftwerk_1", "stahl_1", "werkzeug_1"]), z(4000.0))
	await _shot(out.path_join("w05_bergbau_4km.png"))
	m.focus(_mid(["farm_1", "farm_2", "muehle_1", "farm_3", "muehle_2"]), z(4000.0))
	await _shot(out.path_join("w05_agrar_4km.png"))
	m.focus(_mid(["farm_1", "farm_2", "muehle_1"]), z(1000.0))
	await _shot(out.path_join("w05_agrar_1km.png"))
	m.focus(_mid(["kohle_1", "kraftwerk_1", "stahl_1"]), z(1000.0))
	await _shot(out.path_join("w05_bergbau_1km.png"))
	var f: Vector3 = m.by_id["farm_1"].position
	m.focus(Vector2(f.x, f.z), z(500.0))
	await _shot(out.path_join("w05_farm_500m.png"))
	MainScript.world_override = ""
	quit(0)
