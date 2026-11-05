extends SceneTree
## Phase 4 Welle 2 (Felix): ProtoSim-Adapter – echte Kette Farm → Mühle → Dorf in der Prototyp-Welt.
##   godot --headless --path slice -s res://tests/proto_sim_test.gd
## Prüft: Graph aus Fahrlinien-Ankern zusammenhängend für die Kette, Lizenzen, Fuhrwerk 1 lädt Getreide und liefert an
## die Mühle, Mühle macht Mehl, Fuhrwerk 2 liefert Mehl ans Dorf (Ertrag > 0), Postkutsche pendelt, Sim-Tempo
## 15 m/Tick, Routenlinien (Darstellung) ≈ Sim-Länge, Determinismus (zweiter Lauf gleiche Prüfsumme).

const ProtoSim := preload("res://proto/proto_sim.gd")
const SimWorld := preload("res://core/sim_world.gd")
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
	s.kette_modus = "fest"              # S8 AT-08: Szenen-Default ist "leer"; dieser Test misst die feste Kette
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
	if ps.tempo_k == 1:
		pruef(c1 == FEST_PRUEFSUMME, "FK-02: feste Kette ohne Kauf unverändert gegen Stand vor FK-02-Verdrahtung (%d, Soll %d)" % [c1, FEST_PRUEFSUMME])
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
	# FZ-09: bei k = 20 (0,75 m/Tick) braucht die erste Fahrt länger als 600 Ticks; dann weiter bis zur ersten Lieferung,
	# höchstens 600 × k Ticks (bei k ≤ 8 liegt die Lieferung schon im Fenster, der Test läuft unverändert)
	var t_a7: int = ps.sim.tick_count
	while ps.lieferungen.is_empty() and ps.sim.tick_count < t_a7 + 600 * (ps.tempo_k - 1) and not ps.konto.bankrupt:
		ps.tick()
	pruef(ps.lieferungen.size() > 0, "A7 gekaufte Linie liefert (%d Lieferungen in %d Ticks)" % [ps.lieferungen.size(), 600 + ps.sim.tick_count - t_a7])
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
	_fz01(s)
	_at02_kredit(s)
	_at02_bankrott(s)
	_at02_paritaet(s)
	_at02_kalender(s)
	_fz02(s)
	_at03(s)
	_fk02(s)
	_fz03(s)
	_fx3(s)


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
				rc += b.fix_eff(f)                   # Eingabe: Fix je Fahrzeug (FZ-03 Alterung), Kostenblock selbst wie S7
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


## FZ-01: Fuhrwerk-Linie bucht 60 $/Periode Fix und 10 E Kapazität (fuhrwerk_e1), kein Tempofeld (W1).
func _fz01(s: Node) -> void:
	var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/vehicles.json"))
	var tempo := []
	var ids := []
	for v in d["fahrzeuge"]:
		if v["id"] in ["fuhrwerk_e1", "frachtwagen_e1"]:
			ids.append(v["id"])
			for key in v:
				if String(key).contains("tempo") or String(key).contains("speed") or String(key).contains("promille"):
					tempo.append("%s.%s" % [v["id"], key])
	pruef(ids.size() == 2 and tempo.is_empty(), "FZ-01 Datensätze %s ohne Tempofeld (Treffer %s)" % [str(ids), str(tempo)])
	var ps = _neu(s)
	ps.lizenz_kaufen(FARM)
	var r: Dictionary = ps.linie_anlegen(FARM, MUEHLE)
	var f: Dictionary = ps.fahrzeug(int(r.get("vid", -1)))
	var cap: int = ps.sim.v_cargo_cap[ps.sim.slot_of(int(r.get("vid", -1)))] if r.get("ok", false) else -1
	var e0: int = ps.konto.expenses_total - ps.kauf_total - ps.fahrkosten_total
	_bis(ps, 600)
	var fix_p: int = ps.konto.expenses_total - ps.kauf_total - ps.fahrkosten_total - e0
	pruef(r.get("ok", false) and f["def_id"] == "fuhrwerk_e1" and r["preis_cent"] == 30000 and cap == 10 and fix_p == 6000,
		"FZ-01 Fuhrwerk-Linie: %s, Kauf %d ¢, Kapazität %d E, Fix %d ¢ in Periode 1 (Soll 6000)" % [f.get("def_id", "?"), int(r.get("preis_cent", -1)), cap, fix_p])
	var fw: Dictionary = ps.linie_anlegen(FARM, MUEHLE, "fuhrwerk", "frachtwagen_e1")
	pruef(not fw["ok"] and fw["fehler"] == "noch_nicht_verfuegbar", "FZ-01 Frachtwagen vor 1830 nicht kaufbar (%s)" % fw.get("fehler", "ok"))


