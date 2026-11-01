extends Node
## U-01 Mikroanimationen + Klick-Sound. Hängt sich an SceneTree.node_added: JEDER Button, der in den Baum
## kommt, bekommt Hover-Skalierung (100 ms, ease-out), Press-Stauchung und einen leisen Klick
## (Kenney UI Pack click-a.ogg, -14 dB). Panel-Ein-/Ausblenden über slide_in/slide_out (150 ms).
## Keine Animation länger als 150 ms (Akzeptanz U-01).

const HOVER_SEC := 0.10
const SLIDE_SEC := 0.15
const CLICK := "res://ui/assets/sounds/click-a.ogg"
const SWITCH := "res://ui/assets/sounds/switch-a.ogg"

var _player: AudioStreamPlayer
var _switch: AudioStreamPlayer
var clicks := 0          # für Tests: Anzahl gespielter Klicks


func _ready() -> void:
	_player = _make_player(CLICK, -14.0)
	_switch = _make_player(SWITCH, -16.0)
	get_tree().node_added.connect(_on_node_added)
	_wire_tree(get_tree().root)


func _make_player(path: String, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
	else:
		s = AudioStreamOggVorbis.load_from_file(path)
	p.stream = s
	p.volume_db = db
	p.bus = "Master"
	add_child(p)
	return p


func _wire_tree(n: Node) -> void:
	_on_node_added(n)
	for c in n.get_children():
		_wire_tree(c)


func _on_node_added(n: Node) -> void:
	var b := n as BaseButton
	if b == null or b.has_meta("ui_fx"):
		return
	b.set_meta("ui_fx", true)
	b.mouse_entered.connect(_hover.bind(b, true))
	b.mouse_exited.connect(_hover.bind(b, false))
	b.button_down.connect(_press.bind(b))
	b.pressed.connect(_click.bind(b))


func _scale_to(b: Control, s: float) -> void:
	if not b.is_inside_tree():
		return
	b.pivot_offset = b.size * 0.5
	var tw: Tween = b.get_meta("ui_fx_tw") if b.has_meta("ui_fx_tw") else null
	if tw and tw.is_valid():
		tw.kill()
	tw = b.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "scale", Vector2(s, s), HOVER_SEC)
	b.set_meta("ui_fx_tw", tw)


func _hover(b: BaseButton, on: bool) -> void:
	if b.disabled and on:
		return
	# große Kacheln skalieren dezenter als kleine Knöpfe
	var s := 1.0
	if on:
		s = 1.02 if b.size.x > 200 else 1.05
	_scale_to(b, s)


func _press(b: BaseButton) -> void:
	if not b.disabled:
		_scale_to(b, 0.97)


func _click(b: BaseButton) -> void:
	clicks += 1
	var p := _switch if b.toggle_mode else _player
	if p.stream and p.is_inside_tree():
		p.play()
	_scale_to(b, 1.05 if b.is_hovered() else 1.0)


## Angedocktes Panel: gleitet von rechts (dx > 0) bzw. von oben/unten herein und blendet ein.
## Animiert wird position; vorher und nachher werden die Layout-Offsets wiederhergestellt, damit das
## Anker-Layout (rechts angedockt, wächst nach links/unten) nach der Animation wieder stimmt.
static func _restore(c: Control) -> void:
	if not c.has_meta("rest_offsets"):
		c.set_meta("rest_offsets", [c.offset_left, c.offset_top, c.offset_right, c.offset_bottom])
	var o: Array = c.get_meta("rest_offsets")
	c.offset_left = o[0]
	c.offset_top = o[1]
	c.offset_right = o[2]
	c.offset_bottom = o[3]
	c.reset_size()


## Neue Ruhe-Offsets setzen (z. B. Toast nach Textänderung neu zentriert).
static func set_rest(c: Control, l: float, t: float, r: float, b: float) -> void:
	c.set_meta("rest_offsets", [l, t, r, b])
	var tw: Tween = c.get_meta("slide_tw") if c.has_meta("slide_tw") else null
	if tw == null or not tw.is_running():
		_restore(c)


static func slide_in(c: Control, from := Vector2(60, 0)) -> Tween:
	var tw: Tween = c.get_meta("slide_tw") if c.has_meta("slide_tw") else null
	if tw and tw.is_valid():
		tw.kill()
	c.visible = true
	_restore(c)
	var rest := c.position
	c.position = rest + from
	c.modulate.a = 0.0
	tw = c.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "position", rest, SLIDE_SEC)
	tw.tween_property(c, "modulate:a", 1.0, SLIDE_SEC * 0.8)
	tw.chain().tween_callback(_restore.bind(c))
	c.set_meta("slide_tw", tw)
	return tw


static func slide_out(c: Control, to := Vector2(60, 0)) -> Tween:
	var tw: Tween = c.get_meta("slide_tw") if c.has_meta("slide_tw") else null
	if tw and tw.is_valid():
		tw.kill()
	_restore(c)
	var rest := c.position
	tw = c.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(c, "position", rest + to, SLIDE_SEC * 0.8)
	tw.tween_property(c, "modulate:a", 0.0, SLIDE_SEC * 0.8)
	tw.chain().tween_callback(func():
		c.visible = false
		c.modulate.a = 1.0
		_restore(c))
	c.set_meta("slide_tw", tw)
	return tw
