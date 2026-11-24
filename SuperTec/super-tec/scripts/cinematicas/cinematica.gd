extends Control
## ==========================================================
##  SUPER TEC - Cinemáticas
##  Todo se arma por código (fondos, personajes y diálogos).
##
##  tipo = "intro": Joshua entra al Tec (al dar NUEVA PARTIDA) -> Nivel 1
##  tipo = "final": al pasar el Nivel 9:
##      con los 180 créditos  -> Joshua recibe su título -> menú
##      con menos             -> le exigen los créditos que faltan -> Continuar
##
##  Controles: Enter / Espacio / clic = siguiente diálogo, Esc = saltar.
## ==========================================================

@export_enum("intro", "final") var tipo := "intro"

const SONIDO := preload("res://scripts/juego/sonido.gd")
const PROGRESO := preload("res://scripts/juego/progreso.gd")
const CREDITOS_EQUIPO := preload("res://scripts/juego/creditos_equipo.gd")
const TEX_EUGENIO := preload("res://assets/powerups/credito_eugenio.png")

const NIVEL_1 := "res://escenas/pruebas/niveles/nivel_1.tscn"
const MENU := "res://menu/menu_principal.tscn"
const CONTINUAR := "res://escenas/pruebas/selector_escenarios.tscn"

const PISO := 268.0
const ESCALA_JOSHUA := 0.11
const C_DORADO := Color("f2c14e")
const C_AZUL_TEC := Color("1b3b6f")

var _fondo: Escenario
var _actores: Node2D
var _joshua: AnimatedSprite2D
var _eugenio: Eugenio
var _diploma: Diploma
var _birrete: Birrete
var _caja: PanelContainer
var _retrato: TextureRect
var _nombre: Label
var _texto: Label
var _cartel: Label
var _fade: ColorRect
var _saltar := false
var _avanzar := false
var _terminado := false


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	PROGRESO.cargar()
	PROGRESO.empezar_nivel(0)
	_construir()
	match tipo:
		"intro": _intro()
		_:
			if PROGRESO.total() >= PROGRESO.CREDITOS_TOTALES:
				_titulo()
			else:
				_faltan_creditos()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		_saltar = true
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("ui_accept") or (evento is InputEventMouseButton and evento.pressed) \
			or (evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode == KEY_W):
		_avanzar = true
		get_viewport().set_input_as_handled()


# ==========================================================
#  Las 3 cinemáticas
# ==========================================================

func _intro() -> void:
	_fondo.modo = "campus"
	SONIDO.musica("campus_dia")
	_joshua.position = Vector2(-30, _y_joshua())
	_eugenio.position = Vector2(440, PISO)
	_eugenio.visible = false
	await _aparecer_desde_negro()
	await _mostrar_cartel("Xalapa, Veracruz\nPrimer día de clases")
	await _caminar(255, 3.2)
	await _decir("Joshua", "¡Por fin! Primer día en el Tecnológico Superior de Xalapa.")
	await _aparecer(_eugenio)
	await _decir("Eugenio", "Bienvenido al Tec, Joshua. Yo soy Eugenio... el de los créditos.")
	await _decir("Eugenio", "Para titularte tienes que pasar los 9 semestres y juntar mis 180 créditos.")
	await _decir("Joshua", "¿Los 180? Va, ¡voy por todos!")
	await _caminar(380, 1.3)
	await _entrar_por_la_puerta()
	await _terminar(NIVEL_1)


func _titulo() -> void:
	_fondo.modo = "auditorio"
	SONIDO.musica("menu")
	_joshua.position = Vector2(-30, _y_joshua())
	_eugenio.position = Vector2(330, PISO)
	_diploma.position = _eugenio.position + Vector2(-16, -30)
	_diploma.visible = true
	await _aparecer_desde_negro()
	await _mostrar_cartel("Ceremonia de graduación\nGeneración 2026")
	await _caminar(272, 3.0)
	await _decir("Eugenio", "180 de 180 créditos. ¡Lo lograste, Joshua!")
	await _decir("Eugenio", "Te entrego tu título de Ingeniero en Sistemas Computacionales.")
	await _mover(_diploma, _joshua.position + Vector2(14, -2), 0.8)
	_diploma.reparent(_joshua)   # ahora lo trae Joshua
	SONIDO.efecto("vida_extra")
	_fondo.confeti = true
	await _aparecer(_birrete)
	await _brincar()
	await _decir("Joshua", "¡Lo logré! ¡Ingeniero Joshua!")
	await _esperar(1.0)
	await _pantalla_fin()
	await _terminar(MENU)


