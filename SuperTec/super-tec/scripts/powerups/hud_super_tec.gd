extends CanvasLayer
class_name HudSuperTec

## HUD: créditos (con la cara de Eugenio), vidas (corazones) y efecto activo.
## Lo crea Joshua al iniciar el nivel. Está en el grupo "game" para que
## los créditos Eugenio puedan avisarle (igual que en el proyecto de power-ups).

const ESTADO := preload("res://scripts/juego/estado_juego.gd")
const PROGRESO := preload("res://scripts/juego/progreso.gd")
const TEXTURA_CREDITO := preload("res://assets/powerups/credito_eugenio.png")
const ICONOS := {
	"azulito": preload("res://assets/powerups/azulito.png"),
	"coca_helada": preload("res://assets/powerups/coca_helada.png"),
	"malanga_picante": preload("res://assets/powerups/malanga_picante.png"),
	"volovan": preload("res://assets/powerups/volovan.png"),
}
const TAM_ICONO := 30.0
const SEPARACION_ICONOS := 40.0

# Corazón en pixel art (1 = relleno). Cada "pixel" se dibuja de TAM_PIXEL x TAM_PIXEL.
const CORAZON := [
	".XX.XX.",
	"XXXXXXX",
	"XXXXXXX",
	".XXXXX.",
	"..XXX..",
	"...X...",
]
const TAM_PIXEL := 4.0
const SEPARACION_CORAZONES := 34.0
const MAX_CORAZONES := 5   # con más vidas se muestra "x N"
const ROJO := Color("#ff3355")
const SOMBRA := Color(0, 0, 0, 0.55)
const BRILLO := Color("#ffc2cc")

var _controller: Node
var _label_creditos: Label
var _label_nivel: Label
var _corazones: Control
var _label_vidas: Label
var _efectos: Control
var _reloj := 0.0
var _vidas_dibujadas := -1


func _ready() -> void:
	add_to_group("game")

	# Fila 1: cara de Eugenio + número de créditos
	var icono := TextureRect.new()
	icono.texture = TEXTURA_CREDITO
	icono.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono.position = Vector2(8, 36)
	icono.size = Vector2(32, 32)
	add_child(icono)
	_label_creditos = _crear_label(Vector2(46, 36))
	# créditos de este nivel (de 20), chiquito al lado
	_label_nivel = _crear_label(Vector2(140, 44))
	_label_nivel.add_theme_font_size_override("font_size", 16)
	_label_nivel.modulate = Color(1, 1, 1, 0.85)

	# Fila 2: corazones (vidas)
	_corazones = Control.new()
	_corazones.position = Vector2(10, 78)
	_corazones.size = Vector2(SEPARACION_CORAZONES * MAX_CORAZONES, 28)
	_corazones.draw.connect(_dibujar_corazones)
	add_child(_corazones)
	_label_vidas = _crear_label(Vector2(46, 74))

	# Esquina superior derecha: sprites de los power-ups que se están usando (con barra de tiempo)
	_efectos = Control.new()
	_efectos.anchor_left = 1.0
	_efectos.anchor_right = 1.0
	_efectos.offset_left = -(SEPARACION_ICONOS * 4.0 + 8.0)
	_efectos.offset_right = -8.0
	_efectos.offset_top = 10.0
	_efectos.offset_bottom = 10.0 + TAM_ICONO + 10.0
	_efectos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_efectos.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_efectos.draw.connect(_dibujar_efectos)
	add_child(_efectos)
	_actualizar()


func _crear_label(posicion: Vector2) -> Label:
	var label := Label.new()
	label.position = posicion
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	add_child(label)
	return label


func configurar(controller: Node) -> void:
	_controller = controller
	_actualizar()


# Cada crédito tiene su nombre (id). Se apunta en el intento y se guarda al llegar a la meta.
func collect_coin(id: String = "") -> void:
	PROGRESO.agregar_credito(id)
	_actualizar()


func _process(delta: float) -> void:
	_reloj += delta
	_actualizar()


func _vidas() -> int:
	return _controller.lives if _controller != null else ESTADO.vidas


