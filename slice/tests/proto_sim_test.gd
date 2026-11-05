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
	_at02(s)
	print("Prüfungen OK: %d, FAIL: %d" % [n_ok, n_fail])
	quit(0 if n_fail == 0 else 1)


# ====================================================================== AT-02: ProtoSim spielfähig

const FARM := "Gut Kuppenhof"
const MUEHLE := "Erlenmühle"
const DORF := "Erlenbach"


func _neu(s: Node, mit_linien := false):
	var ps = ProtoSim.new(s.regelwerk)
	ps.graph_bauen(s.strassen)
	var orte = JSON.parse_string(FileAccess.get_file_as_string(s.datei("proto_orte.json")))
	ps.spiel_starten(orte)
	if mit_linien:
		ps.lizenz_kaufen(FARM)
		ps.lizenz_kaufen(MUEHLE)
		ps.linie_anlegen(FARM, MUEHLE)
		ps.linie_anlegen(MUEHLE, DORF)
	return ps


func _bis(ps, t: int) -> void:
	while ps.sim.tick_count < t and not ps.konto.bankrupt:
		ps.tick()


func _at02(s: Node) -> void:
	print("== AT-02 ProtoSim spielfähig")
	# A1 Start ohne Kette, 6.000 $, 0 $ Fix ohne Fahrzeug
	var ps = _neu(s)
	var start: int = int(ps.eco.slice["hq"]["start_capital_cent"])
	pruef(ps.fehler.is_empty() and ps.eco.company_started and ps.fahrzeuge.is_empty() and ps.eco.cash_cent == start and start == 600000,
		"A1 Start ohne Kette: Firma, 0 Fahrzeuge, Kasse %d ¢ = Startkapital 600000 (Fehler %s)" % [ps.eco.cash_cent, str(ps.fehler)])
	_bis(ps, 1200)
	pruef(ps.eco.cash_cent == start and ps.konto.expenses_total == 0 and ps.konto.running_cost_per_period == 0,
		"A2 0 $ Fix ohne Fahrzeug: 1200 Ticks, Kasse %d ¢, Ausgaben %d ¢" % [ps.eco.cash_cent, ps.konto.expenses_total])
	# A3 API: Lizenz, Linie, Kauf
	ps = _neu(s)
	var c0: int = ps.eco.cash_cent
	var l1: Dictionary = ps.lizenz_kaufen(FARM)
	var l2: Dictionary = ps.lizenz_kaufen(MUEHLE)
	var r1: Dictionary = ps.linie_anlegen(FARM, MUEHLE)
	var r2: Dictionary = ps.linie_anlegen(MUEHLE, DORF)
	var lic: int = int(l1.get("bezahlt_cent", -1)) + int(l2.get("bezahlt_cent", -1))
	var kauf: int = int(r1.get("preis_cent", 0)) + int(r2.get("preis_cent", 0))
	pruef(l1.get("ok", false) and l2.get("ok", false) and r1.get("ok", false) and r2.get("ok", false) and ps.eco.cash_cent == c0 - lic - kauf and kauf > 0,
		"A3 lizenz_kaufen ×2 + linie_anlegen ×2: Kasse %d = %d − Lizenz %d − Kauf %d" % [ps.eco.cash_cent, c0, lic, kauf])
	var unb: Dictionary = ps.linie_anlegen(FARM, "Nirgendwo")
	var gl: Dictionary = ps.linie_anlegen(FARM, MUEHLE, "fuhrwerk", "lok_e1")
	pruef(not unb["ok"] and unb["fehler"] == "unbekannter_ort" and not gl["ok"] and gl["fehler"] == "gesperrt",
		"A4 Ablehnung mit Grund: unbekannter Ort (%s), Lok/Gleis gesperrt W10 (%s)" % [unb["fehler"], gl["fehler"]])
	var st: Dictionary = ps.station_anlegen(DORF)
	pruef(st["ok"] and int(st["site"]) >= 0, "A5 station_anlegen(%s): Site %d, Knoten %d" % [DORF, int(st.get("site", -1)), int(st.get("knoten", -1))])
	# A6 Fix je Periode = Σ fix_eff
	var sum_fix := 0
	for f in ps.fahrzeuge:
		sum_fix += ps.fix_eff(f)
	var e0: int = ps.konto.expenses_total - ps.kauf_total - ps.fahrkosten_total - ps.credit.interest_paid
	_bis(ps, ps.sim.tick_count + 600)
	var fix_p: int = ps.konto.expenses_total - ps.kauf_total - ps.fahrkosten_total - ps.credit.interest_paid - e0
	pruef(sum_fix > 0 and fix_p == sum_fix and ps.konto.running_cost_per_period == sum_fix,
		"A6 Fix je Periode = Σ fix_eff: gebucht %d ¢ in 600 Ticks, Σ %d ¢, laufend %d ¢" % [fix_p, sum_fix, ps.konto.running_cost_per_period])
	pruef(ps.lieferungen.size() > 0, "A7 gekaufte Linie liefert (%d Lieferungen in 600 Ticks)" % ps.lieferungen.size())
	# A8 Restwert W20
	var f0: Dictionary = ps.fahrzeuge[0]
	var ld: int = ps.lebensdauer_ticks(f0)
	var k: int = int(f0["kauf_cent"])
	var t: int = ps.sim.tick_count
	var faelle := [[0, k * 500 / 1000], [ld / 2, k * 500 / 1000 * 500 / 1000], [ld * 8 / 10, k * 500 / 1000 * 200 / 1000],
		[ld, k * 500 / 1000 * 200 / 1000], [ld * 2, k * 500 / 1000 * 200 / 1000]]
	var rw_ok := ld > 0
	var rw_txt := []
	for fa in faelle:
		var probe := f0.duplicate()
		probe["kauf_tick"] = t - int(fa[0])
		var rw: int = ps.restwert(probe)
		rw_txt.append("%d→%d" % [fa[0], rw])
		if rw != int(fa[1]):
			rw_ok = false
	pruef(rw_ok, "A8 Restwert 50 %% × max(0,2; 1 − Alter/LD), LD %d Ticks, Kauf %d ¢ (Alter→¢: %s)" % [ld, k, ", ".join(PackedStringArray(rw_txt))])
	var c_v: int = ps.eco.cash_cent
	var rw0: int = ps.restwert(f0)
	var vk: Dictionary = ps.fahrzeug_verkaufen(int(f0["vid"]))
	pruef(vk["ok"] and ps.eco.cash_cent == c_v + rw0 and ps.fix_eff(f0) == 0, "A9 Verkauf: +%d ¢ Restwert, Fix 0" % rw0)
	ps.tick()
	pruef(ps.konto.running_cost_per_period == sum_fix - int(f0["kauf_cent"] * 0) - int(ps.vdef(f0["def_id"]).get("fix_cent_pro_periode", 0)),
		"A10 laufende Kosten nach Verkauf %d ¢" % ps.konto.running_cost_per_period)
	pruef(not ps.fahrzeug_verkaufen(int(f0["vid"]))["ok"], "A11 zweiter Verkauf desselben Fahrzeugs abgelehnt")
	_at02_kredit(s)
	_at02_bankrott(s)
	_at02_paritaet(s)
	_at02_kalender(s)


