extends CharacterBody2D

const SPEED := 200.0
const JUMP_VELOCITY := -400.0
const FRAME_SIZE := Vector2(352.0, 508.0)
const FALL_MARGIN_CELLS := 6

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var follow_camera: Camera2D = get_node_or_null("Camera2D")
var jump_requested := false
var spawn_position := Vector2.ZERO
var fall_limit_y := 600.0

func _ready() -> void:
	floor_max_angle = deg_to_rad(65.0)
	floor_snap_length = 12.0
	floor_constant_speed = true
	spawn_position = global_position
	fall_limit_y = _find_fall_limit_y()
	animated_sprite.sprite_frames = _create_sprite_frames()
	animated_sprite.play("idle")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_W:
		jump_requested = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if jump_requested and is_on_floor():
		velocity.y = JUMP_VELOCITY
	jump_requested = false

	var direction := 0.0
	if Input.is_physical_key_pressed(KEY_A):
		direction -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		direction += 1.0

	if direction != 0.0:
		animated_sprite.flip_h = direction < 0.0
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	_update_animation(direction)
	move_and_slide()
	if global_position.y > fall_limit_y:
		_respawn_at_start()

func _find_fall_limit_y() -> float:
	var limit := spawn_position.y + 600.0
	var body_bottom_offset := 0.0
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape != null and body_shape.shape is RectangleShape2D:
		body_bottom_offset = body_shape.position.y + (body_shape.shape as RectangleShape2D).size.y * 0.5

	for sibling in get_parent().get_children():
		if sibling is TileMapLayer and sibling.tile_set != null:
			var map_layer: TileMapLayer = sibling as TileMapLayer
			var used_rect: Rect2i = map_layer.get_used_rect()
			if used_rect.size.y > 0:
				var cell_below_map := Vector2i(used_rect.position.x, used_rect.end.y + FALL_MARGIN_CELLS)
				var map_cell_position: Vector2 = map_layer.map_to_local(cell_below_map)
				var map_cell_global_position: Vector2 = map_layer.to_global(map_cell_position)
				var candidate_y: float = map_cell_global_position.y - body_bottom_offset
				limit = maxf(limit, candidate_y)
	return limit

func _respawn_at_start() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	jump_requested = false
	animated_sprite.play("idle")
	if follow_camera != null:
		follow_camera.reset_smoothing()

func _update_animation(direction: float) -> void:
	if not is_on_floor():
		animated_sprite.play("jump" if velocity.y < 0.0 else "fall")
	elif direction != 0.0:
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")

func _create_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	for animation_name in frames.get_animation_names():
		frames.remove_animation(animation_name)

	_add_sheet_animation(frames, "idle", "res://idle.png", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)], 2.0, true)
	_add_sheet_animation(frames, "walk", "res://walk.png", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)], 8.0, true)
	_add_sheet_animation(frames, "jump", "res://jump.png", [Vector2i(0, 0), Vector2i(1, 0)], 8.0, false)
	_add_sheet_animation(frames, "fall", "res://jump.png", [Vector2i(1, 1)], 1.0, true)
	return frames

func _add_sheet_animation(frames: SpriteFrames, animation_name: String, sheet_path: String, cells: Array[Vector2i], fps: float, loops: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loops)
	var sheet := load(sheet_path) as Texture2D
	for cell in cells:
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(Vector2(cell) * FRAME_SIZE, FRAME_SIZE)
		frames.add_frame(animation_name, frame)