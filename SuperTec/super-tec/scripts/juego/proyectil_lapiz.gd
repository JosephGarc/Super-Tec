extends Area2D

const ARTE_LAPIZ := preload("res://scripts/juego/arte_lapiz.gd")
var direccion := Vector2.RIGHT
var velocidad := 300.0
var dano := 22
var especial := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 5.0
	forma.shape = circulo
	add_child(forma)
	var lapiz := Polygon2D.new()
	lapiz.polygon = PackedVector2Array([Vector2(-8,-2), Vector2(5,-2), Vector2(9,0), Vector2(5,2), Vector2(-8,2)])
	lapiz.color = Color("#ffd84e") if especial else Color("#f6cf42")
	add_child(lapiz)
	var icono := Sprite2D.new()
	icono.texture = ARTE_LAPIZ.obtener_textura()
	icono.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var escala_icono := 18.0 / maxf(float(icono.texture.get_width()), float(icono.texture.get_height()))
	icono.scale = Vector2.ONE * escala_icono
	icono.rotation = PI * 0.5
	add_child(icono)
	var grafito := Polygon2D.new()
	grafito.polygon = PackedVector2Array([Vector2(5,-2), Vector2(9,0), Vector2(5,2)])
	grafito.color = Color("#303642")
	add_child(grafito)
	if especial:
		var destello := Polygon2D.new()
		destello.polygon = PackedVector2Array([Vector2(-2,-7),Vector2(1,-2),Vector2(7,0),Vector2(1,2),Vector2(-2,7),Vector2(-4,2),Vector2(-8,0),Vector2(-4,-2)])
		destello.color = Color(1.0, 0.83, 0.28, 0.68)
		add_child(destello)
		move_child(destello, 0)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(2.0).timeout.connect(queue_free)

func configurar(hacia: Vector2, dano_ataque: int = 22, es_especial: bool = false) -> void:
	direccion = hacia.normalized()
	dano = dano_ataque
	especial = es_especial
	rotation = direccion.angle()

func _physics_process(delta: float) -> void:
	global_position += direccion * velocidad * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("jefe_tesis"):
		if body.has_method("recibir_dano_jefe"):
			body.call("recibir_dano_jefe", dano)
		queue_free()
	elif body.is_in_group("enemies"):
		if body.has_method("recibir_dano"):
			body.recibir_dano(1)
		elif body.has_method("morir"):
			body.morir()
		queue_free()
	elif body is TileMapLayer or body is StaticBody2D:
		queue_free()
