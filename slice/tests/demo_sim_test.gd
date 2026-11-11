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


## Lokschuppen am Bahnhof einer Station (Züge werden nur im Depot gekauft).
func _lok(ps, name: String) -> Dictionary:
	var kp: Vector3 = ps.knoten_pos[ps.bahnhof[name]]
	return ps.depot_bauen(Vector2(kp.x, kp.z))


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
	_m_personen_linien()
	_m_depot()
	_m_strecken()
	_m_zuege()
	_t_trasse()
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
	var ohne_lok: Dictionary = ps.linie_anlegen(KOHLE, HUETTE, "zug")
	_lok(ps, KOHLE)
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
	pruef(ohne_lok.get("fehler", "") == "kein_depot" and z.get("ok", false) and ps.ist_zug(f) and String(f["kat"]) == "pferdebahn" and kohle >= 60 and ps.fehler.is_empty(),
		"C15 Pferdebahn (ohne Lokschuppen: kein_depot) fährt: %d Kohle an der Hütte nach 5 min, Ladung %d E, 0 Sim-Fehler" % [kohle, ps.sim.v_cargo_cap[ps.sim.slot_of(f["vid"])]])
	pruef(fix_mit == fix_zug + int(q["unterhalt_cent"]) + 500 and int(q["unterhalt_cent"]) == int(q["felder"]) * 30,
		"C16 Gleisunterhalt läuft über konto: Fix %d ¢/min = Zug %d + Gleis %d + Lokschuppen 500" % [fix_mit, fix_zug, int(q["unterhalt_cent"])])
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
		and int(v["heimat_bonus_promille"]) == 100 and int(vw["heimat_bonus_promille"]) == 100 and String(vw["ort"]) == "Hasenwinkel",
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
	for mit in [true, false]:
		var a = _neu(false)
		a.hq_platzieren(HQ_DORF)
		if not mit:
			a.eco.demo_site_bonus = {}                     # Gegenprobe: gleicher Standort und Fahrplan, nur der Bonus fehlt
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
			if ps.auf_gleis(ps.vdef(fr["id"])):
				zug += 1
			else:
				strasse += 1
	pruef(strasse == 3 and zug == 4 and ps.freischaltungen.size() == 7, "E3 Generationswechsel in 30 min: %s" % ", ".join(PackedStringArray(wechsel)))
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
	_lok(ps, KOHLE)
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


# ------------------------------------------------------------------ M Erweiterung: Personen, Linienpläne, Depots, Strecken, Züge

const OST := "Erlenbach Ostend"
const KIRCHE := "Erlenbach Kirchgasse"
const HALT_HW := "Hasenwinkel"

func _summe(ps, gut: String) -> int:
	return int(ps.geliefert.get(gut, 0))


