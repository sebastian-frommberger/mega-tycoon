extends SceneTree
## Test-Runner Spike F-04. Aufruf:
##   godot --headless --path <spike> --script res://test_runner.gd
## Sprint 3 (F-10/F-11): K7 Wende-Deadlock 10 Fälle, K8 Äquivalenz SoA-Kern = Spike-Kern (Prüfsumme je
## Tick, Ereignisse, Ketten) und ereignisgesteuerte Prüfung = Vollscan, K10 Determinismus Bench-Welt 3 Läufe.
## Exit-Code 0 nur, wenn alle drei Szenarien die erwartete Wurzelursache liefern, Deadlocks in
## höchstens 50 Ticks erkannt werden und die Kontrollen (A*, Positivkontrolle Ladung, 10 min ohne
## Fehlalarm) bestehen. Stand 19.11. (D9): zusätzlich kanonischer Ort (root_pos == links[-1].pos,
## gleich für alle Mitglieder eines Deadlocks und Auffahrer), Zusatzfelder in params, Validator V1–V7,
## Prüfsumme, Ring mit 6 Zügen, Gegenverkehr mit Auffahrer.

const Scenarios := preload("res://scenarios.gd")
const SimWorld := preload("res://sim_world.gd")
const Diagnostics := preload("res://diagnostics.gd")
const NetGraph := preload("res://net_graph.gd")
const DanielLauf := preload("res://daniel_d04_lauf_v2.gd")
const F06World := preload("res://f06/f06_world.gd")
const BenchWorld := preload("res://bench_world.gd")
const EcoTests := preload("res://eco_tests.gd")   # F-16 (Sprint 4)
# Referenz: unveränderter Sprint-2-Spike-Kern (Objekte/Dictionaries) als Orakel für K7/K8
const RefScenarios := preload("res://ref/scenarios.gd")
const RefDaniel := preload("res://ref/daniel_d04_lauf_v2.gd")
const RefF06World := preload("res://ref/f06_world.gd")
const RefBenchWorld := preload("res://ref/bench_world.gd")
const RefDiagnostics := preload("res://ref/diagnostics.gd")

const MAX_DETECT_TICKS := 50

var failures: Array = []


func check(cond: bool, msg: String) -> void:
	print("    [%s] %s" % ["OK" if cond else "FEHLER", msg])
	if not cond:
		failures.append(msg)


func _init() -> void:
	print("== Spike F-04 Testlauf, Godot %s ==" % Engine.get_version_info()["string"])
	check(Diagnostics.VS_WARTET_BLOCK == SimWorld.VState.WARTET_BLOCK
		and Diagnostics.VS_WARTET_LADUNG == SimWorld.VState.WARTET_LADUNG, "Enum-Konstanten Diagnose = Sim")
	var t0 := Time.get_ticks_msec()
	test_s1_gegenverkehr()
	test_s2_deadlock_kreis()
	test_s3_warten_auf_ladung()
	test_s1b_auffahrer()
	test_s2b_ring6()
	test_k1_kontrolle_ausweichgleis()
	test_k2_astar()
	test_k3_pruefsumme()
	test_k4_position_fahrend()
	test_k5_b8_freier_block()
	test_k6_f06_welt()
	test_k7_wende_deadlock()
	test_k8_aequivalenz_und_ereignis()
	test_k10_determinismus_bench()
	EcoTests.new().run(self)
	print("== Dauer %d ms ==" % (Time.get_ticks_msec() - t0))
	if failures.is_empty():
		print("ERGEBNIS: ALLE TESTS GRUEN (Exit 0)")
		quit(0)
	else:
		print("ERGEBNIS: %d FEHLER (Exit 1)" % failures.size())
		for f in failures:
			print("  - " + f)
		quit(1)


## Vertragsvalidator (Aylin V1–V7, Sim-Seite) auf einer Kette.
func check_valid(c: Dictionary, label: String) -> void:
	var errs: Array = Diagnostics.validate(c)
	check(errs.is_empty(), "Validator %s: %s" % [label, "gültig" if errs.is_empty() else str(errs)])
	check(c["links"][-1]["pos"] == c["root_pos"], "%s: root_pos == letztes Kettenglied (D9)" % label)


## Läuft, bis ein Deadlock erkannt ist oder max_ticks erreicht; gibt Sim zurück.
func run_until_detected(sim, max_ticks: int) -> void:
	while sim.tick_count < max_ticks and sim.deadlock_events.is_empty():
		sim.step()


