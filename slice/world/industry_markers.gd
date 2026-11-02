extends Node3D
## W-05 (S7, Mira, Block C): Industrie-Lesbarkeit in der S7-Welt. Nur bei --welt=s7 (main.world_s7 != null),
## der Slice instanziiert diese Datei nicht.
##
## (1) Signalfläche je Industrie: getönte, nicht blockierende Bodenfläche 150–300 m je Typ (Felder gelb/braun, Halde
##     dunkel, Holzlager hell …) mit Saum nach S-08. Ein ArrayMesh für alle Flächen (Vertexfarben, folgt hoehe_at),
##     ein zweites für die Säume, deren Breite dem Zoom folgt (≥ 2,5 px, ≥ 6 m). Der blockierende Kern bleibt der
##     Sim-Footprint (Streitprotokoll W-05).
## (2) Icon + Name: je Industrie eine Plakette (Sprite3D, Billboard) über dem Standort; der Name ist das vorhandene
##     Karten-Label (building.label, LOD aus main). Plakettengröße in Bildschirm-px aus der echten Projektion
##     (34 px ab 1,5 km, 22 px und halbtransparent bis 600 m, unter 400 m aus: nah übernehmen die Props).
##     Declutter: Plaketten weichen Stadtlabels, Zielpfeilen und anderen Plaketten nach oben aus; die Industrie-Labels
##     weichen danach in props/label_declutter.gd den Plaketten aus (process_priority 99 < 100).
## (3) Status an der Plakette: Lizenz aktiv = runde grüne Marke mit Haken, ohne Lizenz = eckige graue Marke mit Schloss,
##     nicht lizenzierbar (Abnehmer, Holzfäller) = ohne Marke. Form + Farbe + Symbol (ui/tools/make_industry_plates.py).
## Daten: world/data/industrie_signal_s7.json. Positionen: die geladenen Industrien (main.buildings), also auch
## world/data/world_s7.json aus Felix' Generator, sobald es vorliegt.

const Building := preload("res://building.gd")
const SIG_PATH := "res://world/data/industrie_signal_s7.json"
const PLATE_DIR := "res://ui/assets/industry/"
const TEX_PX := 128.0
const GAP_PX := 4.0          # Abstand Plakette über dem Standortpunkt
const STEP_PX := 10.0        # Declutter-Schritt nach oben
const MAX_STEPS := 6
const MAX_SHIFT_PX := 80.0
const MUSTER := {"flaeche": 0, "streifen": 1, "bretter": 2, "flecken": 3}

var m                          # main.gd
var cfg: Dictionary = {}
var entries: Array = []        # je Industrie: {b, typ, size, sprite, status, rect, shift}
var by_b := {}                 # Building -> entry
var surf_mi: MeshInstance3D
var saum_mi: MeshInstance3D
var saum_m := -1.0             # aktuelle Saumbreite in Metern
var _tex := {}                 # "typ_status" -> Texture2D (mit Mipmaps)
var _rects: Array[Rect2] = []  # Plaketten-Rechtecke dieses Frames (für label_declutter)
var _mat_surf: StandardMaterial3D


func setup(main) -> void:
	m = main
	name = "IndustryMarkers"
	process_priority = 99
	cfg = m._json(SIG_PATH)
	var typen: Dictionary = cfg["typen"]
	for b in m.buildings:
		if b.kind == Building.Kind.CITY or b.kind == Building.Kind.WAREHOUSE or not typen.has(b.typ):
			continue
		var sp := Sprite3D.new()
		sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sp.no_depth_test = true
		sp.shaded = false
		sp.render_priority = 1                     # über den Weltlabels (-1), wie Zielpfeil
		sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sp.visible = false
		sp.name = "Icon_" + b.map_id
		add_child(sp)
		var e := {"b": b, "typ": b.typ, "size": float(typen[b.typ]["groesse_m"]) / m.m_pro_feld, "sprite": sp,
			"status": "", "rect": Rect2(), "shift": 0.0}
		entries.append(e)
		by_b[b] = e
		_set_status(e)
		b.label.pixel_size = float(cfg["lod"]["label_px_s7"])      # Name aus 4 km lesbar (~16 px statt ~14 px)
	_mat_surf = StandardMaterial3D.new()
	_mat_surf.vertex_color_use_as_albedo = true
	_mat_surf.roughness = 1.0
	_mat_surf.cull_mode = BaseMaterial3D.CULL_DISABLED
	surf_mi = MeshInstance3D.new()
	surf_mi.name = "Signalflaechen"
	surf_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	surf_mi.material_override = _mat_surf
	add_child(surf_mi)
	saum_mi = MeshInstance3D.new()
	saum_mi.name = "Signalsaeume"
	saum_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	saum_mi.material_override = _mat_surf
	add_child(saum_mi)
	rebuild_surfaces()
	_update_saum(true)


