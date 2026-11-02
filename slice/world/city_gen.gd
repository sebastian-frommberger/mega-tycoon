extends Node3D
## W-03 (S7, Sophie): Städte im neuen Maßstab – nur bei --welt=s7. Der Slice ruft diese Datei nie auf (bitgleich).
##
## Je Stadt der Karte (Stufe aus den Daten, Radien/Ausfransung/Ausfallstraßen aus world/data/rules_s7.json, Lena):
##   - Straßenraster: Blöcke 3 × 3 Felder (75 m, Regel 72 m), Straßen auf den Blockkanten, Zentrum = Kreuzung.
##     Rand je Richtung ±25 % (rand_variation), Blöcke an den Hauptachsen bis 115 % (hauptachse_faktor).
##     Der Maßstab wird so geregelt, dass der effektive Flächenradius sqrt(Rasterfläche / π) den Zielradius trifft.
##     Alle Rasterstraßen und Ausfallstraßen landen in main.city_streets (Miras Kacheln + Stadtanschluss Z-01 greifen).
##   - Häuser je Zone (Kern/Mitte/Rand nach Abstand zum Zentrum, Dorf nur Rand) aus world/art/building_sets.json,
##     als Parzellen entlang der Blockkanten, Front zur Straße. Instancing: eine MultiMesh je (LOD-Kachel, Modell).
##   - Ausfransung: Ausfallstraßen (Richtung zu Nachbarstädten/Industrien) laufen +300–700 m über den Rand,
##     dort Einzelhäuser mit nach außen fallender Dichte.
##   - Bahnhof am Rand (Empfangsgebäude, Bahnsteig, zwei Deko-Gleise) auf der Seite ohne Ausfallstraße.
##   - Bäume in Baulücken und Gärten, mit Deckel (Anteil an den Stadt-Dreiecken ≤ TREE_SHARE_MAX).
##   - Fern-Proxy: je 800-m-Kachel ein Haus-Quader-MultiMesh ab PROXY_BEGIN_M Kameraabstand (Übersicht-Budget).
##     Das ist kein LOD-System (S8), nur ein Ein/Aus über visibility_range.
## Höhe: BauS7.hoehe_m (Schnittstelle s7_world.hoehe_at(cell, grid) von Felix, heute 0 = flach). Städte liegen auf
## Plateaus < 3 %, je Haus wird die Feldhöhe genommen.
## Nachfrage: unberührt. city_gen registriert die Stadt genau wie main._build_city (Einwohner + Stufe -> economy).

const KenneyLoader := preload("res://props/kenney_loader.gd")
const BauS7 := preload("res://world/bau_s7.gd")
const RULES_PATH := "res://world/data/rules_s7.json"
const SETS_PATH := "res://world/art/building_sets.json"
const ROOF_SHADER := preload("res://world/art/roof_palette.gdshader")
const RAIL_MODEL := "res://props/kenney_city/rail/railroad-straight.glb"
const TREE_MODELS := ["res://props/kenney_city/buildings/suburban/tree-large.glb", "res://props/kenney_city/buildings/suburban/tree-small.glb"]

const RASTER := 3                 # Felder je Block (Straßenmitte zu Straßenmitte) = 75 m
const STREET_HALF_M := 6.0        # Stadtstraße 12 m (road_tiles.json), halbe Breite inkl. Gehweg
const CHUNK := 16                 # Felder je LOD-Kachel (400 m)
const LOD_M := 1400.0             # Detail bis zu diesem Kameraabstand (zur Kachelmitte), dahinter Proxy
## Proxy-Kachel (800 m) beginnt früher als das Detail endet: Mittenabstand Detail-/Proxy-Kachel ≤ √2 · 200 m = 283 m,
## so entsteht nie ein Loch. Im Übergangsband stecken die leicht verkleinerten Proxys im Detailmodell.
const PROXY_BEGIN_M := LOD_M - 290.0
const PROXY_SHRINK := 0.9
const TREE_END_M := 1800.0        # Gartenbäume nur in der Nähe
const TREE_SHARE_MAX := 0.6       # Deckel: Bäume ≤ 60 % der Stadt-Dreiecke (W-03)
const TREES_PER_BUILDING_MAX := 1.2
const MERGE_P := 0.5               # Anteil zusammengelegter Randblöcke (6 × 3 Felder)
const MERGE_P_DORF := 0.8
const MERGE4_P_DORF := 0.55        # Dorf: 2 × 2 Blöcke
const PAL_N := {"kern": 6, "mitte_sub": 5, "mitte_com": 3, "rand": 7}
const EMPTY_MAX := 0.42           # Leerfläche je Block (Parzellen ohne Haus), Akzeptanz < 0,50
const GROUND_Y := 0.012            # Blockgrund über dem Gelände (Szene, 0,3 m)
const IND_MARGIN := 3             # Felder Abstand zu Industrie-Grundflächen
const DIRS4 := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]

## Parzellen je Zone: Rücksprung, Abstand, Belegung, maximale Haustiefe (m). Werte nach Railway-Empire-Referenz:
## Kern geschlossen, Mitte dicht mit Vorgärten, Rand locker mit Gärten, Dorf am lockersten.
const ZONE := {
	"kern": {"setback": 0.6, "gap": 0.5, "fill": 1.0, "dmax": 16.5, "garden": 0.0},
	"mitte": {"setback": 3.0, "gap": 5.0, "fill": 0.92, "dmax": 13.0, "garden": 0.6},
	"rand": {"setback": 4.5, "gap": 14.0, "fill": 0.85, "dmax": 10.5, "garden": 0.9},
	"dorf": {"setback": 5.5, "gap": 18.0, "fill": 0.8, "dmax": 10.5, "garden": 0.9},
}
const KIT_TINT := {"suburban": Vector3(0.88, 0.84, 0.78), "commercial": Vector3(0.86, 0.80, 0.72), "tree": Vector3(0.55, 0.75, 0.42), "rail": Vector3(0.62, 0.60, 0.57)}

var m                                  # main.gd
var mpf := 25.0                        # Meter je Feld
var rules: Dictionary = {}             # rules_s7.json "staedte"
var models := {}                       # Pfad -> {mesh, w, d, h, tris, zone, kit, min_stufe, weight}
var zone_models := {}                  # "kern"/"mitte"/"rand"/"mitte_sub" -> Array[Pfad]
var cities := {}                       # Stadt-ID -> Statistik (Tests, Notiz)
var _det := {}                         # "cx,cy|pfad" -> Array[Transform3D]
var _prox := {}                        # "cx,cy|g"/"cx,cy|f" -> Array[Transform3D]
var _tree := {}                        # "cx,cy|pfad" -> Array[Transform3D]
var _misc := {}                        # Bahnhof: pfad -> Array[Transform3D] (immer sichtbar)
var _mats := {}
var _tri_cache := {}
var industry_cells := {}               # Felder mit Industrie inkl. Rand (vor dem Industriebau aus der Karte gelesen)
var total := {"buildings": 0, "trees": 0, "tris_buildings": 0, "tris_trees": 0, "mmi_detail": 0, "mmi_proxy": 0}
var proxy_mesh_gable: ArrayMesh
var proxy_mesh_flat: ArrayMesh