func test_s1_gegenverkehr() -> void:
	print("S1 Gegenverkehr eingleisig")
	var sim = Scenarios.gegenverkehr_eingleisig()
	run_until_detected(sim, 400)
	check(sim.deadlock_events.size() == 1, "genau ein Deadlock-Ereignis (%d)" % sim.deadlock_events.size())
	if sim.deadlock_events.is_empty():
		return
	var ev: Dictionary = sim.deadlock_events[0]
	print("    Zyklus gebildet Tick %d, erkannt Tick %d, Ticks bis Erkennung: %d, Mitglieder %s" % [
		ev["tick_formed"], ev["tick_detected"], ev["ticks_to_detect"], str(ev["members"])])
	check(ev["ticks_to_detect"] <= MAX_DETECT_TICKS, "Erkennung in <= %d Ticks (%d)" % [MAX_DETECT_TICKS, ev["ticks_to_detect"]])
	var c1: Dictionary = sim.get_wait_chain(1)
	var c2: Dictionary = sim.get_wait_chain(2)
	print("    " + Diagnostics.debug_text(c1))
	print("    " + Diagnostics.debug_text(c2))
	check(c1["root_cause"] == "EINGLEISIG_GEGENVERKEHR", "Zug 1 Ursache EINGLEISIG_GEGENVERKEHR (%s)" % c1["root_cause"])
	check(c2["root_cause"] == "EINGLEISIG_GEGENVERKEHR", "Zug 2 Ursache EINGLEISIG_GEGENVERKEHR (%s)" % c2["root_cause"])
	# Kanonischer Ort (D9): Mitte der umkämpften Blöcke B-C (300000,0) und C-D (500000,0) = (400000,0),
	# für beide Züge gleich. Von Hand aus dem Layout.
	check(c1["root_pos"] == Vector2i(400000, 0), "Zug 1 root_pos = (400000,0) (%s)" % str(c1["root_pos"]))
	check(c2["root_pos"] == c1["root_pos"], "Zug 2 root_pos gleich Zug 1 (kanonisch, Daniel B1)")
	check(c1["root_obj"] == c2["root_obj"], "beide Züge nennen dasselbe Ursache-Objekt %s" % str(c1["root_obj"]))
	check_valid(c1, "S1 Zug 1")
	check_valid(c2, "S1 Zug 2")
	check(c1["params"].get("strecke_mm") == 400000 and c1["params"].get("strecke_felder") == 40
		and c1["params"].get("gleiszahl") == 1 and c1["params"].get("n_fahrzeuge") == 2,
		"params Streckenlänge 400000 mm = 40 Felder, Gleiszahl 1, 2 Fahrzeuge (%s)" % JSON.stringify(c1["params"]))
	check(c1["wait_since_tick"] == 101 and c2["wait_since_tick"] == 51, "wait_since_tick Zug 1 = 101, Zug 2 = 51 (%d, %d)" % [c1["wait_since_tick"], c2["wait_since_tick"]])
	check(c1["is_deadlock"] and c1["in_cycle"] and c1["cycle"].size() == 2, "Zyklus mit 2 Fahrzeugen, Zug 1 darin")
	check(c1["links"].size() == 7 and c1["links"][6]["kind"] == "URSACHE", "Kette Zug 1 hat 7 Glieder, letztes URSACHE (%d)" % c1["links"].size())
	check(c1["suggestion_id"] == "AUSWEICHGLEIS_BAUEN", "Vorschlag-ID AUSWEICHGLEIS_BAUEN")
	# Determinismus: zweiter Lauf, gleiche Ausgabe
	var sim2 = Scenarios.gegenverkehr_eingleisig()
	run_until_detected(sim2, 400)
	check(JSON.stringify(sim2.deadlock_events) == JSON.stringify(sim.deadlock_events)
		and var_to_str(sim2.get_wait_chain(1)) == var_to_str(c1), "zweiter Lauf identisch (deterministisch)")


func test_s2_deadlock_kreis() -> void:
	print("S2 Deadlock-Kreis")
	var sim = Scenarios.deadlock_kreis()
	run_until_detected(sim, 400)
	check(sim.deadlock_events.size() == 1, "genau ein Deadlock-Ereignis (%d)" % sim.deadlock_events.size())
	if sim.deadlock_events.is_empty():
		return
	var ev: Dictionary = sim.deadlock_events[0]
	print("    Zyklus gebildet Tick %d, erkannt Tick %d, Ticks bis Erkennung: %d, Mitglieder %s" % [
		ev["tick_formed"], ev["tick_detected"], ev["ticks_to_detect"], str(ev["members"])])
	check(ev["ticks_to_detect"] <= MAX_DETECT_TICKS, "Erkennung in <= %d Ticks (%d)" % [MAX_DETECT_TICKS, ev["ticks_to_detect"]])
	var c0: Dictionary = sim.get_wait_chain(0)
	print("    " + Diagnostics.debug_text(c0))
	check(c0["root_cause"] == "DEADLOCK", "Ursache DEADLOCK (%s)" % c0["root_cause"])
	check(c0["cycle"].size() == 4, "Zyklus mit 4 Fahrzeugen (%d)" % c0["cycle"].size())
	# Kanonischer Ort (D9): Mitte der vier Block-Mitten des Quadrats = Quadratmitte (100000,100000), für alle 4 gleich
	check(c0["root_pos"] == Vector2i(100000, 100000), "root_pos = Ringmitte (100000,100000) (%s)" % str(c0["root_pos"]))
	var same := true
	for vid in range(4):
		var cv: Dictionary = sim.get_wait_chain(vid)
		same = same and cv["root_pos"] == c0["root_pos"] and cv["root_obj"] == c0["root_obj"]
		check_valid(cv, "S2 Zug %d" % vid)
	check(same, "alle 4 Mitglieder liefern denselben root_pos und root_obj")
	check(c0["params"].get("n_fahrzeuge") == 4 and c0["params"].get("bloecke") == [1, 2, 3, 4], "params n_fahrzeuge 4, Blöcke 1–4 (%s)" % JSON.stringify(c0["params"]))
	check(c0["links"].size() == 13, "Kette hat 13 Glieder (%d)" % c0["links"].size())
	var sim2 = Scenarios.deadlock_kreis()
	run_until_detected(sim2, 400)
	check(JSON.stringify(sim2.deadlock_events) == JSON.stringify(sim.deadlock_events), "zweiter Lauf identisch (deterministisch)")