## FZ-02 Zwei Uhren: Monat = 150 Ticks bei jahr_ticks 1.800; Wirtschafts-Prüfsumme bei 1.800 und 7.200 gleich.
func _fz02(s: Node) -> void:
	const Kal := preload("res://core/kalender.gd")
	var ps = _neu(s)
	var k = ps.kalender
	var txt := [k.datum_text(0), k.datum_text(149), k.datum_text(150), k.datum_text(1650), k.datum_text(1799), k.datum_text(1800)]
	pruef(k.jahr_ticks == 1800 and k.monat_ticks() == 150 and txt == ["Jan 1820", "Jan 1820", "Feb 1820", "Dez 1820", "Dez 1820", "Jan 1821"],
		"FZ-02 Welt-Kalender %d Ticks/Jahr aus economy_proto.json, Monat %d Ticks: %s" % [k.jahr_ticks, k.monat_ticks(), str(txt)])
	var sl = Kal.new(1820, 7200)
	var t4 = Kal.new(1820, 450)
	pruef(sl.datum_text(599) == "Jan 1820" and sl.datum_text(600) == "Feb 1820" and t4.jahr(450 * 10) == 1830 and k.alter_jahre(1800 * 10 - 1) == 9,
		"FZ-02 Slice-Kalender 7200 (Monat 600), Test 450 (1830 bei Tick 4500), Alter 9 J. bei 17999 Ticks")
	var pr := []
	var meld := []
	for jt in [1800, 7200]:
		var p2 = _neu(s, true)
		p2.jahr_ticks = jt
		p2.alterung_an = false                      # Ticket FZ-02: "ohne Fahrzeugalter"
		_bis(p2, 20000)
		pr.append([p2.pruefsumme(), p2.eco.cash_cent, p2.lieferungen.size()])
		meld.append(p2.freischaltungen.size())
	pruef(pr[0] == pr[1] and meld[0] != meld[1],
		"FZ-02 Wirtschaft unabhängig vom Kalender: 20000 Ticks, Prüfsumme/Kasse/Lieferungen 1800 %s = 7200 %s; Freischaltungen %s (Kalender wirkt nur dort)" % [str(pr[0]), str(pr[1]), str(meld)])


## AT-03: generische Site-Registrierung aus proto_orte.json.
func _at03(s: Node) -> void:
	var ps = _neu(s)
	var n := {"getreidefarm": 0, "muehle": 0, "stadt": 0}
	for nm in ps.stationen:
		var st: Dictionary = ps.stationen[nm]
		if int(st["site"]) < 0:
			continue
		if st["id"] in ["getreidefarm", "muehle"]:
			n[st["id"]] += 1
		else:
			n["stadt"] += 1
	pruef(n["getreidefarm"] == 2 and n["muehle"] == 1 and n["stadt"] == 2,
		"AT-03 Sites aus proto_orte.json: %d Farmen, %d Mühle, %d Orte (übersprungen %s)" % [n["getreidefarm"], n["muehle"], n["stadt"], str(ps.uebersprungen)])
	var d_e: int = ps.eco.city_demand(int(ps.stationen.get("Erlenbach", {"site": -1})["site"]))
	var d_l: int = ps.eco.city_demand(int(ps.stationen.get("Lindenfurt", {"site": -1})["site"]))
	pruef(absi(d_e - 10) <= 2 and absi(d_l - 24) <= 3, "AT-03 Nachfrage aus sim_ew: Erlenbach %d E/min (10 ± 2), Lindenfurt %d E/min (24 ± 3)" % [d_e, d_l])
	var lz: Dictionary = ps.lizenz_kaufen("Hof Hasenwinkel")
	ps.lizenz_kaufen(MUEHLE)
	var r: Dictionary = ps.linie_anlegen("Hof Hasenwinkel", MUEHLE)
	_bis(ps, 3000)
	var menge := 0
	for l in ps.lieferungen:
		if l["vid"] == int(r.get("vid", -1)) and l["gut"] == "getreide":
			menge += int(l["menge"])
	var st2: Dictionary = ps.stationen.get("Hof Hasenwinkel", {})
	pruef(lz.get("ok", false) and r.get("ok", false) and menge > 0,
		"AT-03 2. Farm liefert: Hof Hasenwinkel → Erlenmühle %d Getreide in 3000 Ticks (Knoten %d, %.1f m vom Ladeplatz, Lizenz %s, Linie %s)" % [
		menge, int(st2.get("knoten", -1)), float(st2.get("abstand_m", -1.0)), str(lz.get("fehler", "ok")), str(r.get("fehler", "ok"))])


