extends RefCounted

## Sonido de Super Tec: efectos y música.
## Se usa sin autoload, con preload:
##     const SONIDO := preload("res://scripts/juego/sonido.gd")
##     SONIDO.efecto("salto")
##     SONIDO.musica("castillo")
##
## Los efectos están en assets/sonido/efectos/ (generados por código, estilo 8 bits).
## La música va en assets/sonido/musica/ con estos nombres (.ogg, .wav o .mp3):
##     menu, campus_dia, campus_noche, castillo, castillo_final, volovan
## Si un archivo de música todavía no existe, simplemente no suena (no truena).

const CARPETA_EFECTOS := "res://assets/sonido/efectos/"
const CARPETA_MUSICA := "res://assets/sonido/musica/"
const EXTENSIONES := ["ogg", "wav", "mp3"]

## Qué música suena en cada nivel (según el tema del mapa)
const MUSICA_POR_NIVEL := {
	1: "campus_dia", 2: "campus_noche", 3: "campus_dia", 4: "campus_dia", 5: "castillo",
	6: "campus_dia", 7: "campus_noche", 8: "castillo", 9: "castillo_final",
}
## Si falta una pista, se intenta con esta otra
const RESPALDO := {"castillo_final": "castillo", "campus_noche": "campus_dia"}

## Ajuste de volumen por efecto (dB), para que todos suenen parejo
const VOLUMEN_EFECTO := {
	"salto": -7.0, "crecer": -6.0, "encoger": -6.0, "aparece_powerup": -6.0, "menu": -6.0,
	"comer_papa": 2.0, "mordida_volovan": 3.0, "mordida_taco": 3.0, "quemar": -2.0,
}
## Volumen de cada pista (dB). La música va más bajita que los efectos.
const VOLUMEN_MUSICA := {"castillo": -13.0, "volovan": -9.0}
const VOLUMEN_MUSICA_BASE := -9.0
## Efectos largos que bajan la música mientras suenan (como los jingles de Mario)
const JINGLES := ["meta", "vida_extra"]

const CANALES_EFECTOS := 8

static var _nodo: Node = null
static var _efectos: Array[AudioStreamPlayer] = []
static var _siguiente := 0
static var _reproductor_musica: AudioStreamPlayer = null
static var _musica_actual := ""
static var _pista_antes_de_volovan := ""
static var _cache := {}


## Toca un efecto por su nombre (archivo en assets/sonido/efectos/)
static func efecto(nombre: String, volumen_db: float = 0.0) -> void:
	var stream := _cargar(CARPETA_EFECTOS + nombre)
	if stream == null:
		return
	_preparar()
	var reproductor := _efectos[_siguiente]
	_siguiente = (_siguiente + 1) % _efectos.size()
	reproductor.stream = stream
	reproductor.volume_db = VOLUMEN_EFECTO.get(nombre, 0.0) + volumen_db
	_reproducir(reproductor)
	if nombre in JINGLES:
		_bajar_musica(stream.get_length())


## Pone una pista de música en loop. Si ya está sonando esa misma, no la reinicia.
static func musica(nombre: String) -> void:
	_preparar()
	if nombre == _musica_actual and _reproductor_musica.playing:
		return
	var stream := _cargar(CARPETA_MUSICA + nombre)
	if stream == null and RESPALDO.has(nombre):
		stream = _cargar(CARPETA_MUSICA + RESPALDO[nombre])
	_musica_actual = nombre
	_reproductor_musica.stop()
	if stream == null:
		return
	_reproductor_musica.stream = stream
	_reproductor_musica.volume_db = _volumen_pista()
	_reproducir(_reproductor_musica)


## Con el volován suena su propia pista; al acabarse regresa la del nivel
static func musica_invencible(activa: bool) -> void:
	if activa and _musica_actual != "volovan":
		_pista_antes_de_volovan = _musica_actual
		musica("volovan")
	elif not activa and _musica_actual == "volovan":
		musica(_pista_antes_de_volovan)


static func musica_nivel(numero: int) -> void:
	musica(MUSICA_POR_NIVEL.get(numero, "campus_dia"))


static func detener_musica() -> void:
	_preparar()
	_musica_actual = ""
	_reproductor_musica.stop()


## Volumen de 0.0 a 1.0 (por si luego hacen un menú de opciones)
static func volumen_musica(lineal: float) -> void:
	_preparar()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Musica"), linear_to_db(maxf(lineal, 0.0001)))


static func volumen_efectos(lineal: float) -> void:
	_preparar()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Efectos"), linear_to_db(maxf(lineal, 0.0001)))


# --- Interno ---

# Crea (una sola vez) el nodo con los reproductores. Cuelga de la raíz,
# así sigue vivo aunque se cambie de nivel y la música no se corta.
static func _preparar() -> void:
	if _nodo != null and is_instance_valid(_nodo):
		return
	_crear_bus("Musica")
	_crear_bus("Efectos")
	_nodo = Node.new()
	_nodo.name = "Sonido"
	_nodo.process_mode = Node.PROCESS_MODE_ALWAYS
	_efectos.clear()
	for i in CANALES_EFECTOS:
		var r := AudioStreamPlayer.new()
		r.bus = "Efectos"
		_nodo.add_child(r)
		_efectos.append(r)
	_reproductor_musica = AudioStreamPlayer.new()
	_reproductor_musica.bus = "Musica"
	_reproductor_musica.finished.connect(func(): _repetir_musica())   # loop para cualquier formato
	_nodo.add_child(_reproductor_musica)
	var arbol := Engine.get_main_loop() as SceneTree
	arbol.root.add_child.call_deferred(_nodo)


static func _crear_bus(nombre: String) -> void:
	if AudioServer.get_bus_index(nombre) != -1:
		return
	AudioServer.add_bus()
	var indice := AudioServer.bus_count - 1
	AudioServer.set_bus_name(indice, nombre)
	AudioServer.set_bus_send(indice, "Master")


# Si el nodo todavía no entra al árbol (se agrega en diferido), se espera
static func _reproducir(reproductor: AudioStreamPlayer) -> void:
	if reproductor.is_inside_tree():
		reproductor.play()
	else:
		reproductor.play.call_deferred()


static func _repetir_musica() -> void:
	if _musica_actual != "":
		_reproductor_musica.play()


static func _bajar_musica(segundos: float) -> void:
	if _reproductor_musica == null or not _reproductor_musica.playing:
		return
	var t := _nodo.create_tween()
	t.tween_property(_reproductor_musica, "volume_db", _volumen_pista() - 18.0, 0.1)
	t.tween_interval(maxf(segundos - 0.2, 0.0))
	t.tween_property(_reproductor_musica, "volume_db", _volumen_pista(), 0.4)


static func _volumen_pista() -> float:
	return VOLUMEN_MUSICA.get(_musica_actual, VOLUMEN_MUSICA_BASE)


# Busca el archivo con cualquier extensión. Si Godot aún no lo importó
# (archivo recién agregado), lo lee directo del disco.
static func _cargar(ruta_sin_extension: String) -> AudioStream:
	if _cache.has(ruta_sin_extension):
		return _cache[ruta_sin_extension]
	var stream: AudioStream = null
	for ext in EXTENSIONES:
		var ruta: String = ruta_sin_extension + "." + ext
		if ResourceLoader.exists(ruta):
			stream = load(ruta)
		elif FileAccess.file_exists(ruta):
			match ext:
				"wav": stream = AudioStreamWAV.load_from_file(ruta)
				"ogg": stream = AudioStreamOggVorbis.load_from_file(ruta)
		if stream != null:
			break
	_cache[ruta_sin_extension] = stream
	return stream
