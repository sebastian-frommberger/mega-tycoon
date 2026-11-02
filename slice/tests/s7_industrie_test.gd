extends SceneTree
## W-05 Lesbarkeit (S7, Mira, Block C) + U8 „Nächster Schritt“ live (U-03-Rest, beide Welten).
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/s7_industrie_test.gd
## Prüft:
##   Daten: je Typ Fläche 150–300 m, Kontrast nach S-08 (max(Füllung, Saum) ≥ 3:1 gegen Gras, Füllung ≥ 3:1 gegen Saum),
##          Plaketten ja/nein/frei vorhanden und verschieden.
##   Welt:  alle geladenen Industrien haben Signalfläche (im Mesh), Plakette (Textur) und Namen.
##   4 km:  je Industrie (Kamera auf der Industrie) Plakette sichtbar, ≥ 24 px aus der echten Projektion der Billboard-Ecken,
##          Name sichtbar; keine Überlappung zwischen Plaketten, Industrie- und Stadtlabels (auch Kartenmitte).
##   Saum ≥ 2,5 px aus 4 km; LOD: nah dezenter (kleiner, halbtransparent), unter 400 m aus.
##   Status: Lizenz nein → ja wechselt Plakette (Form + Farbe), Abnehmer ohne Plakette; Slice ohne Marker.
##   U8: Hinweise nur mit offenen Teilen und Preis, sofort nach Lizenzkauf/Bau/Linie aktualisiert (slice + s7).

const MAIN := "res://main.tscn"
const MainScript := preload("res://main.gd")
const Welt := preload("res://world/welt.gd")
const Markers := preload("res://world/industry_markers.gd")

var m: Node
var fails := 0
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("  OK   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _fresh(w: String, city := "haberau") -> void:
	if m != null:
		m.free()
	MainScript.world_override = w
	m = load(MAIN).instantiate()
	root.add_child(m)
	m.place_hq(city)
	m.eco.cash_cent = 50_000_000
	m.set_speed(0)
	m.sim_hover_active = true
	m.sim_hover = Vector2i(-1, -1)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func z(meter: float) -> float:
	return Welt.zoom_for_distance_m("s7", meter)


func _run() -> void:
	_daten()
	_fresh("s7")
	_welt()
	await _lesbarkeit()
	await _lod_status()
	_fresh("slice")
	ok(m.industry_markers == null and m.get_node_or_null("IndustryMarkers") == null, "Slice: keine Industrie-Marker (unverändert)")
	for w in ["slice", "s7"]:
		_u8(w)
	if m != null:
		m.free()
	MainScript.world_override = ""
	print("%d/%d Prüfungen OK" % [checks - fails, checks])
	quit(0 if fails == 0 else 1)


# ---------------------------------------------------------------- Daten / Kontrast

func _c(a: Array) -> Color:
	return Color8(int(a[0]), int(a[1]), int(a[2]))


func _daten() -> void:
	var sig: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Markers.SIG_PATH))
	var pal: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/palette_s08.json"))
	var gras := _c(pal["hintergruende"]["gras"]["rgb"])
	var worst := 99.0
	for typ in sig["typen"]:
		var t: Dictionary = sig["typen"][typ]
		var g := float(t["groesse_m"])
		var saum := _c(sig["saum"]["hell"] if t["saum"] == "hell" else sig["saum"]["dunkel"])
		var res := []
		var good := g >= 150.0 and g <= 300.0
		for k in ["fuellung", "fuellung2"]:
			var f := _c(t[k])
			var wirksam := maxf(Markers.contrast(f, gras), Markers.contrast(saum, gras))
			var fs := Markers.contrast(f, saum)
			worst = minf(worst, minf(wirksam, fs))
			good = good and wirksam >= 3.0 and fs >= 3.0
			res.append("%s %.2f/%.2f" % [k, wirksam, fs])
		var tex_ok := true
		var imgs := {}
		for st in ["ja", "nein", "frei"]:
			var p: String = Markers.PLATE_DIR + "%s_%s.png" % [typ, st]
			tex_ok = tex_ok and ResourceLoader.exists(p)
			if ResourceLoader.exists(p):
				imgs[st] = (load(p) as Texture2D).get_image().get_data()
		tex_ok = tex_ok and imgs.size() == 3 and imgs["ja"] != imgs["nein"] and imgs["nein"] != imgs["frei"]
		ok(good, "Signal %s: %d m, %s (wirksam gegen Gras / gegen Saum, je ≥ 3:1)" % [typ, int(g), ", ".join(res)])
		ok(tex_ok, "Plaketten %s ja/nein/frei vorhanden und verschieden" % typ)
	print("  INFO kleinster Kontrast Signalflächen: %.2f:1" % worst)