# ---------------------------------------------------------------- (1) Signalflächen

func _rgb(a: Array) -> Color:
	return Color8(int(a[0]), int(a[1]), int(a[2]))


## Bodenhöhe in Feldern (Szene) an einem Punkt; flach = 0. Folgt Felix' hoehe_at (Meter je Feld).
func ground_y(x: float, z: float) -> float:
	if m.world_s7 == null or not m.world_s7.has_method("hoehe_at"):
		return 0.0
	var c := Vector2i(clampi(int(floor(x)), 0, m.GRID - 1), clampi(int(floor(z)), 0, m.GRID - 1))
	return float(m.world_s7.hoehe_at(c, m.GRID)) / m.m_pro_feld


func _quad(st: SurfaceTool, x0: float, z0: float, x1: float, z1: float, col: Color) -> void:
	var lift := float(cfg["y_lift_felder"])
	var p := [Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(x1, 0, z1), Vector3(x0, 0, z1)]
	for i in 4:
		p[i].y = ground_y(p[i].x, p[i].z) + lift
	st.set_color(col)
	st.set_normal(Vector3.UP)
	for i in [0, 1, 2, 0, 2, 3]:
		st.add_vertex(p[i])


## Flächen neu bauen (nach Laden oder wenn Felix' Terrain/Karte nachträglich kommt).
func rebuild_surfaces() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cell_f: float = float(cfg["muster_m"]) / m.m_pro_feld
	for e in entries:
		var t: Dictionary = cfg["typen"][e["typ"]]
		var c1 := _rgb(t["fuellung"])
		var c2 := _rgb(t["fuellung2"])
		var mu: int = MUSTER.get(t["muster"], 0)
		var size: float = e["size"]
		var n := maxi(1, int(round(size / cell_f)))
		var step := size / n
		var o: Vector3 = e["b"].position - Vector3(size, 0, size) * 0.5
		var seed_h: int = hash(e["b"].map_id)
		for i in n:
			for j in n:
				var col := c1
				match mu:
					1:
						col = c2 if i % 2 == 1 else c1               # Felder: Streifen
					2:
						col = c2 if j % 3 == 2 else c1               # Holzlager: Bretter quer
					3:
						col = c2 if (absi(hash(Vector3i(i, j, seed_h))) % 100) < 35 else c1   # Halde: Flecken
				_quad(st, o.x + i * step, o.z + j * step, o.x + (i + 1) * step, o.z + (j + 1) * step, col)
	surf_mi.mesh = st.commit()


## Saum außen um jede Fläche, Breite = max(px × m/px beim aktuellen Zoom, min_m). Neu gebaut, wenn sich die Breite
## um mehr als 10 % ändert (Zoom), sonst nichts zu tun.
func _update_saum(force := false) -> void:
	var dist_m: float = m.world_s7.camera_distance_m(m)
	var vp_h := maxf(1.0, get_viewport().get_visible_rect().size.y)
	var mpp := 2.0 * dist_m * tan(deg_to_rad(m.cam.fov) * 0.5) / vp_h
	var want := maxf(float(cfg["saum"]["min_m"]), float(cfg["saum"]["px"]) * mpp)
	if not force and saum_m > 0.0 and absf(want - saum_m) / saum_m < 0.1:
		return
	saum_m = want
	var w: float = want / m.m_pro_feld
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for e in entries:
		var t: Dictionary = cfg["typen"][e["typ"]]
		var col := _rgb(cfg["saum"]["hell"] if t["saum"] == "hell" else cfg["saum"]["dunkel"])
		var h: float = e["size"] * 0.5
		var c: Vector3 = e["b"].position
		_quad(st, c.x - h - w, c.z - h - w, c.x + h + w, c.z - h, col)       # Nord
		_quad(st, c.x - h - w, c.z + h, c.x + h + w, c.z + h + w, col)       # Süd
		_quad(st, c.x - h - w, c.z - h, c.x - h, c.z + h, col)               # West
		_quad(st, c.x + h, c.z - h, c.x + h + w, c.z + h, col)               # Ost
	saum_mi.mesh = st.commit()


