# UMBRAL — correccion de carga de imagenes

Proyecto completo basado en el primer commit con la capa visual del monstruo.

## Qué se reparó
- `scripts/ui/renderer.gd`: se quitaron los `preload()` de 20 PNG que provocaban los errores de parseo antes de terminar la importación.
- `scripts/monster/monster_overlay.gd`: mantiene la carga directa de PNG de la entrega anterior, solo para las cuatro imágenes necesarias del monstruo.

No se cambiaron sprites, fondos, físicas, turnos, vidas, puzzles ni el arte de tu proyecto. La imagen del monstruo sigue en un único lado, el del jugador activo, con acercamiento gradual por tiempo y vidas perdidas.

## Abrir
Descomprime el ZIP, importa `project.godot` en Godot 4 y usa F5. También se incluye el lanzador `JUGAR_UMBRAL.bat`.

## Estado de comprobación
Archivos y PNG comprobados, referencias revisadas. No se ha podido ejecutar el motor de Godot en este entorno, por lo que la prueba final dentro del motor sigue pendiente.


## Menu de inicio
- Se agrego una pantalla de inicio con solo dos opciones: JUGAR y SALIR.
- Controles del menu: flechas arriba/abajo (o W/S) para seleccionar, ENTER/ESPACIO para confirmar, ESC para salir.
- No se modifico la jugabilidad; solo se agrego el menu.


## Nueva secuencia de eliminacion y puzzles del jugador 2

- Al perder su ultima vida, el monstruo sale de la pantalla del jugador eliminado durante 0.75 segundos.
- Despues aparece una pantalla completamente negra con el texto ELIMINADO y el numero de jugador durante 1.40 segundos.
- A continuacion se retoma el flujo de turnos habitual. Ningun temporizador del juego avanza durante la secuencia.
- J1 mantiene los puzzles originales; J2 tiene una secuencia/pregunta/objetivo distinto en las 10 rondas.
- El menu, los sprites, las plataformas, el acercamiento progresivo, las animaciones de espejo y el cambio normal de lado no se alteraron.

Archivos GDScript cambiados: `scripts/main.gd`, `scripts/game/puzzles.gd`, `scripts/ui/renderer.gd` y `scripts/monster/monster_overlay.gd`.


## Correccion de carga de imagenes en Godot

- Los 200 fotogramas del monstruo ahora se cargan primero como `Texture2D` con `ResourceLoader` para evitar la advertencia de `Image.load_from_file` y admitir exportacion.
- El cargador del escenario y menu usa el mismo criterio.
- Se conserva el respaldo de decodificacion de PNG para la primera apertura, cuando todavia no termino la importacion.
- No se cambiaron las reglas, los sprites ni las animaciones.
- Antes de exportar, importa el proyecto con Godot: `godot --headless --editor --path . --import`.

Si Git responde `nothing to commit`, primero hay que copiar los archivos del ZIP
a la carpeta del repositorio; Git no supervisa automaticamente la carpeta Descargas.