func _faltan_creditos() -> void:
	var tiene := PROGRESO.total()
	var faltan := PROGRESO.CREDITOS_TOTALES - tiene
	_fondo.modo = "oficina"
	SONIDO.musica("campus_noche")
	_joshua.position = Vector2(-30, _y_joshua())
	_eugenio.position = Vector2(372, PISO)
	await _aparecer_desde_negro()
	await _mostrar_cartel("Servicios Escolares")
	await _caminar(262, 2.8)
	await _decir("Joshua", "Vengo por mi título. Ya pasé los 9 semestres.")
	await _decir("Eugenio", "A ver tu kárdex...")
	await _sacudir(_eugenio)
	await _decir("Eugenio", "Tienes %d de 180 créditos. Te faltan %d." % [tiene, faltan])
	await _decir("Eugenio", "Sin los 180 créditos no hay título.")
	await _decir("Joshua", "¿Neta? ¿Y ahora qué hago?")
	await _decir("Eugenio", "Regresa a los semestres y consigue los que te faltan. Aquí te espero.")
	await _mostrar_cartel("Usa CONTINUAR para repetir niveles\ny conseguir los créditos que te faltan.", 3.5)
	await _terminar(CONTINUAR)


# ==========================================================
#  Ayudantes de la cinemática (si se presiona Esc, todo pasa al instante)
# ==========================================================

func _esperar(segundos: float) -> void:
	var t := 0.0
	while t < segundos and not _saltar:
		await get_tree().process_frame
		t += get_process_delta_time()


func _esperar_tween(tw: Tween) -> void:
	while tw.is_valid() and tw.is_running() and not _saltar:
		await get_tree().process_frame
	if _saltar and tw.is_valid():
		tw.custom_step(100.0)


func _caminar(x: float, segundos: float) -> void:
	_joshua.flip_h = x < _joshua.position.x
	_joshua.play("walk")
	var tw := create_tween()
	tw.tween_property(_joshua, "position:x", x, segundos)
	await _esperar_tween(tw)
	_joshua.play("idle")


func _mover(nodo: Node2D, destino: Vector2, segundos: float) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property(nodo, "position", destino, segundos)
	await _esperar_tween(tw)


func _aparecer(nodo: Node2D) -> void:
	var escala := nodo.scale
	nodo.visible = true
	nodo.scale = escala * 0.2
	SONIDO.efecto("aparece_powerup", -6.0)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(nodo, "scale", escala, 0.35)
	await _esperar_tween(tw)


func _sacudir(nodo: Node2D) -> void:
	var x := nodo.position.x
	var tw := create_tween()
	for i in 4:
		tw.tween_property(nodo, "position:x", x + (3.0 if i % 2 == 0 else -3.0), 0.08)
	tw.tween_property(nodo, "position:x", x, 0.08)
	await _esperar_tween(tw)
	await _esperar(0.4)


func _brincar() -> void:
	var y := _joshua.position.y
	_joshua.play("jump")
	SONIDO.efecto("salto")
	var tw := create_tween()
	for i in 2:
		tw.tween_property(_joshua, "position:y", y - 22.0, 0.22).set_ease(Tween.EASE_OUT)
		tw.tween_property(_joshua, "position:y", y, 0.22).set_ease(Tween.EASE_IN)
	await _esperar_tween(tw)
	_joshua.play("idle")


