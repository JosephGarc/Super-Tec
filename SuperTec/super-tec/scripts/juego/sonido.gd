extends RefCounted

## Sonido de Super Tec: efectos y música.
## Se usa sin autoload, con preload:
##     const SONIDO := preload("res://scripts/juego/sonido.gd")
##     SONIDO.efecto("salto")
##     SONIDO.musica("castillo")
##
## Los efectos principales se sintetizan por código; los demás aceptan archivos opcionales.
## La música va en assets/sonido/musica/ con estos nombres (.ogg, .wav o .mp3):
##     menu, campus_dia, campus_noche, castillo, castillo_final, volovan
## Si un archivo de música todavía no existe, simplemente no suena (no truena).

const CARPETA_EFECTOS := "res://assets/sonido/efectos/"
const CARPETA_MUSICA := "res://assets/sonido/musica/"
const EXTENSIONES := ["ogg", "wav", "mp3"]
const CONTROL_SILENCIO := preload("res://scripts/juego/control_silencio.gd")
const PROGRESO := preload("res://scripts/juego/progreso.gd")
## Los power-ups (aparecer, crecer, encoger, coca, malanga, volován y taco)
## usan sus archivos .wav de assets/sonido/efectos/, no el sonido sintetizado.
const EFECTOS_SINTETIZADOS := [
	"salto", "golpe_bloque", "romper", "credito", "meta", "nivel_completado",
	"morir", "danio", "daño",
]
const DURACION_SINTETIZADA := {
	"salto": 0.14, "golpe_bloque": 0.11, "romper": 0.19, "credito": 0.17,
	"meta": 0.52, "nivel_completado": 0.52, "aparece_powerup": 0.2,
	"crecer": 0.2, "tomar_coca": 0.2, "comer_papa": 0.2,
	"mordida_volovan": 0.2, "mordida_taco": 0.2, "morir": 0.26,
	"encoger": 0.2, "danio": 0.26, "daño": 0.26,
}

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
const JINGLES := ["meta", "nivel_completado", "vida_extra"]

const CANALES_EFECTOS := 8

static var _nodo: Node = null
static var _efectos: Array[AudioStreamPlayer] = []
static var _siguiente := 0
static var _reproductor_musica: AudioStreamPlayer = null
static var _musica_actual := ""
static var _pista_antes_de_volovan := ""
static var _tween_bajar: Tween = null
static var _cache := {}


static func inicializar() -> void:
	_preparar()


## Toca un efecto por su nombre (archivo en assets/sonido/efectos/)
static func efecto(nombre: String, volumen_db: float = 0.0) -> void:
	_preparar()
	var reproductor := _efectos[_siguiente]
	_siguiente = (_siguiente + 1) % _efectos.size()
	if nombre in EFECTOS_SINTETIZADOS:
		if reproductor.is_inside_tree():
			_reproducir_sintetizado(reproductor, nombre, volumen_db)
		else:
			reproductor.tree_entered.connect(func(): _reproducir_sintetizado(reproductor, nombre, volumen_db), CONNECT_ONE_SHOT)
		return
	var stream := _cargar(CARPETA_EFECTOS + nombre)
	if stream == null:
		if reproductor.is_inside_tree():
			_reproducir_sintetizado(reproductor, nombre, volumen_db)
		else:
			reproductor.tree_entered.connect(func(): _reproducir_sintetizado(reproductor, nombre, volumen_db), CONNECT_ONE_SHOT)
		return
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
	# Si una canción corta (jingle) estaba bajando la música, se cancela
	# para que no deje la pista nueva en silencio
	if _tween_bajar != null and _tween_bajar.is_valid():
		_tween_bajar.kill()
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
		var pista := _pista_antes_de_volovan
		if pista == "" or pista == "volovan":
			pista = MUSICA_POR_NIVEL.get(PROGRESO.nivel_actual, "campus_dia")
		musica(pista)


static func musica_nivel(numero: int) -> void:
	musica(MUSICA_POR_NIVEL.get(numero, "campus_dia"))


static func detener_musica() -> void:
	_preparar()
	_musica_actual = ""
	_reproductor_musica.stop()


