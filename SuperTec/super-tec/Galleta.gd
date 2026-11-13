extends CharacterBody2D

# Velocidad de movimiento del enemigo
@export var speed: float = 80.0

# Dirección inicial (1 para la derecha, -1 para la izquierda)
var direction: int = -1

# Referencia al nodo RayCast2D que mira hacia abajo y adelante (para detectar el borde)
@onready var edge_detector: RayCast2D = $EdgeDetector

# Referencia al área de daño superior (para cuando el jugador le cae encima)
@onready var jump_on_detector: Area2D = $JumpOnDetector

func _physics_process(delta: float) -> void:
	# 1. Aplicar gravedad si está en el aire
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Comprobar si hay suelo en frente (Detección de orilla)
	if is_on_floor():
		# Si el RayCast deja de detectar suelo O choca contra una pared lateral, cambia de dirección
		if not edge_detector.is_colliding() or is_on_wall():
			direction *= -1
			# Invertimos la posición horizontal del RayCast para que apunte hacia el nuevo lado
			edge_detector.position.x *= -1

	# 3. Aplicar velocidad horizontal según la dirección
	velocity.x = direction * speed

	# 4. Mover al enemigo
	move_and_slide()

# Esta función se conecta a la señal "body_entered" del nodo JumpOnDetector (Area2D)
func _on_jump_on_detector_body_entered(body: Node2D) -> void:
	# Verificamos que el que tocó el área superior sea el jugador
	if body.name == "CharacterBody2D" or body.is_in_group("jugador"):
		# Opcional: Impulso hacia arriba para el jugador al aplastarlo
		if body.has_method("jump") or "velocity" in body:
			body.velocity.y = -350.0 
			
		# Elimina al enemigo de la escena
		queue_free()
