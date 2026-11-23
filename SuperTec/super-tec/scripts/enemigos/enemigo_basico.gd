extends CharacterBody2D

## Enemigo básico de Super Tec.
## Usa las animaciones que hizo el equipo de personajes (escenas en escenas/enemigos/,
## ataques/ y muertes/) SIN modificarlas: solo copia sus SpriteFrames.
## Si el encargado de personajes les programa su propio comportamiento,
## basta con dejar de usar las escenas de escenas/enemigos/jugables/.
##
## Comportamiento:
## - Camina (o vuela) de un lado a otro dentro de su rango de patrulla.
## - Si Joshua se acerca, reproduce su animación de ataque y se lanza hacia él.
## - Si toca a Joshua de lado, le hace daño.
## - Muere si Joshua le cae encima, con la malanga en llamas o tocándolo con volován.
## - La tapa helada lo congela (se mueve más lento) unos segundos.

# --- Animaciones del equipo de personajes ---
@export var escena_visual: PackedScene
@export var escena_ataque: PackedScene
@export var escena_muerte: PackedScene

# --- Tamaño en pantalla (los sprites originales miden ~200 px) ---
@export var alto_en_pantalla := 20.0   # alto del cuadro de animación en pantalla
@export var desfase_y := 0.0           # para que los pies queden sobre el piso
@export var mira_a_la_derecha := true  # hacia dónde mira el dibujo original

# --- Comportamiento ---
@export var vuela := false
@export var velocidad := 30.0
@export var rango_patrulla := 48.0
@export var vida := 1
@export var distancia_ataque := 40.0

# Copias de las hojas de sprites con fondo transparente (los originales traen fondo pintado)
const SONIDO := preload("res://scripts/juego/sonido.gd")
const CARPETA_SIN_FONDO := "res://assets/personajes/enemigos/sin_fondo/"
const DURACION_CONGELADO := 3.0

var direccion := -1.0
var inicio := Vector2.ZERO
var tiempo := 0.0
var congelado := 0.0
var atacando := 0.0
var muerto := false

var frames_normal: SpriteFrames
var frames_ataque: SpriteFrames
var frames_muerte: SpriteFrames
var sprite: AnimatedSprite2D
var rayo_piso: RayCast2D


func _ready() -> void:
	add_to_group("enemies")
	# Capa "mundo" (como Galleta) para que choque con Joshua y lo detecten los proyectiles;
	# choca con el mundo y con los bloques.
	collision_layer = 1
	collision_mask = 1 | 16
	inicio = global_position

	frames_normal = _cargar_frames(escena_visual)
	frames_ataque = _cargar_frames(escena_ataque)
	frames_muerte = _cargar_frames(escena_muerte)

	sprite = AnimatedSprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.position.y = desfase_y
	add_child(sprite)
	_poner_frames(frames_normal)

	if not vuela:
		# Rayo hacia abajo, adelante del enemigo, para no caerse de las plataformas
		rayo_piso = RayCast2D.new()
		rayo_piso.collision_mask = 1 | 16
		rayo_piso.target_position = Vector2(0, 16)
		add_child(rayo_piso)


func _physics_process(delta: float) -> void:
	if muerto:
		return
	tiempo += delta
	if congelado > 0.0:
		congelado -= delta
		if congelado <= 0.0:
			sprite.modulate = Color.WHITE
	if atacando > 0.0:
		atacando -= delta
		if atacando <= 0.0:
			_poner_frames(frames_normal)

	var rapidez := velocidad * (0.25 if congelado > 0.0 else 1.0)

	if vuela:
		velocity.y = cos(tiempo * 2.5) * 12.0   # flota subiendo y bajando
	elif not is_on_floor():
		velocity += get_gravity() * delta

	# Patrulla: da la vuelta al llegar al límite, al chocar con pared o en la orilla
	if direccion < 0.0 and global_position.x <= inicio.x - rango_patrulla:
		direccion = 1.0
	elif direccion > 0.0 and global_position.x >= inicio.x + rango_patrulla:
		direccion = -1.0
	elif is_on_wall():
		direccion *= -1.0
	elif rayo_piso != null and is_on_floor():
		rayo_piso.position.x = direccion * 8.0
		rayo_piso.force_raycast_update()
		if not rayo_piso.is_colliding():
			direccion *= -1.0

	# Al atacar se lanza hacia Joshua un poco más rápido
	velocity.x = direccion * rapidez * (1.8 if atacando > 0.0 else 1.0)
	_revisar_ataque()
	sprite.flip_h = (direccion < 0.0) == mira_a_la_derecha
	move_and_slide()
	_revisar_contacto_con_jugador()


func _revisar_ataque() -> void:
	if frames_ataque == null or atacando > 0.0:
		return
	var jugador := get_tree().get_first_node_in_group("jugador") as Node2D
	if jugador == null:
		return
	var distancia := jugador.global_position - global_position
	if absf(distancia.x) < distancia_ataque and absf(distancia.y) < 24.0:
		direccion = signf(distancia.x) if distancia.x != 0.0 else direccion
		atacando = _duracion(frames_ataque)
		_poner_frames(frames_ataque)


