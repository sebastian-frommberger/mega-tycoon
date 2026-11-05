extends CanvasLayer
## S8 AT-07 (Mira): Welt-Panel der Prototyp-Welt. Klick auf Farm, Mühle oder Ort öffnet rechts ein Panel (W2, AT-14):
## Bestand, Bedarf, Sättigung, Lizenz kaufen, „Linie von hier“, am HQ der Eintrag „Fuhrhalterei“ (ohne Sim-Funktion).
## Alles in Code, kein Modal (D21). Zahlen kommen nur aus proto_sim/economy (Lesesicht, keine Schreibzugriffe außer über
## die Spieler-API von proto_sim.gd). Jede angezeigte Zahl steht zusätzlich in `panel_werte` (Cent bzw. Einheiten), damit
## Tests sie gegen den Spielwert prüfen können.
##
## Einbau: prototyp_welt.gd legt den Knoten nach dem HUD an (`UiWelt.new()`, `einbauen(welt)`), leitet Klicks
## (Loslassen ohne Ziehen) an `welt_klick(pos)` und Esc an `eingabe(ev)` weiter.
## Fehlertexte: vorläufig hier in FT_WELT (Quelle AT-14, Ursache + Lösung, ≤ 90 Zeichen). Ziel ist ui/fehlertexte.gd
## (Aylin, AT-12). Platzhalter benannt: "{name}".format({...}).

const Economy := preload("res://economy.gd")
const Statistik := preload("res://proto/ui_welt_statistik.gd")   # AT-10
const ToastQueue := preload("res://ui/toast_queue.gd")            # AT-11

const PANEL_B := 360.0
const VORSCHAU_B := 640.0
const LINIEN_B := 430.0
const MITTE_VERSATZ := 50.0            # Vorschau/Modusleiste: Mitte der freien Fläche (links Linienliste, rechts Panel)
const KLICK_RADIUS_PX := 44.0
const TOAST_S := 6.0
const C_TEXT := Color(0.96, 0.92, 0.84)
const C_GRAU := Color(0.62, 0.58, 0.52)
const C_OK := Color("#48E08A")
const C_WARN := Color("#FFA640")
const C_BAD := Color("#FF988A")

## Vorläufige Fehler- und Meldungstexte (AT-14 S1/S3, Wortlaut übernommen). Gehören nach ui/fehlertexte.gd (Aylin).
const FT_WELT := {
	"lizenz_ok": "Lizenz für {name} gekauft, sie gilt {t} min. Jetzt: Linie von hier anlegen.",
	"lizenz_geld_vor12": "Lizenz kostet {x}, es fehlen {d}. Kredit gibt es erst ab Minute 12.",
	"lizenz_geld_ab12": "Lizenz kostet {x}, es fehlen {d}. Nimm Kredit oder warte auf Einnahmen.",
	"lizenz_schon": "{name} ist schon lizenziert, noch {t} min.",
	"lizenz_nicht_noetig": "{name} braucht keine Lizenz. Lege direkt eine Linie dorthin.",
	"lizenz_sonst": "Lizenz gerade nicht möglich. Bitte erneut klicken (Meldung an uns: {code}).",
	"bankrott": "Du bist bankrott, Käufe gehen nicht mehr. Starte neu über das Menü (Esc).",
	"fuhrhalterei": "Unterhalt enthält Futter, Knecht, Stellmacher.",
	"postkutsche": "Postkutschen fahren nur als Kulisse. Passagiere kommen in einer späteren Version.",
	# AT-08 (AT-14 S2/S3)
	"modus": "Linie von {name}: klicke das Ziel. Esc bricht ab.",
	"linie_ok": "Linie {a} → {b} läuft. Fuhrwerk {n} ist unterwegs.",
	"fuhrwerk_ok": "Fuhrwerk {n} gekauft: −{p}, Unterhalt +{u}/min. Linie bringt jetzt ca. {z}/min.",
	"keine_verbindung": "Zwischen {a} und {b} gibt es keine Straße. Wähle ein Ziel am bestehenden Netz.",
	"liefert_nichts": "{name} liefert nichts. Starte die Linie bei Farm, Mühle oder Lager.",
	"keine_lizenz": "{name} hat keine Lizenz. Kaufe sie im Panel (Klick auf das Gebäude).",
	"nimmt_nicht": "{ziel} nimmt {ware} nicht an. Wähle einen Abnehmer, der sie braucht.",
	"fuhrwerk_geld": "Fuhrwerk kostet {x}, es fehlen {d}. Nimm Kredit oder warte auf Einnahmen.",
	# AT-09 (AT-14 S4)
	"kredit_ab12": "Kredit gibt es ab Minute 12. Bis dahin: Einnahmen abwarten.",
	"kredit_voll": "Kreditrahmen {x} ist voll. Tilge Schulden oder warte auf Einnahmen.",
	"kredit_ok": "Kredit {x} aufgenommen. Zins {z}/min, Rahmen noch {r}.",
	"tilgen_geld": "Zum Tilgen fehlen {x} in der Kasse. Warte auf Einnahmen.",
	"tilgen_ok": "Kredit {x} getilgt, offen noch {r}.",
	"kein_kredit": "Du hast keinen Kredit offen. Tilgen ist nicht nötig.",
	# FK-03 (AT-14 S6)
	"kauf_ok": "{name} gehört dir. Werksmarge +{m} %, Unterhalt {u}/min.{aus}",
	"kauf_ok_ausbau": " Ausbau auf {d} E/min: {x}.",
	"kauf_geld": "Kauf kostet {x}, es fehlen {d}. Gekauft wird nur aus der Kasse, nicht mit Kredit.",
	"kauf_kredit": "Kreditgeld kauft keine Firma: ohne Kredit fehlen dir {d}. Warte auf Einnahmen.",
	"kauf_nicht": "{name} steht nicht zum Verkauf. Kaufbar sind Farmen und die Mühle.",
	"kauf_minus": "Die Kasse ist im Minus. Eine Firma kaufst du erst wieder ab 0 $.",
	"kauf_schon": "{name} gehört dir schon. Baue das Werk aus, wenn es geht.",
	"kauf_sonst": "Kauf gerade nicht möglich. Bitte erneut klicken (Meldung an uns: {code}).",
	"ausbau_ok": "{name} verarbeitet jetzt {d} E/min. Liefere mehr Getreide.",
	"ausbau_geld": "Ausbau kostet {x}, es fehlen {d}. Warte auf Einnahmen.",
	"ausbau_kredit": "Kreditgeld zahlt keinen Ausbau: ohne Kredit fehlen dir {d}. Warte auf Einnahmen.",
	"ausbau_vor_kauf": "Ausbauen geht erst nach dem Kauf. Kaufe zuerst {name}.",
	"ausbau_max": "{name} hat schon die höchste Werksstufe dieser Version.",
	"ausbau_roh": "{name} ist ein Rohstoffbetrieb. Ausbauen geht in dieser Version nur bei der Mühle.",
	# FZ-04 (AT-14 S5)
	"ersetzt": "{n} ersetzt: −{x} nach Restwert. Unterhalt jetzt {y}/min statt {z}/min.",
	"ersetzen_geld": "Ersetzen kostet {x}, es fehlen {d}. Warte auf Einnahmen oder nimm Kredit.",
	"ersetzen_nichts": "Ersetzen spart hier nichts ({z}/min). Behalte das Fuhrwerk.",
	"ladung_zu_gross": "{n} hat mehr geladen, als der neue Wagen fasst. Ersetze nach dem Abladen.",
	"verkauft": "{n} verkauft: +{r} Restwert. Die Linie hat noch {k} Fuhrwerk(e).",
	"fz_sonst": "Das geht gerade nicht. Bitte erneut klicken (Meldung an uns: {code}).",
	# AT-11 A-08-Diagnosen (AT-14 S4/S7), Titel = Ort/Linie, Text ≤ 90, eine Aktion
	"d_wartet": "Fuhrwerk {n} wartet {t} s auf Ladung. Zu viele Fuhrwerke für {x} E/min.",
	"d_halb": "Fuhrwerk {n} fährt nur halb voll ab. Zu viele Fuhrwerke für {x} E/min.",
	"d_lizenz_ab": "Lizenz abgelaufen, die Fuhrwerke warten. Erneuern kostet {x}.",
	"d_lizenz_ende": "Die Lizenz endet in {t} min. Verlängern kostet {x}, sonst stehen die Fuhrwerke.",
	"d_gelb": "{ort} nimmt bald kein {ware} mehr ab ({p} %). Plane einen zweiten Abnehmer.",
	"d_rot": "{ort} ist mit {ware} gesättigt ({p} %). Ein zweiter Abnehmer bringt +{x}/min.",
	"d_verlust": "Verlust {x}/min (Fix {a}, Ertrag {b}). Kürzer fahren oder Fuhrwerk abziehen.",
	"d_alt": "{j} Jahre alt: Unterhalt +{p} %. Ersetzen spart {z}/min.",
	"d_kasse_vor12": "Größter Verlust: {posten} (−{x}/min). Löse die Linie auf.",
	"d_kasse_kredit": "Größter Verlust: {posten}. Nimm Kredit oder löse die Linie auf.",
	"d_kasse_voll": "Der Kredit ist voll. Löse {posten} auf oder verkaufe ein Fuhrwerk.",
	"d_kasse_gut": "Kasse reicht wieder. Behalte {posten} im Auge.",
	"liefert_wenig": "{name} liefert nur {x} E/min. Ein weiteres Fuhrwerk bringt kaum mehr.",
	"lizenz_linie_ok": "Lizenz {name} gekauft. Linie nach {b} läuft, Fuhrwerk {n} ist unterwegs.",
	"lizenz_linie_geld": "Lizenz und Fuhrwerk kosten {x}, es fehlen {d}. Nimm Kredit oder warte.",
	"gibt_es_schon": "Diese Linie gibt es schon. Füge ihr ein Fuhrwerk hinzu (+ Fuhrwerk).",
	"ins_leere": "Klicke ein Gebäude an: erst die Quelle, dann das Ziel.",
	"gleich": "Start und Ziel sind gleich. Wähle ein anderes Ziel.",
	"frachtwagen_1830": "Frachtwagen gibt es erst ab 1830. Bis dahin kaufst du das Fuhrwerk.",
	"linie_sonst": "Linie gerade nicht möglich. Bitte erneut klicken (Meldung an uns: {code}).",
}

var welt: Node = null                # prototyp_welt.gd
var ps = null                        # proto_sim.gd
var auswahl := ""                    # Stationsname des offenen Panels, "" = zu
var panel: PanelContainer
var panel_vb: VBoxContainer
var toast_panel                      # AT-11: ui/toast_queue.gd (PanelContainer)
var meldungen_log: Array = []        # [{t_ms, text}] alle gezeigten Meldungen (Test: nie stumm)
var panel_werte: Dictionary = {}     # zuletzt angezeigte Zahlen (Test gegen Spielwert)
var knoepfe: Dictionary = {}         # Name -> Button im offenen Panel (Tests, play_welt)
var klicks := 0                      # gezählte Spielerklicks (Welt + Knöpfe), Messgröße AT-08
var orte_pos: Dictionary = {}        # Stationsname -> Vector3 (m, Gelände)
var _refresh_t := 0.0
var _taste_unten := false            # linke Maustaste gehalten (Neuaufbau des Panels würde den Klick verschlucken)
var _kauf_bestaetigen := ""         # FK-03: Station mit offener Kaufbestätigung (inline, kein Modal)
var _ausbau_bestaetigen := ""        # FK-03: Station mit offener Ausbaubestätigung
var _bereiche: Dictionary = {}       # "panel" | "vorschau" | "modus" -> Knopf-IDs
# AT-08: Linienbau
var modus_von := ""                  # Quelle im Modus „Linie von hier“, "" = kein Modus
var vorschau_ziel := ""              # Ziel der offenen Vorschau, "" = keine
var vorschau_werte: Dictionary = {}  # Zahlen der Vorschau (Test gegen Spielwert)
var modus_panel: PanelContainer
var modus_hb: HBoxContainer
var vorschau_panel: PanelContainer
var vorschau_vb: VBoxContainer
# AT-09: Kopfleiste
var kopf: PanelContainer
var kopf_hb: HBoxContainer
var lbl_kasse: Label
var lbl_netto: Label
var lbl_fix: Label
var lbl_kredit: Label
var lbl_k: Label
var hud_werte: Dictionary = {}       # angezeigte HUD-Zahlen (Test gegen Spielwert)
var statistik = null                # AT-10: proto/ui_welt_statistik.gd
var links_vb: VBoxContainer          # AT-10/13: linke Spalte unten (Ziele, Linien)
var linien_panel: PanelContainer
var linien_vb: VBoxContainer
var linien_werte: Dictionary = {}    # "von|nach" -> angezeigte Zahlen (Test gegen Spielwert)
var _schnapp: Array = []             # Schnappschüsse an den letzten zwei Periodengrenzen


