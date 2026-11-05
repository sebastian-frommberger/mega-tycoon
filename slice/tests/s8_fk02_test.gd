extends SceneTree
## S8 OE-05 + FK-02 (Tobias): Sättigungsanzeige und Firmenkauf C1 in economy.gd, geprüft auf der Proto-Welt (ProtoSim).
##   godot --headless --path slice -s res://tests/s8_fk02_test.gd
## OE-05: 3 Sättigungsstufen (80/120/200 %) mit Handrechnung, Grenzen 100/150 %, Anzeige = Buchung (jede Ledger-Zeile
##        an der Stadt nachgerechnet). FK-02: Kaufpreis je Fall (Formel), Ablehnungen, Besitz ersetzt Lizenz, keine
##        Verlängerung, Werksmarge, Ausbau 40 E/min, Unterhalt über konto, Prüfsumme, Puffer-Deckel, Rückfall W3.

const ProtoSim := preload("res://proto/proto_sim.gd")
const Konto := preload("res://core/konto.gd")
const SZENE := "res://proto/prototyp_welt.tscn"
const FARM := "Gut Kuppenhof"
const FARM2 := "Hof Hasenwinkel"
const MUEHLE := "Erlenmühle"
const DORF := "Erlenbach"
const STADT := "Lindenfurt"

var n_ok := 0
var n_fail := 0
var szene: Node


func _initialize() -> void:
	_run.call_deferred()


func pruef(ok: bool, text: String) -> void:
	if ok:
		n_ok += 1
	else:
		n_fail += 1
	print("  %s %s" % ["OK  " if ok else "FAIL", text])


func _neu():
	var ps = ProtoSim.new(szene.regelwerk)
	ps.graph_bauen(szene.strassen)
	var orte = JSON.parse_string(FileAccess.get_file_as_string(szene.datei("proto_orte.json")))
	ps.spiel_starten(orte)
	return ps


func _site(ps, name: String) -> int:
	return int(ps.stationen[name]["site"])


func _bis(ps, t: int) -> void:
	while ps.sim.tick_count < t and not ps.konto.bankrupt:
		ps.tick()


func _run() -> void:
	print("s8_fk02_test")
	szene = (load(SZENE) as PackedScene).instantiate()
	szene.set("sim_aus", true)
	root.add_child(szene)
	await process_frame
	_oe05_rechnung()
	_oe05_buchung()
	_fk02_preis()
	_fk02_ablehnung()
	_fk02_besitz_lizenz()
	_fk02_ausbau_unterhalt()
	_fk02_pruefsumme()
	_fk02_puffer_w3()
	print("%d/%d Prüfungen OK" % [n_ok, n_ok + n_fail])
	quit(0 if n_fail == 0 else 1)


# ====================================================================== OE-05

