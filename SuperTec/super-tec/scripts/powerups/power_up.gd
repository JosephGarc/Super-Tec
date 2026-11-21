extends Area2D
class_name PowerUpPickup

## Power-up que se recoge al tocarlo (sistema de Joseph).
## Identificador que recibe el personaje: azulito, coca_helada,
## malanga_picante, volovan o taco.
@export_enum("azulito", "coca_helada", "malanga_picante", "volovan", "taco")
var power_up_id: String = "azulito"
@export var texture: Texture2D

# Tamaño en pantalla, adaptado a los bloques de 16 px de Super Tec
const DISPLAY_SIZE := 12.0
const BOB_HEIGHT := 2.0

func _ready() -> void:
	if texture:
		$Sprite2D.texture = texture
		var largest_dimension := maxf(texture.get_width(), texture.get_height())
		if largest_dimension > 0:
			$Sprite2D.scale = Vector2.ONE * (DISPLAY_SIZE / float(largest_dimension))
			var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
			if collision != null and collision.shape is RectangleShape2D:
				var rectangle := (collision.shape as RectangleShape2D).duplicate() as RectangleShape2D
				rectangle.size = Vector2(texture.get_size()) * (DISPLAY_SIZE / float(largest_dimension))
				collision.shape = rectangle
	var bob := create_tween().set_loops()
	bob.tween_property($Sprite2D, "position", Vector2(0, -BOB_HEIGHT), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property($Sprite2D, "position", Vector2(0, BOB_HEIGHT), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("collect_power_up"):
		body.collect_power_up(power_up_id)
		queue_free()
