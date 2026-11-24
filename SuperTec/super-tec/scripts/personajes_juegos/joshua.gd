extends CharacterBody2D

## Joshua de los niveles nuevos.
## Movimiento estilo Mario con WASD + el sistema de power-ups de Joseph
## (PowerUpController: azulito, coca helada, malanga picante, volován y taco).

# --- Movimiento ---
# Velocidad parecida a Mario caminando (~7 bloques por segundo)
const SPEED := 110.0
const ACCELERATION := 700.0
const FRICTION := 900.0
const JUMP_VELOCITY := -400.0
const JUMP_CUT_MULTIPLIER := 0.5
const STOMP_BOUNCE_MULTIPLIER := 0.55
const COYOTE_TIME := 0.12
const JUMP_BUFFER_TIME := 0.12

# --- Tamaño (como Mario: empieza chico y el azulito lo hace grande) ---
# Los bloques miden 16 px. Chico mide ~1 bloque y grande ~2 bloques.
const ESCALA_CHICO := 0.033
const ESCALA_GRANDE := 0.06
const CAPSULA_CHICO := Vector2(5.0, 15.0)   # radio, altura
const CAPSULA_GRANDE := Vector2(7.0, 28.0)

# --- Capas de física (ver project.godot > layer_names) ---
const CAPA_MUNDO := 1        # capa 1 "mundo"
const CAPA_JUGADOR := 2      # capa 2 "jugador"
const CAPA_BLOQUES := 16     # capa 5 "bloques"

const POWER_UP_TEXTURES := {
	"azulito": preload("res://assets/powerups/azulito.png"),
	"coca_helada": preload("res://assets/powerups/coca_helada.png"),
	"malanga_picante": preload("res://assets/powerups/malanga_picante.png"),
	"volovan": preload("res://assets/powerups/volovan.png"),
	"taco": preload("res://assets/powerups/taco.png"),
}

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var w_presionada_antes := false

var es_grande := false       # lo lee bloque_ladrillo.gd para saber si se rompe
var facing_direction := Vector2.RIGHT   # lo usa el PowerUpController para disparar

# Efectos visuales (del Joshua de power-ups de Joseph)
var _damage_cooldown := 0.0
var _effect_clock := 0.0
var _life_popup_time := 0.0
var _consume_progress := 0.0
var _held_item: Texture2D
var _consume_tween: Tween
var _growth_tween: Tween
var _camera_shake_time := 0.0
var _camera_shake_duration := 0.0
var _camera_shake_intensity := 0.0
var _camera_base_offset := Vector2.ZERO
var _dust: GPUParticles2D
var _collection_flash := 0.0

# Punto donde reaparece Joshua al morir. Se guarda en el primer frame,
# porque el escenario de prueba lo coloca en SpawnJugador después de agregarlo.
var spawn_position := Vector2.ZERO
var spawn_guardado := false
# Altura a partir de la cual Joshua se considera caído al vacío (la pone probar_escenario.gd)
var limite_caida := INF
var _muriendo := false

# Punto de reaparición "cercano" (como en Mario): el último lugar de piso firme
# donde estuvo Joshua, lejos de enemigos. Si cae a un precipicio, vuelve a antes del hueco.
const INTERVALO_PUNTO_SEGURO := 0.2
const DISTANCIA_SEGURA_ENEMIGOS := 64.0
const INVULNERABLE_AL_REAPARECER := 2.0
var _punto_seguro := Vector2.ZERO
var _hay_punto_seguro := false
var _tiempo_punto_seguro := 0.0
var _parpadeo := 0.0
var lapiz_equipado := false
var carga_lapiz := 0
var _lapiz_visual: Node2D
var _ataque_enfriamiento := 0.0

# Créditos y vidas que no se reinician al cambiar de nivel
const ESTADO := preload("res://scripts/juego/estado_juego.gd")
const SONIDO := preload("res://scripts/juego/sonido.gd")
const ARTE_LAPIZ := preload("res://scripts/juego/arte_lapiz.gd")
# Sonido de cada power-up al consumirlo
const SONIDO_POWER_UP := {
	"azulito": "crecer",
	"coca_helada": "tomar_coca",
	"malanga_picante": "comer_papa",
	"volovan": "mordida_volovan",
	"taco": "mordida_taco",
}