func _oe05_rechnung() -> void:
	var ps = _neu()
	var e = ps.eco
	var g: int = e.g_index["mehl"]
	# Handrechnung: Mehl 70 ¢/E/Feld, 15 Felder, voll frisch, Nachfrage 10 E/Periode.
	# f_sätt je Einheit: bis 100 % 1.000, 110 % 880, 120 % 760, 130 % 640, 140 % 520, 150 % 400, darüber 100.
	var faelle := [
		[8, 8400, 8400, 0, 0, 800, "80 % grün"],      # 70 × 15 × 8
		[12, 12222, 12600, 378, 1, 1200, "120 % gelb"], # 70 × 15 × (10 + 0,88 + 0,76)
		[20, 14385, 21000, 6615, 2, 2000, "200 % rot"], # 70 × 15 × (10 + 3,2 + 0,5)
	]
	for f in faelle:
		var r: Dictionary = e.saett_luecke(g, 15, 1000, 0, f[0], 10)
		pruef(r["ist_cent"] == f[1] and r["voll_cent"] == f[2] and r["x_cent"] == f[3] and r["ampel"] == f[4] and r["v_promille"] == f[5],
			"OE-05 Stufe %s: %d E → Ist %d ¢ (soll %d), voll %d (soll %d), x = %d ¢/min (soll %d), Ampel %d (soll %d), V %d ‰" % [
			f[6], f[0], r["ist_cent"], f[1], r["voll_cent"], f[2], r["x_cent"], f[3], r["ampel"], f[4], r["v_promille"]])
	var r10: Dictionary = e.saett_luecke(g, 15, 1000, 0, 10, 10)
	var r15: Dictionary = e.saett_luecke(g, 15, 1000, 0, 15, 10)
	var r9: Dictionary = e.saett_luecke(g, 15, 1000, 0, 9, 10)
	pruef(r10["ampel"] == 1 and r10["x_cent"] == 0 and r15["ampel"] == 2 and r9["ampel"] == 0 and r9["frei_einheiten"] == 1,
		"OE-05 Grenzen: 100 %% gelb mit x 0 (%d/%d), 150 %% rot (%d), 90 %% grün mit 1 freier Einheit (%d/%d)" % [
		r10["ampel"], r10["x_cent"], r15["ampel"], r9["ampel"], r9["frei_einheiten"]])
	# Reihenfolge: andere Linie zuerst (before) – dieselbe Summe wie eine Lieferung
	var a: Dictionary = e.saett_luecke(g, 15, 1000, 0, 8, 10)
	var b: Dictionary = e.saett_luecke(g, 15, 1000, 8, 12, 10)
	pruef(a["f_saett_summe"] + b["f_saett_summe"] == e.saett_luecke(g, 15, 1000, 0, 20, 10)["f_saett_summe"],
		"OE-05 Linie hinter anderer Linie (before = 8): Σ f_sätt %d + %d = 20 E am Stück" % [a["f_saett_summe"], b["f_saett_summe"]])


## Anzeige = Buchung: jede Ledger-Zeile an Erlenbach mit saett_luecke nachrechnen (before = vorher in derselben Periode).
func _oe05_buchung() -> void:
	var ps = _neu()
	var e = ps.eco
	ps.lizenz_kaufen(FARM)
	ps.lizenz_kaufen(MUEHLE)
	ps.linie_anlegen(FARM, MUEHLE)
	ps.linie_anlegen(FARM, MUEHLE)
	ps.linie_anlegen(MUEHLE, DORF)
	ps.linie_anlegen(MUEHLE, DORF)
	_bis(ps, 9000)
	var dorf := _site(ps, DORF)
	var dem: int = e.city_demand(dorf)
	var per_seen := {}
	var n := 0
	var bad := 0
	var stufen := {0: 0, 1: 0, 2: 0}
	for l in e.ledger:
		if l["ziel"] != dorf:
			continue
		var per: int = int(l["tick"]) / e.periode_ticks
		var before: int = per_seen.get(per, 0)
		var r: Dictionary = e.saett_luecke(e.g_index[l["gut"]], l["felder"], l["f_zeit"], before, l["menge"], dem)
		n += 1
		if r["ist_cent"] != l["cent"] or r["f_saett_summe"] != l["f_saett_summe"]:
			bad += 1
		stufen[r["ampel"]] += 1
		per_seen[per] = before + int(l["menge"])
	pruef(n > 0 and bad == 0, "OE-05 Anzeige = Buchung: %d Lieferungen an Erlenbach (Nachfrage %d/min) nachgerechnet, %d Abweichungen; Ampel nach Lieferung grün/gelb/rot %d/%d/%d" % [
		n, dem, bad, stufen[0], stufen[1], stufen[2]])
	var sl: Dictionary = e.saett_linie(dorf, _site(ps, MUEHLE), e.g_index["mehl"], 20, 0)
	pruef(sl.get("ok", false) and sl["ampel"] == 2 and sl["x_cent"] > 0,
		"OE-05 saett_linie Mühle→Erlenbach 20 E/min: V %d ‰, Ist %d ¢, x = +%d ¢/min mit neuem Abnehmer" % [sl.get("v_promille", -1), sl.get("ist_cent", -1), sl.get("x_cent", -1)])