func test_s3_warten_auf_ladung() -> void:
	print("S3 Warten auf Ladung (Lager unterversorgt, 1 Lkw liefert)")
	var sim = Scenarios.warten_auf_ladung(0)
	sim.run_ticks(300)
	check(sim.deadlock_events.is_empty(), "kein Deadlock gemeldet (es ist keiner)")
	var c2: Dictionary = sim.get_wait_chain(2)
	var c1: Dictionary = sim.get_wait_chain(1)
	print("    " + Diagnostics.debug_text(c2))
	print("    " + Diagnostics.debug_text(c1))
	check(c2["root_cause"] == "WARTEN_AUF_LADUNG", "Zug 10 (hinten) Ursache WARTEN_AUF_LADUNG (%s)" % c2["root_cause"])
	check(c1["root_cause"] == "WARTEN_AUF_LADUNG", "Zug 7 (am Lager) Ursache WARTEN_AUF_LADUNG (%s)" % c1["root_cause"])
	check(c2["root_pos"] == Vector2i(200000, 0) and c1["root_pos"] == Vector2i(200000, 0), "root_pos = Lagerknoten (200000,0)")
	check_valid(c1, "S3 Zug 7")
	check_valid(c2, "S3 Zug 10")
	check(c2["links"].size() == 7 and c2["links"][4]["kind"] == "LAGER" and c2["links"][5]["kind"] == "INDUSTRIE" and c2["links"][6]["kind"] == "URSACHE",
		"Kette Zug 10: Fahrzeug, Signal, Block, Halter, Lager, Industrie, Ursache")
	var p: Dictionary = c2["params"]
	print("    params Zug 10: %s" % JSON.stringify(p))
	check(p.get("n_lkw") == 1 and p.get("lkw_ids") == [3], "n_lkw = 1 (Zulieferer Lkw 3)")
	check(p.get("fuell_soll") == 40 and p.get("fuell_ist") >= 1 and p.get("fuell_ist") < 40,
		"fuell_ist/fuell_soll = %s/%s: Lager bekommt Ware, aber zu wenig" % [str(p.get("fuell_ist")), str(p.get("fuell_soll"))])
	check(sim.stations[1]["delivered_total"] == p.get("fuell_ist"), "gelieferte Menge == fuell_ist (nur der Lkw liefert)")
	check(not c2["is_deadlock"], "is_deadlock = false")
	# Stillstand bleibt >= 120 s (1200 Ticks) bestehen (Aylin Frage 10, Lena Build-Anforderung 2)
	sim.run_ticks(1000)
	check(sim.get_wait_chain(1)["root_cause"] == "WARTEN_AUF_LADUNG" and sim.get_wait_chain(1)["wait_ticks"] >= 1200,
		"Fehler 3 besteht nach 1300 Ticks noch (wartet %d Ticks, fuell_ist %d)" % [sim.get_wait_chain(1)["wait_ticks"], sim.stations[1]["stock"]])
	# Positivkontrolle A: Eigenproduktion 4 Einheiten alle 10 Ticks -> 40 nach 100 Ticks, Zug 7 lädt
	var ok = Scenarios.warten_auf_ladung(10, 4)
	ok.run_ticks(300)
	var v1: Dictionary = ok.vehicles[1]
	print("    Positivkontrolle A (Produktion 4/10 Ticks): Zug 7 geladen in Tick %d, Zug 10 Zustand %d" % [v1["loaded_tick"], ok.vehicles[2]["state"]])
	check(v1["loaded_tick"] > 0 and ok.deadlock_events.is_empty(), "mit Nachschub wird geladen, keine Meldung")
	check(ok.get_wait_chain(1)["root_cause"] != "WARTEN_AUF_LADUNG", "nach dem Laden keine Ursache WARTEN_AUF_LADUNG mehr")
	# Positivkontrolle B: 8 Lkw statt 1 -> n_lkw = 8, Lager füllt sich in Spielminuten
	var ok8 = Scenarios.warten_auf_ladung(0, 1, 8)
	ok8.run_ticks(300)
	var c8: Dictionary = ok8.get_wait_chain(1)
	print("    Positivkontrolle B (8 Lkw): fuell_ist %d, n_lkw %d, Zug 7 geladen Tick %d" % [ok8.stations[1]["stock"], c8["params"].get("n_lkw", -1), ok8.vehicles[1]["loaded_tick"]])
	check(c8["params"].get("n_lkw", 8) == 8 or c8["root_cause"] != "WARTEN_AUF_LADUNG", "n_lkw zählt alle Zulieferer")
	check(ok8.stations[1]["delivered_total"] >= 8, "8 Lkw liefern in 300 Ticks mindestens 8 Einheiten (%d)" % ok8.stations[1]["delivered_total"])


func test_s1b_auffahrer() -> void:
	print("S1b Gegenverkehr mit Auffahrer (D3, Daniel E)")
	var sim = Scenarios.gegenverkehr_auffahrer()
	run_until_detected(sim, 400)
	sim.run_ticks(60)  # Zug 3 fährt noch auf
	check(sim.deadlock_events.size() == 1 and sim.deadlock_events[0]["members"] == [1, 2], "ein Ereignis, Mitglieder [1, 2] (%s)" % str(sim.deadlock_events))
	var c3: Dictionary = sim.get_wait_chain(3)
	var c1: Dictionary = sim.get_wait_chain(1)
	print("    " + Diagnostics.debug_text(c3))
	check(sim.vehicles[3]["state"] == SimWorld.VState.WARTET_BLOCK, "Zug 3 steht (aufgefahren)")
	check(c3["is_deadlock"] and not c3["in_cycle"] and c3["root_cause"] == "EINGLEISIG_GEGENVERKEHR", "Zug 3: is_deadlock, nicht im Kreis, Ursache EINGLEISIG_GEGENVERKEHR")
	check(c3["root_pos"] == c1["root_pos"] and c3["root_obj"] == c1["root_obj"], "Zug 3 bekommt denselben kanonischen Ort wie Zug 1 (%s)" % str(c3["root_pos"]))
	check_valid(c3, "S1b Zug 3")