## Kredit wie d07 --only=kredit (gespiegelt: B0, B1, B2, B6, B7 verkürzt, B8, B13).
func _at02_kredit(s: Node) -> void:
	var ps = _neu(s)
	var unlock: int = ps.credit.from_ticks
	var lim: int = ps.credit.limit_cent
	pruef(unlock == 7200 and ps.kredit_aufnehmen() == 0 and ps.credit.loan_cent == 0, "K-B0 Kredit vor Tick %d gesperrt" % unlock)
	_bis(ps, unlock)
	var c0: int = ps.eco.cash_cent
	var got := 0
	for i in 12:
		got += ps.kredit_aufnehmen()
	pruef(ps.credit.loan_cent == lim and got == lim and ps.eco.cash_cent == c0 + lim, "K-B1 Obergrenze %d ¢ hart: 12 Versuche" % lim)
	pruef(ps.kredit_aufnehmen() == 0, "K-B2 weiterer Versuch über Rahmen gibt 0")
	var ca: int = ps.eco.cash_cent
	_bis(ps, ps.sim.tick_count + 3 * 600)
	var pm: int = ps.credit.interest_pm
	var want := 3 * ((lim * pm + 500) / 1000)
	pruef(ca - ps.eco.cash_cent == want and ps.credit.interest_paid == want, "K-B6 3 Perioden Zins %d ¢ (erwartet %d)" % [ca - ps.eco.cash_cent, want])
	var viol := 0
	for fall in 5:
		var p2 = _neu(s)
		_bis(p2, unlock)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7000 + fall
		var sc: int = p2.eco.cash_cent
		for step in 60:
			var r := rng.randi_range(0, 9)
			if r < 4:
				p2.kredit_aufnehmen()
			elif r < 8:
				p2.kredit_tilgen()
			else:
				_bis(p2, p2.sim.tick_count + rng.randi_range(1, 400))
			var lo: int = p2.credit.loan_cent
			if lo < 0 or lo > lim or lo % 50000 != 0 or p2.eco.cash_cent != sc + lo - p2.credit.interest_paid:
				viol += 1
	pruef(viol == 0, "K-B7 5 Kreislauf-Fälle × 60 Aktionen: Kasse == Start + Kredit − Zins (Verstöße %d)" % viol)
	var p3 = _neu(s)
	_bis(p3, unlock)
	p3.kredit_aufnehmen()
	p3.eco.cash_cent = 499
	pruef(p3.kredit_tilgen() == 0 and p3.eco.cash_cent == 499, "K-B8 Tilgen mit 4,99 $ abgelehnt")
	p3.eco.cash_cent = 0
	_bis(p3, p3.sim.tick_count + 600)
	pruef(p3.konto.bankrupt, "K-B13 Kasse 0 $ + offener Kredit: Zins → bankrott (Tick %d)" % p3.bankrott_tick)