# ====================================================================== FK-02 Preis

## Unabhängige Nachrechnung der Formel (FK-01), eine Division.
func _soll(p: int, d: int, r: int, n: int, erst: bool, lic: int) -> int:
	var fd := 1000 + 30 * maxi(0, d - r)
	var fo := 1000 + 250 * n
	var ff := 800 if erst else 1000
	var z := p * fd * fo * ff - lic * 500 * 1000000
	var q := z / 1000000000
	if 2 * (z - q * 1000000000) >= 1000000000:
		q += 1
	return maxi(0, q)


func _fk02_preis() -> void:
	var ps = _neu()
	var e = ps.eco
	var m := _site(ps, MUEHLE)
	var q0: Dictionary = e.buy_quote(m)
	pruef(q0["ok"] and q0["preis_cent"] == 160000 and q0["felder_hq"] <= e.hq_radius_felder,
		"FK-02 P1 Mühle im HQ-Radius (%d ≤ %d Felder), keine Lizenz: 2.000 $ × 0,8 = %d ¢ (soll 160.000)" % [q0["felder_hq"], e.hq_radius_felder, q0["preis_cent"]])
	ps.lizenz_kaufen(FARM)
	var lz: Dictionary = ps.lizenz_kaufen(MUEHLE)
	var q1: Dictionary = e.buy_quote(m)
	pruef(int(lz.get("bezahlt_cent", -1)) == 14000 and e.s_lic_paid[m] == 14000 and q1["preis_cent"] == 153000,
		"FK-02 P2 Mühle nach Lizenz (%d ¢ gezahlt, s_lic_paid %d): 160.000 − 50 %% = %d ¢ (soll 153.000)" % [int(lz.get("bezahlt_cent", -1)), e.s_lic_paid[m], q1["preis_cent"]])
	var k: Dictionary = e.buy_site(m, ps.konto, ps.credit)
	var c_vor: int = 600000 - 14000
	pruef(k["ok"] and e.cash_cent == c_vor - 153000 and e.owned_count == 1 and e.s_owner[m] == 1 and e.first_discount_used,
		"FK-02 P3 Kauf Mühle: Kasse %d = %d − 153.000, Werke %d, Besitzer %d, über konto.charge (Ausgaben %d)" % [e.cash_cent, c_vor, e.owned_count, e.s_owner[m], ps.konto.expenses_total])
	var f := _site(ps, FARM)
	var q2: Dictionary = e.buy_quote(f)
	var s2 := _soll(100000, q2["felder_hq"], e.hq_radius_felder, 1, false, 0)
	pruef(q2["preis_cent"] == s2 and s2 == 125000,
		"FK-02 P4 2. Werk (Farm, Gratis-Lizenz, 0 ¢ gezahlt): 1.000 $ × 1,25, kein Erstrabatt = %d ¢ (soll %d / 125.000)" % [q2["preis_cent"], s2])
	e.buy_site(f, ps.konto, ps.credit)
	var f2 := _site(ps, FARM2)
	var q3: Dictionary = e.buy_quote(f2)
	var s3 := _soll(100000, q3["felder_hq"], e.hq_radius_felder, 2, false, 0)
	pruef(q3["preis_cent"] == s3, "FK-02 P5 3. Werk (Hasenwinkel, %d Felder vom HQ): × 1,5 = %d ¢ (soll %d)" % [q3["felder_hq"], q3["preis_cent"], s3])
	# Außerhalb des HQ-Radius: HQ nach Lindenfurt (Kleinstadt, Radius 50), frisches Spiel
	var ps2 = _neu()
	var e2 = ps2.eco
	e2.move_hq_to(int(ps2.stationen[STADT]["knoten"]), "kleinstadt")
	var m2 := _site(ps2, MUEHLE)
	var q4: Dictionary = e2.buy_quote(m2)
	var s4 := _soll(200000, q4["felder_hq"], e2.hq_radius_felder, 0, true, 0)
	pruef(q4["felder_hq"] > e2.hq_radius_felder and q4["preis_cent"] == s4,
		"FK-02 P6 Mühle außerhalb Radius (%d > %d Felder, Faktor %d ‰): %d ¢ (soll %d)" % [q4["felder_hq"], e2.hq_radius_felder, q4["faktor_entfernung_promille"], q4["preis_cent"], s4])
	# Anrechnung größer als Preis → 0 (Untergrenze)
	e2.s_lic_paid[m2] = 10000000
	pruef(e2.buy_quote(m2)["preis_cent"] == 0, "FK-02 P7 Anrechnung > Preis: Preis 0 (Untergrenze)")
	e2.s_lic_paid[m2] = 0


