extends Node2D
## Animacion adicional al perder UNA vida.
## Solo observa las vidas: no altera reglas, personajes, turnos ni monstruo actual.

const FRAME_COUNT: int = 6
const FRAME_SECONDS: float = 0.11
const PANEL_WIDTH: float = 768.0
const WINDOW_BOTTOM: float = 450.0
# Los marcos de vidrio no estan centrados exactamente en ambos paneles.
# Estas coordenadas locales coinciden con los cristales de los fondos originales.
const BITE_SIZE: float = 280.0

var game: Node2D
var frames: Array[Texture2D] = []
var last_hearts: Array[int] = [3, 3]
var hit_player: int = -1
var hit_elapsed: float = 0.0
var playing_hit: bool = false

func _ready() -> void:
    game = get_parent() as Node2D
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    for i in range(FRAME_COUNT):
        frames.append(_load_frame("res://assets/monster/life_loss/hit_%d.png" % i))
    var current_hearts: Array = game.get("hearts")
    last_hearts = [int(current_hearts[0]), int(current_hearts[1])]
    set_process(true)

func _load_frame(path: String) -> Texture2D:
    # La textura importada funciona tambien en exportaciones de Godot.
    if ResourceLoader.exists(path, "Texture2D"):
        var resource: Resource = ResourceLoader.load(path, "Texture2D")
        if resource is Texture2D:
            return resource as Texture2D
    # Respaldo durante la primera importacion de una carpeta nueva.
    if FileAccess.file_exists(path):
        var image: Image = Image.new()
        if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK:
            return ImageTexture.create_from_image(image)
    push_error("UMBRAL: falta el fotograma de perdida de vida: " + path)
    return null

func _process(delta: float) -> void:
    if game == null:
        return
    var was_visible: bool = playing_hit
    var current_mode: String = str(game.get("mode"))
    var current_hearts: Array = game.get("hearts")

    # Detectar cada vida perdida SIN modificar las reglas ni lose_life().
    for player in range(2):
        var remaining: int = int(current_hearts[player])
        if remaining < last_hearts[player] and (current_mode == "playing" or current_mode == "eliminated"):
            hit_player = player
            hit_elapsed = 0.0
            playing_hit = true
        last_hearts[player] = remaining

    # En la muerte definitiva, la etapa 0 es SOLO el mordisco.
    # En la etapa 1 los tentaculos toman el relevo y la 2 es el aviso negro.
    if current_mode == "menu" or current_mode == "end":
        playing_hit = false
    elif current_mode == "eliminated":
        playing_hit = int(game.get("elimination_stage")) == 0
    elif playing_hit:
        hit_elapsed += minf(delta, 0.08)
        if hit_elapsed >= float(FRAME_COUNT) * FRAME_SECONDS:
            playing_hit = false

    if playing_hit or was_visible:
        queue_redraw()

func _glass_rect(player: int) -> Rect2:
    var panel_x: float = float(player) * PANEL_WIDTH
    if player == 0:
        return Rect2(panel_x + 140.0, 76.0, 538.0, 268.0)
    return Rect2(panel_x + 95.0, 76.0, 540.0, 268.0)

func _draw_clipped(texture: Texture2D, dest: Rect2, clip_rect: Rect2) -> void:
    # Recorte manual: CanvasItem.draw_texture_rect() no limita el dibujo
    # a una ventana. La subregion impide desbordes incluso con zoom.
    var visible: Rect2 = dest.intersection(clip_rect)
    if visible.size.x <= 0.0 or visible.size.y <= 0.0:
        return
    var scale: Vector2 = Vector2(float(texture.get_width()) / dest.size.x,
            float(texture.get_height()) / dest.size.y)
    var source: Rect2 = Rect2((visible.position - dest.position) * scale, visible.size * scale)
    draw_texture_rect_region(texture, visible, source)

func _draw() -> void:
    if game == null or hit_player < 0 or not playing_hit:
        return
    if frames.size() != FRAME_COUNT:
        return

    var is_fatal: bool = str(game.get("mode")) == "eliminated" and int(game.get("elimination_stage")) == 0
    var frame_index: int = 0
    var size: float = BITE_SIZE
    if is_fatal:
        var duration: float = maxf(0.01, float(game.get("elimination_exit_seconds")))
        var progress: float = clampf(float(game.get("elimination_elapsed")) / duration, 0.0, 1.0)
        frame_index = mini(int(progress * float(FRAME_COUNT)), FRAME_COUNT - 1)
        # El mordisco final se acerca, pero el vidrio actua como limite estricto.
        var surge: float = progress * progress * (3.0 - 2.0 * progress)
        size = lerpf(275.0, 330.0, surge)
    else:
        frame_index = mini(int(hit_elapsed / FRAME_SECONDS), FRAME_COUNT - 1)
        if frame_index == 2 or frame_index == 4:
            size *= 1.04
        elif frame_index == 3:
            size *= 1.08

    var texture: Texture2D = frames[frame_index]
    if texture == null:
        return
    var glass: Rect2 = _glass_rect(hit_player)
    var center: Vector2 = glass.position + glass.size * 0.5
    var rect: Rect2 = Rect2(center - Vector2(size, size) * 0.5, Vector2(size, size))
    # Tanto un golpe normal como la ultima vida quedan DENTRO del cristal.
    # draw_texture_rect_region recorta incluso los fotogramas ampliados.
    _draw_clipped(texture, rect, glass)
