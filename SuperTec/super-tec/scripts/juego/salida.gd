extends RefCounted
## Cierra el juego sin que el proceso se quede trabado.
## En pantalla completa (con D3D12) Windows a veces no deja terminar el proceso,
## así que primero se regresa a ventana y luego se cierra.
##     const SALIDA := preload("res://scripts/juego/salida.gd")
##     SALIDA.salir()

static var _saliendo := false


static func salir() -> void:
	if _saliendo:
		return
	_saliendo = true
	var arbol := Engine.get_main_loop() as SceneTree
	var modo := DisplayServer.window_get_mode()
	if modo == DisplayServer.WINDOW_MODE_FULLSCREEN or modo == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	# Se deja pasar unos cuadros antes de cerrar (cerrar dentro del clic del botón
	# es lo que dejaba el proceso trabado)
	for i in 3:
		await arbol.process_frame
	arbol.quit()
