extends SceneTree
## Demo-Sprint: Demo-Bot (Gate A, D, E). Spielt die Demo headless über die Spieler-API von proto/demo_sim.gd (dieselbe, die
## ui_demo.gd/ui_welt.gd rufen), ohne UI. Schwester von s8_loop_bot.gd (dessen Strategien kennen die Demo-Systeme nicht).
##
##   godot --headless --path slice -s res://tests/demo_bot.gd -- [--n=20] [--seed0=1] [--minuten=30] [--csv=/abs/pfad.csv]
##        [--strategie=plan|faul] [--ohne_det] [--v] [--gate]
## Strategie "plan": spielt den Bogen aus DEMO_PLAN.md nach (HQ, Kette 1, Straße + Holz, Gleis + Eisen, Firmenkauf, HQ-Ausbau,
##   Skills, Verträge, Ersetzen) mit 800 $ Reserve; je Seed andere Reaktionszeiten, HQ-Lage und Skill-Spezialisierung.
## Strategie "faul": baut nur Kette 1 und nimmt sonst nichts an: misst, ob trotzdem Aktionen ANGEBOTEN bleiben.
## luecke_streng_s: längste Zeit ohne eine Aktion außer „Fahrzeug/Zug nachkaufen“ und „Ersetzen“ (strengere Lesart von Gate A);
## arten_x10: mittlere Zahl verschiedener angebotener Aktionsarten je Takt × 10; luecke_akt_s: längste Pause des Bots (Reserve!).
## Messgrößen je Lauf: Bankrott, Aktionen je Art, "Aktionsfenster" (60-s-Fenster, in denen aktionen_moeglich() nie etwas bot),
##   längste Lücke ohne Angebot, Meilensteine/Skillpunkte, Verträge, Generationswechsel/Ersetzen, Bauwerke, Sim-Fehler.
## Exit 0, wenn alle Läufe durchliefen, Determinismus hält und (mit --gate) Gate A erfüllt ist.
## Grenze: Der Bot prüft Verfügbarkeit und Bezahlbarkeit von Aktionen, nicht Spielgefühl (mt-qa Regel 10).

const DemoSim := preload("res://proto/demo_sim.gd")
const SZENE := "res://proto/prototyp_welt.tscn"
const PERIODE := 600
const TAKT := 50
const FARM1 := "Gut Kuppenhof"
const FARM2 := "Hof Hasenwinkel"
const MUEHLE := "Erlenmühle"
const DORF := "Erlenbach"
const STADT := "Lindenfurt"
const FORST := "Forsthaus Rotwald"
const SAEGE := "Sägemühle am Teich"
const KOHLE := "Kohlegrube Schwarzgrund"
const ERZ := "Erzgrube Silberkuppe"
const HUETTE := "Rotachhütte"
const SCHMIEDE := "Hammerschmiede"
const HQ_ORTE := [Vector2(1668, 688), Vector2(1600, 700), Vector2(160, 150), Vector2(735, 835), Vector2(1700, 760)]
const WEG_FORST := [Vector2(1282, 938), Vector2(1330, 1100), Vector2(1050, 1250)]
const GLEIS_KOHLE := [Vector2(370, 1235), Vector2(700, 1120), Vector2(985, 1020)]
const GLEIS_ERZ := [Vector2(1435, 1318), Vector2(1230, 1170), Vector2(1020, 1015)]

var n_lauefe := 20
var seed0 := 1
var minuten := 30
var csv_pfad := ""
var strategie := "plan"
var det_check := true
var verbose := false
var gate := false
var reserve := 80000

