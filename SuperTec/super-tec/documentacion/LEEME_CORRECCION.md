# Escenario SuperTec: corrección de personaje

Este es el proyecto que se ejecuta con F5. La escena principal es `escenas/escenario.tscn`.

## Cambios

- Joshua ahora usa `AnimatedSprite2D` con los spritesheets `idle.png`, `walk.png` y `jump.png`.
- Se agregaron animaciones de reposo, caminar, salto y caída.
- Se quitó el giro vertical accidental y se dejó una escala uniforme de 0.068 en las tres escenas.
- Controles: A/D para moverse y W para saltar.

## Abrir

En Godot, importa o abre este archivo `../project.godot` y presiona F5.

El ZIP recibido contiene las escenas y sprites de Joshua, pero no trae los archivos del personaje femenino dentro del proyecto principal; por eso esta corrección solo cubre a Joshua.
Al caer por debajo del mapa, el personaje vuelve a su posición inicial, con la velocidad reiniciada y sin perder vidas.

La pendiente de scenario3.tscn usa colisiones inclinadas; el personaje admite pendientes de hasta 65 grados y mantiene contacto al caminar.
