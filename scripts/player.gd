extends CharacterBody2D
## Server-authoritative player. Local client sends input via GameWorld; server moves.

const MOVE_SPEED := 180.0

@onready var body_poly: Polygon2D = $Body
@onready var shadow_poly: Polygon2D = $Shadow
@onready var name_label: Label = $NameLabel
@onready var camera: Camera2D = $Camera2D

var peer_id: int = 0
var display_name: String = ""
var bot_mode: bool = false
var _zone_half: Vector2 = Vector2(420, 280)
var _input_dir: Vector2 = Vector2.ZERO
var _remote_target: Vector2 = Vector2.ZERO
var _has_remote_target: bool = false
var _bot_phase: float = 0.0

## Distinct colors so two clients are easy to tell apart in demos.
const PALETTE := [
	Color(0.85, 0.55, 0.25),
	Color(0.35, 0.65, 0.95),
	Color(0.55, 0.85, 0.45),
	Color(0.90, 0.40, 0.55),
	Color(0.75, 0.65, 0.95),
	Color(0.95, 0.85, 0.40),
]


func setup(id: int, pname: String, zone_half: Vector2) -> void:
	peer_id = id
	_zone_half = zone_half
	set_multiplayer_authority(1)
	set_display_name(pname)
	var color: Color = PALETTE[absi(id) % PALETTE.size()]
	body_poly.color = color
	# Soft isometric diamond silhouette.
	body_poly.polygon = PackedVector2Array([
		Vector2(0, -22), Vector2(16, -6), Vector2(10, 14),
		Vector2(0, 20), Vector2(-10, 14), Vector2(-16, -6),
	])
	shadow_poly.polygon = PackedVector2Array([
		Vector2(0, 8), Vector2(18, 18), Vector2(0, 26), Vector2(-18, 18),
	])
	shadow_poly.color = Color(0, 0, 0, 0.35)

	# Camera only on the locally controlled client avatar.
	var is_local := multiplayer.has_multiplayer_peer() \
		and not multiplayer.is_server() \
		and multiplayer.get_unique_id() == peer_id
	camera.enabled = is_local
	if is_local:
		camera.make_current()


func set_display_name(pname: String) -> void:
	display_name = pname
	if name_label:
		name_label.text = pname


func is_local_client() -> bool:
	return multiplayer.has_multiplayer_peer() \
		and not multiplayer.is_server() \
		and multiplayer.get_unique_id() == peer_id


func poll_input(delta: float) -> Vector2:
	var dir := Vector2.ZERO
	if bot_mode:
		_bot_phase += delta
		dir = Vector2(cos(_bot_phase * 0.7 + float(peer_id % 97)), sin(_bot_phase * 0.55)).normalized()
	else:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return dir


func receive_input(dir: Vector2) -> void:
	_input_dir = dir.limit_length(1.0)


func server_tick(delta: float) -> void:
	if _input_dir != Vector2.ZERO:
		position += _input_dir.normalized() * MOVE_SPEED * delta
	position = clamp_to_zone(position)


func predict_local(dir: Vector2, delta: float) -> void:
	if dir != Vector2.ZERO:
		position += dir.normalized() * MOVE_SPEED * delta
		position = clamp_to_zone(position)


func apply_authoritative(pos: Vector2) -> void:
	if is_local_client():
		position = position.lerp(pos, 0.35)
		position = clamp_to_zone(position)
	else:
		_remote_target = pos
		_has_remote_target = true


func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		return
	if not is_local_client() and _has_remote_target:
		position = position.lerp(_remote_target, clampf(12.0 * delta, 0.0, 1.0))


func clamp_to_zone(pos: Vector2) -> Vector2:
	# Soft diamond bound approximating an isometric meadow.
	var q := Vector2(absf(pos.x) / _zone_half.x, absf(pos.y) / _zone_half.y)
	var m := q.x + q.y
	if m <= 1.0:
		return pos
	return pos / m