# ---------------------------------------------------------------- Welt: Fläche + Icon + Name je Industrie

func _welt() -> void:
	var mk = m.industry_markers
	ok(mk != null, "S7: industry_markers angelegt")
	var n_ind := 0
	for ind in m.map_data["industrien"]:
		if ind.get("im_slice", true):
			n_ind += 1
	ok(mk.entries.size() == n_ind and n_ind > 0, "alle %d geladenen Industrien haben einen Marker (%d)" % [n_ind, mk.entries.size()])
	var aabb: AABB = mk.surf_mi.mesh.get_aabb()
	var miss := []
	for e in mk.entries:
		var b = e["b"]
		var gr: Rect2 = mk.ground_rect(b)
		var size_m: float = gr.size.x * m.m_pro_feld
		var in_mesh := aabb.grow(0.01).has_point(Vector3(gr.position.x, aabb.position.y, gr.position.y)) and \
			aabb.grow(0.01).has_point(Vector3(gr.end.x, aabb.position.y, gr.end.y))
		if not (size_m >= 150.0 and size_m <= 300.0 and in_mesh and e["sprite"].texture != null and b.display_name != "" \
				and b.label.text.begins_with(b.display_name)):
			miss.append(b.map_id)
	ok(miss.is_empty(), "je Industrie Fläche 150–300 m im Mesh + Plakette + Name (fehlend: %s)" % str(miss))
	ok(mk.surf_mi.mesh.get_surface_count() == 1 and mk.saum_mi.mesh.get_surface_count() == 1, "Flächen und Säume je 1 Mesh (2 Draw Calls)")


# ---------------------------------------------------------------- Lesbarkeit aus 4 km

## Rechtecke aller sichtbaren Beschriftungen: Städte (Formel wie label_declutter), Industrien aus der Projektion:
## Plakette = vier Billboard-Ecken, Name = projizierte Label-Position (oben links) + Textmaß.
func _rects() -> Array:
	var out := []
	var mk = m.industry_markers
	var kscale := root.get_viewport().get_visible_rect().size.y / 900.0 * 560.0
	for b in m.buildings:
		var l: Label3D = b.label
		if not l.visible or m.cam.is_position_behind(b.position) or l.modulate.a <= 0.02:
			continue
		if mk.owns(b):
			out.append({"id": "N:" + b.map_id, "r": Rect2(m.cam.unproject_position(l.global_position), mk.text_size(l, kscale))})
		else:
			out.append({"id": "L:" + b.map_id, "r": mk.label_rect(b, m.cam, kscale)})
	for e in mk.entries:
		if e["sprite"].visible:
			out.append({"id": "I:" + e["b"].map_id, "r": mk.projected_rect(e)})
	return out


func _overlaps() -> Array:
	var rs := _rects()
	var bad := []
	for i in rs.size():
		for j in range(i + 1, rs.size()):
			if rs[i]["r"].intersects(rs[j]["r"]):
				bad.append("%s×%s" % [rs[i]["id"], rs[j]["id"]])
	return bad


## Name steht dort, wo die Einheit ihn plant (Projektion gegen Planung, ±2 px), und rechts neben der Plakette.
func _unit_ok(e: Dictionary) -> bool:
	var l: Label3D = e["b"].label
	var lp: Vector2 = m.cam.unproject_position(l.global_position)
	var tr: Rect2 = e.get("text_rect", Rect2())
	var ir: Rect2 = m.industry_markers.projected_rect(e)
	return lp.distance_to(tr.position) < 2.0 and ir.end.x <= lp.x + 1.0 and absf(ir.get_center().y - (tr.position.y + tr.size.y * 0.5)) < 3.0