## Volumen de 0.0 a 1.0 (por si luego hacen un menú de opciones)
static func volumen_musica(lineal: float) -> void:
	_preparar()
	CONTROL_SILENCIO.establecer_volumen("Musica", linear_to_db(maxf(lineal, 0.0001)))


static func volumen_efectos(lineal: float) -> void:
	_preparar()
	CONTROL_SILENCIO.establecer_volumen("Efectos", linear_to_db(maxf(lineal, 0.0001)))


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
	var control_silencio := Node.new()
	control_silencio.name = "ControlSilencio"
	control_silencio.set_script(CONTROL_SILENCIO)
	_nodo.add_child(control_silencio)
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


# Los sonidos "bip" se generan una sola vez como WAV y se guardan en caché.
# (Antes se usaba AudioStreamGenerator: esos reproductores se quedaban "sonando"
# para siempre y acababan ocupando todos los canales, y a veces dejaban el juego mudo.)
static var _cache_sintetizados := {}


static func _reproducir_sintetizado(reproductor: AudioStreamPlayer, nombre: String, volumen_db: float = 0.0) -> void:
	var duracion: float = DURACION_SINTETIZADA.get(nombre, 0.12)
	if not _cache_sintetizados.has(nombre):
		_cache_sintetizados[nombre] = _sintetizar(nombre, duracion)
	reproductor.stream = _cache_sintetizados[nombre]
	reproductor.volume_db = VOLUMEN_EFECTO.get(nombre, -2.0) + volumen_db
	_reproducir(reproductor)
	if nombre in JINGLES:
		_bajar_musica(duracion)


static func _sintetizar(nombre: String, duracion: float) -> AudioStreamWAV:
	var mix_rate := 22050
	var cantidad := maxi(1, int(duracion * mix_rate))
	var datos := PackedByteArray()
	datos.resize(cantidad * 2)
	var fase := 0.0
	var notas := PackedFloat32Array([523.25, 659.25, 783.99, 1046.5])
	var frecuencia_inicio := 440.0
	var frecuencia_final := 660.0
	match nombre:
		"salto":
			frecuencia_inicio = 380.0
			frecuencia_final = 880.0
		"golpe_bloque", "romper":
			frecuencia_inicio = 260.0
			frecuencia_final = 135.0
		"meta", "nivel_completado":
			frecuencia_inicio = 523.25
			frecuencia_final = 1046.5
		"morir", "encoger", "danio", "daño":
			frecuencia_inicio = 240.0
			frecuencia_final = 95.0
		"credito", "aparece_powerup", "crecer", "tomar_coca", "comer_papa", "mordida_volovan", "mordida_taco":
			frecuencia_inicio = 620.0
			frecuencia_final = 1040.0
	var duracion_nota := duracion / float(notas.size())
	for i in range(cantidad):
		var tiempo := float(i) / mix_rate
		var progreso := tiempo / duracion
		var frecuencia := lerpf(frecuencia_inicio, frecuencia_final, progreso)
		if nombre == "meta" or nombre == "nivel_completado":
			frecuencia = notas[mini(int(tiempo / duracion_nota), notas.size() - 1)]
		fase = fmod(fase + TAU * frecuencia / mix_rate, TAU)
		var pulso := 0.72 if sin(fase) >= 0.0 else -0.72
		var ataque := minf(tiempo / 0.008, 1.0)
		var salida := minf((duracion - tiempo) / 0.035, 1.0)
		datos.encode_s16(i * 2, int(clampf(pulso * ataque * salida, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = datos
	return wav


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
	if _tween_bajar != null and _tween_bajar.is_valid():
		_tween_bajar.kill()
	var t := _nodo.create_tween()
	t.tween_property(_reproductor_musica, "volume_db", _volumen_pista() - 18.0, 0.1)
	t.tween_interval(maxf(segundos - 0.2, 0.0))
	# al final regresa al volumen de la pista que esté sonando en ese momento
	t.tween_callback(func(): _nodo.create_tween().tween_property(_reproductor_musica, "volume_db", _volumen_pista(), 0.4))
	_tween_bajar = t


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
