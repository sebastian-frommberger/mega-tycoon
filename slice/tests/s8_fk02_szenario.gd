extends SceneTree
## S8 FK-02 (Tobias): Skript-Szenario Mühlenkauf auf der Proto-Welt, KEIN Bot (eine feste Spielweise, n = 1, deterministisch).
## Misst Netto-$/min vor/nach dem Kauf, Amortisation und die Schneeball-Kennzahl, bis QT-03 (Bot) die Verteilung liefert.
##   godot --headless --path slice -s res://tests/s8_fk02_szenario.gd -- [--tempo_k=4] [--kauf_min=15] [--extra=N]
## --extra=N: ab kauf_min in BEIDEN Varianten N weitere Fuhrwerke (abwechselnd Hasenwinkel→Mühle, Mühle→Lindenfurt).
## Ablauf beider Varianten bis Minute kauf_min gleich: Lizenz Kuppenhof (gratis) + Mühle, Fuhrwerke Kuppenhof→Mühle,
## Mühle→Erlenbach, Mühle→Lindenfurt. Ab kauf_min: Lizenz Hasenwinkel + Fuhrwerk Hasenwinkel→Mühle + 2. Fuhrwerk
## Mühle→Lindenfurt; Variante KAUF kauft zusätzlich die Mühle und baut sobald möglich auf Stufe 2 aus.
## Overlay economy_proto.json (Puffer-Deckel 2 Perioden) aktiv. Werksunterhalt je Periode hier per konto.charge gebucht
## (ProtoSim verdrahtet ihn noch nicht, Felix FK-02-Anteil).
## Netto je Minute = Δ Kasse + Investitionen der Minute (Fahrzeugkauf, Lizenzkauf/-verlängerung, Werkskauf, Ausbau).

const ProtoSim := preload("res://proto/proto_sim.gd")
const SZENE := "res://proto/prototyp_welt.tscn"
const FARM := "Gut Kuppenhof"
const FARM2 := "Hof Hasenwinkel"
const MUEHLE := "Erlenmühle"
const DORF := "Erlenbach"
const STADT := "Lindenfurt"
const MINUTEN := 45

var szene: Node


func _initialize() -> void:
	_run.call_deferred()


func _arg(name: String, d: int) -> int:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % name):
			return int(a.split("=")[1])
	return d


func _lauf(kaufen: bool, kauf_min: int) -> Dictionary:
	var ps = ProtoSim.new(szene.regelwerk)
	ps.graph_bauen(szene.strassen)
	ps.spiel_starten(JSON.parse_string(FileAccess.get_file_as_string(szene.datei("proto_orte.json"))))
	var e = ps.eco
	e.apply_proto(JSON.parse_string(FileAccess.get_file_as_string("res://data/economy_proto.json")))
	var m: int = int(ps.stationen[MUEHLE]["site"])
	var invest := 0
	ps.lizenz_kaufen(FARM)
	ps.lizenz_kaufen(MUEHLE)
	for l in [[FARM, MUEHLE], [MUEHLE, DORF], [MUEHLE, STADT]]:
		ps.linie_anlegen(l[0], l[1])
	var netto: Array = []
	var kauf_tick := -1
	var ausbau_tick := -1
	var kauf_cent := 0
	var ausbau_cent := 0
	var per: int = e.periode_ticks
	var last_cash: int = e.cash_cent
	var last_inv: int = ps.kauf_total + e.licence_paid_total
	for minute in MINUTEN:
		if minute == kauf_min:
			ps.lizenz_kaufen(FARM2)
			ps.linie_anlegen(FARM2, MUEHLE)
			ps.linie_anlegen(MUEHLE, STADT)
			for x in _arg("extra", 0):
				ps.linie_anlegen(FARM2 if x % 2 == 0 else MUEHLE, MUEHLE if x % 2 == 0 else STADT)
		if kaufen and minute >= kauf_min:
			if e.s_owner[m] == 0:
				var r: Dictionary = e.buy_site(m, ps.konto, ps.credit)
				if r["ok"]:
					kauf_tick = ps.sim.tick_count
					kauf_cent = r["bezahlt_cent"]
			if e.s_owner[m] == 1 and e.s_werksstufe[m] == 1:
				var u: Dictionary = e.upgrade_site(m, ps.konto, ps.credit)
				if u["ok"]:
					ausbau_tick = ps.sim.tick_count
					ausbau_cent = u["bezahlt_cent"]
		for t in per:
			ps.tick()
		var up: int = e.works_upkeep_cent_pro_periode()
		if up > 0:
			ps.konto.charge(up)
		var inv: int = ps.kauf_total + e.licence_paid_total + kauf_cent + ausbau_cent
		netto.append((e.cash_cent - last_cash) + (inv - last_inv))
		last_cash = e.cash_cent
		last_inv = inv
	return {"netto": netto, "kauf_tick": kauf_tick, "ausbau_tick": ausbau_tick, "kauf_cent": kauf_cent, "ausbau_cent": ausbau_cent,
		"kasse": e.cash_cent, "bankrott": ps.konto.bankrupt, "pruef": ps.pruefsumme()}


