extends Node3D
## W-04 (S7, Mira): Straßen und Gleise als schmale Kenney-Kacheln mit Autotile – nur bei --welt=s7.
## Daten: world/art/road_tiles.json (Sophie, S7 Block A). Modelle: props/kenney_city/roads|rail (CC0).
## Der Slice instanziiert diese Datei nie; dort bleiben die Quader aus main.build_track (bitgleich).
##
## Regel je Straßenfeld (Sophie): Maske N=1, E=2, S=4, W=8 aus den Nachbarn (eigene Straßen + Stadtstraßen + Anschluss
## an ein Gebäude, das der Bau-Pfad betreten hat). Maske 5/10: eine gestreckte Gerade (Feld + 0,1 m). Sonst Knotenkachel
## Breite×Breite in Feldmitte (Ende, Kurve, T, Kreuzung, Punkt) + je offener Seite ein Arm bis zur Feldkante.
## So stoßen Nachbarfelder immer an der Feldkante mit gleicher Breite und Höhe aneinander (keine Lücke, kein Boxstoß).
## Wasserfeld mit Straße = Brückenkachel (Deck bündig mit der Fahrbahn). Klassen: Stadtstraße 12 m, Landstraße 9,75 m
## (Fahrbahn 7,5 m) für alles, was der Spieler baut.
## Gleise: Train Kit, Spur 1,435 m. Gerade/Arm = 1 Stück je halbes Feld, 90°-Kurve = corner-large auf Radius ½ Feld.
## Weichen/Kreuzungen fehlen im Kit (S8): T/Kreuzung zeigt die Arme übereinander.
## Draw Calls: Gleise/Brücken eine MultiMesh je Modell (kartenweit). Straßenkacheln (D-09, Felix S7 Block D):
##   - Detail je 800-m-Kachel (CHUNK_T Felder) und Modell, sichtbar bis DETAIL_END_M Kameraabstand zur Kachelmitte
##     (wie Sophies Häuser, LOD_M 1400 m). Aus der Übersicht (4,3 km) ist kein Detail mehr im Bild.
##   - Fern-Proxy (zugleich H4 "Millimeterpapier", Sophies Vorschlag): EIN kartenweites MultiMesh flacher Bänder
##     (2 Dreiecke je Stück), nur die Fahrbahn: PROXY_BREITE × Kachelbreite, ohne Gehwegkanten, dunkler Asphalt-Tint
##     (PROXY_DUNKEL). Je Feld: Gerade = ein Band über das Feld; Knoten = Mittelquadrat + je offener Seite ein Band bis
##     zur Feldkante (kein Loch, kein heller Punkt an Kreuzungen). 0,005 Einheiten über der Kachelunterkante, also unter
##     Fahrbahn (0,01) und Gehweg (0,02): in der Nähe deckt die Kachel es zu, kein Übergang. Häuser/Blockgrund tragen
##     aus der Ferne die Stadt, das Netz tritt zurück. Brücken bleiben Kachel (kartenweit, immer sichtbar).

const KenneyLoader := preload("res://props/kenney_loader.gd")
const BauS7 := preload("res://world/bau_s7.gd")
const JSON_PATH := "res://world/art/road_tiles.json"
const ROADS := "res://props/kenney_city/roads/"
const RAIL := "res://props/kenney_city/rail/"
const DIRS := [[1, Vector2i(0, -1)], [2, Vector2i(1, 0)], [4, Vector2i(0, 1)], [8, Vector2i(-1, 0)]]
const Y_BASE := 0.045             # Fahrbahn-Unterkante über der Ebene (Wasserquader enden bei 0,04)
const BRIDGE_DECK_NATIVE := 0.52  # Oberkante Brückenkachel in Kenney-Einheiten (road_tiles.json sonder.bruecke)
const RAIL_BRIDGE_M := 6.0        # Deckbreite unter einem Gleis
const CHUNK_T := 32               # Felder je Detail-Kachel (800 m), D-09
const DETAIL_END_M := 1000.0      # Detail bis zu diesem Kameraabstand zur Kachelmitte (H4: ab ~1 km nur Fern-Band, kein
                                  # Mischbild aus hellen Kacheln und Band im 1,5-km-Blick; Häuser wechseln bei 1,4 km)
