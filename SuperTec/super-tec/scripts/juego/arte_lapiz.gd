extends RefCounted

const RUTA := "res://assets/Lapiz.png"
static var _cache: Texture2D
static var _estados_cache: Dictionary = {}

static func obtener_textura() -> Texture2D:
	if _cache != null:
		return _cache
	if ResourceLoader.exists(RUTA):
		var fuente := load(RUTA) as Texture2D
		if fuente != null:
			var imagen := fuente.get_image()
			if imagen != null and not imagen.is_empty():
				imagen.convert(Image.FORMAT_RGBA8)
				_quitar_blanco_exterior(imagen)
				# El PNG contiene una hoja de varios estados. Para HUD y armas usamos
				# el lápiz vertical de la primera fila, aislado sobre alpha transparente.
				var region := imagen.get_region(Rect2i(552, 84, 72, 150))
				_cache = ImageTexture.create_from_image(region)
				_estados_cache["normal"] = ImageTexture.create_from_image(imagen.get_region(Rect2i(962, 814, 155, 155)))
				_estados_cache["descargado"] = ImageTexture.create_from_image(imagen.get_region(Rect2i(1138, 814, 164, 155)))
				_estados_cache["cargado"] = ImageTexture.create_from_image(imagen.get_region(Rect2i(1298, 808, 176, 170)))
				return _cache
	_cache = _crear_icono_provisional()
	return _cache

static func obtener_icono_estado(estado: String) -> Texture2D:
	if _estados_cache.is_empty():
		obtener_textura()
	return _estados_cache.get(estado, _cache)

static func _quitar_blanco_exterior(imagen: Image) -> void:
	var ancho := imagen.get_width()
	var alto := imagen.get_height()
	var cola := PackedInt32Array()
	cola.resize(ancho * alto)
	var fin := 0
	for x in ancho:
		fin = _encolar_blanco(imagen, cola, fin, x, ancho)
		fin = _encolar_blanco(imagen, cola, fin, (alto - 1) * ancho + x, ancho)
	for y in range(1, alto - 1):
		fin = _encolar_blanco(imagen, cola, fin, y * ancho, ancho)
		fin = _encolar_blanco(imagen, cola, fin, y * ancho + ancho - 1, ancho)
	var actual := 0
	while actual < fin:
		var indice := cola[actual]
		actual += 1
		var x := indice % ancho
		var y := floori(float(indice) / ancho)
		if x > 0:
			fin = _encolar_blanco(imagen, cola, fin, indice - 1, ancho)
		if x + 1 < ancho:
			fin = _encolar_blanco(imagen, cola, fin, indice + 1, ancho)
		if y > 0:
			fin = _encolar_blanco(imagen, cola, fin, indice - ancho, ancho)
		if y + 1 < alto:
			fin = _encolar_blanco(imagen, cola, fin, indice + ancho, ancho)

static func _encolar_blanco(imagen: Image, cola: PackedInt32Array, fin: int, indice: int, ancho: int) -> int:
	var pixel := imagen.get_pixel(indice % ancho, floori(float(indice) / ancho))
	if pixel.a > 0.0 and pixel.r > 0.96 and pixel.g > 0.96 and pixel.b > 0.96:
		imagen.set_pixel(indice % ancho, floori(float(indice) / ancho), Color(1, 1, 1, 0))
		cola[fin] = indice
		return fin + 1
	return fin

static func _crear_icono_provisional() -> Texture2D:
	var imagen := Image.create(32, 8, false, Image.FORMAT_RGBA8)
	imagen.fill(Color(0, 0, 0, 0))
	for y in range(1, 7):
		for x in range(4, 28):
			imagen.set_pixel(x, y, Color("#292b36") if y == 1 or y == 6 else Color("#f3ca3e"))
	for y in range(2, 6):
		imagen.set_pixel(5, y, Color("#fff0a0"))
		imagen.set_pixel(2, y, Color("#e985a5"))
		imagen.set_pixel(3, y, Color("#e985a5"))
	for y in range(3, 5):
		imagen.set_pixel(29, y, Color("#292b36"))
	return ImageTexture.create_from_image(imagen)
