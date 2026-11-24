extends RefCounted

## Progreso guardado de la partida (como Geometry Dash):
## - qué niveles ya superaste
## - qué créditos Eugenio de cada nivel ya conseguiste (cada uno por su nombre)
## Si repites un nivel, los créditos que ya tenías salen transparentes ("fantasma")
## y solo cuentan los que te faltaban. Se guarda al llegar a la meta.
## Se usa con preload, sin autoload:
##     const PROGRESO := preload("res://scripts/juego/progreso.gd")

const RUTA := "user://progreso.cfg"
const NIVELES := 9
const CREDITOS_POR_NIVEL := 20
const CREDITOS_TOTALES := NIVELES * CREDITOS_POR_NIVEL   # 180

static var hay_partida := false
static var nivel_actual := 0
static var _superados := {}      # nivel -> true
static var _guardados := {}      # nivel -> PackedStringArray con los ids de créditos
static var _intento := {}        # ids conseguidos en el intento actual (aún no guardados)
static var _cargado := false


# ---------- Partida ----------

static func nueva_partida() -> void:
	_superados.clear()
	_guardados.clear()
	_intento.clear()
	hay_partida = true
	_cargado = true
	guardar()


static func cargar() -> void:
	if _cargado:
		return
	_cargado = true
	var c := ConfigFile.new()
	if c.load(RUTA) != OK:
		return
	hay_partida = c.get_value("partida", "hay_partida", false)
	for n in range(1, NIVELES + 1):
		if c.get_value("superados", str(n), false):
			_superados[n] = true
		_guardados[n] = PackedStringArray(c.get_value("creditos", str(n), PackedStringArray()))


static func guardar() -> void:
	var c := ConfigFile.new()
	c.set_value("partida", "hay_partida", hay_partida)
	for n in range(1, NIVELES + 1):
		c.set_value("superados", str(n), _superados.has(n))
		c.set_value("creditos", str(n), _guardados.get(n, PackedStringArray()))
	c.save(RUTA)


# ---------- Niveles ----------

static func superado(n: int) -> bool:
	cargar()
	return _superados.has(n)


## Se puede jugar si ya lo pasaste o si es el siguiente que te toca
static func desbloqueado(n: int) -> bool:
	cargar()
	return n == 1 or _superados.has(n) or _superados.has(n - 1)


static func empezar_nivel(n: int) -> void:
	cargar()
	nivel_actual = n
	_intento.clear()


## Al perder todas las vidas se pierde lo del intento (no lo guardado)
static func reiniciar_intento() -> void:
	_intento.clear()


## Llegaste a la meta: se guardan los créditos nuevos y el nivel queda superado
static func completar_nivel() -> void:
	cargar()
	if nivel_actual <= 0:
		return
	var lista := PackedStringArray(_guardados.get(nivel_actual, PackedStringArray()))
	for id in _intento:
		if not lista.has(id):
			lista.append(id)
	_guardados[nivel_actual] = lista
	_superados[nivel_actual] = true
	_intento.clear()
	hay_partida = true
	guardar()


# ---------- Créditos ----------

static func agregar_credito(id: String) -> void:
	if id != "":
		_intento[id] = true


## ¿Este crédito ya lo tenías guardado de otra vez? (sale como fantasma)
static func ya_lo_tenia(id: String) -> bool:
	cargar()
	return PackedStringArray(_guardados.get(nivel_actual, PackedStringArray())).has(id)


## Créditos de un nivel (si es el que estás jugando, cuenta también los del intento)
static func creditos_nivel(n: int) -> int:
	cargar()
	var lista := PackedStringArray(_guardados.get(n, PackedStringArray()))
	var cuenta := lista.size()
	if n == nivel_actual:
		for id in _intento:
			if not lista.has(id):
				cuenta += 1
	return mini(cuenta, CREDITOS_POR_NIVEL)


static func total() -> int:
	var suma := 0
	for n in range(1, NIVELES + 1):
		suma += creditos_nivel(n)
	return suma
