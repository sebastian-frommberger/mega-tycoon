extends SceneTree
## S8 QT-05 (Daniel): Zocker-Session für die WELT (ProtoSim), Gegenstück zu tests/play_session.gd (das steuert nur main.tscn).
##   godot --headless --path . -s res://tests/play_welt.gd -- <commands.txt|ordner> [--out=<ordner>] [--budget=120] [--strikt] [--tempo_k=N]
## Aufruf bequemer: tools/play_welt.sh <commands.txt|ordner> [optionen]
##
## STAND (Gerüst, 05.11.2026): läuft gegen die ProtoSim-API (AT-02/AT-03), NICHT gegen die Welt-UI. Die UI-Befehle (klick, knopf, ...) sind
## als Platzhalter vorhanden und werden mit Hinweis ÜBERSPRUNGEN, solange es keine Welt-UI gibt (AT-07/AT-08, Mira, ungemergt). Mit --strikt
## wird ein übersprungener UI-Befehl zum Fehler (Exit 4). Die UI-Anbindung wird hier NICHT erfunden: Sobald AT-07/08 gemergt sind, kommen
## echte Maus-Wege wie in play_session.gd dazu (Abschnitt `_ui_befehl`).
##
## Befehle (eine Zeile je Befehl, # = Kommentar, Namen mit _ statt Leerzeichen, Umlaute wahlweise ue/oe/ae):
##   API-Ebene (heute testbar)                                  Weg im Spiel (später UI)
##   list                          Stationen, Lizenzpreis, Kasse in state.md
##   kapital <$>                   Startkapital setzen (nur Testwerkzeug, für Fehlerfälle; vor dem ersten Kauf)
##   lizenz <Station>              ps.lizenz_kaufen             Panel → [Lizenz kaufen]
##   linie <von> <nach> [def_id]   ps.linie_anlegen             Linie von hier → Ziel → [Anlegen]
##   kauf <von> <nach> [def_id]    wie linie, erwartet aber eine bestehende Linie (2. Fuhrwerk)   [+ Fuhrwerk]
##   verkauf <vid>                 ps.fahrzeug_verkaufen        Fahrzeugkarte → Verkaufen
##   kredit +|-                    ps.kredit_aufnehmen/tilgen   Kredit-Chip [+]/[-]
##   wait <min>                    Sim-Ticks (600/min), nur hier läuft die Zeit (deterministisch, kein Wanduhr-Einfluss)
##   erwarte <feld><op><wert>      Prüfung; Felder: kasse $, kredit $, fahrzeuge, lieferungen, ertrag $, bankrott 0|1, min, ok 0|1,
##                                 fehler (Code der letzten Ablehnung), betrag $ (letzter Kredit-Schritt), lizenz:<Station> 0|1
##                                 Operatoren: >= <= == != > < =
##   UI-Ebene (noch nicht testbar, AT-07/AT-08): klick <id> · knopf <text> · panel <id> · esc
##
## "Stumm" auf API-Ebene: eine Ablehnung (ok:false) ohne Fehlercode, oder ein Kredit-Aufruf mit Ergebnis 0 ohne Code (die API liefert dort nur
## eine Zahl). Beides wird gezählt und im state.md ausgewiesen; der Text zum Code (fehlertexte.gd, AT-12) ist hier nicht prüfbar.
## Ausgabe im Session-Ordner: state.md, log.md (eine Zeile je Lauf, angehängt). Stdout-Marker: CMD, FEHLER, UEBERSPRUNGEN, ABBRUCH, PLAY_OK.
## Exit: 0 grün · 1 Prüfung/Befehl fehlgeschlagen · 3 Zeitbudget (Default 120 s) überschritten · 4 --strikt und UI-Befehl übersprungen.

const ProtoSim := preload("res://proto/proto_sim.gd")
const SZENE := "res://proto/prototyp_welt.tscn"
const WELT_UI := "res://proto/ui_welt.gd"        # Name aus tech.md §6 ("Die Welt-UI liegt in proto/ui_welt.gd"), Existenz nur geprüft
const UI_BEFEHLE := ["klick", "knopf", "panel", "esc"]