var szene: Node
var orte: Dictionary
var ps
var rng := RandomNumberGenerator.new()
var akt: Dictionary = {}              # Art -> Anzahl ausgeführt
var akt_ticks: Array = []
var angebot_ticks: Array = []         # Ticks (Takt), an denen aktionen_moeglich() nicht leer war
var streng_ticks: Array = []          # dasselbe ohne „mehr vom Gleichen“ (Fahrzeug/Zug nachkaufen, Ersetzen)
var arten_summe := 0                  # Σ verschiedene Aktionsarten je Takt (Vielfalt)
var abl: Dictionary = {}              # API-Ablehnungen
var z: Dictionary = {}                # Strategiezustand
var kauf_sperre: Dictionary = {}      # Linie -> Tick des letzten Kaufs


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="):
			n_lauefe = int(a.substr(4))
		elif a.begins_with("--seed0="):
			seed0 = int(a.substr(8))
		elif a.begins_with("--minuten="):
			minuten = int(a.substr(10))
		elif a.begins_with("--csv="):
			csv_pfad = a.substr(6)
		elif a.begins_with("--strategie="):
			strategie = a.substr(12)
		elif a == "--ohne_det":
			det_check = false
		elif a == "--v":
			verbose = true
		elif a == "--gate":
			gate = true
	_run.call_deferred()


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	szene = (load(SZENE) as PackedScene).instantiate()
	szene.set("sim_aus", true)
	root.add_child(szene)
	await process_frame
	orte = JSON.parse_string(FileAccess.get_file_as_string(szene.datei("proto_orte.json")))
	var res: Array = []
	var zeilen: PackedStringArray = [_kopf()]
	for i in n_lauefe:
		var r := _lauf(seed0 + i)
		res.append(r)
		zeilen.append(_zeile(r))
		if verbose:
			print(_zeile(r))
	var det_ok := true
	if det_check and n_lauefe > 0:
		var r2 := _lauf(seed0)
		det_ok = r2["pruefsumme"] == res[0]["pruefsumme"] and _zeile(r2) == _zeile(res[0])
	if csv_pfad != "":
		var f := FileAccess.open(csv_pfad, FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(zeilen) + "\n")
			f.close()
	var ok := _zusammenfassung(res, det_ok, Time.get_ticks_msec() - t0)
	print("demo_bot Exit %d" % (0 if ok else 1))
	quit(0 if ok else 1)


func _kopf() -> String:
	return "seed,strategie,bankrott_min,kasse,aktionen,fenster_ohne,luecke_max_s,luecke_streng_s,arten_x10,luecke_ohne_aktion_max_s,meilensteine,skillpunkte,skills,vertraege_ok,vertraege_fehl,vertraege_angenommen,ruf,strassen,gleise,zuege,ersetzt,firmen,hq_stufe,anbauten,ertrag_min30,fahrzeuge,sim_fehler,ablehnungen,pruefsumme"


func _zeile(r: Dictionary) -> String:
	return "%d,%s,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d" % [r["seed"], strategie,
		str(r["bankrott_min"]), r["kasse"], r["aktionen"], r["fenster_ohne"], r["luecke_max_s"], r["luecke_streng_s"], r["arten_x10"], r["luecke_akt_s"], r["meilensteine"],
		r["skillpunkte"], r["skills"], r["v_ok"], r["v_fehl"], r["v_an"], r["ruf"], r["strassen"], r["gleise"], r["zuege"], r["ersetzt"],
		r["firmen"], r["hq_stufe"], r["anbauten"], r["ertrag_min30"], r["fahrzeuge"], r["sim_fehler"], r["ablehnungen"], r["pruefsumme"]]


# ------------------------------------------------------------------ ein Lauf