func _at02_bankrott(s: Node) -> void:
	var ps = _neu(s, true)
	ps.eco.cash_cent = 50
	var t_neg := -1
	for i in 6000:
		ps.tick()
		if ps.eco.cash_cent < 0 and t_neg < 0:
			t_neg = ps.sim.tick_count
		if ps.konto.bankrupt:
			break
	var t_b: int = ps.sim.tick_count
	ps.tick()
	pruef(t_neg > 0 and ps.konto.bankrupt and ps.bankrott_tick == t_neg and ps.sim.tick_count == t_b,
		"B1 Kasse < 0 → bankrott im selben Tick (Kasse negativ ab %d, bankrott %d, danach kein Tick mehr: %d)" % [t_neg, ps.bankrott_tick, ps.sim.tick_count])
	pruef(not ps.linie_anlegen(FARM, MUEHLE)["ok"] and ps.kredit_aufnehmen() == 0, "B2 nach Bankrott: kein Kauf, kein Kredit")


## Parität: dieselbe Kette einmal über ProtoSim.tick (konto.gd) und einmal über den Kostenblock aus main.sim_tick
## (Stand S7, wörtlich nachgebaut: Fahrkosten, cost_acc, interest_due, Kasse < 0). 9.000 Ticks (über die Kreditsperre),
## Kredit bei 7.200, Verkauf bei 4.000. Kasse je Tick ±0 ¢.
func _at02_paritaet(s: Node) -> void:
	var a = _neu(s, true)
	var b = _neu(s, true)
	var cost_acc := 0
	var bankrupt := false
	var diffs := 0
	var erste := -1
	var per: int = b.eco.periode_ticks
	for i in 9000:
		if i == 4000:
			a.fahrzeug_verkaufen(1)
			b.fahrzeug_verkaufen(1)
		if a.sim.tick_count == 7200:
			a.kredit_aufnehmen()
			a.kredit_aufnehmen()
			b.credit.borrow(b.eco, b.sim.tick_count)
			b.credit.borrow(b.eco, b.sim.tick_count)
		a.tick()
		if not bankrupt:
			b.sim.step()
			b.eco.cash_cent -= b.sim.line_cost_cent
			b.sim.line_cost_cent = 0
			b.sim.line_events = []
			var rc := 0
			for f in b.fahrzeuge:
				rc += 0 if f["verkauft"] else int(f["fix_cent"])
			cost_acc += rc
			var c := cost_acc / per
			if c > 0:
				cost_acc -= c * per
				b.eco.cash_cent -= c
			var zi: int = b.credit.interest_due(b.sim.tick_count)
			if zi > 0:
				b.eco.cash_cent -= zi
				b.credit.interest_paid += zi
			if b.eco.cash_cent < 0:
				bankrupt = true
		if a.eco.cash_cent != b.eco.cash_cent:
			diffs += 1
			if erste < 0:
				erste = a.sim.tick_count
	pruef(diffs == 0 and a.credit.interest_paid > 0 and a.sim.tick_count == 9000,
		"P1 Parität Slice-Kostenblock ↔ ProtoSim: 9000 Ticks, Kasse %d ¢ = %d ¢, Abweichungen %d (erste Tick %d), Zins %d ¢" % [
		a.eco.cash_cent, b.eco.cash_cent, diffs, erste, a.credit.interest_paid])


func _at02_kalender(s: Node) -> void:
	var ps = _neu(s)
	var ziel: int = (1835 - ps.startjahr) * ps.jahr_ticks
	_bis(ps, ziel + 1)
	var bahn := false
	for fr in ps.freischaltungen:
		if String(fr["id"]) in ["bahn_moeglich", "lok_e1", "waggon_e1"]:
			bahn = true
	var gesperrt := false
	for g in ps.gesperrt_log:
		if g["id"] == "bahn_moeglich" and int(g["jahr"]) == 1835:
			gesperrt = true
	var toast := false
	for mtxt in ps.meldungen:
		if String(mtxt).to_lower().contains("bahn") or String(mtxt).to_lower().contains("gleis"):
			toast = true
	pruef(ps.kalenderjahr() == 1835 and not bahn and not toast and gesperrt,
		"W10 Kalender 1835 (Tick %d): 0 Gleis-Freischaltungen, 0 Toasts, unterdrückt protokolliert (%s)" % [ziel, str(ps.gesperrt_log)])
