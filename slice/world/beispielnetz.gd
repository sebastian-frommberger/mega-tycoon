extends RefCounted
## Startmenü „Beispielnetz ansehen“ (Basti, S7): baut nach dem Laden der Welt ein laufendes Netz – ausschließlich über
## die Spielfunktionen, die auch ein Spieler auslöst (place_hq = Knopf „HQ hier gründen“, ui_buy_licence = Knopf
## „Lizenz kaufen“, build_track = Straße ziehen, create_line = Linie setzen, run_ticks = Spielzeit). Damit gelten alle
## Regeln (Preise, Brücken, Hang, Stadtanschluss), und das Netz ist gültig und deterministisch.
## Ablauf je Welt als Befehlsliste (Format wie tools/play.sh). S7: Daniels geprüfter Lauf
## sprint7/d/daniel/z/s8/commands.txt (Haberau, Farm 1 → Mühle 1 → Haberau, Mühle 1 → Wiesental, 8 Spielminuten).
## Slice: dieselbe Kette mit Mittelfurt als zweitem Abnehmer (Bestand slice_test/s7_industrie).
## Aufbau still: Toasts werden am Ende durch eine Sammelmeldung ersetzt; Fehlschläge stehen in report["fehler"].

const HINWEIS := "Beispielnetz: Klick auf Farm, Mühle oder Linie, um zu sehen, wie sie zusammenhängen."

const ABLAUF := {
	"s7": [
		["hq", "haberau"],
		["lizenz", "farm_1"], ["strasse", "farm_1", "muehle_1"], ["lkw", "farm_1", "muehle_1"], ["warten", 3],
		["lizenz", "muehle_1"], ["strasse", "muehle_1", "haberau"], ["lkw", "muehle_1", "haberau"],
		["strasse", "muehle_1", "108,335"], ["strasse", "108,335", "133,310"], ["lkw", "muehle_1", "wiesental"],
		["warten", 5],
	],
	"slice": [
		["hq", "haberau"],
		["lizenz", "farm_1"], ["strasse", "farm_1", "muehle_1"], ["lkw", "farm_1", "muehle_1"], ["warten", 3],
		["lizenz", "muehle_1"], ["strasse", "muehle_1", "haberau"], ["lkw", "muehle_1", "haberau"],
		["strasse", "muehle_1", "mittelfurt"], ["lkw", "muehle_1", "mittelfurt"],
		["warten", 5],
	],
}


static func _feld(m, s: String) -> Vector2i:
	if m.by_id.has(s):
		return m.by_id[s].anchor()
	var p := s.split(",")
	return Vector2i(int(p[0]), int(p[1]))


## Baut das Netz. Rückgabe {"fehler": [..], "ids": [beteiligte Gebäude]}.
static func build(m) -> Dictionary:
	var fehler: Array = []
	var ids := {}
	for st in ABLAUF.get(m.welt, ABLAUF["slice"]):
		var ok := true
		match st[0]:
			"hq":
				ok = m.place_hq(st[1])
				ids[st[1]] = true
			"lizenz":
				ok = m.ui_buy_licence(m.by_id[st[1]])
				ids[st[1]] = true
			"strasse":
				ok = m.build_track(_feld(m, st[1]), _feld(m, st[2]), false)
			"lkw":
				ok = m.create_line(m.by_id[st[1]], m.by_id[st[2]], "truck") != null
				ids[st[1]] = true
				ids[st[2]] = true
			"warten":
				m.run_ticks(int(st[1]) * m.month_ticks)
				m.hq.refresh_rule()
		if not ok:
			fehler.append("%s: %s" % [" ".join(PackedStringArray(st.map(func(x): return str(x)))), m.toast_label.text])
	m._check_milestones()
	m._refresh_lines()
	m._refresh_milestones()
	# Kamera: Übersicht über alle beteiligten Gebäude (Abstand ≈ 1,8 × Ausdehnung)
	var r := Rect2()
	var first := true
	for id in ids:
		var p: Vector3 = m.by_id[id].position
		r = Rect2(Vector2(p.x, p.z), Vector2.ZERO) if first else r.expand(Vector2(p.x, p.z))
		first = false
	var span := maxf(maxf(r.size.x, r.size.y), 20.0)
	m.focus(r.get_center() + Vector2(0, span * 0.1), span * 1.8 / 25.6)
	m.set_speed(1)
	m._toast(HINWEIS, 20.0)
	if not fehler.is_empty():
		push_warning("Beispielnetz: " + "; ".join(PackedStringArray(fehler)))
	return {"fehler": fehler, "ids": ids.keys()}
