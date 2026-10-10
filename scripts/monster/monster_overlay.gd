extends Node2D
## Capa adicional del monstruo; NO modifica ninguna regla ni sprite original.
## Los PNG se leen directamente (Image.load_from_file), sin exigir que
## Godot haya importado previamente las 200 texturas como recursos.

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
    if not FileAccess.file_exists(path):
        push_error("Falta la imagen del monstruo: " + path)
        return null
    var image: Image = Image.load_from_file(path)
    if image == null or image.is_empty():
        push_error("No se pudo decodificar el PNG del monstruo: " + path)
        return null
    return ImageTexture.create_from_image(image)

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
    # El monstruo no aparece en el menu ni en la pantalla final.
    if game.get("mode") != "playing":
        if game.get("mode") == "menu" or game.get("mode") == "end":
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
    if game == null or game.get("mode") != "playing" or previous_player < 0:
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
    if transfer_phase == 1:
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
