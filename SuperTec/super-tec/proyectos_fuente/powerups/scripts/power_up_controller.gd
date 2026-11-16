extends Node
class_name PowerUpController

## Componente para agregar como hijo del personaje. El personaje debe
## exponer `facing_direction: Vector2` y `collect_power_up(id: String)`.
signal power_up_collected(power_up_id: String)
signal power_up_expired(power_up_id: String)
signal extra_life_added(total_lives: int)

@export var projectile_scene: PackedScene
@export var projectile_spawn_offset: float = 24.0
@export var attack_duration: float = 10.0
@export var invincibility_duration: float = 8.0
@export var starting_lives: int = 3

var lives: int
var is_invincible: bool = false
var is_grown: bool = false
var attack_kind: String = ""
var _attack_time_left: float = 0.0
var _invincibility_time_left: float = 0.0
var _original_scale: Vector2 = Vector2.ONE

@onready var character: Node2D = get_parent() as Node2D

func _ready() -> void:
	lives = starting_lives
	_original_scale = character.scale

func _process(delta: float) -> void:
	if _attack_time_left > 0.0:
		_attack_time_left -= delta
		if _attack_time_left <= 0.0:
			attack_kind = ""
			power_up_expired.emit("ataque")

	if _invincibility_time_left > 0.0:
		_invincibility_time_left -= delta
		if _invincibility_time_left <= 0.0:
			is_invincible = false
			power_up_expired.emit("volovan")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot") and attack_kind != "":
		_shoot()

func activate(power_up_id: String) -> void:
	power_up_collected.emit(power_up_id)
	match power_up_id:
		"azulito":
			if not is_grown:
				character.scale = _original_scale * 1.5
				is_grown = true
		"coca_helada":
			_start_attack("ice")
		"malanga_picante":
			_start_attack("fire")
		"volovan":
			is_invincible = true
			_invincibility_time_left = invincibility_duration
		"taco":
			lives += 1
			extra_life_added.emit(lives)

func reset_growth() -> void:
	if is_grown:
		character.scale = _original_scale
		is_grown = false

func is_effect_near_expiration(warning_time: float = 3.0) -> bool:
	var attack_is_ending := attack_kind != "" and _attack_time_left > 0.0 and _attack_time_left <= warning_time
	var invincibility_is_ending := is_invincible and _invincibility_time_left > 0.0 and _invincibility_time_left <= warning_time
	return attack_is_ending or invincibility_is_ending

func _start_attack(kind: String) -> void:
	attack_kind = kind
	_attack_time_left = attack_duration

func _shoot() -> void:
	if projectile_scene == null:
		return
	var projectile := projectile_scene.instantiate() as PowerUpProjectile
	if projectile == null:
		return
	projectile.attack_kind = attack_kind
	projectile.direction = _facing_direction()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = character.global_position + projectile.direction * projectile_spawn_offset

func _facing_direction() -> Vector2:
	if character.get("facing_direction") is Vector2:
		var facing: Vector2 = character.get("facing_direction")
		if facing != Vector2.ZERO:
			return facing.normalized()
	return Vector2.RIGHT
