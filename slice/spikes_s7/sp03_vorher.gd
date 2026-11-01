extends SceneTree
## SP-03 Vorher: aktueller Slice mit gleicher Kamera (FOV 50, Neigung, Abstand in Metern; Slice 1 Einheit = 10 m).
var m: Node
func _initialize() -> void:
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	_run.call_deferred()
func _frames(n: int) -> void:
	for i in n:
		await process_frame
func _view(t: Vector2, yaw_deg: float, d_m: float, pitch_deg: float) -> void:
	var d := d_m / 10.0
	var p := deg_to_rad(pitch_deg)
	m.focus(t, 6.0)
	m.rig.rotation = Vector3(0, deg_to_rad(yaw_deg), 0)
	m.cam.fov = 50.0
	m.cam.position = Vector3(0, sin(p) * d, cos(p) * d)
	m.cam.rotation = Vector3(-p, 0, 0)
	m.sun.directional_shadow_max_distance = clampf(d * 2.0, 60.0, 520.0)
func _shot(out: String, name: String) -> void:
	await _frames(15)
	print("VORHER perf %s draw_calls=%d primitives=%d" % [name, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("saved ", name)
func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	await _frames(5)
	m.toast_time = 0.0
	m.toast_label.text = ""
	# gleiche Meter-Perspektive wie sp03_uebersicht (4300 m, 61°) und sp03_stadt_nah (700 m, 40°)
	_view(Vector2(172, 236), 20.0, 4300.0, 60.9)
	await _shot(out, "vorher_uebersicht")
	_view(Vector2(164, 247), 22.0, 700.0, 40.0)
	await _shot(out, "vorher_stadt_nah")
	# maximales Herauszoomen im Slice (zoom 26 = Kamera-Grenze Slice) am Kartenrand NW
	m.rig.rotation = Vector3.ZERO
	m.cam.fov = 75.0
	m.cam.rotation = Vector3(-atan2(20.0, 16.0), 0, 0)
	m.focus(Vector2(0, 0), 26.0)
	await _shot(out, "vorher_rand_max")
	quit(0)
