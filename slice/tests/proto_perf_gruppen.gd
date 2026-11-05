extends SceneTree
## Phase 4 Welle 2 (Felix): Perf-Aufschlüsselung der Prototyp-Welt je Node-Gruppe (Dreiecke, Draw Calls, Instanzen).
##   headless (gezählt):  godot --headless --path slice -s res://tests/proto_perf_gruppen.gd [-- --preset=1 --md=<pfad>]
##   live (xvfb):         xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice \
##                            -s res://tests/proto_perf_gruppen.gd
## Gezählt = Mesh-Daten der sichtbaren Knoten (MultiMesh: Dreiecke × sichtbare Instanzen), DC = Flächen je Objekt im
## Farbpass ohne Schatten und ohne Frustum-/Sichtweiten-Culling (obere Schranke). Mit Renderziel zusätzlich die
## RenderingServer-Werte je Preset und je Gruppe (Gruppe ausgeblendet → Differenz).
## Gruppe = Pfad bis Tiefe 2 unter der Szene (z. B. ProtoTerrain/Gelaende_0_0 wird zu ProtoTerrain/Gelaende_*).

const SZENE := "res://proto/prototyp_welt.tscn"

var _cache := {}


func _initialize() -> void:
	_run.call_deferred()


func _tris(m: Mesh) -> int:
	var id := m.get_instance_id()
	if _cache.has(id):
		return _cache[id]
	var t := 0
	if m is PrimitiveMesh:
		t = m.get_faces().size() / 3
	else:
		for s in m.get_surface_count():
			var arr := m.surface_get_arrays(s)
			var idx = arr[Mesh.ARRAY_INDEX]
			t += (idx.size() if idx != null and idx.size() > 0 else arr[Mesh.ARRAY_VERTEX].size()) / 3
	_cache[id] = t
	return t


static func gruppe_von(pfad: String) -> String:
	var teile := pfad.split("/")
	var out: Array = []
	for i in mini(teile.size(), 2):
		var t: String = teile[i]
		var r := RegEx.create_from_string("[_ ]?[0-9]+(_[0-9]+)*$")
		out.append(r.sub(t, "_*"))
	return "/".join(out)


## Zählt je Gruppe {tris, dc, inst, knoten, sicht_m}.
func zaehle(s: Node) -> Dictionary:
	var g := {}
	var stapel: Array = [[s, ""]]
	while not stapel.is_empty():
		var e: Array = stapel.pop_back()
		var n: Node = e[0]
		var pfad: String = e[1]
		if n is Node3D and not (n as Node3D).visible:
			continue
		var t := 0
		var dc := 0
		var inst := 0
		var sicht := 0.0
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			t = _tris(n.mesh)
			dc = n.mesh.get_surface_count()
			inst = 1
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
			var mm: MultiMesh = n.multimesh
			var cnt := mm.instance_count if mm.visible_instance_count < 0 else mm.visible_instance_count
			if mm.mesh != null and cnt > 0:
				t = _tris(mm.mesh) * cnt
				dc = mm.mesh.get_surface_count()
				inst = cnt
		if n is GeometryInstance3D:
			sicht = (n as GeometryInstance3D).visibility_range_end
		if t > 0:
			var k := gruppe_von(pfad)
			if not g.has(k):
				g[k] = {"tris": 0, "dc": 0, "inst": 0, "knoten": 0, "sicht_m": 0.0}
			g[k]["tris"] += t
			g[k]["dc"] += dc
			g[k]["inst"] += inst
			g[k]["knoten"] += 1
			g[k]["sicht_m"] = maxf(g[k]["sicht_m"], sicht)
		for c in n.get_children():
			stapel.append([c, (pfad + "/" if pfad != "" else "") + String(c.name)])
	return g


func _run() -> void:
	var preset := 1
	var md := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--preset="):
			preset = int(a.substr(9))
		elif a.begins_with("--md="):
			md = a.substr(5)
	var s: Node = (load(SZENE) as PackedScene).instantiate()
	s.kette_modus = "fest"              # S8 AT-08: Szenen-Default ist "leer"; dieser Test misst die feste Kette
	root.add_child(s)
	await process_frame
	s.setze_preset(preset)
	for i in 4:
		await process_frame
	var g := zaehle(s)
	var keys := g.keys()
	keys.sort_custom(func(a, b): return g[a]["tris"] > g[b]["tris"])
	var sum_t := 0
	var sum_dc := 0
	for k in keys:
		sum_t += g[k]["tris"]
		sum_dc += g[k]["dc"]
	var live := DisplayServer.get_name() != "headless"
	var zeilen: Array = []
	zeilen.append("| Gruppe | Dreiecke | Anteil | DC (Flächen) | Instanzen | Knoten | Sichtweite m |")
	zeilen.append("|---|---:|---:|---:|---:|---:|---:|")
	for k in keys:
		var e: Dictionary = g[k]
		zeilen.append("| %s | %d | %.1f %% | %d | %d | %d | %s |" % [k, e["tris"], 100.0 * e["tris"] / maxf(1, sum_t), e["dc"], e["inst"],
			e["knoten"], ("%.0f" % e["sicht_m"]) if e["sicht_m"] > 0.0 else "–"])
	zeilen.append("| **Summe** | **%d** | 100 %% | **%d** | | | |" % [sum_t, sum_dc])
	if live:
		var z: Dictionary = s.zaehlung()
		zeilen.append("")
		zeilen.append("Live (RenderingServer, Preset %d): %d Dreiecke, %d DC (inkl. Schatten-Pässe)" % [preset, z["live_dreiecke"], z["live_dc"]])
		# Differenz je großer Gruppe: Gruppe ausblenden, 3 Frames, live neu lesen
		var basis_t: int = z["live_dreiecke"]
		var basis_dc: int = z["live_dc"]
		zeilen.append("")
		zeilen.append("| Gruppe (live, ausgeblendet) | Δ Dreiecke | Δ DC |")
		zeilen.append("|---|---:|---:|")
		var top := ["ProtoTerrain/Baeume", "ProtoTerrain", "Modelle", "Wege", "Fahrzeuge"]
		for k in top:
			var n: Node = s.get_node_or_null(k)
			if n == null or not (n is Node3D):
				continue
			(n as Node3D).visible = false
			for i in 3:
				await process_frame
			var z2: Dictionary = s.zaehlung()
			(n as Node3D).visible = true
			zeilen.append("| %s | %d | %d |" % [k, basis_t - int(z2["live_dreiecke"]), basis_dc - int(z2["live_dc"])])
		for i in 3:
			await process_frame
	print("PERF_GRUPPEN preset=%d live=%s" % [preset, str(live)])
	for zl in zeilen:
		print(zl)
	if md != "":
		var f := FileAccess.open(md, FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(PackedStringArray(zeilen)) + "\n")
			f.close()
	quit(0)
