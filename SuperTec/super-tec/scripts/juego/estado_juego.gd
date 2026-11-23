extends RefCounted

## Datos de la partida que NO se reinician al cambiar de nivel (como en Mario):
## créditos Eugenio y vidas. Son variables estáticas, así que siguen vivas
## aunque se cambie de escena. Se usan con preload (sin autoload).

const VIDAS_INICIALES := 3

static var creditos := 0
static var vidas := VIDAS_INICIALES
# Créditos que se tenían al entrar al nivel actual (para el game over)
static var creditos_inicio_nivel := 0


## Partida nueva (se llama desde el selector de niveles)
static func reiniciar() -> void:
	creditos = 0
	vidas = VIDAS_INICIALES
	creditos_inicio_nivel = 0


## Se llama al empezar un nivel
static func empezar_nivel() -> void:
	creditos_inicio_nivel = creditos


## Sin vidas: se repite el nivel con 3 vidas y se quitan los créditos
## que se habían juntado en ese nivel (porque vuelven a aparecer).
static func game_over() -> void:
	vidas = VIDAS_INICIALES
	creditos = creditos_inicio_nivel
