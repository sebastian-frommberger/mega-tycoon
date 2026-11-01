extends RefCounted
## S-11: Kenney-Props (CC0) zur Laufzeit laden, ohne Editor-Import (wie ui_kit.gd bei den Icons): GLB über
## GLTFDocument lesen, erstes Mesh nehmen, Materialien auf Palette S-08 umlegen. Schlägt das Laden fehl
## (Export ohne *.glb im Filter), liefert tree_mesh() null und der Aufrufer fällt auf die Quader-Bäume zurück.
## Faktoren aus kenney_messung.md §2: Nature Kit ×8 m, 1 Feld = 10 m → ×0,8 Szene-Einheiten.
## Gemessene Dreiecke: tree_default 114, tree_pineDefaultA 230.

const NATURE_SCALE := 0.8
const TREE_DEFAULT := "res://props/kenney/tree_default.glb"
const TREE_PINE := "res://props/kenney/tree_pineDefaultA.glb"

static var _cache := {}


## Liefert ein ArrayMesh mit zwei Flächen (0 = Stamm, 1 = Krone), Krone nimmt die MultiMesh-Instanzfarbe.
static func tree_mesh(path: String, trunk: Color) -> ArrayMesh:
	if _cache.has(path):
		return _cache[path]
	var mesh: ArrayMesh = null
	var gd := GLTFDocument.new()
	var st := GLTFState.new()
	var abs_path := ProjectSettings.globalize_path(path)
	if gd.append_from_file(abs_path, st) == OK:
		var root := gd.generate_scene(st)
		if root != null:
			var mi := _first_mesh(root)
			if mi != null and mi.mesh is ArrayMesh and mi.mesh.get_surface_count() >= 2:
				mesh = (mi.mesh as ArrayMesh).duplicate()
				var m_trunk := StandardMaterial3D.new()
				m_trunk.albedo_color = trunk
				m_trunk.roughness = 1.0
				var m_crown := StandardMaterial3D.new()
				m_crown.vertex_color_use_as_albedo = true
				m_crown.roughness = 1.0
				# Kenney legt Krone und Stamm in unterschiedlicher Reihenfolge ab: nach Name der Materialien zuordnen.
				for i in mesh.get_surface_count():
					var n := String(mesh.surface_get_material(i).resource_name).to_lower() if mesh.surface_get_material(i) != null else ""
					var is_trunk := n.contains("wood") or n.contains("trunk") or n.contains("brown")
					mesh.surface_set_material(i, m_trunk if is_trunk else m_crown)
			root.free()
	_cache[path] = mesh
	return mesh


static func _first_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n
	for c in n.get_children():
		var r := _first_mesh(c)
		if r != null:
			return r
	return null
