extends CharacterBody2D

# Movimiento del personaje original, con controles WASD y conexión de power-ups.
const SPEED := 400.0
const ACCELERATION := 1800.0
const FRICTION := 2200.0
const JUMP_VELOCITY := -800.0
const JUMP_CUT_MULTIPLIER := 0.5
const STOMP_BOUNCE_MULTIPLIER := 0.55
const COYOTE_TIME := 0.12
const JUMP_BUFFER_TIME := 0.12
@export var animated_sprite_path: NodePath = NodePath("AnimatedSprite2D")

const POWER_UP_TEXTURES := {
	"azulito": preload("res://assets/azulito.png"),
	"coca_helada": preload("res://assets/coca_helada.png"),
	"malanga_picante": preload("res://assets/malanga_picante.png"),
	"volovan": preload("res://assets/volovan.png"),
	"taco": preload("res://assets/taco.png"),
}

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var facing_direction := Vector2.RIGHT
var _damage_cooldown := 0.0
var _effect_clock := 0.0
var _life_popup_time := 0.0
var _consume_progress := 0.0
var _held_item: Texture2D
var _base_scale := Vector2.ONE
var _sprite_base_scale := Vector2.ONE
var _growth_tween: Tween
var _damage_tween: Tween
var _consume_tween: Tween

@onready var animated_sprite: AnimatedSprite2D = get_node(animated_sprite_path) as AnimatedSprite2D
@onready var power_ups: PowerUpController = $PowerUpController

func _ready() -> void:
	_base_scale = scale
	_sprite_base_scale = animated_sprite.scale
	power_ups.power_up_collected.connect(_on_power_up_collected)
	power_ups.extra_life_added.connect(_on_extra_life_added)
	if animated_sprite.sprite_frames.has_animation("default"):
		animated_sprite.play("default")

