extends SceneTree
## Demo-Sprint: System- und Unit-Tests für proto/demo_sim.gd (Gates B, C, D, E der Demo).
##   godot --headless --path slice -s res://tests/demo_sim_test.gd
## B Ketten-Validator (jedes Gut Quelle + Abnehmer, jede Kette Rohstoff → Ort, jede Kante befahr-/anschließbar)
## C Straße/Gleis bauen, anschließen, befahren; ungültige Anschlüsse mit Fehlercode
## D Verträge, Firmensitz, Skilltree (Wirkung = Spielwert, Punkte nur aus Meilensteinen, Respec)
## E Fahrzeug-Generationen und Ersetzen im 30-min-Fenster; Determinismus (Prüfsumme)

const DemoSim := preload("res://proto/demo_sim.gd")
const SZENE := "res://proto/prototyp_welt.tscn"
const FARM := "Gut Kuppenhof"
const MUEHLE := "Erlenmühle"
const DORF := "Erlenbach"
const STADT := "Lindenfurt"
const FORST := "Forsthaus Rotwald"
const SAEGE := "Sägemühle am Teich"
const KOHLE := "Kohlegrube Schwarzgrund"
const ERZ := "Erzgrube Silberkuppe"
const HUETTE := "Rotachhütte"
const SCHMIEDE := "Hammerschmiede"
const HQ_DORF := Vector2(1668, 688)

var n_ok := 0
var n_fail := 0
var szene: Node
var orte: Dictionary


func _initialize() -> void:
	_run.call_deferred()


func pruef(ok: bool, text: String) -> void:
	if ok:
		n_ok += 1
	else:
		n_fail += 1
	print("  %s %s" % ["OK  " if ok else "FAIL", text])


func _neu(mit_hq := true, seed_nr := 1):
	var ps = DemoSim.new(szene.regelwerk)
	ps.vertrag_seed = seed_nr
	ps.graph_bauen(szene.strassen)
	ps.spiel_starten(orte)
	if mit_hq:
		ps.hq_platzieren(HQ_DORF)
	return ps


func _bis(ps, t: int) -> void:
	while ps.sim.tick_count < t and not ps.konto.bankrupt:
		ps.tick()


func _pkt(l) -> PackedVector2Array:
	var p := PackedVector2Array()
	for q in l:
		p.append(Vector2(float(q[0]), float(q[1])))
	return p


func _vorschlag(ps, art: String, key: String) -> PackedVector2Array:
	var v = ps.daten["bau_vorschlag"][art][key]
	if v is String:
		return PackedVector2Array([ps.halt_pos(key), ps.naechster_strassenknoten(ps.halt_pos(key))])
	return _pkt(v)


func _run() -> void:
	print("demo_sim_test")
	szene = (load(SZENE) as PackedScene).instantiate()
	szene.set("sim_aus", true)
	root.add_child(szene)
	await process_frame
	orte = JSON.parse_string(FileAccess.get_file_as_string(szene.datei("proto_orte.json")))
	_b_ketten()
	_c_strasse()
	_c_gleis()
	_d_hq()
	_d_skills()
	_d_vertraege()
	_e_fahrzeuge()
	_parity()
	print("demo_sim_test: %d/%d Prüfungen OK" % [n_ok, n_ok + n_fail])
	quit(0 if n_fail == 0 else 1)


# ------------------------------------------------------------------ B Ketten

func _b_ketten() -> void:
	var ps = _neu()
	var e = ps.eco
	pruef(ps.fehler.is_empty() and ps.tempo_k == 8 and e.oe_set == "k8d", "B0 Demo-Start ohne Fehler, tempo_k %d, Satz %s, %d Stationen" % [ps.tempo_k, e.oe_set, ps.stationen.size()])
	var quelle := {}
	var senke := {}
	for nm in ps.stationen:
		var s: int = ps.stationen[nm]["site"]
		if e.s_kind[s] == 0:
			if e.s_out_good[s] >= 0:
				quelle[String(e.g_ids[e.s_out_good[s]])] = true
			for gi in e.s_inbuf[s]:
				senke[String(e.g_ids[gi])] = true
		elif e.s_kind[s] == 1:
			for gi in e.g_ids.size():
				if e.city_accepts(s, gi) and quelle.has(String(e.g_ids[gi])) or e.city_accepts(s, gi):
					senke[String(e.g_ids[gi])] = true
	var verstoss: Array = []
	var gueter := {}
	for g in quelle:
		gueter[g] = true
	for nm in ps.stationen:
		var s2: int = ps.stationen[nm]["site"]
		if e.s_kind[s2] == 0:
			for gi in e.s_inbuf[s2]:
				gueter[String(e.g_ids[gi])] = true
	for g in gueter:
		if not quelle.has(g):
			verstoss.append("%s ohne Quelle" % g)
		if not senke.has(g):
			verstoss.append("%s ohne Abnehmer" % g)
	pruef(verstoss.is_empty() and gueter.size() == 8, "B1 %d Güter der Demo-Karte, jedes mit Quelle und Abnehmer; Verstöße: %s" % [gueter.size(), str(verstoss)])
	# B2: jede Kette endet in einem Ort (Rohstoff → … → Stadt/Dorf)
	var kanten: Array = ps.kanten()
	var erreicht_ort := {}
	var wechsel := true
	while wechsel:
		wechsel = false
		for k in kanten:
			var sb: int = ps.stationen[k["nach"]]["site"]
			var ok: bool = e.s_kind[sb] == 1 or erreicht_ort.has(k["nach"])
			if ok and not erreicht_ort.has(k["von"]):
				erreicht_ort[k["von"]] = true
				wechsel = true
	var v2: Array = []
	var n_ind := 0
	for nm in ps.stationen:
		var s3: int = ps.stationen[nm]["site"]
		if e.s_kind[s3] == 0:
			n_ind += 1
			if not erreicht_ort.has(nm):
				v2.append(nm)
	pruef(v2.is_empty() and n_ind == 9, "B2 alle %d Betriebe liefern über die Kette bis in einen Ort; Verstöße: %s" % [n_ind, str(v2)])
	# B3: nach den geprüften Trassen ist jede Kante befahrbar (Straße), die Gleis-Kanten zusätzlich per Gleis
	ps.eco.cash_cent = 5000000
	var v3: Array = []
	for nm in ps.daten["bau_vorschlag"]["strasse"]:
		if ps.angeschlossen(nm):
			v3.append("%s schon angeschlossen" % nm)
			continue
		var r: Dictionary = ps.bauen("strasse", _vorschlag(ps, "strasse", nm))
		if not r.get("ok", false) or not ps.angeschlossen(nm):
			v3.append("%s: %s" % [nm, r.get("fehler", "nicht angeschlossen")])
	_bis(ps, 7200)
	for key in ps.daten["bau_vorschlag"]["gleis"]:
		var teile: PackedStringArray = String(key).split(">")
		var r2: Dictionary = ps.bauen("gleis", _vorschlag(ps, "gleis", key))
		if not r2.get("ok", false) or ps.gleisroute(teile[0], teile[1]).is_empty():
			v3.append("Gleis %s: %s" % [key, r2.get("fehler", "keine Gleisroute")])
	for k in kanten:
		if ps.strassenroute(k["von"], k["nach"]).is_empty():
			v3.append("keine Straße %s → %s" % [k["von"], k["nach"]])
	pruef(v3.is_empty() and kanten.size() == 12, "B3 %d Kanten: alle per Straße befahrbar, 2 zusätzlich per Gleis; Verstöße: %s" % [kanten.size(), str(v3)])
	pruef(ps.fehler.is_empty(), "B4 0 Sim-Fehler nach allen Bauten: %s" % str(ps.fehler))