func _lauf(sd: int) -> Dictionary:
	rng.seed = sd * 7919 + 17
	ps = DemoSim.new(szene.regelwerk)
	ps.vertrag_seed = sd
	ps.graph_bauen(szene.strassen)
	ps.spiel_starten(orte)
	akt = {}
	akt_ticks = []
	angebot_ticks = []
	streng_ticks = []
	arten_summe = 0
	abl = {}
	kauf_sperre = {}
	z = {"hq": HQ_ORTE[sd % HQ_ORTE.size()], "ast": sd % 3, "verz": rng.randi_range(0, 2) * 100, "v_an": 0, "ersetzt": 0,
		"forst_min": 5 + rng.randi_range(0, 2), "farm2_min": 9 + rng.randi_range(0, 2), "gleis_min": 12 + rng.randi_range(0, 1),
		"stadt_min": 3 + rng.randi_range(0, 2)}
	var ende := minuten * PERIODE
	while ps.sim.tick_count < ende and not ps.konto.bankrupt:
		if verbose and ps.sim.tick_count % 1800 == 0 and ps.sim.tick_count > 0:
			var rv := ""
			for nm in ps.stationen:
				rv += " %s %d" % [nm.substr(0, 6), int(ps.eco.s_revenue[int(ps.stationen[nm]["site"])]) / 100]
			print("  == Min %d Kasse %d Ertrag/min %d Fix/min %d Ertrag ges %d Ausgaben ges %d Fahrk %d Käufe %d |%s" % [ps.sim.tick_count / 600, _cash() / 100,
				ps.ertrag_periode_cent / 100, ps.konto.running_cost_per_period / 100, ps.eco.revenue_total / 100, ps.konto.expenses_total / 100,
				ps.fahrkosten_total / 100, ps.kauf_total / 100, rv])
		if ps.sim.tick_count % TAKT == 0:
			var am: Array = ps.aktionen_moeglich()
			if not am.is_empty():
				angebot_ticks.append(ps.sim.tick_count)
			var arten := {}
			for a in am:
				arten[String(a).split(":")[0]] = true
			arten_summe += arten.size()
			for a in arten:
				if not (a in ["fahrzeug", "zug", "ersetzen"]):
					streng_ticks.append(ps.sim.tick_count)
					break
			_takt(ps.sim.tick_count)
		ps.tick()
	var fen := _fenster(ende)
	var zuege := 0
	var fz := 0
	for f in ps.fahrzeuge:
		if not f["verkauft"]:
			fz += 1
			if ps.ist_zug(f):
				zuege += 1
	var n_akt := 0
	for k in akt:
		n_akt += int(akt[k])
	var n_abl := 0
	for k in abl:
		n_abl += int(abl[k])
	var strassen := 0
	var gleise := 0
	for bw in ps.bauwerke:
		if bw["art"] == "gleis":
			gleise += 1
		else:
			strassen += 1
	return {"seed": sd, "bankrott_min": (ps.bankrott_tick / PERIODE) if ps.konto.bankrupt else -1, "kasse": ps.eco.cash_cent / 100,
		"aktionen": n_akt, "akt": akt.duplicate(), "fenster_ohne": fen[0], "luecke_max_s": fen[1], "luecke_akt_s": fen[2],
		"luecke_streng_s": int(z["luecke_streng_s"]), "arten_x10": int(z["arten_mittel_x10"]),
		"meilensteine": ps.meilensteine_erreicht.size(), "ms": ps.meilensteine_erreicht.duplicate(), "skillpunkte": ps.skillpunkte,
		"skills": ps.skills.size(), "v_ok": ps.vertraege_erfuellt, "v_fehl": ps.vertraege_verfehlt, "v_an": int(z["v_an"]), "ruf": ps.ruf,
		"strassen": strassen, "gleise": gleise, "zuege": zuege, "ersetzt": int(z["ersetzt"]), "firmen": ps.eco.owned_count,
		"hq_stufe": ps.hq_stufe, "anbauten": ps.hq_anbauten.size(), "ertrag_min30": ps.ertrag_periode_cent / 100, "fahrzeuge": fz,
		"sim_fehler": ps.fehler.size(), "fehler": ps.fehler.duplicate(), "ablehnungen": n_abl, "abl": abl.duplicate(),
		"pruefsumme": ps.pruefsumme(), "frei": ps.freischaltungen.duplicate()}


## 60-s-Fenster ohne Angebot, längste Angebotslücke (s), längste Lücke zwischen ausgeführten Aktionen (s).
func _fenster(ende: int) -> Array:
	var ohne := 0
	var w := 0
	while w < ende:
		var hat := false
		for t in angebot_ticks:
			if t >= w and t < w + PERIODE:
				hat = true
				break
		if not hat and not (ps.konto.bankrupt and w >= ps.bankrott_tick):
			ohne += 1
		w += PERIODE
	var lue := 0
	var letzt := 0
	for t in angebot_ticks:
		lue = maxi(lue, t - letzt)
		letzt = t
	lue = maxi(lue, mini(ende, ps.sim.tick_count) - letzt)
	var lue3 := 0
	letzt = 0
	for t in streng_ticks:
		lue3 = maxi(lue3, t - letzt)
		letzt = t
	lue3 = maxi(lue3, mini(ende, ps.sim.tick_count) - letzt)
	z["luecke_streng_s"] = lue3 / 10
	z["arten_mittel_x10"] = arten_summe * 10 / maxi(1, mini(ende, ps.sim.tick_count) / TAKT)
	var lue2 := 0
	letzt = 0
	for t in akt_ticks:
		lue2 = maxi(lue2, t - letzt)
		letzt = t
	lue2 = maxi(lue2, mini(ende, ps.sim.tick_count) - letzt)
	return [ohne, lue / 10, lue2 / 10]


