extends SceneTree
## D-04 Deadlock-Pruefung (Daniel Richter, QA), Tag 4-6, nach Beschluss D3/G3/G4.
## Laeuft gegen eine KOPIE von Felix' Spike (Tag-1-3-Stand, md5 in d04_protokoll.md).
## Aufruf: godot --headless --path <kopie> --script res://daniel_d04_lauf.gd -- <ausgabeordner>
##
## 6 Szenarien x 3 Varianten (keine Seeds: die Sim hat keinen PRNG, Varianten = andere Startpositionen,
## Start-Offsets, ID-Reihenfolge). Jeder Lauf wird zweimal ausgefuehrt (Wiederholung, G4).
## Prueft je Lauf: Typ (Ursache-Code), Objekt (Zyklusmitglieder bzw. Lagerknoten), Ort (root_pos auf
## einem umkaempften Block und <= 2 Felder = 200 m vom anfragenden Fahrzeug), kanonischer Ort nach D9
## (root_pos == kette[-1].pos). Dazu Fehlalarm-Test: eigenes Normalnetz, 3 Varianten x 6000 Ticks.
## Orakel fuer Tick_Eintritt: groesster Fixpunkt wartender Fahrzeuge (eigene Implementierung).

const SimWorld := preload("res://sim_world.gd")
const Scenarios := preload("res://scenarios.gd")

const SEG := 200000
const SPEED := 4000
const FELD := 100000           # Annahme A5: 1 Feld = 100 m, Toleranz 2 Felder
const MAXT := 600
const NORMAL_TICKS := 6000

var csv: Array = []
var fails := 0
var out_dir := ""


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else "."
	print("== D-04 Lauf (Daniel), Godot %s, %d vCPU ==" % [Engine.get_version_info()["string"], OS.get_processor_count()])
	csv.append("szenario;variante;wiederholung;beschreibung;ereignisse;tick_eintritt_orakel;tick_formed_sim;tick_erkannt;typ_erwartet;typ_ist;typ_ok;objekt_erwartet;objekt_ist;objekt_ok;root_pos;ort_ok;kanonisch_D9;kette_glieder;ergebnis;bemerkung")
	var specs := scenario_specs()
	for sp in specs:
		for rep in [1, 2]:
			run_scenario(sp, rep)
	for variant in [1, 2, 3]:
		for rep in [1, 2]:
			run_normal(variant, rep)
	var f := FileAccess.open(out_dir.path_join("d04_protokoll.csv"), FileAccess.WRITE)
	for line in csv:
		f.store_line(line)
	f.close()
	print("== ENDE, Fehlschlaege: %d, CSV: %s ==" % [fails, out_dir.path_join("d04_protokoll.csv")])
	quit(0)


# ---------------------------------------------------------------- Szenarien

func line(s, n: int, id0: int = 0, single: bool = true, y: int = 0) -> void:
	for i in range(n):
		s.graph.add_node(id0 + i, Vector2i(i * SEG, y), "N%d" % (id0 + i))
	for i in range(n - 1):
		s.graph.add_edge(id0 + i + 1, id0 + i, id0 + i + 1, single)


func ring(s, n: int, id0: int = 0, eid0: int = 0, cx: int = 0) -> void:
	for i in range(n):
		var a := TAU * i / n
		s.graph.add_node(id0 + i, Vector2i(cx + int(cos(a) * SEG), int(sin(a) * SEG)), "R%d" % (id0 + i))
	for i in range(n):
		s.graph.add_edge(eid0 + i + 1, id0 + i, id0 + (i + 1) % n)


func ring_trains(s, n: int, id0: int, vid0: int, offsets: Array, rotate: int, reverse_ids: bool) -> Array:
	var members: Array = []
	for i in range(n):
		var start := (i + rotate) % n
		var vid := vid0 + (n - 1 - i if reverse_ids else i)
		s.add_vehicle(vid, "Zug %d" % vid, s.graph.route_from_nodes([id0 + start, id0 + (start + 1) % n, id0 + (start + 2) % n]), SPEED, offsets[i])
		members.append(vid)
	members.sort()
	return members


