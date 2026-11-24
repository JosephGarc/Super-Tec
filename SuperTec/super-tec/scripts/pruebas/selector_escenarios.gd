extends Control

const SONIDO := preload("res://scripts/juego/sonido.gd")

const MENU_PATH := "res://menu/menu_principal.tscn"

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

const PROGRESO := preload("res://scripts/juego/progreso.gd")

## CONTINUAR: solo se pueden elegir los niveles ya superados y el siguiente.
## Cada nivel muestra cuántos créditos llevas (de 20), para regresar por los que faltan.

func _ready() -> void:
	PROGRESO.cargar()
	PROGRESO.empezar_nivel(0)
	preload("res://scripts/juego/estado_juego.gd").reiniciar()   # entras con 3 vidas
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
	title.text = "Continuar · Créditos: %d / %d" % [PROGRESO.total(), PROGRESO.CREDITOS_TOTALES]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	column.add_child(grid)

	var primero: Button = null
	for i in OPTIONS.size():
		var option: Dictionary = OPTIONS[i]
		var n := i + 1
		var button := Button.new()
		if PROGRESO.desbloqueado(n):
			var marca := "" if PROGRESO.superado(n) else " · nuevo"
			button.text = "%s%s\n%d/%d créditos" % [option["label"], marca, PROGRESO.creditos_nivel(n), PROGRESO.CREDITOS_POR_NIVEL]
			if PROGRESO.creditos_nivel(n) == PROGRESO.CREDITOS_POR_NIVEL:
				button.add_theme_color_override("font_color", Color("f2c14e"))
			if primero == null or not PROGRESO.superado(n):
				primero = button
		else:
			button.text = "%s\nBloqueado" % option["label"]
			button.disabled = true
		button.custom_minimum_size = Vector2(146, 48)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_open_scene.bind(option["scene"]))
		button.mouse_entered.connect(func(): SONIDO.efecto("menu"))
		button.focus_entered.connect(func(): SONIDO.efecto("menu"))
		grid.add_child(button)

	if primero:
		primero.grab_focus.call_deferred()

	var regresar := Button.new()
	regresar.text = "Regresar al menú"
	regresar.pressed.connect(_open_scene.bind(MENU_PATH))
	regresar.mouse_entered.connect(func(): SONIDO.efecto("menu"))
	column.add_child(regresar)

	var hint := Label.new()
	hint.text = "A/D mover · W saltar · Esc: menú"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_open_scene(MENU_PATH)


func _open_scene(path: String) -> void:
	SONIDO.efecto("menu_aceptar")
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("No se pudo abrir la escena: %s" % path)