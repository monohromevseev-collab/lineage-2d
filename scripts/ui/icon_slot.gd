extends Button
## Button that procedurally draws a skill or item icon.

const ItemIcons := preload("res://scripts/ui/item_icons.gd")

var kind: String = "skill"  # skill | item
var icon_id: String = "attack"
var icon_enabled: bool = true
var hotkey: String = ""
var stack_count: int = 0  ## >1 shows count badge (Adena, Soulshots, …)


func _draw() -> void:
	var r := Rect2(Vector2(4, 4), size - Vector2(8, 8))
	if kind == "item":
		ItemIcons.draw_item(self, icon_id, r)
	else:
		ItemIcons.draw_skill(self, icon_id, r, icon_enabled)
	if hotkey != "":
		draw_string(ThemeDB.fallback_font, Vector2(6, 14), hotkey, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.95))
	if stack_count > 1:
		var txt := str(stack_count)
		if stack_count >= 10000:
			txt = "%dk" % int(stack_count / 1000.0)
		elif stack_count >= 1000:
			txt = "%.1fk" % (stack_count / 1000.0)
		var font := ThemeDB.fallback_font
		var fs := 11
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2(size.x - tw - 5, size.y - 6), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.85))
		draw_string(font, Vector2(size.x - tw - 6, size.y - 7), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.95, 0.55))