func setup(main) -> void:
	m = main
	name = "CityGen"
	mpf = float(m.m_pro_feld)
	var j = JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH))
	rules = j.get("staedte", {}) if j is Dictionary else {}
	_load_models()
	for ind in m.map_data.get("industrien", []):
		if not ind.get("im_slice", true):
			continue
		var size: Vector2i = m.IND_SIZE.get(ind["typ"], Vector2i(3, 3))
		var c0 := Vector2i(int(ind["x_felder"]), int(ind["y_felder"])) - size / 2
		for x in range(-IND_MARGIN, size.x + IND_MARGIN):
			for y in range(-IND_MARGIN, size.y + IND_MARGIN):
				industry_cells[c0 + Vector2i(x, y)] = true
	proxy_mesh_gable = _proxy_mesh(true)
	proxy_mesh_flat = _proxy_mesh(false)
	m.add_child(self)


# ---------------------------------------------------------------- Modelle

func _load_models() -> void:
	var j = JSON.parse_string(FileAccess.get_file_as_string(SETS_PATH))
	if not (j is Dictionary):
		push_error("CityGen: building_sets.json fehlt")
		return
	for z in ["kern", "mitte", "rand", "mitte_sub"]:
		zone_models[z] = []
	for g in j["gebaeude"]:
		var path: String = g["modell"]
		var zone: String = g["zone"]
		if zone == "garten" or g["min_stufe"] == "grossstadt":
			continue
		var mesh := _mesh(path)
		if mesh == null:
			continue
		var ab := mesh.get_aabb()
		var s: float = float(g["skalierung"])
		var tris := _tris(mesh)
		models[path] = {"mesh": mesh, "w": ab.size.x * s, "d": ab.size.z * s, "h": ab.size.y * s, "s": s,
			"cz": (ab.position.z + ab.size.z * 0.5) * s, "cx": (ab.position.x + ab.size.x * 0.5) * s,
			"tris": tris, "zone": zone, "kit": g["kit"], "min_stufe": g["min_stufe"],
			"weight": clampf(pow(1400.0 / float(tris), 2.0), 0.15, 3.0)}      # schwere Modelle seltener (Perf), leichte öfter
		zone_models[zone].append(path)
		if zone == "mitte" and g["kit"] == "suburban":
			zone_models["mitte_sub"].append(path)
	for path in TREE_MODELS + [RAIL_MODEL]:
		var mesh := _mesh(path)
		if mesh != null:
			models[path] = {"mesh": mesh, "tris": _tris(mesh), "kit": "rail" if path == RAIL_MODEL else "tree"}


static func _mesh(path: String) -> Mesh:
	var root := KenneyLoader.load_root(path)
	if root == null:
		push_warning("CityGen: Modell fehlt %s" % path)
		return null
	var mi := KenneyLoader._first_mesh(root)
	var mesh: Mesh = mi.mesh if mi != null else null
	root.free()
	return mesh