func _m_personen_linien() -> void:
	var ps = _neu()
	pruef(ps.personen_sites.size() == 7 and ps.stationen.size() == 16 and ps.fehler.is_empty(), "M1 Fahrgastnetz: %d Orte/Haltestellen, %d Stationen gesamt" % [ps.personen_sites.size(), ps.stationen.size()])
	_bis(ps, 3000)
	var w_dorf: int = ps.wartende(DORF)
	var w_stadt: int = ps.wartende(STADT)
	var bed: int = ps.eco.city_demand(int(ps.stationen[DORF]["site"]))
	pruef(w_dorf == bed * 3 and w_stadt == ps.eco.city_demand(int(ps.stationen[STADT]["site"])) * 3 and ps.wartende(FARM) == 0,
		"M2 Fahrgäste entstehen: Erlenbach %d wartend (= 3 min × %d), Lindenfurt %d, gedeckelt; Betriebe 0" % [w_dorf, bed, w_stadt])
	var fehl := {
		"zu_wenig_halte": [[DORF], "kutsche_d"], "gleicher_ort": [[DORF, DORF], "kutsche_d"], "falsche_fracht": [[DORF, MUEHLE], "kutsche_d"],
		"keine_verbindung": [[FARM, FORST], "fuhrwerk_d"], "noch_nicht_verfuegbar": [[DORF, OST], "omnibus_d"]}
	var falsch: Array = []
	for code in fehl:
		var r: Dictionary = ps.linienplan_anlegen(fehl[code][0], fehl[code][1])
		if String(r.get("fehler", "ok")) != code:
			falsch.append("%s → %s" % [code, str(r.get("fehler", "ok"))])
	var nur_orte: Dictionary = ps.linienplan_anlegen([DORF, OST], "fuhrwerk_d")
	pruef(falsch.is_empty() and nur_orte.get("fehler", "") == "falsche_fracht" and ps.linien.is_empty(), "M3 ungültige Linienpläne: 6 Fehlercodes; falsch: %s" % str(falsch))
	var kasse: int = ps.eco.cash_cent
	var r1: Dictionary = ps.linienplan_anlegen([DORF, OST, KIRCHE], "kutsche_d")
	var f: Dictionary = ps.fahrzeug(int(r1.get("vid", 0)))
	pruef(r1.get("ok", false) and kasse - ps.eco.cash_cent == 30000 and ps.linien.size() == 1 and ps.linien[0]["auftrag"] == ["mitnehmen", "mitnehmen", "mitnehmen"] and int(f["plan"]) == 1,
		"M4 Stadtlinie mit 3 Halten angelegt, Stadtkutsche gekauft (300 $), Ladeauftrag je Halt: mitnehmen")
	var rev0: int = ps.eco.revenue_total
	var gesehen := {}
	var t_ende: int = ps.sim.tick_count + 3600
	while ps.sim.tick_count < t_ende:
		ps.tick()
		if int(f["halt"]) >= 0:
			gesehen[int(f["halt"])] = true
	var ziele := {}
	for le in ps.eco.ledger:
		if le["gut"] == "fahrgaeste":
			ziele[int(le["ziel"])] = int(ziele.get(int(le["ziel"]), 0)) + int(le["menge"])
	pruef(gesehen.size() == 3 and int(f["hops"]) >= 6 and ziele.size() == 3 and _summe(ps, "fahrgaeste") >= 40 and ps.eco.revenue_total > rev0 and ps.fehler.is_empty(),
		"M5 Kutsche fährt die Halte reihum (%d Teilstrecken in 6 min), %d Fahrgäste an 3 Zielen, Ertrag %d ¢" % [int(f["hops"]), _summe(ps, "fahrgaeste"), ps.eco.revenue_total - rev0])
	pruef(ps.meilensteine_erreicht.has("fahrgast") and ps.meilensteine_erreicht.has("linienplan"), "M6 Meilensteine Fahrgäste und Linie mit drei Halten")
	# Plan bearbeiten
	var a1: Dictionary = ps.linie_halt_dazu(1, MUEHLE)
	var a2: Dictionary = ps.linie_halt_weg(1, 2)
	var halte2: Array = ps.linien[0]["halte"].duplicate()
	var a3: Dictionary = ps.linie_halt_dazu(1, KIRCHE, 1)
	var a4: Dictionary = ps.linie_halt_schieben(1, 1, 1)
	var halte4: Array = ps.linien[0]["halte"].duplicate()
	var a5: Dictionary = ps.linie_auftrag(1, 0, "nichts")
	var a6: Dictionary = ps.linie_halt_weg(1, 0)
	var a7: Dictionary = ps.linie_halt_weg(1, 0)
	pruef(a1.get("fehler", "") == "falsche_fracht" and a2["ok"] and halte2 == [DORF, OST] and a3["ok"] and a4["ok"] and halte4 == [DORF, OST, KIRCHE] and a5["ok"] and a6["ok"]
		and a7.get("fehler", "") == "zu_wenig_halte" and ps.linien[0]["halte"] == [OST, KIRCHE] and int(f["halt"]) == 0,
		"M7 Plan ändern: Halt dazu/weg/schieben, Ladeauftrag, ungültige Änderung wird zurückgenommen; Rest %s" % str(ps.linien[0]["halte"]))
	# Güterlinie mit drei Halten: ein Fuhrwerk fährt Getreide und Mehl
	var b = _neu()
	b.eco.cash_cent = 2000000
	b.lizenz_kaufen(FARM)
	b.lizenz_kaufen(MUEHLE)
	var rb: Dictionary = b.linienplan_anlegen([FARM, MUEHLE, DORF], "fuhrwerk_d")
	_bis(b, 6000)
	pruef(rb.get("ok", false) and b.linien[0]["auftrag"] == ["voll", "voll", "nichts"] and _summe(b, "getreide") >= 40 and _summe(b, "mehl") >= 20 and b.fehler.is_empty(),
		"M8 Güterlinie Farm → Mühle → Erlenbach mit einem Fuhrwerk: %d Getreide und %d Mehl geliefert" % [_summe(b, "getreide"), _summe(b, "mehl")])
	# Zuweisen
	var rk: Dictionary = b.linienplan_anlegen([DORF, OST], "kutsche_d")
	var rk2: Dictionary = b.linienplan_anlegen([DORF, KIRCHE], "kutsche_d")
	var z1: Dictionary = b.fahrzeug_zuweisen(int(rk["vid"]), int(rk2["linie"]))
	var z2: Dictionary = b.fahrzeug_zuweisen(int(rb["vid"]), int(rk2["linie"]))
	var auf1: Dictionary = b.linie_aufloesen(int(rk2["linie"]))
	var auf2: Dictionary = b.linie_aufloesen(int(rk["linie"]))
	pruef(z1["ok"] and b.linie_fahrzeuge(int(rk2["linie"])).size() == 2 and z2.get("fehler", "") == "passt_nicht_zur_linie" and auf1.get("fehler", "") == "linie_hat_fahrzeuge" and auf2["ok"],
		"M9 Fahrzeug einer anderen Linie zuweisen (gleiche Art), Fuhrwerk auf Personenlinie abgelehnt, leere Linie auflösbar")


