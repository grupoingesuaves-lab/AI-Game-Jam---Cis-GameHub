extends Node2D
## Capa adicional del monstruo; NO modifica ninguna regla ni sprite original.
## Texturas importadas mediante ResourceLoader para funcionar al exportar.
## Respaldo PNG solo cuando Godot aun no ha terminado de importar.

const STEPS: int = 25
const ANIMATION_FRAMES: int = 4
const PANEL_WIDTH: float = 768.0
const MAX_HEARTS: int = 3
const BASE_PROXIMITY: float = 0.23
const PROXIMITY_PER_LIFE: float = 0.14
const PROXIMITY_PER_SECOND: float = 0.0045
const SMOOTHING_SPEED: float = 0.12
const FADE_IN_SPEED: float = 2.3
# Solo modifica la animacion de cambio de pantalla: no altera el acercamiento.
const TRANSFER_HIDE_DURATION: float = 0.28
const TRANSFER_SHOW_DURATION: float = 0.44
const TRANSFER_SLIDE: float = 42.0
const VICTORY_EXIT_SECONDS: float = 0.85

var game: Node2D
var previous_player: int = -1
var active_seconds: float = 0.0
var proximity: float = BASE_PROXIMITY
var appearance: float = 0.0
var animation_clock: float = 0.0
# Fase 0: seguimiento habitual; 1: se oculta; 2: aparece en el otro lado.
# Nunca se dibuja en ambos lados al mismo tiempo.
var transfer_phase: int = 0
var transfer_elapsed: float = 0.0
var transfer_destination: int = -1

# Solo conservamos las cuatro texturas del paso y lado actuales;
# antes se cargaban 200 imágenes de golpe en _ready().
var loaded_player: int = -1
var loaded_step: int = -1
var loaded_frames: Array[Texture2D] = []

func _ready() -> void:
    game = get_parent() as Node2D
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    queue_redraw()

func _read_png(path: String) -> Texture2D:
    # Godot importa los PNG como texturas. Esta ruta funciona en editor y exportacion.
    if ResourceLoader.exists(path, "Texture2D"):
        var texture: Resource = ResourceLoader.load(path, "Texture2D")
        if texture is Texture2D:
            return texture as Texture2D
    # Respaldo para la primera apertura: evita Image.load_from_file,
    # que muestra advertencias y no sirve para recursos empaquetados.
    if FileAccess.file_exists(path):
        var image: Image = Image.new()
        var error: int = image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
        if error == OK and not image.is_empty():
            return ImageTexture.create_from_image(image)
    push_error("No se pudo cargar la textura del monstruo: " + path)
    return null

func _load_current_animation(player: int, step: int) -> void:
    if player == loaded_player and step == loaded_step:
        return
    loaded_frames.clear()
    var side: String = "l" if player == 0 else "r"
    for frame in range(ANIMATION_FRAMES):
        var path: String = "res://assets/monster/overlays/%s_%02d_%d.png" % [side, step, frame]
        loaded_frames.append(_read_png(path))
    loaded_player = player
    loaded_step = step

func _process(delta: float) -> void:
    if game == null:
        return
    # Cuando se elimina un jugador solo se muestra el mordisco, no la
    # antigua salida lateral. Reiniciar la transferencia para el proximo turno.
    if game.get("mode") == "eliminated":
        previous_player = -1
        transfer_phase = 0
        transfer_elapsed = 0.0
        transfer_destination = -1
        loaded_player = -1
        loaded_step = -1
        appearance = 0.0
        queue_redraw()
        return
    # Al completar el nivel 10, el monstruo se retira del lado activo.
    # No tocar la animacion de cambio entre jugadores durante las rondas.
    if game.get("mode") == "victory_transition":
        var last_player: int = clampi(int(game.get("active_player")), 0, 1)
        if previous_player != last_player or loaded_player != last_player:
            previous_player = last_player
            _load_current_animation(last_player, clampi(roundi(proximity * float(STEPS - 1)), 0, STEPS - 1))
        transfer_phase = 0
        appearance = 1.0
        animation_clock += minf(delta, 0.08)
        queue_redraw()
        return
    # El monstruo no aparece en el menu ni en la pantalla final.
    if game.get("mode") != "playing":
        if game.get("mode") == "menu" or game.get("mode") == "end" or game.get("mode") == "victory":
            previous_player = -1
            active_seconds = 0.0
            appearance = 0.0
            proximity = BASE_PROXIMITY
            transfer_phase = 0
            transfer_elapsed = 0.0
            transfer_destination = -1
        queue_redraw()
        return

    var player: int = clampi(int(game.get("active_player")), 0, 1)
    var dt: float = minf(delta, 0.08)

    if transfer_phase == 1:
        # El monstruo de la pantalla anterior termina de ocultarse.
        # El siguiente lado no se muestra hasta que el anterior desaparece.
        transfer_destination = player
        transfer_elapsed += dt
        animation_clock += dt
        if transfer_elapsed < TRANSFER_HIDE_DURATION:
            queue_redraw()
            return
        previous_player = transfer_destination
        active_seconds = 0.0
        appearance = 0.0
        proximity = BASE_PROXIMITY
        transfer_phase = 2
        transfer_elapsed = 0.0
    elif player != previous_player:
        if previous_player >= 0:
            # Inicio del cambio de turno: primero salir del lado anterior.
            transfer_destination = player
            transfer_phase = 1
            transfer_elapsed = 0.0
            queue_redraw()
            return
        # Primera aparicion de una partida: solo animacion de entrada.
        previous_player = player
        active_seconds = 0.0
        appearance = 0.0
        proximity = BASE_PROXIMITY
        transfer_phase = 2
        transfer_elapsed = 0.0

    if transfer_phase == 2:
        transfer_elapsed += dt
        if transfer_elapsed >= TRANSFER_SHOW_DURATION:
            transfer_phase = 0

    active_seconds += dt
    animation_clock += dt
    appearance = minf(1.0, appearance + dt * FADE_IN_SPEED)
    var player_hearts: Array = game.get("hearts")
    var lives_lost: int = clampi(MAX_HEARTS - int(player_hearts[player]), 0, MAX_HEARTS)
    var goal: float = clampf(
        BASE_PROXIMITY + float(lives_lost) * PROXIMITY_PER_LIFE
        + active_seconds * PROXIMITY_PER_SECOND, 0.0, 1.0
    )
    proximity = move_toward(proximity, goal, SMOOTHING_SPEED * dt)

    var step: int = clampi(roundi(proximity * float(STEPS - 1)), 0, STEPS - 1)
    _load_current_animation(player, step)
    queue_redraw()

