extends SceneTree
func _init() -> void:
	var out := OS.get_cmdline_user_args()[0]
	get_root().size = Vector2i(1600, 900)
	var sc := Node3D.new(); sc.set_script(load("res://world/art/kit_test.gd")); get_root().add_child(sc)
	await process_frame
	var cam: Camera3D = sc.get_node("Cam")
	var views := {"kit_autotile": [Vector3(110, 230, 215), Vector3(110, 0, 90)], "kit_haeuser": [Vector3(50, 55, 200), Vector3(110, 8, 90)]}
	for k in views:
		cam.position = views[k][0]; cam.look_at(views[k][1])
		await process_frame; await process_frame
		get_root().get_texture().get_image().save_png("%s/%s.png" % [out, k])
	quit()
