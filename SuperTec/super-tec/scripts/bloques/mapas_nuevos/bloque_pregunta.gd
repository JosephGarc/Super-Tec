extends StaticBody2D

const SONIDO := preload("res://scripts/juego/sonido.gd")
const PROGRESO := preload("res://scripts/juego/progreso.gd")

@export var contenido: PackedScene   # Por defecto suelta el azulito (se asigna en bloque_pregunta.tscn)
## Si no hay "contenido", se elige uno de esta lista según la posición del bloque
## (lo usan los ladrillos sorpresa: cada uno suelta siempre lo mismo).
@export var contenidos_posibles: Array[PackedScene] = []
## Bloque ? de moneda (como en Mario): al golpearlo salta un crédito Eugenio
## y se suma solo al contador.
@export var da_credito := false
const CREDITO_ESCENA := preload("res://escenas/powerups/pickups/credito_eugenio.tscn")
var usado := false
var _luz: PointLight2D
var _golpe_tween: Tween
@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_agregar_brillo()

func _agregar_brillo() -> void:
	var gradiente := Gradient.new()
	gradiente.colors = [Color(1, 1, 1, 0.38), Color(1, 1, 1, 0)]
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.width = 64
	textura.height = 64
	textura.fill = GradientTexture2D.FILL_RADIAL
	_luz = PointLight2D.new()
	_luz.texture = textura
	_luz.energy = 0.26
	_luz.texture_scale = 0.24
	_luz.color = Color("#ffe59a")
	add_child(_luz)

func _animar_golpe() -> void:
	if _golpe_tween and _golpe_tween.is_running():
		_golpe_tween.kill()
	var reposo := _sprite.position
	var tono := _sprite.modulate
	var energia := _luz.energy
	_golpe_tween = create_tween()
	_golpe_tween.set_parallel(true)
	_golpe_tween.tween_property(_sprite, "position:y", reposo.y - 5.0, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_golpe_tween.tween_property(_sprite, "modulate", Color("#fff2bb"), 0.06)
	_golpe_tween.tween_property(_luz, "energy", energia + 0.65, 0.06)
	_golpe_tween.chain().set_parallel(true)
	_golpe_tween.tween_property(_sprite, "position:y", reposo.y, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_golpe_tween.tween_property(_sprite, "modulate", tono, 0.15)
	_golpe_tween.tween_property(_luz, "energy", energia, 0.18)

func golpear(_jugador):
	if _jugador.has_method("shake"):
		_jugador.shake(1.4, 0.1)
	if usado:
		_animar_golpe()
		SONIDO.efecto("golpe_bloque")
		return
	usado = true
	SONIDO.efecto("golpe_bloque")
	$Sprite2D.modulate = Color(0.5, 0.5, 0.5)   # se oscurece = ya usado
	_animar_golpe()
	for cuerpo in $ZonaArriba.get_overlapping_bodies():
		if cuerpo.has_method("morir"):
			cuerpo.morir()
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
	var id := "bloque_%d_%d" % [int(position.x), int(position.y)]
	var ya_lo_tenia := PROGRESO.ya_lo_tenia(id)
	if juego and juego.has_method("collect_coin"):
		juego.collect_coin(id)
	# El crédito sale del bloque, sube y desaparece (solo es de adorno, ya se contó)
	var credito := CREDITO_ESCENA.instantiate() as Area2D
	credito.monitoring = false
	credito.monitorable = false
	credito.position = position + Vector2(0, -16)
	get_parent().add_child(credito)
	if ya_lo_tenia:
		credito.modulate = Color(1, 1, 1, 0.4)
	credito.remove_from_group("coins")   # ya se contó: que no cuente como crédito suelto
	var t := credito.create_tween()
	t.tween_property(credito, "position:y", credito.position.y - 24.0, 0.25).set_ease(Tween.EASE_OUT)
	t.tween_property(credito, "modulate:a", 0.0, 0.15)
	t.tween_callback(credito.queue_free)
