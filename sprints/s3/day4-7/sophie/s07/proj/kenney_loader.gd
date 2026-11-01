class_name KenneyLoader
extends RefCounted
## Kenney-Import mit Faktor je Kit (S-07, Godot 4.7.2). Liest kenney_faktoren.json (Festkomma, keine Floats).
## 1 Feld = 10 m = 10 Godot-Einheiten. Fahrzeuge/Gleise sind bewusst nicht enthalten.
##
## Nutzung:
##   var l := KenneyLoader.new("res://kenney_faktoren.json")
##   var baum: Node3D = l.load_model("nature_kit", "res://models/NatureKit/tree_default.glb")   # skaliert, Basis y=0
##   var mms: Array = l.make_multimeshes("nature_kit", "res://models/NatureKit/tree_default.glb", transforms)

var kits: Dictionary = {}
var _cache: Dictionary = {}   # glb-Pfad -> PackedScene bzw. Node3D-Vorlage

func _init(json_path: String = "res://kenney_faktoren.json") -> void:
	var f := FileAccess.open(json_path, FileAccess.READ)
	if f == null:
		push_error("KenneyLoader: %s nicht lesbar" % json_path)
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY or int(data.get("schema_version", 0)) != 1:
		push_error("KenneyLoader: schema_version != 1")
		return
	kits = data["kits"]

## Faktor in Szenen-Metern je Modell-Einheit.
func faktor(kit: String) -> float:
	return float(int(kits[kit]["faktor_promille"])) / 1000.0

## Rohmodell laden: import (res://) wenn vorhanden, sonst zur Laufzeit per GLTFDocument.
func _load_raw(glb_path: String) -> Node3D:
	if ResourceLoader.exists(glb_path):
		var ps := load(glb_path) as PackedScene
		if ps != null:
			return ps.instantiate() as Node3D
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file(glb_path, state, 0, glb_path.get_base_dir())
	if err != OK:
		push_error("KenneyLoader: GLB nicht ladbar: %s (Fehler %d)" % [glb_path, err])
		return null
	return doc.generate_scene(state) as Node3D

## Liefert Wurzel-Node3D "KenneyModell": Kind = Rohmodell, skaliert um Kit-Faktor, Pivot korrigiert
## (Basis auf y=0; XZ je nach Kit "mitte" oder "behalten"). Szene ist mit PackedScene.pack speicherbar.
func load_model(kit: String, glb_path: String) -> Node3D:
	if not kits.has(kit):
		push_error("KenneyLoader: unbekanntes Kit %s (Fahrzeuge/Gleise sind nicht enthalten)" % kit)
		return null
	var raw := _load_raw(glb_path)
	if raw == null:
		return null
	var k: Dictionary = kits[kit]
	var s := faktor(kit)
	var root := Node3D.new()
	root.name = "KenneyModell"
	root.add_child(raw)
	raw.scale = Vector3(s, s, s)
	var off := Vector3.ZERO
	off.y = float(int(k["pivot"]["y_korrektur_milli"])) / 1000.0 * s
	if k["pivot"]["xz"] == "mitte":
		var b := local_aabb(raw)
		off.x = -(b.position.x + b.size.x * 0.5) * s
		off.z = -(b.position.z + b.size.z * 0.5) * s
	raw.position = off
	root.set_meta("kenney_kit", kit)
	root.set_meta("kenney_faktor", s)
	return root

## AABB aller MeshInstance3D im Raumsystem von `n` im lokalen (unskalierten) Raum von n, ohne n.transform.
func local_aabb(n: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mi in _meshes(n):
		var a: AABB = _rel_xform(mi, n) * mi.get_aabb()
		box = a if first else box.merge(a)
		first = false
	return box

## AABB des fertigen Modells (Szenen-Meter) im Raumsystem der Wurzel.
func model_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mi in _meshes(root):
		var a: AABB = _rel_xform(mi, root) * mi.get_aabb()
		box = a if first else box.merge(a)
		first = false
	return box

## MultiMesh-tauglich: je MeshInstance3D des Modells ein MultiMeshInstance3D. Die Modelltransformation
## (Faktor, Pivot, Node-Offset) ist in jede Instanz eingebacken, `transforms` sind reine Platzierungen
## (Position/Y-Drehung, KEINE Skalierung noetig). Instanzfarben ueber use_colors moeglich.
func make_multimeshes(kit: String, glb_path: String, transforms: Array[Transform3D], use_colors: bool = false) -> Array[MultiMeshInstance3D]:
	var out: Array[MultiMeshInstance3D] = []
	var root := load_model(kit, glb_path)
	if root == null:
		return out
	for mi in _meshes(root):
		var mx := _rel_xform(mi, root)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = use_colors
		mm.mesh = mi.mesh
		mm.instance_count = transforms.size()
		for i in transforms.size():
			mm.set_instance_transform(i, transforms[i] * mx)
		var inst := MultiMeshInstance3D.new()
		inst.multimesh = mm
		out.append(inst)
	root.free()
	return out

func _meshes(n: Node) -> Array[MeshInstance3D]:
	var res: Array[MeshInstance3D] = []
	var st: Array[Node] = [n]
	while not st.is_empty():
		var c: Node = st.pop_back()
		for ch in c.get_children():
			st.append(ch)
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			res.append(c)
	return res

func _rel_xform(n: Node3D, ancestor: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var p: Node = n
	while p != null and p != ancestor:
		t = (p as Node3D).transform * t
		p = p.get_parent()
	return t
