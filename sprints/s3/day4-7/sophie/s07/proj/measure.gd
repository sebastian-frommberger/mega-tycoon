extends SceneTree
func _init() -> void:
	for p in ["NatureKit/tree_default","NatureKit/tree_pineDefaultA","NatureKit/rock_largeA","CityKitIndustrial/building-a","CityKitIndustrial/building-f","CityKitIndustrial/chimney-large","CityKitIndustrial/detail-tank","WatercraftPack/ship-cargo-a"]:
		var n: Node3D = (load("res://models/%s.glb" % p) as PackedScene).instantiate()
		var b := _aabb(n)
		print("%s pos=%s size=%s" % [p, b.position, b.size])
	quit()
func _aabb(n: Node) -> AABB:
	var box := AABB(); var first := true
	var st := [n]
	while not st.is_empty():
		var c = st.pop_back()
		st.append_array(c.get_children())
		if c is MeshInstance3D:
			var t: Transform3D = c.transform; var q: Node = c.get_parent()
			while q != null and q != n:
				t = (q as Node3D).transform * t; q = q.get_parent()
			var a: AABB = t * c.get_aabb()
			box = a if first else box.merge(a); first = false
	return box
