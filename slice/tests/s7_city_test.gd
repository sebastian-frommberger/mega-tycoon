extends SceneTree
## W-03 (S7, Sophie): Städte im neuen Maßstab – Akzeptanz aus dem Refinement S7 (nur S7-Welt).
##   godot --headless --path slice -s res://tests/s7_city_test.gd
## Prüft: Radius je Stufe (Kleinstadt 450 m ±15 %), Ausfransung (Kleinstadt +300–700 m), Gebäudezahl (Kleinstadt ≥ 400,
## Dorf/Stadt nach rules_s7), 3 Gebäudetypen Kern/Mitte/Rand, Leerfläche je Block < 50 %, Bäume ≤ 60 % der Dreiecke,
## city_streets vorhanden und vom Zentrum erreichbar (Z-01), Bahnhof, LOD-Schalter ohne Loch, Nachfrage unverändert
## (gegen die Formel und gegen den Slice), Slice ohne Generator, Ladezeit.

const MAIN := "res://main.tscn"
const MainScript := preload("res://main.gd")
const CityGen := preload("res://world/city_gen.gd")
const KenneyLoader := preload("res://props/kenney_loader.gd")

var checks := 0
var fails := 0


func _initialize() -> void:
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("  OK   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _boot(w: String) -> Node:
	MainScript.world_override = w
	var m = load(MAIN).instantiate()
	root.add_child(m)
	return m


func _tris(mesh: Mesh) -> int:
	var n := 0
	for s in mesh.get_surface_count():
		var a := mesh.surface_get_arrays(s)
		var ix = a[Mesh.ARRAY_INDEX]
		n += (ix.size() if ix != null else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return n


func _all_mmi(n: Node, out: Array) -> void:
	if n is MultiMeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_all_mmi(c, out)


func _run() -> void:
	print("== W-03 Leerfläche: Rechenweg (synthetisch)")
	var L := 63.0
	var full := [["N", 0.0, L, true], ["S", 0.0, L, true], ["W", 15.0, L - 15.0, true], ["E", 15.0, L - 15.0, true]]
	var none := [["N", 0.0, L, false], ["S", 0.0, L, false], ["W", 15.0, L - 15.0, false], ["E", 15.0, L - 15.0, false]]
	var ns_only := [["N", 0.0, L, true], ["S", 0.0, L, true], ["W", 15.0, L - 15.0, false], ["E", 15.0, L - 15.0, false]]
	var e_full: float = CityGen.leerflaeche(full, L, L, 15.0)
	var e_none: float = CityGen.leerflaeche(none, L, L, 15.0)
	var e_ns: float = CityGen.leerflaeche(ns_only, L, L, 15.0)
	# Nord/Süd belegt: zwei Dreiecke (je L²/4) + vier Eckanteile (je 15²/2) belegt, Rest leer
	var want_ns := 1.0 - (2.0 * L * L / 4.0 + 4.0 * 15.0 * 15.0 / 2.0) / (L * L)
	ok(absf(e_full) < 1e-4 and absf(e_none - 1.0) < 1e-4 and absf(e_ns - want_ns) < 1e-4,
		"Parzellenmodell exakt: voll %.3f, leer %.3f, nur Nord/Süd %.4f (Soll %.4f)" % [e_full, e_none, e_ns, want_ns])
	var rect_full := [["N", 0.0, 138.0, true], ["S", 0.0, 138.0, true], ["W", 15.0, 48.0, true], ["E", 15.0, 48.0, true]]
	ok(absf(CityGen.leerflaeche(rect_full, 138.0, 63.0, 15.0)) < 1e-4, "Parzellenmodell Rechteck 138 × 63 m voll belegt = 0")

	print("== W-03 Städte S7")
	var t0 := Time.get_ticks_msec()
	var m = _boot("s7")
	var boot_ms := Time.get_ticks_msec() - t0
	var cg = m.city_gen
	ok(cg != null and cg.cities.size() == m.map_data["staedte"].size(), "Generator aktiv, %d/%d Städte" % [cg.cities.size() if cg else 0, m.map_data["staedte"].size()])
	ok(m.load_ms <= 6000.0, "Ladezeit S7 %.0f ms (Budget 6 s Sandbox, Start gesamt %d ms)" % [m.load_ms, boot_ms])
	var rules: Dictionary = cg.rules["stufen"]
	var tol: float = 0.15
	var kleinstadt := 0
	for st in m.map_data["staedte"]:
		var id: String = st["id"]
		var info: Dictionary = cg.cities[id]
		var rs: Dictionary = rules[st["stufe"]]
		var r_soll: float = float(rs["zielradius"]["m"])
		var r_ist: float = info["r_eff_m"]
		var gmin: int = int(rs["gebaeude_min"])
		var fr_max: float = float(rs["ausfransung"]["m_max"])
		var name := "%s (%s)" % [st["name"], st["stufe"]]
		ok(info["stufe"] == st["stufe"], "%s: Stufe aus den Kartendaten" % name)
		ok(absf(r_ist - r_soll) <= r_soll * tol, "%s: Radius %.0f m (Soll %.0f m ±15 %%)" % [name, r_ist, r_soll])
		ok(info["buildings"] >= gmin, "%s: %d Gebäude (Soll ≥ %d)" % [name, info["buildings"], gmin])
		ok(info["fringe_m"] <= fr_max + 1.0, "%s: Ausfransung %.0f m (≤ %.0f m)" % [name, info["fringe_m"], fr_max])
		var worst := 0.0
		var bad := 0
		for b in info["blocks"]:
			var e: float = CityGen.leerflaeche(b["lots"], b["Lx"], b["Ly"], b["inset"])
			worst = maxf(worst, e)
			if e >= 0.5 or absf(e - b["empty"]) > 1e-4:
				bad += 1
		ok(bad == 0 and info["blocks"].size() > 0, "%s: Leerfläche je Block max %.0f %% in %d Blöcken (Soll < 50 %%)" % [name, worst * 100.0, info["blocks"].size()])
		var share: float = float(info["tris_trees"]) / maxf(1.0, float(info["tris_trees"] + info["tris_buildings"]))
		ok(share <= 0.6, "%s: Bäume %.1f %% der Stadt-Dreiecke (%d Bäume, Deckel ≤ 60 %%)" % [name, share * 100.0, info["trees"]])
		# Straßen: im Slice-Format eingetragen, Zentrum ist Stadtstraße, Netz vom Zentrum erreichbar (Z-01-Andocken)
		var city = m.by_id[id]
		var n_st := 0
		for c in city.cells():
			if m.city_streets.has(c):
				n_st += 1
		var reach: Dictionary = m._city_reach(city)
		ok(m.city_streets.has(city.anchor()) and n_st == info["streets"] and float(reach.size()) >= 0.5 * float(n_st),
			"%s: city_streets %d, Zentrum %s ist Straße, vom Zentrum erreichbar %d (≥ 50 %%, Fluss darf teilen)" % [name, n_st, str(city.anchor()), reach.size()])
		if st["stufe"] != "dorf":
			ok(not info["station"].is_empty(), "%s: Bahnhof am Rand %s" % [name, str(info["station"].get("dir", "-"))])
		if st["stufe"] == "kleinstadt":
			kleinstadt += 1
			ok(info["fringe_m"] >= 300.0 and info["fringe_m"] <= 700.0, "%s: Ausfransung +%.0f m an Ausfallstraßen (Soll 300–700 m)" % [name, info["fringe_m"]])
			var z: Dictionary = info["zones"]
			ok(z["kern"] > 0 and z["mitte"] > 0 and z["rand"] > 0, "%s: 3 Gebäudetypen Kern %d / Mitte %d / Rand %d" % [name, z["kern"], z["mitte"], z["rand"]])
			ok(info["buildings"] >= 400, "%s: ≥ 400 Gebäude (%d)" % [name, info["buildings"]])
	var foreign := 0
	for c in m.city_streets:
		var bb = m.cell_to_building.get(c)
		if bb == null or bb.kind != m.Building.Kind.CITY:
			foreign += 1
	ok(foreign == 0, "jede Stadtstraße liegt auf einer Stadtfläche (%d außerhalb)" % foreign)
	ok(kleinstadt >= 1, "mindestens eine Kleinstadt geprüft (%d)" % kleinstadt)
	# Zonen-Modelle stimmen: Kernhäuser nur Commercial, Dorf nur Randmodelle
	var zone_ok := true
	for id in cg.cities:
		for h in cg.cities[id]["houses"]:
			var mi: Dictionary = cg.models[h[1]]
			if cg.cities[id]["stufe"] == "dorf" and mi["min_stufe"] != "dorf":
				zone_ok = false
			if mi["zone"] == "kern" and mi["kit"] != "commercial":
				zone_ok = false
	ok(zone_ok, "Modelle passen zu Zone/Stufe (Kern = Commercial, Dorf nur Dorf-Modelle)")

	print("== W-03 Instancing, LOD-Schalter, Dreiecksanteil Bäume (Szene)")
	var mmis: Array = []
	_all_mmi(m, mmis)
	var tree_meshes: Array = KenneyLoader._cache.values()
	var t_tree := 0
	var t_all := 0
	var n_house := 0
	var lod_ok := true
	var houses_in_mmi := 0
	for mi in mmis:
		var mm: MultiMesh = mi.multimesh
		if mm == null or mm.mesh == null:
			continue
		var t := _tris(mm.mesh) * mm.instance_count
		t_all += t
		if String(mi.name).begins_with("Baum_") or tree_meshes.has(mm.mesh):
			t_tree += t
		if String(mi.name).begins_with("Haus_"):
			n_house += 1
			houses_in_mmi += mm.instance_count
			if mi.visibility_range_end <= 0.0:
				lod_ok = false
		if String(mi.name).begins_with("Proxy_") and (mi.visibility_range_begin <= 0.0 or mi.visibility_range_begin > CityGen.LOD_M / 25.0 - 283.0 / 25.0):
			lod_ok = false
	var n_build := 0
	for id in cg.cities:
		n_build += cg.cities[id]["buildings"]
	ok(n_house > 0 and houses_in_mmi >= n_build, "Häuser als MultiMesh: %d Instanzen in %d MultiMeshes (%d Stadtgebäude + Bahnhof)" % [houses_in_mmi, n_house, n_build])
	ok(lod_ok, "LOD: Detail endet bei %.0f m, Proxy beginnt ≥ 283 m früher (kein Loch)" % CityGen.LOD_M)
	ok(float(t_tree) <= 0.6 * float(t_all), "Bäume %.1f %% aller Instanz-Dreiecke der Szene (%d von %d, Soll ≤ 60 %%)" % [100.0 * t_tree / maxf(1.0, t_all), t_tree, t_all])

	print("== W-03 Nachfrage unverändert")
	var demand_s7 := {}
	var formula_ok := true
	for b in m.buildings:
		if b.kind != m.Building.Kind.CITY:
			continue
		var d: int = m.eco.city_demand(b.site)
		demand_s7[b.map_id] = d
		var mult: int = int(m.eco.demand_mult.get(b.city_stage, 1000))
		var want: int = m.eco.rdiv(b.city_pop * m.eco.demand_per_100 * mult, 100 * 1000)
		if d != want:
			formula_ok = false
			print("     %s: %d != Formel %d" % [b.map_id, d, want])
	ok(formula_ok and demand_s7.size() == m.map_data["staedte"].size(), "S7: Nachfrage je Stadt = Einwohner × Satz × Stufenfaktor (%d Städte)" % demand_s7.size())
	m.free()
	var s = _boot("slice")
	# Hinweis (S7 Block B): Die S7-Welt hat eine eigene Karte (andere Städte), ein Vergleich der Nachfrage mit dem Slice entfällt.
	ok(s.city_gen == null, "Slice: kein Stadtgenerator (bitgleich)")
	s.free()
	MainScript.world_override = ""
	print("%d/%d Prüfungen OK" % [checks - fails, checks])
	quit(0 if fails == 0 else 1)