## Spezifikation: {id, variante, beschreibung, build: Callable -> SimWorld, erwartet: Dictionary}
func scenario_specs() -> Array:
	var specs: Array = []
	# S1 Gegenverkehr eingleisig (F-04 S1)
	specs.append({"id": "S1", "v": 1, "desc": "F-04 S1 Original: A-D, Zug 1 A->D, Zug 2 D->A, Offsets 0/0",
		"build": func():
			var s = Scenarios.gegenverkehr_eingleisig()
			return s,
		"typ": "EINGLEISIG_GEGENVERKEHR", "objekt": [1, 2], "anfrage": 1, "lager": -1})
	specs.append({"id": "S1", "v": 2, "desc": "Offsets 15/0 (Zug 2 faehrt frueher, Treffpunkt verschoben)",
		"build": func():
			var s = SimWorld.new()
			line(s, 4)
			s.add_vehicle(1, "Zug 1", s.graph.find_path(0, 3), SPEED, 15)
			s.add_vehicle(2, "Zug 2", s.graph.find_path(3, 0), SPEED, 0)
			return s,
		"typ": "EINGLEISIG_GEGENVERKEHR", "objekt": [1, 2], "anfrage": 2, "lager": -1})
	specs.append({"id": "S1", "v": 3, "desc": "5 Knoten, Zug 1 startet bei N1 (nicht am Ende), IDs vertauscht (Zug 2 = id 1)",
		"build": func():
			var s = SimWorld.new()
			line(s, 5)
			s.add_vehicle(1, "Zug 2", s.graph.find_path(4, 0), SPEED, 0)
			s.add_vehicle(2, "Zug 1", s.graph.find_path(1, 4), SPEED, 0)
			return s,
		"typ": "EINGLEISIG_GEGENVERKEHR", "objekt": [1, 2], "anfrage": 2, "lager": -1})
	# S2 Deadlock-Kreis 4 Zuege (F-04 S2)
	specs.append({"id": "S2", "v": 1, "desc": "F-04 S2 Original: Quadrat, 4 Zuege, Offsets 0",
		"build": func():
			return Scenarios.deadlock_kreis(),
		"typ": "DEADLOCK", "objekt": [0, 1, 2, 3], "anfrage": 0, "lager": -1})
	specs.append({"id": "S2", "v": 2, "desc": "Ring 4, Offsets 0/7/14/21 (gestaffelter Start)",
		"build": func():
			var s = SimWorld.new()
			ring(s, 4)
			ring_trains(s, 4, 0, 0, [0, 7, 14, 21], 0, false)
			return s,
		"typ": "DEADLOCK", "objekt": [0, 1, 2, 3], "anfrage": 3, "lager": -1})
	specs.append({"id": "S2", "v": 3, "desc": "Ring 4, Startknoten um 2 rotiert, IDs rueckwaerts vergeben",
		"build": func():
			var s = SimWorld.new()
			ring(s, 4)
			ring_trains(s, 4, 0, 10, [5, 5, 0, 0], 2, true)
			return s,
		"typ": "DEADLOCK", "objekt": [10, 11, 12, 13], "anfrage": 12, "lager": -1})
	# S3 Warten auf Ladung (F-04 S3)
	specs.append({"id": "S3", "v": 1, "desc": "F-04 S3 Original: Lager ohne Nachschub, Lkw 2 hinter Lkw 1",
		"build": func():
			return Scenarios.warten_auf_ladung(0),
		"typ": "WARTEN_AUF_LADUNG", "objekt": [], "anfrage": 2, "lager": 1})
	specs.append({"id": "S3", "v": 2, "desc": "Nachschub zu langsam (1 Einheit je 100 Ticks, Bedarf 10), Abfrage bei Tick 300",
		"build": func():
			return Scenarios.warten_auf_ladung(100),
		"typ": "WARTEN_AUF_LADUNG", "objekt": [], "anfrage": 2, "lager": 1})
	specs.append({"id": "S3", "v": 3, "desc": "3 Lkw in Kette (Lkw 3 hinter Lkw 2), Abfrage von Lkw 3",
		"build": func():
			var s = Scenarios.warten_auf_ladung(0)
			s.add_vehicle(3, "Lkw 3", s.graph.find_path(0, 2), SPEED, 20, [1])
			return s,
		"typ": "WARTEN_AUF_LADUNG", "objekt": [], "anfrage": 3, "lager": 1})
	# S4 Ring mit 6 Zuegen (D3)
	specs.append({"id": "S4", "v": 1, "desc": "Ring 6 Zuege/6 Bloecke, Offsets 0",
		"build": func():
			var s = SimWorld.new()
			ring(s, 6)
			ring_trains(s, 6, 0, 0, [0, 0, 0, 0, 0, 0], 0, false)
			return s,
		"typ": "DEADLOCK", "objekt": [0, 1, 2, 3, 4, 5], "anfrage": 0, "lager": -1})
	specs.append({"id": "S4", "v": 2, "desc": "Ring 6, Offsets 0/3/6/9/12/15",
		"build": func():
			var s = SimWorld.new()
			ring(s, 6)
			ring_trains(s, 6, 0, 0, [0, 3, 6, 9, 12, 15], 0, false)
			return s,
		"typ": "DEADLOCK", "objekt": [0, 1, 2, 3, 4, 5], "anfrage": 5, "lager": -1})
	specs.append({"id": "S4", "v": 3, "desc": "Ring 6, Startknoten um 3 rotiert, IDs rueckwaerts, Abfrage mittleres Mitglied",
		"build": func():
			var s = SimWorld.new()
			ring(s, 6)
			ring_trains(s, 6, 0, 20, [10, 0, 10, 0, 10, 0], 3, true)
			return s,
		"typ": "DEADLOCK", "objekt": [20, 21, 22, 23, 24, 25], "anfrage": 23, "lager": -1})
	# S5 Gegenverkehr mit Auffahrer (D3)
	specs.append({"id": "S5", "v": 1, "desc": "A-D, Zug 1 A->D, Zug 2 D->A, Zug 3 A->D ab Tick 70 (hinter Zug 1)",
		"build": func():
			var s = SimWorld.new()
			line(s, 4)
			s.add_vehicle(1, "Zug 1", s.graph.find_path(0, 3), SPEED, 0)
			s.add_vehicle(2, "Zug 2", s.graph.find_path(3, 0), SPEED, 0)
			s.add_vehicle(3, "Zug 3", s.graph.find_path(0, 3), SPEED, 70)
			return s,
		"typ": "EINGLEISIG_GEGENVERKEHR", "objekt": [1, 2], "anfrage": 3, "lager": -1})
	specs.append({"id": "S5", "v": 2, "desc": "Auffahrer dicht dran (ab Tick 30), Abfrage vom Auffahrer",
		"build": func():
			var s = SimWorld.new()
			line(s, 4)
			s.add_vehicle(1, "Zug 1", s.graph.find_path(0, 3), SPEED, 0)
			s.add_vehicle(2, "Zug 2", s.graph.find_path(3, 0), SPEED, 0)
			s.add_vehicle(3, "Zug 3", s.graph.find_path(0, 3), SPEED, 30)
			return s,
		"typ": "EINGLEISIG_GEGENVERKEHR", "objekt": [1, 2], "anfrage": 3, "lager": -1})
	specs.append({"id": "S5", "v": 3, "desc": "Auffahrer auf der anderen Seite (hinter Zug 2, D->A ab Tick 60), 5 Knoten",
		"build": func():
			var s = SimWorld.new()
			line(s, 5)
			s.add_vehicle(1, "Zug 1", s.graph.find_path(0, 4), SPEED, 0)
			s.add_vehicle(2, "Zug 2", s.graph.find_path(4, 0), SPEED, 0)
			s.add_vehicle(3, "Zug 3", s.graph.find_path(4, 0), SPEED, 60)
			return s,
		"typ": "EINGLEISIG_GEGENVERKEHR", "objekt": [1, 2], "anfrage": 3, "lager": -1})
	# S6 (Daniels drittes): drei getrennte Teilnetze gleichzeitig + Kontrollzuege (Vorlaeufer der L-06-Testkarte)
	for v in [1, 2, 3]:
		specs.append({"id": "S6", "v": v, "desc": "Teilnetze Gegenverkehr + Ring 4 + Ladung + 2 Kontrollzuege (K1) in EINER Welt, Variante %d" % v,
			"build": func():
				return build_s6(v),
			"typ": "MEHRERE", "objekt": [], "anfrage": -1, "lager": 201})
	return specs


