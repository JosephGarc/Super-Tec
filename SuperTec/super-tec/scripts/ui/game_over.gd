extends CanvasLayer

const SONIDO := preload("res://scripts/juego/sonido.gd")
const ESTADO := preload("res://scripts/juego/estado_juego.gd")
const TRANSICION := preload("res://scripts/ui/transicion_fade.gd")
const OVERWORLD_PATH := "res://escenas/overworld_super_tec.tscn"

var _cambiando_escena := false

func _ready() -> void:
	layer = 120
	var fondo := ColorRect.new()
	fondo.color = Color(0.015, 0.025, 0.05, 0.86)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 205)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#142735")
	estilo.border_color = Color("#f0c052")
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(14)
	estilo.content_margin_left = 24.0
	estilo.content_margin_right = 24.0
	estilo.content_margin_top = 20.0
	estilo.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(panel)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 14)
	panel.add_child(columna)
	var titulo := Label.new()
	titulo.text = "GAME OVER"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 28)
	titulo.add_theme_color_override("font_color", Color("#fff1cc"))
	columna.add_child(titulo)

	var reintentar := _crear_boton("Reintentar")
	reintentar.pressed.connect(_reintentar)
	columna.add_child(reintentar)
	var mapa := _crear_boton("Volver al Mapa del Tec")
	mapa.pressed.connect(_volver_al_overworld)
	columna.add_child(mapa)
	reintentar.call_deferred("grab_focus")

func _crear_boton(texto: String) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(245, 42)
	boton.add_theme_font_size_override("font_size", 15)
	boton.add_theme_color_override("font_color", Color("#f5fbf4"))
	boton.add_theme_color_override("font_focus_color", Color("#182b37"))
	boton.add_theme_stylebox_override("normal", _estilo_boton(Color("#155f79"), Color("#9ccbd0")))
	boton.add_theme_stylebox_override("hover", _estilo_boton(Color("#278d91"), Color("#fff0b2")))
	boton.add_theme_stylebox_override("focus", _estilo_boton(Color("#f2c34d"), Color("#fff2bf")))
	boton.add_theme_stylebox_override("pressed", _estilo_boton(Color("#e69a35"), Color("#fff0b2")))
	return boton

func _estilo_boton(fondo: Color, borde: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(8)
	return estilo

func _reintentar() -> void:
	if _cambiando_escena:
		return
	_cambiando_escena = true
	SONIDO.efecto("menu_aceptar")
	var salida := TRANSICION.new()
	add_child(salida)
	await salida.fade_out()
	var error := get_tree().reload_current_scene()
	if error != OK:
		_cambiando_escena = false
		await salida.fade_in()
		push_error("No se pudo reiniciar el nivel actual.")

func _volver_al_overworld() -> void:
	if _cambiando_escena:
		return
	_cambiando_escena = true
	ESTADO.detener_cronometro()
	SONIDO.efecto("menu_aceptar")
	var salida := TRANSICION.new()
	add_child(salida)
	await salida.fade_out()
	var error := get_tree().change_scene_to_file(OVERWORLD_PATH)
	if error != OK:
		_cambiando_escena = false
		await salida.fade_in()
		push_error("No se pudo volver al overworld.")