## Prüfsumme der festen Kette (6.000 Ticks, k = 1) auf s8 8f9fb6f vor der FK-02-Verdrahtung (gemessen 05.11.2026).
const FEST_PRUEFSUMME := 1803066295721950847   # S8 05.11.: neu gesetzt nach WA-08 (Durchgangs-Ladeplatz Muehle, Gutsweg bis Hoftor) und WA-10 (Weltdaten); vorher -6753726287387273337 (FK-02-Stand 8f9fb6f)


## FK-02 in ProtoSim: Kauf bucht Kasse um den Vorschaupreis ± 0, Werksunterhalt je Periode über konto, Ausbau, Kredit sperrt.
func _fk02(s: Node) -> void:
	var ps = _neu(s, true)
	ps.alterung_an = false                          # Unterhalt-Perioden über den Jahreswechsel 1800 ohne Alterungsstufe vergleichen
	_bis(ps, 600)
	var q: Dictionary = ps.kauf_angebot(MUEHLE)
	var c0: int = ps.eco.cash_cent
	var r: Dictionary = ps.firma_kaufen(MUEHLE)
	pruef(q.get("ok", false) and q["kaufbar"] and r.get("ok", false) and ps.eco.cash_cent == c0 - int(q["preis_cent"]) and int(q["preis_cent"]) > 0,
		"FK-02 Kauf Mühle: Vorschau %d ¢ (Werk %d, Anrechnung %d, Erstrabatt %s), Kasse %d → %d (Δ = Vorschau ± 0)" % [
		int(q.get("preis_cent", -1)), int(q.get("werkspreis_cent", -1)), int(q.get("anrechnung_cent", -1)), str(q.get("rabatt_erster_kauf", "?")), c0, ps.eco.cash_cent])
	var sum_fix := 0
	for f in ps.fahrzeuge:
		sum_fix += ps.fix_eff(f)
	var up: int = ps.werksunterhalt_cent_pro_periode()
	_bis(ps, 1200)
	var e0: int = ps.konto.expenses_total - ps.kauf_total - ps.fahrkosten_total - ps.credit.interest_paid   # FX3: kauf_total enthält den Firmenkauf
	_bis(ps, 1800)
	var e1: int = ps.konto.expenses_total - ps.kauf_total - ps.fahrkosten_total - ps.credit.interest_paid
	pruef(up == int(q["unterhalt_neu_cent_pro_periode"]) and up == 2000 and e1 - e0 == sum_fix + up and ps.konto.running_cost_per_period == sum_fix + up,
		"FK-02 Werksunterhalt %d ¢/Periode über konto: Periode gebucht %d ¢ = Fahrzeuge %d + Werk %d" % [up, e1 - e0, sum_fix, up])
	var aq: Dictionary = ps.ausbau_angebot(MUEHLE)
	var c1: int = ps.eco.cash_cent
	var ar: Dictionary = ps.werk_ausbauen(MUEHLE)
	_bis(ps, 2400)
	var e2: int = ps.konto.expenses_total - ps.kauf_total - ps.fahrkosten_total - ps.credit.interest_paid
	pruef(aq.get("ok", false) and ar.get("ok", false) and c1 - int(aq["kosten_cent"]) == c1 - int(ar["bezahlt_cent"]) and int(ps.eco.s_werksstufe[ps.stationen[MUEHLE]["site"]]) == 2
		and ps.werksunterhalt_cent_pro_periode() == 4000 and e2 - e1 == sum_fix + 4000,
		"FK-02 Ausbau Stufe 2: %d ¢ (Vorschau %d), Durchsatz %d, Unterhalt 4000 ¢, Periode gebucht %d ¢" % [int(ar.get("bezahlt_cent", -1)), int(aq.get("kosten_cent", -1)), int(ar.get("durchsatz", -1)), e2 - e1])
	pruef(not ps.firma_kaufen(MUEHLE)["ok"] and not ps.kauf_angebot(MUEHLE)["kaufbar"] and ps.kauf_angebot(MUEHLE)["grund"] == "schon_gekauft", "FK-02 zweiter Kauf abgelehnt (schon_gekauft)")
	# Kreditgeld kauft keine Firma
	var pk = _neu(s, true)
	_bis(pk, 7200)
	for i in 4:
		pk.kredit_aufnehmen()
	var qk: Dictionary = pk.kauf_angebot(MUEHLE)
	pk.eco.cash_cent = int(qk["preis_cent"]) + 1000          # Kasse reicht nur mit Kreditgeld
	qk = pk.kauf_angebot(MUEHLE)
	var ck: int = pk.eco.cash_cent
	var rk: Dictionary = pk.firma_kaufen(MUEHLE)
	pruef(not qk["kaufbar"] and qk["grund"] == "kredit_sperrt_firmenkauf" and not rk["ok"] and rk["fehler"] == "kredit_sperrt_firmenkauf" and pk.eco.cash_cent == ck,
		"FK-02 Kreditgeld kauft keine Firma: Kasse %d ¢, Kredit %d ¢, Vorschau-Grund %s, Kauf %s, Kasse unverändert" % [ck, pk.credit.loan_cent, qk["grund"], rk.get("fehler", "ok")])


