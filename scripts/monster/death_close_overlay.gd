extends Node2D
## Cubre la seccion superior COMPLETA del jugador eliminado (768 x 450).
## No modifica turnos, fisica, vidas, ni sprites originales.

const FRAME_COUNT: int = 6
const PANEL_WIDTH: float = 768.0
const UPPER_PANEL_HEIGHT: float = 450.0

var game: Node2D
var frames: Array[Texture2D] = []

func _ready() -> void:
    game = get_parent() as Node2D
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    for index in range(FRAME_COUNT):
        var path: String = "res://assets/monster/death_close/close_%d.png" % index
        if ResourceLoader.exists(path, "Texture2D"):
            frames.append(ResourceLoader.load(path, "Texture2D") as Texture2D)
        elif FileAccess.file_exists(path):
            var img: Image = Image.new()
            if img.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK:
                frames.append(ImageTexture.create_from_image(img))
            else:
                frames.append(null)
        else:
            frames.append(null)
    set_process(true)

var was_closing: bool = false

func _process(_delta: float) -> void:
    var is_closing: bool = game != null and str(game.get("mode")) == "eliminated" and int(game.get("elimination_stage")) == 1
    # Una ultima actualizacion al salir de la etapa limpia el fotograma anterior.
    if is_closing or was_closing:
        queue_redraw()
    was_closing = is_closing

func _upper_panel_rect(player: int) -> Rect2:
    # Coincide con la vista completa superior del jugador, incluido el marco.
    # Nunca invade el panel vecino ni la seccion inferior de parkour.
    return Rect2(float(player) * PANEL_WIDTH, 0.0, PANEL_WIDTH, UPPER_PANEL_HEIGHT)

func _draw() -> void:
    if game == null or str(game.get("mode")) != "eliminated" or int(game.get("elimination_stage")) != 1:
        return
    var duration: float = maxf(0.01, float(game.get("elimination_close_seconds")))
    var t: float = clampf(float(game.get("elimination_elapsed")) / duration, 0.0, 1.0)
    var player: int = clampi(int(game.get("active_player")), 0, 1)
    var panel: Rect2 = _upper_panel_rect(player)

    # Tentaculos y oscurecimiento en TODA la vista superior del eliminado.
    draw_rect(panel, Color(0.0, 0.0, 0.0, t * t * 0.85))
    var index: int = mini(int(t * float(FRAME_COUNT)), FRAME_COUNT - 1)
    if frames.size() == FRAME_COUNT and frames[index] != null:
        var texture: Texture2D = frames[index]
        # Cubrir el rectangulo sin deformar el pixel art: recortar la parte
        # superior e inferior de la fuente en vez de estirar la imagen.
        var source_height: float = minf(float(texture.get_height()),
                float(texture.get_width()) * panel.size.y / panel.size.x)
        var source_y: float = (float(texture.get_height()) - source_height) * 0.5
        draw_texture_rect_region(texture, panel,
                Rect2(0.0, source_y, float(texture.get_width()), source_height))
    # Al terminar queda negra toda la vista superior de ese jugador.
    var blackout: float = clampf((t - 0.84) / 0.16, 0.0, 1.0)
    if blackout > 0.0:
        draw_rect(panel, Color(0.0, 0.0, 0.0, blackout))