func test_s2b_ring6() -> void:
	print("S2b Ring mit 6 Zügen (D3, Daniel B2)")
	var sim = Scenarios.deadlock_ring(6)
	run_until_detected(sim, 600)
	check(sim.deadlock_events.size() == 1 and sim.deadlock_events[0]["members"].size() == 6, "ein Ereignis mit 6 Mitgliedern")
	if sim.deadlock_events.is_empty():
		return
	var c0: Dictionary = sim.get_wait_chain(0)
	print("    " + Diagnostics.debug_text(c0))
	check(c0["root_cause"] == "DEADLOCK" and c0["params"].get("n_fahrzeuge") == 6, "Ursache DEADLOCK, n_fahrzeuge 6")
	var same := true
	for vid in range(6):
		var cv: Dictionary = sim.get_wait_chain(vid)
		same = same and cv["root_pos"] == c0["root_pos"]
		var errs: Array = Diagnostics.validate(cv)
		same = same and errs.is_empty()
	check(same, "alle 6 Mitglieder: gleicher root_pos %s, Validator gültig" % str(c0["root_pos"]))
	# Ringmitte: Knoten liegen auf einem Kreis um (SEG,SEG); Block-Mitten mitteln sich auf die Kreismitte (Rundung ±1 mm)
	check((c0["root_pos"] - Vector2i(Scenarios.SEG, Scenarios.SEG)).length() < 1000, "root_pos ist die Ringmitte (±1 m)")


func test_k1_kontrolle_ausweichgleis() -> void:
	print("K1 Kontrolle: Ausweichgleis, 10 min Normalbetrieb (6000 Ticks), kein Fehlalarm")
	var sim = Scenarios.kontrolle_ausweichgleis()
	var wait_ticks_seen := 0
	for i in range(6000):
		sim.step()
		for vid in sim.vehicles:
			if sim.vehicles[vid]["state"] == SimWorld.VState.WARTET_BLOCK:
				wait_ticks_seen += 1
	print("    Ereignisse: %d, Läufe Zug 1: %d, Zug 2: %d, Warte-Ticks gesamt (Fahrzeug-Ticks): %d" % [
		sim.deadlock_events.size(), sim.vehicles[1]["runs"], sim.vehicles[2]["runs"], wait_ticks_seen])
	check(sim.deadlock_events.is_empty(), "0 Deadlock-Meldungen in 6000 Ticks")
	check(sim.vehicles[1]["runs"] >= 10 and sim.vehicles[2]["runs"] >= 10, "beide Züge fahren weiter (je >= 10 Läufe)")
	check(wait_ticks_seen > 0, "Kontrolle enthält echte Wartezeiten (nicht trivial)")


func test_k2_astar() -> void:
	print("K2 A* gegen AStar2D (Kosten) und Determinismus")
	var g = NetGraph.new()
	var pts := {0: Vector2i(0, 0), 1: Vector2i(300000, 0), 2: Vector2i(300000, 400000), 3: Vector2i(0, 400000), 4: Vector2i(600000, 200000)}
	for id in pts:
		g.add_node(id, pts[id])
	var pairs := [[1, 0, 1], [2, 1, 2], [3, 2, 3], [4, 3, 0], [5, 1, 4], [6, 4, 2]]
	var ref := AStar2D.new()
	for id in pts:
		ref.add_point(id, Vector2(pts[id]))
	for p in pairs:
		g.add_edge(p[0], p[1], p[2])
		ref.connect_points(p[1], p[2], true)
	var ok_all := true
	var checked := 0
	for a in pts:
		for b in pts:
			if a == b:
				continue
			var mine: Array = g.find_path(a, b)
			var ids: PackedInt64Array = ref.get_id_path(a, b)
			var ref_cost := 0
			for i in range(ids.size() - 1):
				ref_cost += ceili(Vector2(pts[ids[i]]).distance_to(Vector2(pts[ids[i + 1]])))
			checked += 1
			if g.route_length(mine) != ref_cost:
				ok_all = false
				print("    Abweichung %d->%d: eigen %d, AStar2D %d" % [a, b, g.route_length(mine), ref_cost])
			if var_to_str(mine) != var_to_str(g.find_path(a, b)):
				ok_all = false
	check(ok_all, "eigenes A* hat gleiche Pfadkosten wie AStar2D bei %d Knotenpaaren, wiederholbar" % checked)


func test_k3_pruefsumme() -> void:
	print("K3 Prüfsumme (Daniel S5): gleicher Aufbau = gleiche Summe, anderer Zustand = andere Summe")
	var a = Scenarios.kontrolle_ausweichgleis()
	var b = Scenarios.kontrolle_ausweichgleis()
	a.run_ticks(500)
	b.run_ticks(500)
	var ha: int = a.checksum()
	print("    Prüfsumme nach 500 Ticks: %d" % ha)
	check(ha == b.checksum(), "zwei Läufe, gleiche Prüfsumme")
	b.step()
	check(ha != b.checksum(), "ein Tick weiter, andere Prüfsumme")
	var c = Scenarios.kontrolle_ausweichgleis()
	c.set_vehicle_speed(2, 3000)  # F-10: vehicles ist Lesesicht, Schreiben über API
	c.run_ticks(500)
	check(ha != c.checksum(), "andere Geschwindigkeit, andere Prüfsumme")
	print("    Zustandsverteilung Tick 500: %s" % JSON.stringify(a.state_counts()))


