extends SceneTree
func _init() -> void:
	var names := ["road-straight","road-bend","road-intersection","road-crossroad","road-end","road-bridge","road-end-round"]
	var root := Node3D.new(); get_root().add_child(root)
	var i := 0
	for n in names:
		var doc := GLTFDocument.new(); var st := GLTFState.new()
		doc.append_from_file("res://props/kenney_city/roads/%s.glb" % n, st)
		var m := doc.generate_scene(st) as Node3D
		m.position = Vector3(i * 1.5, 0, 0)
		root.add_child(m)
		var mk := MeshInstance3D.new(); var b := BoxMesh.new(); b.size = Vector3(0.12,0.1,0.12); mk.mesh = b
		var mat := StandardMaterial3D.new(); mat.albedo_color = Color.RED; mk.material_override = mat
		mk.position = m.position + Vector3(0, 0.05, -0.55); root.add_child(mk)   # -Z = rot
		var mk2 := MeshInstance3D.new(); mk2.mesh = b; var mat2 := StandardMaterial3D.new(); mat2.albedo_color = Color.GREEN; mk2.material_override = mat2
		mk2.position = m.position + Vector3(0.55, 0.05, 0); root.add_child(mk2)  # +X
		var l := Label3D.new(); l.text = n; l.pixel_size = 0.006; l.rotation_degrees = Vector3(-90,0,0); l.position = m.position + Vector3(0,0.05,1.3); root.add_child(l)
		i += 1
	var cam := Camera3D.new(); cam.projection = Camera3D.PROJECTION_ORTHOGONAL; cam.keep_aspect = Camera3D.KEEP_WIDTH; cam.size = 10.8; root.add_child(cam)
	cam.position = Vector3(4.5, 10, 0); cam.rotation_degrees = Vector3(-90, 0, 0)
	var dl := DirectionalLight3D.new(); dl.rotation_degrees = Vector3(-60, 20, 0); root.add_child(dl)
	var we := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.3,0.5,0.3); e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color.WHITE; we.environment = e; root.add_child(we)
	get_root().size = Vector2i(1600, 400)
	await process_frame; await process_frame; await process_frame
	get_root().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	quit()
