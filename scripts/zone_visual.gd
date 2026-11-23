extends Node2D
## Cedric's Training Hall / library as the primary start, with a path west toward the village.


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var half := Vector2(1400, 1000)
	# Outer grounds (muted grass beyond the hall)
	draw_rect(Rect2(-half, half * 2.0), Color(0.16, 0.22, 0.16))

	# Village path west
	_draw_dirt_path(Vector2(-40, 50), Vector2(-700, -10))
	_draw_dirt_path(Vector2(-700, -10), Vector2(-1100, 20))

	# Soft meadow patches far west (wolves / orcs)
	draw_circle(Vector2(-560, 0), 220.0, Color(0.22, 0.32, 0.18, 0.35))
	draw_circle(Vector2(-1000, 20), 260.0, Color(0.20, 0.28, 0.16, 0.4))

	_draw_library_hall()
	_draw_village_markers()

	# Trees along the path, not inside the hall
	for t in [
		Vector2(-280, -90), Vector2(-340, 80), Vector2(-450, -60), Vector2(-600, 90),
		Vector2(-750, -120), Vector2(-900, 50), Vector2(-1050, -80),
	]:
		_draw_tree(t)


func _draw_library_hall() -> void:
	# Stone foundation
	var hall := Rect2(-160, -120, 360, 280)
	draw_rect(hall, Color(0.28, 0.27, 0.30))
	# Inner floor tiles
	for ix in range(-5, 6):
		for iy in range(-4, 5):
			var c := Vector2(ix * 28.0, iy * 22.0)
			if not hall.has_point(c):
				continue
			var shade := 0.02 * ((ix + iy * 2) % 3)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -10), c + Vector2(14, 0), c + Vector2(0, 10), c + Vector2(-14, 0),
			]), Color(0.42 + shade, 0.40 + shade, 0.38 + shade, 0.85))

	# Bookshelf walls (north / south)
	for i in range(-4, 5):
		_draw_bookshelf(Vector2(i * 32.0, -100))
		_draw_bookshelf(Vector2(i * 32.0, 130))
	# Pillars
	for p in [Vector2(-120, -40), Vector2(140, -40), Vector2(-120, 80), Vector2(140, 80)]:
		_draw_pillar(p)

	# Stained-glass glow (teal / gold)
	draw_circle(Vector2(0, -90), 36.0, Color(0.25, 0.55, 0.55, 0.35))
	draw_circle(Vector2(0, -90), 18.0, Color(0.75, 0.65, 0.25, 0.25))

	# Lectern / talking-stone stand-in near Helper
	_draw_lectern(Vector2(-10, 55))

	# Doorway west toward village
	draw_rect(Rect2(-168, 20, 18, 50), Color(0.18, 0.14, 0.12))
	draw_rect(Rect2(-166, 24, 14, 42), Color(0.35, 0.28, 0.18))

	# Hall label
	# (drawn via world props only — no Label node here)


func _draw_bookshelf(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-12, -18), Vector2(24, 36)), Color(0.32, 0.22, 0.14))
	for row in range(3):
		draw_line(
			at + Vector2(-10, -12 + row * 10),
			at + Vector2(10, -12 + row * 10),
			Color(0.55, 0.35, 0.18), 2.0
		)
		draw_rect(Rect2(at + Vector2(-8, -10 + row * 10), Vector2(5, 6)), Color(0.2, 0.45, 0.5))
		draw_rect(Rect2(at + Vector2(-1, -10 + row * 10), Vector2(5, 6)), Color(0.55, 0.25, 0.2))
		draw_rect(Rect2(at + Vector2(6, -10 + row * 10), Vector2(4, 6)), Color(0.7, 0.6, 0.25))


func _draw_pillar(at: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-10, 18), at + Vector2(10, 18), at + Vector2(8, -28), at + Vector2(-8, -28),
	]), Color(0.45, 0.44, 0.48))
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-12, -28), at + Vector2(12, -28), at + Vector2(10, -36), at + Vector2(-10, -36),
	]), Color(0.55, 0.52, 0.48))


func _draw_lectern(at: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(0, 18), at + Vector2(22, 28), at + Vector2(0, 34), at + Vector2(-22, 28),
	]), Color(0, 0, 0, 0.28))
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-10, 10), at + Vector2(10, 10), at + Vector2(14, -8),
		at + Vector2(4, -26), at + Vector2(-4, -26), at + Vector2(-14, -8),
	]), Color(0.5, 0.42, 0.32))
	draw_circle(at + Vector2(0, -30), 5.0, Color(0.7, 0.9, 1.0, 0.85))
	draw_arc(at + Vector2(0, 14), 28.0, 0.0, TAU, 28, Color(0.75, 0.85, 0.55, 0.35), 2.0)


func _draw_village_markers() -> void:
	# Simple hut outlines near Darin / Roxxy cluster
	for hut in [Vector2(-700, 10), Vector2(-760, -30), Vector2(-720, 60)]:
		draw_colored_polygon(PackedVector2Array([
			hut + Vector2(-20, 10), hut + Vector2(20, 10), hut + Vector2(16, -8), hut + Vector2(-16, -8),
		]), Color(0.4, 0.32, 0.22, 0.7))
		draw_colored_polygon(PackedVector2Array([
			hut + Vector2(0, -28), hut + Vector2(22, -6), hut + Vector2(-22, -6),
		]), Color(0.45, 0.25, 0.18, 0.8))


func _draw_dirt_path(a: Vector2, b: Vector2) -> void:
	var steps := 22
	for i in range(steps + 1):
		var p: Vector2 = a.lerp(b, float(i) / float(steps))
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(0, -9), p + Vector2(16, 0), p + Vector2(0, 9), p + Vector2(-16, 0),
		]), Color(0.38, 0.32, 0.22, 0.5))


func _draw_tree(at: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(0, 18), at + Vector2(12, 26), at + Vector2(-12, 26),
	]), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(at + Vector2(-3, 0), Vector2(6, 16)), Color(0.35, 0.22, 0.12))
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(0, -28), at + Vector2(22, 6), at + Vector2(-22, 6),
	]), Color(0.18, 0.36, 0.2))
