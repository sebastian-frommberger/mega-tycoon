extends SceneTree
## S8 QT-03 (Daniel): Loop-Bot headless auf der ProtoSim-API (Spieler-API aus AT-02/AT-03, wie die Welt-UI sie nutzen wird).
## Kein main.gd, keine UI, kein Eingriff in Spielcode. Misst nach Sprint-Ziel S8: Bankrott je Strategie, Minute je Ziel
## E-1..E-6/F1/F2, Entscheidungsereignisse 1-8 (Flanken) mit größter Lücke, Determinismus. Ein Lauf = ein Seed = eine Welt.
##
## Start (aus slice/):
##   godot --headless --path . -s res://tests/s8_loop_bot.gd -- [--n=20] [--strategie=naiv|normal|plan|alle] [--tempo_k=N]
##        [--csv=/abs/pfad.csv] [--seed0=1] [--minuten=45] [--takt=300] [--startkapital=6000] [--gate] [--ohne_det] [--v]
##        [--p_<name>=<wert>]   (Strategie-Parameter, siehe PARAM; werden in der Ausgabe und in <csv>.meta.txt gelistet)
##   --tempo_k und --jahr_ticks liest ProtoSim selbst aus denselben Nutzerargumenten (AT-04, FZ-02).
## Ausgabe: CSV je Lauf (deterministisch, ohne Zeiten), <csv>.zeit.csv (Laufzeit je Lauf, Wanduhr), <csv>.meta.txt, Zusammenfassung auf stdout.
## Exit 0, wenn alle Läufe durchliefen und der Determinismus-Check (Seed zweimal = gleiche Zeile + Prüfsumme) hält.
## --gate: zusätzlich Exit 1, wenn die Sprint-Bänder verletzt sind (naiv 10-30 %, plan <= 5 % Bankrott, plan Lücke P90 <= 1800 Ticks);
## sinnvoll erst bei n >= 300 (Wilson-Intervall beachten), bei kleinem n nur als Info.
##
## STRATEGIEN (Setzung von Daniel nach design.md Q2 / S7-Spielertypen aus d08_bankrott; KEINE Kalibrierung, KEIN Spielerbeleg):
##   naiv    "Zocker": baut nach 0-4 min, vergisst bei 50 % die Mühlenlizenz 3-8 min (Mehllinie bringt nichts), 50 % Fehlverbindung
##           (Getreide direkt zum Dorf), Kaufrausch ohne Reserve (Fuhrwerke, solange Kasse >= Preis + Rest), Kredit "voll" ab Sperre.
##   normal  "Durchschnitt": baut nach 1-3 min eine Kette nach Bedarf (0-1 Extra-Fuhrwerk), Reserve 1.500 $, Mehl zuerst ins Dorf,
##           Lindenfurt, sobald das Dorf gesättigt ist (nach 0-3 min Reaktionszeit) oder ab Minute 12; Kredit nur bei Bedarf, Tilgung
##           ab 1.500 $ Überschuss.
##   plan    spielt den Entscheidungsfahrplan aus design.md 1.3 nach (Minuten +0-2 min Jitter je Schritt): Lizenz Farm, Linie Farm-Mühle,
##           Mehl Dorf (3), Lindenfurt (10), Firmenkauf Mühle (14, API fehlt -> Schnittstelle), Farm 2 (20), Frachtwagen-Ersatz ab 1830,
##           Kredit tilgen. Reserve 1.500 $, Anzahl Fuhrwerke nach Bedarf (Umlaufzeit aus Strecke und Tempo).
## Der Plan-Bot spielt den Fahrplan, den wir selbst geschrieben haben (Goodhart): Er misst Drift der Zahlen, nicht Spaß (mt-qa Regel 10).

const ProtoSim := preload("res://proto/proto_sim.gd")
const SZENE := "res://proto/prototyp_welt.tscn"
const ZIELE_JSON := "res://data/ziele_welt.json"
const CONSTS_JSON := "res://data/economy_constants.json"
const PERIODE := 600
const FARM1 := "Gut Kuppenhof"
const MUEHLE := "Erlenmühle"
const FARM2 := "Hof Hasenwinkel"
const DORF := "Erlenbach"
const STADT := "Lindenfurt"
const STRATEGIEN := ["naiv", "normal", "plan"]
const RESERVE_CENT := 150000        # normal/plan: 1.500 $ Reserve
const SAETT_PM_DEFAULT := 1000      # Ereignis 2: Wechsel auf gelb (W19), Vorschlag aus ziele_welt.json (design.md nennt 1.200)

## Strategie-Parameter, per --p_<name>= überschreibbar (ganze Zahlen). Alle gesetzt, nicht gemessen.
var PARAM := {
	"naiv_bau_max": 4,              # Bau nach 0..N min
	"naiv_vergessen_pct": 50,       # Mühlenlizenz vergessen 3..8 min
	"naiv_fehl_pct": 50,            # Getreide direkt ins Dorf
	"naiv_fz_max": 14,              # Obergrenze Fuhrwerke (Kaufrausch)
	"naiv_rest_max": 8,             # Restkasse nach Kauf 0..N x 100 $
	"normal_extra_pct": 50,         # 1 Extra-Fuhrwerk je Linie
	"normal_reserve": 150000,
	"normal_tilge": 150000,
	"plan_reserve": 150000,
	"plan_jitter": 2,               # Minuten
	"plan_farm2_min": 20,
	"plan_lindenfurt_min": 10,
	"plan_fk_min": 14,
	"plan_farm2": 1,                # 1 = Farm 2 laut Fahrplan ab Minute 20, 0 = nie
	"plan_fk": 1,                   # 1 = Plan-Bot kauft die Mühle (FK-02), 0 = nie (Vergleichslauf "ohne Kauf", gleicher Seed)
	"plan_ausbau": 1,               # 1 = nach dem Kauf Werksstufe 2 (sobald Kasse ohne Kredit >= Kosten + Reserve)
	"plan_mehl_dorf2": 15,          # Mehlmenge E/min Mühle -> Dorf nach Ausbau (vorher 10; Dorfnachfrage ca. 18)
	"plan_mehl_stadt2": 25,         # Mehlmenge E/min Mühle -> Stadt nach Ausbau (vorher 10)
	"normal_fk_min": 28,            # normal kauft die Mühle spät (ab Minute N + Reaktion 0..3), 0 = nie
	"naiv_fk_pct": 0,               # naiv: Anteil Läufe, die die Mühle kaufen (ab Minute 10, ohne Reserve), Setzung 0 = "ohne"
	"plan_ersetzen": 1,             # OE-02 (Tobias): 1 = Frachtwagen-Ersatz ab 1830 wie bisher, 0 = nie (Zuordnungslauf)
}

# ------------------------------------------------------------------ Aufruf-Parameter
var n_lauefe := 20
var strategie_arg := "alle"
var csv_pfad := ""
var seed0 := 1
var minuten := 45
var takt := 300
var startkapital_dollar := 0
var gate := false
var det_check := true
var verbose := false
var saett_pm := SAETT_PM_DEFAULT
var a_pm := 1000                    # Ertragsfaktor a (Promille): wird NUR gelesen (eco.ertrag_a_promille); --a= liest ProtoSim selbst (FX3), der Bot rechnet nichts mehr
var fk_global := true               # --fk=aus : Firmenkauf für alle Strategien aus (Vergleichslauf)
var alterung_override := -1         # --alterung=aus|an : ProtoSim.alterung_an (Attributionslauf, Testwerkzeug)
var deckel_override := -1           # --deckel=N : eco.inbuf_cap_perioden (0 = Mühlendeckel aus; Attributionslauf, Testwerkzeug)
var oe_set := ""                    # OE-02 (Tobias): --oe_set=<name> wählt ein Kalibrier-Set aus economy_proto.json (economy.gd liest es selbst);
var FZ := "fuhrwerk_e1"             #   der Bot nimmt daraus nur die Fahrzeug-Datensätze (fahrzeuge.fuhrwerk / .frachtwagen). Ohne Set: wie bisher.
var FW := "frachtwagen_e1"

# ------------------------------------------------------------------ Welt (einmal geladen)
var szene: Node
var orte: Dictionary
var ziele: Dictionary = {}          # id -> Zieldatensatz aus ziele_welt.json
var luecke_von_min := 2
var luecke_bis_min := 45
var luecke_max_ticks := 1800
var hinweis_vor_ablauf := 1800
var schwelle_f1 := 500
var schwelle_f2 := 60000
var schwelle_e4 := 10

