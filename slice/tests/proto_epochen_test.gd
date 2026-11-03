extends SceneTree
## Phase 4 Welle 1 (Felix), Messprotokoll P7: „Startjahr 1850 statt 1820 ändert nur Werte aus epochen/startjahr_hebel,
## kein Code-Pfad“. Headless:  godot --headless --path slice -s res://tests/proto_epochen_test.gd
## Prüft: (1) Loader liest beide Blöcke, (2) Diff der Weltkonfiguration 1820 ↔ 1850 liegt nur unter "aktiv/" (also nur
## Werte aus epochen/startjahr_hebel), der Rest des Regelwerks ist bitgleich, (3) die geänderten Werte stimmen mit dem
## JSON überein (Hebel-Regel „größter Schlüssel <= Startjahr“), (4) proto_epochen.gd enthält keine Jahreszahl im Code.

const Epochen := preload("res://proto/proto_epochen.gd")

var n_ok := 0
var n_fail := 0


func ok(c: bool, text: String) -> void:
	if c:
		n_ok += 1
		print("  OK   ", text)
	else:
		n_fail += 1
		print("  FAIL ", text)


func _initialize() -> void:
	print("proto_epochen_test")
	var ep = Epochen.laden()
	ok(ep.ok(), "Regelwerk geladen (%s)" % ", ".join(PackedStringArray(ep.fehler)))
	ok(ep.startjahr_standard() == 1820, "Standard-Startjahr aus JSON = 1820")
	var a: Dictionary = ep.welt_konfig(1820)
	var b: Dictionary = ep.welt_konfig(1850)
	var diffs: Array = []
	_diff(a, b, "", diffs)
	var fremd := diffs.filter(func(p): return not String(p).begins_with("aktiv/"))
	ok(diffs.size() > 0, "1820 ↔ 1850 unterscheiden sich (%d Pfade)" % diffs.size())
	ok(fremd.is_empty(), "Unterschiede nur unter aktiv/ (= epochen/startjahr_hebel); fremd: %s" % str(fremd))
	var rest_a := a.duplicate(true)
	var rest_b := b.duplicate(true)
	rest_a.erase("aktiv")
	rest_b.erase("aktiv")
	ok(JSON.stringify(rest_a) == JSON.stringify(rest_b), "Regelwerk ohne aktiv/ bitgleich (skalen, haustypen, …)")
	# Jeder geänderte Wert muss aus dem JSON-Block stammen (kein berechneter Wert)
	var rw: Dictionary = ep.regelwerk
	var f20: Dictionary = ep.fuer_jahr(1820)
	var f50: Dictionary = ep.fuer_jahr(1850)
	ok(f20["epoche_id"] == "W1" and f50["epoche_id"] == "W2", "Epoche 1820 = W1, 1850 = W2 (%s/%s)" % [f20["epoche_id"], f50["epoche_id"]])
	ok(ep.epoche_id(1849) == "W1", "1849 noch W1 (bis-Grenze aus JSON)")
	ok(JSON.stringify(f50["epoche"]) == JSON.stringify(rw["epochen"]["stufen"]["W2"]), "Epochenwerte 1850 = JSON epochen.stufen.W2")
	var st: Dictionary = rw["startjahr_hebel"]["stufen"]
	ok(f50["hebel"]["ort_ew"] == st["1840"]["ort_ew"], "ort_ew 1850 = Stufe 1840 (größter Schlüssel <= 1850)")
	ok(f50["hebel"]["bahn_moeglich"] == st["1835"]["bahn_moeglich"], "bahn_moeglich 1850 = Stufe 1835")
	ok(f50["hebel"]["startkapital_cent"] == st["1820"]["startkapital_cent"], "nicht überschriebene Felder bleiben aus 1820 (startkapital_cent)")
	ok(f20["hebel"]["haustypen_frei"] == st["1820"]["haustypen_frei"], "haustypen_frei 1820 = JSON")
	ok("mietshaus" in f50["hebel"]["haustypen_frei"] and not ("mietshaus" in f20["hebel"]["haustypen_frei"]), "mietshaus nur 1850 frei")
	ok(not f20["hebel"]["bahn_moeglich"], "1820: keine Bahn")
	ok(ep.wert(1850, "hebel/ort_ew/dorf") == st["1840"]["ort_ew"]["dorf"], "Pfadzugriff wert()")
	# Jeder Diff-Pfad zeigt in fuer_jahr auf einen Wert, der so im JSON steht (epochen oder irgendeine Hebelstufe)
	var quelle_ok := true
	for p in diffs:
		var teile: PackedStringArray = String(p).split("/")
		if teile.size() < 3 or not (teile[1] in ["epoche", "hebel", "epoche_id", "startjahr"]):
			if not (teile.size() == 2 and teile[1] in ["epoche_id", "startjahr"]):
				quelle_ok = false
	ok(quelle_ok, "alle Diff-Pfade liegen in aktiv/{startjahr, epoche_id, epoche, hebel}")
	# Kein Code-Pfad je Jahr: keine vierstellige Jahreszahl (18xx–20xx) und keine Epochen-ID im Code (Kommentare ausgenommen)
	var src := FileAccess.get_file_as_string("res://proto/proto_epochen.gd")
	var re := RegEx.new()
	re.compile("\\b(1[89]\\d\\d|20\\d\\d)\\b|\"W[1-6]\"")
	var treffer: Array = []
	var nr := 0
	for zeile in src.split("\n"):
		nr += 1
		var code := zeile
		var hash_pos := zeile.find("#")
		if hash_pos >= 0:
			code = zeile.substr(0, hash_pos)
		if re.search(code) != null:
			treffer.append("Z%d: %s" % [nr, zeile.strip_edges()])
	ok(treffer.is_empty(), "proto_epochen.gd ohne Jahreszahl/Epochen-ID im Code %s" % str(treffer))
	print("Prüfungen OK: %d, FAIL: %d" % [n_ok, n_fail])
	quit(0 if n_fail == 0 else 1)


func _diff(a: Variant, b: Variant, pfad: String, out: Array) -> void:
	if a is Dictionary and b is Dictionary:
		var keys := {}
		for k in a:
			keys[k] = true
		for k in b:
			keys[k] = true
		for k in keys:
			var p := (pfad + "/" + str(k)) if pfad != "" else str(k)
			if not a.has(k) or not b.has(k):
				out.append(p)
			else:
				_diff(a[k], b[k], p, out)
	elif JSON.stringify(a) != JSON.stringify(b):
		out.append(pfad)
