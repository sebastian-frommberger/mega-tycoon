extends SceneTree
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
	for z in [9.0, 7.0, 5.0]:
		m.focus(Vector2(178, 245), z)
		await _frames(12)
		root.get_viewport().get_texture().get_image().save_png(out.path_join("lab_%d.png" % int(z)))
	quit(0)
