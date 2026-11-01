extends RefCounted
## W-01 (S7, Felix): Weltauswahl und Maßstab. Reine Darstellungsschicht, die Sim rechnet weiter in Feldern
## (raum.feld_mm = 1000, Tempo in mm/Tick je Feld). Die Szeneneinheit bleibt 1 Feld = 1.0 in Weltkoordinaten,
## auf beiden Karten. Meter entstehen nur hier: meter = felder * m_pro_feld.
##
## Welten:
##   "slice"  Default. Unverändert seit S6 (bitgleich): Texte in Feldern, Zoom 0,4–26, Karte data/slice_map.json.
##   "s7"     opt-in. 1 Feld = 25 m, Kamera-Abstand 40 m–5,6 km, Distanztexte in m/km. Block A: flache 512²-Ebene
##            mit den Slice-Daten; Block B hängt Heightmap/Generator über world/s7_world.gd ein.
##
## Umschalten (Priorität von oben nach unten, erste gesetzte Quelle gewinnt):
##   1. Main.world_override = "s7"            (Tests, vor dem Instanziieren von main.tscn)
##   2. Kommandozeile  godot --path slice -- --welt=s7   (bzw. --welt=slice)
##   3. ProjectSettings  mega_tycoon/welt = "s7"         (Editor: Projekt > Projekteinstellungen > Erweitert,
##                                                        Abschnitt "Mega Tycoon"; committet bleibt "slice")
##   4. DEFAULT ("slice")

const DEFAULT := "slice"
const SETTING := "mega_tycoon/welt"
const ARG := "--welt="
const WELTEN := ["slice", "s7"]

## Kamera: cam.position = (0, 20, 16) * zoom (main._apply_zoom), Abstand Kamera–Zielpunkt = zoom * |(0,20,16)| Felder.
const CAM_DIR_LEN := 25.612496949731394   # sqrt(20² + 16²)

## Je Welt: m_pro_feld nur für Darstellung/Text. "slice" behält seine Texte in Feldern (dist_in_m = false).
const CFG := {
	"slice": {"m_pro_feld": 10.0, "dist_in_m": false, "zoom_min": 0.4, "zoom_max": 26.0},
	"s7": {"m_pro_feld": 25.0, "dist_in_m": true, "abstand_min_m": 40.0, "abstand_max_m": 5600.0},
}


## Gewählte Welt. override = Main.world_override, args = Kommandozeile (user + engine).
static func pick(override: String, args: PackedStringArray) -> String:
	if override != "":
		return override if WELTEN.has(override) else DEFAULT
	for a in args:
		if a.begins_with(ARG):
			var w := a.substr(ARG.length())
			if WELTEN.has(w):
				return w
			push_warning("Unbekannte Welt '%s', nehme %s" % [w, DEFAULT])
			return DEFAULT
	if ProjectSettings.has_setting(SETTING):
		var s := str(ProjectSettings.get_setting(SETTING))
		if WELTEN.has(s):
			return s
	return DEFAULT


static func m_pro_feld(welt: String) -> float:
	return float(CFG[welt]["m_pro_feld"])


static func zoom_for_distance_m(welt: String, meter: float) -> float:
	return meter / m_pro_feld(welt) / CAM_DIR_LEN


static func distance_m_for_zoom(welt: String, z: float) -> float:
	return z * CAM_DIR_LEN * m_pro_feld(welt)


## [zoom_min, zoom_max] je Welt. S7: aus der Kamera-Klemme 40 m–5,6 km zurückgerechnet (0,0625–8,746).
static func zoom_range(welt: String) -> Vector2:
	var c: Dictionary = CFG[welt]
	if c.has("zoom_min"):
		return Vector2(c["zoom_min"], c["zoom_max"])
	return Vector2(zoom_for_distance_m(welt, c["abstand_min_m"]), zoom_for_distance_m(welt, c["abstand_max_m"]))


static func meter_to_scene(welt: String, meter: float) -> float:
	return meter / m_pro_feld(welt)


static func scene_to_meter(welt: String, scene: float) -> float:
	return scene * m_pro_feld(welt)


## Distanztext. Slice: exakt wie bisher "%d Felder" (bitgleiche Texte). S7: "<1000 m" ganzzahlig, darüber km
## mit Dezimalkomma (2 Stellen bis 10 km, sonst 1). Beispiel: 126 Felder -> "3,15 km", 18 Felder -> "450 m".
static func dist_text(welt: String, felder: int) -> String:
	if not CFG[welt]["dist_in_m"]:
		return "%d Felder" % felder
	return meter_text(felder * m_pro_feld(welt))


static func meter_text(meter: float) -> String:
	if meter < 1000.0:
		return "%d m" % int(round(meter))
	var km := meter / 1000.0
	var s := ("%.2f" % km) if km < 10.0 else ("%.1f" % km)
	return s.replace(".", ",") + " km"
