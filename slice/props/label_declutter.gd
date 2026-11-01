extends Node
## S-13 (aus S-12): Karten-Labels, die einander berühren (Werkzeugfabrik/Kohlberg, Erzmine/Stahlwerk/Kraftwerk), werden
## nach main._place_map_labels (process_priority 100 = danach) nach unten auseinandergeschoben. Städte haben Vorrang,
## dann Reihenfolge der Gebäude. Nur Bildschirm-Offset, keine Änderung an main.gd oder Texten.

const STEP_PX := 13.0
const MAX_STEPS := 5


func _ready() -> void:
	process_priority = 100


func _process(_dt: float) -> void:
	var m := get_parent()
	var cam: Camera3D = m.get("cam")
	var list = m.get("buildings")
	if cam == null or list == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var kscale := vp.y / 900.0 * 560.0
	var items: Array = []
	for b in list:
		var l: Label3D = b.label
		if l.visible and not cam.is_position_behind(b.position):
			items.append(b)
	items.sort_custom(func(a, c): return (a.kind == 2) and (c.kind != 2))      # Kind.CITY = 2, stabil genug für 2 Klassen
	var taken: Array[Rect2] = []
	for b in items:
		var l: Label3D = b.label
		var k := l.pixel_size * kscale
		var pc := cam.unproject_position(b.position)
		var fpx := l.font_size * k
		var lines := l.text.split("\n")
		var wmax := 0
		for ln in lines:
			wmax = maxi(wmax, ln.length())
		var w := wmax * fpx * 0.58
		var h := lines.size() * fpx * 1.4
		var shift := 0.0
		for _i in MAX_STEPS + 1:
			var r := Rect2(pc.x - w * 0.5, pc.y - (l.offset.y - 0.0) * k + shift, w, h).grow(1.0)
			var hit := false
			for t in taken:
				if r.intersects(t):
					hit = true
					shift = maxf(shift, t.end.y - (pc.y - l.offset.y * k) + 1.0)
					break
			if not hit:
				break
		if shift > 0.0:
			l.offset = Vector2(l.offset.x, l.offset.y - shift / k)
		taken.append(Rect2(pc.x - w * 0.5, pc.y - l.offset.y * k, w, h))
	# B-6: Zielpfeil hat Vorrang – nach dem Verschieben noch einmal gegen die Pfeil-Rechtecke prüfen.
	if m.has_method("hide_labels_under_goal_markers"):
		m.hide_labels_under_goal_markers()
