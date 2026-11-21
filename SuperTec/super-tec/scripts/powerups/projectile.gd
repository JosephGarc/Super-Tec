extends Area2D
class_name PowerUpProjectile

## Proyectil de los power-ups (sistema de Joseph):
## - "ice": tapa helada (coca helada), congela/ralentiza al enemigo
## - "fire": malanga en llamas (malanga picante), lo quema
@export var speed: float = 300.0
@export var lifetime: float = 2.0
var direction: Vector2 = Vector2.RIGHT
var attack_kind: String = "ice"

const TAPA_TEXTURE: Texture2D = preload("res://assets/powerups/tapa_helada.png")
const FIRE_TEXTURE: Texture2D = preload("res://assets/powerups/malanga_fuego.png")
const VISUAL_SCALE := 0.65   # 16 px -> ~10 px, acorde a los bloques del mapa

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	var visual := $Visual as Sprite2D
	visual.texture = TAPA_TEXTURE if attack_kind == "ice" else FIRE_TEXTURE
	visual.scale = Vector2(VISUAL_SCALE, VISUAL_SCALE)
	visual.flip_h = direction.x < 0.0
	visual.region_enabled = attack_kind == "ice"
	visual.region_rect = Rect2(0, 0, 16, 16)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

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
	elif target is TileMapLayer or target is StaticBody2D:
		# Choca con paredes y bloques (ya no rompe el mapa)
		queue_free()
