extends Area2D

@export var move_speed: float = 80.0
@export var patrol_width: float = 90.0
@export var health: float = 5.0
@export var contact_damage_cooldown: float = 1.0
var slow_time_left: float = 0.0
var burn_time_left: float = 0.0
var _burn_tick: float = 1.0
var _contact_cooldown_left: float = 0.0
var _direction: float = 1.0
var _origin_x: float

func _ready() -> void:
	_origin_x = position.x
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	slow_time_left = maxf(0.0, slow_time_left - delta)
	burn_time_left = maxf(0.0, burn_time_left - delta)
	_contact_cooldown_left = maxf(0.0, _contact_cooldown_left - delta)
	position.x += _direction * move_speed * (0.25 if slow_time_left > 0.0 else 1.0) * delta
	if absf(position.x - _origin_x) >= patrol_width:
		_direction *= -1.0
	if burn_time_left > 0.0:
		_burn_tick -= delta
		if _burn_tick <= 0.0:
			health -= 1.0
			_burn_tick = 1.0
			if health <= 0.0:
				queue_free()
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if _contact_cooldown_left <= 0.0 and body.has_method("take_damage"):
		body.take_damage()
		_contact_cooldown_left = contact_damage_cooldown

func receive_power_up_attack(kind: String, duration: float) -> void:
	if kind == "ice":
		slow_time_left = duration
	elif kind == "fire":
		burn_time_left = duration
		_burn_tick = minf(_burn_tick, 1.0)

func _draw() -> void:
	var color := Color("#d75555")
	if slow_time_left > 0.0:
		color = Color("#65ccff")
	elif burn_time_left > 0.0:
		color = Color("#ff9d38")
	draw_rect(Rect2(Vector2(-15, -15), Vector2(30, 30)), color)
	draw_rect(Rect2(Vector2(-8, -5), Vector2(5, 5)), Color.WHITE)
	draw_rect(Rect2(Vector2(4, -5), Vector2(5, 5)), Color.WHITE)
