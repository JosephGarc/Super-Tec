extends Area2D

const ESTADO := preload("res://scripts/juego/estado_juego.gd")
var _jugador: Node2D
var _abierto := false
var _tapa: Polygon2D
var _aviso: Label

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var forma := CollisionShape2D.new()
	var rango := RectangleShape2D.new()
	rango.size = Vector2(58, 48)
	forma.shape = rango
	add_child(forma)
	var cuerpo := Polygon2D.new()
	cuerpo.polygon = PackedVector2Array([Vector2(-14,-7), Vector2(14,-7), Vector2(14,8), Vector2(-14,8)])
	cuerpo.color = Color("#855c36")
	add_child(cuerpo)
	var marco := Polygon2D.new()
	marco.polygon = PackedVector2Array([Vector2(-14,-3), Vector2(14,-3), Vector2(14,1), Vector2(-14,1)])
	marco.color = Color("#edc54c")
	add_child(marco)
	_tapa = Polygon2D.new()
	_tapa.polygon = PackedVector2Array([Vector2(-15,-12), Vector2(15,-12), Vector2(13,-6), Vector2(-13,-6)])
	_tapa.color = Color("#a8733e")
	add_child(_tapa)
	_aviso = Label.new()
	_aviso.position = Vector2(-72, -38)
	_aviso.size = Vector2(144, 22)
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.add_theme_font_size_override("font_size", 11)
	_aviso.add_theme_color_override("font_color", Color("#fff1bd"))
	_aviso.add_theme_color_override("font_outline_color", Color("#263347"))
	_aviso.add_theme_constant_override("outline_size", 3)
	add_child(_aviso)
	_abierto = ESTADO.lapiz_poderoso_obtenido
	_aviso.text = "Lápiz equipado" if _abierto else "E · Abrir cofre"
	_aviso.visible = false
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)

func _al_entrar(body: Node2D) -> void:
	if not body.is_in_group("jugador"):
		return
	_jugador = body
	_aviso.visible = true

func _al_salir(body: Node2D) -> void:
	if body == _jugador:
		_jugador = null
		_aviso.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if _jugador == null or _abierto or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_E:
		_abierto = true
		_aviso.text = "¡LÁPIZ PODEROSO!"
		_jugador.call("obtener_lapiz_poderoso", 4)
		var tween := create_tween()
		tween.tween_property(_tapa, "rotation", -0.85, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
