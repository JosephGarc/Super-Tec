extends CharacterBody2D

const SPEED := 200.0
const JUMP_VELOCITY := -400.0
const FRAME_SIZE := Vector2(352.0, 508.0)
const FALL_MARGIN_CELLS := 6
const SMALL_PLAYER_SCALE := 0.5
const FIREBALL_SCENE: PackedScene = preload("res://escenas/powerups/fireball.tscn")
const ORIGINAL_COLLISION_SIZE := Vector2(14.0, 30.0)
const SMALL_COLLISION_SIZE := ORIGINAL_COLLISION_SIZE * SMALL_PLAYER_SCALE
const FIREBALL_COOLDOWN := 0.3

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var follow_camera: Camera2D = get_node_or_null("Camera2D")
var jump_requested := false
var spawn_position := Vector2.ZERO
var fall_limit_y := 600.0
var has_fire_power := false
var fireball_cooldown := 0.0
var original_sprite_scale := Vector2.ONE

func _ready() -> void:
	floor_max_angle = deg_to_rad(65.0)
	floor_snap_length = 12.0
	floor_constant_speed = true
	spawn_position = global_position
	fall_limit_y = _find_fall_limit_y()
	animated_sprite.sprite_frames = _create_sprite_frames()
	original_sprite_scale = animated_sprite.scale
	animated_sprite.scale = original_sprite_scale * SMALL_PLAYER_SCALE
	_set_collision_size(SMALL_COLLISION_SIZE)
	add_to_group("jugador")
	animated_sprite.play("idle")

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode == KEY_W:
		jump_requested = true
	elif event.physical_keycode == KEY_SPACE and has_fire_power:
		_shoot_fireball()

func _physics_process(delta: float) -> void:
	fireball_cooldown = maxf(0.0, fireball_cooldown - delta)
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
	var was_falling := velocity.y > 0.0
	move_and_slide()
	_handle_enemy_collisions(was_falling)
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

func collect_power_up(power_up_id: String) -> void:
	match power_up_id:
		"azulito":
			animated_sprite.scale = original_sprite_scale
			_set_collision_size(ORIGINAL_COLLISION_SIZE)
		"malanga_fuego":
			has_fire_power = true

func _shoot_fireball() -> void:
	if fireball_cooldown > 0.0:
		return
	var fireball := FIREBALL_SCENE.instantiate() as Node2D
	if fireball == null:
		return
	get_tree().current_scene.add_child(fireball)
	var direction := -1.0 if animated_sprite.flip_h else 1.0
	fireball.global_position = animated_sprite.global_position + Vector2(direction * 18.0, -4.0)
	fireball.set("direction", direction)
	fireball_cooldown = FIREBALL_COOLDOWN

func _set_collision_size(size: Vector2) -> void:
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape == null:
		return
	if body_shape.shape is RectangleShape2D:
		var rectangle := (body_shape.shape as RectangleShape2D).duplicate() as RectangleShape2D
		rectangle.size = size
		body_shape.shape = rectangle

func _handle_enemy_collisions(was_falling: bool) -> void:
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var enemy := collision.get_collider() as Node
		if enemy == null or not enemy.is_in_group("enemies"):
			continue
		if was_falling and collision.get_normal().y < -0.5:
			enemy.queue_free()
			velocity.y = JUMP_VELOCITY * 0.55
			return
		_respawn_at_start()
		return

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

	_add_sheet_animation(frames, "idle", "res://assets/personajes/idle.png", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)], 2.0, true)
	_add_sheet_animation(frames, "walk", "res://assets/personajes/walk.png", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)], 8.0, true)
	_add_sheet_animation(frames, "jump", "res://assets/personajes/jump.png", [Vector2i(0, 0), Vector2i(1, 0)], 8.0, false)
	_add_sheet_animation(frames, "fall", "res://assets/personajes/jump.png", [Vector2i(1, 1)], 1.0, true)
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
