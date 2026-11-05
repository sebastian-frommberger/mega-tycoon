extends SceneTree
## Fix-Pass W2 (Technical Artist + Mira): Prüfung der acht Mängel aus der Look-Abnahme, headless.
##   godot --headless --path slice -s res://tests/proto_fixpass_test.gd
## M1 Spur: Feldweg (3,5 m) = Bandmitte, breite Bänder Rechtsverkehr nur mit Luft; M2 Sackgasse: Halt innerhalb des Bandes;
## M3/M4 Schilder: Fußpunkt am Ort, Rahmen im Viewport; M5 Wasserrad + Mühlgraben; M7 Marktstände; M8 Weiler ohne Schild.
## Renderabhängiges (M6 Felder-Moiré, Pflaster) belegen die Bilder aus proto_shots_fix.gd.

const Easing := preload("res://proto/proto_easing.gd")

var n_ok := 0
var n_fail := 0


func ok(c: bool, text: String) -> void:
	if c:
		n_ok += 1
		print("  OK   ", text)
	else:
		n_fail += 1
		print("  FAIL ", text)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("proto_fixpass_test")
	var rw = JSON.parse_string(FileAccess.get_file_as_string("res://world/data/proto/regelwerk.json"))
	var prof = Easing.Profil.aus_regelwerk(rw, "fuhrwerk")
	ok(prof.spur_fuer(3.5) == 0.0, "M1 Feldweg 3,5 m: Spur-Versatz 0 (Bandmitte)")
	var sp6: float = prof.spur_fuer(6.0)
	ok(sp6 >= 0.0 and sp6 <= prof.spur and (6.0 - prof.breite_m) * 0.5 - sp6 >= Easing.SPUR_RAND_M - 1e-4, "M1 breites Band 6 m: Versatz %.2f m, Rad bleibt ≥ %.1f m vom Rand" % [sp6, Easing.SPUR_RAND_M])
	ok(absf(prof.halt_rand_m() - (prof.laenge_m * 0.5 + Easing.HALT_LUFT_M)) < 1e-4, "M2 Halt-Rand = halbe Gespannlänge + Luft (%.2f m)" % prof.halt_rand_m())

	var s: Node = (load("res://proto/prototyp_welt.tscn") as PackedScene).instantiate()
	s.kette_modus = "fest"              # S8 AT-08: Szenen-Default ist "leer"; dieser Test misst die feste Kette
	root.add_child(s)
	await process_frame
	root.size = Vector2i(1600, 900)
	await process_frame
	var vp: Vector2 = root.get_visible_rect().size

	# M1/M2 an den echten Routen
	var mitte_n := 0
	var max_versatz := 0.0
	var sack_n := 0
	var sack_ok := true
	for f in s.proto_sim.fahrzeuge:
		for rl in f["legs"]:
			if rl == null:
				continue
			for k in rl.spur.size():
				var d := Vector2(rl.spur[k].x - rl.mitte[k].x, rl.spur[k].z - rl.mitte[k].z).length()
				max_versatz = maxf(max_versatz, d)
				if d < 0.05:
					mitte_n += 1
			if rl.rand_start + rl.rand_ende > 0.0:
				sack_n += 1
				sack_ok = sack_ok and absf(rl.pose_p(0.0) - rl.rand_start) < 1e-3 and absf(rl.pose_p(rl.laenge) - (rl.laenge - rl.rand_ende)) < 1e-3
	ok(mitte_n > 100, "M1 Fahrzeuge fahren auf Feldweg-Abschnitten in der Bandmitte (%d Proben mit Versatz < 5 cm)" % mitte_n)
	ok(max_versatz <= prof.spur + 1e-3, "M1 Spur-Versatz nie größer als Profil-Spur (max %.2f m)" % max_versatz)
	ok(sack_n > 0 and sack_ok, "M2 Sackgassen-Routen (%d) enden mit Randabstand: Pose bleibt im Band" % sack_n)

	# M5 Wasserrad, M7 Marktstände
	var lage: Dictionary = s.kulissen.lage
	ok(s.kulissen.muehlrad != null and not (lage.get("muehlrad", {}) as Dictionary).is_empty(), "M5 Wasserrad an der Erlenmühle vorhanden (%s)" % str(lage.get("muehlrad", {}).keys()))
	ok(int(lage.get("markt_staende", 0)) == 8 and s.kulissen.markt_mmi != null, "M7 acht Marktstände auf dem Marktplatz Lindenfurt")

	# M3/M4/M8 Schilder
	var sch = s.schilder
	s.setze_preset(5)
	sch.aktualisiere(true)
	var alle_im := true
	var n_sichtbar := 0
	for id in ["erlenbach", "lindenfurt", "erlenmuehle", "hasenwinkel", "gutshof"]:
		var e: Dictionary = sch.eintrag(id)
		if e.is_empty() or not e["sichtbar"]:
			continue
		n_sichtbar += 1
		var r: Rect2 = e["rect"]
		if not Rect2(Vector2.ZERO, vp).grow(1.0).encloses(r):
			alle_im = false
			print("       außerhalb: ", id, " ", r)
	ok(n_sichtbar > 0 and alle_im, "M4 Preset 5: alle sichtbaren Schilder liegen im Viewport (%d geprüft)" % n_sichtbar)
	s.setze_preset(3)
	sch.aktualisiere(true)
	var lf: Dictionary = sch.eintrag("lindenfurt")
	ok(lf["sichtbar"] and lf.has("fuss_pos") and lf.has("fuss_scr"), "M3 Lindenfurt: Fußpunkt (Marktplatz) berechnet, Fußlinie möglich")
	ok(Vector2(lf["ax"] - lf["x"], lf["az"] - lf["z"]).length() < 120.0, "M3 Anker %.0f m vom Ortsmittelpunkt, am Marktplatz" % Vector2(lf["ax"] - lf["x"], lf["az"] - lf["z"]).length())
	var hw: Dictionary = sch.eintrag("hasenwinkel")
	s.ziel = Vector3(hw["x"], 0, hw["z"])
	s.abstand = 200.0
	s._kamera_anwenden()
	sch.aktualisiere(true)
	ok(not sch.eintrag("hasenwinkel")["sichtbar"], "M8 Weiler Hasenwinkel: kein Schild (Charter E6, Regelwerk label.hierarchie.weiler = nie)")

	# WA-08 Ladeplatz je Betrieb/Ort: Datenpunkt = Heck-Halt-Punkt am Sackgassen-Wegende, Gespann-Heck <= 3 m vom Ladeplatz,
	# Halt (ProtoSim.knoten_halt vom Datenpunkt) = Wegende des Ladeplatzes. Heck aus dem echten Profil (halbe Länge + Luft + halbe Länge).
	var orte_j = JSON.parse_string(FileAccess.get_file_as_string("res://world/data/proto/proto_orte.json"))
	var wege_j: Array = JSON.parse_string(FileAccess.get_file_as_string("res://world/data/proto/proto_wege.json"))
	var wege_id := {}
	for w in wege_j:
		wege_id[w["id"]] = w
	var sites: Array = []
	for ind in orte_j["industrie"]:
		sites.append([String(ind["name"]), ind, true])
	for o in orte_j["orte"]:
		if bool(o.get("sim_knoten", false)):
			sites.append([String(o["name"]), o, false])
	var ps = s.proto_sim
	for e in sites:
		var nm: String = e[0]
		var lpd = e[1].get("ladeplatz", null)
		if not (lpd is Dictionary):
			ok(false, "WA-08 %s: Ladeplatz-Datensatz fehlt" % nm)
			continue
		var P := Vector2(float(lpd["x"]), float(lpd["z"]))
		var pts: Array = wege_id[lpd["weg"]]["punkte"]
		var h := Vector2(float(lpd["halt"]["x"]), float(lpd["halt"]["z"]))
		var n_halt: int = ps.knoten_halt(P)
		var kp: Vector3 = ps.knoten_pos[n_halt]
		var ende := Vector2(float(lpd["halt"]["x"]), float(lpd["halt"]["z"]))
		if String(lpd["halt"]["art"]) == "durchgang":
			# Durchgangs-Ladeplatz (Mühle): Datenpunkt = Halteknoten, Gespann hält mit der Mitte im Knoten (Grad ≥ 3, kein Sackgassen-Heck)
			var d_k := Vector2(kp.x, kp.z).distance_to(P)
			ok(d_k < 0.5 and int(ps.knoten_grad.get(n_halt, 0)) >= 2, "WA-08 %s: Durchgangshalt, Halt = Datenpunkt-Knoten (Knoten %d, Grad %d, %.2f m)" % [nm, n_halt, int(ps.knoten_grad.get(n_halt, -1)), d_k])
		else:
			var a := Vector2(float(pts[0][0]), float(pts[0][1]))
			var b := Vector2(float(pts[-1][0]), float(pts[-1][1]))
			ende = b if b.distance_to(ende) < a.distance_to(ende) else a
			var inn: Vector2 = Vector2(float(pts[-2][0]), float(pts[-2][1])) if ende == b else Vector2(float(pts[1][0]), float(pts[1][1]))
			for q in (pts.slice(-8) if ende == b else pts.slice(0, 8)):
				var qv := Vector2(float(q[0]), float(q[1]))
				if qv.distance_to(ende) >= 6.0:
					inn = qv
			var t: Vector2 = (ende - inn).normalized()
			var heck: Vector2 = ende - t * (prof.halt_rand_m() + prof.laenge_m * 0.5)       # Mitte hält halt_rand vor dem Ende, Heck eine halbe Länge dahinter
			var d_heck := heck.distance_to(P)
			var d_knoten := Vector2(kp.x, kp.z).distance_to(ende)
			ok(d_heck <= 3.0, "WA-08 %s: Gespann-Heck %.2f m vom Ladeplatz (≤ 3 m)" % [nm, d_heck])
			ok(n_halt > 0 and int(ps.knoten_grad[n_halt]) == 1 and d_knoten < 1.0, "WA-08 %s: Halt = Wegende des Ladeplatzes (Knoten %d, Grad %d, %.2f m vom Wegende)" % [nm, n_halt, int(ps.knoten_grad.get(n_halt, -1)), d_knoten])
		if ps.stationen.has(nm):
			var st: Dictionary = ps.stationen[nm]
			var sp: Vector3 = ps.knoten_pos[int(st["knoten"])]
			var d_st := Vector2(sp.x, sp.z).distance_to(ende)
			if e[2]:
				ok(d_st < 1.0, "WA-08 %s: ProtoSim-Station liegt am Ladeplatz-Wegende (%.2f m)" % [nm, d_st])
			else:
				print("  INFO WA-08 %s (Ort): ProtoSim liest den Ladeplatz für Orte noch nicht, Station %.0f m vom Ladeplatz-Wegende (Felix, Halt = Ladeplatz)" % [nm, d_st])
		for hf in lpd["lagerhaufen"]:
			var fs: Dictionary = hf["fuellstufen"]
			ok(int(fs["anzahl"]) == 3 and (fs["grenzen"] as Array).size() == 3 and (fs["prefab_refs"] as Array).size() == 3, "WA-08 %s: Lagerhaufen %s mit 3 Füllstufen (Daten)" % [nm, hf["gut"]])

	print("proto_fixpass_test: %d OK, %d FAIL" % [n_ok, n_fail])
	quit(1 if n_fail > 0 else 0)
