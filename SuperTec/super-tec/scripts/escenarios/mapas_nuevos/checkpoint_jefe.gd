extends Area2D

const ESTADO := preload("res://scripts/juego/estado_juego.gd")
var _activado := false

func _ready() -> void:
	body_entered.connect(_al_entrar)

func _al_entrar(body: Node2D) -> void:
	if _activado or not body.is_in_group("jugador"):
		return
	_activado = true
	ESTADO.checkpoint_nivel9 = global_position
	ESTADO.checkpoint_nivel9_activo = true
	if body is CharacterBody2D:
		body.set("spawn_position", global_position)
		body.set("spawn_guardado", true)
		body.set("_punto_seguro", global_position)
		body.set("_hay_punto_seguro", true)
	var aviso := Label.new()
	aviso.text = "CHECKPOINT · ARENA DE TESIS"
	aviso.position = Vector2(-105, -42)
	aviso.add_theme_font_size_override("font_size", 12)
	aviso.add_theme_color_override("font_color", Color("#ffe28a"))
	aviso.add_theme_color_override("font_outline_color", Color("#18283b"))
	aviso.add_theme_constant_override("outline_size", 4)
	add_child(aviso)
	var tween := create_tween()
	tween.tween_property(aviso, "modulate:a", 0.0, 2.0)
	tween.tween_callback(aviso.queue_free)
