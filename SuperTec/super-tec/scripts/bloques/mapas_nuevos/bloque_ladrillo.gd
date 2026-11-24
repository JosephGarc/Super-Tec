extends StaticBody2D

const SONIDO := preload("res://scripts/juego/sonido.gd")
var _luz: PointLight2D
var _golpe_tween: Tween
@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_agregar_brillo()

func _agregar_brillo() -> void:
	var gradiente := Gradient.new()
	gradiente.colors = [Color(1, 1, 1, 0.3), Color(1, 1, 1, 0)]
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.width = 64
	textura.height = 64
	textura.fill = GradientTexture2D.FILL_RADIAL
	_luz = PointLight2D.new()
	_luz.texture = textura
	_luz.energy = 0.2
	_luz.texture_scale = 0.22
	_luz.color = Color("#ffd995")
	add_child(_luz)

func _animar_golpe() -> void:
	if _golpe_tween and _golpe_tween.is_running():
		_golpe_tween.kill()
	var reposo := _sprite.position
	var tono := _sprite.modulate
	var energia := _luz.energy
	_golpe_tween = create_tween()
	_golpe_tween.set_parallel(true)
	_golpe_tween.tween_property(_sprite, "position:y", reposo.y - 5.0, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_golpe_tween.tween_property(_sprite, "modulate", Color("#fff2bb"), 0.06)
	_golpe_tween.tween_property(_luz, "energy", energia + 0.55, 0.06)
	_golpe_tween.chain().set_parallel(true)
	_golpe_tween.tween_property(_sprite, "position:y", reposo.y, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_golpe_tween.tween_property(_sprite, "modulate", tono, 0.15)
	_golpe_tween.tween_property(_luz, "energy", energia, 0.18)

func golpear(jugador):
	_animar_golpe()
	if jugador.has_method("shake"):
		jugador.shake(1.4, 0.1)
	_afectar_lo_de_arriba()
	if jugador.get("es_grande") == true:
		SONIDO.efecto("romper")
		queue_free()          # Mario grande: se rompe
	else:
		SONIDO.efecto("golpe_bloque")

func _afectar_lo_de_arriba():
	for cuerpo in $ZonaArriba.get_overlapping_bodies():
		if cuerpo.has_method("morir"):
			cuerpo.morir()
