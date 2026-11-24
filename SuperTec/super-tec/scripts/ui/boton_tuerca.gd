extends Control
## Tuerca de ajustes que va arriba a la izquierda en los niveles.
## Se dibuja con código (no necesita imagen). Al darle clic abre el menú de ajustes.

signal presionada

const TAM := 26.0
var _encima := false


func _ready() -> void:
	position = Vector2(6, 5)
	size = Vector2(TAM, TAM)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Ajustes (Esc)"
	mouse_entered.connect(_al_entrar)
	mouse_exited.connect(_al_salir)


func _al_entrar() -> void:
	_encima = true
	queue_redraw()


func _al_salir() -> void:
	_encima = false
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		presionada.emit()


func _draw() -> void:
	var c := size / 2.0
	var color := Color("#ffe28a") if _encima else Color("#f4f4f4")
	var borde := Color(0, 0, 0, 0.85)
	var dientes := 8
	# Contorno negro y luego la tuerca encima
	for capa in [[borde, 2.0], [color, 0.0]]:
		var col: Color = capa[0]
		var extra: float = capa[1]
		for i in dientes:
			var ang := TAU * i / dientes
			var dir := Vector2.from_angle(ang)
			var lado := dir.orthogonal() * (3.2 + extra)
			var p1 := c + dir * 7.0
			var p2 := c + dir * (11.5 + extra)
			draw_colored_polygon(PackedVector2Array([p1 - lado, p2 - lado, p2 + lado, p1 + lado]), col)
		draw_circle(c, 8.5 + extra, col)
	draw_circle(c, 3.6, borde)
