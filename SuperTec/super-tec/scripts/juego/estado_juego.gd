extends RefCounted

## Datos de la partida que NO se reinician al cambiar de nivel (como en Mario):
## créditos Eugenio y vidas. Son variables estáticas, así que siguen vivas
## aunque se cambie de escena. Se usan con preload (sin autoload).

const VIDAS_INICIALES := 3
## Los créditos y niveles superados se guardan en progreso.gd (estilo Geometry Dash).
const PROGRESO := preload("res://scripts/juego/progreso.gd")
const ARCHIVO_RANKING := "user://ranking.json"

static var creditos := 0
static var vidas := VIDAS_INICIALES
static var nombre_jugador := "Jugador"
static var cargas_lapiz := 0
static var lapiz_poderoso_obtenido := false
static var checkpoint_nivel9 := Vector2.ZERO
static var checkpoint_nivel9_activo := false
static var personaje_seleccionado := "hombre"
static var posicion_overworld := Vector2.ZERO
static var retorno_overworld_habilitado := false
static var partida_iniciada := false
static var niveles_completados: Dictionary = {}
static var _progreso_cargado := false
# Créditos que se tenían al entrar al nivel actual (para el game over)
static var creditos_inicio_nivel := 0
static var _cronometro_activo := false
static var _cronometro_inicio_msec := 0
static var _tiempo_final_segundos := 0.0
static var _nivel_cronometro := 0
static var _ranking_cache: Array = []
static var _ranking_cargado := false


## Partida nueva (se llama desde el selector de niveles)
static func reiniciar() -> void:
	creditos = 0
	vidas = VIDAS_INICIALES
	cargas_lapiz = 0
	lapiz_poderoso_obtenido = false
	checkpoint_nivel9 = Vector2.ZERO
	checkpoint_nivel9_activo = false
	creditos_inicio_nivel = 0
	posicion_overworld = Vector2.ZERO
	retorno_overworld_habilitado = false
	_cronometro_activo = false
	_tiempo_final_segundos = 0.0
	_nivel_cronometro = 0
	partida_iniciada = true


## Pausa (menú de ajustes): el tiempo en pausa no cuenta
static var _pausa_msec := -1

static func pausar_cronometro() -> void:
	if _cronometro_activo and _pausa_msec < 0:
		_pausa_msec = Time.get_ticks_msec()


static func reanudar_cronometro() -> void:
	if _pausa_msec >= 0:
		_cronometro_inicio_msec += Time.get_ticks_msec() - _pausa_msec
		_pausa_msec = -1


static func iniciar_cronometro(numero_nivel: int = 0) -> void:
	_pausa_msec = -1
	_tiempo_final_segundos = 0.0
	_nivel_cronometro = numero_nivel
	_cronometro_inicio_msec = Time.get_ticks_msec()
	_cronometro_activo = true


static func asegurar_cronometro(numero_nivel: int = 0) -> void:
	if not _cronometro_activo or _nivel_cronometro != numero_nivel:
		iniciar_cronometro(numero_nivel)


static func tiempo_transcurrido() -> float:
	if _cronometro_activo:
		return float((_pausa_msec if _pausa_msec >= 0 else Time.get_ticks_msec()) - _cronometro_inicio_msec) / 1000.0
	return _tiempo_final_segundos


static func detener_cronometro() -> float:
	_tiempo_final_segundos = tiempo_transcurrido()
	_cronometro_activo = false
	return _tiempo_final_segundos


static func tiempo_final_segundos() -> float:
	return _tiempo_final_segundos


static func nivel_cronometro() -> int:
	return _nivel_cronometro


static func cronometro_formateado() -> String:
	return formatear_tiempo(tiempo_transcurrido())


static func formatear_tiempo(segundos: float) -> String:
	var total_ms := maxi(roundi(segundos * 1000.0), 0)
	var minutos := floori(float(total_ms) / 60000.0)
	var segundos_enteros := floori(float(total_ms) / 1000.0) % 60
	var centesimas := floori(float(total_ms) / 10.0) % 100
	return "%02d:%02d.%02d" % [minutos, segundos_enteros, centesimas]