# Se cargan con preload para no depender de la caché de class_name de Godot
const HUD_SCRIPT := preload("res://scripts/powerups/hud_super_tec.gd")
const GAME_OVER_SCRIPT := preload("res://scripts/ui/game_over.gd")
const TEXTURA_MUJER_PATH := "res://assets/Sam.png"
const SAM_COLUMNAS := 6
const SAM_FILAS := 2
const ESCALA_MUJER_CHICA := 0.024
const ESCALA_MUJER_GRANDE := 0.044
const SAM_OFFSET_Y := -36.0
var hud: CanvasLayer
var _spriteframes_hombre: SpriteFrames
var _spriteframes_mujer: SpriteFrames
static var _spriteframes_mujer_cache: SpriteFrames

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var power_ups: Node = $PowerUpController   # power_up_controller.gd


func _ready() -> void:
	add_to_group("jugador")
	lapiz_equipado = ESTADO.lapiz_poderoso_obtenido
	carga_lapiz = ESTADO.cargas_lapiz
	var nodo_nivel := get_parent()
	var numero_nivel := ""
	if nodo_nivel != null:
		for propiedad in nodo_nivel.get_property_list():
			if propiedad.get("name", "") == "nombre_nivel":
				numero_nivel = str(nodo_nivel.get("nombre_nivel"))
				break
	if not lapiz_equipado and numero_nivel == "Nivel 9":
		obtener_lapiz_poderoso(3)
	# Joshua está en la capa "mundo" (para que lo detecten la zona de muerte y los power-ups)
	# y en la capa "jugador". Choca con el mundo y con los bloques.
	collision_layer = CAPA_MUNDO | CAPA_JUGADOR
	collision_mask = CAPA_MUNDO | CAPA_BLOQUES
	_spriteframes_hombre = animated_sprite.sprite_frames
	_spriteframes_mujer = _crear_spriteframes_mujer() if ESTADO.personaje_seleccionado == "mujer" else null
	_actualizar_personaje_seleccionado()
	# Cada Joshua usa su propia forma de colisión para poder cambiarla de tamaño
	collision_shape.shape = collision_shape.shape.duplicate()
	_aplicar_tamano(false)

	# Las vidas vienen del nivel anterior
	power_ups.lives = ESTADO.vidas

	power_ups.power_up_collected.connect(_on_power_up_collected)
	# Al acabarse el volován regresa la música del nivel
	power_ups.power_up_expired.connect(_on_power_up_expired)
	power_ups.extra_life_added.connect(_on_extra_life_added)

	hud = HUD_SCRIPT.new()
	add_child(hud)
	hud.configurar(power_ups)
	_configurar_polvo()
	var camera := get_node_or_null("CamaraDePrueba") as Camera2D
	if camera != null:
		camera.position_smoothing_enabled = true
		_camera_base_offset = camera.offset


func _physics_process(delta: float) -> void:
	if not spawn_guardado:
		var nivel_actual := get_tree().current_scene
		if ESTADO.checkpoint_nivel9_activo and nivel_actual != null and _es_nivel_9(nivel_actual):
			global_position = ESTADO.checkpoint_nivel9
			spawn_position = ESTADO.checkpoint_nivel9
			_punto_seguro = ESTADO.checkpoint_nivel9
			_hay_punto_seguro = true
		else:
			spawn_position = global_position
		spawn_guardado = true

	_effect_clock += delta
	_damage_cooldown = maxf(0.0, _damage_cooldown - delta)
	_parpadeo = maxf(0.0, _parpadeo - delta)
	_ataque_enfriamiento = maxf(0.0, _ataque_enfriamiento - delta)

	if not is_on_floor():
		velocity += get_gravity() * delta

	# Controles WASD: A/D para moverse, W para saltar.
	# Espacio (disparar) lo maneja el PowerUpController.
	var w_presionada := Input.is_physical_key_pressed(KEY_W)
	var w_recien_presionada := w_presionada and not w_presionada_antes
	var w_recien_soltada := w_presionada_antes and not w_presionada
	w_presionada_antes = w_presionada

	if w_recien_presionada:
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		SONIDO.efecto("salto")
		_emitir_polvo()
		coyote_timer = 0.0

	if w_recien_soltada and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	var direction := 0.0
	if Input.is_physical_key_pressed(KEY_A):
		direction -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		direction += 1.0

	if direction != 0.0:
		facing_direction = Vector2(signf(direction), 0.0)
		# flip_h en lugar de scale.x para no perder la escala del sprite
		animated_sprite.flip_h = direction < 0.0
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	_update_animation(direction)
	var estaba_en_suelo := is_on_floor()
	var was_falling := velocity.y > 0.0
	move_and_slide()
	if not estaba_en_suelo and is_on_floor():
		_emitir_polvo()
	_revisar_choques(was_falling)
	_guardar_punto_seguro(delta)
	_update_visual_effects()
	if global_position.y > limite_caida:
		morir()