# ------------------------------------------------------------------ Zustand des laufenden Laufs
var ps = null
var rng := RandomNumberGenerator.new()
var strat := ""
var seed_nr := 0
var gesamt_ticks := 0
var li_idx := 0
var fs_idx := 0
var evs: Array = []                 # [tick, nr]
var ev_n := PackedInt32Array()      # Zähler Ereignis 1..8 (Index 0 ungenutzt)
var ev_erst := PackedInt32Array()   # erster Tick je Ereignis, -1
var z: Dictionary = {}              # Ziel -> erster Tick (Ende Periode/Aktion), -1
var api_abl: Dictionary = {}        # Ablehnungsgrund -> Anzahl (Bot-Aufrufe der Spieler-API)
var api_aufrufe := 0
var gruppen: Dictionary = {}        # "von|nach" -> {von, nach, vids: Array, seit_periode: int, ertrag: int}
var node_name: Dictionary = {}      # Knoten -> Stationsname
var lic_haben: Dictionary = {}      # Name -> true (Bot hat gekauft)
var ertrag_p := 0
var fahrk_last := 0
var exp_last := 0
var kauf_last := 0
var zins_last := 0
var rev_last := 0
var lizpaid_last := 0
var bot_lic_cent := 0
var bot_lic_last := 0
var netto_op: Array = []            # je Periode
var netto_kasse: Array = []
var cash_last := 0
var loan_last := 0
var f2_op_serie := 0
var f2_kasse_serie := 0
var v_hist := {DORF: [], STADT: []} # V je Periodenende (Promille)
var v_alt := {DORF: 0, STADT: 0}
var low_zaehler: Dictionary = {}    # vid -> aufeinanderfolgende Lieferungen < 500 Promille Ladung
var low_aktiv: Dictionary = {}      # vid -> true, solange Ereignis 3 für dieses Fahrzeug ausgelöst ist
var e3_spec_n := 0
var e3_spec_aktiv: Dictionary = {}
var lic_warn: Dictionary = {}       # Site -> true, solange Hinweis aktiv
var kaufart_unten: Dictionary = {}  # kaufart -> war im vorigen Periodenende unter Preis
var deckel_aktiv := false
var fz_alt_aktiv: Dictionary = {}
var getreide_muehle := 0
var mehl_dorf := 0
var e6_serie_alle := 0
var e6_serie_eine := 0
var gruppe_vor_fields: Dictionary = {}  # vid -> v_fields beim letzten Periodenende
var kasse_tief_5_20 := 1 << 60
var kredit_max := 0
var fz_max := 0
var netto5_op_min30 := 0
var netto5_kasse_min30 := 0
var fk_versuche := 0
var fk_status := ""
var naiv: Dictionary = {}
var plan: Dictionary = {}
var normal: Dictionary = {}
var tilge_ok := true
var rw_total := 0                   # Σ Restwert-Gutschriften (Abgleich Kasse)
var rw_last := 0
var recon_fehler := 0               # Periodenabgleich Kassendelta/Netto verletzt
var recon_text := ""
var mutant := ""                    # --mutant=det|recon: absichtlich kaputt, der Wächter muss rot werden
var fk_total := 0                   # Σ Firmenkauf + Ausbau (Cent), nur Anzeige/CSV; ProtoSim.kauf_total zählt sie seit FX3 mit (nicht mehr addieren)
var fk_kauf_tick := -1
var fk_preis := 0
var fk_ausbau_tick := -1
var fk_ausbau_cent := 0
var fk_grund := ""                  # letzter Ablehnungsgrund (kauf_angebot.grund)
var fk_kauf_pending := false
var ersetzt_n := 0
var ersetzt_erst := -1
var ersetzt_spart := 0              # Σ spart_cent_pro_periode der Ersetzungen
var ev8_fm_tick := -1               # Ereignis 8 (a): Folgemodell freigeschaltet
var ev8_alter_tick := -1            # Ereignis 8 (b): Fuhrwerk-Unterhalt >= +40 % (Alter >= 8 Jahre)
var ers_angebot_tick := -1          # erstes ersetzen_angebot ok (Plan-Bot, ältestes Fuhrwerk >= 8 Jahre)
var ers_spart_tick := -1            # erstes Angebot mit spart_cent_pro_periode > 0
var kasse_tief_tick := -1
var serie: Array = []               # Zeilen der Serien-CSV (je Periode)
var serie_aktiv := true


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="):
			n_lauefe = int(a.substr(4))
		elif a.begins_with("--strategie="):
			strategie_arg = a.substr(12)
		elif a.begins_with("--csv="):
			csv_pfad = a.substr(6)
		elif a.begins_with("--seed0="):
			seed0 = int(a.substr(8))
		elif a.begins_with("--minuten="):
			minuten = int(a.substr(10))
		elif a.begins_with("--takt="):
			takt = maxi(1, int(a.substr(7)))
		elif a.begins_with("--startkapital="):
			startkapital_dollar = int(a.substr(15))
		elif a.begins_with("--saett_pm="):
			saett_pm = int(a.substr(11))
		elif a == "--gate":
			gate = true
		elif a.begins_with("--a="):
			pass        # FX3: ProtoSim liest --a= selbst aus den Nutzerargumenten (eco.ertrag_a_promille); der Bot rechnet keinen Bonus mehr
		elif a.begins_with("--alterung="):
			alterung_override = 0 if a.substr(11) == "aus" else 1
		elif a.begins_with("--deckel="):
			deckel_override = int(a.substr(9))
		elif a.begins_with("--oe_set="):
			oe_set = a.substr(9)
			var pj = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy_proto.json"))
			var st: Dictionary = pj.get("kalibrierung_sets", {}).get(oe_set, {}) if pj is Dictionary else {}
			FZ = String(st.get("fahrzeuge", {}).get("fuhrwerk", FZ))
			FW = String(st.get("fahrzeuge", {}).get("frachtwagen", FW))
		elif a.begins_with("--fk="):
			fk_global = a.substr(5) != "aus"
		elif a == "--ohne_det":
			det_check = false
		elif a == "--v":
			verbose = true
		elif a.begins_with("--mutant="):
			mutant = a.substr(9)
		elif a.begins_with("--p_"):
			var kv: PackedStringArray = a.substr(4).split("=")
			if kv.size() == 2 and PARAM.has(kv[0]):
				PARAM[kv[0]] = int(kv[1])
			else:
				print("WARNUNG unbekannter Parameter ", a)
	_run.call_deferred()


# ====================================================================== Hauptprogramm