static func registrar_tiempo_nivel(numero_nivel: int) -> Dictionary:
	var total_ms := maxi(roundi(detener_cronometro() * 1000.0), 0)
	cargar_ranking()
	var registro := {
		"nivel": numero_nivel,
		"nombre": nombre_jugador.strip_edges() if not nombre_jugador.strip_edges().is_empty() else "Jugador",
		"personaje": "Mujer" if personaje_seleccionado == "mujer" else "Hombre",
		"tiempo_ms": total_ms,
		"tiempo": formatear_tiempo(float(total_ms) / 1000.0),
	}
	var indice_existente := -1
	for indice in _ranking_cache.size():
		if int(_ranking_cache[indice].get("nivel", 9)) == numero_nivel:
			indice_existente = indice
			break
	if indice_existente < 0:
		_ranking_cache.append(registro)
	elif total_ms < int(_ranking_cache[indice_existente].get("tiempo_ms", 0)):
		_ranking_cache[indice_existente] = registro
	_ranking_cache.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("nivel", 0)) < int(b.get("nivel", 0))
	)
	_guardar_ranking()
	for guardado in _ranking_cache:
		if int(guardado.get("nivel", 9)) == numero_nivel:
			return guardado
	return registro


static func registrar_tiempo_final() -> Dictionary:
	return registrar_tiempo_nivel(9)


static func obtener_ranking() -> Array:
	cargar_ranking()
	return _ranking_cache.duplicate(true)


static func cargar_ranking() -> void:
	if _ranking_cargado:
		return
	_ranking_cargado = true
	if not FileAccess.file_exists(ARCHIVO_RANKING):
		return
	var archivo := FileAccess.open(ARCHIVO_RANKING, FileAccess.READ)
	if archivo == null:
		push_warning("No se pudo leer el ranking local.")
		return
	var json := JSON.new()
	if json.parse(archivo.get_as_text()) != OK or not (json.data is Array):
		push_warning("El archivo de ranking no tiene un formato válido.")
		return
	_ranking_cache.clear()
	for dato in json.data:
		if dato is Dictionary and dato.has("tiempo_ms"):
			var copia: Dictionary = dato.duplicate(true)
			if not copia.has("nivel"):
				copia["nivel"] = 9
			_ranking_cache.append(copia)
	_ranking_cache.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("nivel", 0)) < int(b.get("nivel", 0))
	)


static func _guardar_ranking() -> void:
	var archivo := FileAccess.open(ARCHIVO_RANKING, FileAccess.WRITE)
	if archivo == null:
		push_warning("No se pudo guardar user://ranking.json")
		return
	archivo.store_string(JSON.stringify(_ranking_cache, "\t"))


## Se llama al empezar un nivel
static func empezar_nivel() -> void:
	creditos_inicio_nivel = creditos


# Niveles superados: ahora los lleva progreso.gd (junto con los créditos de cada nivel)
static func cargar_progreso() -> void:
	PROGRESO.cargar()


static func nivel_completado(numero: int) -> bool:
	return PROGRESO.superado(numero)


## Se llama al llegar a la meta (o al vencer al jefe del Nivel 9):
## guarda los créditos conseguidos y marca el nivel como superado.
static func marcar_nivel_completado(numero: int) -> void:
	if numero < 1 or numero > 9:
		return
	if PROGRESO.nivel_actual != numero:
		PROGRESO.nivel_actual = numero
	PROGRESO.completar_nivel()


## Sin vidas: se repite el nivel con 3 vidas.
## Los créditos del intento se pierden; los ya guardados se quedan.
static func game_over() -> void:
	vidas = VIDAS_INICIALES
	creditos = creditos_inicio_nivel
	PROGRESO.reiniciar_intento()
