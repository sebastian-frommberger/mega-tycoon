extends RefCounted
## Phase 4 Welle 1 (Felix): Epochen-Datenhülle (15_regelwerk_v1_1 Teil A, P7). Liest die Blöcke `epochen` und
## `startjahr_hebel` aus res://world/data/proto/regelwerk.json (Kopie von phase3b/12_regelwerk_v1_1.json, Eigentümer
## bleibt die Doku) und liefert für ein Startjahr die gültigen Werte. Es gibt KEINEN Code-Pfad je Jahr oder Epoche:
## Jahreszahlen stehen nur im JSON, dieser Code vergleicht nur Schlüssel (proto_epochen_test prüft das im Quelltext).
##
## Regeln (aus dem JSON übernommen, nicht erfunden):
##   - Epoche: die Stufe in epochen.stufen mit von <= jahr <= bis (K21: Welt-Epoche folgt dem Kalender).
##   - Hebel: "Je Eintrag gilt der größte Schlüssel <= startjahr. Werte überschreiben die Grundwerte."
##     Umsetzung: alle Stufen mit Schlüssel <= jahr aufsteigend übereinanderlegen (flach je Feld, letzte gewinnt).
##   - Was nicht in epochen/startjahr_hebel steht (skalen, haustypen, …), ändert sich mit dem Startjahr nicht.
##
## API:
##   var ep = ProtoEpochen.laden()                 # Default-Pfad; laden(pfad) für Tests
##   ep.fuer_jahr(1820) -> Dictionary              {startjahr, epoche_id, epoche:{…}, hebel:{…}}
##   ep.welt_konfig(jahr) -> Dictionary            ganzes Regelwerk + Block "aktiv" (= fuer_jahr), Rest unverändert
##   ep.wert(jahr, "hebel/ort_ew/dorf")            Pfadzugriff, null wenn nicht vorhanden
##   ep.startjahr_standard() -> int                regelwerk.startjahr (1820 im JSON)

const PFAD := "res://world/data/proto/regelwerk.json"

var regelwerk: Dictionary = {}
var fehler: Array = []


static func laden(pfad := PFAD):
	var ep = load("res://proto/proto_epochen.gd").new()
	ep._lies(pfad)
	return ep


func _lies(pfad: String) -> void:
	var f := FileAccess.open(pfad, FileAccess.READ)
	if f == null:
		fehler.append("Regelwerk fehlt: " + pfad)
		return
	var d = JSON.parse_string(f.get_as_text())
	if not (d is Dictionary):
		fehler.append("Regelwerk kein JSON-Objekt: " + pfad)
		return
	regelwerk = d
	for k in ["epochen", "startjahr_hebel", "startjahr"]:
		if not regelwerk.has(k):
			fehler.append("Block fehlt: " + k)


func ok() -> bool:
	return fehler.is_empty()


func startjahr_standard() -> int:
	return int(regelwerk.get("startjahr", 0))


## Epochen-ID (Schlüssel aus epochen.stufen) für ein Jahr, "" wenn keine passt.
func epoche_id(jahr: int) -> String:
	var stufen: Dictionary = regelwerk.get("epochen", {}).get("stufen", {})
	for id in stufen:
		var st: Dictionary = stufen[id]
		if jahr >= int(st.get("von", 0)) and jahr <= int(st.get("bis", 0)):
			return id
	return ""


## Hebel: alle Stufen mit Schlüssel <= jahr aufsteigend überlagert.
func hebel(jahr: int) -> Dictionary:
	var stufen: Dictionary = regelwerk.get("startjahr_hebel", {}).get("stufen", {})
	var keys: Array = []
	for k in stufen:
		if String(k).is_valid_int() and int(k) <= jahr:
			keys.append(int(k))
	keys.sort()
	var out := {}
	for k in keys:
		var st: Dictionary = stufen[str(k)]
		for feld in st:
			out[feld] = _kopie(st[feld])
	return out


func fuer_jahr(jahr: int) -> Dictionary:
	var id := epoche_id(jahr)
	var ep: Dictionary = regelwerk.get("epochen", {}).get("stufen", {}).get(id, {})
	return {"startjahr": jahr, "epoche_id": id, "epoche": _kopie(ep), "hebel": hebel(jahr)}


## Ganzes Regelwerk als Weltkonfiguration: unverändert + Block "aktiv". Grundlage für den P7-Test (Diff 1820/1850).
func welt_konfig(jahr: int) -> Dictionary:
	var k: Dictionary = _kopie(regelwerk)
	k["aktiv"] = fuer_jahr(jahr)
	return k


## Pfadzugriff "a/b/c" auf fuer_jahr(jahr).
func wert(jahr: int, pfad: String) -> Variant:
	var cur: Variant = fuer_jahr(jahr)
	for teil in pfad.split("/"):
		if cur is Dictionary and (cur as Dictionary).has(teil):
			cur = cur[teil]
		else:
			return null
	return cur


static func _kopie(v: Variant) -> Variant:
	if v is Dictionary or v is Array:
		return v.duplicate(true)
	return v
