extends SceneTree
## F-06 Replay einer Session (Felix 24.11.). Die Sim hat keine Spielerbefehle, Klicks ändern sie nicht.
## Replay = Welt neu bauen, Vorlauf, Start-Prüfsumme vergleichen, Klick-Log Zeile für Zeile an ihrem Tick
## nachfahren (bei meldung_geoeffnet/zeile_klick wird der Schnappschuss neu erzeugt und ausgegeben, also das,
## was der Tester gesehen hat), am Ende Prüfsumme vergleichen.
## Aufruf: godot --headless --path <spike> --script res://f06/f06_replay.gd -- --session=<pfad/session_X.json>

const F06World := preload("res://f06/f06_world.gd")


func _initialize() -> void:
	var sp := ""
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--session="):
			sp = String(a).trim_prefix("--session=")
	var f := FileAccess.open(sp, FileAccess.READ)
	if f == null:
		print("Session-Datei nicht lesbar: %s" % sp)
		quit(2)
		return
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	var w = F06World.new()
	w.build()
	w.vorlauf(int(data["vorlauf_ticks"]))
	var ok: bool = str(w.sim.checksum()) == data["checksum_start"]
	print("Session %s, Tester %s, Reihenfolge %s" % [data["session"], data["tester"], str(data["reihenfolge"])])
	print("Start-Prüfsumme %s" % ("gleich" if ok else "ABWEICHEND"))
	var mel: Dictionary = {}
	for m in data["meldungen"]:
		mel[int(m["meldung_id"])] = int(m["vehicle_id"])
	var lf := FileAccess.open(sp.get_base_dir().path_join(data["klicklog"]), FileAccess.READ)
	var snap: Array = []
	if lf != null:
		var lines: PackedStringArray = lf.get_as_text().strip_edges().split("\n")
		for i in range(1, lines.size()):
			var c: PackedStringArray = lines[i].split(";")
			var tick := int(c[2])
			if tick > w.sim.tick_count:
				w.sim.run_ticks(tick - w.sim.tick_count)
			var line := "  t=%s ms tick %d %s" % [c[1], tick, c[3]]
			if c[3] == "meldung_geoeffnet":
				snap = w.rows_for(w.sim.get_wait_chain(mel[int(c[4])]))
				line += " -> " + w.titel(mel[int(c[4])]) + " (%d Zeilen)" % snap.size()
			elif c[3] == "zeile_klick" and int(c[6]) <= snap.size():
				line += " -> Zeile %s: %s" % [c[6], snap[int(c[6]) - 1]["text"]]
			elif c[7] != "":
				line += " " + c[7]
			print(line)
	w.sim.run_ticks(maxi(0, int(data["tick_ende"]) - w.sim.tick_count))
	var ok2: bool = str(w.sim.checksum()) == data["checksum_ende"]
	print("End-Prüfsumme (Tick %d) %s" % [w.sim.tick_count, "gleich" if ok2 else "ABWEICHEND"])
	quit(0 if ok and ok2 else 1)
