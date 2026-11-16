extends CharacterBody2D

@export var speed := 70.0
@export var patrol_left := -40.0
@export var patrol_right := 40.0
@export var use_floor_detector := true
var direction := -1.0
var start_x := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_detector: RayCast2D = $FloorDetector

func _ready() -> void:
	add_to_group("enemies")
	start_x = global_position.x
	floor_snap_length = 8.0
	floor_constant_speed = true
	sprite.play("walk")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	var left_limit := start_x + patrol_left
	var right_limit := start_x + patrol_right
	if direction < 0.0 and global_position.x <= left_limit:
		direction = 1.0
	elif direction > 0.0 and global_position.x >= right_limit:
		direction = -1.0
	elif use_floor_detector and is_on_floor():
		floor_detector.position.x = direction * 6.0
		floor_detector.force_raycast_update()
		if not floor_detector.is_colliding() or is_on_wall():
			direction *= -1.0
	velocity.x = direction * speed
	sprite.flip_h = direction < 0.0
	move_and_slide()

func receive_power_up_attack(attack_kind: String, _damage: float = 1.0) -> void:
	if attack_kind == "fire":
		queue_free()
