# Super-Tec: contenido del juego

## Proyecto principal

`project.godot` es la entrada del juego que estamos armando. Sus recursos activos están organizados así:

- `escenas/`: tres mapas Godot (`escenario.tscn`, `escenario2.tscn`, `escenario3.tscn`).
- `assets/escenarios/`: tileset del campus y su imagen de vista previa.
- `assets/personajes/`: sprites y hojas de animación.
- `assets/ui/`: icono del proyecto.
- `scripts/`: movimiento del jugador y lógica de personajes.
- `personajes-juegos/personaje.tscn`: escena de personaje independiente que ya estaba en el proyecto principal.

## Proyectos de origen conservados

`proyectos_fuente/escenarios/` y `proyectos_fuente/personajes/` son proyectos Godot independientes que llegaron anidados. Se conservan completos como referencia; sus escenas no pertenecen todavía al proyecto principal. Las rutas `res://` de cada proyecto siguen siendo relativas a su propio `project.godot`.

## Personajes y recursos identificados

- **Jugador Joshua**: `Joshua.tscn`, con script propio y animaciones construidas desde `idle.png`, `jump.png` y `walk.png`.
- **Perro enemigo**: `Perro.tscn`, con script propio y hoja de animación `walk_galleta.png`.
- **Personaje del proyecto principal**: `personaje.tscn`, una escena sencilla que usa `idle.png`.
- **Sprites adicionales**: `walk galleta.png` y `walk_galleta.png` son archivos distintos; se mantienen ambos hasta decidir cuál se integra.

## Mapas identificados

El proyecto principal contiene tres escenas de mapa: `escenas/escenario.tscn`, `escenas/escenario2.tscn` y `escenas/escenario3.tscn`. Las escenas del proyecto fuente `proyectos_fuente/escenarios/` son otras tres variantes basadas en el mismo tileset del campus. Aún no están combinadas entre sí.

## Power-ups

- `assets/powerups/`: imágenes ordenadas de Azulito, Coca helada, Crédito Eugenio, Malanga de fuego, Malanga picante, Taco, Tapa helada y Volován.
- `proyectos_fuente/powerups/`: proyecto Godot original completo de Joshua y los power-ups, conservado de forma independiente con sus escenas, scripts y configuración. Su `LEEME.md` documenta controles y comportamiento de prueba.

## Funciones en preparación en el proyecto principal

- W o flecha arriba hacen saltar a Joshua. Espacio lanza una bolita roja tras recoger Malanga de fuego; elimina enemigos del grupo `enemies` y rompe la celda de `TileMapLayer` que golpea.
- Joshua inicia al 50 % de su escala actual. Azulito lo devuelve a la escala actual original.
- Azulito y Malanga de fuego están puestos temporalmente cerca del inicio de `escenario.tscn` para poder probarlos. Los power-ups se ajustan a un tamaño visible uniforme, cercano a la mitad de Joshua; las bolas son más pequeñas. Sus escenas reutilizables y la de la bola están en `escenas/powerups/`.
- Galleta está puesta en tres zonas de `escenario.tscn`: Galleta 1 junto a las bancas, Galleta 2 en la misma plataforma de madera donde está Joshua en la captura y Galleta 3 en la plataforma izquierda del último tramo. Sus nombres en el árbol de escena las identifican y cada una tiene un rango de patrulla. El contacto lateral devuelve a Joshua al inicio; si cae encima de Galleta, la elimina y rebota.
- El crédito Eugenio y su colocación quedan pendientes para definirlos junto con la ubicación del enemigo.

## Recursos nuevos integrados

- **Mapas:** cuatro escenas nuevas (`nivel_1.tscn` a `nivel_4.tscn`) en `escenas/mapas_nuevos/`. Sus tilesets e imágenes están en `assets/escenarios/mapas_nuevos/`; los bloques y scripts de soporte están en `escenas/bloques/mapas_nuevos/` y `scripts/`.
- **Personajes:** Joshua, Perro y la escena de demostración están en `escenas/personajes_juegos/`; sus scripts están en `scripts/personajes_juegos/`. Reutilizan sprites ya presentes en `assets/personajes/`.
- **Fuentes:** se conservaron los proyectos originales en `proyectos_fuente/mapas_nuevos/` y `proyectos_fuente/personajes_juegos/`, sin sus cachés generadas `.godot`.

Los cuatro mapas y la demostración de personajes están disponibles como escenas independientes; la escena de inicio del juego no se cambió.
## Enemigos integrados desde `personajes`

Se integraron 16 personajes enemigos en `escenas/enemigos/`, con ataques en `escenas/enemigos/ataques/`, muertes en `escenas/enemigos/muertes/` y sprites en `assets/personajes/enemigos/`. Sus nombres son: Abeja, Basura, Dron, Examen volador, Fantasma graduado, Hielera, Jefe final, Libro, Lobo, Mounstro cables, Multímetro, PC, Rata, Sartén, Villano y William Shakespeare.
## Selector para probar niveles

Al ejecutar el proyecto con F5 aparece un selector con los tres escenarios actuales y los niveles nuevos 1 a 4. Los nuevos niveles colocan a Joshua en `SpawnJugador`; en cada prueba, Esc vuelve al selector. La escena principal anterior sigue disponible como `escenas/escenario.tscn`.