## FZ-03 Alterung, FZ-04 Ersetzen (Restwert W20, Linie läuft weiter), FZ-05 Folgemodell Frachtwagen ab 1830.
func _fz03(s: Node) -> void:
	var ps = _neu(s, true)
	var f: Dictionary = ps.fahrzeuge[0]
	var fix0: int = ps.fix_eff(f)
	var werte := {}
	for j in [1, 5, 10]:
		_bis(ps, j * ps.jahr_ticks + 1)
		werte[j] = ps.fix_eff(f)
	pruef(fix0 == 6000 and werte[1] == 6300 and werte[5] == 7500 and werte[10] == 9000 and ps.konto.running_cost_per_period == 2 * werte[10],
		"FZ-03 Alterung fuhrwerk_e1 (500 bp/Jahr): Fix %d → J1 %d, J5 %d (125 %%), J10 %d (150 %%) ¢; laufend %d ¢" % [fix0, werte[1], werte[5], werte[10], ps.konto.running_cost_per_period])
	var p2 = _neu(s, true)
	_bis(p2, p2.jahr_ticks - 1)
	var vor: int = p2.fix_eff(p2.fahrzeuge[0])
	_bis(p2, p2.jahr_ticks)
	pruef(vor == 6000 and p2.fix_eff(p2.fahrzeuge[0]) == 6300, "FZ-03 Stufe genau am Jahreswechsel (Tick %d: %d → %d ¢)" % [p2.jahr_ticks, vor, p2.fix_eff(p2.fahrzeuge[0])])
	_bis(ps, 15 * ps.jahr_ticks + 1)
	pruef(ps.lebensdauer_erreicht.size() == 2 and int(ps.lebensdauer_erreicht[0]["tick"]) == 15 * ps.jahr_ticks,
		"FZ-03 Meldung bei 100 %% Lebensdauer (15 Jahre): %s" % str(ps.lebensdauer_erreicht))
	# FZ-04 Ersetzen gleiches Modell nach 10 Jahren (Tick 18.000 = 1830)
	var pe = _neu(s, true)
	_bis(pe, 10 * pe.jahr_ticks + 50)
	var vid: int = pe.fahrzeuge[0]["vid"]
	var q: Dictionary = pe.ersetzen_angebot(vid)
	var c0: int = pe.eco.cash_cent
	var lief0: int = pe.lieferungen.size()
	var r: Dictionary = pe.fahrzeug_ersetzen(vid)
	var ok_kasse: bool = r.get("ok", false) and pe.eco.cash_cent == c0 + int(q["restwert_cent"]) - int(q["preis_cent"])
	var rw_soll: int = 30000 * 500 / 1000 * maxi(200, 1000 - (10 * pe.jahr_ticks + 50) * 1000 / (15 * pe.jahr_ticks)) / 1000
	pruef(ok_kasse and int(q["restwert_cent"]) == rw_soll and int(q["fix_alt_cent"]) == 9000 and pe.fix_eff(pe.fahrzeug(vid)) == 6000 and pe.alter_jahre(pe.fahrzeug(vid)) == 0,
		"FZ-04 Ersetzen nach 10 J.: Restwert %d ¢ (W20 %d), Kauf %d, Kasse Δ %d, Fix 9000 → %d ¢ (spart %d ¢/Periode)" % [
		int(q.get("restwert_cent", -1)), rw_soll, int(q.get("preis_cent", -1)), pe.eco.cash_cent - c0, pe.fix_eff(pe.fahrzeug(vid)), int(q.get("spart_cent_pro_periode", 0))])
	_bis(pe, pe.sim.tick_count + 1200)
	var lief_neu := 0
	for l in pe.lieferungen.slice(lief0):
		if l["vid"] == vid:
			lief_neu += 1
	pruef(lief_neu > 0 and pe.sim.v_state[pe.sim.slot_of(vid)] != SimWorld.S_ENDE, "FZ-04 Linie läuft nach dem Ersetzen weiter (%d Lieferungen in 1200 Ticks, gleicher Slot)" % lief_neu)
	# FZ-05 Folgemodell: Frachtwagen erst ab 1830 (Tick 18.000 = Minute 30 bei 3 min/Jahr)
	var pf = _neu(s, true)
	_bis(pf, 10 * pf.jahr_ticks - 1)
	var vorher: Dictionary = pf.ersetzen_angebot(pf.fahrzeuge[1]["vid"], "frachtwagen_e1")
	_bis(pf, 10 * pf.jahr_ticks)
	var frei := false
	for fr in pf.freischaltungen:
		if fr["id"] == "frachtwagen_e1" and int(fr["tick"]) == 10 * pf.jahr_ticks:
			frei = true
	var toast := false
	for m in pf.meldungen:
		if String(m).contains("Frachtwagen"):
			toast = true
	var v2: int = pf.fahrzeuge[1]["vid"]
	var rf: Dictionary = pf.fahrzeug_ersetzen(v2, "frachtwagen_e1")
	var i2: int = pf.sim.slot_of(v2)
	pruef(not vorher["ok"] and vorher["fehler"] == "noch_nicht_verfuegbar" and frei and toast and rf.get("ok", false)
		and pf.sim.v_cargo_cap[i2] == 18 and pf.fix_eff(pf.fahrzeug(v2)) == 9500,
		"FZ-05 Frachtwagen: Tick %d gesperrt, ab Tick %d (1830, Minute 30) frei + Meldung; Ersetzen → Kapazität %d, Fix %d ¢" % [
		10 * pf.jahr_ticks - 1, 10 * pf.jahr_ticks, pf.sim.v_cargo_cap[i2], pf.fix_eff(pf.fahrzeug(v2))])
	var lk: Dictionary = pf.linie_anlegen(FARM, MUEHLE, "fuhrwerk", "frachtwagen_e1")
	pruef(lk.get("ok", false), "FZ-05 Frachtwagen ab 1830 auch neu kaufbar (%s)" % str(lk.get("fehler", "ok")))


