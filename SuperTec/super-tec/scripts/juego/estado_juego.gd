extends RefCounted

## Vidas de la partida: no se reinician al cambiar de nivel (como en Mario).
## Los créditos ahora los guarda scripts/juego/progreso.gd (estilo Geometry Dash).
## Son variables estáticas, así que siguen vivas aunque se cambie de escena.

const VIDAS_INICIALES := 3

static var vidas := VIDAS_INICIALES


## Vidas completas (al empezar partida o al entrar a un nivel desde Continuar)
static func reiniciar() -> void:
	vidas = VIDAS_INICIALES


## Sin vidas: se repite el nivel con 3 vidas.
## Los créditos del intento se pierden; los ya guardados se quedan.
static func game_over() -> void:
	vidas = VIDAS_INICIALES
	preload("res://scripts/juego/progreso.gd").reiniciar_intento()
