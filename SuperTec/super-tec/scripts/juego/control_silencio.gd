extends Node

static var _silenciado := false
static var _volumenes_guardados: Dictionary = {}
static var _instancia: Node

var _aviso: PanelContainer
var _tiempo_aviso := 0.0

func _ready() -> void:
	set_process_unhandled_key_input(true)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_instancia = self
	_crear_aviso()

func _process(delta: float) -> void:
	if _tiempo_aviso <= 0.0:
		return
	_tiempo_aviso -= delta
	if _tiempo_aviso <= 0.0 and _aviso != null:
		_aviso.visible = false

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		alternar()
		get_viewport().set_input_as_handled()

static func esta_silenciado() -> bool:
	return _silenciado

static func alternar() -> void:
	_silenciado = not _silenciado
	for nombre in ["Musica", "Efectos"]:
		var indice := AudioServer.get_bus_index(nombre)
		if indice < 0:
			continue
		if _silenciado:
			_volumenes_guardados[nombre] = AudioServer.get_bus_volume_db(indice)
			AudioServer.set_bus_volume_db(indice, -80.0)
		else:
			AudioServer.set_bus_volume_db(indice, _volumenes_guardados.get(nombre, 0.0))
	if _instancia != null and is_instance_valid(_instancia):
		_instancia.call("_mostrar_aviso")

static func establecer_volumen(nombre: String, volumen_db: float) -> void:
	var indice := AudioServer.get_bus_index(nombre)
	if indice < 0:
		return
	if _silenciado:
		_volumenes_guardados[nombre] = volumen_db
		AudioServer.set_bus_volume_db(indice, -80.0)
	else:
		AudioServer.set_bus_volume_db(indice, volumen_db)

func _crear_aviso() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 110
	add_child(capa)
	_aviso = PanelContainer.new()
	_aviso.anchor_left = 1.0
	_aviso.anchor_right = 1.0
	_aviso.offset_left = -174.0
	_aviso.offset_right = -10.0
	_aviso.offset_top = 10.0
	_aviso.offset_bottom = 42.0
	_aviso.visible = false
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.035, 0.08, 0.12, 0.92)
	estilo.border_color = Color("#a9d8c9")
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(7)
	_aviso.add_theme_stylebox_override("panel", estilo)
	capa.add_child(_aviso)
	var texto := Label.new()
	texto.name = "Texto"
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.add_theme_font_size_override("font_size", 12)
	texto.add_theme_color_override("font_color", Color.WHITE)
	_aviso.add_child(texto)

func _mostrar_aviso() -> void:
	var texto := _aviso.get_node("Texto") as Label
	texto.text = "AUDIO: SILENCIADO (M)" if _silenciado else "AUDIO: ACTIVO (M)"
	_aviso.visible = true
	_tiempo_aviso = 1.4