# ------------------------------------------------------------------ C Straße / Gleis

func _c_strasse() -> void:
	var ps = _neu()
	pruef(not ps.angeschlossen(FORST) and ps.linie_anlegen(FORST, SAEGE).get("fehler", "") == "keine_verbindung",
		"C1 Forsthaus ohne Straße: Linie abgelehnt (keine_verbindung)")
	var fehl := {
		"kein_anschluss": [Vector2(900, 1300), Vector2(1000, 1300)],
		"see": [Vector2(1282, 938), Vector2(1050, 1250)],
		"zu_kurz": [Vector2(2005, 545), Vector2(2032, 545)],
		"zu_steil": [Vector2(1050, 1250), Vector2(1500, 1600)],
		"gleicher_punkt": [Vector2(1282, 938), Vector2(1200, 900), Vector2(1284, 940)],
		"zu_wenig_punkte": [Vector2(1282, 938)],
	}
	var falsch: Array = []
	for code in fehl:
		var r: Dictionary = ps.bau_angebot("strasse", PackedVector2Array(fehl[code]))
		if r.get("ok", false) or String(r.get("fehler", "")) != code:
			falsch.append("%s → %s" % [code, str(r.get("fehler", "ok"))])
	pruef(falsch.is_empty(), "C2 ungültige Trassen geben je einen klaren Fehlercode (%d Fälle); falsch: %s" % [fehl.size(), str(falsch)])
	var weg := _vorschlag(ps, "strasse", FORST)
	var q: Dictionary = ps.bau_angebot("strasse", weg)
	var kasse: int = ps.eco.cash_cent
	ps.eco.cash_cent = 100
	var arm: Dictionary = ps.bauen("strasse", weg)
	ps.eco.cash_cent = kasse
	var r2: Dictionary = ps.bauen("strasse", weg)
	pruef(arm.get("fehler", "") == "guthaben_reicht_nicht" and r2.get("ok", false) and kasse - ps.eco.cash_cent == int(q["kosten_cent"]) and int(q["kosten_cent"]) == int(q["felder"]) * 2500,
		"C3 Straße gebaut: %d m, %d Felder, Kasse −%d ¢ = Vorschau; ohne Geld abgelehnt" % [int(q["laenge_m"]), int(q["felder"]), kasse - ps.eco.cash_cent])
	pruef(ps.angeschlossen(FORST) and not ps.strassenroute(FORST, SAEGE).is_empty() and String(r2["nach"]) == FORST,
		"C4 Forsthaus angeschlossen, Route zur Sägemühle über %d Kanten" % ps.strassenroute(FORST, SAEGE).size())
	ps.lizenz_kaufen(FORST)
	var l: Dictionary = ps.linie_anlegen(FORST, SAEGE)
	_bis(ps, 2400)
	var holz := 0
	for li in ps.lieferungen:
		if li["gut"] == "holz":
			holz += int(li["menge"])
	pruef(l.get("ok", false) and holz > 0 and ps.fehler.is_empty(), "C5 Fuhrwerk befährt die neue Straße: %d Holz an der Sägemühle nach 4 min, 0 Sim-Fehler" % holz)
	# Straße an Straße (zweiter Bau rastet an der selbst gebauten ein) und Brücke über den Fluss
	var q3: Dictionary = ps.bau_angebot("strasse", PackedVector2Array([Vector2(1330, 1100), Vector2(1450, 1200)]))
	pruef(q3.get("ok", false) and String(q3["start"]["typ"]) == "knoten" and String(q3["ende"]["typ"]) == "frei",
		"C6 Abzweig von der eigenen Straße rastet am Knoten ein (Start %s, Ende %s)" % [str(q3.get("start", {}).get("typ", "")), str(q3.get("ende", {}).get("typ", ""))])
	var qb: Dictionary = ps.bau_angebot("strasse", PackedVector2Array([Vector2(1010, 805), Vector2(1000, 450), Vector2(1000, 380)]))
	pruef(qb.get("ok", false) and int(qb["bruecke_m"]) > 0 and int(qb["kosten_cent"]) > int(qb["felder"]) * 2500,
		"C7 Trasse über die Rotach: Brücke %d m, Kosten %d ¢ > %d ¢ ohne Brücke" % [int(qb.get("bruecke_m", 0)), int(qb.get("kosten_cent", 0)), int(qb.get("felder", 0)) * 2500])
	ps.eco.cash_cent = 5000000
	var rb: Dictionary = ps.bauen("strasse", PackedVector2Array([Vector2(1010, 805), Vector2(1000, 450), Vector2(1000, 380)]))
	pruef(rb.get("ok", false) and ps.fehler.is_empty(), "C8 Brückenstraße gebaut, Chaussee-Anschluss Nordufer: %s" % str(rb.get("text", rb.get("fehler", ""))))


