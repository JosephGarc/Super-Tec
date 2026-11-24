extends CharacterBody2D

const ESTADO := preload("res://scripts/juego/estado_juego.gd")
const FINAL_SCRIPT := preload("res://scripts/ui/final_juego.gd")
@export var vida_maxima := 90
@export var velocidad := 34.0
var vida := 90
var jugador: Node2D
var _tiempo := 0.0
var _ataque := 1.4
var _danio_contacto := 0.0
var _muerto := false
var _barra: ProgressBar
var _sprite: AnimatedSprite2D
var _animacion_actual := ""
var _placeholder: Polygon2D

func _ready() -> void:
	add_to_group("jefe_tesis")
	add_to_group("enemies")
	vida = vida_maxima
	collision_layer = 1
	collision_mask = 1 | 16
	jugador = get_tree().get_first_node_in_group("jugador") as Node2D
	_crear_visual()
	_crear_hud()

func _crear_visual() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := _crear_spriteframes()
	if frames != null:
		_sprite.sprite_frames = frames
		_sprite.scale = Vector2.ONE * 0.32
		add_child(_sprite)
		_cambiar_animacion("idle")
	else:
		_placeholder = Polygon2D.new()
		_placeholder.polygon = PackedVector2Array([Vector2(-28,-28),Vector2(20,-28),Vector2(30,-14),Vector2(25,24),Vector2(0,34),Vector2(-30,20)])
		_placeholder.color = Color("#7b3d70")
		add_child(_placeholder)
		var ojos := Polygon2D.new()
		ojos.polygon = PackedVector2Array([Vector2(-15,-10),Vector2(-6,-10),Vector2(-6,-4),Vector2(-15,-4),Vector2(7,-10),Vector2(16,-10),Vector2(16,-4),Vector2(7,-4)])
		ojos.color = Color("#ffe27a")
		add_child(ojos)
	var forma := CollisionShape2D.new()
	var caja := RectangleShape2D.new()
	caja.size = Vector2(48, 56)
	forma.shape = caja
	add_child(forma)

func _crear_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 15
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -155
	panel.offset_right = 155
	panel.offset_top = 12
	panel.offset_bottom = 54
	canvas.add_child(panel)
	var columna := VBoxContainer.new()
	panel.add_child(columna)
	var titulo := Label.new()
	titulo.text = "MONSTRUO DE LA TESIS"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_color_override("font_color", Color("#fff1c2"))
	columna.add_child(titulo)
	_barra = ProgressBar.new()
	_barra.max_value = vida_maxima
	_barra.value = vida
	_barra.show_percentage = false
	_barra.custom_minimum_size = Vector2(280, 14)
	columna.add_child(_barra)

func _physics_process(delta: float) -> void:
	if _muerto:
		return
	_tiempo += delta
	_ataque -= delta
	_danio_contacto = maxf(0.0, _danio_contacto - delta)
	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as Node2D
	# El jefe es estrictamente terrestre: nada de oscilación vertical. La
	# gravedad lo asienta sobre el TileMap y move_and_slide resuelve el suelo.
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y += get_gravity().y * delta
	var furia := float(vida) / float(vida_maxima) < 0.4
	if jugador == null:
		velocity.x = move_toward(velocity.x, 0.0, 180.0 * delta)
		_cambiar_animacion("furia" if furia else "idle")
	else:
		var hacia := jugador.global_position - global_position
		if hacia.length() > 300.0:
			velocity.x = move_toward(velocity.x, 0.0, 180.0 * delta)
			_cambiar_animacion("furia" if furia else "idle")
		else:
			var rango := 74.0 if furia else 100.0
			if hacia.length() > 54.0:
				velocity.x = move_toward(velocity.x, signf(hacia.x) * velocidad * (1.65 if furia else 1.0), 120.0 * delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, 180.0 * delta)
			if _ataque <= 0.0:
				_ataque = (0.85 if furia else 1.5) if hacia.length() < rango else (1.15 if furia else 2.1)
				if hacia.length() < rango:
					_cambiar_animacion("furia" if furia else "melee")
					velocity.x = signf(hacia.x) * (150.0 if furia else 105.0)
					if jugador.has_method("take_damage") and _danio_contacto <= 0.0:
						jugador.call("take_damage")
						_danio_contacto = 0.75
				else:
					_cambiar_animacion("furia" if furia else "ranged")
					_lanzar_proyectil(hacia.normalized(), furia)
			elif _sprite != null and _sprite.is_playing() and _animacion_actual in ["melee", "ranged"]:
				pass
			elif absf(velocity.x) > 3.0:
				_cambiar_animacion("furia" if furia else "walk")
			else:
				_cambiar_animacion("furia" if furia else "idle")
	move_and_slide()
	if _sprite != null:
		_sprite.flip_h = velocity.x < 0.0
		_sprite.modulate = Color("#ff9c78") if furia else Color.WHITE
	if _placeholder != null:
		_placeholder.color = Color("#ef426c") if furia else Color("#7b3d70")

func _cambiar_animacion(nombre: String) -> void:
	if _sprite == null or not _sprite.sprite_frames.has_animation(nombre) or nombre == _animacion_actual:
		return
	_animacion_actual = nombre
	_sprite.play(nombre)

