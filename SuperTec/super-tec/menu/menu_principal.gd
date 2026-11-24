extends Control
## ==========================================================
##  SUPER TEC - Menú de inicio
##  Instituto Tecnológico Superior de Xalapa
##  Godot 4.x
##
##  Todo el menú se construye por código, así que solo necesitas
##  un nodo Control con este script (o abrir menu_principal.tscn).
##  Funciona con mouse, teclado (W/S o flechas + Enter / Esc) y control.
##
##  Adaptado al proyecto: pantalla de 512x384, sonido del juego
##  (scripts/juego/sonido.gd), partida nueva al jugar y botón
##  para el selector de niveles.
## ==========================================================

## Escena que se abre en "NUEVA PARTIDA": nombre y personaje; luego la cinemática
## de entrada al Tec y el mapa del campus.
@export_file("*.tscn") var escena_juego: String = "res://escenas/inicio_super_tec.tscn"
## Escena que se abre en "CONTINUAR": el mapa del campus (niveles superados y el siguiente).
@export_file("*.tscn") var escena_niveles: String = "res://escenas/overworld_super_tec.tscn"

## (Opcional) Fuente pixel, por ejemplo "Press Start 2P" (licencia libre OFL).
@export var fuente: Font

## Los créditos del equipo están en scripts/juego/creditos_equipo.gd

const SALIDA := preload("res://scripts/juego/salida.gd")
const SONIDO := preload("res://scripts/juego/sonido.gd")
const ESTADO := preload("res://scripts/juego/estado_juego.gd")
const PROGRESO := preload("res://scripts/juego/progreso.gd")
const CREDITOS_EQUIPO := preload("res://scripts/juego/creditos_equipo.gd")
const CONFIG_PATH := "user://config.cfg"

# Paleta de Super Tec (azul del Tec, dorado de los bloques ?, campus)
const C_AZUL_TEC := Color("1b3b6f")
const C_DORADO := Color("f2c14e")
const C_ROJO_BLOQUE := Color("b8324f")

var _menu: Control
var _panel_opciones: Control
var _chk_pantalla: CheckButton
var _panel_creditos: Control
var _panel_confirmar: Control
var _titulo: Label
var _fade: ColorRect
var _slider_musica: HSlider
var _slider_efectos: HSlider
var _bloqueado := false
var _listo := false
var _t := 0.0


func _ready() -> void:
	PROGRESO.cargar()
	PROGRESO.empezar_nivel(0)   # ya no se está jugando ningún nivel
	set_anchors_preset(PRESET_FULL_RECT)
	add_child(Fondo.new())
	_crear_titulo()
	_menu = _crear_menu()
	_panel_opciones = _crear_panel_opciones()
	_panel_creditos = _crear_panel_creditos()
	_panel_confirmar = _crear_panel_confirmar()
	_crear_pie()
	_crear_fade()
	_cargar_config()
	_mostrar(_menu)
	SONIDO.musica("menu")
	_listo = true

	# Aparece desde negro
	create_tween().tween_property(_fade, "color:a", 0.0, 0.8)


func _process(delta: float) -> void:
	_t += delta
	# El título "flota" suavemente
	_titulo.position.y = 14.0 + sin(_t * 2.0) * 3.0


func _unhandled_input(evento: InputEvent) -> void:
	# W / S también mueven la selección (además de las flechas)
	if evento is InputEventKey and evento.pressed and not evento.echo:
		var foco := get_viewport().gui_get_focus_owner()
		if foco and evento.physical_keycode == KEY_W:
			var anterior := foco.find_prev_valid_focus()
			if anterior: anterior.grab_focus()
			get_viewport().set_input_as_handled()
			return
		if foco and evento.physical_keycode == KEY_S:
			var siguiente := foco.find_next_valid_focus()
			if siguiente: siguiente.grab_focus()
			get_viewport().set_input_as_handled()
			return
	# Esc / botón B regresa al menú principal desde Opciones o Créditos
	if evento.is_action_pressed("ui_cancel") and not _menu.visible:
		_sonar("menu_aceptar")
		_mostrar(_menu)
		get_viewport().set_input_as_handled()


# ----------------------------------------------------------
#  Construcción de la interfaz
# ----------------------------------------------------------