func einbauen(p_welt: Node) -> void:
	welt = p_welt
	ps = welt.proto_sim
	name = "UiWelt"
	layer = 2
	welt.add_child(self)
	_orte_lesen()
	_baue_panel()
	_baue_toast()
	_baue_linienbau()
	_baue_kopfleiste()
	statistik = Statistik.new(ps)
	_baue_links()


func _orte_lesen() -> void:
	orte_pos.clear()
	var oj: Dictionary = welt.orte_json
	for ind in oj.get("industrie", []):
		var nm := String(ind.get("name", ""))
		orte_pos[nm] = Vector3(float(ind["x"]), welt.hoehe_at(float(ind["x"]), float(ind["z"])), float(ind["z"]))
	for o in oj.get("orte", []):
		var nm := String(o.get("name", ""))
		orte_pos[nm] = Vector3(float(o["x"]), welt.hoehe_at(float(o["x"]), float(o["z"])), float(o["z"]))


func _sim_ok() -> bool:
	return ps != null and ps.eco != null


# ------------------------------------------------------------------ Format

## Cent → "6.000 $" (ganze Dollar, Tausenderpunkt). Negative Beträge mit Minus und aufgerundet (nie "0 $" bei Schulden).
static func geld(cent: int) -> String:
	if cent < 0:
		return "-" + _tsd(int(ceil(-cent / 100.0))) + " $"
	return _tsd(roundi(cent / 100.0)) + " $"


## Fehlbetrag: immer aufgerundet, damit nie "es fehlen 0 $" dasteht.
static func fehlbetrag(cent: int) -> String:
	return _tsd(int(ceil(maxi(0, cent) / 100.0))) + " $"