func test_k4_position_fahrend() -> void:
	print("K4 Position fahrender Fahrzeuge (int32-Überlauf, gefunden 23.11.)")
	var sim = Scenarios.gegenverkehr_eingleisig()
	sim.run_ticks(25)  # Zug 1 ist 24 Ticks à 4000 mm auf Kante A-B (200 m) unterwegs
	var v1: Dictionary = sim.vehicles[1]
	var p: Vector2i = sim.vehicle_pos(v1)
	print("    Zug 1 Zustand %d, Kantenfortschritt %d mm, Position %s" % [v1["state"], v1["pos"], str(p)])
	check(v1["state"] == SimWorld.VState.UNTERWEGS and p == Vector2i(int(v1["pos"]), 0), "Position = Kantenfortschritt auf der x-Achse (%s)" % str(p))



## B8 (Daniel, 23.11.): Fahrzeug wartet zwischen zwei Ticks auf einen Block, den der Halter im selben Tick
## freigegeben hat (Halter = -1). Vorher: SCRIPT ERROR in build_wait_chain, Rückgabe {}. Jetzt: gültige Kette,
## Ursache BLOCK_BELEGT_UNTERWEGS mit halter_id -1 (keine Meldung).
func test_k5_b8_freier_block() -> void:
	print("K5 Regression B8: Warten auf im selben Tick freigegebenen Block")
	# a) synthetisch, von Hand konstruiert: Zug 2 (id 2) fährt ab Tick 1 auf Kante 1 (200 m, 50 Ticks),
	#    Zug 1 (id 1, im Tick zuerst dran) startet in Tick 51 und will denselben Block. In Tick 51 versucht Zug 1
	#    zuerst (Block noch von Zug 2 gehalten -> WARTET_BLOCK), danach fährt Zug 2 auf Kante 2 und gibt frei.
	var s = SimWorld.new()
	s.graph.add_node(0, Vector2i(0, 0), "A")
	s.graph.add_node(1, Vector2i(Scenarios.SEG, 0), "B")
	s.graph.add_node(2, Vector2i(2 * Scenarios.SEG, 0), "C")
	s.graph.add_edge(1, 0, 1, false)
	s.graph.add_edge(2, 1, 2, false)
	s.add_vehicle(2, "Zug 2", s.graph.find_path(0, 2), Scenarios.SPEED, 0)
	s.add_vehicle(1, "Zug 1", s.graph.find_path(0, 2), Scenarios.SPEED, 51)
	s.run_ticks(51)
	var v1: Dictionary = s.vehicles[1]
	var holder: int = s.graph.blocks[v1["wait_block"]]["holder"] if v1["wait_block"] != -1 else -99
	check(v1["state"] == SimWorld.VState.WARTET_BLOCK and holder == -1, "B8-Zustand hergestellt: Zug 1 wartet, Halter -1 (Zustand %d, Halter %d)" % [v1["state"], holder])
	var c: Dictionary = s.get_wait_chain(1)
	check(not c.is_empty() and c.has("links"), "get_wait_chain liefert kein leeres Dictionary")
	if c.has("links"):
		print("    " + Diagnostics.debug_text(c))
		check(c["root_cause"] == "BLOCK_BELEGT_UNTERWEGS" and c["params"].get("halter_id") == -1, "Ursache BLOCK_BELEGT_UNTERWEGS, halter_id -1 (%s)" % c["root_cause"])
		check_valid(c, "B8 synthetisch")
	s.step()
	check(s.vehicles[1]["state"] == SimWorld.VState.UNTERWEGS, "einen Tick später ist Zug 1 eingefahren")
	# b) Glied in der Mitte der Kette: Zug 3 steht hinter Zug 1 (wartet auf dessen Block), Zug 1 wartet auf freien Block
	var s2 = SimWorld.new()
	s2.graph.add_node(0, Vector2i(-Scenarios.SEG, 0), "Z")
	s2.graph.add_node(1, Vector2i(0, 0), "A")
	s2.graph.add_node(2, Vector2i(Scenarios.SEG, 0), "B")
	s2.graph.add_node(3, Vector2i(2 * Scenarios.SEG, 0), "C")
	s2.graph.add_edge(1, 1, 2, false)
	s2.graph.add_edge(2, 2, 3, false)
	s2.graph.add_edge(3, 0, 1, false)
	# Zug 1 hält Kante 3 (Z-A) und will Kante 1, die Zug 2 bis Tick 51 hält; Zug 0 (id 0, zuerst dran) will Kante 3
	s2.add_vehicle(2, "Zug 2", s2.graph.find_path(1, 3), Scenarios.SPEED, 0)
	s2.add_vehicle(1, "Zug 1", s2.graph.find_path(0, 3), Scenarios.SPEED, 0)
	s2.add_vehicle(0, "Zug 0", s2.graph.find_path(0, 3), Scenarios.SPEED, 5)
	var mid_ok := true
	var mid_seen := 0
	for t in range(200):
		s2.step()
		for vid in s2.vehicles:
			var vv: Dictionary = s2.vehicles[vid]
			if vv["state"] == SimWorld.VState.WARTET_BLOCK:
				var cc: Dictionary = s2.get_wait_chain(vid)
				if cc.is_empty() or not Diagnostics.validate(cc).is_empty():
					mid_ok = false
				elif cc["params"].get("halter_id") == -1 and cc["links"].size() > 4:
					mid_seen += 1
	check(mid_seen >= 1, "B8 als mittleres Glied hergestellt (%d Fälle)" % mid_seen)
	check(mid_ok, "alle Ketten in 200 Ticks gültig (inkl. B8 in der Mitte)")
	# c) Daniels Replay (daniel_b8_replay.gd): Normalnetz Variante 1, 6000 Ticks, jedes wartende Fahrzeug jeden Tick
	var sim = DanielLauf.build_normal(1)
	var b8 := 0
	var bad := 0
	var empty := 0
	var meld := 0
	var first_bad := ""
	for t in range(6000):
		sim.step()
		for vid in sim.vehicles:
			var vv: Dictionary = sim.vehicles[vid]
			if vv["state"] != SimWorld.VState.WARTET_BLOCK and vv["state"] != SimWorld.VState.WARTET_LADUNG:
				continue
			var unsafe: bool = DanielLauf.b8_unsafe(sim, vid)
			var cc: Dictionary = sim.get_wait_chain(vid)
			if cc.is_empty():
				empty += 1
				continue
			var e: Array = Diagnostics.validate(cc)
			if not e.is_empty():
				bad += 1
				if first_bad == "":
					first_bad = "Tick %d Fz %d %s" % [sim.tick_count, vid, str(e)]
			if unsafe:
				b8 += 1
			# Meldungsregel Datenvertrag 3a: Deadlock sofort, Ladung erst ab wait_ticks >= 600
			if cc["is_deadlock"] or (cc["root_cause"] == "WARTEN_AUF_LADUNG" and cc["wait_ticks"] >= 600):
				meld += 1
	print("    Daniel Normalnetz V1, 6000 Ticks: B8-Abfragen %d, leere Ketten %d, ungültige %d, meldungsfähige Ursachen %d" % [b8, empty, bad, meld])
	check(b8 >= 80, "B8-Situationen im Replay reproduziert (%d Fahrzeug-Abfragen, Daniel: 80 Ticks)" % b8)
	check(empty == 0 and bad == 0, "keine leere und keine ungültige Kette (%s)" % first_bad)
	check(meld == 0, "Normalbetrieb: keine Meldung nach Regel 3a (Deadlock oder Ladung >= 600 Ticks) (%d)" % meld)
	var sim3 = DanielLauf.build_normal(1)
	sim3.run_ticks(3451)
	var c3: Dictionary = sim3.get_wait_chain(1)
	check(c3.has("links") and Diagnostics.validate(c3).is_empty() and c3["root_obj"]["id"] == 3,
		"Daniels Fall Tick 3451, Fahrzeug 1: gültige Kette, Ursache-Objekt Block 3")


