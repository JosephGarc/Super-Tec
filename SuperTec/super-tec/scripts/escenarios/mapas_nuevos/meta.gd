extends Area2D

const SONIDO := preload("res://scripts/juego/sonido.gd")
const ESTADO := preload("res://scripts/juego/estado_juego.gd")
const NIVEL_COMPLETADO_SCRIPT := preload("res://scripts/ui/nivel_completado.gd")
const OVERWORLD_PATH := "res://escenas/overworld_super_tec.tscn"

@export_file("*.tscn") var siguiente_nivel: String
var _transicionando := false
var _brillo: PointLight2D
var _indicador: Polygon2D
var _animacion_brillo: Tween

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_crear_brillo_meta()

func _crear_brillo_meta() -> void:
	var gradiente := Gradient.new()
	gradiente.colors = [Color(1.0, 0.86, 0.45, 0.46), Color(1.0, 0.76, 0.3, 0.0)]
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.width = 96
	textura.height = 96
	textura.fill = GradientTexture2D.FILL_RADIAL
	_brillo = PointLight2D.new()
	_brillo.name = "BrilloMeta"
	_brillo.texture = textura
	_brillo.energy = 0.3
	_brillo.texture_scale = 0.5
	_brillo.color = Color("#ffe38c")
	add_child(_brillo)
	_indicador = Polygon2D.new()
	_indicador.name = "IndicadorMeta"
	_indicador.polygon = PackedVector2Array([
		Vector2(0, -14), Vector2(9, 0), Vector2(0, 14), Vector2(-9, 0)
	])
	_indicador.color = Color("#ffe38c")
	_indicador.z_index = 2
	add_child(_indicador)
	_animacion_brillo = create_tween().set_loops()
	_animacion_brillo.tween_property(_brillo, "energy", 0.58, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_animacion_brillo.tween_property(_brillo, "energy", 0.3, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_animacion_brillo.parallel().tween_property(_indicador, "position:y", -4.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_animacion_brillo.tween_property(_indicador, "position:y", 0.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body: Node2D) -> void:
	if _transicionando or not body.is_in_group("jugador"):
		return
	var escena_actual := get_tree().current_scene
	if _obtener_numero_nivel(escena_actual) == 9 and not get_tree().get_nodes_in_group("jefe_tesis").is_empty():
		return
	_transicionando = true
	SONIDO.efecto("nivel_completado")
	call_deferred("_avanzar_nivel")

func _avanzar_nivel() -> void:
	var escena_actual := get_tree().current_scene
	var numero_nivel := _obtener_numero_nivel(escena_actual)
	if numero_nivel == 9 and not get_tree().get_nodes_in_group("jefe_tesis").is_empty():
		_transicionando = false
		return
	ESTADO.marcar_nivel_completado(numero_nivel)
	if numero_nivel >= 1 and numero_nivel <= 9:
		ESTADO.registrar_tiempo_nivel(numero_nivel)
	if escena_actual == null:
		var error_sin_escena := get_tree().change_scene_to_file(OVERWORLD_PATH)
		if error_sin_escena != OK:
			_transicionando = false
			push_error("No hay una escena activa ni se pudo abrir el overworld.")
		return
	var siguiente := siguiente_nivel if ResourceLoader.exists(siguiente_nivel, "PackedScene") and siguiente_nivel != OVERWORLD_PATH else ""
	var aviso := NIVEL_COMPLETADO_SCRIPT.new()
	aviso.configurar(numero_nivel, siguiente)
	escena_actual.add_child(aviso)


func _obtener_numero_nivel(escena: Node) -> int:
	if escena == null:
		return 0
	var ruta := escena.scene_file_path.get_file().get_basename()
	if ruta.begins_with("nivel_"):
		var sufijo := ruta.trim_prefix("nivel_")
		if sufijo.is_valid_int():
			return sufijo.to_int()
	for propiedad in escena.get_property_list():
		if propiedad.get("name", "") == "nombre_nivel":
			var nombre := str(escena.get("nombre_nivel"))
			if nombre.begins_with("Nivel "):
				var sufijo := nombre.get_slice(" ", 1)
				if sufijo.is_valid_int():
					return sufijo.to_int()
	return 0