## S6: Knoten 0-3 Gegenverkehr (y=0), 100-103 Ring 4 (x um 1000 m), 200-202 Ladung (y=600 m), 300-303 K1 (y=900 m).
## Variante 1: Reihenfolge wie beschrieben, Offsets 0. Variante 2: Fahrzeug-IDs so, dass Kontrollzuege zuerst
## steppen und Ring-Zuege zuletzt; Offsets gestaffelt. Variante 3: Ring rotiert, Gegenverkehr-Zug startet bei N1.
func build_s6(v: int):
	var s = SimWorld.new()
	# Gegenverkehr
	line(s, 4, 0)
	# Ring
	ring(s, 4, 100, 100, 1000000)
	# Ladung
	for i in range(3):
		s.graph.add_node(200 + i, Vector2i(i * SEG, 600000), "L%d" % i)
	s.graph.add_edge(201, 200, 201)
	s.graph.add_edge(202, 201, 202)
	s.add_station(201, "Lager", 0, 0, 1)
	# K1 Kontrolle (wie Felix, nur verschoben)
	for i in range(4):
		s.graph.add_node(300 + i, Vector2i(i * SEG, 900000), "K%d" % i)
	s.graph.add_edge(301, 300, 301)
	s.graph.add_edge(302, 301, 302)
	s.graph.add_edge(303, 302, 303)
	s.graph.add_edge(305, 301, 302)
	var r1: Array = [{"edge": 301, "fwd": true}, {"edge": 302, "fwd": true}, {"edge": 303, "fwd": true}]
	var r2: Array = [{"edge": 303, "fwd": false}, {"edge": 305, "fwd": false}, {"edge": 301, "fwd": false}]
	match v:
		1:
			s.add_vehicle(1, "Zug 1", s.graph.find_path(0, 3), SPEED, 0)
			s.add_vehicle(2, "Zug 2", s.graph.find_path(3, 0), SPEED, 0)
			ring_trains(s, 4, 100, 10, [0, 0, 0, 0], 0, false)
			s.add_vehicle(21, "Lkw 21", s.graph.find_path(200, 202), SPEED, 0, [201])
			s.add_vehicle(22, "Lkw 22", s.graph.find_path(200, 202), SPEED, 10, [201])
			s.add_vehicle(31, "K-Zug 31", r1, 4000, 0, [], 10, true)
			s.add_vehicle(32, "K-Zug 32", r2, 5000, 0, [], 10, true)
		2:
			s.add_vehicle(1, "K-Zug 1", r1, 4000, 0, [], 10, true)
			s.add_vehicle(2, "K-Zug 2", r2, 5000, 0, [], 10, true)
			s.add_vehicle(11, "Lkw 11", s.graph.find_path(200, 202), SPEED, 5, [201])
			s.add_vehicle(12, "Lkw 12", s.graph.find_path(200, 202), SPEED, 25, [201])
			s.add_vehicle(21, "Zug 21", s.graph.find_path(0, 3), SPEED, 12)
			s.add_vehicle(22, "Zug 22", s.graph.find_path(3, 0), SPEED, 0)
			ring_trains(s, 4, 100, 30, [0, 8, 16, 24], 0, false)
		3:
			s.add_vehicle(1, "Zug 1", s.graph.find_path(1, 3), SPEED, 0)
			s.add_vehicle(2, "Zug 2", s.graph.find_path(3, 0), SPEED, 0)
			ring_trains(s, 4, 100, 10, [3, 3, 3, 3], 1, true)
			s.add_vehicle(21, "Lkw 21", s.graph.find_path(200, 202), SPEED, 0, [201])
			s.add_vehicle(22, "Lkw 22", s.graph.find_path(200, 202), SPEED, 10, [201])
			s.add_vehicle(31, "K-Zug 31", r1, 5000, 0, [], 10, true)
			s.add_vehicle(32, "K-Zug 32", r2, 4000, 0, [], 10, true)
	return s


