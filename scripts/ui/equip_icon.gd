extends Control
## Draws equipped item icon for a gear slot.

const ItemIcons := preload("res://scripts/ui/item_icons.gd")

var slot_name: String = "weapon"
var item_id: String = ""


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if item_id == "":
		draw_rect(r, Color(0.12, 0.12, 0.14))
		draw_rect(r, Color(0.3, 0.3, 0.3), false, 1.0)
	else:
		ItemIcons.draw_item(self, item_id, r)