var out_dir := ""
var cmd_pfad := ""
var budget_s := 120.0
var strikt := false
var szene: Node
var ps = null
var orte: Dictionary
var letzte_ok := true
var letzte_fehler := ""
var letzter_betrag := 0
var log_zeilen: Array = []          # [nr, befehl, ergebnis, ms]
var fehler_liste: Array = []
var uebersprungen: Array = []
var stumm := 0                      # Ablehnungen ohne Code
var codes: Dictionary = {}          # Ablehnungscode -> Anzahl
var pruefungen := 0
var ui_vorhanden := false
var linien_kauf: Dictionary = {}    # "von|nach" -> Anzahl Fahrzeuge (für `kauf`)


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	cmd_pfad = a[0] if a.size() > 0 else ""
	for x in a.slice(1):
		if x.begins_with("--out="):
			out_dir = x.substr(6)
		elif x.begins_with("--budget="):
			budget_s = float(x.substr(9))
		elif x == "--strikt":
			strikt = true
	_run.call_deferred()


func _norm(s: String) -> String:
	return s.to_lower().replace("_", " ").replace("ü", "ue").replace("ö", "oe").replace("ä", "ae").replace("ß", "ss").strip_edges()


func _station(token: String) -> String:
	var t := _norm(token)
	for nm in ps.stationen:
		if _norm(nm) == t or _norm(String(ps.stationen[nm].get("ort_id", ""))) == t:
			return nm
	return ""


func _fz_aktiv() -> int:
	var n := 0
	for f in ps.fahrzeuge:
		if not f["verkauft"]:
			n += 1
	return n


func _min() -> float:
	return ps.sim.tick_count / 600.0


func _feld(name: String) -> Variant:
	if name.begins_with("lizenz:"):
		var nm := _station(name.substr(7))
		if nm == "":
			return null
		return 1 if ps.eco.licence_valid(int(ps.stationen[nm]["site"])) else 0
	match name:
		"kasse":
			return ps.eco.cash_cent / 100.0
		"kredit":
			return ps.credit.loan_cent / 100.0
		"fahrzeuge":
			return _fz_aktiv()
		"lieferungen":
			return ps.lieferungen.size()
		"ertrag":
			return ps.eco.revenue_total / 100.0
		"bankrott":
			return 1 if ps.konto.bankrupt else 0
		"min":
			return _min()
		"ok":
			return 1 if letzte_ok else 0
		"fehler":
			return letzte_fehler
		"betrag":
			return letzter_betrag / 100.0
	return null


## Rückgabe "" = bestanden, sonst Fehlertext.
func _erwarte(ausdruck: String) -> String:
	pruefungen += 1
	var ops := [">=", "<=", "==", "!=", ">", "<", "="]
	var op := ""
	var pos := -1
	for o in ops:
		pos = ausdruck.find(o)
		if pos > 0:
			op = o
			break
	if op == "":
		return "Ausdruck ohne Operator: %s" % ausdruck
	var feld := ausdruck.substr(0, pos).strip_edges()
	var soll := ausdruck.substr(pos + op.length()).strip_edges()
	var ist: Variant = _feld(feld)
	if ist == null:
		return "unbekanntes Feld oder Station: %s" % feld
	var ok := false
	if ist is String:
		ok = (String(ist) == soll) if op in ["==", "="] else (String(ist) != soll if op == "!=" else false)
	else:
		var v := float(ist)
		var w := float(soll)
		match op:
			">=":
				ok = v >= w
			"<=":
				ok = v <= w
			"==", "=":
				ok = is_equal_approx(v, w)
			"!=":
				ok = not is_equal_approx(v, w)
			">":
				ok = v > w
			"<":
				ok = v < w
	return "" if ok else "erwartet %s, ist %s" % [ausdruck, str(ist)]


func _ablehnung(r: Dictionary) -> String:
	var code := String(r.get("fehler", ""))
	if code == "":
		stumm += 1
		code = "STUMM"
	codes[code] = int(codes.get(code, 0)) + 1
	return code


func _ui_befehl(op: String, args: PackedStringArray) -> String:
	# Platzhalter: keine UI, keine Erfindung. Mit AT-07/AT-08 hier echte Maus-Wege wie play_session.gd (warp_mouse + push_input).
	uebersprungen.append("%s %s" % [op, " ".join(args)])
	print("UEBERSPRUNGEN `%s %s` (Welt-UI fehlt: AT-07/AT-08)" % [op, " ".join(args)])
	return "ÜBERSPRUNGEN (Welt-UI fehlt, AT-07/08)"