# ---------------------------------------------------------------- Orakel

func stuck_set(s) -> Array:
	var cand: Array = []
	for id in s.vehicles:
		if s.vehicles[id]["state"] == SimWorld.VState.WARTET_BLOCK:
			cand.append(id)
	var changed := true
	while changed:
		changed = false
		for id in cand.duplicate():
			var h: int = s.graph.blocks[s.vehicles[id]["wait_block"]]["holder"]
			if not cand.has(h):
				cand.erase(id)
				changed = true
	cand.sort()
	return cand


# ---------------------------------------------------------------- Lauf

func run_scenario(sp: Dictionary, rep: int) -> void:
	var sim = sp["build"].call()
	var oracle_tick := -1
	var oracle_set: Array = []
	var ticks: int = 300 if sp["id"] == "S3" else (1000 if sp["id"] == "S6" else MAXT)
	for t in range(ticks):
		sim.step()
		if oracle_tick < 0:
			var st := stuck_set(sim)
			if not st.is_empty():
				oracle_tick = sim.tick_count
				oracle_set = st
	if sp["id"] == "S6":
		eval_s6(sp, rep, sim, oracle_tick, oracle_set)
		return
	var c: Dictionary = sim.get_wait_chain(sp["anfrage"])
	var last: Dictionary = c["links"][c["links"].size() - 1]
	var lastp: Vector2i = last["pos"]
	var rp: Vector2i = c["root_pos"]
	var typ_ok: bool = c["root_cause"] == sp["typ"]
	var obj_ist := ""
	var obj_ok := false
	var ort_ok := false
	var ev_n: int = sim.deadlock_events.size()
	var formed := -1
	var detected := -1
	var bem := ""
	if sp["lager"] >= 0:
		obj_ist = "%s#%d" % [last["kind"], last["id"]]
		obj_ok = last["kind"] == "INDUSTRIE" and int(last["id"]) == sp["lager"]
		ort_ok = rp == sim.graph.nodes[sp["lager"]]["pos"]
		if ev_n != 0:
			bem += "Fehlalarm: %d Deadlock-Ereignis(se) bei Ladungswarten; " % ev_n
		if oracle_tick >= 0:
			bem += "Orakel sieht Stillstand (nicht erwartet); "
	else:
		var cyc: Array = c["cycle"].duplicate()
		cyc.sort()
		obj_ist = str(cyc)
		obj_ok = cyc == sp["objekt"]
		if ev_n == 1:
			formed = int(sim.deadlock_events[0]["tick_formed"])
			detected = int(sim.deadlock_events[0]["tick_detected"])
			var mem: Array = sim.deadlock_events[0]["members"].duplicate()
			mem.sort()
			if mem != sp["objekt"]:
				obj_ok = false
				bem += "Ereignis-Mitglieder %s != erwartet; " % str(mem)
			if formed != oracle_tick:
				bem += "tick_formed %d != Orakel %d; " % [formed, oracle_tick]
		else:
			bem += "erwartet 1 Ereignis, gefunden %d; " % ev_n
			obj_ok = false
		# Ort: root_pos ist Block-Mitte eines umkaempften Blocks (Warteblock eines Zyklusmitglieds)
		# und liegt <= 2 Felder vom anfragenden Fahrzeug (bzw. von einem Mitglied, wenn Anfrager nicht im Kreis)
		var contested: Array = []
		for vid in sp["objekt"]:
			contested.append(sim.graph.blocks[sim.vehicles[vid]["wait_block"]]["center"])
		var ref_ids: Array = [sp["anfrage"]] if c["in_cycle"] else sp["objekt"]
		var near := false
		for vid in ref_ids:
			if Vector2(rp).distance_to(Vector2(sim.vehicle_pos(sim.vehicles[vid]))) <= 2 * FELD:
				near = true
		ort_ok = contested.has(rp) and near
		if sp["id"] == "S5":
			if c["in_cycle"]:
				bem += "Auffahrer faelschlich im Kreis; "
				obj_ok = false
			if not c["is_deadlock"]:
				bem += "Auffahrer: is_deadlock false; "
				typ_ok = false
			var s3: Array = stuck_set(sim)
			if not s3.has(3):
				bem += "Orakel zaehlt Auffahrer nicht als festgefahren; "
	var kanon: bool = rp == lastp
	var result := "OK" if (typ_ok and obj_ok and ort_ok) else "FEHLSCHLAG"
	if result == "FEHLSCHLAG":
		fails += 1
	if not kanon:
		bem += "root_pos %s != kette[-1].pos %s (D9 nicht erfuellt, Build-Stand 18.11.); " % [str(rp), str(lastp)]
	csv.append("%s;%d;%d;%s;%d;%d;%d;%d;%s;%s;%s;%s;%s;%s;%s;%s;%s;%d;%s;%s" % [
		sp["id"], sp["v"], rep, sp["desc"], ev_n, oracle_tick, formed, detected, sp["typ"], c["root_cause"], jn(typ_ok),
		str(sp["objekt"]) if sp["lager"] < 0 else "INDUSTRIE#%d" % sp["lager"], obj_ist, jn(obj_ok),
		"(%d,%d)" % [rp.x, rp.y], jn(ort_ok), jn(kanon), c["links"].size(), result, bem])
	print("%s V%d W%d %s | Typ %s %s | Objekt %s %s | Ort %s %s | kanonisch %s | %s" % [
		sp["id"], sp["v"], rep, result, c["root_cause"], jn(typ_ok), obj_ist, jn(obj_ok), str(rp), jn(ort_ok), jn(kanon), bem])


