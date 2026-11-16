extends Node2D

const START_POSITION := Vector2(100, 330)
const FALL_LIMIT := 1000.0

var coin_count := 0
@onready var player: CharacterBody2D = $CharacterBody2D
@onready var coin_label: Label = $HUD/CoinCount
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	add_to_group("game")
	_update_coin_hud()

func _process(_delta: float) -> void:
	camera.global_position = player.global_position + Vector2(0, -145)
	if player.global_position.y > FALL_LIMIT:
		player.global_position = START_POSITION
		player.velocity = Vector2.ZERO

func collect_coin() -> void:
	coin_count += 1
	_update_coin_hud()

func _update_coin_hud() -> void:
	coin_label.text = "Créditos: %d" % coin_count
