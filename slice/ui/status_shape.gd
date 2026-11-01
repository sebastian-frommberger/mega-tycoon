extends Control
## Statusform nach A-07/S-08: Form + Farbe + dunkler Saum, nie nur Farbe.
## ok = Kreis, warn = Dreieck, bad = Quadrat, none = leerer Kreis (offen).

const TB := preload("res://ui/theme/theme_builder.gd")

var kind := "ok":
	set(v):
		kind = v
		queue_redraw()


func _init(k := "ok", px := 14) -> void:
	kind = k
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _draw() -> void:
	var s := minf(size.x, size.y)
	var o := (size - Vector2(s, s)) * 0.5
	var saum: Color = TB.C["saum"]
	match kind:
		"ok":
			draw_circle(o + Vector2(s, s) * 0.5, s * 0.5, saum)
			draw_circle(o + Vector2(s, s) * 0.5, s * 0.5 - 2.0, TB.C["status_ok"])
		"warn":
			var p := PackedVector2Array([o + Vector2(s * 0.5, 0), o + Vector2(s, s), o + Vector2(0, s)])
			draw_colored_polygon(p, saum)
			var q := PackedVector2Array([o + Vector2(s * 0.5, 3.2), o + Vector2(s - 2.4, s - 1.6), o + Vector2(2.4, s - 1.6)])
			draw_colored_polygon(q, TB.C["status_warn"])
		"bad":
			draw_rect(Rect2(o, Vector2(s, s)), saum)
			draw_rect(Rect2(o + Vector2(2, 2), Vector2(s - 4, s - 4)), TB.C["status_bad"])
		_:
			draw_arc(o + Vector2(s, s) * 0.5, s * 0.5 - 1.5, 0, TAU, 24, TB.C["muted"], 2.0, true)
