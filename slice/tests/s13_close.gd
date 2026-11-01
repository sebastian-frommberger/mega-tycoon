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
	var a := OS.get_cmdline_user_args()
	m.place_hq("kohlberg")
	m.toast_time = 0.0
	m.toast_label.text = ""
	var z := float(a[1]) if a.size() > 1 else 3.0
	for id in ["stahl_1", "kohle_1", "erz_1", "kraftwerk_1", "werkzeug_1", "holz_berg", "farm_3", "muehle_2", "farm_1", "muehle_1"]:
		var b = m.by_id[id]
		m.focus(Vector2(b.position.x, b.position.z), z)
		await _frames(10)
		root.get_viewport().get_texture().get_image().save_png(a[0].path_join("close_%s.png" % id))
	quit(0)
