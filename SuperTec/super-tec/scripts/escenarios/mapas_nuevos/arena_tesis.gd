extends Node2D

func _ready() -> void:
	z_index = -10
	queue_redraw()

func _draw() -> void:
	# Cielo y horizonte cubren el área de cámara aunque alguna capa de tiles
	# falte o tarde en reconstruirse en la primera ejecución.
	draw_rect(Rect2(0, -256, 3400, 310), Color("#294c78"))
	draw_rect(Rect2(0, -100, 3400, 150), Color("#527e9e"))
	draw_rect(Rect2(0, 25, 3400, 34), Color("#d59c74"))
	draw_rect(Rect2(0, 58, 3400, 24), Color("#e7bd89"))
	var silueta := Color("#263958")
	draw_colored_polygon(PackedVector2Array([Vector2(0, 68), Vector2(180, 22), Vector2(360, 68), Vector2(560, 10), Vector2(760, 68), Vector2(980, 32), Vector2(1210, 68), Vector2(1460, 12), Vector2(1700, 68), Vector2(1960, 28), Vector2(2200, 68), Vector2(2440, 8), Vector2(2700, 68), Vector2(2920, 20), Vector2(3200, 68), Vector2(3400, 30), Vector2(3400, 180), Vector2(0, 180)]), silueta)
	# Plataforma visual detrás de la geometría original del escenario.
	draw_rect(Rect2(0, 188, 3400, 180), Color("#342f42"))
	draw_rect(Rect2(0, 188, 3400, 7), Color("#d1a65f"))
	for x in range(0, 3400, 48):
		draw_rect(Rect2(x, 216, 24, 2), Color(0.72, 0.59, 0.48, 0.38))
