extends Node2D

const TEXTURA_MAPA := preload("res://assets/overworld_super_tec.png")
const ESCENA_JOSHUA := preload("res://escenas/personajes_juegos/Joshua.tscn")
const ESTADO := preload("res://scripts/juego/estado_juego.gd")
const SONIDO := preload("res://scripts/juego/sonido.gd")
const TRANSICION := preload("res://scripts/ui/transicion_fade.gd")
const INICIO_PATH := "res://menu/menu_principal.tscn"   # Esc regresa al menú principal
const PROGRESO := preload("res://scripts/juego/progreso.gd")
const SELECTOR_RESPALDO_PATH := "res://escenas/pruebas/selector_escenarios.tscn"
const RUTAS_NIVELES := [
	"res://escenas/pruebas/niveles/nivel_1.tscn",
	"res://escenas/pruebas/niveles/nivel_2.tscn",
	"res://escenas/pruebas/niveles/nivel_3.tscn",
	"res://escenas/pruebas/niveles/nivel_4.tscn",
	"res://escenas/pruebas/niveles/nivel_5.tscn",
	"res://escenas/pruebas/niveles/nivel_6.tscn",
	"res://escenas/pruebas/niveles/nivel_7.tscn",
	"res://escenas/pruebas/niveles/nivel_8.tscn",
	"res://escenas/pruebas/niveles/nivel_9.tscn",
]
# En el orden en que se recorre el camino: 1-2-3 arriba, baja por la derecha
# al Edificio A (4), la fuente (5), el Domo (6), el estanque (7), M/N (8) y el estacionamiento (9).
const POSICIONES_NIVELES := [
	Vector2(252, 256), Vector2(642, 256), Vector2(1204, 256),
	Vector2(1085, 480), Vector2(820, 476), Vector2(366, 462),
	Vector2(753, 697), Vector2(1352, 664), Vector2(1337, 854),
]
const CAMINO := [
	Vector2(252, 256), Vector2(642, 256), Vector2(1204, 256),
	Vector2(1465, 262), Vector2(1492, 430), Vector2(1455, 480),
	Vector2(1200, 480), Vector2(1085, 480), Vector2(900, 476),
	Vector2(820, 476), Vector2(650, 476), Vector2(500, 460),
	Vector2(366, 462), Vector2(430, 485), Vector2(470, 535),
	Vector2(466, 630), Vector2(500, 680), Vector2(753, 697),
	Vector2(900, 705), Vector2(1030, 720), Vector2(1085, 690),
	Vector2(1120, 664), Vector2(1352, 664), Vector2(1460, 680),
	Vector2(1510, 710), Vector2(1510, 830), Vector2(1337, 854),
]
const VELOCIDAD := 155.0
const ANCHO_CAMINO := 38.0
const ZONAS_NIVELES := [
	"Acceso ITSX", "Edificio I", "Edificio E", "Edificio A", "Plaza Central",
	"Domo", "Estanque", "Edificios M y N", "Estacionamiento",
]

var _jugador: CharacterBody2D
var _sprite: AnimatedSprite2D
var _nodo_cercano := -1
# Selección de nivel de uno en uno: el personaje camina solo por el camino
var _nivel_actual := 0
var _caminando := false
var _flecha_izq: Polygon2D
var _flecha_der: Polygon2D
var _reloj := 0.0
var _cambiando_escena := false
var _etiquetas: Array[Label] = []
var _insignias: Array[Label] = []
# Letrero de abajo a la izquierda con el nivel más cercano
var _letrero: PanelContainer
var _letrero_nivel: Label
var _letrero_estado: Label

func _ready() -> void:
	SONIDO.inicializar()
	ESTADO.cargar_progreso()
	if not ESTADO.partida_iniciada:
		ESTADO.reiniciar()
	ESTADO.retorno_overworld_habilitado = true
	_crear_mapa()
	_crear_nodos_nivel()
	_crear_jugador()
	_crear_interfaz()
	var camera := Camera2D.new()
	camera.name = "CamaraOverworld"
	camera.position = TEXTURA_MAPA.get_size() * 0.5
	var escala_mapa := 512.0 / TEXTURA_MAPA.get_width()
	camera.zoom = Vector2(escala_mapa, escala_mapa)
	add_child(camera)
	camera.make_current()
	var entrada := TRANSICION.new()
	add_child(entrada)
	entrada.fade_in()

