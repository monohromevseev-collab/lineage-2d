extends Node2D
## Talking Island–like meadow with a central talking stone.


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var half := Vector2(460, 300)
	var ground := PackedVector2Array([
		Vector2(0, -half.y),
		Vector2(half.x, 0),
		Vector2(0, half.y),
		Vector2(-half.x, 0),
	])
	draw_colored_polygon(ground, Color(0.26, 0.40, 0.24))

	# Path from talking stone toward hunting grounds (east)
	var path := PackedVector2Array([
		Vector2(-90, 40), Vector2(40, -10), Vector2(210, 40), Vector2(40, 90),
	])
	draw_colored_polygon(path, Color(0.42, 0.36, 0.24))

	var step := Vector2(56, 28)
	for ix in range(-8, 9):
		for iy in range(-8, 9):
			var c := Vector2(ix * step.x * 0.5 + iy * step.x * 0.5, -ix * step.y * 0.5 + iy * step.y * 0.5)
			var n := absf(c.x) / half.x + absf(c.y) / half.y
			if n > 0.92:
				continue
			var tile := PackedVector2Array([
				c + Vector2(0, -12),
				c + Vector2(22, 0),
				c + Vector2(0, 12),
				c + Vector2(-22, 0),
			])
			var shade := 0.02 * ((ix + iy) % 3)
			draw_colored_polygon(tile, Color(0.30 + shade, 0.46 + shade, 0.28 + shade, 0.5))

	_draw_talking_stone(Vector2(-40, 70))

	var trees := [
		Vector2(-260, -50), Vector2(-200, 90), Vector2(240, -70),
		Vector2(280, 60), Vector2(-80, -180), Vector2(90, 190),
		Vector2(-330, 30), Vector2(340, -20), Vector2(40, -230),
	]
	for t in trees:
		_draw_tree(t)

	# Soft hunting-ground markers
	draw_circle(Vector2(170, 60), 6.0, Color(0.55, 0.2, 0.15, 0.35))
	draw_circle(Vector2(-200, 0), 6.0, Color(0.35, 0.35, 0.45, 0.35))
	draw_circle(Vector2(0, -185), 7.0, Color(0.25, 0.45, 0.25, 0.4))


func _draw_talking_stone(at: Vector2) -> void:
	# Pedestal shadow
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(0, 28), at + Vector2(34, 40), at + Vector2(0, 48), at + Vector2(-34, 40),
	]), Color(0, 0, 0, 0.3))
	# Stone body — tall rune monolith
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-16, 20), at + Vector2(16, 20), at + Vector2(20, -10),
		at + Vector2(8, -48), at + Vector2(-8, -48), at + Vector2(-20, -10),
	]), Color(0.45, 0.48, 0.55))
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-10, 8), at + Vector2(10, 8), at + Vector2(12, -12),
		at + Vector2(4, -40), at + Vector2(-4, -40), at + Vector2(-12, -12),
	]), Color(0.58, 0.62, 0.70))
	# Rune glow
	draw_line(at + Vector2(0, -36), at + Vector2(0, -8), Color(0.55, 0.85, 1.0, 0.85), 2.0)
	draw_circle(at + Vector2(0, -42), 4.0, Color(0.7, 0.95, 1.0, 0.9))
	# Newbie ring
	draw_arc(at + Vector2(0, 24), 38.0, 0.0, TAU, 32, Color(0.75, 0.85, 0.55, 0.35), 2.0)


func _draw_tree(at: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(0, 18), at + Vector2(14, 28), at + Vector2(-14, 28),
	]), Color(0.25, 0.15, 0.08))
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(0, -36), at + Vector2(28, 10), at + Vector2(-28, 10),
	]), Color(0.18, 0.38, 0.22))
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(0, -22), at + Vector2(18, 4), at + Vector2(-18, 4),
	]), Color(0.24, 0.48, 0.28))