func _es_nivel_9(escena: Node) -> bool:
	for propiedad in escena.get_property_list():
		if propiedad.get("name", "") == "nombre_nivel":
			return str(escena.get("nombre_nivel")) == "Nivel 9"
	return escena.scene_file_path.ends_with("nivel_9.tscn")

func _process(delta: float) -> void:
	ESTADO.vidas = power_ups.lives   # el taco suma vidas desde el PowerUpController
	_life_popup_time = maxf(0.0, _life_popup_time - delta)
	_collection_flash = maxf(0.0, _collection_flash - delta)
	queue_redraw()
	if hud != null and hud.has_method("actualizar_lapiz"):
		hud.actualizar_lapiz(carga_lapiz, lapiz_equipado, _ataque_enfriamiento > 0.0)
	_actualizar_temblo_camara(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_J:
		_atacar_con_lapiz()
	elif event.physical_keycode == KEY_K:
		_disparar_lapiz()


func cargar_lapiz(cantidad: int = 1) -> void:
	if not lapiz_equipado:
		return
	carga_lapiz = mini(carga_lapiz + maxi(cantidad, 1), 9)
	ESTADO.cargas_lapiz = carga_lapiz
	SONIDO.efecto("recolectar")
	if hud != null and hud.has_method("actualizar_lapiz"):
		hud.actualizar_lapiz(carga_lapiz, lapiz_equipado, _ataque_enfriamiento > 0.0)


func obtener_lapiz_poderoso(cargas_iniciales: int = 3) -> void:
	lapiz_equipado = true
	ESTADO.lapiz_poderoso_obtenido = true
	carga_lapiz = mini(carga_lapiz + maxi(cargas_iniciales, 0), 9)
	ESTADO.cargas_lapiz = carga_lapiz
	if hud != null and hud.has_method("actualizar_lapiz"):
		hud.actualizar_lapiz(carga_lapiz, lapiz_equipado, _ataque_enfriamiento > 0.0)


func _ataque_visual() -> void:
	if is_instance_valid(_lapiz_visual):
		_lapiz_visual.queue_free()
	_lapiz_visual = Node2D.new()
	_lapiz_visual.position = Vector2(12.0 * facing_direction.x, -5.0)
	_lapiz_visual.rotation = -0.65 if facing_direction.x > 0.0 else PI + 0.65
	var cuerpo := Polygon2D.new()
	cuerpo.polygon = PackedVector2Array([Vector2(-3,-2), Vector2(13,-2), Vector2(13,2), Vector2(-3,2)])
	cuerpo.color = Color("#f6cf42")
	_lapiz_visual.add_child(cuerpo)
	var punta := Polygon2D.new()
	punta.polygon = PackedVector2Array([Vector2(13,-2), Vector2(19,0), Vector2(13,2)])
	punta.color = Color("#303642")
	_lapiz_visual.add_child(punta)
	var goma := Polygon2D.new()
	goma.polygon = PackedVector2Array([Vector2(-5,-2), Vector2(-2,-2), Vector2(-2,2), Vector2(-5,2)])
	goma.color = Color("#ef8eac")
	_lapiz_visual.add_child(goma)
	var icono := Sprite2D.new()
	icono.texture = ARTE_LAPIZ.obtener_textura()
	icono.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var escala_icono := 24.0 / maxf(float(icono.texture.get_width()), float(icono.texture.get_height()))
	icono.scale = Vector2.ONE * escala_icono
	icono.rotation = PI * 0.5
	_lapiz_visual.add_child(icono)
	add_child(_lapiz_visual)
	var tween := create_tween()
	tween.tween_property(_lapiz_visual, "rotation", _lapiz_visual.rotation + (1.6 if facing_direction.x > 0.0 else -1.6), 0.18)
	tween.tween_callback(_lapiz_visual.queue_free)


func _atacar_con_lapiz() -> void:
	if not lapiz_equipado or _ataque_enfriamiento > 0.0:
		return
	_ataque_enfriamiento = 0.28
	_ataque_visual()
	for jefe in get_tree().get_nodes_in_group("jefe_tesis"):
		if jefe is Node2D and global_position.distance_to(jefe.global_position) < 48.0 and absf(jefe.global_position.y - global_position.y) < 44.0 and signf(jefe.global_position.x - global_position.x) == facing_direction.x:
			if jefe.has_method("recibir_dano_jefe"):
				jefe.call("recibir_dano_jefe", 16)
			shake(1.5, 0.08)


func _disparar_lapiz() -> void:
	if not lapiz_equipado or carga_lapiz <= 0 or _ataque_enfriamiento > 0.0:
		return
	var ataque_especial := carga_lapiz >= 3
	var costo := 3 if ataque_especial else 1
	var dano := 48 if ataque_especial else 22
	carga_lapiz -= costo
	ESTADO.cargas_lapiz = carga_lapiz
	_ataque_enfriamiento = 0.35
	var proyectil: Area2D = preload("res://scripts/juego/proyectil_lapiz.gd").new()
	proyectil.call("configurar", facing_direction, dano, ataque_especial)
	get_tree().current_scene.add_child(proyectil)
	proyectil.global_position = global_position + facing_direction * 16.0 + Vector2(0, -5)
	shake(2.0 if ataque_especial else 1.0, 0.1)


func shake(intensity: float, duration: float) -> void:
	_camera_shake_intensity = maxf(_camera_shake_intensity, intensity)
	_camera_shake_duration = maxf(_camera_shake_duration, duration)
	_camera_shake_time = _camera_shake_duration


func _actualizar_temblo_camara(delta: float) -> void:
	var camera := get_node_or_null("CamaraDePrueba") as Camera2D
	if camera == null:
		return
	if _camera_shake_time > 0.0:
		_camera_shake_time = maxf(0.0, _camera_shake_time - delta)
		var fade := _camera_shake_time / maxf(_camera_shake_duration, 0.001)
		camera.offset = _camera_base_offset + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _camera_shake_intensity * fade
	else:
		camera.offset = _camera_base_offset


func _configurar_polvo() -> void:
	_dust = GPUParticles2D.new()
	_dust.name = "Polvo"
	_dust.emitting = false
	_dust.amount = 12
	_dust.lifetime = 0.38
	_dust.one_shot = true
	_dust.explosiveness = 0.9
	_dust.position = Vector2(0, 12)
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0, -1, 0)
	process.spread = 55.0
	process.initial_velocity_min = 12.0
	process.initial_velocity_max = 34.0
	process.gravity = Vector3(0, 30, 0)
	process.scale_min = 0.45
	process.scale_max = 0.9
	process.color = Color("#d9c49a")
	_dust.process_material = process
	var particula := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	particula.fill(Color.WHITE)
	_dust.texture = ImageTexture.create_from_image(particula)
	_dust.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_dust.visibility_rect = Rect2(-24, -32, 48, 40)
	add_child(_dust)
	var luz := PointLight2D.new()
	luz.name = "BrilloJugador"
	luz.texture = _crear_textura_luz()
	luz.energy = 0.32
	luz.texture_scale = 0.32
	luz.color = Color("#ffe3a8")
	add_child(luz)