func _entrar_por_la_puerta() -> void:
	var tw := create_tween()
	tw.tween_property(_joshua, "modulate:a", 0.0, 0.6)
	tw.parallel().tween_property(_eugenio, "modulate:a", 0.0, 0.6)
	await _esperar_tween(tw)


func _decir(quien: String, texto: String) -> void:
	if _saltar:
		return
	_caja.visible = true
	_nombre.text = quien
	_retrato.texture = TEX_EUGENIO if quien == "Eugenio" else _joshua.sprite_frames.get_frame_texture("idle", 0)
	_texto.text = texto
	_texto.visible_characters = 0
	_avanzar = false
	var total := texto.length()
	while _texto.visible_characters < total and not _saltar:
		if _avanzar:
			_avanzar = false
			_texto.visible_characters = total
			break
		_texto.visible_characters += 1
		if _texto.visible_characters % 3 == 0:
			SONIDO.efecto("menu", -16.0)
		await _esperar(0.03)
	# Avanza con Enter (o solo, si no presionas nada)
	var limite := 2.5 + total * 0.035
	var t := 0.0
	while not _avanzar and not _saltar and t < limite:
		await get_tree().process_frame
		t += get_process_delta_time()
	_avanzar = false
	_caja.visible = false


func _mostrar_cartel(texto: String, segundos: float = 2.4) -> void:
	if _saltar:
		return
	_cartel.text = texto
	_cartel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_cartel, "modulate:a", 1.0, 0.5)
	await _esperar_tween(tw)
	await _esperar(segundos)
	tw = create_tween()
	tw.tween_property(_cartel, "modulate:a", 0.0, 0.5)
	await _esperar_tween(tw)


func _aparecer_desde_negro() -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.8)
	await _esperar_tween(tw)


func _pantalla_fin() -> void:
	if _saltar:
		return
	var capa := ColorRect.new()
	capa.color = Color(0, 0, 0, 0.0)
	capa.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(capa)
	var caja := VBoxContainer.new()
	caja.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_theme_constant_override("separation", 4)
	capa.add_child(caja)
	caja.add_child(_etiqueta("FIN", 40, C_DORADO))
	caja.add_child(_etiqueta("Gracias por jugar Super Tec", 16, Color.WHITE))
	caja.add_child(_etiqueta(" ", 8, Color.WHITE))
	for linea in CREDITOS_EQUIPO.LINEAS:
		caja.add_child(_etiqueta(linea, 11, Color.WHITE))
	caja.add_child(_etiqueta(" ", 8, Color.WHITE))
	caja.add_child(_etiqueta("Tecnológico Superior de Xalapa · 2026", 11, C_DORADO))
	caja.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(capa, "color:a", 0.88, 1.0)
	tw.parallel().tween_property(caja, "modulate:a", 1.0, 1.0)
	await _esperar_tween(tw)
	_avanzar = false
	var t := 0.0
	while not _avanzar and not _saltar and t < 9.0:
		await get_tree().process_frame
		t += get_process_delta_time()


func _terminar(escena: String) -> void:
	if _terminado:
		return
	_terminado = true
	_caja.visible = false
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.5)
	await tw.finished
	get_tree().change_scene_to_file(escena)


# ==========================================================
#  Construcción
# ==========================================================

func _y_joshua() -> float:
	return PISO - 254.0 * ESCALA_JOSHUA


