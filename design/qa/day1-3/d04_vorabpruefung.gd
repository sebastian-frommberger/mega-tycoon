extends SceneTree
## Daniel Richter (QA): Vorabprüfung des F-04-Spikes für D-04. KEINE D-04-Messung (siehe d04_prueffplan.md).
## Aufruf (im Ordner einer KOPIE von felix/spike, damit Felix' Ordner unverändert bleibt):
##   godot --headless --path <kopie> --script res://d04_vorabpruefung.gd
## Die Sim hat keinen PRNG. Der "Seed" ist hier ein RandomNumberGenerator in DIESEM Skript und
## bestimmt nur die Startzeit-Offsets (0..20 Ticks) der Züge. Topologie bleibt fest.
## Unabhängiges Orakel: Tick_Eintritt = erster Tick, in dem eine nichtleere Menge wartender Fahrzeuge
## existiert, deren Blockhalter alle in der Menge liegen (größter Fixpunkt, eigene Implementierung,
## nutzt nicht find_wait_cycles der Sim).

const SimWorld := preload("res://sim_world.gd")
const Diagnostics := preload("res://diagnostics.gd")
const Scenarios := preload("res://scenarios.gd")

const SEG := 200000
const SPEED := 4000
const SEEDS := [101, 202, 303]
const MAXT := 400

var fails := 0


func _init() -> void:
	print("== D-04 Vorabpruefung (Daniel), Godot %s ==" % Engine.get_version_info()["string"])
	for s in SEEDS:
		run_case("A  Gegenverkehr eingleisig (wie F-04 S1) + Offsets", s, "gegen", true, "EINGLEISIG_GEGENVERKEHR")
	for s in SEEDS:
		run_case("B  Ring 4 Zuege/4 Bloecke (wie F-04 S2) + Offsets", s, "ring4", true, "DEADLOCK")
	for s in SEEDS:
		run_case("B2 Ring 6 Zuege/6 Bloecke + Offsets", s, "ring6", true, "DEADLOCK")
	for s in SEEDS:
		run_case("C  Ring 4 Bloecke, nur 3 Zuege (kein Deadlock erwartet)", s, "ring4_leer", false, "")
	for s in SEEDS:
		run_case("D  Gegenverkehr auf DOPPELGLEIS (kein Deadlock erwartet)", s, "doppel", false, "")
	for s in SEEDS:
		run_case("E  Gegenverkehr + dritter Zug dahinter", s, "auffahrer", true, "EINGLEISIG_GEGENVERKEHR")
	for s in SEEDS:
		run_normal(s)
	run_failure_modes()
	print("== ENDE, Auffaelligkeiten markiert mit [!] : %d ==" % fails)
	quit(0)