func _run() -> void:
	var t_start := Time.get_ticks_usec()
	szene = (load(SZENE) as PackedScene).instantiate()
	szene.set("sim_aus", true)
	root.add_child(szene)
	await process_frame
	orte = JSON.parse_string(FileAccess.get_file_as_string(szene.datei("proto_orte.json")))
	_ziele_laden()
	var load_ms := (Time.get_ticks_usec() - t_start) / 1000.0
	var liste: Array = STRATEGIEN if strategie_arg == "alle" else [strategie_arg]
	for s in liste:
		if not STRATEGIEN.has(s):
			print("FEHLER unbekannte Strategie ", s)
			quit(2)
			return
	print("s8_loop_bot: n=%d, Strategien %s, Seeds %d..%d, %d min, Takt %d Ticks, Szene laden %.0f ms" % [n_lauefe, str(liste), seed0, seed0 + n_lauefe - 1, minuten, takt, load_ms])
	var fails := 0
	var zeilen: Array = []              # CSV-Zeilen (ohne Kopf)
	var zeiten: Array = []              # "strategie,seed,ms,ticks"
	var je_strat := {}                  # strategie -> Array von Ergebnis-Dictionaries
	var ms_je_strat := {}
	var t_lauf0 := Time.get_ticks_usec()
	# --- Determinismus: Seed seed0 je Strategie zweimal
	var det_ok := true
	var det_info: Array = []
	if det_check:
		for s in liste:
			var a: Dictionary = _lauf(s, seed0)
			var b: Dictionary = _lauf(s, seed0)
			var gleich: bool = a["zeile"] == b["zeile"] and a["pruefsumme"] == b["pruefsumme"]
			det_ok = det_ok and gleich
			det_info.append("%s Seed %d: %s (Prüfsumme %d / %d)" % [s, seed0, "gleich" if gleich else "VERSCHIEDEN", a["pruefsumme"], b["pruefsumme"]])
			print("  Determinismus ", det_info[-1])
	# --- Läufe
	for s in liste:
		je_strat[s] = []
		ms_je_strat[s] = []
		for i in n_lauefe:
			var sd := seed0 + i
			var t0 := Time.get_ticks_usec()
			var r: Dictionary = _lauf(s, sd)
			var ms := (Time.get_ticks_usec() - t0) / 1000.0
			r["ms"] = ms
			je_strat[s].append(r)
			ms_je_strat[s].append(ms)
			zeilen.append(r["zeile"])
			zeiten.append("%s,%d,%.1f,%d" % [s, sd, ms, r["ticks"]])
			if r.get("fehler", "") != "":
				fails += 1
				print("  FEHLER ", s, " Seed ", sd, ": ", r["fehler"])
			if verbose:
				print("  ", r["zeile"], "  (%.0f ms)" % ms)
	var lauf_ms := (Time.get_ticks_usec() - t_lauf0) / 1000.0
	# --- Ausgabe
	var kopf := _csv_kopf()
	if csv_pfad != "":
		DirAccess.make_dir_recursive_absolute(csv_pfad.get_base_dir())
		var f := FileAccess.open(csv_pfad, FileAccess.WRITE)
		if f == null:
			print("FEHLER CSV nicht schreibbar: ", csv_pfad)
			fails += 1
		else:
			f.store_line(kopf)
			for zl in zeilen:
				f.store_line(zl)
			f.close()
			var fz := FileAccess.open(csv_pfad + ".zeit.csv", FileAccess.WRITE)
			fz.store_line("strategie,seed,ms,ticks")
			for zl in zeiten:
				fz.store_line(zl)
			fz.close()
			var fs := FileAccess.open(csv_pfad + ".serie.csv", FileAccess.WRITE)
			fs.store_line("strategie,seed,periode,netto_op_cent,netto_kasse_cent,kasse_cent,kredit_cent,ertrag_cent,fahrzeuge_gebaut")
			for s2 in je_strat:
				for rr in je_strat[s2]:
					for sz in rr["serie"]:
						fs.store_line(sz)
			fs.close()
			var fm := FileAccess.open(csv_pfad + ".meta.txt", FileAccess.WRITE)
			fm.store_line("Godot %s, Szene proto, tempo_k %d, jahr_ticks %d, startkapital_dollar_override %d, minuten %d, takt %d, saett_pm %d, a_pm %d, fk_global %s, alterung_override %d, deckel_override %d, oe_set %s, fz %s, fw %s" % [Engine.get_version_info()["string"], _tempo_k(), _jahr_ticks(), startkapital_dollar, minuten, takt, saett_pm, a_pm, str(fk_global), alterung_override, deckel_override, oe_set if oe_set != "" else "-", FZ, FW])
			fm.store_line("n %d, seed0 %d, Strategien %s" % [n_lauefe, seed0, str(liste)])
			fm.store_line("PARAM " + JSON.stringify(PARAM))
			fm.store_line("Firmenkauf-Schnittstelle: " + fk_status)
			fm.close()
			print("CSV: ", csv_pfad, " (", zeilen.size(), " Zeilen)")
	var bad_gate := false
	for s in liste:
		bad_gate = _zusammenfassung(s, je_strat[s], ms_je_strat[s]) or bad_gate
	print("Parameter: ", JSON.stringify(PARAM))
	print("Firmenkauf-Schnittstelle (FK-02): ", fk_status if fk_status != "" else "nicht angefragt")
	# --- Laufzeit und Hochrechnung
	var anzahl := 0
	var summe := 0.0
	var maxi_ms := 0.0
	for s in liste:
		for m in ms_je_strat[s]:
			anzahl += 1
			summe += m
			maxi_ms = maxf(maxi_ms, m)
	if anzahl > 0:
		var mittel := summe / anzahl
		print("LAUFZEIT %d Läufe: Summe %.1f s, Mittel %.0f ms/Lauf, Max %.0f ms; Gesamtlauf inkl. Determinismus-Doppel %.1f s, Szene laden %.1f s" % [anzahl, summe / 1000.0, mittel, maxi_ms, lauf_ms / 1000.0, load_ms / 1000.0])
		print("HOCHRECHNUNG n=300 (Mittel x 300 x %d Strategien, linear): %.1f min; n=150: %.1f min (Annahme: Laufzeit je Lauf unabhängig von n, gleiche Last)" % [liste.size(), mittel * 300.0 * liste.size() / 60000.0, mittel * 150.0 * liste.size() / 60000.0])
	print("Determinismus: ", "OK" if det_ok else "FEHLER", " ", "(nicht geprüft: --ohne_det)" if not det_check else "")
	var ex := 0
	if not det_ok or fails > 0:
		ex = 1
	if gate and bad_gate:
		ex = 1
	print("s8_loop_bot Exit ", ex)
	quit(ex)


func _tempo_k() -> int:
	return int(szene.regelwerk.get("fahrzeug_easing", {}).get("tempo_k", {}).get("standard", 1)) if _arg_tempo_k() < 0 else _arg_tempo_k()


func _arg_tempo_k() -> int:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tempo_k="):
			return int(a.substr(10))
	return -1


func _jahr_ticks() -> int:
	return int(ProtoSim.new(szene.regelwerk).jahr_ticks)


func _ziele_laden() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ZIELE_JSON))
	for zd in d["ziele"]:
		ziele[zd["id"]] = zd
	schwelle_f1 = int(ziele["f1"]["messgroesse"]["schwelle"])
	schwelle_f2 = int(ziele["f2"]["messgroesse"]["schwelle"])
	schwelle_e4 = int(ziele["e4"]["messgroesse"]["schwelle"])
	var lr: Dictionary = d["ereignisse"]["luecken_regel"]
	luecke_von_min = int(lr["von_minute"])
	luecke_bis_min = int(lr["bis_minute"])
	luecke_max_ticks = int(lr["max_luecke_ticks"])
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONSTS_JSON))
	hinweis_vor_ablauf = int(c["lizenz"]["hinweis_vor_ablauf_ticks"])


# ====================================================================== Ein Lauf

func _csv_kopf() -> String:
	return "strategie,seed,tempo_k,startkapital_cent,ticks,bankrott,bankrott_min,z_e1,z_e2,z_e3,z_e4,z_e5,z_e6_alle,z_e6_eine,z_f1,z_f2_op,z_f2_kasse," \
		+ "ev1,ev2,ev3,ev4,ev5,ev6,ev7,ev8,ev3_spec,luecke_max_min,luecke_bei_min,luecke_ohne_ev3_min,fz_max,fz_ende,lieferungen,ertrag_cent,kasse_ende_cent,kasse_tief_5_20_cent," \
		+ "kredit_max_cent,kredit_ende_cent,netto5_op_min30_cent,netto5_kasse_min30_cent,fehl_api,pruefsumme," \
		+ "fk_kauf_min,fk_preis_cent,fk_ausbau_min,fk_ausbau_cent,ersetzt_n,ersetzt_erst_min,ev8_erst_min,tief_min,a_pm,fk_grund," \
		+ "ev8_folgemodell_min,ev8_alter_min,ers_angebot_min,ers_spart_min"


func _min_text(tick: int) -> String:
	return "-1" if tick < 0 else "%.2f" % (tick / 600.0)


func _lauf(s: String, sd: int) -> Dictionary:
	_reset(s, sd)
	var fehler := ""
	var t: int = 0
	while t < gesamt_ticks and not ps.konto.bankrupt:
		if t % takt == 0:
			_takt(t)
			_ziele_pruefen(t)
		ps.tick()
		t = ps.sim.tick_count
		_beobachten(t)
	_ziele_pruefen(t)
	if not ps.fehler.is_empty():
		fehler = str(ps.fehler)
	var ende: int = t
	# größte Ereignislücke im Fenster [2, 45] min, bis Bankrott/Ende
	evs.sort_custom(func(a, b): return a[0] < b[0])
	var g1: Array = _luecke(ende, 0)
	var g3: Array = _luecke(ende, 3)
	var gmax: int = g1[0]
	var gbei: int = g1[1]
	if recon_fehler > 0:
		fehler += " Abgleich: " + recon_text
	var sum_l := 0
	for L in ps.lieferungen:
		sum_l += int(L["cent"])
	if sum_l != ps.eco.revenue_total:
		fehler += " Abgleich: Σ Lieferungen %d != revenue_total %d" % [sum_l, ps.eco.revenue_total]
	var br: int = 1 if ps.konto.bankrupt else 0
	var kasse_ende: int = ps.eco.cash_cent
	var zeile := "%s,%d,%d,%d,%d,%d,%s" % [s, sd, ps.tempo_k, _startkapital_cent(), ende, br, _min_text(ps.bankrott_tick)]
	for zid in ["e1", "e2", "e3", "e4", "e5", "e6_alle", "e6_eine", "f1", "f2_op", "f2_kasse"]:
		zeile += "," + _min_text(int(z.get(zid, -1)))
	for nr in range(1, 9):
		zeile += ",%d" % ev_n[nr]
	zeile += ",%d" % e3_spec_n
	zeile += ",%.2f,%.2f,%.2f" % [gmax / 600.0, gbei / 600.0, int(g3[0]) / 600.0]
	var fz_ende := 0
	for f in ps.fahrzeuge:
		if not f["verkauft"]:
			fz_ende += 1
	var tief: int = kasse_tief_5_20 if kasse_tief_5_20 != (1 << 60) else -1
	var api_n := 0
	for k in api_abl:
		api_n += int(api_abl[k])
	zeile += ",%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d" % [fz_max, fz_ende, ps.lieferungen.size(), ps.eco.revenue_total, kasse_ende, tief,
		kredit_max, ps.credit.loan_cent, netto5_op_min30, netto5_kasse_min30, api_n, ps.pruefsumme()]
	zeile += ",%s,%d,%s,%d,%d,%s,%s,%s,%d,%s" % [_min_text(fk_kauf_tick), fk_preis, _min_text(fk_ausbau_tick), fk_ausbau_cent, ersetzt_n,
		_min_text(ersetzt_erst), _min_text(ev_erst[8]), _min_text(kasse_tief_tick), a_pm, fk_grund if fk_kauf_tick < 0 else ""]
	zeile += ",%s,%s,%s,%s" % [_min_text(ev8_fm_tick), _min_text(ev8_alter_tick), _min_text(ers_angebot_tick), _min_text(ers_spart_tick)]
	return {"zeile": zeile, "pruefsumme": ps.pruefsumme(), "ticks": ende, "bankrott": br, "bankrott_tick": ps.bankrott_tick,
		"z": z.duplicate(), "ev_n": Array(ev_n), "gmax": gmax, "gbei": gbei, "gmax3": int(g3[0]), "strategie": s, "seed": sd, "fehler": fehler,
		"fz_max": fz_max, "kasse_ende": kasse_ende, "tief": tief, "api_abl": api_abl.duplicate(), "api_aufrufe": api_aufrufe,
		"n5_op": netto5_op_min30, "n5_kasse": netto5_kasse_min30,
		"fk_kauf": fk_kauf_tick, "fk_ausbau": fk_ausbau_tick, "fk_preis": fk_preis, "ersetzt_erst": ersetzt_erst, "ersetzt_n": ersetzt_n, "ev8": ev_erst[8],
		"serie": serie.duplicate()}