func _construir() -> void:
	_fondo = Escenario.new()
	add_child(_fondo)

	_actores = Node2D.new()
	add_child(_actores)
	_eugenio = Eugenio.new()
	_actores.add_child(_eugenio)
	_diploma = Diploma.new()
	_diploma.visible = false
	_actores.add_child(_diploma)

	# Joshua con sus mismas animaciones del juego
	var j: Node = load("res://escenas/personajes_juegos/Joshua.tscn").instantiate()
	var frames: SpriteFrames = (j.get_node("AnimatedSprite2D") as AnimatedSprite2D).sprite_frames
	j.free()
	_joshua = AnimatedSprite2D.new()
	_joshua.sprite_frames = frames
	_joshua.scale = Vector2(ESCALA_JOSHUA, ESCALA_JOSHUA)
	_joshua.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_joshua.play("idle")
	_actores.add_child(_joshua)

	# El birrete va pegado a la cabeza de Joshua (compensa la escala del sprite)
	_birrete = Birrete.new()
	_birrete.visible = false
	_birrete.scale = Vector2.ONE / ESCALA_JOSHUA
	_birrete.position = Vector2(0, -238)
	_joshua.add_child(_birrete)

	# Cartel (textos grandes de lugar/tiempo)
	_cartel = _etiqueta("", 20, Color.WHITE)
	_cartel.set_anchors_preset(PRESET_TOP_WIDE)
	_cartel.offset_top = 40
	_cartel.offset_bottom = 110
	_cartel.modulate.a = 0.0
	add_child(_cartel)

	# Caja de diálogo
	_caja = PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(C_AZUL_TEC, 0.94)
	estilo.border_color = C_DORADO
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(4)
	estilo.set_content_margin_all(6)
	_caja.add_theme_stylebox_override("panel", estilo)
	_caja.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_caja.offset_left = 8
	_caja.offset_right = -8
	_caja.offset_top = -92
	_caja.offset_bottom = -8
	_caja.visible = false
	add_child(_caja)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	_caja.add_child(fila)
	_retrato = TextureRect.new()
	_retrato.custom_minimum_size = Vector2(56, 56)
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fila.add_child(_retrato)
	var columna := VBoxContainer.new()
	columna.size_flags_horizontal = SIZE_EXPAND_FILL
	fila.add_child(columna)
	_nombre = _etiqueta("", 13, C_DORADO)
	_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	columna.add_child(_nombre)
	_texto = _etiqueta("", 12, Color.WHITE)
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.size_flags_vertical = SIZE_EXPAND_FILL
	columna.add_child(_texto)
	var pista := _etiqueta("Enter ▶", 9, Color(1, 1, 1, 0.7))
	pista.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	columna.add_child(pista)

	var saltar := _etiqueta("Esc: saltar", 9, Color(1, 1, 1, 0.75))
	saltar.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	saltar.set_anchors_preset(PRESET_TOP_WIDE)
	saltar.offset_top = 4
	saltar.offset_right = -6
	saltar.offset_bottom = 18
	add_child(saltar)

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_fade.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_fade)


func _etiqueta(texto: String, tam: int, color: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	return l


# ==========================================================
#  Personajes y objetos dibujados por código
# ==========================================================

## Eugenio: la cara del crédito Eugenio con traje
class Eugenio extends Node2D:
	func _ready() -> void:
		var cara := Sprite2D.new()
		cara.texture = preload("res://assets/powerups/credito_eugenio.png")
		cara.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cara.scale = Vector2(2.4, 2.4)
		cara.position = Vector2(0, -44)
		add_child(cara)

	func _draw() -> void:
		draw_rect(Rect2(-7, -12, 5, 12), Color("2b2b33"))          # piernas
		draw_rect(Rect2(2, -12, 5, 12), Color("2b2b33"))
		draw_rect(Rect2(-11, -26, 22, 16), Color("1b3b6f"))         # saco
		draw_colored_polygon(PackedVector2Array([Vector2(-4, -26), Vector2(4, -26), Vector2(0, -18)]), Color.WHITE)
		draw_rect(Rect2(-1, -24, 2, 8), Color("c8102e"))            # corbata
		draw_rect(Rect2(-15, -25, 4, 12), Color("1b3b6f"))          # brazos
		draw_rect(Rect2(11, -25, 4, 12), Color("1b3b6f"))


## Título enrollado con listón
class Diploma extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(-10, -3, 20, 7), Color("fff7e0"))
		draw_rect(Rect2(-10, -3, 20, 7), Color("8a6d3b"), false, 1.0)
		draw_rect(Rect2(-2, -4, 4, 9), Color("c8102e"))


