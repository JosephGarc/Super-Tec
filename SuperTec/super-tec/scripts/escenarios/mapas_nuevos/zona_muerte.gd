extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# El piso (TileMapLayer) y los bloques también entran al área: esos no se tocan
	if body is TileMapLayer or body is StaticBody2D:
		return
	if body.has_method("morir"):
		body.morir()
	else:
		body.queue_free()
