extends SceneTree
## Phase 4 Welle 2 (Felix): ProtoSim-Adapter – echte Kette Farm → Mühle → Dorf in der Prototyp-Welt.
##   godot --headless --path slice -s res://tests/proto_sim_test.gd
## Prüft: Graph aus Fahrlinien-Ankern zusammenhängend für die Kette, Lizenzen, Fuhrwerk 1 lädt Getreide und liefert an
## die Mühle, Mühle macht Mehl, Fuhrwerk 2 liefert Mehl ans Dorf (Ertrag > 0), Postkutsche pendelt, Sim-Tempo
## 15 m/Tick, Routenlinien (Darstellung) ≈ Sim-Länge, Determinismus (zweiter Lauf gleiche Prüfsumme).

const ProtoSim := preload("res://proto/proto_sim.gd")
const SZENE := "res://proto/prototyp_welt.tscn"
const TICKS := 6000

var n_ok := 0
var n_fail := 0


func _initialize() -> void:
	_run.call_deferred()


func pruef(ok: bool, text: String) -> void:
	if ok:
		n_ok += 1
	else:
		n_fail += 1
	print("  %s %s" % ["OK  " if ok else "FAIL", text])


func _lauf(s: Node, ticks: int) -> Array:
	var ps = ProtoSim.new(s.regelwerk)
	ps.graph_bauen(s.strassen)
	var orte = JSON.parse_string(FileAccess.get_file_as_string(s.datei("proto_orte.json")))
	ps.kette_aufbauen(orte)
	for t in ticks:
		ps.tick()
	return [ps, ps.pruefsumme()]


func _run() -> void:
	print("proto_sim_test")
	var s: Node = (load(SZENE) as PackedScene).instantiate()
	s.set("sim_aus", true)
	root.add_child(s)
	await process_frame
	var t0 := Time.get_ticks_usec()
	var ps = ProtoSim.new(s.regelwerk)
	ps.graph_bauen(s.strassen)
	var orte = JSON.parse_string(FileAccess.get_file_as_string(s.datei("proto_orte.json")))
	var ok: bool = ps.kette_aufbauen(orte)
	var bau_ms := (Time.get_ticks_usec() - t0) / 1000.0
	print("  Graph: %d Knoten, %d Kanten, Aufbau %.0f ms; Stationen %s" % [ps.sim.graph.nodes.size(), ps.sim.graph.edges.size(), bau_ms,
		str(ps.stationen.keys())])
	for n in ps.stationen:
		print("    %-16s Knoten %d  Abstand Gebäude→Knoten %.1f m" % [n, ps.stationen[n]["knoten"], ps.stationen[n].get("abstand_m", 0.0)])
	pruef(ok and ps.fehler.is_empty(), "Kette aufgebaut (Fehler: %s)" % str(ps.fehler))
	pruef(ps.fahrzeuge.size() == 3, "3 Fahrzeuge: 2 Fuhrwerke + Postkutsche (%d)" % ps.fahrzeuge.size())
	for f in ps.fahrzeuge:
		var l0: float = f["legs"][0].laenge
		var sim_m: float = float(f["sim_mm"]) / ps.mm_pro_m
		print("    %-24s Sim %.0f m, Fahrlinie %.0f m (%+.1f %%), Kanten %d, Übergangsbogen min %.1f m, Skala Kurvenzone %.3f" % [
			f["name"], sim_m, l0, (l0 / sim_m - 1.0) * 100.0, f["route_kanten"], f["legs"][0].r_uebergang_min, f["legs"][0].skala])
		pruef(absf(l0 / sim_m - 1.0) < 0.05, "%s: Fahrlinie ≈ Sim-Länge (±5 %%)" % f["name"])
	var spd: int = ps.sim.v_speed[ps.sim.slot_of(1)] if ps.fahrzeuge.size() > 0 else 0
	var k: int = ps.tempo_k        # AT-04: 600 / k (regelwerk tempo_k, --tempo_k=)
	pruef(spd == 600 / k, "Sim-Tempo Fuhrwerk 600/%d = %d mm/Tick (%d)" % [k, 600 / k, spd])
	var lieferung_muehle := 0
	var lieferung_dorf := 0
	var cent_dorf := 0
	var mehl_geladen := false
	var kutsche_wenden := 0
	var leg_alt := 0
	for t in TICKS:
		ps.tick()
		if ps.fahrzeuge.size() >= 3:
			var i: int = ps.sim.slot_of(3)
			if ps.sim.v_leg[i] != leg_alt:
				kutsche_wenden += 1
				leg_alt = ps.sim.v_leg[i]
		if ps.fahrzeuge.size() >= 2 and ps.sim.v_cargo[ps.sim.slot_of(2)] > 0:
			mehl_geladen = true
	for l in ps.lieferungen:
		if l["vid"] == 1:
			lieferung_muehle += l["menge"]
		elif l["vid"] == 2:
			lieferung_dorf += l["menge"]
			cent_dorf += l["cent"]
	print("  nach %d Ticks: Lieferungen %s" % [TICKS, str(ps.lieferungen.slice(0, 6))])
	for f in ps.fahrzeuge:
		print("    " + ps.zustand_text(f))
	pruef(lieferung_muehle > 0, "Fuhrwerk 1 liefert Getreide an die Mühle (%d Einheiten)" % lieferung_muehle)
	pruef(mehl_geladen, "Fuhrwerk 2 lädt Mehl an der Mühle")
	pruef(lieferung_dorf > 0 and cent_dorf > 0, "Fuhrwerk 2 liefert Mehl ans Dorf (%d Einheiten, %d Cent Ertrag)" % [lieferung_dorf, cent_dorf])
	pruef(kutsche_wenden >= 2, "Postkutsche pendelt Dorf ↔ Kleinstadt (%d Wenden)" % kutsche_wenden)
	var c1: int = ps.pruefsumme()
	var r2 := _lauf(s, TICKS)
	pruef(c1 == r2[1], "deterministisch: zweiter Lauf gleiche Prüfsumme (%d)" % c1)
	print("Prüfungen OK: %d, FAIL: %d" % [n_ok, n_fail])
	quit(0 if n_fail == 0 else 1)