func _crear_mapa() -> void:
	var suelo := Polygon2D.new()
	suelo.name = "FondoExteriorMapa"
	suelo.polygon = PackedVector2Array([
		Vector2(-256, -256), Vector2(TEXTURA_MAPA.get_width() + 256, -256),
		Vector2(TEXTURA_MAPA.get_width() + 256, TEXTURA_MAPA.get_height() + 256),
		Vector2(-256, TEXTURA_MAPA.get_height() + 256),
	])
	suelo.color = Color("#43863d")
	add_child(suelo)
	var mapa := Sprite2D.new()
	mapa.name = "MapaCampus"
	mapa.texture = TEXTURA_MAPA
	mapa.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mapa.centered = false
	mapa.position = Vector2.ZERO
	add_child(mapa)
	var ambientacion := CanvasModulate.new()
	ambientacion.color = Color("#f7f1df")
	add_child(ambientacion)

func _crear_nodos_nivel() -> void:
	for indice in range(RUTAS_NIVELES.size()):
		var area := Area2D.new()
		area.name = "NodoNivel%d" % (indice + 1)
		area.position = POSICIONES_NIVELES[indice]
		area.collision_layer = 0
		area.collision_mask = 0
		var forma := CollisionShape2D.new()
		var circulo := CircleShape2D.new()
		circulo.radius = 34.0
		forma.shape = circulo
		area.add_child(forma)
		add_child(area)
		var etiqueta := Label.new()
		etiqueta.text = _texto_nodo(indice + 1)
		etiqueta.position = area.position + Vector2(-54, -74)
		etiqueta.size = Vector2(190, 44)
		etiqueta.visible = false
		etiqueta.add_theme_font_size_override("font_size", 11)
		etiqueta.add_theme_color_override("font_color", Color.WHITE)
		etiqueta.add_theme_color_override("font_outline_color", Color("#182638"))
		etiqueta.add_theme_constant_override("outline_size", 4)
		etiqueta.scale = Vector2(2.6, 2.6)
		add_child(etiqueta)
		_etiquetas.append(etiqueta)
		var insignia := Label.new()
		insignia.text = "✓"
		insignia.position = area.position + Vector2(19, -34)
		insignia.size = Vector2(28, 28)
		insignia.visible = ESTADO.nivel_completado(indice + 1)
		insignia.add_theme_font_size_override("font_size", 20)
		insignia.add_theme_color_override("font_color", Color("#a8ff87"))
		insignia.add_theme_color_override("font_outline_color", Color("#152a1b"))
		insignia.add_theme_constant_override("outline_size", 4)
		insignia.scale = Vector2(2.0, 2.0)
		insignia.z_index = 8
		add_child(insignia)
		_insignias.append(insignia)
	# Los números de la imagen no seguían el camino (y no traía el 4):
	# se dibujan encima los círculos con el número correcto de cada nivel.
	for indice in range(POSICIONES_NIVELES.size()):
		_crear_numero_nivel(indice + 1)

func _crear_numero_nivel(numero: int) -> void:
	var centro: Vector2 = POSICIONES_NIVELES[numero - 1]
	var poligono := Polygon2D.new()
	var puntos := PackedVector2Array()
	for i in range(32):
		var angulo := TAU * float(i) / 32.0
		puntos.append(Vector2(cos(angulo), sin(angulo)) * 25.0)
	# Base oscura un poco más grande para tapar el número que trae la imagen
	var tapa := Polygon2D.new()
	var puntos_tapa := PackedVector2Array()
	for p in puntos:
		puntos_tapa.append(p * 1.22)
	tapa.polygon = puntos_tapa
	tapa.position = centro
	tapa.color = Color("#2a0d0b")
	tapa.z_index = 3
	add_child(tapa)
	poligono.polygon = puntos
	poligono.position = centro
	poligono.color = Color("#d8261d")
	poligono.z_index = 3
	add_child(poligono)
	var borde := Line2D.new()
	var puntos_borde := puntos.duplicate()
	puntos_borde.append(puntos[0])
	borde.points = puntos_borde
	borde.position = centro
	borde.width = 4.0
	borde.default_color = Color.WHITE
	borde.z_index = 4
	add_child(borde)
	var etiqueta := Label.new()
	etiqueta.text = str(numero)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.size = Vector2(36, 36)
	etiqueta.pivot_offset = etiqueta.size / 2.0
	etiqueta.position = centro - etiqueta.size / 2.0
	etiqueta.add_theme_font_size_override("font_size", 24)
	etiqueta.add_theme_color_override("font_color", Color.WHITE)
	etiqueta.add_theme_color_override("font_outline_color", Color.BLACK)
	etiqueta.add_theme_constant_override("outline_size", 4)
	etiqueta.scale = Vector2(1.4, 1.4)
	etiqueta.z_index = 5
	add_child(etiqueta)

