extends Control

const ESTADO := preload("res://scripts/juego/estado_juego.gd")
const SONIDO := preload("res://scripts/juego/sonido.gd")
const ESCENA_JOSHUA := preload("res://escenas/personajes_juegos/Joshua.tscn")
const TEXTURA_CAMPUS := preload("res://assets/overworld_super_tec.png")
const SHADER_CIELO := preload("res://shaders/sky_gradient.gdshader")
const TRANSICION := preload("res://scripts/ui/transicion_fade.gd")
const OVERWORLD_PATH := "res://escenas/cinematicas/intro.tscn"   # primero la cinemática; luego el campus
const MENU_PATH := "res://menu/menu_principal.tscn"
const SELECTOR_RESPALDO_PATH := "res://escenas/pruebas/selector_escenarios.tscn"
const RANKING_SCRIPT := preload("res://scripts/ui/ranking_panel.gd")

var _personaje_seleccionado := "hombre"
var _botones_personaje: Dictionary = {}
var _etiquetas_personaje: Dictionary = {}
var _boton_comenzar: Button
var _nombre_jugador: LineEdit
var _cambiando_escena := false

func _ready() -> void:
	SONIDO.inicializar()
	_personaje_seleccionado = ESTADO.personaje_seleccionado
	_crear_interfaz()
	_actualizar_tarjetas()
	_boton_comenzar.call_deferred("grab_focus")
	var entrada := TRANSICION.new()
	add_child(entrada)
	entrada.fade_in()

func _crear_interfaz() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var material := ShaderMaterial.new()
	material.shader = SHADER_CIELO
	fondo.material = material
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)
	var campus := TextureRect.new()
	campus.texture = TEXTURA_CAMPUS
	campus.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	campus.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	campus.anchor_top = 0.38
	campus.anchor_right = 1.0
	campus.anchor_bottom = 1.0
	campus.modulate = Color(0.64, 0.77, 0.75, 0.42)
	campus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(campus)
	var sombra := ColorRect.new()
	sombra.color = Color(0.035, 0.09, 0.16, 0.42)
	sombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sombra)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.offset_left = 18.0
	centro.offset_top = 12.0
	centro.offset_right = -18.0
	centro.offset_bottom = -12.0
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 400)
	panel.add_theme_stylebox_override("panel", _estilo_panel())
	centro.add_child(panel)
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 20)
	margen.add_theme_constant_override("margin_right", 20)
	margen.add_theme_constant_override("margin_top", 12)
	margen.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margen)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 5)
	margen.add_child(columna)
	var titulo := Label.new()
	titulo.text = "SÚPER TEC"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 34)
	titulo.add_theme_color_override("font_color", Color("#fff2ce"))
	titulo.add_theme_color_override("font_outline_color", Color("#173044"))
	titulo.add_theme_constant_override("outline_size", 5)
	columna.add_child(titulo)
	var subtitulo := Label.new()
	subtitulo.text = "Elige a tu personaje"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_font_size_override("font_size", 14)
	subtitulo.add_theme_color_override("font_color", Color("#d9edf0"))
	columna.add_child(subtitulo)
	var espacio := Control.new()
	espacio.custom_minimum_size.y = 5.0
	columna.add_child(espacio)
	var tarjetas := HBoxContainer.new()
	tarjetas.alignment = BoxContainer.ALIGNMENT_CENTER
	tarjetas.add_theme_constant_override("separation", 14)
	columna.add_child(tarjetas)
	var previews := _crear_previews()
	tarjetas.add_child(_crear_tarjeta("hombre", "Joshua", previews["hombre"]))
	tarjetas.add_child(_crear_tarjeta("mujer", "Sam", previews["mujer"]))
	var fila_jugador := HBoxContainer.new()
	fila_jugador.add_theme_constant_override("separation", 8)
	columna.add_child(fila_jugador)
	_nombre_jugador = LineEdit.new()
	_nombre_jugador.placeholder_text = "Nombre del jugador"
	_nombre_jugador.text = ESTADO.nombre_jugador
	_nombre_jugador.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nombre_jugador.custom_minimum_size.y = 34
	fila_jugador.add_child(_nombre_jugador)
	var boton_ranking := Button.new()
	boton_ranking.text = "RANKING"
	boton_ranking.custom_minimum_size = Vector2(105, 34)
	boton_ranking.pressed.connect(_abrir_ranking)
	fila_jugador.add_child(boton_ranking)
	var espacio_boton := Control.new()
	espacio_boton.custom_minimum_size.y = 3.0
	columna.add_child(espacio_boton)
	_boton_comenzar = Button.new()
	_boton_comenzar.text = "COMENZAR"
	_boton_comenzar.custom_minimum_size = Vector2(250, 42)
	_boton_comenzar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_boton_comenzar.add_theme_font_size_override("font_size", 16)
	_boton_comenzar.add_theme_color_override("font_color", Color("#183044"))
	_boton_comenzar.add_theme_stylebox_override("normal", _estilo_boton(Color("#f1c65a"), Color("#fff0b7")))
	_boton_comenzar.add_theme_stylebox_override("hover", _estilo_boton(Color("#ffe28a"), Color.WHITE))
	_boton_comenzar.add_theme_stylebox_override("focus", _estilo_boton(Color("#ffe28a"), Color.WHITE, 3))
	_boton_comenzar.add_theme_stylebox_override("pressed", _estilo_boton(Color("#dca53e"), Color("#fff0b7")))
	_boton_comenzar.pressed.connect(_comenzar)
	columna.add_child(_boton_comenzar)
	var ayuda := Label.new()
	ayuda.text = "Enter / Espacio comenzar · M audio · F9 selector respaldo"
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ayuda.add_theme_font_size_override("font_size", 10)
	ayuda.add_theme_color_override("font_color", Color("#d9edf0"))
	columna.add_child(ayuda)