# ------------------------------------------------------------------ Hilfen

func _a(art: String, r) -> bool:
	var ok: bool = (r is Dictionary and r.get("ok", false)) or (r is bool and r) or (r is int and r > 0)
	if ok:
		akt[art] = int(akt.get(art, 0)) + 1
		akt_ticks.append(ps.sim.tick_count)
		if verbose:
			print("    %5.1f min  %s  Kasse %d $" % [ps.sim.tick_count / 600.0, art, ps.eco.cash_cent / 100])
	elif r is Dictionary:
		var k := "%s:%s" % [art, String(r.get("fehler", "?"))]
		abl[k] = int(abl.get(k, 0)) + 1
	return ok


func _cash() -> int:
	return ps.eco.cash_cent


func _min() -> float:
	return ps.sim.tick_count / 600.0


func _n_fz(von: String, nach: String, zug := false) -> int:
	var a: int = ps.stationen[von]["knoten"]
	var b: int = ps.stationen[nach]["knoten"]
	var n := 0
	for f in ps.fahrzeuge:
		if not f["verkauft"] and int(f["von"]) == a and int(f["nach"]) == b and ps.ist_zug(f) == zug:
			n += 1
	return n


func _lager(name: String) -> int:
	var site: int = ps.stationen[name]["site"]
	if ps.eco.s_raw[site] == 1:
		ps.eco._sync_raw(ps.sim, site)
	return ps.sim.st_stock[ps.eco.s_station[site]]


func _lizenz(name: String) -> bool:
	if ps.darf_laden(name):
		return true
	var q: Dictionary = ps.eco.licence_quote(int(ps.stationen[name]["site"]), false)
	if not q.get("ok", false) or int(q["zu_zahlen_cent"]) + reserve / 2 > _cash():
		return false
	return _a("lizenz", ps.lizenz_kaufen(name))


## Sorgt für mindestens `soll` Fahrzeuge auf der Linie; kauft höchstens eines je Aufruf. true = Soll erreicht.
func _linie(von: String, nach: String, soll: int, zug := false) -> bool:
	if _n_fz(von, nach, zug) >= soll:
		return true
	if not _lizenz(von):
		return false
	var d: Dictionary = ps.vdef(ps.def_fuer("zug" if zug else "fuhrwerk"))
	if ps._preis(d) + reserve > _cash():
		return false
	if _a("zug" if zug else "fahrzeug", ps.linie_anlegen(von, nach, "zug" if zug else "fuhrwerk")):
		kauf_sperre["%s>%s" % [von, nach]] = ps.sim.tick_count
	return _n_fz(von, nach, zug) >= soll


## Linie verstärken, wenn sich an der Quelle Ware staut (≥ 2 Ladungen) und der letzte Kauf ≥ 90 s her ist.
func _verstaerken(von: String, nach: String, n_max: int, zug := false) -> void:
	var n := _n_fz(von, nach, zug)
	if n == 0 or n >= n_max:
		return
	var d: Dictionary = ps.vdef(ps.def_fuer("zug" if zug else "fuhrwerk"))
	if _lager(von) < 2 * ps._kap(d) or ps.sim.tick_count - int(kauf_sperre.get("%s>%s" % [von, nach], -9999)) < 900:
		return
	_linie(von, nach, n + 1, zug)


func _bauen(art: String, weg: Array, schluessel: String) -> bool:
	if z.get(schluessel, false):
		return true
	var pkt := PackedVector2Array(weg)
	var q: Dictionary = ps.bau_angebot(art, pkt)
	if not q.get("ok", false):
		_a(art, q)
		return false
	if int(q["kosten_cent"]) + reserve > _cash():
		return false
	if _a(art, ps.bauen(art, pkt)):
		z[schluessel] = true
	return z.get(schluessel, false)