func eval_s6(sp: Dictionary, rep: int, sim, oracle_tick: int, oracle_set: Array) -> void:
	var bem := ""
	var ok := true
	var ev_n: int = sim.deadlock_events.size()
	var causes: Array = []
	for ev in sim.deadlock_events:
		causes.append("%s%s" % [ev["root_cause"], str(ev["members"])])
	if ev_n != 2:
		ok = false
		bem += "erwartet 2 Ereignisse (Gegenverkehr, Ring), gefunden %d; " % ev_n
	var have_gv := false
	var have_ring := false
	for ev in sim.deadlock_events:
		if ev["root_cause"] == "EINGLEISIG_GEGENVERKEHR" and ev["members"].size() == 2:
			have_gv = true
		if ev["root_cause"] == "DEADLOCK" and ev["members"].size() == 4:
			have_ring = true
	if not (have_gv and have_ring):
		ok = false
		bem += "Typ/Objekt der Ereignisse falsch; "
	# Ladung: hinterer Lkw muss WARTEN_AUF_LADUNG mit Lager 201 liefern
	var lkw_hinten := 22 if sp["v"] != 2 else 12
	var c: Dictionary = sim.get_wait_chain(lkw_hinten)
	var last: Dictionary = c["links"][c["links"].size() - 1]
	if c["root_cause"] != "WARTEN_AUF_LADUNG" or last["kind"] != "INDUSTRIE" or int(last["id"]) != 201:
		ok = false
		bem += "Ladungskette falsch (%s, %s#%d); " % [c["root_cause"], last["kind"], last["id"]]
	# Kontrollzuege fahren weiter
	var k1 := 31 if sp["v"] != 2 else 1
	var k2 := 32 if sp["v"] != 2 else 2
	var runs: int = mini(int(sim.vehicles[k1]["runs"]), int(sim.vehicles[k2]["runs"]))
	if runs < 4:
		ok = false
		bem += "Kontrollzuege stehen (min. Laeufe %d); " % runs
	# Orakel: Stillstandsmenge darf nur die 6 Deadlock-Zuege plus ggf. niemanden sonst enthalten
	var st: Array = stuck_set(sim)
	if st.size() != 6:
		ok = false
		bem += "Orakel-Stillstandsmenge %s (erwartet 6 Zuege); " % str(st)
	# Ort je Ereignis: root_pos der Mitglieder muss im jeweiligen Teilnetz liegen (Gegenverkehr y=0, Ring x~1000 m)
	for ev in sim.deadlock_events:
		for vid in ev["members"]:
			var rp: Vector2i = sim.get_wait_chain(vid)["root_pos"]
			if ev["root_cause"] == "EINGLEISIG_GEGENVERKEHR" and (rp.y != 0 or rp.x > 3 * SEG):
				ok = false
				bem += "Ort Gegenverkehr ausserhalb Teilnetz %s; " % str(rp)
			if ev["root_cause"] == "DEADLOCK" and absi(rp.x - 1000000) > SEG:
				ok = false
				bem += "Ort Ring ausserhalb Teilnetz %s; " % str(rp)
	if not ok:
		fails += 1
	csv.append("%s;%d;%d;%s;%d;%d;;;%s;%s;%s;%s;%s;%s;%s;%s;%s;%d;%s;%s" % [
		sp["id"], sp["v"], rep, sp["desc"], ev_n, oracle_tick, "GEGENVERKEHR+DEADLOCK+LADUNG", " | ".join(PackedStringArray(causes)) + " | " + c["root_cause"],
		jn(have_gv and have_ring and c["root_cause"] == "WARTEN_AUF_LADUNG"), "2 Zyklen (2+4 Zuege), INDUSTRIE#201, Kontrolle faehrt",
		"Orakel %s, Laeufe K %d" % [str(st), runs], jn(st.size() == 6 and runs >= 4), "je Teilnetz", jn(ok), "n/a (Ereignisse ohne pos, Kette pro Zug)", c["links"].size(), "OK" if ok else "FEHLSCHLAG", bem])
	print("S6 V%d W%d %s | Ereignisse %s | Ladung %s | Orakel %s | K-Laeufe %d | %s" % [sp["v"], rep, "OK" if ok else "FEHLSCHLAG", str(causes), c["root_cause"], str(st), runs, bem])


