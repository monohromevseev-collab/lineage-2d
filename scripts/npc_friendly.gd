extends CharacterBody2D
## Talkable HF NPC (Newbie Helper, Roien, Darin, …).

@onready var visual: Node2D = $Visual
@onready var name_label: Label = $NameLabel

var npc_id: String = ""
var display_name: String = "NPC"
var title: String = ""
var _selected: bool = false
var _select_poly: Polygon2D


func setup(id: String, pos: Vector2) -> void:
	npc_id = id
	position = pos
	var DataRegistry := preload("res://data/data_registry.gd")
	var t: Dictionary = DataRegistry.get_friendly_npc(id)
	display_name = str(t.get("name", id))
	title = str(t.get("title", ""))
	var label := display_name
	if title != "":
		label = "%s\n<%s>" % [display_name, title]
	name_label.text = label
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var color_arr: Array = t.get("color", [0.7, 0.7, 0.7])
	var col := Color(float(color_arr[0]), float(color_arr[1]), float(color_arr[2]))
	_build_body(str(t.get("silhouette", "villager")), col)
	_ensure_select_ring()


func set_selected(on: bool) -> void:
	_selected = on
	if _select_poly:
		_select_poly.visible = on


func _ensure_select_ring() -> void:
	if _select_poly:
		return
	_select_poly = Polygon2D.new()
	_select_poly.z_index = -1
	_select_poly.color = Color(0.35, 0.75, 0.95, 0.4)
	_select_poly.polygon = PackedVector2Array([
		Vector2(0, 12), Vector2(26, 24), Vector2(0, 34), Vector2(-26, 24),
	])
	_select_poly.visible = false
	add_child(_select_poly)


func _build_body(kind: String, color: Color) -> void:
	for c in visual.get_children():
		c.queue_free()
	var body := Polygon2D.new()
	body.color = color
	var head := Polygon2D.new()
	head.color = Color(0.85, 0.72, 0.6)
	match kind:
		"helper":
			body.polygon = PackedVector2Array([
				Vector2(-14, -4), Vector2(14, -4), Vector2(16, 18), Vector2(0, 24), Vector2(-16, 18),
			])
			head.polygon = PackedVector2Array([
				Vector2(-10, -22), Vector2(10, -22), Vector2(12, -6), Vector2(-12, -6),
			])
		"master":
			body.polygon = PackedVector2Array([
				Vector2(-16, -6), Vector2(16, -6), Vector2(18, 20), Vector2(0, 26), Vector2(-18, 20),
			])
			head.polygon = PackedVector2Array([
				Vector2(-11, -26), Vector2(11, -26), Vector2(13, -8), Vector2(-13, -8),
			])
		"mage":
			body.polygon = PackedVector2Array([
				Vector2(-12, -8), Vector2(12, -8), Vector2(14, 22), Vector2(0, 28), Vector2(-14, 22),
			])
			head.polygon = PackedVector2Array([
				Vector2(-9, -24), Vector2(9, -24), Vector2(10, -8), Vector2(-10, -8),
			])
		_:
			body.polygon = PackedVector2Array([
				Vector2(-12, -4), Vector2(12, -4), Vector2(14, 18), Vector2(0, 22), Vector2(-14, 18),
			])
			head.polygon = PackedVector2Array([
				Vector2(-9, -20), Vector2(9, -20), Vector2(10, -6), Vector2(-10, -6),
			])
	visual.add_child(body)
	visual.add_child(head)