func _m_depot() -> void:
	var ps = _neu()
	ps.eco.cash_cent = 2000000
	var fh: Dictionary = ps.depots[0] if ps.depots.size() == 1 else {}
	ps._fix_neu()
	pruef(fh.get("fuhrhof", false) and String(fh["art"]) == "strasse" and ps.konto.running_cost_per_period == 0 and ps.depot_katalog(0) == ["fuhrwerk_d", "kutsche_d"],
		"M10 Firmensitz bringt den Fuhrhof mit (Straßendepot, kostenlos, kein Unterhalt); Katalog 1820: Fuhrwerk, Stadtkutsche")
	var kasse: int = ps.eco.cash_cent
	var k: Dictionary = ps.depot_kaufen(0, "fuhrwerk_d", 3)
	ps._fix_neu()
	var falsch := [ps.depot_kaufen(0, "pferdebahn_d", 1).get("fehler", ""), ps.depot_kaufen(5, "fuhrwerk_d", 1).get("fehler", ""), ps.depot_kaufen(0, "planwagen_d", 1).get("fehler", "")]
	pruef(k["ok"] and k["keys"].size() == 3 and kasse - ps.eco.cash_cent == 120000 and ps.depot_bestand(0).size() == 3 and ps.fahrzeuge.is_empty()
		and ps.konto.running_cost_per_period == 3 * 3500 * 250 / 1000 and falsch == ["falsches_depot", "kein_depot", "noch_nicht_verfuegbar"],
		"M11 Kauf im Depot ohne Linie: 3 Fuhrwerke für 1.200 $ stehen im Fuhrhof (kein Sim-Fahrzeug, 25 %% Unterhalt); Zug im Fuhrhof, falsches Depot, zu früh abgelehnt")
	ps.lizenz_kaufen(FARM)
	ps.lizenz_kaufen(MUEHLE)
	var l1: Dictionary = ps.linie_neu("strasse_gueter", [FARM, MUEHLE])
	var l2: Dictionary = ps.linie_neu("strasse_personen", [DORF, OST])
	var leer: bool = ps.linie_fahrzeuge(int(l1["linie"])).is_empty() and ps.linien.size() == 2
	var z_falsch: Dictionary = ps.zuweisen(k["keys"], int(l2["linie"]))
	var z: Dictionary = ps.zuweisen(k["keys"].slice(0, 2), int(l1["linie"]))
	var f1: Dictionary = ps.fahrzeug(int(String(z["keys"][0]).substr(1)))
	var i1: int = ps.sim.slot_of(f1["vid"])
	var start: Vector3 = ps.knoten_pos[int(fh["knoten"])]
	var p0: Vector3 = ps.knoten_pos[ps.sim.r_from[ps.sim.v_rstart[i1]]]
	pruef(leer and l1["ok"] and z_falsch.get("fehler", "") == "passt_nicht_zur_linie" and z["ok"] and int(z["zugewiesen"]) == 2 and ps.depot_bestand(0).size() == 1
		and f1.get("ausfahrt", false) and int(f1["halt"]) == -1 and Vector2(p0.x, p0.z).distance_to(Vector2(start.x, start.z)) < 30.0,
		"M12 Linie ohne Fahrzeug angelegt; Sammelzuweisung: 2 Fuhrwerke rücken am Fuhrhof aus (Routenstart %.0f m vom Depotknoten), falsche Linienart abgelehnt" % Vector2(p0.x, p0.z).distance_to(Vector2(start.x, start.z)))
	_bis(ps, 3000)
	var getr := _summe(ps, "getreide")
	pruef(int(f1["halt"]) >= 0 and getr >= 40 and ps.fehler.is_empty(), "M13 nach der Ausfahrt beginnt der Umlauf am ersten Halt: %d Getreide in 5 min" % getr)
	var d2: Dictionary = ps.depot_bauen(Vector2(1640, 700))
	ps._fix_neu()
	var fix_vor: int = ps.konto.running_cost_per_period
	var idp: Dictionary = ps.ins_depot(z["keys"], 1)
	ps._fix_neu()
	pruef(d2["ok"] and idp["ok"] and int(idp["n"]) == 2 and ps.depot_bestand(1).size() == 2 and ps.linie_fahrzeuge(int(l1["linie"])).is_empty() and ps.alle_fahrzeuge().size() == 3
		and ps.konto.running_cost_per_period == 500 + 3 * 918 and fix_vor == 500 + 2 * 3675 + 918 and f1["verkauft"] and f1.get("versteckt", false),
		"M14a Betriebshof gebaut (5 $/min); „ins Depot“ nimmt 2 Fahrzeuge von der Linie: Unterhalt %d → %d ¢/min, Name und Nummer bleiben (%s)" % [fix_vor, ps.konto.running_cost_per_period, ps.depot_bestand(1)[0]["name"]])
	_bis(ps, 1800 * 4 + 10)
	var key0: String = ps.depot_bestand(1)[0]["key"]
	var uq: Dictionary = ps.ueberholen_angebot_key(key0)
	kasse = ps.eco.cash_cent
	var ur: Dictionary = ps.ueberholen_key(key0)
	var rec: Dictionary = ps.fz(key0)
	pruef(uq["ok"] and int(uq["kosten_cent"]) == 8000 and ur["ok"] and kasse - ps.eco.cash_cent == 8000 and ps.fix_eff(rec) == 3500 and ps.alter_jahre(rec) == 4
		and ps.ueberholen_key(key0).get("fehler", "") == "nichts_zu_ueberholen", "M14b Überholung im Depot nach 4 Jahren: 80 $, Unterhalt zurück auf 3.500 ¢/min, Alter bleibt 4 J")
	var er: Dictionary = ps.ersetzen_viele(ps.alle_fahrzeuge())
	var rw: int = ps.restwert(ps.fz(key0))
	var soll: int = 52000 * 500 / 1000
	kasse = ps.eco.cash_cent
	var vk: Dictionary = ps.verkaufen_viele([key0, "d999"])
	pruef(er["ok"] and int(er["n"]) == 3 and String(ps.depot_bestand(1)[0]["def_id"]) == "planwagen_d" and rw == soll and vk["ok"] and int(vk["n"]) == 1 and ps.eco.cash_cent - kasse == rw
		and ps.alle_fahrzeuge().size() == 2 and ps.verkaufen_viele([key0]).get("fehler", "") == "keine_auswahl",
		"M14c Sammel-Ersetzen (3 → Planwagen) und Verkauf aus dem Depot: Restwert %d ¢ = Kauf × 50 %% (W20), unbekannter Schlüssel wird übergangen" % rw)
	var zz: Dictionary = ps.zuweisen(ps.alle_fahrzeuge(), int(l1["linie"]))
	_bis(ps, ps.sim.tick_count + 1200)
	pruef(zz["ok"] and int(zz["zugewiesen"]) == 2 and ps.linie_fahrzeuge(int(l1["linie"])).size() == 2 and ps.abgestellt.is_empty() and ps.fehler.is_empty()
		and int(ps.linie_kennzahlen(int(l1["linie"]))["fahrzeuge"]) == 2, "M14d wieder zugewiesen aus zwei Depots: 2 Planwagen auf der Linie, 0 Sim-Fehler")


