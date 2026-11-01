extends RefCounted
## W-01 (S7, Felix): Hooks der S7-Welt. main.gd ruft diese Funktionen nur auf, wenn `--welt=s7` aktiv ist
## (main.world_s7 != null). Ohne Schalter wird diese Datei nicht instanziiert, der Slice bleibt bitgleich.
##
## Block A: flache 512²-Ebene (main._setup_ground), Kartenlogik und Daten wie der Slice (data/slice_map.json),
##          nur Maßstab (1 Feld = 25 m), Kamera-Klemme 40 m–5,6 km und Distanztexte in m/km.
## Block B (W-06/W-02) hängt sich hier ein, ohne main.gd weiter aufzumachen:
##   - MAP_S7: tools/world_gen.py schreibt world/data/world_s7.json im Slice-Schema; liegt die Datei vor, wird sie geladen.
##   - HEIGHTMAP: 16-bit-PNG 513² (+ Rand), hoehe_at() liest daraus; heute 0 überall.
##   - build_terrain(): Chunks/Rand statt der flachen Ebene (heute no-op).

const Welt := preload("res://world/welt.gd")
const WELT := "s7"
const MAP_S7 := "res://world/data/world_s7.json"
const HEIGHTMAP := "res://world/data/hoehe_s7.png"

var m_pro_feld := Welt.m_pro_feld(WELT)
var zoom_range := Welt.zoom_range(WELT)
var hoehe := PackedFloat32Array()     # Block B: Höhe je Feld in Metern (GRID²), leer = flach


## Kartenpfad: eigene S7-Karte, sobald der Generator sie liefert, sonst die Slice-Daten (Block A erlaubt).
func map_path(fallback: String) -> String:
	return MAP_S7 if FileAccess.file_exists(MAP_S7) else fallback


## Nach main._setup_camera: Nahzoom bis 40 m braucht eine kleinere near-Ebene als der Slice (0,8 Felder = 20 m).
func setup_camera(main) -> void:
	main.zoom_min = zoom_range.x
	main.zoom_max = zoom_range.y


## Aus main._apply_zoom, vor dem Setzen der Kameraposition: Zoom klemmen, near/far an den Abstand koppeln
## (Tiefenpräzision über 40 m–5,6 km, wie SP-03: near 0,4 % des Abstands, far 8 × Abstand + 15 km).
func apply_zoom(main) -> void:
	main.zoom = clampf(main.zoom, zoom_range.x, zoom_range.y)
	var dist: float = main.zoom * Welt.CAM_DIR_LEN            # Felder
	main.cam.near = maxf(0.01, dist * 0.004)
	main.cam.far = dist * 8.0 + 15000.0 / m_pro_feld


## Kamera-Abstand zum Zielpunkt in Metern (Tests, HUD/Debug).
func camera_distance_m(main) -> float:
	return Welt.distance_m_for_zoom(WELT, main.zoom)


## Block B: Höhe in Metern je Feld. Block A: flach.
func hoehe_at(cell: Vector2i, grid: int) -> float:
	if hoehe.is_empty():
		return 0.0
	return hoehe[cell.y * grid + cell.x]


## Block B: Terrain-Chunks und Randlandschaft. Block A: no-op, main._setup_ground liefert die flache 512²-Ebene.
func build_terrain(_main) -> void:
	pass