## Kontrast nach S-08/WCAG 2.x (für Tests und Notiz).
static func contrast(a: Color, b: Color) -> float:
	var la := a.srgb_to_linear().get_luminance()
	var lb := b.srgb_to_linear().get_luminance()
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


# ---------------------------------------------------------------- (2)+(3) Plaketten

func licensable(b) -> bool:
	return b.site >= 0 and b.site < m.eco.s_out_good.size() and m.eco.s_out_good[b.site] >= 0 and b.kind != Building.Kind.SINK


func status_of(b) -> String:
	if not licensable(b):
		return "frei"
	return "ja" if m.eco.licence_valid(b.site) else "nein"


func _texture(key: String) -> Texture2D:
	if not _tex.has(key):
		var src: Texture2D = load(PLATE_DIR + key + ".png")
		var img := src.get_image()
		if img.is_compressed():
			img.decompress()
		img.generate_mipmaps()               # 128 px -> 22–34 px ohne Flimmern
		_tex[key] = ImageTexture.create_from_image(img)
	return _tex[key]


func _set_status(e: Dictionary) -> void:
	var s := status_of(e["b"])
	if s == e["status"]:
		return
	e["status"] = s
	e["sprite"].texture = _texture("%s_%s" % [e["typ"], s])


## LOD aus dem Kameraabstand (Meter): {px, alpha}. alpha 0 = aus.
func lod_for(dist_m: float) -> Dictionary:
	var L: Dictionary = cfg["lod"]
	if dist_m < float(L["aus_unter_m"]):
		return {"px": 0.0, "alpha": 0.0}
	var t := clampf((dist_m - float(L["nah_bis_m"])) / (float(L["fern_ab_m"]) - float(L["nah_bis_m"])), 0.0, 1.0)
	return {"px": lerpf(float(L["icon_px_nah"]), float(L["icon_px_fern"]), t), "alpha": lerpf(float(L["alpha_nah"]), 1.0, t)}


## Stadtlabels als Hindernisse (Formel wie props/label_declutter.gd).
func label_rect(b, cam: Camera3D, kscale: float) -> Rect2:
	var l: Label3D = b.label
	var k := l.pixel_size * kscale
	var pc := cam.unproject_position(b.position)
	var fpx := l.font_size * k
	var lines := l.text.split("\n")
	var wmax := 0
	for ln in lines:
		wmax = maxi(wmax, ln.length())
	var w := wmax * fpx * 0.58
	return Rect2(pc.x - w * 0.5, pc.y - l.offset.y * k, w, lines.size() * fpx * 1.4)


func icon_rects() -> Array[Rect2]:
	return _rects


## Signalfläche als Rechteck in Feldern (x/z), leer für Gebäude ohne Fläche. main._place_map_labels setzt das
## Industrie-Label darunter (statt unter den Footprint), damit Fläche, Plakette und Name nicht übereinander liegen.
func ground_rect(b) -> Rect2:
	if not by_b.has(b):
		return Rect2()
	var sz: float = by_b[b]["size"]
	return Rect2(Vector2(b.position.x, b.position.z) - Vector2(sz, sz) * 0.5, Vector2(sz, sz))


## Linke und rechte Kante der Signalfläche auf dem Bildschirm.
func _side_px(e: Dictionary, cam: Camera3D, fallback: float) -> Vector2:
	var r := ground_rect(e["b"])
	var lo := fallback
	var hi := fallback
	for dx in [0.0, 1.0]:
		for dz in [0.0, 1.0]:
			var x: float = r.position.x + r.size.x * dx
			var z: float = r.position.y + r.size.y * dz
			var c := Vector3(x, ground_y(x, z), z)
			if not cam.is_position_behind(c):
				var px := cam.unproject_position(c).x
				lo = minf(lo, px)
				hi = maxf(hi, px)
	return Vector2(lo, hi)