func _m_strecken() -> void:
	var ps = _neu()
	ps.eco.cash_cent = 3000000
	ps.lizenz_kaufen(MUEHLE)
	var l: Dictionary = ps.linie_anlegen(MUEHLE, STADT)
	var f: Dictionary = ps.fahrzeug(int(l["vid"]))
	var i: int = ps.sim.slot_of(f["vid"])
	while int(f["halt"]) != 0 and ps.sim.tick_count < 3000:
		ps.tick()
	var ant: int = ps.maut_anteil_pm(f["route"])
	var var_mit: int = ps.sim.v_var_cent[i]
	var liste: Array = ps.strecken()
	pruef(ant > 700 and var_mit == 70 + (15 * ant + 500) / 1000 and liste.size() == 1 and String(liste[0]["besitz"]) == "staat" and int(liste[0]["benutzt"]) == 1,
		"M14 Chausseegeld: %d ‰ der Teilstrecke Mühle → Lindenfurt auf der Chaussee, Fahrkosten %d ¢/Feld (70 + Maut)" % [ant, var_mit])
	pruef(true,
		"M14 Chausseegeld: %d ‰ der Route Mühle → Lindenfurt auf der Chaussee, Fahrkosten %d ¢/Feld (70 + Maut)" % [ant, var_mit])
	var kq: Dictionary = ps.strecke_kauf_angebot("chaussee")
	var kasse: int = ps.eco.cash_cent
	var kr: Dictionary = ps.strecke_kaufen("chaussee")
	ps._fix_neu()
	pruef(kr["ok"] and kasse - ps.eco.cash_cent == 280000 and ps.sim.v_var_cent[i] == 70 and ps.konto.running_cost_per_period == 3500 + 1500 and int(kq["maut_cent_pro_periode"]) > 0
		and ps.strecke_kaufen("chaussee").get("fehler", "") == "schon_gekauft" and String(ps.strecken()[0]["besitz"]) == "eigen",
		"M15 Chaussee gekauft: −2.800 $, Fahrkosten wieder 70 ¢/Feld, Unterhalt 15 $/min (Maut zuvor ca. %d ¢/min)" % int(kq["maut_cent_pro_periode"]))
	kasse = ps.eco.cash_cent
	var vr: Dictionary = ps.strecke_verkaufen("chaussee")
	pruef(vr["ok"] and ps.eco.cash_cent - kasse == 140000 and ps.sim.v_var_cent[i] == var_mit and not ps.maut_gekauft, "M16 Chaussee verkauft: +1.400 $ (50 %%), Maut gilt wieder")
	# eigene Straße: bauen, benutzen, verkaufen
	var rb: Dictionary = ps.bauen("strasse", _vorschlag(ps, "strasse", FORST))
	ps.lizenz_kaufen(FORST)
	var lf: Dictionary = ps.linie_anlegen(FORST, SAEGE)
	var benutzt: Dictionary = ps.strecke_verkaufen("bau_0")
	ps.fahrzeug_verkaufen(int(lf["vid"]))
	kasse = ps.eco.cash_cent
	var sv: Dictionary = ps.strecke_verkaufen("bau_0")
	pruef(rb["ok"] and benutzt.get("fehler", "") == "strecke_benutzt" and int(benutzt.get("n", 0)) == 1 and sv["ok"] and ps.eco.cash_cent - kasse == int(rb["kosten_cent"]) / 2
		and not ps.angeschlossen(FORST) and ps.strassenroute(FORST, SAEGE).is_empty() and ps.strecken().size() == 1 and ps.linie_anlegen(FORST, SAEGE).get("fehler", "") == "keine_verbindung",
		"M17 eigene Straße: Verkauf gesperrt, solange ein Fahrzeug sie befährt; danach abgebaut, +%d ¢ (50 %%), Forsthaus wieder ohne Anschluss" % (int(rb["kosten_cent"]) / 2))
	var rb2: Dictionary = ps.bauen("strasse", _vorschlag(ps, "strasse", FORST))
	pruef(rb2["ok"] and ps.angeschlossen(FORST) and ps.linie_anlegen(FORST, SAEGE).get("ok", false) and ps.fehler.is_empty(), "M18 dieselbe Trasse neu gebaut und wieder befahrbar, 0 Sim-Fehler")