## Größte Lücke zwischen zwei Ereignissen im Fenster [luecke_von_min, luecke_bis_min] min (Ränder zählen als Ereignis),
## bis Bankrott/Laufende. ohne_nr > 0 lässt diesen Ereignistyp weg. Rückgabe [Lücke, Beginn] in Ticks.
func _luecke(ende: int, ohne_nr: int) -> Array:
	var lo := luecke_von_min * PERIODE
	var hi := mini(luecke_bis_min * PERIODE, ende)
	var prev := lo
	var gmax := 0
	var gbei := lo
	for e in evs:
		if int(e[1]) == ohne_nr:
			continue
		var et: int = e[0]
		if et < lo or et > hi:
			continue
		if et - prev > gmax:
			gmax = et - prev
			gbei = prev
		prev = et
	if hi - prev > gmax and hi > lo:
		gmax = hi - prev
		gbei = prev
	return [gmax, gbei]


func _startkapital_cent() -> int:
	return startkapital_dollar * 100 if startkapital_dollar > 0 else int(ps.eco.slice["hq"]["start_capital_cent"])


func _reset(s: String, sd: int) -> void:
	strat = s
	seed_nr = sd
	rng.seed = sd * 7919 + STRATEGIEN.find(s) * 104729 + 17
	if mutant == "det":
		rng.seed = Time.get_ticks_usec()          # Mutant: Verhalten nicht mehr vom Seed bestimmt
	ps = ProtoSim.new(szene.regelwerk)
	ps.graph_bauen(szene.strassen)
	ps.spiel_starten(orte)
	a_pm = ps.eco.ertrag_a_promille            # gelesen, nicht gesetzt (FX3)
	if alterung_override >= 0:
		ps.alterung_an = alterung_override == 1
	if deckel_override >= 0:
		ps.eco.inbuf_cap_perioden = deckel_override
	if startkapital_dollar > 0:
		ps.eco.cash_cent = startkapital_dollar * 100       # Testwerkzeug setzt das Startkapital (W24-Variation 3.000/4.500/6.000 $)
	gesamt_ticks = minuten * PERIODE
	li_idx = 0
	fs_idx = 0
	evs = []
	ev_n = PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0])
	ev_erst = PackedInt32Array([-1, -1, -1, -1, -1, -1, -1, -1, -1])
	z = {}
	api_abl = {}
	api_aufrufe = 0
	gruppen = {}
	node_name = {}
	for nm in ps.stationen:
		node_name[int(ps.stationen[nm]["knoten"])] = nm
	lic_haben = {}
	ertrag_p = 0
	fahrk_last = 0
	exp_last = 0
	kauf_last = 0
	zins_last = 0
	rev_last = 0
	lizpaid_last = 0
	bot_lic_cent = 0
	bot_lic_last = 0
	netto_op = []
	netto_kasse = []
	cash_last = ps.eco.cash_cent
	loan_last = 0
	f2_op_serie = 0
	f2_kasse_serie = 0
	v_hist = {DORF: [], STADT: []}
	v_alt = {DORF: 0, STADT: 0}
	low_zaehler = {}
	low_aktiv = {}
	e3_spec_n = 0
	e3_spec_aktiv = {}
	lic_warn = {}
	kaufart_unten = {}
	deckel_aktiv = false
	fz_alt_aktiv = {}
	getreide_muehle = 0
	mehl_dorf = 0
	e6_serie_alle = 0
	e6_serie_eine = 0
	gruppe_vor_fields = {}
	kasse_tief_5_20 = 1 << 60
	kredit_max = 0
	fz_max = 0
	netto5_op_min30 = 0
	netto5_kasse_min30 = 0
	fk_versuche = 0
	tilge_ok = true
	rw_total = 0
	rw_last = 0
	fk_total = 0
	fk_kauf_tick = -1
	fk_preis = 0
	fk_ausbau_tick = -1
	fk_ausbau_cent = 0
	fk_grund = ""
	ersetzt_n = 0
	ersetzt_erst = -1
	ersetzt_spart = 0
	ev8_fm_tick = -1
	ev8_alter_tick = -1
	ers_angebot_tick = -1
	ers_spart_tick = -1
	kasse_tief_tick = -1
	serie = []
	recon_fehler = 0
	recon_text = ""
	_fk_status_pruefen()
	_strategie_ziehen()


func _strategie_ziehen() -> void:
	match strat:
		"naiv":
			naiv = {
				"bau": rng.randi_range(0, int(PARAM["naiv_bau_max"])),
				"vergessen": rng.randi_range(3, 8) if rng.randi_range(0, 99) < int(PARAM["naiv_vergessen_pct"]) else 0,
				"fehl": rng.randi_range(0, 99) < int(PARAM["naiv_fehl_pct"]),
				"mehl_ziel": STADT if rng.randi_range(0, 1) == 1 else DORF,
				"x_farm": rng.randi_range(0, 1),
				"x_mehl": rng.randi_range(0, 1),
				"rest": rng.randi_range(0, int(PARAM["naiv_rest_max"])) * 10000,
				"fz_max": rng.randi_range(6, int(PARAM["naiv_fz_max"])),
				"fk": false,
			}
			if int(PARAM["naiv_fk_pct"]) > 0:
				naiv["fk"] = rng.randi_range(0, 99) < int(PARAM["naiv_fk_pct"])      # zieht nur bei Param > 0: Standardläufe bleiben RNG-gleich
		"normal":
			normal = {
				"bau": rng.randi_range(1, 3),
				"x_farm": 1 if rng.randi_range(0, 99) < int(PARAM["normal_extra_pct"]) else 0,
				"x_mehl": 1 if rng.randi_range(0, 99) < int(PARAM["normal_extra_pct"]) else 0,
				"reaktion": rng.randi_range(0, 3),
			}
		"plan":
			var j: int = int(PARAM["plan_jitter"])
			plan = {"j0": rng.randi_range(0, j), "j1": rng.randi_range(0, j), "j2": rng.randi_range(0, j), "j3": rng.randi_range(0, j)}


# ====================================================================== Spieler-API (mit Zählung der Ablehnungen)

func _min_jetzt() -> float:
	return ps.sim.tick_count / 600.0


func _cash() -> int:
	return ps.eco.cash_cent


func _abl(grund: String) -> void:
	api_abl[grund] = int(api_abl.get(grund, 0)) + 1


func _lizenz(name: String) -> bool:
	if lic_haben.has(name):
		return true
	api_aufrufe += 1
	var before := _cash()
	var r: Dictionary = ps.lizenz_kaufen(name)
	if r.get("ok", false):
		lic_haben[name] = true
		bot_lic_cent += before - _cash()
		return true
	_abl("lizenz_" + String(r.get("fehler", "?")))
	return false


func _preis_fz(def_id: String) -> int:
	return int(ps.vdef(def_id).get("kauf_cent", 30000))


func _gruppe_key(von: String, nach: String) -> String:
	return von + "|" + nach


func _n_fz(von: String, nach: String) -> int:
	var k := _gruppe_key(von, nach)
	if not gruppen.has(k):
		return 0
	var n := 0
	for vid in gruppen[k]["vids"]:
		if not ps.fahrzeug(vid)["verkauft"]:
			n += 1
	return n


func _fz_aktiv() -> int:
	var n := 0
	for f in ps.fahrzeuge:
		if not f["verkauft"]:
			n += 1
	return n


