extends SceneTree
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
	var out: String = args[0]
	var pre: String = args[1]
	m.start_game("bergbau")
	m.toast_time = 0.0
	m.toast_label.text = ""
	m.focus(Vector2(172, 238), 6.0)
	await _shot(out.path_join(pre + "_kohlberg.png"))
	m.focus(Vector2(372, 228), 6.0)
	await _shot(out.path_join(pre + "_mittelfurt.png"))
	m.focus(Vector2(355, 360), 6.0)
	await _shot(out.path_join(pre + "_haberau.png"))
	quit(0)
