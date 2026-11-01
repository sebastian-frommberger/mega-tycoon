extends SceneTree
## S-13: HQ-Ghost und gesetzt neben Kohlberg. xvfb ... -s res://tests/s13_hq.gd -- <out_dir>
const HQ := preload("res://props/hq_building.gd")
var m: Node
func _initialize() -> void:
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	_run.call_deferred()
func _frames(n: int) -> void:
	for i in n:
		await process_frame
func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	m.start_game("bergbau")
	m.toast_time = 0.0
	m.toast_label.text = ""
	var g: Node3D = HQ.spawn(m, Vector3(176, 0, 238), true)
	var h: Node3D = HQ.spawn(m, Vector3(184, 0, 238), false)
	assert(g != null and h != null)
	m.focus(Vector2(180, 238), 2.0)
	await _frames(12)
	root.get_viewport().get_texture().get_image().save_png(out.path_join("hq_ghost_gesetzt.png"))
	g.free()
	h.free()
	print("HQ OK, Firmenfarbe ", HQ.company_color())
	quit(0)
