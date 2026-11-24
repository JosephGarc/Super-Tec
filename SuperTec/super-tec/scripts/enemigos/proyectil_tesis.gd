extends Area2D

var direccion := Vector2.LEFT
var rapidez := 125.0
var vida := 3.0

func _ready() -> void:
	body_entered.connect(_al_tocar)

func _physics_process(delta: float) -> void:
	global_position += direccion * rapidez * delta
	vida -= delta
	if vida <= 0.0:
		queue_free()

func _al_tocar(body: Node2D) -> void:
	if body.is_in_group("jugador") and body.has_method("take_damage"):
		body.take_damage()
		queue_free()
