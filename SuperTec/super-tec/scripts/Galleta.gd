extends CharacterBody2D

## =====================================================================
##  GALLETA — Máquina de Estados Finitos (FSM)
## =====================================================================
##  Estados:
##    PATRULLAR  -> camina de un lado a otro alrededor de su punto de inicio
##    PERSEGUIR  -> vio a Joshua y lo sigue (más rápido)
##    VOLVER     -> perdió a Joshua y regresa a su punto de inicio
##
##  Transiciones:
##    PATRULLAR -> PERSEGUIR : Joshua está dentro del rango de visión,
##                             enfrente de ella y sin pared de por medio
##    PERSEGUIR -> VOLVER    : Joshua se aleja más del rango de persecución,
##                             o la Galleta se aleja demasiado de su zona,
##                             o lleva un rato sin verlo
##    VOLVER    -> PERSEGUIR : vuelve a ver a Joshua en el camino
##    VOLVER    -> PATRULLAR : llegó a su punto de inicio
##
##  Cada estado tiene su función (_estado_patrullar, _estado_perseguir,
##  _estado_volver) y todos los cambios pasan por _cambiar_estado().
## =====================================================================

enum Estado { PATRULLAR, PERSEGUIR, VOLVER }

signal estado_cambiado(anterior: Estado, nuevo: Estado)

# --- Velocidades de cada estado ---
@export var speed := 40.0                 ## velocidad al patrullar
@export var velocidad_persecucion := 80.0
@export var velocidad_regreso := 55.0

# --- Zona de patrulla (relativa al punto de inicio) ---
@export var patrol_left := -40.0
@export var patrol_right := 40.0
@export var use_floor_detector := true

# --- Percepción ---
@export var rango_vision := 110.0         ## distancia a la que detecta a Joshua
@export var altura_vision := 40.0         ## diferencia de altura máxima para verlo
@export var rango_persecucion := 170.0    ## si Joshua se aleja más, lo deja de seguir
@export var distancia_max_de_casa := 220.0  ## no se aleja más que esto de su inicio
@export var tiempo_sin_verlo := 1.5       ## segundos sin verlo antes de regresar

# --- Para la presentación: muestra el estado arriba de la Galleta ---
@export var mostrar_estado := true

const NOMBRES := ["PATRULLAR", "PERSEGUIR", "VOLVER"]
const COLORES := [Color(1, 1, 1), Color(1, 0.55, 0.55), Color(0.65, 0.8, 1)]
const DURACION_CONGELADA := 3.0

var estado: Estado = Estado.PATRULLAR
var direction := -1.0
var start_x := 0.0
var _jugador: Node2D = null
var _segundos_sin_verlo := 0.0
var _congelada := 0.0
var _etiqueta: Label

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_detector: RayCast2D = $FloorDetector


func _ready() -> void:
	add_to_group("enemies")
	start_x = global_position.x
	floor_snap_length = 8.0
	floor_constant_speed = true
	sprite.play("walk")
	_crear_etiqueta()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if _jugador == null or not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as Node2D

	# Congelada por la coca helada: no piensa ni se mueve un rato
	if _congelada > 0.0:
		_congelada -= delta
		velocity.x = 0.0
		if _congelada <= 0.0:
			sprite.modulate = COLORES[estado]
			sprite.play("walk")
		move_and_slide()
		return

	# ---- La máquina de estados ----
	match estado:
		Estado.PATRULLAR: _estado_patrullar(delta)
		Estado.PERSEGUIR: _estado_perseguir(delta)
		Estado.VOLVER: _estado_volver(delta)

	sprite.flip_h = direction < 0.0
	move_and_slide()


# ---------------------------------------------------------------------
#  Estado PATRULLAR: va y viene entre patrol_left y patrol_right
# ---------------------------------------------------------------------
func _estado_patrullar(_delta: float) -> void:
	if _ve_al_jugador():
		_cambiar_estado(Estado.PERSEGUIR)
		return
	var limite_izq := start_x + patrol_left
	var limite_der := start_x + patrol_right
	if direction < 0.0 and global_position.x <= limite_izq:
		direction = 1.0
	elif direction > 0.0 and global_position.x >= limite_der:
		direction = -1.0
	elif _hay_obstaculo_enfrente():
		direction *= -1.0
	velocity.x = direction * speed