func _actualizar() -> void:
	if _label_creditos == null:
		return
	_label_creditos.text = "x %d" % PROGRESO.total()
	if PROGRESO.nivel_actual > 0:
		_label_nivel.text = "%d/%d" % [PROGRESO.creditos_nivel(PROGRESO.nivel_actual), PROGRESO.CREDITOS_POR_NIVEL]

	var vidas := maxi(_vidas(), 0)
	if vidas != _vidas_dibujadas:
		_vidas_dibujadas = vidas
		_label_vidas.text = "x %d" % vidas if vidas > MAX_CORAZONES else ""
		_corazones.queue_redraw()

	_efectos.queue_redraw()


# Lista de power-ups activos: [id, fracción de tiempo que queda (-1 = sin tiempo)]
func _activos() -> Array:
	var lista := []
	if _controller == null:
		return lista
	if _controller.is_grown:
		lista.append(["azulito", -1.0])
	match _controller.attack_kind:
		"ice": lista.append(["coca_helada", _controller._attack_time_left / _controller.attack_duration])
		"fire": lista.append(["malanga_picante", _controller._attack_time_left / _controller.attack_duration])
	if _controller.is_invincible:
		lista.append(["volovan", _controller._invincibility_time_left / _controller.invincibility_duration])
	return lista


# Se dibujan de derecha a izquierda, pegados a la esquina
func _dibujar_efectos() -> void:
	var x := _efectos.size.x - TAM_ICONO - 3.0
	for activo in _activos():
		var id: String = activo[0]
		var resta: float = activo[1]
		# parpadea cuando le quedan menos de 3 segundos (igual que Joshua)
		var parpadea: bool = _controller.is_effect_near_expiration() and resta >= 0.0 and resta < 0.35 and int(_reloj * 8.0) % 2 == 0
		var textura: Texture2D = ICONOS[id]
		var escala := TAM_ICONO / maxf(textura.get_width(), textura.get_height())
		var tam := Vector2(textura.get_size()) * escala
		var origen := Vector2(x + (TAM_ICONO - tam.x) * 0.5, (TAM_ICONO - tam.y) * 0.5)
		_efectos.draw_rect(Rect2(Vector2(x - 3, -3), Vector2(TAM_ICONO + 6, TAM_ICONO + 6)), Color(0, 0, 0, 0.35))
		_efectos.draw_texture_rect(textura, Rect2(origen, tam), false, Color(1, 1, 1, 0.3 if parpadea else 1.0))
		if resta >= 0.0:
			_efectos.draw_rect(Rect2(Vector2(x, TAM_ICONO + 4), Vector2(TAM_ICONO, 4)), Color(0, 0, 0, 0.6))
			_efectos.draw_rect(Rect2(Vector2(x, TAM_ICONO + 4), Vector2(TAM_ICONO * clampf(resta, 0.0, 1.0), 4)), Color("#ffe27a"))
		x -= SEPARACION_ICONOS


func _dibujar_corazones() -> void:
	var vidas := _vidas_dibujadas
	var cuantos := vidas if vidas <= MAX_CORAZONES else 1
	for i in cuantos:
		_dibujar_corazon(Vector2(i * SEPARACION_CORAZONES, 0))


func _dibujar_corazon(origen: Vector2) -> void:
	for capa in 2:   # 0 = sombra desplazada, 1 = corazón rojo
		var desfase := Vector2(2, 2) if capa == 0 else Vector2.ZERO
		var color := SOMBRA if capa == 0 else ROJO
		for fila in CORAZON.size():
			for col in CORAZON[fila].length():
				if CORAZON[fila][col] == "X":
					_corazones.draw_rect(Rect2(origen + desfase + Vector2(col, fila) * TAM_PIXEL, Vector2(TAM_PIXEL, TAM_PIXEL)), color)
	# brillito
	_corazones.draw_rect(Rect2(origen + Vector2(1, 1) * TAM_PIXEL, Vector2(TAM_PIXEL, TAM_PIXEL)), BRILLO)