func _fk02_ablehnung() -> void:
	var ps = _neu()
	var e = ps.eco
	var m := _site(ps, MUEHLE)
	var c: Dictionary = e.buy_site(_site(ps, DORF))
	e.cash_cent = 150000
	var r1: Dictionary = e.buy_site(m, ps.konto, ps.credit)
	e.cash_cent = 200000
	ps.credit.loan_cent = 50000
	var r2: Dictionary = e.buy_site(m, ps.konto, ps.credit)
	ps.credit.loan_cent = 0
	e.s_owner[m] = 2
	var r3: Dictionary = e.buy_site(m, ps.konto, ps.credit)
	e.s_owner[m] = 0
	var cash0: int = e.cash_cent
	var ok4: Dictionary = e.buy_site(m, ps.konto, ps.credit)
	var r4: Dictionary = e.buy_site(m, ps.konto, ps.credit)
	pruef(c["fehler"] == "kein_betrieb" and r1["fehler"] == "guthaben_reicht_nicht" and r2["fehler"] == "kredit_sperrt_firmenkauf"
		and r3["fehler"] == "besitzer_reserviert" and ok4["ok"] and r4["fehler"] == "schon_gekauft" and e.cash_cent == cash0 - 160000,
		"FK-02 A1 Ablehnungen: Stadt %s, 1.500 $ < 1.600 $ %s, 2.000 $ mit 500 $ Kredit %s, Besitzer 2 %s, zweimal %s; nur der gültige Kauf bucht" % [
		c["fehler"], r1["fehler"], r2["fehler"], r3["fehler"], r4["fehler"]])


# ====================================================================== FK-02 Besitz, Lizenz, Marge

func _mehl_menge(ps, ab_tick: int) -> int:
	var n := 0
	for l in ps.lieferungen:
		if l["gut"] == "mehl" and int(l["tick"]) >= ab_tick:
			n += int(l["menge"])
	return n


