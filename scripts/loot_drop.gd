extends Area2D
## Ground loot pickup — server spawns, clients render.

@onready var glow: Polygon2D = $Glow
@onready var icon: Polygon2D = $Icon
@onready var label: Label = $Label

var drop_id: int = 0
var item_id: String = ""
var count: int = 1
var ttl: float = 120.0


func setup(id: int, item: String, pos: Vector2, amount: int = 1) -> void:
	drop_id = id
	item_id = item
	count = maxi(1, amount)
	position = pos
	var Items := preload("res://data/items.gd")
	var base_name := Items.display_name(item)
	if item == "57":
		label.text = "%s ×%d" % [base_name, count]
	elif count > 1:
		label.text = "%s ×%d" % [base_name, count]
	else:
		label.text = base_name
	var it: Dictionary = Items.get_item(item)
	var slot: String = str(it.get("slot", ""))
	var tier: int = int(it.get("visual", {}).get("tier", 0)) if typeof(it.get("visual", {})) == TYPE_DICTIONARY else 0
	if item == "57":
		# Single gold coin pile — size scales slightly with amount.
		var s := 1.0 + clampf(log(float(count) + 1.0) / 8.0, 0.0, 0.6)
		icon.color = Color(0.95, 0.82, 0.25)
		icon.polygon = PackedVector2Array([
			Vector2(0, -10 * s), Vector2(9 * s, -3 * s), Vector2(9 * s, 6 * s),
			Vector2(0, 10 * s), Vector2(-9 * s, 6 * s), Vector2(-9 * s, -3 * s),
		])
		glow.color = Color(1.0, 0.88, 0.3, 0.4)
		glow.polygon = PackedVector2Array([
			Vector2(0, -16 * s), Vector2(14 * s, 0), Vector2(0, 16 * s), Vector2(-14 * s, 0),
		])
		return
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
