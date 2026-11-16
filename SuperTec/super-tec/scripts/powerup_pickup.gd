extends Area2D

@export_enum("azulito", "malanga_fuego") var power_up_id := "azulito"
const DISPLAY_SIZE := 8.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null and sprite.texture != null:
		var texture_size := sprite.texture.get_size()
		var largest_dimension := maxf(texture_size.x, texture_size.y)
		if largest_dimension > 0.0:
			sprite.scale = Vector2.ONE * (DISPLAY_SIZE / largest_dimension)
		var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision != null and collision.shape is CircleShape2D:
			var circle := (collision.shape as CircleShape2D).duplicate() as CircleShape2D
			circle.radius = DISPLAY_SIZE * 0.5
			collision.shape = circle

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("collect_power_up"):
		body.collect_power_up(power_up_id)
		queue_free()
