extends CharacterBody2D

const SPEED := 90.0
const PATROL_DISTANCE := 100.0

var direction := 1.0
var start_x := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	start_x = global_position.x
	sprite.play("walk")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if global_position.x >= start_x + PATROL_DISTANCE:
		direction = -1.0
	elif global_position.x <= start_x - PATROL_DISTANCE:
		direction = 1.0

	velocity.x = direction * SPEED
	sprite.flip_h = direction > 0.0
	move_and_slide()

	# Si choca con una pared, cambia de sentido.
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		if absf(collision.get_normal().x) > 0.7:
			direction *= -1.0
			break