func _crear_jugador() -> void:
	_jugador = CharacterBody2D.new()
	_jugador.name = "JugadorOverworld"
	var inicio: Vector2 = ESTADO.posicion_overworld if ESTADO.posicion_overworld != Vector2.ZERO else POSICIONES_NIVELES[0]
	_nivel_actual = 0
	for indice in range(POSICIONES_NIVELES.size()):
		if inicio.distance_to(POSICIONES_NIVELES[indice]) < inicio.distance_to(POSICIONES_NIVELES[_nivel_actual]):
			_nivel_actual = indice
	_jugador.position = POSICIONES_NIVELES[_nivel_actual]
	add_child(_jugador)
	var prototipo := ESCENA_JOSHUA.instantiate() as CharacterBody2D
	var sprite_original := prototipo.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var frames := sprite_original.sprite_frames
	var usar_mujer := false
	if ESTADO.personaje_seleccionado == "mujer":
		var frames_mujer = prototipo.call("_crear_spriteframes_mujer")
		if frames_mujer is SpriteFrames:
			frames = frames_mujer
			usar_mujer = true
	prototipo.free()
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "AnimatedSprite2D"
	_sprite.sprite_frames = frames
	_sprite.offset = Vector2(0.0, -36.0) if usar_mujer else Vector2.ZERO
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# 1.5 veces más grande que antes, y siempre por encima de los círculos de los niveles
	_sprite.scale = Vector2(0.096, 0.096) if usar_mujer else Vector2(0.135, 0.135)
	_jugador.z_index = 20
	_sprite.play("idle")
	_jugador.add_child(_sprite)

func _crear_interfaz() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var guia := Label.new()
	guia.text = "← / → (A / D) cambiar de nivel · Enter entrar · Esc menú · M audio"
	guia.anchor_left = 0.0
	guia.anchor_right = 1.0
	guia.anchor_top = 1.0
	guia.anchor_bottom = 1.0
	guia.offset_left = 8.0
	guia.offset_top = -22.0
	guia.offset_right = -8.0
	guia.offset_bottom = -3.0
	guia.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guia.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	guia.add_theme_font_size_override("font_size", 9)
	guia.add_theme_color_override("font_color", Color.WHITE)
	guia.add_theme_color_override("font_outline_color", Color("#1b2a36"))
	guia.add_theme_constant_override("outline_size", 3)
	layer.add_child(guia)
	_crear_letrero(layer)
	# Nombre del mapa arriba a la izquierda
	var titulo := Label.new()
	titulo.text = "Mapa del Tec"
	titulo.position = Vector2(8, 4)
	titulo.add_theme_font_size_override("font_size", 18)
	titulo.add_theme_color_override("font_color", Color("#ffe28a"))
	titulo.add_theme_color_override("font_outline_color", Color("#182638"))
	titulo.add_theme_constant_override("outline_size", 5)
	layer.add_child(titulo)


func _crear_letrero(layer: CanvasLayer) -> void:
	_letrero = PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.06, 0.13, 0.22, 0.88)
	estilo.border_color = Color("#f1c65a")
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(8)
	estilo.content_margin_left = 12
	estilo.content_margin_right = 14
	estilo.content_margin_top = 6
	estilo.content_margin_bottom = 8
	_letrero.add_theme_stylebox_override("panel", estilo)
	_letrero.anchor_top = 1.0
	_letrero.anchor_bottom = 1.0
	_letrero.offset_left = 8.0
	_letrero.offset_bottom = -26.0
	_letrero.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_letrero.visible = false
	layer.add_child(_letrero)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 0)
	_letrero.add_child(columna)
	_letrero_nivel = Label.new()
	_letrero_nivel.add_theme_font_size_override("font_size", 22)
	_letrero_nivel.add_theme_color_override("font_color", Color("#ffe28a"))
	_letrero_nivel.add_theme_color_override("font_outline_color", Color("#182638"))
	_letrero_nivel.add_theme_constant_override("outline_size", 4)
	columna.add_child(_letrero_nivel)
	_letrero_estado = Label.new()
	_letrero_estado.add_theme_font_size_override("font_size", 17)
	_letrero_estado.add_theme_color_override("font_outline_color", Color("#182638"))
	_letrero_estado.add_theme_constant_override("outline_size", 4)
	columna.add_child(_letrero_estado)