func _physics_process(delta: float) -> void:
	_effect_clock += delta
	_damage_cooldown = maxf(0.0, _damage_cooldown - delta)
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("move_up"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	if Input.is_action_just_released("move_up") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		facing_direction = Vector2(signf(direction), 0.0)
		animated_sprite.scale.x = absf(_sprite_base_scale.x) * signf(direction)
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	_update_animation(direction)
	var was_falling := velocity.y > 0.0
	move_and_slide()
	_handle_enemy_collisions(was_falling)
	_update_visual_effects()

func _process(delta: float) -> void:
	_life_popup_time = maxf(0.0, _life_popup_time - delta)
	queue_redraw()

func collect_power_up(power_up_id: String) -> void:
	power_ups.activate(power_up_id)

## El sistema de enemigos puede llamar este método al golpear al personaje.
## Volován bloquea el daño; si Azulito está activo, el golpe quita el tamaño grande.
func take_damage() -> bool:
	if power_ups.is_invincible or _damage_cooldown > 0.0:
		return false
	_damage_cooldown = 0.7
	if power_ups.is_grown:
		if _growth_tween and _growth_tween.is_running():
			_growth_tween.kill()
		power_ups.reset_growth()
		if _damage_tween and _damage_tween.is_running():
			_damage_tween.kill()
		_damage_tween = create_tween()
		_damage_tween.tween_property(self, "scale", Vector2(0.78, 1.2) * _base_scale, 0.08)
		_damage_tween.tween_property(self, "scale", _base_scale, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	velocity.x = -facing_direction.x * 180.0
	velocity.y = -260.0
	return true

func _handle_enemy_collisions(was_falling: bool) -> void:
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var enemy: Node = collision.get_collider() as Node
		if enemy == null or not enemy.is_in_group("enemies"):
			continue
		if was_falling and collision.get_normal().y < -0.5:
			velocity.y = JUMP_VELOCITY * STOMP_BOUNCE_MULTIPLIER
			enemy.queue_free()
			return
		if absf(collision.get_normal().x) > 0.5:
			take_damage()

func _update_animation(direction: float) -> void:
	var wanted_animation := "idle"
	if not is_on_floor():
		if velocity.y < 0.0:
			wanted_animation = "jump"
		else:
			wanted_animation = "fall"
	elif not is_zero_approx(direction):
		wanted_animation = "walk"
	if animated_sprite.sprite_frames.has_animation(wanted_animation):
		animated_sprite.play(wanted_animation)
	elif animated_sprite.sprite_frames.has_animation("default"):
		animated_sprite.play("default")

func _update_visual_effects() -> void:
	var alpha := 0.18 if power_ups.is_effect_near_expiration() and int(_effect_clock * 8.0) % 2 == 0 else 1.0
	modulate = Color(1.0, 1.0, 1.0, alpha)
	if power_ups.attack_kind == "ice":
		animated_sprite.modulate = Color("#a8e9ff")
	elif power_ups.attack_kind == "fire":
		animated_sprite.modulate = Color("#ffd2a1")
	else:
		animated_sprite.modulate = Color.WHITE

func _on_power_up_collected(power_up_id: String) -> void:
	_held_item = POWER_UP_TEXTURES.get(power_up_id)
	_consume_progress = 0.0
	if _consume_tween and _consume_tween.is_running():
		_consume_tween.kill()
	_consume_tween = create_tween()
	_consume_tween.tween_property(self, "_consume_progress", 1.0, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_consume_tween.tween_callback(_finish_consuming)
	if power_up_id == "azulito":
		call_deferred("_animate_growth")
	queue_redraw()

func _animate_growth() -> void:
	if not power_ups.is_grown:
		return
	if _growth_tween and _growth_tween.is_running():
		_growth_tween.kill()
	scale = _base_scale * 0.82
	_growth_tween = create_tween()
	_growth_tween.tween_property(self, "scale", _base_scale * 1.65, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_growth_tween.tween_property(self, "scale", _base_scale * 1.34, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_growth_tween.tween_property(self, "scale", _base_scale * 1.5, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _finish_consuming() -> void:
	_held_item = null
	_consume_progress = 0.0
	queue_redraw()

func _on_extra_life_added(_total_lives: int) -> void:
	_life_popup_time = 1.2
	queue_redraw()

func _draw() -> void:
	if power_ups.attack_kind == "ice":
		_draw_ice_effect()
	elif power_ups.attack_kind == "fire":
		_draw_fire_effect()
	if power_ups.is_invincible:
		_draw_invincibility_aura()
	if _held_item:
		_draw_consumed_item()
	if _life_popup_time > 0.0:
		_draw_life_popup()

func _draw_ice_effect() -> void:
	var flicker := int(_effect_clock * 8.0) % 2
	var ice := Color(0.66, 0.93, 1.0, 0.85)
	draw_rect(Rect2(Vector2(-195, -185 - flicker * 2), Vector2(22, 22)), ice)
	draw_rect(Rect2(Vector2(173, -90), Vector2(22, 22)), ice)
	draw_rect(Rect2(Vector2(-180, 130 + flicker * 2), Vector2(18, 18)), ice)
	draw_rect(Rect2(Vector2(170, 150), Vector2(18, 18)), ice)

func _draw_fire_effect() -> void:
	var flicker := int(_effect_clock * 12.0) % 3
	var orange := Color("#ff8a36")
	var yellow := Color("#ffe27a")
	draw_rect(Rect2(Vector2(-205, -60 - flicker * 2), Vector2(24, 66 + flicker * 2)), orange)
	draw_rect(Rect2(Vector2(184, -170 + flicker * 2), Vector2(24, 74 - flicker * 2)), orange)
	draw_rect(Rect2(Vector2(-200, 92 + flicker), Vector2(16, 30)), yellow)
	draw_rect(Rect2(Vector2(190, 36 + flicker), Vector2(16, 32)), yellow)

func _draw_invincibility_aura() -> void:
	var pulse := 1.0 if int(_effect_clock * 8.0) % 2 == 0 else 0.55
	for i in range(6):
		var angle := _effect_clock * 2.0 + float(i) * TAU / 6.0
		var pos := Vector2(cos(angle) * 205.0, sin(angle) * 235.0)
		var color := Color(1.0, 0.84, 0.24, pulse) if i % 2 == 0 else Color(1.0, 1.0, 0.82, pulse)
		draw_rect(Rect2(pos, Vector2(22, 22)), color)

func _draw_consumed_item() -> void:
	var x_offset := facing_direction.x * 45.0
	var item_position := Vector2(x_offset, -285.0).lerp(Vector2(x_offset * 0.35, -175.0), _consume_progress)
	var item_size := Vector2(180, 180) * (1.0 - _consume_progress * 0.35)
	draw_set_transform(item_position, lerpf(-0.35, 0.0, _consume_progress))
	draw_texture_rect(_held_item, Rect2(-item_size * 0.5, item_size), false, Color(1, 1, 1, 1.0 - _consume_progress * 0.35))
	draw_set_transform(Vector2.ZERO, 0.0)

func _draw_life_popup() -> void:
	var alpha := minf(1.0, _life_popup_time * 2.0)
	var y := -310.0 - (1.2 - _life_popup_time) * 50.0
	var pink := Color(1.0, 0.25, 0.38, alpha)
	draw_rect(Rect2(Vector2(-80, y), Vector2(32, 32)), pink)
	draw_rect(Rect2(Vector2(-16, y), Vector2(32, 32)), pink)
	draw_rect(Rect2(Vector2(-96, y + 32), Vector2(144, 32)), pink)
	draw_rect(Rect2(Vector2(-64, y + 64), Vector2(80, 32)), pink)
	draw_rect(Rect2(Vector2(-32, y + 96), Vector2(32, 32)), pink)
	draw_string(ThemeDB.fallback_font, Vector2(64, y + 84), "+1", HORIZONTAL_ALIGNMENT_LEFT, -1, 72, Color.WHITE)