const PROXY_Y := 0.005            # Proxy-Viereck über der Kachelunterkante (Kenney: Fahrbahn 0,01, Gehweg 0,02)
const PROXY_BREITE := 0.45        # Fern-Band: Anteil der Kachelbreite (Stadt 12 m -> 5,4 m, Landstraße 9,75 m -> 4,4 m)
const PROXY_DUNKEL := 0.3         # Fern-Tint: Palette stadt_strasse um diesen Anteil abgedunkelt
const CHUNKED := ["road-straight", "road-end", "road-bend", "road-intersection", "road-crossroad", "road-square"]

var m                              # main.gd
var cfg: Dictionary = {}           # road_tiles.json "strassen"
var gcfg: Dictionary = {}          # road_tiles.json "gleise"
var meshes := {}                   # Modellname -> Mesh
var mmis := {}                     # Modellname -> MultiMeshInstance3D (Gleise, Brücken) bzw. "cx,cy|Modell" (Straßen)
var proxy_mmi: MultiMeshInstance3D = null
var proxy_mat: StandardMaterial3D = null
var links_road := {}               # Feld -> Bits: Anschluss an ein Gebäudefeld (aus dem Bau-Pfad)
var links_rail := {}
var counts := {}                   # Modellname -> Instanzen (Tests, Perf)
var pieces := {}                   # "r|x,y" / "g|x,y" -> Array [[modell, Transform3D]] (Tests: Lücken/Stoß)
var dirty := true
var w_city := 12.0                 # Meter
var w_land := 9.75
var m_pro_feld := 25.0


func setup(main) -> void:
	m = main
	name = "RoadTiles"
	m_pro_feld = m.m_pro_feld
	var j = JSON.parse_string(FileAccess.get_file_as_string(JSON_PATH))
	if j is Dictionary:
		cfg = j.get("strassen", {})
		gcfg = j.get("gleise", {})
	if cfg.has("klassen"):
		w_city = float(cfg["klassen"]["stadtstrasse"]["breite_m"])
		w_land = float(cfg["klassen"]["landstrasse"]["breite_m"])
	for n in ["road-straight", "road-end", "road-bend", "road-intersection", "road-crossroad", "road-square", "road-bridge"]:
		meshes[n] = _load_mesh(ROADS + n + ".glb")
	for n in ["railroad-straight", "railroad-corner-large"]:
		meshes[n] = _load_mesh(RAIL + n + ".glb")
	m.add_child(self)


static func _load_mesh(path: String) -> Mesh:
	var root := KenneyLoader.load_root(path)
	if root == null:
		push_warning("RoadTiles: Modell fehlt %s" % path)
		return null
	var mi := KenneyLoader._first_mesh(root)
	var mesh: Mesh = mi.mesh if mi != null else null
	root.free()
	return mesh


## Bau-Pfad merken: Übergänge Netzfeld <-> Gebäudefeld werden zu Anschluss-Bits (Straße endet an der Farm, nicht davor).
func note_path(cells: Array, rail: bool) -> void:
	var links: Dictionary = links_rail if rail else links_road
	var net: Dictionary = m.rails if rail else m.roads
	for i in cells.size() - 1:
		var a: Vector2i = cells[i]
		var b: Vector2i = cells[i + 1]
		for pr in [[a, b], [b, a]]:
			var bb = m.cell_to_building.get(pr[1])
			if net.has(pr[0]) and bb != null and bb.kind != m.Building.Kind.CITY:
				links[pr[0]] = int(links.get(pr[0], 0)) | _bit(pr[1] - pr[0])
	dirty = true


func forget(c: Vector2i, rail: bool) -> void:
	(links_rail if rail else links_road).erase(c)
	dirty = true


static func _bit(d: Vector2i) -> int:
	for e in DIRS:
		if e[1] == d:
			return e[0]
	return 0


func road_mask(c: Vector2i) -> int:
	var mask: int = int(links_road.get(c, 0))
	for e in DIRS:
		var n: Vector2i = c + e[1]
		if m.roads.has(n) or m.city_streets.has(n):
			mask |= e[0]
	return mask


func rail_mask(c: Vector2i) -> int:
	var mask: int = int(links_rail.get(c, 0))
	for e in DIRS:
		if m.rails.has(c + e[1]):
			mask |= e[0]
	return mask