func _tris(mesh: Mesh) -> int:
	if _tri_cache.has(mesh):
		return _tri_cache[mesh]
	var n := 0
	for s in mesh.get_surface_count():
		var a := mesh.surface_get_arrays(s)
		var ix = a[Mesh.ARRAY_INDEX]
		n += (ix.size() if ix != null else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	_tri_cache[mesh] = n
	return n


func _kit_mat(path: String) -> Material:
	var info: Dictionary = models[path]
	var kit: String = info["kit"]
	if _mats.has(kit):
		return _mats[kit]
	var src := (info["mesh"] as Mesh).surface_get_material(0)
	if not (src is StandardMaterial3D) or (src as StandardMaterial3D).albedo_texture == null:
		return null
	var sm := ShaderMaterial.new()
	sm.shader = ROOF_SHADER
	sm.set_shader_parameter("tex", (src as StandardMaterial3D).albedo_texture)
	sm.set_shader_parameter("tint", KIT_TINT.get(kit, Vector3.ONE))
	sm.set_shader_parameter("remap", 1.0 if kit == "suburban" or kit == "commercial" else 0.0)
	var pal = m.palette.get("hintergruende", {}).get("stadt_haus_ziegel", {}).get("rgb", null)
	if pal != null:
		sm.set_shader_parameter("roof", Color8(int(pal[0]), int(pal[1]), int(pal[2])))
	_mats[kit] = sm
	return sm


## Fern-Proxy: Einheitshaus (Grundfläche ±0,5, Traufe 0,62, First 1,0) mit Satteldach bzw. Flachdach, Farben als
## Vertexfarbe (Putz / Ziegel aus der Palette). 14 bzw. 10 Dreiecke.
func _proxy_mesh(gable: bool) -> ArrayMesh:
	var wall := _pal("stadt_haus_hell", Color(0.82, 0.78, 0.70))
	var roof := _pal("stadt_haus_ziegel", Color(0.70, 0.45, 0.38))
	if not gable:
		roof = Color(0.55, 0.53, 0.52)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var e := 0.62 if gable else 1.0
	var c := [Vector3(-0.5, 0, -0.5), Vector3(0.5, 0, -0.5), Vector3(0.5, 0, 0.5), Vector3(-0.5, 0, 0.5)]
	for i in 4:
		var a: Vector3 = c[i]
		var b: Vector3 = c[(i + 1) % 4]
		_quad(st, a, b, b + Vector3(0, e, 0), a + Vector3(0, e, 0), wall)
	if gable:
		var r0 := Vector3(-0.5, 1.0, 0.0)
		var r1 := Vector3(0.5, 1.0, 0.0)
		_quad(st, Vector3(-0.5, e, 0.5), Vector3(0.5, e, 0.5), r1, r0, roof)
		_quad(st, Vector3(0.5, e, -0.5), Vector3(-0.5, e, -0.5), r0, r1, roof)
		_tri(st, Vector3(-0.5, e, -0.5), Vector3(-0.5, e, 0.5), r0, wall)
		_tri(st, Vector3(0.5, e, 0.5), Vector3(0.5, e, -0.5), r1, wall)
	else:
		_quad(st, Vector3(-0.5, e, 0.5), Vector3(0.5, e, 0.5), Vector3(0.5, e, -0.5), Vector3(-0.5, e, -0.5), roof)
	st.generate_normals()
	var mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mesh.surface_set_material(0, mat)
	return mesh


func _pal(key: String, fb: Color) -> Color:
	var p = m.palette.get("hintergruende", {}).get(key, {}).get("rgb", null)
	return Color8(int(p[0]), int(p[1]), int(p[2])) if p != null else fb


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	_tri(st, a, b, c, col)
	_tri(st, a, c, d, col)


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	# Gegen den Uhrzeigersinn von außen gesehen = Godot-Vorderseite im Uhrzeigersinn: Reihenfolge a, c, b
	for v in [a, c, b]:
		st.set_color(col)
		st.add_vertex(v)


# ---------------------------------------------------------------- Stadt bauen

var _ok_cache := {}

func _cell_ok(c: Vector2i) -> bool:
	var v = _ok_cache.get(c)
	if v == null:
		v = m._in_grid(c) and m.terrain_at(c) == m.Terrain.PLAIN and not industry_cells.has(c) and not m.cell_to_building.has(c)
		_ok_cache[c] = v
	return v


func hoehe(c: Vector2i) -> float:
	return BauS7.hoehe_m(m, c) / mpf


## Baut eine Stadt der S7-Welt und registriert sie wie main._build_city (Gebäude, Ökonomie-Knoten, A*).
func build_city(st: Dictionary) -> void:
	_ok_cache.clear()                 # andere Städte sind inzwischen registriert
	var stufe: String = st["stufe"]
	var rs: Dictionary = rules.get("stufen", {}).get(stufe, rules.get("stufen", {}).get("kleinstadt", {}))
	var center := Vector2i(int(st["x_felder"]), int(st["y_felder"]))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(st["id"]) + "|w03")
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.9
	var r_target: float = float(rs["zielradius"]["felder"])
	var var_pm: float = float(rules.get("rand_variation_promille", 250)) / 1000.0
	var axis_f: float = float(rules.get("hauptachse_faktor_promille", 1150)) / 1000.0
	# 1) Raster: Maßstab s so regeln, dass der effektive Flächenradius den Zielradius trifft
	var lo := 0.75
	var hi := 1.5
	var blocks := {}
	for it in 9:
		var s := (lo + hi) * 0.5
		blocks = _mask(center, r_target * s, var_pm, axis_f, noise)
		var r_eff := sqrt(float(_raster_cells(blocks).size()) / PI)
		if r_eff < r_target:
			lo = s
		else:
			hi = s
	blocks = _mask(center, r_target * hi, var_pm, axis_f, noise)
	var raster := _raster_cells(blocks)
	var r_eff := sqrt(float(raster.size()) / PI)
	var cells := {}
	var streets := {}
	for c in raster:
		cells[c] = true
		var rel: Vector2i = c - center
		if posmod(rel.x, RASTER) == 0 or posmod(rel.y, RASTER) == 0:
			streets[c] = true
	# 2) Ausfallstraßen + Ausfransung
	var n_out := rng.randi_range(int(rs["ausfallstrassen"]["min"]), int(rs["ausfallstrassen"]["max"]))
	var dirs := _out_dirs(center, n_out, rng)
	var fr_min: float = float(rs["ausfransung"]["felder_min"])
	var fr_max: float = float(rs["ausfransung"]["felder_max"])
	var fringe_houses: Array = []           # [Zelle Haus, Richtung zur Straße]
	var out_len := {}
	for d in dirs:
		var target_len := rng.randf_range(fr_min + 1.0, fr_max - 1.0)
		var k := 1
		var last_inside := 0
		var walked := 0.0
		while k < 200:
			var c: Vector2i = center + d * k
			if cells.has(c):
				last_inside = k
				k += 1
				continue
			var dist := float(k)
			if dist > r_eff + target_len or not _cell_ok(c):
				break
			# Seitenfelder dürfen die Straße nicht an eine fremde Stadt/Industrie kleben
			streets[c] = true
			cells[c] = true
			walked = dist - r_eff
			var t := clampf((dist - float(last_inside)) / maxf(1.0, r_eff + target_len - float(last_inside)), 0.0, 1.0)
			var p := lerpf(0.95, 0.35, t)
			var perp := Vector2i(d.y, d.x)
			for side in [1, -1]:
				var sc: Vector2i = c + perp * side
				if rng.randf() < p and _cell_ok(sc) and not cells.has(sc):
					cells[sc] = true
					fringe_houses.append([sc, -perp * side])
					var sc2: Vector2i = sc + perp * side
					if t < 0.5 and rng.randf() < 0.3 and _cell_ok(sc2) and not cells.has(sc2):
						cells[sc2] = true
						fringe_houses.append([sc2, -perp * side])
			k += 1
		out_len[d] = walked
	# 3) Bahnhof am Rand (Seite ohne Ausfallstraße)
	var station := _place_station(center, cells, raster, dirs)
	# 4) Bebauung mit Stadt-Palette (je Stadt eine Auswahl Modelle: eigener Charakter, weniger Draw Calls)
	var pal := _city_palette(stufe, rng)
	var info := {"id": st["id"], "name": st["name"], "stufe": stufe, "center": center, "r_target": r_target, "r_eff": r_eff,
		"r_eff_m": r_eff * mpf, "blocks": [], "zones": {"kern": 0, "mitte": 0, "rand": 0}, "buildings": 0, "trees": 0,
		"tris_buildings": 0, "tris_trees": 0, "fringe_m": 0.0, "out_dirs": dirs.size(), "out_len_m": [], "station": station,
		"streets": 0, "cells": cells.size(), "houses": [], "palette": pal}
	for d in dirs:
		info["out_len_m"].append(out_len[d] * mpf)
	var allowed: Array = rs.get("gebaeudetypen", ["kern", "mitte", "rand"])
	var zone_of := {}
	for o in blocks.keys():
		var bc := Vector2(o.x + 2.0, o.y + 2.0)
		var dn := bc.distance_to(Vector2(center) + Vector2(0.5, 0.5)) / r_eff
		var zone := "rand"
		if allowed.has("kern") and dn < 0.33:
			zone = "kern"
		elif allowed.has("mitte") and dn < 0.72:
			zone = "mitte"
		if stufe == "dorf":
			zone = "dorf"
		zone_of[o] = zone
	# Am Rand größere Blöcke (wie Railway Empire): zwei Randblöcke zu 6 × 3 Feldern zusammenlegen, die Straße dazwischen
	# entfällt. Nie über die Hauptachsen (Ausfallstraßen, Bahnhofszufahrt). Weniger Straßenkacheln, lockerer Rand.
	var merged := {}
	var keys: Array = blocks.keys()
	keys.sort()
	info["merged"] = 0
	for o in keys:
		if merged.has(o):
			continue
		var zone: String = zone_of[o]
		var nx := 1
		var ny := 1
		var ox: Vector2i = o + Vector2i(RASTER, 0)
		var oy: Vector2i = o + Vector2i(0, RASTER)
		var oxy: Vector2i = o + Vector2i(RASTER, RASTER)
		var free := func(b: Vector2i) -> bool:
			return blocks.has(b) and not merged.has(b) and zone_of[b] == zone
		var lx_ok: bool = ox.x - center.x != 0
		var ly_ok: bool = oy.y - center.y != 0
		if zone == "dorf" and rng.randf() < MERGE4_P_DORF and lx_ok and ly_ok and free.call(ox) and free.call(oy) and free.call(oxy):
			# Dorf: 2 × 2 Blöcke (138 m) mit Hofstellen am Rand, Mitte Garten/Obstwiese
			for i in range(1, 2 * RASTER):
				streets.erase(o + Vector2i(RASTER, i))
				streets.erase(o + Vector2i(i, RASTER))
			merged[ox] = true
			merged[oy] = true
			merged[oxy] = true
			nx = 2
			ny = 2
			info["merged"] += 3
		elif (zone == "rand" or zone == "dorf") and rng.randf() < (MERGE_P_DORF if zone == "dorf" else MERGE_P):
			var try_x := rng.randf() < 0.5
			for attempt in 2:
				var along_x := try_x if attempt == 0 else not try_x
				var on: Vector2i = ox if along_x else oy
				if not (lx_ok if along_x else ly_ok) or not free.call(on):
					continue
				for i in range(1, RASTER):
					streets.erase(on + (Vector2i(0, i) if along_x else Vector2i(i, 0)))
				merged[on] = true
				if along_x:
					nx = 2
				else:
					ny = 2
				info["merged"] += 1
				break
		merged[o] = true
		_fill_block(o, nx, ny, zone, stufe, rng, info, pal)
	for fh in fringe_houses:
		_fringe_house(fh[0], fh[1], rng, info, center)
	info["streets"] = streets.size()
	_tree_cap(info)
	# 5) Registrieren (wie main._build_city): Felder, Straßen, Ökonomie
	for c in streets:
		m.city_streets[c] = true
	var cell_list: Array = cells.keys()
	var r_i := int(round(r_eff))
	var b = m.Building.new()
	b.custom_cells = cell_list
	m.add_child(b)
	b.map_id = st["id"]
	b.typ = "stadt"
	b.city_stage = stufe
	var pop: int = int(st["einwohner_anzahl"])
	b.city_pop = pop
	b.setup(m.Building.Kind.CITY, st["name"], center - Vector2i(r_i, r_i), Vector2i(2 * r_i + 1, 2 * r_i + 1), Color.WHITE, 1.6)
	m.eco.c_index[b.map_id] = {"id": b.map_id, "stage_id": b.city_stage, "einwohner_anzahl": pop}
	m._new_site_node(b)
	b.site = m.eco.add_city_site(b.node_id, b.map_id)
	b.station = m.eco.s_station[b.site]
	m._register(b)
	for c in cell_list:
		if streets.has(c):
			m.astar_road.set_point_solid(c, false)
			m.astar_rail.set_point_solid(c, false)
	info["cells"] = cell_list.size()
	cities[st["id"]] = info