func offsets(seed: int, n: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var o: Array = []
	for i in range(n):
		o.append(rng.randi_range(0, 20))
	return o


func build(kind: String, seed: int):
	var s = SimWorld.new()
	match kind:
		"gegen":
			var o := offsets(seed, 2)
			for i in range(4):
				s.graph.add_node(i, Vector2i(i * SEG, 0), "N%d" % i)
			for i in range(3):
				s.graph.add_edge(i + 1, i, i + 1)
			s.add_vehicle(1, "Zug 1", s.graph.find_path(0, 3), SPEED, o[0])
			s.add_vehicle(2, "Zug 2", s.graph.find_path(3, 0), SPEED, o[1])
		"auffahrer":
			var o := offsets(seed, 2)
			for i in range(4):
				s.graph.add_node(i, Vector2i(i * SEG, 0), "N%d" % i)
			for i in range(3):
				s.graph.add_edge(i + 1, i, i + 1)
			s.add_vehicle(1, "Zug 1", s.graph.find_path(0, 3), SPEED, o[0])
			s.add_vehicle(2, "Zug 2", s.graph.find_path(3, 0), SPEED, o[1])
			s.add_vehicle(3, "Zug 3", s.graph.find_path(0, 3), SPEED, 70)
		"doppel":
			var o := offsets(seed, 2)
			for i in range(4):
				s.graph.add_node(i, Vector2i(i * SEG, 0), "N%d" % i)
			for i in range(3):
				s.graph.add_edge(i + 1, i, i + 1, false)
			s.add_vehicle(1, "Zug 1", s.graph.find_path(0, 3), SPEED, o[0])
			s.add_vehicle(2, "Zug 2", s.graph.find_path(3, 0), SPEED, o[1])
		"ring4", "ring4_leer", "ring6":
			var n := 6 if kind == "ring6" else 4
			var trains := 3 if kind == "ring4_leer" else n
			var pts := []
			for i in range(n):
				var a := TAU * i / n
				pts.append(Vector2i(int(cos(a) * SEG), int(sin(a) * SEG)))
				s.graph.add_node(i, pts[i], "N%d" % i)
			for i in range(n):
				s.graph.add_edge(i + 1, i, (i + 1) % n)
			var o := offsets(seed, trains)
			for i in range(trains):
				s.add_vehicle(i, "Zug %d" % i, s.graph.route_from_nodes([i, (i + 1) % n, (i + 2) % n]), SPEED, o[i])
	return s


## Orakel: größter Fixpunkt der Menge wartender Fahrzeuge (siehe Kopfkommentar).
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


func run_case(title: String, seed: int, kind: String, expect_dead: bool, expect_cause: String) -> void:
	var sim = build(kind, seed)
	var oracle_tick := -1
	var oracle_set: Array = []
	for t in range(MAXT):
		sim.step()
		if oracle_tick < 0:
			var st := stuck_set(sim)
			if not st.is_empty():
				oracle_tick = sim.tick_count
				oracle_set = st
	var ended := 0
	for id in sim.vehicles:
		if sim.vehicles[id]["state"] == SimWorld.VState.ENDE:
			ended += 1
	var line := "%s | seed %d | offsets %s" % [title, seed, str(offsets(seed, sim.vehicles.size()))]
	print(line)
	var ev_n: int = sim.deadlock_events.size()
	if expect_dead:
		if ev_n != 1:
			flag("erwartet 1 Deadlock-Ereignis, gefunden %d" % ev_n)
			return
		var ev: Dictionary = sim.deadlock_events[0]
		var d_orakel: int = int(ev["tick_detected"]) - oracle_tick
		print("   Orakel: Eintritt Tick %d, Menge %s | Sim: gebildet %d, erkannt %d, Ticks (Sim-Definition) %d, Ticks ab Orakel %d | Mitglieder %s" % [
			oracle_tick, str(oracle_set), ev["tick_formed"], ev["tick_detected"], ev["ticks_to_detect"], d_orakel, str(ev["members"])])
		if d_orakel > 50:
			flag("Erkennung > 50 Ticks ab Orakel")
		if int(ev["tick_formed"]) != oracle_tick:
			flag("Sim tick_formed (%d) != Orakel-Eintritt (%d)" % [ev["tick_formed"], oracle_tick])
		var roots := {}
		for vid in ev["members"]:
			var c: Dictionary = sim.get_wait_chain(vid)
			roots[str(c["root_pos"])] = true
			var last: Dictionary = c["links"][c["links"].size() - 1]
			var lastp: Vector2i = last["pos"]
			print("   Zug %d: Ursache %s root_pos %s, letztes Glied %s#%d @%s, Kette %d Glieder, wartet %d Ticks" % [
				vid, c["root_cause"], str(c["root_pos"]), last["kind"], last["id"], str(lastp), c["links"].size(), c["wait_ticks"]])
			if c["root_cause"] != expect_cause:
				flag("Zug %d: Ursache %s statt %s" % [vid, c["root_cause"], expect_cause])
			if lastp != c["root_pos"]:
				note("Zug %d: root_pos %s weicht vom Ort des letzten Kettenglieds %s ab" % [vid, str(c["root_pos"]), str(lastp)])
		if roots.size() > 1:
			note("Mitglieder desselben Deadlocks liefern %d verschiedene root_pos: %s" % [roots.size(), str(roots.keys())])
		if kind == "auffahrer":
			var c3: Dictionary = sim.get_wait_chain(3)
			print("   Zug 3 (nicht im Kreis): Zustand %d, in_cycle %s, is_deadlock %s, Ursache %s, root_pos %s, Kette %d Glieder" % [
				sim.vehicles[3]["state"], str(c3["in_cycle"]), str(c3["is_deadlock"]), c3["root_cause"], str(c3["root_pos"]), c3["links"].size()])
			if c3["in_cycle"]:
				flag("Zug 3 faelschlich als Kreismitglied")
			if c3["root_cause"] != expect_cause:
				flag("Zug 3: Ursache %s statt %s" % [c3["root_cause"], expect_cause])
	else:
		print("   Ereignisse %d, Orakel-Menge %s, Zuege am Ende (ENDE) %d von %d" % [ev_n, str(oracle_set), ended, sim.vehicles.size()])
		if ev_n != 0:
			flag("Fehlalarm: %d Ereignis(se) ohne Deadlock" % ev_n)
		if not oracle_set.is_empty():
			flag("Orakel sieht Stillstand, Sim meldet %d" % ev_n)
		if ended != sim.vehicles.size():
			flag("nicht alle Zuege am Ziel nach %d Ticks" % MAXT)
	# Determinismus: zweiter Lauf, gleiche Ereignisse
	var sim2 = build(kind, seed)
	for t in range(MAXT):
		sim2.step()
	if JSON.stringify(sim2.deadlock_events) != JSON.stringify(sim.deadlock_events):
		flag("zweiter Lauf weicht ab (Determinismus)")


func run_normal(seed: int) -> void:
	# Felix' Kontrolle K1 (Ausweichgleis), nur mit Seed-Offsets; 6000 Ticks = 10 min Spielzeit
	var sim = Scenarios.kontrolle_ausweichgleis()
	var o := offsets(seed, 2)
	sim.vehicles[1]["start_tick"] = o[0]
	sim.vehicles[2]["start_tick"] = o[1]
	var waits := 0
	var oracle := 0
	for t in range(6000):
		sim.step()
		for id in sim.vehicles:
			if sim.vehicles[id]["state"] == SimWorld.VState.WARTET_BLOCK:
				waits += 1
		if not stuck_set(sim).is_empty():
			oracle += 1
	print("N  Normalbetrieb K1 6000 Ticks | seed %d | offsets %s | Ereignisse %d | Orakel-Stillstand-Ticks %d | Warte-Fahrzeug-Ticks %d | Laeufe Z1 %d Z2 %d" % [
		seed, str(o), sim.deadlock_events.size(), oracle, waits, sim.vehicles[1]["runs"], sim.vehicles[2]["runs"]])
	if sim.deadlock_events.size() != 0:
		flag("Fehlalarm im Normalbetrieb")
	if waits == 0:
		note("Normalbetrieb ohne jede Wartezeit (Test waere trivial)")


## Grenzfaelle der Schnittstelle, die D-04 braucht
func run_failure_modes() -> void:
	print("G  Schnittstellen-Grenzfaelle")
	var sim = Scenarios.gegenverkehr_eingleisig()
	sim.run_ticks(5)
	var c: Dictionary = sim.get_wait_chain(1)
	print("   fahrendes Fahrzeug: Ursache %s, Kette %d Glieder" % [c["root_cause"], c["links"].size()])
	var has_state_api := false
	for m in sim.get_method_list():
		if m["name"] in ["get_state", "get_snapshot", "checksum", "state_hash"]:
			has_state_api = true
	print("   Abfrage-API get_state/get_snapshot/checksum vorhanden: %s" % str(has_state_api))
	print("   Zustand je ID nur ueber direkten Zugriff sim.vehicles[id] (Dictionary), keine Pruefsumme")
	var has_prng := false
	for p in sim.get_property_list():
		if str(p["name"]).findn("rng") >= 0 or str(p["name"]).findn("seed") >= 0:
			has_prng = true
	print("   PRNG/Seed in SimWorld: %s" % str(has_prng))


func flag(msg: String) -> void:
	fails += 1
	print("   [!] " + msg)


func note(msg: String) -> void:
	print("   [Hinweis] " + msg)
