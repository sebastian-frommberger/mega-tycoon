extends Node3D
## S7 Block B (Felix 2, Rendering): gebündelte statische Quader (Straßen-/Gleisfelder, Lager) als MultiMesh.
## Vorher war jedes Straßenfeld und jedes Lager-Teil ein eigener MeshInstance3D (je ein Draw Call; Bench mit
## 5.000 Lkw: 3.366 Straßenfelder = 3.366 Draw Calls). Jetzt: eine MultiMesh je (Material, Schatten, Kachel).
## Kacheln (CHUNK × CHUNK Felder) halten das Frustum-Culling in der Nahsicht. Einheitswürfel, Größe steckt in der
## Instanz-Basis (Skalierung); Material wird geteilt, Optik wie vorher (gleiche Farbe, gleiche Schattenwahl).
## Rein Darstellung: Sim, Netz (roads/rails), A* und Parität unberührt.

const CHUNK := 64

var _unit := BoxMesh.new()        # 1 × 1 × 1
var _batches := {}                # key -> {"mmi", "xf": Array[Transform3D], "ids": Array}
var _where := {}                  # id -> [key, index]


## Quader mit Weltmitte pos und Größe size eintragen. id muss eindeutig sein (z. B. ["r", Vector2i]).
func add_box(id, pos: Vector3, size: Vector3, mat: Material, shadow: bool) -> void:
	if _where.has(id):
		remove(id)
	var key := "%d|%d|%d|%d" % [mat.get_instance_id(), 1 if shadow else 0, floori(pos.x / CHUNK), floori(pos.z / CHUNK)]
	var bt: Dictionary = _batches.get(key, {})
	if bt.is_empty():
		bt = _new_batch(mat, shadow)
		_batches[key] = bt
	var xf := Transform3D(Basis.from_scale(size), pos)
	var xs: Array = bt["xf"]
	xs.append(xf)
	bt["ids"].append(id)
	_where[id] = [key, xs.size() - 1]
	var mm: MultiMesh = bt["mmi"].multimesh
	if xs.size() > mm.instance_count:
		mm.instance_count = maxi(16, xs.size() * 2)       # Wachsen setzt den Puffer zurück: alle neu schreiben
		for i in xs.size():
			mm.set_instance_transform(i, xs[i])
	else:
		mm.set_instance_transform(xs.size() - 1, xf)
	mm.visible_instance_count = xs.size()


func has(id) -> bool:
	return _where.has(id)


## Quader entfernen (letzte Instanz rückt auf den freien Platz).
func remove(id) -> void:
	if not _where.has(id):
		return
	var w: Array = _where[id]
	_where.erase(id)
	var bt: Dictionary = _batches[w[0]]
	var xs: Array = bt["xf"]
	var ids: Array = bt["ids"]
	var i: int = w[1]
	var last := xs.size() - 1
	var mm: MultiMesh = bt["mmi"].multimesh
	if i != last:
		xs[i] = xs[last]
		ids[i] = ids[last]
		_where[ids[i]] = [w[0], i]
		mm.set_instance_transform(i, xs[i])
	xs.pop_back()
	ids.pop_back()
	mm.visible_instance_count = xs.size()


## Geteiltes Standardmaterial je Farbe (wie building._add_box: nur albedo_color), damit gleiche Teile bündeln.
var _mats := {}

func mat_for(color: Color) -> StandardMaterial3D:
	var k := color.to_html()
	if not _mats.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		_mats[k] = m
	return _mats[k]


## Anzahl gebündelter Quader (Tests/Diagnose).
func count() -> int:
	return _where.size()


func batch_count() -> int:
	return _batches.size()


func _new_batch(mat: Material, shadow: bool) -> Dictionary:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _unit
	mm.instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	return {"mmi": mmi, "xf": [], "ids": []}
