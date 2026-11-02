extends SceneTree
## W-02 (S7, Felix): Screenshots der generierten S7-Welt mit Terrain.
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path . -s res://tests/s7_terrain_shots.gd -- <ordner>
## Übersicht (5,6 km), Gebirge, Fluss mit gebauter Brücke, Max-Zoom-Rand Ost (rand_max_ost) + 4 Ecken, eine Stadt.

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
	await _frames(10)
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(path)
	print("saved ", path)


func z(meter: float) -> float:
	return Welt.zoom_for_distance_m("s7", meter)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://"
	var w = m.world_s7
	m.eco.cash_cent = 50_000_000
	print("Ladezeit %.0f ms, Terrain %.0f ms, %d Dreiecke" % [m.load_ms, w.terrain_node.build_ms, w.terrain_node.tri_count])
	m.focus(Vector2(256, 256), z(5600))
	await _shot(out + "/s7_uebersicht.png")
	# Gebirge: höchstes Feld
	var best := 0
	for i in w.hoehe_boden.size():
		if w.hoehe_boden[i] > w.hoehe_boden[best]:
			best = i
	m.focus(Vector2(best % 512, best / 512 + 40), z(2200))
	await _shot(out + "/s7_gebirge.png")
	# Fluss mit Brücke: erste gerade Querung <= 8 Felder, Straße bauen
	var br: Array = []
	for i in range(80, 440, 9):
		if not br.is_empty():
			break
		for vertical in [true, false]:
			var run := 0
			for k in range(1, 511):
				var c := Vector2i(i, k) if vertical else Vector2i(k, i)
				if m.terrain_at(c) == m.Terrain.WATER:
					run += 1
					continue
				if run > 0 and run <= 8:
					var d := Vector2i(0, 1) if vertical else Vector2i(1, 0)
					var a: Vector2i = c - d * (run + 6)
					var b: Vector2i = c + d * 5
					if m.build_track(a, b, false):
						br = [a, b]
						break
				run = 0
			if not br.is_empty():
				break
	print("Brücke ", br)
	if not br.is_empty():
		var mid := (Vector2(br[0]) + Vector2(br[1])) * 0.5
		m.focus(mid, z(260))
		await _shot(out + "/s7_fluss_bruecke.png")
		m.focus(mid, z(1200))
		await _shot(out + "/s7_fluss.png")
	# Max-Zoom-Rand: Ost-Kante + 4 Ecken
	m.focus(Vector2(512, 256), z(5600))
	await _shot(out + "/s7_rand_max_ost.png")
	var names := ["nw", "no", "sw", "so"]
	var k2 := 0
	for c in [Vector2(0, 0), Vector2(512, 0), Vector2(0, 512), Vector2(512, 512)]:
		m.focus(c, z(5600))
		await _shot(out + "/s7_rand_ecke_%s.png" % names[k2])
		k2 += 1
	# Stadt: größte Stadt
	var st: Dictionary = m.map_data["staedte"][0]
	for s in m.map_data["staedte"]:
		if s["einwohner_anzahl"] > st["einwohner_anzahl"]:
			st = s
	m.focus(Vector2(st["x_felder"], st["y_felder"]), z(900))
	await _shot(out + "/s7_stadt_%s.png" % st["id"])
	quit(0)
