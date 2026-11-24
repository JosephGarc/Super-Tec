extends CanvasLayer

const ESTADO := preload("res://scripts/juego/estado_juego.gd")
const RANKING_SCRIPT := preload("res://scripts/ui/ranking_panel.gd")
const INICIO := "res://menu/menu_principal.tscn"
const OVERWORLD := "res://escenas/overworld_super_tec.tscn"

func _ready() -> void:
	layer = 160
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var fondo := ColorRect.new()
	fondo.color = Color(0.015, 0.035, 0.07, 0.88)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(470, 220)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#15334a")
	estilo.border_color = Color("#f1c65a")
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(panel)
	var columna := VBoxContainer.new()
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 14)
	panel.add_child(columna)
	var titulo := Label.new()
	titulo.text = "¡Felicidades! Te graduaste del Tec"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 22)
	titulo.add_theme_color_override("font_color", Color("#ffe28a"))
	columna.add_child(titulo)
	var datos := Label.new()
	datos.text = "%s  ·  %s" % [ESTADO.nombre_jugador, ESTADO.formatear_tiempo(ESTADO.tiempo_final_segundos())]
	datos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	datos.add_theme_font_size_override("font_size", 16)
	columna.add_child(datos)
	var botones := HBoxContainer.new()
	botones.alignment = BoxContainer.ALIGNMENT_CENTER
	botones.add_theme_constant_override("separation", 10)
	columna.add_child(botones)
	_agregar_boton(botones, "VER RANKING", _ver_ranking)
	_agregar_boton(botones, "MAPA DEL TEC", _ir_overworld)
	_agregar_boton(botones, "MENÚ", _reiniciar)

func _agregar_boton(contenedor: HBoxContainer, texto: String, accion: Callable) -> void:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(136, 36)
	boton.pressed.connect(accion)
	contenedor.add_child(boton)

func _ver_ranking() -> void:
	get_tree().root.add_child(RANKING_SCRIPT.new())

func _ir_overworld() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(OVERWORLD)

func _reiniciar() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(INICIO)