## Führt einen Befehl aus. Rückgabe: [Ergebnistext, Fehlertext]; Fehlertext "" = ok.
func _cmd(zeile: String) -> Array:
	var teile: PackedStringArray = zeile.split(" ", false)
	var op: String = teile[0]
	var args: PackedStringArray = teile.slice(1)
	if op != "erwarte":                # erwarte liest das Ergebnis des letzten Befehls, setzt es nicht zurück
		letzte_ok = true
		letzte_fehler = ""
	match op:
		"list":
			var s := ""
			for nm in ps.stationen:
				var st: Dictionary = ps.stationen[nm]
				var q: Dictionary = ps.eco.licence_quote(int(st["site"]), false) if int(st["site"]) >= 0 else {}
				s += "%s (Site %d, Knoten %d)%s; " % [nm, int(st["site"]), int(st["knoten"]), (" Lizenz %d ¢%s" % [int(q.get("zu_zahlen_cent", 0)), " gratis" if q.get("gratis", false) else ""]) if q.get("ok", false) else ""]
			return ["Kasse %d ¢; %s" % [ps.eco.cash_cent, s], ""]
		"kapital":
			if args.size() < 1 or not ps.fahrzeuge.is_empty():
				return ["", "kapital <$> nur vor dem ersten Kauf"]
			ps.eco.cash_cent = int(args[0]) * 100
			return ["Kasse %d ¢ (Testwerkzeug)" % ps.eco.cash_cent, ""]
		"lizenz":
			if args.size() < 1:
				return ["", "lizenz <Station>"]
			var nm := _station(args[0])
			if nm == "":
				return ["", "Station unbekannt: %s" % args[0]]
			var r: Dictionary = ps.lizenz_kaufen(nm)
			if r.get("ok", false):
				return ["Lizenz %s: bezahlt %d ¢, bis Tick %d, Kasse %d ¢" % [nm, int(r["bezahlt_cent"]), int(r["gueltig_bis_tick"]), ps.eco.cash_cent], ""]
			letzte_ok = false
			letzte_fehler = _ablehnung(r)
			return ["abgelehnt: %s" % letzte_fehler, ""]
		"linie", "kauf":
			if args.size() < 2:
				return ["", "%s <von> <nach> [def_id]" % op]
			var von := _station(args[0])
			var nach := _station(args[1])
			if von == "" or nach == "":
				# unbekannte Namen gehen an die API (Ablehnung "unbekannter_ort" ist selbst ein Testfall)
				var r0: Dictionary = ps.linie_anlegen(args[0].replace("_", " "), args[1].replace("_", " "))
				letzte_ok = bool(r0.get("ok", false))
				if not letzte_ok:
					letzte_fehler = _ablehnung(r0)
				return ["abgelehnt: %s" % letzte_fehler if not letzte_ok else "UNERWARTET angenommen", ""]
			var key := von + "|" + nach
			if op == "kauf" and not linien_kauf.has(key):
				return ["", "kauf: Linie %s → %s existiert noch nicht (erst `linie`)" % [von, nach]]
			var d := args[2] if args.size() > 2 else ""
			var r: Dictionary = ps.linie_anlegen(von, nach, "fuhrwerk", d)
			if r.get("ok", false):
				linien_kauf[key] = int(linien_kauf.get(key, 0)) + 1
				return ["Fuhrwerk %d auf %s → %s, Preis %d ¢, Kasse %d ¢" % [int(r["vid"]), von, nach, int(r["preis_cent"]), ps.eco.cash_cent], ""]
			letzte_ok = false
			letzte_fehler = _ablehnung(r)
			return ["abgelehnt: %s" % letzte_fehler, ""]
		"verkauf":
			if args.size() < 1:
				return ["", "verkauf <vid>"]
			var r: Dictionary = ps.fahrzeug_verkaufen(int(args[0]))
			if r.get("ok", false):
				return ["verkauft, Restwert %d ¢" % int(r["restwert_cent"]), ""]
			letzte_ok = false
			letzte_fehler = _ablehnung(r)
			return ["abgelehnt: %s" % letzte_fehler, ""]
		"kredit":
			if args.size() < 1 or not args[0] in ["+", "-"]:
				return ["", "kredit +|-"]
			var a: int = ps.kredit_aufnehmen() if args[0] == "+" else ps.kredit_tilgen()
			letzter_betrag = a
			if a <= 0:
				letzte_ok = false
				letzte_fehler = "STUMM"
				stumm += 1
				codes["STUMM"] = int(codes.get("STUMM", 0)) + 1
				return ["kein Betrag (API liefert 0 ohne Grund; Sperre/Rahmen/Kasse prüft die UI selbst)", ""]
			return ["Kredit %s %d ¢, offen %d ¢" % ["+" if args[0] == "+" else "-", a, ps.credit.loan_cent], ""]
		"wait":
			if args.size() < 1:
				return ["", "wait <min>"]
			var n := roundi(float(args[0]) * 600.0)
			var t0: int = ps.sim.tick_count
			for i in n:
				if ps.konto.bankrupt:
					break
				ps.tick()
			return ["%d Ticks (%.2f min) → Tick %d (%s), Kasse %d ¢, Lieferungen %d%s" % [ps.sim.tick_count - t0, (ps.sim.tick_count - t0) / 600.0, ps.sim.tick_count, ps.kalender.datum_text(ps.sim.tick_count), ps.eco.cash_cent, ps.lieferungen.size(), " · BANKROTT" if ps.konto.bankrupt else ""], ""]
		"erwarte":
			var f := _erwarte(" ".join(args))
			return ["bestanden" if f == "" else "", f]
	if op in UI_BEFEHLE:
		return [_ui_befehl(op, args), ""]
	return ["", "unbekannter Befehl `%s`" % op]


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	var cmds: Array = []
	var pfad := cmd_pfad
	if pfad == "":
		print("FEHLER Aufruf: -- <commands.txt|ordner> [--out=<ordner>] [--budget=120] [--strikt]")
		quit(2)
		return
	if DirAccess.dir_exists_absolute(pfad):
		if out_dir == "":
			out_dir = pfad
		pfad = pfad.path_join("commands.txt")
	elif out_dir == "":
		out_dir = "/tmp/claude-0/play_welt/" + pfad.get_file().get_basename()
	DirAccess.make_dir_recursive_absolute(out_dir)
	var f := FileAccess.open(pfad, FileAccess.READ)
	if f == null:
		print("FEHLER Befehlsdatei nicht lesbar: ", pfad)
		quit(2)
		return
	for raw in f.get_as_text().split("\n"):
		var s := raw.split("#")[0].strip_edges()
		if s != "":
			cmds.append(s)
	f.close()
	ui_vorhanden = ResourceLoader.exists(WELT_UI)
	szene = (load(SZENE) as PackedScene).instantiate()
	szene.set("sim_aus", true)
	root.add_child(szene)
	await process_frame
	orte = JSON.parse_string(FileAccess.get_file_as_string(szene.datei("proto_orte.json")))
	ps = ProtoSim.new(szene.regelwerk)
	ps.graph_bauen(szene.strassen)
	if not ps.spiel_starten(orte):
		print("FEHLER spiel_starten: ", str(ps.fehler))
		quit(1)
		return
	print("START %d ms, %d Befehle, Welt-UI %s" % [Time.get_ticks_msec() - t0, cmds.size(), "vorhanden (Anbindung fehlt)" if ui_vorhanden else "fehlt"])
	var aborted := ""
	var gespielt := 0
	for i in cmds.size():
		if budget_s > 0.0 and (Time.get_ticks_msec() - t0) / 1000.0 > budget_s:
			aborted = "Zeitbudget %.0f s erreicht nach %d von %d Befehlen" % [budget_s, i, cmds.size()]
			print("ABBRUCH ", aborted)
			break
		gespielt += 1
		var tc := Time.get_ticks_msec()
		var r: Array = _cmd(cmds[i])
		var ms := Time.get_ticks_msec() - tc
		log_zeilen.append([i + 1, cmds[i], r[0] if r[1] == "" else "FEHLER: " + String(r[1]), ms])
		print("CMD %d `%s` %d ms: %s" % [i + 1, cmds[i], ms, r[0] if r[1] == "" else "FEHLER " + String(r[1])])
		if r[1] != "":
			fehler_liste.append("Zeile %d `%s`: %s" % [i + 1, cmds[i], r[1]])
			print("FEHLER ", fehler_liste[-1])
	var run_s := (Time.get_ticks_msec() - t0) / 1000.0
	_state_schreiben(cmds, gespielt, run_s, aborted)
	var ex := 0
	if not fehler_liste.is_empty():
		ex = 1
	elif aborted != "":
		ex = 3
	elif strikt and not uebersprungen.is_empty():
		ex = 4
	if ex == 0:
		print("PLAY_OK %d Befehle, %d Prüfungen, %d übersprungen (UI), %d stumme Ablehnungen, %.1f s, Prüfsumme %d" % [gespielt, pruefungen, uebersprungen.size(), stumm, run_s, ps.pruefsumme()])
	else:
		print("PLAY_FAIL Exit %d, %d Fehler, %.1f s" % [ex, fehler_liste.size(), run_s])
	quit(ex)


