extends SceneTree
## Startmenü + Beispielnetz (Basti, S7, Mira).
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/s7_start_test.gd [-- --shots=<dir>]
## Prüft: Projekt-Hauptszene = start_menu.tscn, Menü baut zwei Karten + Weltzeile, Taste 1 → main.tscn mit HQ-Platzierung
## (wie bisher), Taste 2 → Beispielnetz; Beispielnetz in slice und s7: HQ gegründet, ≥ 3 Linien, kein Fehlschlag beim
## Aufbau, keine Fehlertexte, Sammelhinweis, Einnahmen steigen in 2 weiteren Spielminuten, „Neu starten“ führt ins Menü;
## main.tscn direkt (Tests) zeigt kein Menü und keinen Neustart-Knopf.

const MainScript := preload("res://main.gd")
const MENU := "res://start_menu.tscn"
const Beispielnetz := preload("res://world/beispielnetz.gd")
const Kit := preload("res://ui/ui_kit.gd")
const FEHLERWORTE := ["Es fehlen", "reicht nicht", "Zu steil", "nicht anschließbar", "keine Verbindung", "Brücke geht nur",
	"liegt im Weg", "steht im Weg", "nicht möglich", "Bankrott"]

var fails := 0
var checks := 0
var shots := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			shots = a.substr(8)
			DirAccess.make_dir_recursive_absolute(shots)
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("  OK   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	if shots == "":
		return
	await _frames(10)
	root.get_viewport().get_texture().get_image().save_png(shots.path_join(name))
	print("  shot ", name)


func _key(k: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.pressed = true
	root.push_input(ev)


## Menü als aktuelle Szene laden (wie beim Projektstart) und warten.
func _menu() -> Node:
	change_scene_to_file(MENU)
	await _frames(3)
	return current_scene


func _run() -> void:
	ok(str(ProjectSettings.get_setting("application/run/main_scene")) == MENU, "Projekt-Hauptszene ist das Startmenü")
	# --- Menü
	MainScript.world_override = ""
	MainScript.start_mode = ""
	var mn := await _menu()
	ok(mn != null and mn.name == "StartMenu" and mn.karten.size() == 2, "Menü: zwei Karten")
	var txt := ""
	for b in mn.karten:
		for c in _all(b):
			if c is Label:
				txt += c.text + "|"
	ok(txt.contains("Gründe dein Unternehmen, wo du willst.") and txt.contains("sieh, wie Farm, Mühle und Stadt zusammenhängen"),
		"Menü: Erklärzeilen beider Karten")
	ok(mn.welt_label.text.contains("Slice"), "Menü: Weltzeile zeigt aktive Welt („%s“)" % mn.welt_label.text)
	await _shot("menu.png")
	_key(KEY_W)
	await _frames(1)
	ok(mn.welt == "s7" and mn.welt_label.text.contains("S7"), "Menü: W wechselt auf S7")
	_key(KEY_W)
	await _frames(1)
	# --- Taste 1: Neues Spiel wie bisher
	_key(KEY_1)
	await _frames(4)
	var m: Node = current_scene
	ok(m != null and m.get_script() == MainScript and MainScript.start_mode == "neu", "Taste 1 → main.tscn, Modus neu")
	ok(not m.company_started and m.hq.mode == m.hq.Mode.PLACING and m.welt == "slice", "Neues Spiel: HQ-Platzierung aktiv, Slice")
	ok(m.find_child("NeuStarten", true, false) == null, "Neues Spiel: kein Neustart-Knopf (Kopfleiste wie bisher)")
	# --- Taste 2 (über Enter nach Markieren): Beispielnetz je Welt
	for w in ["slice", "s7"]:
		mn = await _menu()
		mn.welt = w
		mn._markiere(1)
		_key(KEY_ENTER)
		await _frames(6)
		m = current_scene
		await _beispiel(m, w)
	# --- main.tscn direkt (Testweg): kein Menü, kein Beispiel
	MainScript.start_mode = ""
	MainScript.world_override = ""
	change_scene_to_file("res://main.tscn")
	await _frames(4)
	m = current_scene
	ok(m.get_script() == MainScript and not m.company_started and m.find_child("NeuStarten", true, false) == null
		and m.beispiel_report.is_empty(), "main.tscn direkt: kein Menü, kein Beispielnetz, keine Gründung")
	MainScript.world_override = ""
	print("%d/%d Prüfungen OK" % [checks - fails, checks])
	quit(0 if fails == 0 else 1)


func _beispiel(m: Node, w: String) -> void:
	ok(m != null and m.get_script() == MainScript and m.welt == w and MainScript.start_mode == "beispiel", "[%s] Enter → Beispielnetz" % w)
	var rep: Dictionary = m.beispiel_report
	ok(not rep.is_empty() and rep["fehler"].is_empty(), "[%s] Aufbau ohne Fehlschlag %s" % [w, str(rep.get("fehler", "kein Bericht"))])
	ok(m.company_started and m.hq_city != null and m.hq_city.map_id == "haberau", "[%s] HQ Haberau gegründet" % w)
	ok(m.line_groups.size() >= 3, "[%s] %d Linien (≥ 3), %d Fahrzeuge" % [w, m.line_groups.size(), m.fleet_size()])
	var bad := []
	for t in m.toast_log:
		for fw in FEHLERWORTE:
			if str(t).contains(fw):
				bad.append(t)
	ok(bad.is_empty(), "[%s] keine Fehlertexte beim Aufbau (%d Toasts) %s" % [w, m.toast_log.size(), str(bad)])
	ok(m.toast_label.text == Kit.txt(Beispielnetz.HINWEIS) and m.next_step_label.text.contains("Beispielnetz"),
		"[%s] Sammelhinweis im Toast und in der Zielleiste" % w)
	var done := 0
	for ms in m.milestones:
		if ms["done"]:
			done += 1
	print("  INFO [%s] Ziele %d/%d, Kasse %s, Einnahmen %s, Zeit %s" % [w, done, m.milestones.size(), m.money_str(m.eco.cash_cent),
		m.money_str(m.eco.revenue_total), m.time_str(m.shim.tick_count)])
	ok(m.speed == 1 and not m.bankrupt, "[%s] Spielzeit läuft (Tempo 1)" % w)
	await _shot("beispiel_%s.png" % w)
	var rev0: int = m.eco.revenue_total
	m.run_ticks(2 * m.month_ticks)
	ok(m.eco.revenue_total > rev0, "[%s] Einnahmen in 2 Spielminuten: +%s" % [w, m.money_str(m.eco.revenue_total - rev0)])
	var rb: Button = m.find_child("NeuStarten", true, false)
	ok(rb != null and rb.is_visible_in_tree(), "[%s] Knopf „Neu starten“ in der Kopfleiste" % w)
	if rb != null:
		var r: Rect2 = rb.get_global_rect()
		var tempo: Rect2 = m.speed_buttons[0][1].get_global_rect()
		ok(r.end.x <= tempo.position.x and r.position.x >= m.hud_vals["zeit"].get_global_rect().end.x,
			"[%s] Neu starten passt zwischen Uhr und Tempo (%.0f–%.0f px)" % [w, r.position.x, r.end.x])
		rb.pressed.emit()
		await _frames(3)
		ok(current_scene != null and current_scene.name == "StartMenu", "[%s] Neu starten → Startmenü" % w)


func _all(n: Node) -> Array:
	var out := [n]
	for c in n.get_children():
		out.append_array(_all(c))
	return out
