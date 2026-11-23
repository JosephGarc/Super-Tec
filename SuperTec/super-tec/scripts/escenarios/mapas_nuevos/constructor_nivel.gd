@tool
extends Node
## Construye un nivel a partir de un mapa de texto (.txt).
## Líneas de cabecera del mapa:
##   tema=dia_campus | noche_campus | dia_fotos | noche_fotos | dia_mixto | castillo
##   deco=nombre,columna,fila_base     (edificios, autos, árboles... ver DECOS)
## Leyenda del mapa:
##   .  vacío            G  superficie         D  relleno         C  camino / piedra
##   S  bloque duro      P  plataforma         F  reja (plataforma)
##   B  ladrillo rompible (escena)   ?  bloque ? (escena)
##   R  ladrillo sorpresa (escena: parece ladrillo, suelta un power-up)
##   $  bloque ? de crédito (escena: suelta un crédito Eugenio; el ? normal suelta azulito)
##   L  lava (superficie)   l  lava (relleno)   -> SIN colisión, matan con la ZonaMuerte
##   J  inicio del jugador   E  enemigo (Marker2D)   M  meta

@export_tool_button("Construir nivel", "Play") var boton_construir = construir
@export_tool_button("Borrar nivel", "Remove") var boton_borrar = borrar

@export_file("*.txt") var archivo_mapa: String

@export_group("Capas")
@export var suelo: TileMapLayer
@export var bloques: TileMapLayer
## Capa de decoración sin colisión. Si la dejas vacía, se crea sola ("Fondo").
@export var fondo: TileMapLayer

@export_group("IDs de las fuentes del TileSet")
## ID de la fuente campus_tileset_817x941.png
@export var fuente_campus := 0
## ID de la fuente campus_tileset_fotos.png
@export var fuente_fotos := 3
## ID de la Colección de Escenas
@export var fuente_escenas := 1
## Deben coincidir con los ids de campus_tileset.tres (scenes/1, scenes/2, scenes/3)
@export var id_ladrillo := 1
@export var id_pregunta := 2
@export var id_ladrillo_sorpresa := 3
@export var id_pregunta_credito := 4

@export_group("Zona de muerte")
## Altura (centro) de la zona de muerte. 240 = mata al caer en un hueco o en la lava.
@export var altura_zona_muerte := 240.0

const TILE := 16

## letra -> [fuente ("campus" o "fotos"), coordenadas en el atlas]
const TEMAS := {
	"dia_campus": {"G": ["campus", Vector2i(0, 0)], "D": ["campus", Vector2i(0, 1)], "S": ["campus", Vector2i(0, 32)], "P": ["campus", Vector2i(6, 32)], "C": ["campus", Vector2i(4, 0)], "F": ["campus", Vector2i(0, 10)], "L": ["fotos", Vector2i(8, 1)], "l": ["fotos", Vector2i(9, 1)]},
	"noche_campus": {"G": ["campus", Vector2i(0, 16)], "D": ["campus", Vector2i(0, 17)], "S": ["campus", Vector2i(12, 21)], "P": ["campus", Vector2i(21, 16)], "C": ["campus", Vector2i(4, 16)], "F": ["campus", Vector2i(0, 26)], "L": ["fotos", Vector2i(8, 31)], "l": ["fotos", Vector2i(9, 31)]},
	"dia_fotos": {"G": ["fotos", Vector2i(4, 0)], "D": ["fotos", Vector2i(5, 0)], "S": ["fotos", Vector2i(11, 1)], "P": ["fotos", Vector2i(13, 0)], "C": ["fotos", Vector2i(0, 0)], "F": ["campus", Vector2i(0, 10)], "L": ["fotos", Vector2i(8, 1)], "l": ["fotos", Vector2i(9, 1)]},
	"noche_fotos": {"G": ["fotos", Vector2i(4, 30)], "D": ["fotos", Vector2i(5, 30)], "S": ["fotos", Vector2i(11, 31)], "P": ["fotos", Vector2i(13, 30)], "C": ["fotos", Vector2i(0, 30)], "F": ["campus", Vector2i(0, 26)], "L": ["fotos", Vector2i(8, 31)], "l": ["fotos", Vector2i(9, 31)]},
	"dia_mixto": {"G": ["fotos", Vector2i(6, 0)], "D": ["fotos", Vector2i(7, 0)], "S": ["fotos", Vector2i(11, 1)], "P": ["fotos", Vector2i(13, 0)], "C": ["fotos", Vector2i(0, 0)], "F": ["campus", Vector2i(0, 10)], "L": ["fotos", Vector2i(8, 1)], "l": ["fotos", Vector2i(9, 1)]},
	"castillo": {"G": ["fotos", Vector2i(10, 31)], "D": ["fotos", Vector2i(10, 31)], "S": ["fotos", Vector2i(11, 31)], "P": ["fotos", Vector2i(10, 30)], "C": ["fotos", Vector2i(10, 31)], "F": ["campus", Vector2i(0, 26)], "L": ["fotos", Vector2i(8, 31)], "l": ["fotos", Vector2i(9, 31)]},
}

