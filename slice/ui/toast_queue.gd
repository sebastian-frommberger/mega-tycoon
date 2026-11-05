extends PanelContainer
## S8 AT-11 (Mira): Toast-Queue. Eine Meldung zugleich (G2), danach die nächste; nichts wird überschrieben oder verworfen.
## Jede gezeigte Meldung landet im Protokoll. Diagnose-Toast (A-08): Titel = Ort (≤ 30 Z.), Text (≤ 90 Z.), eine Aktion
## (≤ 20 Z.) als Knopf. Warnungen (Schlüssel `warn`) bleiben stehen, bis warnung_aufheben(warn) kommt.
## Zeit: weiter(delta) aus _process; Tests rufen weiter() mit festen Schritten (keine Wanduhr).
## Nur Welt-UI (proto/ui_welt.gd). main._toast ist gesperrt und nutzt diese Queue nicht.

signal aktion_geklickt(id: String, daten: Variant)

const MIN_S := 4.0
const MAX_S := 10.0
const S_JE_ZEICHEN := 0.06

var queue: Array = []                # wartende Meldungen
var aktuell: Dictionary = {}         # gezeigte Meldung, {} = keine
var protokoll: Array = []            # [{titel, text, gezeigt_ms}] alle gezeigten (auch die aktuelle, beim Anzeigen)
var rest := 0.0
var _titel: Label
var _text: Label
var _knopf: Button
var _zu: Button
var _zaehler: Label


func _init() -> void:
	name = "ToastQueue"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.07, 0.06, 0.92)
	sb.set_content_margin_all(10)
	sb.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vb)
	var kopf := HBoxContainer.new()
	kopf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(kopf)
	_titel = _lbl(18)
	_titel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kopf.add_child(_titel)
	_zaehler = _lbl(15)
	_zaehler.add_theme_color_override("font_color", Color(0.62, 0.58, 0.52))
	kopf.add_child(_zaehler)
	_zu = Button.new()
	_zu.text = "x"
	_zu.focus_mode = Control.FOCUS_NONE
	_zu.pressed.connect(naechste)
	kopf.add_child(_zu)
	_text = _lbl(16)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_text)
	_knopf = Button.new()
	_knopf.focus_mode = Control.FOCUS_NONE
	_knopf.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_knopf.pressed.connect(_aktion)
	vb.add_child(_knopf)
	visible = false


func _lbl(gr: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", gr)
	l.add_theme_color_override("font_color", Color(0.96, 0.92, 0.84))
	return l


## Dauer nach Textlänge, 4–10 s (G2).
static func dauer_fuer(t: String) -> float:
	return clampf(MIN_S + t.length() * S_JE_ZEICHEN, MIN_S, MAX_S)


## Meldung anstellen. opts: titel, aktion (Knopftext), aktion_id, daten, dauer, warn (Schlüssel: bleibt bis aufgehoben,
## dieselbe Warnung steht nie doppelt in der Queue), form ("ok"|"warn"|"bad"), sofort (Rückmeldung auf einen Klick).
func melden(t: String, opts: Dictionary = {}) -> void:
	var m := {"text": t, "titel": String(opts.get("titel", "")), "aktion": String(opts.get("aktion", "")),
		"aktion_id": String(opts.get("aktion_id", "")), "daten": opts.get("daten", null),
		"dauer": float(opts.get("dauer", dauer_fuer(t))), "warn": String(opts.get("warn", "")), "form": String(opts.get("form", ""))}
	if m["warn"] != "" and (String(aktuell.get("warn", "")) == m["warn"] or queue.any(func(q): return q["warn"] == m["warn"])):
		return
	if (bool(opts.get("sofort", false)) or m["warn"] != "") and not aktuell.is_empty():   # Warnung: Vorrang (Kasse)
		# Rückmeldung auf eine Spieleraktion: sofort zeigen. Eine laufende Diagnose/Warnung kommt direkt danach wieder,
		# eine einfache Rückmeldung ist schon im Protokoll (nichts geht verloren).
		var alt := aktuell
		queue.push_front(m)
		if String(alt["titel"]) != "" or String(alt["warn"]) != "":
			queue.insert(1, alt)
		naechste()
		return
	queue.append(m)
	if aktuell.is_empty():
		naechste()


func warnung_aufheben(key: String) -> void:
	queue = queue.filter(func(q): return q["warn"] != key)
	if String(aktuell.get("warn", "")) == key:
		naechste()


func naechste() -> void:
	aktuell = {}
	if queue.is_empty():
		visible = false
		return
	aktuell = queue.pop_front()
	protokoll.append({"titel": aktuell["titel"], "text": aktuell["text"], "gezeigt_ms": Time.get_ticks_msec()})
	rest = float(aktuell["dauer"])
	var form: String = {"ok": "● ", "warn": "▲ ", "bad": "■ "}.get(aktuell["form"], "")
	_titel.text = form + String(aktuell["titel"])
	_titel.visible = aktuell["titel"] != "" or form != ""
	_text.text = aktuell["text"]
	_knopf.text = aktuell["aktion"]
	_knopf.visible = aktuell["aktion"] != ""
	_zaehler.text = "+%d" % queue.size() if not queue.is_empty() else ""
	visible = true


## Zeit fortschreiben. Normale Meldung: nach ihrer Dauer die nächste. Warnung: bleibt, solange nichts wartet; wartet etwas,
## stellt sie sich nach ihrer Dauer hinten wieder an (kommt wieder, bis warnung_aufheben).
func weiter(delta: float) -> void:
	if aktuell.is_empty():
		return
	_zaehler.text = "+%d" % queue.size() if not queue.is_empty() else ""
	rest -= delta
	if rest > 0.0:
		return
	if aktuell["warn"] != "":
		if queue.is_empty():
			return
		queue.append(aktuell)
	naechste()


func _process(delta: float) -> void:
	weiter(delta)


func _aktion() -> void:
	var m := aktuell
	aktion_geklickt.emit(String(m.get("aktion_id", "")), m.get("daten", null))
	if String(m.get("warn", "")) == "":
		naechste()


## Text der gezeigten Meldung ("" = keine).
func gezeigt() -> String:
	return String(aktuell.get("text", ""))