func _mittel(a: Array, von: int, bis: int) -> float:
	var s := 0.0
	for i in range(von, bis):
		s += a[i]
	return s / float(bis - von) / 100.0


func _run() -> void:
	szene = (load(SZENE) as PackedScene).instantiate()
	szene.set("sim_aus", true)
	root.add_child(szene)
	await process_frame
	var km := _arg("kauf_min", 15)
	var a := _lauf(true, km)
	var b := _lauf(false, km)
	var tk: int = int(ProtoSim.tempo_k_aus(szene.regelwerk))
	print("FK02_SZENARIO tempo_k=%d kauf_min=%d extra=%d Prüfsumme KAUF %d" % [tk, km, _arg("extra", 0), a["pruef"]])
	print("  KAUF: Kauf Tick %d (%d ¢), Ausbau Tick %d (%d ¢), Endkasse %d ¢, bankrott %s" % [a["kauf_tick"], a["kauf_cent"], a["ausbau_tick"], a["ausbau_cent"], a["kasse"], a["bankrott"]])
	print("  OHNE: Endkasse %d ¢, bankrott %s" % [b["kasse"], b["bankrott"]])
	var zeile := "  Netto $/min je Minute KAUF:"
	for x in a["netto"]:
		zeile += " %d" % int(x / 100)
	print(zeile)
	zeile = "  Netto $/min je Minute OHNE:"
	for x in b["netto"]:
		zeile += " %d" % int(x / 100)
	print(zeile)
	var vor := _mittel(a["netto"], km - 5, km)
	var w := [[km, km + 10], [km + 10, km + 20], [km + 20, MINUTEN]]
	for f in w:
		var na := _mittel(a["netto"], f[0], f[1])
		var nb := _mittel(b["netto"], f[0], f[1])
		print("  Minute %d-%d: Netto KAUF %.0f $/min, OHNE %.0f $/min, Differenz %.0f $/min" % [f[0], f[1], na, nb, na - nb])
	# Amortisation: kumulierte Differenz KAUF − OHNE (Netto ohne Investition) erreicht Kaufpreis + Ausbau
	var inv: int = a["kauf_cent"] + a["ausbau_cent"]
	var cum := 0
	var amort := -1
	for i in range(km, MINUTEN):
		cum += int(a["netto"][i]) - int(b["netto"][i])
		if amort < 0 and cum >= inv:
			amort = i + 1 - km
	print("  Amortisation (Kauf + Ausbau %d $): %s min nach Minute %d" % [inv / 100, str(amort) if amort >= 0 else "> %d" % (MINUTEN - km), km])
	var nach := _mittel(a["netto"], km + 5, km + 15)
	print("  Schneeball: Netto KAUF Minute %d-%d %.0f $/min gegen Minute %d-%d %.0f $/min, Faktor %.2f (Grenze: < 2,0 in 10 min)" % [
		km - 5, km, vor, km + 5, km + 15, nach, nach / vor if vor != 0.0 else 0.0])
	quit(0)
