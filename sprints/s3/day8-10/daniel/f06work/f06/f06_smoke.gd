extends SceneTree
## F-06 Smoke-Test (headless), Felix 24.11. Prüfpunkte nach Daniel/Aylin Abschnitt 6:
##  Szene lädt · 3/3 Meldungen da und auslösbar · validate() leer · jede Kette endet in der Soll-Wurzelzeile ·
##  Zeilenzahl 4/6/5 · Texte ohne Platzhalter, <= 60 Zeichen · Sprung (Kamera am Ziel nach 0,6 s) · Kontur ·
##  Klick-Log schreibt meldung_geoeffnet/zeile_klick mit unix_ms · keine vertragsfehler-Zeile ·
##  3.000 Ticks weiter: Fehler bestehen, Kontrollzüge ohne Meldung · Session-Datei, Replay-Prüfsumme.
## Aufruf: godot --headless --path <spike> --script res://f06/f06_smoke.gd [-- --logdir=<pfad>]
## Script-Fehler zählt run_smoke.sh aus der Konsolenausgabe (Godot bricht bei SCRIPT ERROR nicht ab).

const F06World := preload("res://f06/f06_world.gd")
const Diagnostics := preload("res://diagnostics.gd")

var failures: Array = []
var main


func check(cond: bool, msg: String) -> void:
	print("    [%s] %s" % ["OK" if cond else "FEHLER", msg])
	if not cond:
		failures.append(msg)


