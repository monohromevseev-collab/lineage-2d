extends Area2D
## Ground loot pickup — server spawns, clients render.

@onready var glow: Polygon2D = $Glow
@onready var icon: Polygon2D = $Icon
@onready var label: Label = $Label

var drop_id: int = 0
var item_id: String = ""
var ttl: float = 120.0


func setup(id: int, item: String, pos: Vector2) -> void:
	drop_id = id
	item_id = item
	position = pos
	var Items := preload("res://data/items.gd")
	label.text = Items.display_name(item)
	var it: Dictionary = Items.get_item(item)
	var slot: String = str(it.get("slot", ""))
	var tier: int = int(it.get("visual", {}).get("tier", 0)) if typeof(it.get("visual", {})) == TYPE_DICTIONARY else 0
	match slot:
		"weapon":
			icon.color = Color(0.85, 0.85, 0.9) if tier >= 2 else (Color(0.8, 0.55, 0.25) if tier == 1 else Color(0.6, 0.4, 0.2))
			icon.polygon = PackedVector2Array([Vector2(0, -14), Vector2(4, 10), Vector2(-4, 10)])
		"chest":
			icon.color = Color(0.55, 0.65, 0.8) if tier >= 2 else (Color(0.75, 0.5, 0.25) if tier == 1 else Color(0.75, 0.7, 0.55))
			icon.polygon = PackedVector2Array([Vector2(-10, -8), Vector2(10, -8), Vector2(12, 10), Vector2(-12, 10)])
		"head":
			icon.color = Color(0.7, 0.8, 0.9) if tier >= 1 else Color(0.7, 0.65, 0.5)
			icon.polygon = PackedVector2Array([Vector2(0, -12), Vector2(10, -2), Vector2(6, 8), Vector2(-6, 8), Vector2(-10, -2)])
		_:
			icon.color = Color(0.5, 0.55, 0.65) if tier >= 1 else Color(0.65, 0.55, 0.4)
			icon.polygon = PackedVector2Array([Vector2(-8, -6), Vector2(8, -6), Vector2(8, 10), Vector2(-8, 10)])
	glow.color = Color(1.0, 0.85, 0.35, 0.35)
	glow.polygon = PackedVector2Array([
		Vector2(0, -18), Vector2(16, 0), Vector2(0, 18), Vector2(-16, 0),
	])


func _process(delta: float) -> void:
	glow.rotation += delta * 1.2
	if multiplayer.is_server():
		ttl -= delta
		if ttl <= 0.0:
			queue_free()