func _c_gleis() -> void:
	var ps = _neu()
	ps.eco.cash_cent = 5000000
	var gk := _vorschlag(ps, "gleis", KOHLE + ">" + HUETTE)
	var frueh: Dictionary = ps.bau_angebot("gleis", gk)
	pruef(frueh.get("fehler", "") == "noch_nicht_verfuegbar" and int(frueh.get("ab_jahr", 0)) == 1824 and not ps.gleis_frei(),
		"C9 Gleis vor 1824 gesperrt (ab_jahr %d)" % int(frueh.get("ab_jahr", 0)))
	_bis(ps, 7200)
	pruef(ps.gleis_frei() and ps.kalenderjahr() == 1824, "C10 Gleis frei ab 1824 = Minute 12")
	var knick: Dictionary = ps.bau_angebot("gleis", PackedVector2Array([Vector2(370, 1235), Vector2(600, 1235), Vector2(560, 1000), Vector2(985, 1020)]))
	var frei: Dictionary = ps.bau_angebot("gleis", PackedVector2Array([Vector2(600, 600), Vector2(700, 600)]))
	pruef(knick.get("fehler", "") == "kurve_zu_eng" and frei.get("fehler", "") == "kein_anschluss",
		"C11 Gleis: Knick %s° abgelehnt (kurve_zu_eng), ohne Bahnhof/Gleis abgelehnt (kein_anschluss)" % str(knick.get("grad", "?")))
	var q: Dictionary = ps.bau_angebot("gleis", gk)
	var kasse: int = ps.eco.cash_cent
	var r: Dictionary = ps.bauen("gleis", gk)
	pruef(r.get("ok", false) and kasse - ps.eco.cash_cent == int(q["kosten_cent"]) and ps.bahnhof.has(KOHLE) and ps.bahnhof.has(HUETTE),
		"C12 Gleis Kohlegrube → Rotachhütte: %d m, %d ¢, Bahnhöfe an beiden Enden" % [int(q.get("laenge_m", 0)), int(q.get("kosten_cent", 0))])
	pruef(ps.linie_anlegen(KOHLE, HUETTE, "fuhrwerk").get("fehler", "") == "keine_verbindung" and not ps.gleisroute(KOHLE, HUETTE).is_empty(),
		"C13 Fuhrwerk kann das Gleis nicht befahren (keine_verbindung), Gleisroute %d Kanten" % ps.gleisroute(KOHLE, HUETTE).size())
	pruef(ps.linie_anlegen(ERZ, HUETTE, "zug").get("fehler", "") == "kein_bahnhof", "C14 Zug ohne Bahnhof am Start: kein_bahnhof")
	ps.lizenz_kaufen(KOHLE)
	var z: Dictionary = ps.linie_anlegen(KOHLE, HUETTE, "zug")
	var f: Dictionary = ps.fahrzeug(int(z.get("vid", 0)))
	ps._fix_neu()
	var fix_mit: int = ps.konto.running_cost_per_period
	var fix_zug: int = ps.fix_eff(f)
	_bis(ps, 7200 + 3000)
	var kohle := 0
	for li in ps.lieferungen:
		if li["gut"] == "kohle":
			kohle += int(li["menge"])
	pruef(z.get("ok", false) and ps.ist_zug(f) and String(f["kat"]) == "pferdebahn" and kohle >= 60 and ps.fehler.is_empty(),
		"C15 Pferdebahn fährt: %d Kohle an der Hütte nach 5 min, Ladung %d E, 0 Sim-Fehler" % [kohle, ps.sim.v_cargo_cap[ps.sim.slot_of(f["vid"])]])
	pruef(fix_mit == fix_zug + int(q["unterhalt_cent"]) and int(q["unterhalt_cent"]) == int(q["felder"]) * 30,
		"C16 Gleisunterhalt läuft über konto: Fix %d ¢/min = Zug %d + Gleis %d" % [fix_mit, fix_zug, int(q["unterhalt_cent"])])
	# Gleis an Gleis verlängern und Brücke
	var ge := _vorschlag(ps, "gleis", ERZ + ">" + HUETTE)
	var r2: Dictionary = ps.bauen("gleis", ge)
	pruef(r2.get("ok", false) and String(ps.bau_angebot("gleis", gk).get("fehler", "")) != "" or r2.get("ok", false),
		"C17 zweites Gleis Erzgrube → Hütte endet im bestehenden Bahnhof: %s" % str(r2.get("text", r2.get("fehler", ""))))
	pruef(not ps.gleisroute(ERZ, HUETTE).is_empty() and not ps.gleisroute(ERZ, KOHLE).is_empty(),
		"C18 Gleisnetz verbunden: Erzgrube → Kohlegrube über den Bahnhof Hütte (%d Kanten)" % ps.gleisroute(ERZ, KOHLE).size())