## Fahrbahnhöhe (Szeneneinheiten) eines Feldes: Berg-Quader des Slice-Kartenformats + S7-Höhe (W-02, sonst 0).
func base_y(c: Vector2i) -> float:
	var lift := 0.0
	if m.terrain_at(c) == m.Terrain.MOUNTAIN:
		lift = m.mountain_h[m.idx(c)]
	return Y_BASE + lift + BauS7.hoehe_m(m, c) / m_pro_feld


## Neu aufbauen, wenn sich das Netz geändert hat (Bau, Abriss). Kosten: ~1.000 Felder < 5 ms.
func refresh() -> void:
	if not dirty:
		return
	dirty = false
	var acc := {"_proxy": []}
	for n in meshes:
		acc[n] = []
	pieces.clear()
	var done := {}
	for c in m.city_streets:
		done[c] = true
		_road_cell(c, w_city, acc)
	for c in m.roads:
		if not done.has(c):
			_road_cell(c, w_land, acc)
	for c in m.rails:
		_rail_cell(c, acc)
	var by_chunk := {}                 # "cx,cy|Modell" -> Array[Transform3D]
	var proxy_xf: Array = acc["_proxy"]
	for n in acc:
		if n == "_proxy":
			continue
		if not CHUNKED.has(n):
			_commit(n, acc[n])
			continue
		counts[n] = (acc[n] as Array).size()
		for xf: Transform3D in acc[n]:
			var k := "%d,%d|%s" % [floori(xf.origin.x / CHUNK_T), floori(xf.origin.z / CHUNK_T), n]
			if not by_chunk.has(k):
				by_chunk[k] = []
			by_chunk[k].append(xf)
	for k in mmis:
		if String(k).contains("|") and not by_chunk.has(k):
			_commit_chunk(k, [])
	for k in by_chunk:
		_commit_chunk(k, by_chunk[k])
	_commit_proxy(proxy_xf)


func _put(acc: Dictionary, key: String, model: String, xf: Transform3D) -> void:
	acc[model].append(xf)
	if not pieces.has(key):
		pieces[key] = []
	pieces[key].append([model, xf])


static func _xf(rot_deg: float, scale: Vector3, pos: Vector3) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, deg_to_rad(rot_deg)).scaled_local(scale), pos)


func _road_cell(c: Vector2i, w_m: float, acc: Dictionary) -> void:
	var key := "r|%d,%d" % [c.x, c.y]
	var mask := road_mask(c)
	var w := w_m / m_pro_feld
	var y := base_y(c)
	var ctr := Vector3(c.x + 0.5, y, c.y + 0.5)
	if m.terrain_at(c) == m.Terrain.WATER:
		var ew := (mask & 10) != 0 and (mask & 5) != 5
		var sb := w
		_put(acc, key, "road-bridge", _xf(90.0 if ew else 0.0, Vector3(w, sb, 1.004),
			Vector3(ctr.x, y + 0.02 - BRIDGE_DECK_NATIVE * sb, ctr.z)))
		return
	var pw := w * PROXY_BREITE
	if mask == 5 or mask == 10:
		_put(acc, key, "road-straight", _xf(90.0 if mask == 5 else 0.0, Vector3(1.004, 1.0, w), ctr))
		acc["_proxy"].append(_xf(90.0 if mask == 5 else 0.0, Vector3(1.004, 1.0, pw), ctr))
		return
	acc["_proxy"].append(_xf(0.0, Vector3(pw, 1.0, pw), ctr))
	for e in DIRS:
		if mask & e[0]:
			var pv: Vector2i = e[1]
			acc["_proxy"].append(_xf(0.0 if pv.y == 0 else 90.0, Vector3(0.502, 1.0, pw), ctr + Vector3(pv.x, 0, pv.y) * 0.25))
	var t: Dictionary = cfg["autotile"][str(mask)]
	_put(acc, key, String(t["modell"]).get_basename(), _xf(float(t["rot_y_grad"]), Vector3(w, 1.0, w), ctr))
	var arm := (1.0 - w) * 0.5
	for e in DIRS:
		if mask & e[0]:
			var v: Vector2i = e[1]
			var off := Vector3(v.x, 0, v.y) * (w * 0.5 + arm * 0.5)
			_put(acc, key, "road-straight", _xf(0.0 if v.y == 0 else 90.0, Vector3(arm + 0.002, 1.0, w), ctr + off))


