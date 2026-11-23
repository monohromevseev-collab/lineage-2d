extends Node2D
## Simple isometric meadow: diamond tiles + trees (placeholder art for slice 0).


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var half := Vector2(420, 280)
	# Ground diamond
	var ground := PackedVector2Array([
		Vector2(0, -half.y),
		Vector2(half.x, 0),
		Vector2(0, half.y),
		Vector2(-half.x, 0),
	])
	draw_colored_polygon(ground, Color(0.28, 0.42, 0.26))
	# Inner path diamond
	var path := PackedVector2Array([
		Vector2(0, -half.y * 0.35),
		Vector2(half.x * 0.35, 0),
		Vector2(0, half.y * 0.35),
		Vector2(-half.x * 0.35, 0),
	])
	draw_colored_polygon(path, Color(0.40, 0.34, 0.24))

	# Grid of soft isometric diamonds
	var step := Vector2(56, 28)
	for ix in range(-7, 8):
		for iy in range(-7, 8):
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
			draw_colored_polygon(tile, Color(0.30 + shade, 0.46 + shade, 0.28 + shade, 0.55))

	# Trees (simple cones) — decorative only, no collision in slice 0
	var trees := [
		Vector2(-220, -40), Vector2(-180, 70), Vector2(200, -60),
		Vector2(240, 50), Vector2(-60, -150), Vector2(70, 160),
		Vector2(-300, 20), Vector2(310, -10),
	]
	for t in trees:
		_draw_tree(t)


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
