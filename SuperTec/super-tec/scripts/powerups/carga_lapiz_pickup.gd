extends Area2D

var tipo := "carga_lapiz"

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 9.0
	forma.shape = circulo
	add_child(forma)
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([Vector2(0,-9),Vector2(8,-4),Vector2(8,5),Vector2(0,9),Vector2(-8,5),Vector2(-8,-4)])
	base.color = Color("#4bbbd0") if tipo == "carga_lapiz" else Color("#e85a78")
	add_child(base)
	var texto := Label.new()
	texto.text = "+" if tipo == "carga_lapiz" else "♥"
	texto.position = Vector2(-5,-12)
	texto.add_theme_color_override("font_color", Color.WHITE)
	texto.add_theme_font_size_override("font_size", 15)
	add_child(texto)
	body_entered.connect(_recoger)

func _recoger(body: Node2D) -> void:
	if tipo == "carga_lapiz" and body.has_method("cargar_lapiz"):
		body.cargar_lapiz(2)
		queue_free()
	elif tipo == "vida" and body.get("power_ups") != null:
		var controlador: Node = body.get("power_ups")
		controlador.set("lives", int(controlador.get("lives")) + 1)
		queue_free()
