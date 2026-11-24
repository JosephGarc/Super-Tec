extends CanvasLayer

const ESTADO := preload("res://scripts/juego/estado_juego.gd")

func _ready() -> void:
	layer = 180
	process_mode = Node.PROCESS_MODE_ALWAYS
	var fondo := ColorRect.new()
	fondo.color = Color(0.015, 0.035, 0.07, 0.86)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 390)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#15334a")
	estilo.border_color = Color("#f1c65a")
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(panel)
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 22)
	margen.add_theme_constant_override("margin_right", 22)
	margen.add_theme_constant_override("margin_top", 18)
	margen.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margen)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 10)
	margen.add_child(columna)
	var titulo := Label.new()
	titulo.text = "MEJORES TIEMPOS"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 25)
	titulo.add_theme_color_override("font_color", Color("#ffe28a"))
	columna.add_child(titulo)
	var ranking := ESTADO.obtener_ranking()
	var mejores_por_nivel: Dictionary = {}
	for dato in ranking:
		mejores_por_nivel[int(dato.get("nivel", 9))] = dato
	for nivel in range(1, 10):
		var fila := Label.new()
		if mejores_por_nivel.has(nivel):
			var dato: Dictionary = mejores_por_nivel[nivel]
			var estado := "COMPLETADO" if ESTADO.nivel_completado(nivel) else "MEJOR TIEMPO"
			fila.text = "Nivel %d  ·  %s  ·  %s  ·  %s  ·  %s" % [nivel, estado, str(dato.get("nombre", "Jugador")), str(dato.get("personaje", "Hombre")), str(dato.get("tiempo", "--:--"))]
		else:
			var estado := "COMPLETADO" if ESTADO.nivel_completado(nivel) else "PENDIENTE"
			fila.text = "Nivel %d  ·  %s  ·  Sin tiempo registrado" % [nivel, estado]
		fila.add_theme_font_size_override("font_size", 13)
		columna.add_child(fila)
	var cerrar := Button.new()
	cerrar.text = "CERRAR"
	cerrar.custom_minimum_size.y = 38
	cerrar.pressed.connect(queue_free)
	columna.add_child(cerrar)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		queue_free()