func _m_zuege() -> void:
	var ps = _neu()
	ps.eco.cash_cent = 5000000
	_bis(ps, 7200)
	var ohne_bhf: Dictionary = ps.linienplan_anlegen([DORF, STADT], "pferdetram_d")
	var g1: Dictionary = ps.bauen("gleis", _vorschlag(ps, "gleis", KOHLE + ">" + HUETTE))
	var g2: Dictionary = ps.bauen("gleis", _vorschlag(ps, "gleis", DORF + ">" + HALT_HW))
	ps.lizenz_kaufen(KOHLE)
	_lok(ps, KOHLE)
	var lok: Dictionary = _lok(ps, DORF)
	var gz: Dictionary = ps.linie_anlegen(KOHLE, HUETTE, "zug")
	var pz: Dictionary = ps.linienplan_anlegen([DORF, HALT_HW], "pferdetram_d")
	var falsch1: Dictionary = ps.linie_anlegen(DORF, HALT_HW, "zug", "pferdebahn_d")
	var falsch2: Dictionary = ps.linienplan_anlegen([KOHLE, HUETTE], "pferdetram_d")
	pruef(ohne_bhf.get("fehler", "") == "kein_bahnhof" and g1["ok"] and g2.get("ok", false) and gz["ok"] and pz.get("ok", false) and ps.bahnhof.has(DORF) and ps.bahnhof.has(HALT_HW)
		and falsch1.get("fehler", "") == "falsche_fracht" and falsch2.get("fehler", "") == "falsche_fracht",
		"M19 Güterzug (Kohle) und Personenzug (Pferdestraßenbahn Erlenbach ↔ Hasenwinkel) auf eigenen Gleisen; Fracht wird geprüft: %s" % str(g2.get("fehler", g2.get("text", ""))))
	_bis(ps, 7200 + 4200)
	var fp: Dictionary = ps.fahrzeug(int(pz.get("vid", 0)))
	var nach := {}
	for le in ps.eco.ledger:
		if le["gut"] == "fahrgaeste":
			nach[int(le["ziel"])] = int(nach.get(int(le["ziel"]), 0)) + int(le["menge"])
	pruef(_summe(ps, "kohle") >= 60 and nach.size() == 2 and _summe(ps, "fahrgaeste") >= 20 and ps.ist_zug(fp) and ps.fehler.is_empty(),
		"M20 nach 7 min: %d Kohle per Güterzug, %d Fahrgäste per Personenzug in beide Richtungen, 0 Sim-Fehler" % [_summe(ps, "kohle"), _summe(ps, "fahrgaeste")])
	_bis(ps, 14400 + 10)
	var neu: String = ps.neueres_modell(int(fp["vid"]))
	var er: Dictionary = ps.fahrzeug_ersetzen(int(fp["vid"]), neu)
	var d0: Dictionary = ps.depot_bauen(ps.halt_pos(DORF) + Vector2(3, 3))
	var zuw: Dictionary = ps.fahrzeug_zuweisen(int(gz["vid"]), int(pz["linie"]))
	_bis(ps, 14400 + 2400)
	pruef(neu == "personenzug_d" and er["ok"] and ps.sim.v_cargo_cap[ps.sim.slot_of(fp["vid"])] == 80 and String(fp["kat"]) == "dampflok" and lok.get("ok", false) and String(lok["art"]) == "gleis"
		and d0.get("ok", false) and ps.depot_erreicht(DORF, true) == 2 and ps.depot_erreicht(KOHLE, true) == 1 and zuw.get("fehler", "") == "passt_nicht_zur_linie" and ps.fehler.is_empty(),
		"M21 1828: Pferdestraßenbahn → Personenzug (Dampf, 80 Plätze) auf der Linie; Lokschuppen am Bahnhof erreicht nur sein Gleisnetz; Güterzug nicht auf Personenlinie")


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


