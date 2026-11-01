extends Node3D
## S-07 Probeszene: Kits Nature, Industrial-Anbauten, Schiff auf dem 10-m-Raster, Massstabsmessung je Kit.
const MODELLE := [
	["nature_kit", "res://models/NatureKit/tree_default.glb"],
	["nature_kit", "res://models/NatureKit/tree_pineDefaultA.glb"],
	["nature_kit", "res://models/NatureKit/rock_largeA.glb"],
	["city_kit_industrial", "res://models/CityKitIndustrial/building-a.glb"],
	["city_kit_industrial", "res://models/CityKitIndustrial/building-f.glb"],
	["city_kit_industrial", "res://models/CityKitIndustrial/chimney-large.glb"],
	["city_kit_industrial", "res://models/CityKitIndustrial/detail-tank.glb"],
	["watercraft_pack", "res://models/WatercraftPack/ship-cargo-a.glb"],
]

func _ready() -> void:
	var L := KenneyLoader.new("res://kenney_faktoren.json")
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); sun.shadow_enabled = true; add_child(sun)
	var env := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.72, 0.76, 0.70)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.6, 0.6, 0.6); env.environment = e; add_child(env)
	var ground := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(300, 100); ground.mesh = pm
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.56, 0.60, 0.49); ground.material_override = gm; ground.position = Vector3(110, 0, 0); add_child(ground)
	for i in range(-4, 27):
		_line(Vector3(i * 10, 0.03, -50), Vector3(i * 10, 0.03, 50))
	for j in range(-5, 6):
		_line(Vector3(-40, 0.03, j * 10), Vector3(260, 0.03, j * 10))
	# Referenz: Graubox 1 Feld (10 x 10 m Grundflaeche, 1 m hoch) am Ursprung
	var ref := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(10, 1, 10); ref.mesh = bm
	var rm := StandardMaterial3D.new(); rm.albedo_color = Color(0.5, 0.5, 0.55); ref.material_override = rm; ref.position = Vector3(5, 0.5, 5); add_child(ref)
	_label("Referenzfeld 10 x 10 m", Vector3(5, 8, 5))
	var rows: Array[String] = ["kit;modell;faktor;laenge_x_m;hoehe_y_m;tiefe_z_m;basis_y_m;modus"]
	var x := 25.0
	var res := {}
	for i in MODELLE.size():
		var kit: String = MODELLE[i][0]; var path: String = MODELLE[i][1]
		var m := L.load_model(kit, path)
		if m == null: continue
		var b := L.model_aabb(m)
		# Zellenmitte auf Raster: Mitte der AABB in X auf Feldmitte schieben fuer die Darstellung
		var cells := int(ceil(b.size.x / 10.0)) + 0
		var cx := x + cells * 5.0
		m.position = Vector3(cx, 0, (-30.0 if kit == "watercraft_pack" else 0.0) + (-20.0 if i % 2 == 0 and kit != "watercraft_pack" else 15.0))
		add_child(m)
		_label("%s\n%.1f x %.1f x %.1f m" % [path.get_file().get_basename(), b.size.x, b.size.y, b.size.z], m.position + Vector3(0, b.size.y + 4, 0))
		rows.append("%s;%s;%.1f;%.3f;%.3f;%.3f;%.3f;import" % [kit, path.get_file().get_basename(), L.faktor(kit), b.size.x, b.size.y, b.size.z, b.position.y])
		res[path.get_file().get_basename()] = b
		x += cells * 10.0 + 10.0
	# Laufzeitpfad (GLTFDocument) gegenpruefen: Datei ausserhalb res:// importfrei
	var rt := L.load_model("watercraft_pack", ProjectSettings.globalize_path("res://models/WatercraftPack/ship-cargo-a.glb"))
	var rb := L.model_aabb(rt)
	rows.append("watercraft_pack;ship-cargo-a;%.1f;%.3f;%.3f;%.3f;%.3f;GLTFDocument" % [L.faktor("watercraft_pack"), rb.size.x, rb.size.y, rb.size.z, rb.position.y])
	rt.free()
	# MultiMesh: 400 Baeume (Rasterwald 20 x 20 Felder mit Versatz) - nur Praesenz, keine Perf-Aussage
	var tf: Array[Transform3D] = []
	var rng := RandomNumberGenerator.new(); rng.seed = 7
	for ix in 20:
		for iz in 5:
			tf.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(130 + ix * 6.0 + rng.randf() * 3.0, 0, -45 + iz * 8.0 + rng.randf() * 3.0)))
	var mmis := L.make_multimeshes("nature_kit", "res://models/NatureKit/tree_pineDefaultA.glb", tf)
	for mmi in mmis: add_child(mmi)
	print("multimesh_instanzen=", tf.size(), " meshes=", mmis.size())
	_label("MultiMesh: 100 x tree_pineDefaultA", Vector3(160, 22, -30))
	# Auswertung
	var f := FileAccess.open("res://probe_masse.csv", FileAccess.WRITE)
	for r in rows: f.store_line(r)
	f.close()
	for r in rows: print("ROW ", r)
	var cam := Camera3D.new(); cam.fov = 40; add_child(cam)
	await get_tree().process_frame
	cam.position = Vector3(120, 95, 150); cam.look_at(Vector3(120, 0, -5))
	for k in 4: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://shot_probe.png")
	cam.position = Vector3(60, 25, 70); cam.look_at(Vector3(60, 6, 0))
	for k in 4: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://shot_nah.png")
	print("shots fertig")
	get_tree().quit()

func _line(a: Vector3, b: Vector3) -> void:
	var mi := MeshInstance3D.new(); var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES); im.surface_add_vertex(a); im.surface_add_vertex(b); im.surface_end()
	mi.mesh = im; var m := StandardMaterial3D.new(); m.albedo_color = Color(0.3, 0.3, 0.3); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mi.material_override = m; add_child(mi)

func _label(t: String, p: Vector3) -> void:
	var l := Label3D.new(); l.text = t; l.position = p; l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.pixel_size = 0.04; l.font_size = 48; l.outline_size = 12; l.modulate = Color(0.08, 0.08, 0.1); l.outline_modulate = Color(1, 1, 1); add_child(l)