func _emitir_polvo() -> void:
	if _dust != null:
		_dust.restart()
		_dust.emitting = true


func _crear_textura_luz() -> Texture2D:
	var gradiente := Gradient.new()
	gradiente.colors = [Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)]
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.width = 128
	textura.height = 128
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(0.5, 1.0)
	return textura


# Revisa con qué chocó Joshua en este frame:
# - Si le pegó a un bloque con la cabeza, lo golpea (como Mario).
# - Si cayó encima de un enemigo, lo aplasta y rebota.
# - Si un enemigo lo toca de lado, recibe daño (o lo elimina si tiene volován).
func _revisar_choques(was_falling: bool) -> void:
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var objeto := collision.get_collider()
		if not (objeto is Node):
			continue
		var normal := collision.get_normal()
		# normal.y > 0.5: la superficie apunta hacia abajo, o sea, chocó con la cabeza
		if normal.y > 0.5 and objeto.has_method("golpear"):
			objeto.golpear(self)
			return
		if not objeto.is_in_group("enemies"):
			continue
		if was_falling and normal.y < -0.5:
			velocity.y = JUMP_VELOCITY * STOMP_BOUNCE_MULTIPLIER
			SONIDO.efecto("aplastar")
			# Los enemigos nuevos tienen animación de muerte (y el jefe aguanta varios golpes)
			if objeto.has_method("aplastado"):
				objeto.aplastado()
			else:
				objeto.queue_free()
			return
		if absf(normal.x) > 0.5:
			if power_ups.is_invincible:
				if objeto.has_method("morir"):
					objeto.morir()
				else:
					objeto.queue_free()
			else:
				take_damage()
			return


# La llaman los power-ups (power_up.gd) y el bloque dorado
func collect_power_up(power_up_id: String) -> void:
	if power_up_id == "malanga_fuego":   # nombre viejo de la malanga
		power_up_id = "malanga_picante"
	power_ups.activate(power_up_id)


# Las llama el PowerUpController con el azulito / al perderlo
func crecer() -> void:
	_aplicar_tamano(true)
	_animar_crecimiento()