func _crear_spriteframes() -> SpriteFrames:
	var recurso := load("res://assets/Monstruo de la Tesis.png") as Texture2D
	if recurso == null:
		return null
	var imagen := recurso.get_image()
	if imagen == null or imagen.is_empty():
		return null
	imagen.convert(Image.FORMAT_RGBA8)
	_quitar_fondo_exterior(imagen)
	var atlas := ImageTexture.create_from_image(imagen)
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_agregar_animacion(frames, atlas, "idle", [Vector2i(432, 47), Vector2i(592, 47), Vector2i(752, 47), Vector2i(912, 47)], Vector2i(160, 170), 5.0, true)
	_agregar_animacion(frames, atlas, "walk", [Vector2i(1068, 48), Vector2i(1218, 48), Vector2i(1368, 48), Vector2i(1518, 48)], Vector2i(150, 170), 8.0, true)
	_agregar_animacion(frames, atlas, "melee", [Vector2i(410, 286), Vector2i(550, 286), Vector2i(690, 286), Vector2i(830, 286)], Vector2i(145, 145), 9.0, false)
	_agregar_animacion(frames, atlas, "ranged", [Vector2i(1000, 286), Vector2i(1135, 286), Vector2i(1270, 286)], Vector2i(130, 145), 7.0, false)
	_agregar_animacion(frames, atlas, "furia", [Vector2i(430, 740), Vector2i(560, 740), Vector2i(690, 740)], Vector2i(140, 180), 7.0, true)
	return frames

func _agregar_animacion(frames: SpriteFrames, atlas: Texture2D, nombre: String, origenes: Array[Vector2i], tam: Vector2i, fps: float, bucle: bool) -> void:
	frames.add_animation(nombre)
	frames.set_animation_speed(nombre, fps)
	frames.set_animation_loop(nombre, bucle)
	for origen in origenes:
		if origen.x + tam.x > atlas.get_width() or origen.y + tam.y > atlas.get_height():
			continue
		var cuadro := AtlasTexture.new()
		cuadro.atlas = atlas
		cuadro.region = Rect2(Vector2(origen), Vector2(tam))
		frames.add_frame(nombre, cuadro)

func _quitar_fondo_exterior(imagen: Image) -> void:
	var ancho := imagen.get_width()
	var alto := imagen.get_height()
	var cola := PackedInt32Array()
	cola.resize(ancho * alto)
	var fin := 0
	for x in ancho:
		fin = _encolar_negro(imagen, cola, fin, x, ancho)
		fin = _encolar_negro(imagen, cola, fin, (alto - 1) * ancho + x, ancho)
	for y in range(1, alto - 1):
		fin = _encolar_negro(imagen, cola, fin, y * ancho, ancho)
		fin = _encolar_negro(imagen, cola, fin, y * ancho + ancho - 1, ancho)
	var actual := 0
	while actual < fin:
		var indice := cola[actual]
		actual += 1
		var x := indice % ancho
		var y := floori(float(indice) / ancho)
		if x > 0:
			fin = _encolar_negro(imagen, cola, fin, indice - 1, ancho)
		if x + 1 < ancho:
			fin = _encolar_negro(imagen, cola, fin, indice + 1, ancho)
		if y > 0:
			fin = _encolar_negro(imagen, cola, fin, indice - ancho, ancho)
		if y + 1 < alto:
			fin = _encolar_negro(imagen, cola, fin, indice + ancho, ancho)

func _encolar_negro(imagen: Image, cola: PackedInt32Array, fin: int, indice: int, ancho: int) -> int:
	var x := indice % ancho
	var y := floori(float(indice) / ancho)
	var pixel := imagen.get_pixel(x, y)
	if pixel.a > 0.0 and pixel.r < 0.035 and pixel.g < 0.035 and pixel.b < 0.035:
		imagen.set_pixel(x, y, Color(0, 0, 0, 0))
		cola[fin] = indice
		return fin + 1
	return fin

func _lanzar_proyectil(direccion: Vector2, furia: bool) -> void:
	var bola := Area2D.new()
	bola.collision_layer = 0
	bola.collision_mask = 2
	bola.set_script(load("res://scripts/enemigos/proyectil_tesis.gd"))
	bola.set("direccion", direccion)
	bola.set("rapidez", 175.0 if furia else 125.0)
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 7.0
	forma.shape = circulo
	bola.add_child(forma)
	var papel := Polygon2D.new()
	papel.polygon = PackedVector2Array([Vector2(-7,-5),Vector2(6,-5),Vector2(7,4),Vector2(-6,5)])
	papel.color = Color("#d9f5ff")
	bola.add_child(papel)
	get_tree().current_scene.add_child(bola)
	bola.global_position = global_position

func recibir_dano_jefe(cantidad: int) -> void:
	if _muerto:
		return
	vida = maxi(0, vida - cantidad)
	if is_instance_valid(_barra):
		_barra.value = vida
	if _sprite != null:
		var parpadeo := create_tween()
		parpadeo.tween_property(_sprite, "modulate", Color.WHITE, 0.06)
		parpadeo.tween_property(_sprite, "modulate", Color("#ff7790") if vida * 5 < vida_maxima * 2 else Color.WHITE, 0.12)
	if vida <= 0:
		_victoria()

# El jefe solo pierde vida con el Lápiz. Los contactos del sistema clásico
# (pisotón, fuego o volován) no deben eliminarlo de un solo golpe.
func aplastado() -> void:
	pass

func morir() -> void:
	pass

func receive_power_up_attack(_tipo: String, _segundos: float = 0.0) -> void:
	pass

func _victoria() -> void:
	_muerto = true
	ESTADO.marcar_nivel_completado(9)
	ESTADO.registrar_tiempo_nivel(9)
	# Cinemática final: con 180 créditos recibe el título (y luego el ranking);
	# si le faltan, Eugenio le pide los créditos que le faltan.
	get_tree().change_scene_to_file.call_deferred("res://escenas/cinematicas/final.tscn")
	queue_free()
