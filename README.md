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


## Musica ambiental durante parkour

- Pista proporcionada por el usuario: `assets/audio/BackSong.mp3` (originalmente `BackSong.mp3.mpeg`), sin modificar el contenido del audio.
- Reproduccion automatica al pulsar JUGAR y comenzar un parkour; se repite mientras dure esa fase.
- No suena durante las preguntas/puzzles, el menu, la pausa, la pantalla ELIMINADO ni el final de partida.
- Se pausa sin perder la posicion al pausar el juego y se reanuda al continuar.
- La tecla `M`, que ya activaba/desactivaba efectos, tambien silencia y reanuda la musica.
- Logica separada en `scripts/audio/background_music.gd` y `BackgroundMusic` en `scenes/main.tscn`: no se modificaron las reglas de juego, los sprites o la animacion del monstruo.
- **Importar antes de ejecutar**: `godot --headless --editor --path . --import` y despues `godot --path .`.


## Corrección de volumen de BackSong
- La música durante el parkour está ahora en +10 dB sobre el archivo original. La pista de origen es silenciosa (pico aproximado −15 dBFS), por lo que el ajuste anterior de −15 dB dejaba el volumen demasiado bajo.
- El reproductor inicia al comenzar el parkour y se detiene en cualquier otra fase o pantalla. Se reanuda desde el inicio del tema al volver al parkour.
- M alterna el sonido. Si no se oye, pulsa M durante el parkour para comprobar que el sonido no haya sido desactivado.
- En Godot: ejecutar el juego, pulsar JUGAR, comprobar sonido durante el parkour, entrar a un puzzle y comprobar el silencio.


## Diagnostico y correccion de musica de fondo (WAV)

- `assets/audio/BackSong.wav`: conversion PCM de 16 bits / 44.1 kHz / estereo del audio original `BackSong.mp3.mpeg`, normalizada para ser audible. Se conserva `BackSong.mp3` como copia de la pista original, sin usarse para reproduccion.
- `scenes/main.tscn`: BackgroundMusic usa BackSong.wav sin subida artificial de +10 dB.
- `scripts/audio/background_music.gd`: loop WAV y activacion exclusiva en modo `playing` + fase `parkour`, respetando la tecla M.
- Menu, acertijos, pausa, transicion ELIMINADO y fin: sin musica. No se modifican las reglas ni los sprites.
- Mensajes de diagnostico en la salida de Godot: `UMBRAL MUSICA: audio WAV cargado`, `UMBRAL MUSICA: INICIADA en parkour`, `UMBRAL MUSICA: DETENIDA`.
- Si se imprime `INICIADA` pero no hay sonido, revisar mezclador de volumen de Windows, dispositivo de salida de Godot, y niveles de audio de Godot (Master).
- IMPORTANTE: descomprimir esta version en una carpeta nueva, abrir esa carpeta concreta y reimportar recursos con `godot --headless --editor --path . --import` antes de ejecutar.
