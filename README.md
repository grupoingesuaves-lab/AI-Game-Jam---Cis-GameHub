# UMBRAL — correccion de carga de imagenes

Proyecto completo basado en el primer commit con la capa visual del monstruo.

## Qué se reparó
- `scripts/ui/renderer.gd`: se quitaron los `preload()` de 20 PNG que provocaban los errores de parseo antes de terminar la importación.
- `scripts/monster/monster_overlay.gd`: mantiene la carga directa de PNG de la entrega anterior, solo para las cuatro imágenes necesarias del monstruo.

En la correccion original de las imagenes no se cambiaron sprites, fondos, físicas, vidas, puzzles ni el arte del proyecto. Los cambios de turnos y tiempo de esta entrega se describen al final. La imagen del monstruo sigue en un único lado, el del jugador activo, con acercamiento gradual por tiempo y vidas perdidas.

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


## Nuevo sistema de turnos y tiempo (30 segundos)

- El tiempo base de **parkour** pasa de 120 a **30 segundos**. Los puzzles mantienen sus 60 segundos.
- **Ronda 1:** J1 abre (30 s), registra su tiempo de parkour; J2 hace el mismo nivel con ese limite.
- **Ronda 2:** J2 abre (30 s), registra su tiempo; J1 hace el mismo nivel con ese limite.
- **Rondas posteriores:** el jugador que fue segundo inicia la siguiente ronda, alternando ambos.
- El registro se obtiene al terminar el parkour, antes del puzzle, como en el juego original.
- Si el primero no termina el parkour, el segundo dispone de 30 s. Los reintentos del primero vuelven a medir desde cero.
- Se conservan las vidas, los reintentos, los acertijos diferentes, las animaciones de eliminacion y la musica solo durante parkour.
- Si un jugador queda definitivamente eliminado, se omite su turno y el superviviente sigue con 30 s de limite base por ronda.

### Probar en PowerShell (en la carpeta que contiene project.godot)

```powershell
godot --headless --editor --path . --import
godot --path .
```


## Mordisco dentro de la ventana y muerte definitiva

- Si un jugador pierde una vida, el mordisco se dibuja **solo dentro del vidrio** de su ventana (se recorta en los bordes del rectangulo superior).
- Si pierde la ultima vida, **no hay salida lateral** del monstruo: el mordisco crece, atraviesa el marco y cubre parte del nivel de ese jugador, sin invadir el panel del rival.
- Despues se reproduce el cierre de **6 fotogramas de tentaculos** de la imagen facilitada, con fondo transparente y oscurecimiento progresivo de toda la pantalla.
- El cierre termina en una pantalla negra con el texto `ELIMINADO` y despues continua automaticamente el flujo de turnos que ya tenia UMBRAL.
- Se preservan musica, 30 segundos, turnos alternos, puzzles, sprites y reglas.

### Archivos modificados

- `scripts/monster/life_loss_overlay.gd`: recorte del mordisco normal y mordisco final ampliado.
- `scripts/monster/monster_overlay.gd`: elimina SOLO la salida lateral durante la muerte definitiva.
- `scripts/main.gd`: agrega una etapa visual entre mordisco y pantalla negra.
- `scripts/ui/renderer.gd`: mueve el cartel negro a la etapa final.
- `scenes/main.tscn`: incorpora la nueva capa de cierre.

### Archivos nuevos

- `scripts/monster/death_close_overlay.gd`
- `assets/monster/death_close/close_0.png` a `close_5.png`

Los archivos originales de otros sistemas no se modificaron.


## Ajuste: efectos solamente en la ventana del jugador que pierde

- Mordisco normal y mortal: recortados al vidrio real de su lado.
- El mordisco definitivo **no** atraviesa ni el marco ni el area de parkour.
- Cierre de tentaculos: solamente dentro del vidrio del jugador eliminado.
- La fase negra final y el texto ELIMINADO se muestran en ese mismo vidrio.
- La ventana del otro jugador y la zona inferior quedan visibles.
- No se han modificado turnos, puntajes, fisicas, cronometros, musica ni sprites.
- Scripts modificados exclusivamente: `scripts/monster/life_loss_overlay.gd`,
  `scripts/monster/death_close_overlay.gd`, `scripts/ui/renderer.gd`.


## Ajuste visual (mordisco + tentaculos en panel superior)

- Cuando un jugador pierde una vida, la animacion habitual del monstruo se oculta mientras se reproduce el mordisco. Al terminar, vuelve automaticamente.
- **El mordisco sigue limitado al vidrio interior del jugador afectado**, igual que en la version anterior.
- Si esa era su ultima vida, tras el mordisco se reproduce el cierre de tentaculos en **toda la seccion superior de su panel: 768 x 450 px**, desde el borde superior hasta la separacion con el parkour.
- El oscurecimiento final y el texto ELIMINADO cubren esa misma seccion superior.
- En ningun momento los efectos de cierre invaden el panel del otro jugador.
- Se mantuvieron los tiempos (30 segundos), turnos alternos, vida, puzzles, musica, menu y sprites tal cual estaban.
- Archivos de codigo modificados: `scripts/monster/monster_overlay.gd`, `scripts/monster/death_close_overlay.gd`, `scripts/ui/renderer.gd`.



## NUEVO: MENU DE VICTORIA AL TERMINAR EL NIVEL 10

- El juego espera a que ambos jugadores vivos terminen sus turnos del nivel 10.
- Si el otro jugador ya fue eliminado, muestra la victoria cuando el superviviente supera el puzzle final.
- Si un jugador termina el nivel 10 y el otro pierde su ultima vida, primero se completa la animacion de eliminacion y despues aparece la victoria.
- Se compara **solo el numero de vidas restantes**: gana el jugador que conserve mas; si son iguales, **EMPATE**.
- El monstruo se retira durante 0.85 s antes de abrir el menu final.
- El menu permite **VOLVER A JUGAR** o **SALIR**: flechas (o W/S), ENTER/ESPACIO para elegir, ESC para salir.
- Si nadie supera el ultimo nivel, se mantiene el final de partida anterior sin anunciar una victoria inexistente.
- Los cronometros y el parkour permanecen congelados durante la transicion y el menu.
- Se cambiaron solo `scripts/main.gd`, `scripts/ui/renderer.gd` y `scripts/monster/monster_overlay.gd`; no se modificaron los recursos ni las otras animaciones.

## Enlace al video:

https://drive.google.com/drive/folders/1lXUlMvMAuSTV0pSZNp56d0taOreuak5g?usp=sharing
