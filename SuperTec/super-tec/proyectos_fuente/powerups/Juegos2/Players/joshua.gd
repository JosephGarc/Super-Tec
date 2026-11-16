extends CharacterBody2D

# Ajustes del movimiento
const SPEED := 400.0
const ACCELERATION := 1800.0
const FRICTION := 2200.0
const JUMP_VELOCITY := -800.0
const JUMP_CUT_MULTIPLIER := 0.5
const STOMP_BOUNCE_MULTIPLIER := 0.55
const COYOTE_TIME := 0.12
const JUMP_BUFFER_TIME := 0.12

var coyote_timer := 0.0
var jump_buffer_timer := 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept"):
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

	if Input.is_action_just_released("ui_accept") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0.0:
		animated_sprite.scale.x = 1.0 if direction > 0.0 else -1.0
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	_update_animation(direction)
	var was_falling := velocity.y > 0.0
	move_and_slide()
	_handle_enemy_stomps(was_falling)


func _handle_enemy_stomps(was_falling: bool) -> void:
	if not was_falling:
		return

	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var enemy := collision.get_collider()
		if enemy is Node and enemy.is_in_group("enemies") and collision.get_normal().y < -0.5:
			velocity.y = JUMP_VELOCITY * STOMP_BOUNCE_MULTIPLIER
			enemy.queue_free()
			return


func _update_animation(direction: float) -> void:
	if not is_on_floor():
		if velocity.y < 0.0:
			animated_sprite.play("jump")
		else:
			animated_sprite.play("fall")
	elif not is_zero_approx(direction):
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")