func _kredit() -> void:
	if _cash() < 20000 and ps.credit.borrow_amount(ps.sim.tick_count) > 0:
		if ps.kredit_aufnehmen() > 0:
			akt["kredit"] = int(akt.get("kredit", 0)) + 1
	elif ps.credit.loan_cent > 0 and _cash() > reserve + 200000:
		ps.kredit_tilgen()


# ------------------------------------------------------------------ Strategie

func _takt(t: int) -> void:
	if not ps.hq_platziert:
		if t >= int(z["verz"]):
			_a("hq", ps.hq_platzieren(z["hq"]))
		return
	_skills()
	_vertraege()
	_kredit()
	# Kette 1: Getreide → Mehl
	if not _linie(FARM1, MUEHLE, 1):
		return
	if not _linie(MUEHLE, DORF, 1):
		return
	_verstaerken(FARM1, MUEHLE, 2)
	if strategie == "faul":
		return
	if _min() >= float(z["stadt_min"]):
		_linie(MUEHLE, STADT, 2)
		_verstaerken(MUEHLE, STADT, 4)
	# Kette 2: Straße zum Forsthaus, Holz → Bretter
	if _min() >= float(z["forst_min"]):
		if _bauen("strasse", WEG_FORST, "weg_forst"):
			if _linie(FORST, SAEGE, 2) and _linie(SAEGE, DORF, 1):
				_linie(SAEGE, STADT, 2)
				_verstaerken(FORST, SAEGE, 3)
				_verstaerken(SAEGE, STADT, 4)
	if _min() >= float(z["farm2_min"]):
		_linie(FARM2, MUEHLE, 2)
	_firmen()
	# Kette 3: Gleis (ab 1824), Kohle + Erz → Eisen → Werkzeug
	if ps.gleis_frei() and _min() >= float(z["gleis_min"]):
		if _bauen("gleis", GLEIS_KOHLE, "gleis_kohle") and _linie(KOHLE, HUETTE, 1, true):
			if _bauen("gleis", GLEIS_ERZ, "gleis_erz") and _linie(ERZ, HUETTE, 1, true):
				_verstaerken(ERZ, HUETTE, 2, true)
				if _bauen("strasse", [ps.halt_pos(HUETTE), ps.naechster_strassenknoten(ps.halt_pos(HUETTE))], "weg_huette"):
					if _linie(HUETTE, SCHMIEDE, 2) and _linie(SCHMIEDE, STADT, 2):
						_linie(HUETTE, STADT, 2)
						_verstaerken(HUETTE, SCHMIEDE, 3)
						_verstaerken(SCHMIEDE, STADT, 4)
						_verstaerken(HUETTE, STADT, 5)
	_hq()
	_ersetzen()


func _skills() -> void:
	while ps.skillpunkte_frei() > 0:
		var aeste: Array = ps.daten["skilltree"]["aeste"]
		var gesetzt := false
		for i in aeste.size():
			var ast: Dictionary = aeste[(int(z["ast"]) + i) % aeste.size()]
			# Spezialisierung: Hauptast zuerst bis Rang 3, dann Nebenäste
			for kn in ast["knoten"]:
				if ps.skill_zustand(String(kn["id"])) == "frei":
					gesetzt = _a("skill", ps.skill_setzen(String(kn["id"])))
					break
			if gesetzt:
				break
		if not gesetzt:
			break