func _crear_titulo() -> void:
	_titulo = _texto("SUPER TEC", 52, C_DORADO, 8)
	_titulo.set_anchors_preset(PRESET_TOP_WIDE)
	_titulo.offset_top = 14
	_titulo.offset_bottom = 80
	add_child(_titulo)

	var sub := _texto("Instituto Tecnológico Superior de Xalapa", 14, Color.WHITE, 5)
	sub.set_anchors_preset(PRESET_TOP_WIDE)
	sub.offset_top = 78
	sub.offset_bottom = 98
	add_child(sub)


func _crear_menu() -> Control:
	var centro := _contenedor_central()
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 6)
	centro.add_child(caja)

	var b_jugar := _boton("NUEVA PARTIDA", _nueva_partida)
	caja.add_child(b_jugar)
	var b_continuar := _boton("CONTINUAR", _abrir_niveles)
	caja.add_child(b_continuar)
	if PROGRESO.hay_partida:
		b_jugar = b_continuar   # si hay partida guardada, la selección empieza en Continuar
	else:
		b_continuar.disabled = true
		b_continuar.focus_mode = FOCUS_NONE
		b_continuar.modulate = Color(1, 1, 1, 0.45)
	caja.add_child(_boton("OPCIONES", func(): _mostrar(_panel_opciones)))
	caja.add_child(_boton("CRÉDITOS", func(): _mostrar(_panel_creditos)))
	if not OS.has_feature("web"):
		caja.add_child(_boton("SALIR", func(): SALIDA.salir()))

	if PROGRESO.hay_partida:
		caja.add_child(_texto("Créditos: %d / %d" % [PROGRESO.total(), PROGRESO.CREDITOS_TOTALES], 11, C_DORADO, 4))

	centro.set_meta("foco", b_jugar)
	return centro


func _crear_panel_confirmar() -> Control:
	var centro := _panel_base("¿NUEVA PARTIDA?")
	var v: VBoxContainer = centro.get_meta("contenido")
	v.add_child(_texto("Se borrará tu partida guardada\n(niveles superados y créditos).", 11, Color.WHITE, 4))
	var si := _boton("SÍ, EMPEZAR DE NUEVO", _jugar)
	v.add_child(si)
	var no := _boton("NO", func(): _mostrar(_menu))
	v.add_child(no)
	centro.set_meta("foco", no)
	return centro


func _crear_panel_opciones() -> Control:
	var centro := _panel_base("OPCIONES")
	var v: VBoxContainer = centro.get_meta("contenido")

	v.add_child(_texto("Música", 13, Color.WHITE, 4))
	_slider_musica = _slider(_on_volumen_cambiado)
	v.add_child(_slider_musica)
	v.add_child(_texto("Efectos", 13, Color.WHITE, 4))
	_slider_efectos = _slider(_on_volumen_cambiado)
	v.add_child(_slider_efectos)

	_chk_pantalla = CheckButton.new()
	_chk_pantalla.text = "Pantalla completa"
	_chk_pantalla.add_theme_font_size_override("font_size", 13)
	_chk_pantalla.add_theme_color_override("font_color", Color.WHITE)
	_chk_pantalla.add_theme_color_override("font_focus_color", C_DORADO)
	_chk_pantalla.add_theme_color_override("font_hover_color", C_DORADO)
	if fuente:
		_chk_pantalla.add_theme_font_override("font", fuente)
	_chk_pantalla.toggled.connect(_on_pantalla_completa)
	_chk_pantalla.focus_entered.connect(func(): _sonar("menu"))
	v.add_child(_chk_pantalla)

	v.add_child(_boton("REGRESAR", func(): _mostrar(_menu)))
	centro.set_meta("foco", _slider_musica)
	return centro


func _slider(al_cambiar: Callable) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.custom_minimum_size = Vector2(170, 16)
	s.value_changed.connect(func(_v): al_cambiar.call())
	s.focus_entered.connect(func(): _sonar("menu"))
	return s


func _crear_panel_creditos() -> Control:
	var centro := _panel_base("CRÉDITOS")
	var v: VBoxContainer = centro.get_meta("contenido")
	v.add_theme_constant_override("separation", 3)
	for l in CREDITOS_EQUIPO.LINEAS + ["", "Instituto Tecnológico Superior de Xalapa", "Hecho con Godot Engine"]:
		v.add_child(_texto(l, 10, Color.WHITE, 4))

	var b := _boton("REGRESAR", func(): _mostrar(_menu))
	v.add_child(b)
	centro.set_meta("foco", b)
	return centro