# ------------------------------------------------------------------ D Firmensitz

func _d_hq() -> void:
	var ps = _neu(false)
	pruef(ps.lizenz_kaufen(FARM).get("fehler", "") == "kein_hq" and ps.linie_anlegen(FARM, MUEHLE).get("fehler", "") == "kein_hq"
		and ps.aktionen_moeglich() == ["hq"], "D1 ohne Firmensitz lehnt die Spieler-API ab (kein_hq), einzige Aktion: hq")
	var ps0: int = ps.pruefsumme()
	var v: Dictionary = ps.hq_vorschau(HQ_DORF)
	var vs: Dictionary = ps.hq_vorschau(Vector2(160, 150))
	var vw: Dictionary = ps.hq_vorschau(Vector2(735, 835))
	pruef(v["ok"] and vs["ok"] and vw["ok"] and ps.pruefsumme() == ps0 and not ps.hq_platziert, "D2 Vorschau ändert nichts (Prüfsumme gleich)")
	pruef(int(v["im_radius_n"]) > int(vs["im_radius_n"]) and int(v["lizenz_summe_cent"]) < int(vs["lizenz_summe_cent"]) and int(vs["heimat_bonus_promille"]) == 150
		and int(v["heimat_bonus_promille"]) == 100 and int(vw["heimat_bonus_promille"]) == 0 and String(vw["ort"]) == "Hasenwinkel",
		"D3 Standortvorteile unterscheiden sich: Erlenbach %d Betriebe im Radius/Lizenzen %d $, Lindenfurt %d/%d $ (+15 %% Heimat), Hasenwinkel %d/%d $" % [
			int(v["im_radius_n"]), int(v["lizenz_summe_cent"]) / 100, int(vs["im_radius_n"]), int(vs["lizenz_summe_cent"]) / 100, int(vw["im_radius_n"]), int(vw["lizenz_summe_cent"]) / 100])
	var fehl := {"kein_ort": Vector2(1000, 500), "auf_der_strasse": Vector2(1625, 730)}
	var falsch: Array = []
	for code in fehl:
		if String(ps.hq_vorschau(fehl[code]).get("fehler", "")) != code:
			falsch.append(code)
	pruef(falsch.is_empty(), "D4 ungültige Plätze: kein_ort, auf_der_strasse; falsch: %s" % str(falsch))
	var r: Dictionary = ps.hq_platzieren(HQ_DORF)
	var site: int = ps.stationen[FARM]["site"]
	var lic: int = int(ps.eco.licence_quote(site, false)["kosten_cent"])
	var soll := -1
	for b in v["betriebe"]:
		if b["name"] == FARM:
			soll = int(b["lizenz_cent"])
	pruef(r["ok"] and ps.hq_platziert and ps.hq_ort == DORF and lic == soll and ps.eco.cash_cent == 600000 and ps.meilensteine_erreicht.is_empty(),
		"D5 platziert in Erlenbach, kostenlos; Lizenz Gut Kuppenhof %d ¢ = Vorschau" % lic)
	# Heimatbonus: gleiche Lieferung, einmal mit HQ in Erlenbach, einmal in Hasenwinkel
	var cent := []
	for p in [HQ_DORF, Vector2(735, 835)]:
		var a = _neu(false)
		a.hq_platzieren(p)
		a.eco.cash_cent = 2000000
		a.lizenz_kaufen(FARM)
		a.lizenz_kaufen(MUEHLE)
		a.linie_anlegen(FARM, MUEHLE)
		a.linie_anlegen(MUEHLE, DORF)
		_bis(a, 2400)
		var c := 0
		var m := 0
		for le in a.eco.ledger:
			if le["gut"] == "mehl" and m == 0:
				c = int(le["cent"])
				m = int(le["menge"])
		cent.append([c, m])
	pruef(cent[0][1] == cent[1][1] and cent[0][1] > 0 and absi(cent[0][0] * 1000 - cent[1][0] * 1100) <= 1100,
		"D6 Heimatort-Bonus: erste Mehlfuhre Erlenbach %d ¢ mit HQ dort, %d ¢ ohne (+10 %%)" % [cent[0][0], cent[1][0]])
	_bis(ps, 20)
	pruef(ps.meilensteine_erreicht.has("hq") and ps.skillpunkte == 1, "D7 Meilenstein Firmensitz: +1 Skillpunkt")
	# Ausbau und Anbauten
	var q: Dictionary = ps.hq_ausbau_angebot()
	var lim0: int = ps.credit.limit_cent
	var rad0: int = ps.eco.hq_radius_felder
	ps.eco.cash_cent = 100000
	var arm: Dictionary = ps.hq_ausbauen()
	var a1: Dictionary = ps.hq_anbauen("remise")
	var a2: Dictionary = ps.hq_anbauen("stall")
	ps.eco.cash_cent = 1000000
	var kasse: int = ps.eco.cash_cent
	var r2: Dictionary = ps.hq_ausbauen()
	pruef(arm.get("fehler", "") == "guthaben_reicht_nicht" and r2["ok"] and kasse - ps.eco.cash_cent == int(q["kosten_cent"]) and ps.hq_stufe == 2
		and ps.credit.limit_cent == lim0 + 100000 and ps.eco.hq_radius_felder == rad0 + 8 and ps.vertraege_max() == 3,
		"D8 Ausbau Handelshaus: −%d ¢, Radius %d → %d Felder, Kreditrahmen +1.000 $, 3 Verträge" % [int(q["kosten_cent"]), rad0, ps.eco.hq_radius_felder])
	var a3: Dictionary = ps.hq_anbauen("stall")
	var a4: Dictionary = ps.hq_anbauen("schreibstube")
	pruef(a1["ok"] and a2.get("fehler", "") == "kein_platz" and a3["ok"] and a4.get("fehler", "") == "kein_platz" and ps.hq_anbauen("remise").get("fehler", "") == "schon_gebaut",
		"D9 Anbauten: Stufe 1 ein Platz, Stufe 2 zwei; doppelt abgelehnt")
	var d: Dictionary = ps.vdef("fuhrwerk_d")
	pruef(ps._preis(d) == 36000 and ps.bonus("fz_fix_pm") == 100, "D10 Remise wirkt: Fuhrwerk %d ¢ statt 40.000; Stall: Unterhalt −10 %%" % ps._preis(d))
	var k2: int = ps.eco.cash_cent
	var um: Dictionary = ps.hq_platzieren(Vector2(160, 150))
	pruef(um["ok"] and k2 - ps.eco.cash_cent == 50000 and ps.hq_ort == STADT and ps.hq_stufe == 2, "D11 Umzug nach Lindenfurt kostet 500 $, Stufe bleibt")