## F-06 Testwelt: drei Fehler + Kontrolle in einer SimWorld (Datenseite der Testszene).
func test_k6_f06_welt() -> void:
	print("K6 F-06 Testwelt (Datenseite): 3 Fehler nach Vorlauf, Kontrollzüge ohne Meldung")
	var w = F06World.new()
	w.build()
	w.vorlauf()
	for key in ["F1", "F2", "F3"]:
		var vid: int = F06World.FEHLER[key]["vehicle"]
		var c: Dictionary = w.sim.get_wait_chain(vid)
		var rows: Array = w.rows_for(c)
		check(c["root_cause"] == F06World.FEHLER[key]["code"], "%s Zug %d Ursache %s (%s)" % [key, vid, F06World.FEHLER[key]["code"], c["root_cause"]])
		check(Diagnostics.validate(c).is_empty(), "%s Validator gültig" % key)
		check(rows.size() == F06World.FEHLER[key]["zeilen"], "%s Zeilen %d (Soll %d)" % [key, rows.size(), F06World.FEHLER[key]["zeilen"]])
		check(c["wait_ticks"] >= 1200, "%s steht beim Start >= 120 s (%d Ticks)" % [key, c["wait_ticks"]])
	var kont_ok := true
	for t in range(3000):
		w.sim.step()
		for vid in F06World.KONTROLLE:
			var cc: Dictionary = w.sim.get_wait_chain(vid)
			if cc["root_cause"] != "KEINE" and cc["root_cause"] != "BLOCK_BELEGT_UNTERWEGS":
				kont_ok = false
	check(kont_ok and w.sim.deadlock_events.size() == 2, "3000 Ticks: Kontrollzüge ohne Meldung, genau 2 Deadlocks (F1, F2) (%d)" % w.sim.deadlock_events.size())
	check(w.sim.get_wait_chain(F06World.FEHLER["F3"]["vehicle"])["root_cause"] == "WARTEN_AUF_LADUNG", "F3 besteht nach Vorlauf + 3000 Ticks noch")


# =====================================================================================  Sprint 3