func _lesbarkeit() -> void:
	var mk = m.industry_markers
	var vp := root.get_viewport().get_visible_rect().size
	ok(vp.y >= 899.0, "Viewport %s (xvfb 1600×900)" % str(vp))
	var small := []
	var hidden := []
	var ov := {}
	var min_px := 999.0
	for e in mk.entries:
		var b = e["b"]
		m.focus(Vector2(b.position.x, b.position.z), z(4000.0))
		await _frames(4)
		var r: Rect2 = mk.projected_rect(e)
		if not e["sprite"].visible or not b.label.visible:
			hidden.append(b.map_id)
		elif not _unit_ok(e):
			hidden.append(b.map_id + " (Name nicht neben Plakette)")
		min_px = minf(min_px, minf(r.size.x, r.size.y))
		if r.size.x < 24.0 or r.size.y < 24.0:
			small.append("%s %.0f px" % [b.map_id, r.size.x])
		if absf(r.size.x - 34.0) > 1.5:
			small.append("%s soll 34 px, ist %.1f" % [b.map_id, r.size.x])
		for o in _overlaps():
			ov[o] = true
	ok(hidden.is_empty(), "4 km: Plakette + Name als Einheit je Industrie sichtbar (Fehler: %s)" % str(hidden))
	ok(small.is_empty(), "4 km: Plakette ≥ 24 px aus Projektion (min %.1f px) %s" % [min_px, str(small)])
	ok(ov.is_empty(), "4 km: keine Überlappung Plakette/Label/Stadt (%s)" % str(ov.keys()))
	# Kartenmitte (Übersicht): alles im Bild, keine Überlappung
	m.focus(Vector2(m.GRID * 0.5, m.GRID * 0.5), z(4000.0))
	await _frames(4)
	var vis := 0
	for e in mk.entries:
		if e["sprite"].visible:
			vis += 1
	var o2 := _overlaps()
	ok(o2.is_empty() and vis >= 5, "4 km Kartenmitte: %d Plaketten sichtbar, Überlappungen %s" % [vis, str(o2)])
	var mpp: float = 2.0 * Welt.distance_m_for_zoom("s7", m.zoom) * tan(deg_to_rad(m.cam.fov) * 0.5) / vp.y
	ok(mk.saum_m / mpp >= 2.4, "Saum aus 4 km %.1f m = %.1f px (≥ 2,5 px)" % [mk.saum_m, mk.saum_m / mpp])
	# Stadt-Nähe: Haberau liegt 425 m neben Getreidefarm 2 – Plakette weicht dem Stadtlabel aus
	var hab = m.by_id["haberau"]
	m.focus(Vector2(hab.position.x, hab.position.z), z(4000.0))
	await _frames(4)
	var o3 := _overlaps()
	ok(o3.is_empty(), "4 km Haberau + Farmen: keine Überlappung %s" % str(o3))


# ---------------------------------------------------------------- LOD + Status

func _lod_status() -> void:
	var mk = m.industry_markers
	var e: Dictionary = mk.by_b[m.by_id["farm_1"]]
	var b = e["b"]
	m.focus(Vector2(b.position.x, b.position.z), z(1000.0))
	await _frames(4)
	var r1: Rect2 = mk.projected_rect(e)
	var a1: float = e["sprite"].modulate.a
	ok(e["sprite"].visible and r1.size.x < 33.0 and r1.size.x >= 21.0 and a1 < 1.0, "1 km: Plakette dezenter (%.1f px, alpha %.2f)" % [r1.size.x, a1])
	m.focus(Vector2(b.position.x, b.position.z), z(300.0))
	await _frames(4)
	ok(not e["sprite"].visible and b.label.visible, "300 m: Plakette aus (Props übernehmen), Name bleibt")
	m.focus(Vector2(b.position.x, b.position.z), z(4000.0))
	await _frames(2)
	var lic: bool = m.eco.licence_valid(b.site)
	ok(e["status"] == ("ja" if lic else "nein"), "Status farm_1 vor Kauf: %s" % e["status"])
	var tex_before: Texture2D = e["sprite"].texture
	if not lic:
		m.ui_buy_licence(b)
	await _frames(1)
	ok(e["status"] == "ja" and e["sprite"].texture != tex_before, "Lizenzkauf → Plakette „ja“ (runde grüne Marke) im nächsten Frame")
	var kw: Dictionary = mk.by_b[m.by_id["kraftwerk_1"]]
	ok(kw["status"] == "frei", "Kraftwerk (Abnehmer, keine Lizenz): Plakette ohne Statusmarke")
	var mu: Dictionary = mk.by_b[m.by_id["muehle_2"]]
	ok(mu["status"] == "nein", "Mühle 2 ohne Lizenz: eckige graue Marke (Status %s)" % mu["status"])


# ---------------------------------------------------------------- U8 Nächster Schritt