## Blöcke (Ursprung = linke obere Straßenkreuzung) innerhalb des Randes r(θ). Ein Block zählt nur, wenn alle 16 Felder
## (4 innen + 12 Straße) frei und eben sind (kein Wasser, kein Berg, keine Industrie, keine andere Stadt).
func _mask(center: Vector2i, r: float, var_pm: float, axis_f: float, noise: FastNoiseLite) -> Dictionary:
	var out := {}
	var kmax := int(ceil(r * (1.0 + var_pm) * axis_f / RASTER)) + 1
	var cf := Vector2(center) + Vector2(0.5, 0.5)
	for bj in range(-kmax, kmax):
		for bi in range(-kmax, kmax):
			var o := center + Vector2i(bi * RASTER, bj * RASTER)
			var bc := Vector2(o.x + 2.0, o.y + 2.0)
			var v := bc - cf
			var th := v.angle()
			var rr := r * (1.0 + var_pm * noise.get_noise_2d(cos(th) * 1.3, sin(th) * 1.3) * 1.6)
			var on_axis := bi == 0 or bi == -1 or bj == 0 or bj == -1
			var lim := maxf(rr, r * axis_f) if on_axis else rr
			if v.length() > lim:
				continue
			var ok := true
			for y in RASTER + 1:
				for x in RASTER + 1:
					if not _cell_ok(o + Vector2i(x, y)):
						ok = false
						break
				if not ok:
					break
			if ok:
				out[o] = true
	# lose Einzelblöcke ohne Nachbarblock weg (Inseln hinter Wasser/Industrie)
	var keep := {}
	for o in out:
		for dv in DIRS4:
			if out.has(o + dv * RASTER):
				keep[o] = true
				break
	return keep


func _raster_cells(blocks: Dictionary) -> Dictionary:
	var s := {}
	for o in blocks:
		for y in RASTER + 1:
			for x in RASTER + 1:
				s[o + Vector2i(x, y)] = true
	return s


## Richtungen der Ausfallstraßen: zu den nächsten Nachbarstädten und Industrien (Gewicht 1/Abstand), Rest zufällig.
func _out_dirs(center: Vector2i, n: int, rng: RandomNumberGenerator) -> Array:
	var score := {}
	for d in DIRS4:
		score[d] = rng.randf() * 0.001
	var targets: Array = []
	for st in m.map_data["staedte"]:
		targets.append(Vector2i(int(st["x_felder"]), int(st["y_felder"])))
	for ind in m.map_data["industrien"]:
		targets.append(Vector2i(int(ind["x_felder"]), int(ind["y_felder"])))
	for t in targets:
		var v := Vector2(t - center)
		if v.length() < 1.0:
			continue
		var best: Vector2i = DIRS4[0]
		for d in DIRS4:
			if Vector2(d).dot(v) > Vector2(best).dot(v):
				best = d
		score[best] += 1.0 / v.length()
	var ds: Array = DIRS4.duplicate()
	ds.sort_custom(func(a, b): return score[a] > score[b])
	return ds.slice(0, clampi(n, 1, 4))


# ---------------------------------------------------------------- Block füllen

## Block-Innenfläche (zwischen den Straßenkanten) in Szeneneinheiten: Ursprung + Kantenlänge.
func _block_rect(o: Vector2i, nx := 1, ny := 1) -> Rect2:
	var hw := STREET_HALF_M / mpf
	return Rect2(Vector2(o.x + 0.5 + hw, o.y + 0.5 + hw), Vector2(RASTER * nx - 2.0 * hw, RASTER * ny - 2.0 * hw))


func _pick(list: Array, stufe: String, rng: RandomNumberGenerator, dmax: float) -> String:
	var tot := 0.0
	var cand: Array = []
	for p in list:
		var info: Dictionary = models[p]
		if stufe == "dorf" and info["min_stufe"] != "dorf":
			continue
		if info["d"] > dmax:
			continue
		cand.append(p)
		tot += info["weight"]
	if cand.is_empty():
		return ""
	var x := rng.randf() * tot
	for p in cand:
		x -= models[p]["weight"]
		if x <= 0.0:
			return p
	return cand[-1]