## FX3: Ertragsausgleich a (W2) und kauf_total inkl. Firmenkauf/Ausbau.
func _fx3(s: Node) -> void:
	var a1 = _neu(s, true)
	var a2 = _neu(s, true)
	pruef(a1.eco.ertrag_a_promille == 1000, "FX3 a aus economy_proto.json = %d ‰ (Standard)" % a1.eco.ertrag_a_promille)
	a2.eco.ertrag_a_promille = 2000
	_bis(a1, 6000)
	_bis(a2, 6000)
	var gleich: bool = a1.lieferungen.size() == a2.lieferungen.size() and a1.lieferungen.size() > 0
	var max_abw := 0
	for i in mini(a1.lieferungen.size(), a2.lieferungen.size()):
		var l1: Dictionary = a1.lieferungen[i]
		var l2: Dictionary = a2.lieferungen[i]
		if l1["tick"] != l2["tick"] or l1["menge"] != l2["menge"] or l1["gut"] != l2["gut"]:
			gleich = false
		max_abw = maxi(max_abw, absi(int(l2["cent"]) - 2 * int(l1["cent"])))
	pruef(gleich and max_abw <= 1 and a1.eco.units_paid == a2.eco.units_paid,
		"FX3 a = 2000 ‰: %d Lieferungen gleich (Tick, Menge, Gut), Ertrag je Lieferung × 2 (max. Abweichung %d ¢), Einheiten %d = %d; Ertrag %d → %d ¢" % [
		a1.lieferungen.size(), max_abw, a1.eco.units_paid, a2.eco.units_paid, a1.eco.revenue_total, a2.eco.revenue_total])
	var pk = _neu(s, true)
	_bis(pk, 600)
	var k0: int = pk.kauf_total
	var r: Dictionary = pk.firma_kaufen(MUEHLE)
	var u: Dictionary = pk.werk_ausbauen(MUEHLE)
	pruef(r.get("ok", false) and u.get("ok", false) and pk.kauf_total == k0 + int(r["bezahlt_cent"]) + int(u["bezahlt_cent"]),
		"FX3 kauf_total zählt Firmenkauf %d + Ausbau %d ¢ mit (%d → %d)" % [int(r.get("bezahlt_cent", -1)), int(u.get("bezahlt_cent", -1)), k0, pk.kauf_total])
