extends Control

const SONIDO := preload("res://scripts/juego/sonido.gd")

const OPTIONS := [
	{"label": "Nivel 1", "scene": "res://escenas/pruebas/niveles/nivel_1.tscn"},
	{"label": "Nivel 2", "scene": "res://escenas/pruebas/niveles/nivel_2.tscn"},
	{"label": "Nivel 3", "scene": "res://escenas/pruebas/niveles/nivel_3.tscn"},
	{"label": "Nivel 4", "scene": "res://escenas/pruebas/niveles/nivel_4.tscn"},
	{"label": "Nivel 5", "scene": "res://escenas/pruebas/niveles/nivel_5.tscn"},
	{"label": "Nivel 6", "scene": "res://escenas/pruebas/niveles/nivel_6.tscn"},
	{"label": "Nivel 7", "scene": "res://escenas/pruebas/niveles/nivel_7.tscn"},
	{"label": "Nivel 8", "scene": "res://escenas/pruebas/niveles/nivel_8.tscn"},
	{"label": "Nivel 9", "scene": "res://escenas/pruebas/niveles/nivel_9.tscn"},
]

const SKY_SHADER := preload("res://shaders/sky_gradient.gdshader")
const TRANSICION := preload("res://scripts/ui/transicion_fade.gd")
const ESTADO := preload("res://scripts/juego/estado_juego.gd")

var _cambiando_escena := false
var _boton_hombre: Button
var _boton_mujer: Button

class MenuDecoration extends Control:
	func _draw() -> void:
		var bounds := size
		var accent := Color(0.96, 0.77, 0.43, 0.22)
		var soft := Color(0.74, 0.9, 0.94, 0.12)
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, bounds.y * 0.78), Vector2(bounds.x * 0.22, bounds.y * 0.53),
			Vector2(bounds.x * 0.42, bounds.y * 0.78), Vector2(bounds.x * 0.68, bounds.y * 0.48),
			Vector2(bounds.x, bounds.y * 0.76), Vector2(bounds.x, bounds.y), Vector2(0, bounds.y)
		]), Color(0.15, 0.35, 0.43, 0.2))
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, bounds.y * 0.9), Vector2(bounds.x * 0.27, bounds.y * 0.69),
			Vector2(bounds.x * 0.49, bounds.y * 0.88), Vector2(bounds.x * 0.76, bounds.y * 0.65),
			Vector2(bounds.x, bounds.y * 0.86), Vector2(bounds.x, bounds.y), Vector2(0, bounds.y)
		]), Color(0.12, 0.28, 0.34, 0.25))
		draw_circle(Vector2(bounds.x * 0.83, bounds.y * 0.2), 24.0, accent)
		draw_arc(Vector2(bounds.x * 0.83, bounds.y * 0.2), 38.0, 0.1, 5.8, 48, soft, 1.5)
		draw_circle(Vector2(bounds.x * 0.14, bounds.y * 0.19), 2.0, soft)
		draw_circle(Vector2(bounds.x * 0.28, bounds.y * 0.31), 1.5, accent)
		draw_circle(Vector2(bounds.x * 0.68, bounds.y * 0.12), 1.5, soft)

func _ready() -> void:
	# Elegir nivel desde el selector = partida nueva (créditos 0 y 3 vidas)
	ESTADO.reiniciar()
	SONIDO.musica("menu")
	_build_menu()
	var entrada := TRANSICION.new()
	add_child(entrada)
	entrada.fade_in()