## Je Stadt eine Teilmenge je Zone (leichte Modelle bevorzugt): Kern 6, Mitte 5 Wohn + 3 Geschäft, Rand 7.
func _city_palette(stufe: String, rng: RandomNumberGenerator) -> Dictionary:
	var want := {"kern": PAL_N["kern"], "mitte_sub": PAL_N["mitte_sub"], "mitte_com": PAL_N["mitte_com"], "rand": PAL_N["rand"]}
	var src := {"kern": zone_models["kern"], "mitte_sub": zone_models["mitte_sub"], "rand": zone_models["rand"], "mitte_com": []}
	for p in zone_models["mitte"]:
		if models[p]["kit"] == "commercial":
			src["mitte_com"].append(p)
	var out := {}
	for z in want:
		var pool: Array = []
		for p in src[z]:
			if stufe == "dorf" and models[p]["min_stufe"] != "dorf":
				continue
			pool.append(p)
		var sel: Array = []
		while sel.size() < want[z] and not pool.is_empty():
			var tot := 0.0
			for p in pool:
				tot += sqrt(models[p]["weight"])
			var x := rng.randf() * tot
			var pick: String = pool[-1]
			for p in pool:
				x -= sqrt(models[p]["weight"])
				if x <= 0.0:
					pick = p
					break
			sel.append(pick)
			pool.erase(pick)
		out[z] = sel
	return out


func _zone_list(zone: String, stufe: String, rng: RandomNumberGenerator, pal: Dictionary) -> Array:
	match zone:
		"kern":
			return pal["kern"]
		"mitte":
			return pal["mitte_com"] if stufe != "dorf" and not pal["mitte_com"].is_empty() and rng.randf() < 0.3 else pal["mitte_sub"]
		_:
			return pal["rand"]


## Parzellen entlang der vier Blockkanten. Nord/Süd über die ganze Länge, West/Ost zwischen deren Tiefen.
## Jede Parzelle ist [Seite, t0, t1, belegt]; leere Parzellen (Baulücken) bekommen Bäume.
func _fill_block(o: Vector2i, nx: int, ny: int, zone: String, stufe: String, rng: RandomNumberGenerator, info: Dictionary, pal: Dictionary) -> void:
	var zp: Dictionary = ZONE[zone]
	var rect := _block_rect(o, nx, ny)
	var Lx := rect.size.x * mpf                     # m
	var Ly := rect.size.y * mpf
	var inset: float = zp["setback"] + zp["dmax"]
	var lots: Array = []
	var foot := 0.0
	# Seiten: [Name, Ursprung (m, lokal), Laufrichtung, nach innen, t0, t1, Tiefe bis Blockmitte]
	var sides := [["N", Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), 0.0, Lx, Ly * 0.5],
		["S", Vector2(Lx, Ly), Vector2(-1, 0), Vector2(0, -1), 0.0, Lx, Ly * 0.5],
		["W", Vector2(0, Ly), Vector2(0, -1), Vector2(1, 0), inset, Ly - inset, Lx * 0.5],
		["E", Vector2(Lx, 0), Vector2(0, 1), Vector2(-1, 0), inset, Ly - inset, Lx * 0.5]]
	for sd in sides:
		var t: float = sd[4] + rng.randf_range(0.0, 1.5)
		var t_end: float = sd[5]
		while t < t_end - 6.0:
			var path := _pick(_zone_list(zone, stufe, rng, pal), stufe, rng, zp["dmax"])
			if path == "":
				break
			var mi: Dictionary = models[path]
			var w: float = mi["w"]
			var gap: float = zp["gap"] * rng.randf_range(0.6, 1.4)
			if t + w > t_end:
				# kleineres Modell versuchen, sonst Rest der letzten Parzelle zuschlagen
				var alt := ""
				for p in _zone_list(zone, stufe, rng, pal):
					if models[p]["w"] <= t_end - t and models[p]["d"] <= zp["dmax"] and (stufe != "dorf" or models[p]["min_stufe"] == "dorf"):
						alt = p
						break
				if alt == "":
					break
				path = alt
				mi = models[path]
				w = mi["w"]
			var t1 := minf(t + w + gap, t_end)
			var occ: bool = rng.randf() < zp["fill"]
			lots.append([sd[0], t, t1, occ, path, t, sd])
			t = t1
		# Kante lückenlos beparzellieren: erste Parzelle ab Seitenanfang, letzte bis Seitenende
		if not lots.is_empty() and lots[-1][0] == sd[0]:
			lots[-1][2] = t_end
			var fi := lots.size() - 1
			while fi > 0 and lots[fi - 1][0] == sd[0]:
				fi -= 1
			lots[fi][1] = sd[4]
	# Deckel Leerfläche: Baulücken schließen, bis der Block unter EMPTY_MAX liegt (W-03: < 50 %)
	var empty := leerflaeche(lots, Lx, Ly, inset)
	var guard := 0
	while empty > EMPTY_MAX and guard < 64:
		guard += 1
		var free: Array = []
		for i in lots.size():
			if not lots[i][3]:
				free.append(i)
		if free.is_empty():
			break
		lots[free[rng.randi() % free.size()]][3] = true
		empty = leerflaeche(lots, Lx, Ly, inset)
	# Häuser auf belegte Parzellen, Bäume in Baulücken und Gärten
	for l in lots:
		var sd: Array = l[6]
		var u: Vector2 = sd[2]
		var inw: Vector2 = sd[3]
		var t0: float = l[5]
		var t1: float = l[2]
		if l[3]:
			var path: String = l[4]
			var mi: Dictionary = models[path]
			var w: float = mi["w"]
			var lp: Vector2 = sd[1] + u * (t0 + w * 0.5) + inw * (zp["setback"] + mi["d"] * 0.5)
			_house(path, rect.position + lp / mpf, -inw, info)
			foot += w * mi["d"]
			if rng.randf() < zp["garden"]:
				var gx := rng.randf_range(t0 + w + 1.5, maxf(t0 + w + 2.0, t1 - 1.5)) if t1 - t0 - w > 4.0 else t0 + w * rng.randf_range(0.2, 0.8)
				var gd: float = zp["setback"] + (rng.randf_range(2.0, 8.0) if t1 - t0 - w > 4.0 else mi["d"] + rng.randf_range(3.0, 6.0))
				if gd < float(sd[6]) - 1.5:
					_garden_tree(rect.position + (sd[1] + u * gx + inw * gd) / mpf, rng, info)
		else:
			for i in rng.randi_range(1, 3):
				var gp2: Vector2 = sd[1] + u * rng.randf_range(t0 + 2.0, maxf(t0 + 2.5, t1 - 2.0)) + inw * rng.randf_range(3.0, minf(14.0, float(sd[6]) - 2.0))
				_garden_tree(rect.position + gp2 / mpf, rng, info)
	_ground.append([rect, zone])
	var plain: Array = []
	for l in lots:
		plain.append([l[0], l[1], l[2], l[3]])
	info["blocks"].append({"o": o, "nx": nx, "ny": ny, "zone": zone, "Lx": Lx, "Ly": Ly, "inset": inset, "lots": plain, "foot_m2": foot, "empty": empty})