func _fk02_besitz_lizenz() -> void:
	# a) Ohne Lizenz und ohne Besitz lädt die Mühle nicht (L_WAIT); mit Besitz lädt sie.
	var pa = _neu()
	pa.lizenz_kaufen(FARM)
	pa.linie_anlegen(FARM, MUEHLE)
	pa.linie_anlegen(MUEHLE, DORF)
	var pb = _neu()
	pb.lizenz_kaufen(FARM)
	pb.linie_anlegen(FARM, MUEHLE)
	pb.linie_anlegen(MUEHLE, DORF)
	var kb: Dictionary = pb.eco.buy_site(_site(pb, MUEHLE), pb.konto, pb.credit)
	_bis(pa, 4000)
	_bis(pb, 4000)
	pruef(_mehl_menge(pa, 0) == 0 and kb["ok"] and _mehl_menge(pb, 0) > 0 and pb.eco.s_lic_until[_site(pb, MUEHLE)] == -1,
		"FK-02 B1 load_gate: ohne Lizenz/Besitz %d Mehl, gekauft ohne Lizenz %d Mehl (s_lic_until %d)" % [_mehl_menge(pa, 0), _mehl_menge(pb, 0), pb.eco.s_lic_until[_site(pb, MUEHLE)]])
	# b) Lizenz gekauft, dann Werk gekauft: keine Verlängerung der Mühle nach Ablauf (18.000 Ticks), Farm wird verlängert.
	var pc = _neu()
	var e = pc.eco
	pc.lizenz_kaufen(FARM)
	pc.lizenz_kaufen(MUEHLE)
	pc.linie_anlegen(FARM, MUEHLE)
	pc.linie_anlegen(MUEHLE, DORF)
	_bis(pc, 3000)
	var m := _site(pc, MUEHLE)
	var paid0: int = e.licence_paid_total
	var k: Dictionary = e.buy_site(m, pc.konto, pc.credit)
	var t_kauf: int = pc.sim.tick_count
	_bis(pc, 19200)
	var ev_m := 0
	var ev_f := 0
	for ev in e.lic_events:
		if ev["site"] == m:
			ev_m += 1
		elif ev["site"] == _site(pc, FARM):
			ev_f += 1
	var mehl_nach: int = _mehl_menge(pc, 18000)
	pruef(k["ok"] and ev_m == 0 and ev_f == 1 and mehl_nach > 0 and e.licence_paid_total - paid0 == e.s_lic_paid[_site(pc, FARM)],
		"FK-02 B2 nach Kauf (Tick %d): Mühle 0 Verlängerungen (%d), Farm 1 (%d, %d ¢), Mehl nach Tick 18.000: %d E" % [t_kauf, ev_m, ev_f, e.s_lic_paid[_site(pc, FARM)], mehl_nach])
	# c) Werksmarge 15 % auf Mehl (Ursprung = eigenes Werk), keine Marge auf Getreide (Ursprung Farm, nicht gekauft).
	var n_mehl := 0
	var bad := 0
	var n_getr := 0
	var bad_g := 0
	for l in e.ledger:
		if int(l["tick"]) <= t_kauf:
			continue
		var g: int = e.g_index[l["gut"]]
		if l["ursprung"] == m:
			n_mehl += 1
			if l["cent"] != e.yield_cent(g, l["felder"], l["f_zeit"], l["f_saett_summe"], 150) or (l["cent"] > 0 and l["cent"] == e.yield_cent(g, l["felder"], l["f_zeit"], l["f_saett_summe"])):
				bad += 1
		else:
			n_getr += 1
			if l["cent"] != e.yield_cent(g, l["felder"], l["f_zeit"], l["f_saett_summe"]):
				bad_g += 1
	pruef(n_mehl > 0 and bad == 0 and n_getr > 0 and bad_g == 0,
		"FK-02 B3 Werksmarge: %d Mehl-Buchungen mit +150 ‰ (%d Abweichungen), %d Getreide-Buchungen ohne Marge (%d)" % [n_mehl, bad, n_getr, bad_g])


# ====================================================================== FK-02 Ausbau, Unterhalt

func _mehl_produktion(rate_ticks: int, stufe2: bool) -> int:
	var ps = _neu()
	var e = ps.eco
	var m := _site(ps, MUEHLE)
	e.buy_site(m, ps.konto, ps.credit)
	if stufe2:
		e.upgrade_site(m, ps.konto, ps.credit)
	e.s_inbuf[m][e.g_index["getreide"]] = 10000
	e._activate_if_ready(m)
	var k: int = e.s_station[m]
	var s0: int = ps.sim.st_stock[k]
	_bis(ps, ps.sim.tick_count + rate_ticks)
	return ps.sim.st_stock[k] - s0