## K7 (F-11, Entscheidung 27.11. Punkt 3): Wende-Deadlock, 10 Fälle. Je Fall: genau ein Ereignis mit den
## beiden Pendlern, Code DEADLOCK, Erkennung <= 50 Ticks nach Bildung und genau DEADLOCK_CONFIRM_TICKS nach
## dem ersten Tick, in dem der Vollscan den Zyklus sieht; Ketten beider Pendler gültig, gleicher Ort;
## Spike-Kern liefert dieselben Ereignisse.
func test_k7_wende_deadlock() -> void:
	print("K7 Wende-Deadlock (zwei Pendler auf derselben Strecke), %d Fälle" % Scenarios.WENDE_FAELLE)
	var erkannt := 0
	for f in range(1, Scenarios.WENDE_FAELLE + 1):
		var sim = Scenarios.wende_deadlock(f)
		var ref = RefScenarios.wende_deadlock(f)
		var oracle_tick := -1
		while sim.tick_count < 3000 and sim.deadlock_events.is_empty():
			sim.step()
			ref.step()
			if oracle_tick < 0 and not sim.find_wait_cycles_full().is_empty():
				oracle_tick = sim.tick_count
		var why: Array = []
		var ev: Dictionary = sim.deadlock_events[0] if sim.deadlock_events.size() == 1 else {}
		if ev.is_empty():
			why.append("Ereignisse %d" % sim.deadlock_events.size())
		else:
			if ev["members"] != [1, 2]:
				why.append("Mitglieder %s" % str(ev["members"]))
			if ev["root_cause"] != "DEADLOCK":
				why.append("Code %s" % ev["root_cause"])
			if ev["ticks_to_detect"] > MAX_DETECT_TICKS:
				why.append("Erkennung %d Ticks" % ev["ticks_to_detect"])
			if ev["tick_detected"] - oracle_tick + 1 != SimWorld.DEADLOCK_CONFIRM_TICKS:
				why.append("erkannt Tick %d, Vollscan ab Tick %d" % [ev["tick_detected"], oracle_tick])
			var c1: Dictionary = sim.get_wait_chain(1)
			var c2: Dictionary = sim.get_wait_chain(2)
			for c in [c1, c2]:
				if c["root_cause"] != "DEADLOCK" or not c["is_deadlock"] or not c["in_cycle"]:
					why.append("Kette Fz %d: %s" % [c["vehicle_id"], c["root_cause"]])
				if not Diagnostics.validate(c).is_empty():
					why.append("Validator Fz %d: %s" % [c["vehicle_id"], str(Diagnostics.validate(c))])
			if c1["root_pos"] != c2["root_pos"] or c1["root_obj"] != c2["root_obj"]:
				why.append("Ort ungleich")
			if f == 10:
				var c3: Dictionary = sim.get_wait_chain(3)
				if not c3["is_deadlock"] or c3["in_cycle"] or c3["root_pos"] != c1["root_pos"] or not Diagnostics.validate(c3).is_empty():
					why.append("Auffahrer: is_deadlock %s in_cycle %s" % [c3["is_deadlock"], c3["in_cycle"]])
			if JSON.stringify(ref.deadlock_events) != JSON.stringify(sim.deadlock_events) or ref.checksum() != sim.checksum():
				why.append("Spike-Kern abweichend")
		if why.is_empty():
			erkannt += 1
		print("    Fall %2d: %s%s" % [f, ("gebildet Tick %d, erkannt Tick %d (%d Ticks), Code %s, Ort %s" % [ev["tick_formed"], ev["tick_detected"],
			ev["ticks_to_detect"], ev["root_cause"], str(sim.get_wait_chain(1)["root_pos"])]) if not ev.is_empty() else "", "" if why.is_empty() else "  FEHLER " + str(why)])
	check(erkannt == Scenarios.WENDE_FAELLE, "Wende-Deadlock als DEADLOCK erkannt in %d von %d Fällen" % [erkannt, Scenarios.WENDE_FAELLE])
	# Gegenprobe: ein einzelner Pendler auf derselben Strecke wendet 3000 Ticks ohne Meldung
	var s = SimWorld.new()
	s.graph.add_node(0, Vector2i(0, 0), "A")
	s.graph.add_node(1, Vector2i(Scenarios.SEG, 0), "B")
	s.graph.add_edge(1, 0, 1, false)
	s.add_vehicle(1, "Pendler 1", [{"edge": 1, "fwd": true}], Scenarios.SPEED, 0, [], 10, true)
	s.run_ticks(3000)
	check(s.deadlock_events.is_empty() and s.vehicle(1)["runs"] >= 50, "Gegenprobe: ein Pendler allein, 3000 Ticks, 0 Meldungen, %d Wenden" % s.vehicle(1)["runs"])