## Leerfläche eines Blocks: Anteil der Blockfläche auf unbebauten Parzellen (Baulücken). Parzelle = Kantenabschnitt
## bis zur Blockmitte: jeder Punkt gehört zur nächsten Kante (Nord/Süd Trapez, West/Ost Dreieck; Höhe an Stelle t =
## min(t, Länge - t, halbe Gegenkante)). West/Ost beginnen erst nach dem Eckeinzug; diese Eckanteile zählen zur
## Nord-/Süd-Parzelle an der Ecke. Exakt (analytisch), keine Abtastung. Lx = Nord/Süd-Kante, Ly = West/Ost-Kante.
static func leerflaeche(lots: Array, Lx: float, Ly: float, inset: float) -> float:
	var built := 0.0
	var by_side := {"N": [], "S": [], "W": [], "E": []}
	for l in lots:
		by_side[l[0]].append(l)
	for sd in by_side:
		var ns: bool = sd == "N" or sd == "S"
		for l in by_side[sd]:
			if l[3]:
				built += _wedge(l[1], l[2], Lx if ns else Ly, (Ly if ns else Lx) * 0.5)
	var corner := _wedge(0.0, inset, Ly, Lx * 0.5)
	var occ_at := func(side: String, t: float) -> bool:
		for l in by_side[side]:
			if t >= l[1] - 0.01 and t <= l[2] + 0.01:
				return l[3]
		return false
	if occ_at.call("N", Lx): built += corner       # E, t < inset   -> N bei x = Lx
	if occ_at.call("S", 0.0): built += corner      # E, t > Ly-inset -> S bei x = Lx (t_S = 0)
	if occ_at.call("S", Lx): built += corner       # W, t < inset   -> S bei x = 0 (t_S = Lx)
	if occ_at.call("N", 0.0): built += corner      # W, t > Ly-inset -> N bei x = 0
	return clampf(1.0 - built / (Lx * Ly), 0.0, 1.0)


## ∫ min(t, len - t, cap) dt von a bis b (Fläche des Kantenbereichs zwischen a und b).
static func _wedge(a: float, b: float, len: float, cap: float) -> float:
	var f := func(t: float) -> float:
		t = clampf(t, 0.0, len)
		var h := minf(cap, len * 0.5)
		# Stammfunktion von min(t, len - t, h)
		if t <= h:
			return t * t * 0.5
		var area := h * h * 0.5
		if t <= len - h:
			return area + (t - h) * h
		area += (len - 2.0 * h) * h
		var r := len - t
		return area + (h * h - r * r) * 0.5
	return maxf(0.0, f.call(b) - f.call(a))


## Proxy-Kacheln sind doppelt so groß (800 m): weniger Draw Calls in der Übersicht.
func _pchunk_key(p: Vector2) -> String:
	return "%d,%d" % [floori(p.x / (CHUNK * 2)), floori(p.y / (CHUNK * 2))]


func _chunk_key(p: Vector2) -> String:
	return "%d,%d" % [floori(p.x / CHUNK), floori(p.y / CHUNK)]


## Haus an Weltposition p (Szene, Grundflächenmitte), Front zeigt nach front (2D).
func _house(path: String, p: Vector2, front: Vector2, info: Dictionary) -> void:
	var mi: Dictionary = models[path]
	var yaw := atan2(front.x, front.y)
	var s: float = mi["s"] / mpf
	var basis := Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s))
	var c := Vector2i(floori(p.x), floori(p.y))
	var y := hoehe(c)
	# Modell-Pivot liegt fast mittig; Rest-Versatz (cx, cz) ausgleichen
	var off := Basis(Vector3.UP, yaw) * Vector3(-mi["cx"], 0, -mi["cz"]) / mpf
	var xf := Transform3D(basis, Vector3(p.x, y, p.y) + off)
	var key := _chunk_key(p)
	var k := key + "|" + path
	if not _det.has(k):
		_det[k] = []
	_det[k].append(xf)
	# Proxy: etwas kleiner als die Modell-Hülle (verschwindet im Übergangsband im Detailmodell)
	var pk := _pchunk_key(p)
	if not _prox.has(pk):
		_prox[pk] = []
	var pb := Basis(Vector3.UP, yaw).scaled_local(Vector3(mi["w"] * PROXY_SHRINK / mpf, mi["h"] * 0.9 / mpf, mi["d"] * PROXY_SHRINK / mpf))
	_prox[pk].append(Transform3D(pb, Vector3(p.x, y, p.y)))
	info["buildings"] += 1
	info["tris_buildings"] += int(mi["tris"])
	var z: String = mi["zone"]
	info["zones"][z] = info["zones"].get(z, 0) + 1
	info["houses"].append([p, path])


func _garden_tree(p: Vector2, rng: RandomNumberGenerator, info: Dictionary) -> void:
	var path: String = TREE_MODELS[0] if rng.randf() < 0.6 else TREE_MODELS[1]
	if not models.has(path):
		return
	var s := 9.0 / mpf * rng.randf_range(0.9, 1.5)
	var c := Vector2i(floori(p.x), floori(p.y))
	var xf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.9, 1.2), s)), Vector3(p.x, hoehe(c), p.y))
	if not info.has("_tree_list"):
		info["_tree_list"] = []
	info["_tree_list"].append([_chunk_key(p) + "|" + path, xf, int(models[path]["tris"])])


## Deckel: höchstens TREES_PER_BUILDING_MAX je Gebäude und Baum-Dreiecke ≤ TREE_SHARE_MAX der Stadt-Dreiecke.
func _tree_cap(info: Dictionary) -> void:
	var lst: Array = info.get("_tree_list", [])
	info.erase("_tree_list")
	var cap := int(info["buildings"] * TREES_PER_BUILDING_MAX)
	var tb: int = info["tris_buildings"]
	var tt := 0
	var n := 0
	for e in lst:
		if n >= cap or float(tt + e[2]) > TREE_SHARE_MAX / (1.0 - TREE_SHARE_MAX) * float(tb):
			break
		if not _tree.has(e[0]):
			_tree[e[0]] = []
		_tree[e[0]].append(e[1])
		tt += e[2]
		n += 1
	info["trees"] = n
	info["trees_cut"] = lst.size() - n
	info["tris_trees"] = tt