## Gleis: Stück läuft nativ entlang +Z ab z=0 (4 Einheiten lang, 1 breit). Arm = Feldmitte bis Kante (½ Feld).
func _rail_cell(c: Vector2i, acc: Dictionary) -> void:
	var key := "g|%d,%d" % [c.x, c.y]
	var mask := rail_mask(c)
	var gs: float = float(gcfg.get("skala_uniform", 2.392)) / m_pro_feld      # 1 Kenney-Einheit = 2,39 m
	var y := base_y(c) + 0.024
	if m.terrain_at(c) == m.Terrain.WATER:
		var ew := (mask & 10) != 0 and (mask & 5) != 5
		var bw := RAIL_BRIDGE_M / m_pro_feld
		_put(acc, key, "road-bridge", _xf(90.0 if ew else 0.0, Vector3(bw, bw, 1.004),
			Vector3(c.x + 0.5, base_y(c) + 0.02 - BRIDGE_DECK_NATIVE * bw, c.y + 0.5)))
		if mask == 0:
			mask = 10 if ew else 5
	var ctr := Vector3(c.x + 0.5, y, c.y + 0.5)
	var corner := {9: 0.0, 12: 90.0, 6: 180.0, 3: 270.0}
	if corner.has(mask) and m.terrain_at(c) != m.Terrain.WATER:
		var rot: float = corner[mask]
		var basis := Basis(Vector3.UP, deg_to_rad(rot))
		_put(acc, key, "railroad-corner-large", Transform3D(basis.scaled_local(Vector3(0.125, gs, 0.125)), ctr + basis * Vector3(0, 0, -0.5)))
		return
	if mask == 0:
		mask = 10
	# Richtung -> Drehung, damit +Z vom Zentrum zur Kante zeigt: S 0°, E 90°, N 180°, W 270°
	var rot_for := {1: 180.0, 2: 90.0, 4: 0.0, 8: 270.0}
	for e in DIRS:
		if mask & e[0]:
			_put(acc, key, "railroad-straight", _xf(rot_for[e[0]], Vector3(gs, gs, 0.5 / 4.0 + 0.0005), ctr))


## Detail-Kachel (CHUNK_T² Felder) eines Straßenmodells; MultiMesh relativ zur Kachelmitte, damit Sichtweite und
## Frustum-Cull je Kachel greifen. Leere Kacheln bleiben als unsichtbarer Knoten stehen (Abriss).
func _commit_chunk(key: String, xfs: Array) -> void:
	var model := key.get_slice("|", 1)
	var mmi: MultiMeshInstance3D = mmis.get(key)
	if mmi == null:
		if xfs.is_empty() or meshes.get(model) == null:
			return
		var cx := int(key.get_slice("|", 0).get_slice(",", 0))
		var cz := int(key.get_slice("|", 0).get_slice(",", 1))
		mmi = MultiMeshInstance3D.new()
		mmi.name = "Tiles_%s_%d_%d" % [model, cx, cz]
		mmi.position = Vector3((cx + 0.5) * CHUNK_T, 0.0, (cz + 0.5) * CHUNK_T)
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = DETAIL_END_M / m_pro_feld
		add_child(mmi)
		mmis[key] = mmi
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = meshes[model]
	mm.instance_count = xfs.size()
	var o := mmi.position
	for i in xfs.size():
		var t: Transform3D = xfs[i]
		mm.set_instance_transform(i, Transform3D(t.basis, t.origin - o))
	mmi.multimesh = mm
	mmi.visible = xfs.size() > 0


## Fern-Proxy: schmale dunkle Fahrbahnbänder (Transforms aus _road_cell), kartenweit eine MultiMesh (1 Draw Call).
func _commit_proxy(xfs: Array) -> void:
	if proxy_mmi == null:
		if xfs.is_empty():
			return
		proxy_mat = StandardMaterial3D.new()
		proxy_mat.albedo_color = m._bg("stadt_strasse").darkened(PROXY_DUNKEL)
		proxy_mat.roughness = 1.0
		proxy_mmi = MultiMeshInstance3D.new()
		proxy_mmi.name = "Tiles_Fernproxy"
		proxy_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		proxy_mmi.material_override = proxy_mat
		add_child(proxy_mmi)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _proxy_quad()
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	proxy_mmi.multimesh = mm
	proxy_mmi.visible = xfs.size() > 0