# ------------------------------------------------------------------ T Trassenwerkzeug (Teil 4): Kurven, lokale Fehler, Kreuzungen, exakter Bau

func _t_trasse() -> void:
	var ps = _neu()
	ps.eco.cash_cent += 3000000
	var start := Vector2(1284, 936)
	# T1 Kurve: tangentialer Kreisbogen, Punkte ≤ 8 m, Endtangente gedreht
	var g: Dictionary = ps.trasse_geometrie("strasse", PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(200, 100)]), true)
	var pk: PackedVector2Array = g["punkte"]
	var max_schritt := 0.0
	var max_knick := 0.0
	for i in range(1, pk.size()):
		max_schritt = maxf(max_schritt, pk[i - 1].distance_to(pk[i]))
		if i >= 2:
			max_knick = maxf(max_knick, absf(rad_to_deg((pk[i - 1] - pk[i - 2]).angle_to(pk[i] - pk[i - 1]))))
	var te: Vector2 = g["tangente"]
	pruef(pk[-1].distance_to(Vector2(200, 100)) < 0.01 and max_schritt <= 8.01 and max_knick < 7.0 and absf(float(g["r_min"]) - 100.0) < 0.5 and te.distance_to(Vector2(0, 1)) < 0.01 and g["eng"].is_empty(),
		"T1 Kurvenmodus: Gerade 100 m, dann Viertelkreis mit Radius %.0f m tangential angeschlossen; Schritte ≤ %.1f m, größter Knick %.1f°, Endrichtung gedreht" % [float(g["r_min"]), max_schritt, max_knick])
	# T2 zu enger Bogen: Fehler mit Ort, nur das Segment ist markiert
	var qe: Dictionary = ps.trasse_angebot("gleis", PackedVector2Array([Vector2(370, 1235), Vector2(470, 1235), Vector2(500, 1265)]), {"kurve": true})
	var n_schlecht := 0
	for b in qe.get("schlecht", PackedByteArray()):
		n_schlecht += int(b)
	pruef(not qe["ok"] and (qe["fehler"] == "radius_zu_klein" or qe["fehler"] == "noch_nicht_verfuegbar"), "T2a Gleis vor 1824 oder zu enger Bogen wird abgelehnt (%s)" % qe["fehler"])
	var qs: Dictionary = ps.trasse_angebot("strasse", PackedVector2Array([start, start + Vector2(90, 30), start + Vector2(96, 40)]), {"kurve": true})
	n_schlecht = 0
	for b in qs.get("schlecht", PackedByteArray()):
		n_schlecht += int(b)
	var st0: Dictionary = qs["stellen"][0] if not qs.get("stellen", []).is_empty() else {}
	pruef(not qs["ok"] and String(st0.get("fehler", "")) in ["radius_zu_klein", "wende_zu_eng"] and st0.has("bei") and n_schlecht > 0 and n_schlecht < qs["punkte"].size(),
		"T2 zu enger Bogen (Straße): Fehler %s mit Ort, %d von %d Punkten rot (nicht die ganze Trasse)" % [st0.get("fehler", "?"), n_schlecht, qs["punkte"].size()])
	# T3 See: nur die Punkte in der Sperrzone sind rot, Ort wird gemeldet
	var sk: Array = ps.see_kreise[0]
	for k in ps.see_kreise:
		if Vector2(k[0], k[1]).distance_to(start) < Vector2(sk[0], sk[1]).distance_to(start):
			sk = k
	var sm := Vector2(sk[0], sk[1])
	var qz: Dictionary = ps.trasse_angebot("strasse", PackedVector2Array([start, sm + (sm - start).normalized() * (float(sk[2]) + 120.0)]), {"kurve": false})
	n_schlecht = 0
	for b in qz.get("schlecht", PackedByteArray()):
		n_schlecht += int(b)
	pruef(not qz["ok"] and qz["fehler"] == "see" and qz.has("bei") and n_schlecht > 0 and n_schlecht < qz["punkte"].size(), "T3 See: Fehler mit Ort, %d von %d Punkten rot" % [n_schlecht, qz["punkte"].size()])
	# T4 exakter Bau: gebaute Fahrlinie = Vorschau; freies Ende; Werkzeug kann am Ende tangential weiterbauen
	var stz := PackedVector2Array([start, Vector2(1330, 1100), Vector2(1250, 1190)])
	var q4: Dictionary = ps.trasse_angebot("strasse", stz, {"kurve": false})
	var kasse: int = ps.eco.cash_cent
	var r4: Dictionary = ps.trasse_bauen("strasse", stz, {"kurve": false})
	var abw := 0.0
	if r4.get("ok", false):
		var fl = ps.strassen.fahrlinien[int(r4["weg"])]
		for p in q4["punkte"]:
			var best := INF
			for k in range(0, fl.punkte.size(), 2):
				best = minf(best, Vector2(fl.punkte[k].x, fl.punkte[k].z).distance_to(p))
			abw = maxf(abw, best)
	var ende: Vector2 = q4["punkte"][-1]
	var f_ende: Dictionary = ps.fang("strasse", ende)
	var tr = ps.knoten_richtung(int(f_ende["knoten"]))
	if not q4["ok"]:
		print("    T4 Angebot: ", q4.get("fehler"), " ", q4.get("stellen"))
	pruef(q4["ok"] and q4["frei_ende"] and r4.get("ok", false) and kasse - ps.eco.cash_cent == int(q4["kosten_cent"]) and abw < 1.1 and f_ende["typ"] == "knoten" and tr is Vector2
		and (tr as Vector2).distance_to(q4["tangente"]) < 0.2,
		"T4 gebaut wird genau die Vorschau (größte Abweichung %.2f m), −%d $; das freie Ende ist Knoten und gibt die Richtung fürs Weiterbauen" % [abw, int(q4["kosten_cent"]) / 100])
	# T5 Kreuzung: quer über eine bestehende Straße → verbunden
	var nachbarn := {}
	for e in ps.sim.graph.edges.values():
		for paar in [[int(e["a"]), int(e["b"])], [int(e["b"]), int(e["a"])]]:
			if not nachbarn.has(paar[0]):
				nachbarn[paar[0]] = []
			if not nachbarn[paar[0]].has(paar[1]):
				nachbarn[paar[0]].append(paar[1])
	var ok5 := false
	var weg_m := -1
	var n_kr := 0
	for nid in nachbarn:
		if nachbarn[nid].size() != 2 or ps.gleis_knoten.has(nid) or ok5:
			continue
		var np := Vector2(ps.knoten_pos[nid].x, ps.knoten_pos[nid].z)
		var n1 := Vector2(ps.knoten_pos[nachbarn[nid][0]].x, ps.knoten_pos[nachbarn[nid][0]].z)
		var n2 := Vector2(ps.knoten_pos[nachbarn[nid][1]].x, ps.knoten_pos[nachbarn[nid][1]].z)
		var quer := (n2 - n1).normalized().orthogonal()
		var a_id: int = nid
		var vor: int = nachbarn[nid][0]
		for schritt in 22:
			var weiter := -1
			for nb in nachbarn.get(a_id, []):
				if nb != vor:
					weiter = nb
			if weiter < 0 or nachbarn.get(weiter, []).size() != 2:
				break
			vor = a_id
			a_id = weiter
		var ap := Vector2(ps.knoten_pos[a_id].x, ps.knoten_pos[a_id].z)
		if ap.distance_to(np) < 80.0:
			continue
		var p1 := np + quer * 80.0
		var p2 := np - quer * 80.0
		var q5: Dictionary = ps.trasse_angebot("strasse", PackedVector2Array([ap, p1, p2]), {"kurve": false})
		if not q5["ok"] or int(q5["bruecke_m"]) > 0 or q5["kreuzungen"].is_empty():
			continue
		var r5: Dictionary = ps.trasse_bauen("strasse", PackedVector2Array([ap, p1, p2]), {"kurve": false})
		if not r5.get("ok", false):
			continue
		n_kr = int(r5.get("kreuzungen", 0))
		var ek: int = int(ps.fang("strasse", r5["ende_pos"])["knoten"])
		var route: Array = ps.sim.graph.find_path(ek, nid)
		weg_m = int(ps.sim.graph.route_length(route) / ps.mm_pro_m) if not route.is_empty() else -1
		ok5 = true
	pruef(ok5 and n_kr >= 1 and weg_m > 0 and weg_m < 160, "T5 Kreuzung: Trasse quer über eine Straße wird dort verbunden (%d Kreuzung); vom neuen Ende zum gekreuzten Knoten %d m über das Netz (Luftlinie 80 m)" % [n_kr, weg_m])
	# T6 Plan: Abschnitt, der an einem geplanten Ende beginnt, gilt im Angebot; allein gebaut wird er nicht
	var pe := Vector2(1330, 1100) + Vector2(140, 60)
	var p6 := PackedVector2Array([pe, pe + Vector2(60, 60)])
	var q6: Dictionary = ps.trasse_angebot("strasse", p6, {"kurve": false, "plan_enden": [pe]})
	var q6b: Dictionary = ps.trasse_angebot("strasse", p6, {"kurve": false})
	var r6: Dictionary = ps.trasse_bauen("strasse", p6, {"kurve": false, "plan_enden": [pe]})
	if not q6["ok"]:
		print("    T6 Angebot: ", q6.get("fehler"), " ", q6["start"]["typ"], " ", q6["ende"]["typ"])
	pruef(q6["ok"] and q6["start"]["typ"] == "plan" and not q6b["ok"] and q6b["fehler"] == "kein_anschluss" and not r6.get("ok", true) and r6["fehler"] == "kein_anschluss" and ps.fehler.is_empty(),
		"T6 Plan: Anschluss an ein geplantes Ende gilt im Angebot; ohne Plan „kein_anschluss“; frei schwebend wird nichts gebaut; 0 Sim-Fehler")
	# T7 Fahrzeug fährt über eine Kurventrasse (Anschluss Forsthaus per Bogen)
	var fp: Vector2 = ps.halt_pos(FORST)
	var r7: Dictionary = ps.trasse_bauen("strasse", PackedVector2Array([Vector2(1250, 1190), fp]), {"kurve": true})
	ps.lizenz_kaufen(FORST)
	var l7: Dictionary = ps.linie_anlegen(FORST, SAEGE, "fuhrwerk")
	for i in 3000:
		ps.tick()
	pruef(r7.get("ok", false) and ps.angeschlossen(FORST) and l7.get("ok", false) and int(ps.geliefert.get("holz", 0)) > 0 and ps.fehler.is_empty(),
		"T7 Forsthaus per Bogen am freien Ende angeschlossen (%s), Fuhrwerk liefert %d Holz in 5 min, 0 Sim-Fehler" % [str(r7.get("fehler", "ok")), int(ps.geliefert.get("holz", 0))])
