extends Node2D
## Tiny world-space HP bar above entities.

@export var width: float = 40.0
@export var height: float = 5.0
@export var offset_y: float = -42.0

var ratio: float = 1.0
var bar_color: Color = Color(0.35, 0.85, 0.40)


func set_ratio(current: float, maximum: float) -> void:
	if maximum <= 0.0:
		ratio = 0.0
	else:
		ratio = clampf(current / maximum, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var origin := Vector2(-width * 0.5, offset_y)
	draw_rect(Rect2(origin, Vector2(width, height)), Color(0.08, 0.08, 0.08, 0.75))
	draw_rect(Rect2(origin, Vector2(width * ratio, height)), bar_color)
	draw_rect(Rect2(origin, Vector2(width, height)), Color(0.05, 0.05, 0.05, 0.9), false, 1.0)