## Nimmt Angebote an, deren Gut der Bot schon an diesen Ort liefert (oder gleich liefern wird); lehnt den Rest nach 60 s ab.
func _vertraege() -> void:
	for v in ps.vertraege_angebote.duplicate():
		if ps.vertraege_aktiv.size() >= ps.vertraege_max():
			break
		var liefert := false
		for k in ps.kanten():
			if k["nach"] == v["ort"] and k["gut"] == v["gut"] and (_n_fz(k["von"], k["nach"]) + _n_fz(k["von"], k["nach"], true)) > 0:
				liefert = true
		# machbar: geforderte Menge je Minute ≤ 1,1 × das, was in den letzten 3 Minuten dort ankam
		var soll_je_min: float = float(v["menge"]) / (float(v["frist_ticks"]) / 600.0)
		var ist := 0
		var led: Array = ps.eco.ledger
		var i := led.size() - 1
		while i >= 0 and int(led[i]["tick"]) > ps.sim.tick_count - 1800:
			if String(led[i]["gut"]) == String(v["gut"]) and int(led[i]["ziel"]) == int(ps.stationen[v["ort"]]["site"]):
				ist += int(led[i]["menge"])
			i -= 1
		if liefert and (soll_je_min <= float(ist) / 3.0 * 1.1 or int(v["id"]) == 1):
			if _a("vertrag", ps.vertrag_annehmen(int(v["id"]))):
				z["v_an"] = int(z["v_an"]) + 1
		elif ps.sim.tick_count - int(v["angebot_tick"]) >= 600:
			ps.vertrag_ablehnen(int(v["id"]))


func _ersetzen() -> void:
	for f in ps.fahrzeuge:
		if f["verkauft"] or int(f.get("kauf_cent", 0)) <= 0:
			continue
		var neu: String = ps.neueres_modell(int(f["vid"]))
		if neu == "":
			continue
		var q: Dictionary = ps.ersetzen_angebot(int(f["vid"]), neu)
		var polster := 40000 if ps.ist_zug(f) else 150000      # Dampf zuerst (großer Sprung), Wagen nur aus dem Überschuss
		if q.get("ok", false) and int(q["netto_cent"]) + reserve + polster <= _cash() and ps.sim.tick_count - int(z.get("ers_tick", -999)) >= 300:
			z["ers_tick"] = ps.sim.tick_count
			if _a("ersetzen", ps.fahrzeug_ersetzen(int(f["vid"]), neu)):
				z["ersetzt"] = int(z["ersetzt"]) + 1
			return


func _firmen() -> void:
	for nm in [MUEHLE, SAEGE, SCHMIEDE]:
		if not ps.stationen.has(nm):
			continue
		var site: int = ps.stationen[nm]["site"]
		if int(ps.eco.s_owner[site]) != 1:
			if _n_fz(nm, DORF) + _n_fz(nm, STADT) == 0:
				continue
			var q: Dictionary = ps.kauf_angebot(nm)
			if q.get("ok", false) and q.get("kaufbar", false) and int(q["preis_cent"]) + reserve <= _cash() - ps.credit.loan_cent:
				_a("firma", ps.firma_kaufen(nm))
			return
		var aq: Dictionary = ps.ausbau_angebot(nm)
		if aq.get("ok", false) and int(aq["stufe_neu"]) <= 2 and int(aq["kosten_cent"]) + reserve <= _cash() - ps.credit.loan_cent:
			_a("ausbau", ps.werk_ausbauen(nm))
			return


func _hq() -> void:
	if _min() < 8.0:
		return
	for an in ps.daten["hq"]["anbauten"]:
		var q: Dictionary = ps.hq_anbau_angebot(String(an["id"]))
		if q.get("ok", false) and int(q["kosten_cent"]) + reserve + 60000 <= _cash() - ps.credit.loan_cent:
			_a("hq_anbau", ps.hq_anbauen(String(an["id"])))
			return
	var h: Dictionary = ps.hq_ausbau_angebot()
	if h.get("ok", false) and int(h["kosten_cent"]) + reserve + 100000 <= _cash() - ps.credit.loan_cent:
		_a("hq_ausbau", ps.hq_ausbauen())


# ------------------------------------------------------------------ Auswertung

func _p(werte: Array, q: float) -> float:
	if werte.is_empty():
		return -1.0
	var s := werte.duplicate()
	s.sort()
	return float(s[clampi(int(round(q * (s.size() - 1))), 0, s.size() - 1)])


