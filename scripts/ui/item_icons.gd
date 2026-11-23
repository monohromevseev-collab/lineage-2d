extends RefCounted
## Tiny procedural item icons for inventory / equip / skill bar.


static func draw_item(canvas: CanvasItem, item_id: String, rect: Rect2) -> void:
	var Items := preload("res://data/items.gd")
	var it: Dictionary = Items.get_item(item_id)
	var slot: String = str(it.get("slot", ""))
	var vis: Dictionary = it.get("visual", {})
	var tier: int = int(vis.get("tier", 0))
	var bg := Color(0.12, 0.14, 0.16, 0.92)
	var border := Color(0.55, 0.48, 0.28) if tier < 2 else Color(0.65, 0.75, 0.9)
	canvas.draw_rect(rect, bg)
	canvas.draw_rect(rect, border, false, 1.5)
	var c := rect.get_center()
	var s := mini(rect.size.x, rect.size.y) * 0.28
	match slot:
		"weapon":
			var col := Color(0.85, 0.85, 0.95) if tier >= 2 else (Color(0.8, 0.55, 0.25) if tier == 1 else Color(0.6, 0.4, 0.2))
			canvas.draw_line(c + Vector2(0, s), c + Vector2(0, -s * 1.3), col, 3.0)
			canvas.draw_line(c + Vector2(-s * 0.6, s * 0.2), c + Vector2(s * 0.6, s * 0.2), col.darkened(0.2), 2.0)
		"chest":
			var col2 := Color(0.55, 0.65, 0.8) if tier >= 2 else (Color(0.75, 0.5, 0.25) if tier == 1 else Color(0.75, 0.7, 0.55))
			canvas.draw_colored_polygon(PackedVector2Array([
				c + Vector2(-s, -s * 0.6), c + Vector2(s, -s * 0.6), c + Vector2(s * 1.1, s), c + Vector2(-s * 1.1, s),
			]), col2)
		"head":
			var col3 := Color(0.7, 0.8, 0.9) if tier >= 1 else Color(0.7, 0.65, 0.5)
			canvas.draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -s), c + Vector2(s, -s * 0.2), c + Vector2(s * 0.7, s * 0.7),
				c + Vector2(-s * 0.7, s * 0.7), c + Vector2(-s, -s * 0.2),
			]), col3)
		"legs":
			var col4 := Color(0.4, 0.45, 0.55) if tier >= 1 else Color(0.55, 0.48, 0.35)
			canvas.draw_rect(Rect2(c + Vector2(-s * 0.7, -s * 0.3), Vector2(s * 0.55, s * 1.2)), col4)
			canvas.draw_rect(Rect2(c + Vector2(s * 0.15, -s * 0.3), Vector2(s * 0.55, s * 1.2)), col4)
		_:
			canvas.draw_circle(c, s, Color(0.5, 0.55, 0.45))


static func draw_skill(canvas: CanvasItem, skill_id: String, rect: Rect2, enabled: bool = true) -> void:
	var bg := Color(0.1, 0.12, 0.14, 0.95) if enabled else Color(0.08, 0.08, 0.08, 0.7)
	canvas.draw_rect(rect, bg)
	canvas.draw_rect(rect, Color(0.75, 0.65, 0.35) if enabled else Color(0.3, 0.3, 0.3), false, 1.5)
	var c := rect.get_center()
	var s := mini(rect.size.x, rect.size.y) * 0.28
	match skill_id:
		"attack":
			canvas.draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -s), c + Vector2(s * 0.7, s * 0.2), c + Vector2(0, s * 0.5), c + Vector2(-s * 0.7, s * 0.2),
			]), Color(0.9, 0.55, 0.25))
		"power_strike":
			canvas.draw_colored_polygon(PackedVector2Array([
				c + Vector2(-s, s), c + Vector2(0, -s), c + Vector2(s, s),
			]), Color(0.85, 0.35, 0.25))
		"heal":
			canvas.draw_rect(Rect2(c - Vector2(s * 0.25, s), Vector2(s * 0.5, s * 2)), Color(0.4, 0.85, 0.5))
			canvas.draw_rect(Rect2(c - Vector2(s, s * 0.25), Vector2(s * 2, s * 0.5)), Color(0.4, 0.85, 0.5))
		_:
			canvas.draw_circle(c, s * 0.6, Color(0.35, 0.4, 0.5))
