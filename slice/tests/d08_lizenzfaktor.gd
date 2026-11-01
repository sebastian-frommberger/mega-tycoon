extends SceneTree
## D-08: Vorschau-Lizenzfaktor (hq_vorschau.json) gegen den echten Lizenzpreis im Spiel (economy._licence_cost).
## Faktor im Spiel = Kosten / (Kaufpreis Stufe 1 × licence_cost_share). Die Vorschau nennt je Stadt die NÄCHSTE Industrie.
const MainScript := preload("res://main.gd")
var m: Node
func _initialize():
	_run.call_deferred()
func _run():
	var fails := 0
	var checks := 0
	var vor = JSON.parse_string(FileAccess.get_file_as_string("res://data/hq_vorschau.json"))["staedte"]
	for st in ["haberau", "kohlberg", "mittelfurt", "steinbach", "eichwald", "lindach", "weidenau", "seehafen"]:
		if m != null:
			m.free()
		MainScript.core_override = "soa"
		m = load("res://main.tscn").instantiate()
		root.add_child(m)
		await process_frame
		m.place_hq(st)
		# nächste lizenzierbare Industrie mit Ausgangsgut
		var best = null
		var bd := 1e9
		for b in m.buildings:
			if b.is_industry() and b.site >= 0 and m.eco.s_out_good[b.site] >= 0:
				var d: float = m.eco.luftlinie_felder(b.site, m.by_id[st].site)
				if d < bd:
					bd = d
					best = b
		var q: Dictionary = m.licence_quote(best)
		var price: int = m.eco.i_def[m.eco.s_def[best.site]]["kaufpreis_stufe1_cent"]
		var f_game := float(q["kosten_cent"]) / (price * float(m.eco.lic_share) / 1000.0)
		var txt: String = vor[st]["lizenzfaktor"]
		var f_txt := float(txt.split("x")[1].split(" ")[0].replace(",", "."))
		checks += 1
		var same := absf(f_game - f_txt) < 0.015
		if not same:
			fails += 1
		print("  %s %-10s Vorschau %-45s | im Spiel: %s Faktor %.2f (%s %d Felder)" % ["OK  " if same else "FAIL", st, txt, "x%.2f" % f_game, f_game, best.display_name, int(bd)])
	print("%d/%d Vorschau-Lizenzfaktoren stimmen mit dem Spielpreis überein" % [checks - fails, checks])
	quit(0 if fails == 0 else 1)