## Streuhaus an der Ausfallstraße: Zelle c, Straße liegt in Richtung to_street.
func _fringe_house(c: Vector2i, to_street: Vector2i, rng: RandomNumberGenerator, info: Dictionary, center: Vector2i) -> void:
	var path := _pick(zone_models["rand"], "dorf", rng, 10.5)
	if path == "":
		return
	var mi: Dictionary = models[path]
	var front := Vector2(to_street)
	var ctr := Vector2(c) + Vector2(0.5, 0.5)
	# Front an der Straßenkante (Straßenmitte = Nachbarfeldmitte, halbe Breite 6 m) + 4–7 m Vorgarten
	var edge := ctr + front * (1.0 - STREET_HALF_M / mpf)
	var p: Vector2 = edge - front * ((rng.randf_range(4.0, 7.0) + float(mi["d"]) * 0.5) / mpf)
	var along := Vector2(front.y, front.x) * rng.randf_range(-0.18, 0.18)
	_house(path, p + along, front, info)
	info["fringe_m"] = maxf(info["fringe_m"], (p.distance_to(Vector2(center) + Vector2(0.5, 0.5)) - info["r_eff"]) * mpf)
	if rng.randf() < 0.7:
		_garden_tree(p - front * ((mi["d"] * 0.5 + 4.0) / mpf) + Vector2(front.y, front.x) * rng.randf_range(-0.2, 0.2), rng, info)


# ---------------------------------------------------------------- Bahnhof

## Bahnhofsstreifen außerhalb des Rasters, auf einer Hauptachse ohne Ausfallstraße: 2 Felder tief, 7 lang.
## Innen das Empfangsgebäude (Commercial-Kit), außen Bahnsteig + zwei Deko-Gleise parallel zum Stadtrand.
func _place_station(center: Vector2i, cells: Dictionary, raster: Dictionary, used: Array) -> Dictionary:
	# Kandidaten: Achse ohne Ausfallstraße zuerst, dann Rasterlinien neben den Achsen (±3, ±6 Felder). Der Rand wird
	# am Raster gemessen (nicht an der Ausfallstraße), damit der Bahnhof an der Stadt liegt und nicht draußen.
	var cand: Array = []
	for d in DIRS4:
		if not used.has(d):
			cand.append([d, 0])
	for sh in [3, -3, 6, -6, 9, -9, 12, -12]:
		for d in DIRS4:
			if not used.has(d):
				cand.append([d, sh])
		for d in used:
			cand.append([d, sh])
	for cd in cand:
		var d: Vector2i = cd[0]
		var shift: int = cd[1]
		var perp := Vector2i(d.y, d.x)
		var line0: Vector2i = center + perp * shift
		if not raster.has(line0):
			continue
		var k := 0
		while raster.has(line0 + d * (k + 1)):
			k += 1
		if k < 2:
			continue
		# Streifen hinter der weitesten Rasterzelle seiner Breite (Nachbarlinien können weiter reichen)
		for a in range(-3, 4):
			var la: Vector2i = center + perp * (a + shift)
			var ka := k
			while raster.has(la + d * (ka + 1)) and ka < k + 6:
				ka += 1
			k = maxi(k, ka)
		var strip: Array = []
		var ok := true
		for depth in [1, 2]:
			for a in range(-3, 4):
				var c: Vector2i = center + d * (k + depth) + perp * (a + shift)
				if not _cell_ok(c) or cells.has(c):
					ok = false
				strip.append(c)
		if not ok:
			continue
		var rmin := Vector2(1e9, 1e9)
		var rmax := Vector2(-1e9, -1e9)
		for c in strip:
			cells[c] = true
			rmin = rmin.min(Vector2(c))
			rmax = rmax.max(Vector2(c) + Vector2.ONE)
		_ground.append([Rect2(rmin, rmax - rmin), "kern"])        # Bahnhofsvorplatz/Gleisfeld als Fläche
		# Zufahrt: Achsstraße bis an den Streifen verlängern ist nicht nötig, das Gebäude steht am Rasterende
		var base := Vector2(center + d * k + perp * shift) + Vector2(0.5, 0.5)
		var dv := Vector2(d)
		var pv := Vector2(perp)
		var y := hoehe(center + d * (k + 1))
		var front := -dv
		var hall := "res://props/kenney_city/buildings/commercial/building-e.glb"
		var wing := "res://props/kenney_city/buildings/commercial/building-k.glb"
		var hall_pos := base + dv * (0.5 + (STREET_HALF_M + 2.0 + 12.0) / mpf)
		if models.has(hall) and models.has(wing):
			_misc_add(hall, _model_xf(hall, hall_pos, front, 1.3, y))
			for sgn in [-1.0, 1.0]:
				_misc_add(wing, _model_xf(wing, hall_pos + pv * sgn * ((models[hall]["w"] * 1.3 * 0.5 + models[wing]["w"] * 0.5 + 0.5) / mpf), front, 1.0, y))
		# Bahnsteig (175 m × 6 m) + Dach (80 m), zwei Gleise mit 5 m Abstand
		var plat_c := base + dv * 1.78
		_misc_box("platform", plat_c, pv, Vector3(7.0, 0.04, 6.0 / mpf), y + 0.02)
		_misc_box("roof", plat_c, pv, Vector3(3.2, 0.03, 7.0 / mpf), y + 5.0 / mpf)
		for g in [0, 1]:
			var gc: Vector2 = plat_c + dv * ((5.5 + g * 5.0) / mpf)
			_misc_box("ballast", gc, pv, Vector3(7.4, 0.012, 3.8 / mpf), y + 0.006)
			if models.has(RAIL_MODEL):
				var gs := 2.392 / mpf
				var n := 18
				var len := 7.0 / n
				for i in n:
					var start: Vector2 = gc + pv * (-3.5 + i * len)
					var yaw := atan2(pv.x, pv.y)
					var b := Basis(Vector3.UP, yaw).scaled_local(Vector3(gs, gs, len / 4.0 + 0.0005))
					_misc_add(RAIL_MODEL, Transform3D(b, Vector3(start.x, y + 0.024, start.y)))
		return {"dir": d, "cells": strip.size(), "pos": base + dv * 1.5}
	return {}


func _model_xf(path: String, p: Vector2, front: Vector2, scale: float, y: float) -> Transform3D:
	var mi: Dictionary = models[path]
	var yaw := atan2(front.x, front.y)
	var s: float = mi["s"] / mpf * scale
	return Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s)), Vector3(p.x, y, p.y))


