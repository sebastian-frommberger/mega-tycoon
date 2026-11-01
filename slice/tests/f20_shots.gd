extends SceneTree
## F-20 Screenshots (Mira, S6): Hover Mittelfurt, Hover Wagnis-Stadt (Steinbach), nach Gründung (Mittelfurt).
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/f20_shots.gd -- <out_dir>

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
	await create_timer(0.5).timeout          # Ring-Animation (0,35 s) und Panel-Slide abwarten
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(path)
	print("saved ", path, " ", img.get_size())


func _hover(id: String) -> void:
	m.sim_hover_active = true
	m.sim_hover = m.by_id[id].anchor()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://"
	DirAccess.make_dir_recursive_absolute(out)
	await _frames(4)
	_hover("mittelfurt")
	await _shot(out.path_join("f20_1_hover_mittelfurt.png"))
	_hover("steinbach")
	await _shot(out.path_join("f20_2_hover_wagnis_steinbach.png"))
	m.hq.select(m.by_id["mittelfurt"])
	m.sim_hover_active = false
	m.sim_hover = Vector2i(-1, -1)
	m.sim_hover_active = true
	await _shot(out.path_join("f20_3_gewaehlt_ghost_mittelfurt.png"))
	m.hq.confirm()
	m.set_speed(0)
	m.toast_time = 120.0      # Software-GL unter xvfb rendert langsam; Toast für das Bild stehen lassen
	await _shot(out.path_join("f20_4_nach_gruendung_mittelfurt.png"))
	quit(0)