# Si el enemigo es el que se mueve contra Joshua, también le hace daño
func _revisar_contacto_con_jugador() -> void:
	for i in get_slide_collision_count():
		var choque := get_slide_collision(i)
		var otro := choque.get_collider()
		if otro is Node and otro.is_in_group("jugador"):
			# normal.y > 0.5: Joshua está encima (eso lo resuelve Joshua aplastándolo)
			if choque.get_normal().y > 0.5:
				return
			var con_volovan = otro.get("power_ups") != null and otro.power_ups.is_invincible
			if con_volovan:
				morir()
			elif otro.has_method("take_damage"):
				otro.take_damage()
			return


# --- Daño ---

# Joshua le cayó encima
func aplastado() -> void:
	recibir_dano(1)


# Lo llaman los proyectiles de los power-ups (sistema de Joseph)
func receive_power_up_attack(tipo: String, _segundos: float = 0.0) -> void:
	if tipo == "ice":
		congelado = DURACION_CONGELADO
		sprite.modulate = Color("#a8e9ff")
		SONIDO.efecto("congelar")
	elif tipo == "fire":
		SONIDO.efecto("quemar")
		recibir_dano(1)


func recibir_dano(cantidad: int) -> void:
	if muerto:
		return
	vida -= cantidad
	if vida <= 0:
		morir()
	else:
		var parpadeo := create_tween()
		parpadeo.tween_property(sprite, "modulate", Color(1, 0.4, 0.4), 0.08)
		parpadeo.tween_property(sprite, "modulate", Color.WHITE, 0.12)


# También la llama la zona de muerte si el enemigo se cae al vacío
func morir() -> void:
	if muerto:
		return
	muerto = true
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	if frames_muerte != null:
		_poner_frames(frames_muerte)
		await get_tree().create_timer(_duracion(frames_muerte)).timeout
	queue_free()


# --- Animaciones ---

# Saca los SpriteFrames de una escena del equipo de personajes y los pasa
# a las hojas sin fondo (misma animación, mismos cuadros).
func _cargar_frames(escena: PackedScene) -> SpriteFrames:
	if escena == null:
		return null
	var instancia := escena.instantiate()
	var original: SpriteFrames = null
	if instancia is AnimatedSprite2D:
		original = instancia.sprite_frames
	else:
		var hallados := instancia.find_children("*", "AnimatedSprite2D", true, false)
		if hallados.size() > 0:
			original = (hallados[0] as AnimatedSprite2D).sprite_frames
	instancia.free()
	if original == null:
		return null

	var copia := SpriteFrames.new()
	for nombre in original.get_animation_names():
		if not copia.has_animation(nombre):
			copia.add_animation(nombre)
		copia.set_animation_speed(nombre, original.get_animation_speed(nombre))
		copia.set_animation_loop(nombre, original.get_animation_loop(nombre))
		for i in original.get_frame_count(nombre):
			copia.add_frame(nombre, _sin_fondo(original.get_frame_texture(nombre, i)), original.get_frame_duration(nombre, i))
	if copia.has_animation("default") and not original.has_animation("default"):
		copia.remove_animation("default")
	return copia


func _sin_fondo(textura: Texture2D) -> Texture2D:
	var atlas := textura as AtlasTexture
	if atlas == null or atlas.atlas == null:
		return textura
	var ruta := CARPETA_SIN_FONDO + atlas.atlas.resource_path.get_file().get_basename() + ".png"
	var hoja := _hoja_sin_fondo(ruta)
	if hoja == null:
		return textura
	var factor := float(hoja.get_width()) / float(atlas.atlas.get_width())
	var nueva := AtlasTexture.new()
	nueva.atlas = hoja
	nueva.region = Rect2(atlas.region.position * factor, atlas.region.size * factor)
	return nueva


# Las hojas se comparten entre todos los enemigos (se cargan una sola vez)
static var _cache_hojas := {}

static func _hoja_sin_fondo(ruta: String) -> Texture2D:
	if _cache_hojas.has(ruta):
		return _cache_hojas[ruta]
	var hoja: Texture2D = null
	if ResourceLoader.exists(ruta):
		hoja = load(ruta)
	elif FileAccess.file_exists(ruta):
		# Godot todavía no la importa (pasa la primera vez): se lee directo del PNG
		var imagen := Image.load_from_file(ProjectSettings.globalize_path(ruta))
		if imagen != null:
			hoja = ImageTexture.create_from_image(imagen)
	_cache_hojas[ruta] = hoja
	return hoja


func _poner_frames(frames: SpriteFrames) -> void:
	if frames == null:
		return
	sprite.sprite_frames = frames
	var animacion: StringName = frames.get_animation_names()[0]
	var primer_cuadro := frames.get_frame_texture(animacion, 0)
	if primer_cuadro != null and primer_cuadro.get_height() > 0:
		sprite.scale = Vector2.ONE * (alto_en_pantalla / float(primer_cuadro.get_height()))
	sprite.play(animacion)


func _duracion(frames: SpriteFrames) -> float:
	var animacion: StringName = frames.get_animation_names()[0]
	var velocidad_anim := frames.get_animation_speed(animacion)
	if velocidad_anim <= 0.0:
		return 0.6
	return clampf(frames.get_frame_count(animacion) / velocidad_anim, 0.3, 2.0)