func _actualizar_letrero(indice: int) -> void:
	if _letrero == null:
		return
	_letrero.visible = indice >= 0
	if indice < 0:
		return
	var numero := indice + 1
	_letrero_nivel.text = "Nivel %d" % numero
	if not PROGRESO.desbloqueado(numero):
		_letrero_estado.text = "Bloqueado"
		_letrero_estado.add_theme_color_override("font_color", Color("#ff8a80"))
	else:
		var creditos := PROGRESO.creditos_nivel(numero)
		_letrero_estado.text = "%d/%d créditos" % [creditos, PROGRESO.CREDITOS_POR_NIVEL]
		_letrero_estado.add_theme_color_override("font_color",
			Color("#ffe28a") if creditos >= PROGRESO.CREDITOS_POR_NIVEL else Color.WHITE)

func _process(_delta: float) -> void:
	if _jugador == null:
		return
	var mas_cercano := -1
	var distancia := 64.0
	for indice in range(POSICIONES_NIVELES.size()):
		var nueva_distancia := _jugador.position.distance_to(POSICIONES_NIVELES[indice])
		if nueva_distancia < distancia:
			distancia = nueva_distancia
			mas_cercano = indice
	for indice in range(_etiquetas.size()):
		_etiquetas[indice].visible = false   # ahora se usa el letrero de abajo a la izquierda
		_insignias[indice].visible = ESTADO.nivel_completado(indice + 1)
		_etiquetas[indice].text = _texto_nodo(indice + 1)
	_nodo_cercano = mas_cercano
	_actualizar_letrero(mas_cercano)

# Solo se entra a los niveles superados y al siguiente (como Continuar);
# cada nivel dice cuántos créditos llevas de 20.
func _texto_nodo(numero: int) -> String:
	if not PROGRESO.desbloqueado(numero):
		return "Nivel %d · %s\nBloqueado · pasa el nivel %d" % [numero, ZONAS_NIVELES[numero - 1], numero - 1]
	var creditos := "%d/%d créditos" % [PROGRESO.creditos_nivel(numero), PROGRESO.CREDITOS_POR_NIVEL]
	var estado := "Completado" if ESTADO.nivel_completado(numero) else "Enter para entrar"
	return "Nivel %d · %s\n%s · %s" % [numero, ZONAS_NIVELES[numero - 1], creditos, estado]

func _physics_process(delta: float) -> void:
	if _jugador == null:
		return
	_reloj += delta
	_actualizar_flechas()
	if _caminando or _cambiando_escena:
		return
	_sprite.play("idle")
	var derecha := Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_down") \
		or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_S)
	var izquierda := Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_up") \
		or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_W)
	if derecha and not izquierda:
		_ir_a_nivel(_nivel_actual + 1)
	elif izquierda and not derecha:
		_ir_a_nivel(_nivel_actual - 1)


## Camina por el camino hasta el nivel indicado (solo uno a la vez)
func _ir_a_nivel(indice: int) -> void:
	if indice < 0 or indice >= POSICIONES_NIVELES.size():
		return
	if not PROGRESO.desbloqueado(indice + 1):
		if not _caminando:
			_caminando = true
			SONIDO.efecto("golpe_bloque")
			var tw := create_tween()
			var sentido := signf(float(indice - _nivel_actual))
			tw.tween_property(_jugador, "position", POSICIONES_NIVELES[_nivel_actual] + Vector2(10.0 * sentido, 0), 0.07)
			tw.tween_property(_jugador, "position", POSICIONES_NIVELES[_nivel_actual], 0.1)
			tw.tween_interval(0.15)
			tw.tween_callback(func(): _caminando = false)
		return
	var desde := CAMINO.find(POSICIONES_NIVELES[_nivel_actual])
	var hasta := CAMINO.find(POSICIONES_NIVELES[indice])
	var puntos: Array[Vector2] = []
	if desde < 0 or hasta < 0 or desde == hasta:
		puntos.append(POSICIONES_NIVELES[indice])
	else:
		var paso := 1 if hasta > desde else -1
		var k := desde + paso
		while true:
			puntos.append(CAMINO[k])
			if k == hasta:
				break
			k += paso
	_caminando = true
	_sprite.play("walk")
	var tw := create_tween()
	var anterior: Vector2 = _jugador.position
	for punto in puntos:
		var tiempo := anterior.distance_to(punto) / (VELOCIDAD * 2.2)
		tw.tween_callback(_mirar_hacia.bind(punto))
		tw.tween_property(_jugador, "position", punto, tiempo)
		anterior = punto
	tw.tween_callback(func():
		_nivel_actual = indice
		_caminando = false
		_sprite.play("idle"))