func _u8(w: String) -> void:
	_fresh(w)
	var ms: Array = m.milestones
	var src = m.by_id[ms[1]["t"][0]]
	var proc = m.by_id[ms[2]["t"][1]]
	var f = m.by_id[ms[6]["t"][0]]
	var t = m.by_id[ms[6]["t"][1]]
	var q: Dictionary = m.licence_quote(src)
	var price: String = "gratis" if int(q["zu_zahlen_cent"]) == 0 else m.money_str(int(q["zu_zahlen_cent"]))
	ok(m.next_step_label.text.contains(src.display_name) and m.next_step_label.text.contains("Lizenz " + price),
		"[%s] U8 Start: Lizenz-Hinweis mit Preis: „%s“" % [w, m.next_step_label.text])
	var h6: String = ms[6]["hint"]
	# ehrlich: direkt baubar -> Preis; sonst Grund aus der Bauvorschau (gleiche Planung wie beim Ziehen)
	var pl6: Dictionary = m.plan_track(f.anchor(), t.anchor(), false)
	var road6: String = ("Straße bis %s bauen (ca. %s)" % [t.display_name, m.money_str(int(pl6["total"]))]) if pl6["ok"] else \
		("Straße bis %s bauen (direkt nicht baubar: %s)" % [t.display_name, str(pl6["reason"]).trim_suffix(".")])
	ok(h6.contains(road6), "[%s] U8 M3 Straßenteil ehrlich (%s): „%s“" % [w, "direkt baubar" if pl6["ok"] else "direkt nicht baubar", h6])
	ok(h6.contains("Lizenz für %s kaufen (" % f.display_name)
		and h6.contains("ein Zug lohnt sich") == (absi(f.anchor().x - t.anchor().x) + absi(f.anchor().y - t.anchor().y) > 60),
		"[%s] U8 M3 offen: „%s“" % [w, h6])
	m.ui_buy_licence(src)
	var road_cost: int = m._ns_road_cost(src, proc)
	var want := "(ca. %s)" % m.money_str(road_cost)
	ok(m.milestones[1]["done"] and m.next_step_label.text.contains(want) and not m.next_step_label.text.contains("Lizenz kaufen"),
		"[%s] U8 nach Lizenzkauf sofort Straße mit Preis %s: „%s“" % [w, want, m.next_step_label.text])
	var pl: Dictionary = m.plan_track(src.anchor(), proc.anchor(), false)
	ok(road_cost > 0 and road_cost == int(pl["total"]), "[%s] U8 Straßenpreis im Hinweis = Bauvorschau beim Ziehen (%s, %s)" % [w,
		m.money_str(road_cost), "baubar" if pl["ok"] else "Vorschau: " + str(pl["reason"])])
	var cash0: int = m.eco.cash_cent
	if m.build_track(src.anchor(), proc.anchor(), false):
		ok(cash0 - m.eco.cash_cent == road_cost, "[%s] U8 bezahlt = Hinweis (%s)" % [w, m.money_str(cash0 - m.eco.cash_cent)])
	else:          # Farm 2 → Mühle 1 quert den Fluss diagonal (Aylin): über ein Eckfeld bauen
		var mid := Vector2i(src.anchor().x, proc.anchor().y)
		ok(m.build_track(src.anchor(), mid, false) and m.build_track(mid, proc.anchor(), false), "[%s] Straße über Eckfeld gebaut" % w)
	ok(m.milestones[2]["done"] and m.next_step_label.text.contains("[4]"), "[%s] U8 nach Bau sofort Linien-Schritt: „%s“" % [w, m.next_step_label.text])
	# M3: Teile verschwinden einzeln
	m.ui_buy_licence(f)
	h6 = m.milestones[6]["hint"]
	ok(not h6.contains("Lizenz für") and h6.contains("Straße bis"), "[%s] U8 M3 nach Lizenz %s: „%s“" % [w, f.display_name, h6])
	var built := _build_route(f.anchor(), t.anchor())
	h6 = m.milestones[6]["hint"]
	ok(built and not h6.contains("Straße bis") and h6.contains("Linie %s → %s einrichten" % [f.display_name, t.display_name]),
		"[%s] U8 M3 nach Straße: „%s“" % [w, h6])
	m.create_line(f, t, "truck")
	h6 = m.milestones[6]["hint"]
	ok(h6.contains("läuft"), "[%s] U8 M3 nach Linie: „%s“" % [w, h6])


## Baubaren Straßenweg a -> c suchen und bauen: direkt, über ein Eckfeld, sonst über einen Zwischenpunkt außerhalb
## von Städten (±70 Felder, Schritt 5). Baut nur, wenn beide Teilstücke laut Bauvorschau baubar sind.
func _build_route(a: Vector2i, c: Vector2i) -> bool:
	if m.plan_track(a, c, false)["ok"]:
		return m.build_track(a, c, false)
	var vias: Array = [Vector2i(a.x, c.y), Vector2i(c.x, a.y)]
	for dx in range(-70, 71, 5):
		for dy in range(-70, 71, 5):
			vias.append(c + Vector2i(dx, dy))
	for p in vias:
		if not m._in_grid(p) or m.cell_to_building.has(p) or m._city_of(p) != null:
			continue
		if m.plan_track(a, p, false)["ok"] and m.plan_track(p, c, false)["ok"]:
			print("  INFO Straße über Zwischenpunkt ", p)
			return m.build_track(a, p, false) and m.build_track(p, c, false)
	return false
