extends Node3D
# Kenney-Proben nebeneinander, skaliert nach Massstabsregel 1 Feld = 10 m (Faktor je Kit, siehe kenney_messung.md).
# Referenz: Graubox-Lkw 10 x 2.5 x 3 m (1 Feld lang) und Feldraster 10 m.
const FAKTOR := {"truck":3.4,"truck-flat":3.4,"tractor":3.4,
	"train-locomotive-a":3.7,"train-diesel-a":3.7,"train-carriage-coal":3.7,"train-carriage-lumber":3.7,"train-carriage-tank":3.7,
	"railroad-straight":3.7,"railroad-corner-large":3.7,
	"building-a":10.0,"building-f":10.0,"chimney-large":10.0,"detail-tank":10.0,
	"tree_default":8.0,"tree_pineDefaultA":8.0,"rock_largeA":8.0,"ship-cargo-a":10.0}
const KIT := {"truck":"CarKit","truck-flat":"CarKit","tractor":"CarKit","train-locomotive-a":"TrainKit","train-diesel-a":"TrainKit","train-carriage-coal":"TrainKit","train-carriage-lumber":"TrainKit","train-carriage-tank":"TrainKit","railroad-straight":"TrainKit","railroad-corner-large":"TrainKit","building-a":"CityKitIndustrial","building-f":"CityKitIndustrial","chimney-large":"CityKitIndustrial","detail-tank":"CityKitIndustrial","tree_default":"NatureKit","tree_pineDefaultA":"NatureKit","rock_largeA":"NatureKit","ship-cargo-a":"WatercraftPack"}
var order := ["truck","truck-flat","tractor","train-locomotive-a","train-diesel-a","train-carriage-coal","train-carriage-lumber","train-carriage-tank","railroad-straight","railroad-corner-large","building-a","building-f","chimney-large","detail-tank","tree_default","tree_pineDefaultA","rock_largeA","ship-cargo-a"]

func _ready() -> void:
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); sun.shadow_enabled = true; add_child(sun)
	var env := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.72,0.76,0.70); e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.6,0.6,0.6); env.environment = e; add_child(env)
	# Boden mit 10-m-Raster
	var ground := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(400, 120); ground.mesh = pm
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.56,0.60,0.49); ground.material_override = gm; add_child(ground)
	for i in range(-20, 21):
		_line(Vector3(i*10, 0.02, -60), Vector3(i*10, 0.02, 60))
	for j in range(-6, 7):
		_line(Vector3(-200, 0.02, j*10), Vector3(200, 0.02, j*10))
	# Referenz-Graubox Lkw 10 x 2.5 x 3 m
	var ref := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(2.5, 3.0, 10.0); ref.mesh = bm
	var rm := StandardMaterial3D.new(); rm.albedo_color = Color(0.5,0.5,0.5); ref.material_override = rm
	ref.position = Vector3(-190, 1.5, 0); add_child(ref)
	_label("Graubox Lkw 10 m", Vector3(-190, 5, 0))
	var x := -170.0
	var log := []
	for name in order:
		var scene = load("res://models/%s/%s.glb" % [KIT[name], name])
		if scene == null:
			push_error("fehlt: " + name); continue
		var inst: Node3D = scene.instantiate()
		var f: float = FAKTOR.get(name, 1.0)
		inst.scale = Vector3(f, f, f)
		var aabb := _aabb(inst)
		var w := aabb.size.x * f
		x += w * 0.5 + 4.0
		inst.position = Vector3(x - aabb.get_center().x * f, -aabb.position.y * f, -aabb.get_center().z * f)
		add_child(inst)
		_label("%s x%.1f\n%.1f x %.1f x %.1f m" % [name, f, aabb.size.x*f, aabb.size.y*f, aabb.size.z*f], Vector3(x, aabb.size.y * f + 3.0, 0))
		log.append("%s;%.1f;%.2f;%.2f;%.2f" % [name, f, aabb.size.x*f, aabb.size.y*f, aabb.size.z*f])
		x += w * 0.5 + 4.0
	var fl := FileAccess.open("res://probeszene_masse_godot.csv", FileAccess.WRITE)
	fl.store_line("modell;faktor;x_m;y_m;z_m (Godot-AABB nach Skalierung)")
	for l in log: fl.store_line(l)
	fl.close()
	var cam := Camera3D.new(); cam.fov = 40; add_child(cam)
	var shots := [["uebersicht", Vector3(0, 110, 230), Vector3(0, 0, 0)], ["fahrzeuge", Vector3(-120, 25, 60), Vector3(-120, 2, 0)], ["gebaeude", Vector3(60, 40, 90), Vector3(60, 5, 0)]]
	await get_tree().process_frame
	for s in shots:
		cam.position = s[1]; cam.look_at(s[2])
		await get_tree().process_frame; await get_tree().process_frame; await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://shot_%s.png" % s[0])
		print("shot ", s[0])
	get_tree().quit()

func _line(a: Vector3, b: Vector3) -> void:
	var mi := MeshInstance3D.new(); var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES); im.surface_add_vertex(a); im.surface_add_vertex(b); im.surface_end()
	mi.mesh = im; var m := StandardMaterial3D.new(); m.albedo_color = Color(0.3,0.3,0.3); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mi.material_override = m; add_child(mi)

func _label(t: String, p: Vector3) -> void:
	var l := Label3D.new(); l.text = t; l.position = p; l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.pixel_size = 0.03; l.font_size = 48; l.outline_size = 12; l.modulate = Color(0.08,0.08,0.1); l.outline_modulate = Color(1,1,1); add_child(l)

func _aabb(n: Node) -> AABB:
	var box := AABB(); var first := true
	for c in _all(n):
		if c is MeshInstance3D:
			var a: AABB = (c as MeshInstance3D).get_aabb()
			var t: Transform3D = (c as Node3D).transform
			var p: Node = c.get_parent()
			while p != null and p != n:
				t = (p as Node3D).transform * t; p = p.get_parent()
			a = t * a
			box = a if first else box.merge(a); first = false
	return box

func _all(n: Node) -> Array:
	var r := [n]
	for c in n.get_children(): r += _all(c)
	return r