## Ober- und Unterkante der Signalfläche auf dem Bildschirm (kleinstes/größtes y der vier projizierten Ecken).
func _extent_px(e: Dictionary, cam: Camera3D, fallback: float) -> Vector2:
	var r := ground_rect(e["b"])
	var top := fallback
	var bot := fallback
	for dx in [0.0, 1.0]:
		for dz in [0.0, 1.0]:
			var x: float = r.position.x + r.size.x * dx
			var z: float = r.position.y + r.size.y * dz
			var c := Vector3(x, ground_y(x, z), z)
			if not cam.is_position_behind(c):
				var y := cam.unproject_position(c).y
				top = minf(top, y)
				bot = maxf(bot, y)
	return Vector2(top, bot)


## Industrien mit Marker: Label-Platz setzt diese Datei (main._place_map_labels/label_declutter lassen sie aus).
func owns(b) -> bool:
	return by_b.has(b)


## Textmaß wie main/label_declutter (Zeichenbreite 0,58 × Schriftpx, Zeilenhöhe 1,4).
func text_size(l: Label3D, kscale: float) -> Vector2:
	var fpx := l.font_size * l.pixel_size * kscale
	var lines := l.text.split("\n")
	var wmax := 0
	for ln in lines:
		wmax = maxi(wmax, ln.length())
	return Vector2(wmax * fpx * 0.58, lines.size() * fpx * 1.4)


