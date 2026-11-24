extends CanvasLayer
## Menú de ajustes dentro de los niveles (tuerca o Esc).
## Pausa el juego y el cronómetro; deja cambiar el volumen y salir al campus o al menú.

signal salir_al_campus
signal salir_al_menu

const ESTADO := preload("res://scripts/juego/estado_juego.gd")
const SONIDO := preload("res://scripts/juego/sonido.gd")
const CONFIG_PATH := "user://config.cfg"   # el mismo archivo que usa el menú principal
const C_DORADO := Color("#f1c65a")
const C_AZUL := Color("#15334a")

var _musica: HSlider
var _efectos: HSlider
var _primero: Button


func _ready() -> void:
	layer = 150
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	ESTADO.pausar_cronometro()
	SONIDO.efecto("menu")

	var fondo := ColorRect.new()
	fondo.color = Color(0.02, 0.04, 0.08, 0.7)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(250, 0)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = C_AZUL
	estilo.border_color = C_DORADO
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(12)
	estilo.content_margin_left = 18
	estilo.content_margin_right = 18
	estilo.content_margin_top = 12
	estilo.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	v.add_child(_texto("AJUSTES", 20, C_DORADO))
	_primero = _boton("CONTINUAR", cerrar)
	v.add_child(_primero)
	v.add_child(_texto("Música", 13, Color.WHITE))
	_musica = _slider()
	v.add_child(_musica)
	v.add_child(_texto("Efectos", 13, Color.WHITE))
	_efectos = _slider()
	v.add_child(_efectos)
	v.add_child(_boton("MAPA DEL TEC", _ir_campus))
	v.add_child(_boton("MENÚ PRINCIPAL", _ir_menu))

	var c := ConfigFile.new()
	c.load(CONFIG_PATH)
	_musica.set_value_no_signal(c.get_value("audio", "musica", 0.8))
	_efectos.set_value_no_signal(c.get_value("audio", "efectos", 0.9))
	_musica.value_changed.connect(func(_x): _aplicar_volumen())
	_efectos.value_changed.connect(func(_x): _aplicar_volumen())
	_primero.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrar()


func cerrar() -> void:
	_reanudar()
	queue_free()


func _ir_campus() -> void:
	_reanudar()
	salir_al_campus.emit()
	queue_free()


func _ir_menu() -> void:
	_reanudar()
	salir_al_menu.emit()
	queue_free()


func _reanudar() -> void:
	get_tree().paused = false
	ESTADO.reanudar_cronometro()


func _aplicar_volumen() -> void:
	SONIDO.volumen_musica(_musica.value)
	SONIDO.volumen_efectos(_efectos.value)
	var c := ConfigFile.new()
	c.load(CONFIG_PATH)
	c.set_value("audio", "musica", _musica.value)
	c.set_value("audio", "efectos", _efectos.value)
	c.save(CONFIG_PATH)


func _texto(contenido: String, tam: int, color: Color) -> Label:
	var l := Label.new()
	l.text = contenido
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	return l


func _boton(texto: String, accion: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(0, 30)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_focus_color", C_DORADO)
	b.add_theme_color_override("font_hover_color", C_DORADO)
	b.pressed.connect(accion)
	b.focus_entered.connect(func(): SONIDO.efecto("menu"))
	return b


func _slider() -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.custom_minimum_size = Vector2(200, 16)
	return s
