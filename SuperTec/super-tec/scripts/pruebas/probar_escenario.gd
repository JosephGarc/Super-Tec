extends Node2D

const SONIDO := preload("res://scripts/juego/sonido.gd")

@export var map_scene: PackedScene
@export var add_joshua := false
@export var nombre_nivel := ""   # se muestra arriba en pantalla (Nivel 1, Nivel 2...)

const JOSHUA_SCENE: PackedScene = preload("res://escenas/personajes_juegos/Joshua.tscn")
const OVERWORLD_PATH := "res://escenas/overworld_super_tec.tscn"
const SELECTOR_RESPALDO_PATH := "res://escenas/pruebas/selector_escenarios.tscn"
const ESTADO := preload("res://scripts/juego/estado_juego.gd")
const TRANSICION := preload("res://scripts/ui/transicion_fade.gd")
const MENU_PATH := "res://menu/menu_principal.tscn"
const TUERCA := preload("res://scripts/ui/boton_tuerca.gd")
const MENU_PAUSA := preload("res://scripts/ui/menu_pausa.gd")
var _cambiando_escena := false

func _ready() -> void:
	var numero_nivel := nombre_nivel.get_slice(" ", 1).to_int() if nombre_nivel.begins_with("Nivel ") else 0
	ESTADO.asegurar_cronometro(numero_nivel)
	if map_scene == null:
		push_error("Asigna una escena de mapa a este escenario de prueba.")
		return
	# Número del nivel ("Nivel 5" -> 5): música y progreso.
	# Va antes de cargar el mapa para que los créditos sepan si ya los tenías.
	if nombre_nivel.begins_with("Nivel "):
		var numero := nombre_nivel.get_slice(" ", 1).to_int()
		SONIDO.musica_nivel(numero)
		preload("res://scripts/juego/progreso.gd").empezar_nivel(numero)
	var map_instance := map_scene.instantiate()
	add_child(map_instance)

	if add_joshua:
		var player := JOSHUA_SCENE.instantiate() as CharacterBody2D
		add_child(player)
		var spawn := map_instance.find_child("SpawnJugador", true, false) as Node2D
		player.global_position = spawn.global_position if spawn != null else Vector2(32, 180)
		var camera := Camera2D.new()
		camera.name = "CamaraDePrueba"
		# Zoom 2: se ven ~16 x 12 bloques, parecido al encuadre de Super Mario Bros
		camera.zoom = Vector2(2.0, 2.0)
		# Que la cámara no se salga del mapa ni muestre el vacío de abajo.
		# Los límites se calculan con los tiles de cada mapa, así sirve para todos los niveles.
		var limites := _limites_del_mapa(map_instance)
		if limites.has_area():
			camera.limit_left = int(limites.position.x)
			camera.limit_right = int(limites.end.x)
			camera.limit_top = int(minf(limites.position.y, -192.0))
			camera.limit_bottom = int(limites.end.y)
			# Si Joshua cae más abajo del mapa, pierde una vida (por si el mapa no tiene zona de muerte)
			player.set("limite_caida", limites.end.y + 64.0)
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 5.0
		camera.position = Vector2.ZERO
		player.add_child(camera)
		camera.make_current()
		camera.reset_smoothing()

	_add_hint()
	var entrada := TRANSICION.new()
	add_child(entrada)
	entrada.fade_in()

# Rectángulo (en coordenadas globales) que ocupan todos los tiles del mapa
func _limites_del_mapa(map_instance: Node) -> Rect2:
	var total := Rect2()
	var primero := true
	for capa in map_instance.find_children("*", "TileMapLayer", true, false):
		var tiles := capa as TileMapLayer
		var usado := tiles.get_used_rect()
		if usado.size == Vector2i.ZERO or tiles.tile_set == null:
			continue
		var medio := Vector2(tiles.tile_set.tile_size) * 0.5
		var a := tiles.to_global(tiles.map_to_local(usado.position) - medio)
		var b := tiles.to_global(tiles.map_to_local(usado.end - Vector2i.ONE) + medio)
		var r := Rect2(a, b - a)
		total = r if primero else total.merge(r)
		primero = false
	return total

func _add_hint() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	# Tuerca de ajustes (arriba a la izquierda). Esc también abre el menú.
	var tuerca := TUERCA.new()
	tuerca.presionada.connect(_abrir_ajustes)
	layer.add_child(tuerca)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9 and not _cambiando_escena:
		ESTADO.retorno_overworld_habilitado = false
		_cambiando_escena = true
		call_deferred("_cambiar_escena", SELECTOR_RESPALDO_PATH)
		return
	if event.is_action_pressed("ui_cancel") and not _cambiando_escena:
		get_viewport().set_input_as_handled()
		_abrir_ajustes()


func _abrir_ajustes() -> void:
	if _cambiando_escena or get_tree().paused:
		return   # no se abre encima del game over ni del aviso de nivel completado
	var ajustes := MENU_PAUSA.new()
	ajustes.salir_al_campus.connect(func():
		_cambiando_escena = true
		_volver_al_overworld())
	ajustes.salir_al_menu.connect(func():
		_cambiando_escena = true
		ESTADO.detener_cronometro()
		_cambiar_escena(MENU_PATH))
	add_child(ajustes)


func _volver_al_overworld() -> void:
	ESTADO.detener_cronometro()
	await _cambiar_escena(OVERWORLD_PATH)


func _cambiar_escena(destino: String) -> void:
	var salida := TRANSICION.new()
	add_child(salida)
	await salida.fade_out()
	var error := get_tree().change_scene_to_file(destino)
	if error != OK:
		_cambiando_escena = false
		await salida.fade_in()
		push_error("No se pudo abrir la escena de destino: %s" % destino)
