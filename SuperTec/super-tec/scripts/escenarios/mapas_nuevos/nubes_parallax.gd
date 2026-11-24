extends ParallaxLayer

@export var velocidad_nubes := 5.0

func _process(delta: float) -> void:
	motion_offset.x += velocidad_nubes * delta