# ---------------------------------------------------------------------
#  Estado PERSEGUIR: camina hacia Joshua
# ---------------------------------------------------------------------
func _estado_perseguir(delta: float) -> void:
	if _jugador == null:
		_cambiar_estado(Estado.VOLVER)
		return
	if _ve_al_jugador(rango_persecucion):
		_segundos_sin_verlo = 0.0
	else:
		_segundos_sin_verlo += delta

	var lejos_del_jugador := global_position.distance_to(_jugador.global_position) > rango_persecucion
	var lejos_de_casa := absf(global_position.x - start_x) > distancia_max_de_casa
	if lejos_del_jugador or lejos_de_casa or _segundos_sin_verlo > tiempo_sin_verlo:
		_cambiar_estado(Estado.VOLVER)
		return

	var dx := _jugador.global_position.x - global_position.x
	if absf(dx) > 4.0:
		direction = signf(dx)
	# No se avienta al vacío: si no hay piso enfrente, se queda esperando
	velocity.x = 0.0 if _hay_obstaculo_enfrente() else direction * velocidad_persecucion


# ---------------------------------------------------------------------
#  Estado VOLVER: regresa a su punto de inicio
# ---------------------------------------------------------------------
func _estado_volver(_delta: float) -> void:
	if _ve_al_jugador():
		_cambiar_estado(Estado.PERSEGUIR)
		return
	var dx := start_x - global_position.x
	if absf(dx) <= 4.0:
		_cambiar_estado(Estado.PATRULLAR)
		return
	direction = signf(dx)
	velocity.x = 0.0 if _hay_obstaculo_enfrente() else direction * velocidad_regreso


# ---------------------------------------------------------------------
#  Cambio de estado (un solo lugar para todas las transiciones)
# ---------------------------------------------------------------------
func _cambiar_estado(nuevo: Estado) -> void:
	if nuevo == estado:
		return
	var anterior := estado
	estado = nuevo
	_segundos_sin_verlo = 0.0
	sprite.modulate = COLORES[estado]
	sprite.speed_scale = 1.6 if estado == Estado.PERSEGUIR else 1.0
	if _etiqueta:
		_etiqueta.text = NOMBRES[estado]
		_etiqueta.modulate = COLORES[estado]
	estado_cambiado.emit(anterior, nuevo)
	print("Galleta %s: %s -> %s" % [name, NOMBRES[anterior], NOMBRES[nuevo]])


# ---------------------------------------------------------------------
#  Percepción
# ---------------------------------------------------------------------
# Ve a Joshua si está cerca, a una altura parecida, enfrente (o muy pegado)
# y sin pared entre los dos.
func _ve_al_jugador(rango: float = rango_vision) -> bool:
	if _jugador == null or not _jugador.visible:
		return false
	var dif := _jugador.global_position - global_position
	if absf(dif.x) > rango or absf(dif.y) > altura_vision:
		return false
	var esta_enfrente := signf(dif.x) == direction or absf(dif.x) < 24.0
	if not esta_enfrente and estado == Estado.PATRULLAR:
		return false
	var consulta := PhysicsRayQueryParameters2D.create(global_position, _jugador.global_position, 1 | 16)
	consulta.exclude = [get_rid()]
	var choque := get_world_2d().direct_space_state.intersect_ray(consulta)
	# Si lo primero que choca es el mapa o un bloque, hay pared de por medio
	return choque.is_empty() or not (choque.collider is TileMapLayer or choque.collider is StaticBody2D)


# Hay pared enfrente o se acaba el piso
func _hay_obstaculo_enfrente() -> bool:
	if is_on_wall():
		return true
	if use_floor_detector and is_on_floor():
		floor_detector.position.x = direction * 6.0
		floor_detector.force_raycast_update()
		return not floor_detector.is_colliding()
	return false


# ---------------------------------------------------------------------
#  Daño (lo llaman Joshua y los proyectiles)
# ---------------------------------------------------------------------
func receive_power_up_attack(attack_kind: String, _damage: float = 1.0) -> void:
	if attack_kind == "fire":
		queue_free()
	elif attack_kind == "ice":
		_congelada = DURACION_CONGELADA
		sprite.modulate = Color("#a8e9ff")
		sprite.pause()


# ---------------------------------------------------------------------
#  Etiqueta con el estado (para la demo del proyecto de IA)
# ---------------------------------------------------------------------
func _crear_etiqueta() -> void:
	if not mostrar_estado:
		return
	_etiqueta = Label.new()
	_etiqueta.text = NOMBRES[estado]
	_etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_etiqueta.add_theme_font_size_override("font_size", 28)
	_etiqueta.add_theme_color_override("font_outline_color", Color.BLACK)
	_etiqueta.add_theme_constant_override("outline_size", 6)
	_etiqueta.scale = Vector2(0.25, 0.25)
	_etiqueta.size = Vector2(160, 40)
	_etiqueta.position = Vector2(-20, -24)
	add_child(_etiqueta)