## Bahnhofsteile laufen wie Häuser über die LOD-Kacheln (Detail bis LOD_M, Gebäude dahinter als Proxy).
func _misc_add(path: String, xf: Transform3D) -> void:
	var p := Vector2(xf.origin.x, xf.origin.z)
	var key := _chunk_key(p)
	var k := key + "|" + path
	if not _det.has(k):
		_det[k] = []
	_det[k].append(xf)
	if path != RAIL_MODEL:
		var mi: Dictionary = models[path]
		var sc: float = xf.basis.get_scale().x / (float(mi["s"]) / mpf)
		var yaw := atan2(xf.basis.z.x, xf.basis.z.z)
		var pb := Basis(Vector3.UP, yaw).scaled_local(Vector3(mi["w"] * PROXY_SHRINK, mi["h"] * 0.9, mi["d"] * PROXY_SHRINK) * sc / mpf)
		var pk := _pchunk_key(p)
		if not _prox.has(pk):
			_prox[pk] = []
		_prox[pk].append(Transform3D(pb, xf.origin))


var _box_mats := {}
var _boxes: Array = []
var _ground: Array = []                # [Rect2 Blockinneres, Zone]: Grundstücksfläche, liest die Stadt aus der Ferne als Fläche

func _misc_box(kind: String, c: Vector2, along: Vector2, size: Vector3, y: float) -> void:
	_boxes.append([kind, c, along, size, y])


# ---------------------------------------------------------------- MultiMeshes anlegen

## Nach allen Städten: je (Kachel, Modell) eine MultiMesh, Proxy je Kachel, Bäume je (Kachel, Modell), Bahnhöfe.
func commit() -> void:
	var lod := LOD_M / mpf
	for k in _det:
		var path: String = k.get_slice("|", 1)
		var mmi := _mmi(models[path]["mesh"], _det[k], k.get_slice("|", 0), true)
		mmi.material_override = _kit_mat(path)
		mmi.visibility_range_end = lod
		mmi.name = "Haus_" + k.replace("|", "_").replace("/", "_").replace(":", "").replace(".", "_")
		total["mmi_detail"] += 1
		total["buildings"] += (_det[k] as Array).size()
		total["tris_buildings"] += (_det[k] as Array).size() * int(models[path]["tris"])
	for k in _prox:
		var mmi := _mmi(proxy_mesh_gable, _prox[k], k, false, CHUNK * 2)
		mmi.visibility_range_begin = PROXY_BEGIN_M / mpf
		mmi.name = "Proxy_" + k.replace("|", "_").replace(",", "_")
		total["mmi_proxy"] += 1
	for k in _tree:
		var path: String = k.get_slice("|", 1)
		var mmi := _mmi(models[path]["mesh"], _tree[k], k.get_slice("|", 0), false)
		mmi.material_override = _kit_mat(path)
		mmi.visibility_range_end = TREE_END_M / mpf
		mmi.name = "Baum_" + k.get_slice("|", 0).replace(",", "_") + "_" + path.get_file().get_basename()
		total["trees"] += (_tree[k] as Array).size()
		total["tris_trees"] += (_tree[k] as Array).size() * int(models[path]["tris"])
	for path in _misc:
		var mmi := _mmi(models[path]["mesh"], _misc[path], "", path != RAIL_MODEL)
		mmi.material_override = _kit_mat(path)
		mmi.name = "Bahnhof_" + path.get_file().get_basename()
	var cols := {"platform": Color(0.62, 0.59, 0.54), "roof": Color(0.42, 0.30, 0.26), "ballast": Color(0.40, 0.37, 0.34)}
	for kind in cols:
		var xfs: Array = []
		for bx in _boxes:
			if bx[0] != kind:
				continue
			var along: Vector2 = bx[2]
			var size: Vector3 = bx[3]
			var yaw := atan2(along.x, along.y)
			var basis := Basis(Vector3.UP, yaw).scaled_local(Vector3(size.z, size.y, size.x))
			xfs.append(Transform3D(basis, Vector3(bx[1].x, bx[4] + size.y * 0.5, bx[1].y)))
		if xfs.is_empty():
			continue
		var bm := BoxMesh.new()
		var mat := StandardMaterial3D.new()
		mat.albedo_color = cols[kind]
		mat.roughness = 1.0
		bm.material = mat
		var mmi := _mmi(bm, xfs, "", kind == "roof")
		mmi.name = "Bahnhof_" + kind
	_commit_ground()


## Blockgrund (Railway Empire: helle Grundstücke zwischen den Straßen). Farben aus der Palette abgeleitet
## (gras/stadt_haus_hell/stadt_strasse gemischt, nicht in palette_s08): Kern gepflastert, Mitte hell, Rand fast Gras.
## Eine MultiMesh (PlaneMesh, 2 Dreiecke je Block), 0,3 m über dem Gelände, unter Straßenkacheln (1,1 m).
func _commit_ground() -> void:
	if _ground.is_empty():
		return
	var gras := _pal("gras", Color8(115, 148, 92))
	var hell := _pal("stadt_haus_hell", Color8(209, 199, 178))
	var str_c := _pal("stadt_strasse", Color8(76, 76, 82))
	var col := {"kern": hell.lerp(str_c, 0.30), "mitte": gras.lerp(hell, 0.45), "rand": gras.lerp(hell, 0.22), "dorf": gras.lerp(hell, 0.18)}
	var xfs: Array = []
	var cols: Array = []
	for g in _ground:
		var r: Rect2 = g[0]
		var c := Vector2i(floori(r.get_center().x), floori(r.get_center().y))
		xfs.append(Transform3D(Basis.from_scale(Vector3(r.size.x + 0.02, 1.0, r.size.y + 0.02)), Vector3(r.get_center().x, hoehe(c) + GROUND_Y, r.get_center().y)))
		cols.append(col[g[1]])
	var pm := PlaneMesh.new()
	pm.size = Vector2.ONE
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	pm.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = pm
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		mm.set_instance_color(i, cols[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.name = "Stadtgrund"
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## MultiMesh mit Knoten in der Kachelmitte (visibility_range misst zum Knoten bzw. zur AABB-Mitte).
func _mmi(mesh: Mesh, xfs: Array, chunk: String, shadow: bool, size := CHUNK) -> MultiMeshInstance3D:
	var origin := Vector3.ZERO
	if chunk != "":
		var cx := int(chunk.get_slice(",", 0))
		var cz := int(chunk.get_slice(",", 1))
		origin = Vector3((cx + 0.5) * size, 0.0, (cz + 0.5) * size)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	var buf := PackedFloat32Array()
	buf.resize(xfs.size() * 12)
	var j := 0
	for t: Transform3D in xfs:
		var b := t.basis
		var o := t.origin - origin
		buf[j] = b.x.x; buf[j + 1] = b.y.x; buf[j + 2] = b.z.x; buf[j + 3] = o.x
		buf[j + 4] = b.x.y; buf[j + 5] = b.y.y; buf[j + 6] = b.z.y; buf[j + 7] = o.y
		buf[j + 8] = b.x.z; buf[j + 9] = b.y.z; buf[j + 10] = b.z.z; buf[j + 11] = o.z
		j += 12
	mm.buffer = buf
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.position = origin
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi
