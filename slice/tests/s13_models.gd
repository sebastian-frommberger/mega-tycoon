extends SceneTree
func _initialize() -> void:
	var names := ["building-a","building-f","chimney-large","detail-tank","rock_largeA"]
	var root3 := Node3D.new(); root.add_child(root3)
	var x := 0.0
	for n in names:
		var gd := GLTFDocument.new(); var st := GLTFState.new()
		gd.append_from_file(ProjectSettings.globalize_path("res://props/kenney/%s.glb" % n), st)
		var r := gd.generate_scene(st); r.position = Vector3(x, 0, 0); root3.add_child(r); x += 3.0
	var cam := Camera3D.new(); root3.add_child(cam); cam.position = Vector3(6, 4, 8); cam.look_at_from_position(Vector3(6, 3, 8), Vector3(6, 0.5, 0))
	var l := DirectionalLight3D.new(); l.rotation_degrees = Vector3(-50, -30, 0); root3.add_child(l)
	var we := WorldEnvironment.new(); we.environment = Environment.new(); we.environment.background_mode = Environment.BG_COLOR; we.environment.background_color = Color(0.45,0.6,0.4); root3.add_child(we)
	for i in 8: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/gd/sprint6/b/sophie/models.png")
	quit(0)