## Fuhrwerk kaufen auf Linie von -> nach. Gibt true bei Erfolg.
func _kaufe(von: String, nach: String, def_id := "") -> bool:
	api_aufrufe += 1
	var r: Dictionary = ps.linie_anlegen(von, nach, "fuhrwerk", def_id if def_id != "" else FZ)
	if not r.get("ok", false):
		_abl("linie_" + String(r.get("fehler", "?")))
		return false
	var k := _gruppe_key(von, nach)
	if not gruppen.has(k):
		gruppen[k] = {"von": von, "nach": nach, "vids": [], "seit_periode": ps.sim.tick_count / PERIODE, "ertrag": 0}
	gruppen[k]["vids"].append(int(r["vid"]))
	fz_max = maxi(fz_max, _fz_aktiv())
	return true


func _kredit_auf() -> int:
	if int(ps.credit.borrow_amount(ps.sim.tick_count)) <= 0:
		return 0                       # Knopf wäre grau (Sperre/Rahmen voll): kein API-Aufruf, keine Zählung
	api_aufrufe += 1
	var a: int = ps.kredit_aufnehmen()
	if a <= 0:
		_abl("kredit_auf_nein")
	kredit_max = maxi(kredit_max, ps.credit.loan_cent)
	return a


func _kredit_ab() -> int:
	if int(ps.credit.repay_amount(_cash())) <= 0:
		return 0
	api_aufrufe += 1
	var a: int = ps.kredit_tilgen()
	if a <= 0:
		_abl("kredit_ab_nein")
	return a


func _verkaufe(vid: int) -> bool:
	api_aufrufe += 1
	var r: Dictionary = ps.fahrzeug_verkaufen(vid)
	if not r.get("ok", false):
		_abl("verkauf_" + String(r.get("fehler", "?")))
		return false
	rw_total += int(r.get("restwert_cent", 0))
	return true


## FK-02 (Firmenkauf C1) ist in ProtoSim angebunden (s8 de75721): kauf_angebot / firma_kaufen / ausbau_angebot / werk_ausbauen.
## Der Bot nutzt nur diese vier Aufrufe (wie die UI). Kaufbedingung des Bots: Angebot "kaufbar" (Guthaben ohne Kredit >= Preis) UND
## Kasse nach dem Kauf >= Reserve des Spielertyps. Seit FX3 bucht ProtoSim Kauf und Ausbau in kauf_total; fk_total ist nur Anzeige.
func _fk_status_pruefen() -> void:
	fk_status = "angebunden: kauf_angebot/firma_kaufen/ausbau_angebot/werk_ausbauen" if ps.has_method("firma_kaufen") else "API fehlt (kein firma_kaufen)"


func _fk_kaufen(name: String, reserve: int) -> Dictionary:
	fk_versuche += 1
	api_aufrufe += 1
	var q: Dictionary = ps.kauf_angebot(name)
	if not q.get("ok", false):
		fk_grund = String(q.get("fehler", "?"))
		_abl("fk_angebot_" + fk_grund)
		return q
	fk_grund = String(q.get("grund", ""))
	if not bool(q.get("kaufbar", false)):
		return {"ok": false, "fehler": fk_grund}
	var preis: int = int(q["preis_cent"])
	if _cash() - preis < reserve:
		fk_grund = "reserve"
		return {"ok": false, "fehler": "reserve"}
	api_aufrufe += 1
	var r: Dictionary = ps.firma_kaufen(name)
	if r.get("ok", false):
		fk_total += int(r["bezahlt_cent"])
		fk_preis = int(r["bezahlt_cent"])
		fk_kauf_tick = ps.sim.tick_count
		fk_grund = ""
	else:
		fk_grund = String(r.get("fehler", "?"))
		_abl("fk_kauf_" + fk_grund)
	return r


func _fk_ausbauen(name: String, reserve: int) -> Dictionary:
	var q: Dictionary = ps.ausbau_angebot(name)
	if not q.get("ok", false):
		return q
	var kosten: int = int(q["kosten_cent"])
	var frei: int = _cash() - int(ps.credit.loan_cent)
	if frei < kosten or _cash() - kosten < reserve:
		return {"ok": false, "fehler": "reserve"}
	api_aufrufe += 1
	var r: Dictionary = ps.werk_ausbauen(name)
	if r.get("ok", false):
		fk_total += int(r["bezahlt_cent"])
		fk_ausbau_cent = int(r["bezahlt_cent"])
		fk_ausbau_tick = ps.sim.tick_count
	else:
		_abl("fk_ausbau_" + String(r.get("fehler", "?")))
	return r


func _fk_schritt(t: int, reserve: int, ausbau: bool, ausbau_wartezeit_min: float) -> void:
	if fk_kauf_tick < 0:
		_fk_kaufen(MUEHLE, reserve)
	elif ausbau and fk_ausbau_tick < 0 and float(t - fk_kauf_tick) / 600.0 >= ausbau_wartezeit_min:
		_fk_ausbauen(MUEHLE, reserve)


# ---------- Bedarf und Kredit

func _felder(von: String, nach: String) -> float:
	var r: Array = ps.sim.graph.find_path(int(ps.stationen[von]["knoten"]), int(ps.stationen[nach]["knoten"]))
	return ps.sim.graph.route_length(r) / float(ps.sim.feld_mm)


## Umlaufzeit in Ticks: Hin- und Rückfahrt plus 2 x Ladezeit (OE-02-Vorbereitung: 2 x Fahrzeit + 200).
func _umlauf(von: String, nach: String) -> float:
	var prof = ps.profil("fuhrwerk")
	var speed_mm := maxf(1.0, roundf(prof.v_nom * ps.mm_pro_m))
	var r: Array = ps.sim.graph.find_path(int(ps.stationen[von]["knoten"]), int(ps.stationen[nach]["knoten"]))
	return 2.0 * ps.sim.graph.route_length(r) / speed_mm + 200.0


## Fuhrwerke, damit eine Quelle mit rate_e_min E/min abtransportiert wird.
func _bedarf(von: String, nach: String, rate_e_min: float, cap := -1) -> int:
	if cap < 0:
		cap = int(ps.vdef(FZ).get("kapazitaet_einheiten", 10))
	var je_fz_min := float(cap) * 600.0 / _umlauf(von, nach)
	return maxi(1, ceili(rate_e_min / je_fz_min))


## Kasse für eine Ausgabe beschaffen. Kredit nur, wenn borrow_ok. Gibt true, wenn danach cash - cent >= reserve.
func _beschaffe(cent: int, reserve: int, borrow_ok: bool) -> bool:
	if _cash() - cent >= reserve:
		return true
	if not borrow_ok:
		return false
	var guard := 0
	while _cash() - cent < reserve and guard < 6:
		if _kredit_auf() <= 0:
			break
		guard += 1
	return _cash() - cent >= reserve


## Sorgt dafür, dass n Fuhrwerke auf der Linie fahren (soweit bezahlbar). Rückgabe: erreicht.
func _sorge(von: String, nach: String, soll: int, reserve: int, borrow_ok: bool, def_id := "") -> bool:
	var d := def_id if def_id != "" else FZ
	while _n_fz(von, nach) < soll:
		if not _beschaffe(_preis_fz(d), reserve, borrow_ok):
			return false
		if not _kaufe(von, nach, def_id):
			return false
	return true


func _tilge(ueberschuss_cent: int) -> void:
	var guard := 0
	while ps.credit.loan_cent > 0 and _cash() - ps.credit.step_cent >= ueberschuss_cent and guard < 6:
		if _kredit_ab() <= 0:
			break
		guard += 1


## Mehlmenge je Abnehmer (E/min): 10 bei Werksstufe 1 (Mühle 20 E/min), nach Ausbau (40 E/min) die Parameter plan_mehl_*2.
func _mehl_rate(ziel: String) -> float:
	var ms: int = int(ps.stationen[MUEHLE]["site"])
	if int(ps.eco.s_werksstufe[ms]) >= 2:
		return float(PARAM["plan_mehl_dorf2"]) if ziel == DORF else float(PARAM["plan_mehl_stadt2"])
	return 10.0


# ====================================================================== Strategien (ein Entscheidungstakt)

func _takt(t: int) -> void:
	if ps.konto.bankrupt:
		return
	match strat:
		"naiv":
			_takt_naiv(t)
		"normal":
			_takt_normal(t)
		"plan":
			_takt_plan(t)


func _v_letzte(ort: String) -> int:
	var h: Array = v_hist[ort]
	return int(h[-1]) if not h.is_empty() else 0


