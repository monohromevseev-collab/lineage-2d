extends Node2D
## Large seamless meadow tiles + talking stone. No hard playfield walls in view.


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var half := Vector2(1400, 1000)
	# Continuous grass field (axis-aligned expanse — feels walkable forever in-camera)
	draw_rect(Rect2(-half, half * 2.0), Color(0.22, 0.34, 0.20))

	# Soft biome tints
	draw_circle(Vector2(300, 80), 280.0, Color(0.28, 0.40, 0.22, 0.35))
	draw_circle(Vector2(-360, 20), 260.0, Color(0.20, 0.30, 0.22, 0.4))
	draw_circle(Vector2(40, -340), 300.0, Color(0.24, 0.36, 0.18, 0.35))

	# Isometric-ish tile mosaic across the field
	var step := Vector2(64, 32)
	for ix in range(-28, 29):
		for iy in range(-24, 25):
			var c := Vector2(ix * step.x * 0.5 + iy * step.x * 0.5, -ix * step.y * 0.5 + iy * step.y * 0.5)
			if absf(c.x) > half.x or absf(c.y) > half.y:
				continue
			var tile := PackedVector2Array([
				c + Vector2(0, -14),
				c + Vector2(26, 0),
				c + Vector2(0, 14),
				c + Vector2(-26, 0),
			])
			var shade := 0.015 * ((ix + iy * 3) % 5)
			draw_colored_polygon(tile, Color(0.26 + shade, 0.40 + shade, 0.24 + shade, 0.55))

	# Dirt paths radiating from talking stone
	_draw_path(Vector2(-40, 70), Vector2(420, 80))
	_draw_path(Vector2(-40, 70), Vector2(-420, 20))
	_draw_path(Vector2(-40, 70), Vector2(40, -360))

	_draw_talking_stone(Vector2(-40, 70))

	var trees := [
		Vector2(-260, -50), Vector2(-200, 90), Vector2(240, -70), Vector2(280, 60),
		Vector2(-80, -180), Vector2(90, 190), Vector2(-330, 30), Vector2(340, -20),
		Vector2(40, -230), Vector2(600, 100), Vector2(700, -80), Vector2(-600, 60),
		Vector2(-700, -120), Vector2(100, 420), Vector2(-150, 450), Vector2(450, 350),
		Vector2(-500, 300), Vector2(550, -300), Vector2(-100, -500), Vector2(200, -480),
	]
	for t in trees:
		_draw_tree(t)


func _draw_path(a: Vector2, b: Vector2) -> void:
	var steps := 18
	for i in range(steps + 1):
		var p: Vector2 = a.lerp(b, float(i) / float(steps))
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(0, -10), p + Vector2(18, 0), p + Vector2(0, 10), p + Vector2(-18, 0),
		]), Color(0.40, 0.34, 0.22, 0.55))


func _draw_talking_stone(at: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(0, 28), at + Vector2(34, 40), at + Vector2(0, 48), at + Vector2(-34, 40),
	]), Color(0, 0, 0, 0.3))
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-16, 20), at + Vector2(16, 20), at + Vector2(20, -10),
		at + Vector2(8, -48), at + Vector2(-8, -48), at + Vector2(-20, -10),
	]), Color(0.45, 0.48, 0.55))
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-10, 8), at + Vector2(10, 8), at + Vector2(12, -12),
		at + Vector2(4, -40), at + Vector2(-4, -40), at + Vector2(-12, -12),
	]), Color(0.58, 0.62, 0.70))
	draw_line(at + Vector2(0, -36), at + Vector2(0, -8), Color(0.55, 0.85, 1.0, 0.85), 2.0)
	draw_circle(at + Vector2(0, -42), 4.0, Color(0.7, 0.95, 1.0, 0.9))
	draw_arc(at + Vector2(0, 24), 42.0, 0.0, TAU, 40, Color(0.75, 0.85, 0.55, 0.4), 2.5)


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
