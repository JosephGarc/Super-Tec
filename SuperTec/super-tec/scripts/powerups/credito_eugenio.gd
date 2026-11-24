extends Area2D
class_name CreditoEugenio

const SONIDO := preload("res://scripts/juego/sonido.gd")
const PROGRESO := preload("res://scripts/juego/progreso.gd")

## Crédito Eugenio (la "moneda" del juego, sistema de Joseph).
## Al tocarlo, suma 1 al contador del HUD (nodo del grupo "game").

var _escala_base := Vector2.ONE

func _ready() -> void:
	add_to_group("coins")
	# Si ya lo conseguiste en otra partida de este nivel, sale transparente (como en GD)
	if PROGRESO.ya_lo_tenia(name):
		modulate = Color(1, 1, 1, 0.4)
	body_entered.connect(_on_body_entered)
	_escala_base = $Sprite2D.scale
	var spin := create_tween().set_loops()
	spin.tween_property($Sprite2D, "scale", Vector2(_escala_base.x * 0.125, _escala_base.y), 0.18)
	spin.tween_property($Sprite2D, "scale", _escala_base, 0.18)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("jugador"):
		var game := get_tree().get_first_node_in_group("game")
		if game and game.has_method("collect_coin"):
			game.collect_coin(name)
		SONIDO.efecto("credito")
		queue_free()
