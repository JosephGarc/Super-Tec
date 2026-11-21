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

# Punto donde reaparece Joshua al morir. Se guarda en el primer frame,
# porque el escenario de prueba lo coloca en SpawnJugador después de agregarlo.
var spawn_position := Vector2.ZERO
var spawn_guardado := false
# Altura a partir de la cual Joshua se considera caído al vacío (la pone probar_escenario.gd)
var limite_caida := INF
var _muriendo := false

# Se cargan con preload para no depender de la caché de class_name de Godot
const HUD_SCRIPT := preload("res://scripts/powerups/hud_super_tec.gd")
var hud: CanvasLayer

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var power_ups: Node = $PowerUpController   # power_up_controller.gd


func _ready() -> void:
	add_to_group("jugador")
	# Joshua está en la capa "mundo" (para que lo detecten la zona de muerte y los power-ups)
	# y en la capa "jugador". Choca con el mundo y con los bloques.
	collision_layer = CAPA_MUNDO | CAPA_JUGADOR
	collision_mask = CAPA_MUNDO | CAPA_BLOQUES
	# Cada Joshua usa su propia forma de colisión para poder cambiarla de tamaño
	collision_shape.shape = collision_shape.shape.duplicate()
	_aplicar_tamano(false)

	power_ups.power_up_collected.connect(_on_power_up_collected)
	power_ups.extra_life_added.connect(_on_extra_life_added)

	hud = HUD_SCRIPT.new()
	add_child(hud)
	hud.configurar(power_ups)


func _physics_process(delta: float) -> void:
	if not spawn_guardado:
		spawn_position = global_position
		spawn_guardado = true

	_effect_clock += delta
	_damage_cooldown = maxf(0.0, _damage_cooldown - delta)

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
	var was_falling := velocity.y > 0.0
	move_and_slide()
	_revisar_choques(was_falling)
	_update_visual_effects()
	if global_position.y > limite_caida:
		morir()


func _process(delta: float) -> void:
	_life_popup_time = maxf(0.0, _life_popup_time - delta)
	queue_redraw()


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
	_damage_cooldown = 0.7
	if es_grande:
		power_ups.reset_growth()
		velocity.x = -facing_direction.x * 180.0
		velocity.y = -260.0
	else:
		morir()
	return true


func _aplicar_tamano(grande: bool) -> void:
	var altura_antes := _altura_actual()
	es_grande = grande
	var escala := ESCALA_GRANDE if grande else ESCALA_CHICO
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


# La llama la zona de muerte (y take_damage cuando Joshua es chico).
# Pierde una vida y sus power-ups; si se queda sin vidas, el nivel se reinicia.
func morir() -> void:
	if _muriendo:
		return
	_muriendo = true
	power_ups.lives -= 1
	if power_ups.lives <= 0:
		get_tree().call_deferred("reload_current_scene")
		return
	call_deferred("_reaparecer")


func _reaparecer() -> void:
	_muriendo = false
	power_ups.reset_effects()
	_aplicar_tamano(false)
	global_position = spawn_position
	velocity = Vector2.ZERO
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
	var alpha := 0.18 if power_ups.is_effect_near_expiration() and int(_effect_clock * 8.0) % 2 == 0 else 1.0
	modulate = Color(1.0, 1.0, 1.0, alpha)
	if power_ups.attack_kind == "ice":
		animated_sprite.modulate = Color("#a8e9ff")
	elif power_ups.attack_kind == "fire":
		animated_sprite.modulate = Color("#ffd2a1")
	else:
		animated_sprite.modulate = Color.WHITE


func _on_power_up_collected(power_up_id: String) -> void:
	_held_item = POWER_UP_TEXTURES.get(power_up_id)
	_consume_progress = 0.0
	if _consume_tween and _consume_tween.is_running():
		_consume_tween.kill()
	_consume_tween = create_tween()
	_consume_tween.tween_property(self, "_consume_progress", 1.0, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_consume_tween.tween_callback(_finish_consuming)
	queue_redraw()


func _finish_consuming() -> void:
	_held_item = null
	_consume_progress = 0.0
	queue_redraw()


func _on_extra_life_added(_total_lives: int) -> void:
	_life_popup_time = 1.2
	queue_redraw()


func _escala_dibujo() -> float:
	return absf(animated_sprite.scale.y)


func _draw() -> void:
	var k := _escala_dibujo()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
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