func _takt_naiv(t: int) -> void:
	var m := t / 600.0
	var kredit_ab_tick: int = ps.credit.from_ticks
	if m < float(naiv["bau"]):
		return
	if not lic_haben.has(FARM1):
		_lizenz(FARM1)
	var farm_ziel := DORF if bool(naiv["fehl"]) else MUEHLE        # Fehlverbindung: Getreide direkt ins Dorf (wird dort nicht angenommen)
	if _n_fz(FARM1, farm_ziel) == 0 and lic_haben.has(FARM1):
		for i in 1 + int(naiv["x_farm"]):
			if _beschaffe(_preis_fz(FZ), 0, false):
				_kaufe(FARM1, farm_ziel)
	if m >= float(naiv["bau"] + naiv["vergessen"]) and not lic_haben.has(MUEHLE):
		_lizenz(MUEHLE)
	var mehl_ziel: String = naiv["mehl_ziel"]
	if _n_fz(MUEHLE, mehl_ziel) == 0:
		for i in 1 + int(naiv["x_mehl"]):
			if _beschaffe(_preis_fz(FZ), 0, false):
				_kaufe(MUEHLE, mehl_ziel)
	# Kredit voll ab Sperre
	if t >= kredit_ab_tick:
		while _kredit_auf() > 0:
			pass
	# Kaufrausch: bis zu 2 Fuhrwerke je Takt auf zufälligen Linien, solange Kasse >= Preis + Rest
	var keys: Array = gruppen.keys()
	if keys.is_empty():
		return
	for i in 2:
		if _fz_aktiv() >= int(naiv["fz_max"]):
			break
		if _cash() - _preis_fz(FZ) < int(naiv["rest"]):
			break
		var g: Dictionary = gruppen[keys[rng.randi_range(0, keys.size() - 1)]]
		_kaufe(g["von"], g["nach"])
	if fk_global and bool(naiv["fk"]) and m >= 10.0:
		_fk_schritt(t, 0, false, 0.0)
	if ps.credit.loan_cent > 0:
		_tilge(300000 + ps.credit.step_cent)


func _takt_normal(t: int) -> void:
	var m := t / 600.0
	var res: int = int(PARAM["normal_reserve"])
	if m < float(normal["bau"]):
		return
	var borrow: bool = t >= int(ps.credit.from_ticks) and _cash() < 50000
	if not lic_haben.has(FARM1):
		_lizenz(FARM1)
	if not lic_haben.has(MUEHLE) and lic_haben.has(FARM1) and _cash() - 14000 >= res:
		_lizenz(MUEHLE)
	if not (lic_haben.has(FARM1) and lic_haben.has(MUEHLE)):
		return
	_sorge(FARM1, MUEHLE, _bedarf(FARM1, MUEHLE, 20.0) + int(normal["x_farm"]), res, false)
	_sorge(MUEHLE, DORF, _bedarf(MUEHLE, DORF, _mehl_rate(DORF)) + int(normal["x_mehl"]), res, borrow)
	var linden := _v_letzte(DORF) >= saett_pm and m >= 3.0 + float(normal["reaktion"])
	linden = linden or m >= 12.0
	if linden and _n_fz(MUEHLE, DORF) > 0:
		_sorge(MUEHLE, STADT, _bedarf(MUEHLE, STADT, _mehl_rate(STADT)) + int(normal["x_mehl"]), res, borrow)
	if fk_global and int(PARAM["normal_fk_min"]) > 0 and m >= float(PARAM["normal_fk_min"]) + float(normal["reaktion"]):
		_fk_schritt(t, res, true, 3.0)
	if ps.credit.loan_cent > 0:
		_tilge(int(PARAM["normal_tilge"]) + ps.credit.step_cent)


func _takt_plan(t: int) -> void:
	var m := t / 600.0
	var res: int = int(PARAM["plan_reserve"])
	var kredit_ok: bool = t >= int(ps.credit.from_ticks)
	var j0: float = float(plan["j0"])
	var j1: float = float(plan["j1"])
	var j2: float = float(plan["j2"])
	var j3: float = float(plan["j3"])
	# Min 0-3: Lizenz Kuppenhof (E-1), Linie Farm -> Mühle (E-2)
	if m >= 0.5 * j0:
		if not lic_haben.has(FARM1):
			_lizenz(FARM1)
		if lic_haben.has(FARM1) and not lic_haben.has(MUEHLE) and _cash() - 14000 >= res:
			_lizenz(MUEHLE)
		if lic_haben.has(FARM1):
			_sorge(FARM1, MUEHLE, _bedarf(FARM1, MUEHLE, 20.0), res, kredit_ok)
	# Min 3-6: Mehl ins Dorf
	if m >= 3.0 + j1 and lic_haben.has(MUEHLE) and _n_fz(FARM1, MUEHLE) > 0:
		_sorge(MUEHLE, DORF, _bedarf(MUEHLE, DORF, _mehl_rate(DORF)), res, kredit_ok)
	# Min 10-14: Dorf gesättigt oder Minute plan_lindenfurt_min -> Lindenfurt anbinden (F1)
	if m >= float(PARAM["plan_lindenfurt_min"]) + j2 or (m >= 6.0 + j2 and _v_letzte(DORF) >= saett_pm):
		if _n_fz(MUEHLE, DORF) > 0:
			_sorge(MUEHLE, STADT, _bedarf(MUEHLE, STADT, _mehl_rate(STADT)), res, kredit_ok)
	# Min 14: Firmenkauf Mühle (FK-02), danach Ausbau; versucht es jeden Takt, bis es geht (Bedingung: kaufbar + Reserve)
	if fk_global and int(PARAM["plan_fk"]) == 1 and m >= float(PARAM["plan_fk_min"]) + j3 and lic_haben.has(MUEHLE):
		_fk_schritt(t, res, int(PARAM["plan_ausbau"]) == 1, 0.0)
	# Min 20: Farm 2 (Lizenz + Linie)
	if int(PARAM["plan_farm2"]) == 1 and m >= float(PARAM["plan_farm2_min"]) + j3 and _n_fz(MUEHLE, DORF) > 0:
		if not lic_haben.has(FARM2) and _cash() - 7000 >= res:
			_lizenz(FARM2)
		if lic_haben.has(FARM2):
			_sorge(FARM2, MUEHLE, _bedarf(FARM2, MUEHLE, 20.0), res, kredit_ok)
	# Folgemodell: ab Freischaltung Frachtwagen die ältesten Fuhrwerke (Alter >= 8 Jahre, Formel FZ-03: +40 % Unterhalt) ersetzen
	if _frachtwagen_frei() and int(PARAM["plan_ersetzen"]) == 1:
		_ersetzen(res, kredit_ok)
	# Tilgen sobald Überschuss (F2 verlangt Kredit = 0)
	if ps.credit.loan_cent > 0:
		_tilge(res + 100000 + ps.credit.step_cent)


func _frachtwagen_frei() -> bool:
	for fs in ps.freischaltungen:
		if String(fs["id"]) == FW:
			return true
	return false


func _ersetzen(res: int, borrow_ok: bool) -> void:
	# FZ-04: ersetzen_angebot / fahrzeug_ersetzen (Linie läuft weiter). Der Plan-Bot ersetzt Fuhrwerke ab 8 Kalenderjahren, wenn das Angebot
	# Unterhalt spart und die Reserve bleibt; höchstens eins je Takt.
	var alt_id := -1
	var best_alter := -1
	for f in ps.fahrzeuge:
		if f["verkauft"] or String(f["def_id"]) != FZ:
			continue
		var alter: int = ps.sim.tick_count - int(f["kauf_tick"])
		if ps.alter_jahre(f) >= 8 and alter > best_alter:
			best_alter = alter
			alt_id = int(f["vid"])
	if alt_id < 0:
		return
	api_aufrufe += 1
	var q: Dictionary = ps.ersetzen_angebot(alt_id, FW)
	if not q.get("ok", false):
		_abl("ersetzen_angebot_" + String(q.get("fehler", "?")))
		return
	if ers_angebot_tick < 0:
		ers_angebot_tick = ps.sim.tick_count
	if int(q["spart_cent_pro_periode"]) <= 0:
		return
	if ers_spart_tick < 0:
		ers_spart_tick = ps.sim.tick_count
	if not _beschaffe(int(q["netto_cent"]), res, borrow_ok):
		return
	api_aufrufe += 1
	var r: Dictionary = ps.fahrzeug_ersetzen(alt_id, FW)
	if not r.get("ok", false):
		_abl("ersetzen_" + String(r.get("fehler", "?")))
		return
	rw_total += int(r["restwert_cent"])
	ersetzt_n += 1
	ersetzt_spart += int(q["spart_cent_pro_periode"])
	if ersetzt_erst < 0:
		ersetzt_erst = ps.sim.tick_count


# ====================================================================== Beobachtung: Ereignisse und Ziele

func _ev(nr: int, tick: int) -> void:
	ev_n[nr] += 1
	if ev_erst[nr] < 0:
		ev_erst[nr] = tick
	evs.append([tick, nr])


func _ziel(id: String, tick: int) -> void:
	if z.has(id):
		return
	z[id] = tick
	if id in ["e1", "e2", "e3", "e4", "e5", "e6_alle", "f1", "f2_op"]:
		_ev(1, tick)          # Ereignis 1: Ziel erfüllt (je Ziel einmal; Doppelvarianten e6_eine/f2_kasse zählen nicht doppelt)


