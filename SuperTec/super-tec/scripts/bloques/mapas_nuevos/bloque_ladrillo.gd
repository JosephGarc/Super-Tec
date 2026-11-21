extends StaticBody2D

func golpear(jugador):
	_afectar_lo_de_arriba()
	if jugador.get("es_grande") == true:
		queue_free()          # Mario grande: se rompe
	else:
		_rebotar()            # Mario chico: solo rebota

func _rebotar():
	var t = create_tween()
	t.tween_property($Sprite2D, "position:y", -4.0, 0.08)
	t.tween_property($Sprite2D, "position:y", 0.0, 0.08)

func _afectar_lo_de_arriba():
	for cuerpo in $ZonaArriba.get_overlapping_bodies():
		if cuerpo.has_method("morir"):
			cuerpo.morir()
