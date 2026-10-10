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
