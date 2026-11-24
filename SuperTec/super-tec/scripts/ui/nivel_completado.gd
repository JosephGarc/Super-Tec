extends CanvasLayer

const SONIDO := preload("res://scripts/juego/sonido.gd")
const TRANSICION := preload("res://scripts/ui/transicion_fade.gd")
const ESTADO := preload("res://scripts/juego/estado_juego.gd")
const OVERWORLD_PATH := "res://escenas/overworld_super_tec.tscn"

var numero_nivel := 0
var ruta_siguiente := ""
var _cambiando_escena := false

func configurar(nivel: int, siguiente: String) -> void:
	numero_nivel = nivel
	ruta_siguiente = siguiente

func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_key_input(true)
	get_tree().paused = true
	var fondo := ColorRect.new()
	fondo.color = Color(0.015, 0.035, 0.055, 0.82)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 210)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#153348")
	estilo.border_color = Color("#f0c45c")
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(14)
	estilo.content_margin_left = 20.0
	estilo.content_margin_right = 20.0
	estilo.content_margin_top = 18.0
	estilo.content_margin_bottom = 18.0
	panel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(panel)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 12)
	panel.add_child(columna)
	var titulo := Label.new()
	titulo.text = "¡NIVEL %d COMPLETADO!" % numero_nivel
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 22)
	titulo.add_theme_color_override("font_color", Color("#fff1c2"))
	columna.add_child(titulo)
	var detalle := Label.new()
	detalle.text = "Tiempo de este nivel: %s" % ESTADO.formatear_tiempo(ESTADO.tiempo_final_segundos())
	detalle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detalle.add_theme_font_size_override("font_size", 12)
	detalle.add_theme_color_override("font_color", Color("#d5e8e6"))
	columna.add_child(detalle)
	var campus := _crear_boton("Volver al Mapa del Tec")
	campus.pressed.connect(_volver_al_campus)
	columna.add_child(campus)
	var siguiente := _crear_boton("Siguiente nivel")
	siguiente.visible = not ruta_siguiente.is_empty() and ResourceLoader.exists(ruta_siguiente, "PackedScene")
	siguiente.pressed.connect(_ir_al_siguiente)
	columna.add_child(siguiente)
	campus.call_deferred("grab_focus")

func _crear_boton(texto: String) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(270, 38)
	boton.add_theme_font_size_override("font_size", 14)
	boton.add_theme_color_override("font_color", Color.WHITE)
	boton.add_theme_stylebox_override("normal", _estilo_boton(Color("#17627b"), Color("#a7d1d0")))
	boton.add_theme_stylebox_override("hover", _estilo_boton(Color("#278c91"), Color("#fff0b4")))
	boton.add_theme_stylebox_override("focus", _estilo_boton(Color("#f1c45a"), Color("#fff0b4")))
	boton.add_theme_stylebox_override("pressed", _estilo_boton(Color("#d89c3a"), Color("#fff0b4")))
	return boton

func _estilo_boton(fondo: Color, borde: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(8)
	return estilo

func _volver_al_campus() -> void:
	_cambiar_a(OVERWORLD_PATH)

func _ir_al_siguiente() -> void:
	if not ruta_siguiente.is_empty() and ResourceLoader.exists(ruta_siguiente, "PackedScene"):
		_cambiar_a(ruta_siguiente)
	else:
		_cambiar_a(OVERWORLD_PATH)

func _cambiar_a(ruta: String) -> void:
	if _cambiando_escena:
		return
	_cambiando_escena = true
	SONIDO.efecto("menu_aceptar")
	var salida := TRANSICION.new()
	add_child(salida)
	await salida.fade_out()
	get_tree().paused = false
	var error := get_tree().change_scene_to_file(ruta)
	if error != OK:
		_cambiando_escena = false
		get_tree().paused = true
		await salida.fade_in()
		push_error("No se pudo abrir la escena de destino: %s" % ruta)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _cambiando_escena:
		_cambiar_a(OVERWORLD_PATH)
