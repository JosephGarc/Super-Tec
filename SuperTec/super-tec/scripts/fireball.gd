extends Area2D

@export var speed := 300.0
var direction := 1.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(2.5).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta

func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.0, Color("#ff6b16"))
	draw_circle(Vector2.ZERO, 2.0, Color("#e92718"))
	draw_circle(Vector2(-0.7, -0.7), 1.0, Color("#ffe45c"))

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("receive_power_up_attack"):
		body.receive_power_up_attack("fire", 10.0)
		queue_free()
		return
	if body is TileMapLayer:
		var map_layer := body as TileMapLayer
		var cell := map_layer.local_to_map(map_layer.to_local(global_position))
		if map_layer.get_cell_source_id(cell) != -1:
			map_layer.erase_cell(cell)
	queue_free()