func encoger() -> void:
	_aplicar_tamano(false)


## Lo pueden llamar los enemigos al golpear a Joshua.
## Volován bloquea el daño; si es grande, solo se hace chico; si es chico, muere.
func take_damage() -> bool:
	if power_ups.is_invincible or _damage_cooldown > 0.0:
		return false
	shake(2.5, 0.16)
	_parpadeo = maxf(_parpadeo, 0.42)
	_damage_cooldown = 0.7
	if es_grande:
		SONIDO.efecto("encoger")
		power_ups.reset_growth()
		velocity.x = -facing_direction.x * 180.0
		velocity.y = -260.0
	else:
		morir()
	return true


func _aplicar_tamano(grande: bool) -> void:
	var altura_antes := _altura_actual()
	es_grande = grande
	var escala: float
	if ESTADO.personaje_seleccionado == "mujer" and _spriteframes_mujer != null:
		escala = ESCALA_MUJER_GRANDE if grande else ESCALA_MUJER_CHICA
	else:
		escala = ESCALA_GRANDE if grande else ESCALA_CHICO
	var capsula := CAPSULA_GRANDE if grande else CAPSULA_CHICO
	if _growth_tween and _growth_tween.is_running():
		_growth_tween.kill()
	animated_sprite.scale = Vector2(escala, escala)
	var forma := collision_shape.shape as CapsuleShape2D
	if forma != null:
		forma.radius = capsula.x
		forma.height = capsula.y
	# Que los pies sigan en el mismo lugar al crecer o encogerse
	global_position.y -= (_altura_actual() - altura_antes) * 0.5


func _actualizar_personaje_seleccionado() -> void:
	var usar_mujer := ESTADO.personaje_seleccionado == "mujer" and _spriteframes_mujer != null
	animated_sprite.sprite_frames = _spriteframes_mujer if usar_mujer else _spriteframes_hombre
	animated_sprite.offset = Vector2(0.0, SAM_OFFSET_Y) if usar_mujer else Vector2.ZERO
	animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	animated_sprite.modulate = Color.WHITE
	animated_sprite.play("idle")


func _crear_spriteframes_mujer() -> SpriteFrames:
	if _spriteframes_mujer_cache != null:
		return _spriteframes_mujer_cache
	var recurso_textura := ResourceLoader.load(TEXTURA_MUJER_PATH) as Texture2D
	if recurso_textura == null:
		push_warning("No se pudo cargar la hoja de sprites femenina: %s" % TEXTURA_MUJER_PATH)
		return null
	var imagen := recurso_textura.get_image()
	if imagen == null or imagen.is_empty():
		push_warning("No se pudo leer la hoja de sprites femenina: %s" % TEXTURA_MUJER_PATH)
		return null
	imagen.convert(Image.FORMAT_RGBA8)
	_eliminar_fondo_negro_exterior(imagen)
	var atlas := ImageTexture.create_from_image(imagen)
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	var ancho_celda := float(imagen.get_width()) / SAM_COLUMNAS
	var alto_celda := float(imagen.get_height()) / SAM_FILAS
	_agregar_frames_sam(frames, atlas, "idle", 1, [0], 1.0, true, ancho_celda, alto_celda, imagen.get_width(), imagen.get_height())
	_agregar_frames_sam(frames, atlas, "walk", 1, [0, 1, 2, 3, 4, 5], 8.0, true, ancho_celda, alto_celda, imagen.get_width(), imagen.get_height())
	_agregar_frames_sam(frames, atlas, "run", 1, [0, 1, 2, 3, 4, 5], 12.0, true, ancho_celda, alto_celda, imagen.get_width(), imagen.get_height())
	_agregar_frames_sam(frames, atlas, "jump", 0, [0, 1, 2], 8.0, false, ancho_celda, alto_celda, imagen.get_width(), imagen.get_height())
	_agregar_frames_sam(frames, atlas, "fall", 0, [3, 4, 5], 6.0, true, ancho_celda, alto_celda, imagen.get_width(), imagen.get_height())
	_spriteframes_mujer_cache = frames
	return frames


func _agregar_frames_sam(frames: SpriteFrames, atlas: Texture2D, nombre: String, fila: int, columnas: Array, velocidad: float, en_bucle: bool, ancho_celda: float, alto_celda: float, ancho_imagen: int, alto_imagen: int) -> void:
	frames.add_animation(nombre)
	frames.set_animation_speed(nombre, velocidad)
	frames.set_animation_loop(nombre, en_bucle)
	for columna in columnas:
		var x_inicio := roundi(ancho_celda * columna)
		var x_final := roundi(ancho_celda * (columna + 1))
		var y_inicio := fila * int(alto_celda)
		var region := Rect2(x_inicio, y_inicio, x_final - x_inicio, int(alto_celda))
		if region.position.x < 0 or region.end.x > ancho_imagen or region.end.y > alto_imagen:
			push_warning("La celda %d,%d está fuera de la hoja Sam.png." % [columna, fila])
			continue
		var textura := AtlasTexture.new()
		textura.atlas = atlas
		textura.region = region
		frames.add_frame(nombre, textura)


