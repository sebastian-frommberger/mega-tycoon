extends Node3D
## Testszene Autotile-Strassen + Haeuser mit roof_palette.gdshader (S7 Sophie). Liest road_tiles.json / building_sets.json.
## GLBs werden zur Laufzeit per GLTFDocument geladen (kein Editor-Import noetig).
const FELD := 25.0
const MAP := [
	"..........",
	".#######..",
	".#..#..#..",
	".#..#..#..",
	".#######..",
	".#..#.....",
	".#..###...",
	"..........",
]
var _roads: Dictionary
var _sets: Dictionary
var _mesh_cache := {}
var _mat_cache := {}
var tri_total := 0

func _load_json(p: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(p))

func _mesh(path: String) -> Array:   # [Mesh, Texture2D]
	if _mesh_cache.has(path):
		return _mesh_cache[path]
	var doc := GLTFDocument.new(); var st := GLTFState.new()
	doc.append_from_file(path, st)  # B-2: res://-Pfad, kein globalize_path
	var n := doc.generate_scene(st)
	var mi := n.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var tex: Texture2D = null
	var src := mi.mesh.surface_get_material(0)
	if src is StandardMaterial3D:
		tex = (src as StandardMaterial3D).albedo_texture
	var r := [mi.mesh, tex]
	_mesh_cache[path] = r
	return r

func _mat(tex: Texture2D, tint: Vector3, remap: float) -> ShaderMaterial:
	var key := str(tex.get_rid()) + str(tint) + str(remap)
	if _mat_cache.has(key):
		return _mat_cache[key]
	var sm := ShaderMaterial.new(); sm.shader = load("res://world/art/roof_palette.gdshader")
	sm.set_shader_parameter("tex", tex); sm.set_shader_parameter("tint", tint); sm.set_shader_parameter("remap", remap)
	_mat_cache[key] = sm
	return sm

func _put(path: String, pos: Vector3, rot_deg: float, scale: Vector3, tint: Vector3, remap: float) -> void:
	var m := _mesh(path)
	var mi := MeshInstance3D.new(); mi.mesh = m[0]
	mi.material_override = _mat(m[1], tint, remap)
	mi.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(rot_deg)).scaled_local(scale), pos)
	add_child(mi)
	for s in (m[0] as Mesh).get_surface_count():
		var a := (m[0] as Mesh).surface_get_arrays(s)
		tri_total += (a[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3

func _ready() -> void:
	_roads = _load_json("res://world/art/road_tiles.json")["strassen"]
	_sets = _load_json("res://world/art/building_sets.json")
	var rp := "res://props/kenney_city/roads/"
	var kl: Dictionary = _roads["klassen"]["stadtstrasse"]
	var w: float = kl["breite_m"]; var arm: float = kl["arm_laenge_m"]
	var grey := Vector3(0.62, 0.60, 0.57)
	var rows: Array = MAP
	var H := rows.size(); var W := (rows[0] as String).length()
	var dirs := {"N": Vector2i(0, -1), "E": Vector2i(1, 0), "S": Vector2i(0, 1), "W": Vector2i(-1, 0)}
	var bit := {"N": 1, "E": 2, "S": 4, "W": 8}
	for y in H:
		for x in W:
			if rows[y][x] != "#":
				continue
			var mask := 0
			for d in dirs:
				var q: Vector2i = Vector2i(x, y) + dirs[d]
				if q.x >= 0 and q.y >= 0 and q.x < W and q.y < H and rows[q.y][q.x] == "#":
					mask |= bit[d]
			var t: Dictionary = _roads["autotile"][str(mask)]
			var c := Vector3(x * FELD, 0.05, y * FELD)
			if mask == 5 or mask == 10:
				_put(rp + t["modell"], c, t["rot_y_grad"], Vector3(FELD + 0.1, 1, w), grey, 0.0)
			else:
				var sz := w if mask != 0 else w
				_put(rp + t["modell"], c, t["rot_y_grad"], Vector3(sz, 1, sz), grey, 0.0)
				for d in String(t["offen"]):
					var v: Vector2i = dirs[d]
					var off := Vector3(v.x, 0, v.y) * (w * 0.5 + arm * 0.5)
					var rot := 0.0 if (d == "E" or d == "W") else 90.0
					_put(rp + "road-straight.glb", c + off, rot, Vector3(arm, 1, w), grey, 0.0)
	# Haeuser in Blockmitten (Zellen "." im Innenbereich) nach Zone
	var by_zone := {"kern": [], "mitte": [], "rand": []}
	for b in _sets["gebaeude"]:
		if by_zone.has(b["zone"]) and b["min_stufe"] != "grossstadt":
			by_zone[b["zone"]].append(b)
	var rng := RandomNumberGenerator.new(); rng.seed = 5
	for y in range(1, H - 1):
		for x in range(1, W - 1):
			if rows[y][x] == "#":
				continue
			var zone := "kern" if (x >= 4 and x <= 6 and y >= 2 and y <= 4) else ("mitte" if x < 8 else "rand")
			for k in 2:
				var b: Dictionary = by_zone[zone][rng.randi() % by_zone[zone].size()]
				var kit: String = b["kit"]
				var tint := Vector3(0.88, 0.84, 0.78) if kit == "suburban" else Vector3(0.86, 0.80, 0.72)
				var p := Vector3(x * FELD + (k - 0.5) * 12.0, 0.0, y * FELD + rng.randf_range(-3, 3))
				_put(b["modell"], p, 0.0 if rng.randf() < 0.5 else 180.0, Vector3.ONE * float(b["skalierung"]), tint, 1.0)
	var dl := DirectionalLight3D.new(); dl.rotation_degrees = Vector3(-50, -30, 0); dl.shadow_enabled = true; add_child(dl)
	var we := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.62, 0.74, 0.88)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.8, 0.84, 0.9); e.ambient_light_energy = 0.6
	we.environment = e; add_child(we)
	var ground := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(500, 400); ground.mesh = pm
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.451, 0.580, 0.361); ground.material_override = gm
	ground.position = Vector3(120, -0.05, 90); add_child(ground)
	var cam := Camera3D.new(); cam.name = "Cam"; cam.fov = 50.0; cam.far = 3000.0; add_child(cam)
	cam.position = Vector3(110, 210, 280); cam.look_at(Vector3(110, 0, 90))
	print("kit_test dreiecke=", tri_total)
