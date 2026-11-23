extends Area2D

const SONIDO := preload("res://scripts/juego/sonido.gd")

@export_file("*.tscn") var siguiente_nivel: String

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("jugador") and siguiente_nivel != "":
		SONIDO.efecto("meta")
		get_tree().change_scene_to_file.call_deferred(siguiente_nivel)
