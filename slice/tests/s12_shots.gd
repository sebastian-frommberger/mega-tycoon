extends SceneTree
## S-12 Screenshots: Kohlberg/Werkzeugfabrik und Mittelfurt/Mühle.
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/s12_shots.gd -- <out_dir> <prefix>
var m: Node

func _initialize() -> void:
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	_run.call_deferred()

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _shot(path: String) -> void:
	await _frames(12)
	root.get_viewport().get_texture().get_image().save_png(path)
	print("saved ", path)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://"
	var pre: String = args[1] if args.size() > 1 else "s12"
	m.place_hq("kohlberg")
	m.toast_time = 0.0
	m.toast_label.text = ""
	m.focus(Vector2(180, 240), 9.0)
	await _shot(out.path_join(pre + "_kohlberg.png"))
	m.focus(Vector2(372, 228), 8.0)
	await _shot(out.path_join(pre + "_mittelfurt.png"))
	quit(0)
