extends SceneTree
## TA W2: Dreiecke je Knoten der Prototyp-Szene (Uebersicht), headless. -- [preset]
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var s: Node = (load("res://proto/prototyp_welt.tscn") as PackedScene).instantiate()
	s.kette_modus = "fest"              # S8 AT-08: Szenen-Default ist "leer"; dieser Test misst die feste Kette
	root.add_child(s)
	var pr := 1
	if OS.get_cmdline_user_args().size() > 0:
		pr = int(OS.get_cmdline_user_args()[0])
	s.setze_preset(pr)
	for i in 8:
		await process_frame
	var liste: Array = []
	var stapel: Array = [s]
	while not stapel.is_empty():
		var n: Node = stapel.pop_back()
		if n is Node3D and not (n as Node3D).is_visible_in_tree():
			continue
		if n is MultiMeshInstance3D:
			var mm: MultiMesh = n.multimesh
			liste.append([mm.instance_count * int(s._mesh_tris(mm.mesh)), str(n.get_path()).get_file(), mm.instance_count, (n as GeometryInstance3D).visibility_range_end])
		elif n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			liste.append([s._mesh_tris(n.mesh), str(n.get_path()).get_file(), 1, (n as GeometryInstance3D).visibility_range_end])
		for c in n.get_children():
			stapel.append(c)
	liste.sort_custom(func(a, b): return a[0] > b[0])
	var summe := 0
	for e in liste:
		summe += e[0]
	print("Preset %d Summe %d, Kamera %s" % [pr, summe, str(s.cam.global_position)])
	for i in mini(25, liste.size()):
		print("  %8d  %-28s n=%d  vis_end=%.0f" % liste[i])
	quit(0)