func _crear_pie() -> void:
	var pie := _texto("© 2026 ITSX  •  W/S o flechas para moverte, Enter para elegir", 9, Color.WHITE, 4)
	pie.set_anchors_preset(PRESET_BOTTOM_WIDE)
	pie.offset_top = -18
	pie.offset_bottom = -4
	add_child(pie)


func _crear_fade() -> void:
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_fade.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_fade)


# ----------------------------------------------------------
#  Ayudantes de UI
# ----------------------------------------------------------

func _contenedor_central() -> CenterContainer:
	var c := CenterContainer.new()
	c.set_anchors_preset(PRESET_FULL_RECT)
	c.offset_top = 100   # deja espacio para el título
	c.offset_bottom = -40  # no tapar el suelo
	add_child(c)
	return c


func _panel_base(titulo: String) -> CenterContainer:
	var centro := _contenedor_central()
	var panel := PanelContainer.new()
	var estilo := _caja(Color(0.05, 0.1, 0.25, 0.92), Color.WHITE)
	estilo.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	v.add_child(_texto(titulo, 20, C_DORADO, 5))

	centro.set_meta("contenido", v)
	return centro


func _texto(contenido: String, tam: int, color: Color, borde: int) -> Label:
	var l := Label.new()
	l.text = contenido
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", borde)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	if fuente:
		l.add_theme_font_override("font", fuente)
	return l


func _boton(texto: String, accion: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.set_meta("texto", texto)
	b.custom_minimum_size = Vector2(170, 28)
	b.focus_mode = FOCUS_ALL

	var normal := _caja(C_AZUL_TEC, Color.BLACK)
	var activo := _caja(C_DORADO, Color.WHITE)
	var presionado := _caja(Color("d9a032"), Color.WHITE)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", activo)
	b.add_theme_stylebox_override("focus", activo)
	b.add_theme_stylebox_override("pressed", presionado)
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.BLACK)
	b.add_theme_color_override("font_focus_color", Color.BLACK)
	b.add_theme_color_override("font_pressed_color", Color.BLACK)
	b.add_theme_color_override("font_outline_color", Color.BLACK)
	b.add_theme_constant_override("outline_size", 3)
	if fuente:
		b.add_theme_font_override("font", fuente)

	b.pressed.connect(func():
		if _bloqueado:
			return
		_sonar("menu_aceptar")
		accion.call()
	)
	b.mouse_entered.connect(b.grab_focus)
	b.focus_entered.connect(func():
		_sonar("menu")
		b.text = "► " + b.get_meta("texto") + " ◄"
		b.pivot_offset = b.size / 2.0
		_escalar(b, Vector2(1.06, 1.06))
	)
	b.focus_exited.connect(func():
		b.text = b.get_meta("texto")
		_escalar(b, Vector2.ONE)
	)
	return b


func _caja(fondo: Color, borde: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fondo
	s.border_color = borde
	s.set_border_width_all(2)
	s.set_corner_radius_all(3)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 1
	s.shadow_offset = Vector2(3, 3)
	s.content_margin_left = 8
	s.content_margin_right = 8
	return s


func _escalar(b: Control, objetivo: Vector2) -> void:
	if b.has_meta("tween"):
		(b.get_meta("tween") as Tween).kill()
	var tw := b.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "scale", objetivo, 0.15)
	b.set_meta("tween", tw)


func _mostrar(pantalla: Control) -> void:
	for p in [_menu, _panel_opciones, _panel_creditos, _panel_confirmar]:
		p.visible = (p == pantalla)
	if pantalla.has_meta("foco"):
		(pantalla.get_meta("foco") as Control).grab_focus.call_deferred()


# Usa los efectos del juego (assets/sonido/efectos)
func _sonar(efecto: String) -> void:
	if _listo:
		SONIDO.efecto(efecto)


# ----------------------------------------------------------
#  Acciones
# ----------------------------------------------------------

func _nueva_partida() -> void:
	# Si ya hay partida guardada, primero pregunta
	if PROGRESO.hay_partida:
		_mostrar(_panel_confirmar)
	else:
		_jugar()