## nombre -> [fuente, esquina en el atlas, tamaño en tiles, capa ("fondo" sin colisión / "suelo" sólido)]
const DECOS := {
	"edificio_D": ["campus", Vector2i(0, 36), Vector2i(15, 8), "fondo"],
	"edificio_E": ["campus", Vector2i(15, 36), Vector2i(12, 6), "fondo"],
	"cafeteria": ["campus", Vector2i(27, 36), Vector2i(9, 6), "fondo"],
	"arbol": ["campus", Vector2i(36, 36), Vector2i(5, 5), "fondo"],
	"biblioteca": ["campus", Vector2i(0, 44), Vector2i(12, 5), "fondo"],
	"palmera": ["campus", Vector2i(12, 45), Vector2i(3, 4), "fondo"],
	"nube_grande": ["campus", Vector2i(13, 10), Vector2i(4, 2), "fondo"],
	"nube": ["campus", Vector2i(13, 12), Vector2i(3, 2), "fondo"],
	"arbustos": ["campus", Vector2i(2, 12), Vector2i(6, 2), "fondo"],
	"reja": ["campus", Vector2i(0, 10), Vector2i(3, 1), "fondo"],
	"puerta": ["campus", Vector2i(10, 7), Vector2i(2, 2), "fondo"],
	"edificio_D_noche": ["campus", Vector2i(21, 44), Vector2i(15, 8), "fondo"],
	"cafeteria_noche": ["campus", Vector2i(36, 44), Vector2i(9, 6), "fondo"],
	"arbol_noche": ["campus", Vector2i(45, 44), Vector2i(5, 5), "fondo"],
	"nube_grande_noche": ["campus", Vector2i(13, 26), Vector2i(4, 2), "fondo"],
	"nube_noche": ["campus", Vector2i(13, 28), Vector2i(3, 2), "fondo"],
	"arbustos_noche": ["campus", Vector2i(2, 28), Vector2i(6, 2), "fondo"],
	"puerta_noche": ["campus", Vector2i(10, 23), Vector2i(2, 2), "fondo"],
	"edificio_A": ["fotos", Vector2i(0, 13), Vector2i(16, 9), "fondo"],
	"edificio_A_noche": ["fotos", Vector2i(0, 43), Vector2i(16, 9), "fondo"],
	"edificio_B": ["fotos", Vector2i(16, 14), Vector2i(14, 8), "fondo"],
	"edificio_B_noche": ["fotos", Vector2i(16, 44), Vector2i(14, 8), "fondo"],
	"servicio_medico": ["fotos", Vector2i(0, 22), Vector2i(11, 8), "fondo"],
	"servicio_medico_noche": ["fotos", Vector2i(0, 52), Vector2i(11, 8), "fondo"],
	"auditorio": ["fotos", Vector2i(11, 24), Vector2i(12, 6), "fondo"],
	"auditorio_noche": ["fotos", Vector2i(11, 54), Vector2i(12, 6), "fondo"],
	"arbusto_redondo": ["fotos", Vector2i(23, 24), Vector2i(3, 3), "fondo"],
	"arbusto_redondo_noche": ["fotos", Vector2i(23, 54), Vector2i(3, 3), "fondo"],
	"nube_foto": ["fotos", Vector2i(26, 24), Vector2i(3, 2), "fondo"],
	"nube_foto_noche": ["fotos", Vector2i(26, 54), Vector2i(3, 2), "fondo"],
	"edificios_lejanos": ["fotos", Vector2i(21, 3), Vector2i(8, 4), "fondo"],
	"edificios_lejanos_noche": ["fotos", Vector2i(21, 33), Vector2i(8, 4), "fondo"],
	"ficus": ["fotos", Vector2i(0, 7), Vector2i(3, 4), "fondo"],
	"ficus_noche": ["fotos", Vector2i(0, 37), Vector2i(3, 4), "fondo"],
	"pino": ["fotos", Vector2i(3, 7), Vector2i(2, 6), "fondo"],
	"pino_noche": ["fotos", Vector2i(3, 37), Vector2i(2, 6), "fondo"],
	"poste_solar": ["fotos", Vector2i(5, 7), Vector2i(2, 6), "fondo"],
	"poste_solar_noche": ["fotos", Vector2i(5, 37), Vector2i(2, 6), "fondo"],
	"directorio": ["fotos", Vector2i(7, 7), Vector2i(1, 3), "fondo"],
	"directorio_noche": ["fotos", Vector2i(7, 37), Vector2i(1, 3), "fondo"],
	"palmera_foto": ["fotos", Vector2i(8, 7), Vector2i(2, 4), "fondo"],
	"palmera_foto_noche": ["fotos", Vector2i(8, 37), Vector2i(2, 4), "fondo"],
	"cono": ["fotos", Vector2i(0, 1), Vector2i(1, 1), "fondo"],
	"cono_noche": ["fotos", Vector2i(0, 31), Vector2i(1, 1), "fondo"],
	"tambo": ["fotos", Vector2i(1, 1), Vector2i(1, 1), "fondo"],
	"tambo_noche": ["fotos", Vector2i(1, 31), Vector2i(1, 1), "fondo"],
	"agave": ["fotos", Vector2i(4, 1), Vector2i(2, 2), "fondo"],
	"agave_noche": ["fotos", Vector2i(4, 31), Vector2i(2, 2), "fondo"],
	"corazon": ["fotos", Vector2i(6, 1), Vector2i(2, 2), "fondo"],
	"corazon_noche": ["fotos", Vector2i(6, 31), Vector2i(2, 2), "fondo"],
	"letrero_itsx": ["fotos", Vector2i(16, 3), Vector2i(5, 3), "suelo"],
	"letrero_itsx_noche": ["fotos", Vector2i(16, 33), Vector2i(5, 3), "suelo"],
	"auto_rojo": ["fotos", Vector2i(0, 3), Vector2i(4, 2), "suelo"],
	"auto_rojo_noche": ["fotos", Vector2i(0, 33), Vector2i(4, 2), "suelo"],
	"auto_negro": ["fotos", Vector2i(4, 3), Vector2i(4, 2), "suelo"],
	"auto_negro_noche": ["fotos", Vector2i(4, 33), Vector2i(4, 2), "suelo"],
	"camioneta_roja": ["fotos", Vector2i(8, 3), Vector2i(4, 2), "suelo"],
	"camioneta_roja_noche": ["fotos", Vector2i(8, 33), Vector2i(4, 2), "suelo"],
	"auto_gris": ["fotos", Vector2i(12, 3), Vector2i(4, 2), "suelo"],
	"auto_gris_noche": ["fotos", Vector2i(12, 33), Vector2i(4, 2), "suelo"],
}