# ------------------------------------------------------------------ D Skilltree

func _d_skills() -> void:
	var ps = _neu()
	pruef(ps.skillpunkte == 0 and ps.skill_setzen("stellmacher").get("fehler", "") == "kein_punkt", "D12 ohne Meilenstein kein Punkt (kein_punkt)")
	_bis(ps, 20)
	pruef(ps.skill_setzen("futtermeister").get("fehler", "") == "vorgaenger_fehlt" and ps.skill_setzen("gibtsnicht").get("fehler", "") == "unbekannter_skill",
		"D13 Rang 2 ohne Rang 1 abgelehnt (vorgaenger_fehlt)")
	ps.skillpunkte = 12
	var e = ps.eco
	var d: Dictionary = ps.vdef("fuhrwerk_d")
	var zd: Dictionary = ps.vdef("pferdebahn_d")
	var sd: int = ps.stationen[DORF]["site"]
	var sm: int = ps.stationen[MUEHLE]["site"]
	var sf: int = ps.stationen[FARM]["site"]
	var g_mehl: int = e.g_index["mehl"]
	var g_br: int = e.g_index["bretter"]
	ps.lizenz_kaufen(FARM)
	ps.linie_anlegen(FARM, MUEHLE)
	var f: Dictionary = ps.fahrzeuge[0]
	var weg := _vorschlag(ps, "strasse", FORST)
	var basis := {"preis": ps._preis(d), "fix": ps.fix_eff(f), "kap": ps._kap(d), "kap_zug": ps._kap(zd), "bau": int(ps.bau_angebot("strasse", weg)["kosten_cent"]),
		"bedarf": e.city_demand(sd), "rate": int(e.s_rate[sm]), "lizenz": int(e.licence_quote(sm, false)["kosten_cent"]), "limit": ps.credit.limit_cent,
		"zins": ps.credit.interest_pm, "ertrag": e.yield_cent(g_mehl, 20, 1000, 20000, e._demo_extra(sd, g_mehl)), "ertrag_br": e.yield_cent(g_br, 20, 1000, 20000, e._demo_extra(sd, g_br)),
		"upkeep": e.upkeep_per_level, "cap_slot": ps.sim.v_cargo_cap[ps.sim.slot_of(f["vid"])]}
	var falsch: Array = []
	for id in ["stellmacher", "futtermeister", "ladeflaeche", "eisenbahner", "marktstand", "verhandler", "kornspeicher", "handelshaus", "wegerecht", "mahlrecht", "werksleiter", "bankhaus"]:
		if not ps.skill_setzen(id).get("ok", false):
			falsch.append(id)
	ps._fix_neu()
	var v := {"id": 99, "praemie_cent": 10000}
	var ist := {"preis": ps._preis(d), "fix": ps.fix_eff(f), "kap": ps._kap(d), "kap_zug": ps._kap(zd), "bau": int(ps.bau_angebot("strasse", weg)["kosten_cent"]),
		"bedarf": e.city_demand(sd), "rate": int(e.s_rate[sm]), "lizenz": int(e.licence_quote(sm, false)["kosten_cent"]), "limit": ps.credit.limit_cent,
		"zins": ps.credit.interest_pm, "ertrag": e.yield_cent(g_mehl, 20, 1000, 20000, e._demo_extra(sd, g_mehl)), "ertrag_br": e.yield_cent(g_br, 20, 1000, 20000, e._demo_extra(sd, g_br)),
		"upkeep": e.upkeep_per_level, "cap_slot": ps.sim.v_cargo_cap[ps.sim.slot_of(f["vid"])]}
	print("    Basis %s\n    mit 12 Skills %s" % [str(basis), str(ist)])
	pruef(falsch.is_empty() and ps.skillpunkte_frei() == 0, "D14 alle 12 Knoten in Reihenfolge setzbar; abgelehnt: %s" % str(falsch))
	pruef(ist["preis"] == basis["preis"] * 900 / 1000 and ist["fix"] == basis["fix"] * 850 / 1000 and ist["kap"] == basis["kap"] * 1200 / 1000
		and ist["kap_zug"] == basis["kap_zug"] * 1250 / 1000 and ist["cap_slot"] == ist["kap"],
		"D15 Fuhrpark = Spielwert: Kauf %d → %d ¢, Unterhalt %d → %d ¢, Ladung %d → %d E (fahrendes Fuhrwerk: %d), Zug %d → %d E" % [
			basis["preis"], ist["preis"], basis["fix"], ist["fix"], basis["kap"], ist["kap"], ist["cap_slot"], basis["kap_zug"], ist["kap_zug"]])
	pruef(absi(ist["ertrag"] * 1100 - basis["ertrag"] * 1320) <= 1320 and absi(ist["ertrag_br"] * 1100 - basis["ertrag_br"] * 1200) <= 1200 and e.skill_bonus == 100
		and ist["bedarf"] == e.rdiv(basis["bedarf"] * 1150, 1000) and ps.vertrag_praemie(v) == 12500,
		"D16 Handel = Spielwert (additiv zum Heimatbonus 10 %%): Mehl-Ertrag +22 Punkte (%d → %d ¢), Bretter +10 Punkte (B_skill %d ‰), Bedarf %d → %d, Vertragsprämie +25 %%" % [
			basis["ertrag"], ist["ertrag"], e.skill_bonus, basis["bedarf"], ist["bedarf"]])
	pruef(ist["bau"] == basis["bau"] * 750 / 1000 and ist["lizenz"] * 1000 >= basis["lizenz"] * 795 and ist["lizenz"] * 1000 <= basis["lizenz"] * 805
		and ist["rate"] == basis["rate"] * 1250 / 1000 and ist["upkeep"] == basis["upkeep"] * 700 / 1000 and ist["limit"] == basis["limit"] + 150000 and ist["zins"] == basis["zins"] - 10,
		"D17 Werke & Wege = Spielwert: Straße %d → %d ¢, Lizenz %d → %d ¢, Mühle %d → %d E/min, Werksunterhalt −30 %%, Kredit %d → %d ¢, Zins %d → %d ‰" % [
			basis["bau"], ist["bau"], basis["lizenz"], ist["lizenz"], basis["rate"], ist["rate"], basis["limit"], ist["limit"], basis["zins"], ist["zins"]])
	var rs: Dictionary = ps.skill_zuruecksetzen()
	ps._fix_neu()
	pruef(rs["ok"] and ps.skillpunkte_frei() == 12 and ps._preis(d) == basis["preis"] and ps.fix_eff(f) == basis["fix"] and int(e.s_rate[sm]) == basis["rate"]
		and e.city_demand(sd) == basis["bedarf"] and ps.credit.limit_cent == basis["limit"] and e.skill_bonus == 0 and e.demo_cat_bonus.is_empty()
		and ps.sim.v_cargo_cap[ps.sim.slot_of(f["vid"])] == basis["cap_slot"],
		"D18 Respec: 12 Punkte zurück, alle Werte wieder auf Grundwert")
	# Punkte nur aus Meilensteinen: Plan-Stück spielen und zählen
	var a = _neu()
	a.lizenz_kaufen(FARM)
	a.lizenz_kaufen(MUEHLE)
	a.linie_anlegen(FARM, MUEHLE)
	a.linie_anlegen(MUEHLE, DORF)
	_bis(a, 1800)
	pruef(a.skillpunkte == a.meilensteine_erreicht.size() and a.meilensteine_erreicht.has("mehl") and a.skillpunkte == 2,
		"D19 Punkte = erreichte Meilensteine (%d): %s" % [a.skillpunkte, str(a.meilensteine_erreicht.keys())])


