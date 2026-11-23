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

func _ready() -> void:
	# Elegir nivel desde el selector = partida nueva (créditos 0 y 3 vidas)
	preload("res://scripts/juego/estado_juego.gd").reiniciar()
	SONIDO.musica("menu")
	_build_menu()

func _build_menu() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("#17202b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 320)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)

	var title := Label.new()
	title.text = "Super Tec · Elige un nivel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	column.add_child(grid)

	for option in OPTIONS:
		var button := Button.new()
		button.text = option["label"]
		button.custom_minimum_size = Vector2(146, 42)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_open_scene.bind(option["scene"]))
		button.mouse_entered.connect(func(): SONIDO.efecto("menu"))
		button.focus_entered.connect(func(): SONIDO.efecto("menu"))
		grid.add_child(button)

	var hint := Label.new()
	hint.text = "A/D mover · W saltar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)

func _open_scene(path: String) -> void:
	SONIDO.efecto("menu_aceptar")
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("No se pudo abrir la escena: %s" % path)