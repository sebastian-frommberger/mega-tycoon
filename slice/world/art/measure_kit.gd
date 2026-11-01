extends SceneTree
## Misst GLBs (AABB, Dreiecke). Aufruf: godot --headless -s res://world/art/measure_kit.gd -- <ordner> <out.json>
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var res := {}
	var d := DirAccess.open(a[0])
	for f in d.get_files():
		if not f.ends_with(".glb"):
			continue
		var doc := GLTFDocument.new()
		var st := GLTFState.new()
		if doc.append_from_file(a[0] + "/" + f, st) != OK:
			continue
		var n := doc.generate_scene(st)
		var bb := AABB()
		var tri := 0
		var first := true
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			var t := m.global_transform if m.is_inside_tree() else _gt(m, n)
			var ab := t * m.mesh.get_aabb()
			bb = ab if first else bb.merge(ab)
			first = false
			for s in m.mesh.get_surface_count():
				var arr := m.mesh.surface_get_arrays(s)
				var ix = arr[Mesh.ARRAY_INDEX]
				tri += (ix.size() if ix != null else arr[Mesh.ARRAY_VERTEX].size()) / 3
		res[f] = {"pos": [bb.position.x, bb.position.y, bb.position.z], "size": [bb.size.x, bb.size.y, bb.size.z], "tris": tri}
		n.free()
	var fa := FileAccess.open(a[1], FileAccess.WRITE)
	fa.store_string(JSON.stringify(res, " "))
	quit()
func _gt(m: Node3D, root: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	var c: Node = m
	while c != null and c != root:
		if c is Node3D: t = (c as Node3D).transform * t
		c = c.get_parent()
	return t