func _jugar() -> void:
	PROGRESO.nueva_partida()   # borra lo guardado
	ESTADO.reiniciar()         # 3 vidas
	_ir_a(escena_juego)


func _abrir_niveles() -> void:
	_ir_a(escena_niveles)


func _ir_a(escena: String) -> void:
	if _bloqueado:
		return
	_bloqueado = true
	_fade.mouse_filter = MOUSE_FILTER_STOP

	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.5)
	await tw.finished

	if ResourceLoader.exists(escena):
		get_tree().change_scene_to_file(escena)
	else:
		push_warning("SUPER TEC: no existe la escena '%s'. Cámbiala en el Inspector." % escena)
		_fade.mouse_filter = MOUSE_FILTER_IGNORE
		create_tween().tween_property(_fade, "color:a", 0.0, 0.4)
		_bloqueado = false


func _on_volumen_cambiado() -> void:
	SONIDO.volumen_musica(_slider_musica.value)
	SONIDO.volumen_efectos(_slider_efectos.value)
	_guardar_config()


func _on_pantalla_completa(activo: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if activo else DisplayServer.WINDOW_MODE_WINDOWED
	)
	_guardar_config()


func _guardar_config() -> void:
	if not _listo:
		return
	var c := ConfigFile.new()
	c.set_value("audio", "musica", _slider_musica.value)
	c.set_value("audio", "efectos", _slider_efectos.value)
	c.set_value("video", "pantalla_completa", _chk_pantalla.button_pressed)
	c.save(CONFIG_PATH)


func _cargar_config() -> void:
	var c := ConfigFile.new()
	c.load(CONFIG_PATH)  # si no existe, se usan los valores por defecto
	_slider_musica.set_value_no_signal(c.get_value("audio", "musica", 0.8))
	_slider_efectos.set_value_no_signal(c.get_value("audio", "efectos", 0.9))
	SONIDO.volumen_musica(_slider_musica.value)
	SONIDO.volumen_efectos(_slider_efectos.value)
	_chk_pantalla.set_pressed_no_signal(c.get_value("video", "pantalla_completa", false))
	if _chk_pantalla.button_pressed:
		_on_pantalla_completa(true)


