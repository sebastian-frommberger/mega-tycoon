extends SceneTree
## Screenshot mit Ghost-Vorschau während eines (simulierten) Drags.
##   xvfb-run godot --rendering-driver opengl3 --path prototype -s res://tests/f13_shot.gd -- <out_ok.png> <out_bad.png>

var m: Node


func _initialize() -> void:
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(path: String) -> void:
	await _frames(8)
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(path)
	print("saved ", path, " ", img.get_size())


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_ok: String = args[0] if args.size() > 0 else "user://f13_ok.png"
	var out_bad: String = args[1] if args.size() > 1 else "user://f13_bad.png"
	for b in m.buildings:
		if b.display_name == "Mühle":
			m._buy(b)
	m.money = 4000.0
	m.rig.position = Vector3(40, 0, 122)
	m.zoom = 1.25
	m._apply_zoom()
	m.toast_time = 0.0
	m.toast_label.text = ""
	await _frames(3)
	# 1) baubar: weiß, Kosten am Cursor – erst gerade, dann 45°
	m._set_tool(m.Tool.ROAD)
	m.begin_drag(Vector2i(31, 116))
	m.drag_to(Vector2i(47, 122))
	print("ok-plan: ", m.plan["ok"], " ", m.plan["total"], " ", m.plan["reason"])
	await _shot(out_ok)
	m.cancel_drag()
	# 2) nicht baubar: Getreidefarm im Weg, roter Grund am Cursor
	m._set_tool(m.Tool.RAIL)
	m.begin_drag(Vector2i(34, 123))
	m.drag_to(Vector2i(50, 123))
	print("bad-plan: ", m.plan["ok"], " ", m.plan["total"], " ", m.plan["reason"])
	await _shot(out_bad)
	quit(0)