# ------------------------------------------------------------------ D Verträge

func _d_vertraege() -> void:
	var ps = _neu()
	ps.eco.cash_cent = 2000000
	ps.lizenz_kaufen(FARM)
	ps.lizenz_kaufen(MUEHLE)
	ps.linie_anlegen(FARM, MUEHLE)
	ps.linie_anlegen(MUEHLE, DORF)
	_bis(ps, 899)
	var vor: int = ps.vertraege_angebote.size()
	_bis(ps, 900)
	var v: Dictionary = ps.vertraege_angebote[0] if ps.vertraege_angebote.size() > 0 else {}
	pruef(vor == 0 and ps.vertraege_angebote.size() == 1 and String(v.get("ort", "")) == DORF and String(v.get("gut", "")) == "mehl" and int(v.get("menge", 0)) == 30,
		"D20 erstes Angebot bei Tick 900 (Min 1,5): %s will %d %s, Prämie %d ¢, Strafe %d ¢" % [v.get("ort", "?"), int(v.get("menge", 0)), v.get("gut", "?"), int(v.get("praemie_cent", 0)), int(v.get("strafe_cent", 0))])
	var mehl_vor: int = int(ps.geliefert.get("mehl", 0))
	var an: Dictionary = ps.vertrag_annehmen(int(v["id"]))
	pruef(an["ok"] and ps.vertraege_aktiv.size() == 1 and ps.vertraege_angebote.is_empty() and ps.vertrag_annehmen(int(v["id"])).get("fehler", "") == "angebot_weg",
		"D21 annehmen: aktiv 1, Angebot weg; zweites Annehmen abgelehnt (angebot_weg)")
	var kasse_vor := 0
	var erf_tick := -1
	while ps.sim.tick_count < 4000 and ps.vertraege_erfuellt == 0:
		kasse_vor = ps.eco.cash_cent
		var rev: int = ps.eco.revenue_total
		var exp: int = ps.konto.expenses_total
		ps.tick()
		if ps.vertraege_erfuellt == 1:
			erf_tick = ps.sim.tick_count
			kasse_vor = ps.eco.cash_cent - (ps.eco.revenue_total - rev) + (ps.konto.expenses_total - exp) - kasse_vor
	var lg: Dictionary = ps.vertraege_log[-1] if not ps.vertraege_log.is_empty() else {}
	pruef(ps.vertraege_erfuellt == 1 and kasse_vor == int(v["praemie_cent"]) and int(lg.get("cent", 0)) == int(v["praemie_cent"]) and ps.ruf == 1 and int(ps.geliefert["mehl"]) - mehl_vor >= 30,
		"D22 erfüllt bei Tick %d: Kasse +%d ¢ = Prämie, Ruf +1, nur Lieferungen nach der Annahme zählen" % [erf_tick, kasse_vor])
	_bis(ps, erf_tick + 12)
	pruef(ps.meilensteine_erreicht.has("vertrag1"), "D23 Meilenstein erster Vertrag")
	# Verfehlen: Vertrag annehmen, den niemand beliefert
	var b = _neu()
	_bis(b, 900)
	var v2: Dictionary = b.vertraege_angebote[0]
	b.vertrag_annehmen(int(v2["id"]))
	_bis(b, 900 + int(v2["frist_ticks"]) - 1)
	var k_vor: int = b.eco.cash_cent
	_bis(b, 900 + int(v2["frist_ticks"]))
	pruef(b.vertraege_verfehlt == 1 and k_vor - b.eco.cash_cent == int(v2["strafe_cent"]) and b.ruf == -1 and b.vertraege_aktiv.is_empty(),
		"D24 verfehlt zum Fristende: Kasse −%d ¢ = Strafe, Ruf −1" % (k_vor - b.eco.cash_cent))
	# Ablehnen, Verfall, Obergrenze, Determinismus
	var c = _neu()
	_bis(c, 900)
	var id1: int = c.vertraege_angebote[0]["id"]
	var ab: Dictionary = c.vertrag_ablehnen(id1)
	_bis(c, 900 + 1200 * 3)
	var n_ang: int = c.vertraege_angebote.size()
	for vv in c.vertraege_angebote.duplicate():
		c.vertrag_annehmen(int(vv["id"]))
	var zu: int = c.vertraege_aktiv.size()
	_bis(c, 900 + 1200 * 4)
	var voll: Dictionary = c.vertrag_annehmen(int(c.vertraege_angebote[0]["id"])) if not c.vertraege_angebote.is_empty() else {"fehler": "kein_angebot"}
	pruef(ab["ok"] and n_ang >= 2 and n_ang <= 3 and zu == 2 and voll.get("fehler", "") == "zu_viele_vertraege",
		"D25 ablehnen ohne Strafe; %d Angebote offen (≤ 3); Kontor: 2 Verträge zugleich, dritter abgelehnt (zu_viele_vertraege)" % n_ang)
	_bis(c, 900 + 1200 * 4 + 2400)
	var verfallen := 0
	for le in c.vertraege_log:
		if le["ergebnis"] == "verfallen":
			verfallen += 1
	pruef(verfallen >= 1, "D26 nicht angenommene Angebote verfallen nach 4 min (%d im Protokoll)" % verfallen)
	var x1 = _neu(true, 7)
	var x2 = _neu(true, 7)
	var x3 = _neu(true, 8)
	for x in [x1, x2, x3]:
		_bis(x, 4600)
	var gleich := str(x1.vertraege_angebote) == str(x2.vertraege_angebote)
	pruef(gleich and str(x1.vertraege_angebote) != str(x3.vertraege_angebote) and x1.pruefsumme() == x2.pruefsumme(),
		"D27 Angebote deterministisch je vertrag_seed (Seed 7 = Seed 7 ≠ Seed 8)")
	var alle_ok := true
	for vv in x1.vertraege_angebote + x3.vertraege_angebote:
		var s: int = x1.stationen[vv["ort"]]["site"]
		var gi: int = x1.eco.g_index[vv["gut"]]
		var nimmt: bool = x1.eco.city_accepts(s, gi) if x1.eco.s_kind[s] == 1 else x1.eco.s_inbuf[s].has(gi)
		if not nimmt or int(vv["menge"]) <= 0 or int(vv["praemie_cent"]) <= 0 or int(vv["strafe_cent"]) >= int(vv["praemie_cent"]):
			alle_ok = false
	pruef(alle_ok, "D28 jedes Angebot: Ort nimmt das Gut an, Menge > 0, Strafe < Prämie")


