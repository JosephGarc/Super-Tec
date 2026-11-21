extends StaticBody2D

@export var contenido: PackedScene   # Por defecto suelta el azulito (se asigna en bloque_pregunta.tscn)
var usado := false

func golpear(_jugador):
	if usado:
		return
	usado = true
	$Sprite2D.modulate = Color(0.5, 0.5, 0.5)   # se oscurece = ya usado
	for cuerpo in $ZonaArriba.get_overlapping_bodies():
		if cuerpo.has_method("morir"):
			cuerpo.morir()
	var t = create_tween()
	t.tween_property($Sprite2D, "position:y", -4.0, 0.08)
	t.tween_property($Sprite2D, "position:y", 0.0, 0.08)
	if contenido:
		var item = contenido.instantiate()
		# position (no global_position): el bloque es hijo del TileMapLayer,
		# así el power-up queda justo encima del bloque
		item.position = position + Vector2(0, -16)
		get_parent().add_child.call_deferred(item)
