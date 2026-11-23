extends Button
## Button that procedurally draws a skill or item icon.

const ItemIcons := preload("res://scripts/ui/item_icons.gd")

var kind: String = "skill"  # skill | item
var icon_id: String = "attack"
var icon_enabled: bool = true
var hotkey: String = ""


func _draw() -> void:
	var r := Rect2(Vector2(4, 4), size - Vector2(8, 8))
	if kind == "item":
		ItemIcons.draw_item(self, icon_id, r)
	else:
		ItemIcons.draw_skill(self, icon_id, r, icon_enabled)
	if hotkey != "":
		draw_string(ThemeDB.fallback_font, Vector2(6, 14), hotkey, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.95))