func _fk02_ausbau_unterhalt() -> void:
	var ps = _neu()
	var e = ps.eco
	var m := _site(ps, MUEHLE)
	var u0: Dictionary = e.upgrade_quote(m)
	e.buy_site(m, ps.konto, ps.credit)
	var up_f: Dictionary = e.upgrade_quote(_site(ps, FARM))
	var q: Dictionary = e.upgrade_quote(m)
	var c0: int = e.cash_cent
	var x0: int = ps.konto.expenses_total
	var u: Dictionary = e.upgrade_site(m, ps.konto, ps.credit)
	var u2: Dictionary = e.upgrade_site(m, ps.konto, ps.credit)
	pruef(u0["fehler"] == "nicht_im_besitz" and q["kosten_cent"] == 200000 and q["durchsatz_neu"] == 40 and u["ok"]
		and e.cash_cent == c0 - 200000 and ps.konto.expenses_total == x0 + 200000 and e.s_rate[m] == 40 and e.s_werksstufe[m] == 2 and u2["fehler"] == "hoechste_stufe",
		"FK-02 C1 Ausbau: vor Kauf %s, Kosten %d ¢, Durchsatz %d → s_rate %d, Stufe %d, über konto.charge; erneut %s" % [
		u0["fehler"], q["kosten_cent"], q["durchsatz_neu"], e.s_rate[m], e.s_werksstufe[m], u2["fehler"]])
	pruef(up_f["fehler"] == "nicht_im_besitz", "FK-02 C2 Farm ohne Besitz: %s" % up_f["fehler"])
	var p1 := _mehl_produktion(6000, false)
	var p2 := _mehl_produktion(6000, true)
	# ±1 E: Öko-Tick-Phase der Mühle (Bucket site mod oeko_tick_ticks) gegen Fensterbeginn
	pruef(absi(p1 - 200) <= 1 and absi(p2 - 400) <= 1, "FK-02 C3 Mühle mit vollem Eingang, 6.000 Ticks (10 min): Stufe 1 %d Mehl (soll 200 ± 1), Stufe 2 %d (soll 400 ± 1)" % [p1, p2])
	var up: int = e.works_upkeep_cent_pro_periode()
	var k = Konto.new(e)
	var cash1: int = e.cash_cent
	k.fix_neu([], up, 0)
	for t in 600:
		k.tick(t + 1, ps.credit)
	pruef(up == 4000 and k.expenses_total == 4000 and e.cash_cent == cash1 - 4000,
		"FK-02 C4 Unterhalt Mühle Stufe 2: %d ¢/Periode (20 $ × 2), über konto.fix_neu/tick in 600 Ticks gebucht %d ¢" % [up, k.expenses_total])
	var ps3 = _neu()
	var f3 := _site(ps3, FARM)
	ps3.eco.buy_site(f3, ps3.konto, ps3.credit)
	pruef(ps3.eco.upgrade_quote(f3)["fehler"] == "nur_verarbeiter", "FK-02 C5 Farm gekauft, Ausbau: %s (S8 nur Verarbeiter)" % ps3.eco.upgrade_quote(f3)["fehler"])


# ====================================================================== FK-02 Prüfsumme

func _kette(ps) -> void:
	ps.lizenz_kaufen(FARM)
	ps.lizenz_kaufen(MUEHLE)
	ps.linie_anlegen(FARM, MUEHLE)
	ps.linie_anlegen(MUEHLE, DORF)


func _fk02_pruefsumme() -> void:
	var a = _neu()
	var b = _neu()
	_kette(a)
	_kette(b)
	_bis(a, 3000)
	_bis(b, 3000)
	var ha: int = a.pruefsumme()
	var hb: int = b.pruefsumme()
	b.eco.s_owner[_site(b, MUEHLE)] = 1
	var hb1: int = b.pruefsumme()
	b.eco.s_owner[_site(b, MUEHLE)] = 0
	var hb0: int = b.pruefsumme()
	b.eco.s_werksstufe[_site(b, MUEHLE)] = 2
	var hb2: int = b.pruefsumme()
	b.eco.s_werksstufe[_site(b, MUEHLE)] = 1
	pruef(ha == hb and hb1 != hb and hb0 == hb and hb2 != hb,
		"FK-02 D1 Prüfsumme: gleich ohne Kauf (%d), Besitzer 1 ändert sie, zurück auf 0 wieder gleich, Werksstufe 2 ändert sie" % ha)