func _draw() -> void:
    if game == null or previous_player < 0:
        return
    var current_mode: String = str(game.get("mode"))
    var is_victory_exit: bool = current_mode == "victory_transition"
    if current_mode != "playing" and not is_victory_exit:
        return
    # Mientras el mordisco ocupa el vidrio, ocultar el monstruo en reposo.
    # La capa del mordisco se controla por separado y, al terminar,
    # este monstruo vuelve a mostrarse sin reiniciar su animacion.
    var bite_overlay: Node = get_parent().get_node_or_null("LifeLossAnimation")
    if bite_overlay != null:
        var bite_active: bool = bool(bite_overlay.get("playing_hit"))
        var bite_player: int = int(bite_overlay.get("hit_player"))
        if bite_active and bite_player == previous_player:
            return
    if loaded_player != previous_player or loaded_frames.size() != ANIMATION_FRAMES:
        return
    var frame: int = int(animation_clock * 2.0) % ANIMATION_FRAMES
    var texture: Texture2D = loaded_frames[frame]
    if texture == null:
        return
    # La derecha conserva los PNG y su orientacion originales.
    # A la izquierda se reflejan todos los fotogramas en espejo.
    # El espejo se hace SOLO en la capa del monstruo, nunca en el escenario
    # ni en los sprites de los protagonistas.
    var alpha: float = 0.92 * appearance
    var offset_x: float = 0.0
    var direction: float = 1.0 if previous_player == 0 else -1.0
    if is_victory_exit:
        # Deslizarse fuera de la ventana y desvanecerse antes del menu final.
        var exit_duration: float = maxf(0.01, VICTORY_EXIT_SECONDS)
        var exit_t: float = clampf(float(game.get("victory_transition_elapsed")) / exit_duration, 0.0, 1.0)
        alpha *= (1.0 - exit_t) * (1.0 - exit_t)
        offset_x = direction * (PANEL_WIDTH * 0.62) * exit_t * exit_t
    elif transfer_phase == 1:
        var hide_t: float = clampf(transfer_elapsed / TRANSFER_HIDE_DURATION, 0.0, 1.0)
        alpha *= 1.0 - hide_t
        offset_x = direction * TRANSFER_SLIDE * hide_t * hide_t
    elif transfer_phase == 2:
        var show_t: float = clampf(transfer_elapsed / TRANSFER_SHOW_DURATION, 0.0, 1.0)
        alpha *= show_t
        offset_x = -direction * TRANSFER_SLIDE * (1.0 - show_t) * (1.0 - show_t)

    if previous_player == 0:
        # X=768 con escala X=-1 refleja la imagen dentro de su panel izquierdo.
        draw_set_transform(Vector2(PANEL_WIDTH + offset_x, 0.0), 0.0, Vector2(-1.0, 1.0))
        draw_texture(texture, Vector2.ZERO, Color(1.0, 1.0, 1.0, alpha))
        draw_set_transform(Vector2.ZERO)
    else:
        # SIN transformacion en el panel derecho: aspecto original intacto.
        draw_texture(texture, Vector2(PANEL_WIDTH + offset_x, 0.0), Color(1.0, 1.0, 1.0, alpha))
