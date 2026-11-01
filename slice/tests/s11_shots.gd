extends SceneTree
## S-11 Screenshots: Startdialog, Übersicht, Nahaufnahme, Mittelfurt.
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/s11_shots.gd -- <out_dir> <prefix>

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
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(path)
	print("saved ", path, " ", img.get_size())


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://"
	var pre: String = args[1] if args.size() > 1 else "s11"
	await _shot(out.path_join(pre + "_1_startdialog.png"))
	m.start_game("agrar")
	m.toast_time = 0.0
	m.toast_label.text = ""
	m.focus(Vector2(370, 330), 14.0)
	await _shot(out.path_join(pre + "_2_uebersicht.png"))
	m.focus(Vector2(364, 344), 2.0)
	await _shot(out.path_join(pre + "_3_nah_haberau.png"))
	m.focus(Vector2(396, 228), 4.0)
	await _shot(out.path_join(pre + "_4_mittelfurt.png"))
	m.focus(Vector2(364, 344), 5.0)
	await _shot(out.path_join(pre + "_5_mittel.png"))
	m.focus(Vector2(326, 388), 3.0)
	await _shot(out.path_join(pre + "_6_wald.png"))
	quit(0)
