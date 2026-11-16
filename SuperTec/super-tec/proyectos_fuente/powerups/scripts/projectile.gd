extends Area2D
class_name PowerUpProjectile

@export var speed: float = 300.0
@export var lifetime: float = 3.0
var direction: Vector2 = Vector2.RIGHT
var attack_kind: String = "ice"

const TAPA_TEXTURE: Texture2D = preload("res://assets/tapa_helada.png")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	var visual := $Visual as Sprite2D
	visual.texture = TAPA_TEXTURE
	visual.scale = Vector2(0.5, 0.5)
	visual.visible = attack_kind == "ice"
	queue_redraw()
	visual.region_enabled = attack_kind == "ice"
	visual.region_rect = Rect2(0, 0, 16, 16)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _draw() -> void:
	if attack_kind == "fire":
		draw_circle(Vector2.ZERO, 4.0, Color("#ff6b16"))
		draw_circle(Vector2.ZERO, 2.7, Color("#e92718"))
		draw_circle(Vector2(-0.8, -0.8), 1.2, Color("#ffe45c"))

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	_hit_target(body)

func _on_area_entered(area: Area2D) -> void:
	_hit_target(area)

func _hit_target(target: Node) -> void:
	if target.has_method("receive_power_up_attack"):
		target.receive_power_up_attack(attack_kind, 10.0)
		queue_free()
