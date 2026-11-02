extends SceneTree
## W-03 (S7, Sophie): Screenshots der Städte in der S7-Welt + Render-Zählwerte je Ansicht (Dreiecke, Draw Calls).
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/w03_shots.gd -- <out_dir>
## Bilder: w03_kleinstadt_uebersicht (Kohlberg ~1,5 km), w03_kleinstadt_nah (~300 m), w03_dorf (Haberau),
## w03_stadt (Mittelfurt ~2 km), w03_stadt_nah (Mittelfurt 700 m), w03_bahnhof.

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
	await _frames(12)
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(path)
	var tris := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var dc := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	print("saved %s  Dreiecke %d  DrawCalls %d  Kamera %.0f m" % [path.get_file(), tris, dc, m.world_s7.camera_distance_m(m)])


func z(meter: float) -> float:
	return Welt.zoom_for_distance_m("s7", meter)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://"
	m.place_hq("kohlberg")
	m.set_speed(0)
	m.sim_hover_active = true
	m.sim_hover = Vector2i(-1, -1)
	var kb: Vector2 = Vector2(m.by_id["kohlberg"].anchor()) + Vector2(0.5, 0.5)
	m.focus(kb, z(1500.0))
	await _shot(out.path_join("w03_kleinstadt_uebersicht.png"))
	m.focus(kb + Vector2(-3, 2), z(300.0))
	await _shot(out.path_join("w03_kleinstadt_nah.png"))
	var hab: Vector2 = Vector2(m.by_id["haberau"].anchor()) + Vector2(0.5, 0.5)
	m.focus(hab, z(700.0))
	await _shot(out.path_join("w03_dorf.png"))
	var mf: Vector2 = Vector2(m.by_id["mittelfurt"].anchor()) + Vector2(0.5, 0.5)
	m.focus(mf, z(2200.0))
	await _shot(out.path_join("w03_stadt.png"))
	m.focus(mf, z(700.0))
	await _shot(out.path_join("w03_stadt_nah.png"))
	var stn: Dictionary = m.city_gen.cities["kohlberg"]["station"]
	if not stn.is_empty():
		m.focus(stn["pos"], z(260.0))
		await _shot(out.path_join("w03_bahnhof.png"))
	m.focus(Vector2(264, 220), z(4300.0))
	await _shot(out.path_join("w03_perf_uebersicht_4300.png"))
	m.free()
	MainScript.world_override = ""
	quit(0)