func _build_menu() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	var sky := ShaderMaterial.new()
	sky.shader = SKY_SHADER
	background.material = sky
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var decoration := MenuDecoration.new()
	decoration.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	decoration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(decoration)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 14.0
	center.offset_top = 10.0
	center.offset_right = -14.0
	center.offset_bottom = -10.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(474, 356)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 22)
	margins.add_theme_constant_override("margin_right", 22)
	margins.add_theme_constant_override("margin_top", 12)
	margins.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margins)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margins.add_child(column)

	var title := Label.new()
	title.text = "SÚPER TEC"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 31)
	title.add_theme_color_override("font_color", Color("#fff6df"))
	title.add_theme_color_override("font_outline_color", Color("#244253"))
	title.add_theme_constant_override("outline_size", 3)
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Elige un nivel"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("#d5edf0"))
	column.add_child(subtitle)
	var fila_personaje := HBoxContainer.new()
	fila_personaje.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_personaje.add_theme_constant_override("separation", 8)
	column.add_child(fila_personaje)
	var etiqueta_personaje := Label.new()
	etiqueta_personaje.text = "Personaje"
	etiqueta_personaje.add_theme_font_size_override("font_size", 12)
	etiqueta_personaje.add_theme_color_override("font_color", Color("#d5edf0"))
	fila_personaje.add_child(etiqueta_personaje)
	_boton_hombre = _crear_boton_personaje("Hombre", "hombre")
	fila_personaje.add_child(_boton_hombre)
	_boton_mujer = _crear_boton_personaje("Mujer", "mujer")
	fila_personaje.add_child(_boton_mujer)
	_actualizar_botones_personaje()
	var heading_gap := Control.new()
	heading_gap.custom_minimum_size.y = 0.0
	column.add_child(heading_gap)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	column.add_child(grid)

	for option in OPTIONS:
		var button := Button.new()
		button.text = option["label"]
		button.custom_minimum_size = Vector2(128, 44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color("#edf8f3"))
		button.add_theme_color_override("font_hover_color", Color("#fff8df"))
		button.add_theme_color_override("font_focus_color", Color("#172a38"))
		button.add_theme_color_override("font_pressed_color", Color("#172a38"))
		button.add_theme_stylebox_override("normal", _button_style(Color("#155f79"), Color("#9ccbd0")))
		button.add_theme_stylebox_override("hover", _button_style(Color("#238b91"), Color("#fff0b2"), 2))
		button.add_theme_stylebox_override("focus", _button_style(Color("#f2c34d"), Color("#fff2bf"), 3))
		button.add_theme_stylebox_override("pressed", _button_style(Color("#e69a35"), Color("#fff0b2"), 2))
		button.add_theme_stylebox_override("disabled", _button_style(Color("#465d68"), Color("#71828a")))
		button.pressed.connect(_open_scene.bind(option["scene"]))
		button.mouse_entered.connect(func(): SONIDO.efecto("menu"))
		button.focus_entered.connect(func(): SONIDO.efecto("menu"))
		grid.add_child(button)
		if grid.get_child_count() == 1:
			button.call_deferred("grab_focus")

	var footer_gap := Control.new()
	footer_gap.custom_minimum_size.y = 0.0
	column.add_child(footer_gap)
	var divider := HSeparator.new()
	divider.add_theme_stylebox_override("separator", _separator_style())
	column.add_child(divider)

	var hint := Label.new()
	hint.text = "A/D mover · W saltar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color("#d5e8e6"))
	column.add_child(hint)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.13, 0.18, 0.91)
	style.border_color = Color("#a7c9bd")
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.shadow_color = Color(0.02, 0.08, 0.12, 0.42)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 6)
	return style


func _button_style(fill: Color, border: Color, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(9)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style


func _separator_style() -> StyleBoxLine:
	var style := StyleBoxLine.new()
	style.color = Color(0.68, 0.83, 0.79, 0.35)
	style.thickness = 1
	return style


func _crear_boton_personaje(texto: String, tipo: String) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.toggle_mode = true
	boton.custom_minimum_size = Vector2(94, 30)
	boton.add_theme_font_size_override("font_size", 12)
	boton.add_theme_color_override("font_color", Color("#edf8f3"))
	boton.add_theme_color_override("font_pressed_color", Color("#172a38"))
	boton.add_theme_stylebox_override("normal", _button_style(Color("#155f79"), Color("#9ccbd0")))
	boton.add_theme_stylebox_override("hover", _button_style(Color("#238b91"), Color("#fff0b2"), 2))
	boton.add_theme_stylebox_override("pressed", _button_style(Color("#f2c34d"), Color("#fff2bf"), 2))
	boton.add_theme_stylebox_override("focus", _button_style(Color("#238b91"), Color("#fff2bf"), 2))
	boton.pressed.connect(_seleccionar_personaje.bind(tipo))
	return boton


func _seleccionar_personaje(tipo: String) -> void:
	ESTADO.personaje_seleccionado = tipo
	_actualizar_botones_personaje()


func _actualizar_botones_personaje() -> void:
	if _boton_hombre == null or _boton_mujer == null:
		return
	_boton_hombre.button_pressed = ESTADO.personaje_seleccionado == "hombre"
	_boton_mujer.button_pressed = ESTADO.personaje_seleccionado == "mujer"

func _open_scene(path: String) -> void:
	if _cambiando_escena:
		return
	_cambiando_escena = true
	SONIDO.efecto("menu_aceptar")
	var salida := TRANSICION.new()
	add_child(salida)
	await salida.fade_out()
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		_cambiando_escena = false
		await salida.fade_in()
		push_error("No se pudo abrir la escena: %s" % path)