func _beobachten(t: int) -> void:
	var n: int = ps.lieferungen.size()
	while li_idx < n:
		_lieferung(ps.lieferungen[li_idx])
		li_idx += 1
	while fs_idx < ps.freischaltungen.size():
		var fs: Dictionary = ps.freischaltungen[fs_idx]
		fs_idx += 1
		if not ps.vdef(String(fs["id"])).is_empty():
			_ev(8, int(fs["tick"]))            # Ereignis 8: Folgemodell verfügbar
			if ev8_fm_tick < 0:
				ev8_fm_tick = int(fs["tick"])
	if t == ps.credit.from_ticks and ps.credit.active:
		_ev(5, t)
	if t % 50 == 0:
		_alle_50(t)
	if t % PERIODE == PERIODE - 1:
		_periodenende(t)


func _site_name_farm(name: String) -> bool:
	return name == FARM1 or name == FARM2


func _lieferung(L: Dictionary) -> void:
	var f: Dictionary = ps.fahrzeug(int(L["vid"]))
	var von: String = node_name.get(int(f["von"]), "?")
	var nach: String = node_name.get(int(f["nach"]), "?")
	var cent_l: int = int(L["cent"])
	ertrag_p += cent_l
	var k := _gruppe_key(von, nach)
	if gruppen.has(k):
		gruppen[k]["ertrag"] += cent_l
	if L["gut"] == "getreide" and nach == MUEHLE:
		getreide_muehle += int(L["menge"])
		if getreide_muehle >= 1:
			_ziel("e3", int(L["tick"]))
	if L["gut"] == "mehl" and nach == DORF:
		mehl_dorf += int(L["menge"])
		if mehl_dorf >= schwelle_e4:
			_ziel("e4", int(L["tick"]))
	# Ereignis 3 (Ersatzdefinition aus ziele_welt.json, [E]): Ladung bei Ankunft < 500 Promille der Kapazität in 3 Umläufen am Stück
	var vid: int = int(L["vid"])
	var cap: int = int(ps.vdef(String(f["def_id"])).get("kapazitaet_einheiten", 10))
	if int(L["menge"]) * 1000 < 500 * cap:
		low_zaehler[vid] = int(low_zaehler.get(vid, 0)) + 1
		if int(low_zaehler[vid]) >= 3 and not low_aktiv.has(vid):
			low_aktiv[vid] = true
			_ev(3, int(L["tick"]))
	else:
		low_zaehler[vid] = 0
		low_aktiv.erase(vid)


func _alle_50(t: int) -> void:
	# E-1, E-2, E-5 stehen in _ziele_pruefen. Hier: Lizenzablauf (6), Deckel (7), Alter (8), v_lwait (3 spec), Kassentief.
	for nm in [FARM1, FARM2, MUEHLE]:
		var site: int = int(ps.stationen[nm]["site"])
		var rest: int = ps.eco.s_lic_until[site] - t
		if ps.eco.s_lic_until[site] != -1 and rest > 0 and rest <= hinweis_vor_ablauf:
			if not lic_warn.has(nm):
				lic_warn[nm] = true
				_ev(6, t)
		else:
			lic_warn.erase(nm)
	var ms: int = int(ps.stationen[MUEHLE]["site"])
	var gi: int = ps.eco.g_ids.find("getreide")
	var stau: int = int(ps.eco.s_inbuf[ms].get(gi, 0))
	var deckel: bool = ps.eco.inbuf_full(ms) if int(ps.eco.inbuf_cap_perioden) > 0 else stau > 2 * int(ps.eco.s_rate[ms])
	if deckel and not deckel_aktiv:
		_ev(7, t)
	deckel_aktiv = deckel
	for f in ps.fahrzeuge:
		if f["verkauft"]:
			continue
		var vid: int = f["vid"]
		var alter: int = t - int(f["kauf_tick"])
		var d: Dictionary = ps.vdef(String(f["def_id"]))
		var bp: int = int(d.get("alterung_unterhalt_bp_pro_jahr", 0))
		if bp > 0 and ps.kalender.alter_jahre(alter) * bp >= 4000 and not fz_alt_aktiv.has(vid):
			fz_alt_aktiv[vid] = true
			_ev(8, t)                          # Ereignis 8: Unterhalt >= +40 % (FZ-03, im Sim aktiv)
			if ev8_alter_tick < 0:
				ev8_alter_tick = t
		var i: int = ps.sim.slot_of(vid)
		if ps.sim.v_lwait[i] > 600:
			if not e3_spec_aktiv.has(vid):
				e3_spec_aktiv[vid] = true
				e3_spec_n += 1
		else:
			e3_spec_aktiv.erase(vid)
	if t >= 5 * PERIODE and t <= 20 * PERIODE:
		if _cash() < kasse_tief_5_20:
			kasse_tief_5_20 = _cash()
			kasse_tief_tick = t


func _ziele_pruefen(t: int) -> void:
	var s1: int = int(ps.stationen[FARM1]["site"])
	var s2: int = int(ps.stationen[FARM2]["site"])
	if ps.eco.s_lic_until[s1] > t or ps.eco.s_lic_until[s2] > t:
		_ziel("e1", t)
	var n_e2 := _n_fz(FARM1, MUEHLE) + _n_fz(FARM2, MUEHLE)
	if n_e2 >= 1:
		_ziel("e2", t)
	for k in gruppen:
		if _n_fz(gruppen[k]["von"], gruppen[k]["nach"]) >= 2:
			_ziel("e5", t)


## Ende der Periode p = Tick 600p+599: Versorgung, Netto, Liniengewinn, Kassenflanken (Ereignis 4), Ereignis 2.
func _periodenende(t: int) -> void:
	var per: int = t / PERIODE
	var cash: int = _cash()
	# --- Versorgung V (Promille) je Ort
	for ort in [DORF, STADT]:
		var site: int = int(ps.stationen[ort]["site"])
		var v := 0
		if int(ps.eco.s_sat_period[site]) == per:
			v = int(ps.eco.s_sat[site].get("nahrung", 0)) * 1000 / maxi(1, ps.eco.city_demand(site))
		v_hist[ort].append(v)
		if v > saett_pm and int(v_alt[ort]) <= saett_pm:
			_ev(2, t)
		v_alt[ort] = v
	if v_hist[DORF].size() >= 3 and v_hist[STADT].size() >= 3:
		var ok_f1 := true
		for ort in [DORF, STADT]:
			var h: Array = v_hist[ort]
			var summe: int = int(h[-1]) + int(h[-2]) + int(h[-3])
			if summe < 3 * schwelle_f1:
				ok_f1 = false
		if ok_f1:
			_ziel("f1", t + 1)
	# --- Netto je Periode
	var ertrag: int = ps.eco.revenue_total - rev_last
	var fahrk: int = ps.fahrkosten_total - fahrk_last
	var kauf: int = ps.kauf_total - kauf_last      # FX3: kauf_total enthält Firmenkauf und Ausbau
	var zins: int = ps.credit.interest_paid - zins_last
	var fix_zins: int = ps.konto.expenses_total - exp_last - kauf - fahrk
	var fix: int = fix_zins - zins
	var liz_renew: int = (ps.eco.licence_paid_total - lizpaid_last) - (bot_lic_cent - bot_lic_last)
	var n_op: int = ertrag - fahrk - fix - zins - liz_renew
	var n_ka: int = (cash - cash_last) - (ps.credit.loan_cent - loan_last)
	# Abgleich (zwei unabhängige Wege zur Kassenänderung): n_ka = n_op - Käufe - Lizenzkäufe des Bots + Restwerte
	var erw: int = n_op - kauf - (bot_lic_cent - bot_lic_last) + (rw_total - rw_last)
	if mutant == "recon":
		erw += 1
	if erw != n_ka:
		recon_fehler += 1
		recon_text = "Periode %d: Kassendelta %d != erwartet %d (Netto %d, Kauf %d, Bot-Lizenz %d, Restwert %d)" % [per, n_ka, erw, n_op, kauf, bot_lic_cent - bot_lic_last, rw_total - rw_last]
	rw_last = rw_total
	netto_op.append(n_op)
	netto_kasse.append(n_ka)
	serie.append("%s,%d,%d,%d,%d,%d,%d,%d,%d" % [strat, seed_nr, per, n_op, n_ka, cash, ps.credit.loan_cent, ertrag, ps.fahrzeuge.size()])
	rev_last = ps.eco.revenue_total
	fahrk_last = ps.fahrkosten_total
	kauf_last = ps.kauf_total
	zins_last = ps.credit.interest_paid
	exp_last = ps.konto.expenses_total
	lizpaid_last = ps.eco.licence_paid_total
	bot_lic_last = bot_lic_cent
	cash_last = cash
	loan_last = ps.credit.loan_cent
	f2_op_serie = f2_op_serie + 1 if (n_op >= schwelle_f2 and ps.credit.loan_cent == 0) else 0
	f2_kasse_serie = f2_kasse_serie + 1 if (n_ka >= schwelle_f2 and ps.credit.loan_cent == 0) else 0
	if f2_op_serie >= 5:
		_ziel("f2_op", t + 1)
	if f2_kasse_serie >= 5:
		_ziel("f2_kasse", t + 1)
	if per == 29 and netto_op.size() >= 5:        # Periode 29 endet bei Minute 30
		var so := 0
		var sk := 0
		for i in range(netto_op.size() - 5, netto_op.size()):
			so += int(netto_op[i])
			sk += int(netto_kasse[i])
		netto5_op_min30 = so / 5
		netto5_kasse_min30 = sk / 5
	# --- Liniengewinn je Gruppe (nur Gruppen, die die ganze Periode existierten)
	var pos := 0
	var neg := 0
	for k in gruppen:
		var g: Dictionary = gruppen[k]
		var fix_g := 0
		var fahrk_g := 0
		for vid in g["vids"]:
			var f: Dictionary = ps.fahrzeug(vid)
			var i: int = ps.sim.slot_of(vid)
			var fld: int = ps.sim.v_fields[i]
			var dv: int = fld - int(gruppe_vor_fields.get(vid, 0))
			gruppe_vor_fields[vid] = fld
			if f["verkauft"]:
				continue
			fix_g += ps.fix_eff(f)
			fahrk_g += dv * int(ps.vdef(String(f["def_id"])).get("variabel_cent_pro_feld", 0))
		if int(g["seit_periode"]) < per:
			var gew: int = int(g["ertrag"]) - fix_g - fahrk_g
			if gew > 0:
				pos += 1
			elif gew < 0:
				neg += 1
		g["ertrag"] = 0
	e6_serie_eine = e6_serie_eine + 1 if pos > 0 else 0
	e6_serie_alle = e6_serie_alle + 1 if (pos > 0 and neg == 0) else 0
	if e6_serie_eine >= 3:
		_ziel("e6_eine", t + 1)
	if e6_serie_alle >= 3:
		_ziel("e6_alle", t + 1)
	# --- Ereignis 4: Kasse erreicht den Preis einer Kaufart (Flanke von unten, Periodenende)
	var preise := {"fuhrwerk": _preis_fz(FZ)}
	for nm in [FARM1, FARM2, MUEHLE]:
		var site: int = int(ps.stationen[nm]["site"])
		if not ps.eco.licence_valid(site):
			var q: Dictionary = ps.eco.licence_quote(site, false)
			if q.get("ok", false):
				preise["lizenz_" + nm] = int(q["zu_zahlen_cent"])
	for ka in preise:
		var unten: bool = bool(kaufart_unten.get(ka, false))
		if cash >= int(preise[ka]):
			if unten:
				_ev(4, t)
			kaufart_unten[ka] = false
		else:
			kaufart_unten[ka] = true
	# Kaufart C1 (Betrieb kaufen) und Ausbau Werksstufe 2: Guthaben ohne Kredit gegen Preis (FK-02), je Kaufart eine Flanke
	var frei: int = cash - int(ps.credit.loan_cent)
	var qk: Dictionary = ps.kauf_angebot(MUEHLE)
	if qk.get("ok", false) and String(qk.get("grund", "")) != "schon_gekauft":
		_ev4_flanke("firma_" + MUEHLE, frei, int(qk["preis_cent"]), t)
	var qa: Dictionary = ps.ausbau_angebot(MUEHLE)
	if qa.get("ok", false):
		_ev4_flanke("ausbau_" + MUEHLE, frei, int(qa["kosten_cent"]), t)


