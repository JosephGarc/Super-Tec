extends Node2D

const CARGA_PICKUP := preload("res://scripts/powerups/carga_lapiz_pickup.gd")
@export var intervalo := 7.0
@export var posiciones_validas: Array[Vector2] = [Vector2(2180, 176), Vector2(2370, 144), Vector2(2550, 176), Vector2(2780, 144)]
var _reloj := 3.0
var _ultimo_punto := -1
var _pickup_activo := false

func _process(delta: float) -> void:
	if _pickup_activo:
		return
	_reloj -= delta
	if _reloj <= 0.0:
		_generar_utilidad()

func _generar_utilidad() -> void:
	_reloj = intervalo
	var jugador := get_tree().get_first_node_in_group("jugador") as Node2D
	if jugador == null or posiciones_validas.is_empty():
		return
	var cargas := int(jugador.get("carga_lapiz")) if jugador.get("carga_lapiz") != null else 0
	var jefe := get_tree().get_first_node_in_group("jefe_tesis") as Node2D
	var distancia_jefe := jugador.global_position.distance_to(jefe.global_position) if jefe != null else 0.0
	var jugador_powerups: Node = jugador.get("power_ups")
	var vidas := int(jugador_powerups.get("lives")) if jugador_powerups != null else 3
	var utilidad_carga := 40.0 + (55.0 if cargas <= 1 else 0.0) + (25.0 if distancia_jefe > 170.0 else 0.0)
	var utilidad_vida := 25.0 + (65.0 if vidas <= 2 else 0.0)
	var tipo := "carga_lapiz" if utilidad_carga >= utilidad_vida else "vida"
	var mejor := -INF
	var elegido := -1
	for i in posiciones_validas.size():
		if i == _ultimo_punto and posiciones_validas.size() > 1:
			continue
		var dist := jugador.global_position.distance_to(posiciones_validas[i])
		var utilidad := utilidad_carga if tipo == "carga_lapiz" else utilidad_vida
		var puntuacion := 100.0 - dist * 0.025 + utilidad * 0.05 + randf_range(0.0, 8.0)
		if puntuacion > mejor:
			mejor = puntuacion
			elegido = i
	if elegido < 0:
		return
	_ultimo_punto = elegido
	var pickup := CARGA_PICKUP.new()
	pickup.set("tipo", tipo)
	add_child(pickup)
	pickup.global_position = posiciones_validas[elegido]
	_pickup_activo = true
	pickup.tree_exited.connect(func() -> void: _pickup_activo = false)