func construir() -> void:
	if suelo == null or bloques == null:
		push_error("Constructor: asigna las capas Suelo y Bloques en el Inspector.")
		return
	if archivo_mapa == "" or not FileAccess.file_exists(archivo_mapa):
		push_error("Constructor: elige un archivo de mapa (.txt) válido.")
		return

	var raiz: Node = owner if owner else get_parent()
	_asegurar_fondo(raiz)
	borrar()
	suelo.position = Vector2.ZERO
	bloques.position = Vector2.ZERO
	fondo.position = Vector2.ZERO

	var contenedor = _contenedor_enemigos(raiz)
	var lineas := FileAccess.get_file_as_string(archivo_mapa).strip_edges().split("\n")

	var tema := "dia_campus"
	var decos: Array = []
	var filas: Array[String] = []
	for linea in lineas:
		var l := linea.strip_edges()
		if l.begins_with("tema="):
			tema = l.substr(5)
		elif l.begins_with("deco="):
			decos.append(l.substr(5).split(","))
		elif l != "":
			filas.append(l)
	if not TEMAS.has(tema):
		push_error("Constructor: tema desconocido '%s'." % tema)
		return
	var t: Dictionary = TEMAS[tema]

	# decoraciones primero (las de "suelo" quedan debajo de los bloques del mapa)
	for d in decos:
		_poner_deco(d)

	var ancho := 0
	var n_enemigos := 0
	for y in filas.size():
		var fila := filas[y]
		ancho = maxi(ancho, fila.length())
		for x in fila.length():
			var celda := Vector2i(x, y)
			var c := fila[x]
			if t.has(c):
				suelo.set_cell(celda, _fuente(t[c][0]), t[c][1])
			elif c == "B":
				bloques.set_cell(celda, fuente_escenas, Vector2i.ZERO, id_ladrillo)
			elif c == "$":
				bloques.set_cell(celda, fuente_escenas, Vector2i.ZERO, id_pregunta_credito)
			elif c == "R":
				bloques.set_cell(celda, fuente_escenas, Vector2i.ZERO, id_ladrillo_sorpresa)
			elif c == "?":
				bloques.set_cell(celda, fuente_escenas, Vector2i.ZERO, id_pregunta)
			elif c == "J":
				_mover(raiz, "SpawnJugador", _centro(celda))
			elif c == "M":
				_mover(raiz, "Meta", _centro(celda) - Vector2(0, 8))
			elif c == "E":
				n_enemigos += 1
				var m := Marker2D.new()
				m.name = "Enemigo%d" % n_enemigos
				m.position = _centro(celda)
				contenedor.add_child(m)
				m.owner = raiz

	_ajustar_zona_muerte(raiz, ancho * TILE)
	print("Nivel construido (tema %s): %d columnas (%d px), %d enemigos, %d decoraciones." % [tema, ancho, ancho * TILE, n_enemigos, decos.size()])