func _state_schreiben(cmds: Array, gespielt: int, run_s: float, aborted: String) -> void:
	var md := "# play_welt state (%s)\n\n" % cmd_pfad.get_file()
	md += "- Spielzeit: Tick %d = Minute %.2f (%s), tempo_k %d\n" % [ps.sim.tick_count, _min(), ps.kalender.datum_text(ps.sim.tick_count), ps.tempo_k]
	md += "- Kasse %.2f $, Kredit %.2f $, Ertrag gesamt %.2f $, Bankrott: %s\n" % [ps.eco.cash_cent / 100.0, ps.credit.loan_cent / 100.0, ps.eco.revenue_total / 100.0, "ja (Tick %d)" % ps.bankrott_tick if ps.konto.bankrupt else "nein"]
	md += "- Fahrzeuge aktiv %d, Lieferungen %d, Prüfsumme %d\n" % [_fz_aktiv(), ps.lieferungen.size(), ps.pruefsumme()]
	md += "- Befehle gespielt %d von %d, Prüfungen %d, Laufzeit %.1f s (Budget %.0f s)\n" % [gespielt, cmds.size(), pruefungen, run_s, budget_s]
	md += "- Welt-UI: %s; übersprungene UI-Befehle: %d\n" % ["Datei vorhanden, Anbindung fehlt" if ui_vorhanden else "fehlt (AT-07/AT-08)", uebersprungen.size()]
	md += "- Ablehnungen nach Code: %s; stumm (ohne Code): %d\n" % [str(codes), stumm]
	if aborted != "":
		md += "- **ABBRUCH**: %s\n" % aborted
	md += "\n## Befehle\n| # | Befehl | Ergebnis | ms |\n|---|---|---|---|\n"
	for l in log_zeilen:
		md += "| %d | `%s` | %s | %d |\n" % [l[0], l[1], String(l[2]).replace("|", "/"), l[3]]
	md += "\n## Linien (Fahrzeuge)\n"
	for fz in ps.fahrzeuge:
		md += "- %s (vid %d): %s%s\n" % [fz["name"], fz["vid"], ps.zustand_text(fz), " · verkauft" if fz["verkauft"] else ""]
	if not fehler_liste.is_empty():
		md += "\n## Fehler\n" + "\n".join(fehler_liste.map(func(e): return "- " + e)) + "\n"
	if not uebersprungen.is_empty():
		md += "\n## Übersprungen (UI)\n" + "\n".join(uebersprungen.map(func(e): return "- " + e)) + "\n"
	var sf := FileAccess.open(out_dir.path_join("state.md"), FileAccess.WRITE)
	sf.store_string(md)
	sf.close()
	var lp := out_dir.path_join("log.md")
	var lf: FileAccess
	if FileAccess.file_exists(lp):
		lf = FileAccess.open(lp, FileAccess.READ_WRITE)
		lf.seek_end()
	else:
		lf = FileAccess.open(lp, FileAccess.WRITE)
		lf.store_line("| Befehle | Minute | Kasse | Fahrzeuge | Prüfungen | übersprungen | stumm | Fehler |")
		lf.store_line("|---|---|---|---|---|---|---|---|")
	lf.store_line("| %d | %.2f | %.2f $ | %d | %d | %d | %d | %s |" % [gespielt, _min(), ps.eco.cash_cent / 100.0, _fz_aktiv(), pruefungen, uebersprungen.size(), stumm, ("ABBRUCH; " if aborted != "" else "") + (str(fehler_liste.size()) if not fehler_liste.is_empty() else "–")])
	lf.close()