# ------------------------------------------------------------------ E Fahrzeuge

func _e_fahrzeuge() -> void:
	var ps = _neu()
	ps.eco.cash_cent = 3000000
	pruef(ps.modelle("fuhrwerk") == ["fuhrwerk_d"] and ps.modelle("zug").is_empty() and ps.def_fuer("fuhrwerk") == "fuhrwerk_d",
		"E1 1820: nur das Fuhrwerk kaufbar")
	ps.lizenz_kaufen(FARM)
	var l: Dictionary = ps.linie_anlegen(FARM, MUEHLE)
	var vid: int = l["vid"]
	pruef(ps.linie_anlegen(FARM, MUEHLE, "fuhrwerk", "planwagen_d").get("fehler", "") == "noch_nicht_verfuegbar" and ps.neueres_modell(vid) == "",
		"E2 Planwagen vor 1822 abgelehnt (noch_nicht_verfuegbar), kein Ersetzen-Angebot")
	_bis(ps, 18000)
	var wechsel: Array = []
	for fr in ps.freischaltungen:
		wechsel.append("%s %d (Min %d)" % [fr["id"], fr["jahr"], int(fr["tick"]) / 600])
	var strasse := 0
	var zug := 0
	for fr in ps.freischaltungen:
		if int(fr["tick"]) <= 18000:
			if String(ps.vdef(fr["id"]).get("kategorie", "")) == "zug":
				zug += 1
			else:
				strasse += 1
	pruef(strasse == 2 and zug == 2 and ps.freischaltungen.size() == 4, "E3 Generationswechsel in 30 min: %s" % ", ".join(PackedStringArray(wechsel)))
	var f: Dictionary = ps.fahrzeug(vid)
	var neu: String = ps.neueres_modell(vid)
	var q: Dictionary = ps.ersetzen_angebot(vid, neu)
	pruef(neu == "frachtwagen_d" and q["ok"] and int(q["kapazitaet_neu"]) == 36 and int(q["preis_cent"]) == 70000 and int(q["netto_cent"]) == 70000 - int(q["restwert_cent"])
		and int(q["alter_jahre"]) == 10 and int(q["fix_alt_cent"]) == 3500 * 15000 / 10000,
		"E4 Ersetzen-Angebot nach 10 Jahren: Frachtwagen %d ¢ − Restwert %d ¢, Ladung 20 → %d E, Unterhalt alt %d ¢ (+50 %% Alter) → neu %d ¢" % [
			int(q["preis_cent"]), int(q["restwert_cent"]), int(q["kapazitaet_neu"]), int(q["fix_alt_cent"]), int(q["fix_neu_cent"])])
	var kasse: int = ps.eco.cash_cent
	var r: Dictionary = ps.fahrzeug_ersetzen(vid, neu)
	pruef(r["ok"] and kasse - ps.eco.cash_cent == int(q["netto_cent"]) and ps.sim.v_cargo_cap[ps.sim.slot_of(vid)] == 36 and String(f["def_id"]) == "frachtwagen_d"
		and ps.alter_jahre(f) == 0 and ps.neueres_modell(vid) == "", "E5 ersetzt: Kasse −%d ¢ = Angebot, Linie läuft weiter, Alter 0, Name %s" % [kasse - ps.eco.cash_cent, f["name"]])
	# Pferdebahn → Dampfzug: Tempo und Darstellung wechseln, Linie bleibt
	ps.bauen("gleis", _vorschlag(ps, "gleis", KOHLE + ">" + HUETTE))
	ps.lizenz_kaufen(KOHLE)
	pruef(ps.def_fuer("zug") == "dampfzug_d" and ps.modelle("zug") == ["pferdebahn_d", "dampfzug_d"], "E6 1830: Züge Pferdebahn und Dampfzug kaufbar")
	var z: Dictionary = ps.linie_anlegen(KOHLE, HUETTE, "zug", "pferdebahn_d")
	var zf: Dictionary = ps.fahrzeug(int(z["vid"]))
	var v_alt: int = ps.sim.v_speed[ps.sim.slot_of(zf["vid"])]
	_bis(ps, 18300)
	var rz: Dictionary = ps.fahrzeug_ersetzen(int(zf["vid"]), ps.neueres_modell(int(zf["vid"])))
	var v_neu: int = ps.sim.v_speed[ps.sim.slot_of(zf["vid"])]
	_bis(ps, 19000)
	pruef(rz["ok"] and v_alt == 75 and v_neu == 125 and String(zf["kat"]) == "dampflok" and ps.sim.v_cargo_cap[ps.sim.slot_of(zf["vid"])] == 120 and ps.fehler.is_empty()
		and ps.meilensteine_erreicht.has("dampf"), "E7 Pferdebahn → Dampfzug: Tempo %d → %d mm/Tick, Ladung 120 E, Meilenstein Dampf" % [v_alt, v_neu])


