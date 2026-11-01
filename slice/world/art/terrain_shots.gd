extends SceneTree
## godot --path . --rendering-driver opengl3 -s res://world/art/terrain_shots.gd -- <outdir>   (unter xvfb-run)
func _init() -> void:
	var out := OS.get_cmdline_user_args()[0]
	get_root().size = Vector2i(1600, 900)
	var sc: Node3D = load("res://world/art/terrain_test.tscn").instantiate()
	get_root().add_child(sc)
	await process_frame
	var cam: Camera3D = sc.get_node("Cam")
	var views := {
		"terrain_uebersicht": [Vector3(3200, 2600, 5600), Vector3(2600, 100, 2600)],
		"terrain_gebirge": [Vector3(2400, 1500, 2800), Vector3(900, 600, 900)],
		"terrain_fluss": [Vector3(3000, 260, 3200), Vector3(3300, 0, 2300)],
		"terrain_fluss_nah": [Vector3(3050, 90, 3700), Vector3(3250, 0, 3500)],
	}
	for k in views:
		cam.position = views[k][0]; cam.look_at(views[k][1])
		await process_frame; await process_frame
		get_root().get_texture().get_image().save_png("%s/%s.png" % [out, k])
	quit()
