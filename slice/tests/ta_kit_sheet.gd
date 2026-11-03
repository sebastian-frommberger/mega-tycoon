extends SceneTree
## TA W2: Kontaktbogen von Kit-Modellen (Entwicklungshilfe).  -- <out.png> <kit> <modell,modell,...>
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var a := OS.get_cmdline_user_args()
	var out: String = a[0]
	var kit: String = a[1]
	var namen: PackedStringArray = a[2].split(",")
	var w := Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.8, 0.85, 0.9)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.8, 0.8)
	e.ambient_light_energy = 0.6
	env.environment = e
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	w.add_child(sun)
	var n := namen.size()
	var cols := int(ceil(sqrt(n)))
	var sp := 2.2
	for i in n:
		var p := "res://props/kenney_proto/%s/%s.glb" % [kit, namen[i]]
		var ps := load(p) as PackedScene
		if ps == null:
			print("fehlt ", p)
			continue
		var m := ps.instantiate() as Node3D
		m.position = Vector3((i % cols) * sp, 0, (i / cols) * sp)
		w.add_child(m)
		var l := Label3D.new()
		l.text = namen[i]
		l.font_size = 48
		l.pixel_size = 0.004
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.position = m.position + Vector3(0, -0.25, 0.7)
		l.modulate = Color.BLACK
		w.add_child(l)
		# Achsenkreuz +x rot, +z blau
		var ax := MeshInstance3D.new()
		var bm := BoxMesh.new(); bm.size = Vector3(0.6, 0.02, 0.02)
		var mt := StandardMaterial3D.new(); mt.albedo_color = Color.RED; bm.material = mt
		ax.mesh = bm; ax.position = m.position + Vector3(0.3, 0, -0.75); w.add_child(ax)
		var az := MeshInstance3D.new()
		var bz := BoxMesh.new(); bz.size = Vector3(0.02, 0.02, 0.6)
		var mz := StandardMaterial3D.new(); mz.albedo_color = Color.BLUE; bz.material = mz
		az.mesh = bz; az.position = m.position + Vector3(-0.75, 0, 0.3); w.add_child(az)
	var cam := Camera3D.new()
	w.add_child(cam)
	var c := Vector3((cols - 1) * sp * 0.5, 0.4, (ceil(float(n) / cols) - 1) * sp * 0.5)
	cam.position = c + Vector3(0.55, 0.6, 1.0).normalized() * (cols * sp * 0.62)
	cam.look_at(c)
	cam.current = true
	for i in 6:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(out)
	quit(0)