static func _tsd(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


static func text(key: String, werte: Dictionary = {}) -> String:
	return String(FT_WELT.get(key, key)).format(werte)


# ------------------------------------------------------------------ Lesesicht (Spielwerte)

func site_of(nm: String) -> int:
	if not _sim_ok() or not ps.stationen.has(nm):
		return -1
	return int(ps.stationen[nm]["site"])


func ist_industrie(site: int) -> bool:
	return site >= 0 and ps.eco.s_kind[site] == Economy.K_INDUSTRIE


func ist_ort(site: int) -> bool:
	return site >= 0 and ps.eco.s_kind[site] == Economy.K_STADT


func periode() -> int:
	return int(ps.eco.periode_ticks)


## Bestand am Lager-Slot der Site, Rohstoffquellen ohne Schreibzugriff auf den Tick nachgerechnet
## (gleiche Formel wie economy._sync_raw: floor(n × Rate × oeko_tick / periode) − bereits gelegt).
func bestand(site: int) -> int:
	var e = ps.eco
	var k: int = e.s_station[site]
	var st: int = ps.sim.st_stock[k]
	if e.s_raw[site] == 1:
		var n: int = ps.sim.tick_count / e.oeko_tick_ticks - e.s_born[site]
		st += maxi(0, n * e.s_rate[site] * e.oeko_tick_ticks / e.periode_ticks - e.s_made[site])
	return st


## Gut-ID (String) des Ausgangsguts oder "".
func ausgang(site: int) -> String:
	var g: int = ps.eco.s_out_good[site]
	return String(ps.eco.g_ids[g]) if g >= 0 else ""


## Warengruppen (kategorie_id), die der Ort annimmt.
func ort_korb(site: int) -> Array:
	return ps.eco.basket.get(ps.eco.s_stage[site], [])


## Geliefert in der laufenden Periode (Spielminute) je Warengruppe.
func ort_geliefert(site: int, kat: String) -> int:
	var e = ps.eco
	if e.s_sat_period[site] != ps.sim.tick_count / e.periode_ticks:
		return 0
	return int(e.s_sat[site].get(kat, 0))


## Sättigung in Prozent (geliefert ÷ Bedarf der laufenden Minute), ganzzahlig gerundet.
func ort_saettigung_pct(site: int, kat: String) -> int:
	var dem: int = maxi(1, ps.eco.city_demand(site))
	return Economy.rdiv(ort_geliefert(site, kat) * 100, dem)


## Darf die Quelle laden? Lizenz gültig oder Werk im Besitz (FK-02: Besitz ersetzt die Lizenz).
func lizenz_ok(site: int) -> bool:
	return ps.eco.licence_valid(site) or eigen(site)


func eigen(site: int) -> bool:
	return site >= 0 and int(ps.eco.s_owner[site]) == Economy.OWNER_SPIELER


func lizenz_rest_min(site: int) -> int:
	var rest: int = ps.eco.s_lic_until[site] - ps.sim.tick_count
	return maxi(0, int(ceil(rest / float(periode()))))


func ist_hq(site: int) -> bool:
	var e = ps.eco
	return e.company_started and e.s_x[site] == e.hq_x and e.s_y[site] == e.hq_y


## Mögliche Abnehmer des Ausgangsguts: [{name, site, felder, m}] nach Entfernung.
func abnehmer(site: int) -> Array:
	var g: int = ps.eco.s_out_good[site]
	var out: Array = []
	if g < 0:
		return out
	for nm in ps.stationen:
		var t := int(ps.stationen[nm]["site"])
		if t < 0 or t == site or not nimmt_an(t, g):
			continue
		var f: int = ps.eco.luftlinie_felder(site, t)
		out.append({"name": nm, "site": t, "felder": f, "m": roundi(f * ps.eco.feld_mm / ps.mm_pro_m)})
	out.sort_custom(func(a, b): return a["felder"] < b["felder"])
	return out


func nimmt_an(site: int, g: int) -> bool:
	if ist_industrie(site):
		return ps.eco.s_inbuf[site].has(g)
	if ist_ort(site):
		return ps.eco.city_accepts(site, g)
	return false


func fuhrwerk_def() -> Dictionary:
	return ps.vdef(ps.def_fuer("fuhrwerk"))


# ------------------------------------------------------------------ Aufbau

func _stil(bg: Color, rand := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_content_margin_all(rand)
	sb.set_corner_radius_all(4)
	return sb


func _baue_panel() -> void:
	panel = PanelContainer.new()
	panel.name = "WeltPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP           # Klicks im Panel gehen nicht in die Welt
	panel.add_theme_stylebox_override("panel", _stil(Color(0.1, 0.09, 0.08, 0.88), 12))
	panel.custom_minimum_size = Vector2(PANEL_B, 0)
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -PANEL_B - 12.0
	panel.offset_right = -12.0
	panel.offset_top = 72.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN     # breiter Inhalt wächst nach links, nie aus dem Bild
	panel.visible = false
	add_child(panel)
	panel_vb = VBoxContainer.new()
	panel_vb.add_theme_constant_override("separation", 6)
	panel.add_child(panel_vb)


func _baue_toast() -> void:
	toast_panel = ToastQueue.new()
	toast_panel.aktion_geklickt.connect(_toast_aktion)
	toast_panel.anchor_left = 1.0
	toast_panel.anchor_right = 1.0
	toast_panel.anchor_top = 1.0
	toast_panel.anchor_bottom = 1.0
	toast_panel.offset_left = -PANEL_B - 12.0
	toast_panel.offset_right = -12.0
	toast_panel.offset_top = -96.0
	toast_panel.offset_bottom = -12.0
	toast_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(toast_panel)


func _label(t: String, gr := 16, farbe := C_TEXT) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", gr)
	l.add_theme_color_override("font_color", farbe)
	return l


func _knopf(t: String, id: String, f: Callable, primaer := false, grau := false, bereich := "panel") -> Button:
	var b := Button.new()
	b.text = t
	b.name = id
	b.focus_mode = Control.FOCUS_NONE                      # Leertaste bleibt Pause
	b.custom_minimum_size = Vector2(0, 30)
	b.add_theme_font_size_override("font_size", 16)
	if primaer:
		b.add_theme_stylebox_override("normal", _stil(Color(0.24, 0.42, 0.3), 6))
		b.add_theme_stylebox_override("hover", _stil(Color(0.3, 0.5, 0.36), 6))
	if grau:                                                # G3: grau, aber klickbar – der Klick erklärt den Grund (nie stumm)
		b.add_theme_color_override("font_color", C_GRAU)
		b.add_theme_color_override("font_hover_color", C_GRAU)
	b.pressed.connect(func():
		klicks += 1
		f.call())
	knoepfe[id] = b
	if not _bereiche.has(bereich):
		_bereiche[bereich] = []
	_bereiche[bereich].append(id)
	return b


func _bereich_leeren(bereich: String) -> void:
	for id in _bereiche.get(bereich, []):
		knoepfe.erase(id)
	_bereiche[bereich] = []


# ------------------------------------------------------------------ Meldungen

## Rückmeldung auf eine Spieleraktion: sofort sichtbar (AT-11: verdrängt nur eine einfache Rückmeldung, Diagnosen kommen danach).
func meldung(t: String, dauer := -1.0) -> void:
	var o := {"sofort": true}
	if dauer > 0.0:
		o["dauer"] = dauer
	toast_panel.melden(t, o)
	meldungen_log.append({"t_ms": Time.get_ticks_msec(), "text": t})


## System- und Diagnosemeldung: hinten anstellen (AT-11, eine zugleich, 0 verloren).
func melden(t: String, opts: Dictionary = {}) -> void:
	toast_panel.melden(t, opts)
	meldungen_log.append({"t_ms": Time.get_ticks_msec(), "text": t, "titel": String(opts.get("titel", ""))})


func _process(delta: float) -> void:
	if _sim_ok():
		while not ps.meldungen.is_empty():                 # Sim-Meldungen (Freischaltung, Bankrott) in die Queue
			var m := String(ps.meldungen.pop_front())
			if m.contains("Lebensdauer"):
				continue                                     # FZ-03-Meldung kommt als Diagnose D6 (mit Aktion)
			melden(m)
	_refresh_t += delta
	if _refresh_t >= 0.25:
		_refresh_t = 0.0
		if auswahl != "" and not _taste_unten:          # BUG-1-Muster: kein Neuaufbau, solange die linke Taste gehalten wird
			panel_neu()
		if not _taste_unten:
			linien_neu()
		kopf_neu()


# ------------------------------------------------------------------ Eingabe

func _input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_taste_unten = (ev as InputEventMouseButton).pressed


## Weltklick (Bildschirmposition). Gibt true zurück, wenn ein Ort getroffen wurde (oder ein Modus den Klick braucht).
func welt_klick(pos: Vector2) -> bool:
	var nm := ort_unter(pos)
	if modus_von != "":
		klicks += 1
		if nm == "":
			meldung(text("ins_leere"), 2.0)
		else:
			ziel_waehlen(nm)
		return true
	if nm == "":
		return false
	klicks += 1
	oeffnen(nm)
	return true


## Nächster Stationsort im Radius KLICK_RADIUS_PX um pos (Projektion der Ortsmitte), "" = keiner.
func ort_unter(pos: Vector2) -> String:
	var cam: Camera3D = welt.cam
	var best := ""
	var best_d := KLICK_RADIUS_PX
	for nm in orte_pos:
		if not ps.stationen.has(nm):
			continue
		var p: Vector3 = orte_pos[nm]
		if cam.is_position_behind(p):
			continue
		var d := cam.unproject_position(p).distance_to(pos)
		if d <= best_d:
			best_d = d
			best = nm
	return best


func bildschirm_pos(nm: String) -> Vector2:
	return welt.cam.unproject_position(orte_pos[nm])


## Esc und andere Tasten. true = verbraucht (G5: Esc schließt zuerst das Panel, erst dann kommt das Menü).
func eingabe(ev: InputEvent) -> bool:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		if modus_von != "" or vorschau_ziel != "":       # AT-14 S2: Esc bricht in jeder Stufe ohne Text ab
			modus_ende()
			return true
		if auswahl != "":
			schliessen()
			return true
	return false


# ------------------------------------------------------------------ Panel

func oeffnen(nm: String) -> void:
	if nm != auswahl:
		_kauf_bestaetigen = ""
		_ausbau_bestaetigen = ""
	auswahl = nm
	panel_neu()
	panel.visible = true


func schliessen() -> void:
	auswahl = ""
	panel.visible = false
	_bereich_leeren("panel")


func panel_neu() -> void:
	for c in panel_vb.get_children():
		panel_vb.remove_child(c)
		c.queue_free()
	_bereich_leeren("panel")
	panel_werte = {"name": auswahl}
	if auswahl.begins_with("#"):                           # FZ-04: Fahrzeugkarte im selben Panel
		_panel_fahrzeug(int(auswahl.substr(1)))
		return
	var site := site_of(auswahl)
	if site < 0:
		panel_vb.add_child(_label(auswahl, 18))
		panel_vb.add_child(_label("Kein Handelsort.", 16, C_GRAU))
		return
	var e = ps.eco
	var kopf := HBoxContainer.new()
	var titel := _label(auswahl, 18)
	titel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kopf.add_child(titel)
	var typ := "Ort"
	if ist_industrie(site):
		typ = {"getreidefarm": "Getreidefarm", "muehle": "Mühle"}.get(String(e.i_ids[e.s_def[site]]), String(e.i_ids[e.s_def[site]]))
	elif ist_ort(site):
		typ = {"dorf": "Dorf", "kleinstadt": "Kleinstadt"}.get(String(e.s_stage[site]), String(e.s_stage[site]))
	kopf.add_child(_label(typ, 16, C_GRAU))
	kopf.add_child(_knopf("x", "schliessen", schliessen))
	panel_vb.add_child(kopf)
	if ist_industrie(site):
		_panel_industrie(site)
	elif ist_ort(site):
		_panel_ort(site)
	if ist_hq(site):
		_panel_hq()


func _trenner() -> void:
	panel_vb.add_child(HSeparator.new())


func _panel_industrie(site: int) -> void:
	var e = ps.eco
	var gut := ausgang(site)
	var b := bestand(site)
	panel_werte["bestand"] = b
	panel_werte["rate"] = int(e.s_rate[site])
	var roh: bool = e.s_raw[site] == 1
	var zeile := "Bestand %d E %s · %s %d E/min" % [b, gut.capitalize(), "liefert" if roh else "verarbeitet bis", e.s_rate[site]]
	panel_vb.add_child(_label(zeile, 16))
	for gi in e.s_inbuf[site]:                              # Verarbeiter: Eingangslager (Bedarf = Durchsatz)
		var n: int = e.s_inbuf[site][gi]
		panel_werte["eingang_" + String(e.g_ids[gi])] = n
		panel_werte["bedarf"] = int(e.s_rate[site])
		panel_vb.add_child(_label("Eingang %s %d E · Bedarf %d E/min" % [String(e.g_ids[gi]).capitalize(), n, e.s_rate[site]], 16))
	_trenner()
	_lizenz_zeile(site)
	_besitz_block(site)
	var ab := abnehmer(site)
	if not ab.is_empty():
		_trenner()
		panel_vb.add_child(_label("Abnehmer in Reichweite:", 16, C_GRAU))
		var liste: Array = []
		for a in ab:
			var form := "●"
			var zus := ""
			if ist_ort(int(a["site"])):
				var kat: String = e.g_cat[e.s_out_good[site]]
				var p := ort_saettigung_pct(int(a["site"]), kat)
				form = "■" if p >= 150 else ("▲" if p >= 100 else "●")
				zus = " %d %%" % p
			panel_vb.add_child(_label("  %s  %d Felder (%d m)  %s%s" % [a["name"], a["felder"], a["m"], form, zus], 16))
			liste.append(a["name"])
		panel_werte["abnehmer"] = liste
	panel_vb.add_child(_knopf("Linie von hier", "linie_von_hier", linie_von_hier.bind(auswahl), lizenz_ok(site)))
	_linien_ab(auswahl)


func _lizenz_zeile(site: int) -> void:
	var e = ps.eco
	var q: Dictionary = e.licence_quote(site, false)
	var hb := HBoxContainer.new()
	var lt := ""
	if eigen(site):
		lt = "● Lizenz: nicht nötig, gehört dir"
	elif e.licence_valid(site):
		var t := lizenz_rest_min(site)
		panel_werte["lizenz_rest_min"] = t
		lt = "%s Lizenz: gilt noch %d min" % ["▲" if t < 3 else "●", t]
	else:
		lt = "Lizenz: keine"
	var l := _label(lt, 16)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(l)
	if q.get("ok", false) and not lizenz_ok(site):
		var preis: int = q["zu_zahlen_cent"]
		panel_werte["lizenz_preis"] = preis
		var b := _knopf("Lizenz kaufen %s" % geld(preis), "lizenz_kaufen", lizenz_kaufen.bind(auswahl), false, preis > e.cash_cent)
		if preis > e.cash_cent:
			b.tooltip_text = "Es fehlen %s." % fehlbetrag(preis - e.cash_cent)
		hb.add_child(b)
	panel_vb.add_child(hb)


func _panel_ort(site: int) -> void:
	var e = ps.eco
	var ew := int(e.c_index[e.s_city_id[site]].get("einwohner_anzahl", 0))
	var dem: int = e.city_demand(site)
	panel_werte["einwohner"] = ew
	panel_werte["bedarf"] = dem
	panel_vb.add_child(_label("Einwohner %s · Bedarf %d E/min je Warengruppe" % [_tsd(ew), dem], 16))
	var korb := ort_korb(site)
	var gueter: Array = []
	for g in e.g_ids.size():
		if String(e.g_cat[g]) in korb:
			gueter.append(String(e.g_ids[g]).capitalize())
	panel_werte["korb"] = korb
	panel_vb.add_child(_label("Nimmt an: %s" % (", ".join(PackedStringArray(gueter)) if not gueter.is_empty() else "nichts"), 16))
	for kat in korb:
		var p := ort_saettigung_pct(site, kat)
		var n := ort_geliefert(site, kat)
		panel_werte["saettigung_" + String(kat)] = p
		panel_werte["geliefert_" + String(kat)] = n
		var form := "■" if p >= 150 else ("▲" if p >= 100 else "●")
		var l := _label("%s Sättigung %s: %d %% (%d von %d E diese Minute)" % [form, String(kat).capitalize(), p, n, dem], 16,
			C_BAD if p >= 150 else (C_WARN if p >= 100 else C_TEXT))
		panel_vb.add_child(l)
	panel_vb.add_child(_label("Lizenz: nicht nötig", 16, C_GRAU))


## Fuhrhalterei am HQ: nur Panel-Eintrag (AT-14 S3), keine Sim-Funktion. Preis und Unterhalt aus vehicles.json.
func _panel_hq() -> void:
	var d := fuhrwerk_def()
	_trenner()
	panel_vb.add_child(_label("Firmensitz (HQ) · Fuhrhalterei", 18))
	panel_werte["fuhrwerk_preis"] = int(d.get("kauf_cent", 0))
	panel_werte["fuhrwerk_fix"] = int(d.get("fix_cent_pro_periode", 0))
	panel_vb.add_child(_label("Fuhrwerk %s · Unterhalt %s/min · %d E Ladung" % [geld(int(d.get("kauf_cent", 0))),
		geld(int(d.get("fix_cent_pro_periode", 0))), int(d.get("kapazitaet_einheiten", 0))], 16))
	var l := _label(text("fuhrhalterei"), 16, C_GRAU)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_vb.add_child(l)
	var l2 := _label(text("postkutsche"), 15, C_GRAU)
	l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_vb.add_child(l2)


# ------------------------------------------------------------------ Aktionen

## Lizenz kaufen über proto_sim.lizenz_kaufen. Jede Ablehnung mit Text (AT-14 F1.x).
func lizenz_kaufen(nm: String) -> Dictionary:
	var site := site_of(nm)
	var r: Dictionary
	if site < 0:
		r = {"ok": false, "fehler": "unbekannter_ort"}
	elif ist_ort(site):
		meldung(text("lizenz_nicht_noetig", {"name": nm}))
		return {"ok": false, "fehler": "nicht_noetig"}
	else:
		r = ps.lizenz_kaufen(nm)
	if r.get("ok", false):
		meldung(text("lizenz_ok", {"name": nm, "t": lizenz_rest_min(site)}))
	else:
		meldung(lizenz_fehlertext(nm, r))
	if auswahl != "":
		panel_neu()
	return r


func lizenz_fehlertext(nm: String, r: Dictionary) -> String:
	var f := String(r.get("fehler", "?"))
	var site := site_of(nm)
	match f:
		"guthaben_reicht_nicht":
			var q: Dictionary = ps.eco.licence_quote(site, false)
			var w := {"x": geld(int(q.get("zu_zahlen_cent", 0))), "d": fehlbetrag(int(r.get("fehlt_cent", 0)))}
			return text("lizenz_geld_ab12" if ps.sim.tick_count >= int(ps.credit.from_ticks) else "lizenz_geld_vor12", w)
		"schon_lizenziert":
			return text("lizenz_schon", {"name": nm, "t": lizenz_rest_min(site)})
		"bankrott":
			return text("bankrott")
		"keine_lizenzierbare_industrie":
			return text("lizenz_nicht_noetig", {"name": nm})
	return text("lizenz_sonst", {"code": f})




# ------------------------------------------------------------------ AT-08 Linienbau

func _baue_linienbau() -> void:
	modus_panel = PanelContainer.new()
	modus_panel.name = "LinienModus"
	modus_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	modus_panel.add_theme_stylebox_override("panel", _stil(Color(0.12, 0.2, 0.14, 0.9), 8))
	modus_panel.anchor_left = 0.5                         # unten Mitte: oben liegt das Prototyp-HUD (H blendet es aus)
	modus_panel.anchor_right = 0.5
	modus_panel.anchor_top = 1.0
	modus_panel.anchor_bottom = 1.0
	modus_panel.offset_bottom = -16.0
	modus_panel.offset_left = MITTE_VERSATZ                # Mitte der freien Fläche zwischen Linienliste und Panel
	modus_panel.offset_right = MITTE_VERSATZ
	modus_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	modus_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	modus_panel.visible = false
	add_child(modus_panel)
	modus_hb = HBoxContainer.new()
	modus_hb.add_theme_constant_override("separation", 10)
	modus_panel.add_child(modus_hb)
	vorschau_panel = PanelContainer.new()
	vorschau_panel.name = "Linienvorschau"
	vorschau_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	vorschau_panel.add_theme_stylebox_override("panel", _stil(Color(0.1, 0.09, 0.08, 0.92), 12))
	vorschau_panel.anchor_left = 0.5
	vorschau_panel.anchor_right = 0.5
	vorschau_panel.anchor_top = 1.0
	vorschau_panel.anchor_bottom = 1.0
	vorschau_panel.offset_bottom = -72.0                   # über der Modusleiste
	vorschau_panel.offset_left = MITTE_VERSATZ - VORSCHAU_B / 2.0   # feste Breite, Texte brechen um
	vorschau_panel.offset_right = MITTE_VERSATZ + VORSCHAU_B / 2.0
	vorschau_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vorschau_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	vorschau_panel.visible = false
	add_child(vorschau_panel)
	vorschau_vb = VBoxContainer.new()
	vorschau_vb.add_theme_constant_override("separation", 4)
	vorschau_panel.add_child(vorschau_vb)


func _leeren(c: Node) -> void:
	for k in c.get_children():
		c.remove_child(k)
		k.queue_free()


## Modus „Linie von hier“ (S2a). Ohne Lizenz zeigt die Modusleiste den Grund und den Kauf (ein Klick, Modus bleibt).
func linie_von_hier(nm: String) -> void:
	var site := site_of(nm)
	if site < 0 or ausgang(site) == "":
		meldung(text("liefert_nichts", {"name": nm}))
		return
	modus_von = nm
	vorschau_ziel = ""
	vorschau_panel.visible = false
	_bereich_leeren("vorschau")
	modus_neu()


func modus_neu() -> void:
	_leeren(modus_hb)
	_bereich_leeren("modus")
	if modus_von == "":
		modus_panel.visible = false
		return
	modus_hb.add_child(_label(text("modus", {"name": modus_von}), 16))
	var site := site_of(modus_von)
	if not lizenz_ok(site):
		modus_hb.add_child(_label("Keine Lizenz.", 16, C_WARN))
		var q: Dictionary = ps.eco.licence_quote(site, false)
		var preis: int = int(q.get("zu_zahlen_cent", 0))
		var b := _knopf("Lizenz kaufen %s" % geld(preis), "modus_lizenz", func():
			lizenz_kaufen(modus_von)
			modus_neu(), false, preis > ps.eco.cash_cent, "modus")
		modus_hb.add_child(b)
	modus_hb.add_child(_knopf("Abbrechen · Esc", "modus_abbrechen", modus_ende, false, false, "modus"))
	modus_panel.visible = true


func modus_ende() -> void:
	modus_von = ""
	vorschau_ziel = ""
	vorschau_werte = {}
	vorschau_panel.visible = false
	_bereich_leeren("vorschau")
	modus_neu()


## Fahrzeuge (nicht verkauft) der Linie von → nach.
func linien_fahrzeuge(von: String, nach: String) -> Array:
	var a: int = int(ps.stationen[von]["knoten"])
	var b: int = int(ps.stationen[nach]["knoten"])
	return ps.fahrzeuge.filter(func(f): return int(f["von"]) == a and int(f["nach"]) == b and not f["verkauft"] and f["kauf_cent"] > 0)


## Ziel im Modus angeklickt (S2b). Prüfreihenfolge: gleich → Verbindung → Annahme → Lizenz → Vorschau.
func ziel_waehlen(nm: String) -> void:
	var von := modus_von
	if nm == von:
		meldung(text("gleich"))
		return
	var sv := site_of(von)
	var sz := site_of(nm)
	var g: int = ps.eco.s_out_good[sv]
	var v := route_vorschau(von, nm, 1)
	if not v["ok"]:
		meldung(text("keine_verbindung", {"a": von, "b": nm}))
		return
	if not nimmt_an(sz, g):
		meldung(text("nimmt_nicht", {"ziel": nm, "ware": String(ps.eco.g_ids[g]).capitalize()}))
		return
	var n_alt := linien_fahrzeuge(von, nm).size()
	if n_alt > 0:
		meldung(text("gibt_es_schon"))
	vorschau_ziel = nm
	vorschau_zeigen(von, nm, n_alt)


## Routenvorschau (W3): Strecke, Fahrzeit, Ertrag je Fuhre, Netto/min (Schätzung), Preis, Unterhalt.
## n = Zahl der Fuhrwerke auf der Linie nach dem Kauf. Schätzung: volle Frische, ohne Sättigung, Fahrzeit ohne Easing;
## Fuhren je Minute höchstens Liefermenge der Quelle ÷ Ladung.
func route_vorschau(von: String, nach: String, n: int) -> Dictionary:
	var a: Dictionary = ps.stationen[von]
	var b: Dictionary = ps.stationen[nach]
	var route: Array = ps.sim.graph.find_path(int(a["knoten"]), int(b["knoten"]))
	if route.is_empty():
		return {"ok": false, "fehler": "keine_verbindung"}
	var e = ps.eco
	var d := fuhrwerk_def()
	var sv := int(a["site"])
	var sz := int(b["site"])
	var g: int = e.s_out_good[sv]
	var cap := int(d.get("kapazitaet_einheiten", 10))
	var route_mm: int = ps.sim.graph.route_length(route)
	var strecke_m: float = route_mm / ps.mm_pro_m
	var v_nom: float = maxf(0.001, ps.profil("fuhrwerk").v_nom)
	var fahr_ticks: float = strecke_m / v_nom
	var load_ticks := int(e.slice.get("fahrzeug_ref", {}).get("load_ticks", 100))
	var umlauf: float = 2.0 * fahr_ticks + 2.0 * load_ticks
	var felder: int = e.luftlinie_felder(sv, sz)
	var ertrag: int = e.yield_cent(g, felder, Economy.PROMILLE, cap * Economy.PROMILLE) if g >= 0 else 0
	var fahrk: int = int(round(2.0 * route_mm / float(e.feld_mm))) * int(d.get("variabel_cent_pro_feld", 0))
	var fuhren_fz: float = n * float(e.periode_ticks) / umlauf
	var fuhren: float = minf(fuhren_fz, float(e.s_rate[sv]) / cap)
	var fix := int(d.get("fix_cent_pro_periode", 0))
	return {"ok": true, "strecke_m": roundi(strecke_m), "fahrzeit_s": roundi(fahr_ticks / 10.0), "felder": felder,
		"ertrag_fuhre_cent": ertrag, "fahrkosten_fuhre_cent": fahrk, "fuhren_min": fuhren,
		"netto_min_cent": roundi(fuhren * (ertrag - fahrk)) - n * fix, "preis_cent": int(d.get("kauf_cent", 0)), "fix_cent": fix,
		"gut": String(e.g_ids[g]) if g >= 0 else "", "quelle_begrenzt": fuhren_fz > fuhren and n > 1, "quelle_rate": int(e.s_rate[sv])}


func vorschau_zeigen(von: String, nach: String, n_alt: int) -> void:
	_leeren(vorschau_vb)
	_bereich_leeren("vorschau")
	var v := route_vorschau(von, nach, n_alt + 1)
	vorschau_werte = v.duplicate()
	vorschau_werte["von"] = von
	vorschau_werte["nach"] = nach
	vorschau_vb.add_child(_label("Linie: %s → %s (%s)%s" % [von, nach, String(v["gut"]).capitalize(),
		(" · %d Fuhrwerk(e) fahren schon" % n_alt) if n_alt > 0 else ""], 18))
	vorschau_vb.add_child(_label("Strecke %s m · Fahrzeit ~%d s · Ertrag je Fuhre %s · ca. %s%s/min" % [_tsd(v["strecke_m"]), v["fahrzeit_s"],
		geld(v["ertrag_fuhre_cent"]), "+" if v["netto_min_cent"] >= 0 else "", geld(v["netto_min_cent"])], 16))
	vorschau_vb.add_child(_label("Fuhrwerk: %s einmalig · Unterhalt %s/min · Fahrkosten %s je Fuhre" % [geld(v["preis_cent"]),
		geld(v["fix_cent"]), geld(v["fahrkosten_fuhre_cent"])], 16))
	if v["quelle_begrenzt"]:                                # F3.2: Hinweis, Kauf bleibt möglich
		vorschau_vb.add_child(_label("▲ " + text("liefert_wenig", {"name": von, "x": v["quelle_rate"]}), 16, C_WARN))
	vorschau_vb.add_child(_label("Schätzung: volle Frische, ohne Sättigung des Abnehmers.", 15, C_GRAU))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	var sv := site_of(von)
	var lic := 0                                            # PO 05.11.: [Lizenz + Anlegen] in einem Knopf
	if not lizenz_ok(sv):
		lic = int(ps.eco.licence_quote(sv, false).get("zu_zahlen_cent", 0))
		vorschau_vb.add_child(_label("%s hat keine Lizenz: Lizenz %s, gilt %d min" % [von, geld(lic),
			int(ps.eco.lic_duration) / periode()], 16, C_WARN))
	vorschau_werte["lizenz_cent"] = lic
	vorschau_werte["mit_lizenz"] = not lizenz_ok(sv)
	var summe: int = int(v["preis_cent"]) + lic
	vorschau_werte["summe_cent"] = summe
	var grau: bool = summe > ps.eco.cash_cent
	var t := ("+ Fuhrwerk · %s" if n_alt > 0 else "Anlegen · %s") % geld(v["preis_cent"])
	if not lizenz_ok(sv):
		t = "Lizenz + Anlegen · %s" % geld(summe)
	var b := _knopf(t, "anlegen", anlegen, not grau, grau, "vorschau")
	if grau:
		b.tooltip_text = "Es fehlen %s." % fehlbetrag(summe - ps.eco.cash_cent)
	hb.add_child(b)
	hb.add_child(_knopf("Abbrechen · Esc", "vorschau_abbrechen", modus_ende, false, false, "vorschau"))
	vorschau_vb.add_child(hb)
	_umbrechen(vorschau_vb)
	vorschau_panel.visible = true


## [Anlegen] in der Vorschau (S2c, A1: kauft das erste Fuhrwerk mit). Danach geht der Modus am Ziel weiter, wenn es liefert.
func anlegen() -> Dictionary:
	var von := String(vorschau_werte.get("von", ""))
	var nach := String(vorschau_werte.get("nach", ""))
	var sv := site_of(von)
	var mit_lizenz := sv >= 0 and not lizenz_ok(sv)
	if mit_lizenz:                                         # gemeinsamer Knopf: erst prüfen, dann Lizenz, dann Fuhrwerk
		var summe := int(ps.eco.licence_quote(sv, false).get("zu_zahlen_cent", 0)) + int(fuhrwerk_def().get("kauf_cent", 0))
		if summe > ps.eco.cash_cent:
			meldung(text("lizenz_linie_geld", {"x": geld(summe), "d": fehlbetrag(summe - ps.eco.cash_cent)}))
			return {"ok": false, "fehler": "guthaben_reicht_nicht"}
		var rl: Dictionary = ps.lizenz_kaufen(von)
		if not rl.get("ok", false):
			meldung(lizenz_fehlertext(von, rl))
			return rl
	var r := fuhrwerk_kaufen(von, nach, mit_lizenz)
	if r.get("ok", false):
		var sz := site_of(nach)
		if ausgang(sz) != "":
			linie_von_hier(nach)                          # Kette weiter: Ziel ist die nächste Quelle (Esc beendet)
		else:
			modus_ende()
		oeffnen(nach)
	return r


## Fuhrwerk auf der Linie von → nach kaufen (erste Linie oder + Fuhrwerk). Prüft Lizenz und Kasse vor der API,
## jede Ablehnung der API wird übersetzt (nie stumm).
func fuhrwerk_kaufen(von: String, nach: String, mit_lizenz := false) -> Dictionary:
	if von == "" or nach == "":
		meldung(text("ins_leere"))
		return {"ok": false, "fehler": "keine_auswahl"}
	var sv := site_of(von)
	if sv >= 0 and ist_industrie(sv) and ps.eco.lic_required and not lizenz_ok(sv):
		meldung(text("keine_lizenz", {"name": von}))       # API-Lücke: linie_anlegen prüft die Lizenz nicht (Bericht)
		oeffnen(von)
		return {"ok": false, "fehler": "keine_lizenz"}
	var n_alt := linien_fahrzeuge(von, nach).size()
	var r: Dictionary = ps.linie_anlegen(von, nach, "fuhrwerk")
	if not r.get("ok", false):
		meldung(linie_fehlertext(von, nach, r))
		return r
	_fahrzeuge_neu()
	var v := route_vorschau(von, nach, n_alt + 1)
	if mit_lizenz:
		meldung(text("lizenz_linie_ok", {"name": von, "b": nach, "n": r["vid"]}))
	elif n_alt == 0:
		meldung(text("linie_ok", {"a": von, "b": nach, "n": r["vid"]}))
	else:
		meldung(text("fuhrwerk_ok", {"n": r["vid"], "p": geld(int(r["preis_cent"])), "u": geld(v["fix_cent"]),
			"z": ("+" if v["netto_min_cent"] >= 0 else "") + geld(v["netto_min_cent"])}))
	if vorschau_ziel != "" and modus_von == von:
		vorschau_zeigen(von, nach, n_alt + 1)
	if auswahl != "":
		panel_neu()
	return r


func linie_fehlertext(von: String, nach: String, r: Dictionary) -> String:
	var f := String(r.get("fehler", "?"))
	match f:
		"keine_verbindung":
			return text("keine_verbindung", {"a": von, "b": nach})
		"guthaben_reicht_nicht":
			return text("fuhrwerk_geld", {"x": geld(int(fuhrwerk_def().get("kauf_cent", 0))), "d": fehlbetrag(int(r.get("fehlt_cent", 0)))})
		"gleicher_ort":
			return text("gleich")
		"bankrott":
			return text("bankrott")
		"noch_nicht_verfuegbar":
			return text("frachtwagen_1830")
		"unbekannter_ort":
			return text("ins_leere")
	return text("linie_sonst", {"code": f})


## Adapter (API-Lücke): proto_fahrzeuge.gd legt die Slots nur in bauen() an. Nach jedem Kauf baut die UI die Darstellung
## neu (Zustand und Easing liegen in proto_sim, gehen also nicht verloren). Anforderung an Felix: fahrzeug_dazu(f).
func _fahrzeuge_neu() -> void:
	var alt = welt.fahrzeuge
	var neu = preload("res://proto/proto_fahrzeuge.gd").new()
	welt.add_child(neu)
	neu.easing_an = welt.easing_an
	neu.bauen(ps, welt.regelwerk)
	welt.fahrzeuge = neu
	if alt != null:
		alt.queue_free()


## Panel-Abschnitt „Linien ab hier“ (W4-Ausschnitt): je Ziel Fuhrwerke und [+ Fuhrwerk] (S3: ≤ 2 Klicks ab Panel).
func _linien_ab(von: String) -> void:
	var ziele := {}
	var a: int = int(ps.stationen[von]["knoten"])
	for f in ps.fahrzeuge:
		if int(f["von"]) == a and not f["verkauft"] and f["kauf_cent"] > 0:
			for nm in ps.stationen:
				if int(ps.stationen[nm]["knoten"]) == int(f["nach"]):
					ziele[nm] = int(ziele.get(nm, 0)) + 1
	if ziele.is_empty():
		return
	_trenner()
	panel_vb.add_child(_label("Linien ab hier:", 16, C_GRAU))
	var preis := int(fuhrwerk_def().get("kauf_cent", 0))
	for nm in ziele:
		var hb := HBoxContainer.new()
		var l := _label("→ %s · %d Fuhrwerk(e)" % [nm, ziele[nm]], 16)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(l)
		panel_vb.add_child(hb)
		panel_werte["linie_" + nm] = ziele[nm]
		var zeile := _fz_knoepfe(linien_fahrzeuge(von, nm))
		var grau: bool = preis > ps.eco.cash_cent
		var b := _knopf("+ Fuhrwerk %s" % geld(preis), "plus_" + nm, fuhrwerk_kaufen.bind(von, nm), false, grau)
		if grau:
			b.tooltip_text = "Es fehlen %s." % fehlbetrag(preis - ps.eco.cash_cent)
		zeile.add_child(b)
		panel_vb.add_child(zeile)


# ------------------------------------------------------------------ AT-09 Kopfleiste (HUD Welt)

## W1: Kasse zuerst (links), Netto/min, Fix/min, Kredit-Chip, rechts Datum (Kalender), Tempo-Knöpfe und k (AT-14 A7).
## Netto und Ertrag sind Werte der letzten vollen Spielminute (Periode), tick-genau über nach_tick() aus sim_schritt:
## Ertrag = Δ revenue_total, laufende Kosten = Δ konto.expenses_total − Δ kauf_total (Fahrkosten, Unterhalt, Zins; ohne
## Fahrzeug- und Lizenzkäufe). Fix/min = konto.running_cost_per_period (Unterhalt aller Fahrzeuge je Minute).
func _baue_kopfleiste() -> void:
	kopf = PanelContainer.new()
	kopf.name = "Kopfleiste"
	kopf.mouse_filter = Control.MOUSE_FILTER_STOP
	kopf.add_theme_stylebox_override("panel", _stil(Color(0.1, 0.09, 0.08, 0.88), 8))
	kopf.anchor_left = 0.0
	kopf.anchor_right = 1.0
	kopf.offset_left = 8.0
	kopf.offset_right = -8.0
	kopf.offset_top = 8.0
	add_child(kopf)
	kopf_hb = HBoxContainer.new()
	kopf_hb.add_theme_constant_override("separation", 14)
	kopf.add_child(kopf_hb)
	lbl_kasse = _label("", 18)
	lbl_kasse.name = "Kasse"
	kopf_hb.add_child(lbl_kasse)
	lbl_netto = _label("", 16)
	lbl_netto.name = "Netto"
	lbl_netto.tooltip_text = "Ertrag minus Fahrkosten, Unterhalt und Zins der letzten vollen Minute"
	lbl_netto.mouse_filter = Control.MOUSE_FILTER_PASS
	kopf_hb.add_child(lbl_netto)
	lbl_fix = _label("", 16)
	lbl_fix.name = "Fix"
	lbl_fix.tooltip_text = "Unterhalt aller Fuhrwerke und eigenen Werke je Minute"
	lbl_fix.mouse_filter = Control.MOUSE_FILTER_PASS
	kopf_hb.add_child(lbl_fix)
	lbl_kredit = _label("", 16)
	lbl_kredit.name = "Kredit"
	kopf_hb.add_child(lbl_kredit)
	kopf_hb.add_child(_knopf("Kredit", "kredit", kredit_aufnehmen, false, false, "kopf"))
	kopf_hb.add_child(_knopf("Tilgen", "tilgen", kredit_tilgen, false, false, "kopf"))
	var luecke := Control.new()
	luecke.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	luecke.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kopf_hb.add_child(luecke)
	# Datum und Tempo-Knöpfe der Szene (AT-05) ziehen in die Kopfleiste um (gleiche Knoten, Tests der Szene bleiben gültig)
	if welt.datum_label != null:
		welt.datum_label.get_parent().remove_child(welt.datum_label)
		kopf_hb.add_child(welt.datum_label)
	for t in welt.TEMPI:
		var b: Button = welt.tempo_knoepfe.get(t)
		if b != null:
			b.get_parent().remove_child(b)
			kopf_hb.add_child(b)
	lbl_k = _label("", 16)
	lbl_k.name = "TempoK"
	lbl_k.tooltip_text = "Tempo-Teiler k der Fuhrwerke (AT-04): Fahrzeuge fahren 1/k so schnell"
	lbl_k.mouse_filter = Control.MOUSE_FILTER_PASS
	kopf_hb.add_child(lbl_k)
	# altes Prototyp-HUD (Zählung, Hilfe) unter die Kopfleiste
	if welt.hud != null:
		var pc: Control = welt.hud.get_parent().get_parent()
		pc.position.y = 64.0
	_schnapp_neu()
	kopf_neu()


func _schnapp_neu() -> void:
	_schnapp.append({"tick": ps.sim.tick_count, "rev": int(ps.eco.revenue_total), "ausg": int(ps.konto.expenses_total), "kauf": int(ps.kauf_total)})
	while _schnapp.size() > 2:
		_schnapp.pop_front()


## Aus sim_schritt nach jedem Tick (prototyp_welt.gd): Schnappschuss genau an der Periodengrenze.
func nach_tick() -> void:
	if not _sim_ok():
		return
	statistik.nach_tick()
	_warte_zaehlen()
	if ps.sim.tick_count % periode() == 0:
		_schnapp_neu()
		_netto_verlauf_neu()
		diagnose(true)
	elif ps.sim.tick_count % 10 == 0:
		diagnose(false)


func kopf_neu() -> void:
	if not _sim_ok() or kopf == null:
		return
	var e = ps.eco
	hud_werte = {"kasse": int(e.cash_cent), "fix": int(ps.konto.running_cost_per_period), "kredit": int(ps.credit.loan_cent),
		"zins": int(ps.credit.interest_per_period()), "k": int(ps.tempo_k), "tempo": int(welt.sim_tempo),
		"datum": ps.kalender.datum_text(ps.ticks)}
	var form := "■" if e.cash_cent < 0 else "●"
	lbl_kasse.text = "Kasse %s %s" % [form, geld(e.cash_cent)]
	if _schnapp.size() == 2 and _schnapp[0]["tick"] + periode() == _schnapp[1]["tick"]:
		var a: Dictionary = _schnapp[0]
		var b: Dictionary = _schnapp[1]
		var ertrag: int = b["rev"] - a["rev"]
		var laufend: int = (b["ausg"] - a["ausg"]) - (b["kauf"] - a["kauf"])
		hud_werte["ertrag"] = ertrag
		hud_werte["netto"] = ertrag - laufend
		var n: int = hud_werte["netto"]
		lbl_netto.text = "Netto %s %s%s/min" % ["▲" if n >= 0 else "▼", "+" if n > 0 else "", geld(n)]
	else:
		lbl_netto.text = "Netto — $/min"
	lbl_fix.text = "Fix %s/min" % geld(hud_werte["fix"])
	if ps.credit.loan_cent > 0:
		lbl_kredit.text = "Kredit %s · Zins %s/min" % [geld(ps.credit.loan_cent), geld(hud_werte["zins"])]
	else:
		lbl_kredit.text = "Kredit —"
	var ab: bool = ps.sim.tick_count >= int(ps.credit.from_ticks)
	var kb: Button = knoepfe.get("kredit")
	if kb != null:
		kb.text = "Kredit +%s" % geld(ps.credit.step_cent)
		var frei: bool = ab and ps.credit.borrow_amount(ps.sim.tick_count) > 0
		kb.add_theme_color_override("font_color", C_TEXT if frei else C_GRAU)
		kb.tooltip_text = "Zins %d %% je Minute auf den offenen Betrag" % roundi(ps.credit.interest_pm / 10.0) if ab else text("kredit_ab12")
	var tb: Button = knoepfe.get("tilgen")
	if tb != null:
		tb.visible = ps.credit.loan_cent > 0
		tb.text = "Tilgen %s" % geld(mini(ps.credit.step_cent, ps.credit.loan_cent))
	lbl_k.text = "k=%d" % ps.tempo_k


func kredit_aufnehmen() -> int:
	var t: int = ps.sim.tick_count
	if ps.konto.bankrupt:
		meldung(text("bankrott"))
		return 0
	if t < int(ps.credit.from_ticks):
		meldung(text("kredit_ab12"))
		return 0
	var a: int = ps.kredit_aufnehmen()
	if a <= 0:
		meldung(text("kredit_voll", {"x": geld(ps.credit.limit_cent)}))
	else:
		meldung(text("kredit_ok", {"x": geld(a), "z": geld(ps.credit.interest_per_period()), "r": geld(ps.credit.limit_cent - ps.credit.loan_cent)}))
	kopf_neu()
	return a


func kredit_tilgen() -> int:
	if ps.konto.bankrupt:
		meldung(text("bankrott"))
		return 0
	if ps.credit.loan_cent <= 0:
		meldung(text("kein_kredit"))
		return 0
	var a: int = ps.kredit_tilgen()
	if a <= 0:
		meldung(text("tilgen_geld", {"x": fehlbetrag(mini(ps.credit.step_cent, ps.credit.loan_cent) - ps.eco.cash_cent)}))
	else:
		meldung(text("tilgen_ok", {"x": geld(a), "r": geld(ps.credit.loan_cent)}))
	kopf_neu()
	return a


# ------------------------------------------------------------------ FK-03 Firmenkauf C1 (Panel-Block „Besitz“)

## Ausbaustufe 2 vor dem Kauf (Vorschau der Folgen): Kosten und Durchsatz aus economy_slice.json fabrik.
func _ausbau_l2(site: int) -> Dictionary:
	if ps.eco.s_raw[site] == 1 or ps.eco.s_out_good[site] < 0:
		return {}
	var f: Dictionary = ps.eco.slice.get("fabrik", {})
	return {"kosten_cent": int(f.get("factory_upgrade_cost_l2_cent", 0)), "durchsatz": int(f.get("factory_throughput_l2_einheiten_pro_periode", 0))}


func _typname(site: int) -> String:
	return {"getreidefarm": "Farm", "muehle": "Mühle"}.get(String(ps.eco.i_ids[ps.eco.s_def[site]]), "Betrieb")


func _besitz_block(site: int) -> void:
	var nm := auswahl
	var e = ps.eco
	_trenner()
	if eigen(site):
		var stufe: int = int(e.s_werksstufe[site])
		panel_werte["werksstufe"] = stufe
		panel_werte["werk_unterhalt"] = int(e.upkeep_per_level) * stufe
		panel_vb.add_child(_label("Besitz: gehört dir · Werksstufe %d · Unterhalt %s/min" % [stufe, geld(int(e.upkeep_per_level) * stufe)], 16, C_OK))
		var a: Dictionary = ps.ausbau_angebot(nm)
		if not a.get("ok", false):
			var f := String(a.get("fehler", ""))
			if f == "hoechste_stufe":
				panel_vb.add_child(_label("Höchste Werksstufe dieser Version.", 15, C_GRAU))
			return
		panel_werte["ausbau_kosten"] = int(a["kosten_cent"])
		panel_werte["ausbau_durchsatz"] = int(a["durchsatz_neu"])
		if _ausbau_bestaetigen == nm:
			panel_vb.add_child(_label("Ausbau auf %d E/min für %s" % [a["durchsatz_neu"], geld(a["kosten_cent"])], 16))
			panel_vb.add_child(_label("· Unterhalt danach %s/min (+%s)" % [geld(a["unterhalt_neu_cent_pro_periode"]),
				geld(int(a["unterhalt_neu_cent_pro_periode"]) - int(e.upkeep_per_level) * stufe)], 16))
			var hb := HBoxContainer.new()
			hb.add_child(_knopf("Ausbauen · %s" % geld(a["kosten_cent"]), "ausbau_ok", ausbau_bestaetigt.bind(nm), true))
			hb.add_child(_knopf("Abbrechen", "ausbau_ab", func():
				_ausbau_bestaetigen = ""
				panel_neu()))
			panel_vb.add_child(hb)
		else:
			var frei: int = e.cash_cent - int(ps.credit.loan_cent)
			var b := _knopf("Werk ausbauen auf %d E/min · %s" % [a["durchsatz_neu"], geld(a["kosten_cent"])], "ausbauen",
				ausbau_klick.bind(nm), false, frei < int(a["kosten_cent"]))
			panel_vb.add_child(b)
		return
	var q: Dictionary = ps.kauf_angebot(nm)
	if not q.get("ok", false):
		panel_vb.add_child(_label("Besitz: nicht käuflich", 16, C_GRAU))
		return
	var preis: int = q["preis_cent"]
	panel_werte["kauf_preis"] = preis
	panel_werte["kauf_anrechnung"] = int(q["anrechnung_cent"])
	panel_werte["kauf_unterhalt"] = int(q["unterhalt_neu_cent_pro_periode"])
	panel_werte["kauf_marge_pct"] = int(q["marge_promille"]) / 10
	panel_vb.add_child(_label("Besitz: gehört nicht dir", 16))
	var neben := "Unterhalt +%s/min" % geld(q["unterhalt_neu_cent_pro_periode"])
	if int(q["anrechnung_cent"]) > 0:
		neben = "Lizenzgebühren angerechnet −%s · %s" % [geld(q["anrechnung_cent"]), neben]
	if bool(q.get("rabatt_erster_kauf", false)):
		neben += " · Erstkauf-Rabatt"
	if _kauf_bestaetigen == nm and bool(q["kaufbar"]):
		var aus := _ausbau_l2(site)
		panel_vb.add_child(_label("%s kaufen für %s? Das folgt daraus:" % [nm, geld(preis)], 16))
		panel_vb.add_child(_label("· Unterhalt +%s/min · Werksmarge +%d %%" % [geld(q["unterhalt_neu_cent_pro_periode"]), int(q["marge_promille"]) / 10], 16))
		panel_vb.add_child(_label("· Lizenz entfällt, die Fuhrwerke laden ohne", 16))
		if not aus.is_empty():
			panel_werte["kauf_ausbau_kosten"] = aus["kosten_cent"]
			panel_werte["kauf_ausbau_durchsatz"] = aus["durchsatz"]
			panel_vb.add_child(_label("· Danach Ausbau auf %d E/min für %s möglich" % [aus["durchsatz"], geld(aus["kosten_cent"])], 16))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		hb.add_child(_knopf("Kaufen · %s" % geld(preis), "kauf_ok", kauf_bestaetigt.bind(nm), true))
		hb.add_child(_knopf("Abbrechen", "kauf_ab", func():
			_kauf_bestaetigen = ""
			panel_neu()))
		panel_vb.add_child(hb)
	else:
		var b := _knopf("%s kaufen · %s" % [_typname(site), geld(preis)], "kaufen", kauf_klick.bind(nm), false, not bool(q["kaufbar"]))
		if not bool(q["kaufbar"]):
			b.tooltip_text = kauf_fehlertext(nm, {"fehler": q["grund"], "fehlt_cent": preis - int(q["guthaben_ohne_kredit_cent"])})
		panel_vb.add_child(b)
	var l := _label(neben, 15, C_GRAU)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_vb.add_child(l)


## 1. Klick auf [… kaufen]: Bestätigung inline mit Folgen, oder Grund als Text (nie stumm).
func kauf_klick(nm: String) -> void:
	var q: Dictionary = ps.kauf_angebot(nm)
	if not q.get("ok", false) or not bool(q.get("kaufbar", false)):
		var g := String(q.get("grund", q.get("fehler", "?")))
		meldung(kauf_fehlertext(nm, {"fehler": g, "fehlt_cent": int(q.get("preis_cent", 0)) - int(q.get("guthaben_ohne_kredit_cent", 0))}))
		return
	_kauf_bestaetigen = nm
	panel_neu()


## 2. Klick [Kaufen · x $]: firma_kaufen. Kasse ändert sich um den Vorschaupreis (Test).
func kauf_bestaetigt(nm: String) -> Dictionary:
	_kauf_bestaetigen = ""
	var site := site_of(nm)
	var q: Dictionary = ps.kauf_angebot(nm)
	var r: Dictionary = ps.firma_kaufen(nm)
	if r.get("ok", false):
		var aus := _ausbau_l2(site)
		var zus := ""
		if not aus.is_empty():
			zus = text("kauf_ok_ausbau", {"d": aus["durchsatz"], "x": geld(aus["kosten_cent"])})
		meldung(text("kauf_ok", {"name": nm, "m": int(q.get("marge_promille", 0)) / 10, "u": geld(int(q.get("unterhalt_neu_cent_pro_periode", 0))), "aus": zus}))
	else:
		meldung(kauf_fehlertext(nm, r))
	panel_neu()
	kopf_neu()
	return r


func kauf_fehlertext(nm: String, r: Dictionary) -> String:
	var f := String(r.get("fehler", "?"))
	var d := fehlbetrag(int(r.get("fehlt_cent", 0)))
	match f:
		"guthaben_reicht_nicht":
			var q: Dictionary = ps.kauf_angebot(nm)
			return text("kauf_geld", {"x": geld(int(q.get("preis_cent", 0))), "d": d})
		"kredit_sperrt_firmenkauf":
			return text("kauf_kredit", {"d": d})
		"besitzer_reserviert", "kein_betrieb":
			return text("kauf_nicht", {"name": nm})
		"kasse_im_minus":
			return text("kauf_minus")
		"schon_gekauft":
			return text("kauf_schon", {"name": nm})
		"bankrott":
			return text("bankrott")
	return text("kauf_sonst", {"code": f})


func ausbau_klick(nm: String) -> void:
	var a: Dictionary = ps.ausbau_angebot(nm)
	if not a.get("ok", false):
		meldung(ausbau_fehlertext(nm, a))
		return
	var frei: int = ps.eco.cash_cent - int(ps.credit.loan_cent)
	if frei < int(a["kosten_cent"]):
		var f := "kredit_sperrt_firmenausbau" if ps.credit.loan_cent > 0 and ps.eco.cash_cent >= int(a["kosten_cent"]) else "guthaben_reicht_nicht"
		meldung(ausbau_fehlertext(nm, {"fehler": f, "fehlt_cent": int(a["kosten_cent"]) - frei}))
		return
	_ausbau_bestaetigen = nm
	panel_neu()


func ausbau_bestaetigt(nm: String) -> Dictionary:
	_ausbau_bestaetigen = ""
	var r: Dictionary = ps.werk_ausbauen(nm)
	if r.get("ok", false):
		meldung(text("ausbau_ok", {"name": nm, "d": r["durchsatz"]}))
	else:
		meldung(ausbau_fehlertext(nm, r))
	panel_neu()
	kopf_neu()
	return r


func ausbau_fehlertext(nm: String, r: Dictionary) -> String:
	var f := String(r.get("fehler", "?"))
	match f:
		"guthaben_reicht_nicht":
			var a: Dictionary = ps.ausbau_angebot(nm)
			return text("ausbau_geld", {"x": geld(int(a.get("kosten_cent", 0))), "d": fehlbetrag(int(r.get("fehlt_cent", 0)))})
		"kredit_sperrt_firmenausbau":
			return text("ausbau_kredit", {"d": fehlbetrag(int(r.get("fehlt_cent", 0)))})
		"nicht_im_besitz":
			return text("ausbau_vor_kauf", {"name": nm})
		"hoechste_stufe":
			return text("ausbau_max", {"name": nm})
		"nur_verarbeiter":
			return text("ausbau_roh", {"name": nm})
		"kasse_im_minus":
			return text("kauf_minus")
		"bankrott":
			return text("bankrott")
	return text("kauf_sonst", {"code": f})


# ------------------------------------------------------------------ FZ-04 Fahrzeugkarte (W5)

var _verkauf_bestaetigen := -1       # vid mit offener Verkaufsbestätigung

## Knopfzeile [Fuhrwerk n] je Fahrzeug einer Linie: öffnet die Fahrzeugkarte.
func _fz_knoepfe(liste: Array) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	for f in liste:
		var b := _knopf("F%d" % int(f["vid"]), "fz_%d" % int(f["vid"]), fahrzeug_oeffnen.bind(int(f["vid"])))
		b.tooltip_text = "%s: Karte mit Alter, Unterhalt, Ersetzen" % f["name"]
		hb.add_child(b)
	return hb


func fahrzeug_oeffnen(vid: int) -> void:
	_verkauf_bestaetigen = -1
	oeffnen("#%d" % vid)


func _stationsname(knoten: int) -> String:
	for nm in ps.stationen:
		if int(ps.stationen[nm]["knoten"]) == knoten:
			return nm
	return "?"


func _panel_fahrzeug(vid: int) -> void:
	var f: Dictionary = ps.fahrzeug(vid)
	var kopf := HBoxContainer.new()
	var von := _stationsname(int(f.get("von", -1)))
	var nach := _stationsname(int(f.get("nach", -1)))
	var gut := ausgang(site_of(von)).capitalize() if site_of(von) >= 0 else ""
	var d: Dictionary = ps.vdef(String(f.get("def_id", "")))
	var titel := _label("%s (%s)" % [f.get("name", "?"), gut], 18)
	titel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kopf.add_child(titel)
	kopf.add_child(_knopf("x", "schliessen", func(): oeffnen(von)))
	panel_vb.add_child(kopf)
	panel_vb.add_child(_label("%s · Linie %s → %s" % [String(d.get("name", "?")), von, nach], 16, C_GRAU))
	if f.is_empty() or f["verkauft"]:
		panel_vb.add_child(_label("Verkauft, steht still.", 16, C_GRAU))
		panel_werte["verkauft"] = true
		return
	var alter: int = ps.alter_jahre(f)
	var ld := int(d.get("lebensdauer_jahre", 0))
	var pct := alter * 100 / maxi(1, ld)
	panel_werte["alter_jahre"] = alter
	panel_werte["lebensdauer_pct"] = pct
	var hb := HBoxContainer.new()
	hb.add_child(_label("Alter %d J von %d J · %d %%" % [alter, ld, pct], 16, C_BAD if pct >= 100 else (C_WARN if pct >= 80 else C_TEXT)))
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = mini(100, pct)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(90, 14)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(bar)
	panel_vb.add_child(hb)
	var fe: int = ps.fix_eff(f)
	var fix := int(f.get("fix_cent", 0))
	var aufschlag := (fe - fix) * 100 / maxi(1, fix)
	panel_werte["unterhalt"] = fe
	panel_werte["aufschlag_pct"] = aufschlag
	panel_vb.add_child(_label("Unterhalt %s/min (+%d %% durch Alter)" % [geld(fe), aufschlag], 16))
	panel_werte["restwert"] = ps.restwert(f)
	_trenner()
	var defs: Array = [String(f["def_id"])]
	for id in ["frachtwagen_e1"]:                          # FZ-05: Folgemodell, sobald verfügbar
		if id != String(f["def_id"]) and not ps.vdef(id).is_empty() and ps.kalenderjahr() >= int(ps.vdef(id).get("verfuegbar_ab_jahr", 9999)):
			defs.append(id)
	for id in defs:
		var q: Dictionary = ps.ersetzen_angebot(vid, id)
		if not q.get("ok", false):
			continue
		var nm := String(ps.vdef(id).get("name", id))
		panel_werte["ersetzen_" + id] = q
		panel_vb.add_child(_label("Ersetzen durch %s: Restwert %s · neu %s · spart %s/min" % [nm, geld(q["restwert_cent"]),
			geld(q["preis_cent"]), geld(q["spart_cent_pro_periode"])], 16))
		if int(q["spart_cent_pro_periode"]) <= 0 and id == String(f["def_id"]):
			panel_vb.add_child(_label("▲ " + text("ersetzen_nichts", {"z": geld(q["spart_cent_pro_periode"])}), 15, C_WARN))
		var b := _knopf("Ersetzen%s · %s" % ["" if id == String(f["def_id"]) else " durch " + nm, geld(q["netto_cent"])],
			"ersetzen_" + id, ersetzen.bind(vid, id), false, not bool(q["kaufbar"]))
		if not bool(q["kaufbar"]):
			b.tooltip_text = "Es fehlen %s." % fehlbetrag(int(q["netto_cent"]) - ps.eco.cash_cent)
		panel_vb.add_child(b)
	_trenner()
	if _verkauf_bestaetigen == vid:
		var hv := HBoxContainer.new()
		hv.add_child(_label("Verkaufen? Die Ladung verfällt.", 16, C_WARN))
		hv.add_child(_knopf("Verkaufen · +%s" % geld(ps.restwert(f)), "verkaufen_ok", verkaufen.bind(vid)))
		hv.add_child(_knopf("Behalten", "verkaufen_ab", func():
			_verkauf_bestaetigen = -1
			panel_neu()))
		panel_vb.add_child(hv)
	else:
		panel_vb.add_child(_knopf("Verkaufen · +%s" % geld(ps.restwert(f)), "verkaufen", func():
			_verkauf_bestaetigen = vid
			panel_neu()))


func ersetzen(vid: int, def_id: String) -> Dictionary:
	var f: Dictionary = ps.fahrzeug(vid)
	var fa: int = ps.fix_eff(f) if not f.is_empty() else 0
	var r: Dictionary = ps.fahrzeug_ersetzen(vid, def_id)
	if r.get("ok", false):
		meldung(text("ersetzt", {"n": f["name"], "x": geld(int(r["netto_cent"])), "y": geld(ps.fix_eff(f)), "z": geld(fa)}))
	else:
		meldung(fz_fehlertext(f, r))
	panel_neu()
	kopf_neu()
	return r


func verkaufen(vid: int) -> Dictionary:
	_verkauf_bestaetigen = -1
	var f: Dictionary = ps.fahrzeug(vid)
	var r: Dictionary = ps.fahrzeug_verkaufen(vid)
	if r.get("ok", false):
		var rest := linien_fahrzeuge(_stationsname(int(f["von"])), _stationsname(int(f["nach"]))).size()
		meldung(text("verkauft", {"n": f["name"], "r": geld(int(r["restwert_cent"])), "k": rest}))
	else:
		meldung(fz_fehlertext(f, r))
	panel_neu()
	kopf_neu()
	return r


func fz_fehlertext(f: Dictionary, r: Dictionary) -> String:
	var fe := String(r.get("fehler", "?"))
	match fe:
		"guthaben_reicht_nicht":
			var q: Dictionary = ps.ersetzen_angebot(int(f.get("vid", -1)))
			return text("ersetzen_geld", {"x": geld(int(q.get("netto_cent", 0))), "d": fehlbetrag(int(r.get("fehlt_cent", 0)))})
		"noch_nicht_verfuegbar":
			return text("frachtwagen_1830")
		"ladung_zu_gross":
			return text("ladung_zu_gross", {"n": f.get("name", "?")})
		"bankrott":
			return text("bankrott")
	return text("fz_sonst", {"code": fe})


# ------------------------------------------------------------------ AT-10 Linienliste (W4, Szenario i: ohne Sortieren)

func _baue_links() -> void:
	links_vb = VBoxContainer.new()
	links_vb.name = "LinkeSpalte"
	links_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	links_vb.anchor_top = 1.0
	links_vb.anchor_bottom = 1.0
	links_vb.offset_left = 12.0
	links_vb.offset_bottom = -12.0
	links_vb.grow_vertical = Control.GROW_DIRECTION_BEGIN
	links_vb.add_theme_constant_override("separation", 8)
	add_child(links_vb)
	linien_panel = PanelContainer.new()
	linien_panel.name = "Linienliste"
	linien_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	linien_panel.add_theme_stylebox_override("panel", _stil(Color(0.1, 0.09, 0.08, 0.88), 10))
	linien_panel.custom_minimum_size = Vector2(LINIEN_B, 0)
	linien_panel.size = Vector2(LINIEN_B, 0)
	linien_panel.visible = false
	links_vb.add_child(linien_panel)
	linien_vb = VBoxContainer.new()
	linien_vb.add_theme_constant_override("separation", 3)
	linien_panel.add_child(linien_vb)


## Sättigung einer Linie am Ziel (nur Orte): economy.saett_linie mit den Einheiten der letzten Minute
## (diese Linie, andere Linien zum selben Ort zuerst). {} wenn das Ziel kein Ort ist.
func linie_saettigung(k: String) -> Dictionary:
	var z: Dictionary = statistik.linien[k]
	var e = ps.eco
	var ziel: int = e.site_of_node(int(z["nach"]))
	var quelle: int = e.site_of_node(int(z["von"]))
	if ziel < 0 or e.s_kind[ziel] != Economy.K_STADT or quelle < 0:
		return {}
	var g: int = e.s_out_good[quelle]
	var andere := 0
	for k2 in statistik.linien:
		var z2: Dictionary = statistik.linien[k2]
		if k2 != k and int(z2["nach"]) == int(z["nach"]) and e.s_out_good[e.site_of_node(int(z2["von"]))] == g:
			andere += int(z2["units"])
	return e.saett_linie(ziel, quelle, g, int(z["units"]), andere)


func linien_neu() -> void:
	if linien_vb == null or not _sim_ok():
		return
	_leeren(linien_vb)
	_bereich_leeren("linien")
	linien_werte = {}
	var gruppen := {}                                         # aktuelle Linien (auch ohne volle Minute)
	for f in ps.fahrzeuge:
		if f["verkauft"] or int(f.get("kauf_cent", 0)) <= 0:
			continue
		var k: String = statistik.schluessel(int(f["von"]), int(f["nach"]))
		if not gruppen.has(k):
			gruppen[k] = []
		gruppen[k].append(f)
	linien_panel.visible = not gruppen.is_empty()
	if gruppen.is_empty():
		return
	linien_vb.add_child(_label("Linien (Netto der letzten Minute)", 16, C_GRAU))
	for k in gruppen:
		var fz: Array = gruppen[k]
		var von := _stationsname(int(fz[0]["von"]))
		var nach := _stationsname(int(fz[0]["nach"]))
		var gut := ausgang(site_of(von)).capitalize()
		var alter := 0
		var fix := 0
		for f in fz:
			alter = maxi(alter, ps.alter_jahre(f))
			fix += ps.fix_eff(f)
		var w := {"alter": alter, "fix": fix, "n": fz.size()}
		linien_vb.add_child(_label("%s → %s (%s) · %d Fuhrwerk(e)" % [von, nach, gut, fz.size()], 16))
		var zeile := ""
		var farbe := C_TEXT
		if statistik.linien.has(k):
			var z: Dictionary = statistik.linien[k]
			w["gewinn"] = int(z["gewinn"])
			w["ertrag"] = int(z["ertrag"])
			w["fahrk"] = int(z["fahrk"])
			var gw: int = z["gewinn"]
			zeile = "Netto %s%s/min" % ["+" if gw > 0 else "", geld(gw)]
			farbe = C_BAD if gw < 0 else C_TEXT
		else:
			zeile = "Netto — $/min"
		zeile += " · Unterhalt %s/min · Alter %d J" % [geld(fix), alter]
		var sz := ""
		var sfarbe := C_TEXT
		if statistik.linien.has(k):
			var sa := linie_saettigung(k)
			if sa.get("ok", false):
				w["v_promille"] = int(sa["v_promille"])
				w["ampel"] = int(sa["ampel"])
				w["x_cent"] = int(sa["x_cent"])
				var pct: int = Economy.rdiv(int(sa["v_promille"]), 10)
				if int(sa["ampel"]) >= 1:
					sz = "%s %s %d %% · +%s/min nur mit neuem Abnehmer" % ["■" if int(sa["ampel"]) >= 2 else "▲", nach, pct, geld(int(sa["x_cent"]))]
					sfarbe = C_BAD if int(sa["ampel"]) >= 2 else C_WARN
				else:
					sz = "● %s %d %%" % [nach, pct]
		linien_vb.add_child(_label(zeile, 15, farbe))
		if sz != "":
			linien_vb.add_child(_label(sz, 15, sfarbe))
		var hb := _fz_knoepfe_bereich(fz, "linien")
		var preis := int(fuhrwerk_def().get("kauf_cent", 0))
		hb.add_child(_knopf("+ Fuhrwerk %s" % geld(preis), "lplus_" + k, fuhrwerk_kaufen.bind(von, nach), false, preis > ps.eco.cash_cent, "linien"))
		linien_vb.add_child(hb)
		linien_werte[k] = w
	_umbrechen(linien_vb)


func _fz_knoepfe_bereich(liste: Array, bereich: String) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	for f in liste:
		var b := _knopf("F%d" % int(f["vid"]), "l_fz_%d" % int(f["vid"]), fahrzeug_oeffnen.bind(int(f["vid"])), false, false, bereich)
		b.tooltip_text = "%s: Karte mit Alter, Unterhalt, Ersetzen" % f["name"]
		hb.add_child(b)
	return hb


## Labels in einem Container umbrechen lassen (feste Breite des Elternpanels statt Überlauf).
func _umbrechen(c: Node) -> void:
	for k in c.get_children():
		if k is Label:
			(k as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


# ------------------------------------------------------------------ AT-11 A-08-Diagnosen (nur Welt)

const WARTE_TICKS := 300               # 30 s an der Quelle ohne Ladung
const KASSE_WARN_S := 90.0             # A5: Warnschwelle 90 s (Design §2.5)
var _warte: Dictionary = {}            # vid -> Ticks am Stück im Zustand „wartet auf Ladung“
var _halb: Dictionary = {}             # vid -> Abfahrten am Stück mit < 50 % Ladung
var _st_vor: Dictionary = {}           # vid -> Zustand im letzten Tick
var _diag: Dictionary = {}             # Schlüssel -> true, solange der Fall besteht (Flanke: nur beim Eintritt melden)
var _lic_ev_idx := 0
var _ld_idx := 0
var netto_verlauf: Array = []          # Netto der letzten Minuten (Cent), für die Kassenprognose
var diag_log: Array = []               # [{fall, titel, text}] ausgelöste Diagnosen (Test)


func _warte_zaehlen() -> void:
	for f in ps.fahrzeuge:
		if f["verkauft"]:
			continue
		var vid := int(f["vid"])
		var i: int = ps.sim.slot_of(vid)
		var st: int = ps.sim.v_state[i]
		if st == 3:                                       # SimWorld.S_WARTET_LADUNG (core/sim_world.gd)
			_warte[vid] = int(_warte.get(vid, 0)) + 1
		else:
			_warte[vid] = 0
		# Teilladung (OE-01 Ersatz-Vorschlag): Abfahrt an der Quelle mit < 50 % Ladung, 3 Umläufe am Stück
		if int(_st_vor.get(vid, -1)) == 3 and st == 1 and ps.sim.v_leg[i] == 0:
			if ps.sim.v_cargo[i] * 1000 < ps.sim.v_cargo_cap[i] * 500:
				_halb[vid] = int(_halb.get(vid, 0)) + 1
			else:
				_halb[vid] = 0
		_st_vor[vid] = st


func _netto_verlauf_neu() -> void:
	if hud_werte.has("netto") or _schnapp.size() == 2:
		kopf_neu()
	if hud_werte.has("netto"):
		netto_verlauf.append(int(hud_werte["netto"]))
		while netto_verlauf.size() > 2:
			netto_verlauf.pop_front()


func _diag_melden(fall: String, schluessel: String, titel: String, t: String, aktion: String, aktion_id: String, daten, form := "warn") -> void:
	if _diag.get(schluessel, false):
		return
	_diag[schluessel] = true
	diag_log.append({"fall": fall, "titel": titel, "text": t})
	melden(t, {"titel": titel, "aktion": aktion, "aktion_id": aktion_id, "daten": daten, "form": form})


func _diag_ende(schluessel: String) -> void:
	_diag.erase(schluessel)


func _ware_ort(site: int) -> String:
	var e = ps.eco
	for g in e.g_ids.size():
		if String(e.g_cat[g]) in ort_korb(site):
			return String(e.g_ids[g]).capitalize()
	return "Ware"


## Diagnosen prüfen. periode_ende: Fälle, die an der Minute hängen (Sättigung, Verlust, Kasse).
func diagnose(periode_ende: bool) -> void:
	var e = ps.eco
	# D1 wartet auf Ladung (> 30 s); ohne Lizenz an der Quelle stattdessen „Lizenz abgelaufen“
	for f in ps.fahrzeuge:
		if f["verkauft"] or int(f.get("kauf_cent", 0)) <= 0:
			continue
		var w: int = _warte.get(f["vid"], 0)
		var quelle := _stationsname(int(f["von"]))
		var sq := site_of(quelle)
		var key := "wartet_%d" % int(f["vid"])
		if w >= WARTE_TICKS:
			if sq >= 0 and not lizenz_ok(sq):
				_diag_melden("D1b", "lizenz_ab_%d" % sq, quelle, text("d_lizenz_ab", {"x": geld(int(e.licence_quote(sq, false).get("kosten_cent", 0)))}),
					"Erneuern", "lizenz", quelle, "bad")
			else:
				_diag_melden("D1", key, quelle, text("d_wartet", {"n": f["vid"], "t": w / 10, "x": e.s_rate[sq] if sq >= 0 else 0}),
					"Zur Linie", "panel", quelle)
		elif int(_halb.get(f["vid"], 0)) >= 3 and sq >= 0:
			_diag_melden("D1", key, quelle, text("d_halb", {"n": f["vid"], "x": e.s_rate[sq]}), "Zur Linie", "panel", quelle)
		elif w == 0 and int(_halb.get(f["vid"], 0)) == 0:
			_diag_ende(key)
	# D4 Lizenz endet < 3 min und die Kasse reicht nicht für die Verlängerung; D4b Verlängerung gescheitert (lic_events)
	while _lic_ev_idx < e.lic_events.size():
		var ev: Dictionary = e.lic_events[_lic_ev_idx]
		_lic_ev_idx += 1
		if not bool(ev.get("ok", true)):
			var nm := _stationsname(int(e.s_node[int(ev["site"])]))
			_diag.erase("lizenz_ab_%d" % int(ev["site"]))
			_diag_melden("D4b", "lizenz_ab_%d" % int(ev["site"]), nm, text("d_lizenz_ab", {"x": geld(int(ev.get("cent", 0)))}), "Erneuern", "lizenz", nm, "bad")
	for nm in ps.stationen:
		var site := int(ps.stationen[nm]["site"])
		if site < 0 or not ist_industrie(site):
			continue
		var key := "lizenz_ende_%d" % site
		if e.licence_valid(site) and not eigen(site):
			var rest: int = e.s_lic_until[site] - ps.sim.tick_count
			var kosten := int(e.licence_quote(site, false).get("kosten_cent", 0))
			if rest < 3 * periode() and e.cash_cent < kosten:
				_diag_melden("D4", key, nm, text("d_lizenz_ende", {"t": lizenz_rest_min(site), "x": geld(kosten)}), "Zum Betrieb", "panel", nm)
			else:
				_diag_ende(key)
		else:
			_diag_ende(key)
		if lizenz_ok(site):
			_diag_ende("lizenz_ab_%d" % site)
	# D6 Lebensdauer erreicht (FZ-03)
	while _ld_idx < ps.lebensdauer_erreicht.size():
		var le: Dictionary = ps.lebensdauer_erreicht[_ld_idx]
		_ld_idx += 1
		var f: Dictionary = ps.fahrzeug(int(le["vid"]))
		if f.is_empty() or f["verkauft"]:
			continue
		var fix := int(f.get("fix_cent", 0))
		var q: Dictionary = ps.ersetzen_angebot(int(le["vid"]))
		_diag_melden("D6", "alt_%d_%d" % [int(le["vid"]), int(le["tick"])], String(f["name"]), text("d_alt", {"j": ps.alter_jahre(f),
			"p": (ps.fix_eff(f) - fix) * 100 / maxi(1, fix), "z": geld(int(q.get("spart_cent_pro_periode", 0)))}), "Ersetzen", "fahrzeug", int(le["vid"]))
	if not periode_ende:
		return
	# D2/D3 Sättigung am Ort (V der eben beendeten Minute): gelb ≥ 100 %, rot ≥ 150 %
	for site in statistik.ort_v:
		var v: int = statistik.ort_v[site][-1]
		var nm := _stationsname(int(e.s_node[site]))
		var p := Economy.rdiv(v, 10)
		if v >= 1500:
			_diag_ende("gelb_%d" % site)
			var x := 0
			for k in statistik.linien:
				if int(statistik.linien[k]["nach"]) == int(e.s_node[site]):
					x += int(linie_saettigung(k).get("x_cent", 0))
			_diag_melden("D3", "rot_%d" % site, nm, text("d_rot", {"ort": nm, "ware": _ware_ort(site), "p": p, "x": geld(x)}), "Zum Ort", "panel", nm, "bad")
		elif v >= 1000:
			_diag_ende("rot_%d" % site)
			_diag_melden("D2", "gelb_%d" % site, nm, text("d_gelb", {"ort": nm, "ware": _ware_ort(site), "p": p}), "Zum Ort", "panel", nm)
		else:
			_diag_ende("gelb_%d" % site)
			_diag_ende("rot_%d" % site)
	# D5 Linie mit Verlust über 3 Minuten
	for k in statistik.linien:
		var z: Dictionary = statistik.linien[k]
		var key: String = "verlust_" + k
		if statistik.verlust_serie(k) >= 3:
			var von := _stationsname(int(z["von"]))
			_diag_melden("D5", key, "%s → %s" % [von, _stationsname(int(z["nach"]))], text("d_verlust", {"x": geld(-int(z["gewinn"])),
				"a": geld(int(z["fix"])), "b": geld(int(z["ertrag"]))}), "Zur Linie", "panel", von, "bad")
		elif int(z["gewinn"]) >= 0:
			_diag_ende(key)
	_kasse_pruefen()


## D7 Kasse reicht ≤ 90 s (Prognose: Kasse ÷ Verlust je Sekunde aus den letzten 2 Minuten). Warnung bleibt stehen (G2).
func _kasse_pruefen() -> void:
	var e = ps.eco
	var posten := ""
	var schlecht := 1 << 40
	for k in statistik.linien:
		if int(statistik.linien[k]["gewinn"]) < schlecht:
			schlecht = int(statistik.linien[k]["gewinn"])
			posten = "%s → %s" % [_stationsname(int(statistik.linien[k]["von"])), _stationsname(int(statistik.linien[k]["nach"]))]
	var reicht := INF
	if not netto_verlauf.is_empty():
		var mittel := 0.0
		for n in netto_verlauf:
			mittel += float(n)
		mittel /= netto_verlauf.size()
		if mittel < 0.0:
			reicht = maxf(0.0, float(e.cash_cent)) / (-mittel / 60.0)
	hud_werte["kasse_reicht_s"] = reicht
	if reicht <= KASSE_WARN_S and posten != "":
		if _diag.get("kasse", false):
			return
		var t := ""
		var aktion := "Zur Linie"
		var aid := "panel"
		var daten: Variant = posten.get_slice(" → ", 0)
		if ps.sim.tick_count < int(ps.credit.from_ticks):
			t = text("d_kasse_vor12", {"posten": posten, "x": geld(-schlecht)})
		elif ps.credit.borrow_amount(ps.sim.tick_count) > 0:
			t = text("d_kasse_kredit", {"posten": posten})
			aktion = "Kredit"
			aid = "kredit"
		else:
			t = text("d_kasse_voll", {"posten": posten})
		_diag["kasse"] = true
		var titel := "Kasse reicht ~%d s" % int(reicht)
		diag_log.append({"fall": "D7", "titel": titel, "text": t})
		melden(t, {"titel": titel, "aktion": aktion, "aktion_id": aid, "daten": daten, "form": "bad", "warn": "kasse"})
	elif _diag.get("kasse", false) and reicht > KASSE_WARN_S:
		_diag.erase("kasse")
		toast_panel.warnung_aufheben("kasse")
		melden(text("d_kasse_gut", {"posten": posten}), {"titel": "Kasse", "form": "ok"})


## Aktion im Diagnose-Toast (Szenario i: kein Kamerasprung, die Aktion öffnet Panel/Karte oder kauft).
func _toast_aktion(id: String, daten: Variant) -> void:
	klicks += 1
	match id:
		"panel":
			oeffnen(String(daten))
		"lizenz":
			oeffnen(String(daten))
			lizenz_kaufen(String(daten))
		"fahrzeug":
			fahrzeug_oeffnen(int(daten))
		"kredit":
			kredit_aufnehmen()