func _crear_previews() -> Dictionary:
	var prototipo := ESCENA_JOSHUA.instantiate() as CharacterBody2D
	var sprite := prototipo.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var hombre: Texture2D = sprite.sprite_frames.get_frame_texture("idle", 0)
	var frames_mujer = prototipo.call("_crear_spriteframes_mujer")
	var mujer: Texture2D = frames_mujer.get_frame_texture("idle", 0) if frames_mujer is SpriteFrames else hombre
	prototipo.free()
	return {"hombre": hombre, "mujer": mujer}

func _crear_tarjeta(tipo: String, titulo: String, preview: Texture2D) -> Button:
	var boton := Button.new()
	boton.name = "Tarjeta" + titulo
	boton.custom_minimum_size = Vector2(185, 142)
	boton.focus_mode = Control.FOCUS_ALL
	boton.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var contenido := VBoxContainer.new()
	contenido.alignment = BoxContainer.ALIGNMENT_CENTER
	contenido.add_theme_constant_override("separation", 3)
	contenido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var etiqueta := Label.new()
	etiqueta.text = titulo
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_size_override("font_size", 15)
	etiqueta.add_theme_color_override("font_color", Color.WHITE)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.add_child(etiqueta)
	var imagen := TextureRect.new()
	imagen.texture = preview
	imagen.custom_minimum_size = Vector2(100, 88)
	imagen.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.add_child(imagen)
	var estado := Label.new()
	estado.text = "SELECCIONADO" if tipo == _personaje_seleccionado else "Elegir"
	estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	estado.add_theme_font_size_override("font_size", 9)
	estado.add_theme_color_override("font_color", Color("#ffe28a"))
	estado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.add_child(estado)
	boton.add_child(contenido)
	contenido.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	boton.add_theme_stylebox_override("normal", _estilo_boton(Color("#16364a"), Color("#527b88")))
	boton.add_theme_stylebox_override("hover", _estilo_boton(Color("#24566b"), Color("#c4e2d4"), 2))
	boton.add_theme_stylebox_override("focus", _estilo_boton(Color("#24566b"), Color("#ffe28a"), 3))
	boton.pressed.connect(_seleccionar_personaje.bind(tipo))
	_botones_personaje[tipo] = boton
	_etiquetas_personaje[tipo] = estado
	return boton

func _seleccionar_personaje(tipo: String) -> void:
	_personaje_seleccionado = tipo
	_actualizar_tarjetas()

func _actualizar_tarjetas() -> void:
	for tipo in _botones_personaje:
		var seleccionado: bool = tipo == _personaje_seleccionado
		var boton: Button = _botones_personaje[tipo]
		boton.add_theme_stylebox_override(
			"normal",
			_estilo_boton(Color("#24566b"), Color("#ffe28a"), 3) if seleccionado else _estilo_boton(Color("#16364a"), Color("#527b88"))
		)
		_etiquetas_personaje[tipo].text = "SELECCIONADO" if seleccionado else "Elegir"

func _estilo_panel() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.035, 0.105, 0.16, 0.94)
	estilo.border_color = Color("#8eb9b4")
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(16)
	estilo.shadow_color = Color(0.0, 0.025, 0.05, 0.55)
	estilo.shadow_size = 14
	estilo.shadow_offset = Vector2(0, 5)
	return estilo

func _estilo_boton(fondo: Color, borde: Color, ancho: int = 1) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.set_border_width_all(ancho)
	estilo.set_corner_radius_all(10)
	return estilo

func _comenzar() -> void:
	if _cambiando_escena:
		return
	_cambiando_escena = true
	ESTADO.personaje_seleccionado = _personaje_seleccionado
	var nombre := _nombre_jugador.text.strip_edges()
	ESTADO.nombre_jugador = nombre if not nombre.is_empty() else "Jugador"
	ESTADO.reiniciar()
	ESTADO.iniciar_cronometro()
	var salida := TRANSICION.new()
	add_child(salida)
	await salida.fade_out()
	var error := get_tree().change_scene_to_file(OVERWORLD_PATH)
	if error != OK:
		_cambiando_escena = false
		await salida.fade_in()
		push_error("No se pudo abrir el Mapa del Tec.")

func _abrir_ranking() -> void:
	add_child(RANKING_SCRIPT.new())

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or _cambiando_escena:
		return
	if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		_comenzar()
	elif event.keycode == KEY_ESCAPE:
		_cambiando_escena = true
		get_tree().change_scene_to_file.call_deferred(MENU_PATH)
	elif event.keycode == KEY_F9:
		_cambiando_escena = true
		ESTADO.retorno_overworld_habilitado = false
		call_deferred("_abrir_selector_respaldo")

func _abrir_selector_respaldo() -> void:
	var salida := TRANSICION.new()
	add_child(salida)
	await salida.fade_out()
	var error := get_tree().change_scene_to_file(SELECTOR_RESPALDO_PATH)
	if error != OK:
		_cambiando_escena = false
		await salida.fade_in()
		push_error("No se pudo abrir el selector de respaldo.")