## Birrete de graduado
class Birrete extends Node2D:
	func _draw() -> void:
		draw_colored_polygon(PackedVector2Array([Vector2(-12, 0), Vector2(0, -5), Vector2(12, 0), Vector2(0, 5)]), Color("15151a"))
		draw_rect(Rect2(-6, 0, 12, 5), Color("15151a"))
		draw_line(Vector2(0, 0), Vector2(9, 6), Color("f2c14e"), 1.0)
		draw_circle(Vector2(9, 7), 1.5, Color("f2c14e"))


## Fondos: campus (afuera del Tec), auditorio (graduación) y oficina (Servicios Escolares)
class Escenario extends Control:
	var modo := "campus"
	var confeti := false
	var t := 0.0
	var _papelitos: Array = []

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		t += delta
		if confeti:
			if _papelitos.size() < 90:
				for i in 3:
					_papelitos.append([Vector2(randf() * size.x, -8.0), randf_range(30, 70), Color.from_hsv(randf(), 0.7, 1.0), randf() * TAU])
			for p in _papelitos:
				p[0].y += p[1] * delta
				p[0].x += sin(t * 3.0 + p[3]) * 0.4
				if p[0].y > size.y:
					p[0].y = -8.0
		queue_redraw()

	func _draw() -> void:
		match modo:
			"campus": _campus()
			"auditorio": _auditorio()
			"oficina": _oficina()
		for p in _papelitos:
			draw_rect(Rect2(p[0], Vector2(3, 2)), p[2])

	func _campus() -> void:
		var s := size
		var piso := 268.0
		draw_rect(Rect2(Vector2.ZERO, s), Color("64abf8"))
		draw_rect(Rect2(0, 0, s.x, 60), Color("ffd59e"))       # amanecer
		draw_rect(Rect2(0, 60, s.x, 40), Color("9cc8f5"))
		draw_circle(Vector2(70, 70), 22, Color("fff3b0"))       # sol
		for i in 4:
			var x := fposmod(i * 150.0 + t * 6.0, s.x + 120.0) - 60.0
			draw_circle(Vector2(x, 110 + i % 2 * 25), 14, Color.WHITE)
			draw_circle(Vector2(x + 16, 104 + i % 2 * 25), 18, Color.WHITE)
			draw_circle(Vector2(x + 34, 110 + i % 2 * 25), 13, Color.WHITE)
		for i in range(-1, int(s.x / 110.0) + 2):
			draw_circle(Vector2(i * 110.0 + 20, piso + 6), 30, Color("2f7d3a"))
			draw_circle(Vector2(i * 110.0 + 55, piso + 10), 22, Color("3f9a47"))
		# Edificio del Tec con puerta en x = 380
		var r := Rect2(280, piso - 120, 200, 120)
		draw_rect(r, Color("e8d8b0"))
		draw_rect(r, Color("5a3a1a"), false, 2.0)
		draw_rect(Rect2(272, piso - 130, 216, 10), Color("1b3b6f"))
		for fy in 3:
			for fx in 7:
				if fy == 2 and fx == 3:
					continue
				var v := Rect2(290 + fx * 27, piso - 108 + fy * 32, 16, 18)
				draw_rect(v, Color("7ec8e3"))
				draw_rect(v, Color("5a3a1a"), false, 1.0)
		draw_rect(Rect2(366, piso - 34, 28, 34), Color("5a3a1a"))   # puerta
		draw_rect(Rect2(350, piso - 158, 60, 20), Color("1b3b6f"))
		draw_rect(Rect2(350, piso - 158, 60, 20), Color.WHITE, false, 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(350, piso - 143), "ITSX", HORIZONTAL_ALIGNMENT_CENTER, 60, 13, Color.WHITE)
		_piso_campus(piso)

	func _piso_campus(piso: float) -> void:
		var s := size
		draw_rect(Rect2(0, piso, s.x, s.y - piso), Color("4b7a6a"))
		draw_rect(Rect2(0, piso, s.x, 4), Color("4fbf55"))
		for col in int(s.x / 16.0) + 1:
			draw_rect(Rect2(col * 16.0, piso + 4, 16, 16), Color("3a6356"), false, 1.0)

	func _auditorio() -> void:
		var s := size
		var piso := 268.0
		draw_rect(Rect2(Vector2.ZERO, s), Color("2a1f3d"))
		# reflector
		draw_colored_polygon(PackedVector2Array([Vector2(280, 0), Vector2(320, 0), Vector2(380, piso), Vector2(220, piso)]), Color(1, 0.95, 0.7, 0.12))
		# telones
		for lado in [0.0, 1.0]:
			var x0: float = 0.0 if lado == 0.0 else s.x - 90.0
			draw_rect(Rect2(x0, 0, 90, piso), Color("9b1c31"))
			for k in 5:
				draw_line(Vector2(x0 + 10 + k * 18, 0), Vector2(x0 + 10 + k * 18, piso), Color("6e1222"), 3.0)
		draw_rect(Rect2(0, 0, s.x, 22), Color("6e1222"))
		# letrero
		var letrero := Rect2(130, 124, 252, 26)
		draw_rect(letrero, Color("1b3b6f"))
		draw_rect(letrero, Color("f2c14e"), false, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(130, 143), "GENERACIÓN 2026 · ITSX", HORIZONTAL_ALIGNMENT_CENTER, 252, 13, Color.WHITE)
		# escenario de madera
		draw_rect(Rect2(0, piso, s.x, s.y - piso), Color("7a4a24"))
		draw_rect(Rect2(0, piso, s.x, 5), Color("a8703c"))
		for col in int(s.x / 32.0) + 1:
			draw_line(Vector2(col * 32.0, piso + 5), Vector2(col * 32.0, s.y), Color("5e3818"), 1.0)
		# podio
		draw_rect(Rect2(392, piso - 40, 34, 40), Color("5e3818"))
		draw_rect(Rect2(388, piso - 44, 42, 6), Color("8a5a2b"))

	func _oficina() -> void:
		var s := size
		var piso := 268.0
		draw_rect(Rect2(Vector2.ZERO, s), Color("e6dcc3"))
		draw_rect(Rect2(0, piso - 40, s.x, 4), Color("b8a888"))
		# ventana
		var v := Rect2(40, 60, 110, 80)
		draw_rect(v, Color("23365c"))
		draw_circle(Vector2(120, 82), 9, Color("f4f1c9"))
		draw_rect(v, Color("6b4f2a"), false, 3.0)
		draw_line(Vector2(95, 60), Vector2(95, 140), Color("6b4f2a"), 2.0)
		# letrero
		var letrero := Rect2(250, 140, 200, 24)
		draw_rect(letrero, Color("1b3b6f"))
		draw_string(ThemeDB.fallback_font, Vector2(250, 157), "SERVICIOS ESCOLARES", HORIZONTAL_ALIGNMENT_CENTER, 200, 12, Color.WHITE)
		# reloj
		draw_circle(Vector2(200, 100), 12, Color.WHITE)
		draw_arc(Vector2(200, 100), 12, 0, TAU, 24, Color("333333"), 1.5)
		draw_line(Vector2(200, 100), Vector2(200, 92), Color("333333"), 1.5)
		draw_line(Vector2(200, 100), Vector2(206, 100), Color("333333"), 1.5)
		# escritorio con papeles
		draw_rect(Rect2(290, piso - 34, 60, 34), Color("8a5a2b"))
		draw_rect(Rect2(286, piso - 38, 68, 6), Color("a8703c"))
		draw_rect(Rect2(296, piso - 46, 14, 8), Color.WHITE)
		draw_rect(Rect2(312, piso - 48, 14, 10), Color("f5f0dc"))
		draw_rect(Rect2(330, piso - 44, 12, 6), Color("cfe3ff"))
		# piso de mosaico
		draw_rect(Rect2(0, piso, s.x, s.y - piso), Color("a9a9b3"))
		for col in int(s.x / 24.0) + 1:
			for fila in 5:
				if (col + fila) % 2 == 0:
					draw_rect(Rect2(col * 24.0, piso + fila * 24.0, 24, 24), Color("93939e"))
