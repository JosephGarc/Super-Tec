extends CanvasLayer
class_name HudSuperTec

## HUD: créditos Eugenio, vidas y efecto activo.
## Lo crea Joshua al iniciar el nivel. Está en el grupo "game" para que
## los créditos Eugenio puedan avisarle (igual que en el proyecto de power-ups).

var coin_count := 0
var _label: Label
var _controller: Node

func _ready() -> void:
	add_to_group("game")
	_label = Label.new()
	_label.position = Vector2(8, 34)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	add_child(_label)
	_actualizar()

func configurar(controller: Node) -> void:
	_controller = controller
	_actualizar()

func collect_coin() -> void:
	coin_count += 1
	_actualizar()

func _process(_delta: float) -> void:
	_actualizar()

func _actualizar() -> void:
	if _label == null:
		return
	var vidas := 0
	var efecto := ""
	if _controller != null:
		vidas = _controller.lives
		match _controller.attack_kind:
			"fire": efecto = "  ·  Malanga picante"
			"ice": efecto = "  ·  Coca helada"
		if _controller.is_invincible:
			efecto += "  ·  Volován"
	_label.text = "Créditos: %d   Vidas: %d%s" % [coin_count, vidas, efecto]