func borrar() -> void:
	if suelo:
		suelo.clear()
	if bloques:
		bloques.clear()
	if fondo:
		fondo.clear()
	var raiz: Node = owner if owner else get_parent()
	var cont = raiz.find_child("Enemigos", true, false)
	if cont:
		for hijo in cont.get_children():
			hijo.free()


func _fuente(nombre: String) -> int:
	return fuente_campus if nombre == "campus" else fuente_fotos


func _poner_deco(d: PackedStringArray) -> void:
	var nombre := d[0].strip_edges()
	if not DECOS.has(nombre):
		push_warning("Constructor: decoración desconocida '%s'." % nombre)
		return
	var info: Array = DECOS[nombre]
	var fid := _fuente(info[0])
	var origen: Vector2i = info[1]
	var tam: Vector2i = info[2]
	var capa: TileMapLayer = suelo if info[3] == "suelo" else fondo
	var col := int(d[1])
	var base := int(d[2]) if d.size() > 2 else 12
	var fuente_ts = suelo.tile_set.get_source(fid) if suelo.tile_set.has_source(fid) else null
	for j in tam.y:
		for i in tam.x:
			var atlas := origen + Vector2i(i, j)
			if fuente_ts is TileSetAtlasSource and fuente_ts.has_tile(atlas):
				capa.set_cell(Vector2i(col + i, base - tam.y + 1 + j), fid, atlas)


func _asegurar_fondo(raiz: Node) -> void:
	if fondo:
		return
	var existente = raiz.find_child("Fondo", true, false)
	if existente is TileMapLayer:
		fondo = existente
		return
	fondo = TileMapLayer.new()
	fondo.name = "Fondo"
	fondo.tile_set = suelo.tile_set
	fondo.collision_enabled = false
	fondo.z_index = -1
	raiz.add_child(fondo)
	raiz.move_child(fondo, 0)
	fondo.owner = raiz


func _centro(c: Vector2i) -> Vector2:
	return Vector2(c.x * TILE + 8, c.y * TILE + 8)


func _mover(raiz: Node, nombre: String, pos: Vector2) -> void:
	var nodo = raiz.find_child(nombre, true, false)
	if nodo is Node2D:
		nodo.global_position = pos
	else:
		push_warning("Constructor: no encontré el nodo '%s'." % nombre)


func _contenedor_enemigos(raiz: Node) -> Node:
	var cont = raiz.find_child("Enemigos", true, false)
	if cont == null:
		cont = Node2D.new()
		cont.name = "Enemigos"
		raiz.add_child(cont)
		cont.owner = raiz
	return cont


func _ajustar_zona_muerte(raiz: Node, ancho_px: int) -> void:
	var zona = raiz.find_child("ZonaMuerte", true, false)
	if zona == null:
		push_warning("Constructor: no encontré 'ZonaMuerte'.")
		return
	zona.position = Vector2.ZERO
	var forma = zona.get_node_or_null("CollisionShape2D")
	if forma and forma.shape is RectangleShape2D:
		forma.shape.size = Vector2(ancho_px + 200, 48)
		forma.position = Vector2(ancho_px / 2.0, altura_zona_muerte)