# ------------------------------------------------------------------ Determinismus / Parität

func _skript(seed_nr: int):
	var ps = _neu(true, seed_nr)
	ps.lizenz_kaufen(FARM)
	ps.lizenz_kaufen(MUEHLE)
	ps.linie_anlegen(FARM, MUEHLE)
	ps.linie_anlegen(MUEHLE, DORF)
	_bis(ps, 1000)
	if not ps.vertraege_angebote.is_empty():
		ps.vertrag_annehmen(int(ps.vertraege_angebote[0]["id"]))
	ps.skill_setzen("marktstand")
	ps.bauen("strasse", _vorschlag(ps, "strasse", FORST))
	_bis(ps, 5000)
	return ps


func _parity() -> void:
	var a = _skript(3)
	var b = _skript(3)
	var c = _skript(3)
	c.skill_zuruecksetzen()
	pruef(a.pruefsumme() == b.pruefsumme() and a.eco.cash_cent == b.eco.cash_cent and a.pruefsumme() != c.pruefsumme(),
		"P1 gleiches Skript zweimal = gleiche Prüfsumme %d; Demo-Zustand (Skills) geht in die Prüfsumme ein" % a.pruefsumme())
	# Demo aus: ProtoSim ohne --demo kennt nichts davon (Slice-/S8-Parität prüfen proto_sim_test und d08)
	var ProtoSim = load("res://proto/proto_sim.gd")
	var p = ProtoSim.new(szene.regelwerk)
	szene.strassen.zuruecksetzen()
	p.graph_bauen(szene.strassen)
	p.spiel_starten(orte)
	pruef(p.stationen.size() == 5 and p.eco.g_ids.size() == 6 and p.eco.demo_rate.is_empty() and p.tempo_k == 1 and p.eco.oe_set == "",
		"P2 ohne Demo: ProtoSim unverändert (5 Stationen, 6 Güter, k = 1, kein Satz)")
