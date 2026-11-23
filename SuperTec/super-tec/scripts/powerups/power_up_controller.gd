extends Node
class_name PowerUpController

const SONIDO := preload("res://scripts/juego/sonido.gd")

## Componente para agregar como hijo del personaje. El personaje debe
## exponer `facing_direction: Vector2` y `collect_power_up(id: String)`.
## Hecho por Joseph (proyecto Godot_Joshua_PowerUps) e integrado a Super Tec.
## Si el personaje tiene los métodos crecer()/encoger(), se usan para el azulito
## (así cambia también la colisión y puede romper ladrillos).
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
	# Disparo con Espacio (tecla física, como el resto de los controles WASD)
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_SPACE and attack_kind != "":
		_shoot()

func activate(power_up_id: String) -> void:
	power_up_collected.emit(power_up_id)
	match power_up_id:
		"azulito":
			if not is_grown:
				is_grown = true
				if character.has_method("crecer"):
					character.crecer()
				else:
					character.scale = _original_scale * 1.5
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
		is_grown = false
		if character.has_method("encoger"):
			character.encoger()
		else:
			character.scale = _original_scale

## Quita todos los efectos (se usa cuando el personaje muere).
func reset_effects() -> void:
	reset_growth()
	attack_kind = ""
	_attack_time_left = 0.0
	is_invincible = false
	_invincibility_time_left = 0.0

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
	var projectile := projectile_scene.instantiate() as Area2D   # projectile.gd
	if projectile == null:
		return
	projectile.set("attack_kind", attack_kind)
	projectile.set("direction", _facing_direction())
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = character.global_position + _facing_direction() * projectile_spawn_offset
	SONIDO.efecto("disparo_hielo" if attack_kind == "ice" else "disparo_fuego")

func _facing_direction() -> Vector2:
	if character.get("facing_direction") is Vector2:
		var facing: Vector2 = character.get("facing_direction")
		if facing != Vector2.ZERO:
			return facing.normalized()
	return Vector2.RIGHT