# ====================================================================== FK-02 Puffer-Deckel, Rückfall W3

func _puffer_lauf(deckel: int) -> Dictionary:
	var ps = _neu()
	var e = ps.eco
	# Felix 05.11.: ProtoSim wendet economy_proto.json seit der FK-02-Verdrahtung selbst an (Deckel 2); "ohne" setzt 0 ausdrücklich
	e.apply_proto({"firmenkauf_c1": {"eingangspuffer_deckel_perioden": deckel}})
	ps.lizenz_kaufen(FARM)
	ps.lizenz_kaufen(FARM2)
	ps.lizenz_kaufen(MUEHLE)
	for x in 2:
		ps.linie_anlegen(FARM, MUEHLE)
		ps.linie_anlegen(FARM2, MUEHLE)
	var m := _site(ps, MUEHLE)
	var gi: int = e.g_index["getreide"]
	var mx := 0
	var voll_tick := -1
	while ps.sim.tick_count < 9000:
		ps.tick()
		mx = maxi(mx, int(e.s_inbuf[m][gi]))
		if voll_tick < 0 and e.inbuf_full(m):
			voll_tick = ps.sim.tick_count
	var getr := 0
	var cent := 0
	for l in e.ledger:
		if l["ziel"] == m:
			getr += int(l["menge"])
			cent += int(l["cent"])
	return {"max": mx, "voll": voll_tick, "getreide": getr, "cent": cent}


func _fk02_puffer_w3() -> void:
	var ohne := _puffer_lauf(0)
	var mit := _puffer_lauf(2)
	print("    Puffer: ohne Deckel max %d E, %d Getreide bezahlt (%d ¢); Deckel 2 Perioden max %d E, %d Getreide (%d ¢), voll ab Tick %d" % [
		ohne["max"], ohne["getreide"], ohne["cent"], mit["max"], mit["getreide"], mit["cent"], mit["voll"]])
	pruef(ohne["max"] > 40 and mit["max"] <= 40 and mit["voll"] > 0 and mit["getreide"] < ohne["getreide"],
		"FK-02 E1 Mühlen-Eingangspuffer (2 Farmen, 4 Fuhrwerke, 9.000 Ticks): ohne Deckel max %d E, mit Deckel max %d ≤ 40, Ereignis 7 ab Tick %d" % [ohne["max"], mit["max"], mit["voll"]])
	var ps = _neu()
	var m := _site(ps, MUEHLE)
	var r0: int = ps.eco.s_rate[m]
	ps.eco.apply_proto({"firmenkauf_c1": {"rueckfall_w3_muehle_durchsatz_einheiten_pro_periode": 40}})
	pruef(r0 == 20 and ps.eco.s_rate[m] == 40, "FK-02 E2 Rückfall W3 (economy_proto.json): Mühle %d → %d E/min ohne Kauf" % [r0, ps.eco.s_rate[m]])
	var proto = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy_proto.json"))
	var c: Dictionary = proto.get("firmenkauf_c1", {})
	pruef(int(c.get("rueckfall_w3_muehle_durchsatz_einheiten_pro_periode", -1)) == 0 and int(proto.get("tempo_ausgleich_promille", -1)) == 1000,
		"FK-02 E3 economy_proto.json: Rückfall W3 aus (0), Faktor a = %d (bleibt 1.000 bis OE-02)" % int(proto.get("tempo_ausgleich_promille", -1)))