## Je Industrie eine Einheit „[Plakette] Name“ über der Signalfläche, zentriert über dem Standort. Entzerrung wie
## label_declutter (Städte und Zielpfeile zuerst belegt, dann Einheiten der Reihe nach), aber nach oben, höchstens 80 px.
## Unter 400 m entfällt die Plakette, der Name bleibt an derselben Stelle.
func _process(_dt: float) -> void:
	var cam: Camera3D = m.cam
	if cam == null or m.ui_root == null:
		return
	_update_saum()
	var vp := get_viewport().get_visible_rect().size
	var kscale := vp.y / 900.0 * 560.0
	var lod := lod_for(m.world_s7.camera_distance_m(m))
	var hud: Array[Rect2] = []
	m._collect_hud_rects(m.ui_root, 0, hud)
	var taken: Array[Rect2] = []
	for b in m.buildings:
		if b.kind == Building.Kind.CITY and b.label.visible and not cam.is_position_behind(b.position):
			taken.append(label_rect(b, cam, kscale))
	for r in m._goal_mark_rects:
		taken.append(r)
	_rects.clear()
	var xf := cam.global_transform
	var inv := xf.affine_inverse()
	var up := xf.basis.y.normalized()
	var right := xf.basis.x.normalized()
	var tanh := tan(deg_to_rad(cam.fov) * 0.5)
	var icon_on: bool = lod["alpha"] > 0.0
	var s: float = lod["px"] if icon_on else 0.0
	for e in entries:
		_set_status(e)
		var sp: Sprite3D = e["sprite"]
		var b = e["b"]
		var l: Label3D = b.label
		var p: Vector3 = b.position + Vector3(0, ground_y(b.position.x, b.position.z), 0)
		e["rect"] = Rect2()
		if cam.is_position_behind(p) or (not icon_on and not l.visible):
			sp.visible = false
			l.visible = false
			continue
		var ts := text_size(l, kscale) if l.visible else Vector2.ZERO
		var gap := 5.0 if s > 0.0 and ts.x > 0.0 else 0.0
		var uw := s + gap + ts.x
		var uh := maxf(s, ts.y)
		var pc := cam.unproject_position(p)
		var ext := _extent_px(e, cam, pc.y)
		var base := ext.x - GAP_PX                        # Einheit sitzt über der Signalfläche, nicht auf Props/Fläche
		var below := ext.y + GAP_PX                       # Ausweichplatz: unter der Fläche (bleibt an der Fläche)
		# Kandidaten: über der Fläche, unter der Fläche, dann schrittweise weiter weg (oben/unten im Wechsel)
		var shift := 0.0
		var r := Rect2(pc.x - uw * 0.5, base - uh, uw, uh)
		var placed := false
		var side := _side_px(e, cam, pc.x)
		# Zuerst die 6 Plätze an der Flächenkante; ist die Fläche größer als das Bild (Nahzoom, Kante außerhalb),
		# danach am Standortpunkt selbst (unter/über pc), damit der Name nah nicht verschwindet.
		var n_edge := 6 * (MAX_STEPS + 1)
		for i in n_edge + 2 * (MAX_STEPS + 1):
			var kind := i % 6 if i < n_edge else 6 + (i - n_edge) % 2
			var d := ((i / 6) if i < n_edge else ((i - n_edge) / 2)) * STEP_PX
			var cand: Rect2
			match kind:
				6:          # am Standortpunkt, darunter
					cand = Rect2(pc.x - uw * 0.5, pc.y + GAP_PX + d, uw, uh)
				7:          # am Standortpunkt, darüber
					cand = Rect2(pc.x - uw * 0.5, pc.y - GAP_PX - uh - d, uw, uh)
				0:          # über der Fläche, dann weiter nach oben
					cand = Rect2(pc.x - uw * 0.5, base - uh - d, uw, uh)
				1:          # unter der Fläche
					cand = Rect2(pc.x - uw * 0.5, below + d, uw, uh)
				2:          # rechts neben der Fläche, dann weiter nach rechts
					cand = Rect2(side.y + GAP_PX + d, pc.y - uh * 0.5, uw, uh)
				3:          # links neben der Fläche
					cand = Rect2(side.x - GAP_PX - uw - d, pc.y - uh * 0.5, uw, uh)
				4:          # rechts, nach oben versetzt
					cand = Rect2(side.y + GAP_PX, pc.y - uh * 0.5 - d, uw, uh)
				5:          # links, nach oben versetzt
					cand = Rect2(side.x - GAP_PX - uw, pc.y - uh * 0.5 - d, uw, uh)
			var hit := not Rect2(Vector2.ZERO, vp).encloses(cand)
			for h in hud:                   # HUD-Panels und Leisten zählen als belegt (sonst ausgeblendet)
				if hit or cand.intersects(h.grow(4.0)):
					hit = true
					break
			for t in taken:
				if hit or cand.grow(1.0).intersects(t):
					hit = true
					break
			if not hit:
				r = cand
				shift = d + kind * 1000.0      # Debug: Kandidat (0 oben, 1 unten, 2/4 rechts, 3/5 links, 6/7 Standort) × 1000 + Abstand px
				placed = true
				break
		if not placed:
			r = Rect2(pc.x - uw * 0.5, base - uh - MAX_SHIFT_PX, uw, uh)
			shift = MAX_SHIFT_PX
		var gone := not Rect2(Vector2.ZERO, vp).intersects(r)
		for h in hud:
			if r.intersects(h.grow(4.0)):
				gone = true
				break
		if gone:
			sp.visible = false
			l.visible = false
			continue
		var z := -(inv * p).z
		var mpp := 2.0 * z * tanh / vp.y                     # Felder je Bildschirm-px in Tiefe des Standorts
		# Bildschirmversatz (px) vom Standortpunkt pc zu einem Punkt der Einheit -> Weltpunkt in gleicher Tiefe
		var at := func(px: Vector2) -> Vector3:
			return p + right * ((px.x - pc.x) * mpp) - up * ((px.y - pc.y) * mpp)
		if s > 0.0:
			sp.pixel_size = s * mpp / TEX_PX
			sp.global_position = at.call(Vector2(r.position.x + s * 0.5, r.position.y + uh * 0.5))
			sp.modulate = Color(1, 1, 1, lod["alpha"])
			sp.visible = true
		else:
			sp.visible = false
		if l.visible:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			l.offset = Vector2.ZERO
			l.global_position = at.call(Vector2(r.position.x + s + gap, r.position.y + (uh - ts.y) * 0.5))
		e["rect"] = r
		e["shift"] = shift
		e["icon_px"] = s
		e["text_rect"] = Rect2(r.position.x + s + gap, r.position.y + (uh - ts.y) * 0.5, ts.x, ts.y)
		_rects.append(r)
		taken.append(r)


## Test/Debug: Plaketten-Rechteck aus der echten Projektion der vier Billboard-Ecken (nicht aus der Formel oben).
func projected_rect(e: Dictionary) -> Rect2:
	var cam: Camera3D = m.cam
	var sp: Sprite3D = e["sprite"]
	var hw := TEX_PX * sp.pixel_size * 0.5
	var xb := cam.global_transform.basis
	var c := sp.global_position
	var out := Rect2(cam.unproject_position(c), Vector2.ZERO)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			out = out.expand(cam.unproject_position(c + xb.x * hw * sx + xb.y * hw * sy))
	return out