# ==========================================================
#  Fondo animado: cielo, nubes, arbustos, pinos, edificio del Tec,
#  bloques flotantes (? y ladrillo de Super Tec) y piso del campus.
#  Cuando tengan una ilustración, se puede reemplazar por un
#  TextureRect o un ParallaxBackground.
# ==========================================================
class Fondo extends Control:
	var t := 0.0
	var nubes: Array[Vector3] = []  # x, y, escala

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in 6:
			nubes.append(Vector3(randf() * 800.0, randf_range(12.0, 120.0), randf_range(0.35, 0.7)))

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var s := size
		var piso := s.y - 32.0

		# Cielo (mismo azul que los niveles)
		draw_rect(Rect2(Vector2.ZERO, s), Color("64abf8"))
		draw_rect(Rect2(0, s.y * 0.6, s.x, s.y * 0.4), Color("78b8f8"))

		# Nubes que se desplazan
		for n in nubes:
			var x := fposmod(n.x + t * 9.0 * n.z, s.x + 150.0) - 75.0
			_nube(Vector2(x, n.y), n.z)

		# Arbustos del campus
		for i in range(-1, int(s.x / 120.0) + 2):
			var cx := i * 120.0 + 30.0
			draw_circle(Vector2(cx, piso + 8), 34, Color("2f7d3a"))
			draw_circle(Vector2(cx + 34, piso + 12), 24, Color("3f9a47"))
			draw_circle(Vector2(cx + 62, piso + 10), 18, Color("2f7d3a"))

		# Pinos
		_pino(Vector2(s.x * 0.28, piso))
		_pino(Vector2(s.x * 0.55, piso))

		# Edificio del Tecnológico
		_edificio(Vector2(s.x * 0.835, piso))

		# Bloques flotando: ?, ladrillo, ?
		for i in 3:
			var p := Vector2(s.x * 0.06 + i * 22.0, piso - 86.0 + sin(t * 3.0 + i) * 2.0)
			_bloque(p, i == 1)

		# Piso del campus: pasto arriba y piedra abajo
		var tam := 16.0
		draw_rect(Rect2(0, piso, s.x, s.y - piso), Color("4b7a6a"))
		draw_rect(Rect2(0, piso, s.x, 4), Color("4fbf55"))
		for col in int(s.x / tam) + 1:
			draw_rect(Rect2(col * tam + 3, piso + 4, 3, 2), Color("3a9a40"))
			for fila in 2:
				var q := Rect2(col * tam, piso + 4 + fila * tam, tam, tam)
				draw_rect(q, Color("3a6356"), false, 1.0)

	func _nube(p: Vector2, k: float) -> void:
		var c := Color.WHITE
		draw_rect(Rect2(p + Vector2(0, -6) * k, Vector2(60, 26) * k), c)
		draw_circle(p + Vector2(0, 8) * k, 18 * k, c)
		draw_circle(p + Vector2(22, -8) * k, 24 * k, c)
		draw_circle(p + Vector2(46, -2) * k, 20 * k, c)
		draw_circle(p + Vector2(62, 8) * k, 16 * k, c)

	func _pino(base: Vector2) -> void:
		draw_rect(Rect2(base.x - 3, base.y - 14, 6, 14), Color("6b4226"))
		for i in 4:
			var ancho := 30.0 - i * 6.0
			var y := base.y - 12.0 - i * 13.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(base.x - ancho / 2.0, y), Vector2(base.x + ancho / 2.0, y), Vector2(base.x, y - 20.0)
			]), Color("2e6b35"))

	func _edificio(base: Vector2) -> void:
		_edificio_a(base.x, base.y, 164.0, 92.0, 0.8)

	# Edificio A del ITSX (como el real, con la pintura nueva): rojo vino con
	# columnas y letrero en vino oscuro, letras amarillas,
	# toldos durazno y base amarilla. La puerta queda en x = cx.
	func _edificio_a(cx: float, piso: float, ancho: float, alto: float, escala: float = 1.0) -> void:
		var rojo := Color("5e1420")    # columnas y letrero: vino oscuro
		var muro := Color("8a2433")    # paredes: rojo vino
		var blanco := Color("f4f2ec")  # marquitos de las ventanas
		var vidrio := Color("35566a")
		var vidrio_claro := Color("7fb0c6")
		var toldo := Color("f3c48e")
		var amarillo := Color("f2c14e")
		var x0 := cx - ancho / 2.0
		var alto_letrero := 16.0 * escala
		var arriba := piso - alto + alto_letrero
		# cuerpo rojo vino
		draw_rect(Rect2(x0, arriba, ancho, alto - alto_letrero), muro)
		# letrero rojo con letras amarillas
		var letrero := Rect2(x0, piso - alto, ancho, alto_letrero)
		draw_rect(letrero, rojo)
		var fuente := ThemeDB.fallback_font
		var texto := "INSTITUTO TECNOLÓGICO SUPERIOR DE XALAPA"
		var tam := maxi(8, int(10 * escala))
		while tam > 6 and fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x > ancho - 6:
			tam -= 1   # que el letrero quepa completo
		draw_string(fuente, Vector2(x0, letrero.position.y + alto_letrero * 0.78), texto,
			HORIZONTAL_ALIGNMENT_CENTER, ancho, tam, amarillo)
		var medio := arriba + (piso - arriba) * 0.42
		var base_alto := 7.0 * escala
		# bahías de ventanas separadas por columnas rojas
		var bahia := 40.0 * escala
		var x := x0
		var entrada_izq := cx - 30 * escala
		var entrada_der := cx + 30 * escala
		while x < x0 + ancho - 1:
			var fin := minf(x + bahia, x0 + ancho)
			var izq := x
			var der := fin
			if der > entrada_izq and izq < entrada_der:   # aquí va la entrada
				x = fin
				continue
			# ventanas de arriba (vidrio con marquitos blancos)
			var v := Rect2(izq + 5 * escala, arriba + 5 * escala, der - izq - 10 * escala, medio - arriba - 9 * escala)
			draw_rect(v, vidrio)
			var k := v.position.x + 9 * escala
			while k < v.end.x - 2:
				draw_line(Vector2(k, v.position.y), Vector2(k, v.end.y), blanco, 1.0)
				k += 9 * escala
			# toldo durazno inclinado
			draw_colored_polygon(PackedVector2Array([
				Vector2(izq + 2 * escala, medio - 3 * escala), Vector2(der - 2 * escala, medio - 3 * escala),
				Vector2(der + 1 * escala, medio + 9 * escala), Vector2(izq - 1 * escala, medio + 9 * escala)]), toldo)
			# ventanas de abajo (asomando bajo el toldo)
			draw_rect(Rect2(izq + 5 * escala, medio + 11 * escala, der - izq - 10 * escala, piso - base_alto - medio - 14 * escala), vidrio)
			x = fin
		# columnas rojas entre bahías
		x = x0
		while x <= x0 + ancho + 1:
			if x < entrada_izq - 1 or x > entrada_der + 1:
				draw_rect(Rect2(x - 2.5 * escala, arriba, 5 * escala, piso - arriba), rojo)
			x += bahia
		# base amarilla
		draw_rect(Rect2(x0, piso - base_alto, ancho, base_alto), amarillo)
		# entrada central: vidrio alto con marco y columnas rojas
		var ent := Rect2(entrada_izq, arriba, entrada_der - entrada_izq, piso - arriba)
		draw_rect(ent, vidrio_claro)
		for c in 5:
			var lx := ent.position.x + c * ent.size.x / 4.0
			draw_line(Vector2(lx, ent.position.y), Vector2(lx, piso), blanco, 1.0)
		for f in 4:
			var ly := ent.position.y + f * ent.size.y / 4.0
			draw_line(Vector2(ent.position.x, ly), Vector2(ent.end.x, ly), blanco, 1.0)
		draw_rect(Rect2(ent.position.x - 4 * escala, arriba, 6 * escala, piso - arriba), rojo)
		draw_rect(Rect2(ent.end.x - 2 * escala, arriba, 6 * escala, piso - arriba), rojo)
		draw_rect(Rect2(cx - 13 * escala, piso - 28 * escala, 26 * escala, 28 * escala), Color("2e4652"))   # puerta
		draw_line(Vector2(cx, piso - 28 * escala), Vector2(cx, piso), blanco, 1.0)
		# palmeras y arbolitos al frente
		for px in [cx - 22 * escala, cx + 26 * escala]:
			_palmera(Vector2(px, piso), escala)
		var ax := x0 + 18 * escala
		while ax < x0 + ancho:
			if absf(ax - cx) > 50 * escala:
				draw_line(Vector2(ax, piso), Vector2(ax, piso - 12 * escala), Color("7a5a3a"), 2.0)
				draw_circle(Vector2(ax, piso - 16 * escala), 8 * escala, Color("3f9a47"))
				draw_circle(Vector2(ax - 3 * escala, piso - 18 * escala), 5 * escala, Color("56b65d"))
			ax += 46 * escala

	func _palmera(base: Vector2, escala: float) -> void:
		var alto := 52.0 * escala
		draw_line(base, base + Vector2(3 * escala, -alto), Color("7a5a3a"), 4.0 * escala)
		var copa := base + Vector2(3 * escala, -alto)
		for k in 6:
			var ang := -PI + k * PI / 5.0 + sin(t * 1.5 + k) * 0.05
			var punta := copa + Vector2(cos(ang), sin(ang) * 0.5 + 0.35) * 22.0 * escala
			draw_colored_polygon(PackedVector2Array([copa, punta + Vector2(0, -4 * escala), punta + Vector2(0, 3 * escala)]), Color("2f8f3e") if k % 2 else Color("3fae4c"))

	# Bloque ? (dorado con libro) o ladrillo rojo, como en los niveles
	func _bloque(p: Vector2, ladrillo: bool) -> void:
		var r := Rect2(p, Vector2(18, 18))
		if ladrillo:
			draw_rect(r, Color("b8324f"))
			draw_rect(Rect2(p + Vector2(4, 4), Vector2(10, 10)), Color("8e2039"), false, 1.5)
		else:
			draw_rect(r, Color("f2c14e"))
			draw_rect(Rect2(p + Vector2(2, 2), Vector2(14, 14)), Color("8e2039"))
			draw_rect(Rect2(p + Vector2(5, 6), Vector2(8, 6)), Color.WHITE)
			draw_line(p + Vector2(9, 6), p + Vector2(9, 12), Color("8e2039"), 1.0)
		draw_rect(r, Color("3a1020"), false, 1.0)