func _initialize() -> void:
	_run()


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _run() -> void:
	print("== F-06 Smoke-Test, Godot %s ==" % Engine.get_version_info()["string"])
	var logdir := "user://smoke/"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--logdir="):
			logdir = String(a).trim_prefix("--logdir=")
	var packed: PackedScene = load(ProjectSettings.get_setting("application/run/main_scene"))
	check(packed != null, "Main-Scene %s lädt" % ProjectSettings.get_setting("application/run/main_scene"))
	if packed == null:
		_finish()
		return
	main = packed.instantiate()
	main.opts_override = {"tester": "T1", "logdir": logdir}
	root.add_child(main)
	await process_frame
	await process_frame
	print("Meldungen")
	check(main.meldungen.size() == 3, "3 Meldungen erzeugt (%d)" % main.meldungen.size())
	var keys: Array = main.meldungen.map(func(m): return m["fehler"])
	check(keys == ["F1", "F2", "F3"], "Reihenfolge T1 = F1, F2, F3 (%s)" % str(keys))
	check(main.vertragsfehler == 0, "keine Vertragsfehler beim Erzeugen")
	var soll_wurzel := {"F1": "W_EINGLEISIG", "F2": "W_KREIS", "F3": "W_ZULIEFERUNG"}
	for m in main.meldungen:
		var key: String = m["fehler"]
		var titel: String = main.world.titel(m["vehicle_id"])
		print("  %s Meldung %d: %s · bei %s" % [key, m["meldung_id"], titel, F06World.FEHLER[key]["ort"]])
		check(titel.begins_with("Zug %d steht seit " % m["vehicle_id"]), "%s Titel T_STEHT" % key)
		main.click_meldung(m["meldung_id"])
		check(main.open_id == m["meldung_id"], "%s ausgelöst: Meldung offen (Z2)" % key)
		var rows: Array = main.snap_rows
		for r in rows:
			print("      %d%s %s  [%s %s#%d -> (%d,%d)]" % [r["index"], " WURZEL" if r["wurzel"] else "", r["text"], r["key"], r["kind"], r["id"], r["pos"].x, r["pos"].y])
		check(Diagnostics.validate(main.snap_chain).is_empty(), "%s validate() leer" % key)
		check(rows.size() == F06World.FEHLER[key]["zeilen"], "%s %d Zeilen (Soll %d)" % [key, rows.size(), F06World.FEHLER[key]["zeilen"]])
		check(not rows.is_empty() and rows[-1]["wurzel"] and rows[-1]["key"] == soll_wurzel[key], "%s letzte Zeile = Wurzel %s" % [key, soll_wurzel[key]])
		check(rows[-1]["pos"] == main.snap_chain["root_pos"], "%s Sprungziel Wurzelzeile = root_pos (D9)" % key)
		var ok_txt := true
		for r in rows:
			ok_txt = ok_txt and not String(r["text"]).contains("{") and String(r["text"]).length() <= 60
		check(ok_txt, "%s Texte ohne Platzhalter, <= 60 Zeichen" % key)
		# S3 Tag 4–7: Standzeit Titel == Kettenzeile 1, auch wenn die Sim weiterläuft (600 Ticks)
		main.step_sim(600)
		main.refresh_titles()
		var lab: Label = main._title_labels[m["meldung_id"]]
		check(lab.text == rows[0]["text"], "%s Titel '%s' == Zeile 1 '%s' nach 600 Ticks" % [key, lab.text, rows[0]["text"]])
		# Ort und alle in den Zeilen genannten Abschnitte stehen auf der Karte
		var map_txt: Array = main.world.orts_labels().map(func(x): return x["text"]) + main.world.abschnitt_labels().map(func(x): return x["text"])
		var joined := " | ".join(PackedStringArray(map_txt))
		var missing: Array = []
		if not map_txt.has(F06World.FEHLER[key]["ort"]):
			missing.append(F06World.FEHLER[key]["ort"])
		var rx := RegEx.new()
		rx.compile("Abschnitt (\\d+)")
		for r in rows:
			for mt in rx.search_all(r["text"]):
				var num: String = mt.get_string(1)
				var found := false
				for t in map_txt:
					if String(t).begins_with("Abschnitt ") and (String(t).trim_prefix("Abschnitt ").split("/") as Array).has(num):
						found = true
				if not found:
					missing.append("Abschnitt " + num)
		check(missing.is_empty(), "%s Ort + Abschnitte der Kette auf der Karte beschriftet (fehlt: %s)" % [key, str(missing)])
		await _wait(0.75)
		var want: Vector2 = main._cam_pos_for(main.world_px(rows[0]["pos"]), main.JUMP_ZOOM)
		check(main.cam.position.distance_to(want) < 1.0, "%s beim Öffnen: Kamera an Zeile 1 (%s)" % [key, str(main.cam.position)])
		for r in rows:
			main.click_zeile(r["index"])
		await _wait(0.75)
		var want2: Vector2 = main._cam_pos_for(main.world_px(rows[-1]["pos"]), main.JUMP_ZOOM)
		check(main.cam.position.distance_to(want2) < 1.0 and main.cam.zoom.x == main.JUMP_ZOOM, "%s Zeilenklick: Kamera zentriert auf Wurzel-Ort, Zoom %.1f" % [key, main.cam.zoom.x])
		check(main.contour.get("wurzel", false) and main.selected_row == rows.size(), "%s Kontur an der Wurzel, Zeile %d gewählt (Z3)" % [key, main.selected_row])
		main._on_back()
		check(main.open_id == -1, "%s Zurück zur Übersicht -> Z1" % key)
		await _wait(0.1)
	print("Karte: " + " | ".join(PackedStringArray(main.world.orts_labels().map(func(x): return x["text"]) + main.world.abschnitt_labels().map(func(x): return x["text"]))))
	# geschlossene Meldungen laufen live: Titel nach 100 Ticks = aktuelle Standzeit
	main.step_sim(100)
	main.refresh_titles()
	var live_ok := true
	for m in main.meldungen:
		live_ok = live_ok and main._title_labels[m["meldung_id"]].text == main.world.titel(m["vehicle_id"])
	check(live_ok, "geschlossene Meldungen: Titel = aktuelle Standzeit (laufend)")
	print("Sonstige Klicks")
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = Vector2(5, 1070)
	main._unhandled_input(ev)
	main._on_collapse()
	main._on_badge()
	print("3000 Ticks")
	var bad := 0
	var kontroll_meldung := 0
	for i in range(30):
		main.step_sim(100)
		for m in main.meldungen:
			var c: Dictionary = main.sim.get_wait_chain(m["vehicle_id"])
			if c["root_cause"] != F06World.FEHLER[m["fehler"]]["code"] or not Diagnostics.validate(c).is_empty():
				bad += 1
		for vid in F06World.KONTROLLE:
			var cc: Dictionary = main.sim.get_wait_chain(vid)
			if cc["is_deadlock"] or cc["root_cause"] == "WARTEN_AUF_LADUNG":
				kontroll_meldung += 1
		await process_frame
	check(bad == 0, "alle 3 Fehler bestehen über 3000 Ticks, Ketten gültig (Abweichungen %d)" % bad)
	check(kontroll_meldung == 0, "Kontrollzüge 11/12 ohne Meldung (0 Fehlalarme)")
	check(main.sim.deadlock_events.size() == 2, "genau 2 Deadlock-Ereignisse (F1, F2): %d" % main.sim.deadlock_events.size())
	print("    Tick jetzt %d, F3 fuell_ist %d" % [main.sim.tick_count, main.sim.stations[301]["stock"]])
	print("Klick-Log")
	var path: String = main.klicklog_path
	var session_path: String = main.session_path
	var cs_start: String = str(main._checksum_start)
	main._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)   # schreibt session_ende und Session-Datei
	var f := FileAccess.open(path, FileAccess.READ)
	check(f != null, "Klick-Log vorhanden: %s" % ProjectSettings.globalize_path(path))
	if f != null:
		var lines: PackedStringArray = f.get_as_text().strip_edges().split("\n")
		check(lines[0] == "unix_ms;ms_seit_start;tick;ereignis;meldung_id;vehicle_id;index;ziel", "Kopfzeile nach Aylin Abschnitt 5")
		var counts := {}
		var unix_ok := true
		for i in range(1, lines.size()):
			var cols: PackedStringArray = lines[i].split(";")
			counts[cols[3]] = int(counts.get(cols[3], 0)) + 1
			unix_ok = unix_ok and cols.size() == 8 and cols[0].length() == 13 and cols[0].is_valid_int()
		print("    Ereignisse: %s" % JSON.stringify(counts))
		check(unix_ok, "jede Zeile 8 Spalten, unix_ms 13-stellig")
		check(counts.get("meldung_geoeffnet", 0) == 3, "3x meldung_geoeffnet (t_klick)")
		check(counts.get("zeile_klick", 0) == 15, "15x zeile_klick (4+6+5)")
		check(counts.get("klick_sonstige", 0) >= 1 and counts.get("feed_eingeklappt", 0) == 1 and counts.get("sprung_zurueck", 0) == 3, "klick_sonstige, feed_eingeklappt, sprung_zurueck geloggt")
		check(not counts.has("vertragsfehler"), "keine vertragsfehler-Zeile")
	print("Session/Replay")
	var sf := FileAccess.open(session_path, FileAccess.READ)
	check(sf != null, "Session-Datei vorhanden")
	if sf != null:
		var data: Dictionary = JSON.parse_string(sf.get_as_text())
		check(data.get("abgeschlossen", false) and data.get("checksum_start", "") == cs_start, "Session-Datei abgeschlossen, Prüfsumme Start eingetragen")
		var w = F06World.new()
		w.build()
		w.vorlauf()
		check(str(w.sim.checksum()) == data["checksum_start"], "Replay: neu gebaute Welt hat dieselbe Start-Prüfsumme")
		w.sim.run_ticks(int(data["tick_ende"]) - w.sim.tick_count)
		check(str(w.sim.checksum()) == data["checksum_ende"], "Replay: Prüfsumme am Ende (Tick %d) identisch" % int(data["tick_ende"]))
	_finish()


func _finish() -> void:
	if failures.is_empty():
		print("SMOKE: ALLE PRUEFPUNKTE GRUEN (Exit 0)")
		quit(0)
	else:
		print("SMOKE: %d FEHLER (Exit 1)" % failures.size())
		for x in failures:
			print("  - " + x)
		quit(1)
