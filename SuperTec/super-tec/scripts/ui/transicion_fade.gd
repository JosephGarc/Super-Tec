extends CanvasLayer

@export var duracion := 0.32

var _velo: ColorRect

func _ready() -> void:
	layer = 100
	_velo = ColorRect.new()
	_velo.color = Color.BLACK
	_velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_velo)

func fade_in() -> void:
	_velo.color.a = 1.0
	var tween := create_tween()
	tween.tween_property(_velo, "color:a", 0.0, duracion).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	queue_free()

func fade_out() -> void:
	_velo.color.a = 0.0
	var tween := create_tween()
	tween.tween_property(_velo, "color:a", 1.0, duracion).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