static func _proxy_quad() -> ArrayMesh:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(-0.5, PROXY_Y, -0.5), Vector3(0.5, PROXY_Y, -0.5),
		Vector3(0.5, PROXY_Y, 0.5), Vector3(-0.5, PROXY_Y, 0.5)])
	arr[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
	arr[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return am


func _commit(model: String, xfs: Array) -> void:
	counts[model] = xfs.size()
	var mmi: MultiMeshInstance3D = mmis.get(model)
	if mmi == null:
		if xfs.is_empty() or meshes.get(model) == null:
			return
		mmi = MultiMeshInstance3D.new()
		mmi.name = "Tiles_" + model
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		mmis[model] = mmi
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = meshes[model]
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	mmi.multimesh = mm
	mmi.visible = xfs.size() > 0


## Felder, die eine Kachel tragen, für Tests: Maske und Kacheltyp.
func tile_info(c: Vector2i, rail := false) -> Dictionary:
	var mask := rail_mask(c) if rail else road_mask(c)
	var kind := "gerade" if mask == 5 or mask == 10 else String(cfg["autotile"][str(mask)]["kachel"])
	if m.terrain_at(c) == m.Terrain.WATER:
		kind = "bruecke"
	return {"mask": mask, "kachel": kind}


# ---------------------------------------------------------------- Bau-Vorschau (S7)

## Vorschau als schmales Band entlang des Pfads (Knoten + Arme zu Vor-/Nachfolger) statt ganzer Feldquader.
## Fehlstelle: rotes Feld in voller Breite unter dem Band, damit sie auch in der 700-m-Ansicht auffällt.
func preview(plan: Dictionary, root: Node3D, mats: Dictionary) -> void:
	var cells: Array = plan.get("cells", [])
	var items: Array = plan.get("items", [])
	var rail: bool = plan.get("rail", false)
	var gw := (6.0 if rail else w_land) / m_pro_feld + 0.08
	for i in items.size():
		var it: Dictionary = items[i]
		var c: Vector2i = it["cell"]
		if not m._in_grid(c):
			continue
		var bb = m.cell_to_building.get(c)
		if bb != null and bb.kind != m.Building.Kind.CITY and it["state"] != "bad":
			continue            # Anschluss im Gebäude: das Band endet an der Gebäudekante
		var mat: Material = mats["new"]
		match it["state"]:
			"bad":
				mat = mats["bad"]
			"exist":
				mat = mats["exist"]
		var y := base_y(c) + 0.06
		if bb != null and bb.kind != m.Building.Kind.CITY:
			y = minf(bb.height, 3.0) + 0.05
		var ctr := Vector3(c.x + 0.5, y, c.y + 0.5)
		if it["state"] == "bad":
			_box(root, Vector3(0.96, 0.03, 0.96), ctr - Vector3(0, 0.02, 0), mats["bad"], "Fehlstelle")
		_box(root, Vector3(gw + 0.08, 0.04, gw + 0.08), ctr - Vector3(0, 0.01, 0), mats["saum"], "")
		_box(root, Vector3(gw, 0.06, gw), ctr, mat, "")
		for k in [i - 1, i + 1]:
			if k < 0 or k >= cells.size():
				continue
			var d: Vector2i = cells[k] - c
			if absi(d.x) + absi(d.y) != 1:
				continue
			var off := Vector3(d.x, 0, d.y) * 0.25
			var size := Vector3(0.5 if d.x != 0 else gw, 0.06, 0.5 if d.y != 0 else gw)
			var saum := Vector3(size.x + (0.0 if d.x != 0 else 0.08), 0.04, size.z + (0.0 if d.y != 0 else 0.08))
			_box(root, saum, ctr + off - Vector3(0, 0.01, 0), mats["saum"], "")
			_box(root, size, ctr + off, mat, "")


static func _box(root: Node3D, size: Vector3, pos: Vector3, mat: Material, nm: String) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	if nm != "":
		mi.name = nm
	root.add_child(mi, nm != "")