## K8: Äquivalenz SoA-Kern = Spike-Kern (res://ref/, unverändert) und ereignisgesteuerte Prüfung = Vollscan.
## Je Szenario: Prüfsumme in jedem Tick gleich, am Ende deadlock_events gleich; alle 250 Ticks und am Ende
## get_wait_chain aller wartenden Fahrzeuge gleich (var_to_str). In jedem Tick: aktive Zyklen der
## Ereignisprüfung == Zyklen des Vollscans.
func test_k8_aequivalenz_und_ereignis() -> void:
	print("K8 Äquivalenz SoA-Kern = Spike-Kern, Ereignisprüfung = Vollscan")
	var cases: Array = [
		["S1", func(): return Scenarios.gegenverkehr_eingleisig(), func(): return RefScenarios.gegenverkehr_eingleisig(), 400],
		["S2", func(): return Scenarios.deadlock_kreis(), func(): return RefScenarios.deadlock_kreis(), 400],
		["S3", func(): return Scenarios.warten_auf_ladung(0), func(): return RefScenarios.warten_auf_ladung(0), 1300],
		["S3 Prod", func(): return Scenarios.warten_auf_ladung(10, 4), func(): return RefScenarios.warten_auf_ladung(10, 4), 600],
		["S3 8 Lkw", func(): return Scenarios.warten_auf_ladung(0, 1, 8), func(): return RefScenarios.warten_auf_ladung(0, 1, 8), 1300],
		["S1b", func(): return Scenarios.gegenverkehr_auffahrer(), func(): return RefScenarios.gegenverkehr_auffahrer(), 500],
		["S2b Ring6", func(): return Scenarios.deadlock_ring(6), func(): return RefScenarios.deadlock_ring(6), 600],
		["K1", func(): return Scenarios.kontrolle_ausweichgleis(), func(): return RefScenarios.kontrolle_ausweichgleis(), 6000],
		["Daniel N1", func(): return DanielLauf.build_normal(1), func(): return RefDaniel.build_normal(1), 6000],
		["Daniel N2", func(): return DanielLauf.build_normal(2), func(): return RefDaniel.build_normal(2), 6000],
		["Daniel N3", func(): return DanielLauf.build_normal(3), func(): return RefDaniel.build_normal(3), 6000],
		["F06-Welt", func(): var w = F06World.new(); w.build(); return w.sim, func(): var w = RefF06World.new(); w.build(); return w.sim, 4300],
	]
	for f in range(1, Scenarios.WENDE_FAELLE + 1):
		cases.append(["Wende %d" % f, func(): return Scenarios.wende_deadlock(f), func(): return RefScenarios.wende_deadlock(f), 800])
	var all_eq := true
	var all_ev := true
	var total_ticks := 0
	for cs in cases:
		var sim = cs[1].call()
		var ref = cs[2].call()
		var eq: bool = sim.checksum() == ref.checksum()
		var ev_ok := true
		var chains_ok := true
		var first_diff := ""
		for t in range(int(cs[3])):
			sim.step()
			ref.step()
			if sim.checksum() != ref.checksum():
				if eq:
					first_diff = "Prüfsumme Tick %d" % sim.tick_count
				eq = false
			if JSON.stringify(sim.active_cycles()) != JSON.stringify(sim.find_wait_cycles_full()):
				if ev_ok:
					first_diff += " Zyklen Tick %d: %s vs %s" % [sim.tick_count, str(sim.active_cycles()), str(sim.find_wait_cycles_full())]
				ev_ok = false
			if sim.tick_count % 250 == 0 or t == int(cs[3]) - 1:
				for vid in ref.sorted_ids():
					var st: int = ref.vehicles[vid]["state"]
					if st == 2 or st == 3:
						if var_to_str(sim.get_wait_chain(vid)) != var_to_str(ref.get_wait_chain(vid)):
							if chains_ok:
								first_diff += " Kette Fz %d Tick %d" % [vid, sim.tick_count]
							chains_ok = false
		total_ticks += int(cs[3])
		var evs_same: bool = JSON.stringify(sim.deadlock_events) == JSON.stringify(ref.deadlock_events)
		var ok: bool = eq and evs_same and chains_ok
		all_eq = all_eq and ok
		all_ev = all_ev and ev_ok
		if not (ok and ev_ok):
			print("    %s: ABWEICHUNG %s (Ereignisse gleich %s)" % [cs[0], first_diff, evs_same])
		else:
			print("    %s: %d Ticks gleich, Ereignisse %d, End-Prüfsumme %d" % [cs[0], cs[3], sim.deadlock_events.size(), sim.checksum()])
	# Bench-Welt 1k (Generator bench_world.gd), 1500 Ticks, Prüfsumme alle 10 Ticks
	var bw = BenchWorld.new().build(1000, 2001)["sim"]
	var rw = RefBenchWorld.new().build(1000, 2001)["sim"]
	var beq := true
	var bev := true
	for t in range(1500):
		bw.step()
		rw.step()
		if bw.tick_count % 10 == 0 and bw.checksum() != rw.checksum():
			beq = false
		if JSON.stringify(bw.active_cycles()) != JSON.stringify(bw.find_wait_cycles_full()):
			bev = false
	beq = beq and JSON.stringify(bw.deadlock_events) == JSON.stringify(rw.deadlock_events)
	print("    Bench-Welt 1k (Seed 2001), 1500 Ticks: Prüfsumme %s, Ereignisse %d/%d, End-Prüfsumme %d" % [
		"gleich" if beq else "ABWEICHEND", bw.deadlock_events.size(), rw.deadlock_events.size(), bw.checksum()])
	check(all_eq and beq, "SoA-Kern = Spike-Kern in %d Szenarien (%d Ticks) + Bench 1k: Prüfsumme je Tick, Ereignisse, Ketten" % [cases.size(), total_ticks])
	check(all_ev and bev, "ereignisgesteuerte Deadlock-Prüfung = Vollscan in jedem Tick (alle Szenarien + Bench 1k)")


## K10: Determinismus Bench-Welt (Seed 1001+n wie F-05), 3 Läufe à 300 + 3000 Ticks, gleiche Prüfsumme.
func test_k10_determinismus_bench() -> void:
	print("K10 Determinismus Bench-Welt 1k, 3 Läufe à 3300 Ticks")
	var sums: Array = []
	for r in range(3):
		var sim = BenchWorld.new().build(1000, 1001 + 1000)["sim"]
		sim.run_ticks(3300)
		sums.append(sim.checksum())
	print("    Prüfsummen: %s" % str(sums))
	check(sums[0] == sums[1] and sums[1] == sums[2], "3 Läufe, identische Prüfsumme")
