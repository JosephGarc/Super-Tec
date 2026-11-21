extends Node2D

@export var map_scene: PackedScene
@export var add_joshua := false
@export var nombre_nivel := ""   # se muestra arriba en pantalla (Nivel 1, Nivel 2...)

const JOSHUA_SCENE: PackedScene = preload("res://escenas/personajes_juegos/Joshua.tscn")
const SELECTOR_PATH := "res://escenas/pruebas/selector_escenarios.tscn"

func _ready() -> void:
	if map_scene == null:
		push_error("Asigna una escena de mapa a este escenario de prueba.")
		return
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
			camera.limit_bottom = int(limites.end.y)
			# Si Joshua cae más abajo del mapa, pierde una vida (por si el mapa no tiene zona de muerte)
			player.set("limite_caida", limites.end.y + 64.0)
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 5.0
		player.add_child(camera)
		camera.make_current()

	_add_hint()

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
	var hint := Label.new()
	hint.text = (nombre_nivel + "   ·   " if nombre_nivel != "" else "") + "Esc: volver al selector"
	hint.position = Vector2(8, 8)
	layer.add_child(hint)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(SELECTOR_PATH)