func _mirar_hacia(punto: Vector2) -> void:
	if absf(punto.x - _jugador.position.x) > 1.0:
		_sprite.flip_h = punto.x < _jugador.position.x


# Flechitas a los lados del personaje: a qué nivel puedes moverte
func _crear_flechas() -> void:
	_flecha_izq = Polygon2D.new()
	_flecha_izq.polygon = PackedVector2Array([Vector2(0, -34), Vector2(0, 34), Vector2(-42, 0)])
	_flecha_der = Polygon2D.new()
	_flecha_der.polygon = PackedVector2Array([Vector2(0, -34), Vector2(0, 34), Vector2(42, 0)])
	for f in [_flecha_izq, _flecha_der]:
		f.color = Color("#ffd23f")
		f.z_index = 25
		var borde := Line2D.new()
		var pts: PackedVector2Array = f.polygon.duplicate()
		pts.append(pts[0])
		borde.points = pts
		borde.width = 9.0
		borde.default_color = Color("#14202e")
		borde.joint_mode = Line2D.LINE_JOINT_ROUND
		f.add_child(borde)
		f.move_child(borde, 0)
		add_child(f)


func _actualizar_flechas() -> void:
	if _flecha_izq == null:
		_crear_flechas()
	var vaiven := sin(_reloj * 6.0) * 6.0
	var base := _jugador.position + Vector2(0, -45)
	_flecha_izq.position = base + Vector2(-80 - vaiven, 0)
	_flecha_der.position = base + Vector2(80 + vaiven, 0)
	_flecha_izq.visible = not _caminando and _nivel_actual > 0
	_flecha_der.visible = not _caminando and _nivel_actual < POSICIONES_NIVELES.size() - 1
	# la flecha hacia un nivel bloqueado sale gris
	_flecha_der.color = Color("#ffd23f") if PROGRESO.desbloqueado(_nivel_actual + 2) else Color("#7d8591")


func _sobre_camino(punto: Vector2) -> bool:
	for indice in range(CAMINO.size() - 1):
		var cercano := Geometry2D.get_closest_point_to_segment(punto, CAMINO[indice], CAMINO[indice + 1])
		if punto.distance_squared_to(cercano) <= ANCHO_CAMINO * ANCHO_CAMINO:
			return true
	return false

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9 and not _cambiando_escena:
		ESTADO.retorno_overworld_habilitado = false
		call_deferred("_cambiar_a", SELECTOR_RESPALDO_PATH)
		return
	if event.is_action_pressed("ui_cancel") and not _cambiando_escena:
		call_deferred("_cambiar_a", INICIO_PATH)
	elif event.is_action_pressed("ui_accept") and _nodo_cercano >= 0 and not _cambiando_escena and not _caminando:
		if not PROGRESO.desbloqueado(_nodo_cercano + 1):
			SONIDO.efecto("golpe_bloque")
			return
		ESTADO.posicion_overworld = POSICIONES_NIVELES[_nodo_cercano]
		call_deferred("_cambiar_a", RUTAS_NIVELES[_nodo_cercano])

func _cambiar_a(ruta: String) -> void:
	if _cambiando_escena:
		return
	_cambiando_escena = true
	var salida := TRANSICION.new()
	add_child(salida)
	await salida.fade_out()
	var error := get_tree().change_scene_to_file(ruta)
	if error != OK:
		_cambiando_escena = false
		await salida.fade_in()
		push_error("No se pudo abrir la escena: %s" % ruta)