func _ev4_flanke(ka: String, guthaben: int, preis: int, t: int) -> void:
	var unten: bool = bool(kaufart_unten.get(ka, false))
	if guthaben >= preis:
		if unten:
			_ev(4, t)
		kaufart_unten[ka] = false
	else:
		kaufart_unten[ka] = true


# ====================================================================== Auswertung

static func _pct(sorted_arr: Array, p: float) -> float:
	if sorted_arr.is_empty():
		return -1.0
	var idx := clampi(ceili(p / 100.0 * sorted_arr.size()) - 1, 0, sorted_arr.size() - 1)
	return float(sorted_arr[idx])


static func _wilson(k: int, n: int) -> Array:
	if n <= 0:
		return [0.0, 0.0]
	var zz := 1.96
	var p := float(k) / n
	var den := 1.0 + zz * zz / n
	var mid := (p + zz * zz / (2.0 * n)) / den
	var halb := zz * sqrt(p * (1.0 - p) / n + zz * zz / (4.0 * n * n)) / den
	return [maxf(0.0, mid - halb) * 100.0, minf(1.0, mid + halb) * 100.0]


## Gibt true zurück, wenn ein Sprint-Band verletzt ist (nur für --gate).
func _zusammenfassung(s: String, res: Array, ms: Array) -> bool:
	var n := res.size()
	var bk := 0
	var br_min: Array = []
	var luecken: Array = []
	var ev_summe := PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0])
	var tief: Array = []
	var n5: Array = []
	var fzm: Array = []
	var api_sum: Dictionary = {}
	var luecken_ok := 0
	var luecken3: Array = []
	for r in res:
		luecken3.append(float(r["gmax3"]))
		bk += int(r["bankrott"])
		if int(r["bankrott"]) == 1:
			br_min.append(float(r["bankrott_tick"]) / 600.0)
		luecken.append(float(r["gmax"]))
		if int(r["gmax"]) <= luecke_max_ticks:
			luecken_ok += 1
		for i in range(1, 9):
			ev_summe[i] += int(r["ev_n"][i])
		if int(r["tief"]) >= 0:
			tief.append(float(r["tief"]))
		n5.append(float(r["n5_op"]))
		fzm.append(float(r["fz_max"]))
		for kk in r["api_abl"]:
			api_sum[kk] = int(api_sum.get(kk, 0)) + int(r["api_abl"][kk])
	br_min.sort()
	luecken.sort()
	luecken3.sort()
	tief.sort()
	n5.sort()
	fzm.sort()
	var w: Array = _wilson(bk, n)
	print("== %s (n=%d, tempo_k %d)" % [s, n, ps.tempo_k if ps != null else 0])
	print("  Bankrott: %d/%d = %.1f %% (Wilson 95 %%: %.1f-%.1f %%), Minute P50 %.1f (nur Bankrotte)" % [bk, n, 100.0 * bk / maxi(1, n), w[0], w[1], _pct(br_min, 50)])
	var zeile := "  Ziele (erste Minute; erreicht/n; P25/P50/P75 unter den Erreichern):"
	print(zeile)
	for zid in ["e1", "e2", "e3", "e4", "e5", "e6_alle", "e6_eine", "f1", "f2_op", "f2_kasse"]:
		var arr: Array = []
		for r in res:
			if r["z"].has(zid):
				arr.append(float(r["z"][zid]) / 600.0)
		arr.sort()
		print("    %-8s %3d/%-3d  P25 %5.1f  P50 %5.1f  P75 %5.1f" % [zid, arr.size(), n, _pct(arr, 25), _pct(arr, 50), _pct(arr, 75)])
	print("  Ereignisse je Lauf (Mittel) 1..8: %s; ev3 nach Spec (v_lwait > 600) ungezählt in Lücke" % str(_mittel_ev(ev_summe, n)))
	print("  größte Ereignislücke Min 2-%d: P50 %.1f min, P90 %.1f min, Max %.1f min; Läufe mit Lücke <= %.1f min: %d/%d" % [luecke_bis_min,
		_pct(luecken, 50) / 600.0, _pct(luecken, 90) / 600.0, _pct(luecken, 100) / 600.0, luecke_max_ticks / 600.0, luecken_ok, n])
	print("  größte Lücke OHNE Ereignis 3 (Ersatzdefinition [E], feuert häufig): P50 %.1f min, P90 %.1f min, Max %.1f min" % [_pct(luecken3, 50) / 600.0, _pct(luecken3, 90) / 600.0, _pct(luecken3, 100) / 600.0])
	print("  Kasse Tiefpunkt Min 5-20 (min je Lauf): P50 %.0f $ (W24-Kriterium: P50 < 2.000 $), Fuhrwerke max P50 %.0f" % [_pct(tief, 50) / 100.0, _pct(fzm, 50)])
	print("  Netto operativ 5-Perioden-Mittel Min 30: P50 %.0f $/min (F2-Schwelle %.0f $/min), n_Bankrott zählt als 0 (Wert 0)" % [_pct(n5, 50) / 100.0, schwelle_f2 / 100.0])
	print("  Ablehnungen der Spieler-API (Bot-Aufrufe): %s" % str(api_sum))
	var bad := false
	if s == "naiv":
		bad = (100.0 * bk / maxi(1, n)) < 10.0 or (100.0 * bk / maxi(1, n)) > 30.0
	elif s == "plan":
		bad = (100.0 * bk / maxi(1, n)) > 5.0 or _pct(luecken, 90) > luecke_max_ticks
	print("  Sprint-Band: %s" % ("VERLETZT" if bad else "eingehalten (bei n < 300 nur Info)"))
	return bad


func _mittel_ev(sm: PackedInt32Array, n: int) -> Array:
	var out: Array = []
	for i in range(1, 9):
		out.append(snappedf(float(sm[i]) / maxi(1, n), 0.01))
	return out
