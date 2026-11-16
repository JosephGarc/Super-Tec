extends Area2D
class_name GameCoin

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var spin := create_tween().set_loops()
	spin.tween_property($Sprite2D, "scale", Vector2(0.25, 2.0), 0.18)
	spin.tween_property($Sprite2D, "scale", Vector2(2.0, 2.0), 0.18)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		var game := get_tree().get_first_node_in_group("game")
		if game and game.has_method("collect_coin"):
			game.collect_coin()
		queue_free()