func _eliminar_fondo_negro_exterior(imagen: Image) -> void:
	var ancho := imagen.get_width()
	var alto := imagen.get_height()
	var cola := PackedInt32Array()
	cola.resize(ancho * alto)
	var siguiente := 0
	var fin := 0
	for x in range(ancho):
		if _es_fondo_negro(imagen.get_pixel(x, 0)):
			imagen.set_pixel(x, 0, Color(0, 0, 0, 0))
			cola[fin] = x
			fin += 1
		var indice_borde_inferior := (alto - 1) * ancho + x
		if _es_fondo_negro(imagen.get_pixel(x, alto - 1)):
			imagen.set_pixel(x, alto - 1, Color(0, 0, 0, 0))
			cola[fin] = indice_borde_inferior
			fin += 1
	for y in range(1, alto - 1):
		if _es_fondo_negro(imagen.get_pixel(0, y)):
			imagen.set_pixel(0, y, Color(0, 0, 0, 0))
			cola[fin] = y * ancho
			fin += 1
		if _es_fondo_negro(imagen.get_pixel(ancho - 1, y)):
			imagen.set_pixel(ancho - 1, y, Color(0, 0, 0, 0))
			cola[fin] = y * ancho + ancho - 1
			fin += 1
	while siguiente < fin:
		var indice := cola[siguiente]
		siguiente += 1
		var x_actual := indice % ancho
		var y_actual := floori(float(indice) / ancho)
		if x_actual > 0:
			var indice_izquierdo := indice - 1
			if _es_fondo_negro(imagen.get_pixel(x_actual - 1, y_actual)):
				imagen.set_pixel(x_actual - 1, y_actual, Color(0, 0, 0, 0))
				cola[fin] = indice_izquierdo
				fin += 1
		if x_actual + 1 < ancho:
			var indice_derecho := indice + 1
			if _es_fondo_negro(imagen.get_pixel(x_actual + 1, y_actual)):
				imagen.set_pixel(x_actual + 1, y_actual, Color(0, 0, 0, 0))
				cola[fin] = indice_derecho
				fin += 1
		if y_actual > 0:
			var indice_superior := indice - ancho
			if _es_fondo_negro(imagen.get_pixel(x_actual, y_actual - 1)):
				imagen.set_pixel(x_actual, y_actual - 1, Color(0, 0, 0, 0))
				cola[fin] = indice_superior
				fin += 1
		if y_actual + 1 < alto:
			var indice_vecino_inferior := indice + ancho
			if _es_fondo_negro(imagen.get_pixel(x_actual, y_actual + 1)):
				imagen.set_pixel(x_actual, y_actual + 1, Color(0, 0, 0, 0))
				cola[fin] = indice_vecino_inferior
				fin += 1
	cola.clear()


func _es_fondo_negro(pixel: Color) -> bool:
	return pixel.a > 0.0 and pixel.r <= 0.035 and pixel.g <= 0.035 and pixel.b <= 0.035


func _altura_actual() -> float:
	var forma := collision_shape.shape as CapsuleShape2D
	return forma.height if forma != null else 0.0