# ---------------------------------------------------------------- Normalnetz (Fehlalarm-Test)

## Eigenes Normalnetz N (nicht Felix' K1), Fassung 2 (Fassung 1 hatte einen ECHTEN Deadlock, siehe d04_protokoll.md):
## Hauptstrecke zweigleisig A-B-C-D (je Richtung ein Block), 3 Zuege pendelnd (gleiche Richtung staut sich harmlos,
## am Ende wird gewendet). Zweigstrecke eingleisig D-E, Ausweichstelle E-F mit 2 Gleisen, eingleisig F-G;
## 2 Zuege gegenlaeufig pendelnd. Eigene Strasse P-Q-R (eingleisig) mit 1 Lkw, laedt bei Q
## (Nachschub 1 Einheit je 30 Ticks, Bedarf 10 -> wartet ~300 Ticks je Besuch, > 50 Ticks, kein Deadlock).
static func build_normal(variant: int):
	var s = SimWorld.new()
	for i in range(4):
		s.graph.add_node(i, Vector2i(i * SEG, 0), "H%d" % i)
	s.graph.add_edge(1, 0, 1, false)
	s.graph.add_edge(2, 1, 2, false)
	s.graph.add_edge(3, 2, 3, false)
	s.graph.add_node(4, Vector2i(3 * SEG, SEG), "E")
	s.graph.add_node(5, Vector2i(3 * SEG, 2 * SEG), "F")
	s.graph.add_node(6, Vector2i(3 * SEG, 3 * SEG), "G")
	s.graph.add_edge(4, 3, 4)       # D-E eingleisig
	s.graph.add_edge(5, 4, 5)       # E-F Gleis 1
	s.graph.add_edge(6, 4, 5)       # E-F Gleis 2
	s.graph.add_edge(7, 5, 6)       # F-G eingleisig
	s.graph.add_node(7, Vector2i(0, -SEG), "P")
	s.graph.add_node(8, Vector2i(SEG, -SEG), "Q")
	s.graph.add_node(9, Vector2i(2 * SEG, -SEG), "R")
	s.graph.add_edge(8, 7, 8)       # Strasse P-Q
	s.graph.add_edge(9, 8, 9)       # Strasse Q-R
	s.add_station(8, "Lager Q", 0, 30, 1)
	var main_speed := [4000, 5000, 3000]
	var off := [0, 20, 40]
	var branch_speed := [4000, 5000]
	match variant:
		2:
			off = [40, 0, 20]
			branch_speed = [5000, 4000]
		3:
			main_speed = [3000, 3000, 5000]
			off = [10, 10, 60]
			branch_speed = [4000, 4000]
	var rmain: Array = [{"edge": 1, "fwd": true}, {"edge": 2, "fwd": true}, {"edge": 3, "fwd": true}]
	for i in range(3):
		var vid := (i + 1) if variant != 3 else (3 - i)
		s.add_vehicle(vid, "Zug %d" % vid, rmain.duplicate(true), main_speed[i], off[i], [], 10, true)
	var rb1: Array = [{"edge": 4, "fwd": true}, {"edge": 5, "fwd": true}, {"edge": 7, "fwd": true}]
	var rb2: Array = [{"edge": 7, "fwd": false}, {"edge": 6, "fwd": false}, {"edge": 4, "fwd": false}]
	s.add_vehicle(4, "Zug 4", rb1, branch_speed[0], 0, [], 10, true)
	s.add_vehicle(5, "Zug 5", rb2, branch_speed[1], 0 if variant != 2 else 30, [], 10, true)
	var rl: Array = [{"edge": 8, "fwd": true}, {"edge": 9, "fwd": true}]
	s.add_vehicle(6, "Lkw 6", rl, 4000, 0 if variant != 3 else 25, [8], 10, true)
	return s


