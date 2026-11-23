extends StaticBody2D

const SONIDO := preload("res://scripts/juego/sonido.gd")

@export var contenido: PackedScene   # Por defecto suelta el azulito (se asigna en bloque_pregunta.tscn)
## Si no hay "contenido", se elige uno de esta lista según la posición del bloque
## (lo usan los ladrillos sorpresa: cada uno suelta siempre lo mismo).
@export var contenidos_posibles: Array[PackedScene] = []
## Bloque ? de moneda (como en Mario): al golpearlo salta un crédito Eugenio
## y se suma solo al contador.
@export var da_credito := false
const CREDITO_ESCENA := preload("res://escenas/powerups/pickups/credito_eugenio.tscn")
var usado := false

func golpear(_jugador):
	if usado:
		SONIDO.efecto("golpe_bloque")
		return
	usado = true
	SONIDO.efecto("golpe_bloque")
	$Sprite2D.modulate = Color(0.5, 0.5, 0.5)   # se oscurece = ya usado
	for cuerpo in $ZonaArriba.get_overlapping_bodies():
		if cuerpo.has_method("morir"):
			cuerpo.morir()
	var t = create_tween()
	t.tween_property($Sprite2D, "position:y", -4.0, 0.08)
	t.tween_property($Sprite2D, "position:y", 0.0, 0.08)
	if da_credito:
		_soltar_credito()
		return
	var escena := contenido
	if escena == null and not contenidos_posibles.is_empty():
		var indice := absi(int(position.x / 16.0) + int(position.y / 16.0) * 7)
		escena = contenidos_posibles[indice % contenidos_posibles.size()]
	if escena:
		SONIDO.efecto("aparece_powerup")
		var item = escena.instantiate()
		# position (no global_position): el bloque es hijo del TileMapLayer,
		# así el power-up queda justo encima del bloque
		item.position = position + Vector2(0, -16)
		get_parent().add_child.call_deferred(item)


func _soltar_credito() -> void:
	SONIDO.efecto("credito")
	var juego := get_tree().get_first_node_in_group("game")
	if juego and juego.has_method("collect_coin"):
		juego.collect_coin()
	# El crédito sale del bloque, sube y desaparece (solo es de adorno, ya se contó)
	var credito := CREDITO_ESCENA.instantiate() as Area2D
	credito.monitoring = false
	credito.monitorable = false
	credito.position = position + Vector2(0, -16)
	get_parent().add_child(credito)
	credito.remove_from_group("coins")   # ya se contó: que no cuente como crédito suelto
	var t := credito.create_tween()
	t.tween_property(credito, "position:y", credito.position.y - 24.0, 0.25).set_ease(Tween.EASE_OUT)
	t.tween_property(credito, "modulate:a", 0.0, 0.15)
	t.tween_callback(credito.queue_free)