func _animar_crecimiento() -> void:
	# Animación de crecer del Joshua de Joseph, aplicada solo al dibujo
	var final := animated_sprite.scale
	animated_sprite.scale = final * 0.82
	_growth_tween = create_tween()
	_growth_tween.tween_property(animated_sprite, "scale", final * 1.1, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_growth_tween.tween_property(animated_sprite, "scale", final * 0.9, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_growth_tween.tween_property(animated_sprite, "scale", final, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# Guarda el punto de reaparición cada poco tiempo, solo si:
# - Joshua está parado en el piso del mapa (no en un bloque que se rompe ni en un enemigo)
# - hay piso debajo de los dos pies (no está en la orilla de un precipicio)
# - no hay enemigos cerca
func _guardar_punto_seguro(delta: float) -> void:
	_tiempo_punto_seguro -= delta
	if _tiempo_punto_seguro > 0.0 or _muriendo or not is_on_floor():
		return
	_tiempo_punto_seguro = INTERVALO_PUNTO_SEGURO
	if not (_piso_firme(-5.0) and _piso_firme(5.0)):
		return
	for enemigo in get_tree().get_nodes_in_group("enemies"):
		if enemigo is Node2D and enemigo.global_position.distance_to(global_position) < DISTANCIA_SEGURA_ENEMIGOS:
			return
	_punto_seguro = global_position
	_hay_punto_seguro = true


func _piso_firme(desplazamiento_x: float) -> bool:
	var desde := global_position + Vector2(desplazamiento_x, 0.0)
	var consulta := PhysicsRayQueryParameters2D.create(desde, desde + Vector2(0.0, 28.0), CAPA_MUNDO)
	consulta.exclude = [get_rid()]
	var choque := get_world_2d().direct_space_state.intersect_ray(consulta)
	return not choque.is_empty() and choque.collider is TileMapLayer


# La llama la zona de muerte (y take_damage cuando Joshua es chico).
# Pierde una vida y sus power-ups y reaparece cerca de donde murió.
# Si se queda sin vidas (game over), el nivel se repite desde el inicio.
func morir() -> void:
	if _muriendo:
		return
	_muriendo = true
	power_ups.lives -= 1
	ESTADO.vidas = power_ups.lives
	if power_ups.lives <= 0:
		# El jugador elige entre reintentar y volver al overworld.
		ESTADO.game_over()
		SONIDO.detener_musica()
		SONIDO.efecto("game_over")
		visible = false
		if hud != null:
			hud.visible = false
		set_process(false)
		set_physics_process(false)
		set_process_unhandled_input(false)
		var pantalla := GAME_OVER_SCRIPT.new()
		var escena_actual := get_tree().current_scene
		if escena_actual != null:
			escena_actual.add_child(pantalla)
		else:
			get_tree().root.add_child(pantalla)
		return
	SONIDO.efecto("morir")
	call_deferred("_reaparecer")


func _reaparecer() -> void:
	_muriendo = false
	power_ups.reset_effects()
	SONIDO.musica_invencible(false)
	_aplicar_tamano(false)
	var escena_actual := get_tree().current_scene
	if ESTADO.checkpoint_nivel9_activo and escena_actual != null and _es_nivel_9(escena_actual):
		global_position = ESTADO.checkpoint_nivel9
		_punto_seguro = ESTADO.checkpoint_nivel9
		_hay_punto_seguro = true
	else:
		global_position = _punto_seguro if _hay_punto_seguro else spawn_position
	velocity = Vector2.ZERO
	# Un rato sin recibir daño para que no lo vuelva a tocar un enemigo al aparecer
	_damage_cooldown = INVULNERABLE_AL_REAPARECER
	_parpadeo = INVULNERABLE_AL_REAPARECER
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	w_presionada_antes = false
	animated_sprite.play("idle")
	var camera := get_node_or_null("CamaraDePrueba") as Camera2D
	if camera != null:
		camera.reset_smoothing()


func _update_animation(direction: float) -> void:
	if not is_on_floor():
		if velocity.y < 0.0:
			animated_sprite.play("jump")
		else:
			animated_sprite.play("fall")
	elif not is_zero_approx(direction):
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")


# ---------------------------------------------------------------
# Efectos visuales de los power-ups (del Joshua de Joseph).
# Los dibujos estaban hechos para el sprite a escala 1, así que se
# dibujan con la misma escala que tiene el sprite ahora.
# ---------------------------------------------------------------

func _update_visual_effects() -> void:
	var parpadea: bool = power_ups.is_effect_near_expiration() or _parpadeo > 0.0
	var alpha := 0.18 if parpadea and int(_effect_clock * 8.0) % 2 == 0 else 1.0
	modulate = Color(1.0, 1.0, 1.0, alpha)
	if power_ups.attack_kind == "ice":
		animated_sprite.modulate = Color("#a8e9ff")
	elif power_ups.attack_kind == "fire":
		animated_sprite.modulate = Color("#ffd2a1")
	else:
		animated_sprite.modulate = Color.WHITE


func _on_power_up_collected(power_up_id: String) -> void:
	SONIDO.efecto(SONIDO_POWER_UP.get(power_up_id, "crecer"))
	if power_up_id == "volovan":
		SONIDO.musica_invencible(true)
	_held_item = POWER_UP_TEXTURES.get(power_up_id)
	_collection_flash = 0.38
	_consume_progress = 0.0
	if _consume_tween and _consume_tween.is_running():
		_consume_tween.kill()
	_consume_tween = create_tween()
	_consume_tween.tween_property(self, "_consume_progress", 1.0, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_consume_tween.tween_callback(_finish_consuming)
	queue_redraw()


func _on_power_up_expired(power_up_id: String) -> void:
	if power_up_id == "volovan":
		SONIDO.musica_invencible(false)


func _finish_consuming() -> void:
	_held_item = null
	_consume_progress = 0.0
	queue_redraw()


func _on_extra_life_added(_total_lives: int) -> void:
	# primero la mordida del taco y luego el sonido de vida extra
	get_tree().create_timer(0.7).timeout.connect(func(): SONIDO.efecto("vida_extra"))
	_life_popup_time = 1.2
	queue_redraw()


func _escala_dibujo() -> float:
	return absf(animated_sprite.scale.y)


func _draw() -> void:
	var k := _escala_dibujo()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	if _collection_flash > 0.0:
		var alpha := clampf(_collection_flash / 0.38, 0.0, 1.0)
		var radius := 210.0 + (1.0 - alpha) * 90.0
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(1.0, 0.88, 0.48, alpha), 18.0)
	if power_ups.attack_kind == "ice":
		_draw_ice_effect()
	elif power_ups.attack_kind == "fire":
		_draw_fire_effect()
	if power_ups.is_invincible:
		_draw_invincibility_aura()
	if _held_item:
		_draw_consumed_item(k)
	if _life_popup_time > 0.0:
		_draw_life_popup()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_ice_effect() -> void:
	var flicker := int(_effect_clock * 8.0) % 2
	var ice := Color(0.66, 0.93, 1.0, 0.85)
	draw_rect(Rect2(Vector2(-195, -185 - flicker * 2), Vector2(22, 22)), ice)
	draw_rect(Rect2(Vector2(173, -90), Vector2(22, 22)), ice)
	draw_rect(Rect2(Vector2(-180, 130 + flicker * 2), Vector2(18, 18)), ice)
	draw_rect(Rect2(Vector2(170, 150), Vector2(18, 18)), ice)


func _draw_fire_effect() -> void:
	var flicker := int(_effect_clock * 12.0) % 3
	var orange := Color("#ff8a36")
	var yellow := Color("#ffe27a")
	draw_rect(Rect2(Vector2(-205, -60 - flicker * 2), Vector2(24, 66 + flicker * 2)), orange)
	draw_rect(Rect2(Vector2(184, -170 + flicker * 2), Vector2(24, 74 - flicker * 2)), orange)
	draw_rect(Rect2(Vector2(-200, 92 + flicker), Vector2(16, 30)), yellow)
	draw_rect(Rect2(Vector2(190, 36 + flicker), Vector2(16, 32)), yellow)


func _draw_invincibility_aura() -> void:
	var pulse := 1.0 if int(_effect_clock * 8.0) % 2 == 0 else 0.55
	for i in range(6):
		var angle := _effect_clock * 2.0 + float(i) * TAU / 6.0
		var pos := Vector2(cos(angle) * 205.0, sin(angle) * 235.0)
		var color := Color(1.0, 0.84, 0.24, pulse) if i % 2 == 0 else Color(1.0, 1.0, 0.82, pulse)
		draw_rect(Rect2(pos, Vector2(22, 22)), color)


func _draw_consumed_item(k: float) -> void:
	var x_offset := facing_direction.x * 45.0
	var item_position := Vector2(x_offset, -285.0).lerp(Vector2(x_offset * 0.35, -175.0), _consume_progress)
	var item_size := Vector2(180, 180) * (1.0 - _consume_progress * 0.35)
	draw_set_transform(item_position * k, lerpf(-0.35, 0.0, _consume_progress), Vector2(k, k))
	draw_texture_rect(_held_item, Rect2(-item_size * 0.5, item_size), false, Color(1, 1, 1, 1.0 - _consume_progress * 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))


func _draw_life_popup() -> void:
	var alpha := minf(1.0, _life_popup_time * 2.0)
	var y := -310.0 - (1.2 - _life_popup_time) * 50.0
	var pink := Color(1.0, 0.25, 0.38, alpha)
	draw_rect(Rect2(Vector2(-80, y), Vector2(32, 32)), pink)
	draw_rect(Rect2(Vector2(-16, y), Vector2(32, 32)), pink)
	draw_rect(Rect2(Vector2(-96, y + 32), Vector2(144, 32)), pink)
	draw_rect(Rect2(Vector2(-64, y + 64), Vector2(80, 32)), pink)
	draw_rect(Rect2(Vector2(-32, y + 96), Vector2(32, 32)), pink)
	draw_string(ThemeDB.fallback_font, Vector2(64, y + 84), "+1", HORIZONTAL_ALIGNMENT_LEFT, -1, 72, Color.WHITE)