func run_normal(variant: int, rep: int) -> void:
	var sim = build_normal(variant)
	var oracle_ticks := 0
	var wait_vticks := 0
	var longest_wait := 0
	var cur_wait: Dictionary = {}
	var type_counts: Dictionary = {}
	var b8_hits: Array = []
	for t in range(NORMAL_TICKS):
		sim.step()
		if not stuck_set(sim).is_empty():
			oracle_ticks += 1
		for id in sim.vehicles:
			var v: Dictionary = sim.vehicles[id]
			if v["state"] == SimWorld.VState.WARTET_BLOCK or v["state"] == SimWorld.VState.WARTET_LADUNG:
				wait_vticks += 1
				cur_wait[id] = int(cur_wait.get(id, 0)) + 1
				longest_wait = maxi(longest_wait, int(cur_wait[id]))
			else:
				cur_wait[id] = 0
		if t % 50 == 0:
			for id in sim.vehicles:
				var v: Dictionary = sim.vehicles[id]
				if v["state"] == SimWorld.VState.WARTET_BLOCK and b8_unsafe(sim, id):
					# Befund B8: Fahrzeug wartet laut Zustand, Block ist aber schon frei (Halter hat ihn im selben Tick
					# freigegeben). get_wait_chain() stuerzt hier ab (sim.vehicles[-1]). Nicht aufrufen, zaehlen.
					b8_hits.append("Tick %d Fahrzeug %d" % [sim.tick_count, id])
					type_counts["B8_WARTET_AUF_FREIEN_BLOCK"] = int(type_counts.get("B8_WARTET_AUF_FREIEN_BLOCK", 0)) + 1
				elif v["state"] == SimWorld.VState.WARTET_BLOCK or v["state"] == SimWorld.VState.WARTET_LADUNG:
					var rc: String = sim.get_wait_chain(id)["root_cause"]
					type_counts[rc] = int(type_counts.get(rc, 0)) + 1
	var runs: Array = []
	for id in [1, 2, 3, 4, 5, 6]:
		runs.append(int(sim.vehicles[id]["runs"]))
	var ev_n: int = sim.deadlock_events.size()
	var ok: bool = ev_n == 0 and oracle_ticks == 0 and runs.min() >= 3 and longest_wait > 50
	var bem := "Warte-Fahrzeug-Ticks %d, laengste Wartephase %d Ticks, Orakel-Stillstand-Ticks %d, Laeufe je Fahrzeug %s, Kettentypen bei Stichproben alle 50 Ticks %s" % [
		wait_vticks, longest_wait, oracle_ticks, str(runs), str(type_counts)]
	if ev_n > 0:
		bem = "FEHLALARM? %d Ereignis(se), Orakel-Stillstand-Ticks %d; " % [ev_n, oracle_ticks] + bem
	if runs.min() < 3:
		bem = "ein Fahrzeug faehrt kaum (Netz steht?); " + bem
	if not b8_hits.is_empty():
		bem += "; B8 (get_wait_chain wuerde abstuerzen, Halter -1) bei Stichproben: %s" % ", ".join(PackedStringArray(b8_hits))
	if not ok:
		fails += 1
	csv.append("N;%d;%d;Normalnetz Daniel, 6000 Ticks (10 min), Variante %d;%d;;;;KEINE Deadlock-Meldung;%d Ereignisse;%s;;;;;;;;%s;%s" % [
		variant, rep, variant, ev_n, ev_n, jn(ev_n == 0), "OK" if ok else "FEHLSCHLAG", bem])
	print("N V%d W%d %s | Ereignisse %d | %s" % [variant, rep, "OK" if ok else "FEHLSCHLAG", ev_n, bem])


## Befund B8: Entlang der Warte-Kette steht ein Fahrzeug im Zustand WARTET_BLOCK, dessen Warteblock
## in diesem Tick schon frei ist (Halter -1). get_wait_chain() greift dann auf sim.vehicles[-1] zu und stuerzt ab.
static func b8_unsafe(sim, id: int) -> bool:
	var visited: Array = []
	var cur := id
	while not visited.has(cur):
		visited.append(cur)
		var v: Dictionary = sim.vehicles[cur]
		if v["state"] != SimWorld.VState.WARTET_BLOCK:
			return false
		var h: int = int(sim.graph.blocks[v["wait_block"]]["holder"])
		if h == -1:
			return true
		cur = h
	return false


func jn(b: bool) -> String:
	return "ja" if b else "nein"