func _zusammenfassung(res: Array, det_ok: bool, ms: int) -> bool:
	var n := res.size()
	print("demo_bot: %d Läufe, Strategie %s, %d min, Seeds %d..%d, tempo_k %d, Satz %s" % [n, strategie, minuten, seed0, seed0 + n - 1,
		ps.tempo_k if ps != null else 0, ps.eco.oe_set if ps != null else "?"])
	var bank := 0
	var fen_summe := 0
	var fen_max := 0
	var fehler_summe := 0
	var cols := {}
	for r in res:
		if int(r["bankrott_min"]) >= 0:
			bank += 1
		fen_summe += int(r["fenster_ohne"])
		fen_max = maxi(fen_max, int(r["fenster_ohne"]))
		fehler_summe += int(r["sim_fehler"])
		for k in ["kasse", "aktionen", "luecke_max_s", "luecke_streng_s", "arten_x10", "luecke_akt_s", "meilensteine", "skillpunkte", "skills", "v_ok", "v_fehl", "v_an",
				"strassen", "gleise", "zuege", "ersetzt", "firmen", "hq_stufe", "anbauten", "ertrag_min30", "fahrzeuge", "ablehnungen"]:
			if not cols.has(k):
				cols[k] = []
			cols[k].append(int(r[k]))
	print("  Bankrott: %d/%d" % [bank, n])
	print("  Gate A Aktionsfenster: 60-s-Fenster ohne Angebot Summe %d (max je Lauf %d); längste Angebotslücke P50 %d s, Max %d s" % [
		fen_summe, fen_max, int(_p(cols.get("luecke_max_s", []), 0.5)), int(_p(cols.get("luecke_max_s", []), 1.0))])
	for k in cols:
		print("  %-14s min %6d  P25 %6d  P50 %6d  P75 %6d  max %6d" % [k, int(_p(cols[k], 0.0)), int(_p(cols[k], 0.25)),
			int(_p(cols[k], 0.5)), int(_p(cols[k], 0.75)), int(_p(cols[k], 1.0))])
	# Aktionen je Art (Mittel) und Meilenstein-Minuten (P50)
	var arten := {}
	var msm := {}
	var abl_ges := {}
	for r in res:
		for k in r["akt"]:
			arten[k] = int(arten.get(k, 0)) + int(r["akt"][k])
		for k in r["ms"]:
			if not msm.has(k):
				msm[k] = []
			msm[k].append(int(r["ms"][k]) / 600.0)
		for k in r["abl"]:
			abl_ges[k] = int(abl_ges.get(k, 0)) + int(r["abl"][k])
	var at := "  Aktionen je Lauf (Mittel):"
	for k in arten:
		at += " %s %.1f" % [k, float(arten[k]) / maxi(1, n)]
	print(at)
	var mt := "  Meilensteine Minute P50 (erreicht/n):"
	for m in (ps.daten.get("meilensteine", []) if ps != null else []):
		var id := String(m["id"])
		mt += " %s %.1f (%d/%d)" % [id, _p(msm.get(id, []), 0.5), msm.get(id, []).size(), n]
	print(mt)
	if n > 0:
		var ft := "  Freischaltungen (Lauf 1):"
		for f in res[0]["frei"]:
			ft += " %s Min %.0f" % [f["id"], int(f["tick"]) / 600.0]
		print(ft)
	print("  Ablehnungen der Spieler-API: %s" % str(abl_ges))
	if fehler_summe > 0:
		print("  SIM-FEHLER: %s" % str(res.filter(func(r): return int(r["sim_fehler"]) > 0).map(func(r): return r["fehler"]).slice(0, 3)))
	print("  Sim-Fehler gesamt: %d" % fehler_summe)
	print("  Determinismus: %s" % ("OK" if det_ok else "FEHLER") + ("" if det_check else " (nicht geprüft)"))
	print("  LAUFZEIT %.1f s gesamt, %.0f ms je Lauf" % [ms / 1000.0, float(ms) / maxi(1, n + (1 if det_check else 0))])
	var gate_ok: bool = bank == 0 and fen_summe == 0 and fehler_summe == 0 and int(_p(cols.get("luecke_max_s", [0]), 1.0)) <= 120
	print("  Gate A (kein Bankrott, kein 60-s-Fenster ohne Angebot, Lücke ≤ 120 s, 0 Sim-Fehler): %s" % ("ERFÜLLT" if gate_ok else "VERLETZT"))
	return det_ok and fehler_summe == 0 and (gate_ok or not gate)
